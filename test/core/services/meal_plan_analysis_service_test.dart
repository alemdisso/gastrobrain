import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/core/services/meal_plan_analysis_service.dart';
import 'package:gastrobrain/models/meal.dart';
import 'package:gastrobrain/models/meal_plan.dart';
import 'package:gastrobrain/models/meal_plan_item.dart';
import 'package:gastrobrain/models/meal_plan_item_recipe.dart';
import 'package:gastrobrain/models/meal_recipe.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/protein_type.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/utils/id_generator.dart';
import '../../mocks/mock_database_helper.dart';

void main() {
  late MockDatabaseHelper mockDbHelper;
  late MealPlanAnalysisService analysisService;

  setUp(() async {
    mockDbHelper = MockDatabaseHelper();
    analysisService = MealPlanAnalysisService(mockDbHelper);
  });

  tearDown(() {
    mockDbHelper.resetAllData();
  });

  group('MealPlanAnalysisService Tests', () {
    // Helper function to create a test meal plan with items and recipes
    Future<MealPlan> createTestMealPlan({
      required DateTime weekStartDate,
      required List<Recipe> recipes,
      required List<String> dates,
      required List<String> mealTypes,
    }) async {
      final mealPlanId = IdGenerator.generateId();
      final mealPlan = MealPlan(
        id: mealPlanId,
        weekStartDate: weekStartDate,
        notes: 'Test Plan',
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );

      // Add the meal plan to the mock database
      await mockDbHelper.insertMealPlan(mealPlan);

      // Create meal plan items with recipes
      for (var i = 0; i < dates.length; i++) {
        final itemId = IdGenerator.generateId();
        final item = MealPlanItem(
          id: itemId,
          mealPlanId: mealPlanId,
          plannedDate: dates[i],
          mealType: mealTypes[i],
        );

        // Add the item to the meal plan
        mealPlan.items.add(item);

        // Create recipe association (making first recipe primary for each item)
        final recipe = recipes[i % recipes.length];
        final mealPlanItemRecipe = MealPlanItemRecipe(
          mealPlanItemId: itemId,
          recipeId: recipe.id,
          isPrimaryDish: true,
        );

        // Add recipe association
        item.mealPlanItemRecipes = [mealPlanItemRecipe];
      }

      return mealPlan;
    }

    test('getPlannedRecipeIds returns correct IDs from meal plan', () async {
      // Create test recipes
      final recipes = [
        Recipe(
          id: IdGenerator.generateId(),
          name: 'Recipe 1',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
        ),
        Recipe(
          id: IdGenerator.generateId(),
          name: 'Recipe 2',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
        ),
      ];

      // Add recipes to mock database
      for (final recipe in recipes) {
        await mockDbHelper.insertRecipe(recipe);
      }

      // Create test meal plan with items using these recipes
      final weekStart = DateTime(2024, 1, 1); // Monday
      final mealPlan = await createTestMealPlan(
        weekStartDate: weekStart,
        recipes: recipes,
        dates: [
          '2024-01-01', // Monday
          '2024-01-02', // Tuesday
          '2024-01-03', // Wednesday
        ],
        mealTypes: [
          MealPlanItem.dinner,
          MealPlanItem.lunch,
          MealPlanItem.dinner,
        ],
      );

      // Get planned recipe IDs
      final recipeIds = await analysisService.getPlannedRecipeIds(mealPlan);

      // Verify we get both recipe IDs
      expect(recipeIds.length, 2);
      expect(recipeIds.contains(recipes[0].id), true);
      expect(recipeIds.contains(recipes[1].id), true);
    });

    test('getPlannedProteinsForWeek extracts protein types correctly',
        () async {
      // Create test recipes
      final recipes = [
        Recipe(
          id: IdGenerator.generateId(),
          name: 'Chicken Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
        ),
        Recipe(
          id: IdGenerator.generateId(),
          name: 'Beef Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
        ),
      ];

      // Add recipes to mock database
      for (final recipe in recipes) {
        await mockDbHelper.insertRecipe(recipe);
      }

      // Set up protein types in mock database
      mockDbHelper.recipeProteinTypes = {
        recipes[0].id: [ProteinType.chicken],
        recipes[1].id: [ProteinType.beef],
      };

      // Create test meal plan
      final weekStart = DateTime(2024, 1, 1);
      final mealPlan = await createTestMealPlan(
        weekStartDate: weekStart,
        recipes: recipes,
        dates: [
          '2024-01-01', // Chicken dinner
          '2024-01-02', // Beef lunch
        ],
        mealTypes: [
          MealPlanItem.dinner,
          MealPlanItem.lunch,
        ],
      );

      // Get planned proteins
      final proteins =
          await analysisService.getPlannedProteinsForWeek(mealPlan);

      // Verify protein types are correctly extracted
      expect(proteins.length, 2);
      expect(proteins.contains(ProteinType.chicken), true);
      expect(proteins.contains(ProteinType.beef), true);
    });

    test('handles multiple recipes per meal plan item', () async {
      // Create test recipes
      final recipes = [
        Recipe(
          id: IdGenerator.generateId(),
          name: 'Main Dish',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
        ),
        Recipe(
          id: IdGenerator.generateId(),
          name: 'Side Dish',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
        ),
      ];

      // Add recipes to mock database and set protein types
      for (final recipe in recipes) {
        await mockDbHelper.insertRecipe(recipe);
      }
      mockDbHelper.recipeProteinTypes = {
        recipes[0].id: [ProteinType.chicken],
        recipes[1].id: [ProteinType.plantBased],
      };

      // Create meal plan with one item having multiple recipes
      final mealPlanId = IdGenerator.generateId();
      final mealPlan = MealPlan(
        id: mealPlanId,
        weekStartDate: DateTime(2024, 1, 1),
        notes: 'Multi-recipe test',
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );

      await mockDbHelper.insertMealPlan(mealPlan);

      // Create meal plan item with multiple recipes
      final itemId = IdGenerator.generateId();
      final item = MealPlanItem(
        id: itemId,
        mealPlanId: mealPlanId,
        plannedDate: '2024-01-01',
        mealType: MealPlanItem.dinner,
      );

      mealPlan.items.add(item);

      item.mealPlanItemRecipes = [
        MealPlanItemRecipe(
          mealPlanItemId: itemId,
          recipeId: recipes[0].id,
          isPrimaryDish: true,
        ),
        MealPlanItemRecipe(
          mealPlanItemId: itemId,
          recipeId: recipes[1].id,
          isPrimaryDish: false,
        ),
      ];

      // Test recipe ID extraction
      final recipeIds = await analysisService.getPlannedRecipeIds(mealPlan);
      expect(recipeIds.length, 2);
      expect(recipeIds.contains(recipes[0].id), true);
      expect(recipeIds.contains(recipes[1].id), true);

      // Test protein type extraction
      final proteins =
          await analysisService.getPlannedProteinsForWeek(mealPlan);
      expect(proteins.length, 2);
      expect(proteins.contains(ProteinType.chicken), true);
      expect(proteins.contains(ProteinType.plantBased), true);
    });

    test('handles empty meal plan', () async {
      // Create empty meal plan
      final mealPlan = MealPlan(
        id: IdGenerator.generateId(),
        weekStartDate: DateTime(2024, 1, 1),
        notes: 'Empty plan',
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );

      await mockDbHelper.insertMealPlan(mealPlan);

      // Test empty plan handling
      final recipeIds = await analysisService.getPlannedRecipeIds(mealPlan);
      expect(recipeIds.isEmpty, true);

      final proteins =
          await analysisService.getPlannedProteinsForWeek(mealPlan);
      expect(proteins.isEmpty, true);
    });

    test('handles items with no recipes', () async {
      // Create meal plan with item but no recipes
      final mealPlan = MealPlan(
        id: IdGenerator.generateId(),
        weekStartDate: DateTime(2024, 1, 1),
        notes: 'Plan with empty item',
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );

      await mockDbHelper.insertMealPlan(mealPlan);

      // Add item without any recipes
      final item = MealPlanItem(
        id: IdGenerator.generateId(),
        mealPlanId: mealPlan.id,
        plannedDate: '2024-01-01',
        mealType: MealPlanItem.dinner,
      );

      mealPlan.items.add(item);

      // Test empty item handling
      final recipeIds = await analysisService.getPlannedRecipeIds(mealPlan);
      expect(recipeIds.isEmpty, true);

      final proteins =
          await analysisService.getPlannedProteinsForWeek(mealPlan);
      expect(proteins.isEmpty, true);
    });

    test('handles null meal plan', () async {
      // Test null plan handling
      expect(() => analysisService.getPlannedRecipeIds(null),
          throwsAssertionError);
      expect(() => analysisService.getPlannedProteinsForWeek(null),
          throwsAssertionError);
    });
  });

  group('Recently Cooked Context Tests', () {
    // Helper function to create test meals with different dates
    Future<List<String>> createTestMealsWithDates({
      required List<Recipe> recipes,
      required List<DateTime> dates,
      bool useJunctionTable = true,
    }) async {
      final mealIds = <String>[];

      for (var i = 0; i < dates.length; i++) {
        final recipe = recipes[i % recipes.length];
        final mealId =
            IdGenerator.generateId(); // Create meal with all required fields
        final meal = Meal(
          id: mealId,
          recipeId: useJunctionTable ? null : recipe.id,
          cookedAt: dates[i],
          servings: 4,
          notes: 'Test meal ${i + 1}',
          wasSuccessful: true,
          actualPrepTime: 30,
          actualCookTime: 45,
        );
        await mockDbHelper.insertMeal(meal);

        if (useJunctionTable) {
          // Create meal-recipe junction record
          final mealRecipe = MealRecipe(
            mealId: mealId,
            recipeId: recipe.id,
            isPrimaryDish: true,
            notes: 'Primary dish',
          );
          await mockDbHelper.insertMealRecipe(mealRecipe);
        }

        mealIds.add(mealId);
      }

      return mealIds;
    }

    test('getRecentlyCookedRecipeIds respects dayWindow parameter', () async {
      final today = DateTime(2025, 6, 11); // Current test date

      final recipes = [
        Recipe(
          id: IdGenerator.generateId(),
          name: 'Recent Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: today,
        ),
        Recipe(
          id: IdGenerator.generateId(),
          name: 'Old Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: today,
        ),
      ];

      // Add recipes to mock database
      for (final recipe in recipes) {
        await mockDbHelper.insertRecipe(recipe);
      } // Create meals with different dates
      final dates = [
        today, // Today - Recipe 1
        today.subtract(const Duration(days: 1)), // 1 day ago - Recipe 2
        today.subtract(const Duration(days: 3)), // 3 days ago - Recipe 1
        today.subtract(const Duration(days: 5)), // 5 days ago - Recipe 2
        today.subtract(const Duration(days: 7)), // 7 days ago - Recipe 1
      ];

      // Create meals alternating between both recipes explicitly
      for (var i = 0; i < dates.length; i++) {
        await createTestMealsWithDates(
          recipes: [recipes[i % 2]], // Alternate between recipes
          dates: [dates[i]],
          useJunctionTable: true,
        );
      }      // Test with 3-day window
      var recentIds = await analysisService.getRecentlyCookedRecipeIds(
        dayWindow: 3,
        referenceDate: today,
      );
      expect(recentIds.length,
          2); // Should include today and 1 day ago (both recipes)

      // Test with 5-day window  
      recentIds = await analysisService.getRecentlyCookedRecipeIds(
        dayWindow: 5,
        referenceDate: today,
      );
      expect(recentIds.length, 2); // Should include up to 5 days ago (both recipes)

      // Test with 8-day window (to include the 7-day ago meal)
      recentIds = await analysisService.getRecentlyCookedRecipeIds(
        dayWindow: 8,
        referenceDate: today,
      );
      expect(recentIds.length, 2); // Should include all meals (both recipes)
    });

    test('getRecentlyCookedProteins extracts protein types from recent meals',
        () async {
      final today = DateTime(2025, 6, 11);

      final recipes = [
        Recipe(
          id: IdGenerator.generateId(),
          name: 'Chicken Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: today,
        ),
        Recipe(
          id: IdGenerator.generateId(),
          name: 'Beef Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: today,
        ),
      ];

      // Add recipes to mock database
      for (final recipe in recipes) {
        await mockDbHelper.insertRecipe(recipe);
      }

      // Set up protein types
      mockDbHelper.recipeProteinTypes = {
        recipes[0].id: [ProteinType.chicken],
        recipes[1].id: [ProteinType.beef],
      };

      // Create meals with different dates
      final dates = [
        today.subtract(const Duration(days: 1)), // Chicken 1 day ago
        today.subtract(const Duration(days: 3)), // Beef 3 days ago
      ];

      await createTestMealsWithDates(recipes: recipes, dates: dates);      // Test with 2-day window
      var recentProteins = await analysisService.getRecentlyCookedProteins(
        dayWindow: 2,
        referenceDate: today,
      );
      expect(recentProteins.length, 1);
      expect(recentProteins.contains(ProteinType.chicken), true);

      // Test with 4-day window
      recentProteins = await analysisService.getRecentlyCookedProteins(
        dayWindow: 4,
        referenceDate: today,
      );
      expect(recentProteins.length, 2);
      expect(recentProteins.contains(ProteinType.chicken), true);
      expect(recentProteins.contains(ProteinType.beef), true);
    });

    test('handles both junction table and direct recipe references', () async {
      final today = DateTime(2025, 6, 11);

      final recipes = [
        Recipe(
          id: IdGenerator.generateId(),
          name: 'Junction Table Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: today,
        ),
        Recipe(
          id: IdGenerator.generateId(),
          name: 'Direct Reference Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: today,
        ),
      ];

      // Add recipes to mock database
      for (final recipe in recipes) {
        await mockDbHelper.insertRecipe(recipe);
      }

      // Set up protein types
      mockDbHelper.recipeProteinTypes = {
        recipes[0].id: [ProteinType.chicken],
        recipes[1].id: [ProteinType.beef],
      };

      // Create meals using both methods
      final dates = [
        today.subtract(const Duration(days: 1)), // Junction table meal
        today.subtract(const Duration(days: 1)), // Direct reference meal
      ];

      // Create meal with junction table
      await createTestMealsWithDates(
          recipes: [recipes[0]], dates: [dates[0]], useJunctionTable: true);

      // Create meal with direct reference
      await createTestMealsWithDates(
          recipes: [recipes[1]], dates: [dates[1]], useJunctionTable: false);      // Test recipe IDs
      final recentIds = await analysisService.getRecentlyCookedRecipeIds(
        dayWindow: 2,
        referenceDate: today,
      );
      expect(recentIds.length, 2);
      expect(recentIds.contains(recipes[0].id), true);
      expect(recentIds.contains(recipes[1].id), true);

      // Test protein types
      final recentProteins = await analysisService.getRecentlyCookedProteins(
        dayWindow: 2,
        referenceDate: today,
      );
      expect(recentProteins.length, 2);
      expect(recentProteins.contains(ProteinType.chicken), true);
      expect(recentProteins.contains(ProteinType.beef), true);
    });
  });
}
