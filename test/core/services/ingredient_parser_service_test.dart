import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/core/services/ingredient_parser_service.dart';
import 'package:gastrobrain/core/services/ingredient_matching_service.dart';
import 'package:gastrobrain/models/ingredient.dart';
import 'package:gastrobrain/models/ingredient_category.dart';
import 'package:gastrobrain/models/measurement_unit.dart';
import 'package:gastrobrain/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

void main() {
  group('IngredientParserService', () {
    late IngredientParserService parserService;
    late IngredientMatchingService matchingService;
    late AppLocalizations localizations;

    setUp(() async {
      // Get localizations for Portuguese
      localizations = await _getLocalizations();

      // Create test ingredients for matching
      final testIngredients = [
        Ingredient(
          id: '1',
          name: 'mangas',
          category: IngredientCategory.fruit,
          unit: MeasurementUnit.piece,
        ),
        Ingredient(
          id: '2',
          name: 'pasta de tamarindo',
          category: IngredientCategory.other,
          unit: MeasurementUnit.gram,
        ),
        Ingredient(
          id: '3',
          name: 'pão de forma',
          category: IngredientCategory.grain,
          unit: MeasurementUnit.slice,
        ),
        Ingredient(
          id: '4',
          name: 'queijo de cabra',
          category: IngredientCategory.dairy,
          unit: MeasurementUnit.gram,
        ),
        Ingredient(
          id: '5',
          name: 'azeite',
          category: IngredientCategory.oil,
          unit: MeasurementUnit.tablespoon,
        ),
        Ingredient(
          id: '6',
          name: 'sal',
          category: IngredientCategory.seasoning,
          unit: MeasurementUnit.pinch,
        ),
        Ingredient(
          id: '7',
          name: 'ovos',
          category: IngredientCategory.protein,
          unit: MeasurementUnit.piece,
        ),
      ];

      // Initialize matching service
      matchingService = IngredientMatchingService();
      matchingService.initialize(testIngredients);

      // Initialize parser service
      parserService = IngredientParserService();
      parserService.initialize(localizations, matchingService: matchingService);
    });

    group('Unit Matching', () {
      test('matches simple units', () {
        final match = parserService.matchUnitAtStart('kg de mangas');
        expect(match, isNotNull);
        expect(match!.unit, equals('kg'));
        expect(match.remaining, equals('de mangas'));
      });

      test('matches compound units (colheres de sopa)', () {
        final match = parserService.matchUnitAtStart('colheres de sopa de azeite');
        expect(match, isNotNull);
        expect(match!.unit, equals('tbsp'));
        expect(match.remaining, equals('de azeite'));
      });

      test('matches compound units (colher de sopa)', () {
        final match = parserService.matchUnitAtStart('colher de sopa de pasta');
        expect(match, isNotNull);
        expect(match!.unit, equals('tbsp'));
        expect(match.remaining, equals('de pasta'));
      });

      test('matches compound units (colheres de chá)', () {
        final match = parserService.matchUnitAtStart('colheres de chá de sal');
        expect(match, isNotNull);
        expect(match!.unit, equals('tsp'));
        expect(match.remaining, equals('de sal'));
      });

      test('matches longest unit first', () {
        // Should match "colheres de sopa" not just "colheres"
        final match = parserService.matchUnitAtStart('colheres de sopa de azeite');
        expect(match, isNotNull);
        expect(match!.unit, equals('tbsp'));
        expect(match.matchedString.toLowerCase(), equals('colheres de sopa'));
      });

      test('returns null for non-unit text', () {
        final match = parserService.matchUnitAtStart('mangas maduras');
        expect(match, isNull);
      });

      test('respects word boundaries', () {
        // "colheres" should not match "colheresXYZ"
        final match = parserService.matchUnitAtStart('colheresXYZ');
        expect(match, isNull);
      });
    });

    group('Context-Aware "de" Stripping', () {
      test('strips "de" after kg unit', () {
        final result = parserService.parseIngredientLine('2 kg de mangas');
        expect(result.quantity, equals(2));
        expect(result.unit, equals('kg'));
        expect(result.ingredientName, equals('mangas'));
      });

      test('strips "de" after compound unit (colheres de sopa)', () {
        final result = parserService.parseIngredientLine('2 colheres de sopa de azeite');
        expect(result.quantity, equals(2));
        expect(result.unit, equals('tbsp'));
        expect(result.ingredientName, equals('azeite'));
      });

      test('preserves "de" in ingredient name (pão de forma)', () {
        final result = parserService.parseIngredientLine('1 fatia de pão de forma');
        expect(result.quantity, equals(1));
        expect(result.unit, equals('slice'));
        expect(result.ingredientName, equals('pão de forma'));
      });

      test('preserves "de" in ingredient name (queijo de cabra)', () {
        final result = parserService.parseIngredientLine('100g de queijo de cabra');
        expect(result.quantity, equals(100));
        expect(result.unit, equals('g'));
        expect(result.ingredientName, equals('queijo de cabra'));
      });

      test('preserves "de" in ingredient name (pasta de tamarindo)', () {
        final result = parserService.parseIngredientLine('2 colheres de sopa de pasta de tamarindo');
        expect(result.quantity, equals(2));
        expect(result.unit, equals('tbsp'));
        expect(result.ingredientName, equals('pasta de tamarindo'));
      });
    });

    group('Complete Parsing Examples', () {
      test('parses: 2 kg de mangas firmes, mas maduras', () {
        final result = parserService.parseIngredientLine('2 kg de mangas firmes, mas maduras');
        expect(result.quantity, equals(2));
        expect(result.unit, equals('kg'));
        expect(result.ingredientName, equals('mangas'));
        expect(result.notes, isNotNull);
        expect(result.notes!.toLowerCase(), contains('firmes'));
      });

      test('parses: 2 colheres de sopa de pasta de tamarindo em ponto de bala', () {
        final result = parserService.parseIngredientLine(
            '2 colheres de sopa de pasta de tamarindo em ponto de bala');
        expect(result.quantity, equals(2));
        expect(result.unit, equals('tbsp'));
        expect(result.ingredientName, equals('pasta de tamarindo'));
        expect(result.notes, isNotNull);
        expect(result.notes!.toLowerCase(), contains('ponto'));
      });

      test('parses: 1 fatia de pão de forma', () {
        final result = parserService.parseIngredientLine('1 fatia de pão de forma');
        expect(result.quantity, equals(1));
        expect(result.unit, equals('slice'));
        expect(result.ingredientName, equals('pão de forma'));
      });

      test('parses: 100g de queijo de cabra maduro', () {
        final result = parserService.parseIngredientLine('100g de queijo de cabra maduro');
        expect(result.quantity, equals(100));
        expect(result.unit, equals('g'));
        expect(result.ingredientName, equals('queijo de cabra'));
        expect(result.notes, equals('maduro'));
      });

      test('parses: 2 colheres de sopa de azeite', () {
        final result = parserService.parseIngredientLine('2 colheres de sopa de azeite');
        expect(result.quantity, equals(2));
        expect(result.unit, equals('tbsp'));
        expect(result.ingredientName, equals('azeite'));
      });

      test('parses: Sal a gosto', () {
        final result = parserService.parseIngredientLine('Sal a gosto');
        expect(result.quantity, equals(0));
        expect(result.unit, isNull);
        expect(result.ingredientName, equals('sal'));
        expect(result.notes, equals('a gosto'));
      });

      test('parses: 3 ovos', () {
        final result = parserService.parseIngredientLine('3 ovos');
        expect(result.quantity, equals(3));
        expect(result.unit, equals('piece'));
        expect(result.ingredientName, equals('ovos'));
      });
    });

    group('Edge Cases', () {
      test('handles empty string', () {
        final result = parserService.parseIngredientLine('');
        expect(result.ingredientName, equals(''));
        expect(result.quantity, equals(0));
      });

      test('handles quantity with comma', () {
        final result = parserService.parseIngredientLine('2,5 kg de mangas');
        expect(result.quantity, equals(2.5));
      });

      test('handles quantity with period', () {
        final result = parserService.parseIngredientLine('2.5 kg de mangas');
        expect(result.quantity, equals(2.5));
      });

      test('handles quantity without space before unit', () {
        final result = parserService.parseIngredientLine('200g de farinha');
        expect(result.quantity, equals(200));
        expect(result.unit, equals('g'));
      });

      test('handles ingredient without quantity', () {
        final result = parserService.parseIngredientLine('sal');
        expect(result.quantity, equals(1.0));
        expect(result.ingredientName, equals('sal'));
      });

      test('handles unrecognized unit (defaults to piece)', () {
        final result = parserService.parseIngredientLine('3 xyz ingredient');
        expect(result.quantity, equals(3));
        expect(result.unit, equals('piece'));
      });
    });

    group('Unicode Fraction Parsing', () {
      test('parses: ½ xícara de farinha', () {
        final result = parserService.parseIngredientLine('½ xícara de farinha');
        expect(result.quantity, equals(0.5));
        expect(result.unit, equals('cup'));
      });

      test('parses: ¼ colher de sopa de azeite', () {
        final result = parserService.parseIngredientLine('¼ colher de sopa de azeite');
        expect(result.quantity, equals(0.25));
        expect(result.unit, equals('tbsp'));
        expect(result.ingredientName, equals('azeite'));
      });

      test('parses: ¾ kg de mangas', () {
        final result = parserService.parseIngredientLine('¾ kg de mangas');
        expect(result.quantity, equals(0.75));
        expect(result.unit, equals('kg'));
        expect(result.ingredientName, equals('mangas'));
      });

      test('parses: ⅓ xícara de açúcar', () {
        final result = parserService.parseIngredientLine('⅓ xícara de açúcar');
        expect(result.quantity, closeTo(0.333, 0.001));
        expect(result.unit, equals('cup'));
      });

      test('parses: ⅔ colher de chá de sal', () {
        final result = parserService.parseIngredientLine('⅔ colher de chá de sal');
        expect(result.quantity, closeTo(0.667, 0.001));
        expect(result.unit, equals('tsp'));
        expect(result.ingredientName, equals('sal'));
      });

      test('parses: ⅛ colher de chá de canela', () {
        final result = parserService.parseIngredientLine('⅛ colher de chá de canela');
        expect(result.quantity, equals(0.125));
        expect(result.unit, equals('tsp'));
      });

      test('parses: ⅞ xícara de leite', () {
        final result = parserService.parseIngredientLine('⅞ xícara de leite');
        expect(result.quantity, equals(0.875));
        expect(result.unit, equals('cup'));
      });
    });

    group('Localization Support', () {
      test('recognizes Portuguese unit names', () {
        final result = parserService.parseIngredientLine('2 xícaras de farinha');
        expect(result.unit, equals('cup'));
      });

      test('recognizes English unit names', () {
        final result = parserService.parseIngredientLine('2 cups of flour');
        expect(result.unit, equals('cup'));
      });

      test('recognizes abbreviations', () {
        final result = parserService.parseIngredientLine('2 csp de azeite');
        expect(result.unit, equals('tbsp'));
      });
    });

    group('Initialization', () {
      test('throws StateError if not initialized', () {
        final uninitializedService = IngredientParserService();
        expect(
          () => uninitializedService.parseIngredientLine('test'),
          throwsStateError,
        );
      });

      test('throws StateError if matchUnitAtStart called before init', () {
        final uninitializedService = IngredientParserService();
        expect(
          () => uninitializedService.matchUnitAtStart('test'),
          throwsStateError,
        );
      });
    });
  });
}

/// Helper to get AppLocalizations for Portuguese
Future<AppLocalizations> _getLocalizations() async {
  return await AppLocalizations.delegate.load(const Locale('pt'));
}
