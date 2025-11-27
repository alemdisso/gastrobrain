// integration_test/e2e_recipe_selection_all_recipes_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gastrobrain/database/database_helper.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/models/meal_plan_item.dart';
import 'package:gastrobrain/utils/id_generator.dart';
import 'helpers/e2e_test_helpers.dart';

/// All Recipes Tab Selection E2E Test
///
/// This test verifies the workflow of selecting a recipe from the
/// "All Recipes" tab and adding it to the meal plan:
/// 1. Navigate to Meal Plan tab
/// 2. Tap calendar slot (Friday lunch)
/// 3. Switch to "All Recipes" tab
/// 4. Select recipe from all recipes list
/// 5. Verify recipe appears in calendar slot
/// 6. Verify database persistence
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

        // ==================================================================
        // VERIFY: Test Recipe Appears in All Recipes List
        // ==================================================================

        print('\n=== VERIFYING TEST RECIPE IN ALL RECIPES LIST ===');

        // The recipe card should be findable by its key
        final recipeCardKey = Key('recipe_card_$testRecipeId');
        final recipeCardFinder = find.byKey(recipeCardKey);

        // The recipe might not be immediately visible - try scrolling
        var foundRecipeCard = recipeCardFinder.evaluate().isNotEmpty;

        if (!foundRecipeCard) {
          print('⚠ Recipe card not immediately visible, trying to scroll');

          // Try to find the scrollable list and scroll
          final scrollables = find.byType(Scrollable);
          if (scrollables.evaluate().isNotEmpty) {
            // Scroll down to find the recipe
            await tester.drag(scrollables.last, const Offset(0, -300));
            await tester.pumpAndSettle();
            foundRecipeCard = recipeCardFinder.evaluate().isNotEmpty;

            // If still not found, try scrolling more
            if (!foundRecipeCard) {
              await tester.drag(scrollables.last, const Offset(0, -300));
              await tester.pumpAndSettle();
              foundRecipeCard = recipeCardFinder.evaluate().isNotEmpty;
            }
          }
        }

        expect(foundRecipeCard, true,
            reason: 'Recipe card should be present in all recipes list');
        print('✓ Test recipe found in all recipes list');

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
        final recipeNameFinder = find.text(testRecipeName);
        var foundInUI = recipeNameFinder.evaluate().isNotEmpty;

        if (!foundInUI) {
          print('⚠ Recipe name not immediately visible, trying to scroll');

          // Try scrolling to find the recipe
          final scrollables = find.byType(Scrollable);
          if (scrollables.evaluate().isNotEmpty) {
            await tester.drag(scrollables.first, const Offset(0, -100));
            await tester.pumpAndSettle();
            foundInUI = recipeNameFinder.evaluate().isNotEmpty;
          }
        }

        expect(foundInUI, true,
            reason: 'Recipe name should appear in calendar slot');
        print('✓ Recipe appears in calendar slot');

        // ==================================================================
        // VERIFY: Database Persistence
        // ==================================================================

        print('\n=== VERIFYING DATABASE PERSISTENCE ===');

        // Calculate week start (Friday is start of week in this app)
        final now = DateTime.now();
        final weekStart = DateTime(
          now.year,
          now.month,
          now.day - (now.weekday < 5 ? now.weekday + 2 : now.weekday - 5),
        );

        // Verify meal plan was created
        final savedPlan = await dbHelper.getMealPlanForWeek(weekStart);
        expect(savedPlan, isNotNull,
            reason: 'Meal plan should exist in database');
        createdMealPlanId = savedPlan!.id;
        print('✓ Meal plan found in database: $createdMealPlanId');

        // Verify meal plan has items
        expect(savedPlan.items.length, greaterThan(0),
            reason: 'Meal plan should have at least one item');
        print('✓ Meal plan has ${savedPlan.items.length} item(s)');

        // Verify Friday lunch item exists
        final lunchItems = savedPlan.items
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

        print('\n✅ SUCCESS! All recipes tab selection test passed!');

        // ==================================================================
        // CLEANUP
        // ==================================================================

        print('\n=== CLEANING UP ===');

        await dbHelper.deleteMealPlan(createdMealPlanId);
        print('✓ Meal plan deleted');

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
