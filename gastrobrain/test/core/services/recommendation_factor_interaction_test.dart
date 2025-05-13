// test/core/services/recommendation_factor_interaction_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/core/services/recommendation_service.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/meal.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/models/protein_type.dart';
import 'package:gastrobrain/utils/id_generator.dart';

import '../../mocks/mock_database_helper.dart';

void main() {
  group('Recommendation Factor Interactions', () {
    late MockDatabaseHelper mockDbHelper;
    late RecommendationService recommendationService;

    setUp(() {
      // Create a fresh mock database for each test
      mockDbHelper = MockDatabaseHelper();

      // Create and initialize a recommendation service with our mock
      recommendationService = RecommendationService(
        dbHelper: mockDbHelper,
        registerDefaultFactors: true,
      );
    });

    tearDown(() {
      // Clean up after each test
      mockDbHelper.resetAllData();
    });

    test('protein rotation balances with frequency factor', () async {
      // Arrange: Create test scenarios
      final now = DateTime.now();

      // 1. Recipe with overdue frequency (high frequency score) but recently used protein (low protein score)
      final overduePoorProteinRecipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Overdue Recipe with Recent Protein',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 3, // Neutral rating
      );

      // 2. Recipe with not-yet-due frequency (medium frequency score) but unused protein (high protein score)
      final notDueGoodProteinRecipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Not Due Recipe with Fresh Protein',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 3, // Same rating to isolate factor effects
      );

      // Add recipes to mock database
      await mockDbHelper.insertRecipe(overduePoorProteinRecipe);
      await mockDbHelper.insertRecipe(notDueGoodProteinRecipe);

      // Set up protein types for the recipes
      mockDbHelper.recipeProteinTypes = {
        overduePoorProteinRecipe.id: [ProteinType.beef],
        notDueGoodProteinRecipe.id: [ProteinType.chicken],
      };

      // Create cooking history:
      // 1. Overdue recipe was cooked 3 weeks ago (should have high frequency score)
      final overdueMeal = Meal(
        id: IdGenerator.generateId(),
        recipeId: overduePoorProteinRecipe.id,
        cookedAt: now.subtract(const Duration(days: 21)), // 3 weeks ago
        servings: 2,
      );

      // 2. Not-due recipe was cooked 3 days ago (should have low/medium frequency score)
      final recentMeal = Meal(
        id: IdGenerator.generateId(),
        recipeId: notDueGoodProteinRecipe.id,
        cookedAt: now.subtract(const Duration(days: 3)), // 3 days ago
        servings: 2,
      );

      await mockDbHelper.insertMeal(overdueMeal);
      await mockDbHelper.insertMeal(recentMeal);

      // Create a recent beef meal (not using our test recipes) to penalize beef protein
      final beefProteinMeal = Meal(
        id: IdGenerator.generateId(),
        recipeId: 'other-beef-recipe',
        cookedAt: now.subtract(const Duration(days: 1)), // Yesterday
        servings: 2,
      );

      await mockDbHelper.insertMeal(beefProteinMeal);

      // Create a recipe for our beef meal
      final otherBeefRecipe = Recipe(
        id: 'other-beef-recipe',
        name: 'Other Beef Recipe',
        createdAt: now,
        desiredFrequency: FrequencyType.weekly,
      );

      // Add it to the mock database
      await mockDbHelper.insertRecipe(otherBeefRecipe);

      // Make sure it has the beef protein type in our mock
      mockDbHelper.recipeProteinTypes['other-beef-recipe'] = [ProteinType.beef];

      // Set up the context with beef protein used recently
      recommendationService.overrideTestContext = {
        'proteinTypes': mockDbHelper.recipeProteinTypes,
        'recentMeals': [
          {
            'recipe': otherBeefRecipe,
            'cookedAt': now.subtract(const Duration(days: 1)), // Yesterday
          }
        ],
        'lastCooked': {
          overduePoorProteinRecipe.id: now.subtract(const Duration(days: 21)),
          notDueGoodProteinRecipe.id: now.subtract(const Duration(days: 3)),
          'other-beef-recipe': now.subtract(const Duration(days: 1)),
        },
        'mealCounts': {
          overduePoorProteinRecipe.id: 1,
          notDueGoodProteinRecipe.id: 1,
          'other-beef-recipe': 1,
        },
      };
      // Act: Get detailed recommendations with factor scores
      final results = await recommendationService.getDetailedRecommendations();

      // Filter to only our two test recipes
      final testRecipeRecommendations = results.recommendations
          .where((rec) =>
              rec.recipe.id == overduePoorProteinRecipe.id ||
              rec.recipe.id == notDueGoodProteinRecipe.id)
          .toList();

      // Assert: We should have our two test recipes
      expect(testRecipeRecommendations.length, 2,
          reason: "Should find both test recipes in recommendations");

      // Map recipe IDs to their recommendations for easier access
      final recommendationsMap = {
        for (var rec in testRecipeRecommendations) rec.recipe.id: rec
      };
      // Get factor scores for both recipes
      final overduePoorProteinScores =
          recommendationsMap[overduePoorProteinRecipe.id]!.factorScores;
      final notDueGoodProteinScores =
          recommendationsMap[notDueGoodProteinRecipe.id]!.factorScores;

      // Verify frequency scores reflect our setup
      expect(overduePoorProteinScores['frequency']!, greaterThan(85),
          reason: "Overdue recipe should have high frequency score (>85)");
      expect(notDueGoodProteinScores['frequency']!, lessThan(85),
          reason: "Recent recipe should have lower frequency score (<85)");

      // Verify protein scores reflect our setup
      expect(overduePoorProteinScores['protein_rotation']!, lessThan(50),
          reason: "Recently used protein should have low protein score (<50)");
      expect(notDueGoodProteinScores['protein_rotation']!, greaterThan(75),
          reason: "Unused protein should have high protein score (>75)");

      // Compare total scores - with our default weights:
      // - Frequency: 40% weight
      // - Protein Rotation: 30% weight
      // - Rating: 15% weight
      // The outcome could go either way depending on the exact scores, but that's exactly
      // what we want to test - how these factors balance each other

      // The test itself doesn't assert which should win - it's testing that both factors
      // have visible influence on the total score
    });

    test('critical protein repetition can override frequency preference',
        () async {
      // Arrange: Create an extreme case
      final now = DateTime.now();

      // Recipe A: Slightly overdue (good frequency score) but used protein yesterday (terrible protein score)
      final overduePoorProteinRecipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Slightly Overdue Recipe with Recent Protein',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 3, // Neutral rating
      );

      // Recipe B: Not quite due (moderate frequency score) but protein not used recently (great protein score)
      final notDueGoodProteinRecipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Recently Cooked Recipe with Fresh Protein',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 3, // Same rating to isolate factor effects
      );

      // Add recipes to mock database
      await mockDbHelper.insertRecipe(overduePoorProteinRecipe);
      await mockDbHelper.insertRecipe(notDueGoodProteinRecipe);

      // Set up protein types - Recipe A uses beef, Recipe B uses fish
      mockDbHelper.recipeProteinTypes = {
        overduePoorProteinRecipe.id: [ProteinType.beef],
        notDueGoodProteinRecipe.id: [ProteinType.fish],
      };

      // Create cooking history with very specific timings:
      // Recipe A: Cooked 10 days ago (slightly overdue for weekly frequency)
      final slightlyOverdueMeal = Meal(
        id: IdGenerator.generateId(),
        recipeId: overduePoorProteinRecipe.id,
        cookedAt: now.subtract(const Duration(days: 10)), // 10 days ago
        servings: 2,
      );

      // Recipe B: Cooked 5 days ago (not quite due yet for weekly frequency)
      final recentMeal = Meal(
        id: IdGenerator.generateId(),
        recipeId: notDueGoodProteinRecipe.id,
        cookedAt: now.subtract(const Duration(days: 5)), // 5 days ago
        servings: 2,
      );

      await mockDbHelper.insertMeal(slightlyOverdueMeal);
      await mockDbHelper.insertMeal(recentMeal);

      // Create a recipe for our recent beef meal to establish protein penalty
      final yesterdayBeefRecipe = Recipe(
        id: 'yesterday-beef-recipe',
        name: 'Yesterday Beef Recipe',
        createdAt: now,
        desiredFrequency: FrequencyType.weekly,
      );

      // Add it to the mock database
      await mockDbHelper.insertRecipe(yesterdayBeefRecipe);

      // Make sure it has the beef protein type in our mock
      mockDbHelper.recipeProteinTypes['yesterday-beef-recipe'] = [
        ProteinType.beef
      ];

      // Create a meal with beef just yesterday to create a severe protein penalty
      final yesterdayBeefMeal = Meal(
        id: IdGenerator.generateId(),
        recipeId: yesterdayBeefRecipe.id,
        cookedAt: now.subtract(const Duration(days: 1)), // Just yesterday
        servings: 2,
      );

      await mockDbHelper.insertMeal(yesterdayBeefMeal);

// Unregister the randomization factor to ensure deterministic results
      recommendationService.unregisterFactor('randomization');

// Add fixed seed for any remaining randomness
      recommendationService.overrideTestContext = {
        'proteinTypes': mockDbHelper.recipeProteinTypes,
        'recentMeals': [
          {
            'recipe': yesterdayBeefRecipe,
            'cookedAt': now.subtract(const Duration(days: 1)), // Yesterday
          }
        ],
        'lastCooked': {
          overduePoorProteinRecipe.id: now.subtract(const Duration(days: 10)),
          notDueGoodProteinRecipe.id: now.subtract(const Duration(days: 5)),
          'yesterday-beef-recipe': now.subtract(const Duration(days: 1)),
        },
        'mealCounts': {
          overduePoorProteinRecipe.id: 1,
          notDueGoodProteinRecipe.id: 1,
          'yesterday-beef-recipe': 1,
        },
        'randomSeed': 42, // Add a fixed seed for deterministic results
      };

      // Act: Get detailed recommendations
      final results = await recommendationService.getDetailedRecommendations();

      // Filter to only our two test recipes
      final testRecipeRecommendations = results.recommendations
          .where((rec) =>
              rec.recipe.id == overduePoorProteinRecipe.id ||
              rec.recipe.id == notDueGoodProteinRecipe.id)
          .toList();

      // Make sure both recipes are in the results
      expect(testRecipeRecommendations.length, 2,
          reason: "Should find both test recipes in recommendations");

      // Get individual recommendations
      final overduePoorProteinRec = testRecipeRecommendations
          .firstWhere((rec) => rec.recipe.id == overduePoorProteinRecipe.id);
      final notDueGoodProteinRec = testRecipeRecommendations
          .firstWhere((rec) => rec.recipe.id == notDueGoodProteinRecipe.id);

      // Get factor scores
      final overduePoorProteinScores = overduePoorProteinRec.factorScores;
      final notDueGoodProteinScores = notDueGoodProteinRec.factorScores;

      // Log detailed scores

      // Verify recipe B (not overdue but fresh protein) ranks higher than recipe A
      // (slightly overdue but yesterday's protein) in this extreme case
      expect(notDueGoodProteinRec.totalScore > overduePoorProteinRec.totalScore,
          isTrue,
          reason:
              "Fresh protein recipe should outrank yesterday's protein, even though the latter is more overdue");

      // Verify the specific factor scores match our expectations
      // Recipe A: Frequency score should be good (>75) but protein score should be very poor (<20)
      expect(overduePoorProteinScores['frequency']!, greaterThan(75),
          reason: "Slightly overdue recipe should have good frequency score");
      expect(overduePoorProteinScores['protein_rotation']!, lessThan(20),
          reason:
              "Recipe with yesterday's protein should have terrible protein score");

      // Recipe B: Frequency score should be moderate (40-70) but protein score should be excellent (>90)
      expect(notDueGoodProteinScores['frequency']!, inInclusiveRange(40, 70),
          reason: "Not-quite-due recipe should have moderate frequency score");
      expect(notDueGoodProteinScores['protein_rotation']!, greaterThan(90),
          reason:
              "Recipe with unused protein should have excellent protein score");
    });
  });
}
