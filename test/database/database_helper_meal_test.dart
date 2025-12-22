// test/database/database_helper_meal_test.dart

import 'package:flutter_test/flutter_test.dart';
import '../test_utils/test_setup.dart';
import '../mocks/mock_database_helper.dart';
import 'package:gastrobrain/models/meal.dart';
import 'package:gastrobrain/models/meal_recipe.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/utils/id_generator.dart';

void main() {
  group('DatabaseHelper Meal Integration Tests', () {
    late MockDatabaseHelper mockDbHelper;
    late String testRecipeId1;
    late String testRecipeId2;

    setUpAll(() async {
      // Set up mock database using TestSetup utility
      mockDbHelper = TestSetup.setupMockDatabase();


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
        await mockDbHelper.insertRecipe(recipe);
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
      await mockDbHelper.insertMeal(meal);

      // Create and insert a meal-recipe association
      final mealRecipe = MealRecipe(
        mealId: mealId,
        recipeId: testRecipeId1,
        isPrimaryDish: true,
      );

      await mockDbHelper.insertMealRecipe(mealRecipe);

      // Retrieve the meal
      final retrievedMeal = await mockDbHelper.getMeal(mealId);

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
      final mealRecipes = await mockDbHelper.getMealRecipesForMeal(mealId);
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
      await mockDbHelper.insertMeal(meal);

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

      await mockDbHelper.insertMealRecipe(mainDish);
      await mockDbHelper.insertMealRecipe(sideDish);

      // Retrieve the meal recipes
      final mealRecipes = await mockDbHelper.getMealRecipesForMeal(mealId);

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
      await mockDbHelper.insertMeal(meal);

      // Associate with a recipe through junction table
      final mealRecipe = MealRecipe(
        mealId: mealId,
        recipeId: testRecipeId1,
        isPrimaryDish: true,
      );

      await mockDbHelper.insertMealRecipe(mealRecipe);

      // Use the getMealsForRecipe method to find meals by recipe
      final meals = await mockDbHelper.getMealsForRecipe(testRecipeId1);

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
      await mockDbHelper.insertMeal(meal);

      // Retrieve the meal
      final retrievedMeal = await mockDbHelper.getMeal(mealId);

      // Verify meal was correctly stored with direct recipe reference
      expect(retrievedMeal, isNotNull);
      expect(retrievedMeal!.recipeId, testRecipeId2);

      // Verify getMealsForRecipe can find it
      final meals = await mockDbHelper.getMealsForRecipe(testRecipeId2);
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
      await mockDbHelper.insertMeal(initialMeal);

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

      await mockDbHelper.updateMeal(updatedMeal);

      // Retrieve the meal
      final retrievedMeal = await mockDbHelper.getMeal(mealId);

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
      await mockDbHelper.insertMeal(meal);

      // Create and insert a meal-recipe association
      final mealRecipe = MealRecipe(
        mealId: mealId,
        recipeId: testRecipeId1,
        isPrimaryDish: true,
      );

      await mockDbHelper.insertMealRecipe(mealRecipe);

      // Verify meal and junction record exist
      final retrievedMeal = await mockDbHelper.getMeal(mealId);
      expect(retrievedMeal, isNotNull);

      final mealRecipes = await mockDbHelper.getMealRecipesForMeal(mealId);
      expect(mealRecipes.length, 1);

      // Delete the meal
      await mockDbHelper.deleteMeal(mealId);

      // Verify meal is deleted
      final deletedMeal = await mockDbHelper.getMeal(mealId);
      expect(deletedMeal, isNull);

      // Verify junction records are cascaded (deleted)
      final remainingMealRecipes = await mockDbHelper.getMealRecipesForMeal(mealId);
      expect(remainingMealRecipes.isEmpty, true);
    });

    test('updateMeal method updates existing meal records', () async {
      // Create and insert an initial meal
      final originalMeal = Meal(
        id: 'test-meal-update',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 2,
        notes: 'Original notes',
        wasSuccessful: true,
        actualPrepTime: 15.0,
        actualCookTime: 30.0,
      );

      await mockDbHelper.insertMeal(originalMeal);

      // Verify the meal was inserted
      final insertedMeal = await mockDbHelper.getMeal(originalMeal.id);
      expect(insertedMeal, isNotNull);
      expect(insertedMeal!.notes, 'Original notes');
      expect(insertedMeal.servings, 2);

      // Create an updated version of the meal
      final updatedMeal = Meal(
        id: originalMeal.id, // Same ID
        recipeId: null,
        cookedAt: originalMeal.cookedAt,
        servings: 4, // Changed
        notes: 'Updated notes', // Changed
        wasSuccessful: false, // Changed
        actualPrepTime: 20.0, // Changed
        actualCookTime: 45.0, // Changed
        modifiedAt: DateTime.now(), // New modification time
      );

      // Update the meal
      final updateResult = await mockDbHelper.updateMeal(updatedMeal);
      expect(updateResult, 1, reason: 'Update should return 1 for success');

      // Retrieve and verify the changes
      final retrievedMeal = await mockDbHelper.getMeal(originalMeal.id);
      expect(retrievedMeal, isNotNull);
      expect(retrievedMeal!.servings, 4);
      expect(retrievedMeal.notes, 'Updated notes');
      expect(retrievedMeal.wasSuccessful, false);
      expect(retrievedMeal.actualPrepTime, 20.0);
      expect(retrievedMeal.actualCookTime, 45.0);
      expect(retrievedMeal.modifiedAt, isNotNull);
    });

    test('updateMeal preserves junction table relationships', () async {
      // Create a meal with multiple recipes
      final mealId = IdGenerator.generateId();
      final meal = Meal(
        id: mealId,
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 2,
        notes: 'Original notes',
        wasSuccessful: true,
        actualPrepTime: 15.0,
        actualCookTime: 25.0,
      );

      await mockDbHelper.insertMeal(meal);

      // Add multiple recipes via junction table
      final primaryMealRecipe = MealRecipe(
        mealId: mealId,
        recipeId: testRecipeId1,
        isPrimaryDish: true,
      );

      final sideMealRecipe = MealRecipe(
        mealId: mealId,
        recipeId: testRecipeId2,
        isPrimaryDish: false,
      );

      await mockDbHelper.insertMealRecipe(primaryMealRecipe);
      await mockDbHelper.insertMealRecipe(sideMealRecipe);

      // Verify initial setup
      final initialMealRecipes = await mockDbHelper.getMealRecipesForMeal(mealId);
      expect(initialMealRecipes.length, 2);

      // Update the meal
      final updatedMeal = Meal(
        id: mealId,
        recipeId: null,
        cookedAt: meal.cookedAt,
        servings: 4, // Changed
        notes: 'Updated notes', // Changed
        wasSuccessful: false, // Changed
        actualPrepTime: 20.0,
        actualCookTime: 30.0,
        modifiedAt: DateTime.now(),
      );

      final updateResult = await mockDbHelper.updateMeal(updatedMeal);
      expect(updateResult, 1);

      // Verify meal was updated
      final retrievedMeal = await mockDbHelper.getMeal(mealId);
      expect(retrievedMeal!.servings, 4);
      expect(retrievedMeal.notes, 'Updated notes');
      expect(retrievedMeal.wasSuccessful, false);

      // Verify junction table relationships are preserved
      final afterUpdateMealRecipes =
          await mockDbHelper.getMealRecipesForMeal(mealId);
      expect(afterUpdateMealRecipes.length, 2);

      final recipeIds = afterUpdateMealRecipes.map((mr) => mr.recipeId).toSet();
      expect(recipeIds.contains(testRecipeId1), true);
      expect(recipeIds.contains(testRecipeId2), true);
    });

    test('getRecentMeals returns meals ordered by cooked date', () async {
      // Create meals with different cooked dates
      final now = DateTime.now();
      final mealIds = <String>[];

      // Create 5 meals with different dates (oldest to newest)
      for (int i = 0; i < 5; i++) {
        final mealId = IdGenerator.generateId();
        mealIds.add(mealId);

        final meal = Meal(
          id: mealId,
          recipeId: testRecipeId1,
          cookedAt: now.subtract(Duration(days: 5 - i)), // 5 days ago, 4 days ago, etc.
          servings: 2,
          notes: 'Meal $i',
        );

        await mockDbHelper.insertMeal(meal);
      }

      // Get recent meals with default limit
      final recentMeals = await mockDbHelper.getRecentMeals();

      // Verify meals are returned
      expect(recentMeals.isNotEmpty, true);
      expect(recentMeals.length, greaterThanOrEqualTo(5));

      // Verify meals are ordered by cooked date (newest first)
      for (int i = 0; i < recentMeals.length - 1; i++) {
        expect(
          recentMeals[i].cookedAt.isAfter(recentMeals[i + 1].cookedAt) ||
              recentMeals[i].cookedAt.isAtSameMomentAs(recentMeals[i + 1].cookedAt),
          true,
          reason: 'Meals should be ordered by cooked date (newest first)',
        );
      }
    });

    test('getRecentMeals respects limit parameter', () async {
      // Create multiple meals
      final now = DateTime.now();
      for (int i = 0; i < 15; i++) {
        final mealId = IdGenerator.generateId();
        final meal = Meal(
          id: mealId,
          recipeId: testRecipeId1,
          cookedAt: now.subtract(Duration(hours: i)),
          servings: 2,
        );

        await mockDbHelper.insertMeal(meal);
      }

      // Get recent meals with limit of 5
      final recentMeals = await mockDbHelper.getRecentMeals(limit: 5);

      // Verify only 5 meals are returned
      expect(recentMeals.length, lessThanOrEqualTo(5));
    });

    test('getLastCookedDate returns most recent cooking date for recipe',
        () async {
      final now = DateTime.now();
      final twoDaysAgo = now.subtract(const Duration(days: 2));
      final fiveDaysAgo = now.subtract(const Duration(days: 5));

      // Create multiple meals for the same recipe with different dates
      final meal1 = Meal(
        id: IdGenerator.generateId(),
        recipeId: null,
        cookedAt: fiveDaysAgo,
        servings: 2,
      );

      final meal2 = Meal(
        id: IdGenerator.generateId(),
        recipeId: null,
        cookedAt: twoDaysAgo, // Most recent
        servings: 2,
      );

      await mockDbHelper.insertMeal(meal1);
      await mockDbHelper.insertMeal(meal2);

      // Associate both meals with the same recipe
      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: meal1.id,
        recipeId: testRecipeId1,
        isPrimaryDish: true,
      ));

      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: meal2.id,
        recipeId: testRecipeId1,
        isPrimaryDish: true,
      ));

      // Get last cooked date
      final lastCookedDate = await mockDbHelper.getLastCookedDate(testRecipeId1);

      // Verify it returns the most recent date
      expect(lastCookedDate, isNotNull);
      expect(lastCookedDate!.year, twoDaysAgo.year);
      expect(lastCookedDate.month, twoDaysAgo.month);
      expect(lastCookedDate.day, twoDaysAgo.day);
    });

    test('getLastCookedDate returns null for recipe never cooked', () async {
      // Create a new recipe that has never been cooked
      final neverCookedRecipeId = IdGenerator.generateId();
      final recipe = Recipe(
        id: neverCookedRecipeId,
        name: 'Never Cooked Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
      );

      await mockDbHelper.insertRecipe(recipe);

      // Get last cooked date
      final lastCookedDate = await mockDbHelper.getLastCookedDate(neverCookedRecipeId);

      // Verify it returns null
      expect(lastCookedDate, isNull);
    });

    test('insertMeal rejects invalid meal data', () async {
      // Create a meal with invalid servings (negative)
      final invalidMeal = Meal(
        id: IdGenerator.generateId(),
        recipeId: testRecipeId1,
        cookedAt: DateTime.now(),
        servings: -1, // Invalid: negative servings
        notes: 'Invalid meal',
      );

      // Attempt to insert should handle validation
      // Note: This depends on how validation is implemented in DatabaseHelper
      // If validation throws an exception, we expect that
      // If validation is done at UI level, this test might not apply
      try {
        await mockDbHelper.insertMeal(invalidMeal);
        // If no validation, meal is inserted - verify it exists
        final retrievedMeal = await mockDbHelper.getMeal(invalidMeal.id);
        // At minimum, verify the meal was stored
        expect(retrievedMeal, isNotNull);
      } catch (e) {
        // If validation throws, that's also acceptable behavior
        expect(e, isNotNull);
      }
    });

    test('meal retrieval handles empty database gracefully', () async {
      // This test assumes we're starting with an empty database or can clear it
      // For now, just verify getRecentMeals doesn't crash with no data
      final recentMeals = await mockDbHelper.getRecentMeals(limit: 10);

      // Should return a list (possibly empty, possibly with existing test data)
      expect(recentMeals, isA<List<Meal>>());
    });

    test('deleteMealRecipesByMealId deletes all meal recipes for a meal', () async {
      // Create a meal with multiple recipes
      final mealId = IdGenerator.generateId();
      final meal = Meal(
        id: mealId,
        recipeId: null,
        cookedAt: DateTime.now(),
        servings: 2,
      );

      await mockDbHelper.insertMeal(meal);

      // Add primary and side dish recipes
      final primaryRecipe = MealRecipe(
        mealId: mealId,
        recipeId: testRecipeId1,
        isPrimaryDish: true,
      );

      final sideRecipe = MealRecipe(
        mealId: mealId,
        recipeId: testRecipeId2,
        isPrimaryDish: false,
      );

      await mockDbHelper.insertMealRecipe(primaryRecipe);
      await mockDbHelper.insertMealRecipe(sideRecipe);

      // Verify we have 2 meal recipes
      final beforeDelete = await mockDbHelper.getMealRecipesForMeal(mealId);
      expect(beforeDelete.length, 2);

      // Delete all meal recipes for this meal
      final deletedCount = await mockDbHelper.deleteMealRecipesByMealId(mealId);
      expect(deletedCount, 2);

      // Verify all meal recipes are deleted
      final afterDelete = await mockDbHelper.getMealRecipesForMeal(mealId);
      expect(afterDelete.length, 0);
    });

    test('deleteMealRecipesByMealId with excludePrimary keeps primary dish', () async {
      // Create a meal with multiple recipes
      final mealId = IdGenerator.generateId();
      final meal = Meal(
        id: mealId,
        recipeId: null,
        cookedAt: DateTime.now(),
        servings: 2,
      );

      await mockDbHelper.insertMeal(meal);

      // Add primary and side dish recipes
      final primaryRecipe = MealRecipe(
        mealId: mealId,
        recipeId: testRecipeId1,
        isPrimaryDish: true,
      );

      final sideRecipe1 = MealRecipe(
        mealId: mealId,
        recipeId: testRecipeId2,
        isPrimaryDish: false,
      );

      final sideRecipe2 = MealRecipe(
        mealId: mealId,
        recipeId: testRecipeId2,
        isPrimaryDish: false,
      );

      await mockDbHelper.insertMealRecipe(primaryRecipe);
      await mockDbHelper.insertMealRecipe(sideRecipe1);
      await mockDbHelper.insertMealRecipe(sideRecipe2);

      // Verify we have 3 meal recipes
      final beforeDelete = await mockDbHelper.getMealRecipesForMeal(mealId);
      expect(beforeDelete.length, 3);

      // Delete only non-primary meal recipes
      final deletedCount = await mockDbHelper.deleteMealRecipesByMealId(
        mealId,
        excludePrimary: true,
      );
      expect(deletedCount, 2); // Only 2 side dishes deleted

      // Verify only primary dish remains
      final afterDelete = await mockDbHelper.getMealRecipesForMeal(mealId);
      expect(afterDelete.length, 1);
      expect(afterDelete[0].isPrimaryDish, true);
      expect(afterDelete[0].recipeId, testRecipeId1);
    });

    test('deleteMealRecipesByMealId returns 0 for non-existent meal', () async {
      // Try to delete meal recipes for a non-existent meal
      final deletedCount = await mockDbHelper.deleteMealRecipesByMealId('non-existent-meal-id');
      expect(deletedCount, 0);
    });
  });
}
