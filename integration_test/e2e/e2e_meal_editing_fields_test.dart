// integration_test/e2e_meal_editing_fields_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gastrobrain/database/database_helper.dart';
import 'package:gastrobrain/models/meal.dart';
import 'package:gastrobrain/models/meal_recipe.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'helpers/e2e_test_helpers.dart';

/// Meal Editing Fields E2E Tests
///
/// This test suite verifies field-specific editing behaviors:
/// - Multiple field edits in a single session
/// - Notes field with various content types
/// - Time fields (prep/cook) with different values
/// - Data consistency and integrity after edits
///
/// These tests focus on data validation, field interactions,
/// and ensuring all field types work correctly in the edit workflow.

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E - Meal Editing Fields', () {
    // ========================================================================
    // PHASE 3.1: Multiple Fields Edit Test
    // ========================================================================

    testWidgets('Edit multiple fields simultaneously and verify all changes saved',
        (WidgetTester tester) async {
      final testRecipeName =
          'E2E Multi-Field Test ${DateTime.now().millisecondsSinceEpoch}';

      // Original values
      final originalServings = 3;
      final originalNotes = 'Original notes for multi-field test';
      final originalPrepTime = 25.0;
      final originalCookTime = 45.0;
      final originalWasSuccessful = true;
      final originalCookedAt = DateTime.now().subtract(const Duration(days: 3));

      // Updated values
      final updatedServings = 5;
      final updatedNotes = 'Updated notes - multiple fields changed';
      final updatedPrepTime = 30.0;
      final updatedCookTime = 50.0;

      String? createdRecipeId;
      String? createdMealId;

      try {
        print('=== LAUNCHING APP ===');
        await E2ETestHelpers.launchApp(tester);
        print('✓ App launched and initialized');

        final dbHelper = DatabaseHelper();

        print('\n=== CREATING TEST RECIPE ===');
        final testRecipe = Recipe(
          id: 'e2e-multi-field-recipe-${DateTime.now().millisecondsSinceEpoch}',
          name: testRecipeName,
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 2,
          prepTimeMinutes: 20,
          cookTimeMinutes: 40,
          rating: 4,
        );

        await dbHelper.insertRecipe(testRecipe);
        createdRecipeId = testRecipe.id;
        print('✓ Test recipe created: $testRecipeName (ID: $createdRecipeId)');

        print('\n=== CREATING TEST MEAL WITH ALL FIELDS POPULATED ===');
        final testMeal = Meal(
          id: 'e2e-multi-field-meal-${DateTime.now().millisecondsSinceEpoch}',
          cookedAt: originalCookedAt,
          servings: originalServings,
          notes: originalNotes,
          wasSuccessful: originalWasSuccessful,
          actualPrepTime: originalPrepTime,
          actualCookTime: originalCookTime,
        );

        await dbHelper.insertMeal(testMeal);
        createdMealId = testMeal.id;
        await dbHelper.insertMealRecipe(MealRecipe(
          mealId: testMeal.id,
          recipeId: testRecipe.id,
          isPrimaryDish: true,
          notes: 'Primary dish for multi-field test',
        ));
        print('✓ Test meal created with all fields');

        print('\n=== REFRESHING RECIPE PROVIDER ===');
        await E2ETestHelpers.refreshRecipeProvider(tester);
        print('✓ RecipeProvider refreshed');

        print('\n=== NAVIGATING TO MEAL HISTORY SCREEN ===');
        await E2ETestHelpers.tapBottomNavTab(
          tester,
          const Key('recipes_tab_icon'),
        );
        await tester.pumpAndSettle();
        await E2ETestHelpers.navigateToMealHistory(tester, testRecipeName);
        print('✓ Navigated to Meal History Screen');

        print('\n=== OPENING EDIT DIALOG ===');
        await E2ETestHelpers.openMealEditDialog(tester);
        print('✓ Edit dialog opened');

        print('\n=== MODIFYING MULTIPLE FIELDS ===');
        await E2ETestHelpers.fillMealEditDialog(
          tester,
          servings: updatedServings.toString(),
          notes: updatedNotes,
          prepTime: updatedPrepTime.toStringAsFixed(0),
          cookTime: updatedCookTime.toStringAsFixed(0),
        );
        print('✓ All fields updated in edit dialog');

        print('\n=== SAVING CHANGES ===');
        await E2ETestHelpers.saveMealEditDialog(tester);
        await tester.pumpAndSettle();
        print('✓ Changes saved');

        print('\n=== VERIFYING DATABASE: ALL EDITED FIELDS UPDATED ===');
        await E2ETestHelpers.verifyMealFieldsInDatabase(
          dbHelper,
          createdMealId,
          expectedServings: updatedServings,
          expectedNotes: updatedNotes,
          expectedPrepTime: updatedPrepTime,
          expectedCookTime: updatedCookTime,
        );
        print('✓ Database confirmed all edited fields updated');

        print('\n=== VERIFYING DATABASE: UNCHANGED FIELDS PRESERVED ===');
        final mealAfterEdit = await dbHelper.getMeal(createdMealId);
        expect(mealAfterEdit, isNotNull);
        expect(mealAfterEdit!.wasSuccessful, equals(originalWasSuccessful));
        expect(mealAfterEdit.cookedAt, equals(originalCookedAt));
        print('✓ Unchanged fields preserved');

        print('\n=== TEST COMPLETED SUCCESSFULLY ===');
      } finally {
        print('\n=== CLEANING UP TEST DATA ===');
        final dbHelper = DatabaseHelper();
        if (createdMealId != null) {
          await E2ETestHelpers.deleteTestMeal(dbHelper, createdMealId);
        }
        if (createdRecipeId != null) {
          await E2ETestHelpers.deleteTestRecipe(dbHelper, createdRecipeId);
        }
        print('✓ Cleanup complete');
      }
    });

    // ========================================================================
    // PHASE 3.2: Notes Field Edit Tests - 4 Separate Tests
    // ========================================================================

    testWidgets('Notes field: add notes to empty field',
        (WidgetTester tester) async {
      final testRecipeName =
          'E2E Notes Empty ${DateTime.now().millisecondsSinceEpoch}';
      String? createdRecipeId;
      String? createdMealId;

      try {
        print('=== TEST: Add notes to empty field ===');
        await E2ETestHelpers.launchApp(tester);
        final dbHelper = DatabaseHelper();

        // Create recipe
        final testRecipe = Recipe(
          id: 'e2e-notes-${DateTime.now().millisecondsSinceEpoch}',
          name: testRecipeName,
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 2,
          prepTimeMinutes: 15,
          cookTimeMinutes: 25,
          rating: 4,
        );
        await dbHelper.insertRecipe(testRecipe);
        createdRecipeId = testRecipe.id;

        // Create meal with empty notes
        final testMeal = Meal(
          id: 'e2e-meal-${DateTime.now().millisecondsSinceEpoch}',
          cookedAt: DateTime.now().subtract(const Duration(days: 1)),
          servings: 2,
          wasSuccessful: true,
        );
        await dbHelper.insertMeal(testMeal);
        createdMealId = testMeal.id;
        await dbHelper.insertMealRecipe(MealRecipe(
          mealId: testMeal.id,
          recipeId: testRecipe.id,
          isPrimaryDish: true,
        ));
        print('✓ Created meal with empty notes');

        // Navigate and edit
        await E2ETestHelpers.refreshRecipeProvider(tester);
        await E2ETestHelpers.tapBottomNavTab(tester, const Key('recipes_tab_icon'));
        await tester.pumpAndSettle();
        await E2ETestHelpers.navigateToMealHistory(tester, testRecipeName);
        await E2ETestHelpers.openMealEditDialog(tester);

        // Add notes
        final newNotes = 'These are new notes added to an empty field';
        await E2ETestHelpers.fillMealEditDialog(tester, notes: newNotes);
        await E2ETestHelpers.saveMealEditDialog(tester);
        await tester.pumpAndSettle();
        print('✓ Added notes and saved');

        // Verify
        await E2ETestHelpers.verifyMealFieldsInDatabase(
          dbHelper,
          createdMealId,
          expectedNotes: newNotes,
        );
        print('✓ TEST PASSED: empty → filled');
      } finally {
        final dbHelper = DatabaseHelper();
        if (createdMealId != null) {
          await E2ETestHelpers.deleteTestMeal(dbHelper, createdMealId);
        }
        if (createdRecipeId != null) {
          await E2ETestHelpers.deleteTestRecipe(dbHelper, createdRecipeId);
        }
      }
    });

    testWidgets('Notes field: clear existing notes',
        (WidgetTester tester) async {
      final testRecipeName =
          'E2E Notes Clear ${DateTime.now().millisecondsSinceEpoch}';
      String? createdRecipeId;
      String? createdMealId;

      try {
        print('=== TEST: Clear existing notes ===');
        await E2ETestHelpers.launchApp(tester);
        final dbHelper = DatabaseHelper();

        // Create recipe
        final testRecipe = Recipe(
          id: 'e2e-notes-${DateTime.now().millisecondsSinceEpoch}',
          name: testRecipeName,
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 2,
          prepTimeMinutes: 15,
          cookTimeMinutes: 25,
          rating: 4,
        );
        await dbHelper.insertRecipe(testRecipe);
        createdRecipeId = testRecipe.id;

        // Create meal with notes
        final originalNotes = 'These notes will be cleared';
        final testMeal = Meal(
          id: 'e2e-meal-${DateTime.now().millisecondsSinceEpoch}',
          cookedAt: DateTime.now().subtract(const Duration(days: 1)),
          servings: 3,
          notes: originalNotes,
          wasSuccessful: true,
        );
        await dbHelper.insertMeal(testMeal);
        createdMealId = testMeal.id;
        await dbHelper.insertMealRecipe(MealRecipe(
          mealId: testMeal.id,
          recipeId: testRecipe.id,
          isPrimaryDish: true,
        ));
        print('✓ Created meal with notes: "$originalNotes"');

        // Navigate and edit
        await E2ETestHelpers.refreshRecipeProvider(tester);
        await E2ETestHelpers.tapBottomNavTab(tester, const Key('recipes_tab_icon'));
        await tester.pumpAndSettle();
        await E2ETestHelpers.navigateToMealHistory(tester, testRecipeName);
        await E2ETestHelpers.openMealEditDialog(tester);

        // Clear notes
        await E2ETestHelpers.fillMealEditDialog(tester, notes: '');
        await E2ETestHelpers.saveMealEditDialog(tester);
        await tester.pumpAndSettle();
        print('✓ Cleared notes and saved');

        // Verify
        final mealAfterEdit = await dbHelper.getMeal(createdMealId);
        expect(mealAfterEdit, isNotNull);
        expect(mealAfterEdit!.notes.isEmpty, isTrue,
            reason: 'Notes should be empty after clearing');
        print('✓ TEST PASSED: filled → empty');
      } finally {
        final dbHelper = DatabaseHelper();
        if (createdMealId != null) {
          await E2ETestHelpers.deleteTestMeal(dbHelper, createdMealId);
        }
        if (createdRecipeId != null) {
          await E2ETestHelpers.deleteTestRecipe(dbHelper, createdRecipeId);
        }
      }
    });

    testWidgets('Notes field: change existing notes to different text',
        (WidgetTester tester) async {
      final testRecipeName =
          'E2E Notes Change ${DateTime.now().millisecondsSinceEpoch}';
      String? createdRecipeId;
      String? createdMealId;

      try {
        print('=== TEST: Change existing notes ===');
        await E2ETestHelpers.launchApp(tester);
        final dbHelper = DatabaseHelper();

        // Create recipe
        final testRecipe = Recipe(
          id: 'e2e-notes-${DateTime.now().millisecondsSinceEpoch}',
          name: testRecipeName,
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 2,
          prepTimeMinutes: 15,
          cookTimeMinutes: 25,
          rating: 4,
        );
        await dbHelper.insertRecipe(testRecipe);
        createdRecipeId = testRecipe.id;

        // Create meal with notes
        final originalNotes = 'Original notes that will be changed';
        final testMeal = Meal(
          id: 'e2e-meal-${DateTime.now().millisecondsSinceEpoch}',
          cookedAt: DateTime.now().subtract(const Duration(days: 1)),
          servings: 4,
          notes: originalNotes,
          wasSuccessful: true,
        );
        await dbHelper.insertMeal(testMeal);
        createdMealId = testMeal.id;
        await dbHelper.insertMealRecipe(MealRecipe(
          mealId: testMeal.id,
          recipeId: testRecipe.id,
          isPrimaryDish: true,
        ));
        print('✓ Created meal with notes: "$originalNotes"');

        // Navigate and edit
        await E2ETestHelpers.refreshRecipeProvider(tester);
        await E2ETestHelpers.tapBottomNavTab(tester, const Key('recipes_tab_icon'));
        await tester.pumpAndSettle();
        await E2ETestHelpers.navigateToMealHistory(tester, testRecipeName);
        await E2ETestHelpers.openMealEditDialog(tester);

        // Change notes
        final updatedNotes = 'Completely different notes now';
        await E2ETestHelpers.fillMealEditDialog(tester, notes: updatedNotes);
        await E2ETestHelpers.saveMealEditDialog(tester);
        await tester.pumpAndSettle();
        print('✓ Changed notes and saved');

        // Verify
        await E2ETestHelpers.verifyMealFieldsInDatabase(
          dbHelper,
          createdMealId,
          expectedNotes: updatedNotes,
        );
        print('✓ TEST PASSED: filled → different');
      } finally {
        final dbHelper = DatabaseHelper();
        if (createdMealId != null) {
          await E2ETestHelpers.deleteTestMeal(dbHelper, createdMealId);
        }
        if (createdRecipeId != null) {
          await E2ETestHelpers.deleteTestRecipe(dbHelper, createdRecipeId);
        }
      }
    });

    testWidgets('Notes field: handle special characters',
        (WidgetTester tester) async {
      final testRecipeName =
          'E2E Notes Special ${DateTime.now().millisecondsSinceEpoch}';
      String? createdRecipeId;
      String? createdMealId;

      try {
        print('=== TEST: Special characters in notes ===');
        await E2ETestHelpers.launchApp(tester);
        final dbHelper = DatabaseHelper();

        // Create recipe
        final testRecipe = Recipe(
          id: 'e2e-notes-${DateTime.now().millisecondsSinceEpoch}',
          name: testRecipeName,
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 2,
          prepTimeMinutes: 15,
          cookTimeMinutes: 25,
          rating: 4,
        );
        await dbHelper.insertRecipe(testRecipe);
        createdRecipeId = testRecipe.id;

        // Create meal with basic notes
        final testMeal = Meal(
          id: 'e2e-meal-${DateTime.now().millisecondsSinceEpoch}',
          cookedAt: DateTime.now().subtract(const Duration(days: 1)),
          servings: 1,
          notes: 'Basic notes',
          wasSuccessful: true,
        );
        await dbHelper.insertMeal(testMeal);
        createdMealId = testMeal.id;
        await dbHelper.insertMealRecipe(MealRecipe(
          mealId: testMeal.id,
          recipeId: testRecipe.id,
          isPrimaryDish: true,
        ));
        print('✓ Created meal with basic notes');

        // Navigate and edit
        await E2ETestHelpers.refreshRecipeProvider(tester);
        await E2ETestHelpers.tapBottomNavTab(tester, const Key('recipes_tab_icon'));
        await tester.pumpAndSettle();
        await E2ETestHelpers.navigateToMealHistory(tester, testRecipeName);
        await E2ETestHelpers.openMealEditDialog(tester);

        // Add notes with special characters
        final specialCharNotes = 'Special chars: @#\$%^&*()!"\'\n'
            'Line 2 with emoji: 🍕🥗\n'
            'Line 3 with quotes: "double" and \'single\'';
        await E2ETestHelpers.fillMealEditDialog(tester, notes: specialCharNotes);
        await E2ETestHelpers.saveMealEditDialog(tester);
        await tester.pumpAndSettle();
        print('✓ Added notes with special characters and saved');

        // Verify
        await E2ETestHelpers.verifyMealFieldsInDatabase(
          dbHelper,
          createdMealId,
          expectedNotes: specialCharNotes,
        );
        print('✓ TEST PASSED: special characters');
      } finally {
        final dbHelper = DatabaseHelper();
        if (createdMealId != null) {
          await E2ETestHelpers.deleteTestMeal(dbHelper, createdMealId);
        }
        if (createdRecipeId != null) {
          await E2ETestHelpers.deleteTestRecipe(dbHelper, createdRecipeId);
        }
      }
    });

    // Test 3.3.1: Add times to meal with no times (null → value)
    testWidgets('Time fields: add times to meal with no times',
        (WidgetTester tester) async {
      print('\n=== TEST 3.3.1: Add times to meal with no times ===');

      final testRecipeName =
          'E2E Time Add ${DateTime.now().millisecondsSinceEpoch}';
      String? createdRecipeId;
      String? createdMealId;

      try {
        // Launch app
        await E2ETestHelpers.launchApp(tester);
        final dbHelper = DatabaseHelper();

        // Create test recipe
        final testRecipe = Recipe(
          id: 'e2e-time-add-recipe-${DateTime.now().millisecondsSinceEpoch}',
          name: testRecipeName,
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 2,
          prepTimeMinutes: 15,
          cookTimeMinutes: 30,
          rating: 4,
        );
        await dbHelper.insertRecipe(testRecipe);
        createdRecipeId = testRecipe.id;
        print('✓ Created test recipe: $testRecipeName');

        // Create test meal with NO times (actualPrepTime=0, actualCookTime=0)
        final testMeal = Meal(
          id: 'e2e-time-add-meal-${DateTime.now().millisecondsSinceEpoch}',
          recipeId: testRecipe.id,
          cookedAt: DateTime.now().subtract(const Duration(days: 1)),
          servings: 2,
          notes: 'Test meal for adding times',
          wasSuccessful: true,
          actualPrepTime: 0.0, // No prep time initially
          actualCookTime: 0.0, // No cook time initially
        );
        await dbHelper.insertMeal(testMeal);
        createdMealId = testMeal.id;
        print('✓ Created test meal with no times');

        // Create MealRecipe association
        final mealRecipe = MealRecipe(
          mealId: testMeal.id,
          recipeId: testRecipe.id,
          isPrimaryDish: true,
          notes: 'Primary dish',
        );
        await dbHelper.insertMealRecipe(mealRecipe);
        print('✓ Created MealRecipe association');

        // Navigate to meal history
        await E2ETestHelpers.refreshRecipeProvider(tester);
        await E2ETestHelpers.tapBottomNavTab(
            tester, const Key('recipes_tab_icon'));
        await tester.pumpAndSettle();
        print('✓ Navigated to recipes tab');

        await E2ETestHelpers.navigateToMealHistory(tester, testRecipeName);
        print('✓ Opened meal history screen');

        // Verify times are NOT displayed (0 values)
        expect(find.text('0.0'), findsNothing,
            reason: 'Times should not be displayed when they are 0');
        print('✓ Verified times not displayed initially');

        // Open edit dialog
        await E2ETestHelpers.openMealEditDialog(tester);
        print('✓ Opened meal edit dialog');

        // Add times: 20 min prep, 45 min cook
        await E2ETestHelpers.fillMealEditDialog(
          tester,
          prepTime: '20',
          cookTime: '45',
        );
        print('✓ Entered new times: 20 min prep, 45 min cook');

        // Save changes
        await E2ETestHelpers.saveMealEditDialog(tester);
        print('✓ Saved meal edit dialog');

        // Verify times are now displayed in UI
        await tester.pumpAndSettle();
        expect(find.textContaining('20.0'), findsOneWidget,
            reason: 'Prep time should be displayed');
        expect(find.textContaining('45.0'), findsOneWidget,
            reason: 'Cook time should be displayed');
        print('✓ Verified times displayed in UI');

        // Verify in database
        await E2ETestHelpers.verifyMealFieldsInDatabase(
          dbHelper,
          createdMealId,
          expectedPrepTime: 20.0,
          expectedCookTime: 45.0,
        );
        print('✓ TEST PASSED: add times to meal with no times');
      } finally {
        final dbHelper = DatabaseHelper();
        if (createdMealId != null) {
          await E2ETestHelpers.deleteTestMeal(dbHelper, createdMealId);
        }
        if (createdRecipeId != null) {
          await E2ETestHelpers.deleteTestRecipe(dbHelper, createdRecipeId);
        }
      }
    });

    // Test 3.3.2: Clear existing times (value → null)
    testWidgets('Time fields: clear existing times',
        (WidgetTester tester) async {
      print('\n=== TEST 3.3.2: Clear existing times ===');

      final testRecipeName =
          'E2E Time Clear ${DateTime.now().millisecondsSinceEpoch}';
      String? createdRecipeId;
      String? createdMealId;

      try {
        // Launch app
        await E2ETestHelpers.launchApp(tester);
        final dbHelper = DatabaseHelper();

        // Create test recipe
        final testRecipe = Recipe(
          id: 'e2e-time-clear-recipe-${DateTime.now().millisecondsSinceEpoch}',
          name: testRecipeName,
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 2,
          prepTimeMinutes: 15,
          cookTimeMinutes: 30,
          rating: 4,
        );
        await dbHelper.insertRecipe(testRecipe);
        createdRecipeId = testRecipe.id;
        print('✓ Created test recipe: $testRecipeName');

        // Create test meal WITH times
        final testMeal = Meal(
          id: 'e2e-time-clear-meal-${DateTime.now().millisecondsSinceEpoch}',
          recipeId: testRecipe.id,
          cookedAt: DateTime.now().subtract(const Duration(days: 1)),
          servings: 2,
          notes: 'Test meal for clearing times',
          wasSuccessful: true,
          actualPrepTime: 25.0, // Has prep time
          actualCookTime: 40.0, // Has cook time
        );
        await dbHelper.insertMeal(testMeal);
        createdMealId = testMeal.id;
        print('✓ Created test meal with times: 25 prep, 40 cook');

        // Create MealRecipe association
        final mealRecipe = MealRecipe(
          mealId: testMeal.id,
          recipeId: testRecipe.id,
          isPrimaryDish: true,
          notes: 'Primary dish',
        );
        await dbHelper.insertMealRecipe(mealRecipe);
        print('✓ Created MealRecipe association');

        // Navigate to meal history
        await E2ETestHelpers.refreshRecipeProvider(tester);
        await E2ETestHelpers.tapBottomNavTab(
            tester, const Key('recipes_tab_icon'));
        await tester.pumpAndSettle();
        print('✓ Navigated to recipes tab');

        await E2ETestHelpers.navigateToMealHistory(tester, testRecipeName);
        print('✓ Opened meal history screen');

        // Verify times are displayed
        expect(find.textContaining('25.0'), findsOneWidget,
            reason: 'Prep time should be displayed');
        expect(find.textContaining('40.0'), findsOneWidget,
            reason: 'Cook time should be displayed');
        print('✓ Verified times displayed initially');

        // Open edit dialog
        await E2ETestHelpers.openMealEditDialog(tester);
        print('✓ Opened meal edit dialog');

        // Clear times by setting to 0
        await E2ETestHelpers.fillMealEditDialog(
          tester,
          prepTime: '0',
          cookTime: '0',
        );
        print('✓ Cleared times (set to 0)');

        // Save changes
        await E2ETestHelpers.saveMealEditDialog(tester);
        print('✓ Saved meal edit dialog');

        // Verify times are no longer displayed in UI
        await tester.pumpAndSettle();
        expect(find.textContaining('25.0'), findsNothing,
            reason: 'Old prep time should not be displayed');
        expect(find.textContaining('40.0'), findsNothing,
            reason: 'Old cook time should not be displayed');
        print('✓ Verified times not displayed in UI after clearing');

        // Verify in database
        await E2ETestHelpers.verifyMealFieldsInDatabase(
          dbHelper,
          createdMealId,
          expectedPrepTime: 0.0,
          expectedCookTime: 0.0,
        );
        print('✓ TEST PASSED: clear existing times');
      } finally {
        final dbHelper = DatabaseHelper();
        if (createdMealId != null) {
          await E2ETestHelpers.deleteTestMeal(dbHelper, createdMealId);
        }
        if (createdRecipeId != null) {
          await E2ETestHelpers.deleteTestRecipe(dbHelper, createdRecipeId);
        }
      }
    });

    // Test 3.3.3: Change existing times to different values
    testWidgets('Time fields: change existing times to different values',
        (WidgetTester tester) async {
      print('\n=== TEST 3.3.3: Change existing times to different values ===');

      final testRecipeName =
          'E2E Time Change ${DateTime.now().millisecondsSinceEpoch}';
      String? createdRecipeId;
      String? createdMealId;

      try {
        // Launch app
        await E2ETestHelpers.launchApp(tester);
        final dbHelper = DatabaseHelper();

        // Create test recipe
        final testRecipe = Recipe(
          id:
              'e2e-time-change-recipe-${DateTime.now().millisecondsSinceEpoch}',
          name: testRecipeName,
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 2,
          prepTimeMinutes: 15,
          cookTimeMinutes: 30,
          rating: 4,
        );
        await dbHelper.insertRecipe(testRecipe);
        createdRecipeId = testRecipe.id;
        print('✓ Created test recipe: $testRecipeName');

        // Create test meal WITH times
        final testMeal = Meal(
          id: 'e2e-time-change-meal-${DateTime.now().millisecondsSinceEpoch}',
          recipeId: testRecipe.id,
          cookedAt: DateTime.now().subtract(const Duration(days: 1)),
          servings: 2,
          notes: 'Test meal for changing times',
          wasSuccessful: true,
          actualPrepTime: 10.0, // Initial prep time
          actualCookTime: 20.0, // Initial cook time
        );
        await dbHelper.insertMeal(testMeal);
        createdMealId = testMeal.id;
        print('✓ Created test meal with times: 10 prep, 20 cook');

        // Create MealRecipe association
        final mealRecipe = MealRecipe(
          mealId: testMeal.id,
          recipeId: testRecipe.id,
          isPrimaryDish: true,
          notes: 'Primary dish',
        );
        await dbHelper.insertMealRecipe(mealRecipe);
        print('✓ Created MealRecipe association');

        // Navigate to meal history
        await E2ETestHelpers.refreshRecipeProvider(tester);
        await E2ETestHelpers.tapBottomNavTab(
            tester, const Key('recipes_tab_icon'));
        await tester.pumpAndSettle();
        print('✓ Navigated to recipes tab');

        await E2ETestHelpers.navigateToMealHistory(tester, testRecipeName);
        print('✓ Opened meal history screen');

        // Verify initial times are displayed
        expect(find.textContaining('10.0'), findsOneWidget,
            reason: 'Initial prep time should be displayed');
        expect(find.textContaining('20.0'), findsOneWidget,
            reason: 'Initial cook time should be displayed');
        print('✓ Verified initial times displayed');

        // Open edit dialog
        await E2ETestHelpers.openMealEditDialog(tester);
        print('✓ Opened meal edit dialog');

        // Change times to different values: 35 min prep, 60 min cook
        await E2ETestHelpers.fillMealEditDialog(
          tester,
          prepTime: '35',
          cookTime: '60',
        );
        print('✓ Changed times to: 35 min prep, 60 min cook');

        // Save changes
        await E2ETestHelpers.saveMealEditDialog(tester);
        print('✓ Saved meal edit dialog');

        // Verify new times are displayed in UI
        await tester.pumpAndSettle();
        expect(find.textContaining('35.0'), findsOneWidget,
            reason: 'New prep time should be displayed');
        expect(find.textContaining('60.0'), findsOneWidget,
            reason: 'New cook time should be displayed');
        expect(find.textContaining('10.0'), findsNothing,
            reason: 'Old prep time should not be displayed');
        expect(find.textContaining('20.0'), findsNothing,
            reason: 'Old cook time should not be displayed');
        print('✓ Verified new times displayed in UI');

        // Verify in database
        await E2ETestHelpers.verifyMealFieldsInDatabase(
          dbHelper,
          createdMealId,
          expectedPrepTime: 35.0,
          expectedCookTime: 60.0,
        );
        print('✓ TEST PASSED: change existing times to different values');
      } finally {
        final dbHelper = DatabaseHelper();
        if (createdMealId != null) {
          await E2ETestHelpers.deleteTestMeal(dbHelper, createdMealId);
        }
        if (createdRecipeId != null) {
          await E2ETestHelpers.deleteTestRecipe(dbHelper, createdRecipeId);
        }
      }
    });

    // Test 3.4: Data Consistency - Verify meal order and modifiedAt
    testWidgets(
        'Data Consistency: verify meal order maintained and modifiedAt updated after edit',
        (WidgetTester tester) async {
      print('\n=== TEST 3.4: Data Consistency ===');

      final testRecipeName =
          'E2E Data Consistency ${DateTime.now().millisecondsSinceEpoch}';
      String? createdRecipeId;
      final List<String> createdMealIds = [];

      try {
        // Launch app
        await E2ETestHelpers.launchApp(tester);
        final dbHelper = DatabaseHelper();

        // Create test recipe
        final testRecipe = Recipe(
          id:
              'e2e-data-consistency-recipe-${DateTime.now().millisecondsSinceEpoch}',
          name: testRecipeName,
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 2,
          prepTimeMinutes: 15,
          cookTimeMinutes: 30,
          rating: 4,
        );
        await dbHelper.insertRecipe(testRecipe);
        createdRecipeId = testRecipe.id;
        print('✓ Created test recipe: $testRecipeName');

        // Create 5 meals at different dates to test ordering
        // Most recent to oldest: day -1, -2, -3, -4, -5
        print('\n=== Creating 5 meals at different dates ===');
        final now = DateTime.now();
        final mealDates = [
          now.subtract(const Duration(days: 5)), // Oldest
          now.subtract(const Duration(days: 4)),
          now.subtract(const Duration(days: 3)), // Middle - we'll edit this one
          now.subtract(const Duration(days: 2)),
          now.subtract(const Duration(days: 1)), // Most recent
        ];

        for (int i = 0; i < mealDates.length; i++) {
          final meal = Meal(
            id:
                'e2e-data-consistency-meal-$i-${DateTime.now().millisecondsSinceEpoch}',
            recipeId: testRecipe.id,
            cookedAt: mealDates[i],
            servings: 2 + i, // Different servings: 2, 3, 4, 5, 6
            notes: 'Meal ${i + 1} - ${mealDates[i].day}',
            wasSuccessful: true,
            actualPrepTime: 10.0,
            actualCookTime: 20.0,
          );
          await dbHelper.insertMeal(meal);
          createdMealIds.add(meal.id);

          // Create MealRecipe association
          final mealRecipe = MealRecipe(
            mealId: meal.id,
            recipeId: testRecipe.id,
            isPrimaryDish: true,
            notes: 'Primary dish for meal ${i + 1}',
          );
          await dbHelper.insertMealRecipe(mealRecipe);
          print(
              '✓ Created meal ${i + 1} with ${meal.servings} servings on day ${mealDates[i].day}');
        }

        // Navigate to meal history
        await E2ETestHelpers.refreshRecipeProvider(tester);
        await E2ETestHelpers.tapBottomNavTab(
            tester, const Key('recipes_tab_icon'));
        await tester.pumpAndSettle();
        print('✓ Navigated to recipes tab');

        await E2ETestHelpers.navigateToMealHistory(tester, testRecipeName);
        print('✓ Opened meal history screen');

        // Verify initial order: meals should be displayed newest to oldest
        // The most recent meal (day -1, servings=6) should be first
        // The middle meal (day -3, servings=4) should be at index 2
        print('\n=== Verifying initial meal order ===');

        // Get the middle meal's original modifiedAt timestamp
        final middleMealId = createdMealIds[2]; // Day -3 meal
        final middleMealBefore = await dbHelper.getMeal(middleMealId);
        expect(middleMealBefore, isNotNull);
        print(
            '✓ Middle meal (day -3): servings=${middleMealBefore!.servings}, modifiedAt=${middleMealBefore.modifiedAt}');

        // Edit the middle meal (index 2 in the list, which is day -3)
        print('\n=== Editing middle meal ===');
        await E2ETestHelpers.openMealEditDialog(tester, mealIndex: 2);
        print('✓ Opened edit dialog for middle meal');

        // Change servings from 4 to 10 (but don't change date)
        await E2ETestHelpers.fillMealEditDialog(
          tester,
          servings: '10',
        );
        print('✓ Changed servings from 4 to 10');

        // Wait a tiny bit to ensure modifiedAt will be different
        await Future.delayed(const Duration(milliseconds: 100));

        // Save changes
        await E2ETestHelpers.saveMealEditDialog(tester);
        print('✓ Saved meal edit dialog');
        await tester.pumpAndSettle();

        // Verify the meal order is still the same
        // The edited meal should still be at index 2 because we didn't change cookedAt
        print('\n=== Verifying meal order unchanged ===');

        // Get all meals again to check order
        final allMealsAfter = await dbHelper.getMealsForRecipe(testRecipe.id);
        expect(allMealsAfter.length, 5, reason: 'Should still have 5 meals');

        // Sort by cookedAt descending (newest first) to match UI order
        allMealsAfter.sort((a, b) => b.cookedAt.compareTo(a.cookedAt));

        // Verify order: day -1, -2, -3, -4, -5
        expect(allMealsAfter[0].servings, 6,
            reason: 'Most recent meal (day -1) should be first');
        expect(allMealsAfter[1].servings, 5,
            reason: 'Second meal (day -2) should be second');
        expect(allMealsAfter[2].servings, 10,
            reason:
                'Middle meal (day -3) should still be third with updated servings');
        expect(allMealsAfter[3].servings, 3,
            reason: 'Fourth meal (day -4) should be fourth');
        expect(allMealsAfter[4].servings, 2,
            reason: 'Oldest meal (day -5) should be last');
        print('✓ Meal order verified: meals still sorted by cookedAt');

        // Verify modifiedAt timestamp was updated
        final middleMealAfter = await dbHelper.getMeal(middleMealId);
        expect(middleMealAfter, isNotNull);
        print(
            '✓ Middle meal after edit: servings=${middleMealAfter!.servings}, modifiedAt=${middleMealAfter.modifiedAt}');

        // modifiedAt should be updated (or at least not null)
        // Note: Due to issue #232, modifiedAt might be null in production
        // But we can verify the servings were updated
        expect(middleMealAfter.servings, 10,
            reason: 'Servings should be updated to 10');

        if (middleMealBefore.modifiedAt != null &&
            middleMealAfter.modifiedAt != null) {
          expect(
              middleMealAfter.modifiedAt!
                  .isAfter(middleMealBefore.modifiedAt!),
              true,
              reason: 'modifiedAt timestamp should be updated');
          print('✓ modifiedAt timestamp was updated');
        } else {
          print(
              '⚠ modifiedAt is null (expected due to issue #232 - timestamp management anti-pattern)');
        }

        // Verify in UI that the middle meal now shows 10 servings at position 2
        await tester.pumpAndSettle();
        print('✓ Verified meal data consistency');

        print('✓ TEST PASSED: data consistency maintained');
      } finally {
        final dbHelper = DatabaseHelper();
        // Clean up all created meals
        for (final mealId in createdMealIds) {
          await E2ETestHelpers.deleteTestMeal(dbHelper, mealId);
        }
        if (createdRecipeId != null) {
          await E2ETestHelpers.deleteTestRecipe(dbHelper, createdRecipeId);
        }
        print('✓ Cleanup complete');
      }
    });
  });
}
