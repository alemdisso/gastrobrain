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

    group('Fraction Edge Cases', () {
      test('handles fraction greater than 1: 5/3', () {
        final result = parserService.parseIngredientLine('5/3 xícara de farinha');
        expect(result.quantity, closeTo(1.667, 0.001));
        expect(result.unit, equals('cup'));
      });

      test('handles fraction without unit', () {
        final result = parserService.parseIngredientLine('1/2 mangas');
        expect(result.quantity, equals(0.5));
        expect(result.unit, equals('piece'));
      });

      test('handles fraction without space before ingredient', () {
        final result = parserService.parseIngredientLine('½mangas');
        expect(result.quantity, equals(0.5));
        expect(result.unit, equals('piece'));
      });

      test('handles mixed number without unit', () {
        final result = parserService.parseIngredientLine('2 1/2 ovos');
        expect(result.quantity, equals(2.5));
        expect(result.unit, equals('piece'));
      });

      test('handles very large fraction', () {
        final result = parserService.parseIngredientLine('10/3 kg de tomates');
        expect(result.quantity, closeTo(3.333, 0.001));
        expect(result.unit, equals('kg'));
      });

      test('handles unicode fraction at start of line', () {
        final result = parserService.parseIngredientLine('⅛colher de chá de pimenta');
        expect(result.quantity, equals(0.125));
        expect(result.unit, equals('tsp'));
      });

      test('handles mixed number with large whole part', () {
        final result = parserService.parseIngredientLine('25 1/2 kg de farinha');
        expect(result.quantity, equals(25.5));
        expect(result.unit, equals('kg'));
      });

      test('verifies backward compatibility with decimals', () {
        final result = parserService.parseIngredientLine('1.5 xícara de açúcar');
        expect(result.quantity, equals(1.5));
        expect(result.unit, equals('cup'));
      });

      test('verifies backward compatibility with integers', () {
        final result = parserService.parseIngredientLine('3 kg de carne');
        expect(result.quantity, equals(3.0));
        expect(result.unit, equals('kg'));
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

    group('Slash Fraction Parsing', () {
      test('parses: 1/2 xícara de farinha', () {
        final result = parserService.parseIngredientLine('1/2 xícara de farinha');
        expect(result.quantity, equals(0.5));
        expect(result.unit, equals('cup'));
      });

      test('parses: 3/4 colher de sopa de mel', () {
        final result = parserService.parseIngredientLine('3/4 colher de sopa de mel');
        expect(result.quantity, equals(0.75));
        expect(result.unit, equals('tbsp'));
      });

      test('parses: 1/4 kg de açúcar', () {
        final result = parserService.parseIngredientLine('1/4 kg de açúcar');
        expect(result.quantity, equals(0.25));
        expect(result.unit, equals('kg'));
      });

      test('parses: 2/3 xícara de leite', () {
        final result = parserService.parseIngredientLine('2/3 xícara de leite');
        expect(result.quantity, closeTo(0.667, 0.001));
        expect(result.unit, equals('cup'));
      });

      test('parses: 1/3 colher de chá de canela', () {
        final result = parserService.parseIngredientLine('1/3 colher de chá de canela');
        expect(result.quantity, closeTo(0.333, 0.001));
        expect(result.unit, equals('tsp'));
      });

      test('parses: 5/4 xícara de farinha (fraction > 1)', () {
        final result = parserService.parseIngredientLine('5/4 xícara de farinha');
        expect(result.quantity, equals(1.25));
        expect(result.unit, equals('cup'));
      });

      test('handles invalid fraction: 1/0 (divide by zero)', () {
        final result = parserService.parseIngredientLine('1/0 xícara de farinha');
        expect(result.quantity, equals(1.0)); // Falls back to default
        expect(result.unit, equals('cup'));
      });
    });

    group('Mixed Number Parsing', () {
      test('parses: 2 1/2 kg de mangas', () {
        final result = parserService.parseIngredientLine('2 1/2 kg de mangas');
        expect(result.quantity, equals(2.5));
        expect(result.unit, equals('kg'));
        expect(result.ingredientName, equals('mangas'));
      });

      test('parses: 1 ½ xícara de açúcar', () {
        final result = parserService.parseIngredientLine('1 ½ xícara de açúcar');
        expect(result.quantity, equals(1.5));
        expect(result.unit, equals('cup'));
      });

      test('parses: 1 1/4 colheres de sopa de azeite', () {
        final result = parserService.parseIngredientLine('1 1/4 colheres de sopa de azeite');
        expect(result.quantity, equals(1.25));
        expect(result.unit, equals('tbsp'));
        expect(result.ingredientName, equals('azeite'));
      });

      test('parses: 3 3/4 xícaras de farinha', () {
        final result = parserService.parseIngredientLine('3 3/4 xícaras de farinha');
        expect(result.quantity, equals(3.75));
        expect(result.unit, equals('cup'));
      });

      test('parses: 2 ⅔ kg de tomates', () {
        final result = parserService.parseIngredientLine('2 ⅔ kg de tomates');
        expect(result.quantity, closeTo(2.667, 0.001));
        expect(result.unit, equals('kg'));
      });

      test('parses: 5 1/3 colheres de chá de canela', () {
        final result = parserService.parseIngredientLine('5 1/3 colheres de chá de canela');
        expect(result.quantity, closeTo(5.333, 0.001));
        expect(result.unit, equals('tsp'));
      });

      test('parses: 10 ¼ xícaras de leite', () {
        final result = parserService.parseIngredientLine('10 ¼ xícaras de leite');
        expect(result.quantity, equals(10.25));
        expect(result.unit, equals('cup'));
      });
    });

    group('Portuguese "de" with Fractions', () {
      test('parses: 1/4 de xícara de farinha', () {
        final result = parserService.parseIngredientLine('1/4 de xícara de farinha');
        expect(result.quantity, equals(0.25));
        expect(result.unit, equals('cup'));
      });

      test('parses: 1/3 de colher de chá de sal', () {
        final result = parserService.parseIngredientLine('1/3 de colher de chá de sal');
        expect(result.quantity, closeTo(0.333, 0.001));
        expect(result.unit, equals('tsp'));
        expect(result.ingredientName, equals('sal'));
      });

      test('parses: ½ de xícara de azeite', () {
        final result = parserService.parseIngredientLine('½ de xícara de azeite');
        expect(result.quantity, equals(0.5));
        expect(result.unit, equals('cup'));
        expect(result.ingredientName, equals('azeite'));
      });

      test('parses: 1 1/2 de colheres de sopa de mel', () {
        final result = parserService.parseIngredientLine('1 1/2 de colheres de sopa de mel');
        expect(result.quantity, equals(1.5));
        expect(result.unit, equals('tbsp'));
      });

      test('parses: ¾ de colher de chá de canela', () {
        final result = parserService.parseIngredientLine('¾ de colher de chá de canela');
        expect(result.quantity, equals(0.75));
        expect(result.unit, equals('tsp'));
      });

      test('parses: 2/3 de xícara de leite', () {
        final result = parserService.parseIngredientLine('2/3 de xícara de leite');
        expect(result.quantity, closeTo(0.667, 0.001));
        expect(result.unit, equals('cup'));
      });

      test('verifies compound units still work: 1/2 colher de sopa de mel', () {
        final result = parserService.parseIngredientLine('1/2 colher de sopa de mel');
        expect(result.quantity, equals(0.5));
        expect(result.unit, equals('tbsp'));
      });

      test('verifies mixed numbers with compound units: 1 1/2 colheres de chá de canela', () {
        final result = parserService.parseIngredientLine('1 1/2 colheres de chá de canela');
        expect(result.quantity, equals(1.5));
        expect(result.unit, equals('tsp'));
      });
    });

    group('Fraction + "de" + Ingredient (No Unit)', () {
      test('parses: 1/4 de pimenta dedo-de-moça', () {
        final result = parserService.parseIngredientLine('1/4 de pimenta dedo-de-moça');
        expect(result.quantity, equals(0.25));
        expect(result.unit, equals('piece'));
        expect(result.ingredientName, equals('pimenta dedo-de-moça'));
        // Ensure "de" is NOT part of ingredient name
        expect(result.ingredientName.toLowerCase().startsWith('de '), isFalse);
      });

      test('parses: 1/2 de cebola', () {
        final result = parserService.parseIngredientLine('1/2 de cebola');
        expect(result.quantity, equals(0.5));
        expect(result.unit, equals('piece'));
        expect(result.ingredientName, equals('cebola'));
        expect(result.ingredientName.toLowerCase().startsWith('de '), isFalse);
      });

      test('parses: ½ de abacate', () {
        final result = parserService.parseIngredientLine('½ de abacate');
        expect(result.quantity, equals(0.5));
        expect(result.unit, equals('piece'));
        expect(result.ingredientName, equals('abacate'));
        expect(result.ingredientName.toLowerCase().startsWith('de '), isFalse);
      });

      test('parses: 1 1/2 de tomate', () {
        final result = parserService.parseIngredientLine('1 1/2 de tomate');
        expect(result.quantity, equals(1.5));
        expect(result.unit, equals('piece'));
        expect(result.ingredientName, equals('tomate'));
        expect(result.ingredientName.toLowerCase().startsWith('de '), isFalse);
      });

      test('parses: 2/3 de laranja', () {
        final result = parserService.parseIngredientLine('2/3 de laranja');
        expect(result.quantity, closeTo(0.667, 0.001));
        expect(result.unit, equals('piece'));
        expect(result.ingredientName, equals('laranja'));
        expect(result.ingredientName.toLowerCase().startsWith('de '), isFalse);
      });

      test('parses: ¼ de limão', () {
        final result = parserService.parseIngredientLine('¼ de limão');
        expect(result.quantity, equals(0.25));
        expect(result.unit, equals('piece'));
        expect(result.ingredientName, equals('limão'));
        expect(result.ingredientName.toLowerCase().startsWith('de '), isFalse);
      });

      test('preserves "de" in compound ingredient names: 1/2 de pimenta-do-reino', () {
        final result = parserService.parseIngredientLine('1/2 de pimenta-do-reino');
        expect(result.quantity, equals(0.5));
        expect(result.unit, equals('piece'));
        // The first "de" should be stripped, but hyphens in the ingredient name preserved
        expect(result.ingredientName.contains('-'), isTrue);
        expect(result.ingredientName.toLowerCase().startsWith('de '), isFalse);
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

    group('New Measurement Units - Cans', () {
      test('parses "1 lata de tomate pelado" correctly', () {
        final result = parserService.parseIngredientLine('1 lata de tomate pelado');
        expect(result.quantity, equals(1));
        expect(result.unit, equals('can'));
        expect(result.ingredientName, equals('tomate pelado'));
      });

      test('parses "2 latas de atum" correctly', () {
        final result = parserService.parseIngredientLine('2 latas de atum');
        expect(result.quantity, equals(2));
        expect(result.unit, equals('can'));
        expect(result.ingredientName, equals('atum'));
      });

      test('parses "1 can of coconut milk" correctly', () {
        final result = parserService.parseIngredientLine('1 can of coconut milk');
        expect(result.quantity, equals(1));
        expect(result.unit, equals('can'));
        expect(result.ingredientName, contains('coconut milk'));
      });

      test('parses "2 cans of chickpeas" correctly', () {
        final result = parserService.parseIngredientLine('2 cans of chickpeas');
        expect(result.quantity, equals(2));
        expect(result.unit, equals('can'));
        expect(result.ingredientName, contains('chickpeas'));
      });
    });

    group('New Measurement Units - Boxes', () {
      test('parses "1 caixa de creme de leite" correctly', () {
        final result = parserService.parseIngredientLine('1 caixa de creme de leite');
        expect(result.quantity, equals(1));
        expect(result.unit, equals('box'));
        expect(result.ingredientName, equals('creme de leite'));
      });

      test('parses "2 caixas de gelatina" correctly', () {
        final result = parserService.parseIngredientLine('2 caixas de gelatina');
        expect(result.quantity, equals(2));
        expect(result.unit, equals('box'));
        expect(result.ingredientName, equals('gelatina'));
      });

      test('parses "1 box of cream" correctly', () {
        final result = parserService.parseIngredientLine('1 box of cream');
        expect(result.quantity, equals(1));
        expect(result.unit, equals('box'));
        expect(result.ingredientName, contains('cream'));
      });

      test('parses "2 boxes of gelatin" correctly', () {
        final result = parserService.parseIngredientLine('2 boxes of gelatin');
        expect(result.quantity, equals(2));
        expect(result.unit, equals('box'));
        expect(result.ingredientName, contains('gelatin'));
      });
    });

    group('New Measurement Units - Stems', () {
      test('parses "2 talos de salsão" correctly', () {
        final result = parserService.parseIngredientLine('2 talos de salsão');
        expect(result.quantity, equals(2));
        expect(result.unit, equals('stem'));
        expect(result.ingredientName, equals('salsão'));
      });

      test('parses "3 talos de cebolinha picados" correctly', () {
        final result = parserService.parseIngredientLine('3 talos de cebolinha picados');
        expect(result.quantity, equals(3));
        expect(result.unit, equals('stem'));
        expect(result.ingredientName, contains('cebolinha'));
      });

      test('parses "4 stems of celery" correctly', () {
        final result = parserService.parseIngredientLine('4 stems of celery');
        expect(result.quantity, equals(4));
        expect(result.unit, equals('stem'));
        expect(result.ingredientName, contains('celery'));
      });

      test('parses "2 stems of lemongrass" correctly', () {
        final result = parserService.parseIngredientLine('2 stems of lemongrass');
        expect(result.quantity, equals(2));
        expect(result.unit, equals('stem'));
        expect(result.ingredientName, contains('lemongrass'));
      });
    });

    group('New Measurement Units - Sprigs', () {
      test('parses "3 ramos de tomilho fresco" correctly', () {
        final result = parserService.parseIngredientLine('3 ramos de tomilho fresco');
        expect(result.quantity, equals(3));
        expect(result.unit, equals('sprig'));
        expect(result.ingredientName, contains('tomilho'));
      });

      test('parses "2 ramos de alecrim" correctly', () {
        final result = parserService.parseIngredientLine('2 ramos de alecrim');
        expect(result.quantity, equals(2));
        expect(result.unit, equals('sprig'));
        expect(result.ingredientName, equals('alecrim'));
      });

      test('parses "4 sprigs of thyme" correctly', () {
        final result = parserService.parseIngredientLine('4 sprigs of thyme');
        expect(result.quantity, equals(4));
        expect(result.unit, equals('sprig'));
        expect(result.ingredientName, contains('thyme'));
      });

      test('parses "2 sprigs of fresh parsley" correctly', () {
        final result = parserService.parseIngredientLine('2 sprigs of fresh parsley');
        expect(result.quantity, equals(2));
        expect(result.unit, equals('sprig'));
        expect(result.ingredientName, contains('parsley'));
      });
    });

    group('New Measurement Units - Seeds', () {
      test('parses "4 sementes de cardamomo" correctly', () {
        final result = parserService.parseIngredientLine('4 sementes de cardamomo');
        expect(result.quantity, equals(4));
        expect(result.unit, equals('seed'));
        expect(result.ingredientName, equals('cardamomo'));
      });

      test('parses "6 sementes de coentro" correctly', () {
        final result = parserService.parseIngredientLine('6 sementes de coentro');
        expect(result.quantity, equals(6));
        expect(result.unit, equals('seed'));
        expect(result.ingredientName, equals('coentro'));
      });

      test('parses "5 seeds of fennel" correctly', () {
        final result = parserService.parseIngredientLine('5 seeds of fennel');
        expect(result.quantity, equals(5));
        expect(result.unit, equals('seed'));
        expect(result.ingredientName, contains('fennel'));
      });

      test('parses "3 seeds of star anise" correctly', () {
        final result = parserService.parseIngredientLine('3 seeds of star anise');
        expect(result.quantity, equals(3));
        expect(result.unit, equals('seed'));
        expect(result.ingredientName, contains('star anise'));
      });
    });

    group('New Measurement Units - Grains', () {
      test('parses "6 grãos de pimenta-do-reino" correctly', () {
        final result = parserService.parseIngredientLine('6 grãos de pimenta-do-reino');
        expect(result.quantity, equals(6));
        expect(result.unit, equals('grain'));
        expect(result.ingredientName, equals('pimenta-do-reino'));
      });

      test('parses "8 grãos de pimenta rosa" correctly', () {
        final result = parserService.parseIngredientLine('8 grãos de pimenta rosa');
        expect(result.quantity, equals(8));
        expect(result.unit, equals('grain'));
        expect(result.ingredientName, equals('pimenta rosa'));
      });

      test('parses "6 graos de pimenta" (without tilde) correctly', () {
        final result = parserService.parseIngredientLine('6 graos de pimenta');
        expect(result.quantity, equals(6));
        expect(result.unit, equals('grain'));
        expect(result.ingredientName, equals('pimenta'));
      });

      test('parses "10 grains of black pepper" correctly', () {
        final result = parserService.parseIngredientLine('10 grains of black pepper');
        expect(result.quantity, equals(10));
        expect(result.unit, equals('grain'));
        expect(result.ingredientName, contains('black pepper'));
      });

      test('parses "5 grains of cardamom" correctly', () {
        final result = parserService.parseIngredientLine('5 grains of cardamom');
        expect(result.quantity, equals(5));
        expect(result.unit, equals('grain'));
        expect(result.ingredientName, contains('cardamom'));
      });
    });

    group('New Measurement Units - Centimeters', () {
      test('parses "5cm de gengibre" correctly', () {
        final result = parserService.parseIngredientLine('5cm de gengibre');
        expect(result.quantity, equals(5));
        expect(result.unit, equals('cm'));
        expect(result.ingredientName, equals('gengibre'));
      });

      test('parses "10 centímetros de canela em pau" correctly', () {
        final result = parserService.parseIngredientLine('10 centímetros de canela em pau');
        expect(result.quantity, equals(10));
        expect(result.unit, equals('cm'));
        expect(result.ingredientName, contains('canela'));
      });

      test('parses "10 centimetros de canela" (without accent) correctly', () {
        final result = parserService.parseIngredientLine('10 centimetros de canela');
        expect(result.quantity, equals(10));
        expect(result.unit, equals('cm'));
        expect(result.ingredientName, equals('canela'));
      });

      test('parses "3 cm of ginger root" correctly', () {
        final result = parserService.parseIngredientLine('3 cm of ginger root');
        expect(result.quantity, equals(3));
        expect(result.unit, equals('cm'));
        expect(result.ingredientName, contains('ginger'));
      });

      test('parses "2 centimeters of turmeric" correctly', () {
        final result = parserService.parseIngredientLine('2 centimeters of turmeric');
        expect(result.quantity, equals(2));
        expect(result.unit, equals('cm'));
        expect(result.ingredientName, contains('turmeric'));
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
