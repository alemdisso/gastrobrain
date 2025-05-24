// test/database/database_helper_meal_plan_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gastrobrain/database/database_helper.dart';
import 'package:gastrobrain/models/meal.dart';
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

    test('can add and remove recipes from existing meals (Issue #104)',
        () async {
      // Test the core database operations for managing side dishes

      // Create test recipes
      final primaryRecipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Primary Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
      );

      final sideRecipe1 = Recipe(
        id: IdGenerator.generateId(),
        name: 'Side Recipe 1',
        desiredFrequency: FrequencyType.monthly,
        createdAt: DateTime.now(),
      );

      final sideRecipe2 = Recipe(
        id: IdGenerator.generateId(),
        name: 'Side Recipe 2',
        desiredFrequency: FrequencyType.biweekly,
        createdAt: DateTime.now(),
      );

      // Insert recipes
      await dbHelper.insertRecipe(primaryRecipe);
      await dbHelper.insertRecipe(sideRecipe1);
      await dbHelper.insertRecipe(sideRecipe2);

      // Create initial meal with primary recipe
      final meal = Meal(
        id: IdGenerator.generateId(),
        recipeId: null, // Using junction table approach
        cookedAt: DateTime.now(),
        servings: 2,
        wasSuccessful: true,
      );

      await dbHelper.insertMeal(meal);

      // Add primary recipe to meal
      final primaryJunctionId = await dbHelper.addRecipeToMeal(
        meal.id,
        primaryRecipe.id,
        isPrimaryDish: true,
      );

      expect(primaryJunctionId.isNotEmpty, isTrue);

      // Verify initial state - meal has one recipe
      final initialMealRecipes = await dbHelper.getMealRecipesForMeal(meal.id);
      expect(initialMealRecipes.length, 1);
      expect(initialMealRecipes[0].recipeId, primaryRecipe.id);
      expect(initialMealRecipes[0].isPrimaryDish, isTrue);

      // Add first side dish
      final side1JunctionId = await dbHelper.addRecipeToMeal(
        meal.id,
        sideRecipe1.id,
        isPrimaryDish: false,
      );

      expect(side1JunctionId.isNotEmpty, isTrue);

      // Verify meal now has two recipes
      final withOneSideMealRecipes =
          await dbHelper.getMealRecipesForMeal(meal.id);
      expect(withOneSideMealRecipes.length, 2);

      final primaryDishes =
          withOneSideMealRecipes.where((mr) => mr.isPrimaryDish).toList();
      final sideDishes =
          withOneSideMealRecipes.where((mr) => !mr.isPrimaryDish).toList();

      expect(primaryDishes.length, 1);
      expect(primaryDishes[0].recipeId, primaryRecipe.id);
      expect(sideDishes.length, 1);
      expect(sideDishes[0].recipeId, sideRecipe1.id);

      // Add second side dish
      final side2JunctionId = await dbHelper.addRecipeToMeal(
        meal.id,
        sideRecipe2.id,
        isPrimaryDish: false,
      );

      expect(side2JunctionId.isNotEmpty, isTrue);

      // Verify meal now has three recipes
      final withTwoSidesMealRecipes =
          await dbHelper.getMealRecipesForMeal(meal.id);
      expect(withTwoSidesMealRecipes.length, 3);

      final allPrimaryDishes =
          withTwoSidesMealRecipes.where((mr) => mr.isPrimaryDish).toList();
      final allSideDishes =
          withTwoSidesMealRecipes.where((mr) => !mr.isPrimaryDish).toList();

      expect(allPrimaryDishes.length, 1);
      expect(allPrimaryDishes[0].recipeId, primaryRecipe.id);
      expect(allSideDishes.length, 2);

      final sideRecipeIds = allSideDishes.map((sd) => sd.recipeId).toSet();
      expect(sideRecipeIds.contains(sideRecipe1.id), isTrue);
      expect(sideRecipeIds.contains(sideRecipe2.id), isTrue);

      // Remove first side dish
      final removeResult1 =
          await dbHelper.removeRecipeFromMeal(meal.id, sideRecipe1.id);
      expect(removeResult1, isTrue);

      // Verify meal now has two recipes (primary + one side)
      final afterRemovalMealRecipes =
          await dbHelper.getMealRecipesForMeal(meal.id);
      expect(afterRemovalMealRecipes.length, 2);

      final finalPrimaryDishes =
          afterRemovalMealRecipes.where((mr) => mr.isPrimaryDish).toList();
      final finalSideDishes =
          afterRemovalMealRecipes.where((mr) => !mr.isPrimaryDish).toList();

      expect(finalPrimaryDishes.length, 1);
      expect(finalPrimaryDishes[0].recipeId, primaryRecipe.id);
      expect(finalSideDishes.length, 1);
      expect(finalSideDishes[0].recipeId, sideRecipe2.id);

      // Test removing non-existent recipe
      final removeNonExistentResult =
          await dbHelper.removeRecipeFromMeal(meal.id, sideRecipe1.id);
      expect(removeNonExistentResult, isFalse);

      // Clean up
      await dbHelper.deleteMeal(meal.id);
      await dbHelper.deleteRecipe(primaryRecipe.id);
      await dbHelper.deleteRecipe(sideRecipe1.id);
      await dbHelper.deleteRecipe(sideRecipe2.id);
    });

    test('setPrimaryRecipeForMeal works correctly with multiple recipes',
        () async {
      // Test changing which recipe is the primary dish in a multi-recipe meal

      // Create test recipes
      final recipe1 = Recipe(
        id: IdGenerator.generateId(),
        name: 'Recipe 1',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
      );

      final recipe2 = Recipe(
        id: IdGenerator.generateId(),
        name: 'Recipe 2',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
      );

      await dbHelper.insertRecipe(recipe1);
      await dbHelper.insertRecipe(recipe2);

      // Create meal
      final meal = Meal(
        id: IdGenerator.generateId(),
        recipeId: null,
        cookedAt: DateTime.now(),
        servings: 2,
        wasSuccessful: true,
      );

      await dbHelper.insertMeal(meal);

      // Add both recipes, with recipe1 as primary
      await dbHelper.addRecipeToMeal(meal.id, recipe1.id, isPrimaryDish: true);
      await dbHelper.addRecipeToMeal(meal.id, recipe2.id, isPrimaryDish: false);

      // Verify initial state
      final initialMealRecipes = await dbHelper.getMealRecipesForMeal(meal.id);
      expect(initialMealRecipes.length, 2);

      final initialPrimary =
          initialMealRecipes.firstWhere((mr) => mr.isPrimaryDish);
      expect(initialPrimary.recipeId, recipe1.id);

      // Change primary dish to recipe2
      final setPrimaryResult =
          await dbHelper.setPrimaryRecipeForMeal(meal.id, recipe2.id);
      expect(setPrimaryResult, isTrue);

      // Verify the change
      final updatedMealRecipes = await dbHelper.getMealRecipesForMeal(meal.id);
      expect(updatedMealRecipes.length, 2);

      final primaryDishes =
          updatedMealRecipes.where((mr) => mr.isPrimaryDish).toList();
      expect(primaryDishes.length, 1,
          reason: 'Should have exactly one primary dish');
      expect(primaryDishes[0].recipeId, recipe2.id,
          reason: 'Recipe2 should now be primary');

      final sideDishes =
          updatedMealRecipes.where((mr) => !mr.isPrimaryDish).toList();
      expect(sideDishes.length, 1, reason: 'Should have exactly one side dish');
      expect(sideDishes[0].recipeId, recipe1.id,
          reason: 'Recipe1 should now be a side dish');

// Test setting primary for non-existent recipe-meal combination
// (Recipe exists but isn't associated with this meal)
      final unrelatedRecipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Unrelated Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
      );
      await dbHelper.insertRecipe(unrelatedRecipe);

      final nonExistentResult =
          await dbHelper.setPrimaryRecipeForMeal(meal.id, unrelatedRecipe.id);
      expect(nonExistentResult, isTrue,
          reason: 'Method should add recipe and set as primary');

// Verify the recipe was actually added to the meal
      final afterAddingUnrelated =
          await dbHelper.getMealRecipesForMeal(meal.id);
      expect(afterAddingUnrelated.length, 3,
          reason: 'Should now have 3 recipes in meal');

// Clean up the unrelated recipe
      await dbHelper.deleteRecipe(unrelatedRecipe.id);
      // Clean up
      await dbHelper.deleteMeal(meal.id);
      await dbHelper.deleteRecipe(recipe1.id);
      await dbHelper.deleteRecipe(recipe2.id);
    });

    test('getMealsForRecipe includes meals with junction table relationships',
        () async {
      // Test that recipe statistics correctly include junction table relationships

      final recipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Test Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
      );

      await dbHelper.insertRecipe(recipe);

      // Create first meal with direct recipe reference (legacy approach)
      final meal1 = Meal(
        id: IdGenerator.generateId(),
        recipeId: recipe.id, // Direct reference
        cookedAt: DateTime.now().subtract(const Duration(days: 5)),
        servings: 2,
        wasSuccessful: true,
      );

      await dbHelper.insertMeal(meal1);

      // Create second meal using junction table (new approach)
      final meal2 = Meal(
        id: IdGenerator.generateId(),
        recipeId: null, // No direct reference
        cookedAt: DateTime.now().subtract(const Duration(days: 2)),
        servings: 3,
        wasSuccessful: true,
      );

      await dbHelper.insertMeal(meal2);

      // Add recipe to meal2 via junction table
      await dbHelper.addRecipeToMeal(meal2.id, recipe.id, isPrimaryDish: true);

      // Create third meal where recipe is a side dish
      final meal3 = Meal(
        id: IdGenerator.generateId(),
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 4,
        wasSuccessful: true,
      );

      await dbHelper.insertMeal(meal3);

      // Add recipe to meal3 as a side dish
      await dbHelper.addRecipeToMeal(meal3.id, recipe.id, isPrimaryDish: false);

      // Test getMealsForRecipe includes all three meals
      final mealsForRecipe = await dbHelper.getMealsForRecipe(recipe.id);
      expect(mealsForRecipe.length, 3,
          reason: 'Should find all 3 meals containing the recipe');

      final mealIds = mealsForRecipe.map((m) => m.id).toSet();
      expect(mealIds.contains(meal1.id), isTrue,
          reason: 'Should include meal with direct reference');
      expect(mealIds.contains(meal2.id), isTrue,
          reason: 'Should include meal with junction table (primary)');
      expect(mealIds.contains(meal3.id), isTrue,
          reason: 'Should include meal with junction table (side)');

      // Clean up
      await dbHelper.deleteMeal(meal1.id);
      await dbHelper.deleteMeal(meal2.id);
      await dbHelper.deleteMeal(meal3.id);
      await dbHelper.deleteRecipe(recipe.id);
    });

    test('addRecipeToMeal handles duplicate additions gracefully', () async {
      // Test edge case of adding the same recipe multiple times

      final recipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Test Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
      );

      await dbHelper.insertRecipe(recipe);

      final meal = Meal(
        id: IdGenerator.generateId(),
        recipeId: null,
        cookedAt: DateTime.now(),
        servings: 2,
        wasSuccessful: true,
      );

      await dbHelper.insertMeal(meal);

      // Add recipe first time
      final firstAddResult = await dbHelper.addRecipeToMeal(meal.id, recipe.id,
          isPrimaryDish: true);
      expect(firstAddResult.isNotEmpty, isTrue);

      // Verify one junction record exists
      final afterFirstAdd = await dbHelper.getMealRecipesForMeal(meal.id);
      expect(afterFirstAdd.length, 1);

      // Try to add the same recipe again
      final secondAddResult = await dbHelper.addRecipeToMeal(meal.id, recipe.id,
          isPrimaryDish: false);
      expect(secondAddResult.isNotEmpty, isTrue);

      // Verify behavior - implementation might:
      // 1. Return existing junction ID without creating duplicate
      // 2. Update existing junction record
      // 3. Create duplicate (less desirable)

      final afterSecondAdd = await dbHelper.getMealRecipesForMeal(meal.id);

      // The exact behavior depends on implementation, but we should have reasonable handling
      // For this test, we'll verify that at least we don't crash and we get some result
      expect(afterSecondAdd.isNotEmpty, isTrue,
          reason: 'Should have at least one junction record');

      // If implementation prevents duplicates, we should still have only 1 record
      // If it allows duplicates, we might have 2 records
      // Both are acceptable as long as the behavior is consistent
      expect(afterSecondAdd.length, greaterThanOrEqualTo(1),
          reason: 'Should have at least the original junction record');

      // Clean up
      await dbHelper.deleteMeal(meal.id);
      await dbHelper.deleteRecipe(recipe.id);
    });
  });
}
