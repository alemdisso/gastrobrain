// test/core/services/recommendation_factors/rating_factor_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/core/services/recommendation_factors/rating_factor.dart';
import 'package:gastrobrain/utils/id_generator.dart';

void main() {
  group('RatingFactor', () {
    late RatingFactor factor;

    setUp(() {
      factor = RatingFactor();
    });

    test('should have id "rating"', () {
      expect(factor.id, equals('rating'));
    });

    test('should have weight 15', () {
      expect(factor.weight, equals(15));
    });

    test('should not require additional data', () {
      expect(factor.requiredData, isEmpty);
    });

    test('should give neutral score (50) to recipes with no rating', () async {
      // Arrange
      final recipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Unrated Recipe',
        createdAt: DateTime.now(),
        rating: 0, // No rating
      );

      final context = <String, dynamic>{};

      // Act
      final score = await factor.calculateScore(recipe, context);

      // Assert
      expect(score, equals(50.0));
    });

    test('should convert 1-5 rating to appropriate score', () async {
      // Test for each possible rating value (1-5)
      for (int rating = 1; rating <= 5; rating++) {
        // Arrange
        final recipe = Recipe(
          id: IdGenerator.generateId(),
          name: 'Rated Recipe $rating',
          createdAt: DateTime.now(),
          rating: rating,
        );

        final context = <String, dynamic>{};

        // Act
        final score = await factor.calculateScore(recipe, context);

        // Assert
        expect(score, equals(20.0 * rating));
      }
    });

    test('static utility function calculates correct scores', () {
      // Create recipes with different ratings
      final unratedRecipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Unrated Recipe',
        createdAt: DateTime.now(),
        rating: 0,
      );

      final highlyRatedRecipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Highly Rated Recipe',
        createdAt: DateTime.now(),
        rating: 5,
      );

      final lowRatedRecipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Low Rated Recipe',
        createdAt: DateTime.now(),
        rating: 1,
      );

      // Calculate scores using static method
      final unratedScore = RatingFactor.calculateRatingScore(unratedRecipe);
      final highlyRatedScore =
          RatingFactor.calculateRatingScore(highlyRatedRecipe);
      final lowRatedScore = RatingFactor.calculateRatingScore(lowRatedRecipe);

      // Verify scores
      expect(unratedScore, equals(50.0)); // Neutral score
      expect(highlyRatedScore, equals(100.0)); // Max score
      expect(lowRatedScore, equals(20.0)); // Min score
    });
  });
}
