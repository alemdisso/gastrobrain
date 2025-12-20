import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gastrobrain/database/database_helper.dart';
import 'package:gastrobrain/core/services/database_backup_service.dart';
import 'package:gastrobrain/core/errors/gastrobrain_exceptions.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/ingredient.dart';
import 'package:gastrobrain/models/meal.dart';
import 'package:gastrobrain/models/meal_recipe.dart';
import 'package:gastrobrain/models/meal_plan.dart';
import 'package:gastrobrain/models/meal_plan_item.dart';
import 'package:gastrobrain/models/meal_plan_item_recipe.dart';
import 'package:gastrobrain/models/recipe_ingredient.dart';
import 'package:gastrobrain/models/ingredient_category.dart';
import 'package:gastrobrain/models/measurement_unit.dart';
import 'package:gastrobrain/models/protein_type.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/models/recipe_category.dart';
import 'package:gastrobrain/utils/id_generator.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('DatabaseBackupService - Integration Tests', () {
    late DatabaseHelper dbHelper;
    late DatabaseBackupService backupService;

    /// Helper to clean all data from database
    Future<void> cleanDatabase(DatabaseHelper dbHelper) async {
      final db = await dbHelper.database;
      await db.delete('meal_recipes');
      await db.delete('meals');
      await db.delete('meal_plan_item_recipes');
      await db.delete('meal_plan_items');
      await db.delete('meal_plans');
      await db.delete('recipe_ingredients');
      await db.delete('recipes');
      await db.delete('ingredients');
      await db.delete('recommendation_history');
    }

    setUp(() async {
      // Use real database helper for integration tests
      dbHelper = DatabaseHelper();
      backupService = DatabaseBackupService(dbHelper);

      // Clean database before each test
      await cleanDatabase(dbHelper);
    });

    tearDown(() async {
      // Clean up after each test
      await cleanDatabase(dbHelper);
    });

    group('Export with empty database', () {
      test('exports empty database successfully', () async {
        // Verify database is empty
        expect(await dbHelper.getAllRecipes(), isEmpty);
        expect(await dbHelper.getAllIngredients(), isEmpty);
        expect(await dbHelper.getAllMealPlans(), isEmpty);
        expect(await dbHelper.getAllMeals(), isEmpty);

        // Perform backup
        final backupPath = await backupService.backupDatabase();

        // Verify backup file was created
        final backupFile = File(backupPath);
        expect(await backupFile.exists(), isTrue);

        // Parse and verify backup structure
        final jsonString = await backupFile.readAsString();
        final backupData = json.decode(jsonString) as Map<String, dynamic>;

        // Verify metadata
        expect(backupData['version'], equals('1.0'));
        expect(backupData['backup_date'], isNotNull);

        // Verify empty data arrays
        expect(backupData['recipes'], isEmpty);
        expect(backupData['ingredients'], isEmpty);
        expect(backupData['meal_plans'], isEmpty);
        expect(backupData['meals'], isEmpty);
        expect(backupData['recommendation_history'], isEmpty);

        // Clean up
        await backupFile.delete();
      });
    });

    group('Export ingredients', () {
      test('exports ingredients with all fields', () async {
        // Create test ingredients
        final ingredient1 = Ingredient(
          id: IdGenerator.generateId(),
          name: 'Tomato',
          category: IngredientCategory.vegetable,
          unit: MeasurementUnit.piece,
          proteinType: null,
          notes: 'Fresh tomatoes',
        );

        final ingredient2 = Ingredient(
          id: IdGenerator.generateId(),
          name: 'Chicken Breast',
          category: IngredientCategory.protein,
          unit: MeasurementUnit.gram,
          proteinType: ProteinType.chicken,
          notes: null,
        );

        // Add to database
        await dbHelper.insertIngredient(ingredient1);
        await dbHelper.insertIngredient(ingredient2);

        // Perform backup
        final backupPath = await backupService.backupDatabase();
        final backupFile = File(backupPath);
        final jsonString = await backupFile.readAsString();
        final backupData = json.decode(jsonString) as Map<String, dynamic>;

        // Verify ingredients
        final ingredients = backupData['ingredients'] as List;
        expect(ingredients.length, equals(2));

        // Verify ingredient 1
        final ing1 = ingredients.firstWhere((i) => i['id'] == ingredient1.id);
        expect(ing1['name'], equals('Tomato'));
        expect(ing1['category'], equals('vegetable'));
        expect(ing1['unit'], equals('piece')); // MeasurementUnit.piece.value
        expect(ing1['protein_type'], isNull);
        expect(ing1['notes'], equals('Fresh tomatoes'));

        // Verify ingredient 2
        final ing2 = ingredients.firstWhere((i) => i['id'] == ingredient2.id);
        expect(ing2['name'], equals('Chicken Breast'));
        expect(ing2['category'], equals('protein'));
        expect(ing2['unit'], equals('g')); // MeasurementUnit.gram.value
        expect(ing2['protein_type'], equals('chicken'));
        expect(ing2['notes'], isNull);

        // Clean up
        await backupFile.delete();
      });
    });

    group('Export recipes with ingredients', () {
      test('exports recipes with all fields and recipe_ingredients', () async {
        // Create test ingredient
        final ingredient = Ingredient(
          id: IdGenerator.generateId(),
          name: 'Tomato',
          category: IngredientCategory.vegetable,
        );
        await dbHelper.insertIngredient(ingredient);

        // Create test recipe
        final recipe = Recipe(
          id: IdGenerator.generateId(),
          name: 'Tomato Salad',
          difficulty: 2,
          prepTimeMinutes: 10,
          cookTimeMinutes: 0,
          rating: 4,
          category: RecipeCategory.salads,
          desiredFrequency: FrequencyType.weekly,
          notes: 'Quick and easy',
          instructions: 'Chop tomatoes and serve',
          createdAt: DateTime(2025, 1, 1),
        );
        await dbHelper.insertRecipe(recipe);

        // Create recipe ingredient
        final recipeIngredient = RecipeIngredient(
          id: IdGenerator.generateId(),
          recipeId: recipe.id,
          ingredientId: ingredient.id,
          quantity: 2.0,
          notes: 'Chopped',
          unitOverride: 'piece',
        );
        await dbHelper.addIngredientToRecipe(recipeIngredient);

        // Perform backup
        final backupPath = await backupService.backupDatabase();
        final backupFile = File(backupPath);
        final jsonString = await backupFile.readAsString();
        final backupData = json.decode(jsonString) as Map<String, dynamic>;

        // Verify recipes
        final recipes = backupData['recipes'] as List;
        expect(recipes.length, equals(1));

        final r1 = recipes.firstWhere((r) => r['id'] == recipe.id);
        expect(r1['name'], equals('Tomato Salad'));
        expect(r1['difficulty'], equals(2));
        expect(r1['prep_time_minutes'], equals(10));
        expect(r1['cook_time_minutes'], equals(0));
        expect(r1['rating'], equals(4));
        expect(r1['category'], equals('salads'));
        expect(r1['desired_frequency'], equals('weekly'));
        expect(r1['notes'], equals('Quick and easy'));
        expect(r1['instructions'], equals('Chop tomatoes and serve'));
        expect(r1['created_at'], equals('2025-01-01T00:00:00.000'));

        // Verify recipe_ingredients
        final recipeIngredients = r1['recipe_ingredients'] as List;
        expect(recipeIngredients.length, equals(1));

        final ri1 = recipeIngredients[0];
        expect(ri1['id'], equals(recipeIngredient.id));
        expect(ri1['recipe_id'], equals(recipe.id));
        expect(ri1['ingredient_id'], equals(ingredient.id));
        expect(ri1['quantity'], equals(2.0));
        expect(ri1['notes'], equals('Chopped'));
        expect(ri1['unit_override'], equals('piece'));

        // Clean up
        await backupFile.delete();
      });
    });

    group('Export meal plans', () {
      test('exports meal plans with items and recipes', () async {
        // Create test recipe
        final recipe = Recipe(
          id: IdGenerator.generateId(),
          name: 'Test Recipe',
          difficulty: 1,
          desiredFrequency: FrequencyType.weekly,
          category: RecipeCategory.mainDishes,
          createdAt: DateTime(2025, 1, 1),
        );
        await dbHelper.insertRecipe(recipe);

        // Create meal plan
        final mealPlan = MealPlan(
          id: IdGenerator.generateId(),
          weekStartDate: DateTime(2025, 1, 3), // Friday
          notes: 'Test plan',
          createdAt: DateTime(2025, 1, 1),
          modifiedAt: DateTime(2025, 1, 2),
          items: [],
        );
        await dbHelper.insertMealPlan(mealPlan);

        // Create meal plan item
        final mealPlanItem = MealPlanItem(
          id: IdGenerator.generateId(),
          mealPlanId: mealPlan.id,
          plannedDate: '2025-01-03',
          mealType: 'dinner',
          notes: 'Test dinner',
          hasBeenCooked: false,
        );
        await dbHelper.insertMealPlanItem(mealPlanItem);

        // Create meal plan item recipe
        final mealPlanItemRecipe = MealPlanItemRecipe(
          id: IdGenerator.generateId(),
          mealPlanItemId: mealPlanItem.id,
          recipeId: recipe.id,
          isPrimaryDish: true,
          notes: 'Main dish',
        );
        await dbHelper.insertMealPlanItemRecipe(mealPlanItemRecipe);

        // Perform backup
        final backupPath = await backupService.backupDatabase();
        final backupFile = File(backupPath);
        final jsonString = await backupFile.readAsString();
        final backupData = json.decode(jsonString) as Map<String, dynamic>;

        // Verify meal plans
        final mealPlans = backupData['meal_plans'] as List;
        expect(mealPlans.length, equals(1));

        final mp1 = mealPlans.firstWhere((mp) => mp['id'] == mealPlan.id);
        expect(mp1['week_start_date'], equals('2025-01-03T00:00:00.000'));
        expect(mp1['notes'], equals('Test plan'));
        expect(mp1['created_at'], equals('2025-01-01T00:00:00.000'));
        expect(mp1['modified_at'], equals('2025-01-02T00:00:00.000'));

        // Verify meal plan items
        final items = mp1['items'] as List;
        expect(items.length, equals(1));

        final item1 = items[0];
        expect(item1['id'], equals(mealPlanItem.id));
        expect(item1['meal_plan_id'], equals(mealPlan.id));
        expect(item1['planned_date'], equals('2025-01-03'));
        expect(item1['meal_type'], equals('dinner'));
        expect(item1['notes'], equals('Test dinner'));
        expect(item1['has_been_cooked'], equals(false));

        // Verify meal plan item recipes
        final recipes = item1['recipes'] as List;
        expect(recipes.length, equals(1));

        final recipe1 = recipes[0];
        expect(recipe1['id'], equals(mealPlanItemRecipe.id));
        expect(recipe1['meal_plan_item_id'], equals(mealPlanItem.id));
        expect(recipe1['recipe_id'], equals(recipe.id));
        expect(recipe1['is_primary_dish'], equals(true));
        expect(recipe1['notes'], equals('Main dish'));

        // Clean up
        await backupFile.delete();
      });
    });

    group('Export meals', () {
      test('exports meals with meal_recipes', () async {
        // Create test recipe
        final recipe = Recipe(
          id: IdGenerator.generateId(),
          name: 'Test Recipe',
          difficulty: 1,
          desiredFrequency: FrequencyType.weekly,
          category: RecipeCategory.mainDishes,
          createdAt: DateTime(2025, 1, 1),
        );
        await dbHelper.insertRecipe(recipe);

        // Create meal
        final meal = Meal(
          id: IdGenerator.generateId(),
          recipeId: recipe.id,
          cookedAt: DateTime(2025, 1, 5, 18, 30),
          servings: 4,
          notes: 'Delicious!',
          wasSuccessful: true,
          actualPrepTime: 15.0,
          actualCookTime: 30.0,
          modifiedAt: DateTime(2025, 1, 6),
        );
        await dbHelper.insertMeal(meal);

        // Create meal recipe
        final mealRecipe = MealRecipe(
          id: IdGenerator.generateId(),
          mealId: meal.id,
          recipeId: recipe.id,
          isPrimaryDish: true,
          notes: 'Main course',
        );
        await dbHelper.insertMealRecipe(mealRecipe);

        // Perform backup
        final backupPath = await backupService.backupDatabase();
        final backupFile = File(backupPath);
        final jsonString = await backupFile.readAsString();
        final backupData = json.decode(jsonString) as Map<String, dynamic>;

        // Verify meals
        final meals = backupData['meals'] as List;
        expect(meals.length, equals(1));

        final m1 = meals.firstWhere((m) => m['id'] == meal.id);
        expect(m1['recipe_id'], equals(recipe.id));
        expect(m1['cooked_at'], equals('2025-01-05T18:30:00.000'));
        expect(m1['servings'], equals(4));
        expect(m1['notes'], equals('Delicious!'));
        expect(m1['was_successful'], equals(true));
        expect(m1['actual_prep_time'], equals(15.0));
        expect(m1['actual_cook_time'], equals(30.0));
        expect(m1['modified_at'], equals('2025-01-06T00:00:00.000'));

        // Verify meal_recipes
        final mealRecipes = m1['meal_recipes'] as List;
        expect(mealRecipes.length, equals(1));

        final mr1 = mealRecipes[0];
        expect(mr1['id'], equals(mealRecipe.id));
        expect(mr1['meal_id'], equals(meal.id));
        expect(mr1['recipe_id'], equals(recipe.id));
        expect(mr1['is_primary_dish'], equals(true));
        expect(mr1['notes'], equals('Main course'));

        // Clean up
        await backupFile.delete();
      });
    });

    group('Backup file format', () {
      test('creates file with correct naming format', () async {
        final backupPath = await backupService.backupDatabase();
        final fileName = backupPath.split('/').last;

        // Verify filename format: gastrobrain_backup_YYYY-MM-DD_HHMMSS.json
        expect(fileName,
            matches(RegExp(r'gastrobrain_backup_\d{4}-\d{2}-\d{2}_\d{6}\.json')));

        // Clean up
        await File(backupPath).delete();
      });

      test('includes version and backup_date in metadata', () async {
        final backupPath = await backupService.backupDatabase();
        final backupFile = File(backupPath);
        final jsonString = await backupFile.readAsString();
        final backupData = json.decode(jsonString) as Map<String, dynamic>;

        // Verify metadata
        expect(backupData['version'], equals('1.0'));
        expect(backupData['backup_date'], isNotNull);

        // Verify backup_date is valid ISO 8601
        final backupDate = DateTime.parse(backupData['backup_date']);
        expect(
            backupDate
                .isBefore(DateTime.now().add(const Duration(seconds: 1))),
            isTrue);

        // Clean up
        await backupFile.delete();
      });

      test('includes all required data sections', () async {
        final backupPath = await backupService.backupDatabase();
        final backupFile = File(backupPath);
        final jsonString = await backupFile.readAsString();
        final backupData = json.decode(jsonString) as Map<String, dynamic>;

        // Verify all sections are present
        expect(backupData.containsKey('version'), isTrue);
        expect(backupData.containsKey('backup_date'), isTrue);
        expect(backupData.containsKey('recipes'), isTrue);
        expect(backupData.containsKey('ingredients'), isTrue);
        expect(backupData.containsKey('meal_plans'), isTrue);
        expect(backupData.containsKey('meals'), isTrue);
        expect(backupData.containsKey('recommendation_history'), isTrue);

        // Clean up
        await backupFile.delete();
      });
    });

    group('Import/Restore functionality', () {
      test('restores empty database successfully', () async {
        // Create backup of empty database
        final backupPath = await backupService.backupDatabase();

        // Add some data to database
        final ingredient = Ingredient(
          id: IdGenerator.generateId(),
          name: 'Test Ingredient',
          category: IngredientCategory.vegetable,
        );
        await dbHelper.insertIngredient(ingredient);

        // Verify data exists
        expect(await dbHelper.getAllIngredients(), hasLength(1));

        // Restore empty backup
        await backupService.restoreDatabase(backupPath);

        // Verify database is now empty
        expect(await dbHelper.getAllRecipes(), isEmpty);
        expect(await dbHelper.getAllIngredients(), isEmpty);
        expect(await dbHelper.getAllMealPlans(), isEmpty);
        expect(await dbHelper.getAllMeals(), isEmpty);

        // Clean up
        await File(backupPath).delete();
      });

      test('restores ingredients with all fields', () async {
        // Create test ingredients
        final ingredient1 = Ingredient(
          id: IdGenerator.generateId(),
          name: 'Carrot',
          category: IngredientCategory.vegetable,
          unit: MeasurementUnit.gram,
          proteinType: null,
          notes: 'Fresh carrots',
        );

        final ingredient2 = Ingredient(
          id: IdGenerator.generateId(),
          name: 'Salmon',
          category: IngredientCategory.protein,
          unit: MeasurementUnit.gram,
          proteinType: ProteinType.fish,
          notes: null,
        );

        await dbHelper.insertIngredient(ingredient1);
        await dbHelper.insertIngredient(ingredient2);

        // Create backup
        final backupPath = await backupService.backupDatabase();

        // Clear database
        await cleanDatabase(dbHelper);
        expect(await dbHelper.getAllIngredients(), isEmpty);

        // Restore backup
        await backupService.restoreDatabase(backupPath);

        // Verify ingredients restored
        final restoredIngredients = await dbHelper.getAllIngredients();
        expect(restoredIngredients.length, equals(2));

        // Verify ingredient 1
        final restored1 = restoredIngredients.firstWhere((i) => i.id == ingredient1.id);
        expect(restored1.name, equals('Carrot'));
        expect(restored1.category, equals(IngredientCategory.vegetable));
        expect(restored1.unit, equals(MeasurementUnit.gram));
        expect(restored1.proteinType, isNull);
        expect(restored1.notes, equals('Fresh carrots'));

        // Verify ingredient 2
        final restored2 = restoredIngredients.firstWhere((i) => i.id == ingredient2.id);
        expect(restored2.name, equals('Salmon'));
        expect(restored2.category, equals(IngredientCategory.protein));
        expect(restored2.unit, equals(MeasurementUnit.gram));
        expect(restored2.proteinType, equals(ProteinType.fish));
        expect(restored2.notes, isNull);

        // Clean up
        await File(backupPath).delete();
      });

      test('restores recipes with recipe_ingredients', () async {
        // Create test ingredient
        final ingredient = Ingredient(
          id: IdGenerator.generateId(),
          name: 'Pasta',
          category: IngredientCategory.grain,
        );
        await dbHelper.insertIngredient(ingredient);

        // Create test recipe
        final recipe = Recipe(
          id: IdGenerator.generateId(),
          name: 'Pasta Dish',
          difficulty: 1,
          prepTimeMinutes: 5,
          cookTimeMinutes: 15,
          rating: 5,
          category: RecipeCategory.mainDishes,
          desiredFrequency: FrequencyType.weekly,
          notes: 'Simple pasta',
          instructions: 'Cook pasta',
          createdAt: DateTime(2025, 1, 10),
        );
        await dbHelper.insertRecipe(recipe);

        // Create recipe ingredient
        final recipeIngredient = RecipeIngredient(
          id: IdGenerator.generateId(),
          recipeId: recipe.id,
          ingredientId: ingredient.id,
          quantity: 200.0,
          notes: 'Cooked',
          unitOverride: 'g',
        );
        await dbHelper.addIngredientToRecipe(recipeIngredient);

        // Create backup
        final backupPath = await backupService.backupDatabase();

        // Clear database
        await cleanDatabase(dbHelper);
        expect(await dbHelper.getAllRecipes(), isEmpty);

        // Restore backup
        await backupService.restoreDatabase(backupPath);

        // Verify recipe restored
        final restoredRecipes = await dbHelper.getAllRecipes();
        expect(restoredRecipes.length, equals(1));

        final restoredRecipe = restoredRecipes.first;
        expect(restoredRecipe.id, equals(recipe.id));
        expect(restoredRecipe.name, equals('Pasta Dish'));
        expect(restoredRecipe.difficulty, equals(1));
        expect(restoredRecipe.prepTimeMinutes, equals(5));
        expect(restoredRecipe.cookTimeMinutes, equals(15));
        expect(restoredRecipe.rating, equals(5));
        expect(restoredRecipe.category, equals(RecipeCategory.mainDishes));
        expect(restoredRecipe.desiredFrequency, equals(FrequencyType.weekly));
        expect(restoredRecipe.notes, equals('Simple pasta'));
        expect(restoredRecipe.instructions, equals('Cook pasta'));

        // Verify recipe ingredients restored
        final db = await dbHelper.database;
        final restoredRecipeIngredients = await db.query(
          'recipe_ingredients',
          where: 'recipe_id = ?',
          whereArgs: [recipe.id],
        );

        expect(restoredRecipeIngredients.length, equals(1));
        final restoredRI = restoredRecipeIngredients.first;
        expect(restoredRI['id'], equals(recipeIngredient.id));
        expect(restoredRI['recipe_id'], equals(recipe.id));
        expect(restoredRI['ingredient_id'], equals(ingredient.id));
        expect(restoredRI['quantity'], equals(200.0));
        expect(restoredRI['notes'], equals('Cooked'));
        expect(restoredRI['unit_override'], equals('g'));

        // Clean up
        await File(backupPath).delete();
      });

      test('restores meal plans with items and recipes', () async {
        // Create test recipe
        final recipe = Recipe(
          id: IdGenerator.generateId(),
          name: 'Backup Test Recipe',
          difficulty: 2,
          desiredFrequency: FrequencyType.weekly,
          category: RecipeCategory.mainDishes,
          createdAt: DateTime(2025, 1, 15),
        );
        await dbHelper.insertRecipe(recipe);

        // Create meal plan
        final mealPlan = MealPlan(
          id: IdGenerator.generateId(),
          weekStartDate: DateTime(2025, 1, 10),
          notes: 'Restore test plan',
          createdAt: DateTime(2025, 1, 8),
          modifiedAt: DateTime(2025, 1, 9),
          items: [],
        );
        await dbHelper.insertMealPlan(mealPlan);

        // Create meal plan item
        final mealPlanItem = MealPlanItem(
          id: IdGenerator.generateId(),
          mealPlanId: mealPlan.id,
          plannedDate: '2025-01-10',
          mealType: 'lunch',
          notes: 'Restore test lunch',
          hasBeenCooked: true,
        );
        await dbHelper.insertMealPlanItem(mealPlanItem);

        // Create meal plan item recipe
        final mealPlanItemRecipe = MealPlanItemRecipe(
          id: IdGenerator.generateId(),
          mealPlanItemId: mealPlanItem.id,
          recipeId: recipe.id,
          isPrimaryDish: true,
          notes: 'Primary',
        );
        await dbHelper.insertMealPlanItemRecipe(mealPlanItemRecipe);

        // Create backup
        final backupPath = await backupService.backupDatabase();

        // Clear database
        await cleanDatabase(dbHelper);
        expect(await dbHelper.getAllMealPlans(), isEmpty);

        // Restore backup
        await backupService.restoreDatabase(backupPath);

        // Verify meal plan restored
        final restoredMealPlans = await dbHelper.getAllMealPlans();
        expect(restoredMealPlans.length, equals(1));

        final restoredPlan = restoredMealPlans.first;
        expect(restoredPlan.id, equals(mealPlan.id));
        expect(restoredPlan.weekStartDate, equals(DateTime(2025, 1, 10)));
        expect(restoredPlan.notes, equals('Restore test plan'));

        // Verify meal plan items restored
        final restoredItems = await dbHelper.getMealPlanItems(mealPlan.id);
        expect(restoredItems.length, equals(1));

        final restoredItem = restoredItems.first;
        expect(restoredItem.id, equals(mealPlanItem.id));
        expect(restoredItem.mealPlanId, equals(mealPlan.id));
        expect(restoredItem.plannedDate, equals('2025-01-10'));
        expect(restoredItem.mealType, equals('lunch'));
        expect(restoredItem.notes, equals('Restore test lunch'));
        expect(restoredItem.hasBeenCooked, equals(true));

        // Verify meal plan item recipes restored
        expect(restoredItem.mealPlanItemRecipes, isNotNull);
        expect(restoredItem.mealPlanItemRecipes!.length, equals(1));

        final restoredRecipe = restoredItem.mealPlanItemRecipes!.first;
        expect(restoredRecipe.id, equals(mealPlanItemRecipe.id));
        expect(restoredRecipe.mealPlanItemId, equals(mealPlanItem.id));
        expect(restoredRecipe.recipeId, equals(recipe.id));
        expect(restoredRecipe.isPrimaryDish, equals(true));
        expect(restoredRecipe.notes, equals('Primary'));

        // Clean up
        await File(backupPath).delete();
      });

      test('restores meals with meal_recipes', () async {
        // Create test recipe
        final recipe = Recipe(
          id: IdGenerator.generateId(),
          name: 'Meal Restore Test',
          difficulty: 3,
          desiredFrequency: FrequencyType.monthly,
          category: RecipeCategory.mainDishes,
          createdAt: DateTime(2025, 1, 20),
        );
        await dbHelper.insertRecipe(recipe);

        // Create meal
        final meal = Meal(
          id: IdGenerator.generateId(),
          recipeId: recipe.id,
          cookedAt: DateTime(2025, 1, 22, 19, 0),
          servings: 2,
          notes: 'Tasty!',
          wasSuccessful: true,
          actualPrepTime: 10.0,
          actualCookTime: 25.0,
          modifiedAt: DateTime(2025, 1, 23),
        );
        await dbHelper.insertMeal(meal);

        // Create meal recipe
        final mealRecipe = MealRecipe(
          id: IdGenerator.generateId(),
          mealId: meal.id,
          recipeId: recipe.id,
          isPrimaryDish: true,
          notes: 'Main dish',
        );
        await dbHelper.insertMealRecipe(mealRecipe);

        // Create backup
        final backupPath = await backupService.backupDatabase();

        // Clear database
        await cleanDatabase(dbHelper);
        expect(await dbHelper.getAllMeals(), isEmpty);

        // Restore backup
        await backupService.restoreDatabase(backupPath);

        // Verify meal restored
        final restoredMeals = await dbHelper.getAllMeals();
        expect(restoredMeals.length, equals(1));

        final restoredMeal = restoredMeals.first;
        expect(restoredMeal.id, equals(meal.id));
        expect(restoredMeal.recipeId, equals(recipe.id));
        expect(restoredMeal.cookedAt, equals(DateTime(2025, 1, 22, 19, 0)));
        expect(restoredMeal.servings, equals(2));
        expect(restoredMeal.notes, equals('Tasty!'));
        expect(restoredMeal.wasSuccessful, equals(true));
        expect(restoredMeal.actualPrepTime, equals(10.0));
        expect(restoredMeal.actualCookTime, equals(25.0));

        // Verify meal recipes restored
        expect(restoredMeal.mealRecipes, isNotNull);
        expect(restoredMeal.mealRecipes!.length, equals(1));

        final restoredMealRecipe = restoredMeal.mealRecipes!.first;
        expect(restoredMealRecipe.id, equals(mealRecipe.id));
        expect(restoredMealRecipe.mealId, equals(meal.id));
        expect(restoredMealRecipe.recipeId, equals(recipe.id));
        expect(restoredMealRecipe.isPrimaryDish, equals(true));
        expect(restoredMealRecipe.notes, equals('Main dish'));

        // Clean up
        await File(backupPath).delete();
      });

      test('restores recommendation_history', () async {
        // Insert recommendation history records directly
        final db = await dbHelper.database;
        final record1Id = IdGenerator.generateId();
        final record2Id = IdGenerator.generateId();

        await db.insert('recommendation_history', {
          'id': record1Id,
          'result_data': '{"recipe_ids": ["rec1", "rec2"]}',
          'created_at': '2025-01-15T10:00:00.000',
          'context_type': 'meal_plan',
          'target_date': '2025-01-20',
          'meal_type': 'dinner',
          'user_id': 'user123',
        });

        await db.insert('recommendation_history', {
          'id': record2Id,
          'result_data': '{"recipe_ids": ["rec3"]}',
          'created_at': '2025-01-16T11:30:00.000',
          'context_type': 'quick_pick',
          'target_date': null,
          'meal_type': 'lunch',
          'user_id': 'user456',
        });

        // Create backup
        final backupPath = await backupService.backupDatabase();

        // Clear database
        await cleanDatabase(dbHelper);
        final emptyRecords = await db.query('recommendation_history');
        expect(emptyRecords, isEmpty);

        // Restore backup
        await backupService.restoreDatabase(backupPath);

        // Verify recommendation history restored
        final restoredRecords = await db.query('recommendation_history');
        expect(restoredRecords.length, equals(2));

        // Verify record 1
        final restored1 = restoredRecords.firstWhere((r) => r['id'] == record1Id);
        expect(restored1['result_data'], equals('{"recipe_ids": ["rec1", "rec2"]}'));
        expect(restored1['created_at'], equals('2025-01-15T10:00:00.000'));
        expect(restored1['context_type'], equals('meal_plan'));
        expect(restored1['target_date'], equals('2025-01-20'));
        expect(restored1['meal_type'], equals('dinner'));
        expect(restored1['user_id'], equals('user123'));

        // Verify record 2
        final restored2 = restoredRecords.firstWhere((r) => r['id'] == record2Id);
        expect(restored2['result_data'], equals('{"recipe_ids": ["rec3"]}'));
        expect(restored2['created_at'], equals('2025-01-16T11:30:00.000'));
        expect(restored2['context_type'], equals('quick_pick'));
        expect(restored2['target_date'], isNull);
        expect(restored2['meal_type'], equals('lunch'));
        expect(restored2['user_id'], equals('user456'));

        // Clean up
        await File(backupPath).delete();
      });

      test('restore replaces existing data completely', () async {
        // Create original data
        final originalIngredient = Ingredient(
          id: IdGenerator.generateId(),
          name: 'Original Ingredient',
          category: IngredientCategory.vegetable,
        );
        await dbHelper.insertIngredient(originalIngredient);

        final originalRecipe = Recipe(
          id: IdGenerator.generateId(),
          name: 'Original Recipe',
          difficulty: 1,
          desiredFrequency: FrequencyType.weekly,
          category: RecipeCategory.mainDishes,
          createdAt: DateTime(2025, 1, 1),
        );
        await dbHelper.insertRecipe(originalRecipe);

        // Create backup of original data
        final backupPath = await backupService.backupDatabase();

        // Add new different data
        final newIngredient = Ingredient(
          id: IdGenerator.generateId(),
          name: 'New Ingredient',
          category: IngredientCategory.protein,
        );
        await dbHelper.insertIngredient(newIngredient);

        final newRecipe = Recipe(
          id: IdGenerator.generateId(),
          name: 'New Recipe',
          difficulty: 3,
          desiredFrequency: FrequencyType.monthly,
          category: RecipeCategory.desserts,
          createdAt: DateTime(2025, 2, 1),
        );
        await dbHelper.insertRecipe(newRecipe);

        // Verify we have 2 ingredients and 2 recipes
        expect(await dbHelper.getAllIngredients(), hasLength(2));
        expect(await dbHelper.getAllRecipes(), hasLength(2));

        // Restore original backup
        await backupService.restoreDatabase(backupPath);

        // Verify only original data exists (new data was replaced)
        final ingredients = await dbHelper.getAllIngredients();
        expect(ingredients.length, equals(1));
        expect(ingredients.first.id, equals(originalIngredient.id));
        expect(ingredients.first.name, equals('Original Ingredient'));

        final recipes = await dbHelper.getAllRecipes();
        expect(recipes.length, equals(1));
        expect(recipes.first.id, equals(originalRecipe.id));
        expect(recipes.first.name, equals('Original Recipe'));

        // Clean up
        await File(backupPath).delete();
      });

      test('round-trip integrity: export → restore → verify', () async {
        // Create comprehensive test data
        final ingredient = Ingredient(
          id: IdGenerator.generateId(),
          name: 'Round Trip Ingredient',
          category: IngredientCategory.vegetable,
          unit: MeasurementUnit.piece,
          notes: 'Test notes',
        );
        await dbHelper.insertIngredient(ingredient);

        final recipe = Recipe(
          id: IdGenerator.generateId(),
          name: 'Round Trip Recipe',
          difficulty: 2,
          prepTimeMinutes: 15,
          cookTimeMinutes: 30,
          rating: 4,
          category: RecipeCategory.mainDishes,
          desiredFrequency: FrequencyType.weekly,
          notes: 'Recipe notes',
          instructions: 'Cook it well',
          createdAt: DateTime(2025, 1, 25),
        );
        await dbHelper.insertRecipe(recipe);

        final recipeIngredient = RecipeIngredient(
          id: IdGenerator.generateId(),
          recipeId: recipe.id,
          ingredientId: ingredient.id,
          quantity: 3.0,
          notes: 'Chopped',
          unitOverride: 'piece',
        );
        await dbHelper.addIngredientToRecipe(recipeIngredient);

        // Store original values for comparison
        final originalIngredients = await dbHelper.getAllIngredients();
        final originalRecipes = await dbHelper.getAllRecipes();

        // Create backup
        final backupPath = await backupService.backupDatabase();

        // Completely clear database
        await cleanDatabase(dbHelper);
        expect(await dbHelper.getAllIngredients(), isEmpty);
        expect(await dbHelper.getAllRecipes(), isEmpty);

        // Restore backup
        await backupService.restoreDatabase(backupPath);

        // Verify exact match with original data
        final restoredIngredients = await dbHelper.getAllIngredients();
        expect(restoredIngredients.length, equals(originalIngredients.length));

        final restoredIngredient = restoredIngredients.first;
        expect(restoredIngredient.id, equals(ingredient.id));
        expect(restoredIngredient.name, equals(ingredient.name));
        expect(restoredIngredient.category, equals(ingredient.category));
        expect(restoredIngredient.unit, equals(ingredient.unit));
        expect(restoredIngredient.notes, equals(ingredient.notes));

        final restoredRecipes = await dbHelper.getAllRecipes();
        expect(restoredRecipes.length, equals(originalRecipes.length));

        final restoredRecipe = restoredRecipes.first;
        expect(restoredRecipe.id, equals(recipe.id));
        expect(restoredRecipe.name, equals(recipe.name));
        expect(restoredRecipe.difficulty, equals(recipe.difficulty));
        expect(restoredRecipe.prepTimeMinutes, equals(recipe.prepTimeMinutes));
        expect(restoredRecipe.cookTimeMinutes, equals(recipe.cookTimeMinutes));
        expect(restoredRecipe.rating, equals(recipe.rating));
        expect(restoredRecipe.category, equals(recipe.category));
        expect(restoredRecipe.desiredFrequency, equals(recipe.desiredFrequency));
        expect(restoredRecipe.notes, equals(recipe.notes));
        expect(restoredRecipe.instructions, equals(recipe.instructions));

        // Verify recipe ingredients junction table
        final db = await dbHelper.database;
        final restoredRI = await db.query(
          'recipe_ingredients',
          where: 'recipe_id = ?',
          whereArgs: [recipe.id],
        );

        expect(restoredRI.length, equals(1));
        expect(restoredRI.first['id'], equals(recipeIngredient.id));
        expect(restoredRI.first['quantity'], equals(3.0));
        expect(restoredRI.first['notes'], equals('Chopped'));

        // Clean up
        await File(backupPath).delete();
      });
    });

    group('Edge cases and error handling', () {
      test('restore throws exception for non-existent file', () async {
        final nonExistentPath = '/sdcard/Download/does_not_exist.json';

        // Verify file doesn't exist
        expect(await File(nonExistentPath).exists(), isFalse);

        // Attempt restore should throw
        expect(
          () => backupService.restoreDatabase(nonExistentPath),
          throwsA(isA<GastrobrainException>().having(
            (e) => e.message,
            'message',
            contains('Backup file not found'),
          )),
        );
      });

      test('restore throws exception for malformed JSON', () async {
        // Create file with invalid JSON in temporary directory
        final tempDir = Directory.systemTemp;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final malformedFile = File('${tempDir.path}/malformed_$timestamp.json');

        await malformedFile.writeAsString('{ this is not valid JSON }');

        // Verify file was created
        expect(await malformedFile.exists(), isTrue);

        // Attempt restore should throw
        await expectLater(
          backupService.restoreDatabase(malformedFile.path),
          throwsA(isA<GastrobrainException>()),
        );

        // Clean up
        if (await malformedFile.exists()) {
          await malformedFile.delete();
        }
      });

      test('restore throws exception for missing version field', () async {
        // Create backup file without version in temporary directory
        final tempDir = Directory.systemTemp;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final invalidFile = File('${tempDir.path}/no_version_$timestamp.json');

        final invalidBackup = {
          'backup_date': DateTime.now().toIso8601String(),
          'recipes': [],
          'ingredients': [],
          'meal_plans': [],
          'meals': [],
          'recommendation_history': [],
        };

        await invalidFile.writeAsString(json.encode(invalidBackup));

        // Verify file was created
        expect(await invalidFile.exists(), isTrue);

        // Attempt restore should throw
        await expectLater(
          backupService.restoreDatabase(invalidFile.path),
          throwsA(isA<GastrobrainException>().having(
            (e) => e.message,
            'message',
            contains('Invalid backup file: missing version'),
          )),
        );

        // Clean up
        if (await invalidFile.exists()) {
          await invalidFile.delete();
        }
      });

      test('restore is atomic - rolls back on error', () async {
        // Create initial data
        final originalIngredient = Ingredient(
          id: IdGenerator.generateId(),
          name: 'Original Data',
          category: IngredientCategory.vegetable,
        );
        await dbHelper.insertIngredient(originalIngredient);

        final originalRecipe = Recipe(
          id: IdGenerator.generateId(),
          name: 'Original Recipe',
          difficulty: 1,
          desiredFrequency: FrequencyType.weekly,
          category: RecipeCategory.mainDishes,
          createdAt: DateTime(2025, 1, 1),
        );
        await dbHelper.insertRecipe(originalRecipe);

        // Verify initial data exists
        expect(await dbHelper.getAllIngredients(), hasLength(1));
        expect(await dbHelper.getAllRecipes(), hasLength(1));

        // Create a backup with invalid foreign key reference in temporary directory
        // This should cause the transaction to fail
        final tempDir = Directory.systemTemp;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final corruptedFile = File('${tempDir.path}/corrupted_$timestamp.json');

        final corruptedBackup = {
          'version': '1.0',
          'backup_date': DateTime.now().toIso8601String(),
          'ingredients': [],
          'recipes': [
            {
              'id': IdGenerator.generateId(),
              'name': 'Test Recipe',
              'difficulty': 1,
              'prep_time_minutes': null,
              'cook_time_minutes': null,
              'rating': null,
              'category': 'mainDishes',
              'desired_frequency': 'weekly',
              'notes': null,
              'instructions': null,
              'created_at': DateTime.now().toIso8601String(),
              'recipe_ingredients': [
                {
                  'id': IdGenerator.generateId(),
                  'recipe_id': 'valid-recipe-id',
                  'ingredient_id': 'non-existent-ingredient-id', // Invalid FK
                  'quantity': 100.0,
                  'notes': null,
                  'unit_override': null,
                  'custom_name': null,
                  'custom_category': null,
                  'custom_unit': null,
                }
              ],
            }
          ],
          'meal_plans': [],
          'meals': [],
          'recommendation_history': [],
        };

        await corruptedFile.writeAsString(
          const JsonEncoder.withIndent('  ').convert(corruptedBackup),
        );

        // Verify file was created
        expect(await corruptedFile.exists(), isTrue);

        // Attempt restore - should fail and rollback
        try {
          await backupService.restoreDatabase(corruptedFile.path);
          fail('Should have thrown an exception');
        } catch (e) {
          // Expected to fail
          expect(e, isA<GastrobrainException>());
        }

        // Verify original data is still intact (transaction rolled back)
        final ingredientsAfterFail = await dbHelper.getAllIngredients();
        final recipesAfterFail = await dbHelper.getAllRecipes();

        expect(ingredientsAfterFail.length, equals(1));
        expect(ingredientsAfterFail.first.id, equals(originalIngredient.id));
        expect(ingredientsAfterFail.first.name, equals('Original Data'));

        expect(recipesAfterFail.length, equals(1));
        expect(recipesAfterFail.first.id, equals(originalRecipe.id));
        expect(recipesAfterFail.first.name, equals('Original Recipe'));

        // Clean up
        if (await corruptedFile.exists()) {
          await corruptedFile.delete();
        }
      });

      test('handles empty tables gracefully', () async {
        // This is already covered by "exports empty database successfully"
        // but we verify restore side here

        // Create empty backup
        final backupPath = await backupService.backupDatabase();

        // Add data
        final ingredient = Ingredient(
          id: IdGenerator.generateId(),
          name: 'Test',
          category: IngredientCategory.vegetable,
        );
        await dbHelper.insertIngredient(ingredient);

        // Restore empty backup
        await backupService.restoreDatabase(backupPath);

        // Verify all tables are empty
        expect(await dbHelper.getAllRecipes(), isEmpty);
        expect(await dbHelper.getAllIngredients(), isEmpty);
        expect(await dbHelper.getAllMealPlans(), isEmpty);
        expect(await dbHelper.getAllMeals(), isEmpty);

        final db = await dbHelper.database;
        final recommendationHistory = await db.query('recommendation_history');
        expect(recommendationHistory, isEmpty);

        // Clean up
        await File(backupPath).delete();
      });
    });

    group('Data integrity and foreign key constraints', () {
      test('deletion happens in correct order (respects FK constraints)', () async {
        // Create data with dependencies: ingredient -> recipe -> recipe_ingredient
        final ingredient = Ingredient(
          id: IdGenerator.generateId(),
          name: 'Test Ingredient',
          category: IngredientCategory.vegetable,
        );
        await dbHelper.insertIngredient(ingredient);

        final recipe = Recipe(
          id: IdGenerator.generateId(),
          name: 'Test Recipe',
          difficulty: 1,
          desiredFrequency: FrequencyType.weekly,
          category: RecipeCategory.mainDishes,
          createdAt: DateTime.now(),
        );
        await dbHelper.insertRecipe(recipe);

        final recipeIngredient = RecipeIngredient(
          id: IdGenerator.generateId(),
          recipeId: recipe.id,
          ingredientId: ingredient.id,
          quantity: 100.0,
        );
        await dbHelper.addIngredientToRecipe(recipeIngredient);

        // Create meal plan with dependencies (weekStartDate must be Friday)
        final mealPlan = MealPlan(
          id: IdGenerator.generateId(),
          weekStartDate: DateTime(2025, 1, 3), // Friday
          createdAt: DateTime(2025, 1, 1),
          modifiedAt: DateTime(2025, 1, 2),
          items: [],
        );
        await dbHelper.insertMealPlan(mealPlan);

        final mealPlanItem = MealPlanItem(
          id: IdGenerator.generateId(),
          mealPlanId: mealPlan.id,
          plannedDate: '2025-01-01',
          mealType: 'dinner',
          hasBeenCooked: false,
        );
        await dbHelper.insertMealPlanItem(mealPlanItem);

        final mealPlanItemRecipe = MealPlanItemRecipe(
          id: IdGenerator.generateId(),
          mealPlanItemId: mealPlanItem.id,
          recipeId: recipe.id,
          isPrimaryDish: true,
        );
        await dbHelper.insertMealPlanItemRecipe(mealPlanItemRecipe);

        // Create meal with dependencies
        final meal = Meal(
          id: IdGenerator.generateId(),
          recipeId: recipe.id,
          cookedAt: DateTime.now(),
          servings: 4,
          wasSuccessful: true,
        );
        await dbHelper.insertMeal(meal);

        final mealRecipe = MealRecipe(
          id: IdGenerator.generateId(),
          mealId: meal.id,
          recipeId: recipe.id,
          isPrimaryDish: true,
        );
        await dbHelper.insertMealRecipe(mealRecipe);

        // Create backup
        final backupPath = await backupService.backupDatabase();

        // Restore should delete in correct order without FK constraint violations
        // Order: meal_recipes -> meals -> meal_plan_item_recipes -> meal_plan_items ->
        //        meal_plans -> recipe_ingredients -> recipes -> ingredients
        await expectLater(
          backupService.restoreDatabase(backupPath),
          completes,
        );

        // Verify restore completed successfully (no FK violations during deletion)
        final restoredIngredients = await dbHelper.getAllIngredients();
        final restoredRecipes = await dbHelper.getAllRecipes();
        expect(restoredIngredients.length, equals(1));
        expect(restoredRecipes.length, equals(1));

        // Clean up
        await File(backupPath).delete();
      });

      test('insertion happens in correct order (respects FK constraints)', () async {
        // Create comprehensive data with all FK relationships
        final ingredient1 = Ingredient(
          id: IdGenerator.generateId(),
          name: 'Ingredient 1',
          category: IngredientCategory.vegetable,
        );
        final ingredient2 = Ingredient(
          id: IdGenerator.generateId(),
          name: 'Ingredient 2',
          category: IngredientCategory.protein,
        );
        await dbHelper.insertIngredient(ingredient1);
        await dbHelper.insertIngredient(ingredient2);

        final recipe1 = Recipe(
          id: IdGenerator.generateId(),
          name: 'Recipe 1',
          difficulty: 1,
          desiredFrequency: FrequencyType.weekly,
          category: RecipeCategory.mainDishes,
          createdAt: DateTime.now(),
        );
        final recipe2 = Recipe(
          id: IdGenerator.generateId(),
          name: 'Recipe 2',
          difficulty: 2,
          desiredFrequency: FrequencyType.monthly,
          category: RecipeCategory.sideDishes,
          createdAt: DateTime.now(),
        );
        await dbHelper.insertRecipe(recipe1);
        await dbHelper.insertRecipe(recipe2);

        // Add recipe ingredients (depends on recipes and ingredients)
        await dbHelper.addIngredientToRecipe(RecipeIngredient(
          id: IdGenerator.generateId(),
          recipeId: recipe1.id,
          ingredientId: ingredient1.id,
          quantity: 100.0,
        ));
        await dbHelper.addIngredientToRecipe(RecipeIngredient(
          id: IdGenerator.generateId(),
          recipeId: recipe2.id,
          ingredientId: ingredient2.id,
          quantity: 200.0,
        ));

        // Create meal plan (no dependencies, weekStartDate must be Friday)
        final mealPlan = MealPlan(
          id: IdGenerator.generateId(),
          weekStartDate: DateTime(2025, 1, 10), // Friday
          createdAt: DateTime(2025, 1, 8),
          modifiedAt: DateTime(2025, 1, 9),
          items: [],
        );
        await dbHelper.insertMealPlan(mealPlan);

        // Create meal plan items (depends on meal_plans)
        final item1 = MealPlanItem(
          id: IdGenerator.generateId(),
          mealPlanId: mealPlan.id,
          plannedDate: '2025-01-01',
          mealType: 'lunch',
          hasBeenCooked: false,
        );
        final item2 = MealPlanItem(
          id: IdGenerator.generateId(),
          mealPlanId: mealPlan.id,
          plannedDate: '2025-01-02',
          mealType: 'dinner',
          hasBeenCooked: false,
        );
        await dbHelper.insertMealPlanItem(item1);
        await dbHelper.insertMealPlanItem(item2);

        // Create meal plan item recipes (depends on meal_plan_items and recipes)
        await dbHelper.insertMealPlanItemRecipe(MealPlanItemRecipe(
          id: IdGenerator.generateId(),
          mealPlanItemId: item1.id,
          recipeId: recipe1.id,
          isPrimaryDish: true,
        ));
        await dbHelper.insertMealPlanItemRecipe(MealPlanItemRecipe(
          id: IdGenerator.generateId(),
          mealPlanItemId: item2.id,
          recipeId: recipe2.id,
          isPrimaryDish: true,
        ));

        // Create meals (depends on recipes)
        final meal1 = Meal(
          id: IdGenerator.generateId(),
          recipeId: recipe1.id,
          cookedAt: DateTime.now(),
          servings: 2,
          wasSuccessful: true,
        );
        final meal2 = Meal(
          id: IdGenerator.generateId(),
          recipeId: recipe2.id,
          cookedAt: DateTime.now(),
          servings: 4,
          wasSuccessful: true,
        );
        await dbHelper.insertMeal(meal1);
        await dbHelper.insertMeal(meal2);

        // Create meal recipes (depends on meals and recipes)
        await dbHelper.insertMealRecipe(MealRecipe(
          id: IdGenerator.generateId(),
          mealId: meal1.id,
          recipeId: recipe1.id,
          isPrimaryDish: true,
        ));
        await dbHelper.insertMealRecipe(MealRecipe(
          id: IdGenerator.generateId(),
          mealId: meal2.id,
          recipeId: recipe2.id,
          isPrimaryDish: true,
        ));

        // Create backup
        final backupPath = await backupService.backupDatabase();

        // Clear database
        await cleanDatabase(dbHelper);
        expect(await dbHelper.getAllIngredients(), isEmpty);

        // Restore should insert in correct order without FK constraint violations
        // Order: ingredients -> recipes -> recipe_ingredients ->
        //        meal_plans -> meal_plan_items -> meal_plan_item_recipes ->
        //        meals -> meal_recipes -> recommendation_history
        await expectLater(
          backupService.restoreDatabase(backupPath),
          completes,
        );

        // Verify all data was restored successfully (no FK violations during insertion)
        expect(await dbHelper.getAllIngredients(), hasLength(2));
        expect(await dbHelper.getAllRecipes(), hasLength(2));
        expect(await dbHelper.getAllMealPlans(), hasLength(1));
        expect(await dbHelper.getAllMeals(), hasLength(2));

        // Verify junction tables have data
        final db = await dbHelper.database;
        final recipeIngredients = await db.query('recipe_ingredients');
        final mealPlanItemRecipes = await db.query('meal_plan_item_recipes');
        final mealRecipes = await db.query('meal_recipes');

        expect(recipeIngredients.length, equals(2));
        expect(mealPlanItemRecipes.length, equals(2));
        expect(mealRecipes.length, equals(2));

        // Clean up
        await File(backupPath).delete();
      });

      test('all fields are correctly mapped between export and import', () async {
        // Create data with ALL fields populated (including optional/nullable)
        final ingredient = Ingredient(
          id: IdGenerator.generateId(),
          name: 'Complete Ingredient',
          category: IngredientCategory.protein,
          unit: MeasurementUnit.gram,
          proteinType: ProteinType.beef,
          notes: 'Full notes',
        );
        await dbHelper.insertIngredient(ingredient);

        final recipe = Recipe(
          id: IdGenerator.generateId(),
          name: 'Complete Recipe',
          difficulty: 3,
          prepTimeMinutes: 20,
          cookTimeMinutes: 45,
          rating: 5,
          category: RecipeCategory.mainDishes,
          desiredFrequency: FrequencyType.weekly,
          notes: 'Recipe notes',
          instructions: 'Detailed instructions',
          createdAt: DateTime(2025, 1, 15, 10, 30, 0),
        );
        await dbHelper.insertRecipe(recipe);

        final recipeIngredient = RecipeIngredient(
          id: IdGenerator.generateId(),
          recipeId: recipe.id,
          ingredientId: ingredient.id,
          quantity: 500.0,
          notes: 'Prep notes',
          unitOverride: 'kg',
          customName: 'Custom name',
          customCategory: 'Custom category',
          customUnit: 'Custom unit',
        );
        await dbHelper.addIngredientToRecipe(recipeIngredient);

        final meal = Meal(
          id: IdGenerator.generateId(),
          recipeId: recipe.id,
          cookedAt: DateTime(2025, 1, 20, 18, 30, 0),
          servings: 6,
          notes: 'Meal notes',
          wasSuccessful: true,
          actualPrepTime: 25.0,
          actualCookTime: 50.0,
          modifiedAt: DateTime(2025, 1, 21, 9, 0, 0),
        );
        await dbHelper.insertMeal(meal);

        // Export and import
        final backupPath = await backupService.backupDatabase();
        await cleanDatabase(dbHelper);
        await backupService.restoreDatabase(backupPath);

        // Verify ALL fields match exactly
        final restoredIngredients = await dbHelper.getAllIngredients();
        final ing = restoredIngredients.first;
        expect(ing.id, equals(ingredient.id));
        expect(ing.name, equals('Complete Ingredient'));
        expect(ing.category, equals(IngredientCategory.protein));
        expect(ing.unit, equals(MeasurementUnit.gram));
        expect(ing.proteinType, equals(ProteinType.beef));
        expect(ing.notes, equals('Full notes'));

        final restoredRecipes = await dbHelper.getAllRecipes();
        final rec = restoredRecipes.first;
        expect(rec.id, equals(recipe.id));
        expect(rec.name, equals('Complete Recipe'));
        expect(rec.difficulty, equals(3));
        expect(rec.prepTimeMinutes, equals(20));
        expect(rec.cookTimeMinutes, equals(45));
        expect(rec.rating, equals(5));
        expect(rec.category, equals(RecipeCategory.mainDishes));
        expect(rec.desiredFrequency, equals(FrequencyType.weekly));
        expect(rec.notes, equals('Recipe notes'));
        expect(rec.instructions, equals('Detailed instructions'));
        expect(rec.createdAt, equals(DateTime(2025, 1, 15, 10, 30, 0)));

        final db = await dbHelper.database;
        final restoredRI = await db.query(
          'recipe_ingredients',
          where: 'id = ?',
          whereArgs: [recipeIngredient.id],
        );
        final ri = restoredRI.first;
        expect(ri['quantity'], equals(500.0));
        expect(ri['notes'], equals('Prep notes'));
        expect(ri['unit_override'], equals('kg'));
        expect(ri['custom_name'], equals('Custom name'));
        expect(ri['custom_category'], equals('Custom category'));
        expect(ri['custom_unit'], equals('Custom unit'));

        final restoredMeals = await dbHelper.getAllMeals();
        final m = restoredMeals.first;
        expect(m.id, equals(meal.id));
        expect(m.cookedAt, equals(DateTime(2025, 1, 20, 18, 30, 0)));
        expect(m.servings, equals(6));
        expect(m.notes, equals('Meal notes'));
        expect(m.wasSuccessful, equals(true));
        expect(m.actualPrepTime, equals(25.0));
        expect(m.actualCookTime, equals(50.0));
        expect(m.modifiedAt, equals(DateTime(2025, 1, 21, 9, 0, 0)));

        // Clean up
        await File(backupPath).delete();
      });
    });
  });
}
