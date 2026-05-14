import '../migration.dart';

/// Adds a `quantity_max` column to the `recipe_ingredients` table.
///
/// Enables range ingredient quantities (e.g. "2–3 cloves garlic").
/// `quantity_max = NULL` means a single (non-range) value — full backward
/// compatibility. The existing `quantity` column remains the primary value and
/// serves as the lower bound when a range is present.
class AddQuantityMaxMigration extends Migration {
  @override
  int get version => 110;

  @override
  String get description => 'Add quantity_max column to recipe_ingredients table';

  @override
  bool get requiresBackup => false;

  @override
  Future<void> up(DatabaseExecutor db) async {
    final cols = await db.rawQuery('PRAGMA table_info(recipe_ingredients)');
    if (cols.any((r) => r['name'] == 'quantity_max')) return;
    await db.execute(
      'ALTER TABLE recipe_ingredients ADD COLUMN quantity_max REAL',
    );
  }

  @override
  Future<void> down(DatabaseExecutor db) async {
    final cols = await db.rawQuery('PRAGMA table_info(recipe_ingredients)');
    if (!cols.any((r) => r['name'] == 'quantity_max')) return;

    await db.execute('''
      CREATE TABLE recipe_ingredients_backup(
        id TEXT PRIMARY KEY,
        recipe_id TEXT NOT NULL,
        ingredient_id TEXT NOT NULL,
        quantity REAL NOT NULL,
        notes TEXT,
        unit_override TEXT,
        custom_name TEXT,
        custom_category TEXT,
        custom_unit TEXT,
        FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE,
        FOREIGN KEY (ingredient_id) REFERENCES ingredients(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      INSERT INTO recipe_ingredients_backup
      SELECT id, recipe_id, ingredient_id, quantity, notes,
             unit_override, custom_name, custom_category, custom_unit
      FROM recipe_ingredients
    ''');
    await db.execute('DROP TABLE recipe_ingredients');
    await db.execute(
      'ALTER TABLE recipe_ingredients_backup RENAME TO recipe_ingredients',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_recipe_ingredients_recipe_id '
      'ON recipe_ingredients(recipe_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_recipe_ingredients_ingredient_id '
      'ON recipe_ingredients(ingredient_id)',
    );
  }

  @override
  Future<bool> validate(DatabaseExecutor db) async {
    final cols = await db.rawQuery('PRAGMA table_info(recipe_ingredients)');
    return cols.any((r) => r['name'] == 'quantity_max');
  }
}
