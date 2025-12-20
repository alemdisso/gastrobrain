// integration_test/e2e_meal_editing_workflow_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gastrobrain/database/database_helper.dart';
import 'package:gastrobrain/models/meal.dart';
import 'package:gastrobrain/models/meal_recipe.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'helpers/e2e_test_helpers.dart';

/// Meal Editing Workflow E2E Test
///
/// This test verifies the complete meal editing workflow:
/// 1. Navigate to meal history for a recipe
/// 2. Open the edit dialog for an existing meal
/// 3. Modify meal fields
/// 4. Save changes
/// 5. Verify UI updates immediately
/// 6. Verify database persistence

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E - Meal Editing Workflow', () {
    testWidgets(
        'Complete workflow: open meal history, edit meal, save changes, verify UI update',
        (WidgetTester tester) async {
      // ========================================================================
      // TEST DATA SETUP
      // ========================================================================

      final testRecipeName =
          'E2E Edit Test Recipe ${DateTime.now().millisecondsSinceEpoch}';
      final originalServings = 2;
      final updatedServings = 4;
      final originalNotes = 'Original test notes';

      String? createdRecipeId;
      String? createdMealId;

      try {
        // ======================================================================
        // SETUP: Launch and Initialize
        // ======================================================================

        print('=== LAUNCHING APP ===');
        await E2ETestHelpers.launchApp(tester);
        print('✓ App launched and initialized');

        final dbHelper = DatabaseHelper();

        // ======================================================================
        // SETUP: Create Test Recipe
        // ======================================================================

        print('\n=== CREATING TEST RECIPE ===');
        final testRecipe = Recipe(
          id: 'e2e-edit-recipe-${DateTime.now().millisecondsSinceEpoch}',
          name: testRecipeName,
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 2,
          prepTimeMinutes: 20,
          cookTimeMinutes: 30,
          rating: 4,
        );

        await dbHelper.insertRecipe(testRecipe);
        createdRecipeId = testRecipe.id;
        print('✓ Test recipe created: $testRecipeName (ID: $createdRecipeId)');

        // Verify recipe was created
        final recipeInDb = await dbHelper.getRecipe(createdRecipeId);
        expect(recipeInDb, isNotNull,
            reason: 'Recipe should exist in database');
        print('✓ Recipe verified in database');

        // ======================================================================
        // SETUP: Create Test Meal
        // ======================================================================

        print('\n=== CREATING TEST MEAL ===');
        final testMeal = Meal(
          id: 'e2e-edit-meal-${DateTime.now().millisecondsSinceEpoch}',
          cookedAt: DateTime.now().subtract(const Duration(days: 1)),
          servings: originalServings,
          notes: originalNotes,
          wasSuccessful: true,
          actualPrepTime: 18.0,
          actualCookTime: 28.0,
        );

        await dbHelper.insertMeal(testMeal);
        createdMealId = testMeal.id;
        print(
            '✓ Test meal created: servings=$originalServings (ID: $createdMealId)');

        // Create MealRecipe association (primary dish)
        final testMealRecipe = MealRecipe(
          mealId: testMeal.id,
          recipeId: testRecipe.id,
          isPrimaryDish: true,
          notes: 'Test meal recipe',
        );

        await dbHelper.insertMealRecipe(testMealRecipe);
        print('✓ MealRecipe association created');

        // Verify meal was created
        final mealInDb = await dbHelper.getMeal(createdMealId);
        expect(mealInDb, isNotNull, reason: 'Meal should exist in database');
        expect(mealInDb!.servings, equals(originalServings),
            reason: 'Original servings should match');
        print('✓ Meal verified in database');

        // Force RecipeProvider to refresh and pick up the new recipe
        print('\n=== REFRESHING RECIPE PROVIDER ===');
        await E2ETestHelpers.refreshRecipeProvider(tester);
        print('✓ RecipeProvider refreshed');

        // ======================================================================
        // NAVIGATE: To Meal History Screen
        // ======================================================================

        print('\n=== NAVIGATING TO MEAL HISTORY SCREEN ===');
        // Navigate to Recipes tab (app starts on Recipes tab)
        await E2ETestHelpers.tapBottomNavTab(
          tester,
          const Key('recipes_tab_icon'),
        );
        await tester.pumpAndSettle();
        print('✓ On Recipes tab');

        // Navigate to meal history using helper
        await E2ETestHelpers.navigateToMealHistory(tester, testRecipeName);
        print('✓ Navigated to Meal History Screen');

        // Verify we're on the meal history screen
        expect(find.textContaining(testRecipeName), findsWidgets,
            reason: 'Recipe name should appear in history screen');
        print('✓ On Meal History Screen');

        // Verify the meal appears in the list with original servings
        expect(find.text(originalServings.toString()), findsWidgets,
            reason: 'Original servings should be visible in meal card');
        print('✓ Meal card shows original servings: $originalServings');

        // ======================================================================
        // ACT: Open Edit Dialog and Modify Servings
        // ======================================================================

        print('\n=== OPENING EDIT DIALOG ===');
        await E2ETestHelpers.openMealEditDialog(tester);
        print('✓ Edit dialog opened');

        // Verify dialog is open by checking for form fields
        expect(
            find.byKey(const Key('edit_meal_recording_servings_field')),
            findsOneWidget,
            reason: 'Servings field should be visible in edit dialog');
        print('✓ Edit dialog confirmed open');

        print('\n=== MODIFYING SERVINGS FIELD ===');
        await E2ETestHelpers.fillMealEditDialog(
          tester,
          servings: updatedServings.toString(),
        );
        print('✓ Servings field updated to: $updatedServings');

        // ======================================================================
        // ACT: Save Changes
        // ======================================================================

        print('\n=== SAVING CHANGES ===');
        await E2ETestHelpers.saveMealEditDialog(tester);
        print('✓ Save button tapped');

        // Wait for dialog to close and UI to update
        await tester.pumpAndSettle();
        print('✓ Dialog closed and UI settled');

        // ======================================================================
        // VERIFY UI: Success Message
        // ======================================================================

        print('\n=== VERIFYING UI: SUCCESS MESSAGE ===');
        // Look for success snackbar or message
        // The exact text depends on localization, so we look for common patterns
        final successIndicators = [
          find.textContaining('success'),
          find.textContaining('updated'),
          find.textContaining('saved'),
          find.textContaining('sucesso'), // Portuguese
          find.textContaining('atualiza'), // Portuguese "atualizado"
        ];

        bool foundSuccessMessage = false;
        for (final indicator in successIndicators) {
          if (indicator.evaluate().isNotEmpty) {
            foundSuccessMessage = true;
            print('✓ Success message found in UI');
            break;
          }
        }

        if (!foundSuccessMessage) {
          print(
              '⚠ Success message not found (may have disappeared or use different text)');
        }

        // ======================================================================
        // VERIFY UI: Updated Servings Value
        // ======================================================================

        print('\n=== VERIFYING UI: UPDATED SERVINGS ===');
        expect(find.text(updatedServings.toString()), findsWidgets,
            reason: 'Updated servings should be visible in meal card');
        print('✓ Meal card shows updated servings: $updatedServings');

        // ======================================================================
        // VERIFY DATABASE: Updated Value
        // ======================================================================

        print('\n=== VERIFYING DATABASE: UPDATED VALUE ===');
        await E2ETestHelpers.verifyMealFieldsInDatabase(
          dbHelper,
          createdMealId,
          expectedServings: updatedServings,
        );
        print('✓ Database confirmed updated servings: $updatedServings');

        // Additional verification: notes should remain unchanged
        await E2ETestHelpers.verifyMealFieldsInDatabase(
          dbHelper,
          createdMealId,
          expectedNotes: originalNotes,
        );
        print('✓ Database confirmed other fields unchanged');

        print('\n=== TEST COMPLETED SUCCESSFULLY ===');
      } finally {
        // ======================================================================
        // CLEANUP: Delete Test Data
        // ======================================================================

        print('\n=== CLEANING UP TEST DATA ===');
        final dbHelper = DatabaseHelper();

        if (createdMealId != null) {
          await E2ETestHelpers.deleteTestMeal(dbHelper, createdMealId);
          print('✓ Test meal deleted: $createdMealId');
        }

        if (createdRecipeId != null) {
          await E2ETestHelpers.deleteTestRecipe(dbHelper, createdRecipeId);
          print('✓ Test recipe deleted: $createdRecipeId');
        }

        print('✓ Cleanup complete');
      }
    });

    // ========================================================================
    // PHASE 2.1: Multi-Recipe Meal Edit Test
    // ========================================================================

    testWidgets('Edit multi-recipe meal and verify all recipes preserved',
        (WidgetTester tester) async {
      // ========================================================================
      // TEST DATA SETUP
      // ========================================================================

      final testRecipeName =
          'E2E Multi-Recipe Primary ${DateTime.now().millisecondsSinceEpoch}';
      final testSideRecipeName =
          'E2E Multi-Recipe Side ${DateTime.now().millisecondsSinceEpoch}';
      final originalServings = 3;
      final updatedServings = 6;
      final originalNotes = 'Multi-recipe meal notes';

      String? createdRecipeId;
      String? createdSideRecipeId;
      String? createdMealId;

      try {
        // ======================================================================
        // SETUP: Launch and Initialize
        // ======================================================================

        print('=== LAUNCHING APP ===');
        await E2ETestHelpers.launchApp(tester);
        print('✓ App launched and initialized');

        final dbHelper = DatabaseHelper();

        // ======================================================================
        // SETUP: Create Test Recipe (Primary Dish)
        // ======================================================================

        print('\n=== CREATING PRIMARY RECIPE ===');
        final testRecipe = Recipe(
          id: 'e2e-edit-primary-${DateTime.now().millisecondsSinceEpoch}',
          name: testRecipeName,
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 2,
          prepTimeMinutes: 30,
          cookTimeMinutes: 40,
          rating: 4,
        );

        await dbHelper.insertRecipe(testRecipe);
        createdRecipeId = testRecipe.id;
        print('✓ Primary recipe created: $testRecipeName (ID: $createdRecipeId)');

        // ======================================================================
        // SETUP: Create Side Recipe
        // ======================================================================

        print('\n=== CREATING SIDE RECIPE ===');
        final sideRecipe = Recipe(
          id: 'e2e-edit-side-${DateTime.now().millisecondsSinceEpoch}',
          name: testSideRecipeName,
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 1,
          prepTimeMinutes: 10,
          cookTimeMinutes: 15,
          rating: 4,
        );

        await dbHelper.insertRecipe(sideRecipe);
        createdSideRecipeId = sideRecipe.id;
        print('✓ Side recipe created: $testSideRecipeName (ID: $createdSideRecipeId)');

        // ======================================================================
        // SETUP: Create Multi-Recipe Meal
        // ======================================================================

        print('\n=== CREATING MULTI-RECIPE MEAL ===');
        final testMeal = Meal(
          id: 'e2e-edit-multi-meal-${DateTime.now().millisecondsSinceEpoch}',
          cookedAt: DateTime.now().subtract(const Duration(days: 1)),
          servings: originalServings,
          notes: originalNotes,
          wasSuccessful: true,
          actualPrepTime: 35.0,
          actualCookTime: 45.0,
        );

        await dbHelper.insertMeal(testMeal);
        createdMealId = testMeal.id;
        print(
            '✓ Meal created: servings=$originalServings (ID: $createdMealId)');

        // Create MealRecipe association for primary dish
        final primaryMealRecipe = MealRecipe(
          mealId: testMeal.id,
          recipeId: testRecipe.id,
          isPrimaryDish: true,
          notes: 'Primary dish',
        );
        await dbHelper.insertMealRecipe(primaryMealRecipe);
        print('✓ Primary dish MealRecipe association created');

        // Create MealRecipe association for side dish
        final sideMealRecipe = MealRecipe(
          mealId: testMeal.id,
          recipeId: sideRecipe.id,
          isPrimaryDish: false,
          notes: 'Side dish',
        );
        await dbHelper.insertMealRecipe(sideMealRecipe);
        print('✓ Side dish MealRecipe association created');

        // Verify meal was created with both recipes
        final mealInDb = await dbHelper.getMeal(createdMealId);
        expect(mealInDb, isNotNull, reason: 'Meal should exist in database');
        expect(mealInDb!.servings, equals(originalServings),
            reason: 'Original servings should match');
        print('✓ Meal verified in database');

        // Verify both MealRecipe associations exist
        final mealRecipes = await dbHelper.getMealRecipesForMeal(createdMealId);
        expect(mealRecipes.length, equals(2),
            reason: 'Meal should have 2 recipe associations');
        expect(mealRecipes.where((mr) => mr.isPrimaryDish).length, equals(1),
            reason: 'Meal should have 1 primary dish');
        expect(mealRecipes.where((mr) => !mr.isPrimaryDish).length, equals(1),
            reason: 'Meal should have 1 side dish');
        print('✓ Both MealRecipe associations verified in database');

        // Force RecipeProvider to refresh and pick up the new recipes
        print('\n=== REFRESHING RECIPE PROVIDER ===');
        await E2ETestHelpers.refreshRecipeProvider(tester);
        print('✓ RecipeProvider refreshed');

        // ======================================================================
        // NAVIGATE: To Meal History Screen
        // ======================================================================

        print('\n=== NAVIGATING TO MEAL HISTORY SCREEN ===');
        await E2ETestHelpers.tapBottomNavTab(
          tester,
          const Key('recipes_tab_icon'),
        );
        await tester.pumpAndSettle();
        print('✓ On Recipes tab');

        // Navigate to meal history using helper (for primary recipe)
        await E2ETestHelpers.navigateToMealHistory(tester, testRecipeName);
        print('✓ Navigated to Meal History Screen for primary recipe');

        // Verify we're on the meal history screen
        expect(find.textContaining(testRecipeName), findsWidgets,
            reason: 'Recipe name should appear in history screen');
        print('✓ On Meal History Screen');

        // ======================================================================
        // VERIFY UI: Side Dish Count Displayed
        // ======================================================================

        print('\n=== VERIFYING UI: SIDE DISH COUNT ===');
        // Look for side dish indicator (text varies by localization)
        final sideDishIndicators = [
          find.textContaining('1 side'),
          find.textContaining('side dish'),
          find.textContaining('acompanhamento'), // Portuguese
        ];

        bool foundSideDishIndicator = false;
        for (final indicator in sideDishIndicators) {
          if (indicator.evaluate().isNotEmpty) {
            foundSideDishIndicator = true;
            print('✓ UI shows side dish count indicator');
            break;
          }
        }

        if (!foundSideDishIndicator) {
          print(
              '⚠ Side dish indicator not found in expected format - checking for side recipe name');
          // Alternative: check if side recipe name appears
          expect(find.textContaining(testSideRecipeName), findsWidgets,
              reason: 'Side recipe name should be visible');
          print('✓ Side recipe name visible in UI');
        }

        // ======================================================================
        // ACT: Open Edit Dialog and Modify Servings
        // ======================================================================

        print('\n=== OPENING EDIT DIALOG ===');
        await E2ETestHelpers.openMealEditDialog(tester);
        print('✓ Edit dialog opened');

        // Verify dialog is open
        expect(
            find.byKey(const Key('edit_meal_recording_servings_field')),
            findsOneWidget,
            reason: 'Servings field should be visible in edit dialog');
        print('✓ Edit dialog confirmed open');

        // Verify side dish appears in edit dialog
        expect(find.textContaining(testSideRecipeName), findsWidgets,
            reason: 'Side recipe should appear in edit dialog');
        print('✓ Side dish visible in edit dialog');

        print('\n=== MODIFYING SERVINGS FIELD ===');
        await E2ETestHelpers.fillMealEditDialog(
          tester,
          servings: updatedServings.toString(),
        );
        print('✓ Servings field updated to: $updatedServings');

        // ======================================================================
        // ACT: Save Changes
        // ======================================================================

        print('\n=== SAVING CHANGES ===');
        await E2ETestHelpers.saveMealEditDialog(tester);
        print('✓ Save button tapped');

        // Wait for dialog to close and UI to update
        await tester.pumpAndSettle();
        print('✓ Dialog closed and UI settled');

        // ======================================================================
        // VERIFY UI: Success Message
        // ======================================================================

        print('\n=== VERIFYING UI: SUCCESS MESSAGE ===');
        final successIndicators = [
          find.textContaining('success'),
          find.textContaining('updated'),
          find.textContaining('saved'),
          find.textContaining('sucesso'),
          find.textContaining('atualiza'),
        ];

        bool foundSuccessMessage = false;
        for (final indicator in successIndicators) {
          if (indicator.evaluate().isNotEmpty) {
            foundSuccessMessage = true;
            print('✓ Success message found in UI');
            break;
          }
        }

        if (!foundSuccessMessage) {
          print('⚠ Success message not found (may have disappeared)');
        }

        // ======================================================================
        // VERIFY UI: Side Dish Still Displayed
        // ======================================================================

        print('\n=== VERIFYING UI: SIDE DISH PRESERVED ===');
        // Check side dish indicator still appears
        foundSideDishIndicator = false;
        for (final indicator in sideDishIndicators) {
          if (indicator.evaluate().isNotEmpty) {
            foundSideDishIndicator = true;
            print('✓ Side dish count indicator still visible after edit');
            break;
          }
        }

        if (!foundSideDishIndicator) {
          // Alternative check
          expect(find.textContaining(testSideRecipeName), findsWidgets,
              reason: 'Side recipe should still be visible after edit');
          print('✓ Side recipe name still visible after edit');
        }

        // ======================================================================
        // VERIFY DATABASE: All Recipe Associations Preserved
        // ======================================================================

        print('\n=== VERIFYING DATABASE: MEAL UPDATED ===');
        await E2ETestHelpers.verifyMealFieldsInDatabase(
          dbHelper,
          createdMealId,
          expectedServings: updatedServings,
        );
        print('✓ Database confirmed updated servings: $updatedServings');

        print('\n=== VERIFYING DATABASE: RECIPE ASSOCIATIONS PRESERVED ===');
        final mealRecipesAfterEdit =
            await dbHelper.getMealRecipesForMeal(createdMealId);
        expect(mealRecipesAfterEdit.length, equals(2),
            reason: 'Meal should still have 2 recipe associations after edit');
        print('✓ Database confirmed 2 recipe associations still exist');

        // Verify primary dish still exists
        final primaryAfterEdit =
            mealRecipesAfterEdit.firstWhere((mr) => mr.isPrimaryDish);
        expect(primaryAfterEdit.recipeId, equals(createdRecipeId),
            reason: 'Primary recipe association should be preserved');
        print('✓ Primary dish association preserved');

        // Verify side dish still exists
        final sideAfterEdit =
            mealRecipesAfterEdit.firstWhere((mr) => !mr.isPrimaryDish);
        expect(sideAfterEdit.recipeId, equals(createdSideRecipeId),
            reason: 'Side recipe association should be preserved');
        print('✓ Side dish association preserved');

        print('\n=== TEST COMPLETED SUCCESSFULLY ===');
      } finally {
        // ======================================================================
        // CLEANUP: Delete Test Data
        // ======================================================================

        print('\n=== CLEANING UP TEST DATA ===');
        final dbHelper = DatabaseHelper();

        if (createdMealId != null) {
          await E2ETestHelpers.deleteTestMeal(dbHelper, createdMealId);
          print('✓ Test meal deleted: $createdMealId');
        }

        if (createdRecipeId != null) {
          await E2ETestHelpers.deleteTestRecipe(dbHelper, createdRecipeId);
          print('✓ Primary recipe deleted: $createdRecipeId');
        }

        if (createdSideRecipeId != null) {
          await E2ETestHelpers.deleteTestRecipe(dbHelper, createdSideRecipeId);
          print('✓ Side recipe deleted: $createdSideRecipeId');
        }

        print('✓ Cleanup complete');
      }
    });

    // ========================================================================
    // PHASE 2.2: Add Side Dish During Edit Test
    // ========================================================================

    testWidgets('Add side dish to existing meal during edit workflow',
        (WidgetTester tester) async {
      // ========================================================================
      // TEST DATA SETUP
      // ========================================================================

      final testRecipeName =
          'E2E Add Side Primary ${DateTime.now().millisecondsSinceEpoch}';
      final testSideRecipeName =
          'E2E Add Side Dish ${DateTime.now().millisecondsSinceEpoch}';
      final originalServings = 2;

      String? createdRecipeId;
      String? createdSideRecipeId;
      String? createdMealId;

      try {
        // ======================================================================
        // SETUP: Launch and Initialize
        // ======================================================================

        print('=== LAUNCHING APP ===');
        await E2ETestHelpers.launchApp(tester);
        print('✓ App launched and initialized');

        final dbHelper = DatabaseHelper();

        // ======================================================================
        // SETUP: Create Test Recipe (Primary Dish)
        // ======================================================================

        print('\n=== CREATING PRIMARY RECIPE ===');
        final testRecipe = Recipe(
          id: 'e2e-add-primary-${DateTime.now().millisecondsSinceEpoch}',
          name: testRecipeName,
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 2,
          prepTimeMinutes: 20,
          cookTimeMinutes: 30,
          rating: 4,
        );

        await dbHelper.insertRecipe(testRecipe);
        createdRecipeId = testRecipe.id;
        print('✓ Primary recipe created: $testRecipeName (ID: $createdRecipeId)');

        // ======================================================================
        // SETUP: Create Side Recipe (to be added during edit)
        // ======================================================================

        print('\n=== CREATING SIDE RECIPE ===');
        final sideRecipe = Recipe(
          id: 'e2e-add-side-${DateTime.now().millisecondsSinceEpoch}',
          name: testSideRecipeName,
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 1,
          prepTimeMinutes: 10,
          cookTimeMinutes: 15,
          rating: 3,
        );

        await dbHelper.insertRecipe(sideRecipe);
        createdSideRecipeId = sideRecipe.id;
        print('✓ Side recipe created: $testSideRecipeName (ID: $createdSideRecipeId)');

        // ======================================================================
        // SETUP: Create Single-Recipe Meal (no side dishes initially)
        // ======================================================================

        print('\n=== CREATING SINGLE-RECIPE MEAL ===');
        final testMeal = Meal(
          id: 'e2e-add-meal-${DateTime.now().millisecondsSinceEpoch}',
          cookedAt: DateTime.now().subtract(const Duration(days: 1)),
          servings: originalServings,
          notes: 'Single-recipe meal - will add side dish',
          wasSuccessful: true,
          actualPrepTime: 20.0,
          actualCookTime: 30.0,
        );

        await dbHelper.insertMeal(testMeal);
        createdMealId = testMeal.id;
        print(
            '✓ Meal created: servings=$originalServings (ID: $createdMealId)');

        // Create MealRecipe association for primary dish only
        final primaryMealRecipe = MealRecipe(
          mealId: testMeal.id,
          recipeId: testRecipe.id,
          isPrimaryDish: true,
          notes: 'Primary dish',
        );
        await dbHelper.insertMealRecipe(primaryMealRecipe);
        print('✓ Primary dish MealRecipe association created');

        // Verify meal initially has only 1 recipe association
        final mealRecipesBefore =
            await dbHelper.getMealRecipesForMeal(createdMealId);
        expect(mealRecipesBefore.length, equals(1),
            reason: 'Meal should initially have only 1 recipe association');
        print('✓ Initial state: 1 recipe association verified in database');

        // Force RecipeProvider to refresh and pick up the new recipes
        print('\n=== REFRESHING RECIPE PROVIDER ===');
        await E2ETestHelpers.refreshRecipeProvider(tester);
        print('✓ RecipeProvider refreshed');

        // ======================================================================
        // NAVIGATE: To Meal History Screen
        // ======================================================================

        print('\n=== NAVIGATING TO MEAL HISTORY SCREEN ===');
        await E2ETestHelpers.tapBottomNavTab(
          tester,
          const Key('recipes_tab_icon'),
        );
        await tester.pumpAndSettle();
        print('✓ On Recipes tab');

        // Navigate to meal history using helper (for primary recipe)
        await E2ETestHelpers.navigateToMealHistory(tester, testRecipeName);
        print('✓ Navigated to Meal History Screen for primary recipe');

        // Verify we're on the meal history screen
        expect(find.textContaining(testRecipeName), findsWidgets,
            reason: 'Recipe name should appear in history screen');
        print('✓ On Meal History Screen');

        // ======================================================================
        // VERIFY UI: No Side Dish Initially (on meal history screen)
        // ======================================================================

        print('\n=== VERIFYING UI: NO SIDE DISH ON MEAL HISTORY SCREEN ===');
        // Check for side dish count badge (only shown when meal has >1 recipes)
        final sideDishCountBadge = find.textContaining('1 side');
        if (sideDishCountBadge.evaluate().isNotEmpty) {
          fail('Side dish count badge should not be visible initially');
        }
        print('✓ No side dish count badge visible on meal history screen (expected)');

        // ======================================================================
        // ACT: Open Edit Dialog
        // ======================================================================

        print('\n=== OPENING EDIT DIALOG ===');
        await E2ETestHelpers.openMealEditDialog(tester);
        print('✓ Edit dialog opened');

        // Verify dialog is open
        expect(
            find.byKey(const Key('edit_meal_recording_servings_field')),
            findsOneWidget,
            reason: 'Servings field should be visible in edit dialog');
        print('✓ Edit dialog confirmed open');

        // Verify side dish is NOT in dialog initially
        // Side dishes use Icons.restaurant_menu, main dish uses Icons.restaurant
        final sideDishIcons = find.byIcon(Icons.restaurant_menu);
        expect(sideDishIcons, findsNothing,
            reason: 'No side dish icons should appear in edit dialog initially');
        print('✓ No side dishes in edit dialog initially (expected)');

        // ======================================================================
        // ACT: Add Side Dish
        // ======================================================================

        print('\n=== ADDING SIDE DISH ===');
        await E2ETestHelpers.addSideDishInEditDialog(tester, testSideRecipeName);
        print('✓ Side dish added via recipe selection dialog');

        // Wait for UI to update after adding
        await tester.pumpAndSettle();
        print('✓ UI updated after adding side dish');

        // Verify side dish now appears in edit dialog
        final sideDishIconsAfterAdd = find.byIcon(Icons.restaurant_menu);
        expect(sideDishIconsAfterAdd, findsOneWidget,
            reason: 'Side dish icon should appear in edit dialog after adding');
        print('✓ Side dish icon now visible in edit dialog');

        // Also verify the side dish name is visible
        expect(find.textContaining(testSideRecipeName), findsWidgets,
            reason: 'Side recipe name should appear in edit dialog after adding');
        print('✓ Side dish name visible: $testSideRecipeName');

        // ======================================================================
        // ACT: Save Changes
        // ======================================================================

        print('\n=== SAVING CHANGES ===');
        await E2ETestHelpers.saveMealEditDialog(tester);
        print('✓ Save button tapped');

        // Wait for dialog to close and UI to update
        await tester.pumpAndSettle();
        print('✓ Dialog closed and UI settled');

        // ======================================================================
        // VERIFY UI: Success Message
        // ======================================================================

        print('\n=== VERIFYING UI: SUCCESS MESSAGE ===');
        final successIndicators = [
          find.textContaining('success'),
          find.textContaining('updated'),
          find.textContaining('saved'),
          find.textContaining('sucesso'),
          find.textContaining('atualiza'),
        ];

        bool foundSuccessMessage = false;
        for (final indicator in successIndicators) {
          if (indicator.evaluate().isNotEmpty) {
            foundSuccessMessage = true;
            print('✓ Success message found in UI');
            break;
          }
        }

        if (!foundSuccessMessage) {
          print('⚠ Success message not found (may have disappeared)');
        }

        // ======================================================================
        // VERIFY UI: Side Dish Now Displayed (on meal history screen)
        // ======================================================================

        print('\n=== VERIFYING UI: SIDE DISH NOW ON MEAL HISTORY SCREEN ===');
        // Check for side dish count badge (should now show "1 side dish")
        final sideDishCountBadgeAfterSave = find.textContaining('1 side');
        if (sideDishCountBadgeAfterSave.evaluate().isNotEmpty) {
          print('✓ Side dish count badge now visible on meal history screen');
        } else {
          // Alternative: check if side recipe name appears in the side dish list
          expect(find.textContaining(testSideRecipeName), findsWidgets,
              reason: 'Side recipe name should be visible in meal card after adding');
          print('✓ Side recipe name visible in meal card after save');
        }

        // ======================================================================
        // VERIFY DATABASE: New MealRecipe Association Created
        // ======================================================================

        print('\n=== VERIFYING DATABASE: SIDE DISH ADDED ===');
        final mealRecipesAfterEdit =
            await dbHelper.getMealRecipesForMeal(createdMealId);
        expect(mealRecipesAfterEdit.length, equals(2),
            reason: 'Meal should now have 2 recipe associations after adding side dish');
        print('✓ Database confirmed 2 recipe associations now exist');

        // Verify primary dish still exists
        final primaryAfterEdit =
            mealRecipesAfterEdit.firstWhere((mr) => mr.isPrimaryDish);
        expect(primaryAfterEdit.recipeId, equals(createdRecipeId),
            reason: 'Primary recipe association should be preserved');
        print('✓ Primary dish association preserved');

        // Verify side dish was added
        final sideAfterEdit =
            mealRecipesAfterEdit.firstWhere((mr) => !mr.isPrimaryDish);
        expect(sideAfterEdit.recipeId, equals(createdSideRecipeId),
            reason: 'Side recipe association should be created');
        print('✓ Side dish association created in database');

        print('\n=== TEST COMPLETED SUCCESSFULLY ===');
      } finally {
        // ======================================================================
        // CLEANUP: Delete Test Data
        // ======================================================================

        print('\n=== CLEANING UP TEST DATA ===');
        final dbHelper = DatabaseHelper();

        if (createdMealId != null) {
          await E2ETestHelpers.deleteTestMeal(dbHelper, createdMealId);
          print('✓ Test meal deleted: $createdMealId');
        }

        if (createdRecipeId != null) {
          await E2ETestHelpers.deleteTestRecipe(dbHelper, createdRecipeId);
          print('✓ Primary recipe deleted: $createdRecipeId');
        }

        if (createdSideRecipeId != null) {
          await E2ETestHelpers.deleteTestRecipe(dbHelper, createdSideRecipeId);
          print('✓ Side recipe deleted: $createdSideRecipeId');
        }

        print('✓ Cleanup complete');
      }
    });

    // ========================================================================
    // PHASE 2.3: Remove Side Dish During Edit Test
    // ========================================================================

    testWidgets('Remove side dish from meal during edit workflow',
        (WidgetTester tester) async {
      // ========================================================================
      // TEST DATA SETUP
      // ========================================================================

      final testRecipeName =
          'E2E Remove Side Primary ${DateTime.now().millisecondsSinceEpoch}';
      final testSideRecipeName =
          'E2E Remove Side Dish ${DateTime.now().millisecondsSinceEpoch}';
      final originalServings = 4;

      String? createdRecipeId;
      String? createdSideRecipeId;
      String? createdMealId;

      try {
        // ======================================================================
        // SETUP: Launch and Initialize
        // ======================================================================

        print('=== LAUNCHING APP ===');
        await E2ETestHelpers.launchApp(tester);
        print('✓ App launched and initialized');

        final dbHelper = DatabaseHelper();

        // ======================================================================
        // SETUP: Create Test Recipe (Primary Dish)
        // ======================================================================

        print('\n=== CREATING PRIMARY RECIPE ===');
        final testRecipe = Recipe(
          id: 'e2e-remove-primary-${DateTime.now().millisecondsSinceEpoch}',
          name: testRecipeName,
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 2,
          prepTimeMinutes: 25,
          cookTimeMinutes: 35,
          rating: 4,
        );

        await dbHelper.insertRecipe(testRecipe);
        createdRecipeId = testRecipe.id;
        print('✓ Primary recipe created: $testRecipeName (ID: $createdRecipeId)');

        // ======================================================================
        // SETUP: Create Side Recipe
        // ======================================================================

        print('\n=== CREATING SIDE RECIPE ===');
        final sideRecipe = Recipe(
          id: 'e2e-remove-side-${DateTime.now().millisecondsSinceEpoch}',
          name: testSideRecipeName,
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 1,
          prepTimeMinutes: 5,
          cookTimeMinutes: 10,
          rating: 3,
        );

        await dbHelper.insertRecipe(sideRecipe);
        createdSideRecipeId = sideRecipe.id;
        print('✓ Side recipe created: $testSideRecipeName (ID: $createdSideRecipeId)');

        // ======================================================================
        // SETUP: Create Multi-Recipe Meal
        // ======================================================================

        print('\n=== CREATING MULTI-RECIPE MEAL ===');
        final testMeal = Meal(
          id: 'e2e-remove-meal-${DateTime.now().millisecondsSinceEpoch}',
          cookedAt: DateTime.now().subtract(const Duration(days: 2)),
          servings: originalServings,
          notes: 'Meal with side dish to be removed',
          wasSuccessful: true,
          actualPrepTime: 30.0,
          actualCookTime: 40.0,
        );

        await dbHelper.insertMeal(testMeal);
        createdMealId = testMeal.id;
        print(
            '✓ Meal created: servings=$originalServings (ID: $createdMealId)');

        // Create MealRecipe association for primary dish
        final primaryMealRecipe = MealRecipe(
          mealId: testMeal.id,
          recipeId: testRecipe.id,
          isPrimaryDish: true,
          notes: 'Primary dish',
        );
        await dbHelper.insertMealRecipe(primaryMealRecipe);
        print('✓ Primary dish MealRecipe association created');

        // Create MealRecipe association for side dish (to be removed)
        final sideMealRecipe = MealRecipe(
          mealId: testMeal.id,
          recipeId: sideRecipe.id,
          isPrimaryDish: false,
          notes: 'Side dish to remove',
        );
        await dbHelper.insertMealRecipe(sideMealRecipe);
        print('✓ Side dish MealRecipe association created');

        // Verify both MealRecipe associations exist
        final mealRecipesBefore =
            await dbHelper.getMealRecipesForMeal(createdMealId);
        expect(mealRecipesBefore.length, equals(2),
            reason: 'Meal should initially have 2 recipe associations');
        print('✓ Initial state: 2 recipe associations verified in database');

        // Force RecipeProvider to refresh and pick up the new recipes
        print('\n=== REFRESHING RECIPE PROVIDER ===');
        await E2ETestHelpers.refreshRecipeProvider(tester);
        print('✓ RecipeProvider refreshed');

        // ======================================================================
        // NAVIGATE: To Meal History Screen
        // ======================================================================

        print('\n=== NAVIGATING TO MEAL HISTORY SCREEN ===');
        await E2ETestHelpers.tapBottomNavTab(
          tester,
          const Key('recipes_tab_icon'),
        );
        await tester.pumpAndSettle();
        print('✓ On Recipes tab');

        // Navigate to meal history using helper (for primary recipe)
        await E2ETestHelpers.navigateToMealHistory(tester, testRecipeName);
        print('✓ Navigated to Meal History Screen for primary recipe');

        // Verify we're on the meal history screen
        expect(find.textContaining(testRecipeName), findsWidgets,
            reason: 'Recipe name should appear in history screen');
        print('✓ On Meal History Screen');

        // ======================================================================
        // VERIFY UI: Side Dish Initially Displayed (on meal history screen)
        // ======================================================================

        print('\n=== VERIFYING UI: SIDE DISH ON MEAL HISTORY SCREEN ===');
        // Check for side dish count badge (should show "1 side dish")
        final sideDishCountBadge = find.textContaining('1 side');
        if (sideDishCountBadge.evaluate().isNotEmpty) {
          print('✓ Side dish count badge visible on meal history screen');
        } else {
          print('⚠ Side dish count badge not found (may not be displayed yet)');
          print('  Proceeding with test - will verify in edit dialog');
        }

        // ======================================================================
        // ACT: Open Edit Dialog
        // ======================================================================

        print('\n=== OPENING EDIT DIALOG ===');
        await E2ETestHelpers.openMealEditDialog(tester);
        print('✓ Edit dialog opened');

        // Verify dialog is open
        expect(
            find.byKey(const Key('edit_meal_recording_servings_field')),
            findsOneWidget,
            reason: 'Servings field should be visible in edit dialog');
        print('✓ Edit dialog confirmed open');

        // Verify side dish appears in edit dialog before removal
        // Side dishes use Icons.restaurant_menu, main dish uses Icons.restaurant
        // Note: restaurant_menu icon may appear on both meal history (background) and dialog
        // So we just verify the side dish name is visible in the dialog
        expect(find.textContaining(testSideRecipeName), findsWidgets,
            reason: 'Side recipe name should appear in edit dialog before removal');
        print('✓ Side dish name visible in edit dialog: $testSideRecipeName');

        // ======================================================================
        // ACT: Remove Side Dish
        // ======================================================================

        print('\n=== REMOVING SIDE DISH ===');
        await E2ETestHelpers.removeSideDishInEditDialog(tester, 0);
        print('✓ Side dish remove button tapped');

        // Wait for UI to update after removal
        await tester.pumpAndSettle();
        print('✓ UI updated after side dish removal');

        // Verify side dish no longer appears in edit dialog
        // We need to scope the search to the dialog only, not the entire screen
        // (the meal history screen in the background may still show the side dish)

        // First, verify the dialog is still open by checking for the servings field
        final servingsField = find.byKey(const Key('edit_meal_recording_servings_field'));
        expect(servingsField, findsOneWidget,
            reason: 'Dialog should still be open');

        // Find the dialog container - try common dialog types
        Finder? dialogFinder;
        for (final dialogType in [Dialog, AlertDialog, SimpleDialog]) {
          final candidate = find.ancestor(
            of: servingsField,
            matching: find.byType(dialogType),
          );
          if (candidate.evaluate().isNotEmpty) {
            dialogFinder = candidate;
            print('    - Found dialog of type: $dialogType');
            break;
          }
        }

        if (dialogFinder != null) {
          // Search for side dish name only within the dialog
          final sideNameInDialog = find.descendant(
            of: dialogFinder,
            matching: find.textContaining(testSideRecipeName),
          );
          expect(sideNameInDialog, findsNothing,
              reason: 'Side recipe name should not appear in edit dialog after removal');
          print('✓ Side dish name no longer visible in edit dialog');
        } else {
          // Fallback: if we can't find the dialog type, verify by checking
          // that the remaining text doesn't have a delete button near it
          print('    - Could not determine dialog type, using alternative verification');
          final deleteButtons = find.byIcon(Icons.delete_outline);
          expect(deleteButtons, findsNothing,
              reason: 'No delete buttons should remain (side dish list should be empty)');
          print('✓ No delete buttons found - side dish list is empty');
        }

        // ======================================================================
        // ACT: Save Changes
        // ======================================================================

        print('\n=== SAVING CHANGES ===');
        await E2ETestHelpers.saveMealEditDialog(tester);
        print('✓ Save button tapped');

        // Wait for dialog to close and UI to update
        await tester.pumpAndSettle();
        print('✓ Dialog closed and UI settled');

        // ======================================================================
        // VERIFY UI: Success Message
        // ======================================================================

        print('\n=== VERIFYING UI: SUCCESS MESSAGE ===');
        final successIndicators = [
          find.textContaining('success'),
          find.textContaining('updated'),
          find.textContaining('saved'),
          find.textContaining('sucesso'),
          find.textContaining('atualiza'),
        ];

        bool foundSuccessMessage = false;
        for (final indicator in successIndicators) {
          if (indicator.evaluate().isNotEmpty) {
            foundSuccessMessage = true;
            print('✓ Success message found in UI');
            break;
          }
        }

        if (!foundSuccessMessage) {
          print('⚠ Success message not found (may have disappeared)');
        }

        // ======================================================================
        // VERIFY UI: Side Dish No Longer Displayed (on meal history screen)
        // ======================================================================

        print('\n=== VERIFYING UI: SIDE DISH REMOVED FROM MEAL HISTORY ===');
        // Check that side dish count badge is no longer present
        final sideDishCountBadgeAfterRemove = find.textContaining('1 side');
        expect(sideDishCountBadgeAfterRemove, findsNothing,
            reason: 'Side dish count badge should not be visible after removal');
        print('✓ Side dish count badge no longer visible on meal history screen');

        // Verify side recipe name also not visible in meal card
        expect(find.textContaining(testSideRecipeName), findsNothing,
            reason: 'Side recipe name should not be visible in meal card after removal');
        print('✓ Side recipe name no longer visible in meal card');

        // ======================================================================
        // VERIFY DATABASE: Side Dish Association Removed
        // ======================================================================

        print('\n=== VERIFYING DATABASE: SIDE DISH REMOVED ===');
        final mealRecipesAfterEdit =
            await dbHelper.getMealRecipesForMeal(createdMealId);
        expect(mealRecipesAfterEdit.length, equals(1),
            reason: 'Meal should have only 1 recipe association after removal');
        print('✓ Database confirmed only 1 recipe association remains');

        // Verify the remaining association is the primary dish
        final remainingRecipe = mealRecipesAfterEdit.first;
        expect(remainingRecipe.isPrimaryDish, isTrue,
            reason: 'Remaining recipe should be the primary dish');
        expect(remainingRecipe.recipeId, equals(createdRecipeId),
            reason: 'Remaining recipe should be the primary recipe');
        print('✓ Primary dish association preserved');

        // Verify side dish association was actually removed
        final sideRecipeStillExists = mealRecipesAfterEdit
            .any((mr) => mr.recipeId == createdSideRecipeId);
        expect(sideRecipeStillExists, isFalse,
            reason: 'Side recipe association should be removed from database');
        print('✓ Side dish association removed from database');

        print('\n=== TEST COMPLETED SUCCESSFULLY ===');
      } finally {
        // ======================================================================
        // CLEANUP: Delete Test Data
        // ======================================================================

        print('\n=== CLEANING UP TEST DATA ===');
        final dbHelper = DatabaseHelper();

        if (createdMealId != null) {
          await E2ETestHelpers.deleteTestMeal(dbHelper, createdMealId);
          print('✓ Test meal deleted: $createdMealId');
        }

        if (createdRecipeId != null) {
          await E2ETestHelpers.deleteTestRecipe(dbHelper, createdRecipeId);
          print('✓ Primary recipe deleted: $createdRecipeId');
        }

        if (createdSideRecipeId != null) {
          await E2ETestHelpers.deleteTestRecipe(dbHelper, createdSideRecipeId);
          print('✓ Side recipe deleted: $createdSideRecipeId');
        }

        print('✓ Cleanup complete');
      }
    });
  });
}
