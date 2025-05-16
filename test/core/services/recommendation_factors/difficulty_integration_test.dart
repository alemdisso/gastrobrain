import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/core/services/recommendation_service.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
//import 'package:gastrobrain/models/protein_type.dart';
import 'package:gastrobrain/utils/id_generator.dart';

import '../../../mocks/mock_database_helper.dart';

void main() {
  group('Difficulty Factor in Recommendation System', () {
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

    test('difficulty factor influences recommendations', () async {
      // Arrange: Create recipes that are identical except for difficulty
      final now = DateTime.now();

      // Easy recipe
      final easyRecipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Easy Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 3, // Same rating for all
        difficulty: 1, // Easy
      );

      // Medium recipe
      final mediumRecipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Medium Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 3, // Same rating for all
        difficulty: 3, // Medium
      );

      // Hard recipe
      final hardRecipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Hard Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 3, // Same rating for all
        difficulty: 5, // Hard
      );

      // Add recipes to mock database
      await mockDbHelper.insertRecipe(easyRecipe);
      await mockDbHelper.insertRecipe(mediumRecipe);
      await mockDbHelper.insertRecipe(hardRecipe);

      // Set up identical last cooked dates - from a while back
      // so frequency factor doesn't dominate
      final fourWeeksAgo = now.subtract(const Duration(days: 28));

      // Create a map of protein types for recipes (empty for this test)
      mockDbHelper.recipeProteinTypes = {
        easyRecipe.id: [],
        mediumRecipe.id: [],
        hardRecipe.id: [],
      };

      // Override the test context with our mock data
      recommendationService.overrideTestContext = {
        'proteinTypes': mockDbHelper.recipeProteinTypes,
        'recentMeals': [],
        'lastCooked': {
          easyRecipe.id: fourWeeksAgo,
          mediumRecipe.id: fourWeeksAgo,
          hardRecipe.id: fourWeeksAgo,
        },
        'mealCounts': {
          easyRecipe.id: 1,
          mediumRecipe.id: 1,
          hardRecipe.id: 1,
        },
      };

      // Apply the weekday profile which emphasizes difficulty
      recommendationService.applyWeightProfile('weekday');

      // Act: Get detailed recommendations
      final results = await recommendationService.getDetailedRecommendations();

      // Assert: Verify all recipes were included
      expect(results.recommendations.length, 3);

      // Extract the difficulty scores
      final Map<String, double> difficultyScores = {};
      for (final rec in results.recommendations) {
        if (rec.factorScores.containsKey('difficulty')) {
          difficultyScores[rec.recipe.id] = rec.factorScores['difficulty']!;
        }
      }

      // Verify difficulty scores follow expected pattern
      expect(
          difficultyScores[easyRecipe.id], equals(100.0)); // Highest for easy
      expect(difficultyScores[mediumRecipe.id], equals(60.0)); // Medium score
      expect(difficultyScores[hardRecipe.id], equals(20.0)); // Lowest for hard

      // Check final ordering with weekday profile
      // The easy recipe should be first since difficulty has significant weight in weekday profile
      final firstRecId = results.recommendations[0].recipe.id;
      expect(firstRecId, equals(easyRecipe.id),
          reason: "Easy recipe should be ranked highest with weekday profile");

      // Hard recipe should be last
      final lastRecId = results.recommendations[2].recipe.id;
      expect(lastRecId, equals(hardRecipe.id),
          reason: "Hard recipe should be ranked lowest with weekday profile");
    });

    test('difficulty factor balances with other factors', () async {
      // Arrange: Create recipes with competing factors
      final now = DateTime.now();

      // Recipe 1: Easy but not due yet (good for difficulty, bad for frequency)
      final easyRecentRecipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Easy Recently-Cooked Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 3,
        difficulty: 1, // Easy
      );

      // Recipe 2: Hard but overdue (bad for difficulty, good for frequency)
      final hardOverdueRecipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Hard Overdue Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 3,
        difficulty: 5, // Hard
      );

      // Add recipes to mock database
      await mockDbHelper.insertRecipe(easyRecentRecipe);
      await mockDbHelper.insertRecipe(hardOverdueRecipe);

      // Set up different last cooked dates
      final recentDate = now.subtract(const Duration(days: 3)); // 3 days ago
      final overdueDate = now.subtract(const Duration(days: 21)); // 3 weeks ago

      // Mock protein types (not important for this test)
      mockDbHelper.recipeProteinTypes = {
        easyRecentRecipe.id: [],
        hardOverdueRecipe.id: [],
      };

      // Override the test context
      recommendationService.overrideTestContext = {
        'proteinTypes': mockDbHelper.recipeProteinTypes,
        'recentMeals': [],
        'lastCooked': {
          easyRecentRecipe.id: recentDate,
          hardOverdueRecipe.id: overdueDate,
        },
        'mealCounts': {
          easyRecentRecipe.id: 1,
          hardOverdueRecipe.id: 1,
        },
      };

      // Test with standard profile first
      // Act: Get detailed recommendations
      final standardResults =
          await recommendationService.getDetailedRecommendations();

      // Extract factor scores for analysis
      final Map<String, Map<String, double>> standardFactorScores = {};
      for (final rec in standardResults.recommendations) {
        standardFactorScores[rec.recipe.id] = rec.factorScores;
      }

      // Now apply weekday profile which emphasizes difficulty
      recommendationService.applyWeightProfile('weekday');

      // Act: Get detailed recommendations with weekday profile
      final weekdayResults =
          await recommendationService.getDetailedRecommendations();

      // Extract factor scores for analysis
      final Map<String, Map<String, double>> weekdayFactorScores = {};
      for (final rec in weekdayResults.recommendations) {
        weekdayFactorScores[rec.recipe.id] = rec.factorScores;
      }

      // Check factor scores are calculated correctly for both profiles
      // For standard profile, frequency should typically dominate
      // For weekday profile, difficulty should have more influence

      // Get relative positions in each profile
      final easyRecipeRankStandard = standardResults.recommendations
          .indexWhere((rec) => rec.recipe.id == easyRecentRecipe.id);

      final easyRecipeRankWeekday = weekdayResults.recommendations
          .indexWhere((rec) => rec.recipe.id == easyRecentRecipe.id);

      // The easy recipe should rank better (lower index) in weekday profile
      // compared to standard profile, because difficulty is weighted higher
      expect(easyRecipeRankWeekday <= easyRecipeRankStandard, isTrue,
          reason:
              "Easy recipe should rank same or better with weekday profile");
    });
  });
}
