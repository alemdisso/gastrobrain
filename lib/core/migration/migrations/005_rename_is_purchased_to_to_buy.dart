import '../migration.dart';

/// Rename is_purchased column to to_buy and invert values
///
/// This migration changes the shopping list logic from tracking "purchased"
/// items to tracking "to buy" items. The checkbox now indicates whether an
/// item needs to be purchased (checked = to buy, unchecked = not needed).
class RenameIsPurchasedToToBuyMigration extends Migration {
  @override
  int get version => 5;

  @override
  String get description => 'Rename is_purchased to to_buy and invert values';

  @override
  Duration get estimatedDuration => const Duration(seconds: 1);

  @override
  bool get requiresBackup => true; // Modifying existing data

  @override
  Future<void> up(DatabaseExecutor db) async {
    print('Renaming is_purchased column to to_buy...');

    // SQLite doesn't support direct column rename with value transformation,
    // so we need to:
    // 1. Add new column with default value
    // 2. Copy inverted values from old column
    // 3. Drop old column
    // 4. This requires recreating the table

    // Create temporary table with new schema
    await db.execute('''
      CREATE TABLE shopping_list_items_new(
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

    // Copy data with inverted values (is_purchased = 0 becomes to_buy = 1, and vice versa)
    await db.execute('''
      INSERT INTO shopping_list_items_new (
        id, shopping_list_id, ingredient_name, quantity, unit, category, to_buy
      )
      SELECT
        id, shopping_list_id, ingredient_name, quantity, unit, category,
        CASE WHEN is_purchased = 1 THEN 0 ELSE 1 END
      FROM shopping_list_items
    ''');

    // Drop old table
    await db.execute('DROP TABLE shopping_list_items');

    // Rename new table to original name
    await db.execute('ALTER TABLE shopping_list_items_new RENAME TO shopping_list_items');

    print('Column renamed and values inverted successfully');
  }

  @override
  Future<void> down(DatabaseExecutor db) async {
    print('Reverting to_buy column back to is_purchased...');

    // Create temporary table with old schema
    await db.execute('''
      CREATE TABLE shopping_list_items_new(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shopping_list_id INTEGER NOT NULL,
        ingredient_name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        category TEXT NOT NULL,
        is_purchased INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (shopping_list_id) REFERENCES shopping_lists(id) ON DELETE CASCADE
      )
    ''');

    // Copy data with inverted values back
    await db.execute('''
      INSERT INTO shopping_list_items_new (
        id, shopping_list_id, ingredient_name, quantity, unit, category, is_purchased
      )
      SELECT
        id, shopping_list_id, ingredient_name, quantity, unit, category,
        CASE WHEN to_buy = 1 THEN 0 ELSE 1 END
      FROM shopping_list_items
    ''');

    // Drop current table
    await db.execute('DROP TABLE shopping_list_items');

    // Rename new table to original name
    await db.execute('ALTER TABLE shopping_list_items_new RENAME TO shopping_list_items');

    print('Column reverted successfully');
  }

  @override
  Future<bool> validate(DatabaseExecutor db) async {
    // Verify shopping_list_items table structure
    final tableInfo = await db.rawQuery('PRAGMA table_info(shopping_list_items)');

    // Check that to_buy column exists
    final hasToBuyColumn = tableInfo.any((column) => column['name'] == 'to_buy');
    if (!hasToBuyColumn) {
      print('Validation failed: to_buy column not found');
      return false;
    }

    // Check that is_purchased column no longer exists
    final hasIsPurchasedColumn = tableInfo.any((column) => column['name'] == 'is_purchased');
    if (hasIsPurchasedColumn) {
      print('Validation failed: is_purchased column still exists');
      return false;
    }

    print('Validation passed: column renamed successfully');
    return true;
  }
}
