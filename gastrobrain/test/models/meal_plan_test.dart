// test/models/meal_plan_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/meal_plan.dart';
import 'package:gastrobrain/models/meal_plan_item.dart';
import 'package:gastrobrain/models/meal_plan_item_recipe.dart';

void main() {
  group('MealPlan', () {
    test('creates with required fields', () {
      final now = DateTime.now();
      final weekStart = DateTime(2023, 6, 2); // A Friday

      final mealPlan = MealPlan(
        id: 'test_id',
        weekStartDate: weekStart,
        createdAt: now,
        modifiedAt: now,
      );

      expect(mealPlan.id, 'test_id');
      expect(mealPlan.weekStartDate, weekStart);
      expect(mealPlan.notes, '');
      expect(mealPlan.items, isEmpty);
      expect(mealPlan.createdAt, now);
      expect(mealPlan.modifiedAt, now);
    });

    test('converts to map correctly', () {
      final now = DateTime.now();
      final weekStart = DateTime(2023, 6, 2); // A Friday

      final mealPlan = MealPlan(
        id: 'test_id',
        weekStartDate: weekStart,
        notes: 'Test notes',
        createdAt: now,
        modifiedAt: now,
        items: [],
      );

      final map = mealPlan.toMap();
      expect(map['id'], 'test_id');
      expect(map['week_start_date'], weekStart.toIso8601String());
      expect(map['notes'], 'Test notes');
      expect(map['created_at'], now.toIso8601String());
      expect(map['modified_at'], now.toIso8601String());
      // Items are not included in the map
    });

    test('creates from map correctly', () {
      final now = DateTime.now();
      final weekStart = DateTime(2023, 6, 2); // A Friday

      final map = {
        'id': 'test_id',
        'week_start_date': weekStart.toIso8601String(),
        'notes': 'Test notes',
        'created_at': now.toIso8601String(),
        'modified_at': now.toIso8601String(),
      };

      final items = [
        MealPlanItem(
          id: 'item1',
          mealPlanId: 'test_id',
          plannedDate: '2023-06-02',
          mealType: MealPlanItem.lunch,
        ),
      ];

      final mealPlan = MealPlan.fromMap(map, items);
      expect(mealPlan.id, 'test_id');
      expect(mealPlan.weekStartDate.toIso8601String(),
          weekStart.toIso8601String());
      expect(mealPlan.notes, 'Test notes');
      expect(mealPlan.createdAt.toIso8601String(), now.toIso8601String());
      expect(mealPlan.modifiedAt.toIso8601String(), now.toIso8601String());
      expect(mealPlan.items.length, 1);
      expect(mealPlan.items[0].id, 'item1');
    });

    test('calculates week end date correctly', () {
      final weekStart = DateTime(2023, 6, 2); // A Friday
      final expectedWeekEnd = DateTime(2023, 6, 8); // Thursday

      final mealPlan = MealPlan(
        id: 'test_id',
        weekStartDate: weekStart,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );

      expect(mealPlan.weekEndDate, expectedWeekEnd);
    });

    test('filters items by date', () {
      final weekStart = DateTime(2023, 6, 2); // A Friday
      const fridayDate = '2023-06-02';
      const saturdayDate = '2023-06-03';

      // Create meal plan items with associated recipes
      final fridayLunchItem = MealPlanItem(
        id: 'item1',
        mealPlanId: 'test_id',
        plannedDate: fridayDate,
        mealType: MealPlanItem.lunch,
      );

      fridayLunchItem.mealPlanItemRecipes = [
        MealPlanItemRecipe(
          mealPlanItemId: 'item1',
          recipeId: 'recipe1',
          isPrimaryDish: true,
        )
      ];

      final saturdayDinnerItem = MealPlanItem(
        id: 'item2',
        mealPlanId: 'test_id',
        plannedDate: saturdayDate,
        mealType: MealPlanItem.dinner,
      );

      saturdayDinnerItem.mealPlanItemRecipes = [
        MealPlanItemRecipe(
          mealPlanItemId: 'item2',
          recipeId: 'recipe2',
          isPrimaryDish: true,
        )
      ];

      final items = [fridayLunchItem, saturdayDinnerItem];

      final mealPlan = MealPlan(
        id: 'test_id',
        weekStartDate: weekStart,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        items: items,
      );

      final fridayItems = mealPlan.getItemsForDate(DateTime.parse(fridayDate));
      expect(fridayItems.length, 1);
      expect(fridayItems[0].id, 'item1');
      expect(fridayItems[0].mealPlanItemRecipes![0].recipeId, 'recipe1');

      final saturdayItems =
          mealPlan.getItemsForDate(DateTime.parse(saturdayDate));
      expect(saturdayItems.length, 1);
      expect(saturdayItems[0].id, 'item2');
      expect(saturdayItems[0].mealPlanItemRecipes![0].recipeId, 'recipe2');
    });

    test('filters items by meal type', () {
      final weekStart = DateTime(2023, 6, 2); // A Friday

      // Create meal plan items with associated recipes
      final lunchItem = MealPlanItem(
        id: 'item1',
        mealPlanId: 'test_id',
        plannedDate: '2023-06-02',
        mealType: MealPlanItem.lunch,
      );

      lunchItem.mealPlanItemRecipes = [
        MealPlanItemRecipe(
          mealPlanItemId: 'item1',
          recipeId: 'recipe1',
          isPrimaryDish: true,
        )
      ];

      final dinnerItem = MealPlanItem(
        id: 'item2',
        mealPlanId: 'test_id',
        plannedDate: '2023-06-02',
        mealType: MealPlanItem.dinner,
      );

      dinnerItem.mealPlanItemRecipes = [
        MealPlanItemRecipe(
          mealPlanItemId: 'item2',
          recipeId: 'recipe2',
          isPrimaryDish: true,
        )
      ];

      final items = [lunchItem, dinnerItem];

      final mealPlan = MealPlan(
        id: 'test_id',
        weekStartDate: weekStart,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        items: items,
      );

      final lunchItems = mealPlan.getItemsForMealType(MealPlanItem.lunch);
      expect(lunchItems.length, 1);
      expect(lunchItems[0].id, 'item1');
      expect(lunchItems[0].mealPlanItemRecipes![0].recipeId, 'recipe1');

      final dinnerItems = mealPlan.getItemsForMealType(MealPlanItem.dinner);
      expect(dinnerItems.length, 1);
      expect(dinnerItems[0].id, 'item2');
      expect(dinnerItems[0].mealPlanItemRecipes![0].recipeId, 'recipe2');
    });

    test('filters items by date and meal type', () {
      final weekStart = DateTime(2023, 6, 2); // A Friday
      const fridayDate = '2023-06-02';
      const saturdayDate = '2023-06-03';

      // Create meal plan items with associated recipes
      final fridayLunchItem = MealPlanItem(
        id: 'item1',
        mealPlanId: 'test_id',
        plannedDate: fridayDate,
        mealType: MealPlanItem.lunch,
      );

      fridayLunchItem.mealPlanItemRecipes = [
        MealPlanItemRecipe(
          mealPlanItemId: 'item1',
          recipeId: 'recipe1',
          isPrimaryDish: true,
        )
      ];

      final fridayDinnerItem = MealPlanItem(
        id: 'item2',
        mealPlanId: 'test_id',
        plannedDate: fridayDate,
        mealType: MealPlanItem.dinner,
      );

      fridayDinnerItem.mealPlanItemRecipes = [
        MealPlanItemRecipe(
          mealPlanItemId: 'item2',
          recipeId: 'recipe2',
          isPrimaryDish: true,
        )
      ];

      final saturdayLunchItem = MealPlanItem(
        id: 'item3',
        mealPlanId: 'test_id',
        plannedDate: saturdayDate,
        mealType: MealPlanItem.lunch,
      );

      saturdayLunchItem.mealPlanItemRecipes = [
        MealPlanItemRecipe(
          mealPlanItemId: 'item3',
          recipeId: 'recipe3',
          isPrimaryDish: true,
        )
      ];

      final items = [fridayLunchItem, fridayDinnerItem, saturdayLunchItem];

      final mealPlan = MealPlan(
        id: 'test_id',
        weekStartDate: weekStart,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        items: items,
      );

      final fridayLunchItems = mealPlan.getItemsForDateAndMealType(
          DateTime.parse(fridayDate), MealPlanItem.lunch);
      expect(fridayLunchItems.length, 1);
      expect(fridayLunchItems[0].id, 'item1');
      expect(fridayLunchItems[0].mealPlanItemRecipes![0].recipeId, 'recipe1');

      final saturdayLunchItems = mealPlan.getItemsForDateAndMealType(
          DateTime.parse(saturdayDate), MealPlanItem.lunch);
      expect(saturdayLunchItems.length, 1);
      expect(saturdayLunchItems[0].id, 'item3');
      expect(saturdayLunchItems[0].mealPlanItemRecipes![0].recipeId, 'recipe3');

      final saturdayDinnerItems = mealPlan.getItemsForDateAndMealType(
          DateTime.parse(saturdayDate), MealPlanItem.dinner);
      expect(saturdayDinnerItems, isEmpty);
    });

    test('creates for a specific week correctly', () {
      // Test with a Sunday
      final sunday = DateTime(2023, 6, 4);
      final expectedFriday = DateTime(2023, 6, 2);

      final mealPlan = MealPlan.forWeek('test_id', sunday);

      expect(mealPlan.id, 'test_id');
      expect(mealPlan.weekStartDate, expectedFriday);
      expect(mealPlan.items, isEmpty);

      // Test with a Friday
      final friday = DateTime(2023, 6, 9);
      final mealPlan2 = MealPlan.forWeek('test_id2', friday);

      expect(mealPlan2.id, 'test_id2');
      expect(mealPlan2.weekStartDate, friday);
    });

    test('adds items correctly', () async {
      final weekStart = DateTime(2023, 6, 2); // A Friday
      final mealPlan = MealPlan(
        id: 'test_id',
        weekStartDate: weekStart,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        items: [],
      );

      final initialModifiedAt = mealPlan.modifiedAt;
      // Add a small delay to ensure timestamps can be different
      await Future.delayed(const Duration(milliseconds: 1));

      // Create a new item with an associated recipe
      final newItem = MealPlanItem(
        id: 'item1',
        mealPlanId: 'test_id',
        plannedDate: '2023-06-02',
        mealType: MealPlanItem.lunch,
      );

      newItem.mealPlanItemRecipes = [
        MealPlanItemRecipe(
          mealPlanItemId: 'item1',
          recipeId: 'recipe1',
          isPrimaryDish: true,
        )
      ];

      mealPlan.addItem(newItem);

      expect(mealPlan.items.length, 1);
      expect(mealPlan.items[0].id, 'item1');
      expect(mealPlan.items[0].mealPlanItemRecipes![0].recipeId, 'recipe1');
      expect(mealPlan.modifiedAt.isAfter(initialModifiedAt), true);
    });

    test('removes items correctly', () async {
      final weekStart = DateTime(2023, 6, 2); // A Friday

      // Create items with associated recipes
      final item1 = MealPlanItem(
        id: 'item1',
        mealPlanId: 'test_id',
        plannedDate: '2023-06-02',
        mealType: MealPlanItem.lunch,
      );

      item1.mealPlanItemRecipes = [
        MealPlanItemRecipe(
          mealPlanItemId: 'item1',
          recipeId: 'recipe1',
          isPrimaryDish: true,
        )
      ];

      final item2 = MealPlanItem(
        id: 'item2',
        mealPlanId: 'test_id',
        plannedDate: '2023-06-02',
        mealType: MealPlanItem.dinner,
      );

      item2.mealPlanItemRecipes = [
        MealPlanItemRecipe(
          mealPlanItemId: 'item2',
          recipeId: 'recipe2',
          isPrimaryDish: true,
        )
      ];

      final items = [item1, item2];

      final mealPlan = MealPlan(
        id: 'test_id',
        weekStartDate: weekStart,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        items:
            List.from(items), // Create a copy to avoid modifying the original
      );

      final initialModifiedAt = mealPlan.modifiedAt;

      // Add a small delay to ensure timestamps can be different
      await Future.delayed(const Duration(milliseconds: 1));

      // Remove an item
      final result = mealPlan.removeItem('item1');

      expect(result, true);
      expect(mealPlan.items.length, 1);
      expect(mealPlan.items[0].id, 'item2');
      expect(mealPlan.items[0].mealPlanItemRecipes![0].recipeId, 'recipe2');
      expect(mealPlan.modifiedAt.isAfter(initialModifiedAt), true);

      // Try to remove a non-existent item
      final result2 = mealPlan.removeItem('non-existent');

      expect(result2, false);
      expect(mealPlan.items.length, 1); // No change
    });

    test('updates items correctly', () async {
      final weekStart = DateTime(2023, 6, 2); // A Friday

      // Create an item with an associated recipe
      final item1 = MealPlanItem(
        id: 'item1',
        mealPlanId: 'test_id',
        plannedDate: '2023-06-02',
        mealType: MealPlanItem.lunch,
      );

      item1.mealPlanItemRecipes = [
        MealPlanItemRecipe(
          mealPlanItemId: 'item1',
          recipeId: 'recipe1',
          isPrimaryDish: true,
        )
      ];

      final items = [item1];

      final mealPlan = MealPlan(
        id: 'test_id',
        weekStartDate: weekStart,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        items: List.from(items),
      );

      final initialModifiedAt = mealPlan.modifiedAt;

      // Add a small delay to ensure timestamps can be different
      await Future.delayed(const Duration(milliseconds: 1));

      // Create an updated item with a different recipe
      final updatedItem = MealPlanItem(
        id: 'item1',
        mealPlanId: 'test_id',
        plannedDate: '2023-06-02',
        mealType: MealPlanItem.lunch,
      );

      updatedItem.mealPlanItemRecipes = [
        MealPlanItemRecipe(
          mealPlanItemId: 'item1',
          recipeId: 'recipe2', // Changed recipe
          isPrimaryDish: true,
        )
      ];

      final result = mealPlan.updateItem(updatedItem);

      expect(result, true);
      expect(mealPlan.items.length, 1);
      expect(mealPlan.items[0].mealPlanItemRecipes![0].recipeId, 'recipe2');
      expect(mealPlan.modifiedAt.isAfter(initialModifiedAt), true);

      // Try to update a non-existent item
      final nonExistentItem = MealPlanItem(
        id: 'non-existent',
        mealPlanId: 'test_id',
        plannedDate: '2023-06-02',
        mealType: MealPlanItem.lunch,
      );

      nonExistentItem.mealPlanItemRecipes = [
        MealPlanItemRecipe(
          mealPlanItemId: 'non-existent',
          recipeId: 'recipe3',
          isPrimaryDish: true,
        )
      ];

      final result2 = mealPlan.updateItem(nonExistentItem);

      expect(result2, false);
      expect(mealPlan.items.length, 1); // No change
      expect(mealPlan.items[0].id, 'item1'); // Original item still there
      expect(mealPlan.items[0].mealPlanItemRecipes![0].recipeId,
          'recipe2'); // Original recipe still there
    });

    test('handles multiple recipes per meal item', () async {
      final weekStart = DateTime(2023, 6, 2); // A Friday

      // Create an item with multiple recipes
      final item = MealPlanItem(
        id: 'item1',
        mealPlanId: 'test_id',
        plannedDate: '2023-06-02',
        mealType: MealPlanItem.lunch,
      );

      item.mealPlanItemRecipes = [
        MealPlanItemRecipe(
          mealPlanItemId: 'item1',
          recipeId: 'main_dish',
          isPrimaryDish: true,
        ),
        MealPlanItemRecipe(
          mealPlanItemId: 'item1',
          recipeId: 'side_dish_1',
          isPrimaryDish: false,
        ),
        MealPlanItemRecipe(
          mealPlanItemId: 'item1',
          recipeId: 'side_dish_2',
          isPrimaryDish: false,
        )
      ];

      final mealPlan = MealPlan(
        id: 'test_id',
        weekStartDate: weekStart,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        items: [item],
      );

      // Verify we can access all recipes for the meal
      expect(mealPlan.items.length, 1);
      expect(mealPlan.items[0].mealPlanItemRecipes!.length, 3);

      // Verify primary dish is marked correctly
      final primaryDishes = mealPlan.items[0].mealPlanItemRecipes!
          .where((recipe) => recipe.isPrimaryDish)
          .toList();
      expect(primaryDishes.length, 1);
      expect(primaryDishes[0].recipeId, 'main_dish');

      // Verify side dishes
      final sideDishes = mealPlan.items[0].mealPlanItemRecipes!
          .where((recipe) => !recipe.isPrimaryDish)
          .toList();
      expect(sideDishes.length, 2);
      expect(sideDishes[0].recipeId, 'side_dish_1');
      expect(sideDishes[1].recipeId, 'side_dish_2');
    });
  });
}
