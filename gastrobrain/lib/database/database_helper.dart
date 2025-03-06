// Update in database_helper.dart
import 'dart:async'; // Add this import for Zone access
//import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
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
      version: 10, // Increment version number for new tables
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

      // Additional check: see if running in a testing isolate
      final testZone =
          Zone.current[#test.declarer]; // Zone marker used by test framework
      if (testZone != null) {
        return true;
      }
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

    final Database db = await database;

    // Disable foreign keys to allow for clean deletion
    await db.execute('PRAGMA foreign_keys = OFF');

    try {
      // Get all tables in the database
      final List<Map<String, dynamic>> tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'",
      );

      // Drop all tables
      for (final table in tables) {
        final tableName = table['name'] as String;
        await db.execute('DROP TABLE IF EXISTS $tableName');
      }

      // Re-create the tables
      await _onCreate(db, 9); // Use your current db version
    } finally {
      // Re-enable foreign keys
      await db.execute('PRAGMA foreign_keys = ON');
    }
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
        recipe_id TEXT NOT NULL,
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
    // Version 10: Fresh start with a clean schema
    // All previous migrations (versions 1-9) have been consolidated

    // If we're upgrading from any version before 10, apply our new baseline schema
    if (oldVersion < 10) {
      // We're starting with a clean slate for version 10 and up
      // In the future, new migrations will be added below as: if (oldVersion < 11), etc.

      // Add any migration code here if needed in the future
      // For example, if we modify the database schema, we would add migration code here
      // to preserve user data while updating the schema
    }

    // For future migrations, add new version checks below:
    // if (oldVersion < 11) {
    //   // Future migration code for version 11
    // }

    // if (oldVersion < 12) {
    //   // Future migration code for version 12
    // }
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

  // Meal CRUD operations
  Future<int> insertMeal(Meal meal) async {
    final Database db = await database;
    return await db.insert('meals', meal.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Meal>> getMealsForRecipe(String recipeId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'meals',
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
      orderBy: 'cooked_at DESC',
    );
    return List.generate(maps.length, (i) => Meal.fromMap(maps[i]));
  }

  Future<Meal?> getMeal(String id) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'meals',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Meal.fromMap(maps.first);
    }
    return null;
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
    final Database db = await database;
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT recipe_id, COUNT(*) as count
      FROM meals
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
    final Database db = await database;
    final List<Map<String, dynamic>> results = await db.rawQuery('''
    SELECT recipe_id, MAX(cooked_at) as last_cooked
    FROM meals
    GROUP BY recipe_id
  ''');

    // Future<List<Map<String, dynamic>>> getRecipeCookingStats() async {
    //   final Database db = await database;
    //   final List<Map<String, dynamic>> results = await db.rawQuery('''
    //   SELECT
    //     r.id,
    //     r.name,
    //     r.desired_frequency,
    //     MAX(m.cooked_at) as last_cooked,
    //     COUNT(m.id) as times_cooked,
    //     AVG(m.actual_prep_time) as avg_prep_time,
    //     AVG(m.actual_cook_time) as avg_cook_time
    //   FROM recipes r
    //   LEFT JOIN meals m ON r.id = m.recipe_id
    //   GROUP BY r.id
    // ''');

    //   return results;
    // }

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
