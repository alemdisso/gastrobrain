// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide DatabaseExecutor;
import 'package:gastrobrain/core/migration/migration.dart';
import 'package:gastrobrain/core/migration/migration_runner.dart';
import 'package:gastrobrain/core/migration/migrations/001_initial_schema.dart';
import 'package:gastrobrain/core/migration/migrations/003_add_marinating_time.dart';
import 'package:gastrobrain/core/migration/migrations/004_add_recipe_story.dart';
import 'package:gastrobrain/core/migration/migrations/005_add_tags.dart';
import 'package:gastrobrain/core/migration/migrations/006_add_meal_role_food_type.dart';
import 'package:gastrobrain/core/migration/migrations/007_migrate_category_to_tags.dart';
import 'package:gastrobrain/core/migration/migrations/008_add_sauce_food_type.dart';
import 'package:gastrobrain/core/migration/migrations/009_drop_recipe_category.dart';
import 'package:gastrobrain/core/migration/migrations/010_add_quantity_max.dart';
import 'package:gastrobrain/core/migration/migrations/011_add_shopping_list_quantity_max.dart';

// A deliberately broken migration used only to verify runner failure reporting.
class _BrokenMigration extends Migration {
  @override
  int get version => 200;

  @override
  String get description => 'Broken migration for sanity check';

  @override
  Future<void> up(DatabaseExecutor db) async {
    throw Exception('Intentional failure for testing');
  }

  @override
  Future<void> down(DatabaseExecutor db) async {}

  @override
  Future<bool> validate(DatabaseExecutor db) async => false;
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  // ── helpers ──────────────────────────────────────────────────────────────

  Future<Database> openEmpty() =>
      databaseFactoryFfi.openDatabase(inMemoryDatabasePath);

  Future<Set<String>> columnNames(Database db, String table) async {
    final rows = await db.rawQuery('PRAGMA table_info($table)');
    return rows.map((r) => r['name'] as String).toSet();
  }

  // Builds a realistic v108 database state:
  //   - Full 13-table schema (InitialSchemaMigration)
  //   - Migrations 003–008 applied
  //   - category column + index added (existed pre-#377, removed by migration 109)
  //   - schema_migrations seeded with v101–v108
  //   - Realistic data: 2 recipes, 2 ingredients, 3 recipe_ingredient rows
  Future<Database> buildV108Database() async {
    final db = await openEmpty();
    final wrapper = DatabaseWrapper(db);

    await InitialSchemaMigration().up(wrapper);
    await AddMarinatingTimeMigration().up(wrapper);
    await AddRecipeStoryMigration().up(wrapper);
    await AddTagsMigration().up(wrapper);
    await AddMealRoleFoodTypeMigration().up(wrapper);
    await MigrateCategoryToTagsMigration().up(wrapper);
    await AddSauceFoodTypeMigration().up(wrapper);

    // Add category column that existed pre-#377 and is removed by migration 109.
    // Guard with PRAGMA check to be safe if state bleeds across tests.
    final recipeCols = await db.rawQuery('PRAGMA table_info(recipes)');
    if (!recipeCols.any((r) => r['name'] == 'category')) {
      await db.execute(
        "ALTER TABLE recipes ADD COLUMN category TEXT DEFAULT 'uncategorized'",
      );
    }
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_recipes_category ON recipes(category)',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS schema_migrations (
        version INTEGER PRIMARY KEY,
        applied_at TEXT NOT NULL,
        description TEXT NOT NULL,
        duration_ms INTEGER NOT NULL
      )
    ''');
    for (int v = 101; v <= 108; v++) {
      await db.rawInsert(
        'INSERT OR IGNORE INTO schema_migrations '
        '(version, applied_at, description, duration_ms) VALUES (?, ?, ?, ?)',
        [v, DateTime.now().toIso8601String(), 'migration $v', 0],
      );
    }

    // FK off so we can insert linked rows without satisfying all constraints.
    await db.execute('PRAGMA foreign_keys = OFF');

    // Seed ingredients
    await db.rawInsert(
      "INSERT INTO ingredients (id, name, category) VALUES ('i-1', 'frango', 'proteína')",
    );
    await db.rawInsert(
      "INSERT INTO ingredients (id, name, category) VALUES ('i-2', 'alho', 'vegetal')",
    );

    // Seed recipes with all v108 columns.
    // recipe_ingredients uses unit_override, not a top-level unit column.
    await db.rawInsert(
      'INSERT INTO recipes '
      '(id, name, desired_frequency, created_at, difficulty, '
      'prep_time_minutes, cook_time_minutes, rating, servings, '
      'marinating_time_minutes, story, category) '
      "VALUES ('r-1', 'frango assado', 'weekly', '2025-01-01T00:00:00', "
      "2, 20, 60, 4, 4, 30, 'marinado overnight', 'main_dishes')",
    );
    await db.rawInsert(
      'INSERT INTO recipes '
      '(id, name, desired_frequency, created_at, difficulty, '
      'prep_time_minutes, cook_time_minutes, rating, servings, '
      'marinating_time_minutes, story, category) '
      "VALUES ('r-2', 'sopa de legumes', 'weekly', '2025-01-02T00:00:00', "
      "1, 10, 30, 3, 2, 0, 'sopa simples', 'soups_stews')",
    );

    // Seed recipe_ingredients — schema has unit_override, not a top-level unit column
    await db.rawInsert(
      'INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_override) '
      "VALUES ('ri-1', 'r-1', 'i-1', 1.0, 'kg')",
    );
    await db.rawInsert(
      'INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_override) '
      "VALUES ('ri-2', 'r-1', 'i-2', 3.0, 'dentes')",
    );
    await db.rawInsert(
      'INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_override) '
      "VALUES ('ri-3', 'r-2', 'i-2', 1.0, 'dentes')",
    );

    return db;
  }

  // ── Scenario 1: Populated v108 → migration sequence 109→110→111 ──────────
  //
  // Simulates an upgrade path on a device that has been running for a while:
  // realistic data already in the database, FK enforcement ON, full migration
  // sequence applied through the runner.

  group('Populated v108 → migration sequence 109→110→111', () {
    late Database db;
    late MigrationRunner runner;
    late List<MigrationResult> results;

    setUp(() async {
      db = await buildV108Database();

      // Re-enable FK enforcement as production onConfigure does.
      await db.execute('PRAGMA foreign_keys = ON');

      runner = MigrationRunner(db, [
        DropRecipeCategoryMigration(),
        AddQuantityMaxMigration(),
        AddShoppingListQuantityMaxMigration(),
      ]);
      await runner.initialize();
      results = await runner.runPendingMigrations();
    });

    tearDown(() async => db.close());

    test('all three migrations report success', () {
      expect(results.length, equals(3));
      for (final r in results) {
        expect(r.success, isTrue, reason: 'migration ${r.version} failed: ${r.error}');
      }
    });

    test('migration 109 removed the category column from recipes', () async {
      final cols = await columnNames(db, 'recipes');
      expect(cols, isNot(contains('category')));
    });

    test('migration 110 added quantity_max to recipe_ingredients', () async {
      final cols = await columnNames(db, 'recipe_ingredients');
      expect(cols, contains('quantity_max'));
    });

    test('migration 111 added quantity_max to shopping_list_items', () async {
      final cols = await columnNames(db, 'shopping_list_items');
      expect(cols, contains('quantity_max'));
    });

    test('both recipe rows are preserved after migration 109', () async {
      final rows = await db.rawQuery('SELECT id FROM recipes ORDER BY id');
      final ids = rows.map((r) => r['id'] as String).toSet();
      expect(ids, containsAll(['r-1', 'r-2']));
    });

    test('recipe data is intact after migration 109', () async {
      final rows = await db.rawQuery(
        "SELECT name, marinating_time_minutes, story FROM recipes WHERE id = 'r-1'",
      );
      expect(rows.length, equals(1));
      expect(rows.first['name'], equals('frango assado'));
      expect(rows.first['marinating_time_minutes'], equals(30));
      expect(rows.first['story'], equals('marinado overnight'));
    });

    test('both ingredient rows are preserved', () async {
      final rows = await db.rawQuery('SELECT id FROM ingredients ORDER BY id');
      final ids = rows.map((r) => r['id'] as String).toSet();
      expect(ids, containsAll(['i-1', 'i-2']));
    });

    test('all three recipe_ingredient rows are preserved', () async {
      final rows = await db.rawQuery(
        'SELECT id FROM recipe_ingredients ORDER BY id',
      );
      final ids = rows.map((r) => r['id'] as String).toSet();
      expect(ids, containsAll(['ri-1', 'ri-2', 'ri-3']));
    });

    test('FK enforcement is ON after the migration sequence', () async {
      final result = await db.rawQuery('PRAGMA foreign_keys');
      expect(result.first.values.first, equals(1));
    });
  });

  // ── Scenario 2: Runner sanity check — failure is reported, not swallowed ──
  //
  // A deliberately broken migration is wired into the runner to confirm that
  // the runner surfaces failures in its result list instead of silently
  // swallowing them. This proves the integration test above WOULD catch a
  // broken migration 109 rather than passing silently.

  group('Runner sanity check — failure is reported, not swallowed', () {
    late Database db;
    late MigrationRunner runner;

    setUp(() async {
      db = await openEmpty();

      await InitialSchemaMigration().up(DatabaseWrapper(db));

      await db.execute('''
        CREATE TABLE IF NOT EXISTS schema_migrations (
          version INTEGER PRIMARY KEY,
          applied_at TEXT NOT NULL,
          description TEXT NOT NULL,
          duration_ms INTEGER NOT NULL
        )
      ''');
      for (int v = 101; v <= 108; v++) {
        await db.rawInsert(
          'INSERT OR IGNORE INTO schema_migrations '
          '(version, applied_at, description, duration_ms) VALUES (?, ?, ?, ?)',
          [v, DateTime.now().toIso8601String(), 'migration $v', 0],
        );
      }

      runner = MigrationRunner(db, [_BrokenMigration()]);
      await runner.initialize();
    });

    tearDown(() async => db.close());

    test('broken migration causes runPendingMigrations to throw MigrationException', () async {
      await expectLater(
        runner.runPendingMigrations(),
        throwsA(isA<MigrationException>()),
      );
    });

    test('thrown MigrationException identifies the failed migration version', () async {
      try {
        await runner.runPendingMigrations();
        fail('Expected MigrationException');
      } on MigrationException catch (e) {
        expect(e.version, equals(200));
        expect(e.message, contains('Intentional failure'));
      }
    });
  });

  // ── Scenario 3: Migration error recording — schema and SQL invariants ─────
  //
  // Validates the exact table schema and SQL operations that underlie
  // hasPendingMigrationFailure() and acknowledgeMigrationFailure() in
  // DatabaseHelper. These tests lock in the invariants the production code
  // depends on without going through the DatabaseHelper singleton.

  group('Migration error recording — schema and SQL invariants', () {
    late Database db;

    // Mirrors _ensureMigrationErrorsTable in database_helper.dart.
    Future<void> ensureErrorsTable(Database db) => db.execute('''
      CREATE TABLE IF NOT EXISTS schema_migrations_errors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        failed_version INTEGER,
        error_message TEXT NOT NULL,
        occurred_at TEXT NOT NULL,
        acknowledged INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Mirrors _recordMigrationFailure in database_helper.dart.
    Future<void> recordFailure(Database db, int? version, String message) =>
        db.rawInsert(
          'INSERT INTO schema_migrations_errors '
          '(failed_version, error_message, occurred_at) VALUES (?, ?, ?)',
          [version, message, DateTime.now().toIso8601String()],
        );

    // Mirrors the SELECT in hasPendingMigrationFailure.
    Future<bool> hasPending(Database db) async {
      final rows = await db.rawQuery(
        'SELECT COUNT(*) as count FROM schema_migrations_errors WHERE acknowledged = 0',
      );
      return (rows.first['count'] as int) > 0;
    }

    // Mirrors acknowledgeMigrationFailure.
    Future<void> acknowledge(Database db) => db.execute(
          'UPDATE schema_migrations_errors SET acknowledged = 1 WHERE acknowledged = 0',
        );

    setUp(() async {
      db = await openEmpty();
      await ensureErrorsTable(db);
    });

    tearDown(() async => db.close());

    test('table creation is idempotent — safe to call on every launch', () async {
      await expectLater(ensureErrorsTable(db), completes);

      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='schema_migrations_errors'",
      );
      expect(tables.length, equals(1));
    });

    test('error row with known version stores failed_version correctly', () async {
      await recordFailure(db, 109, 'Drop category migration failed');

      final rows = await db.rawQuery('SELECT * FROM schema_migrations_errors');
      expect(rows.length, equals(1));
      expect(rows.first['failed_version'], equals(109));
      expect(rows.first['error_message'], equals('Drop category migration failed'));
    });

    test('system-level error stores null failed_version', () async {
      await recordFailure(db, null, 'DB initialisation error');

      final rows = await db.rawQuery('SELECT * FROM schema_migrations_errors');
      expect(rows.first['failed_version'], isNull);
    });

    test('new error rows default to acknowledged = 0', () async {
      await recordFailure(db, 109, 'some error');

      final rows = await db.rawQuery('SELECT acknowledged FROM schema_migrations_errors');
      expect(rows.first['acknowledged'], equals(0));
    });

    test('hasPendingMigrationFailure returns false on clean database', () async {
      expect(await hasPending(db), isFalse);
    });

    test('hasPendingMigrationFailure returns true after an error is recorded', () async {
      await recordFailure(db, 109, 'migration failed');

      expect(await hasPending(db), isTrue);
    });

    test('acknowledgeMigrationFailure marks all unacknowledged rows', () async {
      await recordFailure(db, 109, 'first failure');
      await recordFailure(db, null, 'second failure');

      await acknowledge(db);

      final unack = await db.rawQuery(
        'SELECT COUNT(*) as count FROM schema_migrations_errors WHERE acknowledged = 0',
      );
      expect(unack.first['count'], equals(0));
    });

    test('hasPendingMigrationFailure returns false after acknowledgement', () async {
      await recordFailure(db, 109, 'migration failed');
      await acknowledge(db);

      expect(await hasPending(db), isFalse);
    });

    test('acknowledgement is idempotent — safe to call twice', () async {
      await recordFailure(db, 109, 'migration failed');
      await acknowledge(db);
      await expectLater(acknowledge(db), completes);

      final rows = await db.rawQuery('SELECT acknowledged FROM schema_migrations_errors');
      expect(rows.first['acknowledged'], equals(1));
    });

    test('only unacknowledged rows are updated by acknowledgement', () async {
      await recordFailure(db, 108, 'old failure');
      await acknowledge(db);
      await recordFailure(db, 109, 'new failure');

      expect(await hasPending(db), isTrue);

      final rows = await db.rawQuery(
        'SELECT failed_version, acknowledged FROM schema_migrations_errors ORDER BY id',
      );
      expect(rows[0]['acknowledged'], equals(1));
      expect(rows[1]['acknowledged'], equals(0));
    });
  });
}
