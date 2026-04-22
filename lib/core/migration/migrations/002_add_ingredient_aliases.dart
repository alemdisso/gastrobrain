import '../migration.dart';

/// Adds an `aliases` column to the ingredients table.
///
/// Aliases are stored as a JSON array (e.g. '["aipo","celery"]') and allow
/// the ingredient matching service to recognise alternative names for the
/// same ingredient, reducing duplicates from recipe parsing.
class AddIngredientAliasesMigration extends Migration {
  @override
  int get version => 2;

  @override
  String get description => 'Add aliases column to ingredients table';

  @override
  bool get requiresBackup => false;

  @override
  Future<void> up(DatabaseExecutor db) async {
    await db.execute('ALTER TABLE ingredients ADD COLUMN aliases TEXT');
  }

  @override
  Future<void> down(DatabaseExecutor db) async {
    // SQLite older than 3.35 does not support DROP COLUMN.
    // Recreate the table without the aliases column instead.
    await db.execute('''
      CREATE TABLE ingredients_backup(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        unit TEXT,
        protein_type TEXT,
        notes TEXT
      )
    ''');
    await db.execute('''
      INSERT INTO ingredients_backup
      SELECT id, name, category, unit, protein_type, notes
      FROM ingredients
    ''');
    await db.execute('DROP TABLE ingredients');
    await db.execute(
      'ALTER TABLE ingredients_backup RENAME TO ingredients',
    );
  }

  @override
  Future<bool> validate(DatabaseExecutor db) async {
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM pragma_table_info('ingredients') "
      "WHERE name = 'aliases'",
    );
    return (result.first['count'] as int) > 0;
  }
}
