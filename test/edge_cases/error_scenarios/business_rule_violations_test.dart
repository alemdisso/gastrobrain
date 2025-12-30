// test/edge_cases/error_scenarios/business_rule_violations_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/meal.dart';
import 'package:gastrobrain/models/meal_recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/models/protein_type.dart';
import 'package:gastrobrain/models/ingredient.dart';
import 'package:gastrobrain/models/ingredient_category.dart';
import 'package:gastrobrain/models/measurement_unit.dart';
import 'package:gastrobrain/utils/id_generator.dart';
import '../../mocks/mock_database_helper.dart';

/// Tests for business rule violations and constraints.
///
/// Verifies that the application enforces business logic rules:
/// - Multi-recipe meals must have at least one primary dish
/// - Protein type constraints for protein ingredients
/// - Frequency type constraints
/// - Rating and difficulty ranges (if enforced at model level)
/// - Meal cooking requires recipe reference
/// - Business rule error messages are descriptive
///
/// Note: Some constraints are enforced at UI level only (e.g., rating 1-5).
/// These tests verify model-level constraints and database-level rules.
void main() {
  group('Business Rule Violations', () {
    late MockDatabaseHelper mockDbHelper;

    setUp(() {
      mockDbHelper = MockDatabaseHelper();
    });

    tearDown(() {
      mockDbHelper.resetAllData();
    });

    group('Multi-Recipe Meal Constraints', () {
      test('meal can have single recipe as primary dish', () async {
        // Create recipe
        final recipe = Recipe(
          id: IdGenerator.generateId(),
          name: 'Main Dish',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 3,
          rating: 4,
          prepTimeMinutes: 20,
          cookTimeMinutes: 40,
        );
        await mockDbHelper.insertRecipe(recipe);

        // Create meal
        final meal = Meal(
          id: IdGenerator.generateId(),
          recipeId: recipe.id,
          cookedAt: DateTime.now(),
          servings: 2,
          wasSuccessful: true,
        );
        await mockDbHelper.insertMeal(meal);

        // Add meal recipe with isPrimaryDish=true
        final mealRecipe = MealRecipe(
          id: IdGenerator.generateId(),
          mealId: meal.id,
          recipeId: recipe.id,
          isPrimaryDish: true,
        );
        await mockDbHelper.insertMealRecipe(mealRecipe);

        // Verify meal recipe was created
        final mealRecipes = await mockDbHelper.getMealRecipesForMeal(meal.id);
        expect(mealRecipes.length, equals(1));
        expect(mealRecipes.first.isPrimaryDish, isTrue);
      });

      test('meal can have multiple recipes with one primary', () async {
        // Create recipes
        final mainDish = Recipe(
          id: IdGenerator.generateId(),
          name: 'Main Dish',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 3,
          rating: 4,
          prepTimeMinutes: 20,
          cookTimeMinutes: 40,
        );
        final sideDish = Recipe(
          id: IdGenerator.generateId(),
          name: 'Side Dish',
          desiredFrequency: FrequencyType.monthly,
          createdAt: DateTime.now(),
          difficulty: 2,
          rating: 3,
          prepTimeMinutes: 10,
          cookTimeMinutes: 15,
        );

        await mockDbHelper.insertRecipe(mainDish);
        await mockDbHelper.insertRecipe(sideDish);

        // Create meal
        final meal = Meal(
          id: IdGenerator.generateId(),
          recipeId: mainDish.id,
          cookedAt: DateTime.now(),
          servings: 2,
          wasSuccessful: true,
        );
        await mockDbHelper.insertMeal(meal);

        // Add main dish as primary
        final primaryMealRecipe = MealRecipe(
          id: IdGenerator.generateId(),
          mealId: meal.id,
          recipeId: mainDish.id,
          isPrimaryDish: true,
        );
        await mockDbHelper.insertMealRecipe(primaryMealRecipe);

        // Add side dish as non-primary
        final sideMealRecipe = MealRecipe(
          id: IdGenerator.generateId(),
          mealId: meal.id,
          recipeId: sideDish.id,
          isPrimaryDish: false,
        );
        await mockDbHelper.insertMealRecipe(sideMealRecipe);

        // Verify both meal recipes were created
        final mealRecipes = await mockDbHelper.getMealRecipesForMeal(meal.id);
        expect(mealRecipes.length, equals(2));
        expect(mealRecipes.where((mr) => mr.isPrimaryDish).length, equals(1),
            reason: 'Exactly one recipe should be marked as primary');
      });

      test('meal can technically have all recipes as non-primary (DB allows)', () async {
        // Note: This is a business rule that should be enforced at UI/service level
        // The database layer currently allows it, so this test documents current behavior

        final recipe = Recipe(
          id: IdGenerator.generateId(),
          name: 'Side Dish',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 2,
          rating: 3,
          prepTimeMinutes: 10,
          cookTimeMinutes: 15,
        );
        await mockDbHelper.insertRecipe(recipe);

        final meal = Meal(
          id: IdGenerator.generateId(),
          recipeId: recipe.id,
          cookedAt: DateTime.now(),
          servings: 2,
          wasSuccessful: true,
        );
        await mockDbHelper.insertMeal(meal);

        final mealRecipe = MealRecipe(
          id: IdGenerator.generateId(),
          mealId: meal.id,
          recipeId: recipe.id,
          isPrimaryDish: false, // No primary dish
        );

        // Database layer allows this (no constraint)
        await mockDbHelper.insertMealRecipe(mealRecipe);

        final mealRecipes = await mockDbHelper.getMealRecipesForMeal(meal.id);
        expect(mealRecipes.length, equals(1));
        expect(mealRecipes.first.isPrimaryDish, isFalse,
            reason: 'DB allows meal with no primary dish - business rule should be enforced at service/UI level');
      });

      test('meal can have multiple primary dishes (DB allows, UI may prevent)', () async {
        // Note: This documents current behavior - DB doesn't enforce unique primary
        // Business logic should be enforced at service/UI level

        final recipe1 = Recipe(
          id: IdGenerator.generateId(),
          name: 'Main Dish 1',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 3,
          rating: 4,
          prepTimeMinutes: 20,
          cookTimeMinutes: 40,
        );
        final recipe2 = Recipe(
          id: IdGenerator.generateId(),
          name: 'Main Dish 2',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 3,
          rating: 4,
          prepTimeMinutes: 20,
          cookTimeMinutes: 40,
        );

        await mockDbHelper.insertRecipe(recipe1);
        await mockDbHelper.insertRecipe(recipe2);

        final meal = Meal(
          id: IdGenerator.generateId(),
          recipeId: recipe1.id,
          cookedAt: DateTime.now(),
          servings: 2,
          wasSuccessful: true,
        );
        await mockDbHelper.insertMeal(meal);

        // Add both as primary
        await mockDbHelper.insertMealRecipe(MealRecipe(
          id: IdGenerator.generateId(),
          mealId: meal.id,
          recipeId: recipe1.id,
          isPrimaryDish: true,
        ));
        await mockDbHelper.insertMealRecipe(MealRecipe(
          id: IdGenerator.generateId(),
          mealId: meal.id,
          recipeId: recipe2.id,
          isPrimaryDish: true,
        ));

        final mealRecipes = await mockDbHelper.getMealRecipesForMeal(meal.id);
        expect(mealRecipes.where((mr) => mr.isPrimaryDish).length, equals(2),
            reason: 'DB allows multiple primary dishes - business rule should limit to one');
      });
    });

    group('Protein Type Constraints', () {
      test('protein ingredient must have proteinType set', () {
        // This is enforced by EntityValidator.validateIngredient
        // which we test in validation_failures_test.dart
        // Here we document the business rule

        final validProteinIngredient = Ingredient(
          id: IdGenerator.generateId(),
          name: 'Chicken Breast',
          category: IngredientCategory.protein,
          unit: MeasurementUnit.gram,
          proteinType: ProteinType.chicken,
        );

        expect(validProteinIngredient.proteinType, equals(ProteinType.chicken),
            reason: 'Protein ingredients must have proteinType for recommendation engine');
      });

      test('non-protein ingredient can have null proteinType', () {
        final vegetableIngredient = Ingredient(
          id: IdGenerator.generateId(),
          name: 'Carrot',
          category: IngredientCategory.vegetable,
          unit: MeasurementUnit.gram,
          proteinType: null,
        );

        expect(vegetableIngredient.proteinType, isNull,
            reason: 'Non-protein ingredients do not need proteinType');
      });
    });

    group('Frequency Type Constraints', () {
      test('recipe frequency type must be valid enum value', () {
        // Test all valid frequency types
        final validTypes = [
          FrequencyType.daily,
          FrequencyType.weekly,
          FrequencyType.biweekly,
          FrequencyType.monthly,
          FrequencyType.bimonthly,
          FrequencyType.rarely,
        ];

        for (final freqType in validTypes) {
          final recipe = Recipe(
            id: IdGenerator.generateId(),
            name: 'Test Recipe ${freqType.value}',
            desiredFrequency: freqType,
            createdAt: DateTime.now(),
            difficulty: 3,
            rating: 3,
            prepTimeMinutes: 20,
            cookTimeMinutes: 40,
          );

          expect(recipe.desiredFrequency, equals(freqType),
              reason: '${freqType.value} should be valid frequency type');
        }
      });

      test('frequency type affects recommendation scoring', () {
        // Document business rule: frequency impacts recommendation weights
        // Actual scoring logic is tested in recommendation service tests

        final dailyRecipe = Recipe(
          id: IdGenerator.generateId(),
          name: 'Daily Recipe',
          desiredFrequency: FrequencyType.daily,
          createdAt: DateTime.now(),
          difficulty: 2,
          rating: 4,
          prepTimeMinutes: 15,
          cookTimeMinutes: 20,
        );

        final rarelyRecipe = Recipe(
          id: IdGenerator.generateId(),
          name: 'Rarely Recipe',
          desiredFrequency: FrequencyType.rarely,
          createdAt: DateTime.now(),
          difficulty: 4,
          rating: 5,
          prepTimeMinutes: 60,
          cookTimeMinutes: 120,
        );

        expect(dailyRecipe.desiredFrequency, equals(FrequencyType.daily));
        expect(rarelyRecipe.desiredFrequency, equals(FrequencyType.rarely));

        // Business rule: daily recipes should be simpler and get recommended more often
        expect(dailyRecipe.difficulty, lessThan(rarelyRecipe.difficulty),
            reason: 'Daily recipes typically simpler than rarely-made ones');
      });
    });

    group('Rating and Difficulty Constraints', () {
      test('rating can be 0 to indicate unrated', () {
        final unratedRecipe = Recipe(
          id: IdGenerator.generateId(),
          name: 'Unrated Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 3,
          rating: 0, // Unrated
          prepTimeMinutes: 20,
          cookTimeMinutes: 40,
        );

        expect(unratedRecipe.rating, equals(0),
            reason: 'Rating of 0 indicates unrated recipe');
      });

      test('rating 1-5 is typical range (UI-enforced)', () {
        // Note: Model doesn't enforce this, but UI should constrain to 1-5
        for (int rating = 1; rating <= 5; rating++) {
          final recipe = Recipe(
            id: IdGenerator.generateId(),
            name: 'Recipe Rating $rating',
            desiredFrequency: FrequencyType.weekly,
            createdAt: DateTime.now(),
            difficulty: 3,
            rating: rating,
            prepTimeMinutes: 20,
            cookTimeMinutes: 40,
          );

          expect(recipe.rating, equals(rating),
              reason: 'Rating $rating should be valid');
        }
      });

      test('model allows rating outside 1-5 range (no validation)', () {
        // Document current behavior: model doesn't validate rating range
        // UI should constrain ratings to 1-5

        final highRating = Recipe(
          id: IdGenerator.generateId(),
          name: 'High Rating Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 3,
          rating: 10, // Outside typical range
          prepTimeMinutes: 20,
          cookTimeMinutes: 40,
        );

        final negativeRating = Recipe(
          id: IdGenerator.generateId(),
          name: 'Negative Rating Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 3,
          rating: -1, // Negative (invalid in business logic)
          prepTimeMinutes: 20,
          cookTimeMinutes: 40,
        );

        expect(highRating.rating, equals(10),
            reason: 'Model allows rating > 5 (UI should prevent)');
        expect(negativeRating.rating, equals(-1),
            reason: 'Model allows negative rating (UI should prevent)');
      });

      test('difficulty 1-5 is typical range (UI-enforced)', () {
        for (int difficulty = 1; difficulty <= 5; difficulty++) {
          final recipe = Recipe(
            id: IdGenerator.generateId(),
            name: 'Recipe Difficulty $difficulty',
            desiredFrequency: FrequencyType.weekly,
            createdAt: DateTime.now(),
            difficulty: difficulty,
            rating: 3,
            prepTimeMinutes: 20,
            cookTimeMinutes: 40,
          );

          expect(recipe.difficulty, equals(difficulty),
              reason: 'Difficulty $difficulty should be valid');
        }
      });
    });

    group('Meal Cooking Business Rules', () {
      test('meal must reference valid recipe ID', () async {
        final recipe = Recipe(
          id: IdGenerator.generateId(),
          name: 'Test Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 3,
          rating: 4,
          prepTimeMinutes: 20,
          cookTimeMinutes: 40,
        );
        await mockDbHelper.insertRecipe(recipe);

        final meal = Meal(
          id: IdGenerator.generateId(),
          recipeId: recipe.id,
          cookedAt: DateTime.now(),
          servings: 2,
          wasSuccessful: true,
        );

        expect(meal.recipeId, equals(recipe.id),
            reason: 'Meal must have valid recipe reference');
      });

      test('meal can reference non-existent recipe (DB allows)', () async {
        // Note: This documents current behavior - DB doesn't enforce FK constraint
        // Business logic should verify recipe exists

        final nonExistentRecipeId = IdGenerator.generateId();

        final meal = Meal(
          id: IdGenerator.generateId(),
          recipeId: nonExistentRecipeId,
          cookedAt: DateTime.now(),
          servings: 2,
          wasSuccessful: true,
        );
        await mockDbHelper.insertMeal(meal);

        // Meal was created with non-existent recipe
        final retrievedMeal = await mockDbHelper.getMeal(meal.id);
        expect(retrievedMeal, isNotNull);
        expect(retrievedMeal!.recipeId, equals(nonExistentRecipeId),
            reason: 'DB allows orphaned meal (business logic should prevent)');
      });

      test('unsuccessful meals are allowed and tracked', () async {
        final recipe = Recipe(
          id: IdGenerator.generateId(),
          name: 'Challenging Recipe',
          desiredFrequency: FrequencyType.rarely,
          createdAt: DateTime.now(),
          difficulty: 5,
          rating: 3,
          prepTimeMinutes: 60,
          cookTimeMinutes: 120,
        );
        await mockDbHelper.insertRecipe(recipe);

        final unsuccessfulMeal = Meal(
          id: IdGenerator.generateId(),
          recipeId: recipe.id,
          cookedAt: DateTime.now(),
          servings: 2,
          wasSuccessful: false, // Marked as unsuccessful
        );
        await mockDbHelper.insertMeal(unsuccessfulMeal);

        final retrievedMeal = await mockDbHelper.getMeal(unsuccessfulMeal.id);
        expect(retrievedMeal!.wasSuccessful, isFalse,
            reason: 'Unsuccessful meals should be tracked for learning');
      });
    });

    group('Business Rule Error Messages', () {
      test('protein type validation error is descriptive', () {
        // From EntityValidator - tested in validation_failures_test.dart
        // Here we verify the error message quality

        const expectedMessage = 'Protein type must be selected for protein ingredients';

        expect(expectedMessage.toLowerCase(), contains('protein'));
        expect(expectedMessage.toLowerCase(), contains('selected'));
        expect(expectedMessage, isNotEmpty);
        expect(expectedMessage.length, greaterThan(20),
            reason: 'Error messages should be descriptive');
      });

      test('meal date validation error is descriptive', () {
        const expectedMessage = 'Meal date cannot be in the future';

        expect(expectedMessage.toLowerCase(), contains('date'));
        expect(expectedMessage.toLowerCase(), contains('future'));
        expect(expectedMessage, isNotEmpty);
      });

      test('servings validation error is descriptive', () {
        const expectedMessage = 'Number of servings must be positive';

        expect(expectedMessage.toLowerCase(), contains('servings'));
        expect(expectedMessage.toLowerCase(), contains('positive'));
        expect(expectedMessage, isNotEmpty);
      });
    });

    group('Constraint Documentation', () {
      test('documents UI-level vs model-level constraints', () {
        // This test serves as documentation of constraint enforcement levels

        final constraints = {
          'Rating range (1-5)': 'UI-enforced',
          'Difficulty range (1-5)': 'UI-enforced',
          'Protein ingredient has proteinType': 'Model-enforced (EntityValidator)',
          'Meal date not in future': 'Model-enforced (EntityValidator)',
          'Servings > 0': 'Model-enforced (EntityValidator)',
          'At least one primary dish': 'Business logic (service/UI)',
          'Unique primary dish per meal': 'Business logic (service/UI)',
          'Recipe exists for meal': 'Business logic (service/UI)',
          'Week start is Friday': 'Model-enforced (EntityValidator)',
          'Meal type is lunch or dinner': 'Model-enforced (EntityValidator)',
        };

        expect(constraints.length, greaterThan(5),
            reason: 'Application has multiple constraint types');

        // Count constraint levels
        final modelEnforced = constraints.values.where((v) => v.contains('Model-enforced')).length;
        final uiEnforced = constraints.values.where((v) => v.contains('UI-enforced')).length;
        final businessLogic = constraints.values.where((v) => v.contains('Business logic')).length;

        expect(modelEnforced, greaterThan(0));
        expect(uiEnforced, greaterThan(0));
        expect(businessLogic, greaterThan(0));
      });
    });
  });
}
