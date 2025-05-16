// test/database/database_helper_meal_plan_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gastrobrain/database/database_helper.dart';
import 'package:gastrobrain/models/meal_plan.dart';
import 'package:gastrobrain/models/meal_plan_item.dart';
import 'package:gastrobrain/models/meal_plan_item_recipe.dart';
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

      // Reset the database to a clean state
      await dbHelper.resetDatabaseForTests();

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

    test('meal_plan_item_recipes junction table exists', () async {
      final db = await dbHelper.database;

      // Check if the table exists
      final tables = await db.query('sqlite_master',
          where: 'type = ? AND name = ?',
          whereArgs: ['table', 'meal_plan_item_recipes']);

      expect(tables.length, 1);

      // Instead of deleting, we'll just count and verify the table is created correctly
      final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM meal_plan_item_recipes'));
      expect(count != null, true); // Just verify we can query the table
    });

    test('can insert and retrieve a meal plan', () async {
      final weekStart = DateTime(2023, 6, 2); // A Friday
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

    test('can add items to a meal plan with associated recipes', () async {
      final weekStart = DateTime(2023, 6, 9); // A Friday
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
      final lunchItem = MealPlanItem(
        id: IdGenerator.generateId(),
        mealPlanId: mealPlanId,
        plannedDate: '2023-06-09',
        mealType: MealPlanItem.lunch,
      );

      final dinnerItem = MealPlanItem(
        id: IdGenerator.generateId(),
        mealPlanId: mealPlanId,
        plannedDate: '2023-06-09',
        mealType: MealPlanItem.dinner,
      );

      // Insert items
      await dbHelper.insertMealPlanItem(lunchItem);
      await dbHelper.insertMealPlanItem(dinnerItem);

      // Create and insert recipe associations
      final lunchRecipe = MealPlanItemRecipe(
        mealPlanItemId: lunchItem.id,
        recipeId: testRecipeIds[0],
        isPrimaryDish: true,
      );

      final dinnerRecipe = MealPlanItemRecipe(
        mealPlanItemId: dinnerItem.id,
        recipeId: testRecipeIds[1],
        isPrimaryDish: true,
      );

      await dbHelper.insertMealPlanItemRecipe(lunchRecipe);
      await dbHelper.insertMealPlanItemRecipe(dinnerRecipe);

      // Retrieve meal plan with items
      final retrievedPlan = await dbHelper.getMealPlan(mealPlanId);
      expect(retrievedPlan, isNotNull);
      expect(retrievedPlan!.items.length, 2);

      // Check if items have associated recipes
      for (var item in retrievedPlan.items) {
        expect(item.mealPlanItemRecipes, isNotNull);
        expect(item.mealPlanItemRecipes!.isNotEmpty, isTrue);
      }

      // Find lunch and dinner items
      final lunchItems = retrievedPlan.items
          .where((item) => item.mealType == MealPlanItem.lunch)
          .toList();
      final dinnerItems = retrievedPlan.items
          .where((item) => item.mealType == MealPlanItem.dinner)
          .toList();

      expect(lunchItems.length, 1);
      expect(dinnerItems.length, 1);

      // Check lunch has the right recipe
      expect(lunchItems[0].mealPlanItemRecipes![0].recipeId, testRecipeIds[0]);

      // Check dinner has the right recipe
      expect(dinnerItems[0].mealPlanItemRecipes![0].recipeId, testRecipeIds[1]);
    });

    test('can update a meal plan with junction table records', () async {
      final weekStart = DateTime(2023, 6, 16); // A Friday
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
      final itemId = IdGenerator.generateId();
      final item = MealPlanItem(
        id: itemId,
        mealPlanId: mealPlanId,
        plannedDate: '2023-06-16',
        mealType: MealPlanItem.lunch,
      );

      await dbHelper.insertMealPlanItem(item);

      // Add recipe association
      final recipe = MealPlanItemRecipe(
        mealPlanItemId: itemId,
        recipeId: testRecipeIds[0],
        isPrimaryDish: true,
      );

      await dbHelper.insertMealPlanItemRecipe(recipe);

      // Retrieve the meal plan
      final retrievedPlan = await dbHelper.getMealPlan(mealPlanId);
      expect(retrievedPlan, isNotNull);
      expect(retrievedPlan!.items.length, 1);
      expect(retrievedPlan.items[0].mealPlanItemRecipes!.length, 1);
      expect(retrievedPlan.items[0].mealPlanItemRecipes![0].recipeId,
          testRecipeIds[0]);

      // Modify the plan - create a new item with a different recipe
      final newItemId = IdGenerator.generateId();
      final newItem = MealPlanItem(
        id: newItemId,
        mealPlanId: mealPlanId,
        plannedDate: '2023-06-17',
        mealType: MealPlanItem.dinner,
      );

      newItem.mealPlanItemRecipes = [
        MealPlanItemRecipe(
          mealPlanItemId: newItemId,
          recipeId: testRecipeIds[2],
          isPrimaryDish: true,
        )
      ];

      final updatedPlan = MealPlan(
        id: mealPlanId,
        weekStartDate: weekStart,
        notes: 'Updated notes',
        createdAt: retrievedPlan.createdAt,
        modifiedAt: DateTime.now(),
        items: [newItem], // Replace with the new item
      );

      // Update the plan
      final updateResult = await dbHelper.updateMealPlan(updatedPlan);
      expect(updateResult, 1);

      // Retrieve the updated plan
      final updatedRetrievedPlan = await dbHelper.getMealPlan(mealPlanId);
      expect(updatedRetrievedPlan, isNotNull);
      expect(updatedRetrievedPlan!.notes, 'Updated notes');
      expect(updatedRetrievedPlan.items.length, 1);

      // Check the item has the new recipe
      expect(updatedRetrievedPlan.items[0].mealPlanItemRecipes!.length, 1);
      expect(updatedRetrievedPlan.items[0].mealPlanItemRecipes![0].recipeId,
          testRecipeIds[2]);
      expect(updatedRetrievedPlan.items[0].plannedDate, '2023-06-17');
      expect(updatedRetrievedPlan.items[0].mealType, MealPlanItem.dinner);
    });

    test('can delete a meal plan with cascade to items and junctions',
        () async {
      final weekStart = DateTime(2023, 6, 23); // A Friday
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
      final itemId = IdGenerator.generateId();
      final item = MealPlanItem(
        id: itemId,
        mealPlanId: mealPlanId,
        plannedDate: '2023-06-23',
        mealType: MealPlanItem.lunch,
      );

      await dbHelper.insertMealPlanItem(item);

      // Add recipe association
      final recipe = MealPlanItemRecipe(
        mealPlanItemId: itemId,
        recipeId: testRecipeIds[0],
        isPrimaryDish: true,
      );

      await dbHelper.insertMealPlanItemRecipe(recipe);

      // Verify plan, item, and recipe association exist
      final retrievedPlan = await dbHelper.getMealPlan(mealPlanId);
      expect(retrievedPlan, isNotNull);
      expect(retrievedPlan!.items.length, 1);
      expect(retrievedPlan.items[0].mealPlanItemRecipes!.length, 1);

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

      // Verify recipe associations were also deleted (cascade)
      final junctions = await db.query(
        'meal_plan_item_recipes',
        where: 'meal_plan_item_id = ?',
        whereArgs: [itemId],
      );
      expect(junctions.length, 0);
    });

    test('can query meal plans by date range', () async {
      // Create several meal plans with different dates
      final plans = [
        MealPlan(
          id: IdGenerator.generateId(),
          weekStartDate: DateTime(2023, 7, 7), // Friday
          notes: 'Week 1',
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        ),
        MealPlan(
          id: IdGenerator.generateId(),
          weekStartDate: DateTime(2023, 7, 14), // Friday
          notes: 'Week 2',
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        ),
        MealPlan(
          id: IdGenerator.generateId(),
          weekStartDate: DateTime(2023, 7, 21), // Friday
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
      final rangeStart = DateTime(2023, 7, 12); // Wednesday of week 1
      final rangeEnd = DateTime(2023, 7, 19); // Wednesday of week 2

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
      final weekStart = DateTime(2023, 7, 28); // Friday

      final mealPlan = MealPlan(
        id: mealPlanId,
        weekStartDate: weekStart,
        notes: 'Test plan for date query',
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );

      // Insert meal plan
      await dbHelper.insertMealPlan(mealPlan);

      // Create meal plan items for different dates with associated recipes
      final fridayLunchId = IdGenerator.generateId();
      final fridayLunch = MealPlanItem(
        id: fridayLunchId,
        mealPlanId: mealPlanId,
        plannedDate: '2023-07-28', // Friday
        mealType: MealPlanItem.lunch,
      );

      final fridayDinnerId = IdGenerator.generateId();
      final fridayDinner = MealPlanItem(
        id: fridayDinnerId,
        mealPlanId: mealPlanId,
        plannedDate: '2023-07-28', // Friday
        mealType: MealPlanItem.dinner,
      );

      final saturdayLunchId = IdGenerator.generateId();
      final saturdayLunch = MealPlanItem(
        id: saturdayLunchId,
        mealPlanId: mealPlanId,
        plannedDate: '2023-07-29', // Saturday
        mealType: MealPlanItem.lunch,
      );

      // Insert items
      await dbHelper.insertMealPlanItem(fridayLunch);
      await dbHelper.insertMealPlanItem(fridayDinner);
      await dbHelper.insertMealPlanItem(saturdayLunch);

      // Add recipe associations
      await dbHelper.insertMealPlanItemRecipe(MealPlanItemRecipe(
        mealPlanItemId: fridayLunchId,
        recipeId: testRecipeIds[0],
        isPrimaryDish: true,
      ));

      await dbHelper.insertMealPlanItemRecipe(MealPlanItemRecipe(
        mealPlanItemId: fridayDinnerId,
        recipeId: testRecipeIds[1],
        isPrimaryDish: true,
      ));

      await dbHelper.insertMealPlanItemRecipe(MealPlanItemRecipe(
        mealPlanItemId: saturdayLunchId,
        recipeId: testRecipeIds[2],
        isPrimaryDish: true,
      ));

      // Query for Friday's items
      final fridayItems =
          await dbHelper.getMealPlanItemsForDate(DateTime(2023, 7, 28));
      expect(fridayItems.length, 2);

      // Query for Saturday's items
      final saturdayItems =
          await dbHelper.getMealPlanItemsForDate(DateTime(2023, 7, 29));
      expect(saturdayItems.length, 1);
      expect(saturdayItems[0].mealType, MealPlanItem.lunch);

      // Query for Sunday (should be empty)
      final sundayItems =
          await dbHelper.getMealPlanItemsForDate(DateTime(2023, 7, 30));
      expect(sundayItems.length, 0);

      // Unfortunately we can't check the recipe associations here since
      // getMealPlanItemsForDate doesn't return associated recipes
      // That would require an enhancement to the method
    });

    test('can get a meal plan for a specific week with recipes', () async {
      final weekStart = DateTime(2023, 8, 4); // Friday
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

      // Add an item with recipe
      final itemId = IdGenerator.generateId();
      final item = MealPlanItem(
        id: itemId,
        mealPlanId: mealPlanId,
        plannedDate: '2023-08-04', // Friday
        mealType: MealPlanItem.lunch,
      );

      await dbHelper.insertMealPlanItem(item);

      // Add recipe association
      final recipe = MealPlanItemRecipe(
        mealPlanItemId: itemId,
        recipeId: testRecipeIds[0],
        isPrimaryDish: true,
      );

      await dbHelper.insertMealPlanItemRecipe(recipe);

      // Query using Friday date
      final fridayPlan = await dbHelper.getMealPlanForWeek(weekStart);
      expect(fridayPlan, isNotNull);
      expect(fridayPlan!.id, mealPlanId);
      expect(fridayPlan.items.length, 1);
      expect(fridayPlan.items[0].mealPlanItemRecipes!.length, 1);
      expect(fridayPlan.items[0].mealPlanItemRecipes![0].recipeId,
          testRecipeIds[0]);

      // Query using Sunday date (should return the same plan)
      final sunday = DateTime(2023, 8, 6);
      final sundayPlan = await dbHelper.getMealPlanForWeek(sunday);
      expect(sundayPlan, isNotNull);
      expect(sundayPlan!.id, mealPlanId);
      expect(sundayPlan.items.length, 1);
      expect(sundayPlan.items[0].mealPlanItemRecipes!.length, 1);
      expect(sundayPlan.items[0].mealPlanItemRecipes![0].recipeId,
          testRecipeIds[0]);

      // Query using next Friday (should return null)
      final nextFriday = DateTime(2023, 8, 11);
      final nextWeekPlan = await dbHelper.getMealPlanForWeek(nextFriday);
      expect(nextWeekPlan, isNull);
    });

    test('MealPlanItem can have multiple recipes', () async {
      final weekStart = DateTime(2023, 8, 18); // Friday
      final mealPlanId = IdGenerator.generateId();

      final mealPlan = MealPlan(
        id: mealPlanId,
        weekStartDate: weekStart,
        notes: 'Multi-recipe test',
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );

      // Insert meal plan
      await dbHelper.insertMealPlan(mealPlan);

      // Add an item
      final itemId = IdGenerator.generateId();
      final item = MealPlanItem(
        id: itemId,
        mealPlanId: mealPlanId,
        plannedDate: '2023-08-18', // Friday
        mealType: MealPlanItem.dinner,
      );

      await dbHelper.insertMealPlanItem(item);

      // Add multiple recipe associations - main dish and two sides
      final mainDish = MealPlanItemRecipe(
        mealPlanItemId: itemId,
        recipeId: testRecipeIds[0],
        isPrimaryDish: true,
      );

      final sideDish1 = MealPlanItemRecipe(
        mealPlanItemId: itemId,
        recipeId: testRecipeIds[1],
        isPrimaryDish: false,
      );

      final sideDish2 = MealPlanItemRecipe(
        mealPlanItemId: itemId,
        recipeId: testRecipeIds[2],
        isPrimaryDish: false,
      );

      await dbHelper.insertMealPlanItemRecipe(mainDish);
      await dbHelper.insertMealPlanItemRecipe(sideDish1);
      await dbHelper.insertMealPlanItemRecipe(sideDish2);

      // Retrieve the meal plan
      final retrievedPlan = await dbHelper.getMealPlanForWeek(weekStart);
      expect(retrievedPlan, isNotNull);
      expect(retrievedPlan!.items.length, 1);

      // Check that all three recipes are associated with the item
      final recipes = retrievedPlan.items[0].mealPlanItemRecipes;
      expect(recipes, isNotNull);
      expect(recipes!.length, 3);

      // Verify primary dish is marked correctly
      final primaryDishes = recipes.where((r) => r.isPrimaryDish).toList();
      expect(primaryDishes.length, 1);
      expect(primaryDishes[0].recipeId, testRecipeIds[0]);

      // Verify side dishes are present
      final sideDishes = recipes.where((r) => !r.isPrimaryDish).toList();
      expect(sideDishes.length, 2);

      // Verify all three recipe IDs are present
      final recipeIds = recipes.map((r) => r.recipeId).toSet();
      expect(recipeIds.length, 3);
      expect(recipeIds.containsAll(testRecipeIds), isTrue);
    });
  });
}
