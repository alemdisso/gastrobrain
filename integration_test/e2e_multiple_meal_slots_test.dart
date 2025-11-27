// integration_test/e2e_multiple_meal_slots_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gastrobrain/database/database_helper.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/models/meal_plan_item.dart';
import 'package:gastrobrain/utils/id_generator.dart';
import 'helpers/e2e_test_helpers.dart';

/// Multiple Meal Slots E2E Test
///
/// This test verifies that users can add recipes to multiple calendar slots
/// in a single session:
/// 1. Navigate to Meal Plan tab
/// 2. Add recipe to Friday lunch
/// 3. Add recipe to Friday dinner
/// 4. Verify both recipes appear in their respective slots
/// 5. Verify database has both meal plan items
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

        await E2ETestHelpers.waitForAsyncOperations();

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
        print('✓ Selected lunch recipe');

        // Verify dialog closed
        expect(find.text('Selecionar Receita'), findsNothing,
            reason: 'Dialog should be closed');
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
        print('✓ Selected dinner recipe');

        // Verify dialog closed
        expect(find.text('Selecionar Receita'), findsNothing,
            reason: 'Dialog should be closed');
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
            await tester.drag(scrollables.first, const Offset(0, -100));
            await tester.pumpAndSettle();
            foundLunchInUI = lunchNameFinder.evaluate().isNotEmpty;
          }
        }

        expect(foundLunchInUI, true,
            reason: 'Lunch recipe should appear in calendar');
        print('✓ Lunch recipe appears in calendar');

        // Verify dinner recipe appears
        final dinnerNameFinder = find.text(dinnerRecipeName);
        final foundDinnerInUI = dinnerNameFinder.evaluate().isNotEmpty;

        expect(foundDinnerInUI, true,
            reason: 'Dinner recipe should appear in calendar');
        print('✓ Dinner recipe appears in calendar');

        // ==================================================================
        // VERIFY: Database Persistence
        // ==================================================================

        print('\n=== VERIFYING DATABASE PERSISTENCE ===');

        // Calculate week start
        final now = DateTime.now();
        final weekStart = DateTime(
          now.year,
          now.month,
          now.day - (now.weekday < 5 ? now.weekday + 2 : now.weekday - 5),
        );

        // Verify meal plan exists
        final savedPlan = await dbHelper.getMealPlanForWeek(weekStart);
        expect(savedPlan, isNotNull,
            reason: 'Meal plan should exist in database');
        createdMealPlanId = savedPlan!.id;
        print('✓ Meal plan found in database: $createdMealPlanId');

        // Verify meal plan has both lunch and dinner items
        expect(savedPlan.items.length, greaterThanOrEqualTo(2),
            reason: 'Meal plan should have at least 2 items (lunch and dinner)');
        print('✓ Meal plan has ${savedPlan.items.length} item(s)');

        // Verify lunch item
        final lunchItems = savedPlan.items
            .where((item) => item.mealType == MealPlanItem.lunch)
            .toList();
        expect(lunchItems.length, greaterThan(0),
            reason: 'Should have at least one lunch item');

        final lunchItem = lunchItems.first;
        expect(lunchItem.mealPlanItemRecipes, isNotEmpty,
            reason: 'Lunch item should have recipes');
        expect(lunchItem.mealPlanItemRecipes!.first.recipeId,
            equals(lunchRecipeId),
            reason: 'Lunch item should be linked to lunch recipe');
        print('✓ Lunch recipe correctly linked in database');

        // Verify dinner item
        final dinnerItems = savedPlan.items
            .where((item) => item.mealType == MealPlanItem.dinner)
            .toList();
        expect(dinnerItems.length, greaterThan(0),
            reason: 'Should have at least one dinner item');

        final dinnerItem = dinnerItems.first;
        expect(dinnerItem.mealPlanItemRecipes, isNotEmpty,
            reason: 'Dinner item should have recipes');
        expect(dinnerItem.mealPlanItemRecipes!.first.recipeId,
            equals(dinnerRecipeId),
            reason: 'Dinner item should be linked to dinner recipe');
        print('✓ Dinner recipe correctly linked in database');

        // Verify both are marked as primary dishes
        expect(lunchItem.mealPlanItemRecipes!.first.isPrimaryDish, true);
        expect(dinnerItem.mealPlanItemRecipes!.first.isPrimaryDish, true);
        print('✓ Both recipes marked as primary dishes');

        print('\n✅ SUCCESS! Multiple meal slots test passed!');

        // ==================================================================
        // CLEANUP
        // ==================================================================

        print('\n=== CLEANING UP ===');

        await dbHelper.deleteMealPlan(createdMealPlanId);
        print('✓ Meal plan deleted');

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

        if (createdMealPlanId != null) {
          try {
            await dbHelper.deleteMealPlan(createdMealPlanId);
            print('✓ Cleanup: Meal plan deleted');
          } catch (cleanupError) {
            print('⚠ Cleanup failed for meal plan: $cleanupError');
          }
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
