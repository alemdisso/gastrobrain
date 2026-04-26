import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/screens/recipe_details_screen.dart';
import 'package:gastrobrain/screens/recipe_details_overview_tab.dart';
import 'package:gastrobrain/screens/recipe_details_ingredients_tab.dart';
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
    home: Scaffold(body: child),
  );
}

Recipe _makeRecipe({int servings = 4, String id = 'test-id'}) {
  return Recipe(
    id: id,
    name: 'Test Recipe',
    createdAt: DateTime(2024, 1, 1),
    servings: servings,
    difficulty: 2,
    rating: 4,
    notes: '',
  );
}

/// A minimal ingredient map matching the shape RecipeDetailsIngredientsTab uses.
Map<String, dynamic> _makeIngredient({String name = 'Salt'}) {
  return {
    'name': name,
    'quantity': 1.0,
    'unit': 'tsp',
    'unit_override': null,
    'protein_type': null,
    'preparation_notes': null,
    'recipe_ingredient_id': 'ri-1',
  };
}

void main() {
  // ─────────────────────────── Overview tab ─────────────────────────────── //

  group('RecipeDetailsOverviewTab', () {
    testWidgets('displays servings row', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(RecipeDetailsOverviewTab(recipe: _makeRecipe(servings: 4))),
      );
      await tester.pumpAndSettle();

      expect(find.text('Servings: '), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('shows marinating time row when marinatingTimeMinutes > 0', (tester) async {
      final recipe = Recipe(
        id: 'test-id',
        name: 'Overnight Chicken',
        createdAt: DateTime(2024, 1, 1),
        marinatingTimeMinutes: 480,
      );

      await tester.pumpWidget(
        _buildTestApp(RecipeDetailsOverviewTab(recipe: recipe)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Marinate Time (min): '), findsOneWidget);
      expect(find.text('480 min'), findsOneWidget);
    });

    testWidgets('hides marinating time row when marinatingTimeMinutes is 0', (tester) async {
      final recipe = Recipe(
        id: 'test-id',
        name: 'Quick Pasta',
        createdAt: DateTime(2024, 1, 1),
        marinatingTimeMinutes: 0, // default — no marinating
      );

      await tester.pumpWidget(
        _buildTestApp(RecipeDetailsOverviewTab(recipe: recipe)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Marinate Time (min): '), findsNothing);
    });

    testWidgets('servings row is always visible regardless of value', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(RecipeDetailsOverviewTab(recipe: _makeRecipe(servings: 1))),
      );
      await tester.pumpAndSettle();

      expect(find.text('Servings: '), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });
  });

  // ─────────────────────────── Ingredients tab ──────────────────────────── //

  group('RecipeDetailsIngredientsTab', () {
    testWidgets('shows "Ingredients for X servings" header with non-empty list',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          RecipeDetailsIngredientsTab(
            ingredients: [_makeIngredient()],
            servings: 3,
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

      expect(find.textContaining('Ingredients for 3 servings'), findsOneWidget);
    });

    testWidgets('header absent on empty state', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          RecipeDetailsIngredientsTab(
            ingredients: const [],
            servings: 4,
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

      expect(find.textContaining('Ingredients for'), findsNothing);
    });

    testWidgets('header absent on error state', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          RecipeDetailsIngredientsTab(
            ingredients: const [],
            servings: 4,
            isLoading: false,
            error: 'Something went wrong',
            onDeleteIngredient: (_) {},
            onEditIngredient: (_) {},
            onRetry: () {},
            onAdd: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Ingredients for'), findsNothing);
    });

    testWidgets('header absent while loading', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          RecipeDetailsIngredientsTab(
            ingredients: const [],
            servings: 4,
            isLoading: true,
            error: null,
            onDeleteIngredient: (_) {},
            onEditIngredient: (_) {},
            onRetry: () {},
            onAdd: () {},
          ),
        ),
      );
      // Don't pumpAndSettle — loading spinner is the expected state.
      await tester.pump();

      expect(find.textContaining('Ingredients for'), findsNothing);
    });
  });

  // ─────────────────────────── Instructions tab ─────────────────────────── //

  group('Instructions tab', () {
    late MockDatabaseHelper mockDb;

    setUp(() {
      mockDb = MockDatabaseHelper();
    });

    tearDown(() {
      mockDb.resetAllData();
    });

    testWidgets('shows empty state when recipe has no instructions', (tester) async {
      final recipe = _makeRecipe();
      await mockDb.insertRecipe(recipe);

      await tester.pumpWidget(
        _buildTestApp(
          RecipeDetailsScreen(
            recipe: recipe,
            databaseHelper: mockDb,
            initialTabIndex: 1,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No instructions available for this recipe.'), findsOneWidget);
      expect(find.text('Add Instructions'), findsOneWidget);
    });

    testWidgets('cancel leaves instructions unchanged', (tester) async {
      final recipe = Recipe(
        id: 'test-id',
        name: 'Test Recipe',
        createdAt: DateTime(2024, 1, 1),
        servings: 4,
        difficulty: 2,
        rating: 4,
        notes: '',
        instructions: 'Original instructions',
      );
      await mockDb.insertRecipe(recipe);

      await tester.pumpWidget(
        _buildTestApp(
          RecipeDetailsScreen(
            recipe: recipe,
            databaseHelper: mockDb,
            initialTabIndex: 1,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Changed instructions');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      final stored = mockDb.recipes['test-id'];
      expect(stored!.instructions, equals('Original instructions'));
    });
  });

  // ────────────────────────── Regression: _saveInstructions ─────────────── //

  group('_saveInstructions regression', () {
    late MockDatabaseHelper mockDb;

    setUp(() {
      mockDb = MockDatabaseHelper();
    });

    tearDown(() {
      mockDb.resetAllData();
    });

    testWidgets('preserves servings when instructions are updated', (tester) async {
      final recipe = _makeRecipe(servings: 6);
      await mockDb.insertRecipe(recipe);

      await tester.pumpWidget(
        _buildTestApp(
          RecipeDetailsScreen(
            recipe: recipe,
            databaseHelper: mockDb,
            initialTabIndex: 1, // Instructions tab
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open edit instructions dialog via FAB.
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Replace instructions text.
      await tester.enterText(find.byType(TextField), 'Updated instructions');
      await tester.pumpAndSettle();

      // Confirm save.
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // The stored recipe must still carry servings = 6.
      final stored = mockDb.recipes['test-id'];
      expect(stored, isNotNull);
      expect(stored!.servings, equals(6),
          reason: '_saveInstructions dropped servings — data loss bug regressed');
    });
  });
}
