// test/core/services/recommendation_factors/user_feedback_factor_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/core/services/recommendation_factors/user_feedback_factor.dart';
import 'package:gastrobrain/core/services/recommendation_service.dart';
import 'package:gastrobrain/utils/id_generator.dart';
import '../../../mocks/mock_database_helper.dart';

void main() {
  group('UserFeedbackFactor', () {
    late UserFeedbackFactor factor;
    late RecommendationService recommendationService;
    late MockDatabaseHelper mockDbHelper;

    setUp(() {
      factor = UserFeedbackFactor();
      mockDbHelper = MockDatabaseHelper();
      recommendationService = RecommendationService(
        dbHelper: mockDbHelper,
        registerDefaultFactors: true,
      );
      // Unregister randomization factor for deterministic results
      recommendationService.unregisterFactor('randomization');
    });

    tearDown(() {
      mockDbHelper.resetAllData();
    });

    test('should have id "user_feedback"', () {
      expect(factor.id, equals('user_feedback'));
    });

    test('should have weight 15', () {
      expect(factor.defaultWeight, equals(15));
    });

    test('should require feedbackHistory data', () {
      expect(factor.requiredData, contains('feedbackHistory'));
      expect(factor.requiredData.length, equals(1));
    });

    test('should return neutral score when no feedback history available', () async {
      // Arrange
      final recipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Test Recipe',
        createdAt: DateTime.now(),
      );

      final context = <String, dynamic>{
        'feedbackHistory': null, // No feedback history
      };

      // Act
      final score = await factor.calculateScore(recipe, context);

      // Assert
      expect(score, equals(70.0)); // Neutral score
    });

    test('should return neutral score when recipe has no feedback', () async {
      // Arrange
      final recipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Test Recipe',
        createdAt: DateTime.now(),
      );

      final context = <String, dynamic>{
        'feedbackHistory': <String, List<Map<String, dynamic>>>{
          // Empty feedback history
        },
      };

      // Act
      final score = await factor.calculateScore(recipe, context);

      // Assert
      expect(score, equals(70.0)); // Neutral score for no feedback
    });

    group('Feedback Impact Calculations', () {
      late Recipe testRecipe;
      late DateTime now;

      setUp(() {
        testRecipe = Recipe(
          id: 'test-recipe-id',
          name: 'Test Recipe',
          createdAt: DateTime.now(),
        );
        now = DateTime.now();
      });

      test('should apply negative adjustment for lessOften feedback', () async {
        // Arrange
        final context = <String, dynamic>{
          'feedbackHistory': <String, List<Map<String, dynamic>>>{
            'test-recipe-id': [
              {
                'user_response': 'lessOften',
                'responded_at': now.subtract(const Duration(days: 5)).toIso8601String(),
                'total_score': 80.0,
                'created_at': now.subtract(const Duration(days: 5)).toIso8601String(),
              },
            ],
          },
        };

        // Act
        final score = await factor.calculateScore(testRecipe, context);

        // Assert
        expect(score, lessThan(70.0)); // Should be below neutral due to negative feedback
        
        // Calculate expected score with dampening:
        // lessOften = -15% = -0.15
        // With single feedback: dampening = log(1+1) / log(6) = log(2) / log(6) ≈ 0.3869
        // Final adjustment = -15 * 0.3869 ≈ -5.8
        // Expected score = 70 + (-5.8) = 64.2
        expect(score, closeTo(64.2, 0.5)); // With single feedback dampening
      });

      test('should apply positive adjustment for moreOften feedback', () async {
        // Arrange
        final context = <String, dynamic>{
          'feedbackHistory': <String, List<Map<String, dynamic>>>{
            'test-recipe-id': [
              {
                'user_response': 'moreOften',
                'responded_at': now.subtract(const Duration(days: 5)).toIso8601String(),
                'total_score': 80.0,
                'created_at': now.subtract(const Duration(days: 5)).toIso8601String(),
              },
            ],
          },
        };

        // Act
        final score = await factor.calculateScore(testRecipe, context);

        // Assert
        expect(score, greaterThan(70.0)); // Should be above neutral due to positive feedback
        
        // Calculate expected score with dampening:
        // moreOften = +20% = +0.20
        // With single feedback: dampening = log(1+1) / log(6) = log(2) / log(6) ≈ 0.3869
        // Final adjustment = +20 * 0.3869 ≈ +7.7
        // Expected score = 70 + (+7.7) = 77.7
        expect(score, closeTo(77.7, 0.5)); // With single feedback dampening
      });

      test('should apply strong negative adjustment for neverAgain feedback', () async {
        // Arrange
        final context = <String, dynamic>{
          'feedbackHistory': <String, List<Map<String, dynamic>>>{
            'test-recipe-id': [
              {
                'user_response': 'neverAgain',
                'responded_at': now.subtract(const Duration(days: 5)).toIso8601String(),
                'total_score': 80.0,
                'created_at': now.subtract(const Duration(days: 5)).toIso8601String(),
              },
            ],
          },
        };

        // Act
        final score = await factor.calculateScore(testRecipe, context);

        // Assert
        expect(score, lessThan(70.0)); // Should be below neutral
        
        // Calculate expected score with dampening:
        // neverAgain = -40% = -0.40
        // With single feedback: dampening = log(1+1) / log(6) = log(2) / log(6) ≈ 0.3869
        // Final adjustment = -40 * 0.3869 ≈ -15.5
        // Expected score = 70 + (-15.5) = 54.5
        expect(score, closeTo(54.5, 0.5)); // With single feedback dampening
      });

      test('should apply positive adjustment for accepted feedback', () async {
        // Arrange
        final context = <String, dynamic>{
          'feedbackHistory': <String, List<Map<String, dynamic>>>{
            'test-recipe-id': [
              {
                'user_response': 'accepted',
                'responded_at': now.subtract(const Duration(days: 3)).toIso8601String(),
                'total_score': 85.0,
                'created_at': now.subtract(const Duration(days: 3)).toIso8601String(),
              },
            ],
          },
        };

        // Act
        final score = await factor.calculateScore(testRecipe, context);

        // Assert
        expect(score, greaterThan(70.0)); // Should be above neutral
        
        // Calculate expected score with dampening:
        // accepted = +25% = +0.25
        // With single feedback: dampening = log(1+1) / log(6) = log(2) / log(6) ≈ 0.3869
        // Final adjustment = +25 * 0.3869 ≈ +9.7
        // Expected score = 70 + (+9.7) = 79.7
        expect(score, closeTo(79.7, 0.5)); // With single feedback dampening
      });

      test('should ignore notToday feedback (no impact)', () async {
        // Arrange
        final context = <String, dynamic>{
          'feedbackHistory': <String, List<Map<String, dynamic>>>{
            'test-recipe-id': [
              {
                'user_response': 'notToday',
                'responded_at': now.subtract(const Duration(days: 1)).toIso8601String(),
                'total_score': 75.0,
                'created_at': now.subtract(const Duration(days: 1)).toIso8601String(),
              },
            ],
          },
        };

        // Act
        final score = await factor.calculateScore(testRecipe, context);

        // Assert
        expect(score, equals(70.0)); // Should remain neutral
      });

      test('should ignore ignored feedback (no impact)', () async {
        // Arrange
        final context = <String, dynamic>{
          'feedbackHistory': <String, List<Map<String, dynamic>>>{
            'test-recipe-id': [
              {
                'user_response': 'ignored',
                'responded_at': now.subtract(const Duration(days: 2)).toIso8601String(),
                'total_score': 75.0,
                'created_at': now.subtract(const Duration(days: 2)).toIso8601String(),
              },
            ],
          },
        };

        // Act
        final score = await factor.calculateScore(testRecipe, context);

        // Assert
        expect(score, equals(70.0)); // Should remain neutral
      });
    });

    group('Temporal Decay', () {
      late Recipe testRecipe;
      late DateTime now;

      setUp(() {
        testRecipe = Recipe(
          id: 'test-recipe-id',
          name: 'Test Recipe',
          createdAt: DateTime.now(),
        );
        now = DateTime.now();
      });

      test('should apply full impact for recent feedback (within 30 days)', () async {
        // Arrange
        final context = <String, dynamic>{
          'feedbackHistory': <String, List<Map<String, dynamic>>>{
            'test-recipe-id': [
              {
                'user_response': 'lessOften',
                'responded_at': now.subtract(const Duration(days: 15)).toIso8601String(),
                'total_score': 80.0,
                'created_at': now.subtract(const Duration(days: 15)).toIso8601String(),
              },
            ],
          },
        };

        // Act
        final score = await factor.calculateScore(testRecipe, context);

        // Assert
        // Recent feedback gets full temporal impact (no decay) but still dampened for single feedback
        // lessOften = -15%, dampening ≈ 0.3869
        // Expected score = 70 + (-15 * 0.3869) = 70 - 5.8 = 64.2
        expect(score, closeTo(64.2, 0.5)); // Full temporal impact with dampening
      });

      test('should apply reduced impact for older feedback (6 months)', () async {
        // Arrange
        final context = <String, dynamic>{
          'feedbackHistory': <String, List<Map<String, dynamic>>>{
            'test-recipe-id': [
              {
                'user_response': 'lessOften',
                'responded_at': now.subtract(const Duration(days: 180)).toIso8601String(), // 6 months old
                'total_score': 80.0,
                'created_at': now.subtract(const Duration(days: 180)).toIso8601String(),
              },
            ],
          },
        };

        // Act
        final score = await factor.calculateScore(testRecipe, context);

        // Assert
        expect(score, greaterThan(64.2)); // Should be less impact than recent feedback
        expect(score, lessThan(70.0)); // But still some impact
        
        // Calculate expected score with temporal decay:
        // 180 days old: decay = 1.0 - ((180-30) / (365-30)) = 1.0 - (150/335) ≈ 0.552
        // lessOften = -15%, dampening ≈ 0.3869, decay ≈ 0.552
        // Final adjustment = -15 * 0.3869 * 0.552 ≈ -3.2
        // Expected score = 70 + (-3.2) = 66.8
        expect(score, closeTo(66.8, 0.5)); // With temporal decay and dampening
      });

      test('should ignore very old feedback (over 12 months)', () async {
        // Arrange
        final context = <String, dynamic>{
          'feedbackHistory': <String, List<Map<String, dynamic>>>{
            'test-recipe-id': [
              {
                'user_response': 'lessOften',
                'responded_at': now.subtract(const Duration(days: 400)).toIso8601String(), // Over 1 year old
                'total_score': 80.0,
                'created_at': now.subtract(const Duration(days: 400)).toIso8601String(),
              },
            ],
          },
        };

        // Act
        final score = await factor.calculateScore(testRecipe, context);

        // Assert
        expect(score, equals(70.0)); // Should ignore old feedback completely
      });
    });

    group('Multiple Feedback Handling', () {
      late Recipe testRecipe;
      late DateTime now;

      setUp(() {
        testRecipe = Recipe(
          id: 'test-recipe-id',
          name: 'Test Recipe',
          createdAt: DateTime.now(),
        );
        now = DateTime.now();
      });

      test('should average multiple feedback entries', () async {
        // Arrange
        final context = <String, dynamic>{
          'feedbackHistory': <String, List<Map<String, dynamic>>>{
            'test-recipe-id': [
              {
                'user_response': 'moreOften', // +20%
                'responded_at': now.subtract(const Duration(days: 5)).toIso8601String(),
                'total_score': 80.0,
                'created_at': now.subtract(const Duration(days: 5)).toIso8601String(),
              },
              {
                'user_response': 'lessOften', // -15%
                'responded_at': now.subtract(const Duration(days: 10)).toIso8601String(),
                'total_score': 75.0,
                'created_at': now.subtract(const Duration(days: 10)).toIso8601String(),
              },
            ],
          },
        };

        // Act
        final score = await factor.calculateScore(testRecipe, context);

        // Assert
        // Average of +20% and -15% = +2.5%
        // With 2 feedback entries: dampening = log(2+1) / log(6) = log(3) / log(6) ≈ 0.613
        // Final adjustment = +2.5 * 0.613 ≈ +1.5
        // Expected score = 70 + (+1.5) = 71.5
        expect(score, closeTo(71.5, 0.5));
      });

      test('should apply dampening for limited feedback sample', () async {
        // Arrange - single feedback entry should be dampened
        final context = <String, dynamic>{
          'feedbackHistory': <String, List<Map<String, dynamic>>>{
            'test-recipe-id': [
              {
                'user_response': 'neverAgain', // -40% but should be dampened
                'responded_at': now.subtract(const Duration(days: 5)).toIso8601String(),
                'total_score': 80.0,
                'created_at': now.subtract(const Duration(days: 5)).toIso8601String(),
              },
            ],
          },
        };

        // Act
        final score = await factor.calculateScore(testRecipe, context);

        // Assert
        // Single feedback should be dampened, so impact should be less than full -40%
        expect(score, greaterThan(30.0)); // Should be higher than full impact (30.0)
        expect(score, lessThan(70.0)); // But still below neutral
        
        // With single feedback: dampening ≈ 0.3869
        // Expected score = 70 + (-40 * 0.3869) = 70 - 15.5 = 54.5
        expect(score, closeTo(54.5, 0.5)); // Dampened impact for single feedback
      });
    });

    group('Edge Cases', () {
      late Recipe testRecipe;

      setUp(() {
        testRecipe = Recipe(
          id: 'test-recipe-id',
          name: 'Test Recipe',
          createdAt: DateTime.now(),
        );
      });

      test('should handle malformed feedback gracefully', () async {
        // Arrange
        final context = <String, dynamic>{
          'feedbackHistory': <String, List<Map<String, dynamic>>>{
            'test-recipe-id': [
              {
                'user_response': 'invalidResponse', // Invalid response type
                'responded_at': DateTime.now().toIso8601String(),
                'total_score': 80.0,
                'created_at': DateTime.now().toIso8601String(),
              },
            ],
          },
        };

        // Act & Assert - Should not throw
        final score = await factor.calculateScore(testRecipe, context);
        expect(score, equals(70.0)); // Should fallback to neutral
      });

      test('should clamp scores to valid range (0-100)', () async {
        // Arrange - Multiple strong negative feedback that could push below 0
        final now = DateTime.now();
        final context = <String, dynamic>{
          'feedbackHistory': <String, List<Map<String, dynamic>>>{
            'test-recipe-id': List.generate(10, (i) => {
              'user_response': 'neverAgain', // -40% each
              'responded_at': now.subtract(Duration(days: i + 1)).toIso8601String(),
              'total_score': 80.0,
              'created_at': now.subtract(Duration(days: i + 1)).toIso8601String(),
            }),
          },
        };

        // Act
        final score = await factor.calculateScore(testRecipe, context);

        // Assert
        expect(score, greaterThanOrEqualTo(0.0)); // Should not go below 0
        expect(score, lessThanOrEqualTo(100.0)); // Should not go above 100
      });
    });
  });
}