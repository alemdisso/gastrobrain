// test/models/meal_plan_item_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/meal_plan_item.dart';

void main() {
  group('MealPlanItem', () {
    test('creates with required fields', () {
      final item = MealPlanItem(
        id: 'test_id',
        mealPlanId: 'plan_id',
        recipeId: 'recipe_id',
        plannedDate: '2023-06-05',
        mealType: MealPlanItem.lunch,
      );

      expect(item.id, 'test_id');
      expect(item.mealPlanId, 'plan_id');
      expect(item.recipeId, 'recipe_id');
      expect(item.plannedDate, '2023-06-05');
      expect(item.mealType, MealPlanItem.lunch);
      expect(item.notes, '');
    });

    test('throws when invalid meal type is provided', () {
      expect(
          () => MealPlanItem(
                id: 'test_id',
                mealPlanId: 'plan_id',
                recipeId: 'recipe_id',
                plannedDate: '2023-06-05',
                mealType: 'invalid',
              ),
          throwsArgumentError);
    });

    test('converts to map correctly', () {
      final item = MealPlanItem(
        id: 'test_id',
        mealPlanId: 'plan_id',
        recipeId: 'recipe_id',
        plannedDate: '2023-06-05',
        mealType: MealPlanItem.dinner,
        notes: 'Test notes',
      );

      final map = item.toMap();
      expect(map['id'], 'test_id');
      expect(map['meal_plan_id'], 'plan_id');
      expect(map['recipe_id'], 'recipe_id');
      expect(map['planned_date'], '2023-06-05');
      expect(map['meal_type'], MealPlanItem.dinner);
      expect(map['notes'], 'Test notes');
    });

    test('creates from map correctly', () {
      final map = {
        'id': 'test_id',
        'meal_plan_id': 'plan_id',
        'recipe_id': 'recipe_id',
        'planned_date': '2023-06-05',
        'meal_type': MealPlanItem.dinner,
        'notes': 'Test notes',
      };

      final item = MealPlanItem.fromMap(map);
      expect(item.id, 'test_id');
      expect(item.mealPlanId, 'plan_id');
      expect(item.recipeId, 'recipe_id');
      expect(item.plannedDate, '2023-06-05');
      expect(item.mealType, MealPlanItem.dinner);
      expect(item.notes, 'Test notes');
    });

    test('handles null notes in fromMap', () {
      final map = {
        'id': 'test_id',
        'meal_plan_id': 'plan_id',
        'recipe_id': 'recipe_id',
        'planned_date': '2023-06-05',
        'meal_type': MealPlanItem.lunch,
        'notes': null,
      };

      final item = MealPlanItem.fromMap(map);
      expect(item.notes, '');
    });

    test('copyWith creates new instance with specified changes', () {
      final original = MealPlanItem(
        id: 'test_id',
        mealPlanId: 'plan_id',
        recipeId: 'recipe_id',
        plannedDate: '2023-06-05',
        mealType: MealPlanItem.lunch,
        notes: 'Original notes',
      );

      // Change recipe and notes
      final copy1 = original.copyWith(
        recipeId: 'new_recipe',
        notes: 'Updated notes',
      );

      expect(copy1.id, original.id);
      expect(copy1.mealPlanId, original.mealPlanId);
      expect(copy1.recipeId, 'new_recipe');
      expect(copy1.plannedDate, original.plannedDate);
      expect(copy1.mealType, original.mealType);
      expect(copy1.notes, 'Updated notes');

      // Change planned date and meal type
      final copy2 = original.copyWith(
        plannedDate: '2023-06-06',
        mealType: MealPlanItem.dinner,
      );

      expect(copy2.id, original.id);
      expect(copy2.mealPlanId, original.mealPlanId);
      expect(copy2.recipeId, original.recipeId);
      expect(copy2.plannedDate, '2023-06-06');
      expect(copy2.mealType, MealPlanItem.dinner);
      expect(copy2.notes, original.notes);
    });

    test('formatPlannedDate correctly formats date object to string', () {
      final date = DateTime(2023, 6, 5);
      final formatted = MealPlanItem.formatPlannedDate(date);
      expect(formatted, '2023-06-05');

      // Test with single digit month and day
      final date2 = DateTime(2023, 1, 2);
      final formatted2 = MealPlanItem.formatPlannedDate(date2);
      expect(formatted2, '2023-01-02');
    });
  });
}
