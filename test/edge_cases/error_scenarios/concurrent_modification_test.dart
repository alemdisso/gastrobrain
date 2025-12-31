// test/edge_cases/error_scenarios/concurrent_modification_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/meal.dart';
import 'package:gastrobrain/models/meal_plan.dart';
import 'package:gastrobrain/models/meal_plan_item.dart';
import 'package:gastrobrain/models/ingredient.dart';
import 'package:gastrobrain/models/ingredient_category.dart';
import 'package:gastrobrain/models/measurement_unit.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/models/protein_type.dart';
import 'package:gastrobrain/utils/id_generator.dart';
import '../../mocks/mock_database_helper.dart';
import '../../helpers/error_injection_helpers.dart';

/// Tests for concurrent modification conflicts and race conditions.
///
/// Verifies that the application handles concurrent modifications gracefully:
/// - Recipe updated while being edited elsewhere
/// - Recipe deleted while being edited
/// - Meal planned in slot already occupied
/// - Ingredient updated while being added to recipe
/// - Last-write-wins behavior
/// - Conflict detection and notification
/// - Recovery options
///
/// Note: These tests simulate concurrent modifications using MockDatabaseHelper.
/// Real concurrent access would be tested in integration tests.
void main() {
  group('Concurrent Modification Conflicts', () {
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

    group('Concurrent Recipe Modifications', () {
      test('recipe updated while being edited elsewhere - last write wins',
          () async {
        // Initial recipe
        final recipe = createRecipe(name: 'Original Recipe', rating: 3);
        await mockDbHelper.insertRecipe(recipe);

        // User A reads the recipe
        final userAVersion = await mockDbHelper.getRecipe(recipe.id);
        expect(userAVersion, isNotNull);

        // User B reads the recipe
        final userBVersion = await mockDbHelper.getRecipe(recipe.id);
        expect(userBVersion, isNotNull);

        // User A updates the recipe
        final userAUpdate = Recipe(
          id: recipe.id,
          name: 'User A Update',
          rating: 4,
          difficulty: recipe.difficulty,
          desiredFrequency: recipe.desiredFrequency,
          createdAt: recipe.createdAt,
          prepTimeMinutes: recipe.prepTimeMinutes,
          cookTimeMinutes: recipe.cookTimeMinutes,
        );
        await mockDbHelper.updateRecipe(userAUpdate);

        // User B updates the recipe (without knowing about User A's changes)
        final userBUpdate = Recipe(
          id: recipe.id,
          name: 'User B Update',
          rating: 5,
          difficulty: recipe.difficulty,
          desiredFrequency: recipe.desiredFrequency,
          createdAt: recipe.createdAt,
          prepTimeMinutes: recipe.prepTimeMinutes,
          cookTimeMinutes: recipe.cookTimeMinutes,
        );
        await mockDbHelper.updateRecipe(userBUpdate);

        // Last write wins - User B's changes should be present
        final finalRecipe = await mockDbHelper.getRecipe(recipe.id);
        expect(finalRecipe?.name, equals('User B Update'),
            reason: 'Last write should win in concurrent updates');
        expect(finalRecipe?.rating, equals(5),
            reason: 'Last writer rating should be preserved');
      });

      test('recipe updated with different fields - last write overwrites all',
          () async {
        // Initial recipe
        final recipe = createRecipe(
          name: 'Original',
          rating: 3,
          difficulty: 3,
        );
        await mockDbHelper.insertRecipe(recipe);

        // User A updates name
        final userAUpdate = Recipe(
          id: recipe.id,
          name: 'Updated Name',
          rating: recipe.rating,
          difficulty: recipe.difficulty,
          desiredFrequency: recipe.desiredFrequency,
          createdAt: recipe.createdAt,
          prepTimeMinutes: recipe.prepTimeMinutes,
          cookTimeMinutes: recipe.cookTimeMinutes,
        );
        await mockDbHelper.updateRecipe(userAUpdate);

        // User B updates rating (based on original version)
        final userBUpdate = Recipe(
          id: recipe.id,
          name: recipe.name, // Uses original name
          rating: 5,
          difficulty: recipe.difficulty,
          desiredFrequency: recipe.desiredFrequency,
          createdAt: recipe.createdAt,
          prepTimeMinutes: recipe.prepTimeMinutes,
          cookTimeMinutes: recipe.cookTimeMinutes,
        );
        await mockDbHelper.updateRecipe(userBUpdate);

        // User A's name change is lost
        final finalRecipe = await mockDbHelper.getRecipe(recipe.id);
        expect(finalRecipe?.name, equals('Original'),
            reason: 'User A name change lost due to User B overwrite');
        expect(finalRecipe?.rating, equals(5),
            reason: 'User B rating change should be present');
      });

      test('recipe deleted while being edited - update fails gracefully',
          () async {
        // Initial recipe
        final recipe = createRecipe(name: 'Recipe to Delete');
        await mockDbHelper.insertRecipe(recipe);

        // User A reads recipe for editing
        final userAVersion = await mockDbHelper.getRecipe(recipe.id);
        expect(userAVersion, isNotNull);

        // User B deletes the recipe
        await mockDbHelper.deleteRecipe(recipe.id);

        // User A tries to update the deleted recipe
        final userAUpdate = Recipe(
          id: recipe.id,
          name: 'Updated Name',
          rating: 5,
          difficulty: recipe.difficulty,
          desiredFrequency: recipe.desiredFrequency,
          createdAt: recipe.createdAt,
          prepTimeMinutes: recipe.prepTimeMinutes,
          cookTimeMinutes: recipe.cookTimeMinutes,
        );

        final updateResult = await mockDbHelper.updateRecipe(userAUpdate);

        // Update should return 0 (no rows affected)
        expect(updateResult, equals(0),
            reason: 'Updating deleted recipe should return 0');

        // Recipe should still be deleted
        final finalRecipe = await mockDbHelper.getRecipe(recipe.id);
        expect(finalRecipe, isNull,
            reason: 'Recipe should remain deleted after failed update');
      });

      test('multiple concurrent updates preserve data integrity', () async {
        // Initial recipe
        final recipe = createRecipe(name: 'Concurrent Test', rating: 3);
        await mockDbHelper.insertRecipe(recipe);

        // Simulate 3 concurrent updates
        final update1 = Recipe(
          id: recipe.id,
          name: 'Update 1',
          rating: 4,
          difficulty: recipe.difficulty,
          desiredFrequency: recipe.desiredFrequency,
          createdAt: recipe.createdAt,
          prepTimeMinutes: recipe.prepTimeMinutes,
          cookTimeMinutes: recipe.cookTimeMinutes,
        );
        await mockDbHelper.updateRecipe(update1);

        final update2 = Recipe(
          id: recipe.id,
          name: 'Update 2',
          rating: 5,
          difficulty: recipe.difficulty,
          desiredFrequency: recipe.desiredFrequency,
          createdAt: recipe.createdAt,
          prepTimeMinutes: recipe.prepTimeMinutes,
          cookTimeMinutes: recipe.cookTimeMinutes,
        );
        await mockDbHelper.updateRecipe(update2);

        final update3 = Recipe(
          id: recipe.id,
          name: 'Update 3',
          rating: 2,
          difficulty: recipe.difficulty,
          desiredFrequency: recipe.desiredFrequency,
          createdAt: recipe.createdAt,
          prepTimeMinutes: recipe.prepTimeMinutes,
          cookTimeMinutes: recipe.cookTimeMinutes,
        );
        await mockDbHelper.updateRecipe(update3);

        // Final state should be consistent (last write)
        final finalRecipe = await mockDbHelper.getRecipe(recipe.id);
        expect(finalRecipe, isNotNull,
            reason: 'Recipe should exist after concurrent updates');
        expect(finalRecipe?.name, equals('Update 3'));
        expect(finalRecipe?.rating, equals(2));

        // Verify only one recipe exists (no duplicates)
        final allRecipes = await mockDbHelper.getAllRecipes();
        expect(allRecipes.length, equals(1),
            reason: 'Concurrent updates should not create duplicates');
      });
    });

    group('Concurrent Meal Modifications', () {
      test('meal updated while being viewed elsewhere', () async {
        // Create recipe and meal
        final recipe = createRecipe(name: 'Test Recipe');
        await mockDbHelper.insertRecipe(recipe);

        final meal = createMeal(
          recipeId: recipe.id,
          cookedAt: DateTime(2024, 1, 1),
          servings: 2,
        );
        await mockDbHelper.insertMeal(meal);

        // User A reads meal
        final userAVersion = await mockDbHelper.getMeal(meal.id);
        expect(userAVersion, isNotNull);

        // User B updates meal
        final userBUpdate = Meal(
          id: meal.id,
          recipeId: meal.recipeId,
          cookedAt: meal.cookedAt,
          servings: 4,
          wasSuccessful: meal.wasSuccessful,
        );
        await mockDbHelper.updateMeal(userBUpdate);

        // User A's version is now stale
        expect(userAVersion?.servings, equals(2),
            reason: 'User A has stale data');

        // Verify current data
        final currentMeal = await mockDbHelper.getMeal(meal.id);
        expect(currentMeal?.servings, equals(4),
            reason: 'Database should have User B update');
      });

      test('meal deleted while being edited', () async {
        // Create recipe and meal
        final recipe = createRecipe(name: 'Test Recipe');
        await mockDbHelper.insertRecipe(recipe);

        final meal = createMeal(
          recipeId: recipe.id,
          cookedAt: DateTime.now(),
        );
        await mockDbHelper.insertMeal(meal);

        // User A reads meal for editing
        final userAVersion = await mockDbHelper.getMeal(meal.id);
        expect(userAVersion, isNotNull);

        // User B deletes the meal
        await mockDbHelper.deleteMeal(meal.id);

        // User A tries to update - should throw exception
        expect(
          () async => await mockDbHelper.updateMeal(Meal(
            id: meal.id,
            recipeId: meal.recipeId,
            cookedAt: meal.cookedAt,
            servings: 10,
            wasSuccessful: true,
          )),
          throwsException,
          reason: 'Updating deleted meal should throw exception',
        );
      });
    });

    group('Concurrent Meal Planning Conflicts', () {
      test('meal planned in slot already occupied', () async {
        // Create a meal plan
        final weekStart = DateTime(2024, 1, 1);
        final now = DateTime.now();
        final mealPlan = MealPlan(
          id: IdGenerator.generateId(),
          weekStartDate: weekStart,
          createdAt: now,
          modifiedAt: now,
          items: [],
        );
        await mockDbHelper.insertMealPlan(mealPlan);

        // Create two recipes
        final recipe1 = createRecipe(name: 'Recipe 1');
        final recipe2 = createRecipe(name: 'Recipe 2');
        await mockDbHelper.insertRecipe(recipe1);
        await mockDbHelper.insertRecipe(recipe2);

        // User A plans recipe1 for Monday lunch
        final plannedDate = DateTime(2024, 1, 1);
        final item1 = MealPlanItem(
          id: IdGenerator.generateId(),
          mealPlanId: mealPlan.id,
          plannedDate: MealPlanItem.formatPlannedDate(plannedDate),
          mealType: 'lunch',
        );
        await mockDbHelper.insertMealPlanItem(item1);

        // User B tries to plan recipe2 for same slot
        // (In real app, this would be prevented by UI or business logic)
        final item2 = MealPlanItem(
          id: IdGenerator.generateId(),
          mealPlanId: mealPlan.id,
          plannedDate: MealPlanItem.formatPlannedDate(plannedDate),
          mealType: 'lunch',
        );
        await mockDbHelper.insertMealPlanItem(item2);

        // Both items exist (current behavior - no unique constraint)
        final itemsForDate =
            await mockDbHelper.getMealPlanItemsForDate(plannedDate);

        // In current implementation, multiple items can exist for same slot
        expect(itemsForDate.length, greaterThanOrEqualTo(2),
            reason: 'Current implementation allows multiple items per slot');

        // Note: Real app would need UI logic or unique constraints to prevent this
      });

      test('concurrent meal plan updates maintain consistency', () async {
        // Create meal plan
        final weekStart = DateTime(2024, 1, 1);
        final now = DateTime.now();
        final mealPlan = MealPlan(
          id: IdGenerator.generateId(),
          weekStartDate: weekStart,
          createdAt: now,
          modifiedAt: now,
          items: [],
        );
        await mockDbHelper.insertMealPlan(mealPlan);

        // Add multiple items concurrently
        final item1 = MealPlanItem(
          id: IdGenerator.generateId(),
          mealPlanId: mealPlan.id,
          plannedDate: MealPlanItem.formatPlannedDate(DateTime(2024, 1, 1)),
          mealType: 'lunch',
        );

        final item2 = MealPlanItem(
          id: IdGenerator.generateId(),
          mealPlanId: mealPlan.id,
          plannedDate: MealPlanItem.formatPlannedDate(DateTime(2024, 1, 1)),
          mealType: 'dinner',
        );

        await mockDbHelper.insertMealPlanItem(item1);
        await mockDbHelper.insertMealPlanItem(item2);

        // Verify both items are in the plan
        final updatedPlan = await mockDbHelper.getMealPlan(mealPlan.id);
        expect(updatedPlan?.items.length, equals(2),
            reason: 'Both items should be added to meal plan');
      });

      test('deleting meal plan while items are being added', () async {
        // Create meal plan
        final weekStart = DateTime(2024, 1, 1);
        final now = DateTime.now();
        final mealPlan = MealPlan(
          id: IdGenerator.generateId(),
          weekStartDate: weekStart,
          createdAt: now,
          modifiedAt: now,
          items: [],
        );
        await mockDbHelper.insertMealPlan(mealPlan);

        // User A adds an item
        final item1 = MealPlanItem(
          id: IdGenerator.generateId(),
          mealPlanId: mealPlan.id,
          plannedDate: MealPlanItem.formatPlannedDate(DateTime(2024, 1, 1)),
          mealType: 'lunch',
        );
        await mockDbHelper.insertMealPlanItem(item1);

        // User B deletes the meal plan
        await mockDbHelper.deleteMealPlan(mealPlan.id);

        // Verify meal plan is deleted
        final deletedPlan = await mockDbHelper.getMealPlan(mealPlan.id);
        expect(deletedPlan, isNull,
            reason: 'Meal plan should be deleted');

        // Item might be orphaned (depending on cascade delete implementation)
        // This tests current behavior - in production would need proper cascade
      });
    });

    group('Concurrent Ingredient Modifications', () {
      test('ingredient updated while being added to recipe', () async {
        // Create ingredient
        final ingredient = Ingredient(
          id: IdGenerator.generateId(),
          name: 'Original Name',
          category: IngredientCategory.vegetable,
          unit: MeasurementUnit.gram,
        );
        await mockDbHelper.insertIngredient(ingredient);

        // Create recipe
        final recipe = createRecipe(name: 'Test Recipe');
        await mockDbHelper.insertRecipe(recipe);

        // User A reads ingredient to add to recipe
        final userAVersion =
            (await mockDbHelper.getAllIngredients())
                .firstWhere((i) => i.id == ingredient.id);
        expect(userAVersion.name, equals('Original Name'));

        // User B updates ingredient
        final updatedIngredient = Ingredient(
          id: ingredient.id,
          name: 'Updated Name',
          category: IngredientCategory.vegetable,
          unit: MeasurementUnit.gram,
        );
        await mockDbHelper.updateIngredient(updatedIngredient);

        // User A's reference is now stale but ingredient ID is still valid
        expect(userAVersion.name, equals('Original Name'),
            reason: 'User A has stale ingredient name');

        // Verify current ingredient state
        final currentIngredient =
            (await mockDbHelper.getAllIngredients())
                .firstWhere((i) => i.id == ingredient.id);
        expect(currentIngredient.name, equals('Updated Name'),
            reason: 'Ingredient should be updated in database');

        // Adding to recipe would use stale data but ingredient ID remains valid
      });

      test('ingredient deleted while being added to another recipe', () async {
        // Create ingredient
        final ingredient = Ingredient(
          id: IdGenerator.generateId(),
          name: 'Test Ingredient',
          category: IngredientCategory.protein,
          unit: MeasurementUnit.gram,
          proteinType: ProteinType.chicken,
        );
        await mockDbHelper.insertIngredient(ingredient);

        // User A has ingredient reference
        final ingredientId = ingredient.id;

        // User B deletes ingredient
        await mockDbHelper.deleteIngredient(ingredientId);

        // Verify ingredient is deleted
        final ingredients = await mockDbHelper.getAllIngredients();
        expect(ingredients.any((i) => i.id == ingredientId), isFalse,
            reason: 'Ingredient should be deleted');

        // If User A tries to use it, they'd reference deleted ingredient
        // Real app would need validation when adding ingredient to recipe
      });

      test('concurrent ingredient updates - last write wins', () async {
        // Create ingredient
        final ingredient = Ingredient(
          id: IdGenerator.generateId(),
          name: 'Original',
          category: IngredientCategory.vegetable,
          unit: MeasurementUnit.gram,
        );
        await mockDbHelper.insertIngredient(ingredient);

        // User A updates
        final userAUpdate = Ingredient(
          id: ingredient.id,
          name: 'User A Update',
          category: IngredientCategory.vegetable,
          unit: MeasurementUnit.gram,
        );
        await mockDbHelper.updateIngredient(userAUpdate);

        // User B updates (based on original)
        final userBUpdate = Ingredient(
          id: ingredient.id,
          name: 'User B Update',
          category: IngredientCategory.fruit,
          unit: MeasurementUnit.piece,
        );
        await mockDbHelper.updateIngredient(userBUpdate);

        // Last write wins
        final finalIngredient =
            (await mockDbHelper.getAllIngredients())
                .firstWhere((i) => i.id == ingredient.id);
        expect(finalIngredient.name, equals('User B Update'));
        expect(finalIngredient.category, equals(IngredientCategory.fruit));
      });
    });

    group('Conflict Detection & Recovery', () {
      test('detecting stale data through version comparison', () async {
        // Create recipe
        final recipe = createRecipe(name: 'Versioned Recipe', rating: 3);
        await mockDbHelper.insertRecipe(recipe);

        // User A reads recipe (version 1)
        await mockDbHelper.getRecipe(recipe.id);
        final userATimestamp = DateTime.now();

        // Simulate time passing
        await Future.delayed(const Duration(milliseconds: 10));

        // User B updates recipe (version 2)
        final userBUpdate = Recipe(
          id: recipe.id,
          name: 'User B Update',
          rating: 5,
          difficulty: recipe.difficulty,
          desiredFrequency: recipe.desiredFrequency,
          createdAt: recipe.createdAt,
          prepTimeMinutes: recipe.prepTimeMinutes,
          cookTimeMinutes: recipe.cookTimeMinutes,
        );
        await mockDbHelper.updateRecipe(userBUpdate);
        final userBTimestamp = DateTime.now();

        // User A tries to save (would detect staleness in real app)
        // Current implementation: last write wins
        final userAUpdate = Recipe(
          id: recipe.id,
          name: 'User A Update',
          rating: 4,
          difficulty: recipe.difficulty,
          desiredFrequency: recipe.desiredFrequency,
          createdAt: recipe.createdAt,
          prepTimeMinutes: recipe.prepTimeMinutes,
          cookTimeMinutes: recipe.cookTimeMinutes,
        );
        await mockDbHelper.updateRecipe(userAUpdate);

        // In optimistic locking, this would fail
        // Current behavior: last write wins (User A overwrites User B)
        final finalRecipe = await mockDbHelper.getRecipe(recipe.id);
        expect(finalRecipe?.name, equals('User A Update'),
            reason: 'Last write wins (no optimistic locking)');

        // Timestamps show User B wrote first, then User A
        expect(userBTimestamp.isAfter(userATimestamp), isTrue);
      });

      test('recovery after detecting conflict - reload and retry', () async {
        // Create recipe
        final recipe = createRecipe(name: 'Conflict Recipe', rating: 3);
        await mockDbHelper.insertRecipe(recipe);

        // User A reads
        await mockDbHelper.getRecipe(recipe.id);

        // User B updates
        final userBUpdate = Recipe(
          id: recipe.id,
          name: 'User B Update',
          rating: 5,
          difficulty: recipe.difficulty,
          desiredFrequency: recipe.desiredFrequency,
          createdAt: recipe.createdAt,
          prepTimeMinutes: recipe.prepTimeMinutes,
          cookTimeMinutes: recipe.cookTimeMinutes,
        );
        await mockDbHelper.updateRecipe(userBUpdate);

        // User A detects conflict (simulated), reloads current version
        final currentVersion = await mockDbHelper.getRecipe(recipe.id);
        expect(currentVersion?.name, equals('User B Update'),
            reason: 'User A should see User B changes');

        // User A retries with current data
        final userARetry = Recipe(
          id: recipe.id,
          name: 'User A Retry',
          rating: currentVersion!.rating, // Use current rating
          difficulty: currentVersion.difficulty,
          desiredFrequency: currentVersion.desiredFrequency,
          createdAt: currentVersion.createdAt,
          prepTimeMinutes: currentVersion.prepTimeMinutes,
          cookTimeMinutes: currentVersion.cookTimeMinutes,
        );
        await mockDbHelper.updateRecipe(userARetry);

        // Retry succeeds
        final finalRecipe = await mockDbHelper.getRecipe(recipe.id);
        expect(finalRecipe?.name, equals('User A Retry'));
        expect(finalRecipe?.rating, equals(5),
            reason: 'User A preserved User B rating in retry');
      });

      test('handling deleted entity during concurrent operation', () async {
        // Create recipe
        final recipe = createRecipe(name: 'To Be Deleted');
        await mockDbHelper.insertRecipe(recipe);

        // User A reads recipe
        final userARecipe = await mockDbHelper.getRecipe(recipe.id);
        expect(userARecipe, isNotNull);

        // User B deletes recipe
        await mockDbHelper.deleteRecipe(recipe.id);

        // User A tries to update - should fail gracefully
        final updateResult = await mockDbHelper.updateRecipe(Recipe(
          id: recipe.id,
          name: 'User A Update',
          rating: 5,
          difficulty: recipe.difficulty,
          desiredFrequency: recipe.desiredFrequency,
          createdAt: recipe.createdAt,
          prepTimeMinutes: recipe.prepTimeMinutes,
          cookTimeMinutes: recipe.cookTimeMinutes,
        ));

        // Update returns 0 (no rows affected)
        expect(updateResult, equals(0),
            reason: 'Update should fail for deleted entity');

        // User A can check and handle the error
        if (updateResult == 0) {
          // Reload to verify deletion
          final reloadedRecipe = await mockDbHelper.getRecipe(recipe.id);
          expect(reloadedRecipe, isNull,
              reason: 'Confirm recipe was deleted');
        }
      });

      test('concurrent modifications with data consistency checks', () async {
        // Create recipe
        final recipe = createRecipe(name: 'Consistency Test', rating: 3);
        await mockDbHelper.insertRecipe(recipe);

        // Multiple sequential updates
        for (int i = 0; i < 5; i++) {
          final update = Recipe(
            id: recipe.id,
            name: 'Update $i',
            rating: i,
            difficulty: recipe.difficulty,
            desiredFrequency: recipe.desiredFrequency,
            createdAt: recipe.createdAt,
            prepTimeMinutes: recipe.prepTimeMinutes,
            cookTimeMinutes: recipe.cookTimeMinutes,
          );
          await mockDbHelper.updateRecipe(update);

          // Verify consistency after each update
          final currentRecipe = await mockDbHelper.getRecipe(recipe.id);
          expect(currentRecipe, isNotNull,
              reason: 'Recipe should exist after each update');
          expect(currentRecipe?.name, equals('Update $i'),
              reason: 'Each update should be persisted correctly');
        }

        // Final verification
        final finalRecipe = await mockDbHelper.getRecipe(recipe.id);
        expect(finalRecipe?.name, equals('Update 4'));
        expect(finalRecipe?.rating, equals(4));

        // No duplicates created
        final allRecipes = await mockDbHelper.getAllRecipes();
        expect(allRecipes.where((r) => r.id == recipe.id).length, equals(1),
            reason: 'Only one recipe should exist');
      });
    });

    group('Last-Write-Wins Behavior', () {
      test('last write wins with complete record replacement', () async {
        // Create recipe with all fields populated
        final recipe = createRecipe(
          name: 'Original',
          rating: 3,
          difficulty: 2,
        );
        await mockDbHelper.insertRecipe(recipe);

        // First write
        final write1 = Recipe(
          id: recipe.id,
          name: 'Write 1',
          rating: 4,
          difficulty: 3,
          desiredFrequency: recipe.desiredFrequency,
          createdAt: recipe.createdAt,
          prepTimeMinutes: 30,
          cookTimeMinutes: 50,
        );
        await mockDbHelper.updateRecipe(write1);

        // Second write (last)
        final write2 = Recipe(
          id: recipe.id,
          name: 'Write 2',
          rating: 5,
          difficulty: 1,
          desiredFrequency: recipe.desiredFrequency,
          createdAt: recipe.createdAt,
          prepTimeMinutes: 10,
          cookTimeMinutes: 20,
        );
        await mockDbHelper.updateRecipe(write2);

        // Verify last write is present
        final finalRecipe = await mockDbHelper.getRecipe(recipe.id);
        expect(finalRecipe?.name, equals('Write 2'));
        expect(finalRecipe?.rating, equals(5));
        expect(finalRecipe?.difficulty, equals(1));
        expect(finalRecipe?.prepTimeMinutes, equals(10));
        expect(finalRecipe?.cookTimeMinutes, equals(20));
      });

      test('last write wins even with partial data changes', () async {
        // Initial state
        final recipe = createRecipe(
          name: 'Original',
          rating: 3,
          difficulty: 3,
        );
        await mockDbHelper.insertRecipe(recipe);

        // Update 1: Change only name
        final update1 = Recipe(
          id: recipe.id,
          name: 'New Name',
          rating: recipe.rating,
          difficulty: recipe.difficulty,
          desiredFrequency: recipe.desiredFrequency,
          createdAt: recipe.createdAt,
          prepTimeMinutes: recipe.prepTimeMinutes,
          cookTimeMinutes: recipe.cookTimeMinutes,
        );
        await mockDbHelper.updateRecipe(update1);

        // Update 2: Change only rating (based on original)
        final update2 = Recipe(
          id: recipe.id,
          name: recipe.name, // Original name, not 'New Name'
          rating: 5,
          difficulty: recipe.difficulty,
          desiredFrequency: recipe.desiredFrequency,
          createdAt: recipe.createdAt,
          prepTimeMinutes: recipe.prepTimeMinutes,
          cookTimeMinutes: recipe.cookTimeMinutes,
        );
        await mockDbHelper.updateRecipe(update2);

        // Last write wins - name change from update1 is lost
        final finalRecipe = await mockDbHelper.getRecipe(recipe.id);
        expect(finalRecipe?.name, equals('Original'),
            reason: 'Update2 overwrote update1 name change');
        expect(finalRecipe?.rating, equals(5),
            reason: 'Update2 rating is preserved');
      });
    });
  });
}
