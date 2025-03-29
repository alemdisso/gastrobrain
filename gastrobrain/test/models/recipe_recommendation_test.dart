import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/recipe_recommendation.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/core/errors/gastrobrain_exceptions.dart';

import '../mocks/mock_database_helper.dart';

void main() {
  group('RecipeRecommendation', () {
    late Recipe testRecipe;

    setUp(() {
      // Create a test recipe to use in our tests
      testRecipe = Recipe(
        id: 'test-recipe-id',
        name: 'Test Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
      );
    });

    test('creates with required properties', () {
      final factorScores = {
        'frequency': 80.0,
        'protein_rotation': 90.0,
        'rating': 75.0,
      };

      final recommendation = RecipeRecommendation(
        recipe: testRecipe,
        totalScore: 82.5,
        factorScores: factorScores,
      );

      // Verify all properties are set correctly
      expect(recommendation.recipe, equals(testRecipe));
      expect(recommendation.totalScore, equals(82.5));
      expect(recommendation.factorScores, equals(factorScores));
      expect(recommendation.metadata, isEmpty);
    });

    test('creates with metadata', () {
      final metadata = {
        'position': 1,
        'source': 'lunch_recommendations',
      };

      final recommendation = RecipeRecommendation(
        recipe: testRecipe,
        totalScore: 75.0,
        factorScores: {'test': 75.0},
        metadata: metadata,
      );

      expect(recommendation.metadata, equals(metadata));
    });

    // test/models/recipe_recommendation_test.dart - add this test to the existing file

    test('converts to JSON correctly', () {
      final recommendation = RecipeRecommendation(
        recipe: testRecipe,
        totalScore: 85.0,
        factorScores: {
          'frequency': 80.0,
          'protein_rotation': 90.0,
        },
        metadata: {
          'position': 2,
          'source': 'dinner_recommendations',
        },
      );

      final json = recommendation.toJson();

      // Verify JSON conversion
      expect(json['recipe_id'], equals(testRecipe.id));
      expect(json['total_score'], equals(85.0));
      expect(
          json['factor_scores'],
          equals({
            'frequency': 80.0,
            'protein_rotation': 90.0,
          }));
      expect(
          json['metadata'],
          equals({
            'position': 2,
            'source': 'dinner_recommendations',
          }));
    });
    // test/models/recipe_recommendation_test.dart - add this test to the existing file

    test('creates from JSON with mockDatabaseHelper', () async {
      // Setup mock database helper
      final mockDbHelper = MockDatabaseHelper();

      // Add test recipe to mock database
      await mockDbHelper.insertRecipe(testRecipe);

      // Create JSON data
      final json = {
        'recipe_id': testRecipe.id,
        'total_score': 85.0,
        'factor_scores': {
          'frequency': 80.0,
          'protein_rotation': 90.0,
        },
        'metadata': {
          'position': 2,
          'source': 'dinner_recommendations',
        },
      };

      // Create recommendation from JSON
      final recommendation =
          await RecipeRecommendation.fromJson(json, mockDbHelper);

      // Verify correct reconstruction
      expect(recommendation.recipe.id, equals(testRecipe.id));
      expect(recommendation.totalScore, equals(85.0));
      expect(
          recommendation.factorScores,
          equals({
            'frequency': 80.0,
            'protein_rotation': 90.0,
          }));
      expect(
          recommendation.metadata,
          equals({
            'position': 2,
            'source': 'dinner_recommendations',
          }));
    });

    test('throws NotFoundException when recipe not found', () async {
      // Setup mock database helper
      final mockDbHelper = MockDatabaseHelper();

      // Create JSON with non-existent recipe ID
      final json = {
        'recipe_id': 'non-existent-id',
        'total_score': 85.0,
        'factor_scores': {},
        'metadata': {},
      };

      // Attempt to create recommendation from JSON
      expect(
        () => RecipeRecommendation.fromJson(json, mockDbHelper),
        throwsA(isA<NotFoundException>()),
      );
    });
  });
}
