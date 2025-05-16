// test/core/services/recommendation_factors/protein_rotation_factor_integration_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/core/services/recommendation_factors/protein_rotation_factor.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/meal.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/models/protein_type.dart';

import '../../../mocks/mock_database_helper.dart';

void main() {
  group('ProteinRotationFactor', () {
    late MockDatabaseHelper mockDbHelper;
    late ProteinRotationFactor proteinFactor;

    setUp(() {
      // Create a fresh mock database for each test
      mockDbHelper = MockDatabaseHelper();
      proteinFactor = ProteinRotationFactor();
    });

    tearDown(() {
      // Clean up after each test
      mockDbHelper.resetAllData();
    });

    test('gives lower scores to proteins used in recent meals', () async {
      final now = DateTime.now();

      // Create test recipes
      final beefRecipe = Recipe(
        id: 'beef-recipe-id',
        name: 'Beef Stew',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
      );

      final chickenRecipe = Recipe(
        id: 'chicken-recipe-id',
        name: 'Chicken Curry',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
      );

      final fishRecipe = Recipe(
        id: 'fish-recipe-id',
        name: 'Salmon Fillet',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
      );

      // Add recipes to the mock database
      await mockDbHelper.insertRecipe(beefRecipe);
      await mockDbHelper.insertRecipe(chickenRecipe);
      await mockDbHelper.insertRecipe(fishRecipe);

      // Set up protein types for test recipes
      mockDbHelper.recipeProteinTypes = {
        'beef-recipe-id': [ProteinType.beef],
        'chicken-recipe-id': [ProteinType.chicken],
        'fish-recipe-id': [ProteinType.fish]
      };

      // Create a recent meal with beef (1 day ago)
      final oneDayAgo = now.subtract(const Duration(days: 1));
      final beefMeal = Meal(
        id: 'beef-meal-id',
        recipeId: 'beef-recipe-id',
        cookedAt: oneDayAgo,
        servings: 2,
      );

      await mockDbHelper.insertMeal(beefMeal);

      // Create test context manually with the data needed by the factor
      final testContext = {
        'proteinTypes': {
          'beef-recipe-id': [ProteinType.beef],
          'chicken-recipe-id': [ProteinType.chicken],
          'fish-recipe-id': [ProteinType.fish]
        },
        'recentMeals': [
          {
            'recipe': beefRecipe,
            'cookedAt': oneDayAgo,
          }
        ]
      };

      // Calculate scores directly using the factor
      final beefScore =
          await proteinFactor.calculateScore(beefRecipe, testContext);
      final chickenScore =
          await proteinFactor.calculateScore(chickenRecipe, testContext);
      final fishScore =
          await proteinFactor.calculateScore(fishRecipe, testContext);

      // Since beef was used recently, it should have a lower score
      expect(beefScore < chickenScore, isTrue,
          reason:
              "Beef should have lower protein score than chicken since it was used recently");
      expect(beefScore < fishScore, isTrue,
          reason:
              "Beef should have lower protein score than fish since it was used recently");

      // Chicken and fish weren't used recently, so should have similar scores
      expect(chickenScore, equals(fishScore),
          reason: "Chicken and fish should have equal protein scores");
    });
    test('applies graduated penalties based on how recently proteins were used',
        () async {
      final now = DateTime.now();

      // Create one test recipe with beef
      final beefRecipe = Recipe(
        id: 'beef-recipe-id',
        name: 'Beef Stew',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
      );

      // Set up protein type for beef recipe
      mockDbHelper.recipeProteinTypes = {
        'beef-recipe-id': [ProteinType.beef],
      };

      // Create an array of contexts, each with beef used a different number of days ago
      final contexts = <Map<String, dynamic>>[];
      final mealDates = <DateTime>[];
      final expectedScores = <double>[];

      // Set up expectations based on penalty table in ProteinRotationFactor:
      // 1 day ago: 100% penalty -> score of 0
      // 2 days ago: 75% penalty -> score of 25
      // 3 days ago: 50% penalty -> score of 50
      // 4 days ago: 25% penalty -> score of 75
      // 5+ days ago: 0% penalty -> score of 100

      // Day 1 (yesterday) - 100% penalty
      mealDates.add(now.subtract(const Duration(days: 1)));
      expectedScores.add(0.0); // 100% penalty = 0.0 score

      // Day 2 - 75% penalty
      mealDates.add(now.subtract(const Duration(days: 2)));
      expectedScores.add(25.0); // 75% penalty = 25.0 score

      // Day 3 - 50% penalty
      mealDates.add(now.subtract(const Duration(days: 3)));
      expectedScores.add(50.0); // 50% penalty = 50.0 score

      // Day 4 - 25% penalty
      mealDates.add(now.subtract(const Duration(days: 4)));
      expectedScores.add(75.0); // 25% penalty = 75.0 score

      // Day 5 - no penalty
      mealDates.add(now.subtract(const Duration(days: 5)));
      expectedScores.add(100.0); // 0% penalty = 100.0 score

      // Create contexts for each day
      for (var i = 0; i < mealDates.length; i++) {
        contexts.add({
          'proteinTypes': {
            'beef-recipe-id': [ProteinType.beef],
          },
          'recentMeals': [
            {
              'recipe': beefRecipe,
              'cookedAt': mealDates[i],
            }
          ]
        });
      }

      // Create the factor
      final proteinFactor = ProteinRotationFactor();

      // Calculate and verify scores for each scenario
      for (var i = 0; i < contexts.length; i++) {
        final score =
            await proteinFactor.calculateScore(beefRecipe, contexts[i]);
        expect(score, closeTo(expectedScores[i], 0.1),
            reason:
                "Beef used ${i + 1} days ago should have a score of ${expectedScores[i]}");
      }

      // Verify the trend: scores should increase as days ago increases
      final allScores = <double>[];
      for (var i = 0; i < contexts.length; i++) {
        allScores
            .add(await proteinFactor.calculateScore(beefRecipe, contexts[i]));
      }

      for (var i = 0; i < allScores.length - 1; i++) {
        expect(allScores[i] < allScores[i + 1], isTrue,
            reason:
                "Score for ${i + 1} days ago (${allScores[i]}) should be less than score for ${i + 2} days ago (${allScores[i + 1]})");
      }
    });
  });
}
