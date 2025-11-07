// ignore_for_file: unused_local_variable

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/core/services/recommendation_service.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/models/protein_type.dart';

import '../../mocks/mock_database_helper.dart';

void main() {
  group('Recommendation Advanced Filtering', () {
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

    test('excludeIds filter removes specified recipes from recommendations',
        () async {
      // Arrange: Create several recipes
      final now = DateTime.now();

      final recipe1 = Recipe(
        id: 'test-recipe-1',
        name: 'Test Recipe 1',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 4,
      );

      final recipe2 = Recipe(
        id: 'test-recipe-2',
        name: 'Test Recipe 2',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 4,
      );

      final recipe3 = Recipe(
        id: 'test-recipe-3',
        name: 'Test Recipe 3',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 4,
      );

      // Add recipes to mock database
      await mockDbHelper.insertRecipe(recipe1);
      await mockDbHelper.insertRecipe(recipe2);
      await mockDbHelper.insertRecipe(recipe3);

      // Create a simple context
      recommendationService.overrideTestContext = {
        'lastCooked': <String, DateTime>{},
        'mealCounts': <String, int>{},
        'proteinTypes': <String, Set<ProteinType>>{},
        'recentMeals': <Map<String, dynamic>>[],
      };

      // Act: Get recommendations excluding recipe2
      final results = await recommendationService.getRecommendations(
        excludeIds: ['test-recipe-2'],
      );

      // Assert: result should contain recipe1 and recipe3, but not recipe2
      expect(results.length, 2);
      expect(results.any((r) => r.id == 'test-recipe-1'), isTrue);
      expect(results.any((r) => r.id == 'test-recipe-2'), isFalse);
      expect(results.any((r) => r.id == 'test-recipe-3'), isTrue);
    });

    test('avoidProteinTypes filter excludes recipes with specified proteins',
        () async {
      // Arrange: Create recipes with different protein types
      final now = DateTime.now();

      final beefRecipe = Recipe(
        id: 'beef-recipe',
        name: 'Beef Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 4,
      );

      final chickenRecipe = Recipe(
        id: 'chicken-recipe',
        name: 'Chicken Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 4,
      );

      final fishRecipe = Recipe(
        id: 'fish-recipe',
        name: 'Fish Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 4,
      );

      // Add recipes to mock database
      await mockDbHelper.insertRecipe(beefRecipe);
      await mockDbHelper.insertRecipe(chickenRecipe);
      await mockDbHelper.insertRecipe(fishRecipe);

      // Set up protein types in the mock database
      mockDbHelper.recipeProteinTypes = {
        'beef-recipe': [ProteinType.beef],
        'chicken-recipe': [ProteinType.chicken],
        'fish-recipe': [ProteinType.fish],
      };

      // Create recommendation service with protein types override
      recommendationService = RecommendationService(
        dbHelper: mockDbHelper,
        registerDefaultFactors: true,
        proteinTypesOverride:
            mockDbHelper.recipeProteinTypes, // Pass the override directly
      );

// Act: Get recommendations avoiding beef and chicken
      final results = await recommendationService.getRecommendations(
        avoidProteinTypes: [ProteinType.beef, ProteinType.chicken],
      );

// Assert: result should only contain fish recipe
      expect(results.length, 1);
      expect(results.first.id, 'fish-recipe');
    });

    test(
        'requiredProteinTypes filter includes only recipes with specified proteins',
        () async {
      // Arrange: Create recipes with different protein types
      final now = DateTime.now();

      final beefRecipe = Recipe(
        id: 'beef-recipe',
        name: 'Beef Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 4,
      );

      final chickenRecipe = Recipe(
        id: 'chicken-recipe',
        name: 'Chicken Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 4,
      );

      final fishRecipe = Recipe(
        id: 'fish-recipe',
        name: 'Fish Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 4,
      );

      // Add recipes to mock database
      await mockDbHelper.insertRecipe(beefRecipe);
      await mockDbHelper.insertRecipe(chickenRecipe);
      await mockDbHelper.insertRecipe(fishRecipe);

      // Set up protein types in the mock database
      mockDbHelper.recipeProteinTypes = {
        'beef-recipe': [ProteinType.beef],
        'chicken-recipe': [ProteinType.chicken],
        'fish-recipe': [ProteinType.fish],
      };

      // Create recommendation service with protein types override
      recommendationService = RecommendationService(
        dbHelper: mockDbHelper,
        registerDefaultFactors: true,
        proteinTypesOverride:
            mockDbHelper.recipeProteinTypes, // Pass the override directly
      );

      // Act: Get recommendations requiring fish
      final results = await recommendationService.getRecommendations(
        requiredProteinTypes: [ProteinType.fish],
      );

      // Assert: result should only contain fish recipe
      expect(results.length, 1);
      expect(results.first.id, 'fish-recipe');
    });

    test('maxDifficulty filter excludes recipes above specified difficulty',
        () async {
      // Arrange: Create recipes with different difficulty levels
      final now = DateTime.now();

      final easyRecipe = Recipe(
        id: 'easy-recipe',
        name: 'Easy Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 4,
        difficulty: 1,
      );

      final mediumRecipe = Recipe(
        id: 'medium-recipe',
        name: 'Medium Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 4,
        difficulty: 3,
      );

      final hardRecipe = Recipe(
        id: 'hard-recipe',
        name: 'Hard Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 4,
        difficulty: 5,
      );

      // Add recipes to mock database
      await mockDbHelper.insertRecipe(easyRecipe);
      await mockDbHelper.insertRecipe(mediumRecipe);
      await mockDbHelper.insertRecipe(hardRecipe);

      // Create a simple context
      recommendationService.overrideTestContext = {
        'lastCooked': <String, DateTime>{},
        'mealCounts': <String, int>{},
        'proteinTypes': <String, Set<ProteinType>>{},
        'recentMeals': <Map<String, dynamic>>[],
      };

      // Act: Get recommendations with max difficulty of 3
      final results = await recommendationService.getRecommendations(
        maxDifficulty: 3,
      );

      // Assert: result should contain easy and medium recipes, but not hard recipe
      expect(results.length, 2);
      expect(results.any((r) => r.id == 'easy-recipe'), isTrue);
      expect(results.any((r) => r.id == 'medium-recipe'), isTrue);
      expect(results.any((r) => r.id == 'hard-recipe'), isFalse);
    });

    test(
        'preferredFrequency filter includes only recipes with specified frequency',
        () async {
      // Arrange: Create recipes with different frequency preferences
      final now = DateTime.now();

      final dailyRecipe = Recipe(
        id: 'daily-recipe',
        name: 'Daily Recipe',
        desiredFrequency: FrequencyType.daily,
        createdAt: now,
        rating: 4,
      );

      final weeklyRecipe = Recipe(
        id: 'weekly-recipe',
        name: 'Weekly Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 4,
      );

      final monthlyRecipe = Recipe(
        id: 'monthly-recipe',
        name: 'Monthly Recipe',
        desiredFrequency: FrequencyType.monthly,
        createdAt: now,
        rating: 4,
      );

      // Add recipes to mock database
      await mockDbHelper.insertRecipe(dailyRecipe);
      await mockDbHelper.insertRecipe(weeklyRecipe);
      await mockDbHelper.insertRecipe(monthlyRecipe);

      // Create a simple context
      recommendationService.overrideTestContext = {
        'lastCooked': <String, DateTime>{},
        'mealCounts': <String, int>{},
        'proteinTypes': <String, Set<ProteinType>>{},
        'recentMeals': <Map<String, dynamic>>[],
      };

      // Act: Get recommendations with weekly frequency preference
      final results = await recommendationService.getRecommendations(
        preferredFrequency: FrequencyType.weekly,
      );

      // Assert: result should only contain weekly recipe
      expect(results.length, 1);
      expect(results.first.id, 'weekly-recipe');
    });

    test('weekdayMeal parameter applies appropriate weight profile', () async {
      // Arrange: Create recipes with different difficulty levels
      final now = DateTime.now();

      final easyRecipe = Recipe(
        id: 'easy-recipe',
        name: 'Easy Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 3, // Same rating for all recipes
        difficulty: 1, // Easy
      );

      final mediumRecipe = Recipe(
        id: 'medium-recipe',
        name: 'Medium Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 3, // Same rating for all recipes
        difficulty: 3, // Medium
      );

      final hardRecipe = Recipe(
        id: 'hard-recipe',
        name: 'Hard Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 3, // Same rating for all recipes
        difficulty: 5, // Hard
      );

      // Add recipes to mock database
      await mockDbHelper.insertRecipe(easyRecipe);
      await mockDbHelper.insertRecipe(mediumRecipe);
      await mockDbHelper.insertRecipe(hardRecipe);

      // Set up identical last cooked dates to isolate difficulty effect
      final twoWeeksAgo = now.subtract(const Duration(days: 14));

      Map<String, Set<ProteinType>> proteinTypes = {
        'easy-recipe': <ProteinType>{},
        'medium-recipe': <ProteinType>{},
        'hard-recipe': <ProteinType>{},
      };

      recommendationService.overrideTestContext = {
        'lastCooked': {
          'easy-recipe': twoWeeksAgo,
          'medium-recipe': twoWeeksAgo,
          'hard-recipe': twoWeeksAgo,
        },
        'mealCounts': {
          'easy-recipe': 1,
          'medium-recipe': 1,
          'hard-recipe': 1,
        },
        'proteinTypes': proteinTypes,
        'recentMeals': <Map<String, dynamic>>[],
      };
      // Act: Get detailed recommendations with weekday flag
      final weekdayResults =
          await recommendationService.getDetailedRecommendations(
        weekdayMeal: true,
      );

      // Get detailed recommendations with weekend flag
      final weekendResults =
          await recommendationService.getDetailedRecommendations(
        weekdayMeal: false,
      );

      // Get recipes by ID for easier comparison
      final weekdayRecipes =
          weekdayResults.recommendations.map((r) => r.recipe.id).toList();
      final weekendRecipes =
          weekendResults.recommendations.map((r) => r.recipe.id).toList();

      // Assert: For weekday meals, easy recipes should rank higher
      // For weekend, difficulty should matter less
      // Without matching the exact order (which depends on specific weights),
      // we can check if difficulty affects weekday ordering

      // In weekday scenario, easy recipe should be ranked higher than in weekend scenario
      final easyWeekdayIndex = weekdayRecipes.indexOf('easy-recipe');
      final easyWeekendIndex = weekendRecipes.indexOf('easy-recipe');

      final hardWeekdayIndex = weekdayRecipes.indexOf('hard-recipe');
      final hardWeekendIndex = weekendRecipes.indexOf('hard-recipe');

// Verify that difficulty factor has more weight in weekday profile
// Extract the factor weights from metadata
      final weekdayWeights = weekdayResults
          .recommendations[0].metadata['factorWeights'] as Map<String, int>;
      final weekendWeights = weekendResults
          .recommendations[0].metadata['factorWeights'] as Map<String, int>;

// Check that weekday gives more weight to difficulty
      expect(
          weekdayWeights['difficulty']! > weekendWeights['difficulty']!, isTrue,
          reason: "Difficulty should have higher weight in weekday profile");

// Alternative assertion: check that easy recipe is first in weekday results
      expect(weekdayRecipes[0], equals('easy-recipe'),
          reason:
              "Easy recipe should be ranked first in weekday recommendations");
    });

    test('combining multiple filters works correctly', () async {
      // Arrange: Create recipes with various properties
      final now = DateTime.now();

      // Recipe combinations:
      // 1. Easy (1) Weekly Chicken
      // 2. Medium (3) Weekly Beef
      // 3. Hard (5) Weekly Fish
      // 4. Medium (3) Monthly Chicken
      // 5. Hard (5) Daily Beef

      final recipes = [
        Recipe(
          id: 'recipe-1',
          name: 'Easy Weekly Chicken',
          desiredFrequency: FrequencyType.weekly,
          createdAt: now,
          rating: 3,
          difficulty: 1,
        ),
        Recipe(
          id: 'recipe-2',
          name: 'Medium Weekly Beef',
          desiredFrequency: FrequencyType.weekly,
          createdAt: now,
          rating: 3,
          difficulty: 3,
        ),
        Recipe(
          id: 'recipe-3',
          name: 'Hard Weekly Fish',
          desiredFrequency: FrequencyType.weekly,
          createdAt: now,
          rating: 3,
          difficulty: 5,
        ),
        Recipe(
          id: 'recipe-4',
          name: 'Medium Monthly Chicken',
          desiredFrequency: FrequencyType.monthly,
          createdAt: now,
          rating: 3,
          difficulty: 3,
        ),
        Recipe(
          id: 'recipe-5',
          name: 'Hard Daily Beef',
          desiredFrequency: FrequencyType.daily,
          createdAt: now,
          rating: 3,
          difficulty: 5,
        ),
      ];

      // Add all recipes to database
      for (final recipe in recipes) {
        await mockDbHelper.insertRecipe(recipe);
      }

      // Set up protein types
      mockDbHelper.recipeProteinTypes = {
        'recipe-1': [ProteinType.chicken],
        'recipe-2': [ProteinType.beef],
        'recipe-3': [ProteinType.fish],
        'recipe-4': [ProteinType.chicken],
        'recipe-5': [ProteinType.beef],
      };

      recommendationService = RecommendationService(
        dbHelper: mockDbHelper,
        registerDefaultFactors: true,
        proteinTypesOverride:
            mockDbHelper.recipeProteinTypes, // Pass the override directly
      );
      Map<String, Set<ProteinType>> proteinTypes =
          Map<String, Set<ProteinType>>.from(mockDbHelper.recipeProteinTypes);

      recommendationService.overrideTestContext = {
        'lastCooked': {
          'recipe-1': now.subtract(const Duration(days: 14)),
          'recipe-2': now.subtract(const Duration(days: 14)),
          'recipe-3': now.subtract(const Duration(days: 14)),
          'recipe-4': now.subtract(const Duration(days: 14)),
          'recipe-5': now.subtract(const Duration(days: 14)),
        },
        'mealCounts': {
          'recipe-1': 1,
          'recipe-2': 1,
          'recipe-3': 1,
          'recipe-4': 1,
          'recipe-5': 1,
        },
        'proteinTypes': proteinTypes,
        'recentMeals': <Map<String, dynamic>>[],
      };

      // Act: Apply multiple filters - combine weekly frequency, max difficulty 3, and avoid beef
      final results = await recommendationService.getRecommendations(
        preferredFrequency: FrequencyType.weekly,
        maxDifficulty: 3,
        avoidProteinTypes: [ProteinType.beef],
      );

      for (final recipe in results) {}

// Make sure protein types are correctly configured
      for (final entry in mockDbHelper.recipeProteinTypes.entries) {}

// Check if the test data matches our expectations
      expect(results.length, 1,
          reason: "Only recipe-1 should match all criteria");
      expect(results.first.id, 'recipe-1',
          reason:
              "Only recipe-1 should match weekly frequency, max difficulty 3, and non-beef protein");
    });
  });
}
