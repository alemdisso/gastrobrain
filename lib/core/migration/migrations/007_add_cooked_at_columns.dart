import '../migration.dart';

/// Add cooked-meal staleness tracking columns
///
/// - `last_cooked_at` on `meal_plans`: updated whenever any meal in the plan
///   is marked as cooked, enabling shopping list stale detection for that event.
/// - `meal_plan_cooked_at` on `shopping_lists`: snapshot of `last_cooked_at` at
///   generation time, used to compare against current value on list load.
class AddCookedAtColumnsMigration extends Migration {
  @override
  int get version => 7;

  @override
  String get description =>
      'Add last_cooked_at to meal_plans and meal_plan_cooked_at to shopping_lists';

  @override
  Duration get estimatedDuration => const Duration(seconds: 1);

  @override
  bool get requiresBackup => false;

  @override
  Future<void> up(DatabaseExecutor db) async {
    await db.execute('''
      ALTER TABLE meal_plans
      ADD COLUMN last_cooked_at TEXT
    ''');

    await db.execute('''
      ALTER TABLE shopping_lists
      ADD COLUMN meal_plan_cooked_at INTEGER
    ''');
  }

  @override
  Future<void> down(DatabaseExecutor db) async {
    // SQLite doesn't support DROP COLUMN before 3.35.0.
    // Recreate meal_plans without last_cooked_at.
    await db.execute('''
      CREATE TABLE meal_plans_new(
        id TEXT PRIMARY KEY,
        week_start_date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        modified_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      INSERT INTO meal_plans_new (id, week_start_date, notes, created_at, modified_at)
      SELECT id, week_start_date, notes, created_at, modified_at
      FROM meal_plans
    ''');
    await db.execute('DROP TABLE meal_plans');
    await db.execute('ALTER TABLE meal_plans_new RENAME TO meal_plans');

    // Recreate shopping_lists without meal_plan_cooked_at.
    await db.execute('''
      CREATE TABLE shopping_lists_new(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        date_created INTEGER NOT NULL,
        start_date INTEGER NOT NULL,
        end_date INTEGER NOT NULL,
        meal_plan_modified_at INTEGER
      )
    ''');
    await db.execute('''
      INSERT INTO shopping_lists_new
        (id, name, date_created, start_date, end_date, meal_plan_modified_at)
      SELECT id, name, date_created, start_date, end_date, meal_plan_modified_at
      FROM shopping_lists
    ''');
    await db.execute('DROP TABLE shopping_lists');
    await db.execute('ALTER TABLE shopping_lists_new RENAME TO shopping_lists');
  }

  @override
  Future<bool> validate(DatabaseExecutor db) async {
    final mealPlanInfo = await db.rawQuery('PRAGMA table_info(meal_plans)');
    final hasLastCookedAt =
        mealPlanInfo.any((col) => col['name'] == 'last_cooked_at');

    final shoppingListInfo =
        await db.rawQuery('PRAGMA table_info(shopping_lists)');
    final hasMealPlanCookedAt =
        shoppingListInfo.any((col) => col['name'] == 'meal_plan_cooked_at');

    if (!hasLastCookedAt) {
      print('Validation failed: last_cooked_at column not found in meal_plans');
      return false;
    }
    if (!hasMealPlanCookedAt) {
      print(
          'Validation failed: meal_plan_cooked_at column not found in shopping_lists');
      return false;
    }
    return true;
  }
}
