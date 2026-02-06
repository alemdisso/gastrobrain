import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gastrobrain/services/shopping_list_service.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/ingredient.dart';
import 'package:gastrobrain/models/recipe_ingredient.dart';
import 'package:gastrobrain/models/meal_plan.dart';
import 'package:gastrobrain/models/meal_plan_item.dart';
import 'package:gastrobrain/models/meal_plan_item_recipe.dart';
import 'package:gastrobrain/models/ingredient_category.dart';
import 'package:gastrobrain/models/measurement_unit.dart';
import 'package:gastrobrain/widgets/shopping_list_preview_bottom_sheet.dart';
import 'package:gastrobrain/l10n/app_localizations.dart';
import '../mocks/mock_database_helper.dart';

void main() {
  group('ShoppingListService - calculateProjectedIngredients', () {
    late MockDatabaseHelper mockDb;
    late ShoppingListService service;

    setUp(() {
      mockDb = MockDatabaseHelper();
      service = ShoppingListService(mockDb);
    });

    test('setup test - service initializes correctly', () {
      expect(service, isNotNull);
      expect(mockDb, isNotNull);
    });

    test('returns correctly formatted data structure (empty case)', () async {
      // Setup: No meal plan data
      final today = DateTime.now();

      // Execute
      final result = await service.calculateProjectedIngredients(
        startDate: today,
        endDate: today,
      );

      // Verify structure
      expect(result, isA<Map<String, List<Map<String, dynamic>>>>());
      expect(result.isEmpty, isTrue, reason: 'Should return empty map when no meals planned');
    });

    test('aggregates same ingredient from multiple recipes', () async {
      // Setup: Create master ingredient
      final tomatoIngredient = Ingredient(
        id: 'ingredient-1',
        name: 'Tomato',
        category: IngredientCategory.vegetable,
        unit: MeasurementUnit.gram,
      );
      mockDb.ingredients[tomatoIngredient.id] = tomatoIngredient;

      // Create two recipes
      final recipe1 = Recipe(
        id: 'recipe-1',
        name: 'Recipe 1',
        createdAt: DateTime.now(),
      );
      final recipe2 = Recipe(
        id: 'recipe-2',
        name: 'Recipe 2',
        createdAt: DateTime.now(),
      );
      mockDb.recipes[recipe1.id] = recipe1;
      mockDb.recipes[recipe2.id] = recipe2;

      // Add tomato to both recipes
      final recipeIngredient1 = RecipeIngredient(
        id: 'ri-1',
        recipeId: recipe1.id,
        ingredientId: tomatoIngredient.id,
        quantity: 200.0,
      );
      final recipeIngredient2 = RecipeIngredient(
        id: 'ri-2',
        recipeId: recipe2.id,
        ingredientId: tomatoIngredient.id,
        quantity: 300.0,
      );
      mockDb.recipeIngredients[recipeIngredient1.id] = recipeIngredient1;
      mockDb.recipeIngredients[recipeIngredient2.id] = recipeIngredient2;

      // Create meal plan items for today (normalize to remove time component)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayStr = today.toIso8601String().split('T')[0];

      // Link recipes to meal plan items
      final mealPlanItemRecipe1 = MealPlanItemRecipe(
        id: 'mpir-1',
        mealPlanItemId: 'mpi-1',
        recipeId: recipe1.id,
      );
      final mealPlanItemRecipe2 = MealPlanItemRecipe(
        id: 'mpir-2',
        mealPlanItemId: 'mpi-2',
        recipeId: recipe2.id,
      );

      final mealPlanItem1 = MealPlanItem(
        id: 'mpi-1',
        mealPlanId: 'plan-1',
        plannedDate: todayStr,
        mealType: MealPlanItem.dinner,
        mealPlanItemRecipes: [mealPlanItemRecipe1],
      );
      final mealPlanItem2 = MealPlanItem(
        id: 'mpi-2',
        mealPlanId: 'plan-1',
        plannedDate: todayStr,
        mealType: MealPlanItem.dinner,
        mealPlanItemRecipes: [mealPlanItemRecipe2],
      );

      // Create meal plan with items
      final mealPlan = MealPlan(
        id: 'plan-1',
        weekStartDate: today,
        createdAt: today,
        modifiedAt: today,
        items: [mealPlanItem1, mealPlanItem2],
      );
      mockDb.mealPlans[mealPlan.id] = mealPlan;

      // Execute
      final result = await service.calculateProjectedIngredients(
        startDate: today,
        endDate: today,
      );

      // Verify aggregation
      expect(result.containsKey('vegetable'), isTrue);
      expect(result['vegetable']!.length, equals(1),
        reason: 'Should aggregate tomatoes from both recipes into one entry');

      final tomato = result['vegetable']![0];
      expect(tomato['name'], equals('Tomato'));
      expect(tomato['quantity'], equals(500.0),
        reason: 'Should sum quantities: 200g + 300g = 500g');
      expect(tomato['unit'], equals('g'));
      expect(tomato['category'], equals('vegetable'));
    });

    test('groups ingredients by category', () async {
      // Setup: Create ingredients from different categories
      final tomato = Ingredient(
        id: 'ing-1',
        name: 'Tomato',
        category: IngredientCategory.vegetable,
        unit: MeasurementUnit.gram,
      );
      final chicken = Ingredient(
        id: 'ing-2',
        name: 'Chicken',
        category: IngredientCategory.protein,
        unit: MeasurementUnit.gram,
      );
      final rice = Ingredient(
        id: 'ing-3',
        name: 'Rice',
        category: IngredientCategory.grain,
        unit: MeasurementUnit.gram,
      );
      mockDb.ingredients[tomato.id] = tomato;
      mockDb.ingredients[chicken.id] = chicken;
      mockDb.ingredients[rice.id] = rice;

      // Create recipe with all three ingredients
      final recipe = Recipe(
        id: 'recipe-1',
        name: 'Mixed Recipe',
        createdAt: DateTime.now(),
      );
      mockDb.recipes[recipe.id] = recipe;

      final ri1 = RecipeIngredient(
        id: 'ri-1',
        recipeId: recipe.id,
        ingredientId: tomato.id,
        quantity: 200.0,
      );
      final ri2 = RecipeIngredient(
        id: 'ri-2',
        recipeId: recipe.id,
        ingredientId: chicken.id,
        quantity: 300.0,
      );
      final ri3 = RecipeIngredient(
        id: 'ri-3',
        recipeId: recipe.id,
        ingredientId: rice.id,
        quantity: 150.0,
      );
      mockDb.recipeIngredients[ri1.id] = ri1;
      mockDb.recipeIngredients[ri2.id] = ri2;
      mockDb.recipeIngredients[ri3.id] = ri3;

      // Create meal plan
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayStr = today.toIso8601String().split('T')[0];

      final mealPlanItemRecipe = MealPlanItemRecipe(
        id: 'mpir-1',
        mealPlanItemId: 'mpi-1',
        recipeId: recipe.id,
      );

      final mealPlanItem = MealPlanItem(
        id: 'mpi-1',
        mealPlanId: 'plan-1',
        plannedDate: todayStr,
        mealType: MealPlanItem.dinner,
        mealPlanItemRecipes: [mealPlanItemRecipe],
      );

      final mealPlan = MealPlan(
        id: 'plan-1',
        weekStartDate: today,
        createdAt: today,
        modifiedAt: today,
        items: [mealPlanItem],
      );
      mockDb.mealPlans[mealPlan.id] = mealPlan;

      // Execute
      final result = await service.calculateProjectedIngredients(
        startDate: today,
        endDate: today,
      );

      // Verify grouping
      expect(result.keys.length, equals(3),
        reason: 'Should have 3 categories');
      expect(result.containsKey('vegetable'), isTrue);
      expect(result.containsKey('protein'), isTrue);
      expect(result.containsKey('grain'), isTrue);

      expect(result['vegetable']!.length, equals(1));
      expect(result['vegetable']![0]['name'], equals('Tomato'));

      expect(result['protein']!.length, equals(1));
      expect(result['protein']![0]['name'], equals('Chicken'));

      expect(result['grain']!.length, equals(1));
      expect(result['grain']![0]['name'], equals('Rice'));
    });

    test('filters excluded ingredients with zero quantity', () async {
      // Setup: Create ingredients including excluded staples
      final salt = Ingredient(
        id: 'ing-1',
        name: 'Salt',
        category: IngredientCategory.seasoning,
        unit: MeasurementUnit.gram,
      );
      final water = Ingredient(
        id: 'ing-2',
        name: 'Water',
        category: IngredientCategory.other,
        unit: MeasurementUnit.milliliter,
      );
      final tomato = Ingredient(
        id: 'ing-3',
        name: 'Tomato',
        category: IngredientCategory.vegetable,
        unit: MeasurementUnit.gram,
      );
      mockDb.ingredients[salt.id] = salt;
      mockDb.ingredients[water.id] = water;
      mockDb.ingredients[tomato.id] = tomato;

      // Create recipe with salt (qty=0), water (qty=0), and tomato (qty=200)
      final recipe = Recipe(
        id: 'recipe-1',
        name: 'Recipe with staples',
        createdAt: DateTime.now(),
      );
      mockDb.recipes[recipe.id] = recipe;

      final riSalt = RecipeIngredient(
        id: 'ri-1',
        recipeId: recipe.id,
        ingredientId: salt.id,
        quantity: 0.0, // To taste - should be excluded
      );
      final riWater = RecipeIngredient(
        id: 'ri-2',
        recipeId: recipe.id,
        ingredientId: water.id,
        quantity: 0.0, // To taste - should be excluded
      );
      final riTomato = RecipeIngredient(
        id: 'ri-3',
        recipeId: recipe.id,
        ingredientId: tomato.id,
        quantity: 200.0, // Normal ingredient - should be included
      );
      mockDb.recipeIngredients[riSalt.id] = riSalt;
      mockDb.recipeIngredients[riWater.id] = riWater;
      mockDb.recipeIngredients[riTomato.id] = riTomato;

      // Create meal plan
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayStr = today.toIso8601String().split('T')[0];

      final mealPlanItemRecipe = MealPlanItemRecipe(
        id: 'mpir-1',
        mealPlanItemId: 'mpi-1',
        recipeId: recipe.id,
      );

      final mealPlanItem = MealPlanItem(
        id: 'mpi-1',
        mealPlanId: 'plan-1',
        plannedDate: todayStr,
        mealType: MealPlanItem.dinner,
        mealPlanItemRecipes: [mealPlanItemRecipe],
      );

      final mealPlan = MealPlan(
        id: 'plan-1',
        weekStartDate: today,
        createdAt: today,
        modifiedAt: today,
        items: [mealPlanItem],
      );
      mockDb.mealPlans[mealPlan.id] = mealPlan;

      // Execute
      final result = await service.calculateProjectedIngredients(
        startDate: today,
        endDate: today,
      );

      // Verify exclusion
      expect(result.containsKey('seasoning'), isFalse,
        reason: 'Salt with quantity 0 should be excluded');
      expect(result.containsKey('other'), isFalse,
        reason: 'Water with quantity 0 should be excluded');
      expect(result.containsKey('vegetable'), isTrue,
        reason: 'Tomato should be included');
      expect(result['vegetable']!.length, equals(1));
      expect(result['vegetable']![0]['name'], equals('Tomato'));
    });

    test('handles date range correctly', () async {
      // Setup: Create ingredient
      final tomato = Ingredient(
        id: 'ing-1',
        name: 'Tomato',
        category: IngredientCategory.vegetable,
        unit: MeasurementUnit.gram,
      );
      mockDb.ingredients[tomato.id] = tomato;

      // Create three recipes with different quantities
      final recipe1 = Recipe(id: 'recipe-1', name: 'Recipe 1', createdAt: DateTime.now());
      final recipe2 = Recipe(id: 'recipe-2', name: 'Recipe 2', createdAt: DateTime.now());
      final recipe3 = Recipe(id: 'recipe-3', name: 'Recipe 3', createdAt: DateTime.now());
      mockDb.recipes[recipe1.id] = recipe1;
      mockDb.recipes[recipe2.id] = recipe2;
      mockDb.recipes[recipe3.id] = recipe3;

      final ri1 = RecipeIngredient(id: 'ri-1', recipeId: recipe1.id, ingredientId: tomato.id, quantity: 100.0);
      final ri2 = RecipeIngredient(id: 'ri-2', recipeId: recipe2.id, ingredientId: tomato.id, quantity: 200.0);
      final ri3 = RecipeIngredient(id: 'ri-3', recipeId: recipe3.id, ingredientId: tomato.id, quantity: 300.0);
      mockDb.recipeIngredients[ri1.id] = ri1;
      mockDb.recipeIngredients[ri2.id] = ri2;
      mockDb.recipeIngredients[ri3.id] = ri3;

      // Create meal plan items for different dates
      final now = DateTime.now();
      final day1 = DateTime(now.year, now.month, now.day);
      final day3 = day1.add(const Duration(days: 2));
      final day7 = day1.add(const Duration(days: 6));

      final day1Str = day1.toIso8601String().split('T')[0];
      final day3Str = day3.toIso8601String().split('T')[0];
      final day7Str = day7.toIso8601String().split('T')[0];

      final mpir1 = MealPlanItemRecipe(id: 'mpir-1', mealPlanItemId: 'mpi-1', recipeId: recipe1.id);
      final mpir2 = MealPlanItemRecipe(id: 'mpir-2', mealPlanItemId: 'mpi-2', recipeId: recipe2.id);
      final mpir3 = MealPlanItemRecipe(id: 'mpir-3', mealPlanItemId: 'mpi-3', recipeId: recipe3.id);

      final mpi1 = MealPlanItem(
        id: 'mpi-1',
        mealPlanId: 'plan-1',
        plannedDate: day1Str,
        mealType: MealPlanItem.dinner,
        mealPlanItemRecipes: [mpir1],
      );
      final mpi2 = MealPlanItem(
        id: 'mpi-2',
        mealPlanId: 'plan-1',
        plannedDate: day3Str,
        mealType: MealPlanItem.dinner,
        mealPlanItemRecipes: [mpir2],
      );
      final mpi3 = MealPlanItem(
        id: 'mpi-3',
        mealPlanId: 'plan-1',
        plannedDate: day7Str,
        mealType: MealPlanItem.dinner,
        mealPlanItemRecipes: [mpir3],
      );

      final mealPlan = MealPlan(
        id: 'plan-1',
        weekStartDate: day1,
        createdAt: day1,
        modifiedAt: day1,
        items: [mpi1, mpi2, mpi3],
      );
      mockDb.mealPlans[mealPlan.id] = mealPlan;

      // Execute: Query for day1 to day5 (should include day1 and day3, exclude day7)
      final day5 = day1.add(const Duration(days: 4));
      final result = await service.calculateProjectedIngredients(
        startDate: day1,
        endDate: day5,
      );

      // Verify only meals within range are included
      expect(result.containsKey('vegetable'), isTrue);
      expect(result['vegetable']!.length, equals(1));
      expect(result['vegetable']![0]['quantity'], equals(300.0),
        reason: 'Should include day1 (100g) + day3 (200g) = 300g, exclude day7 (300g)');
    });

    test('handles empty meal plan', () async {
      // Setup: Create meal plan with no items
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final mealPlan = MealPlan(
        id: 'plan-1',
        weekStartDate: today,
        createdAt: today,
        modifiedAt: today,
        items: [], // Empty items list
      );
      mockDb.mealPlans[mealPlan.id] = mealPlan;

      // Execute
      final result = await service.calculateProjectedIngredients(
        startDate: today,
        endDate: today,
      );

      // Verify empty result
      expect(result.isEmpty, isTrue,
        reason: 'Should return empty map when meal plan has no items');
    });

    test('handles recipes with no ingredients', () async {
      // Setup: Create recipe without ingredients
      final recipe = Recipe(
        id: 'recipe-1',
        name: 'Empty Recipe',
        createdAt: DateTime.now(),
      );
      mockDb.recipes[recipe.id] = recipe;
      // Note: No RecipeIngredients added

      // Create meal plan with this recipe
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayStr = today.toIso8601String().split('T')[0];

      final mealPlanItemRecipe = MealPlanItemRecipe(
        id: 'mpir-1',
        mealPlanItemId: 'mpi-1',
        recipeId: recipe.id,
      );

      final mealPlanItem = MealPlanItem(
        id: 'mpi-1',
        mealPlanId: 'plan-1',
        plannedDate: todayStr,
        mealType: MealPlanItem.dinner,
        mealPlanItemRecipes: [mealPlanItemRecipe],
      );

      final mealPlan = MealPlan(
        id: 'plan-1',
        weekStartDate: today,
        createdAt: today,
        modifiedAt: today,
        items: [mealPlanItem],
      );
      mockDb.mealPlans[mealPlan.id] = mealPlan;

      // Execute
      final result = await service.calculateProjectedIngredients(
        startDate: today,
        endDate: today,
      );

      // Verify empty result
      expect(result.isEmpty, isTrue,
        reason: 'Should return empty map when recipes have no ingredients');
    });

    test('handles multi-recipe meals', () async {
      // Setup: Create ingredient
      final rice = Ingredient(
        id: 'ing-1',
        name: 'Rice',
        category: IngredientCategory.grain,
        unit: MeasurementUnit.gram,
      );
      mockDb.ingredients[rice.id] = rice;

      // Create main dish and side dish recipes, both using rice
      final mainRecipe = Recipe(id: 'recipe-1', name: 'Main Dish', createdAt: DateTime.now());
      final sideRecipe = Recipe(id: 'recipe-2', name: 'Side Dish', createdAt: DateTime.now());
      mockDb.recipes[mainRecipe.id] = mainRecipe;
      mockDb.recipes[sideRecipe.id] = sideRecipe;

      final riMain = RecipeIngredient(
        id: 'ri-1',
        recipeId: mainRecipe.id,
        ingredientId: rice.id,
        quantity: 150.0,
      );
      final riSide = RecipeIngredient(
        id: 'ri-2',
        recipeId: sideRecipe.id,
        ingredientId: rice.id,
        quantity: 100.0,
      );
      mockDb.recipeIngredients[riMain.id] = riMain;
      mockDb.recipeIngredients[riSide.id] = riSide;

      // Create meal plan item with BOTH recipes
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayStr = today.toIso8601String().split('T')[0];

      final mpirMain = MealPlanItemRecipe(
        id: 'mpir-1',
        mealPlanItemId: 'mpi-1',
        recipeId: mainRecipe.id,
      );
      final mpirSide = MealPlanItemRecipe(
        id: 'mpir-2',
        mealPlanItemId: 'mpi-1',
        recipeId: sideRecipe.id,
      );

      final mealPlanItem = MealPlanItem(
        id: 'mpi-1',
        mealPlanId: 'plan-1',
        plannedDate: todayStr,
        mealType: MealPlanItem.dinner,
        mealPlanItemRecipes: [mpirMain, mpirSide], // Multiple recipes in one meal
      );

      final mealPlan = MealPlan(
        id: 'plan-1',
        weekStartDate: today,
        createdAt: today,
        modifiedAt: today,
        items: [mealPlanItem],
      );
      mockDb.mealPlans[mealPlan.id] = mealPlan;

      // Execute
      final result = await service.calculateProjectedIngredients(
        startDate: today,
        endDate: today,
      );

      // Verify aggregation across multiple recipes in same meal
      expect(result.containsKey('grain'), isTrue);
      expect(result['grain']!.length, equals(1));
      expect(result['grain']![0]['name'], equals('Rice'));
      expect(result['grain']![0]['quantity'], equals(250.0),
        reason: 'Should aggregate rice from main (150g) + side (100g) = 250g');
    });

    test('preserves existing aggregation logic', () async {
      // Setup: Create ingredient
      final tomato = Ingredient(
        id: 'ing-1',
        name: 'Tomato',
        category: IngredientCategory.vegetable,
        unit: MeasurementUnit.gram,
      );
      mockDb.ingredients[tomato.id] = tomato;

      // Create recipes with same ingredient in compatible units (g and kg)
      final recipe1 = Recipe(id: 'recipe-1', name: 'Recipe 1', createdAt: DateTime.now());
      final recipe2 = Recipe(id: 'recipe-2', name: 'Recipe 2', createdAt: DateTime.now());
      mockDb.recipes[recipe1.id] = recipe1;
      mockDb.recipes[recipe2.id] = recipe2;

      // One with grams, one with kg (compatible but different units)
      final ri1 = RecipeIngredient(
        id: 'ri-1',
        recipeId: recipe1.id,
        ingredientId: tomato.id,
        quantity: 500.0,
        unitOverride: 'g',
      );
      final ri2 = RecipeIngredient(
        id: 'ri-2',
        recipeId: recipe2.id,
        ingredientId: tomato.id,
        quantity: 1.0,
        unitOverride: 'kg',
      );
      mockDb.recipeIngredients[ri1.id] = ri1;
      mockDb.recipeIngredients[ri2.id] = ri2;

      // Create meal plan
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayStr = today.toIso8601String().split('T')[0];

      final mpir1 = MealPlanItemRecipe(id: 'mpir-1', mealPlanItemId: 'mpi-1', recipeId: recipe1.id);
      final mpir2 = MealPlanItemRecipe(id: 'mpir-2', mealPlanItemId: 'mpi-2', recipeId: recipe2.id);

      final mpi1 = MealPlanItem(
        id: 'mpi-1',
        mealPlanId: 'plan-1',
        plannedDate: todayStr,
        mealType: MealPlanItem.dinner,
        mealPlanItemRecipes: [mpir1],
      );
      final mpi2 = MealPlanItem(
        id: 'mpi-2',
        mealPlanId: 'plan-1',
        plannedDate: todayStr,
        mealType: MealPlanItem.lunch,
        mealPlanItemRecipes: [mpir2],
      );

      final mealPlan = MealPlan(
        id: 'plan-1',
        weekStartDate: today,
        createdAt: today,
        modifiedAt: today,
        items: [mpi1, mpi2],
      );
      mockDb.mealPlans[mealPlan.id] = mealPlan;

      // Execute
      final result = await service.calculateProjectedIngredients(
        startDate: today,
        endDate: today,
      );

      // Verify existing aggregation behavior: converts compatible units and sums
      // 500g + 1kg = 1500g = 1.5kg (auto-converted because >= 1000)
      expect(result.containsKey('vegetable'), isTrue);
      expect(result['vegetable']!.length, equals(1));
      expect(result['vegetable']![0]['name'], equals('Tomato'));
      expect(result['vegetable']![0]['quantity'], equals(1.5),
        reason: 'Existing logic: 500g + 1kg = 1500g = 1.5kg (auto-converted)');
      expect(result['vegetable']![0]['unit'], equals('kg'));
    });
  });

  group('ShoppingListPreviewBottomSheet - Widget Tests', () {
    // Helper to build widget with localization
    Widget buildTestWidget(Map<String, List<Map<String, dynamic>>> groupedIngredients) {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('pt'),
        ],
        home: Scaffold(
          body: ShoppingListPreviewBottomSheet(
            groupedIngredients: groupedIngredients,
          ),
        ),
      );
    }

    testWidgets('displays categories correctly', (WidgetTester tester) async {
      // Setup: Create grouped ingredients with multiple categories
      final groupedIngredients = {
        'vegetable': [
          {'name': 'Tomato', 'quantity': 200.0, 'unit': 'g', 'category': 'vegetable'},
        ],
        'protein': [
          {'name': 'Chicken', 'quantity': 300.0, 'unit': 'g', 'category': 'protein'},
        ],
        'grain': [
          {'name': 'Rice', 'quantity': 150.0, 'unit': 'g', 'category': 'grain'},
        ],
      };

      // Build widget
      await tester.pumpWidget(buildTestWidget(groupedIngredients));

      // Verify categories are displayed
      expect(find.text('Vegetable'), findsOneWidget);
      expect(find.text('Protein'), findsOneWidget);
      expect(find.text('Grain'), findsOneWidget);
    });

    testWidgets('displays ingredients correctly', (WidgetTester tester) async {
      // Setup
      final groupedIngredients = {
        'vegetable': [
          {'name': 'Tomato', 'quantity': 200.0, 'unit': 'g', 'category': 'vegetable'},
          {'name': 'Onion', 'quantity': 150.0, 'unit': 'g', 'category': 'vegetable'},
        ],
      };

      // Build widget
      await tester.pumpWidget(buildTestWidget(groupedIngredients));

      // Verify ingredients are displayed
      expect(find.text('Tomato'), findsOneWidget);
      expect(find.text('Onion'), findsOneWidget);
    });

    testWidgets('displays quantities correctly', (WidgetTester tester) async {
      // Setup
      final groupedIngredients = {
        'vegetable': [
          {'name': 'Tomato', 'quantity': 200.0, 'unit': 'g', 'category': 'vegetable'},
          {'name': 'Onion', 'quantity': 1.5, 'unit': 'kg', 'category': 'vegetable'},
        ],
      };

      // Build widget
      await tester.pumpWidget(buildTestWidget(groupedIngredients));

      // Verify quantities are displayed with units
      expect(find.text('200 g'), findsOneWidget);
      expect(find.text('1½ kg'), findsOneWidget); // QuantityFormatter formats 1.5 as 1½
    });

    testWidgets('shows empty state when no ingredients', (WidgetTester tester) async {
      // Setup: empty map
      final groupedIngredients = <String, List<Map<String, dynamic>>>{};

      // Build widget
      await tester.pumpWidget(buildTestWidget(groupedIngredients));

      // Verify empty state is shown
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
      expect(find.text('No meals planned - nothing to preview'), findsOneWidget);
    });

    testWidgets('renders without error', (WidgetTester tester) async {
      // Setup
      final groupedIngredients = {
        'vegetable': [
          {'name': 'Tomato', 'quantity': 200.0, 'unit': 'g', 'category': 'vegetable'},
        ],
      };

      // Build widget - should not throw
      await tester.pumpWidget(buildTestWidget(groupedIngredients));

      // Verify widget is in the tree
      expect(find.byType(ShoppingListPreviewBottomSheet), findsOneWidget);
    });

    testWidgets('expands categories initially', (WidgetTester tester) async {
      // Setup
      final groupedIngredients = {
        'vegetable': [
          {'name': 'Tomato', 'quantity': 200.0, 'unit': 'g', 'category': 'vegetable'},
        ],
      };

      // Build widget
      await tester.pumpWidget(buildTestWidget(groupedIngredients));

      // Verify ExpansionTile is present and initially expanded
      expect(find.byType(ExpansionTile), findsOneWidget);
      // Ingredient should be visible (tile is initially expanded)
      expect(find.text('Tomato'), findsOneWidget);
    });

    testWidgets('scrolls content', (WidgetTester tester) async {
      // Setup: Many ingredients to require scrolling
      final groupedIngredients = {
        'vegetable': List.generate(
          20,
          (i) => {'name': 'Ingredient $i', 'quantity': 100.0, 'unit': 'g', 'category': 'vegetable'},
        ),
      };

      // Build widget
      await tester.pumpWidget(buildTestWidget(groupedIngredients));

      // Verify ListView is present (for scrolling)
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('handles long ingredient names', (WidgetTester tester) async {
      // Setup: Ingredient with very long name
      final groupedIngredients = {
        'vegetable': [
          {
            'name': 'Extra Large Organic Heirloom Tomato From Local Farm',
            'quantity': 200.0,
            'unit': 'g',
            'category': 'vegetable'
          },
        ],
      };

      // Build widget
      await tester.pumpWidget(buildTestWidget(groupedIngredients));

      // Verify long name is displayed without overflow
      expect(find.text('Extra Large Organic Heirloom Tomato From Local Farm'), findsOneWidget);
      // Widget should render without overflow error
      expect(tester.takeException(), isNull);
    });
  });

  group('Edge Case Tests', () {
    late MockDatabaseHelper mockDb;
    late ShoppingListService service;

    setUp(() {
      mockDb = MockDatabaseHelper();
      service = ShoppingListService(mockDb);
    });

    test('edge case - empty state with no meal plans', () async {
      // No meal plans in database
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final result = await service.calculateProjectedIngredients(
        startDate: today,
        endDate: today,
      );

      expect(result.isEmpty, isTrue,
        reason: 'Empty database should return empty result');
    });

    test('edge case - handles ingredients with missing data gracefully', () async {
      // Setup: Create ingredient
      final tomato = Ingredient(
        id: 'ing-1',
        name: 'Tomato',
        category: IngredientCategory.vegetable,
        unit: MeasurementUnit.gram,
      );
      mockDb.ingredients[tomato.id] = tomato;

      // Create recipe
      final recipe = Recipe(id: 'recipe-1', name: 'Recipe', createdAt: DateTime.now());
      mockDb.recipes[recipe.id] = recipe;

      // Create recipe ingredient with null unit (using master ingredient's unit)
      final ri = RecipeIngredient(
        id: 'ri-1',
        recipeId: recipe.id,
        ingredientId: tomato.id,
        quantity: 200.0,
        // No unitOverride - should use ingredient's unit
      );
      mockDb.recipeIngredients[ri.id] = ri;

      // Create meal plan
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayStr = today.toIso8601String().split('T')[0];

      final mpir = MealPlanItemRecipe(id: 'mpir-1', mealPlanItemId: 'mpi-1', recipeId: recipe.id);
      final mpi = MealPlanItem(
        id: 'mpi-1',
        mealPlanId: 'plan-1',
        plannedDate: todayStr,
        mealType: MealPlanItem.dinner,
        mealPlanItemRecipes: [mpir],
      );
      final plan = MealPlan(
        id: 'plan-1',
        weekStartDate: today,
        createdAt: today,
        modifiedAt: today,
        items: [mpi],
      );
      mockDb.mealPlans[plan.id] = plan;

      // Execute - should not throw
      final result = await service.calculateProjectedIngredients(
        startDate: today,
        endDate: today,
      );

      // Verify result uses default unit from ingredient
      expect(result.containsKey('vegetable'), isTrue);
      expect(result['vegetable']![0]['unit'], equals('g'));
    });

    test('edge case - boundary dates (same start and end date)', () async {
      // Setup
      final tomato = Ingredient(
        id: 'ing-1',
        name: 'Tomato',
        category: IngredientCategory.vegetable,
        unit: MeasurementUnit.gram,
      );
      mockDb.ingredients[tomato.id] = tomato;

      final recipe = Recipe(id: 'recipe-1', name: 'Recipe', createdAt: DateTime.now());
      mockDb.recipes[recipe.id] = recipe;

      final ri = RecipeIngredient(
        id: 'ri-1',
        recipeId: recipe.id,
        ingredientId: tomato.id,
        quantity: 200.0,
      );
      mockDb.recipeIngredients[ri.id] = ri;

      // Create meal plan for a specific date
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayStr = today.toIso8601String().split('T')[0];

      final mpir = MealPlanItemRecipe(id: 'mpir-1', mealPlanItemId: 'mpi-1', recipeId: recipe.id);
      final mpi = MealPlanItem(
        id: 'mpi-1',
        mealPlanId: 'plan-1',
        plannedDate: todayStr,
        mealType: MealPlanItem.dinner,
        mealPlanItemRecipes: [mpir],
      );
      final plan = MealPlan(
        id: 'plan-1',
        weekStartDate: today,
        createdAt: today,
        modifiedAt: today,
        items: [mpi],
      );
      mockDb.mealPlans[plan.id] = plan;

      // Execute with same start and end date (single day)
      final result = await service.calculateProjectedIngredients(
        startDate: today,
        endDate: today, // Same as start
      );

      // Verify single-day range works
      expect(result.containsKey('vegetable'), isTrue);
      expect(result['vegetable']![0]['name'], equals('Tomato'));
      expect(result['vegetable']![0]['quantity'], equals(200.0));
    });
  });
}
