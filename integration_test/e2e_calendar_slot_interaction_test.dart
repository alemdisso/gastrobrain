// integration_test/e2e_calendar_slot_interaction_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gastrobrain/database/database_helper.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/utils/id_generator.dart';
import 'helpers/e2e_test_helpers.dart';

/// Calendar Slot Interaction E2E Test
///
/// This test verifies calendar slot interaction:
/// 1. Navigate to Meal Plan tab
/// 2. Tap specific calendar slot using key
/// 3. Verify recipe selection dialog opens
/// 4. Verify dialog components are accessible
/// 5. Cancel dialog
/// 6. Verify calendar state unchanged
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E - Calendar Slot Interaction', () {
    testWidgets('Tap calendar slot opens recipe selection dialog',
        (WidgetTester tester) async {
      // ======================================================================
      // TEST DATA SETUP
      // ======================================================================

      final testRecipeName =
          'E2E Slot Test Recipe ${DateTime.now().millisecondsSinceEpoch}';
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
        // SETUP: Create Test Recipe for Recommendations
        // ==================================================================

        print('\n=== CREATING TEST RECIPE ===');
        final testRecipe = Recipe(
          id: testRecipeId,
          name: testRecipeName,
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          prepTimeMinutes: 20,
          cookTimeMinutes: 30,
          difficulty: 2,
          rating: 4,
        );

        await dbHelper.insertRecipe(testRecipe);
        createdRecipeId = testRecipeId;
        print('✓ Test recipe created: $testRecipeName');

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
        // Use the key from Phase 1: meal_plan_friday_lunch_slot
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

        // Check for dialog title
        expect(
          find.text('Selecionar Receita'), // Portuguese: "Select Recipe"
          findsOneWidget,
          reason: 'Recipe selection dialog should be open',
        );
        print('✓ Recipe selection dialog is open');

        // Verify tabs are present using keys from Phase 1
        final recommendedTab =
            find.byKey(const Key('recipe_selection_recommended_tab'));
        final allRecipesTab =
            find.byKey(const Key('recipe_selection_all_tab'));

        expect(recommendedTab, findsOneWidget,
            reason: 'Recommended tab should exist');
        expect(allRecipesTab, findsOneWidget,
            reason: 'All Recipes tab should exist');
        print('✓ Both tabs are present');

        // Verify cancel button is present
        final cancelButton =
            find.byKey(const Key('recipe_selection_cancel_button'));
        expect(cancelButton, findsOneWidget,
            reason: 'Cancel button should exist');
        print('✓ Cancel button is present');

        // ==================================================================
        // ACT: Cancel Dialog
        // ==================================================================

        print('\n=== CANCELING DIALOG ===');
        await tester.tap(cancelButton);
        await tester.pumpAndSettle();
        print('✓ Tapped cancel button');

        // ==================================================================
        // VERIFY: Dialog Closed, Calendar State Unchanged
        // ==================================================================

        print('\n=== VERIFYING DIALOG CLOSED ===');

        // Verify dialog is closed
        expect(
          find.text('Selecionar Receita'),
          findsNothing,
          reason: 'Recipe selection dialog should be closed',
        );
        print('✓ Dialog is closed');

        // Verify still on meal plan screen
        expect(
          find.byKey(slotKey),
          findsOneWidget,
          reason: 'Should still be on meal plan screen',
        );
        print('✓ Still on meal plan screen');

        // Verify slot is still empty (no recipe added)
        // The slot should show "Adicionar Refeição" (Add Meal) text
        expect(
          find.text('Adicionar Refeição'),
          findsWidgets,
          reason: 'Empty slots should show "Add Meal" text',
        );
        print('✓ Calendar state unchanged - no meal added');

        print('\n✅ SUCCESS! Calendar slot interaction test passed!');

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
            print('⚠ Cleanup failed: $cleanupError');
          }
        }

        rethrow;
      }
    });
  });
}
