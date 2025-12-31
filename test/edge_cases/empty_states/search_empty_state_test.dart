// test/edge_cases/empty_states/search_empty_state_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/screens/home_screen.dart';
import 'package:gastrobrain/core/di/providers/database_provider.dart';
import 'package:gastrobrain/core/providers/recipe_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gastrobrain/l10n/app_localizations.dart';
import '../../mocks/mock_database_helper.dart';

/// Tests for search functionality empty state handling.
///
/// Verifies that the application handles search edge cases gracefully when:
/// - Searching with no recipes in database
/// - Search field exists and is accessible in empty state
void main() {
  group('Search - Empty States', () {
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

    testWidgets('search field exists even with empty database',
        (WidgetTester tester) async {
      // Setup: Empty database (no recipes)
      expect(mockDbHelper.recipes.isEmpty, isTrue,
          reason: 'Test precondition: database should be empty');

      // Build the HomePage
      await tester.pumpWidget(buildHomePage());
      await tester.pumpAndSettle();

      // Verify search field is present
      expect(find.byType(TextField), findsOneWidget,
          reason: 'Search field should be present even with empty database');

      // Verify search icon
      expect(find.byIcon(Icons.search), findsOneWidget,
          reason: 'Search field should have search icon');
    });

    testWidgets('empty state shows when no recipes exist',
        (WidgetTester tester) async {
      // Setup: Empty database
      expect(mockDbHelper.recipes.isEmpty, isTrue);

      // Build the HomePage
      await tester.pumpWidget(buildHomePage());
      await tester.pumpAndSettle();

      // Verify empty state message
      expect(find.text('No recipes found'), findsOneWidget,
          reason: 'Should show empty state message');

      // Verify guidance message
      expect(find.text('Add your first recipe to get started'), findsOneWidget,
          reason: 'Should show helpful guidance message');
    });

    testWidgets('search field handles text input in empty state',
        (WidgetTester tester) async {
      // Setup: Empty database
      await tester.pumpWidget(buildHomePage());
      await tester.pumpAndSettle();

      // Enter text in search field
      await tester.enterText(find.byType(TextField), 'Sushi');
      await tester.pumpAndSettle();

      // Verify no exceptions occurred
      expect(tester.takeException(), isNull,
          reason: 'Search should handle text input without errors in empty state');

      // Empty state should still be shown
      expect(find.text('No recipes found'), findsOneWidget,
          reason: 'Empty state should persist when searching with no recipes');
    });

    testWidgets('search field can be cleared in empty state',
        (WidgetTester tester) async {
      // Setup: Empty database
      await tester.pumpWidget(buildHomePage());
      await tester.pumpAndSettle();

      // Enter text in search field
      await tester.enterText(find.byType(TextField), 'Test query');
      await tester.pumpAndSettle();

      // Clear the search field
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      // Verify no exceptions occurred
      expect(tester.takeException(), isNull,
          reason: 'Clearing search should work without errors');

      // Empty state should still be shown
      expect(find.text('No recipes found'), findsOneWidget);
    });

    testWidgets('search field handles special characters in empty state',
        (WidgetTester tester) async {
      // Setup: Empty database
      await tester.pumpWidget(buildHomePage());
      await tester.pumpAndSettle();

      // Enter special characters
      await tester.enterText(find.byType(TextField), '@#\$%^&*()');
      await tester.pumpAndSettle();

      // Verify no exceptions occurred
      expect(tester.takeException(), isNull,
          reason: 'Search should handle special characters without errors');

      // Empty state should persist
      expect(find.text('No recipes found'), findsOneWidget);
    });

    testWidgets('search field handles very long input in empty state',
        (WidgetTester tester) async {
      // Setup: Empty database
      await tester.pumpWidget(buildHomePage());
      await tester.pumpAndSettle();

      // Enter very long text
      final longText = 'a' * 1000;
      await tester.enterText(find.byType(TextField), longText);
      await tester.pumpAndSettle();

      // Verify no exceptions occurred
      expect(tester.takeException(), isNull,
          reason: 'Search should handle very long input without errors');

      // Empty state should persist
      expect(find.text('No recipes found'), findsOneWidget);
    });

    testWidgets('search UI layout renders correctly in empty state',
        (WidgetTester tester) async {
      // Setup: Empty database
      await tester.pumpWidget(buildHomePage());
      await tester.pumpAndSettle();

      // Verify search field is visible
      expect(find.byType(TextField), findsOneWidget);

      // Verify no rendering exceptions
      expect(tester.takeException(), isNull,
          reason: 'Search UI should render without exceptions');

      // Verify empty state icon
      expect(find.byIcon(Icons.restaurant_menu), findsWidgets,
          reason: 'Should show empty state icon');
    });

    testWidgets('search field is accessible after rapid text changes',
        (WidgetTester tester) async {
      // Setup: Empty database
      await tester.pumpWidget(buildHomePage());
      await tester.pumpAndSettle();

      // Rapidly change search text
      for (int i = 0; i < 10; i++) {
        await tester.enterText(find.byType(TextField), 'Query $i');
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();

      // Verify no exceptions occurred
      expect(tester.takeException(), isNull,
          reason: 'Rapid text changes should not cause errors');

      // Verify search field is still accessible
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('empty state persists across search operations',
        (WidgetTester tester) async {
      // Setup: Empty database
      await tester.pumpWidget(buildHomePage());
      await tester.pumpAndSettle();

      // Perform multiple search operations
      await tester.enterText(find.byType(TextField), 'First');
      await tester.pumpAndSettle();
      expect(find.text('No recipes found'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Second');
      await tester.pumpAndSettle();
      expect(find.text('No recipes found'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      expect(find.text('No recipes found'), findsOneWidget,
          reason: 'Empty state should persist across all search operations');
    });

    testWidgets('search field maintains state during screen lifecycle',
        (WidgetTester tester) async {
      // Setup: Empty database
      await tester.pumpWidget(buildHomePage());
      await tester.pumpAndSettle();

      // Enter search text
      await tester.enterText(find.byType(TextField), 'Test');
      await tester.pumpAndSettle();

      // Trigger rebuild
      await tester.pump();

      // Verify search field still exists
      expect(find.byType(TextField), findsOneWidget,
          reason: 'Search field should persist through rebuilds');

      // Verify no exceptions
      expect(tester.takeException(), isNull);
    });
  });
}
