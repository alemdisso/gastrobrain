import '../migration.dart';

/// Add shopping_lists and shopping_list_items tables
///
/// This migration adds the shopping list feature tables to support
/// generating shopping lists from meal plans.
class AddShoppingListTablesMigration extends Migration {
  @override
  int get version => 4;

  @override
  String get description => 'Add shopping_lists and shopping_list_items tables';

  @override
  Duration get estimatedDuration => const Duration(seconds: 1);

  @override
  bool get requiresBackup => false; // Creating new tables is safe

  @override
  Future<void> up(DatabaseExecutor db) async {
    print('Creating shopping_lists table...');

    // Create shopping_lists table
    await db.execute('''
      CREATE TABLE shopping_lists(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        date_created INTEGER NOT NULL,
        start_date INTEGER NOT NULL,
        end_date INTEGER NOT NULL
      )
    ''');

    print('Creating shopping_list_items table...');

    // Create shopping_list_items table
    await db.execute('''
      CREATE TABLE shopping_list_items(
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

    print('Shopping list tables created successfully');
  }

  @override
  Future<void> down(DatabaseExecutor db) async {
    // Drop tables in reverse order (items first due to foreign key)
    await db.execute('DROP TABLE IF EXISTS shopping_list_items');
    await db.execute('DROP TABLE IF EXISTS shopping_lists');
    print('Shopping list tables dropped successfully');
  }

  @override
  Future<bool> validate(DatabaseExecutor db) async {
    // Verify that the shopping_lists table exists
    final tablesQuery = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('shopping_lists', 'shopping_list_items')"
    );

    if (tablesQuery.length != 2) {
      print('Validation failed: shopping list tables not found');
      return false;
    }

    // Verify shopping_lists table structure
    final shoppingListsInfo = await db.rawQuery('PRAGMA table_info(shopping_lists)');
    final expectedColumnsLists = ['id', 'name', 'date_created', 'start_date', 'end_date'];

    for (final columnName in expectedColumnsLists) {
      if (!shoppingListsInfo.any((column) => column['name'] == columnName)) {
        print('Validation failed: shopping_lists missing column $columnName');
        return false;
      }
    }

    // Verify shopping_list_items table structure
    final shoppingListItemsInfo = await db.rawQuery('PRAGMA table_info(shopping_list_items)');
    final expectedColumnsItems = ['id', 'shopping_list_id', 'ingredient_name', 'quantity', 'unit', 'category', 'is_purchased'];

    for (final columnName in expectedColumnsItems) {
      if (!shoppingListItemsInfo.any((column) => column['name'] == columnName)) {
        print('Validation failed: shopping_list_items missing column $columnName');
        return false;
      }
    }

    // Verify foreign key constraint exists
    final foreignKeys = await db.rawQuery('PRAGMA foreign_key_list(shopping_list_items)');
    if (foreignKeys.isEmpty) {
      print('Validation failed: foreign key constraint not found');
      return false;
    }

    print('Validation passed: shopping list tables created successfully');
    return true;
  }
}
