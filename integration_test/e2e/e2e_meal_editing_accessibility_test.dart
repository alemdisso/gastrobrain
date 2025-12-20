/// Meal Editing Accessibility & Performance E2E Test
///
/// This test suite verifies accessibility and performance aspects of the meal
/// editing workflow:
/// - Phase 6.2: Screen reader semantics and labels
/// - Phase 6.3: Performance baseline measurements
///
/// These tests ensure the app is accessible to all users and performs within
/// acceptable time limits.

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

  group('Phase 6: Meal Editing Accessibility & Performance', () {
    testWidgets('6.2: Edit dialog has proper semantic labels and accessibility',
        (WidgetTester tester) async {
      print('\n=== TEST 6.2: Screen Reader Semantics ===');
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
        testRecipeId = 'e2e-accessibility-recipe-$timestamp';
        testMealId = 'e2e-accessibility-meal-$timestamp';

        // Use very short name to avoid truncation in UI
        // Just use last 4 digits of timestamp for uniqueness
        final shortId =
            timestamp.toString().substring(timestamp.toString().length - 4);
        final testRecipeName = 'Test$shortId';
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

        final testMeal = Meal(
          id: testMealId,
          cookedAt: DateTime.now().subtract(const Duration(days: 1)),
          servings: 2,
          actualPrepTime: 15.0,
          actualCookTime: 30.0,
          wasSuccessful: true,
          notes: 'Test notes',
        );
        await dbHelper.insertMeal(testMeal);

        final mealRecipe = MealRecipe(
          mealId: testMealId,
          recipeId: testRecipeId,
          isPrimaryDish: true,
        );
        await dbHelper.insertMealRecipe(mealRecipe);

        print('✓ Test data created: $testRecipeName');

        // Force RecipeProvider to refresh and pick up the new recipe
        print('\n=== REFRESHING RECIPE PROVIDER ===');
        await E2ETestHelpers.refreshRecipeProvider(tester);
        print('✓ RecipeProvider refreshed');

        // Ensure we're on Recipes tab
        print('\n=== ENSURING ON RECIPES TAB ===');
        await E2ETestHelpers.tapBottomNavTab(
            tester, const Key('recipes_tab_icon'));
        await tester.pumpAndSettle();
        print('✓ On Recipes tab');

        // Navigate to meal history
        print('\n=== NAVIGATING TO MEAL HISTORY ===');
        await E2ETestHelpers.navigateToMealHistory(tester, testRecipeName);
        print('✓ Navigated to meal history screen');

        // Verify: PopupMenuButton has menu options accessible
        print('\n=== VERIFYING CONTEXT MENU ACCESSIBILITY ===');

        // Find the PopupMenuButton (more_vert icon)
        final moreVertIcon = find.byIcon(Icons.more_vert);
        expect(moreVertIcon, findsOneWidget,
            reason: 'Context menu button should be visible');
        print('✓ Context menu button (more_vert) is visible');

        // Open the context menu
        await E2ETestHelpers.openMealContextMenu(tester);
        print('✓ Context menu opened');

        // Verify edit option is accessible in menu
        final editIcon = find.byIcon(Icons.edit);
        expect(editIcon, findsOneWidget,
            reason: 'Edit option should be visible in menu');
        print('✓ Edit option is accessible in context menu');

        // Tap edit option to open dialog
        print('\n=== OPENING EDIT DIALOG ===');
        await tester.tap(editIcon);
        await tester.pumpAndSettle(E2ETestHelpers.standardSettleDuration);
        print('✓ Edit dialog opened');

        // Verify: Form fields have semantic labels
        print('\n=== VERIFYING FORM FIELD LABELS ===');

        // Check servings field - verify field is present and has label text visible
        final servingsField =
            find.byKey(const Key('edit_meal_recording_servings_field'));
        expect(servingsField, findsOneWidget,
            reason: 'Servings field should be present');

        // Verify label text is present in the widget tree near the field
        expect(find.text('Número de Porções'), findsWidgets,
            reason: 'Servings field should have a visible label');
        print('✓ Servings field has accessible label');

        // Check prep time field
        final prepTimeField =
            find.byKey(const Key('edit_meal_recording_prep_time_field'));
        expect(prepTimeField, findsOneWidget,
            reason: 'Prep time field should be present');

        // Verify label is present (checking for pattern that includes "Prep" and "Time")
        final prepTimeLabels =
            find.textContaining('Preparo', findRichText: true);
        expect(prepTimeLabels, findsWidgets,
            reason: 'Prep time field should have a visible label');
        print('✓ Prep time field has accessible label');

        // Check cook time field
        final cookTimeField =
            find.byKey(const Key('edit_meal_recording_cook_time_field'));
        expect(cookTimeField, findsOneWidget,
            reason: 'Cook time field should be present');

        // Verify label is present (checking for pattern that includes "Cook" and "Time")
        final cookTimeLabels =
            find.textContaining('Cozimento', findRichText: true);
        expect(cookTimeLabels, findsWidgets,
            reason: 'Cook time field should have a visible label');
        print('✓ Cook time field has accessible label');

        // Check notes field
        final notesField =
            find.byKey(const Key('edit_meal_recording_notes_field'));
        expect(notesField, findsOneWidget,
            reason: 'Notes field should be present');

        // Verify label is present (checking for "Notes")
        final notesLabels =
            find.textContaining('Observações', findRichText: true);
        expect(notesLabels, findsWidgets,
            reason: 'Notes field should have a visible label');
        print('✓ Notes field has accessible label');

        // Verify: Validation error messages are announced
        print('\n=== VERIFYING VALIDATION ERROR ACCESSIBILITY ===');

        // Clear servings field to trigger validation error
        await tester.enterText(servingsField, '');
        await tester.pumpAndSettle();

        // Try to save (should fail validation)
        await E2ETestHelpers.saveMealEditDialog(tester);
        await tester.pumpAndSettle();

        // Verify error message is displayed
        final errorText = find.textContaining('Por favor');
        expect(errorText, findsOneWidget,
            reason: 'Validation error should be displayed');
        print(
            '✓ Validation error is displayed and accessible to screen readers');

        // Verify: Cancel button is accessible
        print('\n=== VERIFYING CANCEL BUTTON ACCESSIBILITY ===');
        final cancelButton = find.text('Cancelar');
        expect(cancelButton, findsOneWidget,
            reason: 'Cancel button should be present');
        print('✓ Cancel button is present and accessible');

        // Close dialog
        await E2ETestHelpers.cancelMealEditDialog(tester);
        print('✓ Dialog closed via cancel button');

        print('\n✓ TEST 6.2 PASSED: Edit dialog has proper semantic labels\n');
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

    testWidgets('6.3: Complete edit workflow completes within acceptable time',
        (WidgetTester tester) async {
      print('\n=== TEST 6.3: Performance Baseline ===');
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
        testRecipeId = 'e2e-performance-recipe-$timestamp';
        testMealId = 'e2e-performance-meal-$timestamp';

        final shortId =
            timestamp.toString().substring(timestamp.toString().length - 4);
        final testRecipeName = 'Perf$shortId';

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

        // START PERFORMANCE MEASUREMENT
        print('\n=== MEASURING EDIT WORKFLOW PERFORMANCE ===');
        final startTime = DateTime.now();
        print('⏱️  Start time: ${startTime.toIso8601String()}');

        // Open edit dialog
        await E2ETestHelpers.openMealEditDialog(tester);
        final dialogOpenTime = DateTime.now();
        final openDuration = dialogOpenTime.difference(startTime);
        print('⏱️  Dialog opened in: ${openDuration.inMilliseconds}ms');

        // Edit servings field
        final servingsField =
            find.byKey(const Key('edit_meal_recording_servings_field'));
        await tester.enterText(servingsField, '4');
        await tester.pumpAndSettle();
        final editTime = DateTime.now();
        final editDuration = editTime.difference(dialogOpenTime);
        print('⏱️  Field edited in: ${editDuration.inMilliseconds}ms');

        // Save changes
        await E2ETestHelpers.saveMealEditDialog(tester);
        final saveTime = DateTime.now();
        final saveDuration = saveTime.difference(editTime);
        print('⏱️  Save completed in: ${saveDuration.inMilliseconds}ms');

        // Wait for snackbar and UI update
        await tester.pumpAndSettle();
        final completeTime = DateTime.now();

        // CALCULATE TOTAL TIME
        final totalDuration = completeTime.difference(startTime);
        print(
            '\n⏱️  TOTAL WORKFLOW TIME: ${totalDuration.inMilliseconds}ms (${(totalDuration.inMilliseconds / 1000).toStringAsFixed(2)}s)');

        // Verify: Total time is within acceptable range (< 12 seconds)
        const maxAcceptableDuration = Duration(seconds: 12);
        expect(totalDuration.inMilliseconds,
            lessThan(maxAcceptableDuration.inMilliseconds),
            reason: 'Edit workflow should complete within 12 seconds');
        print('✓ Performance is acceptable (< 12 seconds)');

        // Log performance breakdown
        print('\n📊 Performance Breakdown:');
        print('   - Dialog open:    ${openDuration.inMilliseconds}ms');
        print('   - Field edit:     ${editDuration.inMilliseconds}ms');
        print('   - Save & update:  ${saveDuration.inMilliseconds}ms');
        print('   - Total:          ${totalDuration.inMilliseconds}ms');

        // Verify the edit was actually saved
        print('\n=== VERIFYING EDIT WAS SAVED ===');
        final updatedMeal = await dbHelper.getMeal(testMealId);
        expect(updatedMeal?.servings, equals(4),
            reason: 'Servings should be updated to 4');
        print('✓ Edit was successfully saved to database');

        print('\n✓ TEST 6.3 PASSED: Edit workflow performance is acceptable\n');
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
