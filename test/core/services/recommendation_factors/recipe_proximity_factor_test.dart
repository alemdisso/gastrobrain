// test/core/services/recommendation_factors/recipe_proximity_factor_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/core/services/recommendation_factors/recipe_proximity_factor.dart';
import 'package:gastrobrain/utils/id_generator.dart';

void main() {
  group('RecipeProximityFactor', () {
    late RecipeProximityFactor factor;
    late Recipe recipe;

    setUp(() {
      factor = RecipeProximityFactor();
      recipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Test Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
      );
    });

    test('should have id "recipe_proximity"', () {
      expect(factor.id, equals('recipe_proximity'));
    });

    test('should have default weight 10', () {
      expect(factor.defaultWeight, equals(10));
    });

    test('should require recentMeals data', () {
      expect(factor.requiredData, contains('recentMeals'));
    });

    test('returns 100 when no recent meals and no planned meals', () async {
      final context = {
        'recentMeals': <Map<String, dynamic>>[],
      };

      final score = await factor.calculateScore(recipe, context);

      expect(score, equals(100.0));
    });

    test('returns 0 when recipe was confirmed cooked 1 day before forDate',
        () async {
      final forDate = DateTime(2024, 6, 5);
      final yesterday = DateTime(2024, 6, 4);

      final context = {
        'forDate': forDate,
        'recentMeals': <Map<String, dynamic>>[
          {
            'cookedAt': yesterday,
            'recipes': [recipe],
          }
        ],
      };

      final score = await factor.calculateScore(recipe, context);

      expect(score, equals(0.0)); // 100 - 1.0 * 100
    });

    test('confirmed cook decay: 2 days = 25, 3 days = 50, 4 days = 75',
        () async {
      final forDate = DateTime(2024, 6, 10);

      Future<double> scoreAt(int daysAgo) async {
        final cookedAt = DateTime(2024, 6, 10 - daysAgo);
        final ctx = {
          'forDate': forDate,
          'recentMeals': <Map<String, dynamic>>[
            {'cookedAt': cookedAt, 'recipes': [recipe]},
          ],
        };
        return factor.calculateScore(recipe, ctx);
      }

      expect(await scoreAt(2), equals(25.0));  // 100 - 0.75 * 100
      expect(await scoreAt(3), equals(50.0));  // 100 - 0.50 * 100
      expect(await scoreAt(4), equals(75.0));  // 100 - 0.25 * 100
    });

    test('returns 100 when confirmed cook is 5+ days from forDate', () async {
      final forDate = DateTime(2024, 6, 10);
      final fiveDaysAgo = DateTime(2024, 6, 5);

      final context = {
        'forDate': forDate,
        'recentMeals': <Map<String, dynamic>>[
          {'cookedAt': fiveDaysAgo, 'recipes': [recipe]},
        ],
      };

      final score = await factor.calculateScore(recipe, context);

      expect(score, equals(100.0)); // Outside 4-day window
    });

    group('Unconfirmed past planned meals', () {
      test('in current plan week applies 0.5 confidence', () async {
        // forDate = Wednesday June 12 2024
        // planWeekStartDate = Friday June 7 2024 (5 days before forDate)
        // plannedDate = Saturday June 8 (4 days before forDate, inside current week)
        // NOT in recentMeals (unconfirmed)
        final forDate = DateTime(2024, 6, 12);
        final planWeekStart = DateTime(2024, 6, 7);
        final plannedDate = DateTime(2024, 6, 8); // 4 days before forDate

        final context = {
          'forDate': forDate,
          'recentMeals': <Map<String, dynamic>>[],
          'plannedRecipesByDate': {recipe.id: plannedDate},
          'planWeekStartDate': planWeekStart,
        };

        final score = await factor.calculateScore(recipe, context);

        // dist=4, penalty = 0.25 * 0.5 = 0.125 → score = 100 - 12.5 = 87.5
        expect(score, equals(87.5));
      });

      test('outside current plan week returns 100', () async {
        // June 6 is before planWeekStartDate (June 7) → outside current week
        final forDate = DateTime(2024, 6, 12);
        final planWeekStart = DateTime(2024, 6, 7);
        final outsidePlannedDate = DateTime(2024, 6, 6); // 6 days before forDate, outside week

        final context = {
          'forDate': forDate,
          'recentMeals': <Map<String, dynamic>>[],
          'plannedRecipesByDate': {recipe.id: outsidePlannedDate},
          'planWeekStartDate': planWeekStart,
        };

        final score = await factor.calculateScore(recipe, context);

        expect(score, equals(100.0)); // Outside current week → no penalty
      });
    });

    group('Signal selection — max wins, no compounding', () {
      test('uses planned signal when it is stronger than confirmed', () async {
        // confirmed 4 days ago → penalty 0.25
        // planned 1 day ahead (future) → penalty 0.7
        // Result should be 0.7 (planned), not 0.25 (confirmed), not 0.95 (both)
        final forDate = DateTime(2099, 6, 10);
        final fourDaysAgo = DateTime(2099, 6, 6);
        final tomorrow = DateTime(2099, 6, 11);

        final context = {
          'forDate': forDate,
          'recentMeals': <Map<String, dynamic>>[
            {'cookedAt': fourDaysAgo, 'recipes': [recipe]},
          ],
          'plannedRecipesByDate': {recipe.id: tomorrow},
        };

        final score = await factor.calculateScore(recipe, context);

        // Planned is stronger: 1.0 * 0.7 = 0.7 → score = 30
        expect(score, equals(30.0));
      });

      test('uses confirmed signal when it is stronger than planned', () async {
        // confirmed 1 day ago → penalty 1.0
        // planned 4 days ahead (future) → penalty 0.25 * 0.7 = 0.175
        // Result should be 1.0 (confirmed)
        final forDate = DateTime(2099, 6, 10);
        final yesterday = DateTime(2099, 6, 9);
        final fourDaysOut = DateTime(2099, 6, 14);

        final context = {
          'forDate': forDate,
          'recentMeals': <Map<String, dynamic>>[
            {'cookedAt': yesterday, 'recipes': [recipe]},
          ],
          'plannedRecipesByDate': {recipe.id: fourDaysOut},
        };

        final score = await factor.calculateScore(recipe, context);

        // Confirmed is stronger: penalty = 1.0 → score = 0
        expect(score, equals(0.0));
      });
    });

    group('Future planned meals', () {
      // forDate is in the past relative to the planned date so the planned
      // date is "after today" → future planned confidence = 0.7.
      test('1 day ahead of forDate applies 0.7 confidence penalty', () async {
        // Use a date well in the future so "today" is before plannedDate
        final forDate = DateTime(2099, 6, 10);
        final tomorrow = DateTime(2099, 6, 11);

        final context = {
          'forDate': forDate,
          'recentMeals': <Map<String, dynamic>>[],
          'plannedRecipesByDate': {recipe.id: tomorrow},
        };

        final score = await factor.calculateScore(recipe, context);

        // dist=1, penalty = 1.0 * 0.7 = 0.7 → score = 100 - 70 = 30
        expect(score, equals(30.0));
      });

      test('2 days from forDate applies decayed 0.7 confidence', () async {
        final forDate = DateTime(2099, 6, 10);
        final twoDaysOut = DateTime(2099, 6, 12);

        final context = {
          'forDate': forDate,
          'recentMeals': <Map<String, dynamic>>[],
          'plannedRecipesByDate': {recipe.id: twoDaysOut},
        };

        final score = await factor.calculateScore(recipe, context);

        // dist=2, penalty = 0.75 * 0.7 = 0.525 → score = 100 - 52.5 = 47.5
        expect(score, closeTo(47.5, 0.01));
      });
    });
  });
}
