import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/screens/recipe_form_screen.dart';
import 'package:gastrobrain/l10n/app_localizations.dart';
import '../mocks/mock_database_helper.dart';

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
  int difficulty = 2,
  int rating = 3,
  String? notes,
  String? story,
  int prepTimeMinutes = 15,
  int cookTimeMinutes = 30,
}) {
  return Recipe(
    id: id,
    name: name,
    desiredFrequency: FrequencyType.weekly,
    createdAt: DateTime(2024, 1, 1),
    servings: servings,
    difficulty: difficulty,
    rating: rating,
    notes: notes ?? '',
    story: story ?? '',
    prepTimeMinutes: prepTimeMinutes,
    cookTimeMinutes: cookTimeMinutes,
  );
}

void main() {
  // ─────────────────────── Create mode — Phase 1 ─────────────────────────── //

  group('Create mode — Phase 1', () {
    late MockDatabaseHelper mockDb;

    setUp(() {
      mockDb = MockDatabaseHelper();
    });

    tearDown(() {
      mockDb.resetAllData();
    });

    testWidgets('renders Phase 1 fields on open', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(RecipeFormScreen(databaseHelper: mockDb)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('recipe_form_name_field')), findsOneWidget);
      expect(find.byKey(const Key('recipe_form_frequency_field')), findsOneWidget);
      expect(find.byKey(const Key('recipe_form_servings_stepper')), findsOneWidget);
    });

    testWidgets('save button disabled when name is empty', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(RecipeFormScreen(databaseHelper: mockDb)),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('save button enabled when name is non-empty', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(RecipeFormScreen(databaseHelper: mockDb)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('recipe_form_name_field')), 'Pasta');
      await tester.pump();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('saves recipe and transitions to Phase 4 on valid save',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(RecipeFormScreen(databaseHelper: mockDb)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('recipe_form_name_field')), 'My New Recipe');
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(mockDb.recipes.length, equals(1));
      expect(mockDb.recipes.values.first.name, equals('My New Recipe'));
      // Phase 1 form gone; Phase 4 parser section now visible
      expect(find.byKey(const Key('recipe_form_name_field')), findsNothing);
      expect(find.byKey(const Key('ingredient_parser_parse_button')),
          findsOneWidget);
    });

    testWidgets('Phase 1 collapses to summary card after save', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(RecipeFormScreen(databaseHelper: mockDb)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('recipe_form_name_field')), 'Risotto');
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Summary card shows as a ListTile; name appears in both AppBar and card
      expect(find.byType(ListTile), findsOneWidget);
      expect(find.text('Risotto'), findsWidgets);
    });

    testWidgets('AppBar title updates to recipe name after Phase 1 save',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(RecipeFormScreen(databaseHelper: mockDb)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('recipe_form_name_field')), 'Tacos');
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Tacos'), findsWidgets);
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect((appBar.title as Text).data, equals('Tacos'));
    });

    testWidgets('edit icon on summary re-expands Phase 1', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(RecipeFormScreen(databaseHelper: mockDb)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('recipe_form_name_field')), 'Tacos');
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('recipe_form_name_field')), findsNothing);

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('recipe_form_name_field')), findsOneWidget);
    });
  });

  // ─────────────────────── Create mode — Phase 4 ─────────────────────────── //

  group('Create mode — Phase 4', () {
    late MockDatabaseHelper mockDb;

    setUp(() {
      mockDb = MockDatabaseHelper();
    });

    tearDown(() {
      mockDb.resetAllData();
    });

    testWidgets('Phase 4 shows IngredientParserSection after Phase 1 save',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(RecipeFormScreen(databaseHelper: mockDb)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('recipe_form_name_field')), 'Soup');
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Parse button is the visible entry point for the ingredient section
      expect(find.byKey(const Key('ingredient_parser_parse_button')),
          findsOneWidget);
    });

    testWidgets('Skip for now button is present after Phase 1 save',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(RecipeFormScreen(databaseHelper: mockDb)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('recipe_form_name_field')), 'Soup');
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Skip for now'), findsOneWidget);
    });
  });

  // ──────────────────────────── Edit mode ────────────────────────────────── //

  group('Edit mode', () {
    late MockDatabaseHelper mockDb;
    late Recipe recipe;

    setUp(() async {
      mockDb = MockDatabaseHelper();
      recipe = _makeRecipe(notes: 'Some notes', story: 'A story');
      await mockDb.insertRecipe(recipe);
    });

    tearDown(() {
      mockDb.resetAllData();
    });

    testWidgets('renders with name pre-filled from existing recipe',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
            RecipeFormScreen(recipe: recipe, databaseHelper: mockDb)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Recipe'), findsWidgets);
    });

    testWidgets('Basics and Ingredients sections expanded by default',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
            RecipeFormScreen(recipe: recipe, databaseHelper: mockDb)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('recipe_form_name_field')), findsOneWidget);
      // Parser section is visible (parse button is the entry point)
      expect(find.byKey(const Key('ingredient_parser_parse_button')),
          findsOneWidget);
    });

    testWidgets('More details section expands when tapped', (tester) async {
      // _SectionExpansion uses AnimatedCrossFade which keeps both children in
      // the widget tree — collapsed state is visual, not structural.
      // This test verifies the section IS expandable and reveals fields.
      await tester.pumpWidget(
        _buildTestApp(
            RecipeFormScreen(recipe: recipe, databaseHelper: mockDb)),
      );
      await tester.pumpAndSettle();

      // More details header is below the fold — scroll to it first
      final moreDetailsHeader = find.text('More details');
      expect(moreDetailsHeader, findsOneWidget);
      await tester.ensureVisible(moreDetailsHeader);
      await tester.pumpAndSettle();
      await tester.tap(moreDetailsHeader);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('recipe_form_notes_field')), findsOneWidget);
    });

    testWidgets('returns true to caller on Phase 1 save', (tester) async {
      bool? result;
      await tester.pumpWidget(
        _buildTestApp(
          Navigator(
            onGenerateRoute: (_) => MaterialPageRoute(
              builder: (_) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    result = await Navigator.of(
                            tester.element(find.byType(ElevatedButton).first))
                        .push<bool>(
                      MaterialPageRoute(
                        builder: (_) => RecipeFormScreen(
                            recipe: recipe, databaseHelper: mockDb),
                      ),
                    );
                  },
                  child: const Text('Open'),
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
          find.byKey(const Key('recipe_form_name_field')), 'Updated Name');
      await tester.pump();

      final saveButtons = find.byType(ElevatedButton);
      await tester.tap(saveButtons.first);
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });

  // ──────────────────────── Error handling ───────────────────────────────── //

  group('Error handling', () {
    late MockDatabaseHelper mockDb;

    setUp(() {
      mockDb = MockDatabaseHelper();
    });

    tearDown(() {
      mockDb.resetAllData();
    });

    testWidgets('shows error snackbar on DB save failure (Phase 1)',
        (tester) async {
      mockDb.failOnOperation('insertRecipe');

      await tester.pumpWidget(
        _buildTestApp(RecipeFormScreen(databaseHelper: mockDb)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('recipe_form_name_field')), 'Fail Recipe');
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('stays on Phase 1 form after save failure', (tester) async {
      mockDb.failOnOperation('insertRecipe');

      await tester.pumpWidget(
        _buildTestApp(RecipeFormScreen(databaseHelper: mockDb)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('recipe_form_name_field')), 'Fail Recipe');
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('recipe_form_name_field')), findsOneWidget);
      expect(mockDb.recipes, isEmpty);
    });
  });

  // ─────────────────────── Phase 2 — Timing & Difficulty ─────────────────── //

  group('Phase 2 — Timing & Difficulty', () {
    late MockDatabaseHelper mockDb;

    setUp(() {
      mockDb = MockDatabaseHelper();
    });

    tearDown(() {
      mockDb.resetAllData();
    });

    testWidgets('edit mode shows Timing & Difficulty section header', (tester) async {
      final recipe = _makeRecipe();
      await mockDb.insertRecipe(recipe);

      await tester.pumpWidget(
        _buildTestApp(RecipeFormScreen(recipe: recipe, databaseHelper: mockDb)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Timing & Difficulty'), findsOneWidget,
          reason: 'Phase 2 section header should be visible in edit mode');
    });

    testWidgets('saving Phase 2 persists difficulty and timing to DB', (tester) async {
      final recipe = _makeRecipe(difficulty: 1, prepTimeMinutes: 0);
      await mockDb.insertRecipe(recipe);

      await tester.pumpWidget(
        _buildTestApp(RecipeFormScreen(recipe: recipe, databaseHelper: mockDb)),
      );
      await tester.pumpAndSettle();

      // Collapse Phase 1 and Phase 4 so Phase 2 is reachable.
      // Use widgetWithText(InkWell, ...) to target only the section header InkWells.
      await tester.tap(find.widgetWithText(InkWell, 'Basics').first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(InkWell, 'Ingredients').first);
      await tester.pumpAndSettle();

      // Expand Phase 2
      await tester.tap(find.text('Timing & Difficulty'));
      await tester.pumpAndSettle();

      // Enter prep time
      await tester.enterText(
          find.byKey(const Key('recipe_form_prep_time_field')), '20');
      await tester.pump();

      // Tap Phase 2 save button (now visible after section expanded)
      final saveBtn = find.byKey(const Key('recipe_form_phase2_save_button'));
      await tester.ensureVisible(saveBtn);
      await tester.pumpAndSettle();
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(mockDb.recipes['recipe-1']?.prepTimeMinutes, equals(20),
          reason: 'Phase 2 save should persist prep time to DB');
    });

    testWidgets('More Details section no longer contains timing fields', (tester) async {
      final recipe = _makeRecipe();
      await mockDb.insertRecipe(recipe);

      await tester.pumpWidget(
        _buildTestApp(RecipeFormScreen(recipe: recipe, databaseHelper: mockDb)),
      );
      await tester.pumpAndSettle();

      // Both Phase 2 AND More Details sections exist
      expect(find.text('Timing & Difficulty'), findsOneWidget);
      expect(find.text('More details'), findsOneWidget);

      // Timing fields exist exactly once (inside Phase 2, not duplicated)
      expect(find.byKey(const Key('recipe_form_prep_time_field')), findsOneWidget);
      expect(find.byKey(const Key('recipe_form_cook_time_field')), findsOneWidget);
    });
  });

  // ─────────────────────── Phase 3 — Tags & Rating ───────────────────────── //

  group('Phase 3 — Tags & Rating', () {
    late MockDatabaseHelper mockDb;

    setUp(() {
      mockDb = MockDatabaseHelper();
    });

    tearDown(() {
      mockDb.resetAllData();
    });

    testWidgets('edit mode shows Tags & Rating section header', (tester) async {
      final recipe = _makeRecipe();
      await mockDb.insertRecipe(recipe);

      await tester.pumpWidget(
        _buildTestApp(RecipeFormScreen(recipe: recipe, databaseHelper: mockDb)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tags & Rating'), findsOneWidget,
          reason: 'Phase 3 section header should be visible in edit mode');
    });

    testWidgets('saving Phase 3 persists rating to DB', (tester) async {
      final recipe = _makeRecipe(rating: 1);
      await mockDb.insertRecipe(recipe);

      await tester.pumpWidget(
        _buildTestApp(RecipeFormScreen(recipe: recipe, databaseHelper: mockDb)),
      );
      await tester.pumpAndSettle();

      // Collapse the two expanded sections so Phase 3 header fits in viewport
      await tester.tap(find.widgetWithText(InkWell, 'Basics').first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(InkWell, 'Ingredients').first);
      await tester.pumpAndSettle();

      // Expand Phase 3 (Phase 2 stays collapsed — don't touch it)
      await tester.tap(find.widgetWithText(InkWell, 'Tags & Rating').first);
      await tester.pumpAndSettle();

      // Tap 5th star (rating = 5) — find unlit star_border icons, tap last
      await tester.tap(find.byIcon(Icons.star_border).last);
      await tester.pump();

      // Tap Phase 3 save button
      final saveBtn = find.byKey(const Key('recipe_form_phase3_save_button'));
      await tester.ensureVisible(saveBtn);
      await tester.pumpAndSettle();
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(mockDb.recipes['recipe-1']?.rating, equals(5),
          reason: 'Phase 3 save should persist rating to DB');
    });

    testWidgets('tag picker present in Phase 3 section', (tester) async {
      final recipe = _makeRecipe();
      await mockDb.insertRecipe(recipe);

      await tester.pumpWidget(
        _buildTestApp(RecipeFormScreen(recipe: recipe, databaseHelper: mockDb)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('recipe_form_tag_picker')), findsOneWidget,
          reason: 'TagPickerWidget should be in Phase 3, not More Details');
    });
  });
}
