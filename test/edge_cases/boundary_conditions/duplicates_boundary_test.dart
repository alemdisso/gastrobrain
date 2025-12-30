// test/edge_cases/boundary_conditions/duplicates_boundary_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/ingredient.dart';
import 'package:gastrobrain/models/ingredient_category.dart';
import 'package:gastrobrain/models/recipe_ingredient.dart';
import 'package:gastrobrain/models/meal.dart';
import 'package:gastrobrain/models/meal_recipe.dart';
import '../../mocks/mock_database_helper.dart';

/// Tests for duplicate and uniqueness constraints.
///
/// Verifies that the application correctly handles:
/// - Duplicate entity names (recipes, ingredients)
/// - Same entity added multiple times to collections
/// - Conflict detection for meal planning
/// - Data integrity with duplicate entries
///
/// These tests document the current behavior regarding duplicates
/// and ensure consistency in how the application handles them.
void main() {
  group('Duplicates & Unique Constraints Tests', () {
    late MockDatabaseHelper mockDbHelper;

    setUp(() {
      mockDbHelper = MockDatabaseHelper();
    });

    tearDown(() {
      mockDbHelper.resetAllData();
    });

    group('Duplicate Recipe Names', () {
      test('multiple recipes with same name are allowed', () async {
        final recipe1 = Recipe(
          id: 'recipe-1',
          name: 'Pasta Carbonara',
          createdAt: DateTime.now(),
        );

        final recipe2 = Recipe(
          id: 'recipe-2',
          name: 'Pasta Carbonara', // Same name, different ID
          createdAt: DateTime.now(),
        );

        // Both should be inserted successfully
        await mockDbHelper.insertRecipe(recipe1);
        await mockDbHelper.insertRecipe(recipe2);

        // Verify both exist
        expect(mockDbHelper.recipes.length, equals(2));
        expect(mockDbHelper.recipes.containsKey('recipe-1'), isTrue);
        expect(mockDbHelper.recipes.containsKey('recipe-2'), isTrue);

        // Verify both have the same name
        final retrieved1 = await mockDbHelper.getRecipe('recipe-1');
        final retrieved2 = await mockDbHelper.getRecipe('recipe-2');
        expect(retrieved1!.name, equals(retrieved2!.name));
      });

      test('duplicate recipe names can be filtered/distinguished', () async {
        // Insert 5 recipes, 3 with same name, 2 with different names
        await mockDbHelper.insertRecipe(Recipe(
          id: 'recipe-1',
          name: 'Chicken Soup',
          createdAt: DateTime.now(),
        ));

        await mockDbHelper.insertRecipe(Recipe(
          id: 'recipe-2',
          name: 'Chicken Soup', // Duplicate
          createdAt: DateTime.now(),
        ));

        await mockDbHelper.insertRecipe(Recipe(
          id: 'recipe-3',
          name: 'Beef Stew',
          createdAt: DateTime.now(),
        ));

        await mockDbHelper.insertRecipe(Recipe(
          id: 'recipe-4',
          name: 'Chicken Soup', // Another duplicate
          createdAt: DateTime.now(),
        ));

        await mockDbHelper.insertRecipe(Recipe(
          id: 'recipe-5',
          name: 'Fish Tacos',
          createdAt: DateTime.now(),
        ));

        // Filter by name
        final allRecipes = await mockDbHelper.getAllRecipes();
        final chickenSoups = allRecipes
            .where((recipe) => recipe.name == 'Chicken Soup')
            .toList();

        expect(chickenSoups.length, equals(3));
        expect(allRecipes.length, equals(5));
      });

      test('updating one duplicate name recipe does not affect others', () async {
        final recipe1 = Recipe(
          id: 'recipe-1',
          name: 'Original Name',
          createdAt: DateTime.now(),
        );

        final recipe2 = Recipe(
          id: 'recipe-2',
          name: 'Original Name',
          createdAt: DateTime.now(),
        );

        await mockDbHelper.insertRecipe(recipe1);
        await mockDbHelper.insertRecipe(recipe2);

        // Update recipe1's name
        final updated = Recipe(
          id: 'recipe-1',
          name: 'Updated Name',
          createdAt: recipe1.createdAt,
        );

        await mockDbHelper.updateRecipe(updated);

        // Verify recipe1 is updated
        final retrieved1 = await mockDbHelper.getRecipe('recipe-1');
        expect(retrieved1!.name, equals('Updated Name'));

        // Verify recipe2 is unchanged
        final retrieved2 = await mockDbHelper.getRecipe('recipe-2');
        expect(retrieved2!.name, equals('Original Name'));
      });
    });

    group('Duplicate Ingredient Names', () {
      test('ingredients with same name in different categories are allowed',
          () async {
        final tomatoVegetable = Ingredient(
          id: 'tomato-veg',
          name: 'Tomato',
          category: IngredientCategory.vegetable,
        );

        final tomatoFruit = Ingredient(
          id: 'tomato-fruit',
          name: 'Tomato',
          category: IngredientCategory.fruit,
        );

        // Both should be inserted successfully
        await mockDbHelper.insertIngredient(tomatoVegetable);
        await mockDbHelper.insertIngredient(tomatoFruit);

        // Verify both exist
        expect(mockDbHelper.ingredients.length, equals(2));

        // Both have same name but different categories
        expect(tomatoVegetable.name, equals(tomatoFruit.name));
        expect(tomatoVegetable.category, isNot(equals(tomatoFruit.category)));
      });

      test('ingredients with same name in same category are allowed', () async {
        // This might represent different varieties or brands
        final salt1 = Ingredient(
          id: 'salt-1',
          name: 'Sea Salt',
          category: IngredientCategory.seasoning,
        );

        final salt2 = Ingredient(
          id: 'salt-2',
          name: 'Sea Salt',
          category: IngredientCategory.seasoning,
        );

        await mockDbHelper.insertIngredient(salt1);
        await mockDbHelper.insertIngredient(salt2);

        // Both should exist
        expect(mockDbHelper.ingredients.length, equals(2));

        // Can be distinguished by ID
        expect(mockDbHelper.ingredients.containsKey('salt-1'), isTrue);
        expect(mockDbHelper.ingredients.containsKey('salt-2'), isTrue);
      });

      test('duplicate ingredient names can be filtered by category', () async {
        // Add multiple "Garlic" ingredients in different categories
        await mockDbHelper.insertIngredient(Ingredient(
          id: 'garlic-veg',
          name: 'Garlic',
          category: IngredientCategory.vegetable,
        ));

        await mockDbHelper.insertIngredient(Ingredient(
          id: 'garlic-seasoning',
          name: 'Garlic',
          category: IngredientCategory.seasoning,
        ));

        final allIngredients = await mockDbHelper.getAllIngredients();
        final garlics = allIngredients
            .where((ing) => ing.name == 'Garlic')
            .toList();

        expect(garlics.length, equals(2));

        // Can filter by category
        final garlicVeg = garlics
            .where((ing) => ing.category == IngredientCategory.vegetable)
            .toList();
        expect(garlicVeg.length, equals(1));
        expect(garlicVeg.first.id, equals('garlic-veg'));
      });
    });

    group('Same Ingredient Added Multiple Times to Recipe', () {
      test('same ingredient can be added twice to recipe with different IDs',
          () async {
        final recipe = Recipe(
          id: 'recipe-1',
          name: 'Complex Dish',
          createdAt: DateTime.now(),
        );

        final ingredient = Ingredient(
          id: 'salt',
          name: 'Salt',
          category: IngredientCategory.seasoning,
        );

        await mockDbHelper.insertRecipe(recipe);
        await mockDbHelper.insertIngredient(ingredient);

        // Add salt twice (e.g., different stages of cooking)
        final recipeIngredient1 = RecipeIngredient(
          id: 'ri-1',
          recipeId: recipe.id,
          ingredientId: ingredient.id,
          quantity: 1.0,
          notes: 'For marinade',
        );

        final recipeIngredient2 = RecipeIngredient(
          id: 'ri-2',
          recipeId: recipe.id,
          ingredientId: ingredient.id,
          quantity: 0.5,
          notes: 'For finishing',
        );

        await mockDbHelper.addIngredientToRecipe(recipeIngredient1);
        await mockDbHelper.addIngredientToRecipe(recipeIngredient2);

        // Verify both entries exist
        final ingredients = await mockDbHelper.getRecipeIngredients(recipe.id);
        expect(ingredients.length, equals(2));

        // Both reference the same ingredient
        expect(ingredients[0]['ingredient_id'], equals(ingredient.id));
        expect(ingredients[1]['ingredient_id'], equals(ingredient.id));

        // But have different quantities and notes
        expect(ingredients[0]['quantity'], isNot(equals(ingredients[1]['quantity'])));
      });

      test('deleting one instance of duplicate ingredient does not affect other',
          () async {
        final recipe = Recipe(
          id: 'recipe-1',
          name: 'Test Recipe',
          createdAt: DateTime.now(),
        );

        final ingredient = Ingredient(
          id: 'butter',
          name: 'Butter',
          category: IngredientCategory.dairy,
        );

        await mockDbHelper.insertRecipe(recipe);
        await mockDbHelper.insertIngredient(ingredient);

        // Add butter twice
        final ri1 = RecipeIngredient(
          id: 'ri-1',
          recipeId: recipe.id,
          ingredientId: ingredient.id,
          quantity: 2.0,
        );

        final ri2 = RecipeIngredient(
          id: 'ri-2',
          recipeId: recipe.id,
          ingredientId: ingredient.id,
          quantity: 1.0,
        );

        await mockDbHelper.addIngredientToRecipe(ri1);
        await mockDbHelper.addIngredientToRecipe(ri2);

        // Verify 2 entries
        var ingredients = await mockDbHelper.getRecipeIngredients(recipe.id);
        expect(ingredients.length, equals(2));

        // Delete one
        await mockDbHelper.deleteRecipeIngredient('ri-1');

        // Verify only 1 remains
        ingredients = await mockDbHelper.getRecipeIngredients(recipe.id);
        expect(ingredients.length, equals(1));
        expect(ingredients[0]['id'], equals('ri-2'));
      });
    });

    group('Same Side Dish Added Multiple Times to Meal', () {
      test('same recipe can be added as multiple side dishes', () async {
        final mainRecipe = Recipe(
          id: 'main',
          name: 'Steak',
          createdAt: DateTime.now(),
        );

        final sideRecipe = Recipe(
          id: 'side',
          name: 'Roasted Vegetables',
          createdAt: DateTime.now(),
        );

        final meal = Meal(
          id: 'meal-1',
          cookedAt: DateTime.now().subtract(const Duration(hours: 1)),
          servings: 4,
        );

        await mockDbHelper.insertRecipe(mainRecipe);
        await mockDbHelper.insertRecipe(sideRecipe);
        await mockDbHelper.insertMeal(meal);

        // Add main dish
        await mockDbHelper.insertMealRecipe(MealRecipe(
          id: 'mr-main',
          mealId: meal.id,
          recipeId: mainRecipe.id,
          isPrimaryDish: true,
        ));

        // Add same side dish twice (e.g., double portion)
        await mockDbHelper.insertMealRecipe(MealRecipe(
          id: 'mr-side-1',
          mealId: meal.id,
          recipeId: sideRecipe.id,
          isPrimaryDish: false,
          notes: 'First serving',
        ));

        await mockDbHelper.insertMealRecipe(MealRecipe(
          id: 'mr-side-2',
          mealId: meal.id,
          recipeId: sideRecipe.id,
          isPrimaryDish: false,
          notes: 'Second serving',
        ));

        // Verify 3 total recipe links (1 main + 2 sides of same recipe)
        final mealRecipes = await mockDbHelper.getMealRecipesForMeal(meal.id);
        expect(mealRecipes.length, equals(3));

        // Verify 2 are the same side recipe
        final sides = mealRecipes
            .where((mr) => mr.recipeId == sideRecipe.id)
            .toList();
        expect(sides.length, equals(2));
      });

      test('multiple instances of same side dish can have different notes',
          () async {
        final recipe = Recipe(
          id: 'rice',
          name: 'Rice',
          createdAt: DateTime.now(),
        );

        final meal = Meal(
          id: 'meal-1',
          cookedAt: DateTime.now().subtract(const Duration(hours: 1)),
          servings: 6,
        );

        await mockDbHelper.insertRecipe(recipe);
        await mockDbHelper.insertMeal(meal);

        // Add rice multiple times with different preparations
        await mockDbHelper.insertMealRecipe(MealRecipe(
          id: 'mr-1',
          mealId: meal.id,
          recipeId: recipe.id,
          isPrimaryDish: false,
          notes: 'White rice',
        ));

        await mockDbHelper.insertMealRecipe(MealRecipe(
          id: 'mr-2',
          mealId: meal.id,
          recipeId: recipe.id,
          isPrimaryDish: false,
          notes: 'Fried rice',
        ));

        final mealRecipes = await mockDbHelper.getMealRecipesForMeal(meal.id);
        expect(mealRecipes.length, equals(2));

        // Both reference same recipe but have different notes
        expect(mealRecipes[0].recipeId, equals(mealRecipes[1].recipeId));
        expect(mealRecipes[0].notes, isNot(equals(mealRecipes[1].notes)));
      });
    });

    group('Duplicate Data Integrity', () {
      test('deleting shared ingredient does not affect other recipes using it',
          () async {
        final sharedIngredient = Ingredient(
          id: 'salt',
          name: 'Salt',
          category: IngredientCategory.seasoning,
        );

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

        await mockDbHelper.insertIngredient(sharedIngredient);
        await mockDbHelper.insertRecipe(recipe1);
        await mockDbHelper.insertRecipe(recipe2);

        // Both recipes use the same ingredient
        await mockDbHelper.addIngredientToRecipe(RecipeIngredient(
          id: 'ri-1',
          recipeId: recipe1.id,
          ingredientId: sharedIngredient.id,
          quantity: 1.0,
        ));

        await mockDbHelper.addIngredientToRecipe(RecipeIngredient(
          id: 'ri-2',
          recipeId: recipe2.id,
          ingredientId: sharedIngredient.id,
          quantity: 2.0,
        ));

        // Delete ingredient from recipe1
        await mockDbHelper.deleteRecipeIngredient('ri-1');

        // Verify ingredient still exists in recipe2
        final recipe2Ingredients =
            await mockDbHelper.getRecipeIngredients(recipe2.id);
        expect(recipe2Ingredients.length, equals(1));
        expect(recipe2Ingredients[0]['ingredient_id'], equals(sharedIngredient.id));

        // Ingredient entity still exists
        expect(mockDbHelper.ingredients.containsKey(sharedIngredient.id), isTrue);
      });

      test('deleting shared recipe from one meal does not affect other meals',
          () async {
        final sharedRecipe = Recipe(
          id: 'popular-recipe',
          name: 'Popular Dish',
          createdAt: DateTime.now(),
        );

        final meal1 = Meal(
          id: 'meal-1',
          cookedAt: DateTime.now().subtract(const Duration(days: 1)),
          servings: 2,
        );

        final meal2 = Meal(
          id: 'meal-2',
          cookedAt: DateTime.now().subtract(const Duration(days: 2)),
          servings: 4,
        );

        await mockDbHelper.insertRecipe(sharedRecipe);
        await mockDbHelper.insertMeal(meal1);
        await mockDbHelper.insertMeal(meal2);

        // Both meals use the same recipe
        final mr1 = await mockDbHelper.insertMealRecipe(MealRecipe(
          id: 'mr-1',
          mealId: meal1.id,
          recipeId: sharedRecipe.id,
          isPrimaryDish: true,
        ));

        await mockDbHelper.insertMealRecipe(MealRecipe(
          id: 'mr-2',
          mealId: meal2.id,
          recipeId: sharedRecipe.id,
          isPrimaryDish: true,
        ));

        // Delete recipe from meal1
        await mockDbHelper.deleteMealRecipe(mr1);

        // Verify recipe still exists in meal2
        final meal2Recipes = await mockDbHelper.getMealRecipesForMeal(meal2.id);
        expect(meal2Recipes.length, equals(1));
        expect(meal2Recipes[0].recipeId, equals(sharedRecipe.id));

        // Recipe entity still exists
        expect(mockDbHelper.recipes.containsKey(sharedRecipe.id), isTrue);
      });

      test('updating recipe used in multiple meals updates all references',
          () async {
        final recipe = Recipe(
          id: 'shared-recipe',
          name: 'Original Name',
          createdAt: DateTime.now(),
        );

        final meal1 = Meal(
          id: 'meal-1',
          cookedAt: DateTime.now().subtract(const Duration(days: 1)),
          servings: 2,
        );

        final meal2 = Meal(
          id: 'meal-2',
          cookedAt: DateTime.now().subtract(const Duration(days: 2)),
          servings: 4,
        );

        await mockDbHelper.insertRecipe(recipe);
        await mockDbHelper.insertMeal(meal1);
        await mockDbHelper.insertMeal(meal2);

        await mockDbHelper.insertMealRecipe(MealRecipe(
          mealId: meal1.id,
          recipeId: recipe.id,
          isPrimaryDish: true,
        ));

        await mockDbHelper.insertMealRecipe(MealRecipe(
          mealId: meal2.id,
          recipeId: recipe.id,
          isPrimaryDish: true,
        ));

        // Update recipe name
        final updatedRecipe = Recipe(
          id: recipe.id,
          name: 'Updated Name',
          createdAt: recipe.createdAt,
        );

        await mockDbHelper.updateRecipe(updatedRecipe);

        // Verify recipe is updated
        final retrieved = await mockDbHelper.getRecipe(recipe.id);
        expect(retrieved!.name, equals('Updated Name'));

        // Both meals still reference the same (updated) recipe
        final meal1Recipes = await mockDbHelper.getMealRecipesForMeal(meal1.id);
        final meal2Recipes = await mockDbHelper.getMealRecipesForMeal(meal2.id);

        expect(meal1Recipes[0].recipeId, equals(recipe.id));
        expect(meal2Recipes[0].recipeId, equals(recipe.id));
      });
    });
  });
}
