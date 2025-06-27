// integration_test/edit_meal_flow_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gastrobrain/database/database_helper.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/meal.dart';
import 'package:gastrobrain/models/meal_recipe.dart';
import 'package:gastrobrain/models/meal_plan.dart';
import 'package:gastrobrain/models/meal_plan_item.dart';
import 'package:gastrobrain/models/meal_plan_item_recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/utils/id_generator.dart';
import 'package:gastrobrain/core/di/service_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Edit Meal - Core Functionality', () {
    late DatabaseHelper dbHelper;
    final testRecipeIds = <String>[];
    final testMealIds = <String>[];
    final testMealPlanIds = <String>[];

    setUpAll(() async {
      // Set up database using ServiceProvider pattern
      dbHelper = DatabaseHelper();
      
      // Inject the test database helper into ServiceProvider
      ServiceProvider.database.setDatabaseHelper(dbHelper);

      // Create test recipes for our meal editing tests
      final recipes = [
        Recipe(
          id: IdGenerator.generateId(),
          name: 'Primary Test Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          prepTimeMinutes: 20,
          cookTimeMinutes: 30,
          difficulty: 3,
          rating: 4,
        ),
        Recipe(
          id: IdGenerator.generateId(),
          name: 'Side Dish Recipe 1',
          desiredFrequency: FrequencyType.monthly,
          createdAt: DateTime.now(),
          prepTimeMinutes: 10,
          cookTimeMinutes: 15,
          difficulty: 2,
          rating: 3,
        ),
        Recipe(
          id: IdGenerator.generateId(),
          name: 'Side Dish Recipe 2',
          desiredFrequency: FrequencyType.biweekly,
          createdAt: DateTime.now(),
          prepTimeMinutes: 15,
          cookTimeMinutes: 20,
          difficulty: 2,
          rating: 4,
        ),
      ];

      // Insert all test recipes
      for (final recipe in recipes) {
        await dbHelper.insertRecipe(recipe);
        testRecipeIds.add(recipe.id);
      }
    });

    // Add cleanup after each individual test
    tearDown(() async {
      // Clean up meals created in this test
      for (final mealId in testMealIds.toList()) {
        try {
          await dbHelper.deleteMeal(mealId);
          testMealIds.remove(mealId);
        } catch (e) {
          // Ignore cleanup errors
        }
      }

      // Clean up meal plans created in this test
      for (final planId in testMealPlanIds.toList()) {
        try {
          await dbHelper.deleteMealPlan(planId);
          testMealPlanIds.remove(planId);
        } catch (e) {
          // Ignore cleanup errors
        }
      }
    });

    tearDownAll(() async {
      // Clean up all test data
      for (final mealId in testMealIds) {
        try {
          await dbHelper.deleteMeal(mealId);
        } catch (e) {
          // Ignore cleanup errors
        }
      }

      for (final planId in testMealPlanIds) {
        try {
          await dbHelper.deleteMealPlan(planId);
        } catch (e) {
          // Ignore cleanup errors
        }
      }

      for (final recipeId in testRecipeIds) {
        try {
          await dbHelper.deleteRecipe(recipeId);
        } catch (e) {
          // Ignore cleanup errors
        }
      }
    });

    testWidgets('Database operations for editing cooked meals',
        (WidgetTester tester) async {
      // This test verifies the core database operations for editing meals
      // without any UI interaction

      final primaryRecipeId = testRecipeIds[0];
      final sideDish1Id = testRecipeIds[1];
      final sideDish2Id = testRecipeIds[2];


      // === PHASE 1: Create initial meal with single recipe ===

      final mealId = IdGenerator.generateId();
      testMealIds.add(mealId);

      final originalMeal = Meal(
        id: mealId,
        recipeId: null, // Using junction table approach
        cookedAt: DateTime.now().subtract(const Duration(hours: 2)),
        servings: 3,
        notes: 'Original meal notes',
        wasSuccessful: true,
        actualPrepTime: 25.0,
        actualCookTime: 35.0,
      );

      await dbHelper.insertMeal(originalMeal);

      // Add primary recipe association
      final primaryMealRecipe = MealRecipe(
        mealId: mealId,
        recipeId: primaryRecipeId,
        isPrimaryDish: true,
        notes: 'Main dish',
      );
      await dbHelper.insertMealRecipe(primaryMealRecipe);

      // Verify initial state
      final initialMeal = await dbHelper.getMeal(mealId);
      expect(initialMeal, isNotNull, reason: "Initial meal should exist");
      expect(initialMeal!.servings, 3, reason: "Initial servings should be 3");
      expect(initialMeal.notes, 'Original meal notes',
          reason: "Initial notes should match");

      final initialMealRecipes = await dbHelper.getMealRecipesForMeal(mealId);
      expect(initialMealRecipes.length, 1,
          reason: "Initial meal should have 1 recipe");

      // === PHASE 2: Edit meal basic properties ===

      // Simulate editing the meal (like what the EditMealRecordingDialog would do)
      final updatedCookedAt = DateTime.now().subtract(const Duration(hours: 1));
      final modifiedAt = DateTime.now();

      // Update meal properties
      final db = await dbHelper.database;
      await db.update(
        'meals',
        {
          'cooked_at': updatedCookedAt.toIso8601String(),
          'servings': 4, // Changed from 3 to 4
          'notes': 'Updated meal notes', // Changed notes
          'was_successful': 0, // Changed from successful to unsuccessful
          'actual_prep_time': 30.0, // Changed from 25.0
          'actual_cook_time': 40.0, // Changed from 35.0
          'modified_at':
              modifiedAt.toIso8601String(), // Added modification timestamp
        },
        where: 'id = ?',
        whereArgs: [mealId],
      );

      // Verify the basic properties were updated
      final updatedMeal = await dbHelper.getMeal(mealId);
      expect(updatedMeal, isNotNull, reason: "Updated meal should exist");
      expect(updatedMeal!.servings, 4,
          reason: "Servings should be updated to 4");
      expect(updatedMeal.notes, 'Updated meal notes',
          reason: "Notes should be updated");
      expect(updatedMeal.wasSuccessful, false,
          reason: "Success status should be updated to false");
      expect(updatedMeal.actualPrepTime, 30.0,
          reason: "Prep time should be updated");
      expect(updatedMeal.actualCookTime, 40.0,
          reason: "Cook time should be updated");
      expect(updatedMeal.modifiedAt, isNotNull,
          reason: "Modified timestamp should be set");

      // Verify meal recipes are unchanged so far
      final mealRecipesAfterBasicUpdate =
          await dbHelper.getMealRecipesForMeal(mealId);
      expect(mealRecipesAfterBasicUpdate.length, 1,
          reason: "Should still have 1 recipe after basic update");

      // === PHASE 3: Add side dishes (simulating recipe management) ===

      // Add first side dish
      final sideDish1MealRecipe = MealRecipe(
        mealId: mealId,
        recipeId: sideDish1Id,
        isPrimaryDish: false,
        notes: 'Side dish 1',
      );
      await dbHelper.insertMealRecipe(sideDish1MealRecipe);

      // Add second side dish
      final sideDish2MealRecipe = MealRecipe(
        mealId: mealId,
        recipeId: sideDish2Id,
        isPrimaryDish: false,
        notes: 'Side dish 2',
      );
      await dbHelper.insertMealRecipe(sideDish2MealRecipe);

      // Verify side dishes were added
      final mealRecipesWithSides = await dbHelper.getMealRecipesForMeal(mealId);
      expect(mealRecipesWithSides.length, 3,
          reason: "Should have 3 recipes (1 primary + 2 sides)");

      final primaryDishes =
          mealRecipesWithSides.where((mr) => mr.isPrimaryDish).toList();
      final sideDishes =
          mealRecipesWithSides.where((mr) => !mr.isPrimaryDish).toList();

      expect(primaryDishes.length, 1,
          reason: "Should have exactly 1 primary dish");
      expect(primaryDishes[0].recipeId, primaryRecipeId,
          reason: "Primary dish should be the original recipe");

      expect(sideDishes.length, 2, reason: "Should have exactly 2 side dishes");
      final sideRecipeIds = sideDishes.map((sd) => sd.recipeId).toSet();
      expect(sideRecipeIds.contains(sideDish1Id), true,
          reason: "Should contain first side dish");
      expect(sideRecipeIds.contains(sideDish2Id), true,
          reason: "Should contain second side dish");

      // === PHASE 4: Remove one side dish (simulating recipe removal) ===

      // Remove first side dish
      await db.delete(
        'meal_recipes',
        where: 'meal_id = ? AND recipe_id = ?',
        whereArgs: [mealId, sideDish1Id],
      );

      // Verify removal
      final mealRecipesAfterRemoval =
          await dbHelper.getMealRecipesForMeal(mealId);
      expect(mealRecipesAfterRemoval.length, 2,
          reason: "Should have 2 recipes after removing one side dish");

      final remainingPrimary =
          mealRecipesAfterRemoval.where((mr) => mr.isPrimaryDish).toList();
      final remainingSides =
          mealRecipesAfterRemoval.where((mr) => !mr.isPrimaryDish).toList();

      expect(remainingPrimary.length, 1,
          reason: "Should still have 1 primary dish");
      expect(remainingSides.length, 1,
          reason: "Should have 1 remaining side dish");
      expect(remainingSides[0].recipeId, sideDish2Id,
          reason: "Remaining side dish should be the second one");

      // === PHASE 5: Verify meal statistics are updated correctly ===

      // Check that recipe statistics include the edited meal
      final primaryRecipeMeals =
          await dbHelper.getMealsForRecipe(primaryRecipeId);
      expect(primaryRecipeMeals.length, 1,
          reason: "Primary recipe should appear in 1 meal");
      expect(primaryRecipeMeals[0].id, mealId,
          reason: "Primary recipe meal should be our edited meal");

      final sideDish2Meals = await dbHelper.getMealsForRecipe(sideDish2Id);
      expect(sideDish2Meals.length, 1,
          reason: "Remaining side dish should appear in 1 meal");

      final sideDish1Meals = await dbHelper.getMealsForRecipe(sideDish1Id);
      expect(sideDish1Meals.length, 0,
          reason: "Removed side dish should appear in 0 meals");

      // === PHASE 6: Verify updated meal can be retrieved correctly ===

      final finalMeal = await dbHelper.getMeal(mealId);
      expect(finalMeal, isNotNull, reason: "Final meal should exist");
      expect(finalMeal!.servings, 4, reason: "Final servings should be 4");
      expect(finalMeal.notes, 'Updated meal notes',
          reason: "Final notes should be updated");
      expect(finalMeal.wasSuccessful, false,
          reason: "Final success status should be false");
      expect(finalMeal.modifiedAt, isNotNull,
          reason: "Final meal should have modification timestamp");

      // Load associated recipes
      finalMeal.mealRecipes = await dbHelper.getMealRecipesForMeal(mealId);
      expect(finalMeal.mealRecipes!.length, 2,
          reason: "Final meal should have 2 associated recipes");
    });

    testWidgets('Edit meal integration with meal plan (Issue #99)',
        (WidgetTester tester) async {
      // This test verifies that editing a meal that came from a meal plan
      // works correctly and maintains the relationship

      final primaryRecipeId = testRecipeIds[0];


      // === SETUP: Create meal plan with cooked meal ===

      final weekStart = DateTime(2023, 12, 1); // A Friday
      final mealPlanId = IdGenerator.generateId();
      testMealPlanIds.add(mealPlanId);

      final mealPlan = MealPlan(
        id: mealPlanId,
        weekStartDate: weekStart,
        notes: 'Test meal plan',
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );

      await dbHelper.insertMealPlan(mealPlan);

      // Create meal plan item
      final planItemId = IdGenerator.generateId();
      final planItem = MealPlanItem(
        id: planItemId,
        mealPlanId: mealPlanId,
        plannedDate: MealPlanItem.formatPlannedDate(weekStart),
        mealType: MealPlanItem.lunch,
        hasBeenCooked: true, // Mark as cooked
      );

      await dbHelper.insertMealPlanItem(planItem);

      // Add recipe association to plan item
      final planItemRecipe = MealPlanItemRecipe(
        mealPlanItemId: planItemId,
        recipeId: primaryRecipeId,
        isPrimaryDish: true,
      );
      await dbHelper.insertMealPlanItemRecipe(planItemRecipe);

      // === CREATE CORRESPONDING MEAL RECORD ===

      final mealId = IdGenerator.generateId();
      testMealIds.add(mealId);

      final originalMeal = Meal(
        id: mealId,
        recipeId: null,
        cookedAt: weekStart
            .add(const Duration(hours: 12)), // Cooked on the planned day
        servings: 2,
        notes: 'Meal from plan',
        wasSuccessful: true,
        actualPrepTime: 20.0,
        actualCookTime: 30.0,
      );

      await dbHelper.insertMeal(originalMeal);

      // Add meal recipe association
      final mealRecipe = MealRecipe(
        mealId: mealId,
        recipeId: primaryRecipeId,
        isPrimaryDish: true,
        notes: 'From planned meal',
      );
      await dbHelper.insertMealRecipe(mealRecipe);

      // === VERIFY INITIAL STATE ===

      // Verify meal plan exists and is marked as cooked
      final retrievedPlan = await dbHelper.getMealPlanForWeek(weekStart);
      expect(retrievedPlan, isNotNull, reason: "Meal plan should exist");
      expect(retrievedPlan!.items.length, 1,
          reason: "Should have 1 meal plan item");
      expect(retrievedPlan.items[0].hasBeenCooked, true,
          reason: "Meal plan item should be marked as cooked");

      // Verify meal exists
      final retrievedMeal = await dbHelper.getMeal(mealId);
      expect(retrievedMeal, isNotNull, reason: "Meal should exist");
      expect(retrievedMeal!.servings, 2,
          reason: "Initial servings should be 2");

      // === EDIT THE MEAL ===

      // Simulate editing the meal (what EditMealRecordingDialog would do)
      final modifiedAt = DateTime.now();
      final db = await dbHelper.database;

      await db.update(
        'meals',
        {
          'servings': 4, // Changed from 2 to 4
          'notes': 'Edited meal from plan',
          'actual_prep_time': 25.0, // Changed from 20.0
          'actual_cook_time': 35.0, // Changed from 30.0
          'modified_at': modifiedAt.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [mealId],
      );

      // === VERIFY EDIT RESULTS ===

      // Verify meal was updated
      final editedMeal = await dbHelper.getMeal(mealId);
      expect(editedMeal, isNotNull, reason: "Edited meal should exist");
      expect(editedMeal!.servings, 4,
          reason: "Servings should be updated to 4");
      expect(editedMeal.notes, 'Edited meal from plan',
          reason: "Notes should be updated");
      expect(editedMeal.actualPrepTime, 25.0,
          reason: "Prep time should be updated");
      expect(editedMeal.actualCookTime, 35.0,
          reason: "Cook time should be updated");
      expect(editedMeal.modifiedAt, isNotNull,
          reason: "Modified timestamp should be set");

      // Verify meal plan is still intact
      final planAfterEdit = await dbHelper.getMealPlanForWeek(weekStart);
      expect(planAfterEdit, isNotNull, reason: "Meal plan should still exist");
      expect(planAfterEdit!.items.length, 1,
          reason: "Meal plan should still have 1 item");
      expect(planAfterEdit.items[0].hasBeenCooked, true,
          reason: "Meal plan item should still be marked as cooked");

      // Verify recipe statistics are correct
      final recipeMeals = await dbHelper.getMealsForRecipe(primaryRecipeId);

      expect(recipeMeals.length, 1,
          reason: "Recipe should appear in 1 meal (the edited one)");
      expect(recipeMeals[0].id, mealId,
          reason: "Recipe meal should be our edited meal");
      expect(recipeMeals[0].servings, 4,
          reason: "Recipe meal should have updated servings");
    });

    testWidgets('Verify modifiedAt timestamp is handled correctly',
        (WidgetTester tester) async {
      // This test specifically verifies the new modifiedAt field functionality

      final primaryRecipeId = testRecipeIds[0];


      // === CREATE MEAL WITHOUT MODIFIED TIMESTAMP ===

      final mealId = IdGenerator.generateId();
      testMealIds.add(mealId);

      final originalMeal = Meal(
        id: mealId,
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(hours: 1)),
        servings: 2,
        notes: 'Original notes',
        wasSuccessful: true,
        actualPrepTime: 15.0,
        actualCookTime: 25.0,
        // modifiedAt is null initially
      );

      await dbHelper.insertMeal(originalMeal);

      // Add recipe association
      final mealRecipe = MealRecipe(
        mealId: mealId,
        recipeId: primaryRecipeId,
        isPrimaryDish: true,
      );
      await dbHelper.insertMealRecipe(mealRecipe);

      // === VERIFY INITIAL STATE (NO MODIFIED TIMESTAMP) ===

      final initialMeal = await dbHelper.getMeal(mealId);
      expect(initialMeal, isNotNull, reason: "Initial meal should exist");
      expect(initialMeal!.modifiedAt, isNull,
          reason: "Initial meal should have null modifiedAt");

      // === EDIT MEAL AND ADD MODIFIED TIMESTAMP ===

      final modifiedAt = DateTime.now();
      final db = await dbHelper.database;

      await db.update(
        'meals',
        {
          'servings': 3, // Change servings
          'notes': 'Edited notes',
          'modified_at':
              modifiedAt.toIso8601String(), // Add modification timestamp
        },
        where: 'id = ?',
        whereArgs: [mealId],
      );

      // === VERIFY MODIFIED TIMESTAMP ===

      final editedMeal = await dbHelper.getMeal(mealId);
      expect(editedMeal, isNotNull, reason: "Edited meal should exist");
      expect(editedMeal!.modifiedAt, isNotNull,
          reason: "Edited meal should have modifiedAt timestamp");
      expect(editedMeal.servings, 3, reason: "Servings should be updated");
      expect(editedMeal.notes, 'Edited notes',
          reason: "Notes should be updated");

      // Verify the timestamp is approximately correct (within 1 minute)
      final timeDiff =
          editedMeal.modifiedAt!.difference(modifiedAt).inMinutes.abs();
      expect(timeDiff < 1, true,
          reason: "Modified timestamp should be approximately correct");

      // === EDIT AGAIN TO VERIFY TIMESTAMP UPDATE ===

      await Future.delayed(
          const Duration(milliseconds: 100)); // Ensure different timestamp
      final secondModifiedAt = DateTime.now();

      await db.update(
        'meals',
        {
          'servings': 4, // Change servings again
          'modified_at': secondModifiedAt.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [mealId],
      );

      // Verify second edit
      final secondEditedMeal = await dbHelper.getMeal(mealId);
      expect(secondEditedMeal, isNotNull,
          reason: "Second edited meal should exist");
      expect(secondEditedMeal!.servings, 4,
          reason: "Servings should be updated again");
      expect(secondEditedMeal.modifiedAt, isNotNull,
          reason: "Second edited meal should have updated modifiedAt");

      // Verify the timestamp was updated
      expect(secondEditedMeal.modifiedAt!.isAfter(editedMeal.modifiedAt!), true,
          reason: "Second modification timestamp should be later than first");
    });
  });
}
