// test/widgets/recipe_selection_dialog_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/recipe_recommendation.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/core/providers/debug_settings_provider.dart';
import 'package:gastrobrain/widgets/recipe_selection_dialog.dart';
import 'package:gastrobrain/l10n/app_localizations.dart';

RecipeRecommendation _makeRec(String id, String name, double score) {
  return RecipeRecommendation(
    recipe: Recipe(
      id: id,
      name: name,
      desiredFrequency: FrequencyType.weekly,
      createdAt: DateTime.now(),
    ),
    totalScore: score,
    factorScores: const {},
  );
}

Widget _wrapDialog(Widget dialog) {
  return ChangeNotifierProvider(
    create: (_) => DebugSettingsProvider(),
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      home: Scaffold(body: Builder(builder: (ctx) => dialog)),
    ),
  );
}

/// Opens the dialog as a proper modal route via showDialog so Navigator.pop works.
Widget _buildDialogLauncher(Widget Function(BuildContext) dialogBuilder) {
  return ChangeNotifierProvider(
    create: (_) => DebugSettingsProvider(),
    child: MaterialApp(
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
              onPressed: () =>
                  showDialog<void>(context: ctx, builder: dialogBuilder),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group("RecipeSelectionDialog — 'Voltar' navigation (#366)", () {
    testWidgets('edit mode: Voltar dismisses the dialog', (tester) async {
      final primaryRecipe = Recipe(
        id: 'r_edit',
        name: 'Frango Assado',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(_buildDialogLauncher(
        (_) => RecipeSelectionDialog(
          recipes: const [],
          detailedRecommendations: const [],
          initialPrimaryRecipe: primaryRecipe,
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Confirm we're in menu mode
      expect(find.byKey(const Key('recipe_selection_save_button')), findsOneWidget);

      // Tap Voltar
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Dialog dismissed — Save button gone
      expect(find.byKey(const Key('recipe_selection_save_button')), findsNothing);
    });

    testWidgets('add mode: Voltar returns to recipe selection, not dismissing',
        (tester) async {
      final rec = _makeRec('r1', 'Pasta', 90);

      await tester.pumpWidget(_wrapDialog(
        RecipeSelectionDialog(
          recipes: [rec.recipe],
          detailedRecommendations: [rec],
          allScoredRecipes: [rec],
        ),
      ));
      await tester.pumpAndSettle();

      // Start in selection mode — Save button not visible
      expect(find.byKey(const Key('recipe_selection_save_button')), findsNothing);

      // Select the recipe to enter menu mode
      await tester.tap(find.text('SELECT'));
      await tester.pumpAndSettle();

      // Now in menu mode
      expect(find.byKey(const Key('recipe_selection_save_button')), findsOneWidget);

      // Tap Voltar
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Back in selection mode — Save button gone, recipe list visible
      expect(find.byKey(const Key('recipe_selection_save_button')), findsNothing);
      expect(find.text('Pasta'), findsOneWidget);
    });
  });

  group('RecipeSelectionDialog — replacement on dismissal', () {
    late RecipeRecommendation rec1;
    late RecipeRecommendation rec2;
    late RecipeRecommendation rec3;

    setUp(() {
      rec1 = _makeRec('r1', 'Pasta', 90);
      rec2 = _makeRec('r2', 'Chicken', 80);
      rec3 = _makeRec('r3', 'Salad', 70); // extra in pool, not initially shown
    });

    testWidgets('replacement recipe is appended after dismissal',
        (tester) async {
      await tester.pumpWidget(_wrapDialog(
        RecipeSelectionDialog(
          recipes: [rec1.recipe, rec2.recipe, rec3.recipe],
          detailedRecommendations: [rec1, rec2],
          allScoredRecipes: [rec1, rec2, rec3], // rec3 is the reserve
        ),
      ));
      await tester.pumpAndSettle();

      // Both initial recommendations are visible
      expect(find.text('Pasta'), findsOneWidget);
      expect(find.text('Chicken'), findsOneWidget);

      // rec3 (Salad) is not yet shown
      expect(find.text('Salad'), findsNothing);

      // Open the popup menu on the first card (Pasta)
      final moreButtons = find.byIcon(Icons.more_vert);
      await tester.tap(moreButtons.first);
      await tester.pumpAndSettle();

      // Tap "Skip" (notToday)
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Pasta is dismissed
      expect(find.text('Pasta'), findsNothing);

      // Replacement (Salad) has appeared
      expect(find.text('Salad'), findsOneWidget);

      // Chicken is still there
      expect(find.text('Chicken'), findsOneWidget);
    });
    testWidgets('list shrinks gracefully when pool is exhausted',
        (tester) async {
      // Only 2 recipes total, both shown initially — no reserve
      await tester.pumpWidget(_wrapDialog(
        RecipeSelectionDialog(
          recipes: [rec1.recipe, rec2.recipe],
          detailedRecommendations: [rec1, rec2],
          allScoredRecipes: [rec1, rec2],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Pasta'), findsOneWidget);
      expect(find.text('Chicken'), findsOneWidget);

      // Dismiss Pasta
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Pasta gone, Chicken still there, no crash
      expect(find.text('Pasta'), findsNothing);
      expect(find.text('Chicken'), findsOneWidget);
    });

    testWidgets('dismissed recipe is not offered as its own replacement',
        (tester) async {
      // Pool contains only rec1 and rec2; rec2 is not in initial list
      // but is the only candidate. After dismissing rec1, rec2 should appear.
      // Then dismissing rec2 — pool is exhausted, no replacement.
      await tester.pumpWidget(_wrapDialog(
        RecipeSelectionDialog(
          recipes: [rec1.recipe, rec2.recipe],
          detailedRecommendations: [rec1],
          allScoredRecipes: [rec1, rec2],
        ),
      ));
      await tester.pumpAndSettle();

      // Dismiss rec1 → rec2 replaces it
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.text('Pasta'), findsNothing);
      expect(find.text('Chicken'), findsOneWidget);

      // Dismiss rec2 → nothing to replace with
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.text('Chicken'), findsNothing);
      // No crash, empty state message shown
      expect(find.text('No recommendations available'), findsOneWidget);
    });
  });

  // Helper for capturing the Map return value from RecipeSelectionDialog.
  Map<String, dynamic>? _capturedMap;

  Widget _buildLauncherCapturing(Widget Function(BuildContext) dialogBuilder) {
    _capturedMap = null;
    return ChangeNotifierProvider(
      create: (_) => DebugSettingsProvider(),
      child: MaterialApp(
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
                _capturedMap = await showDialog<Map<String, dynamic>>(
                  context: ctx,
                  builder: dialogBuilder,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
  }

  group('Edit Mode — #316', () {
    late Recipe primaryRecipe;

    setUp(() {
      primaryRecipe = Recipe(
        id: 'edit-r1',
        name: 'Pasta Bolognese',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
      );
    });

    testWidgets(
        'dialog opens with isEditMode=true, shows recipe name and info icon',
        (tester) async {
      await tester.pumpWidget(_buildDialogLauncher(
        (_) => RecipeSelectionDialog(
          recipes: const [],
          initialPrimaryRecipe: primaryRecipe,
          isEditMode: true,
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Pasta Bolognese'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('Save Changes returns {action: save} with recipe data',
        (tester) async {
      await tester.pumpWidget(_buildLauncherCapturing(
        (_) => RecipeSelectionDialog(
          recipes: const [],
          initialPrimaryRecipe: primaryRecipe,
          isEditMode: true,
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('recipe_selection_save_button')));
      await tester.pumpAndSettle();

      expect(_capturedMap, isNotNull);
      expect(_capturedMap!['action'], equals('save'));
      expect(_capturedMap!['primaryRecipe'], equals(primaryRecipe));
    });

    testWidgets('Mark as Cooked returns {action: cooked}', (tester) async {
      await tester.pumpWidget(_buildLauncherCapturing(
        (_) => RecipeSelectionDialog(
          recipes: const [],
          initialPrimaryRecipe: primaryRecipe,
          isEditMode: true,
          initialMealCooked: false,
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

      expect(_capturedMap, isNotNull);
      expect(_capturedMap!['action'], equals('cooked'));
    });

    testWidgets('Edit Cooked Meal button shown when initialMealCooked=true',
        (tester) async {
      await tester.pumpWidget(_buildDialogLauncher(
        (_) => RecipeSelectionDialog(
          recipes: const [],
          initialPrimaryRecipe: primaryRecipe,
          isEditMode: true,
          initialMealCooked: true,
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
    });

    testWidgets('Change Recipe returns {action: change}', (tester) async {
      await tester.pumpWidget(_buildLauncherCapturing(
        (_) => RecipeSelectionDialog(
          recipes: const [],
          initialPrimaryRecipe: primaryRecipe,
          isEditMode: true,
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.swap_horiz));
      await tester.pumpAndSettle();

      expect(_capturedMap, isNotNull);
      expect(_capturedMap!['action'], equals('change'));
    });

    testWidgets('info icon tap returns {action: view}', (tester) async {
      await tester.pumpWidget(_buildLauncherCapturing(
        (_) => RecipeSelectionDialog(
          recipes: const [],
          initialPrimaryRecipe: primaryRecipe,
          isEditMode: true,
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();

      expect(_capturedMap, isNotNull);
      expect(_capturedMap!['action'], equals('view'));
    });

    testWidgets(
        'Remove (uncooked) returns {action: remove} without confirm dialog',
        (tester) async {
      await tester.pumpWidget(_buildLauncherCapturing(
        (_) => RecipeSelectionDialog(
          recipes: const [],
          initialPrimaryRecipe: primaryRecipe,
          isEditMode: true,
          initialMealCooked: false,
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // No AlertDialog shown — remove pops immediately
      expect(find.byType(AlertDialog), findsNothing);
      expect(_capturedMap, isNotNull);
      expect(_capturedMap!['action'], equals('remove'));
    });

    testWidgets(
        'Remove (cooked) shows confirmation dialog before returning {action: remove}',
        (tester) async {
      await tester.pumpWidget(_buildLauncherCapturing(
        (_) => RecipeSelectionDialog(
          recipes: const [],
          initialPrimaryRecipe: primaryRecipe,
          isEditMode: true,
          initialMealCooked: true,
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Confirmation dialog should be open
      expect(find.byType(AlertDialog), findsOneWidget);

      // Confirm removal
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      expect(_capturedMap, isNotNull);
      expect(_capturedMap!['action'], equals('remove'));
    });

    testWidgets('Remove (cooked) cancel does not pop dialog', (tester) async {
      await tester.pumpWidget(_buildLauncherCapturing(
        (_) => RecipeSelectionDialog(
          recipes: const [],
          initialPrimaryRecipe: primaryRecipe,
          isEditMode: true,
          initialMealCooked: true,
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.descendant(
          of: find.byType(AlertDialog), matching: find.text('Cancel')));
      await tester.pumpAndSettle();

      // AlertDialog dismissed but RecipeSelectionDialog still open
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byKey(const Key('recipe_selection_save_button')),
          findsOneWidget);
      expect(_capturedMap, isNull);
    });

    testWidgets('Back button is not visible', (tester) async {
      await tester.pumpWidget(_buildDialogLauncher(
        (_) => RecipeSelectionDialog(
          recipes: const [],
          initialPrimaryRecipe: primaryRecipe,
          isEditMode: true,
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('Cancel returns null', (tester) async {
      await tester.pumpWidget(_buildLauncherCapturing(
        (_) => RecipeSelectionDialog(
          recipes: const [],
          initialPrimaryRecipe: primaryRecipe,
          isEditMode: true,
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('recipe_selection_cancel_button')));
      await tester.pumpAndSettle();

      expect(_capturedMap, isNull);
      // Dialog dismissed
      expect(find.byKey(const Key('recipe_selection_save_button')),
          findsNothing);
    });

    testWidgets('new-meal mode (regression): Back button still visible',
        (tester) async {
      await tester.pumpWidget(_buildLauncherCapturing(
        (_) => RecipeSelectionDialog(
          recipes: const [],
          initialPrimaryRecipe: primaryRecipe,
          // isEditMode defaults to false
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets(
        'new-meal mode (regression): Save Meal returns map without action key',
        (tester) async {
      await tester.pumpWidget(_buildLauncherCapturing(
        (_) => RecipeSelectionDialog(
          recipes: const [],
          initialPrimaryRecipe: primaryRecipe,
          // isEditMode defaults to false
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('recipe_selection_save_button')));
      await tester.pumpAndSettle();

      expect(_capturedMap, isNotNull);
      expect(_capturedMap!.containsKey('action'), isFalse);
    });
  });
}
