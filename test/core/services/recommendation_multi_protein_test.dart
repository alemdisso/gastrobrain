// test/core/services/recommendation_multi_protein_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/core/services/recommendation_service.dart';
import 'package:gastrobrain/core/services/recommendation_factors/protein_rotation_factor.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/models/protein_type.dart';

import '../../mocks/mock_database_helper.dart';
import '../../test_utils/multi_ingredient_fixtures.dart';

void main() {
  group('Multi-Protein Recommendation Tests', () {
    late MockDatabaseHelper mockDbHelper;
    late RecommendationService recommendationService;
    late ProteinRotationFactor proteinFactor;

    setUp(() {
      mockDbHelper = MockDatabaseHelper();
      recommendationService = RecommendationService(
        dbHelper: mockDbHelper,
        registerDefaultFactors: true,
      );
      proteinFactor = ProteinRotationFactor();
    });

    tearDown(() {
      mockDbHelper.resetAllData();
    });

    group('Recipes with 2+ Different Protein Types', () {
      test('recipe with chicken and beef scores lower when either protein was recently used',
          () async {
        final now = DateTime.now();

        // Create a recipe with both chicken and beef
        final multiProteinRecipe = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Chicken and Beef Stir Fry',
          proteinTypes: [ProteinType.chicken, ProteinType.beef],
          vegetableCount: 6,
          otherCount: 4,
        );

        // Create a single-protein recipe with only chicken
        final chickenOnlyRecipe = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Pure Chicken Dish',
          proteinTypes: [ProteinType.chicken],
          vegetableCount: 6,
          otherCount: 4,
        );

        // Create a single-protein recipe with only fish
        final fishRecipe = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Fish Dish',
          proteinTypes: [ProteinType.fish],
          vegetableCount: 6,
          otherCount: 4,
        );

        // Cook chicken recently (1 day ago)
        await MultiIngredientFixtures.createMealHistory(
          mockDb: mockDbHelper,
          recipes: [chickenOnlyRecipe],
          daysAgo: [1],
        );

        // Create context for protein rotation
        final context = MultiIngredientFixtures.createRecommendationContext(
          mockDb: mockDbHelper,
          recentMeals: [
            {
              'recipe': chickenOnlyRecipe,
              'cookedAt': now.subtract(const Duration(days: 1)),
            }
          ],
          lastCooked: {
            chickenOnlyRecipe.id: now.subtract(const Duration(days: 1)),
          },
        );

        // Score the multi-protein recipe (has chicken, recently used)
        final multiProteinScore =
            await proteinFactor.calculateScore(multiProteinRecipe, context);

        // Score the fish recipe (no overlap with recent meals)
        final fishScore = await proteinFactor.calculateScore(fishRecipe, context);

        // Multi-protein recipe should score lower because it contains chicken
        expect(multiProteinScore, lessThan(fishScore));
      });

      test('recipe with multiple proteins gets penalized if any protein was recently used',
          () async {
        final now = DateTime.now();

        // Create recipes with different protein combinations
        final beefChickenRecipe = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Beef and Chicken',
          proteinTypes: [ProteinType.beef, ProteinType.chicken],
          vegetableCount: 5,
          otherCount: 3,
        );

        final fishPorkRecipe = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Fish and Pork',
          proteinTypes: [ProteinType.fish, ProteinType.pork],
          vegetableCount: 5,
          otherCount: 3,
        );

        // Cook a beef dish recently
        final beefRecipe = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Pure Beef',
          proteinTypes: [ProteinType.beef],
          vegetableCount: 5,
          otherCount: 3,
        );

        await MultiIngredientFixtures.createMealHistory(
          mockDb: mockDbHelper,
          recipes: [beefRecipe],
          daysAgo: [1],
        );

        final context = MultiIngredientFixtures.createRecommendationContext(
          mockDb: mockDbHelper,
          recentMeals: [
            {
              'recipe': beefRecipe,
              'cookedAt': now.subtract(const Duration(days: 1)),
            }
          ],
        );

        // Score both recipes
        final beefChickenScore =
            await proteinFactor.calculateScore(beefChickenRecipe, context);
        final fishPorkScore = await proteinFactor.calculateScore(fishPorkRecipe, context);

        // Beef+Chicken recipe should score lower because beef was recently used
        expect(beefChickenScore, lessThan(fishPorkScore));
      });

      test('recipe with three different proteins is correctly penalized', () async {
        final now = DateTime.now();

        // Create a recipe with three proteins
        final tripleProteinRecipe = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Triple Protein Bowl',
          proteinTypes: [ProteinType.chicken, ProteinType.beef, ProteinType.seafood],
          vegetableCount: 8,
          otherCount: 5,
        );

        // Create a single protein recipe
        final singleProteinRecipe = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Single Protein Dish',
          proteinTypes: [ProteinType.fish],
          vegetableCount: 8,
          otherCount: 5,
        );

        // Cook a chicken dish recently
        final chickenRecipe = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Chicken Dish',
          proteinTypes: [ProteinType.chicken],
          vegetableCount: 5,
          otherCount: 3,
        );

        await MultiIngredientFixtures.createMealHistory(
          mockDb: mockDbHelper,
          recipes: [chickenRecipe],
          daysAgo: [1],
        );

        final context = MultiIngredientFixtures.createRecommendationContext(
          mockDb: mockDbHelper,
          recentMeals: [
            {
              'recipe': chickenRecipe,
              'cookedAt': now.subtract(const Duration(days: 1)),
            }
          ],
        );

        final tripleScore =
            await proteinFactor.calculateScore(tripleProteinRecipe, context);
        final singleScore =
            await proteinFactor.calculateScore(singleProteinRecipe, context);

        // Triple protein recipe should be penalized because one of its proteins was recently used
        expect(tripleScore, lessThan(singleScore));
      });
    });

    group('Recipes with Multiple Identical Proteins (Edge Case)', () {
      test('recipe with multiple identical proteins is treated as single protein type',
          () async {
        final now = DateTime.now();

        // Create a recipe with multiple beef variations (e.g., ground beef + beef steak)
        final multipleBeefRecipe =
            await MultiIngredientFixtures.createMultipleIdenticalProteinRecipe(
          mockDb: mockDbHelper,
          name: 'Multiple Beef Variations',
          proteinType: ProteinType.beef,
          proteinVariationCount: 3,
          otherIngredientCount: 6,
        );

        // Create a recipe with single beef
        final singleBeefRecipe = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Single Beef',
          proteinTypes: [ProteinType.beef],
          vegetableCount: 5,
          otherCount: 4,
        );

        // Cook beef recently
        await MultiIngredientFixtures.createMealHistory(
          mockDb: mockDbHelper,
          recipes: [singleBeefRecipe],
          daysAgo: [1],
        );

        final context = MultiIngredientFixtures.createRecommendationContext(
          mockDb: mockDbHelper,
          recentMeals: [
            {
              'recipe': singleBeefRecipe,
              'cookedAt': now.subtract(const Duration(days: 1)),
            }
          ],
        );

        // Both should get similar penalties since they both have beef
        final multipleBeefScore =
            await proteinFactor.calculateScore(multipleBeefRecipe, context);
        final singleBeefScore =
            await proteinFactor.calculateScore(singleBeefRecipe, context);

        // Scores should be similar (within 10 points)
        expect((multipleBeefScore - singleBeefScore).abs(), lessThan(10));
      });

      test('multiple identical proteins do not compound penalty', () async {
        final now = DateTime.now();

        // Create recipe with 3x chicken ingredients
        final tripleChickenRecipe =
            await MultiIngredientFixtures.createMultipleIdenticalProteinRecipe(
          mockDb: mockDbHelper,
          name: 'Triple Chicken',
          proteinType: ProteinType.chicken,
          proteinVariationCount: 3,
          otherIngredientCount: 8,
        );

        // Create recipe with 1x chicken ingredient
        final singleChickenRecipe = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Single Chicken',
          proteinTypes: [ProteinType.chicken],
          vegetableCount: 5,
          otherCount: 3,
        );

        // Cook chicken 2 days ago
        await MultiIngredientFixtures.createMealHistory(
          mockDb: mockDbHelper,
          recipes: [singleChickenRecipe],
          daysAgo: [2],
        );

        final context = MultiIngredientFixtures.createRecommendationContext(
          mockDb: mockDbHelper,
          recentMeals: [
            {
              'recipe': singleChickenRecipe,
              'cookedAt': now.subtract(const Duration(days: 2)),
            }
          ],
        );

        final tripleScore =
            await proteinFactor.calculateScore(tripleChickenRecipe, context);
        final singleScore =
            await proteinFactor.calculateScore(singleChickenRecipe, context);

        // Both should have similar scores - penalty should not multiply
        expect((tripleScore - singleScore).abs(), lessThan(15));
      });
    });

    group('No-Protein Recipes (Vegetarian/Vegan Edge Case)', () {
      test('vegetarian recipe with no protein receives no protein penalty', () async {
        final now = DateTime.now();

        // Create a vegetarian recipe
        final vegetarianRecipe = await MultiIngredientFixtures.createVegetarianRecipe(
          mockDb: mockDbHelper,
          name: 'Vegetable Stir Fry',
          ingredientCount: 12,
        );

        // Create a protein recipe
        final proteinRecipe = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Chicken Dish',
          proteinTypes: [ProteinType.chicken],
          vegetableCount: 6,
          otherCount: 4,
        );

        // Cook chicken recently
        await MultiIngredientFixtures.createMealHistory(
          mockDb: mockDbHelper,
          recipes: [proteinRecipe],
          daysAgo: [1],
        );

        final context = MultiIngredientFixtures.createRecommendationContext(
          mockDb: mockDbHelper,
          recentMeals: [
            {
              'recipe': proteinRecipe,
              'cookedAt': now.subtract(const Duration(days: 1)),
            }
          ],
        );

        // Score both recipes
        final vegetarianScore =
            await proteinFactor.calculateScore(vegetarianRecipe, context);
        final proteinScore = await proteinFactor.calculateScore(proteinRecipe, context);

        // Vegetarian should score higher (no protein penalty)
        // Protein recipe gets penalty for recently used chicken
        expect(vegetarianScore, greaterThan(proteinScore));
      });

      test('vegetarian recipes do not affect protein rotation for other recipes',
          () async {
        final now = DateTime.now();

        // Create vegetarian and chicken recipes
        final vegetarianRecipe = await MultiIngredientFixtures.createVegetarianRecipe(
          mockDb: mockDbHelper,
          name: 'Veggie Bowl',
          ingredientCount: 10,
        );

        final chickenRecipe1 = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Chicken Dish 1',
          proteinTypes: [ProteinType.chicken],
          vegetableCount: 5,
          otherCount: 3,
        );

        final chickenRecipe2 = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Chicken Dish 2',
          proteinTypes: [ProteinType.chicken],
          vegetableCount: 5,
          otherCount: 3,
        );

        // Cook vegetarian recently, chicken 5 days ago
        await MultiIngredientFixtures.createMealHistory(
          mockDb: mockDbHelper,
          recipes: [vegetarianRecipe, chickenRecipe1],
          daysAgo: [1, 5],
        );

        final context = MultiIngredientFixtures.createRecommendationContext(
          mockDb: mockDbHelper,
          recentMeals: [
            {
              'recipe': vegetarianRecipe,
              'cookedAt': now.subtract(const Duration(days: 1)),
            },
            {
              'recipe': chickenRecipe1,
              'cookedAt': now.subtract(const Duration(days: 5)),
            }
          ],
        );

        // Second chicken recipe should have minimal penalty (5 days ago)
        final chickenScore = await proteinFactor.calculateScore(chickenRecipe2, context);

        // Should have relatively high score (only small penalty from 5 days ago)
        expect(chickenScore, greaterThan(70));
      });
    });

    group('Mixed Protein Categories (Main + Plant-Based)', () {
      test('recipe with chicken and tofu is treated as having two distinct proteins',
          () async {
        final now = DateTime.now();

        // Create a mixed protein recipe (animal + plant-based)
        final mixedProteinRecipe =
            await MultiIngredientFixtures.createMixedProteinCategoryRecipe(
          mockDb: mockDbHelper,
          name: 'Chicken and Tofu Bowl',
          mainProtein: ProteinType.chicken,
          plantProtein: ProteinType.plantBased,
          otherIngredientCount: 8,
        );

        // Create chicken-only recipe
        final chickenOnlyRecipe = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Pure Chicken',
          proteinTypes: [ProteinType.chicken],
          vegetableCount: 5,
          otherCount: 3,
        );

        // Create tofu-only recipe
        final tofuOnlyRecipe = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Pure Tofu',
          proteinTypes: [ProteinType.plantBased],
          vegetableCount: 5,
          otherCount: 3,
        );

        // Cook chicken recently
        await MultiIngredientFixtures.createMealHistory(
          mockDb: mockDbHelper,
          recipes: [chickenOnlyRecipe],
          daysAgo: [1],
        );

        final context = MultiIngredientFixtures.createRecommendationContext(
          mockDb: mockDbHelper,
          recentMeals: [
            {
              'recipe': chickenOnlyRecipe,
              'cookedAt': now.subtract(const Duration(days: 1)),
            }
          ],
        );

        // Score all three recipes
        final mixedScore = await proteinFactor.calculateScore(mixedProteinRecipe, context);
        final chickenScore =
            await proteinFactor.calculateScore(chickenOnlyRecipe, context);
        final tofuScore = await proteinFactor.calculateScore(tofuOnlyRecipe, context);

        // Mixed protein recipe should be penalized (contains chicken)
        expect(mixedScore, lessThan(tofuScore));

        // Mixed should score similarly to chicken-only (both contain recently used chicken)
        expect((mixedScore - chickenScore).abs(), lessThan(15));
      });

      test('plant-based protein is tracked independently from animal proteins',
          () async {
        final now = DateTime.now();

        // Create recipes
        final plantBasedRecipe = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Tofu Dish',
          proteinTypes: [ProteinType.plantBased],
          vegetableCount: 7,
          otherCount: 4,
        );

        final beefRecipe = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Beef Dish',
          proteinTypes: [ProteinType.beef],
          vegetableCount: 5,
          otherCount: 3,
        );

        final mixedRecipe = await MultiIngredientFixtures.createMixedProteinCategoryRecipe(
          mockDb: mockDbHelper,
          name: 'Beef and Tofu',
          mainProtein: ProteinType.beef,
          plantProtein: ProteinType.plantBased,
          otherIngredientCount: 8,
        );

        // Cook tofu recently
        await MultiIngredientFixtures.createMealHistory(
          mockDb: mockDbHelper,
          recipes: [plantBasedRecipe],
          daysAgo: [1],
        );

        final context = MultiIngredientFixtures.createRecommendationContext(
          mockDb: mockDbHelper,
          recentMeals: [
            {
              'recipe': plantBasedRecipe,
              'cookedAt': now.subtract(const Duration(days: 1)),
            }
          ],
        );

        // Score recipes
        final beefScore = await proteinFactor.calculateScore(beefRecipe, context);
        final plantScore = await proteinFactor.calculateScore(plantBasedRecipe, context);
        final mixedScore = await proteinFactor.calculateScore(mixedRecipe, context);

        // Beef should score higher (plant-based was used recently, not beef)
        expect(beefScore, greaterThan(plantScore));

        // Mixed recipe behavior: If one protein was recently used, it may get penalized
        // or it may not, depending on implementation. The key is that it shouldn't score
        // higher than beef (which has no penalty)
        expect(mixedScore, lessThanOrEqualTo(beefScore));
      });
    });

    group('Full Recommendation Integration with Multi-Protein', () {
      test('recommendation service ranks multi-protein recipes correctly', () async {
        final now = DateTime.now();

        // Create diverse recipes in the database
        await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Chicken and Beef',
          proteinTypes: [ProteinType.chicken, ProteinType.beef],
          desiredFrequency: FrequencyType.weekly,
          difficulty: 3,
          rating: 4,
        );
        await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Fish Only',
          proteinTypes: [ProteinType.fish],
          desiredFrequency: FrequencyType.weekly,
          difficulty: 3,
          rating: 4,
        );
        await MultiIngredientFixtures.createVegetarianRecipe(
          mockDb: mockDbHelper,
          name: 'Vegetarian Delight',
          desiredFrequency: FrequencyType.weekly,
        );

        // Cook chicken recently
        final chickenRecipe = await MultiIngredientFixtures.createComplexRecipe(
          mockDb: mockDbHelper,
          name: 'Pure Chicken',
          proteinTypes: [ProteinType.chicken],
        );
        await MultiIngredientFixtures.createMealHistory(
          mockDb: mockDbHelper,
          recipes: [chickenRecipe],
          daysAgo: [1],
        );

        // Get recommendations
        final recommendations = await recommendationService.getRecommendations(
          count: 3,
          forDate: now,
        );

        // Verify we got recommendations
        expect(recommendations, isNotEmpty);
        expect(recommendations.length, lessThanOrEqualTo(3));

        // The chicken+beef recipe should not be first (chicken was recently used)
        // Fish or vegetarian should rank higher
        final topRecipe = recommendations.first;
        expect(topRecipe.name, isNot(equals('Chicken and Beef')));
      });
    });
  });
}
