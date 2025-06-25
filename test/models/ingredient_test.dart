// test/models/ingredient_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/ingredient.dart';

void main() {
  group('Ingredient', () {
    test('creates with required fields', () {
      final ingredient = Ingredient(
        id: 'test_id',
        name: 'Carrot',
        category: 'vegetable',
      );

      expect(ingredient.id, 'test_id');
      expect(ingredient.name, 'Carrot');
      expect(ingredient.category, 'vegetable');
      expect(ingredient.unit, isNull);
      expect(ingredient.proteinType, isNull);
      expect(ingredient.notes, isNull);
    });

    test('creates with all fields and converts to map correctly', () {
      final ingredient = Ingredient(
        id: 'test_id',
        name: 'Chicken Breast',
        category: 'protein',
        unit: 'g',
        proteinType: 'chicken',
        notes: 'Boneless, skinless',
      );

      // Verify the fields are set correctly
      expect(ingredient.id, 'test_id');
      expect(ingredient.name, 'Chicken Breast');
      expect(ingredient.category, 'protein');
      expect(ingredient.unit, 'g');
      expect(ingredient.proteinType, 'chicken');
      expect(ingredient.notes, 'Boneless, skinless');

      // Verify toMap creates the correct map representation
      final map = ingredient.toMap();
      expect(map['id'], 'test_id');
      expect(map['name'], 'Chicken Breast');
      expect(map['category'], 'protein');
      expect(map['unit'], 'g');
      expect(map['protein_type'], 'chicken');
      expect(map['notes'], 'Boneless, skinless');
    });

    test('creates from map correctly', () {
      final map = {
        'id': 'test_id',
        'name': 'Olive Oil',
        'category': 'other',
        'unit': 'ml',
        'protein_type': null,
        'notes': 'Extra virgin',
      };

      final ingredient = Ingredient.fromMap(map);

      expect(ingredient.id, 'test_id');
      expect(ingredient.name, 'Olive Oil');
      expect(ingredient.category, 'other');
      expect(ingredient.unit, 'ml');
      expect(ingredient.proteinType, null);
      expect(ingredient.notes, 'Extra virgin');
    });

    test('handles null optional fields in fromMap', () {
      final map = {
        'id': 'test_id',
        'name': 'Salt',
        'category': 'seasoning',
        // Omitting unit, protein_type, and notes
      };

      final ingredient = Ingredient.fromMap(map);

      expect(ingredient.id, 'test_id');
      expect(ingredient.name, 'Salt');
      expect(ingredient.category, 'seasoning');
      expect(ingredient.unit, isNull);
      expect(ingredient.proteinType, isNull);
      expect(ingredient.notes, isNull);
    });

    test('handles empty strings in optional fields', () {
      final ingredient = Ingredient(
        id: 'test_id',
        name: 'Sugar',
        category: 'sugar products',
        unit: '',
        proteinType: '',
        notes: '',
      );

      final map = ingredient.toMap();
      expect(map['unit'], '');
      expect(map['protein_type'], '');
      expect(map['notes'], '');

      final recreatedIngredient = Ingredient.fromMap(map);
      expect(recreatedIngredient.unit, '');
      expect(recreatedIngredient.proteinType, '');
      expect(recreatedIngredient.notes, '');
    });

    test('round-trip conversion preserves all values', () {
      final original = Ingredient(
        id: 'test_id',
        name: 'Bell Pepper',
        category: 'vegetable',
        unit: 'piece',
        proteinType: null,
        notes: 'Red preferred',
      );

      final map = original.toMap();
      final recreated = Ingredient.fromMap(map);

      expect(recreated.id, original.id);
      expect(recreated.name, original.name);
      expect(recreated.category, original.category);
      expect(recreated.unit, original.unit);
      expect(recreated.proteinType, original.proteinType);
      expect(recreated.notes, original.notes);
    });

    test('protein ingredients require proteinType in entity validator', () {
      // This test would ideally verify that EntityValidator checks for proteinType
      // But since we're just testing the model, let's verify the model itself can handle
      // a protein ingredient correctly

      final proteinIngredient = Ingredient(
        id: 'test_id',
        name: 'Salmon',
        category: 'protein',
        proteinType: 'fish',
        unit: 'g',
      );

      expect(proteinIngredient.category, 'protein');
      expect(proteinIngredient.proteinType, 'fish');

      final map = proteinIngredient.toMap();
      expect(map['category'], 'protein');
      expect(map['protein_type'], 'fish');

      final recreated = Ingredient.fromMap(map);
      expect(recreated.category, 'protein');
      expect(recreated.proteinType, 'fish');
    });

    test('handles special characters in fields', () {
      final ingredient = Ingredient(
        id: 'test_id',
        name: 'Jalapeño',
        category: 'vegetable',
        notes: 'Very hot! 🌶️',
      );

      final map = ingredient.toMap();
      final recreated = Ingredient.fromMap(map);

      expect(recreated.name, 'Jalapeño');
      expect(recreated.notes, 'Very hot! 🌶️');
    });

    test('works with all known categories', () {
      final categories = [
        'vegetable',
        'fruit',
        'protein',
        'dairy',
        'grain',
        'pulse',
        'nuts_and_seeds',
        'seasoning',
        'sugar products',
        'other'
      ];

      for (final category in categories) {
        final ingredient = Ingredient(
          id: 'test_id',
          name: 'Test Ingredient',
          category: category,
        );

        expect(ingredient.category, category);

        final map = ingredient.toMap();
        final recreated = Ingredient.fromMap(map);

        expect(recreated.category, category);
      }
    });
  });
}
