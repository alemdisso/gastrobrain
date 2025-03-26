// test/core/services/recommendation_protein_rotation_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/core/services/recommendation_service.dart';
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
  });
}
