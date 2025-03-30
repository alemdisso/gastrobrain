import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/recipe.dart';
//import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/core/services/recommendation_factors/variety_encouragement_factor.dart';
import 'package:gastrobrain/utils/id_generator.dart';

void main() {
  group('VarietyEncouragementFactor', () {
    late VarietyEncouragementFactor factor;

    setUp(() {
      factor = VarietyEncouragementFactor();
    });

    test('should have id "variety_encouragement"', () {
      expect(factor.id, equals('variety_encouragement'));
    });

    test('should have weight 10', () {
      expect(factor.weight, equals(10));
    });

    test('should require mealCounts data', () {
      expect(factor.requiredData, contains('mealCounts'));
    });

    test('should give highest score to recipes never cooked', () async {
      // Arrange
      final recipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Never Cooked Recipe',
        createdAt: DateTime.now(),
      );

      final context = {
        'mealCounts': <String, int>{}, // Empty meal counts
      };

      // Act
      final score = await factor.calculateScore(recipe, context);

      // Assert
      expect(score, equals(100.0)); // Perfect score for never cooked
    });

    test('should give high score to rarely cooked recipes', () async {
      // Arrange
      final recipe = Recipe(
        id: 'rarely-cooked-id',
        name: 'Rarely Cooked Recipe',
        createdAt: DateTime.now(),
      );

      final context = {
        'mealCounts': <String, int>{
          'rarely-cooked-id': 1, // Cooked only once
        },
      };

      // Act
      final score = await factor.calculateScore(recipe, context);

      // Assert
      expect(score, greaterThan(75.0)); // High score for rarely cooked
      expect(score, lessThan(100.0)); // But not perfect
    });

    test('should give lower score to frequently cooked recipes', () async {
      // Arrange
      final recipe = Recipe(
        id: 'frequently-cooked-id',
        name: 'Frequently Cooked Recipe',
        createdAt: DateTime.now(),
      );

      final context = {
        'mealCounts': <String, int>{
          'frequently-cooked-id': 10, // Cooked 10 times
        },
      };

      // Act
      final score = await factor.calculateScore(recipe, context);

      // Assert
      expect(score, lessThan(50.0)); // Lower score for frequently cooked
    });

    test('should handle varying cook counts with appropriate scoring',
        () async {
      // Arrange - Create recipes with different cooking frequencies
      final recipes = [
        Recipe(id: 'recipe-0', name: 'Never Cooked', createdAt: DateTime.now()),
        Recipe(id: 'recipe-1', name: 'Cooked Once', createdAt: DateTime.now()),
        Recipe(
            id: 'recipe-3', name: 'Cooked 3 Times', createdAt: DateTime.now()),
        Recipe(
            id: 'recipe-5', name: 'Cooked 5 Times', createdAt: DateTime.now()),
        Recipe(
            id: 'recipe-10',
            name: 'Cooked 10 Times',
            createdAt: DateTime.now()),
        Recipe(
            id: 'recipe-20',
            name: 'Cooked 20 Times',
            createdAt: DateTime.now()),
      ];

      final mealCounts = <String, int>{
        'recipe-1': 1,
        'recipe-3': 3,
        'recipe-5': 5,
        'recipe-10': 10,
        'recipe-20': 20,
      };

      final context = {
        'mealCounts': mealCounts,
      };

      // Act - Get scores for all recipes
      final scores = <String, double>{};
      for (final recipe in recipes) {
        scores[recipe.id] = await factor.calculateScore(recipe, context);
      }

      // Assert - Verify the scores decrease as cook count increases
      expect(scores['recipe-0']!, equals(100.0)); // Never cooked
      expect(scores['recipe-1']!, lessThan(scores['recipe-0']!));
      expect(scores['recipe-3']!, lessThan(scores['recipe-1']!));
      expect(scores['recipe-5']!, lessThan(scores['recipe-3']!));
      expect(scores['recipe-10']!, lessThan(scores['recipe-5']!));
      expect(scores['recipe-20']!, lessThan(scores['recipe-10']!));
    });
  });
}
