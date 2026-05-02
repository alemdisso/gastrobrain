import '../migration.dart';

/// Adds 'sauce' to the food_type vocabulary.
///
/// Recipes previously categorised as 'sauces' had no mapping in migration 007
/// and were left for manual re-tagging. This tag provides that target.
class AddSauceFoodTypeMigration extends Migration {
  @override
  int get version => 108;

  @override
  String get description => "Add 'sauce' to food_type vocabulary";

  @override
  bool get requiresBackup => false;

  @override
  Future<void> up(DatabaseExecutor db) async {
    await db.execute(
      "INSERT OR IGNORE INTO tags (id, name, type_id) VALUES ('food-type-sauce', 'sauce', 'food_type')",
    );
  }

  @override
  Future<void> down(DatabaseExecutor db) async {
    await db.execute(
      "DELETE FROM recipe_tags WHERE tag_id = 'food-type-sauce'",
    );
    await db.execute(
      "DELETE FROM tags WHERE id = 'food-type-sauce'",
    );
  }

  @override
  Future<bool> validate(DatabaseExecutor db) async {
    final result = await db.rawQuery(
      "SELECT id FROM tags WHERE id = 'food-type-sauce'",
    );
    return result.isNotEmpty;
  }
}
