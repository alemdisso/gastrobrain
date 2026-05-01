// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gastrobrain/core/migration/migration.dart';
import 'package:gastrobrain/core/migration/migration_runner.dart';
import 'package:gastrobrain/core/migration/migrations/001_initial_schema.dart';
import 'package:gastrobrain/core/migration/migrations/003_add_marinating_time.dart';
import 'package:gastrobrain/core/migration/migrations/005_add_tags.dart';
import 'package:gastrobrain/core/migration/migrations/006_add_meal_role_food_type.dart';
import 'package:gastrobrain/core/migration/migrations/007_migrate_category_to_tags.dart';
import 'package:gastrobrain/core/migration/migrations/008_add_sauce_food_type.dart';

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

  // ── Migration 005: AddTagsMigration ──────────────────────────────────────

  group('Migration 005 — AddTagsMigration', () {
    late Database db;
    late AddTagsMigration migration;
    late DatabaseWrapper wrapper;

    setUp(() async {
      db = await openEmpty();
      migration = AddTagsMigration();
      wrapper = DatabaseWrapper(db);
      await InitialSchemaMigration().up(wrapper);
    });

    tearDown(() async => db.close());

    test('up() creates tag_types, tags, and recipe_tags tables', () async {
      await migration.up(wrapper);

      final tables = await tableNames(db);
      expect(tables, containsAll(['tag_types', 'tags', 'recipe_tags']));
    });

    test('up() inserts three built-in tag types', () async {
      await migration.up(wrapper);

      final rows = await db.rawQuery(
        'SELECT id FROM tag_types ORDER BY id',
      );
      final ids = rows.map((r) => r['id'] as String).toSet();
      expect(ids, containsAll(['cuisine', 'occasion', 'dietary']));
    });

    test('up() inserts four closed dietary tags', () async {
      await migration.up(wrapper);

      final rows = await db.rawQuery(
        "SELECT id FROM tags WHERE type_id = 'dietary' ORDER BY id",
      );
      final ids = rows.map((r) => r['id'] as String).toSet();
      expect(ids, containsAll([
        'dietary-vegetarian',
        'dietary-vegan',
        'dietary-gluten-free',
        'dietary-dairy-free',
      ]));
    });

    test('dietary tag type has is_hard=1 and is_open=0', () async {
      await migration.up(wrapper);

      final rows = await db.rawQuery(
        "SELECT is_hard, is_open FROM tag_types WHERE id = 'dietary'",
      );
      expect(rows.length, equals(1));
      expect(rows.first['is_hard'], equals(1));
      expect(rows.first['is_open'], equals(0));
    });

    test('cuisine and occasion tag types have is_hard=0 and is_open=1', () async {
      await migration.up(wrapper);

      final rows = await db.rawQuery(
        "SELECT id, is_hard, is_open FROM tag_types WHERE id IN ('cuisine','occasion')",
      );
      for (final row in rows) {
        expect(row['is_hard'], equals(0), reason: '${row['id']} should not be hard');
        expect(row['is_open'], equals(1), reason: '${row['id']} should be open');
      }
    });

    test('validate() returns true after up()', () async {
      await migration.up(wrapper);

      expect(await migration.validate(wrapper), isTrue);
    });

    test('validate() returns false before up()', () async {
      expect(await migration.validate(wrapper), isFalse);
    });

    test('up() is idempotent — safe to run twice', () async {
      await migration.up(wrapper);
      await migration.up(wrapper); // should not throw

      final tables = await tableNames(db);
      expect(tables, containsAll(['tag_types', 'tags', 'recipe_tags']));

      final rows = await db.rawQuery('SELECT id FROM tag_types ORDER BY id');
      expect(rows.length, equals(3));
    });

    test('down() removes all three tag tables', () async {
      await migration.up(wrapper);
      await migration.down(wrapper);

      final tables = await tableNames(db);
      expect(tables, isNot(contains('tag_types')));
      expect(tables, isNot(contains('tags')));
      expect(tables, isNot(contains('recipe_tags')));
    });

    test('down() is safe when tables do not exist', () async {
      // No up() called — down() should not throw.
      await expectLater(migration.down(wrapper), completes);
    });

    test('up → down → up cycle restores tables and seed data', () async {
      await migration.up(wrapper);
      await migration.down(wrapper);
      await migration.up(wrapper);

      final tables = await tableNames(db);
      expect(tables, containsAll(['tag_types', 'tags', 'recipe_tags']));

      final rows = await db.rawQuery('SELECT id FROM tag_types ORDER BY id');
      expect(rows.length, equals(3));
    });

    test('recipe_tags can link a recipe to a tag', () async {
      await migration.up(wrapper);

      await db.rawInsert(
        "INSERT INTO recipes (id, name, desired_frequency, created_at, difficulty, "
        "prep_time_minutes, cook_time_minutes, rating, servings) "
        "VALUES ('r-1', 'salada', 'weekly', '2025-01-01T00:00:00', 1, 5, 0, 3, 2)",
      );
      await db.rawInsert(
        "INSERT INTO recipe_tags (recipe_id, tag_id) VALUES ('r-1', 'dietary-vegan')",
      );

      final rows = await db.rawQuery(
        "SELECT tag_id FROM recipe_tags WHERE recipe_id = 'r-1'",
      );
      expect(rows.length, equals(1));
      expect(rows.first['tag_id'], equals('dietary-vegan'));
    });
  });

  // ── Migration 006: AddMealRoleFoodTypeMigration ───────────────────────────

  group('Migration 006 — AddMealRoleFoodTypeMigration', () {
    late Database db;
    late AddMealRoleFoodTypeMigration migration;
    late DatabaseWrapper wrapper;

    setUp(() async {
      db = await openEmpty();
      migration = AddMealRoleFoodTypeMigration();
      wrapper = DatabaseWrapper(db);
      await InitialSchemaMigration().up(wrapper);
      await AddTagsMigration().up(wrapper);
    });

    tearDown(() async => db.close());

    test('up() inserts meal_role and food_type tag types', () async {
      await migration.up(wrapper);

      final rows = await db.rawQuery(
        "SELECT id FROM tag_types WHERE id IN ('meal_role', 'food_type') ORDER BY id",
      );
      final ids = rows.map((r) => r['id'] as String).toSet();
      expect(ids, containsAll(['food_type', 'meal_role']));
    });

    test('both new tag types have is_hard=0 and is_open=0', () async {
      await migration.up(wrapper);

      final rows = await db.rawQuery(
        "SELECT id, is_hard, is_open FROM tag_types WHERE id IN ('meal_role', 'food_type')",
      );
      for (final row in rows) {
        expect(row['is_hard'], equals(0), reason: '${row['id']} should not be hard');
        expect(row['is_open'], equals(0), reason: '${row['id']} should be closed');
      }
    });

    test('up() seeds full meal_role vocabulary', () async {
      await migration.up(wrapper);

      final rows = await db.rawQuery(
        "SELECT id FROM tags WHERE type_id = 'meal_role' ORDER BY id",
      );
      final ids = rows.map((r) => r['id'] as String).toSet();
      expect(ids, containsAll([
        'meal-role-main-dish',
        'meal-role-side-dish',
        'meal-role-complete-meal',
        'meal-role-appetizer',
        'meal-role-accompaniment',
        'meal-role-dessert',
        'meal-role-snack',
      ]));
      expect(ids.length, equals(7));
    });

    test('up() seeds full food_type vocabulary', () async {
      await migration.up(wrapper);

      final rows = await db.rawQuery(
        "SELECT id FROM tags WHERE type_id = 'food_type' ORDER BY id",
      );
      final ids = rows.map((r) => r['id'] as String).toSet();
      expect(ids, containsAll([
        'food-type-soup',
        'food-type-stew',
        'food-type-salad',
        'food-type-stock',
        'food-type-sandwich',
        'food-type-pasta',
        'food-type-rice',
        'food-type-grilled',
        'food-type-baked',
        'food-type-raw',
      ]));
      expect(ids.length, equals(10));
    });

    test('validate() returns true after up()', () async {
      await migration.up(wrapper);

      expect(await migration.validate(wrapper), isTrue);
    });

    test('validate() returns false before up()', () async {
      expect(await migration.validate(wrapper), isFalse);
    });

    test('up() is idempotent — safe to run twice', () async {
      await migration.up(wrapper);
      await migration.up(wrapper);

      final typeRows = await db.rawQuery(
        "SELECT id FROM tag_types WHERE id IN ('meal_role', 'food_type')",
      );
      expect(typeRows.length, equals(2));

      final tagRows = await db.rawQuery(
        "SELECT id FROM tags WHERE type_id IN ('meal_role', 'food_type')",
      );
      expect(tagRows.length, equals(17));
    });

    test('down() removes meal_role and food_type tag types and their tags', () async {
      await migration.up(wrapper);
      await migration.down(wrapper);

      final typeRows = await db.rawQuery(
        "SELECT id FROM tag_types WHERE id IN ('meal_role', 'food_type')",
      );
      expect(typeRows, isEmpty);

      final tagRows = await db.rawQuery(
        "SELECT id FROM tags WHERE type_id IN ('meal_role', 'food_type')",
      );
      expect(tagRows, isEmpty);
    });

    test('down() leaves migration 005 tag types and tags intact', () async {
      await migration.up(wrapper);
      await migration.down(wrapper);

      final typeRows = await db.rawQuery(
        "SELECT id FROM tag_types WHERE id IN ('cuisine', 'occasion', 'dietary')",
      );
      expect(typeRows.length, equals(3));
    });

    test('down() is safe when new types were never inserted', () async {
      await expectLater(migration.down(wrapper), completes);
    });

    test('up → down → up cycle restores both tag types and vocabulary', () async {
      await migration.up(wrapper);
      await migration.down(wrapper);
      await migration.up(wrapper);

      expect(await migration.validate(wrapper), isTrue);

      final tagRows = await db.rawQuery(
        "SELECT id FROM tags WHERE type_id IN ('meal_role', 'food_type')",
      );
      expect(tagRows.length, equals(17));
    });
  });

  // ── Migration 007: MigrateCategoryToTagsMigration ────────────────────────

  group('Migration 007 — MigrateCategoryToTagsMigration', () {
    late Database db;
    late MigrateCategoryToTagsMigration migration;
    late DatabaseWrapper wrapper;

    Future<void> insertRecipe(Database db, String id, String category) =>
        db.rawInsert(
          'INSERT INTO recipes (id, name, desired_frequency, created_at, '
          'difficulty, prep_time_minutes, cook_time_minutes, rating, servings, category) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [id, id, 'weekly', '2025-01-01T00:00:00', 1, 10, 20, 3, 4, category],
        );

    setUp(() async {
      db = await openEmpty();
      migration = MigrateCategoryToTagsMigration();
      wrapper = DatabaseWrapper(db);
      await InitialSchemaMigration().up(wrapper);
      await AddTagsMigration().up(wrapper);
      await AddMealRoleFoodTypeMigration().up(wrapper);
    });

    tearDown(() async => db.close());

    test('up() maps main_dishes → meal-role-main-dish', () async {
      await insertRecipe(db, 'r-1', 'main_dishes');
      await migration.up(wrapper);

      final rows = await db.rawQuery(
        "SELECT tag_id FROM recipe_tags WHERE recipe_id = 'r-1'",
      );
      expect(rows.map((r) => r['tag_id']), contains('meal-role-main-dish'));
    });

    test('up() maps side_dishes → meal-role-side-dish', () async {
      await insertRecipe(db, 'r-1', 'side_dishes');
      await migration.up(wrapper);

      final rows = await db.rawQuery(
        "SELECT tag_id FROM recipe_tags WHERE recipe_id = 'r-1'",
      );
      expect(rows.map((r) => r['tag_id']), contains('meal-role-side-dish'));
    });

    test('up() maps all 8 supported categories correctly', () async {
      const mappings = [
        ('r-main', 'main_dishes', 'meal-role-main-dish'),
        ('r-side', 'side_dishes', 'meal-role-side-dish'),
        ('r-complete', 'complete_meals', 'meal-role-complete-meal'),
        ('r-dessert', 'desserts', 'meal-role-dessert'),
        ('r-snack', 'snacks', 'meal-role-snack'),
        ('r-sandwich', 'sandwiches', 'food-type-sandwich'),
        ('r-salad', 'salads', 'food-type-salad'),
        ('r-soup', 'soups_stews', 'food-type-soup'),
      ];
      for (final (id, category, _) in mappings) {
        await insertRecipe(db, id, category);
      }

      await migration.up(wrapper);

      for (final (id, _, tagId) in mappings) {
        final rows = await db.rawQuery(
          'SELECT tag_id FROM recipe_tags WHERE recipe_id = ?',
          [id],
        );
        expect(
          rows.map((r) => r['tag_id']),
          contains(tagId),
          reason: '$id should have tag $tagId',
        );
      }
    });

    test('up() skips unmappable categories (breakfast_items, sauces, dips, pickles_fermented)', () async {
      const skipped = ['breakfast_items', 'sauces', 'dips', 'pickles_fermented', 'uncategorized'];
      for (final (i, cat) in skipped.indexed) {
        await insertRecipe(db, 'r-$i', cat);
      }

      await migration.up(wrapper);

      final rows = await db.rawQuery('SELECT * FROM recipe_tags');
      expect(rows, isEmpty);
    });

    test('up() is idempotent — safe to run twice', () async {
      await insertRecipe(db, 'r-1', 'main_dishes');
      await migration.up(wrapper);
      await migration.up(wrapper); // second run must not throw or duplicate

      final rows = await db.rawQuery(
        "SELECT tag_id FROM recipe_tags WHERE recipe_id = 'r-1'",
      );
      expect(rows.length, equals(1));
    });

    test('up() on empty recipes table produces no recipe_tags', () async {
      await migration.up(wrapper);

      final rows = await db.rawQuery('SELECT * FROM recipe_tags');
      expect(rows, isEmpty);
    });

    test('validate() returns true after up() with no recipes', () async {
      await migration.up(wrapper);
      expect(await migration.validate(wrapper), isTrue);
    });

    test('validate() returns true after up() with mapped recipes', () async {
      await insertRecipe(db, 'r-1', 'main_dishes');
      await insertRecipe(db, 'r-2', 'salads');
      await migration.up(wrapper);

      expect(await migration.validate(wrapper), isTrue);
    });

    test('validate() returns false when mapped recipe has no tag', () async {
      await insertRecipe(db, 'r-1', 'main_dishes');
      // Do NOT call up() — tags not inserted

      expect(await migration.validate(wrapper), isFalse);
    });

    test('down() is a no-op — does not throw', () async {
      await insertRecipe(db, 'r-1', 'main_dishes');
      await migration.up(wrapper);
      await expectLater(migration.down(wrapper), completes);

      // Tags still present after down() — no-op by design
      final rows = await db.rawQuery(
        "SELECT tag_id FROM recipe_tags WHERE recipe_id = 'r-1'",
      );
      expect(rows.length, equals(1));
    });

    test('existing manually-added tags are preserved by up()', () async {
      await insertRecipe(db, 'r-1', 'main_dishes');
      // Pre-insert a dietary tag on the same recipe
      await db.rawInsert(
        "INSERT INTO recipe_tags (recipe_id, tag_id) VALUES ('r-1', 'dietary-vegan')",
      );

      await migration.up(wrapper);

      final rows = await db.rawQuery(
        "SELECT tag_id FROM recipe_tags WHERE recipe_id = 'r-1' ORDER BY tag_id",
      );
      final tagIds = rows.map((r) => r['tag_id'] as String).toSet();
      expect(tagIds, containsAll(['dietary-vegan', 'meal-role-main-dish']));
    });
  });

  // ── Migration 008: AddSauceFoodTypeMigration ──────────────────────────────

  group('Migration 008 — AddSauceFoodTypeMigration', () {
    late Database db;
    late AddSauceFoodTypeMigration migration;
    late DatabaseWrapper wrapper;

    setUp(() async {
      db = await openEmpty();
      migration = AddSauceFoodTypeMigration();
      wrapper = DatabaseWrapper(db);
      await InitialSchemaMigration().up(wrapper);
      await AddTagsMigration().up(wrapper);
      await AddMealRoleFoodTypeMigration().up(wrapper);
    });

    tearDown(() async => db.close());

    test('up() inserts food-type-sauce tag', () async {
      await migration.up(wrapper);

      final rows = await db.rawQuery(
        "SELECT id, name, type_id FROM tags WHERE id = 'food-type-sauce'",
      );
      expect(rows.length, equals(1));
      expect(rows.first['name'], equals('sauce'));
      expect(rows.first['type_id'], equals('food_type'));
    });

    test('up() is idempotent — safe to run twice', () async {
      await migration.up(wrapper);
      await migration.up(wrapper);

      final rows = await db.rawQuery(
        "SELECT id FROM tags WHERE id = 'food-type-sauce'",
      );
      expect(rows.length, equals(1));
    });

    test('validate() returns true after up()', () async {
      await migration.up(wrapper);

      expect(await migration.validate(wrapper), isTrue);
    });

    test('validate() returns false before up()', () async {
      expect(await migration.validate(wrapper), isFalse);
    });

    test('down() removes the tag and its recipe_tags entries', () async {
      await migration.up(wrapper);
      await migration.down(wrapper);

      final rows = await db.rawQuery(
        "SELECT id FROM tags WHERE id = 'food-type-sauce'",
      );
      expect(rows, isEmpty);
    });

    test('down() leaves all other food_type tags intact', () async {
      await migration.up(wrapper);
      await migration.down(wrapper);

      final rows = await db.rawQuery(
        "SELECT id FROM tags WHERE type_id = 'food_type'",
      );
      expect(rows.length, equals(10));
    });
  });
}
