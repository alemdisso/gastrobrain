import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/core/services/recommendation_factors/randomization_factor.dart';
import 'package:gastrobrain/utils/id_generator.dart';

void main() {
  group('RandomizationFactor', () {
    late RandomizationFactor factor;

    setUp(() {
      factor = RandomizationFactor();
    });

    test('should have id "randomization"', () {
      expect(factor.id, equals('randomization'));
    });

    test('should have weight 5', () {
      expect(factor.defaultWeight, equals(5));
    });

    test('should not require additional data', () {
      expect(factor.requiredData, isEmpty);
    });

    test('should generate score between 0 and 100', () async {
      // Arrange
      final recipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Test Recipe',
        createdAt: DateTime.now(),
      );

      // We'll use an empty context since randomization doesn't need context data
      final context = <String, dynamic>{};

      // Act
      final score = await factor.calculateScore(recipe, context);

      // Assert - score should be between 0 and 100
      expect(score, greaterThanOrEqualTo(0.0));
      expect(score, lessThanOrEqualTo(100.0));
    });

    test('should generate different scores for same input with no seed',
        () async {
      // Arrange
      final recipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Test Recipe',
        createdAt: DateTime.now(),
      );

      final context = <String, dynamic>{};

      // Act - get multiple scores
      final score1 = await factor.calculateScore(recipe, context);
      // Add a small delay to ensure timestamp changes
      await Future.delayed(const Duration(milliseconds: 2));
      final score2 = await factor.calculateScore(recipe, context);

      // There's a tiny chance these could be equal by random chance,
      // but it's extremely unlikely with a continuous distribution
      expect(score1, isNot(equals(score2)));
    });

    test('should generate same scores when seed is provided', () async {
      // Arrange
      final recipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Test Recipe',
        createdAt: DateTime.now(),
      );

      final contextWithSeed1 = <String, dynamic>{'randomSeed': 42};
      final contextWithSeed2 = <String, dynamic>{'randomSeed': 42};

      // Act - get scores with the same seed
      final score1 = await factor.calculateScore(recipe, contextWithSeed1);
      final score2 = await factor.calculateScore(recipe, contextWithSeed2);

      // With same seed, should get exactly the same result
      expect(score1, equals(score2));
    });

    test('should generate different scores with different seeds', () async {
      // Arrange
      final recipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Test Recipe',
        createdAt: DateTime.now(),
      );

      final contextWithSeed1 = <String, dynamic>{'randomSeed': 42};
      final contextWithSeed2 = <String, dynamic>{'randomSeed': 43};

      // Act
      final score1 = await factor.calculateScore(recipe, contextWithSeed1);
      final score2 = await factor.calculateScore(recipe, contextWithSeed2);

      // Different seeds should (almost certainly) give different results
      expect(score1, isNot(equals(score2)));
    });

    test(
        'produces identical scores for same recipe and seed across multiple instances',
        () async {
      // Create a recipe
      final recipe = Recipe(
        id: 'consistent-test-recipe', // Fixed ID for deterministic result
        name: 'Test Recipe',
        createdAt: DateTime.now(),
      );

      // Create fixed context with seed
      final context = <String, dynamic>{
        'randomSeed': 42, // Fixed seed
      };

      // Create two separate instances of the factor
      final factor1 = RandomizationFactor();
      final factor2 = RandomizationFactor();

      // Get scores from both instances
      final score1 = await factor1.calculateScore(recipe, context);
      final score2 = await factor2.calculateScore(recipe, context);

      // Scores should be identical with same recipe ID and same seed
      expect(score2, equals(score1),
          reason:
              "Multiple factor instances should produce identical scores for same recipe and seed");
    });
  });
}
