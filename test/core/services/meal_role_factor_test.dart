// test/core/services/meal_role_factor_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/core/services/recommendation_factors/meal_role_factor.dart';
import 'package:gastrobrain/core/services/recommendation_service.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';

import '../../mocks/mock_database_helper.dart';

Recipe _recipe(String id) => Recipe(
      id: id,
      name: 'Recipe $id',
      desiredFrequency: FrequencyType.weekly,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  const factor = MealRoleFactor();

  group('RecommendationService — meal_role weight', () {
    test('meal_role registered with weight 0 by default', () {
      final service = RecommendationService(
        dbHelper: MockDatabaseHelper(),
        registerDefaultFactors: true,
      );
      expect(service.getFactorWeight('meal_role'), equals(0));
    });

    test('weekday_lunch profile gives meal_role non-zero weight', () {
      final service = RecommendationService(
        dbHelper: MockDatabaseHelper(),
        registerDefaultFactors: true,
      );
      service.applyWeightProfile('weekday_lunch');
      expect(service.getFactorWeight('meal_role'), greaterThan(0));
    });

    test('weekend_dinner profile gives meal_role non-zero weight', () {
      final service = RecommendationService(
        dbHelper: MockDatabaseHelper(),
        registerDefaultFactors: true,
      );
      service.applyWeightProfile('weekend_dinner');
      expect(service.getFactorWeight('meal_role'), greaterThan(0));
    });
  });

  group('MealRoleFactor — neutral when recipe has no tags', () {
    test('returns 50 when recipeTags is absent from context', () async {
      final score = await factor.calculateScore(
        _recipe('r1'),
        {'mealType': 'lunch'},
      );
      expect(score, equals(50.0));
    });

    test('returns 50 when recipe has empty tag list', () async {
      final score = await factor.calculateScore(
        _recipe('r1'),
        {'mealType': 'lunch', 'recipeTags': <String, List<String>>{'r1': []}},
      );
      expect(score, equals(50.0));
    });
  });

  group('MealRoleFactor — meal_role scoring at lunch', () {
    test('complete-meal at lunch scores 90×0.6 + neutral 50×0.4 = 74 when no food_type', () async {
      final score = await factor.calculateScore(
        _recipe('r1'),
        {
          'mealType': 'lunch',
          'recipeTags': <String, List<String>>{
            'r1': ['meal-role-complete-meal'],
          },
        },
      );
      expect(score, equals(90 * 0.6 + 50 * 0.4));
    });

    test('soup (food-type) at lunch scores 50×0.6 + 35×0.4 = 44 when no meal_role', () async {
      final score = await factor.calculateScore(
        _recipe('r1'),
        {
          'mealType': 'lunch',
          'recipeTags': <String, List<String>>{
            'r1': ['food-type-soup'],
          },
        },
      );
      expect(score, equals(50 * 0.6 + 35 * 0.4));
    });

    test('complete-meal + rice at lunch scores 90×0.6 + 80×0.4 = 86', () async {
      final score = await factor.calculateScore(
        _recipe('r1'),
        {
          'mealType': 'lunch',
          'recipeTags': <String, List<String>>{
            'r1': ['meal-role-complete-meal', 'food-type-rice'],
          },
        },
      );
      expect(score, equals(90 * 0.6 + 80 * 0.4));
    });
  });

  group('MealRoleFactor — takes best score when multiple tags of same type', () {
    test('uses highest meal_role score when recipe has two meal_role tags', () async {
      // snack=10, complete-meal=90 → should use 90
      final score = await factor.calculateScore(
        _recipe('r1'),
        {
          'mealType': 'lunch',
          'recipeTags': <String, List<String>>{
            'r1': ['meal-role-snack', 'meal-role-complete-meal'],
          },
        },
      );
      expect(score, equals(90 * 0.6 + 50 * 0.4));
    });
  });

  group('MealRoleFactor — dinner vs lunch difference', () {
    test('soup scores higher at dinner (80) than at lunch (35)', () async {
      final lunchScore = await factor.calculateScore(
        _recipe('r1'),
        {
          'mealType': 'lunch',
          'recipeTags': <String, List<String>>{'r1': ['food-type-soup']},
        },
      );
      final dinnerScore = await factor.calculateScore(
        _recipe('r1'),
        {
          'mealType': 'dinner',
          'recipeTags': <String, List<String>>{'r1': ['food-type-soup']},
        },
      );
      expect(dinnerScore, greaterThan(lunchScore));
    });

    test('rice scores higher at lunch (80) than at dinner (60)', () async {
      final lunchScore = await factor.calculateScore(
        _recipe('r1'),
        {
          'mealType': 'lunch',
          'recipeTags': <String, List<String>>{'r1': ['food-type-rice']},
        },
      );
      final dinnerScore = await factor.calculateScore(
        _recipe('r1'),
        {
          'mealType': 'dinner',
          'recipeTags': <String, List<String>>{'r1': ['food-type-rice']},
        },
      );
      expect(lunchScore, greaterThan(dinnerScore));
    });
  });

  group('MealRoleFactor — requiredData', () {
    test('declares recipeTags as required data', () {
      expect(factor.requiredData, contains('recipeTags'));
    });
  });

  group('MealRoleFactor — neutral when mealType absent', () {
    test('returns 50 when mealType is null', () async {
      final score = await factor.calculateScore(
        _recipe('r1'),
        {'mealType': null},
      );
      expect(score, equals(50.0));
    });

    test('returns 50 when mealType is unrecognised', () async {
      final score = await factor.calculateScore(
        _recipe('r1'),
        {'mealType': 'breakfast'},
      );
      expect(score, equals(50.0));
    });
  });
}
