import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/recipe.dart';
import '../models/meal.dart';
import '../models/ingredient.dart';
import '../models/recipe_ingredient.dart';

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
    String path = join(await getDatabasesPath(), 'gastrobrain.db');
    return await openDatabase(
      path,
      version: 4, // Increment version number
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
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
      FOREIGN KEY (recipe_id) REFERENCES recipes (id)
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

    // Create recipe_ingredients table
    await db.execute('''
      CREATE TABLE recipe_ingredients(
        id TEXT PRIMARY KEY,
        recipe_id TEXT NOT NULL,
        ingredient_id TEXT NOT NULL,
        quantity REAL NOT NULL,
        notes TEXT,
        FOREIGN KEY (recipe_id) REFERENCES recipes (id) ON DELETE CASCADE,
        FOREIGN KEY (ingredient_id) REFERENCES ingredients (id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns to existing table
      await db.execute(
          'ALTER TABLE recipes ADD COLUMN difficulty INTEGER DEFAULT 1');
      await db.execute(
          'ALTER TABLE recipes ADD COLUMN prep_time_minutes INTEGER DEFAULT 0');
      await db.execute(
          'ALTER TABLE recipes ADD COLUMN cook_time_minutes INTEGER DEFAULT 0');
      await db
          .execute('ALTER TABLE recipes ADD COLUMN rating INTEGER DEFAULT 0');
    }
    if (oldVersion < 3) {
      // Add new columns to meals table
      await db.execute(
          'ALTER TABLE meals ADD COLUMN was_successful INTEGER DEFAULT 1');
      await db.execute(
          'ALTER TABLE meals ADD COLUMN actual_prep_time REAL DEFAULT 0');
      await db.execute(
          'ALTER TABLE meals ADD COLUMN actual_cook_time REAL DEFAULT 0');
    }

    if (oldVersion < 4) {
      // Add ingredient tables
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

      await db.execute('''
        CREATE TABLE recipe_ingredients(
          id TEXT PRIMARY KEY,
          recipe_id TEXT NOT NULL,
          ingredient_id TEXT NOT NULL,
          quantity REAL NOT NULL,
          notes TEXT,
          FOREIGN KEY (recipe_id) REFERENCES recipes (id) ON DELETE CASCADE,
          FOREIGN KEY (ingredient_id) REFERENCES ingredients (id)
        )
      ''');
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
        i.*
      FROM recipe_ingredients ri
      JOIN ingredients i ON ri.ingredient_id = i.id
      WHERE ri.recipe_id = ?
    ''', [recipeId]);
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
