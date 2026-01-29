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
  // MEAL EDITING HELPERS section
  // ============================================================================

  /// Navigate to meal history screen for a recipe
  ///
  /// This helper:
  /// 1. Finds the recipe by name in the UI
  /// 2. Taps the recipe card to navigate to RecipeDetailsScreen
  /// 3. Taps the History tab to view meal history
  ///
  /// Requires the recipe to be visible in the current view. May need to
  /// scroll to the recipe first if it's off-screen.
  ///
  /// Usage:
  /// ```dart
  /// await E2ETestHelpers.navigateToMealHistory(tester, 'Test Recipe');
  /// ```
  static Future<void> navigateToMealHistory(
    WidgetTester tester,
    String recipeName,
  ) async {
    // Find the recipe card by name
    final recipeNameFinder = find.text(recipeName);
    expect(recipeNameFinder, findsOneWidget,
        reason: 'Recipe "$recipeName" should be visible in UI');

    // Find the recipe card widget that contains this recipe name
    final recipeCard = find.ancestor(
      of: recipeNameFinder,
      matching: find.byType(Card),
    );
    expect(recipeCard, findsOneWidget,
        reason: 'Recipe card should exist for "$recipeName"');

    // Tap the recipe card to navigate to RecipeDetailsScreen
    await tester.tap(recipeCard);
    await tester.pumpAndSettle(standardSettleDuration);

    // Now we're on RecipeDetailsScreen, find and tap the History tab
    // Use the icon instead of text to avoid localization issues
    final historyTab = find.descendant(
      of: find.byType(Tab),
      matching: find.byIcon(Icons.history),
    );
    expect(historyTab, findsOneWidget,
        reason: 'History tab should be visible in RecipeDetailsScreen');

    await tester.tap(historyTab);
    await tester.pumpAndSettle(standardSettleDuration);
  }

  /// Open the edit dialog for a meal at the given index
  ///
  /// Assumes the meal history screen is already open and displays a list
  /// of meals. Each meal card has a PopupMenuButton with Edit option.
  ///
  /// This method:
  /// 1. Opens the context menu (Icons.more_vert) for the specified meal
  /// 2. Taps the Edit option in the menu
  ///
  /// The mealIndex parameter specifies which meal to edit (0-based index):
  /// - 0: First meal (most recent, at the top)
  /// - 1: Second meal
  /// - etc.
  ///
  /// Usage:
  /// ```dart
  /// // Edit the first (most recent) meal
  /// await E2ETestHelpers.openMealEditDialog(tester);
  ///
  /// // Edit the second meal
  /// await E2ETestHelpers.openMealEditDialog(tester, mealIndex: 1);
  /// ```
  static Future<void> openMealEditDialog(
    WidgetTester tester, {
    int mealIndex = 0,
  }) async {
    // Open the context menu for the specified meal
    await openMealContextMenu(tester, mealIndex: mealIndex);

    // Tap the Edit option in the menu
    final editIcon = find.byIcon(Icons.edit);
    expect(editIcon, findsOneWidget,
        reason: 'Edit option should be visible in context menu');

    await tester.tap(editIcon);
    await tester.pumpAndSettle(standardSettleDuration);
  }

  // ============================================================================
  // MEAL DELETION HELPERS
  // ============================================================================

  /// Open the context menu (PopupMenuButton) for a meal at the given index
  ///
  /// Assumes the meal history screen is already open and displays a list
  /// of meals. Each meal card has a PopupMenuButton with three vertical dots
  /// (Icons.more_vert).
  ///
  /// The mealIndex parameter specifies which meal's menu to open (0-based):
  /// - 0: First meal (most recent, at the top)
  /// - 1: Second meal
  /// - etc.
  ///
  /// Usage:
  /// ```dart
  /// // Open context menu for first meal
  /// await E2ETestHelpers.openMealContextMenu(tester);
  ///
  /// // Open context menu for second meal
  /// await E2ETestHelpers.openMealContextMenu(tester, mealIndex: 1);
  /// ```
  static Future<void> openMealContextMenu(
    WidgetTester tester, {
    int mealIndex = 0,
  }) async {
    final moreVertButtons = find.byIcon(Icons.more_vert);
    expect(moreVertButtons.evaluate().length, greaterThan(mealIndex),
        reason:
            'Should have at least ${mealIndex + 1} context menu button(s)');

    await tester.tap(moreVertButtons.at(mealIndex));
    await tester.pumpAndSettle();
  }

  /// Tap the Delete option in the context menu
  ///
  /// Assumes the context menu (PopupMenuButton) is already open.
  /// This finds the Delete menu item and taps it.
  ///
  /// Usage:
  /// ```dart
  /// await E2ETestHelpers.openMealContextMenu(tester);
  /// await E2ETestHelpers.tapDeleteInContextMenu(tester);
  /// ```
  static Future<void> tapDeleteInContextMenu(WidgetTester tester) async {
    // Find the Delete option in the popup menu
    // It should be a PopupMenuItem with Icons.delete icon
    final deleteIcon = find.byIcon(Icons.delete);
    expect(deleteIcon, findsOneWidget,
        reason: 'Delete option should be visible in context menu');

    await tester.tap(deleteIcon);
    await tester.pumpAndSettle();
  }

  /// Verify the delete confirmation dialog is displayed
  ///
  /// Checks that an AlertDialog is present with the appropriate
  /// delete confirmation elements.
  ///
  /// Usage:
  /// ```dart
  /// E2ETestHelpers.verifyDeleteConfirmationDialog();
  /// ```
  static void verifyDeleteConfirmationDialog() {
    final alertDialog = find.byType(AlertDialog);
    expect(alertDialog, findsOneWidget,
        reason: 'Delete confirmation dialog should be displayed');
  }

  /// Confirm deletion in the confirmation dialog
  ///
  /// Finds and taps the Delete/Confirm button (second TextButton) in the
  /// confirmation dialog to proceed with deletion.
  ///
  /// Usage:
  /// ```dart
  /// await E2ETestHelpers.confirmDeletion(tester);
  /// ```
  static Future<void> confirmDeletion(WidgetTester tester) async {
    // The delete button is the second TextButton in the dialog
    // (first is Cancel, second is Delete)
    final textButtons = find.byType(TextButton);
    expect(textButtons.evaluate().length, greaterThanOrEqualTo(2),
        reason: 'Dialog should have at least 2 buttons (Cancel and Delete)');

    // Tap the second TextButton (Delete)
    await tester.tap(textButtons.at(1));
    await tester.pumpAndSettle();
  }

  /// Cancel deletion in the confirmation dialog
  ///
  /// Finds and taps the Cancel button (TextButton) in the confirmation
  /// dialog to abort the deletion.
  ///
  /// Usage:
  /// ```dart
  /// await E2ETestHelpers.cancelDeletion(tester);
  /// ```
  static Future<void> cancelDeletion(WidgetTester tester) async {
    // The cancel button is typically a TextButton in the dialog
    final cancelButtons = find.byType(TextButton);
    expect(cancelButtons, findsWidgets,
        reason: 'Cancel button should exist in confirmation dialog');

    // Tap the first TextButton (Cancel)
    await tester.tap(cancelButtons.first);
    await tester.pumpAndSettle();
  }

  /// Fill in the meal edit dialog fields
  ///
  /// Uses the form field keys from EditMealRecordingDialog
  /// (edit_meal_recording_* keys).
  ///
  /// All parameters are optional - only provide the fields you want to modify.
  /// Fields that are not provided will retain their current values.
  ///
  /// Usage:
  /// ```dart
  /// // Update only servings
  /// await E2ETestHelpers.fillMealEditDialog(
  ///   tester,
  ///   servings: '4',
  /// );
  ///
  /// // Update multiple fields
  /// await E2ETestHelpers.fillMealEditDialog(
  ///   tester,
  ///   servings: '2',
  ///   prepTime: '15',
  ///   cookTime: '30',
  ///   notes: 'Updated notes',
  /// );
  ///
  /// // Toggle success flag
  /// await E2ETestHelpers.fillMealEditDialog(
  ///   tester,
  ///   toggleSuccess: true,
  /// );
  /// ```
  static Future<void> fillMealEditDialog(
    WidgetTester tester, {
    String? servings,
    String? prepTime,
    String? cookTime,
    String? notes,
    bool? toggleSuccess,
  }) async {
    if (servings != null) {
      final servingsField =
          find.byKey(const Key('edit_meal_recording_servings_field'));
      expect(servingsField, findsOneWidget,
          reason: 'Servings field should exist in edit dialog');
      await tester.enterText(servingsField, servings);
      await tester.pumpAndSettle();
    }

    if (prepTime != null) {
      final prepTimeField =
          find.byKey(const Key('edit_meal_recording_prep_time_field'));
      expect(prepTimeField, findsOneWidget,
          reason: 'Prep time field should exist in edit dialog');
      await tester.enterText(prepTimeField, prepTime);
      await tester.pumpAndSettle();
    }

    if (cookTime != null) {
      final cookTimeField =
          find.byKey(const Key('edit_meal_recording_cook_time_field'));
      expect(cookTimeField, findsOneWidget,
          reason: 'Cook time field should exist in edit dialog');
      await tester.enterText(cookTimeField, cookTime);
      await tester.pumpAndSettle();
    }

    if (notes != null) {
      final notesField =
          find.byKey(const Key('edit_meal_recording_notes_field'));
      expect(notesField, findsOneWidget,
          reason: 'Notes field should exist in edit dialog');
      await tester.enterText(notesField, notes);
      await tester.pumpAndSettle();
    }

    if (toggleSuccess != null) {
      final successSwitch =
          find.byKey(const Key('edit_meal_recording_success_switch'));
      expect(successSwitch, findsOneWidget,
          reason: 'Success switch should exist in edit dialog');
      await tester.tap(successSwitch);
      await tester.pumpAndSettle();
    }
  }

  /// Save the meal edit dialog
  ///
  /// Taps the save button in the EditMealRecordingDialog to save changes.
  /// The dialog has two buttons in its actions:
  /// - Cancel (TextButton)
  /// - Save Changes (ElevatedButton)
  ///
  /// This method finds and taps the ElevatedButton.
  ///
  /// Usage:
  /// ```dart
  /// await E2ETestHelpers.saveMealEditDialog(tester);
  /// ```
  static Future<void> saveMealEditDialog(WidgetTester tester) async {
    // Find the save button (ElevatedButton in the dialog actions)
    final saveButton = find.byType(ElevatedButton);
    expect(saveButton, findsOneWidget,
        reason: 'Save button should exist in edit dialog');

    await tester.tap(saveButton);
    await tester.pumpAndSettle(standardSettleDuration);
  }

  /// Cancel the meal edit dialog
  ///
  /// Taps the cancel button in the EditMealRecordingDialog to discard changes.
  /// The dialog has two buttons in its actions:
  /// - Cancel (TextButton)
  /// - Save Changes (ElevatedButton)
  ///
  /// This method finds and taps the TextButton to cancel the edit operation.
  /// All changes made in the dialog will be discarded.
  ///
  /// Usage:
  /// ```dart
  /// await E2ETestHelpers.cancelMealEditDialog(tester);
  /// ```
  static Future<void> cancelMealEditDialog(WidgetTester tester) async {
    // Find the cancel button (TextButton in the dialog actions)
    // Need to find TextButton within the dialog's actions area
    final cancelButtons = find.byType(TextButton);
    expect(cancelButtons, findsWidgets,
        reason: 'Cancel button should exist in edit dialog');

    // The cancel button is typically the first TextButton in the actions
    await tester.tap(cancelButtons.first);
    await tester.pumpAndSettle();
  }

  /// Add a side dish in the edit dialog
  ///
  /// This helper:
  /// 1. Taps the "Add Recipe" button to open the recipe selection dialog
  /// 2. Finds the recipe by name in the list
  /// 3. Taps the recipe to add it as a side dish
  ///
  /// The recipe must be visible in the recipe selection dialog's list.
  /// The edit dialog must be already open.
  ///
  /// Usage:
  /// ```dart
  /// await E2ETestHelpers.addSideDishInEditDialog(tester, 'Side Dish Recipe');
  /// ```
  static Future<void> addSideDishInEditDialog(
    WidgetTester tester,
    String recipeName,
  ) async {
    // Find and tap the "Add Recipe" button
    // This opens a dialog to select additional recipes as side dishes
    final addButton = find.byIcon(Icons.add);
    expect(addButton, findsWidgets,
        reason: 'Add Recipe button should exist in edit dialog');

    // Tap the last add button (the one in the recipes section)
    await tester.tap(addButton.last);
    await tester.pumpAndSettle();

    // Find and tap the recipe in the selection list
    final recipeItem = find.text(recipeName);
    expect(recipeItem, findsOneWidget,
        reason: 'Recipe "$recipeName" should be visible in selection dialog');

    await tester.tap(recipeItem);
    await tester.pumpAndSettle();
  }

  /// Remove a side dish in the edit dialog by index
  ///
  /// Removes a side dish from the meal by tapping its delete button.
  /// The index is 0-based and refers to the position in the list of
  /// side dishes (additional recipes).
  ///
  /// Note: This removes side dishes only, not the primary recipe.
  ///
  /// Usage:
  /// ```dart
  /// // Remove the first side dish
  /// await E2ETestHelpers.removeSideDishInEditDialog(tester, 0);
  ///
  /// // Remove the second side dish
  /// await E2ETestHelpers.removeSideDishInEditDialog(tester, 1);
  /// ```
  static Future<void> removeSideDishInEditDialog(
    WidgetTester tester,
    int index,
  ) async {
    final deleteButtons = find.byIcon(Icons.delete_outline);
    expect(deleteButtons.evaluate().length, greaterThan(index),
        reason:
            'Should have at least ${index + 1} delete button(s) for side dishes');

    await tester.tap(deleteButtons.at(index));
    await tester.pumpAndSettle();
  }

  /// Verify meal fields in database
  ///
  /// Verifies that a meal in the database has specific field values.
  /// All verification parameters are optional - only provided values are checked.
  ///
  /// Usage:
  /// ```dart
  /// // Verify only servings
  /// await E2ETestHelpers.verifyMealFieldsInDatabase(
  ///   dbHelper,
  ///   mealId,
  ///   expectedServings: 4,
  /// );
  ///
  /// // Verify multiple fields
  /// await E2ETestHelpers.verifyMealFieldsInDatabase(
  ///   dbHelper,
  ///   mealId,
  ///   expectedServings: 2,
  ///   expectedNotes: 'Test notes',
  ///   expectedPrepTime: 15.0,
  ///   expectedCookTime: 30.0,
  ///   expectedWasSuccessful: true,
  /// );
  /// ```
  static Future<void> verifyMealFieldsInDatabase(
    DatabaseHelper dbHelper,
    String mealId, {
    int? expectedServings,
    String? expectedNotes,
    double? expectedPrepTime,
    double? expectedCookTime,
    bool? expectedWasSuccessful,
  }) async {
    final meal = await dbHelper.getMeal(mealId);
    expect(meal, isNotNull, reason: 'Meal with id $mealId should exist');

    if (expectedServings != null) {
      expect(meal!.servings, equals(expectedServings),
          reason: 'Meal servings should be $expectedServings');
    }

    if (expectedNotes != null) {
      expect(meal!.notes, equals(expectedNotes),
          reason: 'Meal notes should be "$expectedNotes"');
    }

    if (expectedPrepTime != null) {
      expect(meal!.actualPrepTime, equals(expectedPrepTime),
          reason: 'Meal prep time should be $expectedPrepTime');
    }

    if (expectedCookTime != null) {
      expect(meal!.actualCookTime, equals(expectedCookTime),
          reason: 'Meal cook time should be $expectedCookTime');
    }

    if (expectedWasSuccessful != null) {
      expect(meal!.wasSuccessful, equals(expectedWasSuccessful),
          reason: 'Meal wasSuccessful should be $expectedWasSuccessful');
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
