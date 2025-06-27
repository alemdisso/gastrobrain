import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gastrobrain/database/database_helper.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/models/recipe_recommendation.dart';
import 'package:gastrobrain/models/recommendation_results.dart';
import 'package:gastrobrain/utils/id_generator.dart';

void main() {
  // Initialize FFI
  sqfliteFfiInit();

  // Set the database factory to use the FFI implementation
  databaseFactory = databaseFactoryFfi;

  group('DatabaseHelper Recommendation History Tests', () {
    late DatabaseHelper dbHelper;
    late Recipe testRecipe1;
    late Recipe testRecipe2;

    setUpAll(() async {
      dbHelper = DatabaseHelper();


      // Create test recipes
      testRecipe1 = Recipe(
        id: IdGenerator.generateId(),
        name: 'Test Recipe 1',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
      );

      testRecipe2 = Recipe(
        id: IdGenerator.generateId(),
        name: 'Test Recipe 2',
        desiredFrequency: FrequencyType.monthly,
        createdAt: DateTime.now(),
      );

      // Add recipes to database
      await dbHelper.insertRecipe(testRecipe1);
      await dbHelper.insertRecipe(testRecipe2);
    });

    test('can save and retrieve recommendation history', () async {
      // Create test recommendations
      final recommendation1 = RecipeRecommendation(
        recipe: testRecipe1,
        totalScore: 85.0,
        factorScores: {'test': 85.0},
      );

      final recommendation2 = RecipeRecommendation(
        recipe: testRecipe2,
        totalScore: 75.0,
        factorScores: {'test': 75.0},
      );

      // Create recommendation results
      final results = RecommendationResults(
        recommendations: [recommendation1, recommendation2],
        totalEvaluated: 10,
        queryParameters: {'count': 5, 'mealType': 'lunch'},
      );

      // Save to history
      final historyId = await dbHelper.saveRecommendationHistory(
        results,
        'meal_planning',
        targetDate: DateTime.now(),
        mealType: 'lunch',
      );

      // Verify ID was returned
      expect(historyId, isNotNull);
      expect(historyId.isNotEmpty, true);

      // Retrieve history
      final retrievedResults = await dbHelper.getRecommendationById(historyId);

      // Verify retrieval was successful
      expect(retrievedResults, isNotNull);
      expect(retrievedResults!.recommendations.length, 2);
      expect(retrievedResults.recommendations[0].recipe.id, testRecipe1.id);
      expect(retrievedResults.recommendations[1].recipe.id, testRecipe2.id);
    });

    test('can update user response for recommendation', () async {
      // Create recommendation with no initial response
      final recommendation = RecipeRecommendation(
        recipe: testRecipe1,
        totalScore: 90.0,
        factorScores: {'test': 90.0},
      );

      // Create results
      final results = RecommendationResults(
        recommendations: [recommendation],
        totalEvaluated: 5,
        queryParameters: {},
      );

      // Save to history
      final historyId = await dbHelper.saveRecommendationHistory(
        results,
        'test_context',
      );

      // Update with user response
      final updateResult = await dbHelper.updateRecommendationResponse(
        historyId,
        testRecipe1.id,
        UserResponse.accepted,
      );

      // Verify update was successful
      expect(updateResult, true);

      // Retrieve and verify response was saved
      final updatedResults = await dbHelper.getRecommendationById(historyId);
      expect(updatedResults, isNotNull);
      expect(updatedResults!.recommendations[0].userResponse,
          UserResponse.accepted);
      expect(updatedResults.recommendations[0].respondedAt, isNotNull);
    });

    test('cleanup removes old recommendation history', () async {
      // Create an old recommendation (15 days ago)
      final oldRecommendation = RecipeRecommendation(
        recipe: testRecipe1,
        totalScore: 80.0,
        factorScores: {'test': 80.0},
      );

      final oldResults = RecommendationResults(
        recommendations: [oldRecommendation],
        totalEvaluated: 5,
        queryParameters: {},
        generatedAt: DateTime.now().subtract(const Duration(days: 15)),
      );

      // Save to history with the old date
      final db = await dbHelper.database;
      final oldHistoryId = IdGenerator.generateId();

      await db.insert('recommendation_history', {
        'id': oldHistoryId,
        'result_data': jsonEncode(oldResults.toJson()),
        'created_at':
            DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
        'context_type': 'test_old',
      });

      // Create a recent recommendation
      final newRecommendation = RecipeRecommendation(
        recipe: testRecipe2,
        totalScore: 70.0,
        factorScores: {'test': 70.0},
      );

      final newResults = RecommendationResults(
        recommendations: [newRecommendation],
        totalEvaluated: 5,
        queryParameters: {},
      );

      // Save to history (current date)
      final newHistoryId = await dbHelper.saveRecommendationHistory(
        newResults,
        'test_new',
      );

      // Run cleanup with 14-day retention
      final deletedCount =
          await dbHelper.cleanupRecommendationHistory(daysToKeep: 14);

      // Verify old record was deleted
      expect(deletedCount, greaterThan(0));

      // Verify old record is gone
      final oldRecord = await dbHelper.getRecommendationById(oldHistoryId);
      expect(oldRecord, isNull);

      // Verify new record remains
      final newRecord = await dbHelper.getRecommendationById(newHistoryId);
      expect(newRecord, isNotNull);
    });

    test('getRecommendationHistory returns filtered results', () async {
      // Clear existing history for this test
      final db = await dbHelper.database;
      await db.delete('recommendation_history');

      // Create multiple entries with different contexts
      for (int i = 0; i < 5; i++) {
        final rec = RecipeRecommendation(
          recipe: i % 2 == 0 ? testRecipe1 : testRecipe2,
          totalScore: 80.0 + i,
          factorScores: {'test': 80.0 + i},
        );

        final results = RecommendationResults(
          recommendations: [rec],
          totalEvaluated: 5,
          queryParameters: {},
        );

        final contextType = i % 2 == 0 ? 'type_a' : 'type_b';

        await dbHelper.saveRecommendationHistory(
          results,
          contextType,
        );
      }

      // Test filtering by context type
      final typeAResults =
          await dbHelper.getRecommendationHistory(contextType: 'type_a');
      expect(typeAResults.length, 3); // Should get 3 'type_a' entries

      final typeBResults =
          await dbHelper.getRecommendationHistory(contextType: 'type_b');
      expect(typeBResults.length, 2); // Should get 2 'type_b' entries

      // Test limit
      final limitedResults = await dbHelper.getRecommendationHistory(limit: 2);
      expect(limitedResults.length, 2);
    });
  });
}
