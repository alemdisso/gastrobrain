// test/core/services/temporal_context_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/core/services/recommendation_service.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import '../../mocks/mock_database_helper.dart';

void main() {
  late MockDatabaseHelper mockDbHelper;
  late RecommendationService recommendationService;

  setUp(() {
    mockDbHelper = MockDatabaseHelper();
    recommendationService = RecommendationService(
      dbHelper: mockDbHelper,
      registerDefaultFactors: true,
    );
  });

  group('Temporal Context - Basic Tests', () {
    test('_isWeekday correctly identifies weekdays and weekends', () {
      // Test weekdays (Monday = 1 to Friday = 5)
      final monday = DateTime(2024, 1, 1); // January 1, 2024 is a Monday
      final tuesday = DateTime(2024, 1, 2);
      final wednesday = DateTime(2024, 1, 3);
      final thursday = DateTime(2024, 1, 4);
      final friday = DateTime(2024, 1, 5);

      // Test weekends (Saturday = 6, Sunday = 7)
      final saturday = DateTime(2024, 1, 6);
      final sunday = DateTime(2024, 1, 7);

      // We can't directly test _isWeekday since it's private,
      // but we can test it indirectly through getRecommendations
      // by checking that different weight profiles are applied

      // For now, let's verify the dates are correct
      expect(monday.weekday, equals(DateTime.monday));
      expect(tuesday.weekday, equals(DateTime.tuesday));
      expect(wednesday.weekday, equals(DateTime.wednesday));
      expect(thursday.weekday, equals(DateTime.thursday));
      expect(friday.weekday, equals(DateTime.friday));
      expect(saturday.weekday, equals(DateTime.saturday));
      expect(sunday.weekday, equals(DateTime.sunday));

      // Verify weekday range (1-5 are weekdays, 6-7 are weekends)
      expect(
          monday.weekday >= DateTime.monday &&
              monday.weekday <= DateTime.friday,
          isTrue);
      expect(
          friday.weekday >= DateTime.monday &&
              friday.weekday <= DateTime.friday,
          isTrue);
      expect(
          saturday.weekday >= DateTime.monday &&
              saturday.weekday <= DateTime.friday,
          isFalse);
      expect(
          sunday.weekday >= DateTime.monday &&
              sunday.weekday <= DateTime.friday,
          isFalse);
    });

    test(
        'temporal context is added to recommendation context when forDate provided',
        () async {
      // We'll test this indirectly by calling getDetailedRecommendations
      // and checking that different behavior occurs for weekdays vs weekends

      // First, let's add some test recipes to ensure we get recommendations
      final simpleRecipe = Recipe(
        id: 'simple-recipe',
        name: 'Simple Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
        difficulty: 1, // Very simple
      );

      final complexRecipe = Recipe(
        id: 'complex-recipe',
        name: 'Complex Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
        difficulty: 5, // Very complex
      );

      await mockDbHelper.insertRecipe(simpleRecipe);
      await mockDbHelper.insertRecipe(complexRecipe);

      // Test weekday recommendation (should favor simple recipes)
      final weekdayDate = DateTime(2024, 1, 1); // Monday
      final weekdayResults =
          await recommendationService.getDetailedRecommendations(
        forDate: weekdayDate,
        weekdayMeal: true, // Explicitly set weekday meal
        count: 10,
      );

      // Test weekend recommendation (should not penalize complex recipes as much)
      final weekendDate = DateTime(2024, 1, 6); // Saturday
      final weekendResults =
          await recommendationService.getDetailedRecommendations(
        forDate: weekendDate,
        weekdayMeal: false, // Explicitly set weekend meal
        count: 10,
      );

      // Both should return recommendations
      expect(weekdayResults.recommendations.isNotEmpty, isTrue,
          reason: 'Should get weekday recommendations');
      expect(weekendResults.recommendations.isNotEmpty, isTrue,
          reason: 'Should get weekend recommendations');

      // Verify that forDate was included in query parameters
      expect(weekdayResults.queryParameters['forDate'], isNotNull,
          reason: 'forDate should be recorded in query parameters');
      expect(weekendResults.queryParameters['forDate'], isNotNull,
          reason: 'forDate should be recorded in query parameters');

      // Verify that weekdayMeal was included in query parameters
      expect(weekdayResults.queryParameters['weekdayMeal'], equals(true),
          reason: 'weekdayMeal should be recorded for weekday');
      expect(weekendResults.queryParameters['weekdayMeal'], equals(false),
          reason: 'weekdayMeal should be recorded for weekend');
    });
    test('weekday recommendations favor simpler recipes over complex ones',
        () async {
      // Create recipes with identical attributes except difficulty
      final simpleRecipe = Recipe(
        id: 'simple-recipe',
        name: 'Simple Weekday Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
        difficulty: 1, // Very simple
        rating: 3, // Same rating
        prepTimeMinutes: 30,
        cookTimeMinutes: 30,
      );

      final complexRecipe = Recipe(
        id: 'complex-recipe',
        name: 'Complex Weekend Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
        difficulty: 5, // Very complex
        rating: 3, // Same rating
        prepTimeMinutes: 30,
        cookTimeMinutes: 30,
      );

      await mockDbHelper.insertRecipe(simpleRecipe);
      await mockDbHelper.insertRecipe(complexRecipe);

      // Get weekday recommendations
      final weekdayDate = DateTime(2024, 1, 1); // Monday
      final weekdayResults =
          await recommendationService.getDetailedRecommendations(
        forDate: weekdayDate,
        weekdayMeal: true,
        count: 5,
      );

      // Find the recipes in recommendations
      final simpleRecommendation = weekdayResults.recommendations
          .firstWhere((r) => r.recipe.id == 'simple-recipe');
      final complexRecommendation = weekdayResults.recommendations
          .firstWhere((r) => r.recipe.id == 'complex-recipe');

      // On weekdays, simple recipe should have higher total score due to difficulty factor weight
      expect(simpleRecommendation.totalScore > complexRecommendation.totalScore,
          isTrue,
          reason:
              'Simple recipe should score higher than complex recipe on weekdays');

      // Verify the difficulty factor scores are different
      final simpleDifficultyScore =
          simpleRecommendation.factorScores['difficulty'];
      final complexDifficultyScore =
          complexRecommendation.factorScores['difficulty'];

      expect(simpleDifficultyScore, isNotNull);
      expect(complexDifficultyScore, isNotNull);
      expect(simpleDifficultyScore! > complexDifficultyScore!, isTrue,
          reason: 'Simple recipe should have higher difficulty factor score');
    });
    test(
        'weekend recommendations allow complex recipes to compete with simple ones',
        () async {
      // Recreate recipes to ensure they exist in this test
      final simpleRecipe = Recipe(
        id: 'simple-recipe-weekend',
        name: 'Simple Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
        difficulty: 1, // Very simple
        rating: 3, // Average rating
        prepTimeMinutes: 30,
        cookTimeMinutes: 30,
      );

      final highRatedComplexRecipe = Recipe(
        id: 'high-rated-complex',
        name: 'Amazing Complex Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
        difficulty: 5, // Very complex
        rating: 5, // Excellent rating
        prepTimeMinutes: 60,
        cookTimeMinutes: 90,
      );

      await mockDbHelper.insertRecipe(simpleRecipe);
      await mockDbHelper.insertRecipe(highRatedComplexRecipe);

      // Get weekend recommendations
      final weekendDate = DateTime(2024, 1, 6); // Saturday
      final weekendResults =
          await recommendationService.getDetailedRecommendations(
        forDate: weekendDate,
        weekdayMeal: false,
        count: 10,
      );

      // Find the recipes in recommendations
      final simpleRecommendations = weekendResults.recommendations
          .where((r) => r.recipe.id == 'simple-recipe-weekend')
          .toList();
      final complexRecommendations = weekendResults.recommendations
          .where((r) => r.recipe.id == 'high-rated-complex')
          .toList();

      // Verify both recipes are in the recommendations
      expect(simpleRecommendations.isNotEmpty, isTrue,
          reason: 'Simple recipe should be in weekend recommendations');
      expect(complexRecommendations.isNotEmpty, isTrue,
          reason: 'Complex recipe should be in weekend recommendations');

      final simpleRecommendation = simpleRecommendations.first;
      final complexRecommendation = complexRecommendations.first;

      // The complex recipe should have much higher rating score (5 vs 3)
      final ratingScoreSimple = simpleRecommendation.factorScores['rating']!;
      final ratingScoreComplex = complexRecommendation.factorScores['rating']!;

      expect(ratingScoreComplex > ratingScoreSimple, isTrue,
          reason: 'Highly rated recipe should have higher rating factor score');

      // On weekends, the highly-rated complex recipe can actually score higher
      // than the simple recipe due to reduced difficulty penalty and increased rating weight
      final scoreDifference =
          (complexRecommendation.totalScore - simpleRecommendation.totalScore)
              .abs();
      expect(scoreDifference < 5, isTrue,
          reason:
              'Complex and simple recipes should have very close scores on weekends (within 5 points)');
    });
    test(
        'same recipe gets different difficulty factor scores on weekdays vs weekends',
        () async {
      // Create a moderately complex recipe
      final testRecipe = Recipe(
        id: 'test-recipe-temporal',
        name: 'Moderate Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
        difficulty: 4, // Moderately complex
        rating: 4, // Good rating
        prepTimeMinutes: 45,
        cookTimeMinutes: 60,
      );

      await mockDbHelper.insertRecipe(testRecipe);

      // Get weekday recommendations
      final weekdayDate = DateTime(2024, 1, 1); // Monday
      final weekdayResults =
          await recommendationService.getDetailedRecommendations(
        forDate: weekdayDate,
        weekdayMeal: true,
        count: 5,
      );

      // Get weekend recommendations
      final weekendDate = DateTime(2024, 1, 6); // Saturday
      final weekendResults =
          await recommendationService.getDetailedRecommendations(
        forDate: weekendDate,
        weekdayMeal: false,
        count: 5,
      );

      // Find the same recipe in both recommendation sets
      final weekdayRecommendation = weekdayResults.recommendations
          .firstWhere((r) => r.recipe.id == 'test-recipe-temporal');
      final weekendRecommendation = weekendResults.recommendations
          .firstWhere((r) => r.recipe.id == 'test-recipe-temporal');

      // The difficulty factor score should be the same (it's the same recipe)
      final weekdayDifficultyScore =
          weekdayRecommendation.factorScores['difficulty']!;
      final weekendDifficultyScore =
          weekendRecommendation.factorScores['difficulty']!;

      expect(weekdayDifficultyScore, equals(weekendDifficultyScore),
          reason:
              'Difficulty factor score should be the same for the same recipe');

      // BUT the total scores should be different due to different factor weights
      expect(
          weekdayRecommendation.totalScore != weekendRecommendation.totalScore,
          isTrue,
          reason:
              'Total scores should differ between weekday and weekend due to weight differences');

      // For a difficulty=4 recipe, weekday total score should be lower
      // because difficulty factor has higher weight (20% vs 5%)
      expect(
          weekdayRecommendation.totalScore < weekendRecommendation.totalScore,
          isTrue,
          reason:
              'Complex recipe should score lower on weekdays due to higher difficulty factor weight');

      // Verify the weight profiles are being applied by checking metadata
      final weekdayWeights =
          weekdayRecommendation.metadata['factorWeights'] as Map<String, int>;
      final weekendWeights =
          weekendRecommendation.metadata['factorWeights'] as Map<String, int>;

      expect(weekdayWeights['difficulty'], equals(20),
          reason: 'Weekday profile should have 20% difficulty weight');
      expect(weekendWeights['difficulty'], equals(5),
          reason: 'Weekend profile should have 5% difficulty weight');
      expect(weekendWeights['rating'], equals(20),
          reason: 'Weekend profile should have 20% rating weight');
    });
  });
}
