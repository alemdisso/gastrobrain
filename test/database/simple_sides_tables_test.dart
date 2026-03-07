import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gastrobrain/core/migration/migrations/010_add_simple_sides_tables.dart';
import 'package:gastrobrain/core/migration/migration.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('AddSimpleSidesMigration (v10)', () {
    late Database db;
    late AddSimpleSidesMigration migration;
    late DatabaseWrapper dbWrapper;

    setUp(() async {
      db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      await db.execute('PRAGMA foreign_keys = ON');
      migration = AddSimpleSidesMigration();
      dbWrapper = DatabaseWrapper(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('version is 10', () {
      expect(migration.version, equals(10));
    });

    test('requiresBackup is false', () {
      expect(migration.requiresBackup, isFalse);
    });

    // ─── up() ───────────────────────────────────────────────────────────────

    test('creates meal_plan_item_ingredients table', () async {
      await migration.up(dbWrapper);

      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' "
        "AND name='meal_plan_item_ingredients'",
      );
      expect(tables.length, equals(1));
    });

    test('creates meal_ingredients table', () async {
      await migration.up(dbWrapper);

      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' "
        "AND name='meal_ingredients'",
      );
      expect(tables.length, equals(1));
    });

    test('meal_plan_item_ingredients has all required columns', () async {
      await migration.up(dbWrapper);

      final cols =
          await db.rawQuery('PRAGMA table_info(meal_plan_item_ingredients)');
      final names = cols.map((c) => c['name'] as String).toSet();

      expect(names, containsAll(['id', 'meal_plan_item_id', 'ingredient_id', 'custom_name', 'notes']));
    });

    test('meal_ingredients has all required columns', () async {
      await migration.up(dbWrapper);

      final cols = await db.rawQuery('PRAGMA table_info(meal_ingredients)');
      final names = cols.map((c) => c['name'] as String).toSet();

      expect(names, containsAll(['id', 'meal_id', 'ingredient_id', 'custom_name', 'notes']));
    });

    test('ingredient_id is nullable in meal_plan_item_ingredients', () async {
      await migration.up(dbWrapper);

      final cols =
          await db.rawQuery('PRAGMA table_info(meal_plan_item_ingredients)');
      final ingCol = cols.firstWhere((c) => c['name'] == 'ingredient_id');
      // notnull == 0 means nullable
      expect(ingCol['notnull'], equals(0));
    });

    test('ingredient_id is nullable in meal_ingredients', () async {
      await migration.up(dbWrapper);

      final cols = await db.rawQuery('PRAGMA table_info(meal_ingredients)');
      final ingCol = cols.firstWhere((c) => c['name'] == 'ingredient_id');
      expect(ingCol['notnull'], equals(0));
    });

    test('up() is idempotent — safe to call twice', () async {
      await migration.up(dbWrapper);
      // Should not throw on second call (CREATE TABLE IF NOT EXISTS)
      await expectLater(migration.up(dbWrapper), completes);
    });

    // ─── validate() ─────────────────────────────────────────────────────────

    test('validate() returns true after up()', () async {
      await migration.up(dbWrapper);

      final isValid = await migration.validate(dbWrapper);
      expect(isValid, isTrue);
    });

    test('validate() returns false before up()', () async {
      final isValid = await migration.validate(dbWrapper);
      expect(isValid, isFalse);
    });

    // ─── down() ─────────────────────────────────────────────────────────────

    test('down() drops meal_plan_item_ingredients', () async {
      await migration.up(dbWrapper);
      await migration.down(dbWrapper);

      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' "
        "AND name='meal_plan_item_ingredients'",
      );
      expect(tables, isEmpty);
    });

    test('down() drops meal_ingredients', () async {
      await migration.up(dbWrapper);
      await migration.down(dbWrapper);

      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' "
        "AND name='meal_ingredients'",
      );
      expect(tables, isEmpty);
    });

    test('down() is idempotent — safe to call twice', () async {
      await migration.up(dbWrapper);
      await migration.down(dbWrapper);
      await expectLater(migration.down(dbWrapper), completes);
    });

    // ─── up → down → up cycle ───────────────────────────────────────────────

    test('supports up → down → up cycle', () async {
      // First up
      await migration.up(dbWrapper);
      expect(await migration.validate(dbWrapper), isTrue);

      // Down
      await migration.down(dbWrapper);

      var tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' "
        "AND name IN ('meal_plan_item_ingredients', 'meal_ingredients')",
      );
      expect(tables, isEmpty);

      // Second up
      await migration.up(dbWrapper);
      expect(await migration.validate(dbWrapper), isTrue);
    });

    // ─── data insertion ──────────────────────────────────────────────────────

    // Helper: create prerequisite tables and seed parent rows for FK satisfaction
    Future<void> createParentTablesWithRows() async {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ingredients(
          id TEXT PRIMARY KEY, name TEXT NOT NULL,
          category TEXT NOT NULL, unit TEXT, protein_type TEXT, notes TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS meal_plan_items(
          id TEXT PRIMARY KEY, meal_plan_id TEXT NOT NULL,
          planned_date TEXT NOT NULL, meal_type TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS meals(
          id TEXT PRIMARY KEY, cooked_at TEXT NOT NULL, servings INTEGER NOT NULL
        )
      ''');
      // Seed parent rows so NOT NULL FKs are satisfied
      await db.insert('meal_plan_items', {
        'id': 'item-1',
        'meal_plan_id': 'plan-1',
        'planned_date': '2026-03-04',
        'meal_type': 'dinner',
      });
      await db.insert('meals', {
        'id': 'meal-1',
        'cooked_at': '2026-03-04T19:00:00.000',
        'servings': 2,
      });
    }

    test('accepts row with null ingredient_id (free-text) in meal_plan_item_ingredients', () async {
      await createParentTablesWithRows();
      await migration.up(dbWrapper);

      await expectLater(
        db.insert('meal_plan_item_ingredients', {
          'id': 'side-1',
          'meal_plan_item_id': 'item-1',
          'ingredient_id': null,
          'custom_name': 'Broccoli',
          'notes': null,
        }),
        completes,
      );
    });

    test('accepts row with null ingredient_id (free-text) in meal_ingredients', () async {
      await createParentTablesWithRows();
      await migration.up(dbWrapper);

      await expectLater(
        db.insert('meal_ingredients', {
          'id': 'mside-1',
          'meal_id': 'meal-1',
          'ingredient_id': null,
          'custom_name': 'Rice',
          'notes': 'white rice',
        }),
        completes,
      );
    });
  });
}
