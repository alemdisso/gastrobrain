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

  test('handles null notes in fromMap', () {
    final now = DateTime.now();
    final weekStart = DateTime(2023, 6, 2); // A Friday

    final map = {
      'id': 'test_id',
      'week_start_date': weekStart.toIso8601String(),
      'notes': null, // Explicitly null notes
      'created_at': now.toIso8601String(),
      'modified_at': now.toIso8601String(),
    };

    final mealPlan = MealPlan.fromMap(map, []);
    expect(mealPlan.notes, ''); // Should default to empty string
  });

  test('getItemsForDate handles invalid dates gracefully', () {
    final weekStart = DateTime(2023, 6, 2); // A Friday

    // Create a meal plan with one item
    final fridayItem = MealPlanItem(
      id: 'item1',
      mealPlanId: 'test_id',
      plannedDate: '2023-06-02',
      mealType: MealPlanItem.lunch,
    );

    final mealPlan = MealPlan(
      id: 'test_id',
      weekStartDate: weekStart,
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
      items: [fridayItem],
    );

    // Test with null date - should return empty list rather than crashing
    // This test won't compile if getItemsForDate doesn't handle null safely,
    // but we'd need to modify the method signature to accept nullable DateTime
    // Since the method doesn't accept null currently, we'll skip this test

    // Test with date outside week range
    final outsideWeekDate = DateTime(2023, 6, 10); // Beyond week end
    final outsideWeekItems = mealPlan.getItemsForDate(outsideWeekDate);
    expect(outsideWeekItems, isEmpty);

    // Test with malformed date string in items
    // This requires modifying an item with an invalid date format
    // (would need to bypass constructor validation to create such an item)

    // For now, we'll test with a properly formatted but non-existent date
    final nonExistentDate = DateTime(2023, 6, 3); // Saturday with no items
    final noItemsResult = mealPlan.getItemsForDate(nonExistentDate);
    expect(noItemsResult, isEmpty);
  });

  test('handles extreme date ranges correctly', () {
    // Test with distant past
    final distantPast = DateTime(1900, 1, 1);
    final pastPlan = MealPlan.forWeek('past_id', distantPast);

    // Calculate expected start (previous Friday or same day if Friday)
    final expectedPastStart = DateTime(1899, 12, 29); // Previous Friday

    expect(pastPlan.weekStartDate, expectedPastStart);
    expect(
        pastPlan.weekEndDate, expectedPastStart.add(const Duration(days: 6)));

    // Test with distant future
    final distantFuture = DateTime(2100, 1, 1);
    final futurePlan = MealPlan.forWeek('future_id', distantFuture);

    // Calculate expected start - January 1, 2100 is a Saturday, so previous Friday is December 31, 2099
    final expectedFutureStart =
        DateTime(2100, 1, 1); // Actually the date itself

    expect(futurePlan.weekStartDate, expectedFutureStart);
    expect(futurePlan.weekEndDate,
        expectedFutureStart.add(const Duration(days: 6)));
  });

  test('normalizes date comparisons correctly in getItemsForDate', () {
    final weekStart = DateTime(2023, 6, 2); // A Friday

    // Create item with time component in the date
    final item = MealPlanItem(
      id: 'item1',
      mealPlanId: 'test_id',
      plannedDate: '2023-06-02',
      mealType: MealPlanItem.lunch,
    );

    final mealPlan = MealPlan(
      id: 'test_id',
      weekStartDate: weekStart,
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
      items: [item],
    );

    // Create a date with time component
    final dateWithTime = DateTime(2023, 6, 2, 14, 30, 0); // 2:30 PM

    // Should still find the item despite different time components
    final items = mealPlan.getItemsForDate(dateWithTime);
    expect(items.length, 1);
    expect(items[0].id, 'item1');
  });

  test('handles week transitions correctly', () {
    // Test with December 31st (Sunday) transitioning to January
    final newYearsEve = DateTime(2023, 12, 31); // Sunday
    final newYearsPlan = MealPlan.forWeek('new_years_id', newYearsEve);

    // The previous Friday would be December 29, 2023
    final expectedNewYearsStart = DateTime(2023, 12, 29);

    expect(newYearsPlan.weekStartDate, expectedNewYearsStart);
    expect(newYearsPlan.weekEndDate,
        DateTime(2024, 1, 4)); // Should span into next year

    // Test with February 28 in a leap year (2024)
    final leapYearFeb = DateTime(2024, 2, 28); // Wednesday in leap year
    final leapPlan = MealPlan.forWeek('leap_id', leapYearFeb);

    // The previous Friday would be February 23, 2024
    final expectedLeapStart = DateTime(2024, 2, 23);

    expect(leapPlan.weekStartDate, expectedLeapStart);
    expect(
        leapPlan.weekEndDate, DateTime(2024, 2, 29)); // Should include leap day
  });
}
