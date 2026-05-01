import '../migration.dart';

/// One-shot data migration: maps existing recipe category values to
/// meal_role and food_type tags in recipe_tags.
///
/// Mapping (from issue #334):
///   main_dishes    → meal-role-main-dish
///   side_dishes    → meal-role-side-dish
///   complete_meals → meal-role-complete-meal
///   desserts       → meal-role-dessert
///   snacks         → meal-role-snack
///   sandwiches     → food-type-sandwich
///   salads         → food-type-salad
///   soups_stews    → food-type-soup  (best-effort)
///
/// Intentionally skipped (ambiguous or no clean mapping):
///   breakfast_items, sauces, dips, pickles_fermented, uncategorized
///
/// All INSERTs use OR IGNORE so re-running up() is safe.
/// down() is a no-op — migrated entries cannot be distinguished from
/// manually-added tags after the fact.
class MigrateCategoryToTagsMigration extends Migration {
  @override
  int get version => 7;

  @override
  String get description => 'Migrate recipe category values to meal_role and food_type tags';

  @override
  bool get requiresBackup => false;

  static const _mapping = [
    ('main_dishes', 'meal-role-main-dish'),
    ('side_dishes', 'meal-role-side-dish'),
    ('complete_meals', 'meal-role-complete-meal'),
    ('desserts', 'meal-role-dessert'),
    ('snacks', 'meal-role-snack'),
    ('sandwiches', 'food-type-sandwich'),
    ('salads', 'food-type-salad'),
    ('soups_stews', 'food-type-soup'),
  ];

  @override
  Future<void> up(DatabaseExecutor db) async {
    for (final (category, tagId) in _mapping) {
      await db.execute(
        'INSERT OR IGNORE INTO recipe_tags (recipe_id, tag_id) '
        'SELECT id, ? FROM recipes WHERE category = ?',
        [tagId, category],
      );
    }
  }

  @override
  Future<void> down(DatabaseExecutor db) async {
    // Intentional no-op: inserted entries are indistinguishable from
    // manually-added tags and cannot be safely reversed.
  }

  @override
  Future<bool> validate(DatabaseExecutor db) async {
    for (final (category, tagId) in _mapping) {
      final rows = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM recipes '
        'WHERE category = ? AND id NOT IN ('
        '  SELECT recipe_id FROM recipe_tags WHERE tag_id = ?'
        ')',
        [category, tagId],
      );
      if ((rows.first['cnt'] as int) > 0) return false;
    }
    return true;
  }
}
