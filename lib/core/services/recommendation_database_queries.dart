// lib/core/services/recommendation_database_queries.dart

import '../../database/database_helper.dart';
import '../../models/recipe.dart';
import '../../models/protein_type.dart';
//import '../../models/recipe_ingredient.dart';
//import '../../models/ingredient.dart';
import '../errors/gastrobrain_exceptions.dart';
import 'localized_error_messages.dart';

/// Specialized database query methods for the recommendation engine
class RecommendationDatabaseQueries {
  final DatabaseHelper _dbHelper;

  Map<String, List<ProteinType>>? proteinTypesOverride;

  RecommendationDatabaseQueries({
    required DatabaseHelper dbHelper,
    this.proteinTypesOverride,
  }) : _dbHelper = dbHelper;

  /// Get all available recipes filtered by given criteria
  ///
  /// Parameters:
  /// - [excludeIds]: Recipe IDs to exclude
  /// - [limit]: Maximum number of recipes to return (optional)
  /// - [requiredProteinTypes]: Only include recipes with these protein types (optional)
  /// - [excludedProteinTypes]: Exclude recipes with these protein types (optional)
  Future<List<Recipe>> getCandidateRecipes({
    List<String> excludeIds = const [],
    int? limit,
    List<ProteinType>? requiredProteinTypes,
    List<ProteinType>? excludedProteinTypes,
  }) async {
    try {
      // Start with a basic query to get all recipes
      var recipes = await _dbHelper.getAllRecipes();

      // Filter out excluded recipes
      if (excludeIds.isNotEmpty) {
        recipes =
            recipes.where((recipe) => !excludeIds.contains(recipe.id)).toList();
      }

      // If protein filters are active, we need to get protein information
      if (requiredProteinTypes != null || excludedProteinTypes != null) {
        final recipeProteinTypes = await getRecipeProteinTypes(
            recipeIds: recipes.map((r) => r.id).toList());

        // Apply protein type filters
        recipes = recipes.where((recipe) {
          final proteinTypes = recipeProteinTypes[recipe.id] ?? [];

          // If required types are specified, recipe must contain at least one
          if (requiredProteinTypes != null && requiredProteinTypes.isNotEmpty) {
            if (!proteinTypes
                .any((type) => requiredProteinTypes.contains(type))) {
              return false;
            }
          }

          // If excluded types are specified, recipe must not contain any
          if (excludedProteinTypes != null && excludedProteinTypes.isNotEmpty) {
            if (proteinTypes
                .any((type) => excludedProteinTypes.contains(type))) {
              return false;
            }
          }

          return true;
        }).toList();
      }

      // Apply limit if specified
      if (limit != null && limit > 0 && limit < recipes.length) {
        recipes = recipes.sublist(0, limit);
      }

      return recipes;
    } catch (e) {
      throw GastrobrainException(
          '${LocalizedErrorMessages.getMessage('errorGettingCandidateRecipes')}: ${e.toString()}');
    }
  }

  /// Get the protein types for the given recipe IDs
  ///
  /// Returns a map of recipe ID -> list of protein types
  Future<Map<String, List<ProteinType>>> getRecipeProteinTypes({
    required List<String> recipeIds,
  }) async {
    try {
      if (proteinTypesOverride != null) {
        final result = <String, List<ProteinType>>{};

        // Initialize all recipe IDs with empty lists
        for (final id in recipeIds) {
          // Use the override if available for this ID, otherwise empty list
          result[id] = proteinTypesOverride!.containsKey(id)
              ? List<ProteinType>.from(proteinTypesOverride![id]!)
              : [];
        }

        return result;
      }

      final result = <String, List<ProteinType>>{};

      // Initialize empty lists for all recipe IDs
      for (final id in recipeIds) {
        result[id] = [];
      }

      // For each recipe, get its ingredients and check protein types
      for (final recipeId in recipeIds) {
        final ingredientMaps = await _dbHelper.getRecipeIngredients(recipeId);

        for (final ingredientMap in ingredientMaps) {
          final proteinTypeStr = ingredientMap['protein_type'] as String?;

          if (proteinTypeStr != null) {
            // Find the matching protein type
            final proteinType = ProteinType.values.firstWhere(
              (type) => type.name == proteinTypeStr,
              orElse: () => ProteinType.values.first,
            );

            result[recipeId]!.add(proteinType);
          }
        }
      }

      return result;
    } catch (e) {
      throw GastrobrainException(
          'Error getting recipe protein types: ${e.toString()}');
    }
  }

  /// Get the last time each recipe was cooked
  ///
  /// Returns a map of recipe ID -> last cooked date (or null if never cooked)
  Future<Map<String, DateTime?>> getLastCookedDates({
    List<String> recipeIds = const [],
  }) async {
    try {
      // If specific recipe IDs are provided, get dates just for those
      if (recipeIds.isNotEmpty) {
        final result = <String, DateTime?>{};

        for (final id in recipeIds) {
          final date = await _dbHelper.getLastCookedDate(id);
          result[id] = date;
        }

        return result;
      }

      // Otherwise, use the more efficient bulk query
      return await _dbHelper.getAllLastCooked();
    } catch (e) {
      throw GastrobrainException(
          'Error getting last cooked dates: ${e.toString()}');
    }
  }

  /// Get the number of times each recipe has been cooked
  ///
  /// Returns a map of recipe ID -> count
  Future<Map<String, int>> getMealCounts({
    List<String> recipeIds = const [],
  }) async {
    try {
      // If specific recipe IDs are provided, get counts just for those
      if (recipeIds.isNotEmpty) {
        final result = <String, int>{};

        for (final id in recipeIds) {
          final count = await _dbHelper.getTimesCookedCount(id);
          result[id] = count;
        }

        return result;
      }

      // Otherwise, use the more efficient bulk query
      return await _dbHelper.getAllMealCounts();
    } catch (e) {
      throw GastrobrainException('${LocalizedErrorMessages.getMessage('errorGettingMealCounts')}: ${e.toString()}');
    }
  }

  /// Get all recipes with associated cooking statistics (optimized batch query)
  ///
  /// Returns a map with recipe stats including:
  /// - Recipe object
  /// - Last cooked date
  /// - Times cooked count
  /// - Protein types
  Future<List<Map<String, dynamic>>> getRecipesWithStats({
    List<String> excludeIds = const [],
    bool includeProteinInfo = false,
  }) async {
    try {
      // Get all recipes filtered by excludeIds
      final recipes = await getCandidateRecipes(excludeIds: excludeIds);

      if (recipes.isEmpty) {
        return [];
      }

      // Get batch data for recipes
      final recipeIds = recipes.map((r) => r.id).toList();
      final lastCookedDates = await getLastCookedDates(recipeIds: recipeIds);
      final mealCounts = await getMealCounts(recipeIds: recipeIds);

      // Get protein information if requested
      final Map<String, List<ProteinType>> proteinTypes = includeProteinInfo
          ? await getRecipeProteinTypes(recipeIds: recipeIds)
          : {};

      // Combine all data
      return recipes.map((recipe) {
        return {
          'recipe': recipe,
          'lastCooked': lastCookedDates[recipe.id],
          'timesCooked': mealCounts[recipe.id] ?? 0,
          if (includeProteinInfo) 'proteinTypes': proteinTypes[recipe.id] ?? [],
        };
      }).toList();
    } catch (e) {
      throw GastrobrainException(
          'Error getting recipes with stats: ${e.toString()}');
    }
  }

  /// Get meals cooked in a specific date range
  ///
  /// Returns a list of meal data with recipe information
  Future<List<Map<String, dynamic>>> getRecentMeals({
    required DateTime startDate,
    DateTime? endDate,
    int limit = 10,
  }) async {
    try {
      // Get recent meals first
      final meals = await _dbHelper.getRecentMeals(limit: limit);

      if (meals.isEmpty) {
        return [];
      }

      // For each meal, get the associated recipes
      final result = <Map<String, dynamic>>[];

      for (final meal in meals) {
        // First try to get recipes from junction table
        final mealRecipes = await _dbHelper.getMealRecipesForMeal(meal.id);

        Recipe? primaryRecipe;

        if (mealRecipes.isNotEmpty) {
          // Find the primary recipe if one is marked as primary
          final primaryMealRecipe = mealRecipes.firstWhere(
            (mr) => mr.isPrimaryDish,
            orElse: () => mealRecipes.first,
          );

          primaryRecipe = await _dbHelper.getRecipe(primaryMealRecipe.recipeId);
        }
        // Fallback to direct recipe_id if available and no recipes found in junction
        else if (meal.recipeId != null) {
          primaryRecipe = await _dbHelper.getRecipe(meal.recipeId!);
        }

        if (primaryRecipe != null) {
          result.add({
            'meal': meal,
            'recipe': primaryRecipe,
            'cookedAt': meal.cookedAt,
          });
        }
      }

      return result;
    } catch (e) {
      throw GastrobrainException('${LocalizedErrorMessages.getMessage('errorGettingRecentMeals')}: ${e.toString()}');
    }
  }
}
