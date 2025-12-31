// test/edge_cases/empty_states/meal_history_empty_state_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/screens/meal_history_screen.dart';
import 'package:gastrobrain/core/di/providers/database_provider.dart';
import 'package:gastrobrain/core/providers/recipe_provider.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gastrobrain/l10n/app_localizations.dart';
import '../../mocks/mock_database_helper.dart';
import '../../helpers/edge_case_test_helpers.dart';

/// Tests for meal history empty state handling.
///
/// Verifies that the application handles the empty state gracefully when:
/// - No meals have been recorded for a recipe
/// - All meals for a recipe have been deleted
/// - First-time viewing meal history for a recipe
void main() {
  group('Meal History - Empty States', () {
    late MockDatabaseHelper mockDbHelper;
    late RecipeProvider recipeProvider;
    late Recipe testRecipe;

    setUp(() {
      mockDbHelper = MockDatabaseHelper();
      DatabaseProvider().setDatabaseHelper(mockDbHelper);
      recipeProvider = RecipeProvider();

      // Create a test recipe for the meal history screen
      testRecipe = Recipe(
        id: 'test-recipe-1',
        name: 'Spaghetti Carbonara',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
        difficulty: 3,
        prepTimeMinutes: 15,
        cookTimeMinutes: 20,
      );
      mockDbHelper.insertRecipe(testRecipe);
    });

    tearDown(() {
      mockDbHelper.resetAllData();
    });

    /// Helper to build MealHistoryScreen with proper providers and localization
    Widget buildMealHistoryScreen({
      Recipe? recipe,
      Locale locale = const Locale('en', ''),
    }) {
      return ChangeNotifierProvider<RecipeProvider>.value(
        value: recipeProvider,
        child: MaterialApp(
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
          locale: locale,
          home: MealHistoryScreen(
            recipe: recipe ?? testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );
    }

    testWidgets('shows empty state when no meals recorded for recipe',
        (WidgetTester tester) async {
      // Setup: No meals in database (mockDbHelper has no meals by default)
      expect(mockDbHelper.meals.isEmpty, isTrue,
          reason: 'Test precondition: no meals should exist');

      // Build the MealHistoryScreen
      await tester.pumpWidget(buildMealHistoryScreen());

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Verify empty state message is displayed
      EdgeCaseTestHelpers.verifyEmptyState(
        tester,
        expectedMessage: 'No meals recorded yet',
      );

      // Verify empty state icon
      expect(find.byIcon(Icons.history), findsOneWidget,
          reason: 'Should show history icon in empty state');
    });

    testWidgets('shows recipe name in app bar title',
        (WidgetTester tester) async {
      // Build the MealHistoryScreen
      await tester.pumpWidget(buildMealHistoryScreen());
      await tester.pumpAndSettle();

      // Verify app bar shows recipe name
      expect(find.text(testRecipe.name), findsOneWidget,
          reason: 'App bar should display recipe name as title');
    });

    testWidgets('shows refresh button in app bar',
        (WidgetTester tester) async {
      // Build the MealHistoryScreen
      await tester.pumpWidget(buildMealHistoryScreen());
      await tester.pumpAndSettle();

      // Verify refresh button is present
      expect(find.byIcon(Icons.refresh), findsOneWidget,
          reason: 'App bar should have refresh button');

      // Verify refresh button has correct tooltip
      final refreshButton = find.byIcon(Icons.refresh);
      final iconButton = tester.widget<IconButton>(
        find.ancestor(
          of: refreshButton,
          matching: find.byType(IconButton),
        ),
      );
      expect(iconButton.tooltip, equals('Refresh'),
          reason: 'Refresh button should have tooltip');
    });

    testWidgets('empty state UI renders correctly without overflow',
        (WidgetTester tester) async {
      // Build the MealHistoryScreen
      await tester.pumpWidget(buildMealHistoryScreen());
      await tester.pumpAndSettle();

      // Verify no rendering exceptions
      expect(tester.takeException(), isNull,
          reason: 'Empty state should render without exceptions');

      // Verify empty state is centered
      final emptyMessage = find.text('No meals recorded yet');
      expect(emptyMessage, findsOneWidget);

      final centerWidget = find.ancestor(
        of: emptyMessage,
        matching: find.byType(Center),
      );
      expect(centerWidget, findsWidgets,
          reason: 'Empty state should be in a centered layout');
    });

    testWidgets('empty state message is localized to Portuguese',
        (WidgetTester tester) async {
      // Build with Portuguese locale
      await tester.pumpWidget(
        buildMealHistoryScreen(locale: const Locale('pt', '')),
      );
      await tester.pumpAndSettle();

      // Verify Portuguese empty state message
      expect(find.text('Nenhuma refeição registrada ainda'), findsOneWidget,
          reason: 'Empty state message should be in Portuguese');
    });

    testWidgets('refresh button reloads data without errors',
        (WidgetTester tester) async {
      // Build the MealHistoryScreen
      await tester.pumpWidget(buildMealHistoryScreen());
      await tester.pumpAndSettle();

      // Tap refresh button
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      // Verify screen reloads without errors
      expect(tester.takeException(), isNull,
          reason: 'Refresh should complete without exceptions');

      // Empty state should still be shown
      expect(find.text('No meals recorded yet'), findsOneWidget,
          reason: 'Empty state should persist after refresh');
    });

    testWidgets('empty state persists with different recipes',
        (WidgetTester tester) async {
      // Create another recipe
      final chickenRecipe = Recipe(
        id: 'test-recipe-2',
        name: 'Grilled Chicken',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
        difficulty: 2,
        prepTimeMinutes: 10,
        cookTimeMinutes: 25,
      );
      mockDbHelper.insertRecipe(chickenRecipe);

      // Build the MealHistoryScreen with the new recipe
      await tester.pumpWidget(buildMealHistoryScreen(recipe: chickenRecipe));
      await tester.pumpAndSettle();

      // Verify empty state is shown for the new recipe
      expect(find.text('No meals recorded yet'), findsOneWidget,
          reason: 'Empty state should be shown for recipe with no meals');

      // Verify app bar shows correct recipe name
      expect(find.text(chickenRecipe.name), findsOneWidget,
          reason: 'App bar should show correct recipe name');
    });

    testWidgets('screen builds without crashing when recipe has no meals',
        (WidgetTester tester) async {
      // Build the MealHistoryScreen
      await tester.pumpWidget(buildMealHistoryScreen());

      // Wait for initial load
      await tester.pumpAndSettle();

      // Verify screen builds
      expect(find.byType(MealHistoryScreen), findsOneWidget,
          reason: 'MealHistoryScreen should build successfully');

      // Verify no exceptions
      expect(tester.takeException(), isNull,
          reason: 'Screen should build without exceptions');
    });

    testWidgets('empty state column is properly structured',
        (WidgetTester tester) async {
      // Build the MealHistoryScreen
      await tester.pumpWidget(buildMealHistoryScreen());
      await tester.pumpAndSettle();

      // Verify empty state contains icon and text in a column
      final emptyMessage = find.text('No meals recorded yet');
      expect(emptyMessage, findsOneWidget);

      // Verify the column structure (icon above text)
      final columnWidget = find.ancestor(
        of: emptyMessage,
        matching: find.byType(Column),
      );
      expect(columnWidget, findsWidgets,
          reason: 'Empty state should use Column layout');
    });
  });

  group('Meal History - Empty State Edge Cases', () {
    late MockDatabaseHelper mockDbHelper;
    late RecipeProvider recipeProvider;
    late Recipe testRecipe;

    setUp(() {
      mockDbHelper = MockDatabaseHelper();
      DatabaseProvider().setDatabaseHelper(mockDbHelper);
      recipeProvider = RecipeProvider();

      testRecipe = Recipe(
        id: 'test-recipe-3',
        name: 'Spaghetti Carbonara',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
        difficulty: 3,
        prepTimeMinutes: 15,
        cookTimeMinutes: 20,
      );
      mockDbHelper.insertRecipe(testRecipe);
    });

    tearDown(() {
      mockDbHelper.resetAllData();
    });

    Widget buildMealHistoryScreen() {
      return ChangeNotifierProvider<RecipeProvider>.value(
        value: recipeProvider,
        child: MaterialApp(
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
          home: MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );
    }

    testWidgets('handles rapid refresh button taps without errors',
        (WidgetTester tester) async {
      // Build the MealHistoryScreen
      await tester.pumpWidget(buildMealHistoryScreen());
      await tester.pumpAndSettle();

      // Rapidly tap refresh button multiple times
      final refreshButton = find.byIcon(Icons.refresh);
      for (int i = 0; i < 5; i++) {
        await tester.tap(refreshButton);
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();

      // Verify no errors occurred
      expect(tester.takeException(), isNull,
          reason: 'Rapid refresh taps should not cause exceptions');

      // Empty state should still be shown
      expect(find.text('No meals recorded yet'), findsOneWidget,
          reason: 'Empty state should remain after rapid refresh');
    });

    testWidgets('empty state text is visible and readable',
        (WidgetTester tester) async {
      // Build the MealHistoryScreen
      await tester.pumpWidget(buildMealHistoryScreen());
      await tester.pumpAndSettle();

      // Find the empty state text
      final emptyText = find.text('No meals recorded yet');
      expect(emptyText, findsOneWidget);

      // Verify text widget properties
      final textWidget = tester.widget<Text>(emptyText);
      expect(textWidget.style?.fontSize, equals(18),
          reason: 'Empty state text should have readable font size');
      expect(textWidget.style?.color, equals(Colors.grey),
          reason: 'Empty state text should have grey color');
    });

    testWidgets('empty state icon is visible and properly styled',
        (WidgetTester tester) async {
      // Build the MealHistoryScreen
      await tester.pumpWidget(buildMealHistoryScreen());
      await tester.pumpAndSettle();

      // Find the history icon
      final historyIcon = find.byIcon(Icons.history);
      expect(historyIcon, findsOneWidget);

      // Verify icon widget properties
      final iconWidget = tester.widget<Icon>(historyIcon);
      expect(iconWidget.size, equals(64),
          reason: 'Empty state icon should have appropriate size');
      expect(iconWidget.color, equals(Colors.grey),
          reason: 'Empty state icon should have grey color');
    });
  });
}
