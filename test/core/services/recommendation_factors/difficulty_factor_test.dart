import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/core/services/recommendation_factors/difficulty_factor.dart';
import 'package:gastrobrain/utils/id_generator.dart';

void main() {
  group('DifficultyFactor', () {
    late DifficultyFactor factor;

    setUp(() {
      factor = DifficultyFactor();
    });

    test('should have id "difficulty"', () {
      expect(factor.id, equals('difficulty'));
    });

    test('should have weight 10', () {
      expect(factor.defaultWeight, equals(10));
    });

    test('should not require additional data', () {
      expect(factor.requiredData, isEmpty);
    });

    test('should give highest score to easiest recipes', () async {
      // Arrange
      final recipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Easy Recipe',
        createdAt: DateTime.now(),
        difficulty: 1, // Easiest difficulty
      );

      final context = <String, dynamic>{};

      // Act
      final score = await factor.calculateScore(recipe, context);

      // Assert
      expect(score, equals(100.0)); // Highest score for easiest recipe
    });

    test('should give lowest score to hardest recipes', () async {
      // Arrange
      final recipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Difficult Recipe',
        createdAt: DateTime.now(),
        difficulty: 5, // Hardest difficulty
      );

      final context = <String, dynamic>{};

      // Act
      final score = await factor.calculateScore(recipe, context);

      // Assert
      expect(score, equals(20.0)); // Lowest score for hardest recipe
    });

    test('should give neutral score to recipes with invalid difficulty',
        () async {
      // Arrange
      final recipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Invalid Difficulty Recipe',
        createdAt: DateTime.now(),
        difficulty: 0, // Invalid difficulty
      );

      final context = <String, dynamic>{};

      // Act
      final score = await factor.calculateScore(recipe, context);

      // Assert
      expect(score, equals(50.0)); // Neutral score for invalid difficulty
    });

    test('should score each difficulty level correctly', () async {
      final context = <String, dynamic>{};

      // Test all valid difficulty levels
      for (int difficulty = 1; difficulty <= 5; difficulty++) {
        // Arrange
        final recipe = Recipe(
          id: IdGenerator.generateId(),
          name: 'Recipe with Difficulty $difficulty',
          createdAt: DateTime.now(),
          difficulty: difficulty,
        );

        // Act
        final score = await factor.calculateScore(recipe, context);

        // Assert - Verify score matches expected formula
        final expectedScore = 120.0 - (difficulty * 20.0);
        expect(score, equals(expectedScore));
      }
    });

    test('static utility function calculates correct scores', () {
      // Create recipes with different difficulties
      final easyRecipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Easy Recipe',
        createdAt: DateTime.now(),
        difficulty: 1,
      );

      final mediumRecipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Medium Recipe',
        createdAt: DateTime.now(),
        difficulty: 3,
      );

      final hardRecipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Hard Recipe',
        createdAt: DateTime.now(),
        difficulty: 5,
      );

      // Calculate scores using static method
      final easyScore = DifficultyFactor.calculateDifficultyScore(easyRecipe);
      final mediumScore =
          DifficultyFactor.calculateDifficultyScore(mediumRecipe);
      final hardScore = DifficultyFactor.calculateDifficultyScore(hardRecipe);

      // Verify scores
      expect(easyScore, equals(100.0)); // Highest score
      expect(mediumScore, equals(60.0)); // Middle score
      expect(hardScore, equals(20.0)); // Lowest score
    });
  });
}
