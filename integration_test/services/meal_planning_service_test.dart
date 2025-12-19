import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/meal.dart';
import 'package:gastrobrain/models/meal_recipe.dart';
import 'package:gastrobrain/models/meal_plan.dart';
import 'package:gastrobrain/models/meal_plan_item.dart';
import 'package:gastrobrain/models/meal_plan_item_recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/utils/id_generator.dart';
import '../../test/test_utils/test_setup.dart';
import '../../test/mocks/mock_database_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Meal Planning - Core Functionality', () {
    late MockDatabaseHelper mockDbHelper;
    final testRecipeId = IdGenerator.generateId();
    final testRecipe2Id = IdGenerator.generateId();

    setUpAll(() async {
      // Set up mock database using TestSetup utility
      mockDbHelper = TestSetup.setupMockDatabase();

      // Create test recipes
      final recipe1 = Recipe(
        id: testRecipeId,
        name: 'Test Recipe For Planning',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
        prepTimeMinutes: 30,
        cookTimeMinutes: 45,
      );

      final recipe2 = Recipe(
        id: testRecipe2Id,
        name: 'Second Test Recipe',
        desiredFrequency: FrequencyType.monthly,
        createdAt: DateTime.now(),
        prepTimeMinutes: 15,
        cookTimeMinutes: 20,
      );

      await mockDbHelper.insertRecipe(recipe1);
      await mockDbHelper.insertRecipe(recipe2);
    });

    tearDownAll(() async {
      // Clean up using TestSetup utility
      TestSetup.cleanupMockDatabase(mockDbHelper);
    });

    testWidgets('Test database operations for meal plans',
        (WidgetTester tester) async {
      // This test doesn't interact with UI at all

      // Set up dates for testing
      final now = DateTime.now();
      final weekStart = DateTime(
        now.year,
        now.month,
        now.day - (now.weekday < 5 ? now.weekday + 2 : now.weekday - 5),
      );

      // 1. First get any existing meal plan and clean it up if needed
      final existingPlan = await mockDbHelper.getMealPlanForWeek(weekStart);
      if (existingPlan != null) {
        await mockDbHelper.deleteMealPlan(existingPlan.id);
      }

      // 2. Create meal plan with a fresh ID
      final mealPlanId = IdGenerator.generateId();
      final mealPlan = MealPlan(
        id: mealPlanId,
        weekStartDate: weekStart,
        notes: 'Database test plan',
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );
      await mockDbHelper.insertMealPlan(mealPlan);

      // Verify the plan was created
      final createdPlan = await mockDbHelper.getMealPlan(mealPlanId);
      expect(createdPlan, isNotNull);
      expect(createdPlan!.items.length, 0);

      // 3. Create and add meal items one at a time with verification
      // Friday lunch
      final fridayLunchId = IdGenerator.generateId();
      final fridayLunch = MealPlanItem(
        id: fridayLunchId,
        mealPlanId: mealPlanId,
        plannedDate: MealPlanItem.formatPlannedDate(weekStart),
        mealType: MealPlanItem.lunch,
      );
      await mockDbHelper.insertMealPlanItem(fridayLunch);

      // Verify first item was added
      final planWithLunch = await mockDbHelper.getMealPlan(mealPlanId);
      expect(planWithLunch!.items.length, 1);

      // Friday dinner
      final fridayDinnerId = IdGenerator.generateId();
      final fridayDinner = MealPlanItem(
        id: fridayDinnerId,
        mealPlanId: mealPlanId,
        plannedDate: MealPlanItem.formatPlannedDate(weekStart),
        mealType: MealPlanItem.dinner,
      );
      await mockDbHelper.insertMealPlanItem(fridayDinner);

      // Verify second item was added
      final planWithBothMeals = await mockDbHelper.getMealPlan(mealPlanId);
      expect(planWithBothMeals!.items.length, 2);

      // Add recipe associations
      await mockDbHelper.insertMealPlanItemRecipe(MealPlanItemRecipe(
        mealPlanItemId: fridayLunchId,
        recipeId: testRecipeId,
        isPrimaryDish: true,
      ));

      await mockDbHelper.insertMealPlanItemRecipe(MealPlanItemRecipe(
        mealPlanItemId: fridayDinnerId,
        recipeId: testRecipe2Id,
        isPrimaryDish: true,
      ));

      // 4. Final verification for all the data
      final savedPlan = await mockDbHelper.getMealPlanForWeek(weekStart);
      expect(savedPlan, isNotNull,
          reason: "No meal plan found for the current week");
      expect(savedPlan!.items.length, 2,
          reason: "Expected 2 items but found ${savedPlan.items.length}");

      final lunchItems = savedPlan.items
          .where((item) => item.mealType == MealPlanItem.lunch)
          .toList();
      expect(lunchItems.length, 1);

      final dinnerItems = savedPlan.items
          .where((item) => item.mealType == MealPlanItem.dinner)
          .toList();
      expect(dinnerItems.length, 1);

      // 4. Update plan by removing the dinner item
      await mockDbHelper.deleteMealPlanItem(fridayDinnerId);

      // 5. Verify update worked
      final updatedPlan = await mockDbHelper.getMealPlanForWeek(weekStart);
      expect(updatedPlan, isNotNull);
      expect(updatedPlan!.items.length, 1);
      expect(updatedPlan.items[0].mealType, MealPlanItem.lunch);

      // 6. Clean up
      await mockDbHelper.deleteMealPlan(mealPlanId);
    });

    testWidgets('Can add side dishes to an already cooked meal (Issue #104)',
        (WidgetTester tester) async {
      // This test covers the complete workflow for managing side dishes

      // === SETUP PHASE ===

      // Create test recipes - one primary and two side dishes
      final primaryRecipeId = IdGenerator.generateId();
      final sideDish1Id = IdGenerator.generateId();
      final sideDish2Id = IdGenerator.generateId();

      final primaryRecipe = Recipe(
        id: primaryRecipeId,
        name: 'Primary Test Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
        prepTimeMinutes: 30,
        cookTimeMinutes: 45,
      );

      final sideDish1 = Recipe(
        id: sideDish1Id,
        name: 'Side Dish 1',
        desiredFrequency: FrequencyType.monthly,
        createdAt: DateTime.now(),
        prepTimeMinutes: 15,
        cookTimeMinutes: 20,
      );

      final sideDish2 = Recipe(
        id: sideDish2Id,
        name: 'Side Dish 2',
        desiredFrequency: FrequencyType.biweekly,
        createdAt: DateTime.now(),
        prepTimeMinutes: 10,
        cookTimeMinutes: 15,
      );

      // Insert all recipes into database
      await mockDbHelper.insertRecipe(primaryRecipe);
      await mockDbHelper.insertRecipe(sideDish1);
      await mockDbHelper.insertRecipe(sideDish2);

      // === PHASE 1: Create and cook initial meal ===

      // Create a meal with just the primary recipe (simulating initial cooking)
      final mealId = IdGenerator.generateId();
      final originalMeal = Meal(
        id: mealId,
        recipeId: null, // Using junction table approach
        cookedAt: DateTime.now()
            .subtract(const Duration(hours: 1)), // Cooked 1 hour ago
        servings: 2,
        notes: 'Original meal notes',
        wasSuccessful: true,
        actualPrepTime: 30.0,
        actualCookTime: 45.0,
      );

      // Insert the meal
      await mockDbHelper.insertMeal(originalMeal);

      // Create junction record for primary recipe
      final primaryMealRecipe = MealRecipe(
        mealId: mealId,
        recipeId: primaryRecipeId,
        isPrimaryDish: true,
        notes: 'Main dish',
      );
      await mockDbHelper.insertMealRecipe(primaryMealRecipe);

      // === VERIFICATION PHASE 1: Initial state ===

      // Verify initial meal has only one recipe
      final initialMeal = await mockDbHelper.getMeal(mealId);
      expect(initialMeal, isNotNull, reason: "Initial meal should exist");

      final initialMealRecipes = await mockDbHelper.getMealRecipesForMeal(mealId);
      expect(initialMealRecipes.length, 1,
          reason: "Initial meal should have 1 recipe");
      expect(initialMealRecipes[0].recipeId, primaryRecipeId,
          reason: "Initial recipe should be the primary recipe");
      expect(initialMealRecipes[0].isPrimaryDish, true,
          reason: "Initial recipe should be marked as primary");

      // === PHASE 2: Add first side dish ===

      // Simulate adding a side dish using the database operations
      // (This simulates what would happen when user uses "Manage Side Dishes")
      final sideDish1MealRecipeId = await mockDbHelper
          .addRecipeToMeal(mealId, sideDish1Id, isPrimaryDish: false);

      expect(sideDish1MealRecipeId.isNotEmpty, true,
          reason: "Adding side dish should return a valid ID");

      // === VERIFICATION PHASE 2: After adding first side dish ===

      // Verify meal now has two recipes
      final mealWith1SideDish = await mockDbHelper.getMeal(mealId);
      expect(mealWith1SideDish, isNotNull, reason: "Meal should still exist");

      final mealRecipesAfter1 = await mockDbHelper.getMealRecipesForMeal(mealId);
      expect(mealRecipesAfter1.length, 2,
          reason: "Meal should now have 2 recipes (primary + 1 side)");

      // Find primary and side dishes
      final primaryDishes1 =
          mealRecipesAfter1.where((mr) => mr.isPrimaryDish).toList();
      final sideDishes1 =
          mealRecipesAfter1.where((mr) => !mr.isPrimaryDish).toList();

      expect(primaryDishes1.length, 1,
          reason: "Should still have exactly 1 primary dish");
      expect(primaryDishes1[0].recipeId, primaryRecipeId,
          reason: "Primary dish should remain unchanged");

      expect(sideDishes1.length, 1, reason: "Should have exactly 1 side dish");
      expect(sideDishes1[0].recipeId, sideDish1Id,
          reason: "Side dish should be the one we added");

      // === PHASE 3: Add second side dish ===

      final sideDish2MealRecipeId = await mockDbHelper
          .addRecipeToMeal(mealId, sideDish2Id, isPrimaryDish: false);

      expect(sideDish2MealRecipeId.isNotEmpty, true,
          reason: "Adding second side dish should return a valid ID");

      // === VERIFICATION PHASE 3: After adding second side dish ===

      final mealWith2SideDishes = await mockDbHelper.getMeal(mealId);
      expect(mealWith2SideDishes, isNotNull, reason: "Meal should still exist");

      final mealRecipesAfter2 = await mockDbHelper.getMealRecipesForMeal(mealId);
      expect(mealRecipesAfter2.length, 3,
          reason: "Meal should now have 3 recipes (primary + 2 sides)");

      // Verify primary dish remains unchanged
      final primaryDishes2 =
          mealRecipesAfter2.where((mr) => mr.isPrimaryDish).toList();
      expect(primaryDishes2.length, 1,
          reason: "Should still have exactly 1 primary dish");
      expect(primaryDishes2[0].recipeId, primaryRecipeId,
          reason: "Primary dish should remain unchanged");

      // Verify we have two side dishes
      final sideDishes2 =
          mealRecipesAfter2.where((mr) => !mr.isPrimaryDish).toList();
      expect(sideDishes2.length, 2,
          reason: "Should have exactly 2 side dishes");

      final sideDishRecipeIds = sideDishes2.map((sd) => sd.recipeId).toSet();
      expect(sideDishRecipeIds.contains(sideDish1Id), true,
          reason: "Should contain first side dish");
      expect(sideDishRecipeIds.contains(sideDish2Id), true,
          reason: "Should contain second side dish");

      // === PHASE 4: Remove one side dish ===

      // Test removing a side dish (simulating removal via "Manage Side Dishes")
      final removeResult =
          await mockDbHelper.removeRecipeFromMeal(mealId, sideDish1Id);
      expect(removeResult, true, reason: "Removing side dish should succeed");

      // === VERIFICATION PHASE 4: After removing side dish ===

      final mealAfterRemoval = await mockDbHelper.getMeal(mealId);
      expect(mealAfterRemoval, isNotNull, reason: "Meal should still exist");

      final mealRecipesAfterRemoval =
          await mockDbHelper.getMealRecipesForMeal(mealId);
      expect(mealRecipesAfterRemoval.length, 2,
          reason: "Meal should now have 2 recipes (primary + 1 side)");

      // Verify primary dish still exists
      final primaryDishesAfterRemoval =
          mealRecipesAfterRemoval.where((mr) => mr.isPrimaryDish).toList();
      expect(primaryDishesAfterRemoval.length, 1,
          reason: "Should still have exactly 1 primary dish");
      expect(primaryDishesAfterRemoval[0].recipeId, primaryRecipeId,
          reason: "Primary dish should remain unchanged");

      // Verify only second side dish remains
      final sideDishesAfterRemoval =
          mealRecipesAfterRemoval.where((mr) => !mr.isPrimaryDish).toList();
      expect(sideDishesAfterRemoval.length, 1,
          reason: "Should have exactly 1 side dish remaining");
      expect(sideDishesAfterRemoval[0].recipeId, sideDish2Id,
          reason: "Remaining side dish should be the second one");

      // === PHASE 5: Verify recipe statistics ===

      // Test that recipe statistics are updated correctly
      // (This addresses the related Issue #120 about statistics)

      // Check meals for each recipe
      final primaryRecipeMeals =
          await mockDbHelper.getMealsForRecipe(primaryRecipeId);
      expect(primaryRecipeMeals.length, 1,
          reason: "Primary recipe should appear in 1 meal");
      expect(primaryRecipeMeals[0].id, mealId,
          reason: "Primary recipe meal should be our test meal");

      final sideDish2Meals = await mockDbHelper.getMealsForRecipe(sideDish2Id);
      expect(sideDish2Meals.length, 1,
          reason: "Remaining side dish should appear in 1 meal");
      expect(sideDish2Meals[0].id, mealId,
          reason: "Side dish meal should be our test meal");

      final sideDish1Meals = await mockDbHelper.getMealsForRecipe(sideDish1Id);
      expect(sideDish1Meals.length, 0,
          reason: "Removed side dish should appear in 0 meals");

      // === PHASE 6: Test edge cases ===

      // Test adding the same recipe twice (should not create duplicate)
      final duplicateResult = await mockDbHelper
          .addRecipeToMeal(mealId, sideDish2Id, isPrimaryDish: false);

      // The method should handle this gracefully - either return existing ID or prevent duplicate
      expect(duplicateResult.isNotEmpty, true,
          reason: "Adding duplicate should return a result (existing or new)");

      // Verify we still have only 2 recipes total
      final finalMealRecipes = await mockDbHelper.getMealRecipesForMeal(mealId);
      expect(finalMealRecipes.length, 2,
          reason: "Should still have only 2 recipes after duplicate attempt");

      // Test removing non-existent recipe
      final removeNonExistentResult =
          await mockDbHelper.removeRecipeFromMeal(mealId, sideDish1Id);
      expect(removeNonExistentResult, false,
          reason: "Removing non-existent recipe should return false");

      // === CLEANUP ===

      // Clean up test data
      await mockDbHelper.deleteMeal(mealId);
      await mockDbHelper.deleteRecipe(primaryRecipeId);
      await mockDbHelper.deleteRecipe(sideDish1Id);
      await mockDbHelper.deleteRecipe(sideDish2Id);
    });
  });
}
