// integration_test/e2e_recipe_selection_all_recipes_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gastrobrain/database/database_helper.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/utils/id_generator.dart';
import 'helpers/e2e_test_helpers.dart';

/// All Recipes Tab Selection E2E Test
///
/// This test verifies the UI workflow of selecting a recipe from the
/// "All Recipes" tab and adding it to the meal plan:
/// 1. Navigate to Meal Plan tab
/// 2. Tap calendar slot (Friday lunch)
/// 3. Switch to "All Recipes" tab
/// 4. Select recipe from all recipes list
/// 5. Verify recipe appears in calendar slot
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E - All Recipes Tab Selection', () {
    testWidgets('Select recipe from all recipes tab adds to meal plan',
        (WidgetTester tester) async {
      // ======================================================================
      // TEST DATA SETUP
      // ======================================================================

      final testRecipeName =
          'E2E All Recipes Test ${DateTime.now().millisecondsSinceEpoch}';
      final testRecipeId = IdGenerator.generateId();

      String? createdRecipeId;

      try {
        // ==================================================================
        // SETUP: Launch and Initialize
        // ==================================================================

        print('=== LAUNCHING APP ===');
        await E2ETestHelpers.launchApp(tester);
        print('✓ App launched and initialized');

        final dbHelper = DatabaseHelper();

        // ==================================================================
        // SETUP: Create Test Recipe
        // ==================================================================

        print('\n=== CREATING TEST RECIPE ===');
        final testRecipe = Recipe(
          id: testRecipeId,
          name: testRecipeName,
          desiredFrequency: FrequencyType.monthly,
          createdAt: DateTime.now(),
          prepTimeMinutes: 45,
          cookTimeMinutes: 60,
          difficulty: 4, // Difficult recipe - may not appear in recommendations
          rating: 3, // Medium rating
        );

        await dbHelper.insertRecipe(testRecipe);
        createdRecipeId = testRecipeId;
        print('✓ Test recipe created: $testRecipeName');
        print('  (difficulty: 4, rating: 3 - may not be in recommendations)');

        // ==================================================================
        // VERIFY: On Main Screen
        // ==================================================================

        E2ETestHelpers.verifyOnMainScreen();
        print('✓ On main screen');

        // ==================================================================
        // ACT: Navigate to Meal Plan Tab
        // ==================================================================

        print('\n=== NAVIGATING TO MEAL PLAN TAB ===');
        await E2ETestHelpers.tapBottomNavTab(
            tester, const Key('meal_plan_tab_icon'));
        print('✓ Tapped Meal Plan tab');

        // Wait for meal plan screen to load
        await E2ETestHelpers.waitForAsyncOperations();

        // ==================================================================
        // ACT: Tap Calendar Slot
        // ==================================================================

        print('\n=== TAPPING CALENDAR SLOT ===');
        final slotKey = const Key('meal_plan_friday_lunch_slot');
        final slotFinder = find.byKey(slotKey);

        expect(slotFinder, findsOneWidget,
            reason: 'Friday lunch slot should exist');
        print('✓ Found Friday lunch slot');

        await tester.tap(slotFinder);
        await tester.pumpAndSettle();
        print('✓ Tapped Friday lunch slot');

        // ==================================================================
        // VERIFY: Recipe Selection Dialog Opened
        // ==================================================================

        print('\n=== VERIFYING RECIPE SELECTION DIALOG ===');

        expect(
          find.text('Selecionar Receita'),
          findsOneWidget,
          reason: 'Recipe selection dialog should be open',
        );
        print('✓ Recipe selection dialog is open');

        // ==================================================================
        // ACT: Switch to All Recipes Tab
        // ==================================================================

        print('\n=== SWITCHING TO ALL RECIPES TAB ===');

        final allRecipesTab =
            find.byKey(const Key('recipe_selection_all_tab'));
        expect(allRecipesTab, findsOneWidget,
            reason: 'All Recipes tab should exist');

        await tester.tap(allRecipesTab);
        await tester.pumpAndSettle();
        print('✓ Tapped All Recipes tab');

        // Wait for all recipes list to load
        await E2ETestHelpers.waitForAsyncOperations();

        // ==================================================================
        // VERIFY: Test Recipe Appears in All Recipes List
        // ==================================================================

        print('\n=== VERIFYING TEST RECIPE IN ALL RECIPES LIST ===');

        // First, try to find the recipe by name (more reliable than key)
        final recipeNameFinder = find.text(testRecipeName);
        var foundRecipe = recipeNameFinder.evaluate().isNotEmpty;

        if (!foundRecipe) {
          print('⚠ Recipe not immediately visible, trying to scroll');

          // Try to find the scrollable list and scroll
          final scrollables = find.byType(Scrollable);
          if (scrollables.evaluate().isNotEmpty) {
            // Scroll down to find the recipe
            for (int i = 0; i < 5 && !foundRecipe; i++) {
              await tester.drag(scrollables.last, const Offset(0, -300));
              await tester.pumpAndSettle();
              foundRecipe = recipeNameFinder.evaluate().isNotEmpty;
              if (foundRecipe) {
                print('✓ Found recipe after ${i + 1} scroll(s)');
                break;
              }
            }
          }
        }

        expect(foundRecipe, true,
            reason: 'Test recipe should appear in all recipes list');
        print('✓ Test recipe found in all recipes list');

        // Now find the recipe card by key for tapping
        final recipeCardKey = Key('recipe_card_$testRecipeId');
        final recipeCardFinder = find.byKey(recipeCardKey);

        expect(recipeCardFinder, findsOneWidget,
            reason: 'Recipe card with key should exist');
        print('✓ Recipe card key found');

        // ==================================================================
        // ACT: Select Recipe
        // ==================================================================

        print('\n=== SELECTING RECIPE ===');
        await tester.tap(recipeCardFinder);
        await tester.pumpAndSettle();
        print('✓ Tapped recipe card');

        // ==================================================================
        // VERIFY: Dialog Closed
        // ==================================================================

        print('\n=== VERIFYING DIALOG CLOSED ===');
        expect(
          find.text('Selecionar Receita'),
          findsNothing,
          reason: 'Recipe selection dialog should be closed',
        );
        print('✓ Dialog is closed');

        // ==================================================================
        // VERIFY: Recipe Appears in Calendar Slot
        // ==================================================================

        print('\n=== VERIFYING RECIPE IN CALENDAR SLOT ===');

        // Wait for UI to update
        await E2ETestHelpers.waitForAsyncOperations();

        // Look for the recipe name in the UI
        final calendarRecipeNameFinder = find.text(testRecipeName);
        var foundInUI = calendarRecipeNameFinder.evaluate().isNotEmpty;

        if (!foundInUI) {
          print('⚠ Recipe name not immediately visible, trying to scroll');

          // Try scrolling to find the recipe
          final scrollables = find.byType(Scrollable);
          if (scrollables.evaluate().isNotEmpty) {
            await tester.drag(scrollables.first, const Offset(0, -100));
            await tester.pumpAndSettle();
            foundInUI = calendarRecipeNameFinder.evaluate().isNotEmpty;
          }
        }

        expect(foundInUI, true,
            reason: 'Recipe name should appear in calendar slot');
        print('✓ Recipe appears in calendar slot');

        print('\n✅ SUCCESS! All recipes tab selection test passed!');

        // ==================================================================
        // CLEANUP
        // ==================================================================

        print('\n=== CLEANING UP ===');

        await dbHelper.deleteRecipe(createdRecipeId);
        print('✓ Test recipe deleted');

        print('✅ CLEANUP COMPLETE!');
      } catch (e, stackTrace) {
        print('❌ TEST FAILED: $e');
        print('Stack trace: $stackTrace');

        // Attempt cleanup even on failure
        final dbHelper = DatabaseHelper();

        if (createdRecipeId != null) {
          try {
            await dbHelper.deleteRecipe(createdRecipeId);
            print('✓ Cleanup: Test recipe deleted');
          } catch (cleanupError) {
            print('⚠ Cleanup failed for recipe: $cleanupError');
          }
        }

        rethrow;
      }
    });
  });
}
