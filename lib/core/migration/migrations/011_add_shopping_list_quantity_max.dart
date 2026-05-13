import '../migration.dart';

/// Adds a `quantity_max` column to the `shopping_list_items` table.
///
/// Enables range ingredient quantities (e.g. "2–3 cloves garlic") to be
/// persisted in saved shopping lists. `quantity_max = NULL` means a single
/// (non-range) value — full backward compatibility.
class AddShoppingListQuantityMaxMigration extends Migration {
  @override
  int get version => 111;

  @override
  String get description =>
      'Add quantity_max column to shopping_list_items table';

  @override
  bool get requiresBackup => false;

  @override
  Future<void> up(DatabaseExecutor db) async {
    final cols = await db.rawQuery('PRAGMA table_info(shopping_list_items)');
    if (cols.any((r) => r['name'] == 'quantity_max')) return;
    await db.execute(
      'ALTER TABLE shopping_list_items ADD COLUMN quantity_max REAL',
    );
  }

  @override
  Future<void> down(DatabaseExecutor db) async {
    final cols = await db.rawQuery('PRAGMA table_info(shopping_list_items)');
    if (!cols.any((r) => r['name'] == 'quantity_max')) return;

    await db.execute('''
      CREATE TABLE shopping_list_items_backup(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shopping_list_id INTEGER NOT NULL,
        ingredient_name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        category TEXT NOT NULL,
        to_buy INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (shopping_list_id) REFERENCES shopping_lists(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      INSERT INTO shopping_list_items_backup
      SELECT id, shopping_list_id, ingredient_name, quantity,
             unit, category, to_buy
      FROM shopping_list_items
    ''');
    await db.execute('DROP TABLE shopping_list_items');
    await db.execute(
      'ALTER TABLE shopping_list_items_backup RENAME TO shopping_list_items',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_shopping_list_items_list_id '
      'ON shopping_list_items(shopping_list_id)',
    );
  }

  @override
  Future<bool> validate(DatabaseExecutor db) async {
    final cols = await db.rawQuery('PRAGMA table_info(shopping_list_items)');
    return cols.any((r) => r['name'] == 'quantity_max');
  }
}