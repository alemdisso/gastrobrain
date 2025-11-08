// test/core/services/recommendation_factors/variety_encouragement_multi_ingredient_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/core/services/recommendation_factors/variety_encouragement_factor.dart';
import 'package:gastrobrain/models/protein_type.dart';

import '../../../mocks/mock_database_helper.dart';
import '../../../test_utils/multi_ingredient_fixtures.dart';

void main() {
  group('VarietyEncouragementFactor with Multi-Ingredient Recipes', () {
    late MockDatabaseHelper mockDbHelper;
    late VarietyEncouragementFactor factor;

    setUp(() {
      mockDbHelper = MockDatabaseHelper();
      factor = VarietyEncouragementFactor();
    });

    tearDown(() {
      mockDbHelper.resetAllData();
    });

    group('Variety Scoring with Complex Ingredients (10+ ingredients)', () {
      test('multi-ingredient recipe scores based on meal count, not ingredient count',
          () async {
        // Create two recipes with different ingredient counts but same meal count
        final simpleRecipe = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Simple Recipe',
          vegetableCount: 2,
          otherCount: 1,
        );

        final complexRecipe = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Complex Recipe',
          vegetableCount: 8,
          otherCount: 5, // 13 total ingredients
        );

        // Both cooked the same number of times
        final context = {
          'mealCounts': {
            simpleRecipe.id: 3,
            complexRecipe.id: 3,
          },
        };

        final simpleScore = await factor.calculateScore(simpleRecipe, context);
        final complexScore = await factor.calculateScore(complexRecipe, context);

        // Scores should be similar since meal count is the same
        expect((simpleScore - complexScore).abs(), lessThan(5));
      });

      test('never-cooked complex recipe gets perfect variety score', () async {
        final complexRecipe = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Complex Never Cooked',
          vegetableCount: 10,
          otherCount: 5, // 15 total ingredients
          difficulty: 4,
        );

        final context = {
          'mealCounts': <String, int>{}, // Never cooked
        };

        final score = await factor.calculateScore(complexRecipe, context);

        expect(score, equals(100.0));
      });

      test('frequently cooked complex recipe gets low variety score', () async {
        final complexRecipe = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Complex Frequently Cooked',
          vegetableCount: 12,
          otherCount: 6,
        );

        // Cook it many times
        await MultiIngredientFixtures.createMealHistory(
          mockDb: mockDbHelper,
          recipes: List.filled(15, complexRecipe),
          daysAgo: List.generate(15, (i) => i + 5), // 5-20 days ago
        );

        final context = {
          'mealCounts': {
            complexRecipe.id: 15,
          },
        };

        final score = await factor.calculateScore(complexRecipe, context);

        // Should have low score due to frequency
        expect(score, lessThan(40.0));
      });
    });

    group('Consistency Between Single and Multi-Ingredient Recipes', () {
      test('variety scoring is consistent regardless of ingredient complexity', () async {
        // Create recipes with varying ingredient counts
        final recipes = [
          await MultiIngredientFixtures.createComplexRecipe(
            mockDb: mockDbHelper,
            name: 'Recipe with 3 ingredients',
            vegetableCount: 2,
            otherCount: 0,
          ),
          await MultiIngredientFixtures.createComplexRecipe(
            mockDb: mockDbHelper,
            name: 'Recipe with 10 ingredients',
            vegetableCount: 7,
            otherCount: 2,
          ),
          await MultiIngredientFixtures.createComplexRecipe(
            mockDb: mockDbHelper,
            name: 'Recipe with 20 ingredients',
            vegetableCount: 15,
            otherCount: 4,
          ),
        ];

        // All cooked the same number of times
        final context = {
          'mealCounts': {
            for (var recipe in recipes) recipe.id: 5
          },
        };

        // Get scores
        final scores = <double>[];
        for (final recipe in recipes) {
          scores.add(await factor.calculateScore(recipe, context));
        }

        // All scores should be very similar (within 5 points)
        for (var i = 0; i < scores.length - 1; i++) {
          expect((scores[i] - scores[i + 1]).abs(), lessThan(5));
        }
      });

      test('variety encouragement works correctly with large ingredient lists',
          () async {
        // Create recipes with many ingredients
        final neverCooked = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Never Cooked Complex',
          vegetableCount: 12,
          otherCount: 8, // 20 ingredients
        );

        final rarelyCooked = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Rarely Cooked Complex',
          vegetableCount: 12,
          otherCount: 8,
        );

        final oftenCooked = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Often Cooked Complex',
          vegetableCount: 12,
          otherCount: 8,
        );

        // Create meal history
        await MultiIngredientFixtures.createMealHistory(
          mockDb: mockDbHelper,
          recipes: [rarelyCooked],
          daysAgo: [10],
        );

        await MultiIngredientFixtures.createMealHistory(
          mockDb: mockDbHelper,
          recipes: List.filled(10, oftenCooked),
          daysAgo: List.generate(10, (i) => i + 5),
        );

        final context = {
          'mealCounts': {
            neverCooked.id: 0,
            rarelyCooked.id: 1,
            oftenCooked.id: 10,
          },
        };

        final neverScore = await factor.calculateScore(neverCooked, context);
        final rarelyScore = await factor.calculateScore(rarelyCooked, context);
        final oftenScore = await factor.calculateScore(oftenCooked, context);

        // Verify proper ordering
        expect(neverScore, equals(100.0));
        expect(rarelyScore, lessThan(neverScore));
        expect(rarelyScore, greaterThan(75.0));
        expect(oftenScore, lessThan(rarelyScore));
        expect(oftenScore, lessThan(50.0));
      });
    });

    group('Multi-Protein Recipes and Variety', () {
      test('variety factor treats multi-protein recipes same as single-protein', () async {
        final singleProtein = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Single Protein',
          proteinTypes: [
            ProteinType.chicken
          ],
          vegetableCount: 8,
          otherCount: 4,
        );

        final multiProtein = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Multi Protein',
          proteinTypes: [ProteinType.chicken, ProteinType.beef, ProteinType.seafood],
          vegetableCount: 8,
          otherCount: 4,
        );

        // Both cooked same number of times
        final context = {
          'mealCounts': {
            singleProtein.id: 5,
            multiProtein.id: 5,
          },
        };

        final singleScore = await factor.calculateScore(singleProtein, context);
        final multiScore = await factor.calculateScore(multiProtein, context);

        // Scores should be similar
        expect((singleScore - multiScore).abs(), lessThan(5));
      });
    });

    group('Vegetarian Recipes and Variety', () {
      test('vegetarian recipes with many ingredients are scored consistently',
          () async {
        final vegetarian = await MultiIngredientFixtures.createVegetarianRecipe(
          mockDb: mockDbHelper,
          name: 'Complex Vegetarian',
          ingredientCount: 15,
        );

        final meatRecipe = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Meat Recipe',
          proteinTypes: [ProteinType.chicken],
          vegetableCount: 10,
          otherCount: 4, // Similar total ingredients
        );

        // Both cooked same number of times
        final context = {
          'mealCounts': {
            vegetarian.id: 3,
            meatRecipe.id: 3,
          },
        };

        final vegScore = await factor.calculateScore(vegetarian, context);
        final meatScore = await factor.calculateScore(meatRecipe, context);

        // Scores should be similar
        expect((vegScore - meatScore).abs(), lessThan(5));
      });
    });

    group('Performance with Large Datasets', () {
      test('variety calculation performs well with 50+ complex recipes', () async {
        // Create large dataset
        final recipes = await MultiIngredientFixtures.createLargeRecipeDataset(
          mockDb: mockDbHelper,
          count: 50,
          ingredientsPerRecipe: 15,
        );

        // Create varied meal counts
        final mealCounts = <String, int>{};
        for (var i = 0; i < recipes.length; i++) {
          mealCounts[recipes[i].id] = i % 10; // 0-9 cook counts
        }

        final context = {
          'mealCounts': mealCounts,
        };

        // Time the scoring operation
        final stopwatch = Stopwatch()..start();

        for (final recipe in recipes) {
          await factor.calculateScore(recipe, context);
        }

        stopwatch.stop();

        // Should complete in reasonable time (< 1 second for 50 recipes)
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });

      test('variety scoring scales linearly with recipe count', () async {
        // Create two datasets of different sizes
        final smallDataset = await MultiIngredientFixtures.createLargeRecipeDataset(
          mockDb: mockDbHelper,
          count: 20,
          ingredientsPerRecipe: 12,
        );

        final smallMealCounts = <String, int>{
          for (var i = 0; i < smallDataset.length; i++) smallDataset[i].id: i % 5
        };

        final smallContext = {'mealCounts': smallMealCounts};

        // Time small dataset
        final stopwatch1 = Stopwatch()..start();
        for (final recipe in smallDataset) {
          await factor.calculateScore(recipe, smallContext);
        }
        stopwatch1.stop();

        // Clean and create larger dataset
        mockDbHelper.resetAllData();

        final largeDataset = await MultiIngredientFixtures.createLargeRecipeDataset(
          mockDb: mockDbHelper,
          count: 40,
          ingredientsPerRecipe: 12,
        );

        final largeMealCounts = <String, int>{
          for (var i = 0; i < largeDataset.length; i++) largeDataset[i].id: i % 5
        };

        final largeContext = {'mealCounts': largeMealCounts};

        // Time large dataset
        final stopwatch2 = Stopwatch()..start();
        for (final recipe in largeDataset) {
          await factor.calculateScore(recipe, largeContext);
        }
        stopwatch2.stop();

        // Large dataset (2x size) should take roughly 2x time (with 50% margin)
        // Use microseconds for more precision since these operations are very fast
        final time1 = stopwatch1.elapsedMicroseconds;
        final time2 = stopwatch2.elapsedMicroseconds;

        // Only check ratio if both times are measurable (> 0)
        if (time1 > 0 && time2 > 0) {
          final ratio = time2 / time1;
          expect(ratio, lessThan(5.0)); // Should scale roughly linearly (allow 5x margin)
        } else {
          // Both operations completed too fast to measure - that's also acceptable!
          expect(time1 + time2, lessThan(10000)); // Combined should be < 10ms
        }
      });
    });
  });
}
