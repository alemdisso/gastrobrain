// test/test_utils/multi_ingredient_fixtures.dart

import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/ingredient.dart';
import 'package:gastrobrain/models/recipe_ingredient.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/models/protein_type.dart';
import 'package:gastrobrain/models/ingredient_category.dart';
import 'package:gastrobrain/models/measurement_unit.dart';
import 'package:gastrobrain/models/meal.dart';
import 'package:gastrobrain/utils/id_generator.dart';

import '../mocks/mock_database_helper.dart';

/// Test fixtures for multi-ingredient recipe testing scenarios.
/// Provides reusable helper functions for creating complex recipes with various
/// ingredient compositions to test the recommendation engine.
class MultiIngredientFixtures {
  /// Creates a complex recipe with multiple ingredients and protein types.
  ///
  /// [mockDb] - The mock database helper to insert data into
  /// [name] - Recipe name
  /// [proteinTypes] - List of protein types to include
  /// [vegetableCount] - Number of vegetable ingredients (default: 5)
  /// [otherCount] - Number of other ingredients (default: 3)
  /// [difficulty] - Recipe difficulty (1-5)
  /// [rating] - Recipe rating (1-5)
  /// [desiredFrequency] - How often to cook this recipe
  static Future<Recipe> createComplexRecipe({
    required MockDatabaseHelper mockDb,
    required String name,
    List<ProteinType>? proteinTypes,
    int vegetableCount = 5,
    int otherCount = 3,
    int difficulty = 3,
    int? rating,
    FrequencyType desiredFrequency = FrequencyType.weekly,
  }) async {
    final recipeId = IdGenerator.generateId();
    final now = DateTime.now();

    // Create the recipe
    final recipe = Recipe(
      id: recipeId,
      name: name,
      desiredFrequency: desiredFrequency,
      createdAt: now,
      difficulty: difficulty,
      rating: rating ?? 3,
      prepTimeMinutes: 20,
      cookTimeMinutes: 40,
    );
    await mockDb.insertRecipe(recipe);

    // Add protein ingredients
    final proteinIngredients = <Ingredient>[];
    if (proteinTypes != null && proteinTypes.isNotEmpty) {
      for (var i = 0; i < proteinTypes.length; i++) {
        final protein = Ingredient(
          id: IdGenerator.generateId(),
          name: '${proteinTypes[i].name.toLowerCase()}-$i',
          category: IngredientCategory.protein,
          unit: MeasurementUnit.gram,
          proteinType: proteinTypes[i],
        );
        proteinIngredients.add(protein);
        await mockDb.insertIngredient(protein);

        final recipeIngredient = RecipeIngredient(
          id: IdGenerator.generateId(),
          recipeId: recipeId,
          ingredientId: protein.id,
          quantity: 500,
        );
        await mockDb.addIngredientToRecipe(recipeIngredient);
      }

      // Update the protein types mapping in mock database
      mockDb.recipeProteinTypes[recipeId] = proteinTypes;
    }

    // Add vegetable ingredients
    for (var i = 0; i < vegetableCount; i++) {
      final vegetable = Ingredient(
        id: IdGenerator.generateId(),
        name: 'vegetable-$i',
        category: IngredientCategory.vegetable,
        unit: MeasurementUnit.gram,
        proteinType: null,
      );
      await mockDb.insertIngredient(vegetable);

      final recipeIngredient = RecipeIngredient(
        id: IdGenerator.generateId(),
        recipeId: recipeId,
        ingredientId: vegetable.id,
        quantity: 200,
      );
      await mockDb.addIngredientToRecipe(recipeIngredient);
    }

    // Add other ingredients (grains, seasonings, etc.)
    final otherCategories = [
      IngredientCategory.grain,
      IngredientCategory.seasoning,
      IngredientCategory.oil,
    ];

    for (var i = 0; i < otherCount; i++) {
      final category = otherCategories[i % otherCategories.length];
      final other = Ingredient(
        id: IdGenerator.generateId(),
        name: '${category.name.toLowerCase()}-$i',
        category: category,
        unit: MeasurementUnit.gram,
        proteinType: null,
      );
      await mockDb.insertIngredient(other);

      final recipeIngredient = RecipeIngredient(
        id: IdGenerator.generateId(),
        recipeId: recipeId,
        ingredientId: other.id,
        quantity: 50,
      );
      await mockDb.addIngredientToRecipe(recipeIngredient);
    }

    return recipe;
  }

  /// Creates a recipe with no protein ingredients (vegetarian/vegan).
  static Future<Recipe> createVegetarianRecipe({
    required MockDatabaseHelper mockDb,
    required String name,
    int ingredientCount = 10,
    FrequencyType desiredFrequency = FrequencyType.weekly,
  }) async {
    final recipeId = IdGenerator.generateId();
    final now = DateTime.now();

    final recipe = Recipe(
      id: recipeId,
      name: name,
      desiredFrequency: desiredFrequency,
      createdAt: now,
      difficulty: 2,
      rating: 4,
    );
    await mockDb.insertRecipe(recipe);

    // Add only non-protein ingredients
    for (var i = 0; i < ingredientCount; i++) {
      final ingredient = Ingredient(
        id: IdGenerator.generateId(),
        name: 'veggie-ingredient-$i',
        category: IngredientCategory.vegetable,
        unit: MeasurementUnit.gram,
        proteinType: null,
      );
      await mockDb.insertIngredient(ingredient);

      final recipeIngredient = RecipeIngredient(
        id: IdGenerator.generateId(),
        recipeId: recipeId,
        ingredientId: ingredient.id,
        quantity: 150,
      );
      await mockDb.addIngredientToRecipe(recipeIngredient);
    }

    // Ensure no protein types for this recipe
    mockDb.recipeProteinTypes[recipeId] = [];

    return recipe;
  }

  /// Creates a recipe with multiple identical protein types.
  ///
  /// Example: A recipe with both beef steak and ground beef.
  static Future<Recipe> createMultipleIdenticalProteinRecipe({
    required MockDatabaseHelper mockDb,
    required String name,
    required ProteinType proteinType,
    int proteinVariationCount = 3,
    int otherIngredientCount = 5,
  }) async {
    final recipeId = IdGenerator.generateId();
    final now = DateTime.now();

    final recipe = Recipe(
      id: recipeId,
      name: name,
      desiredFrequency: FrequencyType.weekly,
      createdAt: now,
      difficulty: 3,
      rating: 4,
    );
    await mockDb.insertRecipe(recipe);

    // Add multiple variations of the same protein type
    final proteinList = <ProteinType>[];
    for (var i = 0; i < proteinVariationCount; i++) {
      final protein = Ingredient(
        id: IdGenerator.generateId(),
        name: '${proteinType.name.toLowerCase()}-variation-$i',
        category: IngredientCategory.protein,
        unit: MeasurementUnit.gram,
        proteinType: proteinType,
      );
      await mockDb.insertIngredient(protein);

      final recipeIngredient = RecipeIngredient(
        id: IdGenerator.generateId(),
        recipeId: recipeId,
        ingredientId: protein.id,
        quantity: 200,
      );
      await mockDb.addIngredientToRecipe(recipeIngredient);

      proteinList.add(proteinType);
    }

    mockDb.recipeProteinTypes[recipeId] = proteinList;

    // Add other ingredients
    for (var i = 0; i < otherIngredientCount; i++) {
      final ingredient = Ingredient(
        id: IdGenerator.generateId(),
        name: 'ingredient-$i',
        category: IngredientCategory.vegetable,
        unit: MeasurementUnit.gram,
        proteinType: null,
      );
      await mockDb.insertIngredient(ingredient);

      final recipeIngredient = RecipeIngredient(
        id: IdGenerator.generateId(),
        recipeId: recipeId,
        ingredientId: ingredient.id,
        quantity: 100,
      );
      await mockDb.addIngredientToRecipe(recipeIngredient);
    }

    return recipe;
  }

  /// Creates a recipe with mixed protein categories (e.g., chicken + tofu).
  static Future<Recipe> createMixedProteinCategoryRecipe({
    required MockDatabaseHelper mockDb,
    required String name,
    required ProteinType mainProtein,
    required ProteinType plantProtein,
    int otherIngredientCount = 8,
  }) async {
    return createComplexRecipe(
      mockDb: mockDb,
      name: name,
      proteinTypes: [mainProtein, plantProtein],
      vegetableCount: otherIngredientCount ~/ 2,
      otherCount: otherIngredientCount - (otherIngredientCount ~/ 2),
    );
  }

  /// Creates a realistic meal history with specific protein types.
  ///
  /// [mockDb] - The mock database helper
  /// [recipes] - List of recipes to create meal history for
  /// [daysAgo] - How many days ago each meal was cooked (parallel to recipes list)
  static Future<List<Meal>> createMealHistory({
    required MockDatabaseHelper mockDb,
    required List<Recipe> recipes,
    required List<int> daysAgo,
  }) async {
    assert(recipes.length == daysAgo.length,
        'Recipes and daysAgo lists must have same length');

    final now = DateTime.now();
    final meals = <Meal>[];

    for (var i = 0; i < recipes.length; i++) {
      final cookedAt = now.subtract(Duration(days: daysAgo[i]));
      final meal = Meal(
        id: IdGenerator.generateId(),
        recipeId: recipes[i].id,
        cookedAt: cookedAt,
        servings: 2,
        notes: 'Test meal for ${recipes[i].name}',
        wasSuccessful: true,
      );
      await mockDb.insertMeal(meal);
      meals.add(meal);
    }

    return meals;
  }

  /// Creates a large dataset of recipes for performance testing.
  ///
  /// [mockDb] - The mock database helper
  /// [count] - Number of recipes to create
  /// [ingredientsPerRecipe] - Number of ingredients per recipe
  static Future<List<Recipe>> createLargeRecipeDataset({
    required MockDatabaseHelper mockDb,
    required int count,
    int ingredientsPerRecipe = 12,
  }) async {
    final recipes = <Recipe>[];
    final proteinTypesList = ProteinType.values;

    for (var i = 0; i < count; i++) {
      // Vary protein types across recipes
      final proteinType = proteinTypesList[i % proteinTypesList.length];

      final recipe = await createComplexRecipe(
        mockDb: mockDb,
        name: 'Recipe $i',
        proteinTypes: [proteinType],
        vegetableCount: ingredientsPerRecipe ~/ 2,
        otherCount: ingredientsPerRecipe - (ingredientsPerRecipe ~/ 2) - 1,
        difficulty: (i % 5) + 1,
        rating: ((i % 5) + 1),
        desiredFrequency: FrequencyType.values[i % FrequencyType.values.length],
      );

      recipes.add(recipe);
    }

    return recipes;
  }

  /// Creates a recommendation context map for testing.
  ///
  /// This helper builds the context map that recommendation factors expect.
  static Map<String, dynamic> createRecommendationContext({
    required MockDatabaseHelper mockDb,
    List<Map<String, dynamic>>? recentMeals,
    Map<String, DateTime>? lastCooked,
    Map<String, int>? mealCounts,
  }) {
    // Convert List<ProteinType> to Set<ProteinType> for protein rotation factor
    final proteinTypesMap = <String, Set<ProteinType>>{};
    for (final entry in mockDb.recipeProteinTypes.entries) {
      proteinTypesMap[entry.key] = entry.value.toSet();
    }

    return {
      'proteinTypes': proteinTypesMap,
      'recentMeals': recentMeals ?? [],
      'lastCooked': lastCooked ?? {},
      'mealCounts': mealCounts ?? {},
      'feedbackHistory': <String, List<Map<String, dynamic>>>{},
    };
  }
}
