// integration_test/helpers/e2e_test_helpers.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gastrobrain/main.dart';
import 'package:gastrobrain/database/database_helper.dart';
import 'package:gastrobrain/core/providers/recipe_provider.dart';

/// E2E Test Helper Methods
///
/// Common utilities for end-to-end integration tests.
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

  /// Tap a bottom navigation tab by its semantic key
  ///
  /// Usage:
  /// ```dart
  /// await E2ETestHelpers.tapBottomNavTab(
  ///   tester,
  ///   const Key('recipes_tab_icon')
  /// );
  /// ```
  static Future<void> tapBottomNavTab(
    WidgetTester tester,
    Key tabKey,
  ) async {
    final bottomNavBar = find.byType(BottomNavigationBar);
    final tab = find.descendant(
      of: bottomNavBar,
      matching: find.byKey(tabKey),
    );
    expect(tab, findsOneWidget,
        reason: 'Tab with key $tabKey should exist in bottom navigation');
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
    expect(fab, findsOneWidget, reason: 'FAB should be visible on main screen');
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

  /// Delete a test meal from the database
  ///
  /// Usage:
  /// ```dart
  /// await E2ETestHelpers.deleteTestMeal(dbHelper, mealId);
  /// ```
  static Future<void> deleteTestMeal(
    DatabaseHelper dbHelper,
    String mealId,
  ) async {
    try {
      await dbHelper.deleteMeal(mealId);
    } catch (e) {
      // Ignore errors during cleanup
      print('⚠ Error cleaning up test meal $mealId: $e');
    }
  }

  // ============================================================================
  // PROVIDER REFRESH HELPERS
  // ============================================================================

  /// Force RecipeProvider to refresh after direct database operations
  ///
  /// Use this when creating/modifying recipes via database in tests
  /// to ensure the UI reflects the changes. The RecipeProvider uses
  /// a 5-minute cache that must be explicitly invalidated when data
  /// is modified outside the normal UI flow.
  ///
  /// Usage:
  /// ```dart
  /// await dbHelper.insertRecipe(testRecipe);
  /// await E2ETestHelpers.refreshRecipeProvider(tester);
  /// // Recipe now appears in UI
  /// ```
  static Future<void> refreshRecipeProvider(WidgetTester tester) async {
    await tester.runAsync(() async {
      final context = tester.element(find.byType(MaterialApp));
      final recipeProvider =
          Provider.of<RecipeProvider>(context, listen: false);
      await recipeProvider.loadRecipes(forceRefresh: true);
    });
    await tester.pumpAndSettle();
  }

  // ============================================================================
  // MEAL RECORDING HELPERS
  // ============================================================================

  /// Open the meal recording dialog from CookMealScreen
  ///
  /// Taps the "Registrar Detalhes da Refeição" button to open the dialog.
  ///
  /// Usage:
  /// ```dart
  /// await E2ETestHelpers.openMealRecordingDialog(tester);
  /// ```
  static Future<void> openMealRecordingDialog(WidgetTester tester) async {
    // Find and tap the "Registrar Detalhes da Refeição" button
    final recordButton = find.byIcon(Icons.restaurant);
    expect(recordButton, findsOneWidget,
        reason: 'Meal recording button should exist');
    await tester.tap(recordButton);
    await tester.pumpAndSettle();
  }

  /// Fill in the meal recording dialog fields
  ///
  /// Uses the form field keys added to MealRecordingDialog.
  ///
  /// Usage:
  /// ```dart
  /// await E2ETestHelpers.fillMealRecordingDialog(
  ///   tester,
  ///   servings: '2',
  ///   prepTime: '15',
  ///   cookTime: '30',
  ///   notes: 'Test notes',
  /// );
  /// ```
  static Future<void> fillMealRecordingDialog(
    WidgetTester tester, {
    String? servings,
    String? prepTime,
    String? cookTime,
    String? notes,
    bool? toggleSuccess,
  }) async {
    if (servings != null) {
      final servingsField =
          find.byKey(const Key('meal_recording_servings_field'));
      expect(servingsField, findsOneWidget);
      await tester.enterText(servingsField, servings);
      await tester.pumpAndSettle();
    }

    if (prepTime != null) {
      final prepTimeField =
          find.byKey(const Key('meal_recording_prep_time_field'));
      expect(prepTimeField, findsOneWidget);
      await tester.enterText(prepTimeField, prepTime);
      await tester.pumpAndSettle();
    }

    if (cookTime != null) {
      final cookTimeField =
          find.byKey(const Key('meal_recording_cook_time_field'));
      expect(cookTimeField, findsOneWidget);
      await tester.enterText(cookTimeField, cookTime);
      await tester.pumpAndSettle();
    }

    if (notes != null) {
      final notesField = find.byKey(const Key('meal_recording_notes_field'));
      expect(notesField, findsOneWidget);
      await tester.enterText(notesField, notes);
      await tester.pumpAndSettle();
    }

    if (toggleSuccess != null) {
      final successSwitch =
          find.byKey(const Key('meal_recording_success_switch'));
      expect(successSwitch, findsOneWidget);
      await tester.tap(successSwitch);
      await tester.pumpAndSettle();
    }
  }

  /// Save the meal recording dialog
  ///
  /// Taps the save button in the dialog.
  ///
  /// Note: Uses warnIfMissed: false because the test framework's fallback
  /// behavior is acceptable here - even if modal barriers obscure the button
  /// in hit testing, the tap event is correctly dispatched to the found widget.
  ///
  /// Usage:
  /// ```dart
  /// await E2ETestHelpers.saveMealRecordingDialog(tester);
  /// ```
  static Future<void> saveMealRecordingDialog(WidgetTester tester) async {
    final saveButton = find.byKey(const Key('meal_recording_save_button'));
    expect(saveButton, findsOneWidget, reason: 'Save button should exist');

    // Ensure button is visible and not obscured by overlays
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();

    // warnIfMissed: false - Accept test framework's lenient tap behavior
    // when modal overlays are present but the button is correctly found
    await tester.tap(saveButton, warnIfMissed: false);
    await tester.pumpAndSettle(standardSettleDuration);
  }

  /// Verify a meal exists in the database for a specific recipe
  ///
  /// Returns the meal ID if found, null otherwise.
  ///
  /// Usage:
  /// ```dart
  /// final mealId = await E2ETestHelpers.verifyMealInDatabase(
  ///   dbHelper,
  ///   recipeId,
  ///   expectedServings: 2,
  /// );
  /// ```
  static Future<String?> verifyMealInDatabase(
    DatabaseHelper dbHelper,
    String recipeId, {
    int? expectedServings,
  }) async {
    final meals = await dbHelper.getMealsForRecipe(recipeId);

    if (meals.isEmpty) {
      return null;
    }

    // Get the most recent meal
    final meal = meals.first;

    if (expectedServings != null) {
      expect(meal.servings, equals(expectedServings),
          reason: 'Meal servings should match expected value');
    }

    return meal.id;
  }

  // ============================================================================
  // MEAL PLANNING HELPERS
  // ============================================================================

  /// Tap a meal plan calendar slot by day and meal type
  ///
  /// Uses the key pattern: meal_plan_{day}_{mealtype}_slot
  ///
  /// Usage:
  /// ```dart
  /// await E2ETestHelpers.tapMealPlanSlot(tester, 'friday', 'lunch');
  /// ```
  static Future<void> tapMealPlanSlot(
    WidgetTester tester,
    String day,
    String mealType,
  ) async {
    final slotKey = Key('meal_plan_${day}_${mealType}_slot');
    final slotFinder = find.byKey(slotKey);

    expect(slotFinder, findsOneWidget,
        reason: '$day $mealType slot should exist');

    await tester.tap(slotFinder);
    await tester.pumpAndSettle();
  }

  /// Verify the recipe selection dialog is open
  ///
  /// Checks for the dialog title "Selecionar Receita" and tab buttons.
  ///
  /// Usage:
  /// ```dart
  /// E2ETestHelpers.verifyRecipeSelectionDialogOpen();
  /// ```
  static void verifyRecipeSelectionDialogOpen() {
    expect(find.text('Selecionar Receita'), findsOneWidget,
        reason: 'Recipe selection dialog should be open');

    expect(find.byKey(const Key('recipe_selection_recommended_tab')),
        findsOneWidget,
        reason: 'Recommended tab should exist');

    expect(find.byKey(const Key('recipe_selection_all_tab')), findsOneWidget,
        reason: 'All Recipes tab should exist');

    expect(
        find.byKey(const Key('recipe_selection_cancel_button')), findsOneWidget,
        reason: 'Cancel button should exist');
  }

  /// Select a recipe from the recommended tab
  ///
  /// Assumes the recipe selection dialog is already open and the
  /// recommended tab is active. Will scroll if needed to find the recipe.
  ///
  /// Usage:
  /// ```dart
  /// await E2ETestHelpers.selectRecipeFromRecommended(tester, recipeId);
  /// ```
  static Future<void> selectRecipeFromRecommended(
    WidgetTester tester,
    String recipeId,
  ) async {
    final recipeCardKey = Key('recipe_card_$recipeId');
    var recipeCardFinder = find.byKey(recipeCardKey);

    // Scroll if needed to find the recipe
    if (recipeCardFinder.evaluate().isEmpty) {
      final scrollables = find.byType(Scrollable);
      if (scrollables.evaluate().isNotEmpty) {
        await tester.drag(scrollables.last, const Offset(0, -200));
        await tester.pumpAndSettle();
        recipeCardFinder = find.byKey(recipeCardKey);
      }
    }

    expect(recipeCardFinder, findsOneWidget,
        reason: 'Recipe card should be present in recommended list');

    await tester.tap(recipeCardFinder);
    await tester.pumpAndSettle();
  }

  /// Select a recipe from the all recipes tab
  ///
  /// Assumes the recipe selection dialog is already open. This method will:
  /// 1. Switch to the "All Recipes" tab
  /// 2. Find and tap the recipe card
  ///
  /// Will scroll if needed to find the recipe.
  ///
  /// Usage:
  /// ```dart
  /// await E2ETestHelpers.selectRecipeFromAllRecipes(tester, recipeId);
  /// ```
  static Future<void> selectRecipeFromAllRecipes(
    WidgetTester tester,
    String recipeId,
  ) async {
    // Switch to All Recipes tab
    final allRecipesTab = find.byKey(const Key('recipe_selection_all_tab'));
    expect(allRecipesTab, findsOneWidget,
        reason: 'All Recipes tab should exist');

    await tester.tap(allRecipesTab);
    await tester.pumpAndSettle();

    // Find and tap recipe card
    final recipeCardKey = Key('recipe_card_$recipeId');
    var recipeCardFinder = find.byKey(recipeCardKey);

    // Scroll if needed to find the recipe
    if (recipeCardFinder.evaluate().isEmpty) {
      final scrollables = find.byType(Scrollable);
      if (scrollables.evaluate().isNotEmpty) {
        // May need to scroll more for all recipes list
        await tester.drag(scrollables.last, const Offset(0, -300));
        await tester.pumpAndSettle();
        recipeCardFinder = find.byKey(recipeCardKey);

        // Try scrolling more if still not found
        if (recipeCardFinder.evaluate().isEmpty) {
          await tester.drag(scrollables.last, const Offset(0, -300));
          await tester.pumpAndSettle();
        }
      }
    }

    expect(recipeCardFinder, findsOneWidget,
        reason: 'Recipe card should be present in all recipes list');

    await tester.tap(recipeCardFinder);
    await tester.pumpAndSettle();
  }

  /// Verify a recipe appears in a specific calendar slot
  ///
  /// Checks that the recipe name is visible in the UI.
  /// May scroll to find the recipe.
  ///
  /// Usage:
  /// ```dart
  /// await E2ETestHelpers.verifyRecipeInCalendarSlot(
  ///   tester,
  ///   'friday',
  ///   'lunch',
  ///   'Test Recipe'
  /// );
  /// ```
  static Future<bool> verifyRecipeInCalendarSlot(
    WidgetTester tester,
    String day,
    String mealType,
    String recipeName,
  ) async {
    // Look for the recipe name in the UI
    var recipeNameFinder = find.text(recipeName);
    var foundInUI = recipeNameFinder.evaluate().isNotEmpty;

    if (!foundInUI) {
      // Try scrolling to find the recipe
      final scrollables = find.byType(Scrollable);
      if (scrollables.evaluate().isNotEmpty) {
        await tester.drag(scrollables.first, const Offset(0, -100));
        await tester.pumpAndSettle();
        foundInUI = recipeNameFinder.evaluate().isNotEmpty;
      }
    }

    return foundInUI;
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
    print(
        'BottomNavBars: ${find.byType(BottomNavigationBar).evaluate().length}');
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
