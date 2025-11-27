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

    test('round-trip serialization preserves all data', () {
      final original = MealRecipe(
        id: 'round_trip_test',
        mealId: 'meal_123',
        recipeId: 'recipe_456',
        isPrimaryDish: true,
        notes: 'Round trip test notes',
      );

      // Convert to map and back
      final map = original.toMap();
      final recovered = MealRecipe.fromMap(map);

      // Convert recovered back to map
      final secondMap = recovered.toMap();

      // Both maps should be identical
      expect(secondMap['id'], map['id']);
      expect(secondMap['meal_id'], map['meal_id']);
      expect(secondMap['recipe_id'], map['recipe_id']);
      expect(secondMap['is_primary_dish'], map['is_primary_dish']);
      expect(secondMap['notes'], map['notes']);
    });

    test('copyWith with no changes returns same values', () {
      final original = MealRecipe(
        id: 'test_id',
        mealId: 'meal_123',
        recipeId: 'recipe_456',
        isPrimaryDish: true,
        notes: 'Original notes',
      );

      // Copy with no changes
      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.mealId, original.mealId);
      expect(copy.recipeId, original.recipeId);
      expect(copy.isPrimaryDish, original.isPrimaryDish);
      expect(copy.notes, original.notes);
    });

    test('copyWith can change all fields at once', () {
      final original = MealRecipe(
        id: 'original_id',
        mealId: 'original_meal',
        recipeId: 'original_recipe',
        isPrimaryDish: false,
        notes: 'Original notes',
      );

      // Change all fields
      final modified = original.copyWith(
        id: 'new_id',
        mealId: 'new_meal',
        recipeId: 'new_recipe',
        isPrimaryDish: true,
        notes: 'New notes',
      );

      expect(modified.id, 'new_id');
      expect(modified.mealId, 'new_meal');
      expect(modified.recipeId, 'new_recipe');
      expect(modified.isPrimaryDish, true);
      expect(modified.notes, 'New notes');

      // Original should remain unchanged
      expect(original.id, 'original_id');
      expect(original.mealId, 'original_meal');
      expect(original.recipeId, 'original_recipe');
      expect(original.isPrimaryDish, false);
      expect(original.notes, 'Original notes');
    });

    test('copyWith preserves original notes when null is passed', () {
      final original = MealRecipe(
        id: 'test_id',
        mealId: 'meal_123',
        recipeId: 'recipe_456',
        isPrimaryDish: true,
        notes: 'Original notes',
      );

      // Passing null for notes preserves the original value
      // (This is the current behavior of the copyWith implementation)
      final modified = original.copyWith(notes: null);

      expect(modified.notes, 'Original notes'); // Preserves original
      expect(original.notes, 'Original notes'); // Original unchanged
    });

    test('auto-generated UUID is valid format', () {
      final mealRecipe = MealRecipe(
        mealId: 'meal_123',
        recipeId: 'recipe_456',
        // id not provided, should be auto-generated
      );

      // UUID v4 format: 8-4-4-4-12 hexadecimal characters
      final uuidPattern = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      );

      expect(mealRecipe.id, matches(uuidPattern));
      expect(mealRecipe.id.length, 36); // Standard UUID length
    });

    test('auto-generated UUIDs are unique', () {
      final mealRecipe1 = MealRecipe(
        mealId: 'meal_123',
        recipeId: 'recipe_456',
      );

      final mealRecipe2 = MealRecipe(
        mealId: 'meal_123',
        recipeId: 'recipe_456',
      );

      // Even with the same data, IDs should be different
      expect(mealRecipe1.id, isNot(equals(mealRecipe2.id)));
    });

    test('handles special characters in notes', () {
      final specialNotes = 'Test with special chars: !@#\$%^&*()_+-=[]{}|;:\'",.<>?/\\~`\n\tNew line and tab';
      final mealRecipe = MealRecipe(
        mealId: 'meal_123',
        recipeId: 'recipe_456',
        notes: specialNotes,
      );

      final map = mealRecipe.toMap();
      final recovered = MealRecipe.fromMap(map);

      expect(recovered.notes, specialNotes);
    });

    test('handles very long notes strings', () {
      final longNotes = 'B' * 10000; // 10,000 character string

      final mealRecipe = MealRecipe(
        mealId: 'meal_123',
        recipeId: 'recipe_456',
        notes: longNotes,
      );

      final map = mealRecipe.toMap();
      final recovered = MealRecipe.fromMap(map);

      expect(recovered.notes, longNotes);
      expect(recovered.notes!.length, 10000);
    });
  });
}
