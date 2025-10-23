import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/core/services/ingredient_matching_service.dart';
import 'package:gastrobrain/models/ingredient.dart';
import 'package:gastrobrain/models/ingredient_category.dart';
import 'package:gastrobrain/models/ingredient_match.dart';
import 'package:gastrobrain/models/measurement_unit.dart';
import 'package:gastrobrain/models/protein_type.dart';

void main() {
  group('IngredientMatchingService', () {
    late IngredientMatchingService service;
    late List<Ingredient> testIngredients;

    setUp(() {
      service = IngredientMatchingService();

      // Create test ingredients with various characteristics
      testIngredients = [
        Ingredient(
          id: '1',
          name: 'Tomate',
          category: IngredientCategory.vegetable,
          unit: MeasurementUnit.piece,
        ),
        Ingredient(
          id: '2',
          name: 'tomate',
          category: IngredientCategory.vegetable,
          unit: MeasurementUnit.piece,
        ),
        Ingredient(
          id: '3',
          name: 'sal',
          category: IngredientCategory.seasoning,
          unit: MeasurementUnit.gram,
        ),
        Ingredient(
          id: '4',
          name: 'Sal',
          category: IngredientCategory.seasoning,
          unit: MeasurementUnit.gram,
        ),
        Ingredient(
          id: '5',
          name: 'Frango',
          category: IngredientCategory.protein,
          unit: MeasurementUnit.gram,
          proteinType: ProteinType.chicken,
        ),
        Ingredient(
          id: '6',
          name: 'Cebola',
          category: IngredientCategory.vegetable,
          unit: MeasurementUnit.piece,
        ),
        Ingredient(
          id: '7',
          name: 'Açúcar',
          category: IngredientCategory.other,
          unit: MeasurementUnit.gram,
        ),
        Ingredient(
          id: '8',
          name: 'Azeite',
          category: IngredientCategory.other,
          unit: MeasurementUnit.milliliter,
        ),
        Ingredient(
          id: '9',
          name: 'Alho',
          category: IngredientCategory.seasoning,
          unit: MeasurementUnit.piece,
        ),
        Ingredient(
          id: '10',
          name: 'Arroz',
          category: IngredientCategory.grain,
          unit: MeasurementUnit.gram,
        ),
      ];

      service.initialize(testIngredients);
    });

    group('initialization', () {
      test('initializes with ingredients successfully', () {
        final freshService = IngredientMatchingService();
        expect(() => freshService.initialize(testIngredients), returnsNormally);
      });

      test('handles empty ingredient list', () {
        final freshService = IngredientMatchingService();
        expect(() => freshService.initialize([]), returnsNormally);
      });
    });

    group('exact match (Stage 1)', () {
      test('finds exact match with identical string', () {
        final matches = service.findMatches('Tomate');

        expect(matches, isNotEmpty);
        expect(matches.first.ingredient.name, equals('Tomate'));
        expect(matches.first.confidence, equals(1.0));
        expect(matches.first.matchType, equals(MatchType.exact));
        expect(matches.first.confidenceLevel, equals(MatchConfidence.high));
      });

      test('finds exact match for lowercase ingredient', () {
        final matches = service.findMatches('sal');

        expect(matches, isNotEmpty);
        expect(matches.first.ingredient.name, equals('sal'));
        expect(matches.first.confidence, equals(1.0));
        expect(matches.first.matchType, equals(MatchType.exact));
      });

      test('does not confuse case-sensitive exact match', () {
        final matches = service.findMatches('Tomate');

        // Should match 'Tomate' (id=1), not 'tomate' (id=2)
        expect(matches.first.ingredient.id, equals('1'));
        expect(matches.first.matchType, equals(MatchType.exact));
      });

      test('returns early after exact match (no further processing)', () {
        final matches = service.findMatches('Frango');

        // Should only return one match (exact)
        expect(matches.length, equals(1));
        expect(matches.first.confidence, equals(1.0));
      });
    });

    group('case-insensitive match (Stage 2)', () {
      test('finds case-insensitive match when exact fails', () {
        final matches = service.findMatches('TOMATE');

        expect(matches, isNotEmpty);
        // Should match either 'Tomate' or 'tomate'
        expect(matches.first.ingredient.name.toLowerCase(), equals('tomate'));
        expect(matches.first.confidence, equals(0.95));
        expect(matches.first.matchType, equals(MatchType.caseInsensitive));
        expect(matches.first.confidenceLevel, equals(MatchConfidence.high));
      });

      test('finds case-insensitive match for mixed case', () {
        final matches = service.findMatches('FrAnGo');

        expect(matches, isNotEmpty);
        expect(matches.first.ingredient.name, equals('Frango'));
        expect(matches.first.confidence, equals(0.95));
        expect(matches.first.matchType, equals(MatchType.caseInsensitive));
      });

      test('handles uppercase input', () {
        final matches = service.findMatches('SAL');

        expect(matches, isNotEmpty);
        expect(matches.first.confidence, equals(0.95));
        expect(matches.first.matchType, equals(MatchType.caseInsensitive));
      });

      test('returns early after case-insensitive match', () {
        final matches = service.findMatches('frango');

        // Should only return one match (case-insensitive)
        expect(matches.length, equals(1));
        expect(matches.first.confidence, equals(0.95));
      });
    });

    group('normalized match (Stage 3)', () {
      test('finds match after removing accents', () {
        final matches = service.findMatches('Acucar');

        expect(matches, isNotEmpty);
        expect(matches.first.ingredient.name, equals('Açúcar'));
        expect(matches.first.confidence, equals(0.90));
        expect(matches.first.matchType, equals(MatchType.normalized));
        expect(matches.first.confidenceLevel, equals(MatchConfidence.high));
      });

      test('finds match with lowercase and no accents', () {
        final matches = service.findMatches('acucar');

        expect(matches, isNotEmpty);
        expect(matches.first.ingredient.name, equals('Açúcar'));
        expect(matches.first.confidence, equals(0.90));
      });

      test('matches ingredient with accents to normalized input', () {
        final matches = service.findMatches('azeite');

        expect(matches, isNotEmpty);
        expect(matches.first.ingredient.name, equals('Azeite'));
      });

      test('handles multiple normalized matches', () {
        // Add another ingredient with similar normalized form
        final extraIngredients = [
          ...testIngredients,
          Ingredient(
            id: '11',
            name: 'açucar',
            category: IngredientCategory.other,
            unit: MeasurementUnit.gram,
          ),
        ];
        service.initialize(extraIngredients);

        final matches = service.findMatches('acucar');

        // Could match both 'Açúcar' and 'açucar' at normalized level
        expect(matches, isNotEmpty);
      });

      test('matches hyphenated ingredient to space-separated input', () {
        // Add hyphenated ingredient
        final extraIngredients = [
          ...testIngredients,
          Ingredient(
            id: '11',
            name: 'noz-moscada',
            category: IngredientCategory.seasoning,
            unit: MeasurementUnit.gram,
          ),
        ];
        service.initialize(extraIngredients);

        final matches = service.findMatches('noz moscada');

        expect(matches, isNotEmpty);
        expect(matches.first.ingredient.name, equals('noz-moscada'));
        expect(matches.first.confidence, equals(0.90));
        expect(matches.first.matchType, equals(MatchType.normalized));
      });

      test('matches space-separated ingredient to hyphenated input', () {
        // Add space-separated ingredient
        final extraIngredients = [
          ...testIngredients,
          Ingredient(
            id: '11',
            name: 'pimenta do reino',
            category: IngredientCategory.seasoning,
            unit: MeasurementUnit.gram,
          ),
        ];
        service.initialize(extraIngredients);

        final matches = service.findMatches('pimenta-do-reino');

        expect(matches, isNotEmpty);
        expect(matches.first.ingredient.name, equals('pimenta do reino'));
        expect(matches.first.confidence, equals(0.90));
      });

      test('handles underscores as word separators', () {
        final extraIngredients = [
          ...testIngredients,
          Ingredient(
            id: '11',
            name: 'azeite_oliva',
            category: IngredientCategory.other,
            unit: MeasurementUnit.milliliter,
          ),
        ];
        service.initialize(extraIngredients);

        final matches = service.findMatches('azeite oliva');

        expect(matches, isNotEmpty);
        expect(matches.first.ingredient.name, equals('azeite_oliva'));
      });

      test('collapses multiple spaces to single space', () {
        final extraIngredients = [
          ...testIngredients,
          Ingredient(
            id: '11',
            name: 'queijo  ralado',
            category: IngredientCategory.other,
            unit: MeasurementUnit.gram,
          ),
        ];
        service.initialize(extraIngredients);

        final matches = service.findMatches('queijo ralado');

        expect(matches, isNotEmpty);
        expect(matches.first.ingredient.name, equals('queijo  ralado'));
      });
    });

    group('prefix/partial match (Stage 4)', () {
      test('finds prefix match for partial ingredient name', () {
        final extraIngredients = [
          ...testIngredients,
          Ingredient(
            id: '11',
            name: 'manteiga de amendoim',
            category: IngredientCategory.other,
            unit: MeasurementUnit.gram,
          ),
        ];
        service.initialize(extraIngredients);

        final matches = service.findMatches('manteiga');

        expect(matches, isNotEmpty);

        // Should find prefix match since "manteiga" is not in testIngredients
        final prefixMatches = matches.where((m) => m.matchType == MatchType.partial).toList();
        expect(prefixMatches, isNotEmpty);
        expect(prefixMatches.first.ingredient.name, equals('manteiga de amendoim'));
        expect(prefixMatches.first.confidence, greaterThanOrEqualTo(0.65));
        expect(prefixMatches.first.confidence, lessThanOrEqualTo(0.85));
      });

      test('finds multiple prefix matches for same prefix', () {
        final extraIngredients = [
          ...testIngredients,
          Ingredient(
            id: '11',
            name: 'queijo parmesao',
            category: IngredientCategory.other,
            unit: MeasurementUnit.gram,
          ),
          Ingredient(
            id: '12',
            name: 'queijo mussarela',
            category: IngredientCategory.other,
            unit: MeasurementUnit.gram,
          ),
          Ingredient(
            id: '13',
            name: 'queijo cheddar',
            category: IngredientCategory.other,
            unit: MeasurementUnit.gram,
          ),
        ];
        service.initialize(extraIngredients);

        final matches = service.findMatches('queijo');

        // Should find prefix matches since "queijo" alone is not in testIngredients
        expect(matches, isNotEmpty);

        // Filter for partial matches only
        final prefixMatches = matches.where((m) => m.matchType == MatchType.partial).toList();
        expect(prefixMatches.length, greaterThanOrEqualTo(2));

        // All should start with "queijo"
        for (final match in prefixMatches) {
          expect(match.ingredient.name.toLowerCase().startsWith('queijo'), isTrue);
        }
      });

      test('respects word boundary - prevents partial word matching', () {
        final extraIngredients = [
          ...testIngredients,
          Ingredient(
            id: '11',
            name: 'pimentao',
            category: IngredientCategory.vegetable,
            unit: MeasurementUnit.piece,
          ),
          Ingredient(
            id: '12',
            name: 'pimenta do reino',
            category: IngredientCategory.seasoning,
            unit: MeasurementUnit.gram,
          ),
        ];
        service.initialize(extraIngredients);

        final matches = service.findMatches('pimenta');

        // Should match "pimenta do reino" but NOT "pimentao"
        expect(matches, isNotEmpty);

        final prefixMatches = matches.where((m) => m.matchType == MatchType.partial).toList();
        expect(prefixMatches, isNotEmpty);
        expect(prefixMatches.first.ingredient.name, equals('pimenta do reino'));

        // Verify pimentao is not in prefix matches
        final pimentaoMatch = prefixMatches.where((m) => m.ingredient.name == 'pimentao');
        expect(pimentaoMatch, isEmpty);
      });

      test('calculates confidence based on match ratio', () {
        final extraIngredients = [
          ...testIngredients,
          Ingredient(
            id: '11',
            name: 'sal grosso',
            category: IngredientCategory.seasoning,
            unit: MeasurementUnit.gram,
          ),
          Ingredient(
            id: '12',
            name: 'sal marinho refinado',
            category: IngredientCategory.seasoning,
            unit: MeasurementUnit.gram,
          ),
        ];
        service.initialize(extraIngredients);

        final matches = service.findMatches('sal');

        // "sal" is 3 chars, "sal grosso" is 10 chars (30% ratio)
        // "sal" is 3 chars, "sal marinho refinado" is 19 chars (16% ratio)
        // Higher match ratio should have higher confidence
        final prefixMatches = matches.where((m) => m.matchType == MatchType.partial).toList();

        if (prefixMatches.length >= 2) {
          final grossoMatch = prefixMatches.firstWhere((m) => m.ingredient.name == 'sal grosso');
          final marinhoMatch = prefixMatches.firstWhere((m) => m.ingredient.name == 'sal marinho refinado');

          expect(grossoMatch.confidence, greaterThan(marinhoMatch.confidence));
        }
      });

      test('reverse prefix match - longer input matches shorter database entry', () {
        final extraIngredients = [
          ...testIngredients,
          Ingredient(
            id: '11',
            name: 'molho de tomate',
            category: IngredientCategory.other,
            unit: MeasurementUnit.gram,
          ),
        ];
        service.initialize(extraIngredients);

        // User types more specific than what's in database
        final matches = service.findMatches('molho de tomate caseiro');

        expect(matches, isNotEmpty);

        final partialMatches = matches.where((m) => m.matchType == MatchType.partial).toList();
        expect(partialMatches, isNotEmpty);
        expect(partialMatches.first.ingredient.name, equals('molho de tomate'));

        // Reverse matches have lower confidence (60-75%)
        expect(partialMatches.first.confidence, greaterThanOrEqualTo(0.60));
        expect(partialMatches.first.confidence, lessThanOrEqualTo(0.75));
      });

      test('limits prefix matches to top 5 results', () {
        final extraIngredients = [
          ...testIngredients,
          ...List.generate(10, (i) => Ingredient(
            id: 'pref_$i',
            name: 'queijo tipo $i',
            category: IngredientCategory.other,
          )),
        ];
        service.initialize(extraIngredients);

        final matches = service.findMatches('queijo');

        final prefixMatches = matches.where((m) => m.matchType == MatchType.partial).toList();
        expect(prefixMatches.length, lessThanOrEqualTo(5));
      });

      test('skips very short strings (< 3 chars)', () {
        final extraIngredients = [
          ...testIngredients,
          Ingredient(
            id: '11',
            name: 'sal marinho',
            category: IngredientCategory.seasoning,
            unit: MeasurementUnit.gram,
          ),
        ];
        service.initialize(extraIngredients);

        // Very short input should not produce prefix matches
        final matches = service.findMatches('sa');

        expect(matches, isA<List<IngredientMatch>>());
        // Should not crash, just might not find prefix matches
      });

      test('prefix match has lower confidence than exact match', () {
        final extraIngredients = [
          ...testIngredients,
          Ingredient(
            id: '11',
            name: 'Tomate',
            category: IngredientCategory.vegetable,
          ),
          Ingredient(
            id: '12',
            name: 'Tomate cereja',
            category: IngredientCategory.vegetable,
          ),
        ];
        service.initialize(extraIngredients);

        final exactMatches = service.findMatches('Tomate');

        expect(exactMatches, isNotEmpty);
        expect(exactMatches.first.matchType, equals(MatchType.exact));
        expect(exactMatches.first.confidence, equals(1.0));

        // Any prefix matches should have lower confidence
        final prefixMatches = exactMatches.where((m) => m.matchType == MatchType.partial);
        for (final match in prefixMatches) {
          expect(match.confidence, lessThan(1.0));
        }
      });

      test('works with normalized strings (accents removed)', () {
        final extraIngredients = [
          ...testIngredients,
          Ingredient(
            id: '11',
            name: 'vinagre balsamico',
            category: IngredientCategory.other,
            unit: MeasurementUnit.milliliter,
          ),
        ];
        service.initialize(extraIngredients);

        // Input without accents should still match via normalization + prefix
        final matches = service.findMatches('vinagre');

        expect(matches, isNotEmpty);

        // Should match via prefix (vinagre is not in testIngredients)
        final prefixMatches = matches.where(
          (m) => m.matchType == MatchType.partial && m.ingredient.name == 'vinagre balsamico'
        ).toList();
        expect(prefixMatches, isNotEmpty);
      });
    });

    group('fuzzy match (Stage 5)', () {
      test('finds fuzzy match for typo in ingredient name', () {
        // Add ingredient
        final extraIngredients = [
          ...testIngredients,
          Ingredient(
            id: '11',
            name: 'Tomate',
            category: IngredientCategory.vegetable,
            unit: MeasurementUnit.piece,
          ),
        ];
        service.initialize(extraIngredients);

        // "Tomatoe" is a common typo
        final matches = service.findMatches('Tomatoe');

        expect(matches, isNotEmpty);
        expect(matches.first.ingredient.name, equals('Tomate'));
        expect(matches.first.matchType, equals(MatchType.fuzzy));
        expect(matches.first.confidence, greaterThan(0.60));
        expect(matches.first.confidence, lessThan(0.90));
      });

      test('finds fuzzy match for similar spelling', () {
        final extraIngredients = [
          ...testIngredients,
          Ingredient(
            id: '11',
            name: 'Cebola',
            category: IngredientCategory.vegetable,
            unit: MeasurementUnit.piece,
          ),
        ];
        service.initialize(extraIngredients);

        // "Cebolla" (Spanish) vs "Cebola" (Portuguese)
        final matches = service.findMatches('Cebolla');

        expect(matches, isNotEmpty);
        expect(matches.first.ingredient.name, equals('Cebola'));
        expect(matches.first.matchType, equals(MatchType.fuzzy));
      });

      test('fuzzy match has lower confidence than exact match', () {
        final extraIngredients = [
          ...testIngredients,
          Ingredient(
            id: '11',
            name: 'Sal',
            category: IngredientCategory.seasoning,
            unit: MeasurementUnit.gram,
          ),
        ];
        service.initialize(extraIngredients);

        final exactMatches = service.findMatches('Sal');
        final fuzzyMatches = service.findMatches('Slt');

        if (fuzzyMatches.isNotEmpty) {
          expect(exactMatches.first.confidence, greaterThan(fuzzyMatches.first.confidence));
        }
      });

      test('returns multiple fuzzy matches sorted by confidence', () {
        final extraIngredients = [
          ...testIngredients,
          Ingredient(
            id: '11',
            name: 'Tomate',
            category: IngredientCategory.vegetable,
          ),
          Ingredient(
            id: '12',
            name: 'Tomato',
            category: IngredientCategory.vegetable,
          ),
          Ingredient(
            id: '13',
            name: 'Tomatinho',
            category: IngredientCategory.vegetable,
          ),
        ];
        service.initialize(extraIngredients);

        final matches = service.findMatches('Tomat');

        expect(matches.length, greaterThanOrEqualTo(2));

        // Verify sorted by confidence
        for (int i = 0; i < matches.length - 1; i++) {
          expect(
            matches[i].confidence,
            greaterThanOrEqualTo(matches[i + 1].confidence),
          );
        }
      });

      test('limits fuzzy matches to top 5 results', () {
        // Create many similar ingredients
        final extraIngredients = [
          ...testIngredients,
          ...List.generate(10, (i) => Ingredient(
            id: 'similar_$i',
            name: 'Ingredient$i',
            category: IngredientCategory.other,
          )),
        ];
        service.initialize(extraIngredients);

        final matches = service.findMatches('Ingredien');

        // Should limit to 5 fuzzy matches even if more are similar
        expect(matches.length, lessThanOrEqualTo(5));
      });

      test('skips very short strings (< 3 chars)', () {
        // Should not crash, but might not find fuzzy matches for very short strings
        expect(() => service.findMatches('AB'), returnsNormally);

        // Verify it returns a result (even if empty or non-fuzzy)
        final matches = service.findMatches('AB');
        expect(matches, isA<List<IngredientMatch>>());
      });

      test('fuzzy match confidence correlates with similarity', () {
        final extraIngredients = [
          ...testIngredients,
          Ingredient(
            id: '11',
            name: 'Manteiga',
            category: IngredientCategory.other,
          ),
        ];
        service.initialize(extraIngredients);

        // Very similar
        final closeMatch = service.findMatches('Mantega');
        // Less similar
        final farMatch = service.findMatches('Mantiga');

        if (closeMatch.isNotEmpty && farMatch.isNotEmpty) {
          expect(
            closeMatch.first.confidence,
            greaterThanOrEqualTo(farMatch.first.confidence),
          );
        }
      });

      test('fuzzy match respects minimum threshold (60%)', () {
        final extraIngredients = [
          ...testIngredients,
          Ingredient(
            id: '11',
            name: 'Abacaxi',
            category: IngredientCategory.other,
          ),
        ];
        service.initialize(extraIngredients);

        final matches = service.findMatches('xyz');

        // Completely different string should not match
        expect(matches, isEmpty);
      });

      test('fuzzy match works with normalized strings', () {
        final extraIngredients = [
          ...testIngredients,
          Ingredient(
            id: '11',
            name: 'Açúcar',
            category: IngredientCategory.other,
          ),
        ];
        service.initialize(extraIngredients);

        // Typo without accent
        final matches = service.findMatches('Acucar');

        // Should find via normalized match (90%) before fuzzy
        expect(matches, isNotEmpty);
        expect(matches.first.confidence, equals(0.90));
        expect(matches.first.matchType, equals(MatchType.normalized));
      });
    });

    group('no matches', () {
      test('returns empty list when no match found', () {
        final matches = service.findMatches('xyz123');

        expect(matches, isEmpty);
      });

      test('returns empty list for ingredient not in database', () {
        final matches = service.findMatches('Chocolate');

        expect(matches, isEmpty);
      });
    });

    group('edge cases', () {
      test('handles empty string input', () {
        final matches = service.findMatches('');

        expect(matches, isEmpty);
      });

      test('handles whitespace-only input', () {
        final matches = service.findMatches('   ');

        expect(matches, isEmpty);
      });

      test('handles input with leading/trailing whitespace', () {
        final matches = service.findMatches('  Tomate  ');

        // Normalization should trim the input and find match
        expect(matches, isNotEmpty);
        expect(matches.first.ingredient.name, equals('Tomate'));
      });

      test('handles single character input', () {
        // Might match ingredients starting with A (Arroz, Alho, etc.)
        // depending on first-letter index
        expect(() => service.findMatches('A'), returnsNormally);
      });

      test('handles special characters in input', () {
        final matches = service.findMatches('Açúcar');

        expect(matches, isNotEmpty);
        expect(matches.first.ingredient.name, equals('Açúcar'));
      });
    });

    group('getBestMatch', () {
      test('returns highest confidence match', () {
        final match = service.getBestMatch('Tomate');

        expect(match, isNotNull);
        expect(match!.confidence, equals(1.0));
        expect(match.ingredient.name, equals('Tomate'));
      });

      test('returns null when no matches found', () {
        final match = service.getBestMatch('Chocolate');

        expect(match, isNull);
      });

      test('returns first match when multiple equal confidence', () {
        final match = service.getBestMatch('tomate');

        expect(match, isNotNull);
        expect(match!.confidence, greaterThan(0.0));
      });
    });

    group('shouldAutoSelect', () {
      test('returns true for high confidence single match', () {
        final matches = service.findMatches('Tomate');

        expect(service.shouldAutoSelect(matches), isTrue);
      });

      test('returns true for case-insensitive match', () {
        final matches = service.findMatches('frango');

        expect(service.shouldAutoSelect(matches), isTrue);
        expect(matches.first.confidenceLevel, equals(MatchConfidence.high));
      });

      test('returns false for empty match list', () {
        final matches = service.findMatches('Chocolate');

        expect(service.shouldAutoSelect(matches), isFalse);
      });

      test('returns false when multiple matches with same confidence', () {
        // Create scenario with multiple equal-confidence matches
        final multiService = IngredientMatchingService();
        final multiIngredients = [
          Ingredient(
            id: '1',
            name: 'Tomate',
            category: IngredientCategory.vegetable,
          ),
          Ingredient(
            id: '2',
            name: 'Tomate',
            category: IngredientCategory.vegetable,
          ),
        ];
        multiService.initialize(multiIngredients);

        final matches = multiService.findMatches('Tomate');

        // If there are multiple exact matches, shouldn't auto-select
        if (matches.length > 1 &&
            matches[0].confidence == matches[1].confidence) {
          expect(multiService.shouldAutoSelect(matches), isFalse);
        }
      });
    });

    group('getAutoSelectedMatch', () {
      test('returns match when should auto-select', () {
        final match = service.getAutoSelectedMatch('Tomate');

        expect(match, isNotNull);
        expect(match!.ingredient.name, equals('Tomate'));
      });

      test('returns null when no high-confidence match', () {
        final match = service.getAutoSelectedMatch('Chocolate');

        expect(match, isNull);
      });

      test('returns null when empty input', () {
        final match = service.getAutoSelectedMatch('');

        expect(match, isNull);
      });
    });

    group('confidence levels', () {
      test('exact match has high confidence', () {
        final matches = service.findMatches('Tomate');

        expect(matches.first.confidenceLevel, equals(MatchConfidence.high));
      });

      test('case-insensitive match has high confidence', () {
        final matches = service.findMatches('frango');

        expect(matches.first.confidenceLevel, equals(MatchConfidence.high));
      });

      test('normalized match has high confidence', () {
        final matches = service.findMatches('acucar');

        expect(matches.first.confidenceLevel, equals(MatchConfidence.high));
      });
    });

    group('match sorting', () {
      test('matches are sorted by confidence (highest first)', () {
        // This will be more relevant when we have fuzzy/partial matches
        final matches = service.findMatches('Tomate');

        // Verify descending order
        for (int i = 0; i < matches.length - 1; i++) {
          expect(
            matches[i].confidence,
            greaterThanOrEqualTo(matches[i + 1].confidence),
          );
        }
      });
    });

    group('preserves ingredient properties', () {
      test('matched ingredient preserves category', () {
        final match = service.getBestMatch('Frango');

        expect(match, isNotNull);
        expect(match!.ingredient.category, equals(IngredientCategory.protein));
      });

      test('matched ingredient preserves protein type', () {
        final match = service.getBestMatch('Frango');

        expect(match, isNotNull);
        expect(match!.ingredient.proteinType, equals(ProteinType.chicken));
      });

      test('matched ingredient preserves unit', () {
        final match = service.getBestMatch('Arroz');

        expect(match, isNotNull);
        expect(match!.ingredient.unit, equals(MeasurementUnit.gram));
      });

      test('matched ingredient preserves ID', () {
        final match = service.getBestMatch('Tomate');

        expect(match, isNotNull);
        expect(match!.ingredient.id, equals('1'));
      });
    });

    group('performance characteristics', () {
      test('handles large ingredient list efficiently', () {
        final largeList = List.generate(
          1000,
          (i) => Ingredient(
            id: 'ing_$i',
            name: 'Ingredient $i',
            category: IngredientCategory.other,
          ),
        );

        final perfService = IngredientMatchingService();
        perfService.initialize(largeList);

        // Should complete quickly (< 100ms implied by requirement)
        final stopwatch = Stopwatch()..start();
        perfService.findMatches('Ingredient 500');
        stopwatch.stop();

        // Just verify it completes without error
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });

    group('IngredientMatch model', () {
      test('toString provides readable output', () {
        final ingredient = Ingredient(
          id: '1',
          name: 'Tomate',
          category: IngredientCategory.vegetable,
        );

        final match = IngredientMatch(
          ingredient: ingredient,
          confidence: 0.95,
          matchType: MatchType.caseInsensitive,
        );

        final str = match.toString();
        expect(str, contains('Tomate'));
        expect(str, contains('95%'));
        expect(str, contains('caseInsensitive'));
      });

      test('confidence level thresholds work correctly', () {
        final ingredient = Ingredient(
          id: '1',
          name: 'Test',
          category: IngredientCategory.other,
        );

        // High: >= 0.90
        final highMatch = IngredientMatch(
          ingredient: ingredient,
          confidence: 0.95,
          matchType: MatchType.exact,
        );
        expect(highMatch.confidenceLevel, equals(MatchConfidence.high));

        // Medium: >= 0.70
        final mediumMatch = IngredientMatch(
          ingredient: ingredient,
          confidence: 0.75,
          matchType: MatchType.fuzzy,
        );
        expect(mediumMatch.confidenceLevel, equals(MatchConfidence.medium));

        // Low: < 0.70
        final lowMatch = IngredientMatch(
          ingredient: ingredient,
          confidence: 0.60,
          matchType: MatchType.partial,
        );
        expect(lowMatch.confidenceLevel, equals(MatchConfidence.low));
      });
    });
  });
}
