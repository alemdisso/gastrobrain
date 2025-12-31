// test/edge_cases/boundary_conditions/special_characters_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/ingredient.dart';
import 'package:gastrobrain/models/ingredient_category.dart';
import '../../fixtures/boundary_fixtures.dart';
import '../../mocks/mock_database_helper.dart';

/// Tests for special character and unicode handling.
///
/// Verifies that the application correctly handles:
/// - HTML/XML special characters (<>'"&)
/// - Emoji in text fields
/// - Unicode characters (accents, international characters)
/// - Newlines and tabs in text
/// - Markdown-like syntax in notes
/// - SQL injection attempts (should be safely escaped)
/// - XSS attempts (should be safely stored)
///
/// These tests ensure data integrity and security when handling
/// unusual or potentially malicious input.
void main() {
  group('Special Characters & Unicode Tests', () {
    late MockDatabaseHelper mockDbHelper;

    setUp(() {
      mockDbHelper = MockDatabaseHelper();
    });

    tearDown(() {
      mockDbHelper.resetAllData();
    });

    group('HTML/XML Special Characters', () {
      test('recipe name with HTML special chars is accepted and stored', () async {
        final recipe = Recipe(
          id: 'recipe-html',
          name: BoundaryValues.specialChars,
          createdAt: DateTime.now(),
        );

        expect(recipe.name, equals(BoundaryValues.specialChars));
        expect(recipe.name, contains('<'));
        expect(recipe.name, contains('>'));
        expect(recipe.name, contains('"'));
        expect(recipe.name, contains("'"));
        expect(recipe.name, contains('&'));

        // Should be stored and retrieved safely
        await mockDbHelper.insertRecipe(recipe);
        final retrieved = await mockDbHelper.getRecipe(recipe.id);
        expect(retrieved!.name, equals(BoundaryValues.specialChars));

        // Characters should not be escaped or modified
        expect(retrieved.name, contains('<script>'));
      });

      test('notes with HTML special chars are stored without modification', () async {
        final recipe = Recipe(
          id: 'recipe-notes-html',
          name: 'Test Recipe',
          notes: 'Recipe notes: ${BoundaryValues.specialChars}',
          createdAt: DateTime.now(),
        );

        await mockDbHelper.insertRecipe(recipe);
        final retrieved = await mockDbHelper.getRecipe(recipe.id);

        // Notes should preserve special characters exactly
        expect(retrieved!.notes, equals(recipe.notes));
        expect(retrieved.notes, contains('<'));
        expect(retrieved.notes, contains('>'));
      });
    });

    group('Emoji Support', () {
      test('recipe name with emoji is accepted and stored', () async {
        final recipe = Recipe(
          id: 'recipe-emoji',
          name: BoundaryValues.withEmoji,
          createdAt: DateTime.now(),
        );

        expect(recipe.name, equals(BoundaryValues.withEmoji));
        expect(recipe.name, contains('😀'));
        expect(recipe.name, contains('🎉'));
        expect(recipe.name, contains('🍕'));

        // Should be stored and retrieved correctly
        await mockDbHelper.insertRecipe(recipe);
        final retrieved = await mockDbHelper.getRecipe(recipe.id);
        expect(retrieved!.name, equals(BoundaryValues.withEmoji));

        // Emoji should be preserved
        expect(retrieved.name, contains('😀'));
        expect(retrieved.name, contains('🍕'));
      });

      test('notes with emoji are stored correctly', () async {
        final recipe = Recipe(
          id: 'recipe-notes-emoji',
          name: 'Test Recipe',
          notes: 'Delicious! 😋 Perfect for parties! 🎉',
          createdAt: DateTime.now(),
        );

        await mockDbHelper.insertRecipe(recipe);
        final retrieved = await mockDbHelper.getRecipe(recipe.id);

        expect(retrieved!.notes, equals(recipe.notes));
        expect(retrieved.notes, contains('😋'));
        expect(retrieved.notes, contains('🎉'));
      });
    });

    group('Unicode Characters', () {
      test('recipe name with unicode (accents) is accepted and stored', () async {
        final recipe = Recipe(
          id: 'recipe-unicode',
          name: BoundaryValues.withUnicode,
          createdAt: DateTime.now(),
        );

        expect(recipe.name, equals(BoundaryValues.withUnicode));
        expect(recipe.name, contains('è')); // Crème
        expect(recipe.name, contains('û')); // brûlée
        expect(recipe.name, contains('ñ')); // Jalapeño
        expect(recipe.name, contains('ï')); // Naïve

        // Should be stored and retrieved correctly
        await mockDbHelper.insertRecipe(recipe);
        final retrieved = await mockDbHelper.getRecipe(recipe.id);
        expect(retrieved!.name, equals(BoundaryValues.withUnicode));

        // Accents should be preserved
        expect(retrieved.name, contains('Crème'));
        expect(retrieved.name, contains('brûlée'));
      });

      test('ingredient name with unicode is accepted and stored', () async {
        final ingredient = Ingredient(
          id: 'ing-unicode',
          name: BoundaryValues.ingredientUnicode,
          category: IngredientCategory.vegetable,
        );

        expect(ingredient.name, contains('ñ'));

        await mockDbHelper.insertIngredient(ingredient);
        final retrieved = mockDbHelper.ingredients[ingredient.id]!;
        expect(retrieved.name, equals(BoundaryValues.ingredientUnicode));
        expect(retrieved.name, contains('Jalapeño'));
      });
    });

    group('Newlines and Tabs', () {
      test('notes with newlines are accepted and preserved', () async {
        final recipe = Recipe(
          id: 'recipe-newlines',
          name: 'Test Recipe',
          notes: BoundaryValues.withNewlines,
          createdAt: DateTime.now(),
        );

        expect(recipe.notes, contains('\n'));

        // Should be stored and retrieved with newlines preserved
        await mockDbHelper.insertRecipe(recipe);
        final retrieved = await mockDbHelper.getRecipe(recipe.id);
        expect(retrieved!.notes, equals(BoundaryValues.withNewlines));
        expect(retrieved.notes, contains('\n'));

        // Should have 3 lines
        final lines = retrieved.notes.split('\n');
        expect(lines.length, equals(3));
        expect(lines[0], equals('Line 1'));
        expect(lines[1], equals('Line 2'));
        expect(lines[2], equals('Line 3'));
      });

      test('instructions with mixed whitespace are preserved', () async {
        final instructions = 'Step 1:\tPreheat oven\nStep 2:\tMix ingredients\n\tStir well';

        final recipe = Recipe(
          id: 'recipe-whitespace',
          name: 'Test Recipe',
          instructions: instructions,
          createdAt: DateTime.now(),
        );

        await mockDbHelper.insertRecipe(recipe);
        final retrieved = await mockDbHelper.getRecipe(recipe.id);
        expect(retrieved!.instructions, equals(instructions));

        // Tabs and newlines should be preserved
        expect(retrieved.instructions, contains('\t'));
        expect(retrieved.instructions, contains('\n'));
      });
    });

    group('Markdown-like Syntax', () {
      test('notes with markdown syntax are stored as plain text', () async {
        final markdownNotes = '''
# Recipe Title

## Ingredients
- Item 1
- Item 2

## Instructions
1. **Bold step**
2. *Italic step*
3. `Code snippet`

> Quote

[Link](http://example.com)
''';

        final recipe = Recipe(
          id: 'recipe-markdown',
          name: 'Test Recipe',
          notes: markdownNotes,
          createdAt: DateTime.now(),
        );

        await mockDbHelper.insertRecipe(recipe);
        final retrieved = await mockDbHelper.getRecipe(recipe.id);

        // Markdown should be stored as-is, not rendered
        expect(retrieved!.notes, equals(markdownNotes));
        expect(retrieved.notes, contains('# Recipe Title'));
        expect(retrieved.notes, contains('**Bold step**'));
        expect(retrieved.notes, contains('*Italic step*'));
        expect(retrieved.notes, contains('[Link](http://example.com)'));
      });
    });

    group('SQL Injection Protection', () {
      test('SQL injection attempt in recipe name is safely stored', () async {
        final recipe = Recipe(
          id: 'recipe-sql',
          name: BoundaryValues.sqlInjection,
          createdAt: DateTime.now(),
        );

        expect(recipe.name, equals(BoundaryValues.sqlInjection));
        expect(recipe.name, contains("'; DROP TABLE"));

        // Should be stored safely without executing SQL
        await mockDbHelper.insertRecipe(recipe);
        final retrieved = await mockDbHelper.getRecipe(recipe.id);
        expect(retrieved!.name, equals(BoundaryValues.sqlInjection));

        // Verify database is still intact (recipes table not dropped)
        expect(() => mockDbHelper.recipes, returnsNormally);
        expect(mockDbHelper.recipes, isNotEmpty);
      });

      test('SQL injection attempt in notes is safely stored', () async {
        final recipe = Recipe(
          id: 'recipe-notes-sql',
          name: 'Test Recipe',
          notes: "Notes: ${BoundaryValues.sqlInjection}",
          createdAt: DateTime.now(),
        );

        await mockDbHelper.insertRecipe(recipe);
        final retrieved = await mockDbHelper.getRecipe(recipe.id);

        expect(retrieved!.notes, contains(BoundaryValues.sqlInjection));

        // Database should remain intact
        expect(mockDbHelper.recipes.length, greaterThanOrEqualTo(1));
      });

      test('SQL injection in ingredient name is safely stored', () async {
        final ingredient = Ingredient(
          id: 'ing-sql',
          name: "Salt'; DROP TABLE ingredients; --",
          category: IngredientCategory.seasoning,
        );

        await mockDbHelper.insertIngredient(ingredient);
        final retrieved = mockDbHelper.ingredients[ingredient.id]!;

        expect(retrieved.name, contains('DROP TABLE'));

        // Database should remain intact
        expect(mockDbHelper.ingredients, isNotEmpty);
      });
    });

    group('XSS Protection', () {
      test('XSS attempt in recipe name is safely stored', () async {
        final recipe = Recipe(
          id: 'recipe-xss',
          name: BoundaryValues.xssAttempt,
          createdAt: DateTime.now(),
        );

        expect(recipe.name, equals(BoundaryValues.xssAttempt));
        expect(recipe.name, contains('<img src='));
        expect(recipe.name, contains('onerror='));

        // Should be stored as plain text, not executed
        await mockDbHelper.insertRecipe(recipe);
        final retrieved = await mockDbHelper.getRecipe(recipe.id);
        expect(retrieved!.name, equals(BoundaryValues.xssAttempt));

        // XSS payload should be stored as-is (not executed)
        expect(retrieved.name, contains('<img'));
        expect(retrieved.name, contains('alert(1)'));
      });

      test('XSS attempt in notes is safely stored', () async {
        final recipe = Recipe(
          id: 'recipe-notes-xss',
          name: 'Test Recipe',
          notes: 'Recipe notes: ${BoundaryValues.xssAttempt}',
          createdAt: DateTime.now(),
        );

        await mockDbHelper.insertRecipe(recipe);
        final retrieved = await mockDbHelper.getRecipe(recipe.id);

        expect(retrieved!.notes, contains(BoundaryValues.xssAttempt));
        expect(retrieved.notes, contains('onerror='));
      });
    });

    group('Multiple Consecutive Spaces', () {
      test('recipe name with multiple spaces is preserved', () async {
        final recipe = Recipe(
          id: 'recipe-spaces',
          name: BoundaryValues.multipleSpaces,
          createdAt: DateTime.now(),
        );

        expect(recipe.name, contains('    '));

        // Multiple spaces should be preserved
        await mockDbHelper.insertRecipe(recipe);
        final retrieved = await mockDbHelper.getRecipe(recipe.id);
        expect(retrieved!.name, equals(BoundaryValues.multipleSpaces));

        // Spaces should not be collapsed
        expect(retrieved.name, contains('Word    with'));
      });
    });

    group('Combined Special Characters', () {
      test('text with mixed special chars, unicode, and emoji is handled', () async {
        final complexText = 'Crème "Brûlée" <Recipe> 🍰 & Jalapeño \'Sauce\'\n'
            'With: Tabs\there & Newlines!\n'
            '**Bold** & *Italic* & `code`';

        final recipe = Recipe(
          id: 'recipe-complex',
          name: 'Complex Recipe',
          notes: complexText,
          createdAt: DateTime.now(),
        );

        await mockDbHelper.insertRecipe(recipe);
        final retrieved = await mockDbHelper.getRecipe(recipe.id);

        // All special characters should be preserved
        expect(retrieved!.notes, equals(complexText));
        expect(retrieved.notes, contains('Crème'));
        expect(retrieved.notes, contains('🍰'));
        expect(retrieved.notes, contains('<Recipe>'));
        expect(retrieved.notes, contains('\t'));
        expect(retrieved.notes, contains('\n'));
        expect(retrieved.notes, contains('**Bold**'));
      });

      test('round-trip with special chars preserves all data', () async {
        final recipe = Recipe(
          id: 'recipe-roundtrip-special',
          name: 'Recipe 😋 <with> "special" \'chars\'',
          notes: BoundaryValues.sqlInjection,
          instructions: BoundaryValues.xssAttempt,
          createdAt: DateTime.now(),
        );

        // Serialize to map
        final recipeMap = recipe.toMap();

        // Deserialize from map
        final deserialized = Recipe.fromMap(recipeMap);

        // All fields should be preserved exactly
        expect(deserialized.name, equals(recipe.name));
        expect(deserialized.notes, equals(recipe.notes));
        expect(deserialized.instructions, equals(recipe.instructions));

        // Store and retrieve from database
        await mockDbHelper.insertRecipe(recipe);
        final retrieved = await mockDbHelper.getRecipe(recipe.id);

        expect(retrieved!.name, equals(recipe.name));
        expect(retrieved.notes, equals(recipe.notes));
        expect(retrieved.instructions, equals(recipe.instructions));
      });
    });
  });
}
