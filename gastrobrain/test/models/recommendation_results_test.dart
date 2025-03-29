// test/core/models/recommendation_results_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/recipe_recommendation.dart';
import 'package:gastrobrain/models/recommendation_results.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';

void main() {
  group('RecommendationResults', () {
    late List<RecipeRecommendation> testRecommendations;
    late Map<String, dynamic> testQueryParameters;

    setUp(() {
      // Create test recipes
      final recipe1 = Recipe(
        id: 'recipe-1',
        name: 'Recipe 1',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
      );

      final recipe2 = Recipe(
        id: 'recipe-2',
        name: 'Recipe 2',
        desiredFrequency: FrequencyType.monthly,
        createdAt: DateTime.now(),
      );

      // Create test recommendations
      testRecommendations = [
        RecipeRecommendation(
          recipe: recipe1,
          totalScore: 90.0,
          factorScores: {'test': 90.0},
        ),
        RecipeRecommendation(
          recipe: recipe2,
          totalScore: 85.0,
          factorScores: {'test': 85.0},
        ),
      ];

      // Create test query parameters
      testQueryParameters = {
        'count': 5,
        'excludeIds': ['excluded-id-1', 'excluded-id-2'],
        'forDate': DateTime.now().toIso8601String(),
        'mealType': 'lunch',
      };
    });

    test('creates with required properties', () {
      final results = RecommendationResults(
        recommendations: testRecommendations,
        totalEvaluated: 10,
        queryParameters: testQueryParameters,
      );

      // Verify properties are set correctly
      expect(results.recommendations, equals(testRecommendations));
      expect(results.totalEvaluated, equals(10));
      expect(results.queryParameters, equals(testQueryParameters));
      expect(results.generatedAt, isNotNull); // Default should be generated
    });

    test('creates with specified generation time', () {
      final specificTime = DateTime(2024, 1, 1, 12, 0);

      final results = RecommendationResults(
        recommendations: testRecommendations,
        totalEvaluated: 10,
        queryParameters: testQueryParameters,
        generatedAt: specificTime,
      );

      expect(results.generatedAt, equals(specificTime));
    });

    test('handles empty recommendations list', () {
      final results = RecommendationResults(
        recommendations: [],
        totalEvaluated: 0,
        queryParameters: {},
      );

      expect(results.recommendations, isEmpty);
      expect(results.totalEvaluated, equals(0));
    });
  });
}
