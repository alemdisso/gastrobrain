// test/edge_cases/interaction_patterns/recipe_form_flow_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/screens/recipe_form_screen.dart';
import 'package:gastrobrain/l10n/app_localizations.dart';
import '../../mocks/mock_database_helper.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [
      Locale('en', ''),
      Locale('pt', ''),
    ],
    home: child,
  );
}

Recipe _makeRecipe({
  String id = 'recipe-1',
  String name = 'Test Recipe',
  int servings = 4,
}) {
  return Recipe(
    id: id,
    name: name,
    desiredFrequency: FrequencyType.weekly,
    createdAt: DateTime(2024, 1, 1),
    servings: servings,
    difficulty: 2,
    rating: 3,
    notes: '',
    story: '',
    prepTimeMinutes: 15,
    cookTimeMinutes: 30,
  );
}

void main() {
  group('RecipeFormScreen — interaction patterns', () {
    late MockDatabaseHelper mockDb;

    setUp(() {
      mockDb = MockDatabaseHelper();
    });

    tearDown(() {
      mockDb.resetAllData();
    });

    testWidgets('back button before Phase 1 save does not persist anything',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          Navigator(
            onGenerateRoute: (_) => MaterialPageRoute(
              builder: (_) => Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            RecipeFormScreen(databaseHelper: mockDb),
                      ),
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('recipe_form_name_field')), 'Draft');
      await tester.pump();

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(mockDb.recipes, isEmpty,
          reason: 'No recipe should be saved when back is pressed before save');
    });

    testWidgets('back button after Phase 1 save does not delete the stub',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          Navigator(
            onGenerateRoute: (_) => MaterialPageRoute(
              builder: (_) => Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            RecipeFormScreen(databaseHelper: mockDb),
                      ),
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Save Phase 1
      await tester.enterText(
          find.byKey(const Key('recipe_form_name_field')), 'Saved Recipe');
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(mockDb.recipes.length, equals(1));

      // Navigate back without finishing
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Recipe stub persists — it was already saved to DB
      expect(mockDb.recipes.length, equals(1),
          reason: 'Recipe stub should remain after back navigation');
      expect(mockDb.recipes.values.first.name, equals('Saved Recipe'));
    });

    testWidgets('servings value preserved across Phase 1 collapse/re-expand',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(RecipeFormScreen(databaseHelper: mockDb)),
      );
      await tester.pumpAndSettle();

      // Tap the + stepper to increment servings from default (4) to 5
      final incrementButtons = find.byIcon(Icons.add);
      await tester.tap(incrementButtons.first);
      await tester.pump();

      // Enter name and save Phase 1 (collapses form to summary card)
      await tester.enterText(
          find.byKey(const Key('recipe_form_name_field')), 'Soup');
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Re-expand Phase 1 via edit icon (scoped to summary ListTile to avoid
      // ambiguity with the story-field segmented button)
      await tester.tap(find.descendant(
        of: find.byType(ListTile),
        matching: find.byIcon(Icons.edit_outlined),
      ));
      await tester.pumpAndSettle();

      // Servings stepper should be visible again
      expect(find.byKey(const Key('recipe_form_servings_stepper')),
          findsOneWidget);

      // The saved recipe should have servings = 5
      expect(mockDb.recipes.values.first.servings, equals(5),
          reason: 'Servings should be preserved after collapse/re-expand cycle');
    });

    testWidgets(
        'edit mode with recipe that has no ingredients shows empty parser state',
        (tester) async {
      final recipe = _makeRecipe();
      await mockDb.insertRecipe(recipe);
      // No ingredients added for this recipe

      await tester.pumpWidget(
        _buildTestApp(
            RecipeFormScreen(recipe: recipe, databaseHelper: mockDb)),
      );
      await tester.pumpAndSettle();

      // Parser section is visible; parse button is the entry point
      expect(find.byKey(const Key('ingredient_parser_parse_button')),
          findsOneWidget,
          reason: 'Parse button should be available with no existing ingredients');

      // No confirm button present (nothing parsed yet)
      expect(find.byKey(const Key('ingredient_parser_confirm_button')),
          findsNothing,
          reason: 'Confirm button should not show before any parsing');
    });

    testWidgets('create mode with very long recipe name fits in summary card',
        (tester) async {
      const longName =
          'Braised Short Rib with Red Wine Reduction and Rosemary Polenta';

      await tester.pumpWidget(
        _buildTestApp(RecipeFormScreen(databaseHelper: mockDb)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('recipe_form_name_field')), longName);
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Screen should render without overflow exceptions
      expect(tester.takeException(), isNull,
          reason: 'Long recipe name should not cause rendering overflow');

      // Summary card should be visible
      expect(find.byType(ListTile), findsOneWidget);
    });
  });
}
