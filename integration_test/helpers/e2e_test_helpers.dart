// integration_test/helpers/e2e_test_helpers.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/main.dart';
import 'package:gastrobrain/database/database_helper.dart';

/// E2E Test Helper Methods
///
/// Common utilities for end-to-end integration tests.
/// Extracted from working tests to reduce duplication and improve maintainability.
class E2ETestHelpers {
  /// Standard app initialization time
  static const appInitializationDuration = Duration(seconds: 10);

  /// Standard animation settlement time
  static const standardSettleDuration = Duration(seconds: 3);

  // ============================================================================
  // APP INITIALIZATION
  // ============================================================================

  /// Launch the app and wait for complete initialization
  ///
  /// This handles:
  /// - Database initialization and migrations
  /// - JSON asset loading (recipes, ingredients)
  /// - Provider setup
  /// - Initial data loading
  ///
  /// Usage:
  /// ```dart
  /// await E2ETestHelpers.launchApp(tester);
  /// ```
  static Future<void> launchApp(WidgetTester tester) async {
    WidgetsFlutterBinding.ensureInitialized();
    await tester.pumpWidget(const GastrobrainApp());
    await tester.pumpAndSettle(appInitializationDuration);
  }

  // ============================================================================
  // NAVIGATION HELPERS
  // ============================================================================

  /// Tap a bottom navigation tab by its icon
  ///
  /// Usage:
  /// ```dart
  /// await E2ETestHelpers.tapBottomNavTab(tester, Icons.calendar_today);
  /// ```
  static Future<void> tapBottomNavTab(
    WidgetTester tester,
    IconData icon,
  ) async {
    final bottomNavBar = find.byType(BottomNavigationBar);
    final tab = find.descendant(
      of: bottomNavBar,
      matching: find.byIcon(icon),
    );
    expect(tab, findsOneWidget, reason: 'Tab with icon $icon should exist');
    await tester.tap(tab);
    await tester.pumpAndSettle();
  }

  /// Open the Add Recipe form by tapping the FAB
  ///
  /// Returns the number of text fields found in the form (useful for verification)
  ///
  /// Usage:
  /// ```dart
  /// final fieldCount = await E2ETestHelpers.openAddRecipeForm(tester);
  /// ```
  static Future<int> openAddRecipeForm(WidgetTester tester) async {
    final fab = find.byType(FloatingActionButton);
    expect(fab, findsOneWidget, reason: 'FAB should be visible');
    await tester.tap(fab);
    await tester.pumpAndSettle();

    final textFields = find.byType(TextFormField);
    return textFields.evaluate().length;
  }

  /// Close a form or dialog using the back button
  ///
  /// Usage:
  /// ```dart
  /// await E2ETestHelpers.closeFormWithBackButton(tester);
  /// ```
  static Future<void> closeFormWithBackButton(WidgetTester tester) async {
    final backButton = find.byType(BackButton);
    if (backButton.evaluate().isEmpty) {
      final backIcon = find.byIcon(Icons.arrow_back);
      expect(backIcon, findsOneWidget, reason: 'Back button should exist');
      await tester.tap(backIcon);
    } else {
      await tester.tap(backButton);
    }
    await tester.pumpAndSettle();
  }

  // ============================================================================
  // FORM INTERACTION HELPERS
  // ============================================================================

  /// Enter text into a form field by index
  ///
  /// Note: Using index-based access is fragile. Consider adding keys to form
  /// fields for more robust access (see issue #219).
  ///
  /// Usage:
  /// ```dart
  /// await E2ETestHelpers.fillTextFieldByIndex(tester, 0, 'Recipe Name');
  /// ```
  static Future<void> fillTextFieldByIndex(
    WidgetTester tester,
    int index,
    String text,
  ) async {
    final textFields = find.byType(TextFormField);
    expect(textFields.evaluate().length, greaterThan(index),
        reason: 'TextFormField at index $index should exist');

    await tester.enterText(textFields.at(index), text);
    await tester.pumpAndSettle();
  }

  /// Enter text into a form field by key
  ///
  /// Requires form fields to have explicit keys (see issue #219).
  ///
  /// Usage:
  /// ```dart
  /// await E2ETestHelpers.fillTextFieldByKey(
  ///   tester,
  ///   Key('add_recipe_name_field'),
  ///   'Recipe Name'
  /// );
  /// ```
  static Future<void> fillTextFieldByKey(
    WidgetTester tester,
    Key key,
    String text,
  ) async {
    final field = find.byKey(key);
    expect(field, findsOneWidget, reason: 'Field with key $key should exist');
    await tester.enterText(field, text);
    await tester.pumpAndSettle();
  }

  /// Scroll down in a scrollable view
  ///
  /// Usage:
  /// ```dart
  /// await E2ETestHelpers.scrollDown(tester, offset: 500);
  /// ```
  static Future<void> scrollDown(
    WidgetTester tester, {
    double offset = 500,
  }) async {
    final scrollView = find.byType(SingleChildScrollView).first;
    await tester.drag(scrollView, Offset(0, -offset));
    await tester.pumpAndSettle();
  }

  /// Scroll up in a scrollable view
  ///
  /// Usage:
  /// ```dart
  /// await E2ETestHelpers.scrollUp(tester, offset: 500);
  /// ```
  static Future<void> scrollUp(
    WidgetTester tester, {
    double offset = 500,
  }) async {
    final scrollView = find.byType(SingleChildScrollView).first;
    await tester.drag(scrollView, Offset(0, offset));
    await tester.pumpAndSettle();
  }

  /// Find and tap the save button (ElevatedButton) in a form
  ///
  /// Automatically scrolls to make button visible before tapping.
  ///
  /// Usage:
  /// ```dart
  /// await E2ETestHelpers.tapSaveButton(tester);
  /// ```
  static Future<void> tapSaveButton(WidgetTester tester) async {
    // Scroll down to reveal save button
    await scrollDown(tester);

    final saveButtons = find.byType(ElevatedButton);
    expect(saveButtons, findsWidgets, reason: 'Save button should exist');

    final saveButton = saveButtons.last;
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle(standardSettleDuration);
  }

  // ============================================================================
  // VERIFICATION HELPERS
  // ============================================================================

  /// Verify we're on the main screen (has FAB and bottom nav)
  ///
  /// Usage:
  /// ```dart
  /// E2ETestHelpers.verifyOnMainScreen();
  /// ```
  static void verifyOnMainScreen() {
    final bottomNavBar = find.byType(BottomNavigationBar);
    final fab = find.byType(FloatingActionButton);

    expect(bottomNavBar, findsOneWidget,
        reason: 'Bottom navigation should be visible on main screen');
    expect(fab, findsOneWidget,
        reason: 'FAB should be visible on main screen');
  }

  /// Verify we're on a form screen (has text fields)
  ///
  /// Usage:
  /// ```dart
  /// E2ETestHelpers.verifyOnFormScreen(expectedFieldCount: 4);
  /// ```
  static void verifyOnFormScreen({int? expectedFieldCount}) {
    final textFields = find.byType(TextFormField);
    expect(textFields, findsWidgets, reason: 'Form should have text fields');

    if (expectedFieldCount != null) {
      expect(textFields.evaluate().length, equals(expectedFieldCount),
          reason: 'Form should have $expectedFieldCount fields');
    }
  }

  /// Verify a recipe exists in the database by name
  ///
  /// Returns the recipe ID if found, null otherwise.
  ///
  /// Usage:
  /// ```dart
  /// final recipeId = await E2ETestHelpers.verifyRecipeInDatabase(
  ///   dbHelper,
  ///   'Test Recipe'
  /// );
  /// expect(recipeId, isNotNull);
  /// ```
  static Future<String?> verifyRecipeInDatabase(
    DatabaseHelper dbHelper,
    String recipeName,
  ) async {
    final recipes = await dbHelper.getAllRecipes();
    final matchingRecipes = recipes.where((r) => r.name == recipeName).toList();

    expect(matchingRecipes.length, lessThanOrEqualTo(1),
        reason: 'Should have at most one recipe with name $recipeName');

    return matchingRecipes.isEmpty ? null : matchingRecipes.first.id;
  }

  /// Verify a recipe appears in the UI list
  ///
  /// May require scrolling to find the recipe.
  ///
  /// Usage:
  /// ```dart
  /// final found = await E2ETestHelpers.verifyRecipeInUI(
  ///   tester,
  ///   'Test Recipe'
  /// );
  /// ```
  static Future<bool> verifyRecipeInUI(
    WidgetTester tester,
    String recipeName,
  ) async {
    // Try to find recipe in current view
    var recipeFinder = find.text(recipeName);
    if (recipeFinder.evaluate().isNotEmpty) {
      return true;
    }

    // Try scrolling down to find it
    final listView = find.byType(ListView);
    if (listView.evaluate().isNotEmpty) {
      await tester.drag(listView, const Offset(0, -200));
      await tester.pumpAndSettle();

      recipeFinder = find.text(recipeName);
      return recipeFinder.evaluate().isNotEmpty;
    }

    return false;
  }

  // ============================================================================
  // CLEANUP HELPERS
  // ============================================================================

  /// Delete a test recipe from the database
  ///
  /// Usage:
  /// ```dart
  /// await E2ETestHelpers.deleteTestRecipe(dbHelper, recipeId);
  /// ```
  static Future<void> deleteTestRecipe(
    DatabaseHelper dbHelper,
    String recipeId,
  ) async {
    try {
      await dbHelper.deleteRecipe(recipeId);
    } catch (e) {
      // Ignore errors during cleanup
      print('⚠ Error cleaning up test recipe $recipeId: $e');
    }
  }

  // ============================================================================
  // DIAGNOSTIC HELPERS
  // ============================================================================

  /// Print current screen state for debugging
  ///
  /// Usage:
  /// ```dart
  /// E2ETestHelpers.printScreenState('After save button tap');
  /// ```
  static void printScreenState(String label) {
    print('\n=== $label ===');
    print('AppBars: ${find.byType(AppBar).evaluate().length}');
    print('FABs: ${find.byType(FloatingActionButton).evaluate().length}');
    print('TextFormFields: ${find.byType(TextFormField).evaluate().length}');
    print('BottomNavBars: ${find.byType(BottomNavigationBar).evaluate().length}');
  }

  /// Wait for async operations to complete
  ///
  /// Useful after save operations or navigation.
  ///
  /// Usage:
  /// ```dart
  /// await E2ETestHelpers.waitForAsyncOperations();
  /// ```
  static Future<void> waitForAsyncOperations({
    Duration duration = const Duration(seconds: 2),
  }) async {
    await Future.delayed(duration);
  }
}
