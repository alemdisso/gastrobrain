import '../migration.dart';

/// Consolidated baseline migration — represents the complete database schema
/// as of migrations 001-011 (issue #292).
///
/// All 13 tables are created in a single step for fresh installs. Migrations
/// 002-011 are archived in _archived/ and no longer run; this migration is
/// the sole source of truth for the schema.
///
/// Tables created:
///   recipes, meals, ingredients, recipe_ingredients,
///   meal_plans, meal_plan_items, meal_plan_item_recipes, meal_recipes,
///   recommendation_history,
///   shopping_lists, shopping_list_items,
///   meal_plan_item_ingredients, meal_ingredients
class InitialSchemaMigration extends Migration {
  @override
  int get version => 101;

  @override
  String get description =>
      'Consolidated baseline schema — all 13 tables (migrations 001-011)';

  @override
  Duration get estimatedDuration => const Duration(seconds: 2);

  @override
  bool get requiresBackup => false;

  @override
  Future<void> up(DatabaseExecutor db) async {
    await db.execute('PRAGMA foreign_keys = ON;');

    // ── Core recipe & ingredient tables ────────────────────────────────────

    await db.execute('''
      CREATE TABLE IF NOT EXISTS recipes(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        desired_frequency TEXT NOT NULL,
        notes TEXT,
        instructions TEXT DEFAULT '',
        created_at TEXT NOT NULL,
        difficulty INTEGER DEFAULT 1,
        prep_time_minutes INTEGER DEFAULT 0,
        cook_time_minutes INTEGER DEFAULT 0,
        rating INTEGER DEFAULT 0,
        category TEXT DEFAULT 'uncategorized',
        servings INTEGER NOT NULL DEFAULT 4
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ingredients(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        unit TEXT,
        protein_type TEXT,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS recipe_ingredients(
        id TEXT PRIMARY KEY,
        recipe_id TEXT NOT NULL,
        ingredient_id TEXT NOT NULL,
        quantity REAL NOT NULL,
        notes TEXT,
        unit_override TEXT,
        custom_name TEXT,
        custom_category TEXT,
        custom_unit TEXT,
        FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE,
        FOREIGN KEY (ingredient_id) REFERENCES ingredients(id) ON DELETE CASCADE
      )
    ''');

    // ── Meal recording tables ───────────────────────────────────────────────

    await db.execute('''
      CREATE TABLE IF NOT EXISTS meals(
        id TEXT PRIMARY KEY,
        recipe_id TEXT,
        cooked_at TEXT NOT NULL,
        servings INTEGER NOT NULL,
        notes TEXT,
        was_successful INTEGER DEFAULT 1,
        actual_prep_time REAL DEFAULT 0,
        actual_cook_time REAL DEFAULT 0,
        modified_at TEXT,
        meal_type TEXT,
        FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS meal_recipes(
        id TEXT PRIMARY KEY,
        meal_id TEXT NOT NULL,
        recipe_id TEXT NOT NULL,
        is_primary_dish INTEGER DEFAULT 0,
        notes TEXT,
        FOREIGN KEY (meal_id) REFERENCES meals(id) ON DELETE CASCADE,
        FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS meal_ingredients(
        id TEXT PRIMARY KEY,
        meal_id TEXT NOT NULL,
        ingredient_id TEXT,
        custom_name TEXT,
        notes TEXT,
        quantity REAL NOT NULL DEFAULT 1.0,
        unit TEXT,
        FOREIGN KEY (meal_id) REFERENCES meals(id) ON DELETE CASCADE,
        FOREIGN KEY (ingredient_id) REFERENCES ingredients(id) ON DELETE SET NULL
      )
    ''');

    // ── Meal planning tables ────────────────────────────────────────────────

    await db.execute('''
      CREATE TABLE IF NOT EXISTS meal_plans(
        id TEXT PRIMARY KEY,
        week_start_date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        modified_at TEXT NOT NULL,
        last_cooked_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS meal_plan_items(
        id TEXT PRIMARY KEY,
        meal_plan_id TEXT NOT NULL,
        planned_date TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        notes TEXT,
        has_been_cooked INTEGER DEFAULT 0,
        planned_servings INTEGER NOT NULL DEFAULT 4,
        FOREIGN KEY (meal_plan_id) REFERENCES meal_plans(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS meal_plan_item_recipes(
        id TEXT PRIMARY KEY,
        meal_plan_item_id TEXT NOT NULL,
        recipe_id TEXT NOT NULL,
        is_primary_dish INTEGER DEFAULT 0,
        notes TEXT,
        FOREIGN KEY (meal_plan_item_id) REFERENCES meal_plan_items(id) ON DELETE CASCADE,
        FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS meal_plan_item_ingredients(
        id TEXT PRIMARY KEY,
        meal_plan_item_id TEXT NOT NULL,
        ingredient_id TEXT,
        custom_name TEXT,
        notes TEXT,
        quantity REAL NOT NULL DEFAULT 1.0,
        unit TEXT,
        FOREIGN KEY (meal_plan_item_id) REFERENCES meal_plan_items(id) ON DELETE CASCADE,
        FOREIGN KEY (ingredient_id) REFERENCES ingredients(id) ON DELETE SET NULL
      )
    ''');

    // ── Shopping list tables ────────────────────────────────────────────────

    await db.execute('''
      CREATE TABLE IF NOT EXISTS shopping_lists(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        date_created INTEGER NOT NULL,
        start_date INTEGER NOT NULL,
        end_date INTEGER NOT NULL,
        meal_plan_modified_at INTEGER,
        meal_plan_cooked_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS shopping_list_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shopping_list_id INTEGER NOT NULL,
        ingredient_name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        category TEXT NOT NULL,
        to_buy INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (shopping_list_id) REFERENCES shopping_lists(id) ON DELETE CASCADE
      )
    ''');

    // ── Recommendation history ──────────────────────────────────────────────

    await db.execute('''
      CREATE TABLE IF NOT EXISTS recommendation_history(
        id TEXT PRIMARY KEY,
        result_data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        context_type TEXT NOT NULL,
        target_date TEXT,
        meal_type TEXT,
        user_id TEXT
      )
    ''');

    await _createIndexes(db);
  }

  @override
  Future<void> down(DatabaseExecutor db) async {
    await db.execute('PRAGMA foreign_keys = OFF');

    await db.execute('DROP TABLE IF EXISTS recommendation_history');
    await db.execute('DROP TABLE IF EXISTS shopping_list_items');
    await db.execute('DROP TABLE IF EXISTS shopping_lists');
    await db.execute('DROP TABLE IF EXISTS meal_plan_item_ingredients');
    await db.execute('DROP TABLE IF EXISTS meal_plan_item_recipes');
    await db.execute('DROP TABLE IF EXISTS meal_plan_items');
    await db.execute('DROP TABLE IF EXISTS meal_plans');
    await db.execute('DROP TABLE IF EXISTS meal_ingredients');
    await db.execute('DROP TABLE IF EXISTS meal_recipes');
    await db.execute('DROP TABLE IF EXISTS meals');
    await db.execute('DROP TABLE IF EXISTS recipe_ingredients');
    await db.execute('DROP TABLE IF EXISTS ingredients');
    await db.execute('DROP TABLE IF EXISTS recipes');

    await db.execute('PRAGMA foreign_keys = ON');
  }

  @override
  Future<bool> validate(DatabaseExecutor db) async {
    const tables = [
      'recipes',
      'ingredients',
      'recipe_ingredients',
      'meals',
      'meal_recipes',
      'meal_ingredients',
      'meal_plans',
      'meal_plan_items',
      'meal_plan_item_recipes',
      'meal_plan_item_ingredients',
      'shopping_lists',
      'shopping_list_items',
      'recommendation_history',
    ];

    for (final table in tables) {
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [table],
      );
      if (result.isEmpty) return false;
    }

    // Verify the is_purchased → to_buy fix is in place
    final itemColumns =
        await db.rawQuery('PRAGMA table_info(shopping_list_items)');
    final hasToBuy = itemColumns.any((c) => c['name'] == 'to_buy');
    final hasIsPurchased = itemColumns.any((c) => c['name'] == 'is_purchased');
    if (!hasToBuy || hasIsPurchased) return false;

    // Verify servings column on recipes
    final recipeColumns = await db.rawQuery('PRAGMA table_info(recipes)');
    if (!recipeColumns.any((c) => c['name'] == 'servings')) return false;

    // Verify planned_servings on meal_plan_items
    final itemPlanColumns =
        await db.rawQuery('PRAGMA table_info(meal_plan_items)');
    if (!itemPlanColumns.any((c) => c['name'] == 'planned_servings')) {
      return false;
    }

    return true;
  }

  Future<void> _createIndexes(DatabaseExecutor db) async {
    // Recipes
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_recipes_category ON recipes(category)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_recipes_frequency ON recipes(desired_frequency)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_recipes_rating ON recipes(rating)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_recipes_difficulty ON recipes(difficulty)');

    // Meals
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_meals_recipe_id ON meals(recipe_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_meals_cooked_at ON meals(cooked_at)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_meals_successful ON meals(was_successful)');

    // Ingredients
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_ingredients_category ON ingredients(category)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_ingredients_protein_type ON ingredients(protein_type)');

    // Recipe ingredients
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_recipe_ingredients_recipe_id ON recipe_ingredients(recipe_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_recipe_ingredients_ingredient_id ON recipe_ingredients(ingredient_id)');

    // Meal plans
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_meal_plans_week_start ON meal_plans(week_start_date)');

    // Meal plan items
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_meal_plan_items_plan_id ON meal_plan_items(meal_plan_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_meal_plan_items_date ON meal_plan_items(planned_date)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_meal_plan_items_type ON meal_plan_items(meal_type)');

    // Junction tables
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_meal_plan_item_recipes_item_id ON meal_plan_item_recipes(meal_plan_item_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_meal_plan_item_recipes_recipe_id ON meal_plan_item_recipes(recipe_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_meal_recipes_meal_id ON meal_recipes(meal_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_meal_recipes_recipe_id ON meal_recipes(recipe_id)');

    // Simple sides
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_meal_plan_item_ingredients_item_id ON meal_plan_item_ingredients(meal_plan_item_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_meal_ingredients_meal_id ON meal_ingredients(meal_id)');

    // Shopping lists
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_shopping_list_items_list_id ON shopping_list_items(shopping_list_id)');

    // Recommendation history
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_recommendation_history_created_at ON recommendation_history(created_at)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_recommendation_history_context ON recommendation_history(context_type)');
  }
}
