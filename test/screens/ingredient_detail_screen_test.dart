import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gastrobrain/models/ingredient.dart';
import 'package:gastrobrain/models/ingredient_category.dart';
import 'package:gastrobrain/models/measurement_unit.dart';
import 'package:gastrobrain/models/meal.dart';
import 'package:gastrobrain/models/meal_ingredient.dart';
import 'package:gastrobrain/models/meal_recipe.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/recipe_ingredient.dart';
import 'package:gastrobrain/screens/ingredient_detail_screen.dart';
import 'package:gastrobrain/screens/recipe_details_screen.dart';
import 'package:gastrobrain/l10n/app_localizations.dart';
import '../mocks/mock_database_helper.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en', '')],
    home: child,
  );
}

Ingredient _makeIngredient({String id = 'ing-1', String name = 'Salt'}) {
  return Ingredient(
    id: id,
    name: name,
    category: IngredientCategory.seasoning,
  );
}

Recipe _makeRecipe({
  String id = 'recipe-1',
  String name = 'Test Recipe',
  int difficulty = 2,
  int rating = 3,
}) {
  return Recipe(
    id: id,
    name: name,
    createdAt: DateTime(2024, 1, 1),
    difficulty: difficulty,
    rating: rating,
    notes: '',
  );
}

RecipeIngredient _makeRecipeIngredient({
  required String recipeId,
  required String ingredientId,
  double quantity = 1.5,
  String id = 'ri-1',
}) {
  return RecipeIngredient(
    id: id,
    recipeId: recipeId,
    ingredientId: ingredientId,
    quantity: quantity,
  );
}

void main() {
  late MockDatabaseHelper mockDb;
  late Ingredient ingredient;

  setUp(() {
    mockDb = MockDatabaseHelper();
    ingredient = _makeIngredient();
  });

  tearDown(() {
    mockDb.resetAllData();
  });

  group('IngredientDetailScreen — Used In tab', () {
    testWidgets('recipe card shows name, difficulty, rating, quantity',
        (tester) async {
      final recipe = _makeRecipe(difficulty: 3, rating: 4);
      mockDb.recipes[recipe.id] = recipe;
      await mockDb.addIngredientToRecipe(
        _makeRecipeIngredient(
            recipeId: recipe.id, ingredientId: ingredient.id, quantity: 2.5),
      );

      await tester.pumpWidget(_buildTestApp(
        IngredientDetailScreen(
            ingredient: ingredient, databaseHelper: mockDb),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Test Recipe'), findsOneWidget);
      expect(find.text('Uncategorized'), findsNothing);
      expect(find.textContaining('2.5'), findsOneWidget); // quantity
      // Difficulty 3: three filled batteries, two empty
      expect(find.byIcon(Icons.battery_full), findsNWidgets(3));
      expect(find.byIcon(Icons.battery_0_bar), findsNWidgets(2));
      // Rating 4: four filled stars, one empty
      expect(find.byIcon(Icons.star), findsNWidgets(4));
      expect(find.byIcon(Icons.star_border), findsNWidgets(1));
    });

    testWidgets('recipe card shows unit alongside quantity when ingredient has a unit',
        (tester) async {
      final ingredientWithUnit = _makeIngredient(id: 'ing-2', name: 'Flour');
      ingredientWithUnit.unit = MeasurementUnit.gram;
      mockDb.ingredients[ingredientWithUnit.id] = ingredientWithUnit;

      final recipe = _makeRecipe();
      mockDb.recipes[recipe.id] = recipe;
      await mockDb.addIngredientToRecipe(
        _makeRecipeIngredient(
            recipeId: recipe.id,
            ingredientId: ingredientWithUnit.id,
            quantity: 100),
      );

      await tester.pumpWidget(_buildTestApp(
        IngredientDetailScreen(
            ingredient: ingredientWithUnit, databaseHelper: mockDb),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('100'), findsOneWidget);
      expect(find.textContaining('g'), findsOneWidget);
    });

    testWidgets('recipe card shows quantity without unit when no unit is defined',
        (tester) async {
      final recipe = _makeRecipe();
      mockDb.recipes[recipe.id] = recipe;
      await mockDb.addIngredientToRecipe(
        _makeRecipeIngredient(
            recipeId: recipe.id, ingredientId: ingredient.id, quantity: 3),
      );

      await tester.pumpWidget(_buildTestApp(
        IngredientDetailScreen(
            ingredient: ingredient, databaseHelper: mockDb),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('3'), findsOneWidget);
      // null unit — rendered as bare number, no crash
      expect(find.textContaining('null'), findsNothing);
    });

    testWidgets('recipe card shows "to taste" when quantity is zero',
        (tester) async {
      final recipe = _makeRecipe();
      mockDb.recipes[recipe.id] = recipe;
      await mockDb.addIngredientToRecipe(
        _makeRecipeIngredient(
            recipeId: recipe.id, ingredientId: ingredient.id, quantity: 0),
      );

      await tester.pumpWidget(_buildTestApp(
        IngredientDetailScreen(
            ingredient: ingredient, databaseHelper: mockDb),
      ));
      await tester.pumpAndSettle();

      expect(find.text('to taste'), findsOneWidget);
      expect(find.textContaining('0'), findsNothing);
    });

    testWidgets('tapping recipe card navigates to RecipeDetailsScreen',
        (tester) async {
      final recipe = _makeRecipe();
      mockDb.recipes[recipe.id] = recipe;
      await mockDb.addIngredientToRecipe(
        _makeRecipeIngredient(
            recipeId: recipe.id, ingredientId: ingredient.id),
      );

      await tester.pumpWidget(_buildTestApp(
        IngredientDetailScreen(
            ingredient: ingredient, databaseHelper: mockDb),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Test Recipe'));
      await tester.pump(); // start navigation
      await tester.pump(); // settle navigation frame

      expect(find.byType(RecipeDetailsScreen), findsOneWidget);
    });

    testWidgets('shows empty state when no recipes use the ingredient',
        (tester) async {
      // No recipes or recipe ingredients added → empty result

      await tester.pumpWidget(_buildTestApp(
        IngredientDetailScreen(
            ingredient: ingredient, databaseHelper: mockDb),
      ));
      await tester.pumpAndSettle();

      expect(
        find.text(
            "This ingredient hasn't been added to any recipes yet."),
        findsOneWidget,
      );
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('no Incomplete chip when recipe has 3 or more ingredients',
        (tester) async {
      final recipe = _makeRecipe();
      mockDb.recipes[recipe.id] = recipe;
      // Add 3 ingredients → ingredient_count = 3 → not incomplete
      await mockDb.addIngredientToRecipe(
        _makeRecipeIngredient(
            id: 'ri-1', recipeId: recipe.id, ingredientId: ingredient.id),
      );
      await mockDb.addIngredientToRecipe(
        RecipeIngredient(
            id: 'ri-2',
            recipeId: recipe.id,
            ingredientId: 'other-ing',
            quantity: 1.0),
      );
      await mockDb.addIngredientToRecipe(
        RecipeIngredient(
            id: 'ri-3',
            recipeId: recipe.id,
            ingredientId: 'another-ing',
            quantity: 2.0),
      );

      await tester.pumpWidget(_buildTestApp(
        IngredientDetailScreen(
            ingredient: ingredient, databaseHelper: mockDb),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Incomplete'), findsNothing);
    });

    testWidgets('shows Incomplete chip when recipe has fewer than 3 ingredients',
        (tester) async {
      final recipe = _makeRecipe();
      mockDb.recipes[recipe.id] = recipe;
      // Only 1 ingredient → ingredient_count = 1 → incomplete
      await mockDb.addIngredientToRecipe(
        _makeRecipeIngredient(
            recipeId: recipe.id, ingredientId: ingredient.id),
      );

      await tester.pumpWidget(_buildTestApp(
        IngredientDetailScreen(
            ingredient: ingredient, databaseHelper: mockDb),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Incomplete'), findsOneWidget);
    });

    testWidgets('renders recipe list when recipes use the ingredient',
        (tester) async {
      final recipe = _makeRecipe();
      mockDb.recipes[recipe.id] = recipe;
      await mockDb.addIngredientToRecipe(
        _makeRecipeIngredient(
            recipeId: recipe.id, ingredientId: ingredient.id),
      );

      await tester.pumpWidget(_buildTestApp(
        IngredientDetailScreen(
            ingredient: ingredient, databaseHelper: mockDb),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Test Recipe'), findsOneWidget);
    });
  });

  group('IngredientDetailScreen — Meal History tab', () {
    Future<void> _switchToMealHistoryTab(WidgetTester tester) async {
      await tester.tap(find.text('Meal History'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows empty state when ingredient has no meal history',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        IngredientDetailScreen(
            ingredient: ingredient, databaseHelper: mockDb),
      ));
      await tester.pumpAndSettle();
      await _switchToMealHistoryTab(tester);

      expect(
        find.text("This ingredient hasn't appeared in any cooked meals yet."),
        findsOneWidget,
      );
    });

    testWidgets('shows meal history when ingredient is in a cooked recipe',
        (tester) async {
      final recipe = _makeRecipe();
      mockDb.recipes[recipe.id] = recipe;
      await mockDb.addIngredientToRecipe(
        _makeRecipeIngredient(
            recipeId: recipe.id, ingredientId: ingredient.id),
      );

      final meal = Meal(
        id: 'meal-1',
        cookedAt: DateTime(2025, 3, 15),
        servings: 2,
      );
      mockDb.meals[meal.id] = meal;
      mockDb.mealRecipes['mr-1'] = MealRecipe(
        id: 'mr-1',
        mealId: meal.id,
        recipeId: recipe.id,
      );

      await tester.pumpWidget(_buildTestApp(
        IngredientDetailScreen(
            ingredient: ingredient, databaseHelper: mockDb),
      ));
      await tester.pumpAndSettle();
      await _switchToMealHistoryTab(tester);

      expect(find.text('Test Recipe'), findsOneWidget);
      expect(find.text('2025-03-15'), findsOneWidget);
    });

    testWidgets('shows direct side ingredient in meal history',
        (tester) async {
      final meal = Meal(
        id: 'meal-2',
        cookedAt: DateTime(2025, 4, 1),
        servings: 2,
      );
      mockDb.meals[meal.id] = meal;
      mockDb.mealIngredients['mi-1'] = MealIngredient(
        id: 'mi-1',
        mealId: meal.id,
        ingredientId: ingredient.id,
        quantity: 1.0,
      );

      await tester.pumpWidget(_buildTestApp(
        IngredientDetailScreen(
            ingredient: ingredient, databaseHelper: mockDb),
      ));
      await tester.pumpAndSettle();
      await _switchToMealHistoryTab(tester);

      expect(find.text('Side ingredient'), findsOneWidget);
      expect(find.text('2025-04-01'), findsOneWidget);
    });

    testWidgets('summary chip shows correct count', (tester) async {
      final recipe = _makeRecipe();
      mockDb.recipes[recipe.id] = recipe;
      await mockDb.addIngredientToRecipe(
        _makeRecipeIngredient(
            recipeId: recipe.id, ingredientId: ingredient.id),
      );

      for (var i = 1; i <= 3; i++) {
        final meal = Meal(
          id: 'meal-$i',
          cookedAt: DateTime(2025, i, 1),
          servings: 2,
        );
        mockDb.meals[meal.id] = meal;
        mockDb.mealRecipes['mr-$i'] = MealRecipe(
          id: 'mr-$i',
          mealId: meal.id,
          recipeId: recipe.id,
        );
      }

      await tester.pumpWidget(_buildTestApp(
        IngredientDetailScreen(
            ingredient: ingredient, databaseHelper: mockDb),
      ));
      await tester.pumpAndSettle();
      await _switchToMealHistoryTab(tester);

      expect(find.textContaining('3'), findsAtLeastNWidgets(1));
    });

    testWidgets('filter chips are visible on meal history tab', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        IngredientDetailScreen(
            ingredient: ingredient, databaseHelper: mockDb),
      ));
      await tester.pumpAndSettle();
      await _switchToMealHistoryTab(tester);

      expect(find.text('Last 30 days'), findsOneWidget);
      expect(find.text('Last 3 months'), findsOneWidget);
      expect(find.text('All time'), findsOneWidget);
    });

    testWidgets('time range filter narrows results', (tester) async {
      final recipe = _makeRecipe();
      mockDb.recipes[recipe.id] = recipe;
      await mockDb.addIngredientToRecipe(
        _makeRecipeIngredient(
            recipeId: recipe.id, ingredientId: ingredient.id),
      );

      // Old meal outside 30 days
      final oldMeal = Meal(
        id: 'meal-old',
        cookedAt: DateTime.now().subtract(const Duration(days: 60)),
        servings: 2,
      );
      mockDb.meals[oldMeal.id] = oldMeal;
      mockDb.mealRecipes['mr-old'] = MealRecipe(
        id: 'mr-old',
        mealId: oldMeal.id,
        recipeId: recipe.id,
      );

      // Recent meal within 30 days
      final recentMeal = Meal(
        id: 'meal-recent',
        cookedAt: DateTime.now().subtract(const Duration(days: 5)),
        servings: 2,
      );
      mockDb.meals[recentMeal.id] = recentMeal;
      mockDb.mealRecipes['mr-recent'] = MealRecipe(
        id: 'mr-recent',
        mealId: recentMeal.id,
        recipeId: recipe.id,
      );

      await tester.pumpWidget(_buildTestApp(
        IngredientDetailScreen(
            ingredient: ingredient, databaseHelper: mockDb),
      ));
      await tester.pumpAndSettle();
      await _switchToMealHistoryTab(tester);

      // All time: both meals show → 2 recipe name tiles
      expect(find.text('Test Recipe'), findsNWidgets(2));

      // Switch to Last 30 days
      await tester.tap(find.text('Last 30 days'));
      await tester.pumpAndSettle();

      // Only recent meal should remain
      expect(find.text('Test Recipe'), findsOneWidget);
    });
  });
}
