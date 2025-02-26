// test/models/meal_plan_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/meal_plan.dart';
import 'package:gastrobrain/models/meal_plan_item.dart';

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
          recipeId: 'recipe1',
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

      final items = [
        MealPlanItem(
          id: 'item1',
          mealPlanId: 'test_id',
          recipeId: 'recipe1',
          plannedDate: fridayDate,
          mealType: MealPlanItem.lunch,
        ),
        MealPlanItem(
          id: 'item2',
          mealPlanId: 'test_id',
          recipeId: 'recipe2',
          plannedDate: saturdayDate,
          mealType: MealPlanItem.dinner,
        ),
      ];

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

      final saturdayItems =
          mealPlan.getItemsForDate(DateTime.parse(saturdayDate));
      expect(saturdayItems.length, 1);
      expect(saturdayItems[0].id, 'item2');
    });

    test('filters items by meal type', () {
      final weekStart = DateTime(2023, 6, 2); // A Friday

      final items = [
        MealPlanItem(
          id: 'item1',
          mealPlanId: 'test_id',
          recipeId: 'recipe1',
          plannedDate: '2023-06-02',
          mealType: MealPlanItem.lunch,
        ),
        MealPlanItem(
          id: 'item2',
          mealPlanId: 'test_id',
          recipeId: 'recipe2',
          plannedDate: '2023-06-02',
          mealType: MealPlanItem.dinner,
        ),
      ];

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

      final dinnerItems = mealPlan.getItemsForMealType(MealPlanItem.dinner);
      expect(dinnerItems.length, 1);
      expect(dinnerItems[0].id, 'item2');
    });

    test('filters items by date and meal type', () {
      final weekStart = DateTime(2023, 6, 2); // A Friday
      const fridayDate = '2023-06-02';
      const saturdayDate = '2023-06-03';

      final items = [
        MealPlanItem(
          id: 'item1',
          mealPlanId: 'test_id',
          recipeId: 'recipe1',
          plannedDate: fridayDate,
          mealType: MealPlanItem.lunch,
        ),
        MealPlanItem(
          id: 'item2',
          mealPlanId: 'test_id',
          recipeId: 'recipe2',
          plannedDate: fridayDate,
          mealType: MealPlanItem.dinner,
        ),
        MealPlanItem(
          id: 'item3',
          mealPlanId: 'test_id',
          recipeId: 'recipe3',
          plannedDate: saturdayDate,
          mealType: MealPlanItem.lunch,
        ),
      ];

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

      final saturdayLunchItems = mealPlan.getItemsForDateAndMealType(
          DateTime.parse(saturdayDate), MealPlanItem.lunch);
      expect(saturdayLunchItems.length, 1);
      expect(saturdayLunchItems[0].id, 'item3');

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

      // Add a new item
      final newItem = MealPlanItem(
        id: 'item1',
        mealPlanId: 'test_id',
        recipeId: 'recipe1',
        plannedDate: '2023-06-02',
        mealType: MealPlanItem.lunch,
      );

      mealPlan.addItem(newItem);

      expect(mealPlan.items.length, 1);
      expect(mealPlan.items[0].id, 'item1');
      expect(mealPlan.modifiedAt.isAfter(initialModifiedAt), true);
    });

    test('removes items correctly', () async {
      final weekStart = DateTime(2023, 6, 2); // A Friday
      final items = [
        MealPlanItem(
          id: 'item1',
          mealPlanId: 'test_id',
          recipeId: 'recipe1',
          plannedDate: '2023-06-02',
          mealType: MealPlanItem.lunch,
        ),
        MealPlanItem(
          id: 'item2',
          mealPlanId: 'test_id',
          recipeId: 'recipe2',
          plannedDate: '2023-06-02',
          mealType: MealPlanItem.dinner,
        ),
      ];

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
      expect(mealPlan.modifiedAt.isAfter(initialModifiedAt), true);

      // Try to remove a non-existent item
      final result2 = mealPlan.removeItem('non-existent');

      expect(result2, false);
      expect(mealPlan.items.length, 1); // No change
    });

    test('updates items correctly', () async {
      final weekStart = DateTime(2023, 6, 2); // A Friday
      final items = [
        MealPlanItem(
          id: 'item1',
          mealPlanId: 'test_id',
          recipeId: 'recipe1',
          plannedDate: '2023-06-02',
          mealType: MealPlanItem.lunch,
        ),
      ];

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

      // Update an item
      final updatedItem = MealPlanItem(
        id: 'item1',
        mealPlanId: 'test_id',
        recipeId: 'recipe2', // Changed recipe
        plannedDate: '2023-06-02',
        mealType: MealPlanItem.lunch,
      );

      final result = mealPlan.updateItem(updatedItem);

      expect(result, true);
      expect(mealPlan.items.length, 1);
      expect(mealPlan.items[0].recipeId, 'recipe2');
      expect(mealPlan.modifiedAt.compareTo(initialModifiedAt) >= 0, true);

      // Try to update a non-existent item
      final nonExistentItem = MealPlanItem(
        id: 'non-existent',
        mealPlanId: 'test_id',
        recipeId: 'recipe3',
        plannedDate: '2023-06-02',
        mealType: MealPlanItem.lunch,
      );

      final result2 = mealPlan.updateItem(nonExistentItem);

      expect(result2, false);
      expect(mealPlan.items.length, 1); // No change
      expect(mealPlan.items[0].id, 'item1'); // Original item still there
    });
  });
}
