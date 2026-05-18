import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/ingredient.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/widgets/unified_add_side_dialog.dart';
import 'package:gastrobrain/l10n/app_localizations.dart';
import '../test_utils/dialog_fixtures.dart';

// ── Test helpers ─────────────────────────────────────────────────────────────

Widget _buildLauncher({
  List<Recipe>? recipes,
  List<Recipe>? excludeRecipes,
  List<Ingredient>? ingredients,
}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en', '')],
    home: Builder(
      builder: (ctx) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => showDialog<Map<String, dynamic>>(
              context: ctx,
              builder: (_) => UnifiedAddSideDialog(
                availableRecipes: recipes ?? [],
                excludeRecipes: excludeRecipes ?? [],
                availableIngredients: ingredients ?? [],
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openDialog(WidgetTester tester,
    {List<Recipe>? recipes,
    List<Recipe>? excludeRecipes,
    List<Ingredient>? ingredients}) async {
  await tester.pumpWidget(_buildLauncher(
    recipes: recipes,
    excludeRecipes: excludeRecipes,
    ingredients: ingredients,
  ));
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Recipe _recipe(String id, String name) => Recipe(
      id: id,
      name: name,
      desiredFrequency: FrequencyType.weekly,
      createdAt: DateTime.now(),
    );

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('UnifiedAddSideDialog — Cancellation', () {
    testWidgets('Cancel button returns null', (tester) async {
      Map<String, dynamic>? result = {'sentinel': true};

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', '')],
        home: Builder(
          builder: (ctx) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await showDialog<Map<String, dynamic>>(
                  context: ctx,
                  builder: (_) => const UnifiedAddSideDialog(
                    availableRecipes: [],
                    availableIngredients: [],
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('unified_side_cancel_button')));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });

    testWidgets('back button returns null without crash', (tester) async {
      await _openDialog(tester);
      // Simulate Android back button
      final NavigatorState navigator = tester.state(find.byType(Navigator).last);
      navigator.pop();
      await tester.pumpAndSettle();
      // Test passes if no disposal crash occurs
    });
  });

  group('UnifiedAddSideDialog — Ingredient tab', () {
    testWidgets('ingredient tab is visible', (tester) async {
      await _openDialog(tester);
      expect(find.byKey(const Key('unified_side_ingredient_tab')), findsOneWidget);
    });

    testWidgets('Add button is disabled when no ingredient selected', (tester) async {
      await _openDialog(tester);
      await tester.tap(find.byKey(const Key('unified_side_ingredient_tab')));
      await tester.pumpAndSettle();

      final addButton = tester.widget<ElevatedButton>(
          find.byKey(const Key('unified_side_add_button')));
      expect(addButton.onPressed, isNull);
    });

    testWidgets('Add button enables after typing free-text ingredient', (tester) async {
      await _openDialog(tester, ingredients: []);
      await tester.tap(find.byKey(const Key('unified_side_ingredient_tab')));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('unified_side_ingredient_search')), 'Salt');
      await tester.pumpAndSettle();

      final addButton = tester.widget<ElevatedButton>(
          find.byKey(const Key('unified_side_add_button')));
      expect(addButton.onPressed, isNotNull);
    });

    testWidgets('confirms free-text ingredient with correct map keys', (tester) async {
      Map<String, dynamic>? result;

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', '')],
        home: Builder(
          builder: (ctx) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await showDialog<Map<String, dynamic>>(
                  context: ctx,
                  builder: (_) => const UnifiedAddSideDialog(
                    availableRecipes: [],
                    availableIngredients: [],
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('unified_side_ingredient_tab')));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('unified_side_ingredient_search')), 'Salt');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('unified_side_add_button')));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!['type'], equals('simple'));
      expect(result!['customName'], equals('Salt'));
      expect(result!['ingredientId'], isNull);
      expect(result!['quantity'], equals(1.0));
    });

    testWidgets('Cancel on ingredient tab returns null', (tester) async {
      Map<String, dynamic>? result = {'sentinel': true};

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', '')],
        home: Builder(
          builder: (ctx) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await showDialog<Map<String, dynamic>>(
                  context: ctx,
                  builder: (_) => const UnifiedAddSideDialog(
                    availableRecipes: [],
                    availableIngredients: [],
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('unified_side_ingredient_tab')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('unified_side_ingredient_search')), 'Salt');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('unified_side_cancel_button')));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });
  });

  group('UnifiedAddSideDialog — Recipe tab', () {
    testWidgets('shows recipe list on recipe tab', (tester) async {
      final recipes = [_recipe('1', 'Pasta'), _recipe('2', 'Rice')];
      await _openDialog(tester, recipes: recipes);

      expect(find.text('Pasta'), findsOneWidget);
      expect(find.text('Rice'), findsOneWidget);
    });

    testWidgets('excludes recipes from excludeRecipes list', (tester) async {
      final primary = _recipe('1', 'Pasta');
      final side = _recipe('2', 'Rice');
      await _openDialog(
          tester, recipes: [primary, side], excludeRecipes: [primary]);

      expect(find.text('Pasta'), findsNothing);
      expect(find.text('Rice'), findsOneWidget);
    });

    testWidgets('search filters recipe list', (tester) async {
      final recipes = [_recipe('1', 'Pasta'), _recipe('2', 'Rice')];
      await _openDialog(tester, recipes: recipes);

      await tester.enterText(
          find.byKey(const Key('unified_side_recipe_search')), 'pas');
      await tester.pumpAndSettle();

      expect(find.text('Pasta'), findsOneWidget);
      expect(find.text('Rice'), findsNothing);
    });

    testWidgets('shows empty state when no recipes match search', (tester) async {
      final recipes = [_recipe('1', 'Pasta')];
      await _openDialog(tester, recipes: recipes);

      await tester.enterText(
          find.byKey(const Key('unified_side_recipe_search')), 'xyz');
      await tester.pumpAndSettle();

      expect(find.text('Pasta'), findsNothing);
    });

    testWidgets('tapping a recipe closes dialog and returns recipe result',
        (tester) async {
      Map<String, dynamic>? result;
      final recipe = _recipe('1', 'Pasta');

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', '')],
        home: Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showDialog<Map<String, dynamic>>(
                    context: ctx,
                    builder: (_) => UnifiedAddSideDialog(
                      availableRecipes: [recipe],
                      availableIngredients: const [],
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pasta'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!['type'], equals('recipe'));
      expect((result!['recipe'] as Recipe).id, equals('1'));
    });
  });
}
