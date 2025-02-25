// test/database/database_helper_meal_plan_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gastrobrain/database/database_helper.dart';
import 'package:gastrobrain/models/meal_plan.dart';
import 'package:gastrobrain/models/meal_plan_item.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/utils/id_generator.dart';

void main() {
  // Initialize FFI
  sqfliteFfiInit();

  // Set the database factory to use the FFI implementation
  databaseFactory = databaseFactoryFfi;

  group('DatabaseHelper Meal Plan Integration Tests', () {
    late DatabaseHelper dbHelper;
    final testRecipeIds = <String>[];

    setUpAll(() async {
      dbHelper = DatabaseHelper();

      // Create some test recipes for reference
      final recipes = [
        Recipe(
          id: IdGenerator.generateId(),
          name: 'Test Recipe 1',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
        ),
        Recipe(
          id: IdGenerator.generateId(),
          name: 'Test Recipe 2',
          desiredFrequency: FrequencyType.monthly,
          createdAt: DateTime.now(),
        ),
        Recipe(
          id: IdGenerator.generateId(),
          name: 'Test Recipe 3',
          desiredFrequency: FrequencyType.biweekly,
          createdAt: DateTime.now(),
        ),
      ];

      // Insert test recipes
      for (var recipe in recipes) {
        await dbHelper.insertRecipe(recipe);
        testRecipeIds.add(recipe.id);
      }
    });

    test('meal_plans table exists and is empty initially', () async {
      final db = await dbHelper.database;

      // First make sure tables are empty
      await db.rawDelete('DELETE FROM meal_plans');

      final tables = await db.query('sqlite_master',
          where: 'type = ? AND name = ?', whereArgs: ['table', 'meal_plans']);

      expect(tables.length, 1);

      final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM meal_plans'));
      expect(count, 0);
    });

    test('meal_plan_items table exists and is empty initially', () async {
      final db = await dbHelper.database;

      // First make sure tables are empty
      await db.rawDelete('DELETE FROM meal_plan_items');

      final tables = await db.query('sqlite_master',
          where: 'type = ? AND name = ?',
          whereArgs: ['table', 'meal_plan_items']);

      expect(tables.length, 1);

      final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM meal_plan_items'));
      expect(count, 0);
    });

    test('can insert and retrieve a meal plan', () async {
      final weekStart = DateTime(2023, 6, 5);
      final mealPlanId = IdGenerator.generateId();

      final mealPlan = MealPlan(
        id: mealPlanId,
        weekStartDate: weekStart,
        notes: 'Test plan',
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );

      // Insert meal plan
      final insertedId = await dbHelper.insertMealPlan(mealPlan);
      expect(insertedId, mealPlanId);

      // Retrieve meal plan
      final retrievedPlan = await dbHelper.getMealPlan(mealPlanId);
      expect(retrievedPlan, isNotNull);
      expect(retrievedPlan!.id, mealPlanId);
      expect(retrievedPlan.weekStartDate.year, weekStart.year);
      expect(retrievedPlan.weekStartDate.month, weekStart.month);
      expect(retrievedPlan.weekStartDate.day, weekStart.day);
      expect(retrievedPlan.notes, 'Test plan');
      expect(retrievedPlan.items, isEmpty);
    });

    test('can add items to a meal plan', () async {
      final weekStart = DateTime(2023, 6, 12);
      final mealPlanId = IdGenerator.generateId();

      final mealPlan = MealPlan(
        id: mealPlanId,
        weekStartDate: weekStart,
        notes: 'Test plan with items',
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );

      // Insert meal plan
      await dbHelper.insertMealPlan(mealPlan);

      // Create meal plan items
      final items = [
        MealPlanItem(
          id: IdGenerator.generateId(),
          mealPlanId: mealPlanId,
          recipeId: testRecipeIds[0],
          plannedDate: '2023-06-12',
          mealType: MealPlanItem.lunch,
        ),
        MealPlanItem(
          id: IdGenerator.generateId(),
          mealPlanId: mealPlanId,
          recipeId: testRecipeIds[1],
          plannedDate: '2023-06-12',
          mealType: MealPlanItem.dinner,
        ),
      ];

      // Insert items
      for (var item in items) {
        await dbHelper.insertMealPlanItem(item);
      }

      // Retrieve meal plan with items
      final retrievedPlan = await dbHelper.getMealPlan(mealPlanId);
      expect(retrievedPlan, isNotNull);
      expect(retrievedPlan!.items.length, 2);

      // Check if items match
      expect(
          retrievedPlan.items.any((item) =>
              item.recipeId == testRecipeIds[0] &&
              item.mealType == MealPlanItem.lunch),
          isTrue);

      expect(
          retrievedPlan.items.any((item) =>
              item.recipeId == testRecipeIds[1] &&
              item.mealType == MealPlanItem.dinner),
          isTrue);
    });

    test('can update a meal plan', () async {
      final weekStart = DateTime(2023, 6, 19);
      final mealPlanId = IdGenerator.generateId();

      final mealPlan = MealPlan(
        id: mealPlanId,
        weekStartDate: weekStart,
        notes: 'Original notes',
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );

      // Insert meal plan
      await dbHelper.insertMealPlan(mealPlan);

      // Add an item
      final item = MealPlanItem(
        id: IdGenerator.generateId(),
        mealPlanId: mealPlanId,
        recipeId: testRecipeIds[0],
        plannedDate: '2023-06-19',
        mealType: MealPlanItem.lunch,
      );

      await dbHelper.insertMealPlanItem(item);

      // Retrieve the meal plan
      final retrievedPlan = await dbHelper.getMealPlan(mealPlanId);
      expect(retrievedPlan, isNotNull);

      // Modify the plan
      final updatedPlan = MealPlan(
        id: mealPlanId,
        weekStartDate: weekStart,
        notes: 'Updated notes',
        createdAt: retrievedPlan!.createdAt,
        modifiedAt: DateTime.now(),
        items: [
          // Replace the item with a new one
          MealPlanItem(
            id: IdGenerator.generateId(),
            mealPlanId: mealPlanId,
            recipeId: testRecipeIds[2],
            plannedDate: '2023-06-20',
            mealType: MealPlanItem.dinner,
          ),
        ],
      );

      // Update the plan
      final updateResult = await dbHelper.updateMealPlan(updatedPlan);
      expect(updateResult, 1);

      // Retrieve the updated plan
      final updatedRetrievedPlan = await dbHelper.getMealPlan(mealPlanId);
      expect(updatedRetrievedPlan, isNotNull);
      expect(updatedRetrievedPlan!.notes, 'Updated notes');
      expect(updatedRetrievedPlan.items.length, 1);
      expect(updatedRetrievedPlan.items[0].recipeId, testRecipeIds[2]);
      expect(updatedRetrievedPlan.items[0].plannedDate, '2023-06-20');
      expect(updatedRetrievedPlan.items[0].mealType, MealPlanItem.dinner);
    });

    test('can delete a meal plan with cascade to items', () async {
      final weekStart = DateTime(2023, 6, 26);
      final mealPlanId = IdGenerator.generateId();

      final mealPlan = MealPlan(
        id: mealPlanId,
        weekStartDate: weekStart,
        notes: 'Plan to delete',
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );

      // Insert meal plan
      await dbHelper.insertMealPlan(mealPlan);

      // Add an item
      final item = MealPlanItem(
        id: IdGenerator.generateId(),
        mealPlanId: mealPlanId,
        recipeId: testRecipeIds[0],
        plannedDate: '2023-06-26',
        mealType: MealPlanItem.lunch,
      );

      await dbHelper.insertMealPlanItem(item);

      // Verify plan and item exist
      final retrievedPlan = await dbHelper.getMealPlan(mealPlanId);
      expect(retrievedPlan, isNotNull);
      expect(retrievedPlan!.items.length, 1);

      // Delete the plan
      final deleteResult = await dbHelper.deleteMealPlan(mealPlanId);
      expect(deleteResult, 1);

      // Verify plan no longer exists
      final deletedPlan = await dbHelper.getMealPlan(mealPlanId);
      expect(deletedPlan, isNull);

      // Verify item was also deleted (cascade)
      final db = await dbHelper.database;
      final items = await db.query(
        'meal_plan_items',
        where: 'meal_plan_id = ?',
        whereArgs: [mealPlanId],
      );
      expect(items.length, 0);
    });

    test('can query meal plans by date range', () async {
      // Create several meal plans with different dates
      final plans = [
        MealPlan(
          id: IdGenerator.generateId(),
          weekStartDate: DateTime(2023, 7, 3),
          notes: 'Week 1',
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        ),
        MealPlan(
          id: IdGenerator.generateId(),
          weekStartDate: DateTime(2023, 7, 10),
          notes: 'Week 2',
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        ),
        MealPlan(
          id: IdGenerator.generateId(),
          weekStartDate: DateTime(2023, 7, 17),
          notes: 'Week 3',
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        ),
      ];

      // Insert all plans
      for (var plan in plans) {
        await dbHelper.insertMealPlan(plan);
      }

      // Query for a specific date range
      final rangeStart = DateTime(2023, 7, 8); // Saturday of week 1
      final rangeEnd = DateTime(2023, 7, 15); // Saturday of week 2

      final plansInRange =
          await dbHelper.getMealPlansByDateRange(rangeStart, rangeEnd);

      // Should include weeks 1 and 2
      expect(plansInRange.length, 2);
      expect(plansInRange.any((plan) => plan.notes == 'Week 1'), isTrue);
      expect(plansInRange.any((plan) => plan.notes == 'Week 2'), isTrue);
      expect(plansInRange.any((plan) => plan.notes == 'Week 3'), isFalse);
    });

    test('can get meal plan items for a specific date', () async {
      final mealPlanId = IdGenerator.generateId();
      final weekStart = DateTime(2023, 7, 24);

      final mealPlan = MealPlan(
        id: mealPlanId,
        weekStartDate: weekStart,
        notes: 'Test plan for date query',
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );

      // Insert meal plan
      await dbHelper.insertMealPlan(mealPlan);

      // Create meal plan items for different dates
      final items = [
        MealPlanItem(
          id: IdGenerator.generateId(),
          mealPlanId: mealPlanId,
          recipeId: testRecipeIds[0],
          plannedDate: '2023-07-24', // Monday
          mealType: MealPlanItem.lunch,
        ),
        MealPlanItem(
          id: IdGenerator.generateId(),
          mealPlanId: mealPlanId,
          recipeId: testRecipeIds[1],
          plannedDate: '2023-07-24', // Monday
          mealType: MealPlanItem.dinner,
        ),
        MealPlanItem(
          id: IdGenerator.generateId(),
          mealPlanId: mealPlanId,
          recipeId: testRecipeIds[2],
          plannedDate: '2023-07-25', // Tuesday
          mealType: MealPlanItem.lunch,
        ),
      ];

      // Insert items
      for (var item in items) {
        await dbHelper.insertMealPlanItem(item);
      }

      // Query for Monday's items
      final mondayItems =
          await dbHelper.getMealPlanItemsForDate(DateTime(2023, 7, 24));
      expect(mondayItems.length, 2);

      // Query for Tuesday's items
      final tuesdayItems =
          await dbHelper.getMealPlanItemsForDate(DateTime(2023, 7, 25));
      expect(tuesdayItems.length, 1);
      expect(tuesdayItems[0].mealType, MealPlanItem.lunch);

      // Query for Wednesday (should be empty)
      final wednesdayItems =
          await dbHelper.getMealPlanItemsForDate(DateTime(2023, 7, 26));
      expect(wednesdayItems.length, 0);
    });

    test('can get a meal plan for a specific week', () async {
      final weekStart = DateTime(2023, 7, 31); // Monday
      final mealPlanId = IdGenerator.generateId();

      final mealPlan = MealPlan(
        id: mealPlanId,
        weekStartDate: weekStart,
        notes: 'Week lookup test',
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );

      // Insert meal plan
      await dbHelper.insertMealPlan(mealPlan);

      // Query using Monday date
      final mondayPlan = await dbHelper.getMealPlanForWeek(weekStart);
      expect(mondayPlan, isNotNull);
      expect(mondayPlan!.id, mealPlanId);

      // Query using Wednesday date (should return the same plan)
      final wednesday = DateTime(2023, 8, 2);
      final wednesdayPlan = await dbHelper.getMealPlanForWeek(wednesday);
      expect(wednesdayPlan, isNotNull);
      expect(wednesdayPlan!.id, mealPlanId);

      // Query using next Monday (should return null)
      final nextMonday = DateTime(2023, 8, 7);
      final nextWeekPlan = await dbHelper.getMealPlanForWeek(nextMonday);
      expect(nextWeekPlan, isNull);
    });
  });
}
