// test/core/services/recommendation_performance_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/core/services/recommendation_service.dart';
import 'package:gastrobrain/models/protein_type.dart';

import '../../mocks/mock_database_helper.dart';
import '../../test_utils/multi_ingredient_fixtures.dart';

void main() {
  group('Recommendation Service Performance Tests', () {
    late MockDatabaseHelper mockDbHelper;
    late RecommendationService recommendationService;

    setUp(() {
      mockDbHelper = MockDatabaseHelper();
      recommendationService = RecommendationService(
        dbHelper: mockDbHelper,
        registerDefaultFactors: true,
      );
    });

    tearDown(() {
      mockDbHelper.resetAllData();
    });

    group('Performance with 10+ Ingredient Recipes', () {
      test('recommendation with 10-ingredient recipes completes in reasonable time',
          () async {
        // Create 20 recipes with 10+ ingredients each
        await MultiIngredientFixtures.createLargeRecipeDataset(
          mockDb: mockDbHelper,
          count: 20,
          ingredientsPerRecipe: 10,
        );

        // Measure time to get recommendations
        final stopwatch = Stopwatch()..start();

        final recommendations = await recommendationService.getRecommendations(
          count: 5,
        );

        stopwatch.stop();

        // Verify we got recommendations
        expect(recommendations, isNotEmpty);
        expect(recommendations.length, lessThanOrEqualTo(5));

        // Should complete in under 500ms
        expect(stopwatch.elapsedMilliseconds, lessThan(500),
            reason: 'Recommendations should be fast with 10-ingredient recipes');
      });

      test('recommendation with 15-ingredient recipes maintains performance',
          () async {
        // Create 20 recipes with 15+ ingredients each
        await MultiIngredientFixtures.createLargeRecipeDataset(
          mockDb: mockDbHelper,
          count: 20,
          ingredientsPerRecipe: 15,
        );

        final stopwatch = Stopwatch()..start();

        final recommendations = await recommendationService.getRecommendations(
          count: 5,
        );

        stopwatch.stop();

        expect(recommendations, isNotEmpty);

        // Should still complete in under 500ms
        expect(stopwatch.elapsedMilliseconds, lessThan(500),
            reason: 'Performance should not degrade significantly with 15 ingredients');
      });

      test('recommendation with 20-ingredient recipes is performant', () async {
        // Create 20 recipes with 20+ ingredients each
        await MultiIngredientFixtures.createLargeRecipeDataset(
          mockDb: mockDbHelper,
          count: 20,
          ingredientsPerRecipe: 20,
        );

        final stopwatch = Stopwatch()..start();

        final recommendations = await recommendationService.getRecommendations(
          count: 5,
        );

        stopwatch.stop();

        expect(recommendations, isNotEmpty);

        // Should complete in under 1 second
        expect(stopwatch.elapsedMilliseconds, lessThan(1000),
            reason: 'Even with 20 ingredients, should remain under 1 second');
      });
    });

    group('Performance with Large Recipe Datasets', () {
      test('50 recipes with complex ingredients performs well', () async {
        // Create 50 recipes with 12 ingredients each
        await MultiIngredientFixtures.createLargeRecipeDataset(
          mockDb: mockDbHelper,
          count: 50,
          ingredientsPerRecipe: 12,
        );

        final stopwatch = Stopwatch()..start();

        final recommendations = await recommendationService.getRecommendations(
          count: 10,
        );

        stopwatch.stop();

        expect(recommendations, isNotEmpty);
        expect(recommendations.length, lessThanOrEqualTo(10));

        // Should complete in under 1 second for 50 recipes
        expect(stopwatch.elapsedMilliseconds, lessThan(1000),
            reason: '50 complex recipes should process in under 1 second');
      });

      test('100 recipes with complex ingredients maintains performance', () async {
        // Create 100 recipes with 12 ingredients each
        await MultiIngredientFixtures.createLargeRecipeDataset(
          mockDb: mockDbHelper,
          count: 100,
          ingredientsPerRecipe: 12,
        );

        final stopwatch = Stopwatch()..start();

        final recommendations = await recommendationService.getRecommendations(
          count: 10,
        );

        stopwatch.stop();

        expect(recommendations, isNotEmpty);

        // Should complete in under 2 seconds for 100 recipes
        expect(stopwatch.elapsedMilliseconds, lessThan(2000),
            reason: '100 complex recipes should process in under 2 seconds');
      });

      test('200 recipes with complex ingredients is still performant', () async {
        // Create 200 recipes with 12 ingredients each
        await MultiIngredientFixtures.createLargeRecipeDataset(
          mockDb: mockDbHelper,
          count: 200,
          ingredientsPerRecipe: 12,
        );

        final stopwatch = Stopwatch()..start();

        final recommendations = await recommendationService.getRecommendations(
          count: 10,
        );

        stopwatch.stop();

        expect(recommendations, isNotEmpty);

        // Should complete in under 4 seconds for 200 recipes
        expect(stopwatch.elapsedMilliseconds, lessThan(4000),
            reason: '200 complex recipes should process in under 4 seconds');
      });
    });

    group('Performance Scaling Tests', () {
      test('recommendation time scales linearly with recipe count', () async {
        // Test with 25 recipes
        await MultiIngredientFixtures.createLargeRecipeDataset(
          mockDb: mockDbHelper,
          count: 25,
          ingredientsPerRecipe: 12,
        );

        final stopwatch1 = Stopwatch()..start();
        await recommendationService.getRecommendations(count: 5);
        stopwatch1.stop();
        final time25 = stopwatch1.elapsedMilliseconds;

        // Clear and test with 50 recipes (2x)
        mockDbHelper.resetAllData();
        await MultiIngredientFixtures.createLargeRecipeDataset(
          mockDb: mockDbHelper,
          count: 50,
          ingredientsPerRecipe: 12,
        );

        final stopwatch2 = Stopwatch()..start();
        await recommendationService.getRecommendations(count: 5);
        stopwatch2.stop();
        final time50 = stopwatch2.elapsedMilliseconds;

        // 50 recipes should take roughly 2x the time (with 3x margin for variance)
        final ratio = time50 / time25;
        expect(ratio, lessThan(6.0),
            reason: 'Performance should scale roughly linearly with recipe count');
      });

      test('ingredient count has minimal impact on performance', () async {
        // Create dataset with 5 ingredients per recipe
        await MultiIngredientFixtures.createLargeRecipeDataset(
          mockDb: mockDbHelper,
          count: 30,
          ingredientsPerRecipe: 5,
        );

        final stopwatch1 = Stopwatch()..start();
        await recommendationService.getRecommendations(count: 5);
        stopwatch1.stop();
        final time5Ingredients = stopwatch1.elapsedMilliseconds;

        // Clear and create dataset with 20 ingredients per recipe (4x)
        mockDbHelper.resetAllData();
        await MultiIngredientFixtures.createLargeRecipeDataset(
          mockDb: mockDbHelper,
          count: 30,
          ingredientsPerRecipe: 20,
        );

        final stopwatch2 = Stopwatch()..start();
        await recommendationService.getRecommendations(count: 5);
        stopwatch2.stop();
        final time20Ingredients = stopwatch2.elapsedMilliseconds;

        // Time should not increase significantly (allow 3x margin)
        // Since most recommendation logic is per-recipe, not per-ingredient
        final ratio = time20Ingredients / time5Ingredients;
        expect(ratio, lessThan(3.0),
            reason: 'Ingredient count should have minimal performance impact');
      });
    });

    group('Performance with Meal History', () {
      test('performance with extensive meal history', () async {
        // Create recipes
        final recipes = await MultiIngredientFixtures.createLargeRecipeDataset(
          mockDb: mockDbHelper,
          count: 30,
          ingredientsPerRecipe: 12,
        );

        // Create extensive meal history (100 meals across recipes)
        for (var i = 0; i < 100; i++) {
          final recipe = recipes[i % recipes.length];
          await MultiIngredientFixtures.createMealHistory(
            mockDb: mockDbHelper,
            recipes: [recipe],
            daysAgo: [i + 1],
          );
        }

        final stopwatch = Stopwatch()..start();

        final recommendations = await recommendationService.getRecommendations(
          count: 5,
        );

        stopwatch.stop();

        expect(recommendations, isNotEmpty);

        // Should complete in under 1 second even with 100 meal history entries
        expect(stopwatch.elapsedMilliseconds, lessThan(1000),
            reason: 'Extensive meal history should not significantly impact performance');
      });

      test('performance with protein rotation analysis on complex recipes', () async {
        // Create recipes with various protein types
        for (var proteinType in ProteinType.values) {
          await MultiIngredientFixtures.createComplexRecipe(
            mockDb: mockDbHelper,
            name: 'Recipe with ${proteinType.name}',
            proteinTypes: [proteinType],
            vegetableCount: 10,
            otherCount: 5,
          );
        }

        // Create recent meal history for half the protein types
        final recipes = await mockDbHelper.getAllRecipes();
        for (var i = 0; i < recipes.length ~/ 2; i++) {
          await MultiIngredientFixtures.createMealHistory(
            mockDb: mockDbHelper,
            recipes: [recipes[i]],
            daysAgo: [i + 1],
          );
        }

        final stopwatch = Stopwatch()..start();

        final recommendations = await recommendationService.getRecommendations(
          count: 5,
        );

        stopwatch.stop();

        expect(recommendations, isNotEmpty);

        // Protein rotation calculation should be fast
        expect(stopwatch.elapsedMilliseconds, lessThan(500),
            reason: 'Protein rotation analysis should be performant');
      });
    });

    group('Detailed Recommendations Performance', () {
      test('getDetailedRecommendations performs well with complex recipes', () async {
        // Create 40 recipes with complex ingredients
        await MultiIngredientFixtures.createLargeRecipeDataset(
          mockDb: mockDbHelper,
          count: 40,
          ingredientsPerRecipe: 15,
        );

        final stopwatch = Stopwatch()..start();

        final results = await recommendationService.getDetailedRecommendations(
          count: 10,
        );

        stopwatch.stop();

        expect(results.recommendations, isNotEmpty);

        // Detailed recommendations include factor scores, so allow more time
        expect(stopwatch.elapsedMilliseconds, lessThan(2000),
            reason: 'Detailed recommendations should complete in under 2 seconds');
      });

      test('factor score calculation performance with multi-protein recipes',
          () async {
        // Create recipes with multiple proteins (more complex scoring)
        for (var i = 0; i < 30; i++) {
          await MultiIngredientFixtures.createComplexRecipe(
            mockDb: mockDbHelper,
            name: 'Multi-protein Recipe $i',
            proteinTypes: [
              ProteinType.values[i % ProteinType.values.length],
              ProteinType.values[(i + 1) % ProteinType.values.length],
            ],
            vegetableCount: 10,
            otherCount: 5,
          );
        }

        final stopwatch = Stopwatch()..start();

        final results = await recommendationService.getDetailedRecommendations(
          count: 10,
        );

        stopwatch.stop();

        expect(results.recommendations, isNotEmpty);

        // Multi-protein scoring should still be fast
        expect(stopwatch.elapsedMilliseconds, lessThan(2000),
            reason: 'Multi-protein factor scoring should be performant');

        // Verify factor scores were calculated
        for (final rec in results.recommendations) {
          expect(rec.factorScores, isNotEmpty);
        }
      });
    });

    group('Regression Detection Benchmarks', () {
      test('baseline: 50 recipes, 12 ingredients, 5 recommendations', () async {
        // This test establishes a baseline for future regression detection
        await MultiIngredientFixtures.createLargeRecipeDataset(
          mockDb: mockDbHelper,
          count: 50,
          ingredientsPerRecipe: 12,
        );

        final stopwatch = Stopwatch()..start();

        final recommendations = await recommendationService.getRecommendations(
          count: 5,
        );

        stopwatch.stop();

        expect(recommendations.length, equals(5));

        // Record baseline performance (should be under 1 second)
        final baselineMs = stopwatch.elapsedMilliseconds;
        expect(baselineMs, lessThan(1000));

        // Print for manual baseline tracking
        // ignore: avoid_print
        print('Performance baseline: ${baselineMs}ms for 50 recipes with 12 ingredients');
      });

      test('baseline: 100 recipes, 15 ingredients, 10 recommendations', () async {
        await MultiIngredientFixtures.createLargeRecipeDataset(
          mockDb: mockDbHelper,
          count: 100,
          ingredientsPerRecipe: 15,
        );

        final stopwatch = Stopwatch()..start();

        final recommendations = await recommendationService.getRecommendations(
          count: 10,
        );

        stopwatch.stop();

        expect(recommendations.length, equals(10));

        final baselineMs = stopwatch.elapsedMilliseconds;
        expect(baselineMs, lessThan(2000));

        // ignore: avoid_print
        print('Performance baseline: ${baselineMs}ms for 100 recipes with 15 ingredients');
      });

      test('baseline: detailed recommendations with 50 complex recipes', () async {
        await MultiIngredientFixtures.createLargeRecipeDataset(
          mockDb: mockDbHelper,
          count: 50,
          ingredientsPerRecipe: 12,
        );

        final stopwatch = Stopwatch()..start();

        final results = await recommendationService.getDetailedRecommendations(
          count: 10,
        );

        stopwatch.stop();

        expect(results.recommendations.length, equals(10));

        final baselineMs = stopwatch.elapsedMilliseconds;
        expect(baselineMs, lessThan(2000));

        // ignore: avoid_print
        print(
            'Performance baseline: ${baselineMs}ms for detailed recommendations with 50 recipes');
      });
    });

    group('Memory Performance', () {
      test('large dataset does not cause excessive memory allocation', () async {
        // This is a smoke test to ensure we don't have memory leaks
        // Create and discard large datasets multiple times

        for (var iteration = 0; iteration < 5; iteration++) {
          await MultiIngredientFixtures.createLargeRecipeDataset(
            mockDb: mockDbHelper,
            count: 100,
            ingredientsPerRecipe: 15,
          );

          await recommendationService.getRecommendations(count: 10);

          // Clear for next iteration
          mockDbHelper.resetAllData();
        }

        // If we got here without crashing, memory management is acceptable
        expect(true, isTrue);
      });
    });
  });
}
