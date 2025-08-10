import '../migration.dart';

/// Initial schema migration - represents the current database structure
/// 
/// This migration creates all the core tables that currently exist
/// in the database. It serves as the baseline for future migrations.
class InitialSchemaMigration extends Migration {
  @override
  int get version => 1;

  @override
  String get description => 'Create initial database schema with all core tables';

  @override
  Duration get estimatedDuration => const Duration(seconds: 2);

  @override
  bool get requiresBackup => false; // Initial schema doesn't need backup

  @override
  Future<void> up(DatabaseExecutor db) async {
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON;');

    // Create recipes table
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
        rating INTEGER DEFAULT 0,
        category TEXT DEFAULT 'uncategorized'
      )
    ''');

    // Create meals table
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
        modified_at TEXT,
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

    // Create recipe_ingredients table
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

    // Create meal_plan_items table
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

    // Create recommendation_history table
    await db.execute('''
      CREATE TABLE recommendation_history(
        id TEXT PRIMARY KEY,
        result_data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        context_type TEXT NOT NULL,
        target_date TEXT,
        meal_type TEXT,
        user_id TEXT
      )
    ''');

    // Create indexes for better performance
    await _createIndexes(db);
  }

  @override
  Future<void> down(DatabaseExecutor db) async {
    // Drop all tables in reverse dependency order
    await db.execute('PRAGMA foreign_keys = OFF');
    
    await db.execute('DROP TABLE IF EXISTS recommendation_history');
    await db.execute('DROP TABLE IF EXISTS meal_recipes');
    await db.execute('DROP TABLE IF EXISTS meal_plan_item_recipes');
    await db.execute('DROP TABLE IF EXISTS meal_plan_items');
    await db.execute('DROP TABLE IF EXISTS meal_plans');
    await db.execute('DROP TABLE IF EXISTS recipe_ingredients');
    await db.execute('DROP TABLE IF EXISTS ingredients');
    await db.execute('DROP TABLE IF EXISTS meals');
    await db.execute('DROP TABLE IF EXISTS recipes');
    
    await db.execute('PRAGMA foreign_keys = ON');
  }

  @override
  Future<bool> validate(DatabaseExecutor db) async {
    // Validate that all tables were created
    final tables = [
      'recipes',
      'meals', 
      'ingredients',
      'recipe_ingredients',
      'meal_plans',
      'meal_plan_items',
      'meal_plan_item_recipes',
      'meal_recipes',
      'recommendation_history'
    ];

    for (final table in tables) {
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [table]
      );
      
      if (result.isEmpty) {
        return false;
      }
    }

    return true;
  }

  /// Create indexes for better query performance
  Future<void> _createIndexes(DatabaseExecutor db) async {
    // Recipes indexes
    await db.execute('CREATE INDEX idx_recipes_category ON recipes(category)');
    await db.execute('CREATE INDEX idx_recipes_frequency ON recipes(desired_frequency)');
    await db.execute('CREATE INDEX idx_recipes_rating ON recipes(rating)');
    await db.execute('CREATE INDEX idx_recipes_difficulty ON recipes(difficulty)');

    // Meals indexes
    await db.execute('CREATE INDEX idx_meals_recipe_id ON meals(recipe_id)');
    await db.execute('CREATE INDEX idx_meals_cooked_at ON meals(cooked_at)');
    await db.execute('CREATE INDEX idx_meals_successful ON meals(was_successful)');

    // Ingredients indexes
    await db.execute('CREATE INDEX idx_ingredients_category ON ingredients(category)');
    await db.execute('CREATE INDEX idx_ingredients_protein_type ON ingredients(protein_type)');

    // Recipe ingredients indexes
    await db.execute('CREATE INDEX idx_recipe_ingredients_recipe_id ON recipe_ingredients(recipe_id)');
    await db.execute('CREATE INDEX idx_recipe_ingredients_ingredient_id ON recipe_ingredients(ingredient_id)');

    // Meal plans indexes
    await db.execute('CREATE INDEX idx_meal_plans_week_start ON meal_plans(week_start_date)');

    // Meal plan items indexes
    await db.execute('CREATE INDEX idx_meal_plan_items_plan_id ON meal_plan_items(meal_plan_id)');
    await db.execute('CREATE INDEX idx_meal_plan_items_date ON meal_plan_items(planned_date)');
    await db.execute('CREATE INDEX idx_meal_plan_items_type ON meal_plan_items(meal_type)');

    // Junction table indexes
    await db.execute('CREATE INDEX idx_meal_plan_item_recipes_item_id ON meal_plan_item_recipes(meal_plan_item_id)');
    await db.execute('CREATE INDEX idx_meal_plan_item_recipes_recipe_id ON meal_plan_item_recipes(recipe_id)');
    await db.execute('CREATE INDEX idx_meal_recipes_meal_id ON meal_recipes(meal_id)');
    await db.execute('CREATE INDEX idx_meal_recipes_recipe_id ON meal_recipes(recipe_id)');

    // Recommendation history indexes
    await db.execute('CREATE INDEX idx_recommendation_history_created_at ON recommendation_history(created_at)');
    await db.execute('CREATE INDEX idx_recommendation_history_context ON recommendation_history(context_type)');
  }
}