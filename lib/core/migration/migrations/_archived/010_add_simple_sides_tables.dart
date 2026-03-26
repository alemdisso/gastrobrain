import '../migration.dart';

/// Add simple sides tables — ingredients as meal sides (#311)
///
/// Introduces two junction tables that allow users to attach bare ingredients
/// (DB-linked or free-text) to a meal as "simple sides", without requiring a
/// full recipe. Mirrors the existing meal_plan_item_recipes / meal_recipes
/// pattern.
///
/// New tables:
/// - meal_plan_item_ingredients: simple sides for the planning phase
/// - meal_ingredients: simple sides for the recording/cooking phase
///
/// Dual-mode: ingredientId is nullable to support free-text entries
/// (customName is non-null in that case). ON DELETE CASCADE from parent tables
/// ensures no orphaned records. ON DELETE SET NULL from ingredients table
/// handles the case where a DB ingredient is later deleted.
class AddSimpleSidesMigration extends Migration {
  @override
  int get version => 10;

  @override
  String get description =>
      'Add meal_plan_item_ingredients and meal_ingredients tables for simple sides (#311)';

  @override
  Duration get estimatedDuration => const Duration(seconds: 1);

  @override
  bool get requiresBackup => false; // Additive new tables — no existing data affected

  @override
  Future<void> up(DatabaseExecutor db) async {
    // meal_plan_item_ingredients — planning phase simple sides
    await db.execute('''
      CREATE TABLE IF NOT EXISTS meal_plan_item_ingredients(
        id TEXT PRIMARY KEY,
        meal_plan_item_id TEXT NOT NULL,
        ingredient_id TEXT,
        custom_name TEXT,
        notes TEXT,
        FOREIGN KEY (meal_plan_item_id) REFERENCES meal_plan_items(id) ON DELETE CASCADE,
        FOREIGN KEY (ingredient_id) REFERENCES ingredients(id) ON DELETE SET NULL
      )
    ''');

    // meal_ingredients — recording/cooking phase simple sides
    await db.execute('''
      CREATE TABLE IF NOT EXISTS meal_ingredients(
        id TEXT PRIMARY KEY,
        meal_id TEXT NOT NULL,
        ingredient_id TEXT,
        custom_name TEXT,
        notes TEXT,
        FOREIGN KEY (meal_id) REFERENCES meals(id) ON DELETE CASCADE,
        FOREIGN KEY (ingredient_id) REFERENCES ingredients(id) ON DELETE SET NULL
      )
    ''');
  }

  @override
  Future<void> down(DatabaseExecutor db) async {
    // Drop in reverse order; CASCADE FKs make this safe
    await db.execute('DROP TABLE IF EXISTS meal_ingredients');
    await db.execute('DROP TABLE IF EXISTS meal_plan_item_ingredients');
  }

  @override
  Future<bool> validate(DatabaseExecutor db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' "
      "AND name IN ('meal_plan_item_ingredients', 'meal_ingredients')",
    );

    if (tables.length != 2) {
      print('Validation failed: expected 2 simple-sides tables, found ${tables.length}');
      return false;
    }

    // Verify meal_plan_item_ingredients columns
    final planIngColumns =
        await db.rawQuery('PRAGMA table_info(meal_plan_item_ingredients)');
    for (final col in ['id', 'meal_plan_item_id', 'ingredient_id', 'custom_name', 'notes']) {
      if (!planIngColumns.any((c) => c['name'] == col)) {
        print('Validation failed: meal_plan_item_ingredients missing column $col');
        return false;
      }
    }

    // Verify meal_ingredients columns
    final mealIngColumns =
        await db.rawQuery('PRAGMA table_info(meal_ingredients)');
    for (final col in ['id', 'meal_id', 'ingredient_id', 'custom_name', 'notes']) {
      if (!mealIngColumns.any((c) => c['name'] == col)) {
        print('Validation failed: meal_ingredients missing column $col');
        return false;
      }
    }

    return true;
  }
}
