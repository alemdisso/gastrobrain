import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/ingredient.dart';
import 'package:gastrobrain/models/ingredient_category.dart';
import 'package:gastrobrain/models/measurement_unit.dart';
import 'package:gastrobrain/models/protein_type.dart';
import 'package:gastrobrain/core/errors/gastrobrain_exceptions.dart';
import '../mocks/mock_database_helper.dart';

void main() {
  late MockDatabaseHelper dbHelper;

  setUp(() {
    dbHelper = MockDatabaseHelper();
  });

  tearDown(() {
    dbHelper.resetAllData();
  });

  group('Ingredient Management', () {
    test('can insert and retrieve ingredient', () async {
      final ingredient = Ingredient(
        id: 'test-ingredient-1',
        name: 'Carrots',
        category: IngredientCategory.vegetable,
        unit: MeasurementUnit.gram,
      );

      // Insert the ingredient
      final id = await dbHelper.insertIngredient(ingredient);

      // Verify the returned id matches
      expect(id, ingredient.id);

      // Verify we can retrieve it
      final ingredients = await dbHelper.getAllIngredients();
      expect(ingredients.length, 1);
      expect(ingredients.first.id, ingredient.id);
      expect(ingredients.first.name, 'Carrots');
      expect(ingredients.first.category, IngredientCategory.vegetable);
      expect(ingredients.first.unit, MeasurementUnit.gram);
    });

    test('can update existing ingredient', () async {
      // Insert initial ingredient
      final ingredient = Ingredient(
        id: 'test-ingredient-1',
        name: 'Carrots',
        category: IngredientCategory.vegetable,
        unit: MeasurementUnit.gram,
      );
      await dbHelper.insertIngredient(ingredient);

      // Create updated version
      final updatedIngredient = Ingredient(
        id: ingredient.id,
        name: 'Baby Carrots',
        category: IngredientCategory.vegetable,
        unit: MeasurementUnit.kilogram,
      );

      // Update the ingredient
      final updateResult = await dbHelper.updateIngredient(updatedIngredient);
      expect(updateResult, 1); // Should return 1 for successful update

      // Verify the update
      final ingredients = await dbHelper.getAllIngredients();
      expect(ingredients.length, 1);
      expect(ingredients.first.id, updatedIngredient.id);
      expect(ingredients.first.name, 'Baby Carrots');
      expect(ingredients.first.unit, MeasurementUnit.kilogram);
    });

    test('updating non-existing ingredient returns 0', () async {
      final nonExistingIngredient = Ingredient(
        id: 'non-existing-id',
        name: 'Does Not Exist',
        category: IngredientCategory.other,
        unit: MeasurementUnit.gram,
      );

      final result = await dbHelper.updateIngredient(nonExistingIngredient);
      expect(result, 0); // Should return 0 for unsuccessful update
    });

    group('Delete Operations', () {
      test('can delete existing ingredient', () async {
        // Insert an ingredient first
        final ingredient = Ingredient(
          id: 'test-ingredient-1',
          name: 'Carrots',
          category: IngredientCategory.vegetable,
          unit: MeasurementUnit.gram,
        );
        await dbHelper.insertIngredient(ingredient);

        // Verify it was inserted
        var ingredients = await dbHelper.getAllIngredients();
        expect(ingredients.length, 1);

        // Delete the ingredient
        final deleteResult = await dbHelper.deleteIngredient(ingredient.id);
        expect(deleteResult, 1); // Should return 1 for successful deletion

        // Verify it was deleted
        ingredients = await dbHelper.getAllIngredients();
        expect(ingredients.length, 0);
      });

      test('deleting non-existing ingredient returns 0', () async {
        final result = await dbHelper.deleteIngredient('non-existing-id');
        expect(result, 0); // Should return 0 for unsuccessful deletion
      });
    });

    group('Get All Ingredients', () {
      test('returns empty list when no ingredients exist', () async {
        final ingredients = await dbHelper.getAllIngredients();
        expect(ingredients, isEmpty);
      });

      test('returns single ingredient when one exists', () async {
        final ingredient = Ingredient(
          id: 'test-ingredient-1',
          name: 'Carrots',
          category: IngredientCategory.vegetable,
          unit: MeasurementUnit.gram,
        );
        await dbHelper.insertIngredient(ingredient);

        final ingredients = await dbHelper.getAllIngredients();
        expect(ingredients.length, 1);
        expect(ingredients.first.id, ingredient.id);
        expect(ingredients.first.name, ingredient.name);
        expect(ingredients.first.category, ingredient.category);
        expect(ingredients.first.unit, ingredient.unit);
      });

      test('returns all ingredients when multiple exist', () async {
        final ingredients = [
          Ingredient(
            id: 'test-ingredient-1',
            name: 'Carrots',
            category: IngredientCategory.vegetable,
            unit: MeasurementUnit.gram,
          ),
          Ingredient(
            id: 'test-ingredient-2',
            name: 'Chicken Breast',
            category: IngredientCategory.protein,
            unit: MeasurementUnit.kilogram,
            proteinType: ProteinType.chicken,
          ),
          Ingredient(
            id: 'test-ingredient-3',
            name: 'Olive Oil',
            category: IngredientCategory.oil,
            unit: MeasurementUnit.milliliter,
          ),
        ];

        // Insert all ingredients
        for (final ingredient in ingredients) {
          await dbHelper.insertIngredient(ingredient);
        }

        // Retrieve and verify
        final retrievedIngredients = await dbHelper.getAllIngredients();
        expect(retrievedIngredients.length, ingredients.length);

        // Verify each ingredient exists in retrieved list
        for (final original in ingredients) {
          expect(
            retrievedIngredients.any((retrieved) =>
                retrieved.id == original.id &&
                retrieved.name == original.name &&
                retrieved.category == original.category &&
                retrieved.unit == original.unit),
            isTrue,
          );
        }
      });
    });

    group('Validation', () {
      test('can insert ingredient with valid category', () async {
        final validCategories = [
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

        for (final category in validCategories) {
          final ingredient = Ingredient(
            id: 'test-${category.value}',
            name: 'Test ${category.value}',
            category: category,
            // Add protein type for protein category
            proteinType: category == IngredientCategory.protein ? ProteinType.chicken : null,
          );

          final id = await dbHelper.insertIngredient(ingredient);
          expect(id, isNotNull);
        }

        final ingredients = await dbHelper.getAllIngredients();
        expect(ingredients.length, validCategories.length);
      });

      test('protein ingredients require protein type', () async {
        final proteinTypes = [ProteinType.chicken, ProteinType.beef, ProteinType.pork, ProteinType.fish];

        for (final type in proteinTypes) {
          final ingredient = Ingredient(
            id: 'test-${type.name}',
            name: 'Test ${type.name}',
            category: IngredientCategory.protein,
            proteinType: type,
          );

          final id = await dbHelper.insertIngredient(ingredient);
          expect(id, isNotNull);

          final ingredients = await dbHelper.getAllIngredients();
          final inserted = ingredients.firstWhere((i) => i.id == ingredient.id);
          expect(inserted.proteinType, type);
        }
      });

      test('non-protein ingredients should not have protein type', () async {
        final ingredient = Ingredient(
          id: 'test-carrot',
          name: 'Carrot',
          category: IngredientCategory.vegetable,
          proteinType: null, // Should be null for non-proteins
        );

        final id = await dbHelper.insertIngredient(ingredient);
        expect(id, isNotNull);

        final ingredients = await dbHelper.getAllIngredients();
        final inserted = ingredients.first;
        expect(inserted.proteinType, isNull);
      });

      test('rejects ingredient with empty name', () async {
        final ingredient = Ingredient(
          id: 'test-empty-name',
          name: '', // Empty name
          category: IngredientCategory.vegetable,
        );

        try {
          await dbHelper.insertIngredient(ingredient);
          fail('Should throw ValidationException');
        } on ValidationException catch (e) {
          expect(e.message, 'Ingredient name cannot be empty');
        }

        final ingredients = await dbHelper.getAllIngredients();
        expect(ingredients.length, 0);
      });

      // Note: Empty category test removed since enum types enforce non-null category selection

      test('rejects protein ingredient without protein type', () async {
        final ingredient = Ingredient(
          id: 'test-no-protein-type',
          name: 'Generic Meat',
          category: IngredientCategory.protein,
          proteinType: null, // Missing protein type
        );

        try {
          await dbHelper.insertIngredient(ingredient);
          fail('Should throw ValidationException');
        } on ValidationException catch (e) {
          expect(e.message,
              'Protein type must be selected for protein ingredients');
        }

        final ingredients = await dbHelper.getAllIngredients();
        expect(ingredients.length, 0);
      });
    });
  });
}
