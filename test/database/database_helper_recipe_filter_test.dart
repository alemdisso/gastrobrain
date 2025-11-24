import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/database/database_helper.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/recipe_category.dart';
import 'package:gastrobrain/utils/id_generator.dart';

void main() {
  late DatabaseHelper dbHelper;

  setUp(() async {
    // Use in-memory database for testing
    dbHelper = DatabaseHelper();
    await dbHelper.database;
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('Recipe Name Filter Tests', () {
    test('should filter recipes by name - case insensitive', () async {
      // Create test recipes
      final recipe1 = Recipe(
        id: IdGenerator.generateId(),
        name: 'Spaghetti Carbonara',
        category: RecipeCategory.pasta,
        difficulty: 3,
        rating: 4,
      );
      final recipe2 = Recipe(
        id: IdGenerator.generateId(),
        name: 'Chicken Pasta',
        category: RecipeCategory.pasta,
        difficulty: 2,
        rating: 5,
      );
      final recipe3 = Recipe(
        id: IdGenerator.generateId(),
        name: 'Beef Stew',
        category: RecipeCategory.meat,
        difficulty: 4,
        rating: 4,
      );

      await dbHelper.insertRecipe(recipe1);
      await dbHelper.insertRecipe(recipe2);
      await dbHelper.insertRecipe(recipe3);

      // Filter by "pasta" - should match both pasta recipes (case insensitive)
      final pastaResults = await dbHelper.getRecipesWithSortAndFilter(
        filters: {'name': 'pasta'},
      );

      expect(pastaResults.length, 2);
      expect(pastaResults.any((r) => r.id == recipe1.id), true);
      expect(pastaResults.any((r) => r.id == recipe2.id), true);
      expect(pastaResults.any((r) => r.id == recipe3.id), false);
    });

    test('should filter recipes by name - partial match', () async {
      final recipe1 = Recipe(
        id: IdGenerator.generateId(),
        name: 'Spaghetti Carbonara',
        category: RecipeCategory.pasta,
        difficulty: 3,
        rating: 4,
      );
      final recipe2 = Recipe(
        id: IdGenerator.generateId(),
        name: 'Spaghetti Bolognese',
        category: RecipeCategory.pasta,
        difficulty: 2,
        rating: 5,
      );
      final recipe3 = Recipe(
        id: IdGenerator.generateId(),
        name: 'Lasagna',
        category: RecipeCategory.pasta,
        difficulty: 4,
        rating: 4,
      );

      await dbHelper.insertRecipe(recipe1);
      await dbHelper.insertRecipe(recipe2);
      await dbHelper.insertRecipe(recipe3);

      // Filter by "spag" - should match only spaghetti recipes
      final results = await dbHelper.getRecipesWithSortAndFilter(
        filters: {'name': 'spag'},
      );

      expect(results.length, 2);
      expect(results.any((r) => r.id == recipe1.id), true);
      expect(results.any((r) => r.id == recipe2.id), true);
      expect(results.any((r) => r.id == recipe3.id), false);
    });

    test('should filter recipes by name with case variations', () async {
      final recipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Chicken Tikka Masala',
        category: RecipeCategory.meat,
        difficulty: 3,
        rating: 5,
      );

      await dbHelper.insertRecipe(recipe);

      // Test different case variations
      final results1 = await dbHelper.getRecipesWithSortAndFilter(
        filters: {'name': 'CHICKEN'},
      );
      final results2 = await dbHelper.getRecipesWithSortAndFilter(
        filters: {'name': 'chicken'},
      );
      final results3 = await dbHelper.getRecipesWithSortAndFilter(
        filters: {'name': 'ChIcKeN'},
      );

      expect(results1.length, 1);
      expect(results2.length, 1);
      expect(results3.length, 1);
    });

    test('should combine name filter with other filters', () async {
      final recipe1 = Recipe(
        id: IdGenerator.generateId(),
        name: 'Pasta Primavera',
        category: RecipeCategory.pasta,
        difficulty: 2,
        rating: 4,
      );
      final recipe2 = Recipe(
        id: IdGenerator.generateId(),
        name: 'Pasta Alfredo',
        category: RecipeCategory.pasta,
        difficulty: 1,
        rating: 3,
      );
      final recipe3 = Recipe(
        id: IdGenerator.generateId(),
        name: 'Grilled Chicken Pasta',
        category: RecipeCategory.pasta,
        difficulty: 3,
        rating: 5,
      );

      await dbHelper.insertRecipe(recipe1);
      await dbHelper.insertRecipe(recipe2);
      await dbHelper.insertRecipe(recipe3);

      // Filter by name="pasta" AND difficulty=2
      final results = await dbHelper.getRecipesWithSortAndFilter(
        filters: {
          'name': 'pasta',
          'difficulty': 2,
        },
      );

      expect(results.length, 1);
      expect(results[0].id, recipe1.id);
    });

    test('should return empty list when no recipes match name filter', () async {
      final recipe = Recipe(
        id: IdGenerator.generateId(),
        name: 'Spaghetti Carbonara',
        category: RecipeCategory.pasta,
        difficulty: 3,
        rating: 4,
      );

      await dbHelper.insertRecipe(recipe);

      final results = await dbHelper.getRecipesWithSortAndFilter(
        filters: {'name': 'pizza'},
      );

      expect(results.length, 0);
    });

    test('should work with sorting when name filter is applied', () async {
      final recipe1 = Recipe(
        id: IdGenerator.generateId(),
        name: 'Chicken Pasta',
        category: RecipeCategory.pasta,
        difficulty: 2,
        rating: 3,
      );
      final recipe2 = Recipe(
        id: IdGenerator.generateId(),
        name: 'Pasta Carbonara',
        category: RecipeCategory.pasta,
        difficulty: 3,
        rating: 5,
      );
      final recipe3 = Recipe(
        id: IdGenerator.generateId(),
        name: 'Alfredo Pasta',
        category: RecipeCategory.pasta,
        difficulty: 1,
        rating: 4,
      );

      await dbHelper.insertRecipe(recipe1);
      await dbHelper.insertRecipe(recipe2);
      await dbHelper.insertRecipe(recipe3);

      // Filter by "pasta" and sort by name
      final results = await dbHelper.getRecipesWithSortAndFilter(
        filters: {'name': 'pasta'},
        sortBy: 'name',
        sortOrder: 'ASC',
      );

      expect(results.length, 3);
      expect(results[0].name, 'Alfredo Pasta');
      expect(results[1].name, 'Chicken Pasta');
      expect(results[2].name, 'Pasta Carbonara');
    });
  });
}
