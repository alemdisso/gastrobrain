import '../migration.dart';

/// Add planned servings count to meal plan items
///
/// Each meal planning slot now records how many servings the user intends
/// to prepare. This is used by the shopping list generator (#306) to scale
/// ingredient quantities correctly.
///
/// Existing rows receive a default of 4 servings. New items default to the
/// selected primary recipe's own servings value at runtime.
class AddPlannedServingsMigration extends Migration {
  @override
  int get version => 9;

  @override
  String get description =>
      'Add planned_servings column (default 4) to meal_plan_items table';

  @override
  Duration get estimatedDuration => const Duration(seconds: 1);

  @override
  bool get requiresBackup => false;

  @override
  Future<void> up(DatabaseExecutor db) async {
    final itemInfo = await db.rawQuery('PRAGMA table_info(meal_plan_items)');
    final hasPlannedServings =
        itemInfo.any((col) => col['name'] == 'planned_servings');
    if (!hasPlannedServings) {
      await db.execute('''
        ALTER TABLE meal_plan_items
        ADD COLUMN planned_servings INTEGER NOT NULL DEFAULT 4
      ''');
    }
  }

  @override
  Future<void> down(DatabaseExecutor db) async {
    // SQLite < 3.35.0 does not support DROP COLUMN.
    // Recreate meal_plan_items without the planned_servings column.
    await db.execute('''
      CREATE TABLE meal_plan_items_new(
        id TEXT PRIMARY KEY,
        meal_plan_id TEXT NOT NULL,
        planned_date TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        has_been_cooked INTEGER NOT NULL DEFAULT 0,
        cooked_at TEXT,
        FOREIGN KEY (meal_plan_id) REFERENCES meal_plans(id)
      )
    ''');
    await db.execute('''
      INSERT INTO meal_plan_items_new
        (id, meal_plan_id, planned_date, meal_type, notes, has_been_cooked, cooked_at)
      SELECT
        id, meal_plan_id, planned_date, meal_type, notes, has_been_cooked, cooked_at
      FROM meal_plan_items
    ''');
    await db.execute('DROP TABLE meal_plan_items');
    await db.execute('ALTER TABLE meal_plan_items_new RENAME TO meal_plan_items');
  }

  @override
  Future<bool> validate(DatabaseExecutor db) async {
    final itemInfo = await db.rawQuery('PRAGMA table_info(meal_plan_items)');
    final hasPlannedServings =
        itemInfo.any((col) => col['name'] == 'planned_servings');
    if (!hasPlannedServings) {
      print(
          'Validation failed: planned_servings column not found in meal_plan_items');
      return false;
    }
    return true;
  }
}
