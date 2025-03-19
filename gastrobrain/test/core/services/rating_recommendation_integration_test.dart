// test/core/services/rating_recommendation_integration_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/core/services/recommendation_service.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/meal.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/utils/id_generator.dart';

import '../../mocks/mock_database_helper.dart';

void main() {
  group('Rating-based Recipe Recommendations Integration', () {
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

    test('ratings influence recommendation order when other factors are equal',
        () async {
      // Create several recipes with identical properties except for rating
      final now = DateTime.now();

      // High rated recipe (5 stars)
      final highRatedRecipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'High Rated Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 5, // Max rating
      );

      // Medium rated recipe (3 stars)
      final mediumRatedRecipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Medium Rated Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 3, // Medium rating
      );

      // Low rated recipe (1 star)
      final lowRatedRecipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Low Rated Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 1, // Low rating
      );

      // Unrated recipe (0 stars)
      final unratedRecipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Unrated Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 0, // No rating
      );

      // Add all recipes to the mock database
      await mockDbHelper.insertRecipe(highRatedRecipe);
      await mockDbHelper.insertRecipe(mediumRatedRecipe);
      await mockDbHelper.insertRecipe(lowRatedRecipe);
      await mockDbHelper.insertRecipe(unratedRecipe);

      // Set up the recipes to be cooked at the same time in the past
      // This way, the frequency factor should score them all similarly
      final oneWeekAgo = now.subtract(const Duration(days: 7));

      // Create a meal for each recipe with the same cooked date
      for (final recipe in [
        highRatedRecipe,
        mediumRatedRecipe,
        lowRatedRecipe,
        unratedRecipe
      ]) {
        final mealId = IdGenerator.generateId();

        // Create a meal with the recipe directly linked
        await mockDbHelper.insertMeal(
          Meal(
            id: mealId,
            recipeId: recipe.id,
            cookedAt: oneWeekAgo,
            servings: 2,
            notes: 'Test meal',
            wasSuccessful: true,
          ),
        );
      }

      // Verify the mock database populated the last cooked dates correctly
      expect(mockDbHelper.getAllLastCooked(), completion(isNotEmpty));
      expect(mockDbHelper.getAllMealCounts(), completion(isNotEmpty));

      // Get detailed recommendations to analyze scores
      final results = await recommendationService.getDetailedRecommendations();

      // Verify we got recommendations for all recipes
      expect(results.recommendations.length, 4);

      // Extract the rating scores
      final ratingScores = <String, double>{};
      for (final rec in results.recommendations) {
        if (rec.factorScores.containsKey('rating')) {
          ratingScores[rec.recipe.id] = rec.factorScores['rating']!;
        }
      }

      // Verify rating scores match our expectations
      expect(ratingScores[highRatedRecipe.id], equals(100.0)); // 5 stars = 100
      expect(ratingScores[mediumRatedRecipe.id], equals(60.0)); // 3 stars = 60
      expect(ratingScores[lowRatedRecipe.id], equals(20.0)); // 1 star = 20
      expect(ratingScores[unratedRecipe.id],
          equals(50.0)); // 0 stars = 50 (neutral)

      // Since frequency and protein factors should be equal for all recipes,
      // check that the order of recommendations follows rating (highest first)
      expect(results.recommendations[0].recipe.id, equals(highRatedRecipe.id));

      // The order of the remaining recipes depends on how the other factors are weighted
      // but the highly rated recipe should definitely be first
    });

    test('ratings provide moderate influence when frequency is more important',
        () async {
      // Create two recipes, one overdue but poorly rated, one on time but highly rated
      final now = DateTime.now();

      // High rated recipe that was recently cooked (not yet due)
      final highRatedRecipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Recent High Rated Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 5, // Max rating
      );

      // Low rated recipe that is overdue
      final overdueRecipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Overdue Low Rated Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 1, // Low rating
      );

      // Add recipes to the mock database
      await mockDbHelper.insertRecipe(highRatedRecipe);
      await mockDbHelper.insertRecipe(overdueRecipe);

      // Set up last cooked dates - one recipe recent, one overdue
      final recentDate = now.subtract(const Duration(days: 2)); // 2 days ago
      final overdueDate =
          now.subtract(const Duration(days: 14)); // 2 weeks ago (overdue)

      // Create meals with appropriate dates to establish cooking history
      await mockDbHelper.insertMeal(
        Meal(
          id: IdGenerator.generateId(),
          recipeId: highRatedRecipe.id,
          cookedAt: recentDate,
          servings: 2,
          notes: 'Recent meal',
          wasSuccessful: true,
        ),
      );

      await mockDbHelper.insertMeal(
        Meal(
          id: IdGenerator.generateId(),
          recipeId: overdueRecipe.id,
          cookedAt: overdueDate,
          servings: 2,
          notes: 'Overdue meal',
          wasSuccessful: true,
        ),
      );

      // Verify the cooking history was properly set up
      expect(
          await mockDbHelper.getLastCookedDate(highRatedRecipe.id), recentDate);
      expect(
          await mockDbHelper.getLastCookedDate(overdueRecipe.id), overdueDate);

      // Get detailed recommendations
      final results = await recommendationService.getDetailedRecommendations();

      // Verify we got recommendations for both recipes
      expect(results.recommendations.length, 2);

      // Extract the factor scores
      final Map<String, Map<String, double>> factorScores = {};
      for (final rec in results.recommendations) {
        factorScores[rec.recipe.id] = rec.factorScores;
      }

      // Frequency should dominate over rating
      // The overdue recipe should be recommended first despite its low rating

      // High rated recipe recently cooked scores:
      // - Rating: High (100)
      // - Frequency: Low (around 30 since it's only 2/7 of the way to being due)

      // Overdue recipe with low rating scores:
      // - Rating: Low (20)
      // - Frequency: Very high (85+ since it's overdue)

      // Overall, the overdue recipe should be first
      expect(results.recommendations[0].recipe.id, equals(overdueRecipe.id));
      expect(results.recommendations[1].recipe.id, equals(highRatedRecipe.id));

      // Verify frequency scores are following this pattern
      final highRatedFrequencyScore =
          factorScores[highRatedRecipe.id]!['frequency']!;
      final overdueFrequencyScore =
          factorScores[overdueRecipe.id]!['frequency']!;

      expect(highRatedFrequencyScore, lessThan(overdueFrequencyScore));
    });
  });
}
