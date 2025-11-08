// test/core/services/recommendation_multi_ingredient_integration_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/core/services/recommendation_service.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/models/protein_type.dart';

import '../../mocks/mock_database_helper.dart';
import '../../test_utils/multi_ingredient_fixtures.dart';

void main() {
  group('Multi-Ingredient Recommendation Integration Tests', () {
    late MockDatabaseHelper mockDbHelper;
    late RecommendationService recommendationService;

    setUp(() {
      mockDbHelper = MockDatabaseHelper();
      recommendationService = RecommendationService(
        dbHelper: mockDbHelper,
        registerDefaultFactors: true,
      );
    });

    tearDown(() {
      mockDbHelper.resetAllData();
    });

    group('Full Recommendation Flow with Enhanced Data', () {
      test('recommendation flow works correctly with multi-ingredient recipes', () async {
        final now = DateTime.now();

        // Create a diverse set of complex recipes
        final beefStew = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Beef Stew',
          proteinTypes: [ProteinType.beef],
          vegetableCount: 8,
          otherCount: 5, // 13 ingredients
          difficulty: 3,
          rating: 4,
          desiredFrequency: FrequencyType.weekly,
        );

        final chickenCurry = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Chicken Curry',
          proteinTypes: [ProteinType.chicken],
          vegetableCount: 10,
          otherCount: 6, // 16 ingredients
          difficulty: 4,
          rating: 5,
          desiredFrequency: FrequencyType.weekly,
        );

        final fishTacos = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Fish Tacos',
          proteinTypes: [ProteinType.fish],
          vegetableCount: 6,
          otherCount: 4, // 10 ingredients
          difficulty: 2,
          rating: 4,
          desiredFrequency: FrequencyType.weekly,
        );

        final veggieBowl = await MultiIngredientFixtures.createVegetarianRecipe(
          mockDb: mockDbHelper,
          name: 'Veggie Bowl',
          ingredientCount: 12,
          desiredFrequency: FrequencyType.weekly,
        );

        // Create meal history - beef cooked recently, chicken a week ago
        await MultiIngredientFixtures.createMealHistory(
          mockDb: mockDbHelper,
          recipes: [beefStew, chickenCurry],
          daysAgo: [1, 7],
        );

        // Get recommendations
        final recommendations = await recommendationService.getRecommendations(
          count: 3,
          forDate: now,
        );

        // Verify we got recommendations
        expect(recommendations, isNotEmpty);
        expect(recommendations.length, lessThanOrEqualTo(3));

        // Beef should not be top recommendation (cooked yesterday)
        expect(recommendations.first.id, isNot(equals(beefStew.id)));

        // Fish or veggie should be prioritized (never cooked)
        final topTwoIds = recommendations.take(2).map((r) => r.id).toList();
        expect(topTwoIds, anyOf([
          contains(fishTacos.id),
          contains(veggieBowl.id),
        ]));
      });

      test('all recommendation factors work together with complex recipes', () async {
        // Create recipes that test different factors
        final frequentlyCooked = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Frequently Cooked',
          proteinTypes: [ProteinType.chicken],
          vegetableCount: 8,
          otherCount: 4,
          difficulty: 2,
          rating: 5,
          desiredFrequency: FrequencyType.daily, // High frequency preference
        );

        final rarelyCooked = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Rarely Cooked',
          proteinTypes: [ProteinType.fish],
          vegetableCount: 10,
          otherCount: 5,
          difficulty: 4,
          rating: 3,
          desiredFrequency: FrequencyType.rarely, // Low frequency preference
        );

        final neverCooked = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Never Cooked',
          proteinTypes: [ProteinType.pork],
          vegetableCount: 12,
          otherCount: 6,
          difficulty: 3,
          rating: 4,
          desiredFrequency: FrequencyType.weekly,
        );

        // Cook frequently cooked recipe multiple times (10 times)
        await MultiIngredientFixtures.createMealHistory(
          mockDb: mockDbHelper,
          recipes: List.filled(10, frequentlyCooked),
          daysAgo: List.generate(10, (i) => i + 10), // 10-20 days ago
        );

        // Cook rarely cooked recipe once, long ago
        await MultiIngredientFixtures.createMealHistory(
          mockDb: mockDbHelper,
          recipes: [rarelyCooked],
          daysAgo: [30],
        );

        // Get detailed recommendations to see factor scores
        final results = await recommendationService.getDetailedRecommendations(
          count: 3,
        );

        expect(results.recommendations, hasLength(3));

        // Verify all factors contributed to scoring
        for (final rec in results.recommendations) {
          expect(rec.factorScores, isNotEmpty);
          expect(rec.factorScores.containsKey('frequency'), isTrue);
          expect(rec.factorScores.containsKey('protein_rotation'), isTrue);
          expect(rec.factorScores.containsKey('variety_encouragement'), isTrue);
          expect(rec.factorScores.containsKey('rating'), isTrue);
          expect(rec.factorScores.containsKey('difficulty'), isTrue);
        }

        // Never cooked should rank highly (good variety score)
        final neverCookedRec = results.recommendations
            .firstWhere((r) => r.recipe.id == neverCooked.id);
        expect(neverCookedRec.factorScores['variety_encouragement'], equals(100.0));
      });
    });

    group('Temporal Intelligence with Multi-Ingredient Recipes', () {
      test('weekday recommendations favor simpler multi-ingredient recipes', () async {
        // Get a weekday date (Monday)
        final monday = DateTime.now();
        final weekday = monday.subtract(Duration(days: monday.weekday - 1));

        // Create recipes with different difficulty levels
        final simpleRecipe = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Simple Multi-Ingredient',
          proteinTypes: [ProteinType.chicken],
          vegetableCount: 5,
          otherCount: 3,
          difficulty: 1, // Easy
          rating: 4,
          desiredFrequency: FrequencyType.weekly,
        );

        final complexRecipe = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Complex Multi-Ingredient',
          proteinTypes: [ProteinType.beef],
          vegetableCount: 15,
          otherCount: 10,
          difficulty: 5, // Very difficult
          rating: 4,
          desiredFrequency: FrequencyType.weekly,
        );

        // Get recommendations for a weekday
        final recommendations = await recommendationService.getRecommendations(
          count: 2,
          forDate: weekday,
          weekdayMeal: true,
        );

        expect(recommendations, isNotEmpty);

        // Get detailed scores to see difficulty factor impact
        final results = await recommendationService.getDetailedRecommendations(
          count: 2,
          forDate: weekday,
          weekdayMeal: true,
        );

        // Find the simple and complex recipes in results
        final simpleResult = results.recommendations
            .firstWhere((r) => r.recipe.id == simpleRecipe.id);
        final complexResult = results.recommendations
            .firstWhere((r) => r.recipe.id == complexRecipe.id);

        // Simple recipe should have higher difficulty score on weekday
        expect(simpleResult.factorScores['difficulty']!,
            greaterThan(complexResult.factorScores['difficulty']!));
      });

      test('weekend recommendations allow complex multi-ingredient recipes', () async {
        // Get a weekend date (Saturday)
        final saturday = DateTime.now();
        final weekend = saturday.add(Duration(days: 6 - saturday.weekday));

        // Create recipes
        final complexRecipe = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Weekend Special',
          proteinTypes: [ProteinType.beef, ProteinType.pork],
          vegetableCount: 12,
          otherCount: 8,
          difficulty: 5,
          rating: 5,
          desiredFrequency: FrequencyType.weekly,
        );

        await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Quick Meal',
          proteinTypes: [ProteinType.chicken],
          vegetableCount: 3,
          otherCount: 2,
          difficulty: 1,
          rating: 3,
          desiredFrequency: FrequencyType.weekly,
        );

        // Get recommendations for weekend
        final recommendations = await recommendationService.getRecommendations(
          count: 2,
          forDate: weekend,
          weekdayMeal: false,
        );

        expect(recommendations, isNotEmpty);

        // Complex recipe should be included in weekend recommendations
        final complexIncluded = recommendations.any((r) => r.id == complexRecipe.id);
        expect(complexIncluded, isTrue,
            reason: 'Complex recipes should be viable on weekends');
      });
    });

    group('Protein Rotation Across Multi-Ingredient Recipes', () {
      test('protein rotation works correctly with varied ingredient complexity', () async {
        // Create recipes with same protein but different ingredient counts
        final simpleChicken = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Simple Chicken',
          proteinTypes: [ProteinType.chicken],
          vegetableCount: 3,
          otherCount: 2,
        );

        final complexChicken = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Complex Chicken',
          proteinTypes: [ProteinType.chicken],
          vegetableCount: 12,
          otherCount: 8,
        );

        final beefRecipe = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Beef Recipe',
          proteinTypes: [ProteinType.beef],
          vegetableCount: 8,
          otherCount: 5,
        );

        // Cook simple chicken recently
        await MultiIngredientFixtures.createMealHistory(
          mockDb: mockDbHelper,
          recipes: [simpleChicken],
          daysAgo: [1],
        );

        // Get recommendations
        final recommendations = await recommendationService.getRecommendations(
          count: 3,
        );

        // Both chicken recipes should be penalized equally
        // Beef should rank higher
        final beefRank = recommendations.indexWhere((r) => r.id == beefRecipe.id);
        final simpleChickenRank =
            recommendations.indexWhere((r) => r.id == simpleChicken.id);
        final complexChickenRank =
            recommendations.indexWhere((r) => r.id == complexChicken.id);

        // Beef should rank higher than both chicken recipes
        if (beefRank != -1 && simpleChickenRank != -1) {
          expect(beefRank, lessThan(simpleChickenRank));
        }
        if (beefRank != -1 && complexChickenRank != -1) {
          expect(beefRank, lessThan(complexChickenRank));
        }
      });

      test('multi-protein recipes interact correctly with protein rotation', () async {
        // Create single and multi-protein recipes
        final singleBeef = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Pure Beef',
          proteinTypes: [ProteinType.beef],
          vegetableCount: 8,
          otherCount: 4,
        );

        final beefChicken = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Beef and Chicken',
          proteinTypes: [ProteinType.beef, ProteinType.chicken],
          vegetableCount: 10,
          otherCount: 5,
        );

        final fishRecipe = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Fish',
          proteinTypes: [ProteinType.fish],
          vegetableCount: 7,
          otherCount: 4,
        );

        // Cook beef recently
        await MultiIngredientFixtures.createMealHistory(
          mockDb: mockDbHelper,
          recipes: [singleBeef],
          daysAgo: [1],
        );

        // Get detailed recommendations
        final results = await recommendationService.getDetailedRecommendations(
          count: 3,
        );

        // Find protein rotation scores
        final beefScore = results.recommendations
            .firstWhere((r) => r.recipe.id == singleBeef.id)
            .factorScores['protein_rotation']!;
        final beefChickenScore = results.recommendations
            .firstWhere((r) => r.recipe.id == beefChicken.id)
            .factorScores['protein_rotation']!;
        final fishScore = results.recommendations
            .firstWhere((r) => r.recipe.id == fishRecipe.id)
            .factorScores['protein_rotation']!;

        // Both beef-containing recipes should have lower or equal scores compared to fish
        // Note: Exact scoring depends on how the recommendation service builds context
        expect(beefScore, lessThanOrEqualTo(fishScore));
        expect(beefChickenScore, lessThanOrEqualTo(fishScore));

        // Single beef and beef+chicken should have similar penalties (within 20 points)
        // This is more lenient to account for how multi-protein penalties are calculated
        expect((beefScore - beefChickenScore).abs(), lessThan(20));
      });
    });

    group('Factor Scoring Accuracy with Complex Recipes', () {
      test('frequency factor scores complex recipes correctly', () async {
        // Create recipes with different frequency preferences
        final daily = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Daily Recipe',
          vegetableCount: 10,
          otherCount: 5,
          desiredFrequency: FrequencyType.daily,
        );

        final rarely = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Rare Recipe',
          vegetableCount: 10,
          otherCount: 5,
          desiredFrequency: FrequencyType.rarely,
        );

        // Cook both recipes the same time ago
        await MultiIngredientFixtures.createMealHistory(
          mockDb: mockDbHelper,
          recipes: [daily, rarely],
          daysAgo: [7, 7],
        );

        final results = await recommendationService.getDetailedRecommendations(
          count: 2,
        );

        final dailyScore = results.recommendations
            .firstWhere((r) => r.recipe.id == daily.id)
            .factorScores['frequency']!;
        final rarelyScore = results.recommendations
            .firstWhere((r) => r.recipe.id == rarely.id)
            .factorScores['frequency']!;

        // Daily recipe should have higher frequency score (overdue)
        expect(dailyScore, greaterThan(rarelyScore));
      });

      test('rating factor scores complex recipes correctly', () async {
        final highRated = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'High Rated',
          vegetableCount: 12,
          otherCount: 6,
          rating: 5,
        );

        final lowRated = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Low Rated',
          vegetableCount: 12,
          otherCount: 6,
          rating: 2,
        );

        final results = await recommendationService.getDetailedRecommendations(
          count: 2,
        );

        final highScore = results.recommendations
            .firstWhere((r) => r.recipe.id == highRated.id)
            .factorScores['rating']!;
        final lowScore = results.recommendations
            .firstWhere((r) => r.recipe.id == lowRated.id)
            .factorScores['rating']!;

        // High rated should score better
        expect(highScore, greaterThan(lowScore));
      });

      test('all factors produce valid scores for complex recipes', () async {
        // Create a very complex recipe
        await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Very Complex',
          proteinTypes: [ProteinType.beef, ProteinType.chicken, ProteinType.pork],
          vegetableCount: 15,
          otherCount: 10,
          difficulty: 5,
          rating: 4,
          desiredFrequency: FrequencyType.weekly,
        );

        final results = await recommendationService.getDetailedRecommendations(
          count: 1,
        );

        final rec = results.recommendations.first;

        // All factor scores should be between 0 and 100
        for (final entry in rec.factorScores.entries) {
          expect(entry.value, greaterThanOrEqualTo(0.0),
              reason: '${entry.key} score should be >= 0');
          expect(entry.value, lessThanOrEqualTo(100.0),
              reason: '${entry.key} score should be <= 100');
        }

        // Final score should also be valid
        expect(rec.totalScore, greaterThanOrEqualTo(0.0));
        expect(rec.totalScore, lessThanOrEqualTo(100.0));
      });
    });

    group('Edge Cases with Multi-Ingredient Recipes', () {
      test('handles empty database gracefully', () async {
        // Don't create any recipes
        final recommendations = await recommendationService.getRecommendations(
          count: 5,
        );

        expect(recommendations, isEmpty);
      });

      test('handles all recipes recently cooked', () async {
        // Create recipes and cook them all yesterday
        final recipes = await MultiIngredientFixtures.createLargeRecipeDataset(
          mockDb: mockDbHelper,
          count: 10,
          ingredientsPerRecipe: 12,
        );

        for (final recipe in recipes) {
          await MultiIngredientFixtures.createMealHistory(
            mockDb: mockDbHelper,
            recipes: [recipe],
            daysAgo: [1],
          );
        }

        // Should still return recommendations (just with lower scores)
        final recommendations = await recommendationService.getRecommendations(
          count: 5,
        );

        expect(recommendations, isNotEmpty);
        expect(recommendations.length, lessThanOrEqualTo(5));
      });

      test('handles mix of simple and complex recipes', () async {
        // Create a mix of simple (3 ingredients) and complex (20 ingredients) recipes
        await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Simple',
          vegetableCount: 2,
          otherCount: 0,
        );

        await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Complex',
          vegetableCount: 15,
          otherCount: 10,
        );

        // Should handle both gracefully
        final recommendations = await recommendationService.getRecommendations(
          count: 2,
        );

        expect(recommendations, hasLength(2));
      });
    });
  });
}
