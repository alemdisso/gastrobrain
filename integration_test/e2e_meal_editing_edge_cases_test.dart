/// Meal Editing Edge Cases E2E Test
///
/// This test suite verifies edge cases and validation in the meal editing workflow:
/// - Validation errors (invalid servings, non-numeric input)
/// - Empty required fields
/// - Cancellation workflows
/// - Partial edit cancellation
///
/// These tests ensure the app handles invalid input gracefully and maintains
/// data integrity when users cancel operations.

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

  group('Meal Editing Edge Cases E2E Tests', () {
    testWidgets(
        'Validation errors prevent saving and do not corrupt data',
        (WidgetTester tester) async {
      print('\n=== TEST: Validation Errors ===');
      String? testRecipeId;
      String? testMealId;

      try {
        // Launch app first
        print('\n=== LAUNCHING APP ===');
        await E2ETestHelpers.launchApp(tester);
        print('✓ App launched and initialized');

        final dbHelper = ServiceProvider.database.helper;

        // Setup: Create test recipe and meal
        print('\n=== CREATING TEST DATA ===');
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        testRecipeId = 'e2e-validation-recipe-$timestamp';
        testMealId = 'e2e-validation-meal-$timestamp';

        final testRecipeName = 'Validation Test Recipe $timestamp';
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

        final cookedAt = DateTime.now().subtract(const Duration(days: 1));
        final testMeal = Meal(
          id: testMealId,
          cookedAt: cookedAt,
          servings: 4,
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

        // Refresh recipe provider to load new data
        print('\n=== REFRESHING RECIPE PROVIDER ===');
        await E2ETestHelpers.refreshRecipeProvider(tester);
        print('✓ RecipeProvider refreshed');

        print('\n=== NAVIGATING TO MEAL HISTORY ===');
        await E2ETestHelpers.navigateToMealHistory(tester, testRecipeName);
        print('✓ Navigated to meal history');

        // Open edit dialog
        print('\n=== OPENING EDIT DIALOG ===');
        await E2ETestHelpers.openMealEditDialog(tester);
        print('✓ Edit dialog opened');

        // Test Case 1: Enter invalid servings (0)
        print('\n=== TEST CASE 1: Zero servings ===');
        await E2ETestHelpers.fillMealEditDialog(tester, servings: '0');
        await tester.pumpAndSettle();

        // Try to save
        print('Attempting to save with invalid data...');
        final saveButton = find.byType(ElevatedButton);
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        // Verify: Validation error appears
        expect(
          find.textContaining('Por favor, informe um'),
          findsOneWidget,
          reason: 'Validation error should appear for servings = 0',
        );
        print('✓ Validation error displayed for zero servings');

        // Verify: Dialog remains open
        expect(
          find.byKey(const Key('edit_meal_recording_servings_field')),
          findsOneWidget,
          reason: 'Dialog should remain open after validation error',
        );
        print('✓ Dialog remains open');

        // Verify: Database unchanged
        final mealAfterInvalidAttempt = await dbHelper.getMeal(testMealId);
        expect(mealAfterInvalidAttempt?.servings, equals(4),
            reason: 'Database should be unchanged after validation error');
        print('✓ Database unchanged after invalid save attempt');

        // Test Case 2: Enter negative servings
        print('\n=== TEST CASE 2: Negative servings ===');
        await E2ETestHelpers.fillMealEditDialog(tester, servings: '-5');
        await tester.pumpAndSettle();

        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        // Verify: Validation error appears
        expect(
          find.textContaining('Por favor, informe um'),
          findsOneWidget,
          reason: 'Validation error should appear for negative servings',
        );
        print('✓ Validation error displayed for negative servings');

        // Test Case 3: Fix error and save successfully
        print('\n=== TEST CASE 3: Fix error and save ===');
        await E2ETestHelpers.fillMealEditDialog(tester, servings: '6');
        await tester.pumpAndSettle();

        await tester.tap(saveButton);
        await tester.pumpAndSettle(E2ETestHelpers.standardSettleDuration);

        // Verify: Success message appears
        expect(
          find.textContaining('sucesso'),
          findsOneWidget,
          reason: 'Success message should appear after fixing validation error',
        );
        print('✓ Success message displayed');

        // Verify: Database updated
        final mealAfterValidSave = await dbHelper.getMeal(testMealId);
        expect(mealAfterValidSave?.servings, equals(6),
            reason: 'Database should be updated after valid save');
        print('✓ Database updated with valid data');

        print('\n=== TEST PASSED ===\n');
      } finally {
        // Cleanup
        print('Cleaning up test data...');
        final dbHelper = ServiceProvider.database.helper;
        if (testMealId != null) {
          await dbHelper.deleteMeal(testMealId);
        }
        if (testRecipeId != null) {
          await dbHelper.deleteRecipe(testRecipeId);
        }
        print('✓ Cleanup complete');
      }
    });

    testWidgets(
        'Empty required fields prevent saving and show validation error',
        (WidgetTester tester) async {
      print('\n=== TEST: Empty Required Fields ===');
      String? testRecipeId;
      String? testMealId;

      try {
        // Launch app first
        print('\n=== LAUNCHING APP ===');
        await E2ETestHelpers.launchApp(tester);
        print('✓ App launched and initialized');

        final dbHelper = ServiceProvider.database.helper;

        // Setup: Create test recipe and meal
        print('\n=== CREATING TEST DATA ===');
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        testRecipeId = 'e2e-empty-field-recipe-$timestamp';
        testMealId = 'e2e-empty-field-meal-$timestamp';

        final testRecipeName = 'Empty Field Test Recipe $timestamp';
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

        final cookedAt = DateTime.now().subtract(const Duration(days: 1));
        final testMeal = Meal(
          id: testMealId,
          cookedAt: cookedAt,
          servings: 4,
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

        // Refresh recipe provider to load new data
        print('\n=== REFRESHING RECIPE PROVIDER ===');
        await E2ETestHelpers.refreshRecipeProvider(tester);
        print('✓ RecipeProvider refreshed');

        print('\n=== NAVIGATING TO MEAL HISTORY ===');
        await E2ETestHelpers.navigateToMealHistory(tester, testRecipeName);
        print('✓ Navigated to meal history');

        // Open edit dialog
        print('\n=== OPENING EDIT DIALOG ===');
        await E2ETestHelpers.openMealEditDialog(tester);
        print('✓ Edit dialog opened');

        // Test: Clear servings field (required field)
        print('\n=== CLEARING REQUIRED FIELD ===');
        final servingsField =
            find.byKey(const Key('edit_meal_recording_servings_field'));
        await tester.enterText(servingsField, '');
        await tester.pumpAndSettle();
        print('✓ Servings field cleared');

        // Try to save
        print('\n=== ATTEMPTING TO SAVE ===');
        final saveButton = find.byType(ElevatedButton);
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        // Verify: Validation error appears
        expect(
          find.textContaining('Por favor'),
          findsOneWidget,
          reason: 'Validation error should appear for empty required field',
        );
        print('✓ Validation error displayed for empty field');

        // Verify: Dialog remains open
        expect(
          servingsField,
          findsOneWidget,
          reason: 'Dialog should remain open after validation error',
        );
        print('✓ Dialog remains open');

        // Verify: Database unchanged
        final mealAfterInvalidAttempt = await dbHelper.getMeal(testMealId);
        expect(mealAfterInvalidAttempt?.servings, equals(4),
            reason: 'Database should be unchanged after validation error');
        print('✓ Database unchanged after invalid save attempt');

        print('\n=== TEST PASSED ===\n');
      } finally {
        // Cleanup
        print('Cleaning up test data...');
        final dbHelper = ServiceProvider.database.helper;
        if (testMealId != null) {
          await dbHelper.deleteMeal(testMealId);
        }
        if (testRecipeId != null) {
          await dbHelper.deleteRecipe(testRecipeId);
        }
        print('✓ Cleanup complete');
      }
    });

    testWidgets(
        'Cancellation discards all changes and returns to original state',
        (WidgetTester tester) async {
      print('\n=== TEST: Cancellation Workflow ===');
      String? testRecipeId;
      String? testMealId;

      try {
        // Launch app first
        print('\n=== LAUNCHING APP ===');
        await E2ETestHelpers.launchApp(tester);
        print('✓ App launched and initialized');

        final dbHelper = ServiceProvider.database.helper;

        // Setup: Create test recipe and meal with known values
        print('\n=== CREATING TEST DATA ===');
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        testRecipeId = 'e2e-cancel-recipe-$timestamp';
        testMealId = 'e2e-cancel-meal-$timestamp';

        final testRecipeName = 'Cancel Test Recipe $timestamp';
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

        // Original values that should be preserved after cancel
        final originalServings = 4;
        final originalNotes = 'Original notes for cancel test';
        final originalPrepTime = 20.0;
        final originalCookTime = 35.0;

        final cookedAt = DateTime.now().subtract(const Duration(days: 1));
        final testMeal = Meal(
          id: testMealId,
          cookedAt: cookedAt,
          servings: originalServings,
          actualPrepTime: originalPrepTime,
          actualCookTime: originalCookTime,
          wasSuccessful: true,
          notes: originalNotes,
        );
        await dbHelper.insertMeal(testMeal);

        final mealRecipe = MealRecipe(
          mealId: testMealId,
          recipeId: testRecipeId,
          isPrimaryDish: true,
        );
        await dbHelper.insertMealRecipe(mealRecipe);

        print('✓ Test data created with known values:');
        print('  - Servings: $originalServings');
        print('  - Notes: "$originalNotes"');
        print('  - Prep time: $originalPrepTime');
        print('  - Cook time: $originalCookTime');

        // Refresh recipe provider to load new data
        print('\n=== REFRESHING RECIPE PROVIDER ===');
        await E2ETestHelpers.refreshRecipeProvider(tester);
        print('✓ RecipeProvider refreshed');

        print('\n=== NAVIGATING TO MEAL HISTORY ===');
        await E2ETestHelpers.navigateToMealHistory(tester, testRecipeName);
        print('✓ Navigated to meal history');

        // Open edit dialog
        print('\n=== OPENING EDIT DIALOG ===');
        await E2ETestHelpers.openMealEditDialog(tester);
        print('✓ Edit dialog opened');

        // Modify multiple fields
        print('\n=== MODIFYING MULTIPLE FIELDS ===');
        await E2ETestHelpers.fillMealEditDialog(
          tester,
          servings: '8',
          notes: 'Modified notes - should be discarded',
          prepTime: '45',
          cookTime: '60',
        );
        await tester.pumpAndSettle();
        print('✓ Modified servings, notes, prep time, and cook time');

        // Cancel the dialog
        print('\n=== CANCELING DIALOG ===');
        await E2ETestHelpers.cancelMealEditDialog(tester);
        print('✓ Dialog canceled');

        // Verify: UI shows original values
        print('\n=== VERIFYING UI SHOWS ORIGINAL VALUES ===');
        expect(
          find.text('$originalServings'),
          findsOneWidget,
          reason: 'UI should show original servings after cancel',
        );
        print('✓ UI shows original servings');

        expect(
          find.textContaining(originalNotes),
          findsOneWidget,
          reason: 'UI should show original notes after cancel',
        );
        print('✓ UI shows original notes');

        // Verify: Database unchanged
        print('\n=== VERIFYING DATABASE UNCHANGED ===');
        final mealAfterCancel = await dbHelper.getMeal(testMealId);
        expect(mealAfterCancel?.servings, equals(originalServings),
            reason: 'Database servings should be unchanged after cancel');
        expect(mealAfterCancel?.notes, equals(originalNotes),
            reason: 'Database notes should be unchanged after cancel');
        expect(mealAfterCancel?.actualPrepTime, equals(originalPrepTime),
            reason: 'Database prep time should be unchanged after cancel');
        expect(mealAfterCancel?.actualCookTime, equals(originalCookTime),
            reason: 'Database cook time should be unchanged after cancel');
        print('✓ Database unchanged - all original values preserved');

        print('\n=== TEST PASSED ===\n');
      } finally {
        // Cleanup
        print('Cleaning up test data...');
        final dbHelper = ServiceProvider.database.helper;
        if (testMealId != null) {
          await dbHelper.deleteMeal(testMealId);
        }
        if (testRecipeId != null) {
          await dbHelper.deleteRecipe(testRecipeId);
        }
        print('✓ Cleanup complete');
      }
    });

    testWidgets(
        'Cancel after editing some fields discards all changes',
        (WidgetTester tester) async {
      print('\n=== TEST: Cancel After Partial Edit ===');
      String? testRecipeId;
      String? testMealId;

      try {
        // Launch app first
        print('\n=== LAUNCHING APP ===');
        await E2ETestHelpers.launchApp(tester);
        print('✓ App launched and initialized');

        final dbHelper = ServiceProvider.database.helper;

        // Setup: Create test recipe and meal with known values
        print('\n=== CREATING TEST DATA ===');
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        testRecipeId = 'e2e-partial-cancel-recipe-$timestamp';
        testMealId = 'e2e-partial-cancel-meal-$timestamp';

        final testRecipeName = 'Partial Cancel Test Recipe $timestamp';
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

        // Original values that should be preserved after cancel
        final originalServings = 3;
        final originalNotes = 'Original notes for partial cancel test';

        final cookedAt = DateTime.now().subtract(const Duration(days: 1));
        final testMeal = Meal(
          id: testMealId,
          cookedAt: cookedAt,
          servings: originalServings,
          actualPrepTime: 15.0,
          actualCookTime: 25.0,
          wasSuccessful: true,
          notes: originalNotes,
        );
        await dbHelper.insertMeal(testMeal);

        final mealRecipe = MealRecipe(
          mealId: testMealId,
          recipeId: testRecipeId,
          isPrimaryDish: true,
        );
        await dbHelper.insertMealRecipe(mealRecipe);

        print('✓ Test data created with known values:');
        print('  - Servings: $originalServings');
        print('  - Notes: "$originalNotes"');

        // Refresh recipe provider to load new data
        print('\n=== REFRESHING RECIPE PROVIDER ===');
        await E2ETestHelpers.refreshRecipeProvider(tester);
        print('✓ RecipeProvider refreshed');

        print('\n=== NAVIGATING TO MEAL HISTORY ===');
        await E2ETestHelpers.navigateToMealHistory(tester, testRecipeName);
        print('✓ Navigated to meal history');

        // Open edit dialog
        print('\n=== OPENING EDIT DIALOG ===');
        await E2ETestHelpers.openMealEditDialog(tester);
        print('✓ Edit dialog opened');

        // Edit servings first
        print('\n=== EDITING SERVINGS (PARTIAL EDIT 1) ===');
        await E2ETestHelpers.fillMealEditDialog(tester, servings: '7');
        await tester.pumpAndSettle();
        print('✓ Servings modified to 7');

        // Then edit notes (partial edit 2)
        print('\n=== EDITING NOTES (PARTIAL EDIT 2) ===');
        await E2ETestHelpers.fillMealEditDialog(
          tester,
          notes: 'Modified notes - should be discarded',
        );
        await tester.pumpAndSettle();
        print('✓ Notes modified');

        // Cancel the dialog
        print('\n=== CANCELING DIALOG ===');
        await E2ETestHelpers.cancelMealEditDialog(tester);
        print('✓ Dialog canceled');

        // Verify: UI shows original notes (unique identifier)
        print('\n=== VERIFYING UI SHOWS ORIGINAL VALUES ===');
        expect(
          find.textContaining(originalNotes),
          findsOneWidget,
          reason: 'UI should show original notes after cancel',
        );
        print('✓ UI shows original notes');

        // Verify: Database unchanged for both fields
        print('\n=== VERIFYING DATABASE UNCHANGED ===');
        final mealAfterCancel = await dbHelper.getMeal(testMealId);
        expect(mealAfterCancel?.servings, equals(originalServings),
            reason: 'Database servings should be unchanged after cancel');
        print('✓ Database servings unchanged ($originalServings)');

        expect(mealAfterCancel?.notes, equals(originalNotes),
            reason: 'Database notes should be unchanged after cancel');
        print('✓ Database notes unchanged');

        print('\n=== TEST PASSED ===\n');
      } finally {
        // Cleanup
        print('Cleaning up test data...');
        final dbHelper = ServiceProvider.database.helper;
        if (testMealId != null) {
          await dbHelper.deleteMeal(testMealId);
        }
        if (testRecipeId != null) {
          await dbHelper.deleteRecipe(testRecipeId);
        }
        print('✓ Cleanup complete');
      }
    });
  });
}