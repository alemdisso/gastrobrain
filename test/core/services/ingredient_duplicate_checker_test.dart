import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/core/services/ingredient_duplicate_checker.dart';
import 'package:gastrobrain/models/ingredient.dart';
import 'package:gastrobrain/models/ingredient_category.dart';

Ingredient _ing(String id, String name, {List<String> aliases = const []}) =>
    Ingredient(id: id, name: name, category: IngredientCategory.vegetable, aliases: aliases);

void main() {
  group('IngredientDuplicateChecker', () {
    late IngredientDuplicateChecker checker;

    setUp(() {
      checker = IngredientDuplicateChecker([
        _ing('1', 'tomate'),
        _ing('2', 'tomate cereja'),
        _ing('3', 'cebola'),
        _ing('4', 'salsão', aliases: ['aipo', 'celery']),
      ]);
    });

    group('empty / short input', () {
      test('returns none for empty string', () {
        final result = checker.check('');
        expect(result.isClean, isTrue);
      });

      test('returns none for whitespace only', () {
        final result = checker.check('   ');
        expect(result.isClean, isTrue);
      });

      test('returns none for single-character input (below prefix threshold)', () {
        final result = checker.check('t');
        expect(result.isClean, isTrue);
      });
    });

    group('exact duplicate detection (name)', () {
      test('detects exact name match (same case)', () {
        final result = checker.check('tomate');
        expect(result.isExact, isTrue);
        expect(result.similarNames, contains('tomate'));
      });

      test('detects exact name match (different case)', () {
        final result = checker.check('Tomate');
        expect(result.isExact, isTrue);
      });

      test('detects exact name match with leading/trailing whitespace', () {
        final result = checker.check('  tomate  ');
        expect(result.isExact, isTrue);
      });

      test('detects exact name match after diacritic normalization', () {
        final checker2 = IngredientDuplicateChecker([
          _ing('1', 'óleo'),
        ]);
        final result = checker2.check('oleo');
        expect(result.isExact, isTrue);
      });
    });

    group('exact duplicate detection (alias)', () {
      test('hard-blocks a name that matches an existing alias', () {
        final result = checker.check('aipo');
        expect(result.isExact, isTrue);
        expect(result.similarNames, contains('salsão'));
      });

      test('alias match is case-insensitive', () {
        final result = checker.check('CELERY');
        expect(result.isExact, isTrue);
        expect(result.similarNames, contains('salsão'));
      });
    });

    group('prefix / similar suggestions', () {
      test('shows similar for prefix-of-existing-ingredient', () {
        // 'tom' is a prefix of 'tomate' and 'tomate cereja'
        final result = checker.check('tom');
        expect(result.hasSimilar, isTrue);
        expect(result.similarNames, containsAll(['tomate', 'tomate cereja']));
      });

      test('shows similar when typed name starts with existing ingredient name', () {
        // 'tomate extra' starts with 'tomate' (existing)
        final result = checker.check('tomate extra');
        expect(result.hasSimilar, isTrue);
        expect(result.similarNames, contains('tomate'));
      });

      test('returns none for unrelated name with 2+ chars', () {
        final result = checker.check('ba');
        expect(result.isClean, isTrue);
      });
    });

    group('edit mode (excludeId)', () {
      test('does not flag ingredient against itself when editing', () {
        // Editing 'tomate' (id='1') — should not report self as duplicate
        final result = checker.check('tomate', excludeId: '1');
        expect(result.isExact, isFalse);
      });

      test('still flags true duplicate when excluding a different id', () {
        // Editing 'tomate cereja' (id='2') — 'tomate' (id='1') is still there
        final result = checker.check('tomate', excludeId: '2');
        expect(result.isExact, isTrue);
        expect(result.similarNames, contains('tomate'));
      });

      test('does not show self in prefix suggestions when editing', () {
        // Editing 'tomate' (id='1'), typing 'tom' — should not list 'tomate' itself
        final result = checker.check('tom', excludeId: '1');
        expect(result.hasSimilar, isTrue);
        expect(result.similarNames, isNot(contains('tomate')));
        expect(result.similarNames, contains('tomate cereja'));
      });
    });

    group('no ingredients in list', () {
      test('returns none when ingredient list is empty', () {
        final emptyChecker = IngredientDuplicateChecker([]);
        final result = emptyChecker.check('tomate');
        expect(result.isClean, isTrue);
      });
    });
  });
}
