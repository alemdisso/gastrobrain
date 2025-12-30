// test/edge_cases/error_scenarios/database_crud_failures_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/meal.dart';
import 'package:gastrobrain/models/ingredient.dart';
import 'package:gastrobrain/models/ingredient_category.dart';
import 'package:gastrobrain/models/measurement_unit.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/utils/id_generator.dart';
import '../../mocks/mock_database_helper.dart';
import '../../helpers/error_injection_helpers.dart';
import '../../helpers/edge_case_test_helpers.dart';

/// Tests for database CRUD (Create, Read, Update, Delete) operation failures.
///
/// Verifies that the application handles CRUD failures gracefully:
/// - Insert operations failing
/// - Update operations failing (no partial updates)
/// - Delete operations failing (UI consistency)
/// - Query timeouts and failures
/// - Constraint violations (unique, foreign key)
/// - Transaction rollback behavior
/// - Appropriate user feedback
///
/// These tests ensure data integrity and graceful error handling when
/// database operations fail for any reason.
void main() {
  group('Database CRUD Operation Failures', () {
    late MockDatabaseHelper mockDbHelper;

    setUp(() {
      mockDbHelper = MockDatabaseHelper();
    });

    tearDown(() {
      mockDbHelper.resetAllData();
      ErrorInjectionHelpers.resetErrorInjection(mockDbHelper);
    });

    // Helper to create a test recipe
    Recipe createRecipe({
      String? id,
      String name = 'Test Recipe',
      int rating = 3,
      int difficulty = 3,
    }) {
      return Recipe(
        id: id ?? IdGenerator.generateId(),
        name: name,
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
        difficulty: difficulty,
        rating: rating,
        prepTimeMinutes: 20,
        cookTimeMinutes: 40,
      );
    }

    // Helper to create a test meal
    Meal createMeal({
      String? id,
      required String recipeId,
      required DateTime cookedAt,
      int servings = 2,
    }) {
      return Meal(
        id: id ?? IdGenerator.generateId(),
        recipeId: recipeId,
        cookedAt: cookedAt,
        servings: servings,
        wasSuccessful: true,
      );
    }

    group('Insert Operation Failures', () {
      test('insertRecipe fails - error handled gracefully', () async {
        // Inject insert error
        ErrorInjectionHelpers.injectDatabaseError(
          mockDbHelper,
          ErrorType.insertFailed,
          operation: 'insertRecipe',
        );

        final recipe = createRecipe(name: 'Test Recipe');

        // Attempt to insert
        expect(
          () async => await mockDbHelper.insertRecipe(recipe),
          throwsException,
          reason: 'Insert should throw exception when error is injected',
        );

        // Verify no partial data stored
        final recipes = await mockDbHelper.getAllRecipes();
        expect(recipes, isEmpty,
            reason: 'No recipe should be stored after failed insert');
      });

      test('insertMeal fails - no side effects', () async {
        // Create a recipe first
        final recipe = createRecipe(name: 'Test Recipe');
        await mockDbHelper.insertRecipe(recipe);

        // Inject error for meal insert
        ErrorInjectionHelpers.injectDatabaseError(
          mockDbHelper,
          ErrorType.insertFailed,
          operation: 'insertMeal',
        );

        final meal = createMeal(
          recipeId: recipe.id,
          cookedAt: DateTime.now(),
        );

        // Attempt to insert
        expect(
          () async => await mockDbHelper.insertMeal(meal),
          throwsException,
        );

        // Verify meal was not stored
        final meals = mockDbHelper.meals.values.toList();
        expect(meals, isEmpty, reason: 'Failed insert should not store meal');

        // Verify recipe is still intact
        final retrievedRecipe = await mockDbHelper.getRecipe(recipe.id);
        expect(retrievedRecipe, isNotNull,
            reason: 'Recipe should remain intact after failed meal insert');
      });

      test('insertIngredient fails - database remains consistent', () async {
        // Inject error
        ErrorInjectionHelpers.injectOperationError(
          mockDbHelper,
          operation: 'insertIngredient',
          errorMessage: 'Insert constraint violation',
        );

        final ingredient = Ingredient(
          id: IdGenerator.generateId(),
          name: 'Test Ingredient',
          category: IngredientCategory.vegetable,
          unit: MeasurementUnit.gram,
        );

        // Attempt to insert
        expect(
          () async => await mockDbHelper.insertIngredient(ingredient),
          throwsException,
        );

        // Verify no ingredient stored
        final ingredients = await mockDbHelper.getAllIngredients();
        expect(ingredients, isEmpty);
      });

      test('multiple insert failures are handled independently', () async {
        // First failure
        ErrorInjectionHelpers.injectDatabaseError(
          mockDbHelper,
          ErrorType.insertFailed,
          operation: 'insertRecipe',
        );

        final recipe1 = createRecipe(name: 'Recipe 1');

        expect(() async => await mockDbHelper.insertRecipe(recipe1),
            throwsException);

        // Reset and try different insert
        ErrorInjectionHelpers.resetErrorInjection(mockDbHelper);
        ErrorInjectionHelpers.injectDatabaseError(
          mockDbHelper,
          ErrorType.insertFailed,
          operation: 'insertMeal',
        );

        final meal = createMeal(
          recipeId: 'test-recipe',
          cookedAt: DateTime.now(),
        );

        expect(() async => await mockDbHelper.insertMeal(meal), throwsException);

        // Verify database is empty (both inserts failed)
        expect(await mockDbHelper.getAllRecipes(), isEmpty);
        expect(mockDbHelper.meals.values, isEmpty);
      });
    });

    group('Update Operation Failures', () {
      test('updateRecipe fails - original data remains unchanged', () async {
        // Insert a recipe first
        final originalRecipe = createRecipe(
          name: 'Original Recipe',
          rating: 3,
        );
        await mockDbHelper.insertRecipe(originalRecipe);

        // Inject update error
        ErrorInjectionHelpers.injectDatabaseError(
          mockDbHelper,
          ErrorType.updateFailed,
          operation: 'updateRecipe',
        );

        // Create updated version
        final updatedRecipe = Recipe(
          id: originalRecipe.id,
          name: 'Updated Recipe',
          rating: 5,
          difficulty: originalRecipe.difficulty,
          desiredFrequency: originalRecipe.desiredFrequency,
          createdAt: originalRecipe.createdAt,
          prepTimeMinutes: originalRecipe.prepTimeMinutes,
          cookTimeMinutes: originalRecipe.cookTimeMinutes,
        );

        // Attempt to update
        expect(
          () async => await mockDbHelper.updateRecipe(updatedRecipe),
          throwsException,
        );

        // Verify original data is unchanged
        final retrievedRecipe = await mockDbHelper.getRecipe(originalRecipe.id);
        expect(retrievedRecipe?.name, equals('Original Recipe'),
            reason: 'Recipe name should not change after failed update');
        expect(retrievedRecipe?.rating, equals(3),
            reason: 'Recipe rating should not change after failed update');
      });

      test('updateMeal fails - no partial updates occur', () async {
        // Insert a meal
        final originalMeal = createMeal(
          recipeId: 'recipe-1',
          cookedAt: DateTime(2024, 1, 1),
          servings: 2,
        );
        await mockDbHelper.insertMeal(originalMeal);

        // Inject update error
        ErrorInjectionHelpers.injectDatabaseError(
          mockDbHelper,
          ErrorType.updateFailed,
          operation: 'updateMeal',
        );

        // Create updated version
        final updatedMeal = Meal(
          id: originalMeal.id,
          recipeId: originalMeal.recipeId,
          cookedAt: DateTime(2024, 1, 15),
          servings: 4,
          wasSuccessful: originalMeal.wasSuccessful,
        );

        // Attempt to update
        expect(
          () async => await mockDbHelper.updateMeal(updatedMeal),
          throwsException,
        );

        // Verify original data unchanged
        final retrievedMeal = await mockDbHelper.getMeal(originalMeal.id);
        expect(retrievedMeal?.servings, equals(2),
            reason: 'Servings should not change after failed update');
        expect(retrievedMeal?.cookedAt, equals(DateTime(2024, 1, 1)),
            reason: 'Date should not change after failed update');
      });

      test('updateIngredient fails - original data preserved', () async {
        // Insert ingredient
        final originalIngredient = Ingredient(
          id: IdGenerator.generateId(),
          name: 'Original Name',
          category: IngredientCategory.vegetable,
          unit: MeasurementUnit.gram,
        );
        await mockDbHelper.insertIngredient(originalIngredient);

        // Inject error
        ErrorInjectionHelpers.injectDatabaseError(
          mockDbHelper,
          ErrorType.updateFailed,
          operation: 'updateIngredient',
        );

        // Attempt update
        final updatedIngredient = Ingredient(
          id: originalIngredient.id,
          name: 'Updated Name',
          category: IngredientCategory.grain,
          unit: MeasurementUnit.kilogram,
        );

        expect(
          () async => await mockDbHelper.updateIngredient(updatedIngredient),
          throwsException,
        );

        // Verify original preserved
        final ingredients = await mockDbHelper.getAllIngredients();
        final retrieved =
            ingredients.firstWhere((i) => i.id == originalIngredient.id);
        expect(retrieved.name, equals('Original Name'));
        expect(retrieved.category, equals(IngredientCategory.vegetable));
      });

      test('update of non-existent record fails appropriately', () async {
        // Attempt to update a recipe that doesn't exist
        final nonExistentRecipe = createRecipe(
          id: 'non-existent-id',
          name: 'Ghost Recipe',
        );

        final result = await mockDbHelper.updateRecipe(nonExistentRecipe);

        // Should return 0 (no rows updated)
        expect(result, equals(0),
            reason: 'Updating non-existent record should return 0');

        // Verify it wasn't created
        final recipe = await mockDbHelper.getRecipe('non-existent-id');
        expect(recipe, isNull,
            reason: 'Update should not create a new record');
      });

      test('concurrent update attempts are handled', () async {
        // Insert a recipe
        final recipe = createRecipe(name: 'Concurrent Recipe');
        await mockDbHelper.insertRecipe(recipe);

        // First update should succeed
        final update1 = Recipe(
          id: recipe.id,
          name: 'Update 1',
          desiredFrequency: recipe.desiredFrequency,
          createdAt: recipe.createdAt,
          difficulty: recipe.difficulty,
          rating: recipe.rating,
          prepTimeMinutes: recipe.prepTimeMinutes,
          cookTimeMinutes: recipe.cookTimeMinutes,
        );
        await mockDbHelper.updateRecipe(update1);

        // Inject error for second update
        ErrorInjectionHelpers.injectDatabaseError(
          mockDbHelper,
          ErrorType.updateFailed,
          operation: 'updateRecipe',
        );

        // Second update should fail
        final update2 = Recipe(
          id: recipe.id,
          name: 'Update 2',
          desiredFrequency: recipe.desiredFrequency,
          createdAt: recipe.createdAt,
          difficulty: recipe.difficulty,
          rating: recipe.rating,
          prepTimeMinutes: recipe.prepTimeMinutes,
          cookTimeMinutes: recipe.cookTimeMinutes,
        );
        expect(() async => await mockDbHelper.updateRecipe(update2),
            throwsException);

        // Verify first update persisted
        final retrieved = await mockDbHelper.getRecipe(recipe.id);
        expect(retrieved?.name, equals('Update 1'),
            reason: 'First update should persist despite second update failure');
      });
    });

    group('Delete Operation Failures', () {
      test('deleteRecipe fails - recipe remains in database', () async {
        // Insert a recipe
        final recipe = createRecipe(name: 'Test Recipe');
        await mockDbHelper.insertRecipe(recipe);

        // Inject delete error
        ErrorInjectionHelpers.injectDatabaseError(
          mockDbHelper,
          ErrorType.deleteFailed,
          operation: 'deleteRecipe',
        );

        // Attempt to delete
        expect(
          () async => await mockDbHelper.deleteRecipe(recipe.id),
          throwsException,
        );

        // Verify recipe still exists
        final retrievedRecipe = await mockDbHelper.getRecipe(recipe.id);
        expect(retrievedRecipe, isNotNull,
            reason: 'Recipe should remain after failed delete');
        expect(retrievedRecipe?.name, equals('Test Recipe'));
      });

      test('deleteMeal fails - meal remains with all relationships', () async {
        // Insert recipe and meal
        final recipe = createRecipe(name: 'Test Recipe');
        await mockDbHelper.insertRecipe(recipe);

        final meal = createMeal(
          recipeId: recipe.id,
          cookedAt: DateTime.now(),
        );
        await mockDbHelper.insertMeal(meal);

        // Use the built-in delete error flag
        mockDbHelper.shouldThrowOnDelete = true;

        // Attempt to delete
        expect(
          () async => await mockDbHelper.deleteMeal(meal.id),
          throwsException,
        );

        // Reset flag
        mockDbHelper.shouldThrowOnDelete = false;

        // Verify meal still exists
        final retrievedMeal = await mockDbHelper.getMeal(meal.id);
        expect(retrievedMeal, isNotNull,
            reason: 'Meal should remain after failed delete');

        // Verify related data intact
        final relatedMeals = await mockDbHelper.getMealsForRecipe(recipe.id);
        expect(relatedMeals, isNotEmpty,
            reason: 'Meal-recipe relationship should be intact');
      });

      test('deleteIngredient fails - ingredient preserved', () async {
        // Insert ingredient
        final ingredient = Ingredient(
          id: IdGenerator.generateId(),
          name: 'Test Ingredient',
          category: IngredientCategory.vegetable,
          unit: MeasurementUnit.gram,
        );
        await mockDbHelper.insertIngredient(ingredient);

        // Inject error
        ErrorInjectionHelpers.injectDatabaseError(
          mockDbHelper,
          ErrorType.deleteFailed,
          operation: 'deleteIngredient',
        );

        // Attempt delete
        expect(
          () async => await mockDbHelper.deleteIngredient(ingredient.id),
          throwsException,
        );

        // Verify ingredient exists
        final ingredients = await mockDbHelper.getAllIngredients();
        expect(ingredients.any((i) => i.id == ingredient.id), isTrue,
            reason: 'Ingredient should remain after failed delete');
      });

      test('delete of non-existent record handled gracefully', () async {
        // Attempt to delete non-existent recipe
        final result = await mockDbHelper.deleteRecipe('non-existent-id');

        // Should return 0 (no rows deleted)
        expect(result, equals(0),
            reason: 'Deleting non-existent record should return 0');

        // Database should remain stable
        final recipes = await mockDbHelper.getAllRecipes();
        expect(recipes, isEmpty, reason: 'Database should remain empty');
      });

      test('failed delete maintains data consistency', () async {
        // Insert multiple recipes
        final recipe1 = createRecipe(name: 'Recipe 1');
        final recipe2 = createRecipe(name: 'Recipe 2');
        await mockDbHelper.insertRecipe(recipe1);
        await mockDbHelper.insertRecipe(recipe2);

        // Inject error for first delete
        ErrorInjectionHelpers.injectDatabaseError(
          mockDbHelper,
          ErrorType.deleteFailed,
          operation: 'deleteRecipe',
        );

        // Attempt to delete first recipe
        expect(() async => await mockDbHelper.deleteRecipe(recipe1.id),
            throwsException);

        // Reset error and delete second recipe successfully
        ErrorInjectionHelpers.resetErrorInjection(mockDbHelper);
        await mockDbHelper.deleteRecipe(recipe2.id);

        // Verify consistency: recipe1 exists, recipe2 deleted
        final recipes = await mockDbHelper.getAllRecipes();
        expect(recipes.length, equals(1));
        expect(recipes.first.id, equals(recipe1.id),
            reason: 'Only failed-delete recipe should remain');
      });
    });

    group('Query Timeout & Failure Scenarios', () {
      test('query timeout - error thrown appropriately', () async {
        // Inject timeout error
        ErrorInjectionHelpers.simulateTimeout(
          mockDbHelper,
          operation: 'getAllRecipes',
        );

        // Attempt query
        expect(
          () async => await mockDbHelper.getAllRecipes(),
          throwsException,
          reason: 'Query timeout should throw exception',
        );
      });

      test('query failure - database remains accessible', () async {
        // Insert some data first
        final recipe = createRecipe(name: 'Test Recipe');
        await mockDbHelper.insertRecipe(recipe);

        // Inject query failure
        ErrorInjectionHelpers.simulateQueryFailure(
          mockDbHelper,
          operation: 'getAllRecipes',
          reason: 'Query execution failed',
        );

        // Query should fail
        expect(() async => await mockDbHelper.getAllRecipes(), throwsException);

        // Reset error
        ErrorInjectionHelpers.resetErrorInjection(mockDbHelper);

        // Database should still be accessible
        final recipes = await mockDbHelper.getAllRecipes();
        expect(recipes, isNotEmpty,
            reason: 'Database should be accessible after query failure');
      });

      test('getMeal query timeout handled', () async {
        // Insert meal
        final meal = createMeal(
          recipeId: 'test-recipe',
          cookedAt: DateTime.now(),
        );
        await mockDbHelper.insertMeal(meal);

        // Inject timeout
        ErrorInjectionHelpers.simulateTimeout(
          mockDbHelper,
          operation: 'getMeal',
        );

        // Query should timeout
        expect(() async => await mockDbHelper.getMeal(meal.id), throwsException);

        // Reset and verify meal still exists
        ErrorInjectionHelpers.resetErrorInjection(mockDbHelper);
        final retrieved = await mockDbHelper.getMeal(meal.id);
        expect(retrieved, isNotNull);
      });

      test('getMealsForRecipe query failure', () async {
        // Insert data
        final recipe = createRecipe(name: 'Test Recipe');
        await mockDbHelper.insertRecipe(recipe);

        // Inject query failure
        ErrorInjectionHelpers.simulateQueryFailure(
          mockDbHelper,
          operation: 'getMealsForRecipe',
          reason: 'Complex query failed',
        );

        // Should throw
        expect(
          () async => await mockDbHelper.getMealsForRecipe(recipe.id),
          throwsException,
        );
      });
    });

    group('Constraint Violation Scenarios', () {
      test('unique constraint violation on insert', () async {
        // Simulate unique constraint violation
        ErrorInjectionHelpers.simulateConstraintViolation(
          mockDbHelper,
          operation: 'insertRecipe',
          constraint: 'UNIQUE constraint failed: recipes.name',
        );

        final recipe = createRecipe(name: 'Duplicate Name');

        // Should throw constraint violation
        expect(
          () async => await mockDbHelper.insertRecipe(recipe),
          throwsException,
        );

        // Verify no data inserted
        final recipes = await mockDbHelper.getAllRecipes();
        expect(recipes, isEmpty);
      });

      test('foreign key constraint violation on insert', () async {
        // Simulate foreign key violation
        ErrorInjectionHelpers.simulateForeignKeyError(
          mockDbHelper,
          operation: 'insertMeal',
          message: 'FOREIGN KEY constraint failed: meals.recipeId',
        );

        final meal = createMeal(
          recipeId: 'non-existent-recipe-id',
          cookedAt: DateTime.now(),
        );

        // Should throw FK violation
        expect(
          () async => await mockDbHelper.insertMeal(meal),
          throwsException,
        );

        // Verify no meal inserted
        expect(mockDbHelper.meals, isEmpty);
      });

      test('constraint violation on update', () async {
        // Insert a recipe first
        final recipe = createRecipe(name: 'Original Recipe');
        await mockDbHelper.insertRecipe(recipe);

        // Inject constraint violation for update
        ErrorInjectionHelpers.simulateConstraintViolation(
          mockDbHelper,
          operation: 'updateRecipe',
          constraint: 'UNIQUE constraint failed',
        );

        // Attempt update
        final updatedRecipe = Recipe(
          id: recipe.id,
          name: 'Updated Name',
          desiredFrequency: recipe.desiredFrequency,
          createdAt: recipe.createdAt,
          difficulty: recipe.difficulty,
          rating: recipe.rating,
          prepTimeMinutes: recipe.prepTimeMinutes,
          cookTimeMinutes: recipe.cookTimeMinutes,
        );
        expect(
          () async => await mockDbHelper.updateRecipe(updatedRecipe),
          throwsException,
        );

        // Verify original preserved
        final retrieved = await mockDbHelper.getRecipe(recipe.id);
        expect(retrieved?.name, equals('Original Recipe'));
      });

      test('foreign key constraint on delete', () async {
        // Insert recipe and meal
        final recipe = createRecipe(name: 'Test Recipe');
        await mockDbHelper.insertRecipe(recipe);

        final meal = createMeal(
          recipeId: recipe.id,
          cookedAt: DateTime.now(),
        );
        await mockDbHelper.insertMeal(meal);

        // Simulate FK constraint preventing delete
        ErrorInjectionHelpers.simulateForeignKeyError(
          mockDbHelper,
          operation: 'deleteRecipe',
          message: 'Cannot delete recipe with existing meals',
        );

        // Should throw FK violation
        expect(
          () async => await mockDbHelper.deleteRecipe(recipe.id),
          throwsException,
        );

        // Verify recipe still exists
        final retrieved = await mockDbHelper.getRecipe(recipe.id);
        expect(retrieved, isNotNull);
      });

      test('multiple constraint violations handled independently', () async {
        // First constraint violation
        ErrorInjectionHelpers.simulateConstraintViolation(
          mockDbHelper,
          operation: 'insertRecipe',
        );

        final recipe1 = createRecipe(name: 'Recipe 1');
        expect(() async => await mockDbHelper.insertRecipe(recipe1),
            throwsException);

        // Reset and try FK violation
        ErrorInjectionHelpers.resetErrorInjection(mockDbHelper);
        ErrorInjectionHelpers.simulateForeignKeyError(
          mockDbHelper,
          operation: 'insertMeal',
        );

        final meal = createMeal(
          recipeId: 'non-existent',
          cookedAt: DateTime.now(),
        );
        expect(() async => await mockDbHelper.insertMeal(meal), throwsException);

        // Both should have failed independently
        expect(await mockDbHelper.getAllRecipes(), isEmpty);
        expect(mockDbHelper.meals.values, isEmpty);
      });
    });

    group('Transaction Rollback & Data Consistency', () {
      test('failed insert does not leave partial data', () async {
        // Inject error
        ErrorInjectionHelpers.injectDatabaseError(
          mockDbHelper,
          ErrorType.insertFailed,
          operation: 'insertRecipe',
        );

        final recipe = createRecipe(name: 'Test Recipe');

        // Attempt insert
        expect(() async => await mockDbHelper.insertRecipe(recipe),
            throwsException);

        // Verify absolutely no data stored
        expect(mockDbHelper.recipes, isEmpty,
            reason: 'Failed insert should not leave any data');
        expect(await mockDbHelper.getAllRecipes(), isEmpty);
      });

      test('failed update maintains original state', () async {
        // Insert recipe
        final originalRecipe = createRecipe(
          name: 'Original',
          rating: 3,
          difficulty: 2,
        );
        await mockDbHelper.insertRecipe(originalRecipe);

        // Inject error
        ErrorInjectionHelpers.injectDatabaseError(
          mockDbHelper,
          ErrorType.updateFailed,
          operation: 'updateRecipe',
        );

        // Attempt update with multiple changes
        final updatedRecipe = Recipe(
          id: originalRecipe.id,
          name: 'Updated',
          rating: 5,
          difficulty: 4,
          desiredFrequency: originalRecipe.desiredFrequency,
          createdAt: originalRecipe.createdAt,
          prepTimeMinutes: originalRecipe.prepTimeMinutes,
          cookTimeMinutes: originalRecipe.cookTimeMinutes,
        );

        expect(() async => await mockDbHelper.updateRecipe(updatedRecipe),
            throwsException);

        // Verify ALL fields remain original (no partial update)
        final retrieved = await mockDbHelper.getRecipe(originalRecipe.id);
        expect(retrieved?.name, equals('Original'));
        expect(retrieved?.rating, equals(3));
        expect(retrieved?.difficulty, equals(2));
      });

      test('failed delete preserves all related data', () async {
        // Insert recipe with meal
        final recipe = createRecipe(name: 'Test Recipe');
        await mockDbHelper.insertRecipe(recipe);

        final meal = createMeal(
          recipeId: recipe.id,
          cookedAt: DateTime.now(),
        );
        await mockDbHelper.insertMeal(meal);

        // Use built-in delete error
        mockDbHelper.shouldThrowOnDelete = true;

        // Attempt delete
        expect(() async => await mockDbHelper.deleteMeal(meal.id),
            throwsException);

        mockDbHelper.shouldThrowOnDelete = false;

        // Verify both meal and relationships intact
        final retrievedMeal = await mockDbHelper.getMeal(meal.id);
        expect(retrievedMeal, isNotNull);

        final relatedMeals = await mockDbHelper.getMealsForRecipe(recipe.id);
        expect(relatedMeals, isNotEmpty,
            reason: 'Relationships should be preserved after failed delete');
      });

      test('error during operation does not affect other data', () async {
        // Insert some existing data
        final existingRecipe = createRecipe(name: 'Existing');
        await mockDbHelper.insertRecipe(existingRecipe);

        // Inject error for new insert
        ErrorInjectionHelpers.injectDatabaseError(
          mockDbHelper,
          ErrorType.insertFailed,
          operation: 'insertRecipe',
        );

        final newRecipe = createRecipe(name: 'New Recipe');
        expect(() async => await mockDbHelper.insertRecipe(newRecipe),
            throwsException);

        // Verify existing data unaffected
        final recipes = await mockDbHelper.getAllRecipes();
        expect(recipes.length, equals(1));
        expect(recipes.first.name, equals('Existing'),
            reason: 'Existing data should not be affected by failed insert');
      });
    });

    group('User Feedback & Error Messages', () {
      test('insert failure provides meaningful error', () async {
        ErrorInjectionHelpers.injectOperationError(
          mockDbHelper,
          operation: 'insertRecipe',
          errorMessage: 'Disk space insufficient for insert',
        );

        final recipe = createRecipe(name: 'Test Recipe');

        // Capture error message
        try {
          await mockDbHelper.insertRecipe(recipe);
          fail('Should have thrown exception');
        } catch (e) {
          expect(e.toString(), contains('Disk space insufficient'),
              reason: 'Error message should be descriptive');
        }
      });

      test('update failure provides context', () async {
        final recipe = createRecipe(name: 'Test Recipe');
        await mockDbHelper.insertRecipe(recipe);

        ErrorInjectionHelpers.injectOperationError(
          mockDbHelper,
          operation: 'updateRecipe',
          errorMessage: 'Record locked by another transaction',
        );

        try {
          final updatedRecipe = Recipe(
            id: recipe.id,
            name: 'Updated',
            desiredFrequency: recipe.desiredFrequency,
            createdAt: recipe.createdAt,
            difficulty: recipe.difficulty,
            rating: recipe.rating,
            prepTimeMinutes: recipe.prepTimeMinutes,
            cookTimeMinutes: recipe.cookTimeMinutes,
          );
          await mockDbHelper.updateRecipe(updatedRecipe);
          fail('Should have thrown exception');
        } catch (e) {
          expect(e.toString(), contains('locked'),
              reason: 'Error should explain why update failed');
        }
      });

      test('delete failure explains issue', () async {
        final recipe = createRecipe(name: 'Test Recipe');
        await mockDbHelper.insertRecipe(recipe);

        ErrorInjectionHelpers.injectOperationError(
          mockDbHelper,
          operation: 'deleteRecipe',
          errorMessage: 'Cannot delete: referenced by other records',
        );

        try {
          await mockDbHelper.deleteRecipe(recipe.id);
          fail('Should have thrown exception');
        } catch (e) {
          expect(e.toString(), contains('referenced by other records'),
              reason: 'Error should explain constraint preventing delete');
        }
      });

      test('constraint violation error is specific', () async {
        ErrorInjectionHelpers.simulateConstraintViolation(
          mockDbHelper,
          operation: 'insertRecipe',
          constraint: 'UNIQUE constraint failed: recipes.name',
        );

        final recipe = createRecipe(name: 'Duplicate');

        try {
          await mockDbHelper.insertRecipe(recipe);
          fail('Should have thrown exception');
        } catch (e) {
          expect(e.toString(), contains('UNIQUE constraint'),
              reason: 'Error should specify constraint type');
          expect(e.toString(), contains('recipes.name'),
              reason: 'Error should specify affected field');
        }
      });

      test('timeout error is distinguishable from other errors', () async {
        ErrorInjectionHelpers.simulateTimeout(
          mockDbHelper,
          operation: 'getAllRecipes',
        );

        try {
          await mockDbHelper.getAllRecipes();
          fail('Should have thrown exception');
        } catch (e) {
          expect(e.toString(), contains('timed out'),
              reason: 'Timeout errors should be clearly identified');
        }
      });
    });
  });
}
