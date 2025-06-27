import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
//import 'package:gastrobrain/main.dart' as app;
import 'package:gastrobrain/database/database_helper.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/models/meal.dart';
import 'package:gastrobrain/models/protein_type.dart';
import 'package:gastrobrain/models/ingredient.dart';
import 'package:gastrobrain/models/recipe_ingredient.dart';
import 'package:gastrobrain/core/services/recommendation_service.dart';
import 'package:gastrobrain/core/services/recommendation_factors/frequency_factor.dart';
import 'package:gastrobrain/core/di/service_provider.dart';
import 'package:gastrobrain/utils/id_generator.dart';

import '../test/mocks/mock_database_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Recommendation System Integration Tests', () {
    late DatabaseHelper dbHelper;
    late RecommendationService recommendationService;

    // Test recipes with various attributes to test different recommendation factors
    final testRecipes = <Recipe>[];
    final DateTime now = DateTime.now();

    /// Creates test recipes with various attributes to test different recommendation factors
    Future<void> setupTestRecipes() async {
      // 1. Recipe that was recently cooked (should score low on frequency)
      final recentlyUsedRecipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Recently Cooked Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 4,
        difficulty: 2,
        prepTimeMinutes: 15,
        cookTimeMinutes: 30,
      );
      testRecipes.add(recentlyUsedRecipe);

      // 2. Recipe that hasn't been cooked in a while (should score high on frequency)
      final overdueRecipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Overdue Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 3,
        difficulty: 3,
        prepTimeMinutes: 20,
        cookTimeMinutes: 40,
      );
      testRecipes.add(overdueRecipe);

      // 3. Recipe with high difficulty (should score lower on weekdays)
      final difficultRecipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Difficult Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 5,
        difficulty: 5,
        prepTimeMinutes: 45,
        cookTimeMinutes: 90,
      );
      testRecipes.add(difficultRecipe);

      // 4. Recipe with commonly used protein (should score lower on protein rotation)
      final commonProteinRecipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Beef Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: now,
        rating: 4,
        difficulty: 3,
        prepTimeMinutes: 25,
        cookTimeMinutes: 35,
      );
      testRecipes.add(commonProteinRecipe);

      // 5. Recipe with uncommon protein (should score higher on protein rotation)
      final uncommonProteinRecipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Fish Recipe',
        desiredFrequency: FrequencyType.biweekly,
        createdAt: now,
        rating: 4,
        difficulty: 4,
        prepTimeMinutes: 20,
        cookTimeMinutes: 25,
      );
      testRecipes.add(uncommonProteinRecipe);

      // Add all recipes to database
      for (final recipe in testRecipes) {
        await dbHelper.insertRecipe(recipe);
      }

      // Set up protein types for recipes
      // For MockDatabaseHelper, we can set protein types directly
      if (dbHelper is MockDatabaseHelper) {
        final mockDb = dbHelper as MockDatabaseHelper;
        mockDb.recipeProteinTypes = {
          commonProteinRecipe.id: [ProteinType.beef],
          uncommonProteinRecipe.id: [ProteinType.fish],
          recentlyUsedRecipe.id: [ProteinType.chicken],
          overdueRecipe.id: [ProteinType.pork],
          difficultRecipe.id: [ProteinType.plantBased],
        };
      } else {
        // For a real database, create ingredients with protein types and link them to recipes
        try {
          // Create protein ingredients
          final beefIngredient = Ingredient(
            id: IdGenerator.generateId(),
            name: 'Test Beef',
            category: 'protein',
            proteinType: ProteinType.beef.name,
          );

          final fishIngredient = Ingredient(
            id: IdGenerator.generateId(),
            name: 'Test Fish',
            category: 'protein',
            proteinType: ProteinType.fish.name,
          );

          final chickenIngredient = Ingredient(
            id: IdGenerator.generateId(),
            name: 'Test Chicken',
            category: 'protein',
            proteinType: ProteinType.chicken.name,
          );

          final porkIngredient = Ingredient(
            id: IdGenerator.generateId(),
            name: 'Test Pork',
            category: 'protein',
            proteinType: ProteinType.pork.name,
          );

          final plantBasedIngredient = Ingredient(
            id: IdGenerator.generateId(),
            name: 'Test Plant Protein',
            category: 'protein',
            proteinType: ProteinType.plantBased.name,
          );

          // Add ingredients to database
          await dbHelper.insertIngredient(beefIngredient);
          await dbHelper.insertIngredient(fishIngredient);
          await dbHelper.insertIngredient(chickenIngredient);
          await dbHelper.insertIngredient(porkIngredient);
          await dbHelper.insertIngredient(plantBasedIngredient);

          // Link ingredients to recipes
          final recipeIngredients = [
            RecipeIngredient(
              id: IdGenerator.generateId(),
              recipeId: commonProteinRecipe.id,
              ingredientId: beefIngredient.id,
              quantity: 500.0,
            ),
            RecipeIngredient(
              id: IdGenerator.generateId(),
              recipeId: uncommonProteinRecipe.id,
              ingredientId: fishIngredient.id,
              quantity: 400.0,
            ),
            RecipeIngredient(
              id: IdGenerator.generateId(),
              recipeId: recentlyUsedRecipe.id,
              ingredientId: chickenIngredient.id,
              quantity: 500.0,
            ),
            RecipeIngredient(
              id: IdGenerator.generateId(),
              recipeId: overdueRecipe.id,
              ingredientId: porkIngredient.id,
              quantity: 400.0,
            ),
            RecipeIngredient(
              id: IdGenerator.generateId(),
              recipeId: difficultRecipe.id,
              ingredientId: plantBasedIngredient.id,
              quantity: 300.0,
            ),
          ];

          // Add recipe ingredients to database
          for (final ri in recipeIngredients) {
            await dbHelper.addIngredientToRecipe(ri);
          }
        } catch (e) {
          // ignore: avoid_print
          print('Error setting up protein types: $e');
          // ignore: avoid_print
          print('Tests involving protein rotation may not work correctly');
        }
      }

      // Set up meal history by creating meals for certain recipes
      // 1. Recently used recipe - cooked yesterday
      final recentMeal = Meal(
        id: IdGenerator.generateId(),
        recipeId: recentlyUsedRecipe.id,
        cookedAt: now.subtract(const Duration(days: 1)),
        servings: 2,
        wasSuccessful: true,
      );
      await dbHelper.insertMeal(recentMeal);

      // 2. Overdue recipe - cooked 3 weeks ago
      final overdueMeal = Meal(
        id: IdGenerator.generateId(),
        recipeId: overdueRecipe.id,
        cookedAt: now.subtract(const Duration(days: 21)),
        servings: 4,
        wasSuccessful: true,
      );
      await dbHelper.insertMeal(overdueMeal);

      // 3. Common protein recipe - cooked 2 days ago (for protein rotation testing)
      final commonProteinMeal = Meal(
        id: IdGenerator.generateId(),
        recipeId: commonProteinRecipe.id,
        cookedAt: now.subtract(const Duration(days: 2)),
        servings: 3,
        wasSuccessful: true,
      );
      await dbHelper.insertMeal(commonProteinMeal);

      // 4. Create a "dummy" meal with beef protein to establish beef as a commonly used protein
      // We'll use the common protein recipe again
      final anotherBeefMeal = Meal(
        id: IdGenerator.generateId(),
        recipeId: commonProteinRecipe.id,
        cookedAt: now.subtract(const Duration(days: 5)),
        servings: 2,
        wasSuccessful: true,
      );
      await dbHelper.insertMeal(anotherBeefMeal);

      // 5. Uncommon protein recipe - cooked 4 weeks ago (for protein rotation testing)
      final uncommonProteinMeal = Meal(
        id: IdGenerator.generateId(),
        recipeId: uncommonProteinRecipe.id,
        cookedAt: now.subtract(const Duration(days: 28)),
        servings: 2,
        wasSuccessful: true,
      );
      await dbHelper.insertMeal(uncommonProteinMeal);
    }

    setUpAll(() async {
      // Set up database using ServiceProvider pattern
      dbHelper = DatabaseHelper();
      await dbHelper.resetDatabaseForTests();
      
      // Inject the test database helper into ServiceProvider
      ServiceProvider.database.setDatabaseHelper(dbHelper);

      // Create and set up test recipes
      await setupTestRecipes();

      // Get recommendation service from provider
      recommendationService =
          ServiceProvider.recommendations.recommendationService;
    });

    tearDownAll(() async {
      // Clean up
      for (final recipe in testRecipes) {
        try {
          await dbHelper.deleteRecipe(recipe.id);
        } catch (e) {
          // Ignore errors during cleanup
        }
      }
    });

    testWidgets('RecommendationService returns expected recommendations',
        (WidgetTester tester) async {
      // This test verifies that the recommendation service returns expected results
      // without involving the UI - pure service integration test

      // Get detailed recommendations to see factor scores and rankings
      final results =
          await recommendationService.getDetailedRecommendations(count: 10);
      final recommendations = results.recommendations;

      // Verify we got recommendations
      expect(recommendations.isNotEmpty, isTrue,
          reason: "Should return recommendations");

      // Extract recipe IDs for testing
      final recentlyUsedRecipe =
          testRecipes.firstWhere((r) => r.name == 'Recently Cooked Recipe');
      final overdueRecipe =
          testRecipes.firstWhere((r) => r.name == 'Overdue Recipe');
      final difficultRecipe =
          testRecipes.firstWhere((r) => r.name == 'Difficult Recipe');
      final commonProteinRecipe =
          testRecipes.firstWhere((r) => r.name == 'Beef Recipe');
      final uncommonProteinRecipe = testRecipes.firstWhere(
          (r) => r.name.contains('Fish Recipe'),
          orElse: () => testRecipes.firstWhere((r) =>
              r.name != 'Recently Cooked Recipe' &&
              r.name != 'Overdue Recipe' &&
              r.name != 'Difficult Recipe' &&
              r.name != 'Beef Recipe'));

      // Find our test recipes in the recommendations
      final recentlyUsedIndex = recommendations
          .indexWhere((r) => r.recipe.id == recentlyUsedRecipe.id);
      final overdueIndex =
          recommendations.indexWhere((r) => r.recipe.id == overdueRecipe.id);
      final difficultIndex =
          recommendations.indexWhere((r) => r.recipe.id == difficultRecipe.id);
      final commonProteinIndex = recommendations
          .indexWhere((r) => r.recipe.id == commonProteinRecipe.id);
      final uncommonProteinIndex = recommendations
          .indexWhere((r) => r.recipe.id == uncommonProteinRecipe.id);

      // Create a map of found indices for easier logging
      final indices = {
        'Recently Cooked Recipe': recentlyUsedIndex,
        'Overdue Recipe': overdueIndex,
        'Difficult Recipe': difficultIndex,
        'Beef Recipe (common protein)': commonProteinIndex,
        'Fish Recipe (uncommon protein)': uncommonProteinIndex,
      };

      // Print which recipes were found in recommendations
      indices.forEach((name, index) {
        if (index != -1) {
          // ignore: avoid_print
          print('$name found at position ${index + 1}');
        } else {
          // ignore: avoid_print
          print(
              '$name not found in top ${recommendations.length} recommendations');
        }
      });

      // Verify that at least some test recipes are included
      expect(indices.values.any((index) => index != -1), isTrue,
          reason: "At least one test recipe should be in recommendations");

      // Validate frequency-based ordering
      if (recentlyUsedIndex != -1 && overdueIndex != -1) {
        expect(overdueIndex < recentlyUsedIndex, isTrue,
            reason:
                "Overdue recipe should rank higher than recently used recipe");

        // Verify factor scores
        final recentlyUsedFreqScore =
            recommendations[recentlyUsedIndex].factorScores['frequency']!;
        final overdueFreqScore =
            recommendations[overdueIndex].factorScores['frequency']!;

        expect(overdueFreqScore > recentlyUsedFreqScore, isTrue,
            reason: "Overdue recipe should have higher frequency score");
      }

      // Validate protein rotation ordering
      if (commonProteinIndex != -1 && uncommonProteinIndex != -1) {
        // Verify that uncommon protein recipe scores higher on protein rotation
        final commonProteinRotationScore = recommendations[commonProteinIndex]
            .factorScores['protein_rotation']!;
        final uncommonProteinRotationScore =
            recommendations[uncommonProteinIndex]
                .factorScores['protein_rotation']!;

        expect(
            uncommonProteinRotationScore > commonProteinRotationScore, isTrue,
            reason:
                "Uncommon protein recipe should have higher protein rotation score");

        // Overall ranking depends on ALL factors, not just protein rotation,
        // so we don't strictly expect uncommonProteinIndex < commonProteinIndex
      }

      // Validate difficulty factor
      if (difficultIndex != -1) {
        final difficultScore =
            recommendations[difficultIndex].factorScores['difficulty']!;

        // Difficulty factor should give low scores to difficult recipes (5 difficulty)
        expect(difficultScore <= 50.0, isTrue,
            reason: "Difficult recipe should have low difficulty score");
      }

      // Verify all standard factors are present for all recommendations
      for (final recommendation in recommendations) {
        expect(recommendation.factorScores.containsKey('frequency'), isTrue);
        expect(recommendation.factorScores.containsKey('protein_rotation'),
            isTrue);
        expect(recommendation.factorScores.containsKey('rating'), isTrue);
        expect(recommendation.factorScores.containsKey('difficulty'), isTrue);
        expect(recommendation.factorScores.containsKey('variety_encouragement'),
            isTrue);
        expect(
            recommendation.factorScores.containsKey('randomization'), isTrue);
      }
    });

    testWidgets('Verify meal history and frequency calculation',
        (WidgetTester tester) async {
      // Step 1: Create two recipes with different cooking dates
      final recentRecipeId = IdGenerator.generateId();
      final overdueRecipeId = IdGenerator.generateId();

      final recentRecipe = Recipe(
        id: recentRecipeId,
        name: 'Recent Test Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
      );

      final overdueRecipe = Recipe(
        id: overdueRecipeId,
        name: 'Overdue Test Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
      );

      // Add to database
      await dbHelper.insertRecipe(recentRecipe);
      await dbHelper.insertRecipe(overdueRecipe);

      // Step 2: Create meal history with explicit dates
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final monthAgo = now.subtract(const Duration(days: 30));

      // Create meals with these specific dates
      final recentMeal = Meal(
        id: IdGenerator.generateId(),
        recipeId: recentRecipeId,
        cookedAt: yesterday,
        servings: 2,
        wasSuccessful: true,
      );

      final overdueMeal = Meal(
        id: IdGenerator.generateId(),
        recipeId: overdueRecipeId,
        cookedAt: monthAgo,
        servings: 2,
        wasSuccessful: true,
      );

      // Insert meals
      await dbHelper.insertMeal(recentMeal);
      await dbHelper.insertMeal(overdueMeal);

      // Step 3: Verify the meal history was recorded correctly
      final recentLastCooked = await dbHelper.getLastCookedDate(recentRecipeId);
      final overdueLastCooked =
          await dbHelper.getLastCookedDate(overdueRecipeId);

      expect(recentLastCooked, isNotNull);
      expect(overdueLastCooked, isNotNull);

      // Verify approximate dates (within a day)
      expect(
          (recentLastCooked!.difference(yesterday)).inHours.abs() < 24, isTrue,
          reason: "Recent recipe should be cooked yesterday");
      expect(
          (overdueLastCooked!.difference(monthAgo)).inHours.abs() < 24, isTrue,
          reason: "Overdue recipe should be cooked a month ago");

      // Step 4: Create a frequency factor directly and test its calculation
      final frequencyFactor = FrequencyFactor();

      // Create context with the last cooked dates for our test
      final context = {
        'lastCooked': {
          recentRecipeId: yesterday,
          overdueRecipeId: monthAgo,
        }
      };

      // Calculate scores directly
      final recentScore =
          await frequencyFactor.calculateScore(recentRecipe, context);
      final overdueScore =
          await frequencyFactor.calculateScore(overdueRecipe, context);

      // The overdue recipe should have a higher frequency score
      expect(overdueScore > recentScore, isTrue,
          reason:
              "Overdue recipe should have higher frequency score than recent recipe");

      // Step 5: Get full recommendations and verify
      final results = await recommendationService.getDetailedRecommendations();

      // Find our recipes in the results
      final recentRecIndex = results.recommendations
          .indexWhere((r) => r.recipe.id == recentRecipeId);
      final overdueRecIndex = results.recommendations
          .indexWhere((r) => r.recipe.id == overdueRecipeId);

      if (recentRecIndex != -1 && overdueRecIndex != -1) {
        final recentRecommendation = results.recommendations[recentRecIndex];
        final overdueRecommendation = results.recommendations[overdueRecIndex];

        final recentFreqScore = recentRecommendation.factorScores['frequency']!;
        final overdueFreqScore =
            overdueRecommendation.factorScores['frequency']!;

        expect(overdueFreqScore > recentFreqScore, isTrue,
            reason:
                "Overdue recipe should have higher frequency score in full recommendations");
      }
    });

    testWidgets('Recommendation system prioritizes overdue recipes',
        (WidgetTester tester) async {
      // Create two recipes with different cooking dates
      final recentRecipeId = IdGenerator.generateId();
      final overdueRecipeId = IdGenerator.generateId();

      final recentRecipe = Recipe(
        id: recentRecipeId,
        name: 'Recent Test Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
        rating:
            4, // Good rating to ensure it's only the frequency that's lowering its rank
      );

      final overdueRecipe = Recipe(
        id: overdueRecipeId,
        name: 'Overdue Test Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
        rating:
            3, // Slightly lower rating to make the frequency factor more impactful
      );

      // Add to database
      await dbHelper.insertRecipe(recentRecipe);
      await dbHelper.insertRecipe(overdueRecipe);

      // Create meal history
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final monthAgo = now.subtract(const Duration(days: 30));

      // Create meals with these specific dates
      final recentMeal = Meal(
        id: IdGenerator.generateId(),
        recipeId: recentRecipeId,
        cookedAt: yesterday,
        servings: 2,
        wasSuccessful: true,
      );

      final overdueMeal = Meal(
        id: IdGenerator.generateId(),
        recipeId: overdueRecipeId,
        cookedAt: monthAgo,
        servings: 2,
        wasSuccessful: true,
      );

      // Insert meals
      await dbHelper.insertMeal(recentMeal);
      await dbHelper.insertMeal(overdueMeal);

      // Get recommendations
      final recommendations =
          await recommendationService.getRecommendations(count: 5);

      // Verify the overdue recipe is included in recommendations
      final containsOverdueRecipe =
          recommendations.any((r) => r.id == overdueRecipeId);
      expect(containsOverdueRecipe, isTrue,
          reason: "Overdue recipe should be included in recommendations");

      // Get detailed recommendations to see scores
      final results =
          await recommendationService.getDetailedRecommendations(count: 5);
      final detailedRecs = results.recommendations;

      // Check if overdue recipe has a good rank
      final overdueRecIndex =
          detailedRecs.indexWhere((r) => r.recipe.id == overdueRecipeId);
      expect(overdueRecIndex != -1, isTrue,
          reason: "Overdue recipe should be in detailed recommendations");

      // Find rank of recent recipe if present
      final recentRecIndex =
          detailedRecs.indexWhere((r) => r.recipe.id == recentRecipeId);
      if (recentRecIndex != -1) {
        // Verify ranking (overdue should rank higher than recent)
        expect(overdueRecIndex < recentRecIndex, isTrue,
            reason: "Overdue recipe should rank higher than recent recipe");
      }
    });
  });
}
