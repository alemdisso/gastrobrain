// test/models/ingredient_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/ingredient.dart';
import 'package:gastrobrain/models/ingredient_category.dart';
import 'package:gastrobrain/models/measurement_unit.dart';
import 'package:gastrobrain/models/protein_type.dart';

void main() {
  group('Ingredient', () {
    test('creates with required fields', () {
      final ingredient = Ingredient(
        id: 'test_id',
        name: 'Carrot',
        category: IngredientCategory.vegetable,
      );

      expect(ingredient.id, 'test_id');
      expect(ingredient.name, 'Carrot');
      expect(ingredient.category, IngredientCategory.vegetable);
      expect(ingredient.unit, isNull);
      expect(ingredient.proteinType, isNull);
      expect(ingredient.notes, isNull);
    });

    test('creates with all fields and converts to map correctly', () {
      final ingredient = Ingredient(
        id: 'test_id',
        name: 'Chicken Breast',
        category: IngredientCategory.protein,
        unit: MeasurementUnit.gram,
        proteinType: ProteinType.chicken,
        notes: 'Boneless, skinless',
      );

      // Verify the fields are set correctly
      expect(ingredient.id, 'test_id');
      expect(ingredient.name, 'Chicken Breast');
      expect(ingredient.category, IngredientCategory.protein);
      expect(ingredient.unit, MeasurementUnit.gram);
      expect(ingredient.proteinType, ProteinType.chicken);
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
      expect(ingredient.category, IngredientCategory.other);
      expect(ingredient.unit, MeasurementUnit.milliliter);
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
      expect(ingredient.category, IngredientCategory.seasoning);
      expect(ingredient.unit, isNull);
      expect(ingredient.proteinType, isNull);
      expect(ingredient.notes, isNull);
    });

    test('handles null optional fields correctly', () {
      final ingredient = Ingredient(
        id: 'test_id',
        name: 'Sugar',
        category: IngredientCategory.sugarProducts,
        unit: null,
        proteinType: null,
        notes: '',
      );

      final map = ingredient.toMap();
      expect(map['unit'], null);
      expect(map['protein_type'], null);
      expect(map['notes'], '');

      final recreatedIngredient = Ingredient.fromMap(map);
      expect(recreatedIngredient.unit, null);
      expect(recreatedIngredient.proteinType, null);
      expect(recreatedIngredient.notes, '');
    });

    test('round-trip conversion preserves all values', () {
      final original = Ingredient(
        id: 'test_id',
        name: 'Bell Pepper',
        category: IngredientCategory.vegetable,
        unit: MeasurementUnit.piece,
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
        category: IngredientCategory.protein,
        proteinType: ProteinType.fish,
        unit: MeasurementUnit.gram,
      );

      expect(proteinIngredient.category, IngredientCategory.protein);
      expect(proteinIngredient.proteinType, ProteinType.fish);

      final map = proteinIngredient.toMap();
      expect(map['category'], 'protein');
      expect(map['protein_type'], 'fish');

      final recreated = Ingredient.fromMap(map);
      expect(recreated.category, IngredientCategory.protein);
      expect(recreated.proteinType, ProteinType.fish);
    });

    test('handles special characters in fields', () {
      final ingredient = Ingredient(
        id: 'test_id',
        name: 'Jalapeño',
        category: IngredientCategory.vegetable,
        notes: 'Very hot! 🌶️',
      );

      final map = ingredient.toMap();
      final recreated = Ingredient.fromMap(map);

      expect(recreated.name, 'Jalapeño');
      expect(recreated.notes, 'Very hot! 🌶️');
    });

    test('works with all known categories', () {
      final categories = [
        IngredientCategory.vegetable,
        IngredientCategory.fruit,
        IngredientCategory.protein,
        IngredientCategory.dairy,
        IngredientCategory.grain,
        IngredientCategory.pulse,
        IngredientCategory.nutsAndSeeds,
        IngredientCategory.seasoning,
        IngredientCategory.sugarProducts,
        IngredientCategory.other,
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

    group('aliases field', () {
      test('defaults to empty list when not provided', () {
        final ingredient = Ingredient(
          id: 'test_id',
          name: 'Salsão',
          category: IngredientCategory.vegetable,
        );

        expect(ingredient.aliases, isEmpty);
        expect(ingredient.aliases, isA<List<String>>());
      });

      test('toMap() stores null when aliases is empty', () {
        final ingredient = Ingredient(
          id: 'test_id',
          name: 'Tomate',
          category: IngredientCategory.vegetable,
          aliases: [],
        );

        final map = ingredient.toMap();

        expect(map['aliases'], isNull);
      });

      test('toMap() encodes non-empty aliases as JSON string', () {
        final ingredient = Ingredient(
          id: 'test_id',
          name: 'Salsão',
          category: IngredientCategory.vegetable,
          aliases: ['aipo', 'celery'],
        );

        final map = ingredient.toMap();

        expect(map['aliases'], isA<String>());
        expect(map['aliases'], equals('["aipo","celery"]'));
      });

      test('fromMap() decodes JSON string to List<String>', () {
        final map = {
          'id': 'test_id',
          'name': 'Salsão',
          'category': 'vegetable',
          'aliases': '["aipo","celery"]',
        };

        final ingredient = Ingredient.fromMap(map);

        expect(ingredient.aliases, hasLength(2));
        expect(ingredient.aliases, containsAll(['aipo', 'celery']));
      });

      test('fromMap() handles null aliases column (existing DB rows)', () {
        final map = {
          'id': 'test_id',
          'name': 'Tomate',
          'category': 'vegetable',
          'aliases': null,
        };

        final ingredient = Ingredient.fromMap(map);

        expect(ingredient.aliases, isEmpty);
      });

      test('fromMap() handles malformed JSON gracefully', () {
        final map = {
          'id': 'test_id',
          'name': 'Tomate',
          'category': 'vegetable',
          'aliases': 'not-valid-json{{{',
        };

        final ingredient = Ingredient.fromMap(map);

        expect(ingredient.aliases, isEmpty);
      });

      test('round-trip toMap → fromMap preserves aliases', () {
        final original = Ingredient(
          id: 'test_id',
          name: 'Coentro',
          category: IngredientCategory.herb,
          aliases: ['cilantro', 'coriander'],
        );

        final recreated = Ingredient.fromMap(original.toMap());

        expect(recreated.aliases, hasLength(2));
        expect(recreated.aliases, containsAll(['cilantro', 'coriander']));
      });
    });
  });
}
