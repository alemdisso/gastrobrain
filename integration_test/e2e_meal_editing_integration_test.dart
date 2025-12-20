/// Meal Editing Integration & Complex Scenarios E2E Test
///
/// This test suite verifies complex real-world scenarios in the meal editing workflow:
/// - Phase 7.2: Success flag editing and UI indicator updates
/// - Phase 7.5: Rapid sequential edits and data integrity
///
/// These tests ensure the app handles complex user workflows correctly.

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

  group('Phase 7: Complex Scenarios & Integration', () {
    testWidgets('7.2: Edit wasSuccessful flag and verify UI indicator updates',
        (WidgetTester tester) async {
      print('\n=== TEST 7.2: Success Flag Edit ===');
      String? testRecipeId;
      String? testMealId;

      try {
        // Launch app
        print('\n=== LAUNCHING APP ===');
        await E2ETestHelpers.launchApp(tester);
        print('✓ App launched and initialized');

        final dbHelper = ServiceProvider.database.helper;

        // Setup: Create test recipe and successful meal
        print('\n=== CREATING TEST DATA ===');
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        testRecipeId = 'e2e-success-flag-recipe-$timestamp';
        testMealId = 'e2e-success-flag-meal-$timestamp';

        final shortId =
            timestamp.toString().substring(timestamp.toString().length - 4);
        final testRecipeName = 'Flag$shortId';

        final testRecipe = Recipe(
          id: testRecipeId,
          name: testRecipeName,
          createdAt: DateTime.now(),
          instructions: 'Test instructions',
          notes: 'Test notes',
          prepTimeMinutes: 15,
          cookTimeMinutes: 30,
          difficulty: 3,
          rating: 4,
        );
        await dbHelper.insertRecipe(testRecipe);

        // Create SUCCESSFUL meal
        final testMeal = Meal(
          id: testMealId,
          cookedAt: DateTime.now().subtract(const Duration(days: 1)),
          servings: 2,
          actualPrepTime: 15.0,
          actualCookTime: 30.0,
          wasSuccessful: true, // Initially successful
          notes: 'Initial notes',
        );
        await dbHelper.insertMeal(testMeal);

        final mealRecipe = MealRecipe(
          mealId: testMealId,
          recipeId: testRecipeId,
          isPrimaryDish: true,
        );
        await dbHelper.insertMealRecipe(mealRecipe);

        print('✓ Test data created: $testRecipeName with successful meal');

        // Refresh and navigate
        print('\n=== REFRESHING AND NAVIGATING ===');
        await E2ETestHelpers.refreshRecipeProvider(tester);
        await E2ETestHelpers.tapBottomNavTab(
            tester, const Key('recipes_tab_icon'));
        await tester.pumpAndSettle();
        await E2ETestHelpers.navigateToMealHistory(tester, testRecipeName);
        print('✓ Navigated to meal history screen');

        // Verify: Initial state shows success indicator (green check)
        print('\n=== VERIFYING INITIAL SUCCESS INDICATOR ===');
        final successIcon = find.byIcon(Icons.check_circle);
        expect(successIcon, findsOneWidget,
            reason: 'Should show check_circle icon for successful meal');
        print('✓ Success indicator (green check) is displayed');

        // Verify warning icon is NOT present initially
        final warningIcon = find.byIcon(Icons.warning);
        expect(warningIcon, findsNothing,
            reason: 'Should NOT show warning icon for successful meal');
        print('✓ Warning icon is not displayed initially');

        // Open edit dialog
        print('\n=== OPENING EDIT DIALOG ===');
        await E2ETestHelpers.openMealEditDialog(tester);
        print('✓ Edit dialog opened');

        // Find and toggle the success switch
        print('\n=== CHANGING SUCCESS FLAG ===');
        final successSwitch = find.byKey(const Key('edit_meal_recording_success_switch'));
        expect(successSwitch, findsOneWidget,
            reason: 'Success switch should be present in edit dialog');

        // Tap switch to change from true to false
        await tester.tap(successSwitch);
        await tester.pumpAndSettle();
        print('✓ Toggled success switch from true to false');

        // Save changes
        print('\n=== SAVING CHANGES ===');
        await E2ETestHelpers.saveMealEditDialog(tester);
        await tester.pumpAndSettle();
        print('✓ Changes saved');

        // Verify: UI now shows failure indicator (orange warning)
        print('\n=== VERIFYING UPDATED FAILURE INDICATOR ===');
        final updatedWarningIcon = find.byIcon(Icons.warning);
        expect(updatedWarningIcon, findsOneWidget,
            reason: 'Should show warning icon after changing to unsuccessful');
        print('✓ Warning indicator (orange warning) is now displayed');

        // Verify success icon is no longer present
        final updatedSuccessIcon = find.byIcon(Icons.check_circle);
        expect(updatedSuccessIcon, findsNothing,
            reason: 'Should NOT show check_circle icon after changing to unsuccessful');
        print('✓ Success icon is no longer displayed');

        // Verify database was updated correctly
        print('\n=== VERIFYING DATABASE UPDATE ===');
        final updatedMeal = await dbHelper.getMeal(testMealId);
        expect(updatedMeal, isNotNull, reason: 'Meal should still exist');
        expect(updatedMeal!.wasSuccessful, false,
            reason: 'wasSuccessful should be updated to false in database');
        print('✓ Database correctly updated wasSuccessful to false');

        // Bonus: Test toggling back to true
        print('\n=== TESTING TOGGLE BACK TO SUCCESS ===');
        await E2ETestHelpers.openMealEditDialog(tester);
        await tester.tap(successSwitch);
        await tester.pumpAndSettle();
        await E2ETestHelpers.saveMealEditDialog(tester);
        await tester.pumpAndSettle();

        final finalSuccessIcon = find.byIcon(Icons.check_circle);
        expect(finalSuccessIcon, findsOneWidget,
            reason: 'Should show check_circle icon after toggling back to successful');
        print('✓ Successfully toggled back to success state');

        final finalMeal = await dbHelper.getMeal(testMealId);
        expect(finalMeal!.wasSuccessful, true,
            reason: 'wasSuccessful should be back to true');
        print('✓ Database correctly updated wasSuccessful back to true');

        print('\n✓ TEST 7.2 PASSED: Success flag editing works correctly\n');
      } finally {
        // Cleanup
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

    testWidgets('7.5: Multiple rapid edits maintain data integrity',
        (WidgetTester tester) async {
      print('\n=== TEST 7.5: Rapid Sequential Edits ===');
      String? testRecipeId;
      String? testMealId;

      try {
        // Launch app
        print('\n=== LAUNCHING APP ===');
        await E2ETestHelpers.launchApp(tester);
        print('✓ App launched and initialized');

        final dbHelper = ServiceProvider.database.helper;

        // Setup: Create test recipe and meal
        print('\n=== CREATING TEST DATA ===');
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        testRecipeId = 'e2e-rapid-edit-recipe-$timestamp';
        testMealId = 'e2e-rapid-edit-meal-$timestamp';

        final shortId =
            timestamp.toString().substring(timestamp.toString().length - 4);
        final testRecipeName = 'Rapid$shortId';

        final testRecipe = Recipe(
          id: testRecipeId,
          name: testRecipeName,
          createdAt: DateTime.now(),
          instructions: 'Test instructions',
          notes: 'Test notes',
          prepTimeMinutes: 15,
          cookTimeMinutes: 30,
          difficulty: 3,
          rating: 4,
        );
        await dbHelper.insertRecipe(testRecipe);

        // Create initial meal
        final testMeal = Meal(
          id: testMealId,
          cookedAt: DateTime.now().subtract(const Duration(days: 1)),
          servings: 2,
          actualPrepTime: 15.0,
          actualCookTime: 30.0,
          wasSuccessful: true,
          notes: 'Original notes',
        );
        await dbHelper.insertMeal(testMeal);

        final mealRecipe = MealRecipe(
          mealId: testMealId,
          recipeId: testRecipeId,
          isPrimaryDish: true,
        );
        await dbHelper.insertMealRecipe(mealRecipe);

        print('✓ Test data created: $testRecipeName');

        // Refresh and navigate
        print('\n=== REFRESHING AND NAVIGATING ===');
        await E2ETestHelpers.refreshRecipeProvider(tester);
        await E2ETestHelpers.tapBottomNavTab(
            tester, const Key('recipes_tab_icon'));
        await tester.pumpAndSettle();
        await E2ETestHelpers.navigateToMealHistory(tester, testRecipeName);
        print('✓ Navigated to meal history screen');

        // === FIRST RAPID EDIT ===
        print('\n=== FIRST EDIT: Change servings to 3 ===');
        await E2ETestHelpers.openMealEditDialog(tester);
        final servingsField =
            find.byKey(const Key('edit_meal_recording_servings_field'));
        await tester.enterText(servingsField, '3');
        await tester.pumpAndSettle();
        await E2ETestHelpers.saveMealEditDialog(tester);
        await tester.pumpAndSettle();
        print('✓ First edit saved');

        // Verify first edit persisted
        var meal = await dbHelper.getMeal(testMealId);
        expect(meal!.servings, 3, reason: 'First edit: servings should be 3');
        expect(meal.notes, 'Original notes',
            reason: 'First edit: notes should remain unchanged');
        print('✓ First edit persisted correctly in database');

        // === SECOND RAPID EDIT ===
        print('\n=== SECOND EDIT: Change notes ===');
        await E2ETestHelpers.openMealEditDialog(tester);
        final notesField =
            find.byKey(const Key('edit_meal_recording_notes_field'));
        await tester.enterText(notesField, 'Updated notes from second edit');
        await tester.pumpAndSettle();
        await E2ETestHelpers.saveMealEditDialog(tester);
        await tester.pumpAndSettle();
        print('✓ Second edit saved');

        // Verify second edit persisted (and first edit still there)
        meal = await dbHelper.getMeal(testMealId);
        expect(meal!.servings, 3,
            reason: 'Second edit: servings should still be 3');
        expect(meal.notes, 'Updated notes from second edit',
            reason: 'Second edit: notes should be updated');
        print('✓ Second edit persisted, first edit still intact');

        // === THIRD RAPID EDIT ===
        print('\n=== THIRD EDIT: Change prep time and servings ===');
        await E2ETestHelpers.openMealEditDialog(tester);
        await tester.enterText(servingsField, '5');
        final prepTimeField =
            find.byKey(const Key('edit_meal_recording_prep_time_field'));
        await tester.enterText(prepTimeField, '25');
        await tester.pumpAndSettle();
        await E2ETestHelpers.saveMealEditDialog(tester);
        await tester.pumpAndSettle();
        print('✓ Third edit saved');

        // Verify third edit persisted (and previous edits still there)
        meal = await dbHelper.getMeal(testMealId);
        expect(meal!.servings, 5,
            reason: 'Third edit: servings should be updated to 5');
        expect(meal.actualPrepTime, 25,
            reason: 'Third edit: prep time should be updated to 25');
        expect(meal.notes, 'Updated notes from second edit',
            reason: 'Third edit: notes from second edit should still be there');
        print('✓ Third edit persisted, previous edits still intact');

        // === FOURTH RAPID EDIT ===
        print('\n=== FOURTH EDIT: Toggle success flag ===');
        await E2ETestHelpers.openMealEditDialog(tester);
        final successSwitch =
            find.byKey(const Key('edit_meal_recording_success_switch'));
        await tester.tap(successSwitch);
        await tester.pumpAndSettle();
        await E2ETestHelpers.saveMealEditDialog(tester);
        await tester.pumpAndSettle();
        print('✓ Fourth edit saved');

        // Verify fourth edit persisted (and all previous edits still there)
        meal = await dbHelper.getMeal(testMealId);
        expect(meal!.servings, 5,
            reason: 'Fourth edit: servings should still be 5');
        expect(meal.actualPrepTime, 25,
            reason: 'Fourth edit: prep time should still be 25');
        expect(meal.notes, 'Updated notes from second edit',
            reason: 'Fourth edit: notes should still be from second edit');
        expect(meal.wasSuccessful, false,
            reason: 'Fourth edit: wasSuccessful should be toggled to false');
        print('✓ Fourth edit persisted, all previous edits intact');

        // === FIFTH RAPID EDIT ===
        print('\n=== FIFTH EDIT: Change cook time and notes ===');
        await E2ETestHelpers.openMealEditDialog(tester);
        final cookTimeField =
            find.byKey(const Key('edit_meal_recording_cook_time_field'));
        await tester.enterText(cookTimeField, '45');
        await tester.enterText(notesField, 'Final notes after all edits');
        await tester.pumpAndSettle();
        await E2ETestHelpers.saveMealEditDialog(tester);
        await tester.pumpAndSettle();
        print('✓ Fifth edit saved');

        // FINAL VERIFICATION - All edits should be persisted
        print('\n=== FINAL VERIFICATION ===');
        meal = await dbHelper.getMeal(testMealId);
        expect(meal, isNotNull, reason: 'Meal should still exist');
        expect(meal!.servings, 5,
            reason: 'Final: servings should be 5 (from third edit)');
        expect(meal.actualPrepTime, 25,
            reason: 'Final: prep time should be 25 (from third edit)');
        expect(meal.actualCookTime, 45,
            reason: 'Final: cook time should be 45 (from fifth edit)');
        expect(meal.notes, 'Final notes after all edits',
            reason: 'Final: notes should be from fifth edit');
        expect(meal.wasSuccessful, false,
            reason: 'Final: wasSuccessful should be false (from fourth edit)');
        expect(meal.modifiedAt, isNotNull,
            reason: 'modifiedAt should be set after edits');
        print('✓ All 5 rapid edits persisted correctly');

        // Verify UI shows final state
        print('\n=== VERIFYING UI SHOWS FINAL STATE ===');
        expect(find.text('5'), findsWidgets,
            reason: 'UI should show servings count of 5');
        expect(find.text('Final notes after all edits'), findsOneWidget,
            reason: 'UI should show final notes');
        expect(find.byIcon(Icons.warning), findsOneWidget,
            reason: 'UI should show warning icon for unsuccessful meal');
        print('✓ UI correctly reflects all accumulated changes');

        // Verify no data corruption
        print('\n=== VERIFYING NO DATA CORRUPTION ===');
        final allMeals = await dbHelper.getMealsForRecipe(testRecipeId);
        expect(allMeals.length, 1,
            reason: 'Should still have exactly 1 meal (no duplicates)');
        print('✓ No duplicate meals created during rapid edits');

        print('\n✓ TEST 7.5 PASSED: Rapid sequential edits maintain data integrity\n');
      } finally {
        // Cleanup
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
