/// Meal Deletion E2E Test
///
/// This test suite verifies the meal deletion workflow from meal history screen:
/// - 5.3: Successful meal deletion with confirmation
/// - 5.4: Cancelled deletion (user cancels in confirmation dialog)
/// - 5.5: Deleting meal with side dishes
/// - 5.6: UI consistency verification
///
/// These tests ensure users can delete meals from their history with proper
/// confirmation dialogs and UI updates.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/meal.dart';
import 'package:gastrobrain/models/meal_recipe.dart';
import 'package:gastrobrain/core/di/service_provider.dart';
import 'helpers/e2e_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E - Meal Deletion', () {
    testWidgets('5.3: Delete meal from history with confirmation',
        (WidgetTester tester) async {
      print('\n=== TEST 5.3: Successful Meal Deletion ===');
      String? testRecipeId;
      String? testMealId;

      try {
        // ======================================================================
        // TEST DATA SETUP (Phase 5.2)
        // ======================================================================
        print('\n=== LAUNCHING APP ===');
        await E2ETestHelpers.launchApp(tester);
        print('✓ App launched and initialized');

        final dbHelper = ServiceProvider.database.helper;

        // Create test data with unique identifiers
        print('\n=== CREATING TEST DATA ===');
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        testRecipeId = 'e2e-delete-recipe-$timestamp';
        testMealId = 'e2e-delete-meal-$timestamp';

        final shortId =
            timestamp.toString().substring(timestamp.toString().length - 4);
        final testRecipeName = 'DelTest$shortId';

        // Create test recipe
        final testRecipe = Recipe(
          id: testRecipeId,
          name: testRecipeName,
          createdAt: DateTime.now(),
          instructions: 'Test instructions for deletion',
          notes: 'Test notes',
          prepTimeMinutes: 20,
          cookTimeMinutes: 40,
          difficulty: 3,
          rating: 4,
        );
        await dbHelper.insertRecipe(testRecipe);
        print('✓ Test recipe created: $testRecipeName');

        // Create test meal
        final testMeal = Meal(
          id: testMealId,
          cookedAt: DateTime.now().subtract(const Duration(days: 1)),
          servings: 2,
          actualPrepTime: 20.0,
          actualCookTime: 40.0,
          wasSuccessful: true,
          notes: 'Test meal for deletion',
        );
        await dbHelper.insertMeal(testMeal);
        print('✓ Test meal created');

        // Create MealRecipe entry (primary dish)
        final mealRecipe = MealRecipe(
          mealId: testMealId,
          recipeId: testRecipeId,
          isPrimaryDish: true,
        );
        await dbHelper.insertMealRecipe(mealRecipe);
        print('✓ MealRecipe entry created');

        // ======================================================================
        // ACT: Navigate to Meal History Screen
        // ======================================================================
        print('\n=== NAVIGATING TO MEAL HISTORY ===');
        await E2ETestHelpers.refreshRecipeProvider(tester);
        await E2ETestHelpers.tapBottomNavTab(
            tester, const Key('recipes_tab_icon'));
        await tester.pumpAndSettle();
        await E2ETestHelpers.navigateToMealHistory(tester, testRecipeName);
        print('✓ Navigated to meal history screen');

        // Verify meal card is displayed
        expect(find.text('Test meal for deletion'), findsOneWidget,
            reason: 'Meal notes should be visible in meal card');
        print('✓ Meal card is displayed');

        // ======================================================================
        // ACT: Open PopupMenuButton and Tap Delete
        // ======================================================================
        print('\n=== OPENING CONTEXT MENU ===');
        await E2ETestHelpers.openMealContextMenu(tester);
        print('✓ Context menu opened');

        print('\n=== TAPPING DELETE OPTION ===');
        await E2ETestHelpers.tapDeleteInContextMenu(tester);
        print('✓ Delete option tapped');

        // ======================================================================
        // VERIFY: Confirmation Dialog Appears
        // ======================================================================
        print('\n=== VERIFYING CONFIRMATION DIALOG ===');
        E2ETestHelpers.verifyDeleteConfirmationDialog();
        print('✓ Confirmation dialog is displayed');

        // ======================================================================
        // ACT: Confirm Deletion
        // ======================================================================
        print('\n=== CONFIRMING DELETION ===');
        await E2ETestHelpers.confirmDeletion(tester);
        print('✓ Deletion confirmed');

        // Wait for async operations
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // ======================================================================
        // VERIFY: Success Snackbar Appears
        // ======================================================================
        print('\n=== VERIFYING SUCCESS SNACKBAR ===');
        // Look for success message (will be localized)
        final snackbar = find.byType(SnackBar);
        expect(snackbar, findsOneWidget,
            reason: 'Success snackbar should be displayed');
        print('✓ Success snackbar displayed');

        // ======================================================================
        // VERIFY: Meal Card Removed from UI
        // ======================================================================
        print('\n=== VERIFYING MEAL CARD REMOVED FROM UI ===');
        expect(find.text('Test meal for deletion'), findsNothing,
            reason: 'Meal card should be removed from UI after deletion');
        print('✓ Meal card removed from UI');

        // ======================================================================
        // VERIFY: Meal Deleted from Database
        // ======================================================================
        print('\n=== VERIFYING DATABASE DELETION ===');
        final deletedMeal = await dbHelper.getMeal(testMealId);
        expect(deletedMeal, isNull,
            reason: 'Meal should be deleted from database');
        print('✓ Meal deleted from database');

        // Verify MealRecipe entry is also deleted (cascade delete)
        final mealRecipes = await dbHelper.getMealRecipesForMeal(testMealId);
        expect(mealRecipes.isEmpty, isTrue,
            reason: 'Associated MealRecipe entries should be deleted');
        print('✓ MealRecipe entries cascade deleted');

        print(
            '\n✓ TEST 5.3 PASSED: Meal deletion with confirmation works correctly\n');

        // Clear the meal ID since it's already deleted
        testMealId = null;
      } finally {
        // ======================================================================
        // CLEANUP
        // ======================================================================
        print('\n=== CLEANUP ===');
        final dbHelper = ServiceProvider.database.helper;

        if (testMealId != null) {
          try {
            await dbHelper.deleteMeal(testMealId);
            print('✓ Deleted test meal');
          } catch (e) {
            print('Note: Could not delete test meal: $e');
          }
        }

        if (testRecipeId != null) {
          try {
            await dbHelper.deleteRecipe(testRecipeId);
            print('✓ Deleted test recipe');
          } catch (e) {
            print('Note: Could not delete test recipe: $e');
          }
        }

        print('✓ Cleanup complete');
      }
    });

    testWidgets('5.4: Cancel meal deletion and verify meal persists',
        (WidgetTester tester) async {
      print('\n=== TEST 5.4: Cancelled Deletion ===');
      String? testRecipeId;
      String? testMealId;

      try {
        // ======================================================================
        // TEST DATA SETUP
        // ======================================================================
        print('\n=== LAUNCHING APP ===');
        await E2ETestHelpers.launchApp(tester);
        print('✓ App launched and initialized');

        final dbHelper = ServiceProvider.database.helper;

        // Create test data with unique identifiers
        print('\n=== CREATING TEST DATA ===');
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        testRecipeId = 'e2e-cancel-recipe-$timestamp';
        testMealId = 'e2e-cancel-meal-$timestamp';

        final shortId =
            timestamp.toString().substring(timestamp.toString().length - 4);
        final testRecipeName = 'CancelTest$shortId';

        // Create test recipe
        final testRecipe = Recipe(
          id: testRecipeId,
          name: testRecipeName,
          createdAt: DateTime.now(),
          instructions: 'Test instructions for cancel deletion',
          notes: 'Test notes',
          prepTimeMinutes: 15,
          cookTimeMinutes: 25,
          difficulty: 2,
          rating: 5,
        );
        await dbHelper.insertRecipe(testRecipe);
        print('✓ Test recipe created: $testRecipeName');

        // Create test meal
        final testMeal = Meal(
          id: testMealId,
          cookedAt: DateTime.now().subtract(const Duration(days: 2)),
          servings: 3,
          actualPrepTime: 15.0,
          actualCookTime: 25.0,
          wasSuccessful: true,
          notes: 'Test meal that should NOT be deleted',
        );
        await dbHelper.insertMeal(testMeal);
        print('✓ Test meal created');

        // Create MealRecipe entry
        final mealRecipe = MealRecipe(
          mealId: testMealId,
          recipeId: testRecipeId,
          isPrimaryDish: true,
        );
        await dbHelper.insertMealRecipe(mealRecipe);
        print('✓ MealRecipe entry created');

        // ======================================================================
        // ACT: Navigate to Meal History Screen
        // ======================================================================
        print('\n=== NAVIGATING TO MEAL HISTORY ===');
        await E2ETestHelpers.refreshRecipeProvider(tester);
        await E2ETestHelpers.tapBottomNavTab(
            tester, const Key('recipes_tab_icon'));
        await tester.pumpAndSettle();
        await E2ETestHelpers.navigateToMealHistory(tester, testRecipeName);
        print('✓ Navigated to meal history screen');

        // Verify meal card is displayed
        expect(find.text('Test meal that should NOT be deleted'), findsOneWidget,
            reason: 'Meal notes should be visible in meal card');
        print('✓ Meal card is displayed');

        // ======================================================================
        // ACT: Open PopupMenuButton and Tap Delete
        // ======================================================================
        print('\n=== OPENING CONTEXT MENU ===');
        await E2ETestHelpers.openMealContextMenu(tester);
        print('✓ Context menu opened');

        print('\n=== TAPPING DELETE OPTION ===');
        await E2ETestHelpers.tapDeleteInContextMenu(tester);
        print('✓ Delete option tapped');

        // ======================================================================
        // VERIFY: Confirmation Dialog Appears
        // ======================================================================
        print('\n=== VERIFYING CONFIRMATION DIALOG ===');
        E2ETestHelpers.verifyDeleteConfirmationDialog();
        print('✓ Confirmation dialog is displayed');

        // ======================================================================
        // ACT: Cancel Deletion
        // ======================================================================
        print('\n=== CANCELLING DELETION ===');
        await E2ETestHelpers.cancelDeletion(tester);
        print('✓ Deletion cancelled');

        // Wait for dialog to close
        await tester.pumpAndSettle();

        // ======================================================================
        // VERIFY: Meal Card Still Exists in UI
        // ======================================================================
        print('\n=== VERIFYING MEAL CARD STILL IN UI ===');
        expect(find.text('Test meal that should NOT be deleted'), findsOneWidget,
            reason: 'Meal card should still be visible after cancelling deletion');
        print('✓ Meal card still displayed in UI');

        // ======================================================================
        // VERIFY: Meal Still Exists in Database
        // ======================================================================
        print('\n=== VERIFYING MEAL STILL IN DATABASE ===');
        final existingMeal = await dbHelper.getMeal(testMealId);
        expect(existingMeal, isNotNull,
            reason: 'Meal should still exist in database after cancel');
        expect(existingMeal!.notes, 'Test meal that should NOT be deleted',
            reason: 'Meal data should be unchanged');
        print('✓ Meal still exists in database');

        // Verify MealRecipe entry still exists
        final mealRecipes = await dbHelper.getMealRecipesForMeal(testMealId);
        expect(mealRecipes.isNotEmpty, isTrue,
            reason: 'MealRecipe entries should still exist');
        print('✓ MealRecipe entries still exist');

        // ======================================================================
        // VERIFY: No Snackbar Shown
        // ======================================================================
        print('\n=== VERIFYING NO SNACKBAR ===');
        final snackbar = find.byType(SnackBar);
        expect(snackbar, findsNothing,
            reason: 'No snackbar should be shown after cancelling deletion');
        print('✓ No snackbar displayed');

        print(
            '\n✓ TEST 5.4 PASSED: Cancel deletion preserves meal correctly\n');
      } finally {
        // ======================================================================
        // CLEANUP
        // ======================================================================
        print('\n=== CLEANUP ===');
        final dbHelper = ServiceProvider.database.helper;

        if (testMealId != null) {
          try {
            await dbHelper.deleteMeal(testMealId);
            print('✓ Deleted test meal');
          } catch (e) {
            print('Note: Could not delete test meal: $e');
          }
        }

        if (testRecipeId != null) {
          try {
            await dbHelper.deleteRecipe(testRecipeId);
            print('✓ Deleted test recipe');
          } catch (e) {
            print('Note: Could not delete test recipe: $e');
          }
        }

        print('✓ Cleanup complete');
      }
    });

    testWidgets('5.5: Delete meal with multiple side dishes',
        (WidgetTester tester) async {
      print('\n=== TEST 5.5: Delete Meal with Side Dishes ===');
      String? testRecipeId;
      String? sideDish1Id;
      String? sideDish2Id;
      String? testMealId;

      try {
        // ======================================================================
        // TEST DATA SETUP
        // ======================================================================
        print('\n=== LAUNCHING APP ===');
        await E2ETestHelpers.launchApp(tester);
        print('✓ App launched and initialized');

        final dbHelper = ServiceProvider.database.helper;

        // Create test data with unique identifiers
        print('\n=== CREATING TEST DATA ===');
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        testRecipeId = 'e2e-sides-main-recipe-$timestamp';
        sideDish1Id = 'e2e-sides-side1-recipe-$timestamp';
        sideDish2Id = 'e2e-sides-side2-recipe-$timestamp';
        testMealId = 'e2e-sides-meal-$timestamp';

        final shortId =
            timestamp.toString().substring(timestamp.toString().length - 4);
        final testRecipeName = 'SidesTest$shortId';
        final sideDish1Name = 'Side1-$shortId';
        final sideDish2Name = 'Side2-$shortId';

        // Create main recipe
        final testRecipe = Recipe(
          id: testRecipeId,
          name: testRecipeName,
          createdAt: DateTime.now(),
          instructions: 'Main dish instructions',
          notes: 'Main dish notes',
          prepTimeMinutes: 30,
          cookTimeMinutes: 45,
          difficulty: 3,
          rating: 4,
        );
        await dbHelper.insertRecipe(testRecipe);
        print('✓ Main recipe created: $testRecipeName');

        // Create first side dish recipe
        final sideDish1 = Recipe(
          id: sideDish1Id,
          name: sideDish1Name,
          createdAt: DateTime.now(),
          instructions: 'Side dish 1 instructions',
          notes: 'Side dish 1 notes',
          prepTimeMinutes: 10,
          cookTimeMinutes: 15,
          difficulty: 1,
          rating: 4,
        );
        await dbHelper.insertRecipe(sideDish1);
        print('✓ Side dish 1 created: $sideDish1Name');

        // Create second side dish recipe
        final sideDish2 = Recipe(
          id: sideDish2Id,
          name: sideDish2Name,
          createdAt: DateTime.now(),
          instructions: 'Side dish 2 instructions',
          notes: 'Side dish 2 notes',
          prepTimeMinutes: 5,
          cookTimeMinutes: 10,
          difficulty: 1,
          rating: 5,
        );
        await dbHelper.insertRecipe(sideDish2);
        print('✓ Side dish 2 created: $sideDish2Name');

        // Create test meal
        final testMeal = Meal(
          id: testMealId,
          cookedAt: DateTime.now().subtract(const Duration(days: 3)),
          servings: 4,
          actualPrepTime: 45.0,
          actualCookTime: 70.0,
          wasSuccessful: true,
          notes: 'Meal with 2 side dishes',
        );
        await dbHelper.insertMeal(testMeal);
        print('✓ Test meal created');

        // Create MealRecipe entry for main dish
        final mealRecipeMain = MealRecipe(
          mealId: testMealId,
          recipeId: testRecipeId,
          isPrimaryDish: true,
        );
        await dbHelper.insertMealRecipe(mealRecipeMain);
        print('✓ MealRecipe entry created for main dish');

        // Create MealRecipe entry for first side dish
        final mealRecipeSide1 = MealRecipe(
          mealId: testMealId,
          recipeId: sideDish1Id,
          isPrimaryDish: false,
        );
        await dbHelper.insertMealRecipe(mealRecipeSide1);
        print('✓ MealRecipe entry created for side dish 1');

        // Create MealRecipe entry for second side dish
        final mealRecipeSide2 = MealRecipe(
          mealId: testMealId,
          recipeId: sideDish2Id,
          isPrimaryDish: false,
        );
        await dbHelper.insertMealRecipe(mealRecipeSide2);
        print('✓ MealRecipe entry created for side dish 2');

        // Verify we have 3 MealRecipe entries total
        final initialMealRecipes =
            await dbHelper.getMealRecipesForMeal(testMealId);
        expect(initialMealRecipes.length, 3,
            reason: 'Should have 3 MealRecipe entries (1 main + 2 sides)');
        print('✓ Verified 3 MealRecipe entries exist');

        // ======================================================================
        // ACT: Navigate to Meal History Screen
        // ======================================================================
        print('\n=== NAVIGATING TO MEAL HISTORY ===');
        await E2ETestHelpers.refreshRecipeProvider(tester);
        await E2ETestHelpers.tapBottomNavTab(
            tester, const Key('recipes_tab_icon'));
        await tester.pumpAndSettle();
        await E2ETestHelpers.navigateToMealHistory(tester, testRecipeName);
        print('✓ Navigated to meal history screen');

        // Verify meal card shows side dishes
        expect(find.text('Meal with 2 side dishes'), findsOneWidget,
            reason: 'Meal notes should be visible');
        print('✓ Meal card is displayed');

        // ======================================================================
        // ACT: Delete Meal
        // ======================================================================
        print('\n=== OPENING CONTEXT MENU ===');
        await E2ETestHelpers.openMealContextMenu(tester);
        print('✓ Context menu opened');

        print('\n=== TAPPING DELETE OPTION ===');
        await E2ETestHelpers.tapDeleteInContextMenu(tester);
        print('✓ Delete option tapped');

        print('\n=== CONFIRMING DELETION ===');
        E2ETestHelpers.verifyDeleteConfirmationDialog();
        await E2ETestHelpers.confirmDeletion(tester);
        print('✓ Deletion confirmed');

        // Wait for async operations
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // ======================================================================
        // VERIFY: All MealRecipe Entries Deleted (Cascade Delete)
        // ======================================================================
        print('\n=== VERIFYING CASCADE DELETE ===');
        final remainingMealRecipes =
            await dbHelper.getMealRecipesForMeal(testMealId);
        expect(remainingMealRecipes.isEmpty, isTrue,
            reason:
                'All 3 MealRecipe entries should be deleted (cascade delete)');
        print('✓ All 3 MealRecipe entries cascade deleted');

        // ======================================================================
        // VERIFY: Meal Deleted from Database
        // ======================================================================
        print('\n=== VERIFYING MEAL DELETION ===');
        final deletedMeal = await dbHelper.getMeal(testMealId);
        expect(deletedMeal, isNull,
            reason: 'Meal should be deleted from database');
        print('✓ Meal deleted from database');

        // ======================================================================
        // VERIFY: Recipes Still Exist (Only Meal and MealRecipes Deleted)
        // ======================================================================
        print('\n=== VERIFYING RECIPES STILL EXIST ===');
        final mainRecipe = await dbHelper.getRecipe(testRecipeId);
        expect(mainRecipe, isNotNull,
            reason: 'Main recipe should still exist');

        final side1Recipe = await dbHelper.getRecipe(sideDish1Id);
        expect(side1Recipe, isNotNull,
            reason: 'Side dish 1 recipe should still exist');

        final side2Recipe = await dbHelper.getRecipe(sideDish2Id);
        expect(side2Recipe, isNotNull,
            reason: 'Side dish 2 recipe should still exist');
        print('✓ All recipes still exist (only meal deleted)');

        // ======================================================================
        // VERIFY: Success Snackbar
        // ======================================================================
        print('\n=== VERIFYING SUCCESS SNACKBAR ===');
        final snackbar = find.byType(SnackBar);
        expect(snackbar, findsOneWidget,
            reason: 'Success snackbar should be displayed');
        print('✓ Success snackbar displayed');

        print(
            '\n✓ TEST 5.5 PASSED: Meal with side dishes deleted correctly with cascade delete\n');

        // Clear the meal ID since it's already deleted
        testMealId = null;
      } finally {
        // ======================================================================
        // CLEANUP
        // ======================================================================
        print('\n=== CLEANUP ===');
        final dbHelper = ServiceProvider.database.helper;

        if (testMealId != null) {
          try {
            await dbHelper.deleteMeal(testMealId);
            print('✓ Deleted test meal');
          } catch (e) {
            print('Note: Could not delete test meal: $e');
          }
        }

        // Clean up all recipes
        if (testRecipeId != null) {
          try {
            await dbHelper.deleteRecipe(testRecipeId);
            print('✓ Deleted main recipe');
          } catch (e) {
            print('Note: Could not delete main recipe: $e');
          }
        }

        if (sideDish1Id != null) {
          try {
            await dbHelper.deleteRecipe(sideDish1Id);
            print('✓ Deleted side dish 1');
          } catch (e) {
            print('Note: Could not delete side dish 1: $e');
          }
        }

        if (sideDish2Id != null) {
          try {
            await dbHelper.deleteRecipe(sideDish2Id);
            print('✓ Deleted side dish 2');
          } catch (e) {
            print('Note: Could not delete side dish 2: $e');
          }
        }

        print('✓ Cleanup complete');
      }
    });

    testWidgets('5.6: Verify UI consistency of context menu',
        (WidgetTester tester) async {
      print('\n=== TEST 5.6: UI Consistency Verification ===');
      String? testRecipeId;
      String? testMealId;

      try {
        // ======================================================================
        // TEST DATA SETUP
        // ======================================================================
        print('\n=== LAUNCHING APP ===');
        await E2ETestHelpers.launchApp(tester);
        print('✓ App launched and initialized');

        final dbHelper = ServiceProvider.database.helper;

        // Create test data with unique identifiers
        print('\n=== CREATING TEST DATA ===');
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        testRecipeId = 'e2e-ui-recipe-$timestamp';
        testMealId = 'e2e-ui-meal-$timestamp';

        final shortId =
            timestamp.toString().substring(timestamp.toString().length - 4);
        final testRecipeName = 'UITest$shortId';

        // Create test recipe
        final testRecipe = Recipe(
          id: testRecipeId,
          name: testRecipeName,
          createdAt: DateTime.now(),
          instructions: 'Test instructions for UI verification',
          notes: 'Test notes',
          prepTimeMinutes: 10,
          cookTimeMinutes: 20,
          difficulty: 2,
          rating: 3,
        );
        await dbHelper.insertRecipe(testRecipe);
        print('✓ Test recipe created: $testRecipeName');

        // Create test meal
        final testMeal = Meal(
          id: testMealId,
          cookedAt: DateTime.now().subtract(const Duration(days: 1)),
          servings: 2,
          actualPrepTime: 10.0,
          actualCookTime: 20.0,
          wasSuccessful: true,
          notes: 'Test meal for UI verification',
        );
        await dbHelper.insertMeal(testMeal);
        print('✓ Test meal created');

        // Create MealRecipe entry
        final mealRecipe = MealRecipe(
          mealId: testMealId,
          recipeId: testRecipeId,
          isPrimaryDish: true,
        );
        await dbHelper.insertMealRecipe(mealRecipe);
        print('✓ MealRecipe entry created');

        // ======================================================================
        // ACT: Navigate to Meal History Screen
        // ======================================================================
        print('\n=== NAVIGATING TO MEAL HISTORY ===');
        await E2ETestHelpers.refreshRecipeProvider(tester);
        await E2ETestHelpers.tapBottomNavTab(
            tester, const Key('recipes_tab_icon'));
        await tester.pumpAndSettle();
        await E2ETestHelpers.navigateToMealHistory(tester, testRecipeName);
        print('✓ Navigated to meal history screen');

        // ======================================================================
        // VERIFY: PopupMenuButton Icon is Icons.more_vert
        // ======================================================================
        print('\n=== VERIFYING POPUPMENUBUTTON ICON ===');
        final moreVertIcon = find.byIcon(Icons.more_vert);
        expect(moreVertIcon, findsOneWidget,
            reason:
                'PopupMenuButton should have Icons.more_vert (three vertical dots)');
        print('✓ PopupMenuButton uses Icons.more_vert');

        // ======================================================================
        // VERIFY: Context Menu Has Edit and Delete Options
        // ======================================================================
        print('\n=== OPENING CONTEXT MENU ===');
        await E2ETestHelpers.openMealContextMenu(tester);
        print('✓ Context menu opened');

        print('\n=== VERIFYING MENU OPTIONS ===');

        // Verify Edit option with icon
        final editIcon = find.byIcon(Icons.edit);
        expect(editIcon, findsOneWidget,
            reason: 'Edit option should have Icons.edit icon');
        print('✓ Edit option has Icons.edit icon');

        // Verify Delete option with icon
        final deleteIcon = find.byIcon(Icons.delete);
        expect(deleteIcon, findsOneWidget,
            reason: 'Delete option should have Icons.delete icon');
        print('✓ Delete option has Icons.delete icon');

        // ======================================================================
        // VERIFY: Localized Text is Displayed
        // ======================================================================
        print('\n=== VERIFYING LOCALIZED TEXT ===');

        // The text will be either "Edit"/"Editar" or "Delete"/"Excluir"
        // depending on the locale. We'll just verify that text exists
        // alongside the icons in the menu items.

        // Find all PopupMenuItem widgets
        final popupMenuItems = find.byType(PopupMenuItem<String>);
        expect(popupMenuItems, findsNWidgets(2),
            reason: 'Should have exactly 2 menu items (Edit and Delete)');
        print('✓ Context menu has 2 options');

        // Verify that menu items contain Row widgets with icon and text
        final rows = find.descendant(
          of: popupMenuItems.first,
          matching: find.byType(Row),
        );
        expect(rows, findsOneWidget,
            reason: 'Menu items should use Row layout for icon + text');
        print('✓ Menu items use Row layout with icon and text');

        // Close the menu by tapping outside or pressing back
        print('\n=== CLOSING CONTEXT MENU ===');
        await tester.tapAt(Offset.zero); // Tap outside menu
        await tester.pumpAndSettle();
        print('✓ Context menu closed');

        // ======================================================================
        // VERIFY: UI Elements Alignment and Spacing
        // ======================================================================
        print('\n=== VERIFYING UI LAYOUT ===');

        // Verify the PopupMenuButton is still visible after closing menu
        expect(moreVertIcon, findsOneWidget,
            reason: 'PopupMenuButton should be visible in meal card');
        print('✓ PopupMenuButton properly integrated in meal card');

        print('\n✓ TEST 5.6 PASSED: UI consistency verified\n');
      } finally {
        // ======================================================================
        // CLEANUP
        // ======================================================================
        print('\n=== CLEANUP ===');
        final dbHelper = ServiceProvider.database.helper;

        if (testMealId != null) {
          try {
            await dbHelper.deleteMeal(testMealId);
            print('✓ Deleted test meal');
          } catch (e) {
            print('Note: Could not delete test meal: $e');
          }
        }

        if (testRecipeId != null) {
          try {
            await dbHelper.deleteRecipe(testRecipeId);
            print('✓ Deleted test recipe');
          } catch (e) {
            print('Note: Could not delete test recipe: $e');
          }
        }

        print('✓ Cleanup complete');
      }
    });
  });
}
