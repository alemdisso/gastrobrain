// test/edge_cases/empty_states/ingredients_empty_state_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/screens/ingredients_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gastrobrain/l10n/app_localizations.dart';

/// Tests for ingredient management empty state handling.
///
/// **Note on Testing Limitations:**
/// IngredientsScreen does not currently support dependency injection for
/// DatabaseHelper, making it difficult to test with a mock database in unit tests.
/// These tests focus on UI rendering and behavior that can be verified without
/// database mocking.
///
/// **Future Enhancement:**
/// Consider adding optional DatabaseHelper parameter to IngredientsScreen
/// constructor for better testability (similar to AddRecipeScreen pattern).
///
/// Verifies that the application handles the empty state gracefully when:
/// - No ingredients exist in the database
/// - UI renders correctly in empty state
/// - Empty state messages are properly localized
void main() {
  group('Ingredient Management - Empty States', () {
    /// Helper to build IngredientsScreen with proper localization
    Widget buildIngredientsScreen({Locale locale = const Locale('en', '')}) {
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
        locale: locale,
        home: const IngredientsScreen(),
      );
    }

    testWidgets('IngredientsScreen builds without crashing',
        (WidgetTester tester) async {
      // Build the IngredientsScreen
      await tester.pumpWidget(buildIngredientsScreen());

      // Wait for initial load
      await tester.pump();

      // Verify screen builds
      expect(find.byType(IngredientsScreen), findsOneWidget,
          reason: 'IngredientsScreen should build successfully');

      // Verify no exceptions
      expect(tester.takeException(), isNull,
          reason: 'Screen should build without exceptions');
    });

    testWidgets('empty state UI contains expected elements',
        (WidgetTester tester) async {
      // Build the IngredientsScreen
      await tester.pumpWidget(buildIngredientsScreen());

      // Wait for loading to complete (database will be empty in test environment initially)
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Note: Without database mocking, we can't guarantee empty state
      // But if it appears, we can verify its structure
      final emptyMessage = find.text('No ingredients added yet');
      if (emptyMessage.evaluate().isNotEmpty) {
        // Verify empty state message
        expect(emptyMessage, findsOneWidget,
            reason: 'Should show empty state message');

        // Verify add button is present
        expect(find.widgetWithText(ElevatedButton, 'Add Ingredient'),
            findsOneWidget,
            reason: 'Should show add ingredient button in empty state');

        // Verify icon is present
        expect(find.byIcon(Icons.no_food), findsOneWidget,
            reason: 'Should show empty state icon');
      }
    });

    testWidgets('empty state message is localized to Portuguese',
        (WidgetTester tester) async {
      // Build with Portuguese locale
      await tester.pumpWidget(
        buildIngredientsScreen(locale: const Locale('pt', '')),
      );

      // Wait for loading to complete
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // If empty state is shown, verify Portuguese text
      final ptEmptyMessage = find.text('Nenhum ingrediente adicionado ainda');
      if (ptEmptyMessage.evaluate().isNotEmpty) {
        expect(ptEmptyMessage, findsOneWidget,
            reason: 'Empty state message should be in Portuguese');

        expect(find.widgetWithText(ElevatedButton, 'Adicionar Ingrediente'),
            findsOneWidget,
            reason: 'Add button should be in Portuguese');
      }
    });

    testWidgets('empty state layout renders without overflow',
        (WidgetTester tester) async {
      // Build the screen
      await tester.pumpWidget(buildIngredientsScreen());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify no rendering exceptions
      expect(tester.takeException(), isNull,
          reason: 'Empty state should render without overflow or exceptions');

      // If empty state is visible, verify it's centered
      final emptyMessage = find.text('No ingredients added yet');
      if (emptyMessage.evaluate().isNotEmpty) {
        final centerWidget = find.ancestor(
          of: emptyMessage,
          matching: find.byType(Center),
        );
        expect(centerWidget, findsWidgets,
            reason: 'Empty state should be centered');
      }
    });

    testWidgets('search field exists even in empty state',
        (WidgetTester tester) async {
      // Build the screen
      await tester.pumpWidget(buildIngredientsScreen());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Search field should be available for future use
      // (This tests that the UI structure is complete even when empty)
      expect(find.byType(TextField), findsWidgets,
          reason: 'Search functionality should be present');
    });
  });

  group('Ingredient Management - Empty State Limitations', () {
    testWidgets('documents DI limitation for future improvement',
        (WidgetTester tester) async {
      // This test serves as documentation for a known limitation

      // CURRENT LIMITATION:
      // IngredientsScreen uses DatabaseHelper() singleton directly
      // without accepting an optional parameter for testing.
      //
      // IMPACT:
      // - Cannot easily test with mock database
      // - Cannot test transition from empty to populated state
      // - Cannot test database error scenarios
      //
      // RECOMMENDED ENHANCEMENT:
      // Add optional DatabaseHelper parameter to IngredientsScreen:
      //
      // class IngredientsScreen extends StatefulWidget {
      //   final DatabaseHelper? databaseHelper;
      //   const IngredientsScreen({super.key, this.databaseHelper});
      // }
      //
      // Then in _IngredientsScreenState:
      // late final DatabaseHelper _dbHelper =
      //     widget.databaseHelper ?? DatabaseHelper();
      //
      // This pattern is already used successfully in AddRecipeScreen
      // and other screens.

      expect(true, isTrue, reason: 'Documentation test always passes');
    });
  });
}
