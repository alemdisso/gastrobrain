import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gastrobrain/database/database_helper.dart';
import 'package:gastrobrain/core/services/database_backup_service.dart';
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
        expect(ing1['unit'], equals('piece'));
        expect(ing1['protein_type'], isNull);
        expect(ing1['notes'], equals('Fresh tomatoes'));

        // Verify ingredient 2
        final ing2 = ingredients.firstWhere((i) => i['id'] == ingredient2.id);
        expect(ing2['name'], equals('Chicken Breast'));
        expect(ing2['category'], equals('protein'));
        expect(ing2['unit'], equals('gram'));
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
  });
}
