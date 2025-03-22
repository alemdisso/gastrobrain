// test/models/meal_plan_item_recipe_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/meal_plan_item_recipe.dart';

void main() {
  group('MealPlanItemRecipe', () {
    test('creates with required fields', () {
      final mealPlanItemRecipe = MealPlanItemRecipe(
        mealPlanItemId: 'meal-plan-item-1',
        recipeId: 'recipe-1',
      );

      expect(mealPlanItemRecipe.mealPlanItemId, 'meal-plan-item-1');
      expect(mealPlanItemRecipe.recipeId, 'recipe-1');
      expect(mealPlanItemRecipe.isPrimaryDish, false); // Default value
      expect(mealPlanItemRecipe.notes, isNull); // Default value
      expect(mealPlanItemRecipe.id, isNotNull); // UUID should be generated
      expect(mealPlanItemRecipe.id.length, greaterThan(0));
    });

    test('creates with all fields specified', () {
      final mealPlanItemRecipe = MealPlanItemRecipe(
        id: 'custom-id',
        mealPlanItemId: 'meal-plan-item-1',
        recipeId: 'recipe-1',
        isPrimaryDish: true,
        notes: 'Test notes',
      );

      expect(mealPlanItemRecipe.id, 'custom-id');
      expect(mealPlanItemRecipe.mealPlanItemId, 'meal-plan-item-1');
      expect(mealPlanItemRecipe.recipeId, 'recipe-1');
      expect(mealPlanItemRecipe.isPrimaryDish, true);
      expect(mealPlanItemRecipe.notes, 'Test notes');
    });
    test('converts to map correctly', () {
      final mealPlanItemRecipe = MealPlanItemRecipe(
        id: 'test-id',
        mealPlanItemId: 'meal-plan-item-1',
        recipeId: 'recipe-1',
        isPrimaryDish: true,
        notes: 'Test notes',
      );

      final map = mealPlanItemRecipe.toMap();

      expect(map['id'], 'test-id');
      expect(map['meal_plan_item_id'], 'meal-plan-item-1');
      expect(map['recipe_id'], 'recipe-1');
      expect(
          map['is_primary_dish'], 1); // Boolean true should be converted to 1
      expect(map['notes'], 'Test notes');
    });
    test('creates from map correctly', () {
      final map = {
        'id': 'test-id',
        'meal_plan_item_id': 'meal-plan-item-1',
        'recipe_id': 'recipe-1',
        'is_primary_dish': 1,
        'notes': 'Test notes',
      };

      final mealPlanItemRecipe = MealPlanItemRecipe.fromMap(map);

      expect(mealPlanItemRecipe.id, 'test-id');
      expect(mealPlanItemRecipe.mealPlanItemId, 'meal-plan-item-1');
      expect(mealPlanItemRecipe.recipeId, 'recipe-1');
      expect(mealPlanItemRecipe.isPrimaryDish,
          true); // 1 should be converted to true
      expect(mealPlanItemRecipe.notes, 'Test notes');
    });
    test('copyWith creates a new instance with specified changes', () {
      final original = MealPlanItemRecipe(
        id: 'test-id',
        mealPlanItemId: 'meal-plan-item-1',
        recipeId: 'recipe-1',
        isPrimaryDish: false,
        notes: 'Original notes',
      );

      // Test changing one field
      final copy1 = original.copyWith(
        isPrimaryDish: true,
      );
      expect(copy1.id, original.id);
      expect(copy1.mealPlanItemId, original.mealPlanItemId);
      expect(copy1.recipeId, original.recipeId);
      expect(copy1.isPrimaryDish, true); // Changed
      expect(copy1.notes, original.notes);

      // Test changing multiple fields
      final copy2 = original.copyWith(
        recipeId: 'recipe-2',
        notes: 'Updated notes',
      );
      expect(copy2.id, original.id);
      expect(copy2.mealPlanItemId, original.mealPlanItemId);
      expect(copy2.recipeId, 'recipe-2'); // Changed
      expect(copy2.isPrimaryDish, original.isPrimaryDish);
      expect(copy2.notes, 'Updated notes'); // Changed
    });
    test('handles boolean to integer conversion correctly', () {
      // Test true -> 1 conversion (toMap)
      final primaryRecipe = MealPlanItemRecipe(
        mealPlanItemId: 'item-1',
        recipeId: 'recipe-1',
        isPrimaryDish: true,
      );
      expect(primaryRecipe.toMap()['is_primary_dish'], 1);

      // Test false -> 0 conversion (toMap)
      final secondaryRecipe = MealPlanItemRecipe(
        mealPlanItemId: 'item-1',
        recipeId: 'recipe-2',
        isPrimaryDish: false,
      );
      expect(secondaryRecipe.toMap()['is_primary_dish'], 0);

      // Test 1 -> true conversion (fromMap)
      final primaryMap = {
        'id': 'test-id',
        'meal_plan_item_id': 'item-1',
        'recipe_id': 'recipe-1',
        'is_primary_dish': 1,
      };
      expect(MealPlanItemRecipe.fromMap(primaryMap).isPrimaryDish, true);

      // Test 0 -> false conversion (fromMap)
      final secondaryMap = {
        'id': 'test-id',
        'meal_plan_item_id': 'item-1',
        'recipe_id': 'recipe-2',
        'is_primary_dish': 0,
      };
      expect(MealPlanItemRecipe.fromMap(secondaryMap).isPrimaryDish, false);
    });
    test('handles null values in fromMap correctly', () {
      // Test with null notes
      final mapWithNullNotes = {
        'id': 'test-id',
        'meal_plan_item_id': 'item-1',
        'recipe_id': 'recipe-1',
        'is_primary_dish': 1,
        'notes': null,
      };
      final resultWithNullNotes = MealPlanItemRecipe.fromMap(mapWithNullNotes);
      expect(resultWithNullNotes.notes, isNull);

      // Test with missing is_primary_dish (should default to false)
      final mapWithoutIsPrimary = {
        'id': 'test-id',
        'meal_plan_item_id': 'item-1',
        'recipe_id': 'recipe-1',
      };
      final resultWithoutIsPrimary =
          MealPlanItemRecipe.fromMap(mapWithoutIsPrimary);
      expect(resultWithoutIsPrimary.isPrimaryDish, false);
    });
    test('different instances with same properties are unique objects', () {
      final recipe1 = MealPlanItemRecipe(
        id: 'test-id',
        mealPlanItemId: 'item-1',
        recipeId: 'recipe-1',
        isPrimaryDish: true,
      );

      final recipe2 = MealPlanItemRecipe(
        id: 'test-id',
        mealPlanItemId: 'item-1',
        recipeId: 'recipe-1',
        isPrimaryDish: true,
      );

      // Should be equal in value but not the same object
      expect(recipe1.id, recipe2.id);
      expect(recipe1.mealPlanItemId, recipe2.mealPlanItemId);
      expect(recipe1.recipeId, recipe2.recipeId);
      expect(recipe1.isPrimaryDish, recipe2.isPrimaryDish);

      // But they should be different object instances
      expect(identical(recipe1, recipe2), false);

      // Modifying one should not affect the other
      final updatedRecipe = recipe1.copyWith(notes: 'Updated notes');
      expect(updatedRecipe.notes, 'Updated notes');
      expect(recipe2.notes, isNull);
    });
    test('handles edge cases in data correctly', () {
      // Test with empty strings (these should be allowed but preserved)
      final emptyStringRecipe = MealPlanItemRecipe(
        id: '',
        mealPlanItemId: '',
        recipeId: '',
        notes: '',
      );

      // Verify empty strings are preserved in toMap and fromMap
      final emptyMap = emptyStringRecipe.toMap();
      final recreatedRecipe = MealPlanItemRecipe.fromMap(emptyMap);

      expect(recreatedRecipe.id, '');
      expect(recreatedRecipe.mealPlanItemId, '');
      expect(recreatedRecipe.recipeId, '');
      expect(recreatedRecipe.notes, '');

      // Test with very long strings
      final longString = 'a' * 1000;
      final longStringRecipe = MealPlanItemRecipe(
        mealPlanItemId: 'item-1',
        recipeId: 'recipe-1',
        notes: longString,
      );

      final longStringMap = longStringRecipe.toMap();
      final recreatedLongStringRecipe =
          MealPlanItemRecipe.fromMap(longStringMap);

      expect(recreatedLongStringRecipe.notes, longString);
      expect(recreatedLongStringRecipe.notes?.length, 1000);
    });
  });
}
