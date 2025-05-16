// test/models/meal_recipe_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/meal_recipe.dart';

void main() {
  group('MealRecipe', () {
    test('creates with required fields', () {
      final mealRecipe = MealRecipe(
        mealId: 'meal_123',
        recipeId: 'recipe_456',
      );

      expect(mealRecipe.id.isNotEmpty, true); // Auto-generated ID
      expect(mealRecipe.mealId, 'meal_123');
      expect(mealRecipe.recipeId, 'recipe_456');
      expect(mealRecipe.isPrimaryDish, false); // Default value
      expect(mealRecipe.notes, isNull); // Default value
    });

    test('creates with all fields and converts to map correctly', () {
      final mealRecipe = MealRecipe(
        id: 'test_id',
        mealId: 'meal_123',
        recipeId: 'recipe_456',
        isPrimaryDish: true,
        notes: 'Main dish for dinner',
      );

      // Verify all fields are set correctly
      expect(mealRecipe.id, 'test_id');
      expect(mealRecipe.mealId, 'meal_123');
      expect(mealRecipe.recipeId, 'recipe_456');
      expect(mealRecipe.isPrimaryDish, true);
      expect(mealRecipe.notes, 'Main dish for dinner');

      // Verify toMap creates the correct map representation
      final map = mealRecipe.toMap();
      expect(map['id'], 'test_id');
      expect(map['meal_id'], 'meal_123');
      expect(map['recipe_id'], 'recipe_456');
      expect(map['is_primary_dish'], 1); // Boolean converted to integer
      expect(map['notes'], 'Main dish for dinner');
    });

    test('creates from map correctly', () {
      final map = {
        'id': 'test_id',
        'meal_id': 'meal_123',
        'recipe_id': 'recipe_456',
        'is_primary_dish': 1,
        'notes': 'Side dish for lunch',
      };

      final mealRecipe = MealRecipe.fromMap(map);

      expect(mealRecipe.id, 'test_id');
      expect(mealRecipe.mealId, 'meal_123');
      expect(mealRecipe.recipeId, 'recipe_456');
      expect(mealRecipe.isPrimaryDish, true); // Integer 1 converted to true
      expect(mealRecipe.notes, 'Side dish for lunch');
    });
    test('copyWith creates new instance with specified changes', () {
      final original = MealRecipe(
        id: 'test_id',
        mealId: 'meal_123',
        recipeId: 'recipe_456',
        isPrimaryDish: false,
        notes: 'Original notes',
      );

      // Change primary dish status and notes
      final modified = original.copyWith(
        isPrimaryDish: true,
        notes: 'Updated notes',
      );

      // Verify unchanged fields remain the same
      expect(modified.id, original.id);
      expect(modified.mealId, original.mealId);
      expect(modified.recipeId, original.recipeId);

      // Verify changed fields
      expect(modified.isPrimaryDish, true);
      expect(modified.notes, 'Updated notes');

      // Verify original is not modified
      expect(original.isPrimaryDish, false);
      expect(original.notes, 'Original notes');
    });
    test('handles boolean to integer conversion correctly', () {
      // Test true → 1 conversion in toMap
      final primaryDish = MealRecipe(
        mealId: 'meal_123',
        recipeId: 'recipe_456',
        isPrimaryDish: true,
      );
      expect(primaryDish.toMap()['is_primary_dish'], 1);

      // Test false → 0 conversion in toMap
      final sideDish = MealRecipe(
        mealId: 'meal_123',
        recipeId: 'recipe_456',
        isPrimaryDish: false,
      );
      expect(sideDish.toMap()['is_primary_dish'], 0);

      // Test 1 → true conversion in fromMap
      final mapWithOne = {
        'id': 'test_id',
        'meal_id': 'meal_123',
        'recipe_id': 'recipe_456',
        'is_primary_dish': 1,
      };
      expect(MealRecipe.fromMap(mapWithOne).isPrimaryDish, true);

      // Test 0 → false conversion in fromMap
      final mapWithZero = {
        'id': 'test_id',
        'meal_id': 'meal_123',
        'recipe_id': 'recipe_456',
        'is_primary_dish': 0,
      };
      expect(MealRecipe.fromMap(mapWithZero).isPrimaryDish, false);
    });

    test('handles null values correctly', () {
      // Test with null notes in constructor
      final nullNotes = MealRecipe(
        mealId: 'meal_123',
        recipeId: 'recipe_456',
        notes: null,
      );
      expect(nullNotes.notes, isNull);

      // Verify null notes are included in map
      final map = nullNotes.toMap();
      expect(map.containsKey('notes'), isTrue);
      expect(map['notes'], isNull);

      // Test with null notes in fromMap
      final mapWithNullNotes = {
        'id': 'test_id',
        'meal_id': 'meal_123',
        'recipe_id': 'recipe_456',
        'is_primary_dish': 0,
        'notes': null,
      };
      final fromMapNullNotes = MealRecipe.fromMap(mapWithNullNotes);
      expect(fromMapNullNotes.notes, isNull);

      // Test with missing notes in fromMap
      final mapWithoutNotes = {
        'id': 'test_id',
        'meal_id': 'meal_123',
        'recipe_id': 'recipe_456',
        'is_primary_dish': 0,
        // notes field is missing
      };
      final fromMapMissingNotes = MealRecipe.fromMap(mapWithoutNotes);
      expect(fromMapMissingNotes.notes, isNull);
    });

    test('handles empty string values correctly', () {
      // Test with empty string for notes
      final emptyNotes = MealRecipe(
        mealId: 'meal_123',
        recipeId: 'recipe_456',
        notes: '',
      );

      // Verify empty string is preserved in toMap
      final map = emptyNotes.toMap();
      expect(map['notes'], '');

      // Verify empty string is preserved in fromMap
      final mapWithEmptyNotes = {
        'id': 'test_id',
        'meal_id': 'meal_123',
        'recipe_id': 'recipe_456',
        'is_primary_dish': 0,
        'notes': '',
      };
      final fromMapEmptyNotes = MealRecipe.fromMap(mapWithEmptyNotes);
      expect(fromMapEmptyNotes.notes, '');
    });
  });
}
