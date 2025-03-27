// test/core/services/recommendation_protein_rotation_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/core/services/recommendation_service.dart';
import 'package:gastrobrain/core/services/recommendation_factors/protein_rotation_factor.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/meal.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/models/protein_type.dart';
import 'package:gastrobrain/utils/id_generator.dart';

import '../../mocks/mock_database_helper.dart';

void main() {
  group('Protein Rotation in Recommendations', () {
    late MockDatabaseHelper mockDbHelper;
    late RecommendationService recommendationService;

    setUp(() {
      // Create a fresh mock database for each test
      mockDbHelper = MockDatabaseHelper();

      // Create and initialize a recommendation service with our mock
      recommendationService = RecommendationService(
        dbHelper: mockDbHelper,
        registerDefaultFactors: true,
      );
    });

    tearDown(() {
      // Clean up after each test
      mockDbHelper.resetAllData();
    });

    test('recipes with recently used proteins rank lower in recommendations',
        () async {
      // Arrange: Create recipes with different protein types
      final now = DateTime.now();

      // Create recipes with different protein types but otherwise identical properties
      final beefRecipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Beef Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 4, // Same rating for all recipes
      );

      final chickenRecipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Chicken Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 4, // Same rating for all recipes
      );

      final fishRecipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Fish Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 4, // Same rating for all recipes
      );

      // Add recipes to mock database
      await mockDbHelper.insertRecipe(beefRecipe);
      await mockDbHelper.insertRecipe(chickenRecipe);
      await mockDbHelper.insertRecipe(fishRecipe);

      // Set up protein types in the mock database
      mockDbHelper.recipeProteinTypes = {
        beefRecipe.id: [ProteinType.beef],
        chickenRecipe.id: [ProteinType.chicken],
        fishRecipe.id: [ProteinType.fish]
      };
      print('Recipe protein types set up: ${mockDbHelper.recipeProteinTypes}');

      // Create last cooked dates - make all recipes cooked at same time except beef (1 day ago)
      final oneWeekAgo = now.subtract(const Duration(days: 7));
      final oneDayAgo = now.subtract(const Duration(days: 1));

      // Create a meal with beef (recently cooked - 1 day ago)
      final beefMeal = Meal(
        id: IdGenerator.generateId(),
        recipeId: beefRecipe.id,
        cookedAt: oneDayAgo, // Recently cooked
        servings: 2,
        notes: 'Recent beef meal',
        wasSuccessful: true,
      );

      // Create meals for chicken and fish (cooked longer ago - 1 week ago)
      final chickenMeal = Meal(
        id: IdGenerator.generateId(),
        recipeId: chickenRecipe.id,
        cookedAt: oneWeekAgo, // Cooked a week ago
        servings: 2,
        notes: 'Not so recent chicken meal',
        wasSuccessful: true,
      );

      final fishMeal = Meal(
        id: IdGenerator.generateId(),
        recipeId: fishRecipe.id,
        cookedAt: oneWeekAgo, // Cooked a week ago
        servings: 2,
        notes: 'Not so recent fish meal',
        wasSuccessful: true,
      );

      // Insert meals to establish cooking history
      await mockDbHelper.insertMeal(beefMeal);
      await mockDbHelper.insertMeal(chickenMeal);
      await mockDbHelper.insertMeal(fishMeal);

      // Verify the cooking history was properly set up
      final lastCooked = await mockDbHelper.getAllLastCooked();
      expect(lastCooked[beefRecipe.id], oneDayAgo);
      expect(lastCooked[chickenRecipe.id], oneWeekAgo);
      expect(lastCooked[fishRecipe.id], oneWeekAgo);

      mockDbHelper.returnCustomMealsForRecommendations = [
        {
          'meal': beefMeal,
          'recipe': beefRecipe,
          'cookedAt': oneDayAgo,
        },
        {
          'meal': chickenMeal,
          'recipe': chickenRecipe,
          'cookedAt': oneWeekAgo,
        },
        {
          'meal': fishMeal,
          'recipe': fishRecipe,
          'cookedAt': oneWeekAgo,
        }
      ];
// Direct modification of the context the factor will receive
      recommendationService.overrideTestContext = {
        'proteinTypes': mockDbHelper.recipeProteinTypes,
        'recentMeals': [
          {
            'recipe': beefRecipe,
            'cookedAt': oneDayAgo,
          },
          {
            'recipe': chickenRecipe,
            'cookedAt': oneWeekAgo,
          },
          {
            'recipe': fishRecipe,
            'cookedAt': oneWeekAgo,
          }
        ],
        // Add lastCooked data for FrequencyFactor
        'lastCooked': {
          beefRecipe.id: oneDayAgo,
          chickenRecipe.id: oneWeekAgo,
          fishRecipe.id: oneWeekAgo
        },
        // Add mealCounts data as well since it might be required
        'mealCounts': {beefRecipe.id: 1, chickenRecipe.id: 1, fishRecipe.id: 1}
      };
      // Act: Get recommendations
      // final recipes = await _getCandidateRecipes(excludeIds); is returning null
      final recommendations = await recommendationService.getRecommendations();

      // Assert: Beef recipe should rank lower than others due to protein rotation
      expect(recommendations.length, 3,
          reason: "Should return all three recipes");

      // Get the indices of each recipe in the recommendations
      final beefIndex =
          recommendations.indexWhere((r) => r.id == beefRecipe.id);
      final chickenIndex =
          recommendations.indexWhere((r) => r.id == chickenRecipe.id);
      final fishIndex =
          recommendations.indexWhere((r) => r.id == fishRecipe.id);

      // Ensure all recipes were found in recommendations
      expect(beefIndex, isNot(-1),
          reason: "Beef recipe should be in recommendations");
      expect(chickenIndex, isNot(-1),
          reason: "Chicken recipe should be in recommendations");
      expect(fishIndex, isNot(-1),
          reason: "Fish recipe should be in recommendations");

      // Verify beef recipe ranks lower (higher index) than others due to protein rotation
      // Note: lower rank = higher index because list is sorted by score descending
      expect(beefIndex > chickenIndex || beefIndex > fishIndex, isTrue,
          reason:
              'Beef should rank lower than at least one other protein due to recent use');

      // For more detailed verification, get detailed recommendations with scores
      final detailedResults =
          await recommendationService.getDetailedRecommendations();

      // Extract protein rotation scores
      final Map<String, double> proteinScores = {};
      for (final rec in detailedResults.recommendations) {
        if (rec.factorScores.containsKey('protein_rotation')) {
          proteinScores[rec.recipe.id] = rec.factorScores['protein_rotation']!;
        }
      }

      // Verify beef has lower protein rotation score
      expect(proteinScores[beefRecipe.id]! < proteinScores[chickenRecipe.id]!,
          isTrue,
          reason: "Beef should have lower protein score than chicken");
      expect(
          proteinScores[beefRecipe.id]! < proteinScores[fishRecipe.id]!, isTrue,
          reason: "Beef should have lower protein score than fish");
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
        print('Beef protein score with meal from ${i + 1} days ago: $score');
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
