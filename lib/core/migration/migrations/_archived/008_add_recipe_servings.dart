import '../migration.dart';

/// Add baseline serving yield to recipes
///
/// Every recipe now has a `servings` field representing how many people
/// it feeds by default. Existing recipes receive a default of 4. New
/// recipes default to 4 unless the user changes it.
///
/// This field is the foundation for:
/// - Planned-servings in meal planning slots (#305)
/// - Shopping list quantity scaling (#306)
class AddRecipeServingsMigration extends Migration {
  @override
  int get version => 8;

  @override
  String get description => 'Add servings column (default 4) to recipes table';

  @override
  Duration get estimatedDuration => const Duration(seconds: 1);

  @override
  bool get requiresBackup => false;

  @override
  Future<void> up(DatabaseExecutor db) async {
    final recipeInfo = await db.rawQuery('PRAGMA table_info(recipes)');
    final hasServings = recipeInfo.any((col) => col['name'] == 'servings');
    if (!hasServings) {
      await db.execute('''
        ALTER TABLE recipes
        ADD COLUMN servings INTEGER NOT NULL DEFAULT 4
      ''');
    }
  }

  @override
  Future<void> down(DatabaseExecutor db) async {
    // SQLite < 3.35.0 does not support DROP COLUMN.
    // Recreate recipes without the servings column.
    await db.execute('''
      CREATE TABLE recipes_new(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        desired_frequency TEXT NOT NULL,
        notes TEXT,
        instructions TEXT,
        created_at TEXT NOT NULL,
        difficulty INTEGER NOT NULL DEFAULT 1,
        prep_time_minutes INTEGER NOT NULL DEFAULT 0,
        cook_time_minutes INTEGER NOT NULL DEFAULT 0,
        rating INTEGER NOT NULL DEFAULT 0,
        category TEXT NOT NULL DEFAULT 'uncategorized'
      )
    ''');
    await db.execute('''
      INSERT INTO recipes_new
        (id, name, desired_frequency, notes, instructions, created_at,
         difficulty, prep_time_minutes, cook_time_minutes, rating, category)
      SELECT
        id, name, desired_frequency, notes, instructions, created_at,
        difficulty, prep_time_minutes, cook_time_minutes, rating, category
      FROM recipes
    ''');
    await db.execute('DROP TABLE recipes');
    await db.execute('ALTER TABLE recipes_new RENAME TO recipes');
  }

  @override
  Future<bool> validate(DatabaseExecutor db) async {
    final recipeInfo = await db.rawQuery('PRAGMA table_info(recipes)');
    final hasServings = recipeInfo.any((col) => col['name'] == 'servings');
    if (!hasServings) {
      print('Validation failed: servings column not found in recipes');
      return false;
    }
    return true;
  }
}
