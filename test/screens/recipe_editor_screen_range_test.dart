import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gastrobrain/screens/recipe_details_ingredients_tab.dart';
import 'package:gastrobrain/l10n/app_localizations.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en', '')],
    home: Scaffold(body: child),
  );
}

Map<String, dynamic> _makeIngredient({
  String name = 'Garlic',
  double quantity = 2.0,
  double? quantityMax,
  String unit = 'clove',
}) {
  return {
    'name': name,
    'quantity': quantity,
    'quantity_max': quantityMax,
    'unit': unit,
    'unit_override': null,
    'protein_type': null,
    'preparation_notes': null,
    'recipe_ingredient_id': 'ri-1',
  };
}

void main() {
  // ─── RecipeDetailsIngredientsTab — range display ───────────────────────── //

  group('RecipeDetailsIngredientsTab — range quantities display', () {
    testWidgets('displays range ingredient as "2–3" quantity', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          RecipeDetailsIngredientsTab(
            ingredients: [_makeIngredient(quantity: 2.0, quantityMax: 3.0)],
            servings: 1,
            isLoading: false,
            error: null,
            onDeleteIngredient: (_) {},
            onEditIngredient: (_) {},
            onRetry: () {},
            onAdd: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show en-dash range, not a hyphen
      expect(find.textContaining('2–3'), findsOneWidget);
    });

    testWidgets('displays fraction range ingredient as "½–1"', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          RecipeDetailsIngredientsTab(
            ingredients: [_makeIngredient(quantity: 0.5, quantityMax: 1.0)],
            servings: 1,
            isLoading: false,
            error: null,
            onDeleteIngredient: (_) {},
            onEditIngredient: (_) {},
            onRetry: () {},
            onAdd: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('½–1'), findsOneWidget);
    });

    testWidgets('single-value ingredient displays unchanged', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          RecipeDetailsIngredientsTab(
            ingredients: [_makeIngredient(quantity: 2.0, quantityMax: null)],
            servings: 1,
            isLoading: false,
            error: null,
            onDeleteIngredient: (_) {},
            onEditIngredient: (_) {},
            onRetry: () {},
            onAdd: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Plain "2", no dash
      expect(find.textContaining('2'), findsWidgets);
      expect(find.textContaining('–'), findsNothing);
    });

    testWidgets('mixed-number range displays as "1½–2"', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          RecipeDetailsIngredientsTab(
            ingredients: [_makeIngredient(quantity: 1.5, quantityMax: 2.0)],
            servings: 1,
            isLoading: false,
            error: null,
            onDeleteIngredient: (_) {},
            onEditIngredient: (_) {},
            onRetry: () {},
            onAdd: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('1½–2'), findsOneWidget);
    });
  });

  // ─── Qty field parse behavior (logic mirroring _buildIngredientRow.onChanged) ─ //
  //
  // RecipeEditorScreen has no constructor DI, so the onChanged logic is tested
  // here as a pure unit test using the same regex pattern to document expected
  // parse behavior. Widget-level interaction tests are deferred to a future
  // refactoring that adds DI to RecipeEditorScreen.

  group('qty field range parse logic', () {
    // Mirrors the onChanged regex in _buildIngredientRow.
    (double, double?) parseQtyInput(String text) {
      final trimmed = text.trim();
      final rangeMatch = RegExp(
        r'^(\d+(?:[.,]\d+)?)\s*[–-]\s*(\d+(?:[.,]\d+)?)$',
      ).firstMatch(trimmed);
      if (rangeMatch != null) {
        final min =
            double.tryParse(rangeMatch.group(1)!.replaceAll(',', '.')) ?? 0.0;
        final max =
            double.tryParse(rangeMatch.group(2)!.replaceAll(',', '.')) ?? 0.0;
        if (max > min) return (min, max);
        return (min, null); // inverted range: treated as single value
      }
      return (double.tryParse(trimmed.replaceAll(',', '.')) ?? 0.0, null);
    }

    String? validateQtyInput(String text) {
      final trimmed = text.trim();
      final rangeMatch = RegExp(
        r'^(\d+(?:[.,]\d+)?)\s*[–-]\s*(\d+(?:[.,]\d+)?)$',
      ).firstMatch(trimmed);
      if (rangeMatch != null) {
        final min =
            double.tryParse(rangeMatch.group(1)!.replaceAll(',', '.'));
        final max =
            double.tryParse(rangeMatch.group(2)!.replaceAll(',', '.'));
        if (min != null && max != null && min >= max) {
          return 'Min must be less than max';
        }
      }
      return null;
    }

    test('single integer parses to (2.0, null)', () {
      final (min, max) = parseQtyInput('2');
      expect(min, equals(2.0));
      expect(max, isNull);
    });

    test('single decimal parses to (1.5, null)', () {
      final (min, max) = parseQtyInput('1.5');
      expect(min, equals(1.5));
      expect(max, isNull);
    });

    test('comma decimal parses to (1.5, null)', () {
      final (min, max) = parseQtyInput('1,5');
      expect(min, equals(1.5));
      expect(max, isNull);
    });

    test('range with hyphen "2-3" parses to (2.0, 3.0)', () {
      final (min, max) = parseQtyInput('2-3');
      expect(min, equals(2.0));
      expect(max, equals(3.0));
    });

    test('range with en-dash "2–3" parses to (2.0, 3.0)', () {
      final (min, max) = parseQtyInput('2–3');
      expect(min, equals(2.0));
      expect(max, equals(3.0));
    });

    test('decimal range "1.5-2.5" parses correctly', () {
      final (min, max) = parseQtyInput('1.5-2.5');
      expect(min, equals(1.5));
      expect(max, equals(2.5));
    });

    test('inverted range "3-2" returns single value (3.0, null)', () {
      final (min, max) = parseQtyInput('3-2');
      expect(min, equals(3.0));
      expect(max, isNull);
    });

    test('equal range "2-2" returns single value (2.0, null)', () {
      final (min, max) = parseQtyInput('2-2');
      expect(min, equals(2.0));
      expect(max, isNull);
    });

    test('range with spaces "2 - 3" parses correctly', () {
      final (min, max) = parseQtyInput('2 - 3');
      expect(min, equals(2.0));
      expect(max, equals(3.0));
    });

    test('empty string parses to (0.0, null)', () {
      final (min, max) = parseQtyInput('');
      expect(min, equals(0.0));
      expect(max, isNull);
    });

    test('inverted range produces validation error', () {
      expect(validateQtyInput('3-2'), equals('Min must be less than max'));
    });

    test('equal range produces validation error', () {
      expect(validateQtyInput('2-2'), equals('Min must be less than max'));
    });

    test('valid range produces no validation error', () {
      expect(validateQtyInput('2-3'), isNull);
    });

    test('single value produces no validation error', () {
      expect(validateQtyInput('2'), isNull);
    });
  });
}
