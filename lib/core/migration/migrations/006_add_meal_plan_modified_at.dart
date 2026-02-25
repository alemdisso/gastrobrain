import '../migration.dart';

/// Add meal_plan_modified_at column to shopping_lists table
///
/// This column stores the meal plan's modifiedAt timestamp at the time
/// the shopping list was generated, enabling stale list detection.
class AddMealPlanModifiedAtMigration extends Migration {
  @override
  int get version => 6;

  @override
  String get description =>
      'Add meal_plan_modified_at to shopping_lists for stale detection';

  @override
  Duration get estimatedDuration => const Duration(seconds: 1);

  @override
  bool get requiresBackup => false;

  @override
  Future<void> up(DatabaseExecutor db) async {
    // Guard against column already existing (idempotent migration).
    final tableInfo = await db.rawQuery('PRAGMA table_info(shopping_lists)');
    final hasColumn =
        tableInfo.any((col) => col['name'] == 'meal_plan_modified_at');
    if (!hasColumn) {
      await db.execute('''
        ALTER TABLE shopping_lists
        ADD COLUMN meal_plan_modified_at INTEGER
      ''');
    }
  }

  @override
  Future<void> down(DatabaseExecutor db) async {
    // SQLite doesn't support DROP COLUMN before 3.35.0
    // Recreate table without the column
    await db.execute('''
      CREATE TABLE shopping_lists_new(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        date_created INTEGER NOT NULL,
        start_date INTEGER NOT NULL,
        end_date INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      INSERT INTO shopping_lists_new (id, name, date_created, start_date, end_date)
      SELECT id, name, date_created, start_date, end_date
      FROM shopping_lists
    ''');

    await db.execute('DROP TABLE shopping_lists');
    await db.execute(
        'ALTER TABLE shopping_lists_new RENAME TO shopping_lists');
  }

  @override
  Future<bool> validate(DatabaseExecutor db) async {
    final tableInfo =
        await db.rawQuery('PRAGMA table_info(shopping_lists)');
    final hasColumn = tableInfo
        .any((column) => column['name'] == 'meal_plan_modified_at');
    if (!hasColumn) {
      print('Validation failed: meal_plan_modified_at column not found');
      return false;
    }
    return true;
  }
}
