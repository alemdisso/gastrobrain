// ignore_for_file: avoid_print

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
import '../models/ingredient_category.dart';
import '../models/measurement_unit.dart';
import '../models/protein_type.dart';
import '../models/recipe_ingredient.dart';
import '../models/meal_plan.dart';
import '../models/meal_plan_item.dart';
import '../models/meal_plan_item_recipe.dart';
import '../models/meal_plan_item_ingredient.dart';
import '../models/meal_ingredient.dart';
import '../models/recipe_recommendation.dart';
import '../models/recommendation_results.dart';
import '../models/shopping_list.dart';
import '../models/shopping_list_item.dart';
import '../core/errors/gastrobrain_exceptions.dart';
import '../core/migration/migration_runner.dart';
import '../core/migration/migration.dart';
import '../core/migration/migrations/001_initial_schema.dart';
import '../core/migration/migrations/002_add_ingredient_aliases.dart';
import '../core/migration/migrations/003_add_marinating_time.dart';
import '../core/migration/migrations/004_add_recipe_story.dart';
import '../core/migration/migrations/005_add_tags.dart';
import '../core/migration/migrations/006_add_meal_role_food_type.dart';
import '../core/migration/migrations/007_migrate_category_to_tags.dart';
import '../core/migration/migrations/008_add_sauce_food_type.dart';
import '../core/migration/migrations/009_drop_recipe_category.dart';
import '../core/migration/migrations/010_add_quantity_max.dart';
import '../core/migration/migrations/011_add_shopping_list_quantity_max.dart';
import '../core/migration/migrations/012_fix_recipe_tags_cascade.dart';
import '../core/repositories/base_repository.dart';
import 'daos/ingredient_dao.dart';
import 'daos/meal_dao.dart';
import 'daos/meal_plan_dao.dart';
import 'daos/recommendation_dao.dart';
import 'daos/recipe_dao.dart';
import 'daos/shopping_list_dao.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static MigrationRunner? _migrationRunner;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  late final IngredientDao _ingredientDao = IngredientDao(() => database);
  late final MealDao _mealDao = MealDao(() => database);
  late final MealPlanDao _mealPlanDao = MealPlanDao(() => database);
  late final RecommendationDao _recommendationDao = RecommendationDao(() => database);
  late final RecipeDao _recipeDao = RecipeDao(() => database);
  late final ShoppingListDao _shoppingListDao = ShoppingListDao(() => database);

  /// Get all available migrations in order
  static List<Migration> get _migrations => [
    InitialSchemaMigration(),
    AddIngredientAliasesMigration(),
    AddMarinatingTimeMigration(),
    AddRecipeStoryMigration(),
    AddTagsMigration(),
    AddMealRoleFoodTypeMigration(),
    MigrateCategoryToTagsMigration(),
    AddSauceFoodTypeMigration(),
    DropRecipeCategoryMigration(),
    AddQuantityMaxMigration(),
    AddShoppingListQuantityMaxMigration(),
    FixRecipeTagsCascadeMigration(),
  ];

  /// Get the migration runner instance
  MigrationRunner? get migrationRunner => _migrationRunner;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'gastrobrain.db');
    
    final db = await openDatabase(
      path,
      version: 18, // Bumped for lastCookedAt on meal_plans and mealPlanCookedAt on shopping_lists
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        // Enable foreign key constraints
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
    
    // Initialize migration system after database is opened
    await _initializeMigrationSystem(db);
    
    return db;
  }

  /// Initialize the migration system
  ///
  /// Sets up the migration runner and runs pending migrations. On failure,
  /// attempts to rollback to the last known good schema version:
  ///   - Rollback succeeds → records 'warning'; app launches on previous schema.
  ///   - Rollback fails    → records 'fatal'; MigrationErrorScreen shown on next launch.
  Future<void> _initializeMigrationSystem(Database db) async {
    try {
      await _ensureMigrationErrorsTable(db);
      _migrationRunner = MigrationRunner(db, _migrations);
      await _migrationRunner!.initialize();
      await _handleLegacyDatabase(db);
    } catch (e, stack) {
      print('MIGRATION SETUP ERROR: $e');
      print('Stack trace:\n$stack');
      final failedVersion = e is MigrationException ? e.version : null;
      await _recordMigrationFailure(db, failedVersion, e.toString(), 'warning');
      return;
    }

    if (!await _migrationRunner!.needsMigration()) {
      // No pending migrations — clear any errors from previous launches.
      await _acknowledgeAllMigrationErrors(db);
      return;
    }

    final versionBeforeMigrations = await _migrationRunner!.getCurrentVersion();

    try {
      print('Running pending migrations...');
      final results = await _migrationRunner!.runPendingMigrations();
      for (final result in results) {
        print('✓ ${result.toString()}');
      }
      // All migrations succeeded — clear errors from previous failed launches.
      await _acknowledgeAllMigrationErrors(db);
    } catch (e, stack) {
      print('MIGRATION ERROR — attempting rollback: $e');
      print('Stack trace:\n$stack');
      final failedVersion = e is MigrationException ? e.version : null;
      await _attemptRollbackAndRecord(
        db, failedVersion, e.toString(), versionBeforeMigrations,
      );
    }
  }

  Future<void> _ensureMigrationErrorsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS schema_migrations_errors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        failed_version INTEGER,
        error_message TEXT NOT NULL,
        occurred_at TEXT NOT NULL,
        acknowledged INTEGER NOT NULL DEFAULT 0,
        severity TEXT NOT NULL DEFAULT 'warning'
      )
    ''');
    // For databases created before 0.2.12 (lacking the severity column), add it.
    // ALTER TABLE fails if the column already exists, so guard with a PRAGMA check.
    final cols = await db.rawQuery('PRAGMA table_info(schema_migrations_errors)');
    if (!cols.any((r) => r['name'] == 'severity')) {
      await db.execute(
        "ALTER TABLE schema_migrations_errors ADD COLUMN severity TEXT NOT NULL DEFAULT 'warning'",
      );
    }
  }

  Future<void> _recordMigrationFailure(
    Database db,
    int? version,
    String message,
    String severity,
  ) async {
    try {
      await db.rawInsert(
        'INSERT INTO schema_migrations_errors '
        '(failed_version, error_message, occurred_at, severity) VALUES (?, ?, ?, ?)',
        [version, message, DateTime.now().toIso8601String(), severity],
      );
    } catch (_) {
      // Recording failed — nothing further we can do at this point.
    }
  }

  Future<void> _acknowledgeAllMigrationErrors(Database db) async {
    try {
      await db.execute(
        'UPDATE schema_migrations_errors SET acknowledged = 1 WHERE acknowledged = 0',
      );
    } catch (_) {
      // Best-effort.
    }
  }

  /// Attempts rollback to [versionBeforeMigrations]. Records 'warning' on rollback
  /// success and 'fatal' when rollback itself fails (leaving schema undefined).
  ///
  /// No-op down() constraint: migrations such as #107 have an empty down() that
  /// does not throw — rollback proceeds successfully even though their data-level
  /// changes persist. This is by design; irreversible data migrations are safe to
  /// keep. Only a throwing down() causes the rollback to be treated as failed.
  Future<void> _attemptRollbackAndRecord(
    Database db,
    int? failedVersion,
    String errorMessage,
    int versionBeforeMigrations,
  ) async {
    try {
      final currentVersion = await _migrationRunner!.getCurrentVersion();
      if (currentVersion > versionBeforeMigrations) {
        await _migrationRunner!.rollbackToVersion(versionBeforeMigrations);
      }
      // Rollback succeeded (or no partial state to rollback) — schema is consistent.
      await _recordMigrationFailure(db, failedVersion, errorMessage, 'warning');
    } catch (rollbackError, rollbackStack) {
      print('ROLLBACK FAILED — schema is in undefined state: $rollbackError');
      print('Stack trace:\n$rollbackStack');
      await _recordMigrationFailure(db, failedVersion, errorMessage, 'fatal');
    }
  }

  Future<bool> hasPendingMigrationFailure() async {
    try {
      final db = await database;
      await _ensureMigrationErrorsTable(db);
      final rows = await db.rawQuery(
        "SELECT COUNT(*) as count FROM schema_migrations_errors "
        "WHERE severity = 'warning' AND acknowledged = 0",
      );
      return (rows.first['count'] as int) > 0;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasFatalMigrationError() async {
    try {
      final db = await database;
      await _ensureMigrationErrorsTable(db);
      final rows = await db.rawQuery(
        "SELECT COUNT(*) as count FROM schema_migrations_errors "
        "WHERE severity = 'fatal' AND acknowledged = 0",
      );
      return (rows.first['count'] as int) > 0;
    } catch (_) {
      return false;
    }
  }

  Future<void> acknowledgeMigrationFailure() async {
    try {
      final db = await database;
      await db.execute(
        "UPDATE schema_migrations_errors SET acknowledged = 1 "
        "WHERE severity = 'warning' AND acknowledged = 0",
      );
    } catch (_) {
      // Best-effort acknowledgement.
    }
  }

  /// Handle transition from legacy database to migration system
  /// 
  /// For existing databases that don't have migration tracking yet,
  /// we'll mark the initial schema as already applied.
  Future<void> _handleLegacyDatabase(Database db) async {
    try {
      // Check if any tables exist (indicating this is not a fresh database)
      final existingTables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name != 'schema_migrations'"
      );
      
      // Check if migration tracking exists
      final currentVersion = await _migrationRunner!.getCurrentVersion();
      
      // If we have tables but no migration tracking, this is a legacy database
      if (existingTables.isNotEmpty && currentVersion == 0) {
        print('Detected legacy database, marking initial schema as applied...');
        
        // Mark the initial schema migration as already applied.
        // INSERT OR IGNORE handles the case where multiple database instances
        // initialise concurrently and one has already inserted this record.
        await db.rawInsert(
          'INSERT OR IGNORE INTO schema_migrations '
          '(version, applied_at, description, duration_ms) VALUES (?, ?, ?, ?)',
          [1, DateTime.now().toIso8601String(), 'Legacy database - initial schema marked as applied', 0],
        );
        
        print('Legacy database successfully transitioned to migration system');
      }
      
    } catch (e) {
      print('Legacy database handling failed: $e');
      // Continue without marking - fresh migration will handle it
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
        modified_at TEXT,
        meal_type TEXT,
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
        modified_at TEXT NOT NULL,
        last_cooked_at TEXT
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
        planned_servings INTEGER NOT NULL DEFAULT 4,
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
      );
    ''');

    // Create shopping_lists table
    await db.execute('''
      CREATE TABLE shopping_lists(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        date_created INTEGER NOT NULL,
        start_date INTEGER NOT NULL,
        end_date INTEGER NOT NULL,
        meal_plan_modified_at INTEGER,
        meal_plan_cooked_at INTEGER
      )
    ''');

    // Create shopping_list_items table
    await db.execute('''
      CREATE TABLE shopping_list_items(
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

    // Create simple sides tables (ingredients attached to planned/recorded meals)
    await db.execute('''
      CREATE TABLE meal_plan_item_ingredients(
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

    await db.execute('''
      CREATE TABLE meal_ingredients(
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
    if (oldVersion < 14) {
      // Add recommendation_history table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS recommendation_history(
          id TEXT PRIMARY KEY,
          result_data TEXT NOT NULL,
          created_at TEXT NOT NULL,
          context_type TEXT NOT NULL,
          target_date TEXT,
          meal_type TEXT,
          user_id TEXT
        );
      ''');
    }
    if (oldVersion < 15) {
      // Add category column to recipes table
      await db.execute(
          'ALTER TABLE recipes ADD COLUMN category TEXT DEFAULT \'uncategorized\'');
    }

    if (oldVersion < 16) {
      // Add modified_at column to meals table
      await db.execute('ALTER TABLE meals ADD COLUMN modified_at TEXT');

      // Update existing meals to have current timestamp
      final now = DateTime.now().toIso8601String();
      await db.execute(
          'UPDATE meals SET modified_at = ? WHERE modified_at IS NULL', [now]);
    }

    if (oldVersion < 17) {
      // Add instructions column to recipes table
      await db.execute(
          'ALTER TABLE recipes ADD COLUMN instructions TEXT DEFAULT \'\'');
    }
    if (oldVersion < 18) {
      // Add cooked-meal staleness tracking columns (mirrors migration 007)
      await db.execute(
          'ALTER TABLE meal_plans ADD COLUMN last_cooked_at TEXT');
      await db.execute(
          'ALTER TABLE shopping_lists ADD COLUMN meal_plan_cooked_at INTEGER');
    }
  }
  // Meal Plan — delegated to MealPlanDao
  Future<String> insertMealPlan(MealPlan mealPlan) => _mealPlanDao.insertMealPlan(mealPlan);
  Future<MealPlan?> getMealPlan(String id) => _mealPlanDao.getMealPlan(id);
  Future<List<MealPlan>> getMealPlansByDateRange(DateTime start, DateTime end) => _mealPlanDao.getMealPlansByDateRange(start, end);
  Future<MealPlan?> getMealPlanForWeek(DateTime date) => _mealPlanDao.getMealPlanForWeek(date);
  Future<void> updateMealPlanCookedAt(String mealPlanId, DateTime cookedAt) => _mealPlanDao.updateMealPlanCookedAt(mealPlanId, cookedAt);
  Future<int> updateMealPlan(MealPlan mealPlan) => _mealPlanDao.updateMealPlan(mealPlan);
  Future<int> deleteMealPlan(String id) => _mealPlanDao.deleteMealPlan(id);
  Future<List<MealPlan>> getAllMealPlans() => _mealPlanDao.getAllMealPlans();

  // Meal Plan Items — delegated to MealPlanDao
  Future<String> insertMealPlanItem(MealPlanItem item) => _mealPlanDao.insertMealPlanItem(item);
  Future<int> updateMealPlanItem(MealPlanItem item) => _mealPlanDao.updateMealPlanItem(item);
  Future<int> deleteMealPlanItem(String id) => _mealPlanDao.deleteMealPlanItem(id);
  Future<List<MealPlanItem>> getMealPlanItemsForDate(DateTime date) => _mealPlanDao.getMealPlanItemsForDate(date);
  Future<List<MealPlanItem>> getMealPlanItems(String mealPlanId) => _mealPlanDao.getMealPlanItems(mealPlanId);

  // Meal Plan Item Recipes — delegated to MealPlanDao
  Future<String> insertMealPlanItemRecipe(MealPlanItemRecipe mealPlanItemRecipe) => _mealPlanDao.insertMealPlanItemRecipe(mealPlanItemRecipe);
  Future<int> deleteMealPlanItemRecipesByItemId(String mealPlanItemId) => _mealPlanDao.deleteMealPlanItemRecipesByItemId(mealPlanItemId);

  // Meal Plan Item Ingredients — delegated to MealPlanDao
  Future<String> insertMealPlanItemIngredient(MealPlanItemIngredient side) => _mealPlanDao.insertMealPlanItemIngredient(side);
  Future<List<MealPlanItemIngredient>> getMealPlanItemIngredientsForItem(String mealPlanItemId) => _mealPlanDao.getMealPlanItemIngredientsForItem(mealPlanItemId);
  Future<int> deleteMealPlanItemIngredient(String id) => _mealPlanDao.deleteMealPlanItemIngredient(id);
  Future<int> deleteMealPlanItemIngredientsByItemId(String mealPlanItemId) => _mealPlanDao.deleteMealPlanItemIngredientsByItemId(mealPlanItemId);

  // MealIngredient — delegated to MealDao
  Future<String> insertMealIngredient(MealIngredient side) => _mealDao.insertMealIngredient(side);
  Future<List<MealIngredient>> getMealIngredientsForMeal(String mealId) => _mealDao.getMealIngredientsForMeal(mealId);
  Future<int> deleteMealIngredient(String id) => _mealDao.deleteMealIngredient(id);
  Future<int> deleteMealIngredientsByMealId(String mealId) => _mealDao.deleteMealIngredientsByMealId(mealId);

  // Ingredient operations — delegated to IngredientDao
  Future<String> insertIngredient(Ingredient ingredient) => _ingredientDao.insertIngredient(ingredient);
  Future<List<Ingredient>> getAllIngredients() => _ingredientDao.getAllIngredients();
  Future<Ingredient?> getIngredient(String id) => _ingredientDao.getIngredient(id);
  Future<List<Ingredient>> getProteinIngredients({String? proteinType}) => _ingredientDao.getProteinIngredients(proteinType: proteinType);
  Future<int> updateIngredient(Ingredient ingredient) => _ingredientDao.updateIngredient(ingredient);
  Future<int> deleteIngredient(String id) => _ingredientDao.deleteIngredient(id);
  Future<int> getIngredientsCount() => _ingredientDao.getIngredientsCount();

  // Recipe ingredients — delegated to IngredientDao
  Future<void> addIngredientToRecipe(RecipeIngredient recipeIngredient) => _ingredientDao.addIngredientToRecipe(recipeIngredient);
  Future<List<Map<String, dynamic>>> getRecipeIngredients(String recipeId) => _ingredientDao.getRecipeIngredients(recipeId);
  Future<List<Map<String, dynamic>>> getRecipesByIngredientId(String ingredientId) => _ingredientDao.getRecipesByIngredientId(ingredientId);
  Future<List<Map<String, dynamic>>> getMealHistoryByIngredientId(String ingredientId, {String? sinceDate}) => _ingredientDao.getMealHistoryByIngredientId(ingredientId, sinceDate: sinceDate);
  Future<int> updateRecipeIngredient(RecipeIngredient recipeIngredient) => _ingredientDao.updateRecipeIngredient(recipeIngredient);

  Future<void> importIngredientsFromJson(String assetPath) async {
    try {
      final String jsonString = await rootBundle.loadString(assetPath);
      final List<dynamic> ingredientsJson = json.decode(jsonString) as List<dynamic>;
      for (final ingredientJson in ingredientsJson) {
        try {
          final ingredient = Ingredient(
            id: IdGenerator.generateId(),
            name: ingredientJson['name'] as String,
            category: IngredientCategory.fromString(ingredientJson['category'] as String),
            unit: MeasurementUnit.fromString(ingredientJson['unit'] as String?),
            proteinType: ingredientJson['protein_type'] != null
                ? ProteinType.values.firstWhere(
                    (type) => type.name == ingredientJson['protein_type'],
                    orElse: () => ProteinType.other,
                  )
                : null,
          );
          await _ingredientDao.insertIngredient(ingredient);
        } catch (_) {}
      }
    } catch (e) {
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
            instructions: recipeJson['instructions'] as String? ?? '',
            createdAt: DateTime.parse(recipeJson['created_at'] as String),
            difficulty: recipeJson['difficulty'] as int? ?? 1,
            prepTimeMinutes: recipeJson['prep_time_minutes'] as int? ?? 0,
            cookTimeMinutes: recipeJson['cook_time_minutes'] as int? ?? 0,
            rating: recipeJson['rating'] as int? ?? 0,
          );

          // Insert the recipe
          await insertRecipe(recipe);
          successCount++;

          // Handle ingredients list if present
          final ingredientsList =
              recipeJson['ingredients'] as List<dynamic>? ?? [];
          for (final ingJson in ingredientsList) {
            final ingredientName =
                (ingJson['name'] as String? ?? '').toLowerCase();
            if (ingredientName.isEmpty) continue;

            final existing = await _ingredientDao.findIngredientByName(ingredientName);
            String ingredientId;
            if (existing != null) {
              ingredientId = existing.id;
            } else {
              final ingredient = Ingredient(
                id: IdGenerator.generateId(),
                name: ingredientName,
                category: IngredientCategory.fromString(
                    ingJson['category'] as String? ?? 'other'),
                proteinType: null,
              );
              ingredientId = await _ingredientDao.insertIngredient(ingredient);
              ingredientCount++;
            }

            await _ingredientDao.addIngredientToRecipe(RecipeIngredient(
              id: IdGenerator.generateId(),
              recipeId: recipe.id,
              ingredientId: ingredientId,
              quantity: (ingJson['quantity'] as num?)?.toDouble() ?? 1.0,
              unitOverride: ingJson['unit_override'] as String?,
            ));
          }

          // Legacy: handle main_ingredient if present and no ingredients list
          if (ingredientsList.isEmpty &&
              recipeJson.containsKey('main_ingredient') &&
              recipeJson['main_ingredient'] != null &&
              recipeJson['main_ingredient'].toString().isNotEmpty) {
            final ingredientName =
                (recipeJson['main_ingredient'] as String).toLowerCase();

            final existing = await _ingredientDao.findIngredientByName(ingredientName);
            String ingredientId;
            if (existing != null) {
              ingredientId = existing.id;
            } else {
              final ingredient = Ingredient(
                id: IdGenerator.generateId(),
                name: ingredientName,
                category: IngredientCategory.other,
                proteinType: null,
              );
              ingredientId = await _ingredientDao.insertIngredient(ingredient);
              ingredientCount++;
            }

            await _ingredientDao.addIngredientToRecipe(RecipeIngredient(
              id: IdGenerator.generateId(),
              recipeId: recipe.id,
              ingredientId: ingredientId,
              quantity: 1.0,
            ));
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

  // Recipe CRUD operations — delegated to RecipeDao
  Future<int> insertRecipe(Recipe recipe) => _recipeDao.insertRecipe(recipe);
  Future<List<Recipe>> getAllRecipes() => _recipeDao.getAllRecipes();
  Future<Recipe?> getRecipe(String id) => _recipeDao.getRecipe(id);
  Future<int> updateRecipe(Recipe recipe) => _recipeDao.updateRecipe(recipe);
  Future<int> deleteRecipe(String id) => _recipeDao.deleteRecipe(id);
  Future<int> getRecipesCount() => _recipeDao.getRecipesCount();
  Future<int> getEnrichedRecipeCount() => _recipeDao.getEnrichedRecipeCount();
  Future<Map<String, int>> getRecipeEnrichmentStats() => _recipeDao.getRecipeEnrichmentStats();

  // Meal CRUD — delegated to MealDao
  Future<int> insertMeal(Meal meal) => _mealDao.insertMeal(meal);
  Future<List<Meal>> getMealsForRecipe(String recipeId) => _mealDao.getMealsForRecipe(recipeId);
  Future<Meal?> getMeal(String id) => _mealDao.getMeal(id);
  Future<int> updateMeal(Meal meal) => _mealDao.updateMeal(meal);
  Future<int> deleteMeal(String id) => _mealDao.deleteMeal(id);
  Future<List<Meal>> getAllMeals() => _mealDao.getAllMeals();
  Future<List<Meal>> getRecentMeals({int limit = 10}) => _mealDao.getRecentMeals(limit: limit);

  // MealRecipe — delegated to MealDao
  Future<String> insertMealRecipe(MealRecipe mealRecipe) => _mealDao.insertMealRecipe(mealRecipe);
  Future<List<MealRecipe>> getMealRecipesForMeal(String mealId) => _mealDao.getMealRecipesForMeal(mealId);
  Future<int> updateMealRecipe(MealRecipe mealRecipe) => _mealDao.updateMealRecipe(mealRecipe);
  Future<int> deleteMealRecipe(String id) => _mealDao.deleteMealRecipe(id);
  Future<int> deleteMealRecipesByMealId(String mealId, {bool excludePrimary = false}) => _mealDao.deleteMealRecipesByMealId(mealId, excludePrimary: excludePrimary);
  Future<String> addRecipeToMeal(String mealId, String recipeId, {bool isPrimaryDish = false}) => _mealDao.addRecipeToMeal(mealId, recipeId, isPrimaryDish: isPrimaryDish);
  Future<bool> removeRecipeFromMeal(String mealId, String recipeId) => _mealDao.removeRecipeFromMeal(mealId, recipeId);
  Future<bool> setPrimaryRecipeForMeal(String mealId, String recipeId) => _mealDao.setPrimaryRecipeForMeal(mealId, recipeId);

  // Meal statistics — delegated to MealDao
  Future<DateTime?> getLastCookedDate(String recipeId) => _mealDao.getLastCookedDate(recipeId);
  Future<int> getTimesCookedCount(String recipeId) => _mealDao.getTimesCookedCount(recipeId);
  Future<Map<String, int>> getAllMealCounts() => _mealDao.getAllMealCounts();
  Future<Map<String, DateTime>> getAllLastCooked() => _mealDao.getAllLastCooked();

  Future<List<Recipe>> getRecipesWithSortAndFilter({
    String? sortBy,
    String? sortOrder,
    Map<String, dynamic>? filters,
  }) => _recipeDao.getRecipesWithSortAndFilter(
        sortBy: sortBy, sortOrder: sortOrder, filters: filters);

  Future<int> deleteRecipeIngredient(String id) => _ingredientDao.deleteRecipeIngredient(id);

  // Recommendation history — simple ops delegated to RecommendationDao
  Future<String> saveRecommendationHistory(RecommendationResults results, String contextType,
          {DateTime? targetDate, String? mealType}) =>
      _recommendationDao.saveRecommendationHistory(results, contextType,
          targetDate: targetDate, mealType: mealType);

  Future<List<Map<String, dynamic>>> getRecommendationHistory({
    int limit = 10,
    String? contextType,
    DateTime? startDate,
    DateTime? endDate,
  }) =>
      _recommendationDao.getRecommendationHistory(
          limit: limit, contextType: contextType, startDate: startDate, endDate: endDate);

  Future<int> cleanupRecommendationHistory({int daysToKeep = 14}) =>
      _recommendationDao.cleanupRecommendationHistory(daysToKeep: daysToKeep);

  // getRecommendationById and updateRecommendationResponse stay here because
  // RecommendationResults.fromJson requires the full DatabaseHelper for recipe lookups.
  Future<RecommendationResults?> getRecommendationById(String id) async {
    final rawData = await _recommendationDao.getRawRecommendationById(id);
    if (rawData == null) return null;
    final map = jsonDecode(rawData) as Map<String, dynamic>;
    return await RecommendationResults.fromJson(map, this);
  }

  Future<bool> updateRecommendationResponse(
    String historyId,
    String recipeId,
    UserResponse response,
  ) async {
    final results = await getRecommendationById(historyId);
    if (results == null) return false;

    final updatedRecommendations = <RecipeRecommendation>[];
    bool found = false;
    for (final rec in results.recommendations) {
      if (rec.recipe.id == recipeId) {
        updatedRecommendations.add(RecipeRecommendation(
          recipe: rec.recipe,
          totalScore: rec.totalScore,
          factorScores: rec.factorScores,
          metadata: rec.metadata,
          userResponse: response,
          respondedAt: DateTime.now(),
        ));
        found = true;
      } else {
        updatedRecommendations.add(rec);
      }
    }
    if (!found) return false;

    final updatedResults = RecommendationResults(
      recommendations: updatedRecommendations,
      totalEvaluated: results.totalEvaluated,
      queryParameters: results.queryParameters,
      generatedAt: results.generatedAt,
    );
    await _recommendationDao.updateRecommendationResultData(
        historyId, jsonEncode(updatedResults.toJson()));
    return true;
  }

  // === MIGRATION MANAGEMENT METHODS ===

  /// Check if migrations need to be run
  Future<bool> needsMigration() async {
    if (_migrationRunner == null) {
      await database; // Initialize database and migration system
    }
    return _migrationRunner?.needsMigration() ?? false;
  }

  /// Get the current database schema version
  Future<int> getCurrentVersion() async {
    if (_migrationRunner == null) {
      await database; // Initialize database and migration system
    }
    return _migrationRunner?.getCurrentVersion() ?? 0;
  }

  /// Get the latest available migration version
  int getLatestVersion() {
    return _migrations.isEmpty ? 0 : _migrations.last.version;
  }

  /// Get migration history
  Future<List<Map<String, dynamic>>> getMigrationHistory() async {
    if (_migrationRunner == null) {
      await database; // Initialize database and migration system
    }
    return _migrationRunner?.getMigrationHistory() ?? [];
  }

  /// Run pending migrations manually
  /// 
  /// This is useful for UI-controlled migrations or debugging.
  /// Normally migrations run automatically during database initialization.
  Future<List<MigrationResult>> runPendingMigrations({
    void Function(String status, double progress)? onProgress,
    void Function(MigrationResult result)? onMigrationComplete,
  }) async {
    if (_migrationRunner == null) {
      await database; // Initialize database and migration system
    }

    if (_migrationRunner == null) {
      throw const GastrobrainException('Migration system not initialized');
    }

    // Create a new runner with progress callbacks if provided
    if (onProgress != null || onMigrationComplete != null) {
      final db = await database;
      final runner = MigrationRunner(
        db, 
        _migrations,
        onProgress: onProgress,
        onMigrationComplete: onMigrationComplete,
      );
      
      await runner.initialize();
      final results = await runner.runPendingMigrations();
      
      // Notify repositories if any migrations were applied
      if (results.isNotEmpty && results.every((r) => r.success)) {
        notifyMigrationCompleted();
      }
      
      return results;
    }

    final results = await _migrationRunner!.runPendingMigrations();
    
    // Notify repositories if any migrations were applied
    if (results.isNotEmpty && results.every((r) => r.success)) {
      notifyMigrationCompleted();
    }
    
    return results;
  }

  /// Rollback to a specific version (USE WITH CAUTION)
  /// 
  /// This can cause data loss. Only use for development or recovery scenarios.
  Future<List<MigrationResult>> rollbackToVersion(
    int targetVersion, {
    void Function(String status, double progress)? onProgress,
    void Function(MigrationResult result)? onMigrationComplete,
  }) async {
    if (_migrationRunner == null) {
      await database; // Initialize database and migration system
    }

    if (_migrationRunner == null) {
      throw const GastrobrainException('Migration system not initialized');
    }

    // Create a new runner with progress callbacks if provided
    if (onProgress != null || onMigrationComplete != null) {
      final db = await database;
      final runner = MigrationRunner(
        db, 
        _migrations,
        onProgress: onProgress,
        onMigrationComplete: onMigrationComplete,
      );
      
      await runner.initialize();
      final results = await runner.rollbackToVersion(targetVersion);
      
      // Notify repositories if any rollbacks were applied
      if (results.isNotEmpty && results.every((r) => r.success)) {
        notifyMigrationCompleted();
      }
      
      return results;
    }

    final results = await _migrationRunner!.rollbackToVersion(targetVersion);
    
    // Notify repositories if any rollbacks were applied  
    if (results.isNotEmpty && results.every((r) => r.success)) {
      notifyMigrationCompleted();
    }
    
    return results;
  }

  /// Force invalidate all repository caches after migration
  ///
  /// This should be called by repositories after successful migrations
  /// to ensure cached data is refreshed with the new schema.
  void notifyMigrationCompleted() {
    // Notify all registered repositories to invalidate their caches
    print('Migration completed - notifying repositories to invalidate caches');
    RepositoryRegistry.notifyMigrationCompleted();
  }

  /// Close the database connection
  ///
  /// This is used by backup/restore operations that need to close the database
  /// temporarily. After calling this, you must call reopenDatabase() to restore
  /// the connection.
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _migrationRunner = null;
    }
  }

  /// Reopen the database connection
  ///
  /// This reinitializes the database connection after it was closed.
  /// Used by backup/restore operations.
  Future<void> reopenDatabase() async {
    _database = null;
    _migrationRunner = null;
    await database; // This will trigger _initDatabase()
  }

  // Shopping list — delegated to ShoppingListDao
  Future<int> insertShoppingList(ShoppingList shoppingList) => _shoppingListDao.insertShoppingList(shoppingList);
  Future<ShoppingList?> getShoppingList(int id) => _shoppingListDao.getShoppingList(id);
  Future<ShoppingList?> getShoppingListForDateRange(DateTime startDate, DateTime endDate) => _shoppingListDao.getShoppingListForDateRange(startDate, endDate);
  Future<void> deleteShoppingList(int id) => _shoppingListDao.deleteShoppingList(id);
  Future<int> insertShoppingListItem(ShoppingListItem item) => _shoppingListDao.insertShoppingListItem(item);
  Future<ShoppingListItem?> getShoppingListItem(int id) => _shoppingListDao.getShoppingListItem(id);
  Future<List<ShoppingListItem>> getShoppingListItems(int shoppingListId) => _shoppingListDao.getShoppingListItems(shoppingListId);
  Future<void> updateShoppingListItem(ShoppingListItem item) => _shoppingListDao.updateShoppingListItem(item);
  Future<void> deleteShoppingListItem(int id) => _shoppingListDao.deleteShoppingListItem(id);

  /// Get the database file path
  ///
  /// Returns the path to the SQLite database file.
  /// Useful for backup operations.
  Future<String> getDatabasePath() async {
    final db = await database;
    return db.path;
  }

  /// Return meal_role and food_type tag IDs for all recipes.
  ///
  /// Keyed by recipe ID; only recipes with at least one relevant tag appear.
  Future<Map<String, List<String>>> getRecipeTagsForScoring() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT rt.recipe_id, t.id AS tag_id
      FROM recipe_tags rt
      JOIN tags t ON t.id = rt.tag_id
      WHERE t.type_id IN ('meal_role', 'food_type')
    ''');
    final result = <String, List<String>>{};
    for (final row in rows) {
      final recipeId = row['recipe_id'] as String;
      final tagId = row['tag_id'] as String;
      (result[recipeId] ??= []).add(tagId);
    }
    return result;
  }

}
