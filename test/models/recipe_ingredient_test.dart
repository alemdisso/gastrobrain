// test/models/recipe_ingredient_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/recipe_ingredient.dart';

void main() {
  group('RecipeIngredient', () {
    test('creates with required fields', () {
      final recipeIngredient = RecipeIngredient(
        id: 'test_id',
        recipeId: 'recipe_123',
        ingredientId: 'ingredient_456',
        quantity: 2.5,
      );

      expect(recipeIngredient.id, 'test_id');
      expect(recipeIngredient.recipeId, 'recipe_123');
      expect(recipeIngredient.ingredientId, 'ingredient_456');
      expect(recipeIngredient.quantity, 2.5);
      expect(recipeIngredient.notes, isNull);
      expect(recipeIngredient.unitOverride, isNull);
      expect(recipeIngredient.customName, isNull);
      expect(recipeIngredient.customCategory, isNull);
      expect(recipeIngredient.customUnit, isNull);
      expect(recipeIngredient.isCustom, isFalse);
    });

    test('creates with all fields and converts to map correctly', () {
      final recipeIngredient = RecipeIngredient(
        id: 'test_id',
        recipeId: 'recipe_123',
        ingredientId: 'ingredient_456',
        quantity: 2.5,
        notes: 'Finely chopped',
        unitOverride: 'cup',
        customName: 'Special Carrots',
        customCategory: 'vegetable',
        customUnit: 'handful',
      );

      // Verify all fields are set correctly
      expect(recipeIngredient.id, 'test_id');
      expect(recipeIngredient.recipeId, 'recipe_123');
      expect(recipeIngredient.ingredientId, 'ingredient_456');
      expect(recipeIngredient.quantity, 2.5);
      expect(recipeIngredient.notes, 'Finely chopped');
      expect(recipeIngredient.unitOverride, 'cup');
      expect(recipeIngredient.customName, 'Special Carrots');
      expect(recipeIngredient.customCategory, 'vegetable');
      expect(recipeIngredient.customUnit, 'handful');

      // Verify toMap creates the correct map representation
      final map = recipeIngredient.toMap();
      expect(map['id'], 'test_id');
      expect(map['recipe_id'], 'recipe_123');
      expect(map['ingredient_id'], 'ingredient_456');
      expect(map['quantity'], 2.5);
      expect(map['notes'], 'Finely chopped');
      expect(map['unit_override'], 'cup');
      expect(map['custom_name'], 'Special Carrots');
      expect(map['custom_category'], 'vegetable');
      expect(map['custom_unit'], 'handful');
    });

    test('creates custom ingredient correctly', () {
      final customIngredient = RecipeIngredient.custom(
        id: 'test_id',
        recipeId: 'recipe_123',
        name: 'Homemade Sauce',
        category: 'other',
        quantity: 3.0,
        unit: 'tbsp',
        notes: 'Add to taste',
      );

      // Verify fields are set correctly
      expect(customIngredient.id, 'test_id');
      expect(customIngredient.recipeId, 'recipe_123');
      expect(customIngredient.ingredientId, isNull);
      expect(customIngredient.quantity, 3.0);
      expect(customIngredient.notes, 'Add to taste');
      expect(customIngredient.customName, 'Homemade Sauce');
      expect(customIngredient.customCategory, 'other');
      expect(customIngredient.customUnit, 'tbsp');

      // Verify isCustom getter works correctly
      expect(customIngredient.isCustom, isTrue);

      // Verify toMap creates the correct map
      final map = customIngredient.toMap();
      expect(map['id'], 'test_id');
      expect(map['recipe_id'], 'recipe_123');
      expect(map['ingredient_id'], isNull);
      expect(map['quantity'], 3.0);
      expect(map['notes'], 'Add to taste');
      expect(map['custom_name'], 'Homemade Sauce');
      expect(map['custom_category'], 'other');
      expect(map['custom_unit'], 'tbsp');
    });

    test('handles edge cases', () {
      // Test with zero quantity
      final zeroQuantity = RecipeIngredient(
        id: 'test_id',
        recipeId: 'recipe_123',
        ingredientId: 'ingredient_456',
        quantity: 0,
      );
      expect(zeroQuantity.quantity, 0);

      // Test with very small quantity
      final smallQuantity = RecipeIngredient(
        id: 'test_id',
        recipeId: 'recipe_123',
        ingredientId: 'ingredient_456',
        quantity: 0.125, // 1/8
      );
      expect(smallQuantity.quantity, 0.125);

      // Test with very large quantity
      final largeQuantity = RecipeIngredient(
        id: 'test_id',
        recipeId: 'recipe_123',
        ingredientId: 'ingredient_456',
        quantity: 1000,
      );
      expect(largeQuantity.quantity, 1000);

      // Test with non-trivial decimal quantity
      final decimalQuantity = RecipeIngredient(
        id: 'test_id',
        recipeId: 'recipe_123',
        ingredientId: 'ingredient_456',
        quantity: 1.333,
      );
      expect(decimalQuantity.quantity, 1.333);
    });

    test('handles empty and null values correctly', () {
      // Create with empty strings for optional fields
      final emptyStrings = RecipeIngredient(
        id: 'test_id',
        recipeId: 'recipe_123',
        ingredientId: 'ingredient_456',
        quantity: 1.0,
        notes: '',
        unitOverride: '',
        customName: '',
        customCategory: '',
        customUnit: '',
      );

      // Verify empty strings are preserved in toMap
      final map = emptyStrings.toMap();
      expect(map['notes'], '');
      expect(map['unit_override'], '');
      expect(map['custom_name'], '');
      expect(map['custom_category'], '');
      expect(map['custom_unit'], '');

      // Create with explicit null values
      final nullValues = RecipeIngredient(
        id: 'test_id',
        recipeId: 'recipe_123',
        ingredientId: 'ingredient_456',
        quantity: 1.0,
        notes: null,
        unitOverride: null,
        customName: null,
        customCategory: null,
        customUnit: null,
      );

      // Verify null values are preserved in toMap
      final nullMap = nullValues.toMap();
      expect(nullMap.containsKey('notes'), isTrue);
      expect(nullMap.containsKey('unit_override'), isTrue);
      expect(nullMap.containsKey('custom_name'), isTrue);
      expect(nullMap.containsKey('custom_category'), isTrue);
      expect(nullMap.containsKey('custom_unit'), isTrue);
      expect(nullMap['notes'], isNull);
      expect(nullMap['unit_override'], isNull);
      expect(nullMap['custom_name'], isNull);
      expect(nullMap['custom_category'], isNull);
      expect(nullMap['custom_unit'], isNull);

      // Test isCustom behavior with empty string vs null ingredientId
      final emptyIngredientId = RecipeIngredient(
        id: 'test_id',
        recipeId: 'recipe_123',
        ingredientId: '',
        quantity: 1.0,
      );
      expect(emptyIngredientId.isCustom, isFalse); // Empty string is not null

      final nullIngredientId = RecipeIngredient(
        id: 'test_id',
        recipeId: 'recipe_123',
        ingredientId: null,
        quantity: 1.0,
      );
      expect(
          nullIngredientId.isCustom, isTrue); // Null ingredientId means custom
    });
    test('handles unit override correctly', () {
      // Create an ingredient with a unit override
      final ingredientWithOverride = RecipeIngredient(
        id: 'test_id',
        recipeId: 'recipe_123',
        ingredientId: 'ingredient_456',
        quantity: 2.0,
        unitOverride: 'cup', // Override the default unit
      );

      expect(ingredientWithOverride.unitOverride, 'cup');

      // Verify the unit override is correctly included in the map
      final map = ingredientWithOverride.toMap();
      expect(map['unit_override'], 'cup');

      // Test the case where both unitOverride and customUnit are provided
      // (this might occur in some edge cases - customUnit should be used for custom ingredients)
      final complexOverride = RecipeIngredient(
        id: 'test_id',
        recipeId: 'recipe_123',
        ingredientId: null, // Custom ingredient
        quantity: 2.0,
        unitOverride: 'cup', // Should be ignored for custom ingredients
        customUnit: 'handful', // Should be used for custom ingredients
        customName: 'Special Ingredient',
        customCategory: 'other',
      );

      // Verify both unit fields are preserved in the map
      final complexMap = complexOverride.toMap();
      expect(complexMap['unit_override'], 'cup');
      expect(complexMap['custom_unit'], 'handful');

      // Verify isCustom behavior is not affected by unit override
      expect(complexOverride.isCustom, isTrue);
    });
  });
}
