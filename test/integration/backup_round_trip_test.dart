import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:gastrobrain/core/migration/migration.dart';
import 'package:gastrobrain/core/migration/tag_vocabulary_seed.dart';
import 'package:gastrobrain/core/services/database_backup_service.dart';
import 'package:gastrobrain/database/database_helper.dart';

import 'helpers/backup_seed_helper.dart';

/// Tables fully exported/restored by [DatabaseBackupService] — content-diffed
/// before and after a round trip.
const _coveredTables = {
  'ingredients',
  'recipes',
  'recipe_ingredients',
  'recipe_tags',
  'tag_types',
  'tags',
  'meal_plans',
  'meal_plan_items',
  'meal_plan_item_recipes',
  'meal_plan_item_ingredients',
  'meals',
  'meal_recipes',
  'meal_ingredients',
  'recommendation_history',
};

/// Tables intentionally excluded from the round-trip content diff.
const _allowlist = {
  // SQLite-managed AUTOINCREMENT counters; not application data.
  'sqlite_sequence',
  // Migration bookkeeping, not user data.
  'schema_migrations',
  'schema_migrations_errors',
  // Derived/regenerable via ShoppingListService.generateFromDateRange().
  // Manual `to_buy` checkbox toggles are not preserved across a restore —
  // a minor UX loss, not data loss (see issue #402 decisions).
  'shopping_lists',
  'shopping_list_items',
};

/// `recipe_tags` has a composite primary key (recipe_id, tag_id) with no
/// `id` column — every other covered table has `id TEXT PRIMARY KEY`.
String _orderByFor(String table) =>
    table == 'recipe_tags' ? 'recipe_id, tag_id' : 'id';

/// All user-data tables, in FK-safe delete order (children before parents).
const _tablesToClean = [
  'meal_recipes',
  'meal_ingredients',
  'meals',
  'meal_plan_item_recipes',
  'meal_plan_item_ingredients',
  'meal_plan_items',
  'meal_plans',
  'recipe_ingredients',
  'recipe_tags',
  'recipes',
  'ingredients',
  'recommendation_history',
  'shopping_list_items',
  'shopping_lists',
  'tags',
  'tag_types',
];

Future<void> _resetDatabase(Database db) async {
  for (final table in _tablesToClean) {
    await db.delete(table);
  }
  await seedBuiltInTagVocabulary(DatabaseWrapper(db));
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseBackupService — full schema round trip', () {
    late DatabaseHelper dbHelper;
    late Database db;
    late DatabaseBackupService backupService;

    setUp(() async {
      dbHelper = DatabaseHelper();
      db = await dbHelper.database;
      backupService = DatabaseBackupService(dbHelper);
      await _resetDatabase(db);
      await seedBackupTestData(dbHelper);
    });

    tearDown(() async {
      await _resetDatabase(db);
    });

    test('round trip preserves every table in the live schema', () async {
      final tableRows = await db
          .rawQuery("SELECT name FROM sqlite_master WHERE type = 'table'");
      final tableNames = tableRows.map((r) => r['name'] as String).toSet();

      final before = <String, List<Map<String, Object?>>>{};
      for (final table in tableNames) {
        if (_allowlist.contains(table)) continue;
        if (!_coveredTables.contains(table)) {
          fail(
            'Table "$table" exists in sqlite_master but is neither backed '
            'up by DatabaseBackupService nor in the allowlist. Update '
            '_exportXxx()/_restoreFromJson() to cover it, or add it to the '
            'allowlist in this test with a justification comment.',
          );
        }
        before[table] = await db.query(table, orderBy: _orderByFor(table));
      }

      // Sanity check: the tables added for #402 should hold seeded rows.
      expect(before['meal_ingredients'], isNotEmpty);
      expect(before['meal_plan_item_ingredients'], isNotEmpty);

      final backupJson = jsonEncode(await backupService.buildBackupData());

      await backupService.restoreDatabaseFromString(backupJson);

      for (final table in before.keys) {
        final after = await db.query(table, orderBy: _orderByFor(table));
        expect(after, equals(before[table]),
            reason: 'Table "$table" was not faithfully restored');
      }
    });
  });
}
