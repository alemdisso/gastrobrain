// test/core/services/recommendation_factors/frequency_factor_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/core/services/recommendation_factors/frequency_factor.dart';
import 'package:gastrobrain/utils/id_generator.dart';

void main() {
  group('FrequencyFactor', () {
    late FrequencyFactor factor;

    setUp(() {
      factor = FrequencyFactor();
    });

    test('should have id "frequency"', () {
      expect(factor.id, equals('frequency'));
    });

    test('should have weight 40', () {
      expect(factor.defaultWeight, equals(35));
    });

    test('should require lastCooked data', () {
      expect(factor.requiredData, contains('lastCooked'));
    });

    test('should give high score to recipes never cooked', () async {
      // Arrange
      final recipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Test Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
      );

      final context = {
        'lastCooked': <String, DateTime?>{},
      };

      // Act
      final score = await factor.calculateScore(recipe, context);

      // Assert
      expect(score, equals(85.0));
    });

    test('should give high score to overdue recipes', () async {
      // Arrange
      final recipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Test Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
      );

      final context = {
        'lastCooked': <String, DateTime?>{
          recipe.id:
              DateTime.now().subtract(const Duration(days: 14)), // 2 weeks ago
        },
      };

      // Act
      final score = await factor.calculateScore(recipe, context);

      // Assert
      expect(score, greaterThanOrEqualTo(90.0));
      expect(score, lessThan(95.0));
    });

    test('should give low score to recently cooked recipes', () async {
      // Arrange
      final recipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Test Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
      );

      final context = {
        'lastCooked': <String, DateTime?>{
          recipe.id:
              DateTime.now().subtract(const Duration(days: 1)), // 1 day ago
        },
      };

      // Act
      final score = await factor.calculateScore(recipe, context);

      // Assert
      expect(score, lessThan(20.0)); // Expect low score for recently cooked
    });

    test('should handle different frequency types correctly', () async {
      // Arrange
      final dailyRecipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Daily Recipe',
        desiredFrequency: FrequencyType.daily,
        createdAt: DateTime.now(),
      );

      final weeklyRecipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Weekly Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
      );

      final monthlyRecipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Monthly Recipe',
        desiredFrequency: FrequencyType.monthly,
        createdAt: DateTime.now(),
      );

      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));

      final context = {
        'lastCooked': <String, DateTime?>{
          dailyRecipe.id: threeDaysAgo,
          weeklyRecipe.id: threeDaysAgo,
          monthlyRecipe.id: threeDaysAgo,
        },
      };

      // Act
      final dailyScore = await factor.calculateScore(dailyRecipe, context);
      final weeklyScore = await factor.calculateScore(weeklyRecipe, context);
      final monthlyScore = await factor.calculateScore(monthlyRecipe, context);

      // Assert
      // Daily recipe cooked 3 days ago should have a higher score than
      // a weekly recipe cooked 3 days ago
      expect(dailyScore, greaterThan(weeklyScore));

      // Weekly recipe cooked 3 days ago should have a higher score than
      // a monthly recipe cooked 3 days ago
      expect(weeklyScore, greaterThan(monthlyScore));
    });
  });
}
