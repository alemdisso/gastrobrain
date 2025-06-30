import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/models/recipe_recommendation.dart';
import 'package:gastrobrain/models/recommendation_results.dart';
import 'package:gastrobrain/utils/id_generator.dart';
import '../mocks/mock_database_helper.dart';

void main() {
  group('User Response Tracking', () {
    late Recipe testRecipe;
    late MockDatabaseHelper mockDbHelper;

    setUp(() async {
      // Set up test recipe
      testRecipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Test Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
      );

      // Set up mock database
      mockDbHelper = MockDatabaseHelper();
      
      // Add test recipe to mock database
      await mockDbHelper.insertRecipe(testRecipe);
    });

    test('can create recommendation with all response types', () {
      // Test all possible UserResponse values
      final responses = {
        UserResponse.accepted: 'accepted',
        UserResponse.rejected: 'rejected',
        UserResponse.saved: 'saved',
        UserResponse.ignored: 'ignored',
      };

      // Test each response type
      for (final entry in responses.entries) {
        final response = entry.key;
        final expectedName = entry.value;

        final recommendation = RecipeRecommendation(
          recipe: testRecipe,
          totalScore: 85.0,
          factorScores: {'test': 85.0},
          userResponse: response,
          respondedAt: DateTime.now(),
        );

        // Verify response is correctly set
        expect(recommendation.userResponse, equals(response));

        // Verify response name
        expect(recommendation.userResponse!.name, equals(expectedName));
      }
    });

    test('handles null user response correctly', () {
      final recommendation = RecipeRecommendation(
        recipe: testRecipe,
        totalScore: 85.0,
        factorScores: {'test': 85.0},
        // No userResponse or respondedAt
      );

      // Verify response fields are null
      expect(recommendation.userResponse, isNull);
      expect(recommendation.respondedAt, isNull);

      // Verify toJson handles null values
      final json = recommendation.toJson();
      expect(json.containsKey('user_response'), isTrue);
      expect(json['user_response'], isNull);
      expect(json.containsKey('responded_at'), isTrue);
      expect(json['responded_at'], isNull);
    });

    test('correctly serializes and deserializes different response types',
        () async {
      // Test round-trip serialization for each response type
      for (final response in UserResponse.values) {
        final responseDate = DateTime(2024, 3, 15, 12, 30);

        // Create recommendation with response
        final originalRec = RecipeRecommendation(
          recipe: testRecipe,
          totalScore: 85.0,
          factorScores: {'test': 85.0},
          userResponse: response,
          respondedAt: responseDate,
        );

        // Convert to JSON
        final json = originalRec.toJson();

        // Verify response in JSON
        expect(json['user_response'], equals(response.name));
        expect(json['responded_at'], equals(responseDate.toIso8601String()));

        // Reconstruct from JSON
        final reconstructed =
            await RecipeRecommendation.fromJson(json, mockDbHelper);

        // Verify response was preserved
        expect(reconstructed.userResponse, equals(response));
        expect(reconstructed.respondedAt, equals(responseDate));
      }
    });

    test('timestamp handling for response updates', () async {
      // Create initial recommendation with no response
      final initialRec = RecipeRecommendation(
        recipe: testRecipe,
        totalScore: 90.0,
        factorScores: {'test': 90.0},
      );

      // Create results containing the recommendation
      final results = RecommendationResults(
        recommendations: [initialRec],
        totalEvaluated: 5,
        queryParameters: {},
      );

      // Save to history
      final historyId = await mockDbHelper.saveRecommendationHistory(
        results,
        'test_response_timestamps',
      );

      // Record time before update
      final beforeUpdate = DateTime.now();

      // Wait a bit to ensure time difference is detectable
      await Future.delayed(const Duration(milliseconds: 100));

      // Update with user response
      await mockDbHelper.updateRecommendationResponse(
        historyId,
        testRecipe.id,
        UserResponse.accepted,
      );

      // Record time after update
      final afterUpdate = DateTime.now();

      // Retrieve updated recommendation
      final updatedResults = await mockDbHelper.getRecommendationById(historyId);
      expect(updatedResults, isNotNull);
      expect(updatedResults!.recommendations[0].userResponse,
          equals(UserResponse.accepted));

      // Verify timestamp is between before and after
      final responseTimestamp = updatedResults.recommendations[0].respondedAt!;
      expect(
          responseTimestamp.isAfter(beforeUpdate) ||
              responseTimestamp.isAtSameMomentAs(beforeUpdate),
          isTrue);
      expect(
          responseTimestamp.isBefore(afterUpdate) ||
              responseTimestamp.isAtSameMomentAs(afterUpdate),
          isTrue);
    });

    test('updating response after initial creation', () async {
      // Create recommendation with initial response
      final initialRec = RecipeRecommendation(
        recipe: testRecipe,
        totalScore: 90.0,
        factorScores: {'test': 90.0},
        userResponse: UserResponse.saved,
        respondedAt: DateTime(2024, 3, 15),
      );

      // Create results containing the recommendation
      final results = RecommendationResults(
        recommendations: [initialRec],
        totalEvaluated: 5,
        queryParameters: {},
      );

      // Save to history
      final historyId = await mockDbHelper.saveRecommendationHistory(
        results,
        'test_response_update',
      );

      // Update with new response
      await mockDbHelper.updateRecommendationResponse(
        historyId,
        testRecipe.id,
        UserResponse.accepted,
      );

      // Retrieve updated recommendation
      final updatedResults = await mockDbHelper.getRecommendationById(historyId);
      expect(updatedResults, isNotNull);

      // Verify response was changed
      expect(updatedResults!.recommendations[0].userResponse,
          equals(UserResponse.accepted));

      // Verify timestamp was updated (should be more recent)
      expect(
          updatedResults.recommendations[0].respondedAt!
              .isAfter(DateTime(2024, 3, 15)),
          isTrue);
    });

    test('handles multiple recommendations in a single results object',
        () async {
      // Create a second test recipe
      final testRecipe2 = Recipe(
        id: IdGenerator.generateId(),
        name: 'Test Recipe 2',
        desiredFrequency: FrequencyType.monthly,
        createdAt: DateTime.now(),
      );
      await mockDbHelper.insertRecipe(testRecipe2);

      // Create recommendations with different responses
      final rec1 = RecipeRecommendation(
        recipe: testRecipe,
        totalScore: 90.0,
        factorScores: {'test': 90.0},
        userResponse: UserResponse.saved,
        respondedAt: DateTime(2024, 3, 15),
      );

      final rec2 = RecipeRecommendation(
        recipe: testRecipe2,
        totalScore: 80.0,
        factorScores: {'test': 80.0},
        userResponse: UserResponse.rejected,
        respondedAt: DateTime(2024, 3, 16),
      );

      // Create results with both recommendations
      final results = RecommendationResults(
        recommendations: [rec1, rec2],
        totalEvaluated: 5,
        queryParameters: {},
      );

      // Save to history
      final historyId = await mockDbHelper.saveRecommendationHistory(
        results,
        'test_multiple_recs',
      );

      // Update only the first recommendation
      await mockDbHelper.updateRecommendationResponse(
        historyId,
        testRecipe.id,
        UserResponse.accepted,
      );

      // Retrieve results
      final updatedResults = await mockDbHelper.getRecommendationById(historyId);
      expect(updatedResults, isNotNull);

      // Find recommendations by recipe ID
      final updatedRec1 = updatedResults!.recommendations
          .firstWhere((rec) => rec.recipe.id == testRecipe.id);
      final updatedRec2 = updatedResults.recommendations
          .firstWhere((rec) => rec.recipe.id == testRecipe2.id);

      // Verify only the first one was updated
      expect(updatedRec1.userResponse, equals(UserResponse.accepted));
      expect(updatedRec2.userResponse, equals(UserResponse.rejected));

      // Verify the first timestamp was updated while the second wasn't
      expect(updatedRec1.respondedAt!.isAfter(DateTime(2024, 3, 15)), isTrue);
      expect(updatedRec2.respondedAt, equals(DateTime(2024, 3, 16)));
    });

    test('persistence survives reloading from database', () async {
      // Create recommendation with response
      final initialRec = RecipeRecommendation(
        recipe: testRecipe,
        totalScore: 90.0,
        factorScores: {'test': 90.0},
        userResponse: UserResponse.accepted,
        respondedAt: DateTime(2024, 3, 15),
      );

      // Create results
      final results = RecommendationResults(
        recommendations: [initialRec],
        totalEvaluated: 5,
        queryParameters: {},
      );

      // Save to history
      final historyId = await mockDbHelper.saveRecommendationHistory(
        results,
        'test_persistence',
      );

      // Load results with same helper (mock already simulates persistence)
      final reloadedResults =
          await mockDbHelper.getRecommendationById(historyId);
      expect(reloadedResults, isNotNull);

      // Verify response data persisted
      expect(reloadedResults!.recommendations[0].userResponse,
          equals(UserResponse.accepted));
      expect(reloadedResults.recommendations[0].respondedAt,
          equals(DateTime(2024, 3, 15)));
    });

    test('handles new feedback UserResponse enum values correctly', () async {
      // Test all new feedback response types
      final newResponseTypes = [
        UserResponse.notToday,
        UserResponse.lessOften,
        UserResponse.moreOften,
        UserResponse.neverAgain,
      ];

      for (final responseType in newResponseTypes) {
        // Create recommendation with new response type
        final recommendation = RecipeRecommendation(
          recipe: testRecipe,
          totalScore: 75.0,
          factorScores: {'test': 75.0},
          userResponse: responseType,
          respondedAt: DateTime(2024, 3, 15),
        );

        // Test JSON serialization
        final json = recommendation.toJson();
        expect(json['user_response'], equals(responseType.name));

        // Test JSON deserialization
        final reconstructed = await RecipeRecommendation.fromJson(json, mockDbHelper);
        expect(reconstructed.userResponse, equals(responseType));
        expect(reconstructed.respondedAt, equals(DateTime(2024, 3, 15)));
      }
    });

    test('correctly saves and updates feedback responses in recommendation history', () async {
      // Create initial recommendation without feedback
      final recommendation = RecipeRecommendation(
        recipe: testRecipe,
        totalScore: 80.0,
        factorScores: {'frequency': 70.0, 'rating': 90.0},
      );

      final results = RecommendationResults(
        recommendations: [recommendation],
        totalEvaluated: 10,
        queryParameters: {'mealType': 'dinner'},
        generatedAt: DateTime.now(),
      );

      // Save to history
      final historyId = await mockDbHelper.saveRecommendationHistory(
        results,
        'meal_planning',
        targetDate: DateTime(2024, 3, 15),
        mealType: 'dinner',
      );

      // Test updating with new feedback response types
      final feedbackTypes = [
        UserResponse.lessOften,
        UserResponse.moreOften,
        UserResponse.notToday,
        UserResponse.neverAgain,
      ];

      for (final feedbackType in feedbackTypes) {
        // Update with feedback
        final success = await mockDbHelper.updateRecommendationResponse(
          historyId,
          testRecipe.id,
          feedbackType,
        );

        expect(success, isTrue);

        // Verify feedback was saved
        final updatedResults = await mockDbHelper.getRecommendationById(historyId);
        expect(updatedResults, isNotNull);
        expect(updatedResults!.recommendations[0].userResponse, equals(feedbackType));
        expect(updatedResults.recommendations[0].respondedAt, isNotNull);
      }
    });
  });
}
