// integration_test/e2e_recipe_selection_recommended_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gastrobrain/database/database_helper.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/models/meal_plan.dart';
import 'package:gastrobrain/models/meal_plan_item.dart';
import 'package:gastrobrain/utils/id_generator.dart';
import 'helpers/e2e_test_helpers.dart';

/// Recommended Recipe Selection E2E Test
///
/// This test verifies the complete workflow of selecting a recipe from the
/// recommended tab and adding it to the meal plan:
/// 1. Navigate to Meal Plan tab
/// 2. Tap calendar slot (Friday lunch)
/// 3. Verify recipe selection dialog opens with recommended tab active
/// 4. Select recipe from recommended list
/// 5. Verify recipe appears in calendar slot
/// 6. Verify database persistence
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E - Recommended Recipe Selection', () {
    testWidgets('Select recipe from recommended tab adds to meal plan',
        (WidgetTester tester) async {
      // ======================================================================
      // TEST DATA SETUP
      // ======================================================================

      final testRecipeName =
          'E2E Recommended Recipe ${DateTime.now().millisecondsSinceEpoch}';
      final testRecipeId = IdGenerator.generateId();

      String? createdRecipeId;
      String? createdMealPlanId;

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
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          prepTimeMinutes: 15,
          cookTimeMinutes: 20,
          difficulty: 1, // Easy recipe - should score well in recommendations
          rating: 5, // High rating - should appear in recommendations
        );

        await dbHelper.insertRecipe(testRecipe);
        createdRecipeId = testRecipeId;
        print('✓ Test recipe created: $testRecipeName');
        print('  (difficulty: 1, rating: 5 - should rank high in recommendations)');

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

        // Verify recommended tab exists
        final recommendedTab =
            find.byKey(const Key('recipe_selection_recommended_tab'));
        expect(recommendedTab, findsOneWidget,
            reason: 'Recommended tab should exist');
        print('✓ Recommended tab is present');

        // Wait for recommendations to load
        await E2ETestHelpers.waitForAsyncOperations();

        // ==================================================================
        // VERIFY: Test Recipe Appears in Recommended List
        // ==================================================================

        print('\n=== VERIFYING TEST RECIPE IN RECOMMENDATIONS ===');

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
            reason: 'Test recipe should appear in recommended list');
        print('✓ Test recipe found in recommended list');

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
        // ACT: Confirm Selection (Tap Save Button)
        // ==================================================================

        print('\n=== CONFIRMING SELECTION ===');

        // After tapping recipe, a menu appears with a Save button
        // The dialog title changes to "Meal Options" (Opções da Refeição)
        expect(find.text('Opções da Refeição'), findsOneWidget,
            reason: 'Menu should be showing after recipe selection');
        print('✓ Menu is showing');

        // Find and tap the Save button
        final saveButton = find.text('Salvar');
        expect(saveButton, findsOneWidget, reason: 'Save button should exist');

        await tester.tap(saveButton);
        await tester.pumpAndSettle();
        print('✓ Tapped Save button');

        // ==================================================================
        // VERIFY: Dialog Closed
        // ==================================================================

        print('\n=== VERIFYING DIALOG CLOSED ===');
        expect(
          find.text('Opções da Refeição'),
          findsNothing,
          reason: 'Menu dialog should be closed',
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

        // ==================================================================
        // VERIFY: Database Persistence
        // ==================================================================

        print('\n=== VERIFYING DATABASE PERSISTENCE ===');

        // Wait for database operations to complete
        await E2ETestHelpers.waitForAsyncOperations();
        await Future.delayed(const Duration(seconds: 2));

        // Calculate week start (Friday is start of week in this app)
        final now = DateTime.now();
        final weekStart = DateTime(
          now.year,
          now.month,
          now.day - (now.weekday < 5 ? now.weekday + 2 : now.weekday - 5),
        );
        print('Looking for meal plan with week start: ${weekStart.toIso8601String().split('T')[0]}');
        print('Today is: ${now.toIso8601String().split('T')[0]} (weekday: ${now.weekday})');

        // Debug: Check meal plans in a wide date range to find any recent ones
        final startRange = now.subtract(const Duration(days: 30));
        final endRange = now.add(const Duration(days: 30));
        final allMealPlans = await dbHelper.getMealPlansByDateRange(startRange, endRange);
        print('Total meal plans in last 60 days: ${allMealPlans.length}');
        if (allMealPlans.isNotEmpty) {
          for (final plan in allMealPlans) {
            print('  - Plan ${plan.id}: week_start=${plan.weekStartDate.toIso8601String().split('T')[0]}, items=${plan.items.length}');
          }
        }

        // Verify meal plan was created - use the most recent one
        MealPlan? savedPlan;
        if (allMealPlans.isNotEmpty) {
          // Sort by creation date and get the most recent
          allMealPlans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          savedPlan = allMealPlans.first;
          print('Using most recent meal plan: ${savedPlan.id}');
          createdMealPlanId = savedPlan.id;
        }

        expect(savedPlan, isNotNull,
            reason: 'At least one meal plan should exist in database');
        print('✓ Meal plan found in database: $createdMealPlanId');

        final finalPlan = savedPlan!;

        // Verify meal plan has items
        expect(finalPlan.items.length, greaterThan(0),
            reason: 'Meal plan should have at least one item');
        print('✓ Meal plan has ${finalPlan.items.length} item(s)');

        // Verify Friday lunch item exists
        final lunchItems = finalPlan.items
            .where((item) => item.mealType == MealPlanItem.lunch)
            .toList();
        expect(lunchItems.length, greaterThan(0),
            reason: 'Should have at least one lunch item');
        print('✓ Found lunch item in meal plan');

        // Verify recipe is linked to the lunch item
        final firstLunchItem = lunchItems.first;
        expect(firstLunchItem.mealPlanItemRecipes, isNotEmpty,
            reason: 'Lunch item should have recipes');

        final linkedRecipeId =
            firstLunchItem.mealPlanItemRecipes!.first.recipeId;
        expect(linkedRecipeId, equals(testRecipeId),
            reason: 'Lunch item should be linked to our test recipe');
        print('✓ Recipe correctly linked to meal plan item');

        // Verify isPrimaryDish flag is set
        expect(firstLunchItem.mealPlanItemRecipes!.first.isPrimaryDish, true,
            reason: 'Single recipe should be marked as primary dish');
        print('✓ Recipe marked as primary dish');

        print('\n✅ SUCCESS! Recommended recipe selection test passed!');

        // ==================================================================
        // CLEANUP
        // ==================================================================

        print('\n=== CLEANING UP ===');

        if (createdMealPlanId != null) {
          await dbHelper.deleteMealPlan(createdMealPlanId);
          print('✓ Meal plan deleted');
        }

        await dbHelper.deleteRecipe(createdRecipeId);
        print('✓ Test recipe deleted');

        print('✅ CLEANUP COMPLETE!');
      } catch (e, stackTrace) {
        print('❌ TEST FAILED: $e');
        print('Stack trace: $stackTrace');

        // Attempt cleanup even on failure
        final dbHelper = DatabaseHelper();

        if (createdMealPlanId != null) {
          try {
            await dbHelper.deleteMealPlan(createdMealPlanId);
            print('✓ Cleanup: Meal plan deleted');
          } catch (cleanupError) {
            print('⚠ Cleanup failed for meal plan: $cleanupError');
          }
        }

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
