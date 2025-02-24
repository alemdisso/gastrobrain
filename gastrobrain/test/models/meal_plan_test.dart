// test/models/meal_plan_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/meal_plan.dart';
import 'package:gastrobrain/models/meal_plan_item.dart';
import 'package:gastrobrain/utils/id_generator.dart';

void main() {
  group('MealPlan', () {
    test('creates with required fields', () {
      final now = DateTime.now();
      final weekStart = DateTime(2023, 6, 5); // A Monday

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
      final weekStart = DateTime(2023, 6, 5); // A Monday

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
      final weekStart = DateTime(2023, 6, 5); // A Monday

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
          plannedDate: '2023-06-05',
          mealType: MealPlanItem.LUNCH,
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
      final weekStart = DateTime(2023, 6, 5); // A Monday
      final expectedWeekEnd = DateTime(2023, 6, 11); // Sunday

      final mealPlan = MealPlan(
        id: 'test_id',
        weekStartDate: weekStart,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );

      expect(mealPlan.weekEndDate, expectedWeekEnd);
    });

    test('filters items by date', () {
      final weekStart = DateTime(2023, 6, 5); // A Monday
      final mondayDate = '2023-06-05';
      final tuesdayDate = '2023-06-06';

      final items = [
        MealPlanItem(
          id: 'item1',
          mealPlanId: 'test_id',
          recipeId: 'recipe1',
          plannedDate: mondayDate,
          mealType: MealPlanItem.LUNCH,
        ),
        MealPlanItem(
          id: 'item2',
          mealPlanId: 'test_id',
          recipeId: 'recipe2',
          plannedDate: tuesdayDate,
          mealType: MealPlanItem.DINNER,
        ),
      ];

      final mealPlan = MealPlan(
        id: 'test_id',
        weekStartDate: weekStart,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        items: items,
      );

      final mondayItems = mealPlan.getItemsForDate(DateTime.parse(mondayDate));
      expect(mondayItems.length, 1);
      expect(mondayItems[0].id, 'item1');

      final tuesdayItems =
          mealPlan.getItemsForDate(DateTime.parse(tuesdayDate));
      expect(tuesdayItems.length, 1);
      expect(tuesdayItems[0].id, 'item2');
    });
  });
}
