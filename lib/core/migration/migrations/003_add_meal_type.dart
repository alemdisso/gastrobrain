import '../migration.dart';

/// Add meal_type column to meals table
///
/// This migration adds an optional meal_type field to track whether a meal
/// was for lunch, dinner, or meal prep. This provides better context for
/// meal history and enables future pattern analysis.
class AddMealTypeMigration extends Migration {
  @override
  int get version => 3;

  @override
  String get description => 'Add meal_type column to meals table';

  @override
  Duration get estimatedDuration => const Duration(seconds: 1);

  @override
  bool get requiresBackup => false; // Adding nullable column is safe

  @override
  Future<void> up(DatabaseExecutor db) async {
    print('Adding meal_type column to meals table...');

    // Add nullable meal_type column to meals table
    // Valid values: 'lunch', 'dinner', 'prep', or NULL
    await db.execute('''
      ALTER TABLE meals ADD COLUMN meal_type TEXT
    ''');

    // Note: existing meals will have NULL meal_type - this is intentional
    // Only new meals will have the opportunity to set meal type

    print('meal_type column added successfully');
  }

  @override
  Future<void> down(DatabaseExecutor db) async {
    // SQLite doesn't support DROP COLUMN directly
    // To rollback, we would need to:
    // 1. Create new table without meal_type
    // 2. Copy data from old table
    // 3. Drop old table
    // 4. Rename new table
    //
    // This is complex and risky, so we're not implementing rollback
    print('Rollback not supported for this migration (SQLite limitation)');
    throw UnsupportedError('Cannot rollback meal_type column addition - SQLite does not support DROP COLUMN');
  }

  @override
  Future<bool> validate(DatabaseExecutor db) async {
    // Verify that the meal_type column exists
    final tableInfo = await db.rawQuery('PRAGMA table_info(meals)');

    final hasMealTypeColumn = tableInfo.any((column) => column['name'] == 'meal_type');

    if (!hasMealTypeColumn) {
      print('Validation failed: meal_type column not found in meals table');
      return false;
    }

    // Verify column is TEXT type and nullable
    final mealTypeColumn = tableInfo.firstWhere((column) => column['name'] == 'meal_type');
    final isTextType = mealTypeColumn['type'] == 'TEXT';
    final isNullable = mealTypeColumn['notnull'] == 0;

    if (!isTextType) {
      print('Validation failed: meal_type column is not TEXT type');
      return false;
    }

    if (!isNullable) {
      print('Validation failed: meal_type column should be nullable');
      return false;
    }

    // Count meals to verify table is intact
    final mealCount = await db.rawQuery('SELECT COUNT(*) as count FROM meals');
    final count = mealCount.first['count'] as int;

    print('Validation passed: meal_type column added successfully ($count existing meals preserved)');
    return true;
  }
}
