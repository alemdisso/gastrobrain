import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/ingredient.dart';
import 'package:gastrobrain/models/ingredient_category.dart';
import 'package:gastrobrain/models/measurement_unit.dart';
import 'package:gastrobrain/models/recipe_ingredient.dart';
import '../mocks/mock_database_helper.dart';

void main() {
  late MockDatabaseHelper dbHelper;

  setUp(() {
    dbHelper = MockDatabaseHelper();
  });

  tearDown(() {
    dbHelper.resetAllData();
  });

  group('Recipe Enrichment Statistics', () {
    test('getEnrichedRecipeCount returns 0 when no recipes exist', () async {
      final count = await dbHelper.getEnrichedRecipeCount();
      expect(count, 0);
    });

    test('getEnrichedRecipeCount counts only recipes with 3+ ingredients',
        () async {
      // Create test ingredients
      final ingredient1 = Ingredient(
        id: 'ing-1',
        name: 'Tomato',
        category: IngredientCategory.vegetable,
        unit: MeasurementUnit.unit,
      );
      final ingredient2 = Ingredient(
        id: 'ing-2',
        name: 'Onion',
        category: IngredientCategory.vegetable,
        unit: MeasurementUnit.unit,
      );
      final ingredient3 = Ingredient(
        id: 'ing-3',
        name: 'Garlic',
        category: IngredientCategory.vegetable,
        unit: MeasurementUnit.unit,
      );
      final ingredient4 = Ingredient(
        id: 'ing-4',
        name: 'Oil',
        category: IngredientCategory.other,
        unit: MeasurementUnit.tablespoon,
      );

      await dbHelper.insertIngredient(ingredient1);
      await dbHelper.insertIngredient(ingredient2);
      await dbHelper.insertIngredient(ingredient3);
      await dbHelper.insertIngredient(ingredient4);

      // Create recipes with varying ingredient counts
      final recipe1 = Recipe(
        id: 'recipe-1',
        name: 'Enriched Recipe 1',
        difficulty: 2,
        instructions: 'Test',
      );
      final recipe2 = Recipe(
        id: 'recipe-2',
        name: 'Incomplete Recipe',
        difficulty: 1,
        instructions: 'Test',
      );
      final recipe3 = Recipe(
        id: 'recipe-3',
        name: 'Enriched Recipe 2',
        difficulty: 3,
        instructions: 'Test',
      );

      await dbHelper.insertRecipe(recipe1);
      await dbHelper.insertRecipe(recipe2);
      await dbHelper.insertRecipe(recipe3);

      // Add 3 ingredients to recipe1 (enriched)
      await dbHelper.addIngredientToRecipe(RecipeIngredient(
        recipeId: recipe1.id,
        ingredientId: ingredient1.id,
        quantity: 1,
      ));
      await dbHelper.addIngredientToRecipe(RecipeIngredient(
        recipeId: recipe1.id,
        ingredientId: ingredient2.id,
        quantity: 1,
      ));
      await dbHelper.addIngredientToRecipe(RecipeIngredient(
        recipeId: recipe1.id,
        ingredientId: ingredient3.id,
        quantity: 1,
      ));

      // Add only 2 ingredients to recipe2 (incomplete)
      await dbHelper.addIngredientToRecipe(RecipeIngredient(
        recipeId: recipe2.id,
        ingredientId: ingredient1.id,
        quantity: 1,
      ));
      await dbHelper.addIngredientToRecipe(RecipeIngredient(
        recipeId: recipe2.id,
        ingredientId: ingredient2.id,
        quantity: 1,
      ));

      // Add 4 ingredients to recipe3 (enriched)
      await dbHelper.addIngredientToRecipe(RecipeIngredient(
        recipeId: recipe3.id,
        ingredientId: ingredient1.id,
        quantity: 1,
      ));
      await dbHelper.addIngredientToRecipe(RecipeIngredient(
        recipeId: recipe3.id,
        ingredientId: ingredient2.id,
        quantity: 1,
      ));
      await dbHelper.addIngredientToRecipe(RecipeIngredient(
        recipeId: recipe3.id,
        ingredientId: ingredient3.id,
        quantity: 1,
      ));
      await dbHelper.addIngredientToRecipe(RecipeIngredient(
        recipeId: recipe3.id,
        ingredientId: ingredient4.id,
        quantity: 1,
      ));

      // Verify enriched count: should be 2 (recipe1 and recipe3)
      final enrichedCount = await dbHelper.getEnrichedRecipeCount();
      expect(enrichedCount, 2);
    });

    test('getRecipeEnrichmentStats returns correct statistics', () async {
      // Create test ingredients
      final ingredient1 = Ingredient(
        id: 'ing-1',
        name: 'Tomato',
        category: IngredientCategory.vegetable,
        unit: MeasurementUnit.unit,
      );
      final ingredient2 = Ingredient(
        id: 'ing-2',
        name: 'Onion',
        category: IngredientCategory.vegetable,
        unit: MeasurementUnit.unit,
      );
      final ingredient3 = Ingredient(
        id: 'ing-3',
        name: 'Garlic',
        category: IngredientCategory.vegetable,
        unit: MeasurementUnit.unit,
      );

      await dbHelper.insertIngredient(ingredient1);
      await dbHelper.insertIngredient(ingredient2);
      await dbHelper.insertIngredient(ingredient3);

      // Create recipes
      final enrichedRecipe = Recipe(
        id: 'enriched',
        name: 'Enriched Recipe',
        difficulty: 2,
        instructions: 'Test',
      );
      final incompleteRecipe1 = Recipe(
        id: 'incomplete1',
        name: 'Incomplete Recipe 1',
        difficulty: 1,
        instructions: 'Test',
      );
      final incompleteRecipe2 = Recipe(
        id: 'incomplete2',
        name: 'Incomplete Recipe 2',
        difficulty: 1,
        instructions: 'Test',
      );

      await dbHelper.insertRecipe(enrichedRecipe);
      await dbHelper.insertRecipe(incompleteRecipe1);
      await dbHelper.insertRecipe(incompleteRecipe2);

      // Add 3 ingredients to enriched recipe
      await dbHelper.addIngredientToRecipe(RecipeIngredient(
        recipeId: enrichedRecipe.id,
        ingredientId: ingredient1.id,
        quantity: 1,
      ));
      await dbHelper.addIngredientToRecipe(RecipeIngredient(
        recipeId: enrichedRecipe.id,
        ingredientId: ingredient2.id,
        quantity: 1,
      ));
      await dbHelper.addIngredientToRecipe(RecipeIngredient(
        recipeId: enrichedRecipe.id,
        ingredientId: ingredient3.id,
        quantity: 1,
      ));

      // Add 1 ingredient to first incomplete recipe
      await dbHelper.addIngredientToRecipe(RecipeIngredient(
        recipeId: incompleteRecipe1.id,
        ingredientId: ingredient1.id,
        quantity: 1,
      ));

      // Add 0 ingredients to second incomplete recipe (keep it empty)

      // Get stats
      final stats = await dbHelper.getRecipeEnrichmentStats();

      // Verify stats
      expect(stats['total'], 3, reason: 'Total recipes should be 3');
      expect(stats['enriched'], 1,
          reason: 'Enriched recipes (3+ ingredients) should be 1');
      expect(stats['incomplete'], 2,
          reason: 'Incomplete recipes (<3 ingredients) should be 2');
    });

    test('getRecipeEnrichmentStats returns zeros when no recipes exist',
        () async {
      final stats = await dbHelper.getRecipeEnrichmentStats();

      expect(stats['total'], 0);
      expect(stats['enriched'], 0);
      expect(stats['incomplete'], 0);
    });
  });
}
