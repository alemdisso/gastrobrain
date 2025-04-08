import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/core/services/recommendation_service.dart';
import 'package:gastrobrain/core/services/recommendation_factors/randomization_factor.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/models/protein_type.dart';
import 'package:gastrobrain/utils/id_generator.dart';

import '../../../mocks/mock_database_helper.dart';

void main() {
  group('Randomization Factor in Recommendation System', () {
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

    test('randomization factor influences recommendations', () async {
      // Arrange: Create identical recipes
      final now = DateTime.now();

      // First set of identical recipes
      final recipes1 = List.generate(5, (index) {
        return Recipe(
          id: IdGenerator.generateId(),
          name: 'Recipe ${index + 1}',
          desiredFrequency: FrequencyType.weekly,
          createdAt: now,
          rating: 3, // Same rating
        );
      });

      // Second set of identical recipes - exact copies
      final recipes2 = List.generate(5, (index) {
        return Recipe(
          id: IdGenerator.generateId(),
          name: 'Recipe ${index + 1}',
          desiredFrequency: FrequencyType.weekly,
          createdAt: now,
          rating: 3, // Same rating
        );
      });

      // Add all recipes to mock database
      for (final recipe in [...recipes1, ...recipes2]) {
        await mockDbHelper.insertRecipe(recipe);
      }

      // Set up identical last cooked dates to make all factors equal
      final twoWeeksAgo = now.subtract(const Duration(days: 14));

      // Create explicitly typed maps for context
      final Map<String, DateTime?> lastCookedDates =
          Map<String, DateTime?>.fromEntries([...recipes1, ...recipes2]
              .map((r) => MapEntry(r.id, twoWeeksAgo)));

      final Map<String, int> mealCounts = Map<String, int>.fromEntries(
          [...recipes1, ...recipes2].map((r) => MapEntry(r.id, 1)));

      final Map<String, List<ProteinType>> proteinTypes =
          Map<String, List<ProteinType>>.fromEntries([...recipes1, ...recipes2]
              .map((r) => MapEntry(r.id, <ProteinType>[])));

      // First run with deterministic seed
      recommendationService.overrideTestContext = <String, dynamic>{
        'lastCooked': lastCookedDates,
        'mealCounts': mealCounts,
        'proteinTypes': proteinTypes,
        'recentMeals': <Map<String, dynamic>>[],
        'randomSeed': 42, // Fixed seed
      };

      // Act: Get detailed recommendations for first run
      final results1 =
          await recommendationService.getDetailedRecommendations(count: 5);

      // Second run with different seed
      recommendationService.overrideTestContext = <String, dynamic>{
        'lastCooked': lastCookedDates,
        'mealCounts': mealCounts,
        'proteinTypes': proteinTypes,
        'recentMeals': <Map<String, dynamic>>[],
        'randomSeed': 43, // Different seed
      };

      // Act: Get recommendations for second run
      final results2 =
          await recommendationService.getDetailedRecommendations(count: 5);

      // Instead of checking if order changed, check that randomization scores differ
      bool randomScoresDifferent = false;
      for (int i = 0; i < results1.recommendations.length; i++) {
        final score1 =
            results1.recommendations[i].factorScores['randomization'];
        final score2 =
            results2.recommendations[i].factorScores['randomization'];

        if (score1 != score2) {
          randomScoresDifferent = true;
          break;
        }
      }

      expect(randomScoresDifferent, isTrue,
          reason: "Randomization scores should change with different seeds");

      // Examine score details
      for (final rec in results1.recommendations) {
        // Verify randomization factor was included
        expect(rec.factorScores.containsKey('randomization'), isTrue);

        // Verify randomization factor is within expected range
        expect(rec.factorScores['randomization']!, greaterThanOrEqualTo(0.0));
        expect(rec.factorScores['randomization']!, lessThanOrEqualTo(100.0));
      }
    });
    test('randomization has appropriate influence on final score', () async {
      // Arrange: Create a recipe
      final recipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Test Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
      );
      await mockDbHelper.insertRecipe(recipe);

      // Create a simplified recommendation service with ONLY the randomization factor
      // This allows us to test its influence in isolation
      final isolatedService = RecommendationService(
          dbHelper: mockDbHelper, registerDefaultFactors: false);

      // Register ONLY the randomization factor
      isolatedService.registerFactor(RandomizationFactor());

      // First run with seed 42
      isolatedService.overrideTestContext = {
        'lastCooked': <String, DateTime?>{},
        'mealCounts': <String, int>{},
        'proteinTypes': <String, List<ProteinType>>{recipe.id: []},
        'recentMeals': <Map<String, dynamic>>[],
        'randomSeed': 42, // First seed
      };

      // Act: Get detailed recommendations for first run
      final results1 = await isolatedService.getDetailedRecommendations();
      final rec1 = results1.recommendations.first;

      // Get randomization score and total score from first run
      final randomScore1 = rec1.factorScores['randomization']!;
      final totalScore1 = rec1.totalScore;

      // Second run with different seed
      isolatedService.overrideTestContext = {
        'lastCooked': <String, DateTime?>{},
        'mealCounts': <String, int>{},
        'proteinTypes': <String, List<ProteinType>>{recipe.id: []},
        'recentMeals': <Map<String, dynamic>>[],
        'randomSeed': 43, // Different seed
      };

      // Act: Get recommendations for second run
      final results2 = await isolatedService.getDetailedRecommendations();
      final rec2 = results2.recommendations.first;

      // Get randomization score and total score from second run
      final randomScore2 = rec2.factorScores['randomization']!;
      final totalScore2 = rec2.totalScore;

      // Since randomization is the only factor, its score should equal the total score
// Use closeTo for floating point comparisons to account for tiny precision differences
      expect(randomScore1, closeTo(totalScore1, 1e-10));
      expect(randomScore2, closeTo(totalScore2, 1e-10));

      // Verify the scores are different between runs due to the different seeds
      expect(randomScore1, isNot(equals(randomScore2)));
      expect(totalScore1, isNot(equals(totalScore2)));
    });
  });
}
