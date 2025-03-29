import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/recipe_recommendation.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';

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
  });
}
