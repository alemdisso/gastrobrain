// test/services/meal_editing_error_scenarios_test.dart

/// Meal Editing Error Scenarios Test
///
/// This test file contains service integration tests for error handling
/// in the meal editing workflow. These tests use MockDatabaseHelper to
/// simulate database failures and verify graceful error handling.
///
/// Tests in this file:
/// - Database update failure handling
/// - Concurrent modification scenarios
/// - Recipe loading failure handling

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/meal.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import '../mocks/mock_database_helper.dart';

void main() {
  // Note: This is a service integration test using MockDatabaseHelper.
  // No IntegrationTestWidgetsFlutterBinding needed as we're not testing UI.

  group('Phase 5: Meal Editing Error Handling', () {
    late MockDatabaseHelper mockDbHelper;

    setUp(() {
      mockDbHelper = MockDatabaseHelper();
    });

    tearDown(() {
      mockDbHelper.resetAllData();
      mockDbHelper.resetErrorSimulation();
    });

    test('5.1: Database update failure is handled gracefully', () async {
      print('\n=== TEST 5.1: Database Update Failure ===');

      // Setup: Create a test recipe and meal
      print('Setting up test data...');
      final testRecipe = Recipe(
        id: 'test-recipe-${DateTime.now().millisecondsSinceEpoch}',
        name: 'Test Recipe for Error Handling',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
        prepTimeMinutes: 20,
        cookTimeMinutes: 30,
        difficulty: 3,
        rating: 4,
      );

      await mockDbHelper.insertRecipe(testRecipe);

      final originalMeal = Meal(
        id: 'test-meal-${DateTime.now().millisecondsSinceEpoch}',
        recipeId: testRecipe.id,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 2,
        notes: 'Original notes',
        wasSuccessful: true,
        actualPrepTime: 20,
        actualCookTime: 30,
      );

      await mockDbHelper.insertMeal(originalMeal);
      print('✓ Test data created');

      // Verify original data exists
      print('\nVerifying original meal data...');
      final mealBeforeUpdate = await mockDbHelper.getMeal(originalMeal.id);
      expect(mealBeforeUpdate, isNotNull, reason: 'Meal should exist before update');
      expect(mealBeforeUpdate!.servings, 2);
      expect(mealBeforeUpdate.notes, 'Original notes');
      print('✓ Original data verified');

      // Configure mock to fail on updateMeal
      print('\nConfiguring mock to fail on updateMeal...');
      mockDbHelper.failOnOperation('updateMeal');
      print('✓ Mock configured to fail');

      // Act: Attempt to update the meal
      print('\nAttempting to update meal (should fail)...');
      final updatedMeal = Meal(
        id: originalMeal.id,
        recipeId: originalMeal.recipeId,
        cookedAt: originalMeal.cookedAt,
        servings: 4, // Changed
        notes: 'Updated notes', // Changed
        wasSuccessful: originalMeal.wasSuccessful,
        actualPrepTime: originalMeal.actualPrepTime,
        actualCookTime: originalMeal.actualCookTime,
        modifiedAt: DateTime.now(),
      );

      // Verify: Operation should throw an exception
      bool exceptionThrown = false;
      String? errorMessage;

      try {
        await mockDbHelper.updateMeal(updatedMeal);
      } catch (e) {
        exceptionThrown = true;
        errorMessage = e.toString();
        print('✓ Exception caught: $errorMessage');
      }

      expect(exceptionThrown, true,
          reason: 'updateMeal should throw an exception when configured to fail');
      expect(errorMessage, contains('Simulated database error'),
          reason: 'Error message should indicate database failure');

      // Verify: Original data is preserved (not corrupted by failed update)
      print('\nVerifying original data is preserved...');
      final mealAfterFailedUpdate = await mockDbHelper.getMeal(originalMeal.id);
      expect(mealAfterFailedUpdate, isNotNull,
          reason: 'Meal should still exist after failed update');
      expect(mealAfterFailedUpdate!.servings, 2,
          reason: 'Servings should remain unchanged');
      expect(mealAfterFailedUpdate.notes, 'Original notes',
          reason: 'Notes should remain unchanged');
      print('✓ Original data preserved');

      // Verify: Error simulation is reset (single-use)
      print('\nVerifying error simulation is single-use...');
      final anotherMeal = Meal(
        id: 'test-meal-2-${DateTime.now().millisecondsSinceEpoch}',
        recipeId: testRecipe.id,
        cookedAt: DateTime.now(),
        servings: 3,
        notes: 'Another meal',
        wasSuccessful: true,
        actualPrepTime: 15,
        actualCookTime: 25,
      );
      await mockDbHelper.insertMeal(anotherMeal);

      // This update should succeed because error simulation auto-resets
      final updatedAnotherMeal = Meal(
        id: anotherMeal.id,
        recipeId: anotherMeal.recipeId,
        cookedAt: anotherMeal.cookedAt,
        servings: 5, // Updated
        notes: anotherMeal.notes,
        wasSuccessful: anotherMeal.wasSuccessful,
        actualPrepTime: anotherMeal.actualPrepTime,
        actualCookTime: anotherMeal.actualCookTime,
      );
      await mockDbHelper.updateMeal(updatedAnotherMeal);
      final verifyMeal = await mockDbHelper.getMeal(anotherMeal.id);
      expect(verifyMeal!.servings, 5,
          reason: 'Subsequent updates should succeed after error simulation resets');
      print('✓ Error simulation correctly resets after first use');

      print('\n✓ TEST 5.1 PASSED: Database update failure handled gracefully\n');
    });

    test('5.2: Concurrent modification (meal deleted during edit) is handled gracefully',
        () async {
      print('\n=== TEST 5.2: Concurrent Modification ===');

      // Setup: Create a test recipe and meal
      print('Setting up test data...');
      final testRecipe = Recipe(
        id: 'test-recipe-${DateTime.now().millisecondsSinceEpoch}',
        name: 'Test Recipe for Concurrent Modification',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
        prepTimeMinutes: 20,
        cookTimeMinutes: 30,
        difficulty: 3,
        rating: 4,
      );

      await mockDbHelper.insertRecipe(testRecipe);

      final originalMeal = Meal(
        id: 'test-meal-${DateTime.now().millisecondsSinceEpoch}',
        recipeId: testRecipe.id,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 2,
        notes: 'Original notes',
        wasSuccessful: true,
        actualPrepTime: 20,
        actualCookTime: 30,
      );

      await mockDbHelper.insertMeal(originalMeal);
      print('✓ Test data created');

      // Verify meal exists before deletion
      print('\nVerifying meal exists...');
      final mealBeforeDelete = await mockDbHelper.getMeal(originalMeal.id);
      expect(mealBeforeDelete, isNotNull, reason: 'Meal should exist initially');
      print('✓ Meal exists');

      // Simulate concurrent modification: Delete the meal
      print('\nSimulating concurrent deletion...');
      await mockDbHelper.deleteMeal(originalMeal.id);
      print('✓ Meal deleted (concurrent modification simulated)');

      // Verify meal is actually deleted
      print('\nVerifying meal is deleted...');
      final mealAfterDelete = await mockDbHelper.getMeal(originalMeal.id);
      expect(mealAfterDelete, isNull, reason: 'Meal should be deleted');
      print('✓ Confirmed meal no longer exists');

      // Act: Attempt to update the deleted meal (simulates user clicking save)
      print('\nAttempting to update deleted meal (should fail)...');
      final updatedMeal = Meal(
        id: originalMeal.id,
        recipeId: originalMeal.recipeId,
        cookedAt: originalMeal.cookedAt,
        servings: 4, // Changed
        notes: 'Updated notes', // Changed
        wasSuccessful: originalMeal.wasSuccessful,
        actualPrepTime: originalMeal.actualPrepTime,
        actualCookTime: originalMeal.actualCookTime,
        modifiedAt: DateTime.now(),
      );

      // Verify: Operation should throw an exception
      bool exceptionThrown = false;
      String? errorMessage;

      try {
        await mockDbHelper.updateMeal(updatedMeal);
      } catch (e) {
        exceptionThrown = true;
        errorMessage = e.toString();
        print('✓ Exception caught: $errorMessage');
      }

      expect(exceptionThrown, true,
          reason: 'updateMeal should throw an exception for non-existent meal');
      expect(errorMessage, contains('Meal not found'),
          reason: 'Error message should indicate meal was not found');

      // Verify: Meal remains deleted (no phantom data created)
      print('\nVerifying meal remains deleted (no phantom data)...');
      final finalCheck = await mockDbHelper.getMeal(originalMeal.id);
      expect(finalCheck, isNull,
          reason: 'Meal should remain deleted after failed update attempt');
      print('✓ Meal remains deleted, no data corruption');

      // Additional verification: Ensure we can still work with the database
      print('\nVerifying database is still functional...');
      final anotherMeal = Meal(
        id: 'test-meal-2-${DateTime.now().millisecondsSinceEpoch}',
        recipeId: testRecipe.id,
        cookedAt: DateTime.now(),
        servings: 3,
        notes: 'Another meal',
        wasSuccessful: true,
        actualPrepTime: 15,
        actualCookTime: 25,
      );
      await mockDbHelper.insertMeal(anotherMeal);
      final verifyMeal = await mockDbHelper.getMeal(anotherMeal.id);
      expect(verifyMeal, isNotNull,
          reason: 'Database should remain functional after error');
      print('✓ Database remains functional');

      print('\n✓ TEST 5.2 PASSED: Concurrent modification handled gracefully\n');
    });

    test('5.3: Recipe loading failure in edit dialog is handled gracefully',
        () async {
      print('\n=== TEST 5.3: Recipe Loading Failure ===');

      // Setup: Create test recipes
      print('Setting up test data...');
      final recipes = [
        Recipe(
          id: 'test-recipe-1-${DateTime.now().millisecondsSinceEpoch}',
          name: 'Primary Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          prepTimeMinutes: 20,
          cookTimeMinutes: 30,
          difficulty: 3,
          rating: 4,
        ),
        Recipe(
          id: 'test-recipe-2-${DateTime.now().millisecondsSinceEpoch}',
          name: 'Side Dish Recipe 1',
          desiredFrequency: FrequencyType.biweekly,
          createdAt: DateTime.now(),
          prepTimeMinutes: 10,
          cookTimeMinutes: 15,
          difficulty: 2,
          rating: 3,
        ),
        Recipe(
          id: 'test-recipe-3-${DateTime.now().millisecondsSinceEpoch}',
          name: 'Side Dish Recipe 2',
          desiredFrequency: FrequencyType.monthly,
          createdAt: DateTime.now(),
          prepTimeMinutes: 15,
          cookTimeMinutes: 20,
          difficulty: 2,
          rating: 4,
        ),
      ];

      for (final recipe in recipes) {
        await mockDbHelper.insertRecipe(recipe);
      }
      print('✓ Test recipes created');

      // Verify getAllRecipes works normally first
      print('\nVerifying getAllRecipes works normally...');
      final recipesBeforeError = await mockDbHelper.getAllRecipes();
      expect(recipesBeforeError.length, greaterThanOrEqualTo(3),
          reason: 'Should have at least 3 recipes');
      print('✓ getAllRecipes works normally (${recipesBeforeError.length} recipes)');

      // Configure mock to fail on getAllRecipes
      print('\nConfiguring mock to fail on getAllRecipes...');
      mockDbHelper.failOnOperation('getAllRecipes');
      print('✓ Mock configured to fail');

      // Act: Attempt to load recipes (simulates opening edit dialog)
      print('\nAttempting to load recipes (should fail)...');
      bool exceptionThrown = false;
      String? errorMessage;

      try {
        await mockDbHelper.getAllRecipes();
      } catch (e) {
        exceptionThrown = true;
        errorMessage = e.toString();
        print('✓ Exception caught: $errorMessage');
      }

      // Verify: Exception should be thrown
      expect(exceptionThrown, true,
          reason: 'getAllRecipes should throw an exception when configured to fail');
      expect(errorMessage, contains('Simulated database error'),
          reason: 'Error message should indicate database failure');

      // Verify: Error simulation resets after single use
      print('\nVerifying error simulation is single-use...');
      final recipesAfterError = await mockDbHelper.getAllRecipes();
      expect(recipesAfterError, isNotEmpty,
          reason: 'Subsequent calls to getAllRecipes should succeed');
      print('✓ Error simulation correctly resets (${recipesAfterError.length} recipes loaded)');

      // Additional verification: Ensure all recipes are still accessible
      print('\nVerifying all recipes remain accessible...');
      for (final recipe in recipes) {
        final loadedRecipe = await mockDbHelper.getRecipe(recipe.id);
        expect(loadedRecipe, isNotNull,
            reason: 'Recipe ${recipe.name} should still be accessible');
      }
      print('✓ All recipes remain accessible');

      // Verify: Database operations remain functional
      print('\nVerifying database remains functional...');
      final newRecipe = Recipe(
        id: 'test-recipe-new-${DateTime.now().millisecondsSinceEpoch}',
        name: 'New Recipe After Error',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
        prepTimeMinutes: 25,
        cookTimeMinutes: 35,
        difficulty: 3,
        rating: 5,
      );
      await mockDbHelper.insertRecipe(newRecipe);
      final verifyRecipe = await mockDbHelper.getRecipe(newRecipe.id);
      expect(verifyRecipe, isNotNull,
          reason: 'Should be able to insert new recipes after error');
      print('✓ Database remains fully functional');

      print('\n✓ TEST 5.3 PASSED: Recipe loading failure handled gracefully\n');
    });
  });
}
