// test/database/database_helper_meal_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gastrobrain/database/database_helper.dart';
import 'package:gastrobrain/models/meal.dart';
import 'package:gastrobrain/models/meal_recipe.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/utils/id_generator.dart';

void main() {
  // Initialize FFI
  sqfliteFfiInit();

  // Set the database factory to use the FFI implementation
  databaseFactory = databaseFactoryFfi;

  group('DatabaseHelper Meal Integration Tests', () {
    late DatabaseHelper dbHelper;
    late String testRecipeId1;
    late String testRecipeId2;

    setUpAll(() async {
      dbHelper = DatabaseHelper();

      // Reset the database to a clean state
      await dbHelper.resetDatabaseForTests();

      // Create test recipes for reference
      testRecipeId1 = IdGenerator.generateId();
      testRecipeId2 = IdGenerator.generateId();

      final recipes = [
        Recipe(
          id: testRecipeId1,
          name: 'Test Recipe 1',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
        ),
        Recipe(
          id: testRecipeId2,
          name: 'Test Recipe 2',
          desiredFrequency: FrequencyType.monthly,
          createdAt: DateTime.now(),
        ),
      ];

      // Insert test recipes
      for (var recipe in recipes) {
        await dbHelper.insertRecipe(recipe);
      }
    });

    test('can insert and retrieve a meal with null recipeId', () async {
      // Create a meal with null recipeId (new approach using junction table)
      final mealId = IdGenerator.generateId();
      final meal = Meal(
        id: mealId,
        recipeId: null, // Now nullable
        cookedAt: DateTime.now(),
        servings: 2,
        notes: 'Test notes',
        wasSuccessful: true,
        actualPrepTime: 10.0,
        actualCookTime: 20.0,
      );

      // Insert the meal
      await dbHelper.insertMeal(meal);

      // Create and insert a meal-recipe association
      final mealRecipe = MealRecipe(
        mealId: mealId,
        recipeId: testRecipeId1,
        isPrimaryDish: true,
      );

      await dbHelper.insertMealRecipe(mealRecipe);

      // Retrieve the meal
      final retrievedMeal = await dbHelper.getMeal(mealId);

      // Verify meal was correctly stored with null recipeId
      expect(retrievedMeal, isNotNull);
      expect(retrievedMeal!.id, mealId);
      expect(retrievedMeal.recipeId, isNull);
      expect(retrievedMeal.servings, 2);
      expect(retrievedMeal.notes, 'Test notes');
      expect(retrievedMeal.wasSuccessful, true);
      expect(retrievedMeal.actualPrepTime, 10.0);
      expect(retrievedMeal.actualCookTime, 20.0);

      // Verify we can get meal recipes
      final mealRecipes = await dbHelper.getMealRecipesForMeal(mealId);
      expect(mealRecipes.length, 1);
      expect(mealRecipes[0].recipeId, testRecipeId1);
      expect(mealRecipes[0].isPrimaryDish, true);
    });

    test('can handle multiple recipes per meal with junction table', () async {
      // Create a meal with null recipeId
      final mealId = IdGenerator.generateId();
      final meal = Meal(
        id: mealId,
        recipeId: null,
        cookedAt: DateTime.now(),
        servings: 4,
        notes: 'Multiple recipes test',
      );

      // Insert the meal
      await dbHelper.insertMeal(meal);

      // Create and insert multiple meal-recipe associations
      final mainDish = MealRecipe(
        mealId: mealId,
        recipeId: testRecipeId1,
        isPrimaryDish: true,
        notes: 'Main dish',
      );

      final sideDish = MealRecipe(
        mealId: mealId,
        recipeId: testRecipeId2,
        isPrimaryDish: false,
        notes: 'Side dish',
      );

      await dbHelper.insertMealRecipe(mainDish);
      await dbHelper.insertMealRecipe(sideDish);

      // Retrieve the meal recipes
      final mealRecipes = await dbHelper.getMealRecipesForMeal(mealId);

      // Verify we have both recipes associated with the meal
      expect(mealRecipes.length, 2);

      // Verify we can find the main dish
      final mainDishes = mealRecipes.where((r) => r.isPrimaryDish).toList();
      expect(mainDishes.length, 1);
      expect(mainDishes[0].recipeId, testRecipeId1);
      expect(mainDishes[0].notes, 'Main dish');

      // Verify we can find the side dish
      final sideDishes = mealRecipes.where((r) => !r.isPrimaryDish).toList();
      expect(sideDishes.length, 1);
      expect(sideDishes[0].recipeId, testRecipeId2);
      expect(sideDishes[0].notes, 'Side dish');
    });

    test('can find meals for a recipe through junction table', () async {
      // Create a meal with null recipeId
      final mealId = IdGenerator.generateId();
      final meal = Meal(
        id: mealId,
        recipeId: null,
        cookedAt: DateTime.now(),
        servings: 3,
        notes: 'Junction table lookup test',
      );

      // Insert the meal
      await dbHelper.insertMeal(meal);

      // Associate with a recipe through junction table
      final mealRecipe = MealRecipe(
        mealId: mealId,
        recipeId: testRecipeId1,
        isPrimaryDish: true,
      );

      await dbHelper.insertMealRecipe(mealRecipe);

      // Use the getMealsForRecipe method to find meals by recipe
      final meals = await dbHelper.getMealsForRecipe(testRecipeId1);

      // Verify we can find the meal through the junction table
      expect(meals.isNotEmpty, true);
      expect(meals.any((m) => m.id == mealId), true);

      // For the found meal, verify properties
      final foundMeal = meals.firstWhere((m) => m.id == mealId);
      expect(foundMeal.notes, 'Junction table lookup test');
      expect(foundMeal.servings, 3);
    });

    test('supports backward compatibility with direct recipe_id reference',
        () async {
      // Create a meal with a direct recipe reference (legacy approach)
      final mealId = IdGenerator.generateId();
      final meal = Meal(
        id: mealId,
        recipeId: testRecipeId2, // Direct reference (not null)
        cookedAt: DateTime.now(),
        servings: 2,
        notes: 'Backward compatibility test',
      );

      // Insert the meal
      await dbHelper.insertMeal(meal);

      // Retrieve the meal
      final retrievedMeal = await dbHelper.getMeal(mealId);

      // Verify meal was correctly stored with direct recipe reference
      expect(retrievedMeal, isNotNull);
      expect(retrievedMeal!.recipeId, testRecipeId2);

      // Verify getMealsForRecipe can find it
      final meals = await dbHelper.getMealsForRecipe(testRecipeId2);
      expect(meals.any((m) => m.id == mealId), true);
    });

    test('can update a meal with null recipeId', () async {
      // Create a meal with null recipeId
      final mealId = IdGenerator.generateId();
      final initialMeal = Meal(
        id: mealId,
        recipeId: null,
        cookedAt: DateTime.now(),
        servings: 2,
        notes: 'Initial notes',
        wasSuccessful: true,
      );

      // Insert the meal
      await dbHelper.insertMeal(initialMeal);

      // Update the meal
      final updatedMeal = Meal(
        id: mealId,
        recipeId: null, // Still null
        cookedAt: initialMeal.cookedAt,
        servings: 4, // Changed
        notes: 'Updated notes', // Changed
        wasSuccessful: false, // Changed
        actualPrepTime: 15.0,
        actualCookTime: 25.0,
      );

      await dbHelper.updateMeal(updatedMeal);

      // Retrieve the meal
      final retrievedMeal = await dbHelper.getMeal(mealId);

      // Verify meal was correctly updated while keeping recipeId null
      expect(retrievedMeal, isNotNull);
      expect(retrievedMeal!.recipeId, isNull);
      expect(retrievedMeal.servings, 4);
      expect(retrievedMeal.notes, 'Updated notes');
      expect(retrievedMeal.wasSuccessful, false);
      expect(retrievedMeal.actualPrepTime, 15.0);
      expect(retrievedMeal.actualCookTime, 25.0);
    });

    test('can delete a meal with junction records', () async {
      // Create a meal with null recipeId
      final mealId = IdGenerator.generateId();
      final meal = Meal(
        id: mealId,
        recipeId: null,
        cookedAt: DateTime.now(),
        servings: 2,
      );

      // Insert the meal
      await dbHelper.insertMeal(meal);

      // Create and insert a meal-recipe association
      final mealRecipe = MealRecipe(
        mealId: mealId,
        recipeId: testRecipeId1,
        isPrimaryDish: true,
      );

      await dbHelper.insertMealRecipe(mealRecipe);

      // Verify meal and junction record exist
      final retrievedMeal = await dbHelper.getMeal(mealId);
      expect(retrievedMeal, isNotNull);

      final mealRecipes = await dbHelper.getMealRecipesForMeal(mealId);
      expect(mealRecipes.length, 1);

      // Delete the meal
      await dbHelper.deleteMeal(mealId);

      // Verify meal is deleted
      final deletedMeal = await dbHelper.getMeal(mealId);
      expect(deletedMeal, isNull);

      // Verify junction records are cascaded (deleted)
      final db = await dbHelper.database;
      final junctionRecords = await db.query(
        'meal_recipes',
        where: 'meal_id = ?',
        whereArgs: [mealId],
      );
      expect(junctionRecords.isEmpty, true);
    });
  });
}
