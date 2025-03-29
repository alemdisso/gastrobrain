// test/core/models/recommendation_results_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/recipe_recommendation.dart';
import 'package:gastrobrain/models/recommendation_results.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';

import '../mocks/mock_database_helper.dart';

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

    test('converts to JSON correctly', () {
      final specificTime = DateTime(2024, 1, 1, 12, 0);

      final results = RecommendationResults(
        recommendations: testRecommendations,
        totalEvaluated: 10,
        queryParameters: testQueryParameters,
        generatedAt: specificTime,
      );

      final json = results.toJson();

      // Verify JSON structure
      expect(json['recommendations'].length, equals(2));
      expect(json['recommendations'][0]['recipe_id'], equals('recipe-1'));
      expect(json['recommendations'][1]['recipe_id'], equals('recipe-2'));
      expect(json['total_evaluated'], equals(10));
      expect(json['query_parameters'], equals(testQueryParameters));
      expect(json['generated_at'], equals(specificTime.toIso8601String()));
      expect(json['schema_version'], equals(1));
    });

    test('creates from JSON with mockDatabaseHelper', () async {
      // Setup mock database helper
      final mockDbHelper = MockDatabaseHelper();

      // Add test recipes to mock database
      for (final rec in testRecommendations) {
        await mockDbHelper.insertRecipe(rec.recipe);
      }

      // Create JSON data
      final specificTime = DateTime(2024, 1, 1, 12, 0);
      final json = {
        'recommendations': [
          {
            'recipe_id': 'recipe-1',
            'total_score': 90.0,
            'factor_scores': {'test': 90.0},
            'metadata': {},
          },
          {
            'recipe_id': 'recipe-2',
            'total_score': 85.0,
            'factor_scores': {'test': 85.0},
            'metadata': {},
          },
        ],
        'total_evaluated': 10,
        'query_parameters': testQueryParameters,
        'generated_at': specificTime.toIso8601String(),
        'schema_version': 1,
      };

      // Create results from JSON
      final results = await RecommendationResults.fromJson(json, mockDbHelper);

      // Verify correct reconstruction
      expect(results.recommendations.length, equals(2));
      expect(results.recommendations[0].recipe.id, equals('recipe-1'));
      expect(results.recommendations[1].recipe.id, equals('recipe-2'));
      expect(results.totalEvaluated, equals(10));
      expect(results.queryParameters, equals(testQueryParameters));
      expect(results.generatedAt, equals(specificTime));
    });
  });
}
