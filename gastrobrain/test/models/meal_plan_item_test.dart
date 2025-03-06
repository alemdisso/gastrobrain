// test/models/meal_plan_item_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/meal_plan_item.dart';
import 'package:gastrobrain/models/meal_plan_item_recipe.dart';

void main() {
  group('MealPlanItem', () {
    test('creates with required fields', () {
      final item = MealPlanItem(
        id: 'test_id',
        mealPlanId: 'plan_id',
        plannedDate: '2023-06-05',
        mealType: MealPlanItem.lunch,
      );

      expect(item.id, 'test_id');
      expect(item.mealPlanId, 'plan_id');
      expect(item.plannedDate, '2023-06-05');
      expect(item.mealType, MealPlanItem.lunch);
      expect(item.notes, '');
      expect(item.mealPlanItemRecipes, isNull);
    });

    test('throws when invalid meal type is provided', () {
      expect(
          () => MealPlanItem(
                id: 'test_id',
                mealPlanId: 'plan_id',
                plannedDate: '2023-06-05',
                mealType: 'invalid',
              ),
          throwsArgumentError);
    });

    test('converts to map correctly', () {
      final item = MealPlanItem(
        id: 'test_id',
        mealPlanId: 'plan_id',
        plannedDate: '2023-06-05',
        mealType: MealPlanItem.dinner,
        notes: 'Test notes',
      );

      final map = item.toMap();
      expect(map['id'], 'test_id');
      expect(map['meal_plan_id'], 'plan_id');
      expect(map['planned_date'], '2023-06-05');
      expect(map['meal_type'], MealPlanItem.dinner);
      expect(map['notes'], 'Test notes');
      // Note: mealPlanItemRecipes is not included in the map
    });

    test('creates from map correctly', () {
      final map = {
        'id': 'test_id',
        'meal_plan_id': 'plan_id',
        'planned_date': '2023-06-05',
        'meal_type': MealPlanItem.dinner,
        'notes': 'Test notes',
      };

      final item = MealPlanItem.fromMap(map);
      expect(item.id, 'test_id');
      expect(item.mealPlanId, 'plan_id');
      expect(item.plannedDate, '2023-06-05');
      expect(item.mealType, MealPlanItem.dinner);
      expect(item.notes, 'Test notes');
      expect(item.mealPlanItemRecipes, isNull);
    });

    test('handles null notes in fromMap', () {
      final map = {
        'id': 'test_id',
        'meal_plan_id': 'plan_id',
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
        plannedDate: '2023-06-05',
        mealType: MealPlanItem.lunch,
        notes: 'Original notes',
      );

      // Create associated recipes
      final recipes = [
        MealPlanItemRecipe(
          mealPlanItemId: 'test_id',
          recipeId: 'recipe_id_1',
          isPrimaryDish: true,
        )
      ];
      original.mealPlanItemRecipes = recipes;

      // Change planned date and meal type
      final copy = original.copyWith(
        plannedDate: '2023-06-06',
        mealType: MealPlanItem.dinner,
      );

      expect(copy.id, original.id);
      expect(copy.mealPlanId, original.mealPlanId);
      expect(copy.plannedDate, '2023-06-06');
      expect(copy.mealType, MealPlanItem.dinner);
      expect(copy.notes, original.notes);
      expect(copy.mealPlanItemRecipes, original.mealPlanItemRecipes);

      // Change recipes
      final newRecipes = [
        MealPlanItemRecipe(
          mealPlanItemId: 'test_id',
          recipeId: 'recipe_id_2',
          isPrimaryDish: true,
        )
      ];

      final copy2 = original.copyWith(
        mealPlanItemRecipes: newRecipes,
      );

      expect(copy2.id, original.id);
      expect(copy2.mealPlanId, original.mealPlanId);
      expect(copy2.plannedDate, original.plannedDate);
      expect(copy2.mealType, original.mealType);
      expect(copy2.notes, original.notes);
      expect(copy2.mealPlanItemRecipes, newRecipes);
      expect(copy2.mealPlanItemRecipes![0].recipeId, 'recipe_id_2');
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

    test('correctly handles associated recipes', () {
      final item = MealPlanItem(
        id: 'test_id',
        mealPlanId: 'plan_id',
        plannedDate: '2023-06-05',
        mealType: MealPlanItem.lunch,
      );

      // Initially no recipes
      expect(item.mealPlanItemRecipes, isNull);

      // Add recipes
      final recipes = [
        MealPlanItemRecipe(
          mealPlanItemId: 'test_id',
          recipeId: 'recipe_id_1',
          isPrimaryDish: true,
        ),
        MealPlanItemRecipe(
          mealPlanItemId: 'test_id',
          recipeId: 'recipe_id_2',
          isPrimaryDish: false,
        ),
      ];

      item.mealPlanItemRecipes = recipes;
      expect(item.mealPlanItemRecipes!.length, 2);
      expect(item.mealPlanItemRecipes![0].recipeId, 'recipe_id_1');
      expect(item.mealPlanItemRecipes![0].isPrimaryDish, isTrue);
      expect(item.mealPlanItemRecipes![1].recipeId, 'recipe_id_2');
      expect(item.mealPlanItemRecipes![1].isPrimaryDish, isFalse);
    });
  });
}
