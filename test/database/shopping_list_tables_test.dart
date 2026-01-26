import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gastrobrain/core/migration/migrations/004_add_shopping_list_tables.dart';
import 'package:gastrobrain/core/migration/migration.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Shopping List Tables Migration', () {
    test('creates shopping_lists table', () async {
      // Create an in-memory database
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);

      try {
        // Enable foreign keys
        await db.execute('PRAGMA foreign_keys = ON');

        // Run the migration
        final migration = AddShoppingListTablesMigration();
        final dbWrapper = DatabaseWrapper(db);
        await migration.up(dbWrapper);

        // Verify the shopping_lists table exists
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='shopping_lists'"
        );

        expect(tables.length, 1);
        expect(tables.first['name'], 'shopping_lists');
      } finally {
        await db.close();
      }
    });

    test('creates shopping_list_items table', () async {
      // Create an in-memory database
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);

      try {
        // Enable foreign keys
        await db.execute('PRAGMA foreign_keys = ON');

        // Run the migration
        final migration = AddShoppingListTablesMigration();
        final dbWrapper = DatabaseWrapper(db);
        await migration.up(dbWrapper);

        // Verify the shopping_list_items table exists
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='shopping_list_items'"
        );

        expect(tables.length, 1);
        expect(tables.first['name'], 'shopping_list_items');
      } finally {
        await db.close();
      }
    });

    test('migration validation passes after up()', () async {
      // Create an in-memory database
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);

      try {
        // Enable foreign keys
        await db.execute('PRAGMA foreign_keys = ON');

        // Run the migration
        final migration = AddShoppingListTablesMigration();
        final dbWrapper = DatabaseWrapper(db);
        await migration.up(dbWrapper);

        // Validate the migration
        final isValid = await migration.validate(dbWrapper);

        expect(isValid, isTrue);
      } finally {
        await db.close();
      }
    });

    test('foreign key constraint enforced for shopping_list_items', () async {
      // Create an in-memory database
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);

      try {
        // Enable foreign keys
        await db.execute('PRAGMA foreign_keys = ON');

        // Run the migration
        final migration = AddShoppingListTablesMigration();
        final dbWrapper = DatabaseWrapper(db);
        await migration.up(dbWrapper);

        // Try to insert an item with non-existent shopping_list_id
        // This should fail due to foreign key constraint
        expect(
          () async {
            await db.insert('shopping_list_items', {
              'shopping_list_id': 999,
              'ingredient_name': 'Test',
              'quantity': 1.0,
              'unit': 'g',
              'category': 'Test',
              'is_purchased': 0,
            });
          },
          throwsA(isA<Exception>()),
        );
      } finally {
        await db.close();
      }
    });
  });
}
