// test/mocks/mock_database_helper.dart

import 'package:gastrobrain/database/database_helper.dart';
import 'package:gastrobrain/utils/id_generator.dart';
import 'package:gastrobrain/models/recipe_recommendation.dart';
import 'package:gastrobrain/models/recommendation_results.dart';
import 'package:gastrobrain/models/protein_type.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/meal.dart';
import 'package:gastrobrain/models/meal_recipe.dart';
import 'package:gastrobrain/models/meal_plan.dart';
import 'package:gastrobrain/models/meal_plan_item.dart';
import 'package:gastrobrain/models/meal_plan_item_recipe.dart';
import 'package:gastrobrain/models/ingredient.dart';
import 'package:gastrobrain/models/recipe_ingredient.dart';
import 'package:sqflite/sqflite.dart';

/// A partial mock implementation of DatabaseHelper for testing.
///
/// This class implements a subset of the DatabaseHelper methods needed for
/// testing the recommendation algorithm. Other methods throw UnimplementedError.
class MockDatabaseHelper implements DatabaseHelper {
  Map<String, List<ProteinType>> recipeProteinTypes = {};
  List<Map<String, dynamic>>? returnCustomMealsForRecommendations;

  @override
  Future<int> deleteMealPlan(String id) async {
    throw UnimplementedError('Method not implemented for tests');
  }

  @override
  Future<MealPlan?> getMealPlan(String id) async {
    return _mealPlans[id];
  }

  @override
  Future<MealPlan?> getMealPlanForWeek(DateTime startDate) async {
    final normalizedStartDate =
        DateTime(startDate.year, startDate.month, startDate.day);

    // Find a plan that starts on the given date
    try {
      return _mealPlans.values.firstWhere(
        (plan) => DateTime(plan.weekStartDate.year, plan.weekStartDate.month,
                plan.weekStartDate.day)
            .isAtSameMomentAs(normalizedStartDate),
      );
    } catch (e) {
      // No matching plan found
      return null;
    }
  }

  @override
  Future<List<MealPlanItem>> getMealPlanItemsForDate(DateTime date) async {
    final dateString = MealPlanItem.formatPlannedDate(date);

    List<MealPlanItem> result = [];

    // Search through all meal plans
    for (final plan in _mealPlans.values) {
      // Find items for this date
      final items =
          plan.items.where((item) => item.plannedDate == dateString).toList();

      result.addAll(items);
    }

    return result;
  }

  @override
  Future<String> insertMealPlan(MealPlan mealPlan) async {
    _mealPlans[mealPlan.id] = mealPlan;
    return mealPlan.id;
  }

  @override
  Future<String> insertMealPlanItem(MealPlanItem item) async {
    // Find the meal plan this item belongs to
    final plan = _mealPlans[item.mealPlanId];
    if (plan != null) {
      // Add the item to the plan
      plan.items.add(item);
    }
    return item.id;
  }

  @override
  Future<int> updateMealPlan(MealPlan mealPlan) async {
    throw UnimplementedError('Method not implemented for tests');
  }

  @override
  Future<int> updateMealPlanItem(MealPlanItem item) async {
    throw UnimplementedError('Method not implemented for tests');
  }

  // In-memory storage for entities
  final Map<String, Recipe> _recipes = {};
  final Map<String, Meal> _meals = {};
  final Map<String, MealRecipe> _mealRecipes = {};
  final Map<String, MealPlan> _mealPlans = {};
  final Map<String, MealPlanItem> _mealPlanItems = {};
  final Map<String, MealPlanItemRecipe> _mealPlanItemRecipes = {};
  final Map<String, Ingredient> _ingredients = {};
  final Map<String, RecipeIngredient> _recipeIngredients = {};

  // Additional storage for recommendation-specific data
  final Map<String, DateTime?> _lastCookedDates = {};
  final Map<String, int> _mealCounts = {};

  // We'll expose these maps for direct manipulation in tests if needed
  Map<String, Recipe> get recipes => _recipes;
  Map<String, MealPlan> get mealPlans => _mealPlans;
  Map<String, Ingredient> get ingredients => _ingredients;

  // Database property implementation
  @override
  Future<Database> get database => throw UnimplementedError(
      'The database property is not implemented in MockDatabaseHelper');

  // Reset all data
  void resetAllData() {
    _recipes.clear();
    _meals.clear();
    _mealRecipes.clear();
    _mealPlans.clear();
    _mealPlanItems.clear();
    _mealPlanItemRecipes.clear();
    _ingredients.clear();
    _recipeIngredients.clear();
    _lastCookedDates.clear();
    _mealCounts.clear();
  }

  // RECIPE OPERATIONS
  @override
  Future<int> insertRecipe(Recipe recipe) async {
    _recipes[recipe.id] = recipe;
    return 1;
  }

  @override
  Future<List<Recipe>> getAllRecipes() async {
    return _recipes.values.toList();
  }

  @override
  Future<Recipe?> getRecipe(String id) async {
    return _recipes[id];
  }

  Future<Map<String, List<ProteinType>>> getRecipeProteinTypes({
    required List<String> recipeIds,
  }) async {
    // Create a result map - recipeId -> list of protein types
    final Map<String, List<ProteinType>> result = {};

    // Initialize with empty lists
    for (final id in recipeIds) {
      result[id] = [];
    }

    // If we have protein types defined in our map, use those
    for (final id in recipeIds) {
      if (recipeProteinTypes.containsKey(id)) {
        result[id] = recipeProteinTypes[id]!;
      } else {
        // Fall back to default behavior for recipes without defined types
        result[id] = [ProteinType.chicken];
      }
    }
    return result;
  }

  @override
  Future<int> updateRecipe(Recipe recipe) async {
    if (!_recipes.containsKey(recipe.id)) return 0;
    _recipes[recipe.id] = recipe;
    return 1;
  }

  @override
  Future<int> deleteRecipe(String id) async {
    if (!_recipes.containsKey(id)) return 0;
    _recipes.remove(id);
    return 1;
  }

  @override
  Future<List<Recipe>> getRecipesWithSortAndFilter({
    String? sortBy,
    String? sortOrder,
    Map<String, dynamic>? filters,
  }) async {
    // A simple implementation that returns all recipes
    // In a real implementation, we would apply sorting and filtering
    return _recipes.values.toList();
  }

  // MEAL OPERATIONS
  @override
  Future<int> insertMeal(Meal meal) async {
    _meals[meal.id] = meal;

    // If the meal has a recipeId, update last cooked date
    if (meal.recipeId != null) {
      _lastCookedDates[meal.recipeId!] = meal.cookedAt;
      _mealCounts[meal.recipeId!] = (_mealCounts[meal.recipeId!] ?? 0) + 1;
    }

    return 1;
  }

  @override
  Future<Meal?> getMeal(String id) async {
    return _meals[id];
  }

  @override
  Future<List<Meal>> getMealsForRecipe(String recipeId) async {
    // Return meals with direct recipeId reference OR meals linked via junction table
    final directMeals =
        _meals.values.where((meal) => meal.recipeId == recipeId).toList();

    // Get meal IDs from junction table
    final junctionMealIds = _mealRecipes.values
        .where((mr) => mr.recipeId == recipeId)
        .map((mr) => mr.mealId)
        .toSet();

    // Add meals referenced via junction table
    final junctionMeals = _meals.values
        .where((meal) => junctionMealIds.contains(meal.id))
        .toList();

    // Combine both lists and deduplicate by meal ID
    final allMeals = <String, Meal>{};
    for (final meal in directMeals) {
      allMeals[meal.id] = meal;
    }
    for (final meal in junctionMeals) {
      allMeals[meal.id] = meal;
    }
    return allMeals.values.toList();
  }

  @override
  Future<int> deleteMeal(String id) async {
    if (!_meals.containsKey(id)) return 0;

    // Remove related junction records
    _mealRecipes.removeWhere((_, mr) => mr.mealId == id);

    _meals.remove(id);
    return 1;
  }

  @override
  Future<List<Meal>> getRecentMeals({int limit = 10}) async {
    // Sort meals by cooked date (most recent first)
    final sortedMeals = _meals.values.toList()
      ..sort((a, b) => b.cookedAt.compareTo(a.cookedAt));

    // Take the most recent meals, up to the limit
    return sortedMeals.take(limit).toList();
  }

// Add this to your MockDatabaseHelper class
  Future<List<Map<String, dynamic>>> getRecentMealsForRecommendations({
    required DateTime startDate,
    DateTime? endDate,
    int limit = 10,
  }) async {
    if (returnCustomMealsForRecommendations != null) {
      return returnCustomMealsForRecommendations!;
    }

    // Get recent meals
    final meals = await getRecentMeals(limit: limit);

    final result = <Map<String, dynamic>>[];

    for (final meal in meals) {
      Recipe? recipe;

      // Try to get recipe from recipeId
      if (meal.recipeId != null && _recipes.containsKey(meal.recipeId)) {
        recipe = _recipes[meal.recipeId];

        if (recipe != null) {
          result.add({
            'meal': meal,
            'recipe': recipe,
            'cookedAt': meal.cookedAt,
          });
        }
      }
    }

    return result;
  }

  // MEAL RECIPE OPERATIONS
  @override
  Future<String> insertMealRecipe(MealRecipe mealRecipe) async {
    _mealRecipes[mealRecipe.id] = mealRecipe;

    // Update last cooked date and count
    if (_meals.containsKey(mealRecipe.mealId)) {
      final meal = _meals[mealRecipe.mealId]!;
      _lastCookedDates[mealRecipe.recipeId] = meal.cookedAt;
      _mealCounts[mealRecipe.recipeId] =
          (_mealCounts[mealRecipe.recipeId] ?? 0) + 1;
    }

    return mealRecipe.id;
  }

  @override
  Future<List<MealRecipe>> getMealRecipesForMeal(String mealId) async {
    return _mealRecipes.values.where((mr) => mr.mealId == mealId).toList();
  }

  // LAST COOKED DATE AND MEAL COUNTS
  @override
  Future<DateTime?> getLastCookedDate(String recipeId) async {
    return _lastCookedDates[recipeId];
  }

  @override
  Future<int> getTimesCookedCount(String recipeId) async {
    return _mealCounts[recipeId] ?? 0;
  }

  @override
  Future<Map<String, DateTime>> getAllLastCooked() async {
    // Filter out null dates
    return Map.fromEntries(_lastCookedDates.entries
        .where((entry) => entry.value != null)
        .map((entry) => MapEntry(entry.key, entry.value!)));
  }

  @override
  Future<Map<String, int>> getAllMealCounts() async {
    return Map.from(_mealCounts);
  }

  // Override for resetDatabaseForTests to support integration tests
  @override
  Future<void> resetDatabaseForTests() async {
    resetAllData();
  }

  // INGREDIENT OPERATIONS
  @override
  Future<String> insertIngredient(Ingredient ingredient) async {
    _ingredients[ingredient.id] = ingredient;
    return ingredient.id;
  }

  @override
  Future<List<Ingredient>> getAllIngredients() async {
    return _ingredients.values.toList();
  }

  @override
  Future<int> updateIngredient(Ingredient ingredient) async {
    if (!_ingredients.containsKey(ingredient.id)) return 0;

    _ingredients[ingredient.id] = ingredient;
    return 1;
  }

  @override
  Future<int> deleteIngredient(String id) async {
    if (!_ingredients.containsKey(id)) return 0;

    _ingredients.remove(id);
    return 1;
  }

  // Not implemented methods - these would need to be added as needed
  @override
  Future<void> addIngredientToRecipe(RecipeIngredient recipeIngredient) {
    throw UnimplementedError('Method not implemented for tests');
  }

  @override
  Future<String> addRecipeToMeal(String mealId, String recipeId,
      {bool isPrimaryDish = false}) async {
    if (!_meals.containsKey(mealId)) {
      throw Exception('Meal not found');
    }

    final mealRecipe = MealRecipe(
      mealId: mealId,
      recipeId: recipeId,
      isPrimaryDish: isPrimaryDish,
    );

    _mealRecipes[mealRecipe.id] = mealRecipe;

    // Update meal's recipe list if it exists
    final meal = _meals[mealId];
    if (meal != null) {
      meal.mealRecipes ??= [];
      meal.mealRecipes!.add(mealRecipe);

      // Update last cooked date
      _lastCookedDates[recipeId] = meal.cookedAt;
      _mealCounts[recipeId] = (_mealCounts[recipeId] ?? 0) + 1;
    }

    return mealRecipe.id;
  }

  @override
  Future<void> importIngredientsFromJson(String assetPath) {
    throw UnimplementedError('Method not implemented for tests');
  }

  @override
  Future<void> importRecipesFromJson(String assetPath) {
    throw UnimplementedError('Method not implemented for tests');
  }

  @override
  Future<int> deleteMealPlanItem(String id) {
    throw UnimplementedError('Method not implemented for tests');
  }

  @override
  Future<int> deleteMealRecipe(String id) async {
    if (!_mealRecipes.containsKey(id)) return 0;

    final mealRecipe = _mealRecipes[id]!;

    // Update meal's recipe list if it exists
    final meal = _meals[mealRecipe.mealId];
    if (meal != null && meal.mealRecipes != null) {
      meal.mealRecipes!.removeWhere((mr) => mr.id == id);
    }

    _mealRecipes.remove(id);
    return 1;
  }

  @override
  Future<int> deleteRecipeIngredient(String id) {
    throw UnimplementedError('Method not implemented for tests');
  }

  @override
  Future<List<Map<String, dynamic>>> getRecipeIngredients(
      String recipeId) async {
    // Return a minimal mock response with no ingredients for simplicity
    // This should prevent the error in the rating recommendation tests
    return [];
  }

  @override
  Future<int> getRecipesCount() {
    throw UnimplementedError('Method not implemented for tests');
  }

  @override
  Future<int> getIngredientsCount() {
    throw UnimplementedError('Method not implemented for tests');
  }

  @override
  Future<List<Ingredient>> getProteinIngredients({String? proteinType}) {
    throw UnimplementedError('Method not implemented for tests');
  }

  @override
  Future<bool> removeRecipeFromMeal(String mealId, String recipeId) async {
    if (!_meals.containsKey(mealId)) return false;

    // Find and remove all MealRecipe entries matching this mealId and recipeId
    final toRemove = _mealRecipes.values
        .where((mr) => mr.mealId == mealId && mr.recipeId == recipeId)
        .map((mr) => mr.id)
        .toList();

    if (toRemove.isEmpty) return false;

    // Remove each matching MealRecipe
    for (final id in toRemove) {
      await deleteMealRecipe(id);
    }

    return true;
  }

  @override
  Future<bool> setPrimaryRecipeForMeal(String mealId, String recipeId) async {
    if (!_meals.containsKey(mealId)) return false;

    // Find if there's already a MealRecipe for this recipe
    final mealRecipeEntries = _mealRecipes.values
        .where((mr) => mr.mealId == mealId && mr.recipeId == recipeId)
        .toList();

    if (mealRecipeEntries.isEmpty) {
      // Recipe not associated with this meal
      return false;
    }

    // Clear primary status from all recipes in this meal
    for (final entry
        in _mealRecipes.values.where((mr) => mr.mealId == mealId)) {
      if (entry.isPrimaryDish) {
        final updated = entry.copyWith(isPrimaryDish: false);
        _mealRecipes[entry.id] = updated;

        // Update in the meal's recipe list if it exists
        final meal = _meals[mealId];
        if (meal != null && meal.mealRecipes != null) {
          final index = meal.mealRecipes!.indexWhere((mr) => mr.id == entry.id);
          if (index >= 0) {
            meal.mealRecipes![index] = updated;
          }
        }
      }
    }

    // Set the specified recipe as primary
    final mealRecipe = mealRecipeEntries.first;
    final updatedMealRecipe = mealRecipe.copyWith(isPrimaryDish: true);
    _mealRecipes[mealRecipe.id] = updatedMealRecipe;

    // Update in the meal's recipe list if it exists
    final meal = _meals[mealId];
    if (meal != null && meal.mealRecipes != null) {
      final index =
          meal.mealRecipes!.indexWhere((mr) => mr.id == mealRecipe.id);
      if (index >= 0) {
        meal.mealRecipes![index] = updatedMealRecipe;
      }
    }

    return true;
  }

  @override
  Future<int> updateMeal(Meal meal) async {
    // Check if the meal exists
    if (!_meals.containsKey(meal.id)) return 0;

    // Store the original meal to handle recipeId changes
    final originalMeal = _meals[meal.id];

    // Update the meal
    _meals[meal.id] = meal;

    // Update last cooked dates if the recipeId has changed
    // First, remove the old recipeId's association if it existed
    if (originalMeal!.recipeId != null &&
        originalMeal.recipeId != meal.recipeId) {
      // This is a simplification - in a real implementation you might
      // need to recalculate the last cooked date based on all meals
      // We're just removing this meal's contribution
      _lastCookedDates.remove(originalMeal.recipeId);
      _mealCounts[originalMeal.recipeId!] =
          (_mealCounts[originalMeal.recipeId!] ?? 1) - 1;
    }

    // Then add the new recipeId's association if it exists
    if (meal.recipeId != null && meal.recipeId != originalMeal.recipeId) {
      _lastCookedDates[meal.recipeId!] = meal.cookedAt;
      _mealCounts[meal.recipeId!] = (_mealCounts[meal.recipeId!] ?? 0) + 1;
    }

    return 1; // Return 1 to indicate success
  }

  @override
  Future<int> updateMealRecipe(MealRecipe mealRecipe) async {
    if (!_mealRecipes.containsKey(mealRecipe.id)) return 0;

    _mealRecipes[mealRecipe.id] = mealRecipe;

    // Update in the meal's recipe list if it exists
    final meal = _meals[mealRecipe.mealId];
    if (meal != null && meal.mealRecipes != null) {
      final index =
          meal.mealRecipes!.indexWhere((mr) => mr.id == mealRecipe.id);
      if (index >= 0) {
        meal.mealRecipes![index] = mealRecipe;
      }
    }

    return 1;
  }

  @override
  Future<int> updateRecipeIngredient(RecipeIngredient recipeIngredient) {
    throw UnimplementedError('Method not implemented for tests');
  }

  @override
  Future<List<MealPlan>> getMealPlansByDateRange(
      DateTime start, DateTime end) async {
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);

    return _mealPlans.values.where((plan) {
      final planEndDate = plan.weekEndDate;
      return !normalizedStart.isAfter(planEndDate) &&
          !normalizedEnd.isBefore(plan.weekStartDate);
    }).toList();
  }

  @override
  Future<String> insertMealPlanItemRecipe(
      MealPlanItemRecipe mealPlanItemRecipe) async {
    // Find the item this recipe belongs to
    for (final plan in _mealPlans.values) {
      for (final item in plan.items) {
        if (item.id == mealPlanItemRecipe.mealPlanItemId) {
          // Found the item, add the recipe to it
          item.mealPlanItemRecipes ??= [];
          item.mealPlanItemRecipes!.add(mealPlanItemRecipe);
          return mealPlanItemRecipe.id;
        }
      }
    }

    // Item not found
    return mealPlanItemRecipe.id;
  }

  // In-memory storage for recommendation history
  final Map<String, Map<String, dynamic>> _recommendationHistory = {};

  @override
  Future<String> saveRecommendationHistory(
      RecommendationResults results, String contextType,
      {DateTime? targetDate, String? mealType}) async {
    final id = IdGenerator.generateId();
    final now = DateTime.now();

    _recommendationHistory[id] = {
      'id': id,
      'result_data':
          results, // Store the actual object for simplicity in the mock
      'created_at': now,
      'context_type': contextType,
      'target_date': targetDate,
      'meal_type': mealType,
      'user_id': null,
    };

    return id;
  }

  @override
  Future<List<Map<String, dynamic>>> getRecommendationHistory({
    int limit = 10,
    String? contextType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final results = _recommendationHistory.values.where((entry) {
      if (contextType != null && entry['context_type'] != contextType) {
        return false;
      }

      final createdAt = entry['created_at'] as DateTime;

      if (startDate != null && createdAt.isBefore(startDate)) {
        return false;
      }

      if (endDate != null && createdAt.isAfter(endDate)) {
        return false;
      }

      return true;
    }).toList();

    // Sort by created_at descending
    results.sort((a, b) =>
        (b['created_at'] as DateTime).compareTo(a['created_at'] as DateTime));

    // Apply limit
    final limitedResults = results.take(limit).toList();

    // Convert to maps
    return limitedResults
        .map((entry) => {
              'id': entry['id'],
              'result_data':
                  entry['result_data'].toString(), // Simplified for mock
              'created_at': (entry['created_at'] as DateTime).toIso8601String(),
              'context_type': entry['context_type'],
              'target_date': entry['target_date'] != null
                  ? (entry['target_date'] as DateTime).toIso8601String()
                  : null,
              'meal_type': entry['meal_type'],
              'user_id': entry['user_id'],
            })
        .toList();
  }

  @override
  Future<RecommendationResults?> getRecommendationById(String id) async {
    if (!_recommendationHistory.containsKey(id)) {
      return null;
    }

    // Return the actual object - in the real implementation, we'd deserialize from JSON
    return _recommendationHistory[id]?['result_data'] as RecommendationResults?;
  }

  @override
  Future<bool> updateRecommendationResponse(
    String historyId,
    String recipeId,
    UserResponse response,
  ) async {
    if (!_recommendationHistory.containsKey(historyId)) {
      return false;
    }

    final results = _recommendationHistory[historyId]?['result_data']
        as RecommendationResults?;
    if (results == null) return false;

    // Create a new list of recommendations with the updated response
    final updatedRecommendations = <RecipeRecommendation>[];
    bool found = false;

    for (final rec in results.recommendations) {
      if (rec.recipe.id == recipeId) {
        // Create a new recommendation with the updated response
        updatedRecommendations.add(RecipeRecommendation(
          recipe: rec.recipe,
          totalScore: rec.totalScore,
          factorScores: rec.factorScores,
          metadata: rec.metadata,
          userResponse: response,
          respondedAt: DateTime.now(),
        ));
        found = true;
      } else {
        // Keep the original recommendation
        updatedRecommendations.add(rec);
      }
    }

    if (!found) return false;

    // Create new results with the updated recommendations
    final updatedResults = RecommendationResults(
      recommendations: updatedRecommendations,
      totalEvaluated: results.totalEvaluated,
      queryParameters: results.queryParameters,
      generatedAt: results.generatedAt,
    );

    // Update the stored results
    _recommendationHistory[historyId]?['result_data'] = updatedResults;

    return true;
  }

  @override
  Future<int> cleanupRecommendationHistory({int daysToKeep = 14}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

    final initialCount = _recommendationHistory.length;

    _recommendationHistory.removeWhere((_, entry) {
      final createdAt = entry['created_at'] as DateTime;
      return createdAt.isBefore(cutoffDate);
    });

    return initialCount - _recommendationHistory.length;
  }

  Future<List<Recipe>> getCandidateRecipes({
    List<String> excludeIds = const [],
    int? limit,
    List<ProteinType>? requiredProteinTypes,
    List<ProteinType>? excludedProteinTypes,
  }) async {
    // Use custom implementation if provided
    if (customGetCandidateRecipes != null) {
      return customGetCandidateRecipes!(
        excludeIds: excludeIds,
        requiredProteinTypes: requiredProteinTypes,
        excludedProteinTypes: excludedProteinTypes,
      );
    }

    // Default implementation
    var recipes = await getAllRecipes();

    // Filter out excluded recipes
    if (excludeIds.isNotEmpty) {
      recipes =
          recipes.where((recipe) => !excludeIds.contains(recipe.id)).toList();
    }

    // Apply protein type filters
    if ((requiredProteinTypes != null && requiredProteinTypes.isNotEmpty) ||
        (excludedProteinTypes != null && excludedProteinTypes.isNotEmpty)) {
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
          if (proteinTypes.any((type) => excludedProteinTypes.contains(type))) {
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
  }

  Future<List<Recipe>> Function(
      {List<String> excludeIds,
      List<ProteinType>? requiredProteinTypes,
      List<ProteinType>? excludedProteinTypes})? customGetCandidateRecipes;
}
