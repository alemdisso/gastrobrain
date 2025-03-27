// test/core/services/recommendation_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/core/services/recommendation_service.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/meal.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/models/protein_type.dart';

import '../../mocks/mock_database_helper.dart';

class TestRecommendationFactor implements RecommendationFactor {
  @override
  String get id => 'test_factor';

  @override
  int get weight => 10;

  @override
  Set<String> get requiredData => {'test_data'};

  @override
  Future<double> calculateScore(
      Recipe recipe, Map<String, dynamic> context) async {
    return 50.0; // Fixed test score
  }
}

void main() {
  late RecommendationService recommendationService;
  late MockDatabaseHelper mockDbHelper;

  setUp(() {
    mockDbHelper = MockDatabaseHelper();
    recommendationService = RecommendationService(
        dbHelper: mockDbHelper, registerDefaultFactors: true);
  });

  tearDown(() {
    // Clean up after each test
    mockDbHelper.resetAllData();
  });

  group('RecommendationService - Factor Management', () {
    test('registers default factors correctly', () {
      // Verify the service has registered the correct factors
      expect(recommendationService.factors.length, 3);

      final factorIds = recommendationService.factors.map((f) => f.id).toList();
      expect(factorIds, contains('frequency'));
      expect(factorIds, contains('protein_rotation'));
      expect(factorIds, contains('rating'));

      // Verify total weight adds up correctly (40% + 30%)
      expect(recommendationService.totalWeight, 85);
    });

    test('can register and unregister factors', () {
      // Initial factors count (frequency and protein_rotation)
      expect(recommendationService.factors.length, 3);

      // Unregister two factors
      recommendationService.unregisterFactor('frequency');
      recommendationService.unregisterFactor('rating');
      expect(recommendationService.factors.length, 1);
      expect(recommendationService.factors.map((f) => f.id).toList(),
          ['protein_rotation']);

      // Unregister another factor
      recommendationService.unregisterFactor('protein_rotation');
      expect(recommendationService.factors.length, 0);

      // Create and register a test factor
      final testFactor = TestRecommendationFactor();
      recommendationService.registerFactor(testFactor);

      expect(recommendationService.factors.length, 1);
      expect(recommendationService.factors.first.id, 'test_factor');
      expect(recommendationService.totalWeight, 10);
    });
    test('recommendations include protein type information in scoring',
        () async {
      // Arrange: Create recipes with protein information
      final now = DateTime.now();

      final beefRecipe = Recipe(
        id: 'beef-recipe',
        name: 'Beef Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
      );

      final chickenRecipe = Recipe(
        id: 'chicken-recipe',
        name: 'Chicken Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
      );

      // Add recipes to mock database
      await mockDbHelper.insertRecipe(beefRecipe);
      await mockDbHelper.insertRecipe(chickenRecipe);

      // Set up protein types
      mockDbHelper.recipeProteinTypes = {
        'beef-recipe': [ProteinType.beef],
        'chicken-recipe': [ProteinType.chicken],
      };

      // Create a recent meal with beef to establish protein penalty
      final recentBeefMeal = Meal(
        id: 'recent-beef-meal',
        recipeId: 'beef-recipe',
        cookedAt: now.subtract(const Duration(days: 1)), // Yesterday
        servings: 2,
      );

      await mockDbHelper.insertMeal(recentBeefMeal);

      // Set up the context for testing
      // This is important - we're verifying that protein information is included in the context
      // and used for scoring
      recommendationService.overrideTestContext = {
        'proteinTypes': mockDbHelper.recipeProteinTypes,
        'recentMeals': [
          {
            'recipe': beefRecipe,
            'cookedAt': now.subtract(const Duration(days: 1)), // Yesterday
          }
        ],
        'lastCooked': {
          'beef-recipe': now.subtract(const Duration(days: 1)),
          'chicken-recipe': now.subtract(const Duration(days: 7)), // A week ago
        },
      };

      // Act: Get detailed recommendations
      final results = await recommendationService.getDetailedRecommendations();

      // Assert: Verify protein information was included in context and used in scoring
      expect(results.recommendations.length, 2);

      // Map recipe IDs to their recommendations for easier access
      final recommendationsMap = {
        for (var rec in results.recommendations) rec.recipe.id: rec
      };

      // Verify both recipes have protein rotation scores
      expect(
          recommendationsMap['beef-recipe']!
              .factorScores
              .containsKey('protein_rotation'),
          isTrue,
          reason: "Beef recipe should have a protein rotation score");
      expect(
          recommendationsMap['chicken-recipe']!
              .factorScores
              .containsKey('protein_rotation'),
          isTrue,
          reason: "Chicken recipe should have a protein rotation score");

      // The beef recipe should have a lower protein score than the chicken recipe
      // since beef was used yesterday and chicken wasn't
      final beefProteinScore =
          recommendationsMap['beef-recipe']!.factorScores['protein_rotation']!;
      final chickenProteinScore = recommendationsMap['chicken-recipe']!
          .factorScores['protein_rotation']!;

      expect(beefProteinScore < chickenProteinScore, isTrue,
          reason:
              "Beef should have a lower protein score than chicken since it was used recently");

      // Verify beef recipe gets substantial protein penalty
      expect(beefProteinScore, lessThan(50.0),
          reason:
              "Recent beef should receive a significant protein rotation penalty");

      // Verify chicken recipe gets good protein score
      expect(chickenProteinScore, greaterThan(75.0),
          reason:
              "Unused chicken should receive a good protein rotation score");
    });
  });
}
