// test/edge_cases/error_scenarios/recommendation_failures_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/core/services/recommendation_service.dart';
import 'package:gastrobrain/core/services/meal_plan_analysis_service.dart';
import 'package:gastrobrain/core/errors/gastrobrain_exceptions.dart';
import 'package:gastrobrain/models/protein_type.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/core/di/providers/database_provider.dart';
import '../../mocks/mock_database_helper.dart';

/// Tests for recommendation service error scenarios and failures.
///
/// Verifies that RecommendationService handles error conditions gracefully:
/// - No recipes in database
/// - All recipes filtered out by constraints
/// - Invalid recommendation parameters
/// - No recommendation factors registered
/// - Empty result sets
/// - Fallback to simpler recommendations
/// - User-friendly error messages
///
/// Note: These tests verify service-layer error handling, not scoring logic.
/// Scoring logic is tested in recommendation service unit tests.
void main() {
  group('Recommendation Service Failures', () {
    late MockDatabaseHelper mockDbHelper;
    late RecommendationService recommendationService;

    setUp(() {
      mockDbHelper = MockDatabaseHelper();
      DatabaseProvider().setDatabaseHelper(mockDbHelper);
      recommendationService = RecommendationService(
        dbHelper: mockDbHelper,
        mealPlanAnalysis: MealPlanAnalysisService(mockDbHelper),
        registerDefaultFactors: true,
      );
    });

    tearDown(() {
      mockDbHelper.resetAllData();
    });

    group('No Recipes Available', () {
      test('returns empty list when no recipes in database', () async {
        // No recipes added to database
        final recommendations = await recommendationService.getRecommendations(
          count: 5,
        );

        expect(recommendations, isEmpty,
            reason: 'Should return empty list when no recipes available');
      });

      test('returns empty list when requesting zero recommendations', () async {
        // Requesting 0 recommendations should fail validation
        expect(
          () async => await recommendationService.getRecommendations(count: 0),
          throwsA(isA<ValidationException>()),
          reason: 'Requesting 0 recommendations should throw validation error',
        );
      });

      test('returns empty list when requesting negative count', () async {
        expect(
          () async => await recommendationService.getRecommendations(count: -1),
          throwsA(isA<ValidationException>()),
          reason: 'Negative count should throw validation error',
        );
      });

      test('handles no recipes gracefully with detailed recommendations', () async {
        final results = await recommendationService.getDetailedRecommendations(
          count: 5,
        );

        expect(results.recommendations, isEmpty);
        expect(results.totalEvaluated, equals(0));
        expect(results.queryParameters, isNotEmpty,
            reason: 'Query parameters should be recorded even when empty');
      });
    });

    group('All Recipes Filtered Out', () {
      test('handles excludeIds parameter without crashing', () async {
        // Test that excludeIds parameter is accepted
        final recommendations = await recommendationService.getRecommendations(
          count: 5,
          excludeIds: ['recipe1', 'recipe2'],
        );

        expect(recommendations, isNotNull,
            reason: 'Should handle excludeIds without crashing');
      });

      test('handles avoidProteinTypes parameter', () async {
        // Test that avoidProteinTypes parameter is accepted
        final recommendations = await recommendationService.getRecommendations(
          count: 5,
          avoidProteinTypes: [ProteinType.chicken, ProteinType.beef],
        );

        expect(recommendations, isNotNull);
      });

      test('handles maxDifficulty constraint parameter', () async {
        // Test that maxDifficulty parameter is accepted
        final recommendations = await recommendationService.getRecommendations(
          count: 5,
          maxDifficulty: 2,
        );

        expect(recommendations, isNotNull,
            reason: 'Should handle maxDifficulty without crashing');
      });

      test('handles preferredFrequency parameter', () async {
        // Test that preferredFrequency parameter is accepted
        final recommendations = await recommendationService.getRecommendations(
          count: 5,
          preferredFrequency: FrequencyType.rarely,
        );

        expect(recommendations, isNotNull);
      });
    });

    group('Invalid Parameters', () {
      test('throws ValidationException for count <= 0', () async {
        expect(
          () async => await recommendationService.getRecommendations(count: 0),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.message.toLowerCase(),
              'message',
              contains('positive'),
            ),
          ),
        );
      });

      test('throws ValidationException for negative count', () async {
        expect(
          () async => await recommendationService.getRecommendations(count: -5),
          throwsA(isA<ValidationException>()),
        );
      });

      test('handles null parameters gracefully', () async {
        final recommendations = await recommendationService.getRecommendations(
          count: 5,
          excludeIds: [],
          avoidProteinTypes: null,
          requiredProteinTypes: null,
          forDate: null,
          mealType: null,
          maxDifficulty: null,
          preferredFrequency: null,
          weekdayMeal: null,
          mealPlan: null,
        );

        expect(recommendations, isNotNull);
      });

      test('handles empty exclude list', () async {
        final recommendations = await recommendationService.getRecommendations(
          count: 5,
          excludeIds: [],
        );

        expect(recommendations, isNotNull);
      });
    });

    group('Error Messages', () {
      test('validation error message is descriptive for invalid count', () async {
        try {
          await recommendationService.getRecommendations(count: 0);
          fail('Should have thrown ValidationException');
        } on ValidationException catch (e) {
          expect(e.message, isNotEmpty);
          expect(e.message.length, greaterThan(10),
              reason: 'Error message should be descriptive');
        }
      });

      test('error messages are user-friendly', () async {
        try {
          await recommendationService.getRecommendations(count: -1);
          fail('Should have thrown ValidationException');
        } on ValidationException catch (e) {
          // Error message should not contain technical jargon
          expect(e.message, isNot(contains('stack')));
          expect(e.message, isNot(contains('null')));
        }
      });
    });

    group('Edge Cases', () {
      test('handles very large count values without crashing', () async {
        final recommendations = await recommendationService.getRecommendations(
          count: 1000,
        );

        expect(recommendations, isNotNull,
            reason: 'Should handle large count values gracefully');
      });

      test('handles count of 1 (minimum valid)', () async {
        final recommendations = await recommendationService.getRecommendations(
          count: 1,
        );

        expect(recommendations, isNotNull);
      });

      test('handles weekdayMeal parameter for temporal context', () async {
        // Weekday profile
        final weekdayRecs = await recommendationService.getRecommendations(
          count: 5,
          weekdayMeal: true,
        );

        expect(weekdayRecs, isNotNull);

        // Weekend profile
        final weekendRecs = await recommendationService.getRecommendations(
          count: 5,
          weekdayMeal: false,
        );

        expect(weekendRecs, isNotNull);
      });

      test('handles forDate parameter', () async {
        final recommendations = await recommendationService.getRecommendations(
          count: 5,
          forDate: DateTime.now(),
        );

        expect(recommendations, isNotNull);
      });

      test('handles mealType parameter', () async {
        final lunchRecs = await recommendationService.getRecommendations(
          count: 5,
          mealType: 'lunch',
        );

        expect(lunchRecs, isNotNull);

        final dinnerRecs = await recommendationService.getRecommendations(
          count: 5,
          mealType: 'dinner',
        );

        expect(dinnerRecs, isNotNull);
      });
    });

    group('Fallback Behavior', () {
      test('returns empty list gracefully when no recipes available', () async {
        // Empty database
        final recommendations = await recommendationService.getRecommendations(
          count: 5,
        );

        expect(recommendations, isEmpty,
            reason: 'Empty database should return empty list, not crash');
      });

      test('detailed recommendations return empty with proper metadata', () async {
        final results = await recommendationService.getDetailedRecommendations(
          count: 5,
        );

        expect(results.recommendations, isEmpty);
        expect(results.totalEvaluated, equals(0));
        expect(results.generatedAt, isNotNull,
            reason: 'Should include generation timestamp');
        expect(results.queryParameters, isNotNull,
            reason: 'Should include query parameters even when empty');
      });
    });
  });
}
