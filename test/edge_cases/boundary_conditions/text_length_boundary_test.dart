// test/edge_cases/boundary_conditions/text_length_boundary_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/ingredient.dart';
import 'package:gastrobrain/models/ingredient_category.dart';
import 'package:gastrobrain/core/validators/entity_validator.dart';
import 'package:gastrobrain/core/errors/gastrobrain_exceptions.dart';
import '../../fixtures/boundary_fixtures.dart';
import '../../mocks/mock_database_helper.dart';

/// Tests for text length boundary conditions.
///
/// Verifies that the application correctly handles:
/// - Empty text fields
/// - Single character text
/// - Very long text (100+ characters)
/// - Extremely long text (1000+ characters)
/// - Database storage of long text
/// - Model serialization/deserialization with boundary values
///
/// These tests complement existing widget-level validation tests by
/// focusing on model-level and database-level text handling.
void main() {
  group('Text Length Boundary Tests', () {
    late MockDatabaseHelper mockDbHelper;

    setUp(() {
      mockDbHelper = MockDatabaseHelper();
    });

    tearDown(() {
      mockDbHelper.resetAllData();
    });

    group('Recipe Name Length Boundaries', () {
      test('empty recipe name is rejected by EntityValidator', () {
        expect(
          () => EntityValidator.validateRecipe(
            id: 'recipe-1',
            name: BoundaryValues.emptyString,
            ingredients: [],
            instructions: [],
          ),
          throwsA(isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('Recipe name cannot be empty'),
          )),
        );
      });

      test('single character recipe name is accepted', () {
        final recipe = Recipe(
          id: 'recipe-1',
          name: BoundaryValues.singleChar,
          createdAt: DateTime.now(),
        );

        expect(recipe.name, equals(BoundaryValues.singleChar));
        expect(recipe.name.length, equals(1));

        // Should not throw when validating
        expect(
          () => EntityValidator.validateRecipe(
            id: recipe.id,
            name: recipe.name,
            ingredients: [],
            instructions: [],
          ),
          returnsNormally,
        );
      });

      test('very long recipe name (100+ chars) is accepted and stored', () async {
        expect(BoundaryValues.recipeVeryLong.length, greaterThan(100));

        final recipe = Recipe(
          id: 'recipe-long',
          name: BoundaryValues.recipeVeryLong,
          createdAt: DateTime.now(),
        );

        // Should be accepted by validator
        expect(
          () => EntityValidator.validateRecipe(
            id: recipe.id,
            name: recipe.name,
            ingredients: [],
            instructions: [],
          ),
          returnsNormally,
        );

        // Should serialize correctly
        final recipeMap = recipe.toMap();
        expect(recipeMap['name'], equals(BoundaryValues.recipeVeryLong));

        // Should deserialize correctly
        final deserializedRecipe = Recipe.fromMap(recipeMap);
        expect(deserializedRecipe.name, equals(BoundaryValues.recipeVeryLong));

        // Should be stored and retrieved from database
        await mockDbHelper.insertRecipe(recipe);
        final retrieved = await mockDbHelper.getRecipe(recipe.id);
        expect(retrieved!.name, equals(BoundaryValues.recipeVeryLong));
      });

      test('extremely long recipe name (1000+ chars) is accepted and stored',
          () async {
        expect(BoundaryValues.veryLongText.length, greaterThanOrEqualTo(1000));

        final recipe = Recipe(
          id: 'recipe-extreme',
          name: BoundaryValues.veryLongText,
          createdAt: DateTime.now(),
        );

        // Should be accepted by validator
        expect(
          () => EntityValidator.validateRecipe(
            id: recipe.id,
            name: recipe.name,
            ingredients: [],
            instructions: [],
          ),
          returnsNormally,
        );

        // Should be stored and retrieved from database
        await mockDbHelper.insertRecipe(recipe);
        final retrieved = await mockDbHelper.getRecipe(recipe.id);
        expect(retrieved!.name, equals(BoundaryValues.veryLongText));
        expect(retrieved.name.length, equals(BoundaryValues.veryLongText.length));
      });
    });

    group('Recipe Notes Length Boundaries', () {
      test('empty notes are accepted', () {
        final recipe = Recipe(
          id: 'recipe-1',
          name: 'Test Recipe',
          notes: BoundaryValues.emptyString,
          createdAt: DateTime.now(),
        );

        expect(recipe.notes, equals(''));

        // Should serialize correctly
        final recipeMap = recipe.toMap();
        expect(recipeMap['notes'], equals(''));
      });

      test('notes with 1000+ characters are accepted and stored', () async {
        expect(BoundaryValues.veryLongText.length, greaterThanOrEqualTo(1000));

        final recipe = Recipe(
          id: 'recipe-notes-long',
          name: 'Test Recipe',
          notes: BoundaryValues.veryLongText,
          createdAt: DateTime.now(),
        );

        expect(recipe.notes, equals(BoundaryValues.veryLongText));

        // Should be stored and retrieved from database
        await mockDbHelper.insertRecipe(recipe);
        final retrieved = await mockDbHelper.getRecipe(recipe.id);
        expect(retrieved!.notes, equals(BoundaryValues.veryLongText));
        expect(retrieved.notes.length, equals(BoundaryValues.veryLongText.length));
      });

      test('notes with 10000+ characters are accepted and stored', () async {
        expect(BoundaryValues.extremelyLongText.length, greaterThanOrEqualTo(10000));

        final recipe = Recipe(
          id: 'recipe-notes-extreme',
          name: 'Test Recipe',
          notes: BoundaryValues.extremelyLongText,
          createdAt: DateTime.now(),
        );

        expect(recipe.notes, equals(BoundaryValues.extremelyLongText));

        // Should be stored and retrieved from database
        await mockDbHelper.insertRecipe(recipe);
        final retrieved = await mockDbHelper.getRecipe(recipe.id);
        expect(retrieved!.notes, equals(BoundaryValues.extremelyLongText));
        expect(retrieved.notes.length, equals(BoundaryValues.extremelyLongText.length));
      });
    });

    group('Recipe Instructions Length Boundaries', () {
      test('empty instructions are accepted', () {
        final recipe = Recipe(
          id: 'recipe-1',
          name: 'Test Recipe',
          instructions: BoundaryValues.emptyString,
          createdAt: DateTime.now(),
        );

        expect(recipe.instructions, equals(''));
      });

      test('instructions with extreme length are accepted and stored', () async {
        // Create instructions with 10000+ chars
        final extremeInstructions = BoundaryValues.extremelyLongText;
        expect(extremeInstructions.length, greaterThanOrEqualTo(10000));

        final recipe = Recipe(
          id: 'recipe-instructions-extreme',
          name: 'Test Recipe',
          instructions: extremeInstructions,
          createdAt: DateTime.now(),
        );

        expect(recipe.instructions, equals(extremeInstructions));

        // Should be stored and retrieved from database
        await mockDbHelper.insertRecipe(recipe);
        final retrieved = await mockDbHelper.getRecipe(recipe.id);
        expect(retrieved!.instructions, equals(extremeInstructions));
        expect(retrieved.instructions.length, equals(extremeInstructions.length));
      });
    });

    group('Ingredient Name Length Boundaries', () {
      test('empty ingredient name is rejected by EntityValidator', () {
        expect(
          () => EntityValidator.validateIngredient(
            id: 'ing-1',
            name: BoundaryValues.emptyString,
            category: IngredientCategory.other,
          ),
          throwsA(isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('Ingredient name cannot be empty'),
          )),
        );
      });

      test('single character ingredient name is accepted', () {
        final ingredient = Ingredient(
          id: 'ing-1',
          name: BoundaryValues.singleChar,
          category: IngredientCategory.other,
        );

        expect(ingredient.name, equals(BoundaryValues.singleChar));
        expect(ingredient.name.length, equals(1));
      });

      test('very long ingredient name is accepted and stored', () async {
        final longName = BoundaryValues.ingredientLong;
        expect(longName.length, greaterThan(50));

        final ingredient = Ingredient(
          id: 'ing-long',
          name: longName,
          category: IngredientCategory.other,
        );

        // Should be stored and retrieved from database
        await mockDbHelper.insertIngredient(ingredient);
        final retrieved = mockDbHelper.ingredients[ingredient.id]!;
        expect(retrieved.name, equals(longName));
      });

      test('extremely long ingredient name (1000+ chars) is accepted and stored',
          () async {
        final extremeName = BoundaryValues.veryLongText;
        expect(extremeName.length, greaterThanOrEqualTo(1000));

        final ingredient = Ingredient(
          id: 'ing-extreme',
          name: extremeName,
          category: IngredientCategory.other,
        );

        // Should be stored and retrieved from database
        await mockDbHelper.insertIngredient(ingredient);
        final retrieved = mockDbHelper.ingredients[ingredient.id]!;
        expect(retrieved.name, equals(extremeName));
        expect(retrieved.name.length, equals(extremeName.length));
      });
    });

    group('Database Storage of Long Text', () {
      test('round-trip serialization preserves very long text', () async {
        final recipe = Recipe(
          id: 'recipe-roundtrip',
          name: BoundaryValues.recipeVeryLong,
          notes: BoundaryValues.veryLongText,
          instructions: BoundaryValues.extremelyLongText,
          createdAt: DateTime.now(),
        );

        // Store in database
        await mockDbHelper.insertRecipe(recipe);

        // Retrieve from database
        final retrieved = await mockDbHelper.getRecipe(recipe.id);

        // All text fields should be preserved exactly
        expect(retrieved!.name, equals(recipe.name));
        expect(retrieved.notes, equals(recipe.notes));
        expect(retrieved.instructions, equals(recipe.instructions));

        // Verify lengths are preserved
        expect(retrieved.name.length, equals(recipe.name.length));
        expect(retrieved.notes.length, equals(recipe.notes.length));
        expect(retrieved.instructions.length, equals(recipe.instructions.length));
      });

      test('multiple recipes with long text are stored independently', () async {
        final recipe1 = Recipe(
          id: 'recipe-1',
          name: 'Recipe 1',
          notes: BoundaryValues.veryLongText,
          createdAt: DateTime.now(),
        );

        final recipe2 = Recipe(
          id: 'recipe-2',
          name: 'Recipe 2',
          notes: BoundaryValues.extremelyLongText,
          createdAt: DateTime.now(),
        );

        // Store both
        await mockDbHelper.insertRecipe(recipe1);
        await mockDbHelper.insertRecipe(recipe2);

        // Retrieve and verify they're independent
        final retrieved1 = await mockDbHelper.getRecipe('recipe-1');
        final retrieved2 = await mockDbHelper.getRecipe('recipe-2');

        expect(retrieved1!.notes, equals(BoundaryValues.veryLongText));
        expect(retrieved2!.notes, equals(BoundaryValues.extremelyLongText));
        expect(retrieved1.notes, isNot(equals(retrieved2.notes)));
      });
    });
  });
}
