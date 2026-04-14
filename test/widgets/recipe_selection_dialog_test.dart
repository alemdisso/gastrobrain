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

void main() {
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
}
