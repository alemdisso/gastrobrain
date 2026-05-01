import '../migration.dart';

/// Adds the tagging system: tag_types, tags, and recipe_tags tables.
///
/// tag_types defines vocabulary categories (Cuisine, Occasion, Dietary).
///   is_hard  — 1 = AND filter logic; 0 = OR filter logic.
///   is_open  — 1 = users may create new tags; 0 = closed vocabulary.
///
/// tags holds individual tag values linked to a tag_type.
///
/// recipe_tags is the junction table linking recipes to their tags.
///
/// Seed data inserts three built-in tag types and four fixed dietary tags.
/// All INSERTs use OR IGNORE so re-running up() is safe.
class AddTagsMigration extends Migration {
  @override
  int get version => 5;

  @override
  String get description => 'Add tag_types, tags, and recipe_tags tables';

  @override
  bool get requiresBackup => false;

  @override
  Future<void> up(DatabaseExecutor db) async {
    // Check each table individually so up() is idempotent.
    final existing = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('tag_types','tags','recipe_tags')",
    );
    final existingNames = existing.map((r) => r['name'] as String).toSet();

    if (!existingNames.contains('tag_types')) {
      await db.execute('''
        CREATE TABLE tag_types (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          is_hard INTEGER NOT NULL DEFAULT 0,
          is_open INTEGER NOT NULL DEFAULT 1
        )
      ''');
    }

    if (!existingNames.contains('tags')) {
      await db.execute('''
        CREATE TABLE tags (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          type_id TEXT NOT NULL REFERENCES tag_types(id)
        )
      ''');
    }

    if (!existingNames.contains('recipe_tags')) {
      await db.execute('''
        CREATE TABLE recipe_tags (
          recipe_id TEXT NOT NULL REFERENCES recipes(id),
          tag_id TEXT NOT NULL REFERENCES tags(id),
          PRIMARY KEY (recipe_id, tag_id)
        )
      ''');
    }

    // Seed built-in tag types (INSERT OR IGNORE = idempotent).
    await db.execute(
      "INSERT OR IGNORE INTO tag_types (id, name, is_hard, is_open) VALUES ('cuisine', 'Cuisine', 0, 1)",
    );
    await db.execute(
      "INSERT OR IGNORE INTO tag_types (id, name, is_hard, is_open) VALUES ('occasion', 'Occasion', 0, 1)",
    );
    await db.execute(
      "INSERT OR IGNORE INTO tag_types (id, name, is_hard, is_open) VALUES ('dietary', 'Dietary', 1, 0)",
    );

    // Seed closed dietary tags.
    await db.execute(
      "INSERT OR IGNORE INTO tags (id, name, type_id) VALUES ('dietary-vegetarian', 'vegetarian', 'dietary')",
    );
    await db.execute(
      "INSERT OR IGNORE INTO tags (id, name, type_id) VALUES ('dietary-vegan', 'vegan', 'dietary')",
    );
    await db.execute(
      "INSERT OR IGNORE INTO tags (id, name, type_id) VALUES ('dietary-gluten-free', 'gluten-free', 'dietary')",
    );
    await db.execute(
      "INSERT OR IGNORE INTO tags (id, name, type_id) VALUES ('dietary-dairy-free', 'dairy-free', 'dietary')",
    );
  }

  @override
  Future<void> down(DatabaseExecutor db) async {
    // Drop in reverse dependency order.
    await db.execute('DROP TABLE IF EXISTS recipe_tags');
    await db.execute('DROP TABLE IF EXISTS tags');
    await db.execute('DROP TABLE IF EXISTS tag_types');
  }

  @override
  Future<bool> validate(DatabaseExecutor db) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('tag_types','tags','recipe_tags')",
    );
    return result.length == 3;
  }
}
