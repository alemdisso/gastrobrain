// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gastrobrain/core/migration/migration.dart';
import 'package:gastrobrain/core/migration/migration_runner.dart';
import 'package:gastrobrain/core/migration/migrations/001_initial_schema.dart';
import 'package:gastrobrain/core/migration/migrations/003_add_marinating_time.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  // ── helpers ──────────────────────────────────────────────────────────────

  Future<Database> openEmpty() =>
      databaseFactoryFfi.openDatabase(inMemoryDatabasePath);

  Future<Set<String>> tableNames(Database db) async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
    );
    return rows.map((r) => r['name'] as String).toSet();
  }

  Future<Set<String>> columnNames(Database db, String table) async {
    final rows = await db.rawQuery('PRAGMA table_info($table)');
    return rows.map((r) => r['name'] as String).toSet();
  }

  // ── Scenario 1: Fresh install ─────────────────────────────────────────────
  //
  // Tests InitialSchemaMigration.up() in isolation on an empty in-memory DB.
  // This mirrors what _onCreate does for real fresh installs.

  group('Scenario 1 — Fresh install', () {
    late Database db;
    late InitialSchemaMigration migration;
    late DatabaseWrapper wrapper;

    setUp(() async {
      db = await openEmpty();
      migration = InitialSchemaMigration();
      wrapper = DatabaseWrapper(db);
    });

    tearDown(() async => db.close());

    test('creates all 13 tables', () async {
      await migration.up(wrapper);

      final tables = await tableNames(db);
      const expected = {
        'recipes',
        'ingredients',
        'recipe_ingredients',
        'meals',
        'meal_recipes',
        'meal_ingredients',
        'meal_plans',
        'meal_plan_items',
        'meal_plan_item_recipes',
        'meal_plan_item_ingredients',
        'shopping_lists',
        'shopping_list_items',
        'recommendation_history',
      };
      expect(tables, containsAll(expected));
    });

    test('shopping_list_items has to_buy column, not is_purchased', () async {
      await migration.up(wrapper);

      final cols = await columnNames(db, 'shopping_list_items');
      expect(cols, contains('to_buy'));
      expect(cols, isNot(contains('is_purchased')));
    });

    test('to_buy defaults to 1 (items need buying by default)', () async {
      await migration.up(wrapper);

      // Insert a minimal shopping list to satisfy the FK
      await db.execute('''
        INSERT INTO shopping_lists (name, date_created, start_date, end_date)
        VALUES ('test', 0, 0, 0)
      ''');
      await db.execute('''
        INSERT INTO shopping_list_items
          (shopping_list_id, ingredient_name, quantity, unit, category)
        VALUES (1, 'onion', 1.0, 'unit', 'vegetable')
      ''');

      final row = await db.rawQuery(
        'SELECT to_buy FROM shopping_list_items LIMIT 1',
      );
      expect(row.first['to_buy'], equals(1));
    });

    test('recipes has servings column', () async {
      await migration.up(wrapper);

      final cols = await columnNames(db, 'recipes');
      expect(cols, contains('servings'));
    });

    test('recipes has instructions column', () async {
      await migration.up(wrapper);

      final cols = await columnNames(db, 'recipes');
      expect(cols, contains('instructions'));
    });

    test('meals has meal_type column', () async {
      await migration.up(wrapper);

      final cols = await columnNames(db, 'meals');
      expect(cols, contains('meal_type'));
    });

    test('meal_plan_items has planned_servings column', () async {
      await migration.up(wrapper);

      final cols = await columnNames(db, 'meal_plan_items');
      expect(cols, contains('planned_servings'));
    });

    test('meal_plan_item_ingredients has quantity and unit columns', () async {
      await migration.up(wrapper);

      final cols = await columnNames(db, 'meal_plan_item_ingredients');
      expect(cols, containsAll(['quantity', 'unit']));
    });

    test('meal_ingredients has quantity and unit columns', () async {
      await migration.up(wrapper);

      final cols = await columnNames(db, 'meal_ingredients');
      expect(cols, containsAll(['quantity', 'unit']));
    });

    test('meal_plans has last_cooked_at column', () async {
      await migration.up(wrapper);

      final cols = await columnNames(db, 'meal_plans');
      expect(cols, contains('last_cooked_at'));
    });

    test('shopping_lists has stale-detection columns', () async {
      await migration.up(wrapper);

      final cols = await columnNames(db, 'shopping_lists');
      expect(cols, containsAll(['meal_plan_modified_at', 'meal_plan_cooked_at']));
    });

    test('validate() returns true after up()', () async {
      await migration.up(wrapper);

      expect(await migration.validate(wrapper), isTrue);
    });

    test('validate() returns false on empty database', () async {
      expect(await migration.validate(wrapper), isFalse);
    });
  });

  // ── Scenario 3: Already-migrated database ─────────────────────────────────
  //
  // Simulates a device that already ran migrations 1-11. The registry now
  // only contains version 1, so currentVersion (11) >= latestVersion (1)
  // and no migrations should run.

  group('Scenario 3 — Already-migrated database', () {
    late Database db;
    late MigrationRunner runner;

    setUp(() async {
      db = await openEmpty();

      // Build the complete schema as if migrations 1-11 already ran
      final migration = InitialSchemaMigration();
      await migration.up(DatabaseWrapper(db));

      // Seed schema_migrations with versions 1-11 (existing user's DB)
      await db.execute('''
        CREATE TABLE schema_migrations (
          version INTEGER PRIMARY KEY,
          applied_at TEXT NOT NULL,
          description TEXT NOT NULL,
          duration_ms INTEGER NOT NULL
        )
      ''');
      for (int v = 1; v <= 11; v++) {
        await db.rawInsert(
          'INSERT INTO schema_migrations (version, applied_at, description, duration_ms) '
          'VALUES (?, ?, ?, ?)',
          [v, DateTime.now().toIso8601String(), 'migration $v', 0],
        );
      }

      // Wire up the runner exactly as DatabaseHelper does post-consolidation
      runner = MigrationRunner(db, [InitialSchemaMigration()]);
      await runner.initialize(); // no-op: table already exists
    });

    tearDown(() async => db.close());

    test('currentVersion is 11 (highest version in schema_migrations)', () async {
      expect(await runner.getCurrentVersion(), equals(11));
    });

    test('latestVersion is 1 (only migration in registry)', () {
      expect(runner.getLatestVersion(), equals(1));
    });

    test('needsMigration() returns false', () async {
      expect(await runner.needsMigration(), isFalse);
    });

    test('runPendingMigrations() returns empty list', () async {
      final results = await runner.runPendingMigrations();
      expect(results, isEmpty);
    });

    test('all 13 tables are still present after runner initializes', () async {
      await runner.runPendingMigrations();

      final tables = await tableNames(db);
      const expected = {
        'recipes', 'meals', 'ingredients', 'recipe_ingredients',
        'meal_plans', 'meal_plan_items', 'meal_plan_item_recipes',
        'meal_recipes', 'recommendation_history',
        'shopping_lists', 'shopping_list_items',
        'meal_plan_item_ingredients', 'meal_ingredients',
      };
      expect(tables, containsAll(expected));
    });

    test('existing data is preserved after runner initializes', () async {
      // Insert a recipe before running the runner
      await db.execute('''
        INSERT INTO recipes
          (id, name, desired_frequency, created_at, difficulty,
           prep_time_minutes, cook_time_minutes, rating, servings)
        VALUES ('r-1', 'frango assado', 'weekly', '2025-01-01T00:00:00', 2,
                20, 60, 4, 4)
      ''');

      await runner.runPendingMigrations();

      final rows = await db.rawQuery(
        "SELECT name FROM recipes WHERE id = 'r-1'",
      );
      expect(rows.length, equals(1));
      expect(rows.first['name'], equals('frango assado'));
    });
  });

  // ── Migration 003: AddMarinatingTimeMigration ─────────────────────────────

  group('Migration 003 — AddMarinatingTimeMigration', () {
    late Database db;
    late AddMarinatingTimeMigration migration;
    late DatabaseWrapper wrapper;

    setUp(() async {
      db = await openEmpty();
      migration = AddMarinatingTimeMigration();
      wrapper = DatabaseWrapper(db);
      // Apply initial schema first so the recipes table exists
      await InitialSchemaMigration().up(wrapper);
    });

    tearDown(() async => db.close());

    test('up() adds marinating_time_minutes column to recipes table', () async {
      await migration.up(wrapper);

      final cols = await db.rawQuery('PRAGMA table_info(recipes)');
      final names = cols.map((r) => r['name'] as String).toSet();
      expect(names, contains('marinating_time_minutes'));
    });

    test('existing rows have marinating_time_minutes defaulting to 0', () async {
      // Insert a recipe before the migration runs
      await db.rawInsert(
        "INSERT INTO recipes (id, name, desired_frequency, created_at, difficulty, "
        "prep_time_minutes, cook_time_minutes, rating, servings) "
        "VALUES ('r-1', 'frango grelhado', 'weekly', '2025-01-01T00:00:00', 2, 10, 20, 4, 4)",
      );

      await migration.up(wrapper);

      final rows = await db.rawQuery(
        'SELECT marinating_time_minutes FROM recipes WHERE id = ?',
        ['r-1'],
      );
      expect(rows.length, equals(1));
      expect(rows.first['marinating_time_minutes'], equals(0));
    });

    test('validate() returns true after up()', () async {
      await migration.up(wrapper);

      expect(await migration.validate(wrapper), isTrue);
    });

    test('down() removes marinating_time_minutes column', () async {
      await migration.up(wrapper);
      await migration.down(wrapper);

      final cols = await db.rawQuery('PRAGMA table_info(recipes)');
      final names = cols.map((r) => r['name'] as String).toSet();
      expect(names, isNot(contains('marinating_time_minutes')));
      // Original columns still present after rollback
      expect(names, containsAll(['prep_time_minutes', 'cook_time_minutes', 'servings']));
    });
  });
}
