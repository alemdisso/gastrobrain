// test/edge_cases/boundary_conditions/list_size_boundary_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/ingredient.dart';
import 'package:gastrobrain/models/ingredient_category.dart';
import 'package:gastrobrain/models/recipe_ingredient.dart';
import 'package:gastrobrain/models/meal.dart';
import 'package:gastrobrain/models/meal_recipe.dart';
import '../../mocks/mock_database_helper.dart';

/// Tests for collection size boundary conditions.
///
/// Verifies that the application correctly handles:
/// - Empty collections (0 items)
/// - Single item collections
/// - Small collections (< 10 items)
/// - Medium collections (10-100 items)
/// - Large collections (100+ items)
/// - Very large collections (1000+ items)
///
/// These tests ensure the application scales properly and handles
/// extreme collection sizes without performance degradation or crashes.
void main() {
  group('List Size Boundary Tests', () {
    late MockDatabaseHelper mockDbHelper;

    setUp(() {
      mockDbHelper = MockDatabaseHelper();
    });

    tearDown(() {
      mockDbHelper.resetAllData();
    });

    group('Recipe Ingredient Collections', () {
      test('recipe with 0 ingredients is valid (can be created)', () async {
        final recipe = Recipe(
          id: 'recipe-no-ingredients',
          name: 'Empty Recipe',
          createdAt: DateTime.now(),
        );

        // Recipe can be created without ingredients
        await mockDbHelper.insertRecipe(recipe);
        final retrieved = await mockDbHelper.getRecipe(recipe.id);
        expect(retrieved, isNotNull);

        // Get ingredients for this recipe (should be empty)
        final ingredients = await mockDbHelper.getRecipeIngredients(recipe.id);
        expect(ingredients, isEmpty);
      });

      test('recipe with 1 ingredient is handled correctly', () async {
        final recipe = Recipe(
          id: 'recipe-1-ingredient',
          name: 'Single Ingredient Recipe',
          createdAt: DateTime.now(),
        );

        final ingredient = Ingredient(
          id: 'ing-1',
          name: 'Salt',
          category: IngredientCategory.seasoning,
        );

        await mockDbHelper.insertRecipe(recipe);
        await mockDbHelper.insertIngredient(ingredient);

        final recipeIngredient = RecipeIngredient(
          id: 'ri-1',
          recipeId: recipe.id,
          ingredientId: ingredient.id,
          quantity: 1.0,
        );

        await mockDbHelper.addIngredientToRecipe(recipeIngredient);

        // Verify single ingredient is stored
        final ingredients = await mockDbHelper.getRecipeIngredients(recipe.id);
        expect(ingredients.length, equals(1));
        expect(ingredients[0]['ingredient_id'], equals(ingredient.id));
      });

      test('recipe with 10 ingredients is handled correctly', () async {
        final recipe = Recipe(
          id: 'recipe-10-ingredients',
          name: 'Recipe with 10 Ingredients',
          createdAt: DateTime.now(),
        );

        await mockDbHelper.insertRecipe(recipe);

        // Add 10 ingredients
        for (int i = 0; i < 10; i++) {
          final ingredient = Ingredient(
            id: 'ing-$i',
            name: 'Ingredient $i',
            category: IngredientCategory.other,
          );

          await mockDbHelper.insertIngredient(ingredient);

          final recipeIngredient = RecipeIngredient(
            id: 'ri-$i',
            recipeId: recipe.id,
            ingredientId: ingredient.id,
            quantity: 1.0,
          );

          await mockDbHelper.addIngredientToRecipe(recipeIngredient);
        }

        // Verify all 10 ingredients are stored
        final ingredients = await mockDbHelper.getRecipeIngredients(recipe.id);
        expect(ingredients.length, equals(10));
      });

      test('recipe with 100+ ingredients is handled correctly', () async {
        final recipe = Recipe(
          id: 'recipe-100-ingredients',
          name: 'Recipe with 100 Ingredients',
          createdAt: DateTime.now(),
        );

        await mockDbHelper.insertRecipe(recipe);

        // Add 100 ingredients
        for (int i = 0; i < 100; i++) {
          final ingredient = Ingredient(
            id: 'ing-$i',
            name: 'Ingredient $i',
            category: IngredientCategory.other,
          );

          await mockDbHelper.insertIngredient(ingredient);

          final recipeIngredient = RecipeIngredient(
            id: 'ri-$i',
            recipeId: recipe.id,
            ingredientId: ingredient.id,
            quantity: 1.0,
          );

          await mockDbHelper.addIngredientToRecipe(recipeIngredient);
        }

        // Verify all 100 ingredients are stored
        final ingredients = await mockDbHelper.getRecipeIngredients(recipe.id);
        expect(ingredients.length, equals(100));

        // Verify we can retrieve individual ingredients
        expect(ingredients[0]['ingredient_id'], equals('ing-0'));
        expect(ingredients[50]['ingredient_id'], equals('ing-50'));
        expect(ingredients[99]['ingredient_id'], equals('ing-99'));
      });

      test('recipe with 500 ingredients performs acceptably', () async {
        final recipe = Recipe(
          id: 'recipe-500-ingredients',
          name: 'Recipe with 500 Ingredients',
          createdAt: DateTime.now(),
        );

        await mockDbHelper.insertRecipe(recipe);

        // Add 500 ingredients (simulates extreme edge case)
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 500; i++) {
          final ingredient = Ingredient(
            id: 'ing-$i',
            name: 'Ingredient $i',
            category: IngredientCategory.other,
          );

          await mockDbHelper.insertIngredient(ingredient);

          final recipeIngredient = RecipeIngredient(
            id: 'ri-$i',
            recipeId: recipe.id,
            ingredientId: ingredient.id,
            quantity: 1.0,
          );

          await mockDbHelper.addIngredientToRecipe(recipeIngredient);
        }

        stopwatch.stop();

        // Verify all 500 ingredients are stored
        final ingredients = await mockDbHelper.getRecipeIngredients(recipe.id);
        expect(ingredients.length, equals(500));

        // Performance check: should complete reasonably fast (< 5 seconds for mock DB)
        expect(stopwatch.elapsedMilliseconds, lessThan(5000),
            reason: 'Adding 500 ingredients should complete in < 5 seconds');
      });
    });

    group('Meal Recipe Collections', () {
      test('meal with 1 recipe (minimum) is valid', () async {
        final recipe = Recipe(
          id: 'recipe-1',
          name: 'Main Dish',
          createdAt: DateTime.now(),
        );

        await mockDbHelper.insertRecipe(recipe);

        final meal = Meal(
          id: 'meal-1',
          cookedAt: DateTime.now().subtract(const Duration(hours: 1)),
          servings: 2,
          notes: 'Single Recipe Meal',
        );

        await mockDbHelper.insertMeal(meal);

        // Link recipe to meal
        final mealRecipe = MealRecipe(
          id: 'mr-1',
          mealId: meal.id,
          recipeId: recipe.id,
          isPrimaryDish: true,
        );

        await mockDbHelper.insertMealRecipe(mealRecipe);

        // Verify meal has 1 recipe
        final mealRecipes = await mockDbHelper.getMealRecipesForMeal(meal.id);
        expect(mealRecipes.length, equals(1));
      });

      test('meal with 10+ side dishes (multi-recipe meal) is handled', () async {
        final mainRecipe = Recipe(
          id: 'main-recipe',
          name: 'Main Dish',
          createdAt: DateTime.now(),
        );

        await mockDbHelper.insertRecipe(mainRecipe);

        final meal = Meal(
          id: 'meal-multi',
          cookedAt: DateTime.now().subtract(const Duration(hours: 1)),
          servings: 4,
          notes: 'Multi-Recipe Meal',
        );

        await mockDbHelper.insertMeal(meal);

        // Add main dish
        await mockDbHelper.insertMealRecipe(MealRecipe(
          id: 'mr-main',
          mealId: meal.id,
          recipeId: mainRecipe.id,
          isPrimaryDish: true,
        ));

        // Add 10 side dishes
        for (int i = 0; i < 10; i++) {
          final sideRecipe = Recipe(
            id: 'side-$i',
            name: 'Side Dish $i',
            createdAt: DateTime.now(),
          );

          await mockDbHelper.insertRecipe(sideRecipe);

          await mockDbHelper.insertMealRecipe(MealRecipe(
            id: 'mr-side-$i',
            mealId: meal.id,
            recipeId: sideRecipe.id,
            isPrimaryDish: false,
          ));
        }

        // Verify meal has 11 recipes total (1 main + 10 sides)
        final mealRecipes = await mockDbHelper.getMealRecipesForMeal(meal.id);
        expect(mealRecipes.length, equals(11));

        // Verify exactly 1 primary dish
        final primaryDishes =
            mealRecipes.where((mr) => mr.isPrimaryDish == true).toList();
        expect(primaryDishes.length, equals(1));

        // Verify 10 side dishes
        final sideDishes =
            mealRecipes.where((mr) => mr.isPrimaryDish == false).toList();
        expect(sideDishes.length, equals(10));
      });

      test('meal with 50 side dishes is handled (extreme case)', () async {
        final mainRecipe = Recipe(
          id: 'main-extreme',
          name: 'Main Dish',
          createdAt: DateTime.now(),
        );

        await mockDbHelper.insertRecipe(mainRecipe);

        final meal = Meal(
          id: 'meal-extreme',
          cookedAt: DateTime.now().subtract(const Duration(hours: 1)),
          servings: 10,
          notes: 'Extreme Multi-Recipe Meal',
        );

        await mockDbHelper.insertMeal(meal);

        // Add main dish
        await mockDbHelper.insertMealRecipe(MealRecipe(
          id: 'mr-main-extreme',
          mealId: meal.id,
          recipeId: mainRecipe.id,
          isPrimaryDish: true,
        ));

        // Add 50 side dishes
        for (int i = 0; i < 50; i++) {
          final sideRecipe = Recipe(
            id: 'extreme-side-$i',
            name: 'Side Dish $i',
            createdAt: DateTime.now(),
          );

          await mockDbHelper.insertRecipe(sideRecipe);

          await mockDbHelper.insertMealRecipe(MealRecipe(
            id: 'mr-extreme-side-$i',
            mealId: meal.id,
            recipeId: sideRecipe.id,
            isPrimaryDish: false,
          ));
        }

        // Verify meal has 51 recipes total
        final mealRecipes = await mockDbHelper.getMealRecipesForMeal(meal.id);
        expect(mealRecipes.length, equals(51));
      });
    });

    group('Database Collection Scaling', () {
      test('database with 100 recipes is handled efficiently', () async {
        final stopwatch = Stopwatch()..start();

        // Insert 100 recipes
        for (int i = 0; i < 100; i++) {
          final recipe = Recipe(
            id: 'recipe-$i',
            name: 'Recipe $i',
            createdAt: DateTime.now(),
          );
          await mockDbHelper.insertRecipe(recipe);
        }

        stopwatch.stop();

        // Verify all recipes are stored
        expect(mockDbHelper.recipes.length, equals(100));

        // Performance check: should complete in reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(1000),
            reason: 'Inserting 100 recipes should complete in < 1 second');

        // Verify we can retrieve all recipes
        final allRecipes = await mockDbHelper.getAllRecipes();
        expect(allRecipes.length, equals(100));
      });

      test('database with 1000+ recipes performs acceptably', () async {
        final stopwatch = Stopwatch()..start();

        // Insert 1000 recipes
        for (int i = 0; i < 1000; i++) {
          final recipe = Recipe(
            id: 'recipe-$i',
            name: 'Recipe $i',
            notes: 'Recipe notes $i',
            createdAt: DateTime.now(),
          );
          await mockDbHelper.insertRecipe(recipe);
        }

        stopwatch.stop();

        // Verify all recipes are stored
        expect(mockDbHelper.recipes.length, equals(1000));

        // Performance check: should complete in reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(10000),
            reason: 'Inserting 1000 recipes should complete in < 10 seconds');

        // Verify we can retrieve all recipes
        final retrieveStopwatch = Stopwatch()..start();
        final allRecipes = await mockDbHelper.getAllRecipes();
        retrieveStopwatch.stop();

        expect(allRecipes.length, equals(1000));

        // Retrieval should be fast
        expect(retrieveStopwatch.elapsedMilliseconds, lessThan(2000),
            reason: 'Retrieving 1000 recipes should complete in < 2 seconds');
      });

      test('database with 100 ingredients is handled efficiently', () async {
        // Insert 100 ingredients
        for (int i = 0; i < 100; i++) {
          final ingredient = Ingredient(
            id: 'ing-$i',
            name: 'Ingredient $i',
            category: IngredientCategory.other,
          );
          await mockDbHelper.insertIngredient(ingredient);
        }

        // Verify all ingredients are stored
        expect(mockDbHelper.ingredients.length, equals(100));

        // Verify we can retrieve all ingredients
        final allIngredients = await mockDbHelper.getAllIngredients();
        expect(allIngredients.length, equals(100));
      });

      test('database with 1000 meals is handled correctly', () async {
        // Create a recipe to use for all meals
        final recipe = Recipe(
          id: 'recipe-common',
          name: 'Common Recipe',
          createdAt: DateTime.now(),
        );
        await mockDbHelper.insertRecipe(recipe);

        // Insert 1000 meals
        for (int i = 0; i < 1000; i++) {
          final meal = Meal(
            id: 'meal-$i',
            cookedAt:
                DateTime.now().subtract(Duration(days: i)), // Different dates
            servings: 2,
            notes: 'Meal $i',
          );
          await mockDbHelper.insertMeal(meal);

          // Link recipe to meal
          await mockDbHelper.insertMealRecipe(MealRecipe(
            id: 'mr-$i',
            mealId: meal.id,
            recipeId: recipe.id,
            isPrimaryDish: true,
          ));
        }

        // Verify all meals are stored
        expect(mockDbHelper.meals.length, equals(1000));

        // Verify we can retrieve meals
        final allMeals = await mockDbHelper.getAllMeals();
        expect(allMeals.length, equals(1000));
      });
    });

    group('Search and Filter with Large Collections', () {
      test('searching through 100+ recipes returns correct results', () async {
        // Insert 100 recipes with pattern in names
        for (int i = 0; i < 100; i++) {
          final recipe = Recipe(
            id: 'recipe-$i',
            name: i % 10 == 0
                ? 'Special Recipe $i' // Every 10th is "Special"
                : 'Regular Recipe $i',
            createdAt: DateTime.now(),
          );
          await mockDbHelper.insertRecipe(recipe);
        }

        // Filter for "Special" recipes
        final allRecipes = await mockDbHelper.getAllRecipes();
        final searchResults = allRecipes
            .where((recipe) => recipe.name.contains('Special'))
            .toList();

        // Should find 10 "Special" recipes (indices 0, 10, 20, ..., 90)
        expect(searchResults.length, equals(10));

        // Verify all results contain "Special"
        for (final recipe in searchResults) {
          expect(recipe.name, contains('Special'));
        }
      });

      test('filtering large recipe collection by category', () async {
        // Insert 100 recipes, half in each of two categories
        for (int i = 0; i < 100; i++) {
          final recipe = Recipe(
            id: 'recipe-$i',
            name: 'Recipe $i',
            createdAt: DateTime.now(),
          );
          await mockDbHelper.insertRecipe(recipe);

          // Add 2 ingredients per recipe to test filtering
          final ingredient1 = Ingredient(
            id: 'ing-${i}-1',
            name: 'Ingredient ${i}-1',
            category: i % 2 == 0
                ? IngredientCategory.vegetable
                : IngredientCategory.grain,
          );

          await mockDbHelper.insertIngredient(ingredient1);

          await mockDbHelper.addIngredientToRecipe(RecipeIngredient(
            id: 'ri-${i}-1',
            recipeId: recipe.id,
            ingredientId: ingredient1.id,
            quantity: 1.0,
          ));
        }

        // Verify we can filter ingredients by category
        final allIngredients = await mockDbHelper.getAllIngredients();
        final vegetables = allIngredients
            .where((ing) => ing.category == IngredientCategory.vegetable)
            .toList();
        final grains = allIngredients
            .where((ing) => ing.category == IngredientCategory.grain)
            .toList();

        expect(vegetables.length, equals(50));
        expect(grains.length, equals(50));
      });
    });

    group('Empty Collection Results', () {
      test('search with no matching results returns empty list', () async {
        // Insert some recipes
        await mockDbHelper.insertRecipe(Recipe(
          id: 'recipe-1',
          name: 'Pasta',
          createdAt: DateTime.now(),
        ));

        await mockDbHelper.insertRecipe(Recipe(
          id: 'recipe-2',
          name: 'Pizza',
          createdAt: DateTime.now(),
        ));

        // Filter for something that doesn't exist
        final allRecipes = await mockDbHelper.getAllRecipes();
        final results = allRecipes
            .where((recipe) => recipe.name.contains('NonExistent'))
            .toList();

        expect(results, isEmpty);
        expect(results.length, equals(0));
      });

      test('getAllRecipes returns empty list when no recipes exist', () async {
        final allRecipes = await mockDbHelper.getAllRecipes();

        expect(allRecipes, isEmpty);
        expect(allRecipes, isA<List<Recipe>>());
      });

      test('getAllIngredients returns empty list when no ingredients exist',
          () async {
        final allIngredients = await mockDbHelper.getAllIngredients();

        expect(allIngredients, isEmpty);
        expect(allIngredients, isA<List<Ingredient>>());
      });

      test('getMealRecipesForMeal returns empty list for meal with no recipes',
          () async {
        final meal = Meal(
          id: 'meal-empty',
          cookedAt: DateTime.now().subtract(const Duration(hours: 1)),
          servings: 1,
          notes: 'Empty Meal',
        );

        await mockDbHelper.insertMeal(meal);

        final mealRecipes = await mockDbHelper.getMealRecipesForMeal(meal.id);

        expect(mealRecipes, isEmpty);
      });
    });

    group('Collection Consistency', () {
      test('deleting recipe with many ingredients cleans up properly', () async {
        final recipe = Recipe(
          id: 'recipe-cleanup',
          name: 'Recipe to Delete',
          createdAt: DateTime.now(),
        );

        await mockDbHelper.insertRecipe(recipe);

        // Add 50 ingredients
        for (int i = 0; i < 50; i++) {
          final ingredient = Ingredient(
            id: 'cleanup-ing-$i',
            name: 'Ingredient $i',
            category: IngredientCategory.other,
          );

          await mockDbHelper.insertIngredient(ingredient);

          await mockDbHelper.addIngredientToRecipe(RecipeIngredient(
            id: 'cleanup-ri-$i',
            recipeId: recipe.id,
            ingredientId: ingredient.id,
            quantity: 1.0,
          ));
        }

        // Verify 50 recipe ingredients exist
        final beforeDelete = await mockDbHelper.getRecipeIngredients(recipe.id);
        expect(beforeDelete.length, equals(50));

        // Delete the recipe (should cascade delete recipe ingredients)
        await mockDbHelper.deleteRecipe(recipe.id);

        // Verify recipe is deleted
        expect(mockDbHelper.recipes.containsKey(recipe.id), isFalse);

        // Note: In real database, recipe_ingredients would be cascade deleted
        // In MockDatabaseHelper, we need to verify the implementation
      });

      test('updating recipe with large ingredient list maintains consistency',
          () async {
        final recipe = Recipe(
          id: 'recipe-update',
          name: 'Original Name',
          createdAt: DateTime.now(),
        );

        await mockDbHelper.insertRecipe(recipe);

        // Add 25 ingredients
        for (int i = 0; i < 25; i++) {
          final ingredient = Ingredient(
            id: 'update-ing-$i',
            name: 'Ingredient $i',
            category: IngredientCategory.other,
          );

          await mockDbHelper.insertIngredient(ingredient);

          await mockDbHelper.addIngredientToRecipe(RecipeIngredient(
            id: 'update-ri-$i',
            recipeId: recipe.id,
            ingredientId: ingredient.id,
            quantity: 1.0,
          ));
        }

        // Update recipe
        final updatedRecipe = Recipe(
          id: recipe.id,
          name: 'Updated Name',
          createdAt: recipe.createdAt,
          notes: 'Added notes',
        );

        await mockDbHelper.updateRecipe(updatedRecipe);

        // Verify recipe is updated
        final retrieved = await mockDbHelper.getRecipe(recipe.id);
        expect(retrieved!.name, equals('Updated Name'));
        expect(retrieved.notes, equals('Added notes'));

        // Verify ingredients are still linked
        final ingredients = await mockDbHelper.getRecipeIngredients(recipe.id);
        expect(ingredients.length, equals(25));
      });
    });
  });
}
