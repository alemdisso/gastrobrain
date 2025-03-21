import 'dart:convert';
import 'dart:async';
//import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../utils/id_generator.dart';
import '../models/recipe.dart';
import '../models/meal.dart';
import '../models/meal_recipe.dart';
import '../models/ingredient.dart';
import '../models/recipe_ingredient.dart';
import '../models/meal_plan.dart';
import '../models/meal_plan_item.dart';
import '../models/meal_plan_item_recipe.dart';
import '../core/validators/entity_validator.dart';
import '../core/errors/gastrobrain_exceptions.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // More reliable detection: use a direct test to see if in test context
    // Check if we're in a test by examining stack traces and context
    bool inTestContext = _detectTestEnvironment();

    String filename;
    if (inTestContext) {
      // For tests, use a named test database that's separate from the main one
      // With timestamp for uniqueness between test runs
      filename = 'gastrobrain_test_${DateTime.now().millisecondsSinceEpoch}.db';
    } else {
      // Normal app operation
      filename = 'gastrobrain.db';
    }

    String path = join(await getDatabasesPath(), filename);
    return await openDatabase(
      path,
      version: 13, // Increment version number for new tables
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        // Enable foreign key constraints
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // Helper method to detect test environment more reliably
  bool _detectTestEnvironment() {
    try {
      // Check stack trace for testing frameworks
      final stackTraceStr = StackTrace.current.toString();
      if (stackTraceStr.contains('_integrationTester') ||
          stackTraceStr.contains('integration_test') ||
          stackTraceStr.contains('flutter_test') ||
          stackTraceStr.contains('test_async_utils')) {
        return true;
      }

      // Basic check if we're in a test Zone
      return Zone.current['test.declarer'] != null;
    } catch (_) {
      // If any error occurs in detection, be conservative
    }

    // Fallback to check environment variable (although we know it might not be reliable)
    return const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);
  }

  Future<void> resetDatabaseForTests() async {
    // Use the more reliable test detection method
    if (!_detectTestEnvironment()) {
      return; // Only allow in test environment
    }

    // Close any existing database connection
    if (_database != null) {
      await _database!.close();
    }

    // Since we're using a new database file for each test run with the timestamp,
    // we don't need to delete anything - just set _database to null
    // so that the next call to database getter will create a fresh one
    _database = null;

    // Force initialization of a new database
    await database;
  }

  Future<void> _onCreate(Database db, int version) async {
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON;');

    // Create recipes table with all columns that were added in upgrades
    await db.execute('''
      CREATE TABLE recipes(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        desired_frequency TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        difficulty INTEGER DEFAULT 1,
        prep_time_minutes INTEGER DEFAULT 0,
        cook_time_minutes INTEGER DEFAULT 0,
        rating INTEGER DEFAULT 0
      )
    ''');

    // Create meals table with all columns that were added in upgrades
    await db.execute('''
      CREATE TABLE meals(
        id TEXT PRIMARY KEY,
        recipe_id TEXT,
        cooked_at TEXT NOT NULL,
        servings INTEGER NOT NULL,
        notes TEXT,
        was_successful INTEGER DEFAULT 1,
        actual_prep_time REAL DEFAULT 0,
        actual_cook_time REAL DEFAULT 0,
        FOREIGN KEY (recipe_id) REFERENCES recipes (id) ON DELETE CASCADE
      )
    ''');

    // Create ingredients table
    await db.execute('''
      CREATE TABLE ingredients(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        unit TEXT,
        protein_type TEXT,
        notes TEXT
      )
    ''');

    // Create recipe_ingredients table with the new unit_override column
    await db.execute('''
      CREATE TABLE recipe_ingredients(
        id TEXT PRIMARY KEY,
        recipe_id TEXT NOT NULL,
        ingredient_id TEXT NOT NULL,
        quantity REAL NOT NULL,
        notes TEXT,
        unit_override TEXT,
        custom_name TEXT,
        custom_category TEXT,
        custom_unit TEXT,
        FOREIGN KEY (recipe_id) REFERENCES recipes (id) ON DELETE CASCADE,
        FOREIGN KEY (ingredient_id) REFERENCES ingredients (id) ON DELETE CASCADE
      )
    ''');

    // Create meal_plans table
    await db.execute('''
      CREATE TABLE meal_plans(
        id TEXT PRIMARY KEY,
        week_start_date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        modified_at TEXT NOT NULL
      )
    ''');

    // Create meal_plan_items table - Without recipe_id field
    await db.execute('''
      CREATE TABLE meal_plan_items(
        id TEXT PRIMARY KEY,
        meal_plan_id TEXT NOT NULL,
        planned_date TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        notes TEXT,
        has_been_cooked INTEGER DEFAULT 0,
        FOREIGN KEY (meal_plan_id) REFERENCES meal_plans (id) ON DELETE CASCADE
      )
    ''');

    // Create meal_plan_item_recipes junction table
    await db.execute('''
      CREATE TABLE meal_plan_item_recipes(
        id TEXT PRIMARY KEY,
        meal_plan_item_id TEXT NOT NULL,
        recipe_id TEXT NOT NULL,
        is_primary_dish INTEGER DEFAULT 0,
        notes TEXT,
        FOREIGN KEY (meal_plan_item_id) REFERENCES meal_plan_items (id) ON DELETE CASCADE,
        FOREIGN KEY (recipe_id) REFERENCES recipes (id) ON DELETE CASCADE
      )
    ''');

    // Create meal_recipes table
    await db.execute('''
      CREATE TABLE meal_recipes(
        id TEXT PRIMARY KEY,
        meal_id TEXT NOT NULL,
        recipe_id TEXT NOT NULL,
        is_primary_dish INTEGER DEFAULT 0,
        notes TEXT,
        FOREIGN KEY (meal_id) REFERENCES meals (id) ON DELETE CASCADE,
        FOREIGN KEY (recipe_id) REFERENCES recipes (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 12) {
      // Since we don't need to preserve data, simply drop and recreate the meals table
      // Force recreation of the tables with foreign keys disabled temporarily
      await db.execute('PRAGMA foreign_keys = OFF');

      // Drop related tables first to avoid foreign key constraint issues
      await db.execute('DROP TABLE IF EXISTS meal_recipes');

      // Drop the meals table
      await db.execute('DROP TABLE IF EXISTS meals');

      // Recreate the meals table with nullable recipe_id
      await db.execute('''
        CREATE TABLE meals(
          id TEXT PRIMARY KEY,
          recipe_id TEXT, 
          cooked_at TEXT NOT NULL,
          servings INTEGER NOT NULL,
          notes TEXT,
          was_successful INTEGER DEFAULT 1,
          actual_prep_time REAL DEFAULT 0,
          actual_cook_time REAL DEFAULT 0,
          FOREIGN KEY (recipe_id) REFERENCES recipes (id) ON DELETE CASCADE
        )
      ''');

      // Recreate the meal_recipes junction table
      await db.execute('''
        CREATE TABLE meal_recipes(
          id TEXT PRIMARY KEY,
          meal_id TEXT NOT NULL,
          recipe_id TEXT NOT NULL,
          is_primary_dish INTEGER DEFAULT 0,
          notes TEXT,
          FOREIGN KEY (meal_id) REFERENCES meals (id) ON DELETE CASCADE,
          FOREIGN KEY (recipe_id) REFERENCES recipes (id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 13) {
      await db.execute(
          'ALTER TABLE meal_plan_items ADD COLUMN has_been_cooked INTEGER DEFAULT 0');
    }
  }
  // Meal Plan operations

  Future<String> insertMealPlan(MealPlan mealPlan) async {
    final Database db = await database;
    try {
      // Validate meal plan before inserting
      EntityValidator.validateMealPlan(
        id: mealPlan.id,
        weekStartDate: mealPlan.weekStartDate,
      );

      await db.insert('meal_plans', mealPlan.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      return mealPlan.id;
    } on ValidationException {
      // Re-throw validation exceptions
      rethrow;
    } catch (e) {
      throw GastrobrainException('Failed to insert meal plan: ${e.toString()}');
    }
  }

  Future<MealPlan?> getMealPlan(String id) async {
    final Database db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'meal_plans',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) {
        return null;
      }

      // Get the meal plan items for this plan
      final List<Map<String, dynamic>> itemMaps = await db.query(
        'meal_plan_items',
        where: 'meal_plan_id = ?',
        whereArgs: [id],
      );

      // Create MealPlanItem objects from the maps
      final List<MealPlanItem> items = [];

      for (final itemMap in itemMaps) {
        final item = MealPlanItem.fromMap(itemMap);

        // Fetch associated recipes from the junction table
        final List<Map<String, dynamic>> recipeMaps = await db.query(
          'meal_plan_item_recipes',
          where: 'meal_plan_item_id = ?',
          whereArgs: [item.id],
        );

        if (recipeMaps.isNotEmpty) {
          item.mealPlanItemRecipes = List.generate(recipeMaps.length,
              (i) => MealPlanItemRecipe.fromMap(recipeMaps[i]));
        }

        items.add(item);
      }

      return MealPlan.fromMap(maps.first, items);
    } catch (e) {
      throw GastrobrainException('Failed to get meal plan: ${e.toString()}');
    }
  }

  Future<List<MealPlan>> getMealPlansByDateRange(
      DateTime start, DateTime end) async {
    final Database db = await database;

    // Convert dates to ISO format for SQL query
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();

    // Query for meal plans that might fall within the specified range
    // A week now starts on Friday and ends on Thursday (7 days later)
    final List<Map<String, dynamic>> planMaps = await db.rawQuery('''
      SELECT * FROM meal_plans 
      WHERE week_start_date <= ? AND 
            date(week_start_date, '+7 days') >= ?
      ORDER BY week_start_date ASC
    ''', [endStr, startStr]);

    // Build the list of meal plans
    List<MealPlan> mealPlans = [];

    for (var planMap in planMaps) {
      final String planId = planMap['id'];

      // Get all items for this plan
      final List<Map<String, dynamic>> itemMaps = await db.query(
        'meal_plan_items',
        where: 'meal_plan_id = ?',
        whereArgs: [planId],
      );

      final List<MealPlanItem> items = List.generate(
          itemMaps.length, (i) => MealPlanItem.fromMap(itemMaps[i]));

      mealPlans.add(MealPlan.fromMap(planMap, items));
    }

    return mealPlans;
  }

  Future<MealPlan?> getMealPlanForWeek(DateTime date) async {
    final Database db = await database;

    // Calculate the Friday of the week containing this date
    final int weekday = date.weekday;
    // If today is Friday (weekday 5), subtract 0; otherwise calculate offset
    final daysToSubtract = weekday < 5
        ? weekday + 2 // Go back to previous Friday
        : weekday - 5; // Friday is day 5

    // Normalize the date to start of day
    final normalizedStart = DateTime(
      date.subtract(Duration(days: daysToSubtract)).year,
      date.subtract(Duration(days: daysToSubtract)).month,
      date.subtract(Duration(days: daysToSubtract)).day,
    );
    final startStr = normalizedStart.toIso8601String();

    final List<Map<String, dynamic>> maps = await db.query(
      'meal_plans',
      where: 'week_start_date = ?',
      whereArgs: [startStr],
    );

    if (maps.isEmpty) {
      return null;
    }

    // Get the meal plan items for this plan
    final String planId = maps.first['id'];
    final List<Map<String, dynamic>> itemMaps = await db.query(
      'meal_plan_items',
      where: 'meal_plan_id = ?',
      whereArgs: [planId],
    );

    // Create MealPlanItem objects with their associated recipes
    final List<MealPlanItem> items = [];

    for (final itemMap in itemMaps) {
      final item = MealPlanItem.fromMap(itemMap);

      // Fetch associated recipes from the junction table
      final List<Map<String, dynamic>> recipeMaps = await db.query(
        'meal_plan_item_recipes',
        where: 'meal_plan_item_id = ?',
        whereArgs: [item.id],
      );

      if (recipeMaps.isNotEmpty) {
        item.mealPlanItemRecipes = List.generate(recipeMaps.length,
            (i) => MealPlanItemRecipe.fromMap(recipeMaps[i]));
      }

      items.add(item);
    }

    return MealPlan.fromMap(maps.first, items);
  }

  Future<int> updateMealPlan(MealPlan mealPlan) async {
    final Database db = await database;
    try {
      // Validate meal plan before updating
      EntityValidator.validateMealPlan(
        id: mealPlan.id,
        weekStartDate: mealPlan.weekStartDate,
      );

      // Begin a transaction to update the meal plan and its items
      return await db.transaction((txn) async {
        // Update the meal plan
        final updateCount = await txn.update(
          'meal_plans',
          mealPlan.toMap(),
          where: 'id = ?',
          whereArgs: [mealPlan.id],
        );

        if (updateCount == 0) {
          throw NotFoundException(
              'Meal plan not found with id: ${mealPlan.id}');
        }

        // Delete all existing items for this plan
        await txn.delete(
          'meal_plan_items',
          where: 'meal_plan_id = ?',
          whereArgs: [mealPlan.id],
        );
        // Note: junction table records will be deleted by ON DELETE CASCADE

        // Insert all items
        for (var item in mealPlan.items) {
          // Validate each item before inserting
          EntityValidator.validateMealPlanItem(
            mealPlanId: item.mealPlanId,
            plannedDate: item.plannedDate,
            mealType: item.mealType,
          );

          // Insert the meal plan item
          await txn.insert(
            'meal_plan_items',
            item.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          // Insert the recipe associations if any
          if (item.mealPlanItemRecipes != null &&
              item.mealPlanItemRecipes!.isNotEmpty) {
            for (var recipe in item.mealPlanItemRecipes!) {
              await txn.insert(
                'meal_plan_item_recipes',
                recipe.toMap(),
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }
        }

        return 1; // Return success
      });
    } on ValidationException {
      // Re-throw validation exceptions
      rethrow;
    } on NotFoundException {
      // Re-throw not found exceptions
      rethrow;
    } catch (e) {
      throw GastrobrainException('Failed to update meal plan: ${e.toString()}');
    }
  }

  Future<int> deleteMealPlan(String id) async {
    final Database db = await database;

    // The meal_plan_items will be automatically deleted due to ON DELETE CASCADE
    return await db.delete(
      'meal_plans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Meal Plan Item operations

  Future<String> insertMealPlanItem(MealPlanItem item) async {
    final Database db = await database;
    try {
      // Validate item before inserting
      EntityValidator.validateMealPlanItem(
        mealPlanId: item.mealPlanId,
        plannedDate: item.plannedDate,
        mealType: item.mealType,
      );

      await db.insert('meal_plan_items', item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      return item.id;
    } on ValidationException {
      // Re-throw validation exceptions
      rethrow;
    } catch (e) {
      throw GastrobrainException(
          'Failed to insert meal plan item: ${e.toString()}');
    }
  }

  Future<int> updateMealPlanItem(MealPlanItem item) async {
    final Database db = await database;
    return await db.update(
      'meal_plan_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteMealPlanItem(String id) async {
    final Database db = await database;
    return await db.delete(
      'meal_plan_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<MealPlanItem>> getMealPlanItemsForDate(DateTime date) async {
    final Database db = await database;
    final dateStr =
        date.toIso8601String().split('T')[0]; // Get just the date part

    final List<Map<String, dynamic>> maps = await db.query(
      'meal_plan_items',
      where: 'planned_date = ?',
      whereArgs: [dateStr],
    );

    return List.generate(maps.length, (i) => MealPlanItem.fromMap(maps[i]));
  }

  Future<String> insertMealPlanItemRecipe(
      MealPlanItemRecipe mealPlanItemRecipe) async {
    final Database db = await database;
    try {
      // Verify the meal plan item exists before inserting the junction record
      final mealPlanItem = await db.query(
        'meal_plan_items',
        where: 'id = ?',
        whereArgs: [mealPlanItemRecipe.mealPlanItemId],
      );

      if (mealPlanItem.isEmpty) {
        throw NotFoundException(
            'Meal plan item not found with id: ${mealPlanItemRecipe.mealPlanItemId}');
      }

      // Insert the junction record
      await db.insert('meal_plan_item_recipes', mealPlanItemRecipe.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      return mealPlanItemRecipe.id;
    } catch (e) {
      throw GastrobrainException(
          'Failed to insert meal plan item recipe: ${e.toString()}');
    }
  }

  // Ingredient operations
  Future<String> insertIngredient(Ingredient ingredient) async {
    final Database db = await database;
    await db.insert('ingredients', ingredient.toMap());
    return ingredient.id;
  }

  Future<List<Ingredient>> getAllIngredients() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('ingredients');
    return List.generate(maps.length, (i) => Ingredient.fromMap(maps[i]));
  }

  Future<List<Ingredient>> getProteinIngredients({String? proteinType}) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ingredients',
      where:
          proteinType != null ? 'protein_type = ?' : 'protein_type IS NOT NULL',
      whereArgs: proteinType != null ? [proteinType] : null,
    );
    return List.generate(maps.length, (i) => Ingredient.fromMap(maps[i]));
  }

  // Recipe ingredients operations
  Future<void> addIngredientToRecipe(RecipeIngredient recipeIngredient) async {
    final Database db = await database;
    await db.insert('recipe_ingredients', recipeIngredient.toMap());
  }

  Future<List<Map<String, dynamic>>> getRecipeIngredients(
      String recipeId) async {
    final Database db = await database;
    return await db.rawQuery('''
      SELECT 
      ri.id as recipe_ingredient_id,
      ri.quantity,
      ri.notes as preparation_notes,
      ri.unit_override,
      ri.custom_name,
      ri.custom_category,
      ri.custom_unit,
      ri.ingredient_id,
      COALESCE(ri.custom_name, i.name) as name,
      COALESCE(ri.custom_category, i.category) as category,
      COALESCE(ri.custom_unit, COALESCE(ri.unit_override, i.unit)) as unit,
      i.protein_type,
      i.notes as ingredient_notes
    FROM recipe_ingredients ri
    LEFT JOIN ingredients i ON ri.ingredient_id = i.id
    WHERE ri.recipe_id = ?
    ''', [recipeId]);
  }

  Future<int> updateRecipeIngredient(RecipeIngredient recipeIngredient) async {
    final Database db = await database;
    return await db.update(
      'recipe_ingredients',
      recipeIngredient.toMap(),
      where: 'id = ?',
      whereArgs: [recipeIngredient.id],
    );
  }

  // Add this to your DatabaseHelper class
  Future<int> getIngredientsCount() async {
    final Database db = await database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as count FROM ingredients');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Fix your importIngredientsFromJson method:
  Future<void> importIngredientsFromJson(String assetPath) async {
    try {
      // Load the file content from assets - this is the key part
      final String jsonString = await rootBundle.loadString(assetPath);

      // Parse the JSON with error handling
      final List<dynamic> ingredientsJson =
          json.decode(jsonString) as List<dynamic>;

      // Process each ingredient
      for (final ingredientJson in ingredientsJson) {
        try {
          final ingredient = Ingredient(
            id: IdGenerator.generateId(),
            name: ingredientJson['name'] as String,
            category: ingredientJson['category'] as String,
            unit: ingredientJson['unit'] as String?,
            proteinType: ingredientJson['protein_type'] as String?,
          );

          await insertIngredient(ingredient);
        } catch (e) {
          //print(
          //    'Error creating ingredient: ${ingredientJson['name']}, Error: $e');
        }
      }

      //print('Successfully imported ingredients');
    } catch (e) {
      //print('Error importing ingredients: $e');
      rethrow;
    }
  }

  /// Imports recipes from a JSON file in the assets folder
  Future<void> importRecipesFromJson(String assetPath) async {
    try {
      // Load the file content from assets
      final String jsonString = await rootBundle.loadString(assetPath);

      // Parse the JSON data
      final List<dynamic> recipesJson =
          json.decode(jsonString) as List<dynamic>;

      // Track counters for logging
      int successCount = 0;
      int errorCount = 0;
      int ingredientCount = 0;

      // Process each recipe
      for (final recipeJson in recipesJson) {
        try {
          // Create Recipe object
          final recipe = Recipe(
            id: IdGenerator.generateId(),
            name: (recipeJson['name'] as String).toLowerCase(),
            desiredFrequency: FrequencyType.fromString(
                recipeJson['desired_frequency'] as String? ?? 'monthly'),
            notes: recipeJson['notes'] as String? ?? '',
            createdAt: DateTime.parse(recipeJson['created_at'] as String),
            difficulty: recipeJson['difficulty'] as int? ?? 1,
            prepTimeMinutes: recipeJson['prep_time_minutes'] as int? ?? 0,
            cookTimeMinutes: recipeJson['cook_time_minutes'] as int? ?? 0,
            rating: recipeJson['rating'] as int? ?? 0,
          );

          // Insert the recipe
          await insertRecipe(recipe);
          successCount++;

          // Handle main_ingredient if present
          if (recipeJson.containsKey('main_ingredient') &&
              recipeJson['main_ingredient'] != null &&
              recipeJson['main_ingredient'].toString().isNotEmpty) {
            final ingredientName =
                (recipeJson['main_ingredient'] as String).toLowerCase();

            // Check if ingredient exists
            final db = await database;
            final existingIngredient = await db.query(
              'ingredients',
              where: 'name = ?',
              whereArgs: [ingredientName],
              limit: 1,
            );

            String ingredientId;
            if (existingIngredient.isNotEmpty) {
              // Use existing ingredient
              ingredientId = existingIngredient.first['id'] as String;
            } else {
              // Create new ingredient
              final ingredient = Ingredient(
                id: IdGenerator.generateId(),
                name: ingredientName,
                category: 'other',
                proteinType: null,
              );
              ingredientId = await insertIngredient(ingredient);
              ingredientCount++;
            }

            // Create recipe_ingredient relationship
            final recipeIngredient = RecipeIngredient(
              id: IdGenerator.generateId(),
              recipeId: recipe.id,
              ingredientId: ingredientId,
              quantity: 1.0,
            );

            await addIngredientToRecipe(recipeIngredient);
          }
        } catch (e) {
          print('Error creating recipe: ${recipeJson['name']}, Error: $e');
          errorCount++;
        }
      }

      print(
          'Recipe import summary: $successCount recipes imported successfully, $errorCount errors.');
      print('Created $ingredientCount new ingredients.');
    } catch (e) {
      print('Error importing recipes: $e');
      rethrow;
    }
  }

  // Recipe CRUD operations
  Future<int> insertRecipe(Recipe recipe) async {
    final Database db = await database;
    return await db.insert('recipes', recipe.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Recipe>> getAllRecipes() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('recipes');
    return List.generate(maps.length, (i) => Recipe.fromMap(maps[i]));
  }

  Future<Recipe?> getRecipe(String id) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Recipe.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateRecipe(Recipe recipe) async {
    final Database db = await database;
    return await db.update(
      'recipes',
      recipe.toMap(),
      where: 'id = ?',
      whereArgs: [recipe.id],
    );
  }

  Future<int> deleteRecipe(String id) async {
    final Database db = await database;
    return await db.delete(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getRecipesCount() async {
    final Database db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM recipes');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Meal CRUD operations
  Future<int> insertMeal(Meal meal) async {
    final Database db = await database;
    return await db.insert('meals', meal.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Meal>> getMealsForRecipe(String recipeId) async {
    final Database db = await database;

    // Use a join with the junction table to find all meals with this recipe
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT DISTINCT m.* 
      FROM meals m
      LEFT JOIN meal_recipes mr ON m.id = mr.meal_id
      WHERE mr.recipe_id = ? OR m.recipe_id = ?
      ORDER BY m.cooked_at DESC
    ''', [recipeId, recipeId]);

    final meals = List.generate(maps.length, (i) => Meal.fromMap(maps[i]));

    // Load meal recipes for each meal
    for (final meal in meals) {
      final recipes = await getMealRecipesForMeal(meal.id);
      meal.mealRecipes = recipes;
    }

    return meals;
  }

  Future<Meal?> getMeal(String id) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'meals',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    final meal = Meal.fromMap(maps.first);

    // Load associated recipes
    final recipes = await getMealRecipesForMeal(id);
    meal.mealRecipes = recipes;

    return meal;
  }

  Future<int> updateMeal(Meal meal) async {
    final Database db = await database;
    return await db.update(
      'meals',
      meal.toMap(),
      where: 'id = ?',
      whereArgs: [meal.id],
    );
  }

  Future<int> deleteMeal(String id) async {
    final Database db = await database;
    return await db.delete(
      'meals',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // MealRecipe operations
  Future<String> insertMealRecipe(MealRecipe mealRecipe) async {
    final Database db = await database;
    try {
      await db.insert('meal_recipes', mealRecipe.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      return mealRecipe.id;
    } catch (e) {
      throw GastrobrainException(
          'Failed to insert meal recipe: ${e.toString()}');
    }
  }

  Future<List<MealRecipe>> getMealRecipesForMeal(String mealId) async {
    final Database db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'meal_recipes',
        where: 'meal_id = ?',
        whereArgs: [mealId],
      );

      return List.generate(maps.length, (i) => MealRecipe.fromMap(maps[i]));
    } catch (e) {
      throw GastrobrainException('Failed to get meal recipes: ${e.toString()}');
    }
  }

  Future<int> updateMealRecipe(MealRecipe mealRecipe) async {
    final Database db = await database;
    return await db.update(
      'meal_recipes',
      mealRecipe.toMap(),
      where: 'id = ?',
      whereArgs: [mealRecipe.id],
    );
  }

  Future<int> deleteMealRecipe(String id) async {
    final Database db = await database;
    return await db.delete(
      'meal_recipes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Helper methods
  Future<List<Meal>> getRecentMeals({int limit = 10}) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'meals',
      orderBy: 'cooked_at DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => Meal.fromMap(maps[i]));
  }

  /// Add a recipe to an existing meal
  Future<String> addRecipeToMeal(String mealId, String recipeId,
      {bool isPrimaryDish = false}) async {
    final Database db = await database;
    try {
      // Check if meal exists
      final mealExists = await db.query(
        'meals',
        where: 'id = ?',
        whereArgs: [mealId],
        limit: 1,
      );

      if (mealExists.isEmpty) {
        throw NotFoundException('Meal not found with id: $mealId');
      }

      // Check if recipe exists
      final recipeExists = await db.query(
        'recipes',
        where: 'id = ?',
        whereArgs: [recipeId],
        limit: 1,
      );

      if (recipeExists.isEmpty) {
        throw NotFoundException('Recipe not found with id: $recipeId');
      }

      // Check if the junction already exists
      final existing = await db.query(
        'meal_recipes',
        where: 'meal_id = ? AND recipe_id = ?',
        whereArgs: [mealId, recipeId],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        // If it exists and we're trying to set it as primary, update it
        if (isPrimaryDish) {
          // First remove primary status from any other recipes
          await db.update(
            'meal_recipes',
            {'is_primary_dish': 0},
            where: 'meal_id = ?',
            whereArgs: [mealId],
          );

          // Then set this one as primary
          await db.update(
            'meal_recipes',
            {'is_primary_dish': 1},
            where: 'meal_id = ? AND recipe_id = ?',
            whereArgs: [mealId, recipeId],
          );
        }

        return existing.first['id'] as String;
      }

      // If setting as primary, first remove primary status from others
      if (isPrimaryDish) {
        await db.update(
          'meal_recipes',
          {'is_primary_dish': 0},
          where: 'meal_id = ?',
          whereArgs: [mealId],
        );
      }

      // Create new junction record
      final mealRecipe = MealRecipe(
        mealId: mealId,
        recipeId: recipeId,
        isPrimaryDish: isPrimaryDish,
      );

      await db.insert('meal_recipes', mealRecipe.toMap());
      return mealRecipe.id;
    } catch (e) {
      if (e is NotFoundException) {
        rethrow;
      }
      throw GastrobrainException(
          'Failed to add recipe to meal: ${e.toString()}');
    }
  }

  /// Remove a recipe from a meal
  Future<bool> removeRecipeFromMeal(String mealId, String recipeId) async {
    final Database db = await database;
    try {
      final deleted = await db.delete(
        'meal_recipes',
        where: 'meal_id = ? AND recipe_id = ?',
        whereArgs: [mealId, recipeId],
      );

      return deleted > 0;
    } catch (e) {
      throw GastrobrainException(
          'Failed to remove recipe from meal: ${e.toString()}');
    }
  }

  /// Set a recipe as the primary dish for a meal
  Future<bool> setPrimaryRecipeForMeal(String mealId, String recipeId) async {
    final Database db = await database;
    try {
      await db.transaction((txn) async {
        // First reset all recipes for this meal to non-primary
        await txn.update(
          'meal_recipes',
          {'is_primary_dish': 0},
          where: 'meal_id = ?',
          whereArgs: [mealId],
        );

        // Then set the specified recipe as primary
        final updated = await txn.update(
          'meal_recipes',
          {'is_primary_dish': 1},
          where: 'meal_id = ? AND recipe_id = ?',
          whereArgs: [mealId, recipeId],
        );

        if (updated == 0) {
          // Recipe wasn't found in this meal
          // Add it as the primary recipe
          final mealRecipe = MealRecipe(
            mealId: mealId,
            recipeId: recipeId,
            isPrimaryDish: true,
          );

          await txn.insert('meal_recipes', mealRecipe.toMap());
        }
      });

      return true;
    } catch (e) {
      throw GastrobrainException(
          'Failed to set primary recipe: ${e.toString()}');
    }
  }

  Future<DateTime?> getLastCookedDate(String recipeId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'meals',
      columns: ['cooked_at'],
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
      orderBy: 'cooked_at DESC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      return DateTime.parse(result.first['cooked_at']);
    }
    return null;
  }

  Future<int> getTimesCookedCount(String recipeId) async {
    final Database db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM meals WHERE recipe_id = ?',
      [recipeId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Map<String, int>> getAllMealCounts() async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT recipe_id, COUNT(*) as count
      FROM (
        -- Get counts from direct recipe_id references (legacy approach)
        SELECT recipe_id FROM meals WHERE recipe_id IS NOT NULL
        UNION ALL
        -- Get counts from junction table records
        SELECT recipe_id FROM meal_recipes
      )
      GROUP BY recipe_id
    ''');

    return Map.fromEntries(
      results.map((row) => MapEntry(
            row['recipe_id'] as String,
            row['count'] as int,
          )),
    );
  }

  Future<Map<String, DateTime>> getAllLastCooked() async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT recipe_id, MAX(cooked_at) as last_cooked
      FROM (
        -- Get last cooked dates from direct recipe_id references (legacy approach)
        SELECT m.recipe_id, m.cooked_at 
        FROM meals m 
        WHERE m.recipe_id IS NOT NULL
        
        UNION ALL
        
        -- Get last cooked dates from junction table records
        SELECT mr.recipe_id, m.cooked_at 
        FROM meal_recipes mr
        JOIN meals m ON mr.meal_id = m.id
      )
      GROUP BY recipe_id
    ''');

    return Map.fromEntries(
      results.map((row) => MapEntry(
            row['recipe_id'] as String,
            DateTime.parse(row['last_cooked'] as String),
          )),
    );
  }

  Future<List<Recipe>> getRecipesWithSortAndFilter({
    String? sortBy,
    String? sortOrder,
    Map<String, dynamic>? filters,
  }) async {
    final Database db = await database;

    // Start building the query
    String query = 'SELECT * FROM recipes';
    List<dynamic> arguments = [];

    // Add filters if any
    if (filters != null && filters.isNotEmpty) {
      List<String> whereConditions = [];

      if (filters.containsKey('difficulty')) {
        whereConditions.add('difficulty = ?');
        arguments.add(filters['difficulty']);
      }

      if (filters.containsKey('rating')) {
        whereConditions.add('rating >= ?');
        arguments.add(filters['rating']);
      }

      if (filters.containsKey('desired_frequency')) {
        whereConditions.add('desired_frequency = ?');
        arguments.add(filters['desired_frequency']);
      }

      if (whereConditions.isNotEmpty) {
        query += ' WHERE ${whereConditions.join(' AND ')}';
      }
    }

    // Add sorting
    if (sortBy != null) {
      query += ' ORDER BY $sortBy';
      if (sortOrder != null) {
        query += ' $sortOrder';
      }
    } else {
      query += ' ORDER BY created_at DESC'; // Default sorting
    }

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, arguments);
    return List.generate(maps.length, (i) => Recipe.fromMap(maps[i]));
  }

  Future<int> deleteRecipeIngredient(String id) async {
    final Database db = await database;
    return await db.delete(
      'recipe_ingredients',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
