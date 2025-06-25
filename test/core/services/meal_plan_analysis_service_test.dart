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

  group('MealPlanAnalysisService Tests', () {
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
      } // Test with 3-day window
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
      expect(recentIds.length,
          2); // Should include up to 5 days ago (both recipes)

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

      await createTestMealsWithDates(
          recipes: recipes, dates: dates); // Test with 2-day window
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
          recipes: [recipes[1]],
          dates: [dates[1]],
          useJunctionTable: false); // Test recipe IDs
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

  group('Protein Penalty Strategy Tests', () {
    // Helper function to create test meals with cooked dates
    Future<void> createTestMealsWithCookedDates({
      required List<Recipe> recipes,
      required List<DateTime> cookedDates,
    }) async {
      for (var i = 0; i < recipes.length && i < cookedDates.length; i++) {
        final meal = Meal(
          id: IdGenerator.generateId(),
          cookedAt: cookedDates[i],
          servings: 4,
          notes: 'Test meal ${i + 1}',
          wasSuccessful: true,
          actualPrepTime: 30,
          actualCookTime: 45,
        );

        await mockDbHelper.insertMeal(meal);

        final mealRecipe = MealRecipe(
          mealId: meal.id,
          recipeId: recipes[i].id,
          isPrimaryDish: true,
        );

        await mockDbHelper.insertMealRecipe(mealRecipe);
      }
    }

    // Helper function to create test meal plan with protein recipes
    Future<MealPlan> createMealPlanWithProteins({
      required DateTime weekStart,
      required Map<String, List<ProteinType>> proteinMap,
    }) async {
      final recipes = <Recipe>[];

      // Create recipes for each protein type
      proteinMap.forEach((recipeName, proteins) {
        final recipe = Recipe(
          id: IdGenerator.generateId(),
          name: recipeName,
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
        );
        recipes.add(recipe);
      });

      // Add recipes to mock database and set protein types
      for (var i = 0; i < recipes.length; i++) {
        await mockDbHelper.insertRecipe(recipes[i]);
        final recipeName = recipes[i].name;
        mockDbHelper.recipeProteinTypes[recipes[i].id] =
            proteinMap[recipeName]!;
      }

      // Create meal plan with these recipes
      return await createTestMealPlan(
        weekStartDate: weekStart,
        recipes: recipes,
        dates: List.generate(
            recipes.length,
            (i) => weekStart
                .add(Duration(days: i))
                .toIso8601String()
                .substring(0, 10)),
        mealTypes: List.generate(recipes.length, (_) => MealPlanItem.dinner),
      );
    }

    test('calculates no penalty for proteins not planned or recently cooked',
        () async {
      final today = DateTime(2025, 6, 11);
      final weekStart = DateTime(2025, 6, 9); // Monday

      // Create empty meal plan and no recent meals
      final emptyPlan = MealPlan(
        id: IdGenerator.generateId(),
        weekStartDate: weekStart,
        notes: 'Empty Plan',
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );

      await mockDbHelper.insertMealPlan(emptyPlan);

      // Calculate penalty strategy
      final strategy = await analysisService.calculateProteinPenaltyStrategy(
        emptyPlan,
        today,
        MealPlanItem.dinner,
      );

      // Should have no penalties for any proteins
      for (final protein in ProteinType.values.where((p) => p.isMainProtein)) {
        expect(strategy.getPenalty(protein), equals(0.0),
            reason:
                'Protein $protein should have no penalty when not planned or recently cooked');
      }
    });

    test('applies ~0.6 penalty for proteins planned this week only', () async {
      final today = DateTime(2025, 6, 11); // Wednesday
      final weekStart = DateTime(2025, 6, 9); // Monday

      // Create meal plan with chicken and beef planned
      final mealPlan = await createMealPlanWithProteins(
        weekStart: weekStart,
        proteinMap: {
          'Chicken Curry': [ProteinType.chicken],
          'Beef Stew': [ProteinType.beef],
        },
      );

      // Calculate penalty strategy
      final strategy = await analysisService.calculateProteinPenaltyStrategy(
        mealPlan,
        today,
        MealPlanItem.dinner,
      );

      // Planned proteins should have ~0.6 penalty
      expect(strategy.getPenalty(ProteinType.chicken), equals(0.6),
          reason: 'Chicken planned this week should have 0.6 penalty');
      expect(strategy.getPenalty(ProteinType.beef), equals(0.6),
          reason: 'Beef planned this week should have 0.6 penalty');

      // Non-planned proteins should have no penalty
      expect(strategy.getPenalty(ProteinType.fish), equals(0.0),
          reason: 'Fish not planned should have no penalty');
      expect(strategy.getPenalty(ProteinType.pork), equals(0.0),
          reason: 'Pork not planned should have no penalty');
    });

    test('applies 0.6-0.8 penalty for proteins cooked 1-2 days ago', () async {
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

      mockDbHelper.recipeProteinTypes = {
        recipes[0].id: [ProteinType.chicken],
        recipes[1].id: [ProteinType.beef],
      };

      // Create meals: chicken 1 day ago, beef 2 days ago
      await createTestMealsWithCookedDates(
        recipes: recipes,
        cookedDates: [
          today.subtract(const Duration(days: 1)), // Chicken 1 day ago
          today.subtract(const Duration(days: 2)), // Beef 2 days ago
        ],
      );

      // Create empty meal plan (no current planning)
      final emptyPlan = MealPlan(
        id: IdGenerator.generateId(),
        weekStartDate: today.subtract(const Duration(days: 2)),
        notes: 'Empty Plan',
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );
      await mockDbHelper.insertMealPlan(emptyPlan);

      // Calculate penalty strategy
      final strategy = await analysisService.calculateProteinPenaltyStrategy(
        emptyPlan,
        today,
        MealPlanItem.dinner,
      );

      // Chicken (1 day ago) should have 0.8 penalty
      expect(strategy.getPenalty(ProteinType.chicken), equals(0.8),
          reason: 'Chicken cooked 1 day ago should have 0.8 penalty');

      // Beef (2 days ago) should have 0.6 penalty
      expect(strategy.getPenalty(ProteinType.beef), equals(0.6),
          reason: 'Beef cooked 2 days ago should have 0.6 penalty');

      // Non-cooked proteins should have no penalty
      expect(strategy.getPenalty(ProteinType.fish), equals(0.0),
          reason: 'Fish not recently cooked should have no penalty');
    });

    test('applies 0.25-0.4 penalty for proteins cooked 3-4 days ago', () async {
      final today = DateTime(2025, 6, 11);

      final recipes = [
        Recipe(
          id: IdGenerator.generateId(),
          name: 'Fish Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: today,
        ),
        Recipe(
          id: IdGenerator.generateId(),
          name: 'Pork Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: today,
        ),
      ];

      // Add recipes to mock database
      for (final recipe in recipes) {
        await mockDbHelper.insertRecipe(recipe);
      }

      mockDbHelper.recipeProteinTypes = {
        recipes[0].id: [ProteinType.fish],
        recipes[1].id: [ProteinType.pork],
      };

      // Create meals: fish 3 days ago, pork 4 days ago
      await createTestMealsWithCookedDates(
        recipes: recipes,
        cookedDates: [
          today.subtract(const Duration(days: 3)), // Fish 3 days ago
          today.subtract(const Duration(days: 4)), // Pork 4 days ago
        ],
      );

      // Create empty meal plan (no current planning)
      final emptyPlan = MealPlan(
        id: IdGenerator.generateId(),
        weekStartDate: today.subtract(const Duration(days: 2)),
        notes: 'Empty Plan',
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );
      await mockDbHelper.insertMealPlan(emptyPlan);

      // Calculate penalty strategy
      final strategy = await analysisService.calculateProteinPenaltyStrategy(
        emptyPlan,
        today,
        MealPlanItem.dinner,
      );

      // Fish (3 days ago) should have 0.4 penalty
      expect(strategy.getPenalty(ProteinType.fish), equals(0.4),
          reason: 'Fish cooked 3 days ago should have 0.4 penalty');

      // Pork (4 days ago) should have 0.25 penalty
      expect(strategy.getPenalty(ProteinType.pork), equals(0.25),
          reason: 'Pork cooked 4 days ago should have 0.25 penalty');

      // Non-cooked proteins should have no penalty
      expect(strategy.getPenalty(ProteinType.chicken), equals(0.0),
          reason: 'Chicken not recently cooked should have no penalty');
    });

    test('combines planned and recently cooked penalties, capped at 1.0',
        () async {
      final today = DateTime(2025, 6, 11); // Wednesday
      final weekStart = DateTime(2025, 6, 9); // Monday

      // Create recipe with chicken
      final recipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Chicken Dish',
        desiredFrequency: FrequencyType.weekly,
        createdAt: today,
      );

      await mockDbHelper.insertRecipe(recipe);
      mockDbHelper.recipeProteinTypes = {
        recipe.id: [ProteinType.chicken],
      };

      // Create meal plan with chicken planned
      final mealPlan = await createMealPlanWithProteins(
        weekStart: weekStart,
        proteinMap: {
          'Planned Chicken': [ProteinType.chicken],
        },
      );

      // Also create a recent meal with chicken (1 day ago)
      await createTestMealsWithCookedDates(
        recipes: [recipe],
        cookedDates: [today.subtract(const Duration(days: 1))],
      );

      // Calculate penalty strategy
      final strategy = await analysisService.calculateProteinPenaltyStrategy(
        mealPlan,
        today,
        MealPlanItem.dinner,
      );

      // Chicken should have combined penalty: 0.6 (planned) + 0.8 (1 day ago) = 1.4, capped at 1.0
      expect(strategy.getPenalty(ProteinType.chicken), equals(1.0),
          reason:
              'Chicken both planned and recently cooked should have penalty capped at 1.0');
    });

    test('applyPenalty method correctly reduces scores', () async {
      // Create a strategy with various penalty levels
      const strategy = ProteinPenaltyStrategy(penalties: {
        ProteinType.chicken: 0.0, // No penalty
        ProteinType.beef: 0.25, // Light penalty
        ProteinType.fish: 0.5, // Moderate penalty
        ProteinType.pork: 0.8, // High penalty
        ProteinType.seafood: 1.0, // Maximum penalty
      });

      const baseScore = 100.0;

      // Test different penalty levels
      expect(
          strategy.applyPenalty(ProteinType.chicken, baseScore), equals(100.0),
          reason: 'No penalty should leave score unchanged');

      expect(strategy.applyPenalty(ProteinType.beef, baseScore), equals(75.0),
          reason: '0.25 penalty should reduce 100 to 75');

      expect(strategy.applyPenalty(ProteinType.fish, baseScore), equals(50.0),
          reason: '0.5 penalty should reduce 100 to 50');
      expect(strategy.applyPenalty(ProteinType.pork, baseScore),
          closeTo(20.0, 0.01),
          reason: '0.8 penalty should reduce 100 to 20');

      expect(strategy.applyPenalty(ProteinType.seafood, baseScore), equals(0.0),
          reason: '1.0 penalty should reduce score to 0');

      // Test with different base score
      const lowBaseScore = 60.0;
      expect(
          strategy.applyPenalty(ProteinType.fish, lowBaseScore), equals(30.0),
          reason: '0.5 penalty should reduce 60 to 30');
    });

    test('categorizes proteins by penalty levels correctly', () async {
      const strategy = ProteinPenaltyStrategy(penalties: {
        ProteinType.chicken: 0.0, // No penalty
        ProteinType.beef: 0.1, // Light penalty
        ProteinType.fish: 0.4, // Moderate penalty
        ProteinType.pork: 0.8, // High penalty
        ProteinType.seafood: 1.0, // Maximum penalty
      });

      // Test penalty categorization
      expect(strategy.penalizedProteins.length, equals(4),
          reason: 'Should identify 4 proteins with any penalty');

      expect(strategy.highPenaltyProteins.length, equals(2),
          reason: 'Should identify 2 proteins with high penalties (>=0.7)');
      expect(strategy.highPenaltyProteins.contains(ProteinType.pork), isTrue);
      expect(
          strategy.highPenaltyProteins.contains(ProteinType.seafood), isTrue);

      expect(strategy.moderatePenaltyProteins.length, equals(1),
          reason: 'Should identify 1 protein with moderate penalty (0.3-0.69)');
      expect(
          strategy.moderatePenaltyProteins.contains(ProteinType.fish), isTrue);

      expect(strategy.lightPenaltyProteins.length, equals(1),
          reason: 'Should identify 1 protein with light penalty (0.01-0.29)');
      expect(strategy.lightPenaltyProteins.contains(ProteinType.beef), isTrue);
    });

    test('handles edge cases with old cooked dates', () async {
      final today = DateTime(2025, 6, 11);

      final recipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Old Chicken Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: today,
      );

      await mockDbHelper.insertRecipe(recipe);
      mockDbHelper.recipeProteinTypes = {
        recipe.id: [ProteinType.chicken],
      };

      // Create meal with chicken cooked 7+ days ago
      await createTestMealsWithCookedDates(
        recipes: [recipe],
        cookedDates: [today.subtract(const Duration(days: 8))],
      );

      // Create empty meal plan
      final emptyPlan = MealPlan(
        id: IdGenerator.generateId(),
        weekStartDate: today.subtract(const Duration(days: 2)),
        notes: 'Empty Plan',
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );
      await mockDbHelper.insertMealPlan(emptyPlan);

      // Calculate penalty strategy
      final strategy = await analysisService.calculateProteinPenaltyStrategy(
        emptyPlan,
        today,
        MealPlanItem.dinner,
      );

      // Chicken cooked 8 days ago should have no penalty
      expect(strategy.getPenalty(ProteinType.chicken), equals(0.0),
          reason: 'Chicken cooked 8 days ago should have no penalty');
    });

    test('handles multiple proteins in same recipe', () async {
      final today = DateTime(2025, 6, 11);

      final recipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Surf and Turf',
        desiredFrequency: FrequencyType.weekly,
        createdAt: today,
      );

      await mockDbHelper.insertRecipe(recipe);

      // Recipe has both beef and fish
      mockDbHelper.recipeProteinTypes = {
        recipe.id: [ProteinType.beef, ProteinType.fish],
      };

      // Create meal with mixed proteins cooked 2 days ago
      await createTestMealsWithCookedDates(
        recipes: [recipe],
        cookedDates: [today.subtract(const Duration(days: 2))],
      );

      // Create empty meal plan
      final emptyPlan = MealPlan(
        id: IdGenerator.generateId(),
        weekStartDate: today.subtract(const Duration(days: 2)),
        notes: 'Empty Plan',
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );
      await mockDbHelper.insertMealPlan(emptyPlan);

      // Calculate penalty strategy
      final strategy = await analysisService.calculateProteinPenaltyStrategy(
        emptyPlan,
        today,
        MealPlanItem.dinner,
      );

      // Both proteins should have 0.6 penalty (2 days ago)
      expect(strategy.getPenalty(ProteinType.beef), equals(0.6),
          reason: 'Beef cooked 2 days ago should have 0.6 penalty');
      expect(strategy.getPenalty(ProteinType.fish), equals(0.6),
          reason: 'Fish cooked 2 days ago should have 0.6 penalty');
    });

    test('verifies penalty calculation matches expected ranges', () async {
      final today = DateTime(2025, 6, 11);

      // Create recipes for different scenarios
      final recipes = [
        Recipe(
            id: 'recipe-1-day',
            name: '1 Day Recipe',
            desiredFrequency: FrequencyType.weekly,
            createdAt: today),
        Recipe(
            id: 'recipe-2-day',
            name: '2 Day Recipe',
            desiredFrequency: FrequencyType.weekly,
            createdAt: today),
        Recipe(
            id: 'recipe-3-day',
            name: '3 Day Recipe',
            desiredFrequency: FrequencyType.weekly,
            createdAt: today),
        Recipe(
            id: 'recipe-4-day',
            name: '4 Day Recipe',
            desiredFrequency: FrequencyType.weekly,
            createdAt: today),
        Recipe(
            id: 'recipe-5-day',
            name: '5 Day Recipe',
            desiredFrequency: FrequencyType.weekly,
            createdAt: today),
        Recipe(
            id: 'recipe-6-day',
            name: '6 Day Recipe',
            desiredFrequency: FrequencyType.weekly,
            createdAt: today),
      ]; // Add recipes and set protein types
      for (var i = 0; i < recipes.length; i++) {
        await mockDbHelper.insertRecipe(
            recipes[i]); // Use different proteins to avoid conflicts
        final proteinTypes = [
          ProteinType.chicken,
          ProteinType.beef,
          ProteinType.fish,
          ProteinType.pork,
          ProteinType.seafood,
          ProteinType.lamb
        ];
        mockDbHelper.recipeProteinTypes[recipes[i].id] = [proteinTypes[i]];
      }

      // Create meals with graduated dates
      await createTestMealsWithCookedDates(
        recipes: recipes,
        cookedDates: [
          today.subtract(const Duration(days: 1)), // Should get 0.8 penalty
          today.subtract(const Duration(days: 2)), // Should get 0.6 penalty
          today.subtract(const Duration(days: 3)), // Should get 0.4 penalty
          today.subtract(const Duration(days: 4)), // Should get 0.25 penalty
          today.subtract(const Duration(days: 5)), // Should get 0.1 penalty
          today.subtract(const Duration(days: 6)), // Should get 0.1 penalty
        ],
      );

      // Create empty meal plan
      final emptyPlan = MealPlan(
        id: IdGenerator.generateId(),
        weekStartDate: today.subtract(const Duration(days: 2)),
        notes: 'Empty Plan',
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );
      await mockDbHelper.insertMealPlan(emptyPlan);

      // Calculate penalty strategy
      final strategy = await analysisService.calculateProteinPenaltyStrategy(
        emptyPlan,
        today,
        MealPlanItem.dinner,
      ); // Verify graduated penalties match expected values
      expect(strategy.getPenalty(ProteinType.chicken), equals(0.8),
          reason: 'Chicken should have 0.8 penalty for 1 day ago');
      expect(strategy.getPenalty(ProteinType.beef), equals(0.6),
          reason: 'Beef should have 0.6 penalty for 2 days ago');
      expect(strategy.getPenalty(ProteinType.fish), equals(0.4),
          reason: 'Fish should have 0.4 penalty for 3 days ago');
      expect(strategy.getPenalty(ProteinType.pork), equals(0.25),
          reason: 'Pork should have 0.25 penalty for 4 days ago');
      expect(strategy.getPenalty(ProteinType.seafood), equals(0.1),
          reason: 'Seafood should have 0.1 penalty for 5 days ago');
      expect(strategy.getPenalty(ProteinType.lamb), equals(0.1),
          reason: 'Lamb should have 0.1 penalty for 6 days ago');
    });
  });
}
