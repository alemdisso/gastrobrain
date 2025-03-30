// test/core/services/recommendation_factors/variety_encouragement_integration_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/core/services/recommendation_service.dart';
//import 'package:gastrobrain/core/services/recommendation_factors/variety_encouragement_factor.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/meal.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/models/protein_type.dart';
import 'package:gastrobrain/utils/id_generator.dart';

import '../../../mocks/mock_database_helper.dart';

void main() {
  group('Variety Encouragement in Recommendation System', () {
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

    test('variety factor influences recommendations', () async {
      // Arrange: Create recipes with identical properties except for cooking history
      final now = DateTime.now();

      // Recipe that has never been cooked
      final neverCookedRecipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Never Cooked Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 4, // Same rating for all recipes
      );

      // Recipe cooked once
      final cookedOnceRecipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Cooked Once Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 4, // Same rating for all recipes
      );

      // Recipe cooked many times
      final cookedOftenRecipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Cooked Often Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 4, // Same rating for all recipes
      );

      // Add recipes to mock database
      await mockDbHelper.insertRecipe(neverCookedRecipe);
      await mockDbHelper.insertRecipe(cookedOnceRecipe);
      await mockDbHelper.insertRecipe(cookedOftenRecipe);

      // Set up identical last cooked dates - from a while back
      // so frequency factor doesn't dominate
      final sixWeeksAgo = now.subtract(const Duration(days: 42));

      // Create meals for different recipes
      // One meal for cookedOnceRecipe
      final singleMeal = Meal(
        id: IdGenerator.generateId(),
        recipeId: cookedOnceRecipe.id,
        cookedAt: sixWeeksAgo,
        servings: 2,
      );
      await mockDbHelper.insertMeal(singleMeal);

      // Multiple meals for cookedOftenRecipe
      for (int i = 0; i < 10; i++) {
        final manyMeal = Meal(
          id: IdGenerator.generateId(),
          recipeId: cookedOftenRecipe.id,
          cookedAt: sixWeeksAgo,
          servings: 2,
        );
        await mockDbHelper.insertMeal(manyMeal);
      }

      // Instead of directly assigning to private fields, create a mock context
      // with the data we need for our test
      final mealCounts = <String, int>{
        neverCookedRecipe.id: 0,
        cookedOnceRecipe.id: 1,
        cookedOftenRecipe.id: 10,
      };

      final lastCookedDates = <String, DateTime>{
        cookedOnceRecipe.id: sixWeeksAgo,
        cookedOftenRecipe.id: sixWeeksAgo,
      };

      // Override the test context with our mock data
// Create a map of protein types for each recipe (empty for this test)
      final proteinTypes = <String, List<ProteinType>>{
        neverCookedRecipe.id: [],
        cookedOnceRecipe.id: [],
        cookedOftenRecipe.id: [],
      };

// Also need to add 'recentMeals' for the protein rotation factor
      final recentMeals = <Map<String, dynamic>>[
        {
          'recipe': cookedOnceRecipe,
          'cookedAt': sixWeeksAgo,
        },
      ];

      for (int i = 0; i < 10; i++) {
        recentMeals.add({
          'recipe': cookedOftenRecipe,
          'cookedAt': sixWeeksAgo,
        });
      }

      recommendationService.overrideTestContext = {
        'mealCounts': mealCounts,
        'lastCooked': lastCookedDates,
        'proteinTypes': proteinTypes,
        'recentMeals': recentMeals,
      };

      // Act: Get detailed recommendations to analyze scores
      final results = await recommendationService.getDetailedRecommendations();

      // Assert: Verify all recipes were included
      expect(results.recommendations.length, 3);

      // Extract the variety factor scores
      final Map<String, double> varietyScores = {};
      for (final rec in results.recommendations) {
        if (rec.factorScores.containsKey('variety_encouragement')) {
          varietyScores[rec.recipe.id] =
              rec.factorScores['variety_encouragement']!;
        }
      }

      // Verify the variety scores follow the expected pattern
      // Never cooked should have highest score
      expect(varietyScores[neverCookedRecipe.id], equals(100.0));

      // Cooked once should have medium score
      expect(varietyScores[cookedOnceRecipe.id], lessThan(100.0));
      expect(varietyScores[cookedOnceRecipe.id], greaterThan(50.0));

      final cookedOftenScore = varietyScores[cookedOftenRecipe.id];
      final cookedOnceScore = varietyScores[cookedOnceRecipe.id];

      expect(cookedOftenScore, isNotNull);
      expect(cookedOnceScore, isNotNull);
      expect(cookedOftenScore!,
          lessThan(cookedOnceScore!)); // Cooked often should have lowest score
    });
  });
}
