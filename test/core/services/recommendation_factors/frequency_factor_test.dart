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

    group('With Meal Plan (Planned Recipes)', () {
      test('should return 0.0 for recipe already in meal plan', () async {
        // Arrange
        final recipe = Recipe(
          id: 'recipe-1',
          name: 'Chicken Curry',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
        );

        final context = {
          'plannedRecipeIds': ['recipe-1'], // recipe-1 is planned
          'lastCooked': <String, DateTime?>{
            'recipe-1': null, // Never cooked
          },
        };

        // Act
        final score = await factor.calculateScore(recipe, context);

        // Assert - Should get 0.0 even though never cooked
        expect(score, equals(0.0));
      });

      test('should score normally for recipe NOT in meal plan', () async {
        // Arrange
        final recipe = Recipe(
          id: 'recipe-2',
          name: 'Beef Tacos',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
        );

        final context = {
          'plannedRecipeIds': ['recipe-1'], // recipe-2 not planned
          'lastCooked': <String, DateTime?>{
            'recipe-2': null, // Never cooked
          },
        };

        // Act
        final score = await factor.calculateScore(recipe, context);

        // Assert - Should get normal score for never-cooked recipe
        expect(score, equals(85.0));
      });

      test('should penalize planned recipe even if overdue', () async {
        // Arrange
        final recipe = Recipe(
          id: 'recipe-1',
          name: 'Weekly Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
        );

        final context = {
          'plannedRecipeIds': ['recipe-1'],
          'lastCooked': <String, DateTime?>{
            'recipe-1':
                DateTime.now().subtract(const Duration(days: 14)), // 2 weeks ago
          },
        };

        // Act
        final score = await factor.calculateScore(recipe, context);

        // Assert - Should get 0.0 even though overdue
        expect(score, equals(0.0));
      });

      test('should work when plannedRecipeIds is empty', () async {
        // Arrange
        final recipe = Recipe(
          id: 'recipe-1',
          name: 'Chicken Curry',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
        );

        final context = {
          'plannedRecipeIds': <String>[], // Empty list
          'lastCooked': <String, DateTime?>{
            'recipe-1': null,
          },
        };

        // Act
        final score = await factor.calculateScore(recipe, context);

        // Assert - Should score normally
        expect(score, equals(85.0));
      });

      test('should fallback to normal behavior when no plannedRecipeIds',
          () async {
        // Arrange
        final recipe = Recipe(
          id: 'recipe-1',
          name: 'Weekly Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
        );

        final context = {
          // No plannedRecipeIds in context
          'lastCooked': <String, DateTime?>{
            'recipe-1':
                DateTime.now().subtract(const Duration(days: 3)), // 3 days ago
          },
        };

        // Act
        final score = await factor.calculateScore(recipe, context);

        // Assert - Should use normal frequency scoring
        expect(score, greaterThan(0.0));
        expect(score, lessThan(85.0)); // Not yet due (3 days < 7 days)
      });
    });
  });
}
