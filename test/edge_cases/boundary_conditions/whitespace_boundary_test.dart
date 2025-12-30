// test/edge_cases/boundary_conditions/whitespace_boundary_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/ingredient.dart';
import 'package:gastrobrain/models/ingredient_category.dart';
import 'package:gastrobrain/core/validators/entity_validator.dart';
import 'package:gastrobrain/core/errors/gastrobrain_exceptions.dart';
import '../../fixtures/boundary_fixtures.dart';
import '../../mocks/mock_database_helper.dart';

/// Tests for whitespace handling in text fields.
///
/// Verifies that the application correctly handles:
/// - Whitespace-only strings
/// - Leading and trailing whitespace
/// - Multiple consecutive spaces
/// - Empty strings vs null values
/// - Whitespace in optional fields
///
/// These tests document current whitespace handling behavior.
/// Note: The current implementation does NOT trim whitespace automatically.
/// Trimming is handled at the UI/form validation layer, not at the model layer.
void main() {
  group('Whitespace Boundary Tests', () {
    late MockDatabaseHelper mockDbHelper;

    setUp(() {
      mockDbHelper = MockDatabaseHelper();
    });

    tearDown(() {
      mockDbHelper.resetAllData();
    });

    group('Whitespace-Only Strings', () {
      test('recipe name with only whitespace passes EntityValidator', () {
        // Note: EntityValidator only checks isEmpty(), not if string is whitespace-only
        // Whitespace-only validation should be done at the UI layer
        final whitespaceName = BoundaryValues.whitespaceOnly;

        expect(whitespaceName.isEmpty, isFalse);
        expect(whitespaceName.trim().isEmpty, isTrue);

        // EntityValidator.validateRecipe checks isEmpty(), not isBlank/trimmed
        // So whitespace-only string will pass the validator
        expect(
          () => EntityValidator.validateRecipe(
            id: 'recipe-1',
            name: whitespaceName,
            ingredients: [],
            instructions: [],
          ),
          returnsNormally,
        );
      });

      test('whitespace-only recipe name is stored as-is (not trimmed)', () async {
        final recipe = Recipe(
          id: 'recipe-whitespace',
          name: BoundaryValues.whitespaceOnly,
          createdAt: DateTime.now(),
        );

        // Model does not automatically trim
        expect(recipe.name, equals(BoundaryValues.whitespaceOnly));
        expect(recipe.name.trim().isEmpty, isTrue);

        // Whitespace is preserved in storage
        await mockDbHelper.insertRecipe(recipe);
        final retrieved = await mockDbHelper.getRecipe(recipe.id);
        expect(retrieved!.name, equals(BoundaryValues.whitespaceOnly));
        expect(retrieved.name, isNot(equals(retrieved.name.trim())));
      });

      test('whitespace-only notes are accepted and stored', () async {
        final recipe = Recipe(
          id: 'recipe-notes-whitespace',
          name: 'Test Recipe',
          notes: '     ',
          createdAt: DateTime.now(),
        );

        await mockDbHelper.insertRecipe(recipe);
        final retrieved = await mockDbHelper.getRecipe(recipe.id);

        // Whitespace in notes is preserved
        expect(retrieved!.notes, equals('     '));
        expect(retrieved.notes.trim().isEmpty, isTrue);
      });

      test('ingredient name with only whitespace passes EntityValidator', () {
        final whitespaceName = '   ';

        // EntityValidator only checks isEmpty()
        expect(
          () => EntityValidator.validateIngredient(
            id: 'ing-1',
            name: whitespaceName,
            category: IngredientCategory.other,
          ),
          returnsNormally,
        );
      });
    });

    group('Leading and Trailing Whitespace', () {
      test('recipe name with leading/trailing spaces is NOT auto-trimmed', () async {
        final nameWithSpaces = '  Recipe Name  ';

        final recipe = Recipe(
          id: 'recipe-spaces',
          name: nameWithSpaces,
          createdAt: DateTime.now(),
        );

        // Model does not trim automatically
        expect(recipe.name, equals(nameWithSpaces));
        expect(recipe.name, isNot(equals(recipe.name.trim())));
        expect(recipe.name.startsWith(' '), isTrue);
        expect(recipe.name.endsWith(' '), isTrue);

        // Whitespace is preserved in storage
        await mockDbHelper.insertRecipe(recipe);
        final retrieved = await mockDbHelper.getRecipe(recipe.id);
        expect(retrieved!.name, equals(nameWithSpaces));
        expect(retrieved.name, equals('  Recipe Name  '));
      });

      test('notes with leading/trailing whitespace are preserved', () async {
        final notesWithSpaces = '\n\n  Important note  \n\n';

        final recipe = Recipe(
          id: 'recipe-notes-spaces',
          name: 'Test Recipe',
          notes: notesWithSpaces,
          createdAt: DateTime.now(),
        );

        await mockDbHelper.insertRecipe(recipe);
        final retrieved = await mockDbHelper.getRecipe(recipe.id);

        // All whitespace is preserved
        expect(retrieved!.notes, equals(notesWithSpaces));
        expect(retrieved.notes.startsWith('\n'), isTrue);
        expect(retrieved.notes.endsWith('\n'), isTrue);
      });

      test('ingredient name with leading/trailing spaces is preserved', () async {
        final nameWithSpaces = '  Salt  ';

        final ingredient = Ingredient(
          id: 'ing-spaces',
          name: nameWithSpaces,
          category: IngredientCategory.seasoning,
        );

        // Not trimmed automatically
        expect(ingredient.name, equals(nameWithSpaces));

        await mockDbHelper.insertIngredient(ingredient);
        final retrieved = mockDbHelper.ingredients[ingredient.id]!;
        expect(retrieved.name, equals(nameWithSpaces));
      });
    });

    group('Empty String vs Null', () {
      test('empty string in recipe name is rejected by EntityValidator', () {
        expect(
          () => EntityValidator.validateRecipe(
            id: 'recipe-1',
            name: '',
            ingredients: [],
            instructions: [],
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('empty string vs null are handled consistently in optional fields', () {
        final recipeWithEmptyNotes = Recipe(
          id: 'recipe-1',
          name: 'Test',
          notes: '',
          createdAt: DateTime.now(),
        );

        final recipeWithDefaultNotes = Recipe(
          id: 'recipe-2',
          name: 'Test',
          // notes defaults to ''
          createdAt: DateTime.now(),
        );

        // Both should have empty string notes (not null)
        expect(recipeWithEmptyNotes.notes, equals(''));
        expect(recipeWithDefaultNotes.notes, equals(''));
        expect(recipeWithEmptyNotes.notes, equals(recipeWithDefaultNotes.notes));
      });

      test('empty string is serialized and deserialized consistently', () {
        final recipe = Recipe(
          id: 'recipe-empty',
          name: 'Test',
          notes: '',
          instructions: '',
          createdAt: DateTime.now(),
        );

        final recipeMap = recipe.toMap();
        expect(recipeMap['notes'], equals(''));
        expect(recipeMap['instructions'], equals(''));

        final deserialized = Recipe.fromMap(recipeMap);
        expect(deserialized.notes, equals(''));
        expect(deserialized.instructions, equals(''));
      });

      test('null in map is converted to empty string for optional fields', () {
        final recipeMap = {
          'id': 'recipe-null',
          'name': 'Test',
          'notes': null, // null in database
          'instructions': null,
          'created_at': DateTime.now().toIso8601String(),
          'difficulty': 1,
          'prep_time_minutes': 0,
          'cook_time_minutes': 0,
          'rating': 0,
          'desired_frequency': 'monthly',
          'category': 'uncategorized',
        };

        final recipe = Recipe.fromMap(recipeMap);

        // Null should be converted to empty string
        expect(recipe.notes, equals(''));
        expect(recipe.instructions, equals(''));
        expect(recipe.notes, isNot(isNull));
        expect(recipe.instructions, isNot(isNull));
      });
    });

    group('Multiple Consecutive Spaces', () {
      test('recipe name with multiple spaces is preserved exactly', () async {
        final nameWithManySpaces = 'Word    with    many    spaces';

        final recipe = Recipe(
          id: 'recipe-many-spaces',
          name: nameWithManySpaces,
          createdAt: DateTime.now(),
        );

        // Spaces are not collapsed
        expect(recipe.name.contains('    '), isTrue);

        await mockDbHelper.insertRecipe(recipe);
        final retrieved = await mockDbHelper.getRecipe(recipe.id);
        expect(retrieved!.name, equals(nameWithManySpaces));

        // Multiple spaces should still be there
        expect(retrieved.name.split('    ').length, greaterThan(1));
      });

      test('notes with irregular spacing are preserved', () async {
        final irregularSpacing = '''
Line 1          with many spaces
  Line 2  has   irregular   spacing
    Line 3      too
''';

        final recipe = Recipe(
          id: 'recipe-irregular',
          name: 'Test Recipe',
          notes: irregularSpacing,
          createdAt: DateTime.now(),
        );

        await mockDbHelper.insertRecipe(recipe);
        final retrieved = await mockDbHelper.getRecipe(recipe.id);

        // All spacing should be preserved exactly
        expect(retrieved!.notes, equals(irregularSpacing));
        expect(retrieved.notes.contains('          '), isTrue);
        expect(retrieved.notes.contains('   '), isTrue);
      });
    });

    group('Whitespace Edge Cases', () {
      test('tab characters in text are preserved', () async {
        final textWithTabs = 'Step 1:\tMix\nStep 2:\tBake\nStep 3:\tServe';

        final recipe = Recipe(
          id: 'recipe-tabs',
          name: 'Test Recipe',
          instructions: textWithTabs,
          createdAt: DateTime.now(),
        );

        await mockDbHelper.insertRecipe(recipe);
        final retrieved = await mockDbHelper.getRecipe(recipe.id);

        expect(retrieved!.instructions, equals(textWithTabs));
        expect(retrieved.instructions.contains('\t'), isTrue);
      });

      test('mixed whitespace types are all preserved', () async {
        final mixedWhitespace = ' \t\n Leading space, tab, newline\n\t ';

        final recipe = Recipe(
          id: 'recipe-mixed',
          name: 'Test Recipe',
          notes: mixedWhitespace,
          createdAt: DateTime.now(),
        );

        await mockDbHelper.insertRecipe(recipe);
        final retrieved = await mockDbHelper.getRecipe(recipe.id);

        // All whitespace types preserved
        expect(retrieved!.notes, equals(mixedWhitespace));
        expect(retrieved.notes.contains(' '), isTrue);
        expect(retrieved.notes.contains('\t'), isTrue);
        expect(retrieved.notes.contains('\n'), isTrue);
      });

      test('zero-width spaces and special unicode whitespace are preserved', () async {
        // Various unicode whitespace characters
        final unicodeWhitespace = 'Text\u00A0with\u2003non-breaking\u2009spaces';

        final recipe = Recipe(
          id: 'recipe-unicode-space',
          name: 'Test Recipe',
          notes: unicodeWhitespace,
          createdAt: DateTime.now(),
        );

        await mockDbHelper.insertRecipe(recipe);
        final retrieved = await mockDbHelper.getRecipe(recipe.id);

        // Unicode whitespace should be preserved
        expect(retrieved!.notes, equals(unicodeWhitespace));
      });
    });

    group('Whitespace Consistency Across Operations', () {
      test('whitespace is consistent through serialization round-trip', () async {
        final textWithVariousWhitespace = '  \t Start\n\nMiddle  \t\n  End \t ';

        final recipe = Recipe(
          id: 'recipe-roundtrip',
          name: '  Recipe Name  ',
          notes: textWithVariousWhitespace,
          instructions: '\t\tIndented\n\tInstructions',
          createdAt: DateTime.now(),
        );

        // Serialize
        final recipeMap = recipe.toMap();

        // Deserialize
        final deserialized = Recipe.fromMap(recipeMap);

        // All whitespace should be preserved
        expect(deserialized.name, equals(recipe.name));
        expect(deserialized.notes, equals(recipe.notes));
        expect(deserialized.instructions, equals(recipe.instructions));

        // Store and retrieve
        await mockDbHelper.insertRecipe(recipe);
        final retrieved = await mockDbHelper.getRecipe(recipe.id);

        expect(retrieved!.name, equals(recipe.name));
        expect(retrieved.notes, equals(recipe.notes));
        expect(retrieved.instructions, equals(recipe.instructions));
      });
    });
  });
}
