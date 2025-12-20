// integration_test/e2e_multiple_meal_slots_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gastrobrain/database/database_helper.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/meal_plan_item.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/utils/id_generator.dart';
import 'helpers/e2e_test_helpers.dart';

/// Multiple Meal Slots E2E Test
///
/// This test verifies the UI workflow for adding recipes to multiple calendar
/// slots in a single session:
/// 1. Navigate to Meal Plan tab
/// 2. Add recipe to Friday lunch
/// 3. Add recipe to Friday dinner
/// 4. Verify both recipes appear in their respective slots
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E - Multiple Meal Slots', () {
    testWidgets('Add recipes to multiple slots in same session',
        (WidgetTester tester) async {
      // ======================================================================
      // TEST DATA SETUP
      // ======================================================================

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final lunchRecipeName = 'E2E Lunch Recipe $timestamp';
      final dinnerRecipeName = 'E2E Dinner Recipe $timestamp';
      final lunchRecipeId = IdGenerator.generateId();
      final dinnerRecipeId = IdGenerator.generateId();

      String? createdLunchRecipeId;
      String? createdDinnerRecipeId;

      // Helper function to calculate Friday date (same logic as _getFriday in weekly_plan_screen.dart)
      DateTime getFridayDate() {
        final now = DateTime.now();
        final weekday = now.weekday;
        final daysToSubtract = weekday < 5
            ? weekday + 2 // Go back to previous Friday
            : weekday - 5; // Friday is day 5
        return now.subtract(Duration(days: daysToSubtract));
      }

      try {
        // ==================================================================
        // SETUP: Launch and Initialize
        // ==================================================================

        print('=== LAUNCHING APP ===');
        await E2ETestHelpers.launchApp(tester);
        print('✓ App launched and initialized');

        final dbHelper = DatabaseHelper();
        final fridayDate = getFridayDate(); // Calculate once and reuse

        // ==================================================================
        // SETUP: Clean up any existing meal plan items for Friday
        // ==================================================================

        print('\n=== CLEANING UP EXISTING FRIDAY MEAL PLANS ===');

        // Get all meal plan items for Friday
        final existingFridayItems =
            await dbHelper.getMealPlanItemsForDate(fridayDate);

        // Delete existing Friday lunch and dinner items
        for (final item in existingFridayItems) {
          if (item.mealType == MealPlanItem.lunch ||
              item.mealType == MealPlanItem.dinner) {
            await dbHelper.deleteMealPlanItem(item.id);
            print('✓ Deleted existing ${item.mealType} item for Friday');
          }
        }

        print('✓ Friday slots cleared');

        // ==================================================================
        // SETUP: Create Test Recipes
        // ==================================================================

        print('\n=== CREATING TEST RECIPES ===');

        // Create lunch recipe
        final lunchRecipe = Recipe(
          id: lunchRecipeId,
          name: lunchRecipeName,
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          prepTimeMinutes: 15,
          cookTimeMinutes: 20,
          difficulty: 1,
          rating: 5,
        );

        await dbHelper.insertRecipe(lunchRecipe);
        createdLunchRecipeId = lunchRecipeId;
        print('✓ Lunch recipe created: $lunchRecipeName');

        // Create dinner recipe
        final dinnerRecipe = Recipe(
          id: dinnerRecipeId,
          name: dinnerRecipeName,
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          prepTimeMinutes: 25,
          cookTimeMinutes: 35,
          difficulty: 2,
          rating: 4,
        );

        await dbHelper.insertRecipe(dinnerRecipe);
        createdDinnerRecipeId = dinnerRecipeId;
        print('✓ Dinner recipe created: $dinnerRecipeName');

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

        // Wait for meal plan to load and settle
        await E2ETestHelpers.waitForAsyncOperations();
        await tester.pumpAndSettle();
        await Future.delayed(const Duration(milliseconds: 500)); // Extra wait for UI
        await tester.pumpAndSettle();

        // ==================================================================
        // ACT: Add Recipe to Friday Lunch
        // ==================================================================

        print('\n=== ADDING RECIPE TO FRIDAY LUNCH ===');

        // Tap Friday lunch slot
        final lunchSlotKey = const Key('meal_plan_friday_lunch_slot');
        final lunchSlotFinder = find.byKey(lunchSlotKey);

        expect(lunchSlotFinder, findsOneWidget,
            reason: 'Friday lunch slot should exist');
        print('✓ Found Friday lunch slot');

        await tester.tap(lunchSlotFinder);
        await tester.pumpAndSettle();
        print('✓ Tapped Friday lunch slot');

        // Add extra wait time for dialog to open
        await E2ETestHelpers.waitForAsyncOperations();
        await tester.pumpAndSettle();

        // Debug: Check what's actually on screen
        print('🔍 Checking what dialogs are visible after lunch tap...');
        var selectRecipeDialog = find.text('Selecionar Receita');
        var mealOptionsDialog = find.text('Opções de Refeição');

        print('   - "Selecionar Receita": ${selectRecipeDialog.evaluate().length} found');
        print('   - "Opções de Refeição": ${mealOptionsDialog.evaluate().length} found');

        // If meal already exists, remove it first
        if (mealOptionsDialog.evaluate().isNotEmpty) {
          print('⚠ WARNING: Found existing meal in lunch slot, removing it');
          final removeOption = find.text('Remover');
          if (removeOption.evaluate().isNotEmpty) {
            await tester.tap(removeOption);
            await tester.pumpAndSettle();
            print('✓ Tapped Remover');

            // Confirm removal
            final confirmButton = find.text('Remover').last;
            if (confirmButton.evaluate().isNotEmpty) {
              await tester.tap(confirmButton);
              await tester.pumpAndSettle();
              print('✓ Confirmed removal');
            }

            // Tap lunch slot again
            await tester.tap(lunchSlotFinder);
            await tester.pumpAndSettle();
            await E2ETestHelpers.waitForAsyncOperations();
            print('✓ Tapped lunch slot again after removal');
          }
        }

        // Verify dialog opened
        expect(find.text('Selecionar Receita'), findsOneWidget,
            reason: 'Recipe selection dialog should be open');
        print('✓ Recipe selection dialog opened');

        // Wait for recommendations to load
        await E2ETestHelpers.waitForAsyncOperations();

        // Find lunch recipe by name first
        var lunchRecipeNameFinder = find.text(lunchRecipeName);
        var foundLunchRecipe = lunchRecipeNameFinder.evaluate().isNotEmpty;

        if (!foundLunchRecipe) {
          print('⚠ Lunch recipe not immediately visible, scrolling...');
          final scrollables = find.byType(Scrollable);
          if (scrollables.evaluate().isNotEmpty) {
            for (int i = 0; i < 3 && !foundLunchRecipe; i++) {
              await tester.drag(scrollables.last, const Offset(0, -300));
              await tester.pumpAndSettle();
              foundLunchRecipe = lunchRecipeNameFinder.evaluate().isNotEmpty;
            }
          }
        }

        expect(foundLunchRecipe, true,
            reason: 'Lunch recipe should appear in list');

        // Now find and tap the recipe card by key
        final lunchRecipeCardKey = Key('recipe_card_$lunchRecipeId');
        final lunchRecipeCardFinder = find.byKey(lunchRecipeCardKey);

        expect(lunchRecipeCardFinder, findsOneWidget,
            reason: 'Lunch recipe card should be present');
        await tester.tap(lunchRecipeCardFinder);
        await tester.pumpAndSettle();
        print('✓ Tapped lunch recipe card');

        // Verify menu appears
        expect(find.text('Opções de Refeição'), findsOneWidget,
            reason: 'Menu should be showing after recipe selection');
        print('✓ Menu is showing');

        // Find and tap the Save button
        final lunchSaveButton = find.text('Salvar');
        expect(lunchSaveButton, findsOneWidget,
            reason: 'Save button should exist');

        await tester.tap(lunchSaveButton, warnIfMissed: false);
        await tester.pumpAndSettle();
        print('✓ Tapped Save button');

        // Verify dialog closed
        expect(find.text('Opções de Refeição'), findsNothing,
            reason: 'Menu dialog should be closed');
        print('✓ Dialog closed');

        // Wait for UI to update
        await E2ETestHelpers.waitForAsyncOperations();

        // ==================================================================
        // ACT: Add Recipe to Friday Dinner
        // ==================================================================

        print('\n=== ADDING RECIPE TO FRIDAY DINNER ===');

        // Tap Friday dinner slot
        final dinnerSlotKey = const Key('meal_plan_friday_dinner_slot');
        final dinnerSlotFinder = find.byKey(dinnerSlotKey);

        expect(dinnerSlotFinder, findsOneWidget,
            reason: 'Friday dinner slot should exist');
        print('✓ Found Friday dinner slot');

        await tester.tap(dinnerSlotFinder);
        await tester.pumpAndSettle();
        print('✓ Tapped Friday dinner slot');

        // Add extra wait time for any async operations
        await E2ETestHelpers.waitForAsyncOperations();
        await tester.pumpAndSettle();

        // Debug: Check what's actually on screen
        print('🔍 Checking what dialogs are visible after dinner tap...');
        // Reuse variables from lunch section (already declared)
        // ignore: prefer_final_locals
        selectRecipeDialog = find.text('Selecionar Receita');
        // ignore: prefer_final_locals
        mealOptionsDialog = find.text('Opções de Refeição');
        final editDialog = find.text('Editar Registro de Refeição');

        print('   - "Selecionar Receita": ${selectRecipeDialog.evaluate().length} found');
        print('   - "Opções de Refeição": ${mealOptionsDialog.evaluate().length} found');
        print('   - "Editar Registro de Refeição": ${editDialog.evaluate().length} found');

        // If we find a meal options dialog, it means there's already a meal in this slot
        if (mealOptionsDialog.evaluate().isNotEmpty) {
          print('⚠ WARNING: Found existing meal in dinner slot, need to remove it first');

          // Find and tap the "Remover" option
          final removeOption = find.text('Remover');
          if (removeOption.evaluate().isNotEmpty) {
            await tester.tap(removeOption);
            await tester.pumpAndSettle();
            print('✓ Tapped Remover option');

            // Confirm removal if there's a confirmation dialog
            final confirmButton = find.text('Remover').last;
            if (confirmButton.evaluate().isNotEmpty) {
              await tester.tap(confirmButton);
              await tester.pumpAndSettle();
              print('✓ Confirmed removal');
            }

            // Now tap the dinner slot again to add a new meal
            await tester.tap(dinnerSlotFinder);
            await tester.pumpAndSettle();
            await E2ETestHelpers.waitForAsyncOperations();
            print('✓ Tapped dinner slot again after removal');
          } else {
            // No remove option, just close the dialog
            final cancelButton = find.text('Cancelar');
            if (cancelButton.evaluate().isNotEmpty) {
              await tester.tap(cancelButton.first);
              await tester.pumpAndSettle();
              print('✓ Closed meal options dialog');
            }
          }
        }

        // Verify dialog opened
        expect(find.text('Selecionar Receita'), findsOneWidget,
            reason: 'Recipe selection dialog should be open');
        print('✓ Recipe selection dialog opened');

        // Wait for recommendations to load
        await E2ETestHelpers.waitForAsyncOperations();

        // Find dinner recipe by name first
        var dinnerRecipeNameFinder = find.text(dinnerRecipeName);
        var foundDinnerRecipe = dinnerRecipeNameFinder.evaluate().isNotEmpty;

        if (!foundDinnerRecipe) {
          print('⚠ Dinner recipe not immediately visible, scrolling...');
          final scrollables = find.byType(Scrollable);
          if (scrollables.evaluate().isNotEmpty) {
            for (int i = 0; i < 3 && !foundDinnerRecipe; i++) {
              await tester.drag(scrollables.last, const Offset(0, -300));
              await tester.pumpAndSettle();
              foundDinnerRecipe = dinnerRecipeNameFinder.evaluate().isNotEmpty;
            }
          }
        }

        expect(foundDinnerRecipe, true,
            reason: 'Dinner recipe should appear in list');

        // Now find and tap the recipe card by key
        final dinnerRecipeCardKey = Key('recipe_card_$dinnerRecipeId');
        final dinnerRecipeCardFinder = find.byKey(dinnerRecipeCardKey);

        expect(dinnerRecipeCardFinder, findsOneWidget,
            reason: 'Dinner recipe card should be present');
        await tester.tap(dinnerRecipeCardFinder);
        await tester.pumpAndSettle();
        print('✓ Tapped dinner recipe card');

        // Verify menu appears
        expect(find.text('Opções de Refeição'), findsOneWidget,
            reason: 'Menu should be showing after recipe selection');
        print('✓ Menu is showing');

        // Find and tap the Save button
        final dinnerSaveButton = find.text('Salvar');
        expect(dinnerSaveButton, findsOneWidget,
            reason: 'Save button should exist');

        await tester.tap(dinnerSaveButton, warnIfMissed: false);
        await tester.pumpAndSettle();
        print('✓ Tapped Save button');

        // Verify dialog closed
        expect(find.text('Opções de Refeição'), findsNothing,
            reason: 'Menu dialog should be closed');
        print('✓ Dialog closed');

        // Wait for UI to update
        await E2ETestHelpers.waitForAsyncOperations();

        // ==================================================================
        // VERIFY: Both Recipes Appear in Calendar
        // ==================================================================

        print('\n=== VERIFYING RECIPES IN CALENDAR ===');

        // Verify lunch recipe appears
        var lunchNameFinder = find.text(lunchRecipeName);
        var foundLunchInUI = lunchNameFinder.evaluate().isNotEmpty;

        if (!foundLunchInUI) {
          print('⚠ Lunch recipe not immediately visible, scrolling...');
          final scrollables = find.byType(Scrollable);
          if (scrollables.evaluate().isNotEmpty) {
            await tester.drag(scrollables.first, const Offset(0, -100),
                warnIfMissed: false);
            await tester.pumpAndSettle();
            foundLunchInUI = lunchNameFinder.evaluate().isNotEmpty;
          }
        }

        expect(foundLunchInUI, true,
            reason: 'Lunch recipe should appear in calendar');
        print('✓ Lunch recipe appears in calendar');

        // Verify dinner recipe appears
        var dinnerNameFinder = find.text(dinnerRecipeName);
        var foundDinnerInUI = dinnerNameFinder.evaluate().isNotEmpty;

        if (!foundDinnerInUI) {
          print('⚠ Dinner recipe not immediately visible, scrolling...');
          final scrollables = find.byType(Scrollable);
          if (scrollables.evaluate().isNotEmpty) {
            // Try scrolling down to find dinner
            for (int i = 0; i < 3 && !foundDinnerInUI; i++) {
              await tester.drag(scrollables.first, const Offset(0, -200),
                  warnIfMissed: false);
              await tester.pumpAndSettle();
              foundDinnerInUI = dinnerNameFinder.evaluate().isNotEmpty;
              if (foundDinnerInUI) {
                print('✓ Found dinner recipe after scrolling ${i + 1} times');
                break;
              }
            }
          }

          // If still not found, try scrolling horizontally (might be in different column)
          if (!foundDinnerInUI) {
            print('⚠ Trying horizontal scroll...');
            final scrollables = find.byType(Scrollable);
            if (scrollables.evaluate().length > 1) {
              await tester.drag(scrollables.at(1), const Offset(-200, 0),
                  warnIfMissed: false);
              await tester.pumpAndSettle();
              foundDinnerInUI = dinnerNameFinder.evaluate().isNotEmpty;
            }
          }
        }

        expect(foundDinnerInUI, true,
            reason: 'Dinner recipe should appear in calendar');
        print('✓ Dinner recipe appears in calendar');

        print('\n✅ SUCCESS! Multiple meal slots test passed!');

        // ==================================================================
        // CLEANUP
        // ==================================================================

        print('\n=== CLEANING UP ===');

        // Delete meal plan items created during test
        final createdFridayItems =
            await dbHelper.getMealPlanItemsForDate(fridayDate);
        for (final item in createdFridayItems) {
          await dbHelper.deleteMealPlanItem(item.id);
          print('✓ Deleted ${item.mealType} meal plan item');
        }

        await dbHelper.deleteRecipe(createdLunchRecipeId);
        print('✓ Lunch recipe deleted');

        await dbHelper.deleteRecipe(createdDinnerRecipeId);
        print('✓ Dinner recipe deleted');

        print('✅ CLEANUP COMPLETE!');
      } catch (e, stackTrace) {
        print('❌ TEST FAILED: $e');
        print('Stack trace: $stackTrace');

        // Attempt cleanup even on failure
        final dbHelper = DatabaseHelper();

        // Clean up meal plan items
        try {
          final now = DateTime.now();
          final weekday = now.weekday;
          final daysToSubtract = weekday < 5
              ? weekday + 2 // Go back to previous Friday
              : weekday - 5; // Friday is day 5
          final fridayDate = now.subtract(Duration(days: daysToSubtract));

          final fridayItems = await dbHelper.getMealPlanItemsForDate(fridayDate);
          for (final item in fridayItems) {
            await dbHelper.deleteMealPlanItem(item.id);
          }
          print('✓ Cleanup: Friday meal plan items deleted');
        } catch (cleanupError) {
          print('⚠ Cleanup failed for meal plan items: $cleanupError');
        }

        if (createdLunchRecipeId != null) {
          try {
            await dbHelper.deleteRecipe(createdLunchRecipeId);
            print('✓ Cleanup: Lunch recipe deleted');
          } catch (cleanupError) {
            print('⚠ Cleanup failed for lunch recipe: $cleanupError');
          }
        }

        if (createdDinnerRecipeId != null) {
          try {
            await dbHelper.deleteRecipe(createdDinnerRecipeId);
            print('✓ Cleanup: Dinner recipe deleted');
          } catch (cleanupError) {
            print('⚠ Cleanup failed for dinner recipe: $cleanupError');
          }
        }

        rethrow;
      }
    });
  });
}
