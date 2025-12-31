// test/edge_cases/empty_states/recipes_empty_state_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/screens/home_screen.dart';
import 'package:gastrobrain/core/di/providers/database_provider.dart';
import 'package:gastrobrain/core/providers/recipe_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gastrobrain/l10n/app_localizations.dart';
import '../../mocks/mock_database_helper.dart';
import '../../helpers/edge_case_test_helpers.dart';

/// Tests for recipe management empty state handling.
///
/// Verifies that the application handles the empty state gracefully when:
/// - No recipes exist in the database
/// - Search returns no results
/// - Filters exclude all recipes
void main() {
  group('Recipe Management - Empty States', () {
    late MockDatabaseHelper mockDbHelper;
    late RecipeProvider recipeProvider;

    setUp(() {
      mockDbHelper = MockDatabaseHelper();
      DatabaseProvider().setDatabaseHelper(mockDbHelper);
      recipeProvider = RecipeProvider();
    });

    tearDown(() {
      mockDbHelper.resetAllData();
    });

    /// Helper to build HomePage with proper providers and localization
    Widget buildHomePage() {
      return ChangeNotifierProvider<RecipeProvider>.value(
        value: recipeProvider,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('en', ''),
            Locale('pt', ''),
          ],
          home: HomePage(),
        ),
      );
    }

    testWidgets('shows empty state when no recipes exist in database',
        (WidgetTester tester) async {
      // Setup: Empty database (mockDbHelper has no recipes by default)
      expect(mockDbHelper.recipes.isEmpty, isTrue,
          reason: 'Test precondition: database should be empty');

      // Build the HomePage
      await tester.pumpWidget(buildHomePage());

      // Wait for provider to load (it loads in initState)
      await tester.pumpAndSettle();

      // Verify empty state is displayed
      EdgeCaseTestHelpers.verifyEmptyState(
        tester,
        expectedMessage: 'No recipes found',
      );

      // Verify helpful guidance message
      expect(find.text('Add your first recipe to get started'), findsOneWidget,
          reason: 'Should show helpful message for first-time users');

      // Verify empty state icon is displayed (there may be multiple icons in tabs, so check for at least one)
      expect(find.byIcon(Icons.restaurant_menu), findsWidgets,
          reason: 'Should show visual indicator in empty state');
    });

    testWidgets('shows add recipe button in empty state',
        (WidgetTester tester) async {
      // Setup: Empty database
      expect(mockDbHelper.recipes.isEmpty, isTrue);

      // Build the HomePage
      await tester.pumpWidget(buildHomePage());
      await tester.pumpAndSettle();

      // Verify empty state
      expect(find.text('No recipes found'), findsOneWidget);

      // Verify add button is available (FAB or other add action)
      // The HomePage should have a way to add recipes even when empty
      expect(find.byType(FloatingActionButton), findsOneWidget,
          reason: 'Should provide action button to add first recipe');
    });

    testWidgets('empty state UI renders correctly without overflow',
        (WidgetTester tester) async {
      // Setup: Empty database
      await tester.pumpWidget(buildHomePage());
      await tester.pumpAndSettle();

      // Verify empty state renders
      expect(find.text('No recipes found'), findsOneWidget);

      // Verify no rendering issues
      expect(tester.takeException(), isNull,
          reason: 'Empty state should render without exceptions');

      // Verify layout is centered and well-structured (may have multiple Columns in the tree)
      final centerWidget = find.ancestor(
        of: find.text('No recipes found'),
        matching: find.byType(Center),
      );
      expect(centerWidget, findsWidgets,
          reason: 'Empty state should be in a centered layout');
    });

    testWidgets('empty state persists during loading',
        (WidgetTester tester) async {
      // Build the HomePage
      await tester.pumpWidget(buildHomePage());

      // Pump once to trigger loading
      await tester.pump();

      // Database is empty, so after loading completes, empty state should show
      await tester.pumpAndSettle();

      // Verify empty state appears after loading
      expect(find.text('No recipes found'), findsOneWidget);
    });

    testWidgets('empty state message is localized',
        (WidgetTester tester) async {
      // Test with Portuguese locale
      final ptHomePage = ChangeNotifierProvider<RecipeProvider>.value(
        value: recipeProvider,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('en', ''),
            Locale('pt', ''),
          ],
          locale: Locale('pt', ''), // Force Portuguese
          home: HomePage(),
        ),
      );

      await tester.pumpWidget(ptHomePage);
      await tester.pumpAndSettle();

      // Verify Portuguese empty state message
      expect(find.text('Nenhuma receita encontrada'), findsOneWidget,
          reason: 'Empty state should be localized to Portuguese');
      expect(find.text('Adicione sua primeira receita para começar'),
          findsOneWidget,
          reason: 'Guidance message should be localized to Portuguese');
    });
  });
}
