import '../migration.dart';

/// Drops the `category` column from the recipes table.
///
/// The column was superseded by the tags system (migrations 005-007).
/// Uses table recreation because SQLite on older Android does not support
/// DROP COLUMN natively (pre-3.35).
///
/// up() is a no-op when the column is already absent (fresh installs that
/// ran the updated InitialSchemaMigration will not have the column at all).
///
/// Foreign keys are disabled for the duration of the table recreation.
/// This follows the same pattern used in _onUpgrade (database_helper.dart)
/// and avoids FK enforcement errors on DROP TABLE in some SQLite builds.
/// recipes_new is dropped first to handle dirty state from a previous
/// failed attempt (sqflite DDL is not guaranteed transactional on all
/// Android SQLite versions).
class DropRecipeCategoryMigration extends Migration {
  @override
  int get version => 109;

  @override
  String get description => 'Drop category column from recipes table';

  @override
  bool get requiresBackup => false;

  @override
  Future<void> up(DatabaseExecutor db) async {
    final cols = await db.rawQuery('PRAGMA table_info(recipes)');
    if (!cols.any((r) => r['name'] == 'category')) return;

    await db.execute('PRAGMA foreign_keys = OFF');
    try {
      await db.execute('DROP TABLE IF EXISTS recipes_new');
      await db.execute('DROP INDEX IF EXISTS idx_recipes_category');
      await db.execute('''
        CREATE TABLE recipes_new(
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          desired_frequency TEXT NOT NULL,
          notes TEXT,
          instructions TEXT DEFAULT '',
          created_at TEXT NOT NULL,
          difficulty INTEGER DEFAULT 1,
          prep_time_minutes INTEGER DEFAULT 0,
          cook_time_minutes INTEGER DEFAULT 0,
          marinating_time_minutes INTEGER DEFAULT 0,
          rating INTEGER DEFAULT 0,
          servings INTEGER NOT NULL DEFAULT 4,
          story TEXT DEFAULT ''
        )
      ''');
      await db.execute('''
        INSERT INTO recipes_new
        SELECT id, name, desired_frequency, notes, instructions, created_at,
               difficulty, prep_time_minutes, cook_time_minutes,
               marinating_time_minutes, rating, servings, story
        FROM recipes
      ''');
      await db.execute('DROP TABLE recipes');
      await db.execute('ALTER TABLE recipes_new RENAME TO recipes');
    } finally {
      await db.execute('PRAGMA foreign_keys = ON');
    }
  }

  @override
  Future<void> down(DatabaseExecutor db) async {
    final cols = await db.rawQuery('PRAGMA table_info(recipes)');
    if (cols.any((r) => r['name'] == 'category')) return;

    await db.execute('PRAGMA foreign_keys = OFF');
    try {
      await db.execute('DROP TABLE IF EXISTS recipes_new');
      await db.execute('''
        CREATE TABLE recipes_new(
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          desired_frequency TEXT NOT NULL,
          notes TEXT,
          instructions TEXT DEFAULT '',
          created_at TEXT NOT NULL,
          difficulty INTEGER DEFAULT 1,
          prep_time_minutes INTEGER DEFAULT 0,
          cook_time_minutes INTEGER DEFAULT 0,
          marinating_time_minutes INTEGER DEFAULT 0,
          rating INTEGER DEFAULT 0,
          category TEXT DEFAULT 'uncategorized',
          servings INTEGER NOT NULL DEFAULT 4,
          story TEXT DEFAULT ''
        )
      ''');
      await db.execute('''
        INSERT INTO recipes_new
        SELECT id, name, desired_frequency, notes, instructions, created_at,
               difficulty, prep_time_minutes, cook_time_minutes,
               marinating_time_minutes, rating, 'uncategorized', servings, story
        FROM recipes
      ''');
      await db.execute('DROP TABLE recipes');
      await db.execute('ALTER TABLE recipes_new RENAME TO recipes');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_recipes_category ON recipes(category)',
      );
    } finally {
      await db.execute('PRAGMA foreign_keys = ON');
    }
  }

  @override
  Future<bool> validate(DatabaseExecutor db) async {
    final cols = await db.rawQuery('PRAGMA table_info(recipes)');
    return !cols.any((r) => r['name'] == 'category');
  }
}
