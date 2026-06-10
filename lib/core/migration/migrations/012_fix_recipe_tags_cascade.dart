import '../migration.dart';

/// Fixes missing ON DELETE CASCADE on recipe_tags.recipe_id.
///
/// Migration 005 created recipe_tags with a bare REFERENCES recipes(id)
/// constraint, which blocks deleting a recipe that has any tags when
/// PRAGMA foreign_keys = ON is active.
///
/// requiresFkDisable = true: FK enforcement must be off at the connection
/// level before the table swap; PRAGMA foreign_keys cannot be changed inside
/// a transaction.
class FixRecipeTagsCascadeMigration extends Migration {
  @override
  int get version => 112;

  @override
  String get description =>
      'Add ON DELETE CASCADE to recipe_tags.recipe_id foreign key';

  @override
  bool get requiresBackup => false;

  @override
  bool get requiresFkDisable => true;

  @override
  Future<void> up(DatabaseExecutor db) async {
    await db.execute('DROP TABLE IF EXISTS recipe_tags_new');
    await db.execute('''
      CREATE TABLE recipe_tags_new (
        recipe_id TEXT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
        tag_id    TEXT NOT NULL REFERENCES tags(id)    ON DELETE CASCADE,
        PRIMARY KEY (recipe_id, tag_id)
      )
    ''');
    await db.execute(
        'INSERT INTO recipe_tags_new SELECT recipe_id, tag_id FROM recipe_tags');
    await db.execute('DROP TABLE recipe_tags');
    await db.execute('ALTER TABLE recipe_tags_new RENAME TO recipe_tags');
  }

  @override
  Future<void> down(DatabaseExecutor db) async {
    await db.execute('DROP TABLE IF EXISTS recipe_tags_new');
    await db.execute('''
      CREATE TABLE recipe_tags_new (
        recipe_id TEXT NOT NULL REFERENCES recipes(id),
        tag_id    TEXT NOT NULL REFERENCES tags(id),
        PRIMARY KEY (recipe_id, tag_id)
      )
    ''');
    await db.execute(
        'INSERT INTO recipe_tags_new SELECT recipe_id, tag_id FROM recipe_tags');
    await db.execute('DROP TABLE recipe_tags');
    await db.execute('ALTER TABLE recipe_tags_new RENAME TO recipe_tags');
  }

  @override
  Future<bool> validate(DatabaseExecutor db) async {
    final result = await db.rawQuery(
        "SELECT sql FROM sqlite_master WHERE type='table' AND name='recipe_tags'");
    if (result.isEmpty) return false;
    final sql = result.first['sql'] as String? ?? '';
    return sql.toUpperCase().contains('ON DELETE CASCADE');
  }
}
