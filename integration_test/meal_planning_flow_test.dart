// test/integration/meal_planning_flow_test.dart
//import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
//import 'package:gastrobrain/main.dart' as app;
import 'package:gastrobrain/database/database_helper.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/meal_plan.dart';
import 'package:gastrobrain/models/meal_plan_item.dart';
import 'package:gastrobrain/models/meal_plan_item_recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/utils/id_generator.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Meal Planning - Core Functionality', () {
    late DatabaseHelper dbHelper;
    final testRecipeId = IdGenerator.generateId();
    final testRecipe2Id = IdGenerator.generateId();

    setUpAll(() async {
      // Set up database
      dbHelper = DatabaseHelper();
      await dbHelper.resetDatabaseForTests();

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

      await dbHelper.insertRecipe(recipe1);
      await dbHelper.insertRecipe(recipe2);
    });

    tearDownAll(() async {
      // Clean up
      try {
        await dbHelper.deleteRecipe(testRecipeId);
        await dbHelper.deleteRecipe(testRecipe2Id);
      } catch (e) {
        // Ignore errors during cleanup
      }
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
      final existingPlan = await dbHelper.getMealPlanForWeek(weekStart);
      if (existingPlan != null) {
        await dbHelper.deleteMealPlan(existingPlan.id);
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
      await dbHelper.insertMealPlan(mealPlan);

      // Verify the plan was created
      final createdPlan = await dbHelper.getMealPlan(mealPlanId);
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
      await dbHelper.insertMealPlanItem(fridayLunch);

      // Verify first item was added
      final planWithLunch = await dbHelper.getMealPlan(mealPlanId);
      expect(planWithLunch!.items.length, 1);

      // Friday dinner
      final fridayDinnerId = IdGenerator.generateId();
      final fridayDinner = MealPlanItem(
        id: fridayDinnerId,
        mealPlanId: mealPlanId,
        plannedDate: MealPlanItem.formatPlannedDate(weekStart),
        mealType: MealPlanItem.dinner,
      );
      await dbHelper.insertMealPlanItem(fridayDinner);

      // Verify second item was added
      final planWithBothMeals = await dbHelper.getMealPlan(mealPlanId);
      expect(planWithBothMeals!.items.length, 2);

      // Add recipe associations
      await dbHelper.insertMealPlanItemRecipe(MealPlanItemRecipe(
        mealPlanItemId: fridayLunchId,
        recipeId: testRecipeId,
        isPrimaryDish: true,
      ));

      await dbHelper.insertMealPlanItemRecipe(MealPlanItemRecipe(
        mealPlanItemId: fridayDinnerId,
        recipeId: testRecipe2Id,
        isPrimaryDish: true,
      ));

      // 4. Final verification for all the data
      final savedPlan = await dbHelper.getMealPlanForWeek(weekStart);
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
      await dbHelper.deleteMealPlanItem(fridayDinnerId);

      // 5. Verify update worked
      final updatedPlan = await dbHelper.getMealPlanForWeek(weekStart);
      expect(updatedPlan, isNotNull);
      expect(updatedPlan!.items.length, 1);
      expect(updatedPlan.items[0].mealType, MealPlanItem.lunch);

      // 6. Clean up
      await dbHelper.deleteMealPlan(mealPlanId);
    });
  });
}
