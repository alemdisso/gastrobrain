import '../migration.dart';

/// Adds a `marinating_time_minutes` column to the recipes table.
///
/// Marinating is advance passive preparation separate from active prep and cook
/// time. Stored as INTEGER DEFAULT 0; 0 means the recipe has no marinating step.
class AddMarinatingTimeMigration extends Migration {
  @override
  int get version => 103;

  @override
  String get description => 'Add marinating_time_minutes column to recipes table';

  @override
  bool get requiresBackup => false;

  @override
  Future<void> up(DatabaseExecutor db) async {
    final cols = await db.rawQuery('PRAGMA table_info(recipes)');
    if (cols.any((r) => r['name'] == 'marinating_time_minutes')) return;
    await db.execute(
      'ALTER TABLE recipes ADD COLUMN marinating_time_minutes INTEGER DEFAULT 0',
    );
  }

  @override
  Future<void> down(DatabaseExecutor db) async {
    // SQLite older than 3.35 does not support DROP COLUMN.
    // Recreate the recipes table without the marinating_time_minutes column.
    await db.execute('''
      CREATE TABLE recipes_backup(
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
      INSERT INTO recipes_backup
      SELECT id, name, desired_frequency, notes, instructions, created_at,
             difficulty, prep_time_minutes, cook_time_minutes, rating,
             category, servings
      FROM recipes
    ''');
    await db.execute('DROP TABLE recipes');
    await db.execute('ALTER TABLE recipes_backup RENAME TO recipes');
  }

  @override
  Future<bool> validate(DatabaseExecutor db) async {
    final result = await db.rawQuery('PRAGMA table_info(recipes)');
    return result.any((r) => r['name'] == 'marinating_time_minutes');
  }
}
