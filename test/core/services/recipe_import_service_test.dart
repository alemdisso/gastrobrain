import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gastrobrain/core/services/recipe_import_service.dart';
import 'package:gastrobrain/core/migration/migration.dart';
import 'package:gastrobrain/core/migration/migrations/001_initial_schema.dart';
import 'package:gastrobrain/core/migration/migrations/003_add_marinating_time.dart';
import 'package:gastrobrain/core/migration/migrations/005_add_tags.dart';
import 'package:gastrobrain/core/migration/migrations/010_add_quantity_max.dart';
import '../../mocks/mock_database_helper.dart';

Future<Database> _openInMemoryDb() async {
  final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
  final wrapper = DatabaseWrapper(db);
  await InitialSchemaMigration().up(wrapper);
  await AddMarinatingTimeMigration().up(wrapper);
  await AddTagsMigration().up(wrapper);
  await AddQuantityMaxMigration().up(wrapper);
  return db;
}

Uint8List _toBytes(List<Map<String, dynamic>> data) =>
    Uint8List.fromList(utf8.encode(jsonEncode(data)));

Map<String, dynamic> _buildRecipeJson({
  String id = 'r1',
  String name = 'Test Recipe',
  String? instructions = '',
}) {
  return {
    'recipe_id': id,
    'name': name,
    'instructions': instructions,
    'current_ingredients': <Map<String, dynamic>>[],
    'enhanced_ingredients': <Map<String, dynamic>>[],
    'metadata': {
      'difficulty': 2,
      'prep_time_minutes': 10,
      'cook_time_minutes': 20,
      'rating': 4,
      'desired_frequency': 'weekly',
      'notes': '',
      'created_at': '2026-01-01T00:00:00.000Z',
    },
    'cooking_history': {
      'times_cooked': 0,
      'last_cooked_date': null,
    },
  };
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('RecipeImportService — instructions field', () {
    late Database db;
    late MockDatabaseHelper mockDbHelper;
    late RecipeImportService importService;

    setUp(() async {
      db = await _openInMemoryDb();
      mockDbHelper = MockDatabaseHelper();
      mockDbHelper.setDatabase(db);
      importService = RecipeImportService(mockDbHelper);
    });

    tearDown(() async {
      await db.close();
    });

    test('restores instructions from top-level JSON key', () async {
      const expected = 'Step 1: Boil water. Step 2: Add pasta.';
      final bytes = _toBytes([_buildRecipeJson(instructions: expected)]);
      final preview = await importService.previewImport(bytes);
      await importService.executeImport(preview, DuplicateStrategy.skip);

      final rows =
          await db.query('recipes', where: 'id = ?', whereArgs: ['r1']);
      expect(rows, hasLength(1));
      expect(rows.first['instructions'], equals(expected));
    });

    test('restores multiline instructions correctly', () async {
      const expected = 'Step 1: Prep.\nStep 2: Cook.\nStep 3: Serve.';
      final bytes = _toBytes([_buildRecipeJson(instructions: expected)]);
      final preview = await importService.previewImport(bytes);
      await importService.executeImport(preview, DuplicateStrategy.skip);

      final rows =
          await db.query('recipes', where: 'id = ?', whereArgs: ['r1']);
      expect(rows.first['instructions'], equals(expected));
    });

    test('defaults to empty string when instructions key is absent', () async {
      final jsonMap = _buildRecipeJson();
      jsonMap.remove('instructions');
      final bytes = _toBytes([jsonMap]);
      final preview = await importService.previewImport(bytes);
      await importService.executeImport(preview, DuplicateStrategy.skip);

      final rows =
          await db.query('recipes', where: 'id = ?', whereArgs: ['r1']);
      expect(rows.first['instructions'], equals(''));
    });

    test('defaults to empty string when instructions value is null', () async {
      final bytes = _toBytes([_buildRecipeJson(instructions: null)]);
      final preview = await importService.previewImport(bytes);
      await importService.executeImport(preview, DuplicateStrategy.skip);

      final rows =
          await db.query('recipes', where: 'id = ?', whereArgs: ['r1']);
      expect(rows.first['instructions'], equals(''));
    });
  });

  group('RecipeImportService — junction table preservation', () {
    late Database db;
    late MockDatabaseHelper mockDbHelper;
    late RecipeImportService importService;

    setUp(() async {
      db = await _openInMemoryDb();
      mockDbHelper = MockDatabaseHelper();
      mockDbHelper.setDatabase(db);
      importService = RecipeImportService(mockDbHelper);
    });

    tearDown(() async {
      await db.close();
    });

    Future<void> _seedMealRecipe(Database db, String recipeId) async {
      await db.insert('meals', {
        'id': 'meal-$recipeId',
        'recipe_id': null,
        'cooked_at': '2026-01-01T12:00:00.000Z',
        'servings': 2,
        'notes': '',
        'was_successful': 1,
        'actual_prep_time': 0,
        'actual_cook_time': 0,
      });
      await db.insert('meal_recipes', {
        'id': 'mr-$recipeId',
        'meal_id': 'meal-$recipeId',
        'recipe_id': recipeId,
        'is_primary_dish': 1,
        'notes': null,
      });
    }

    Future<void> _seedMealPlanItemRecipe(Database db, String recipeId) async {
      await db.insert('meal_plans', {
        'id': 'plan-$recipeId',
        'week_start_date': '2026-01-01',
        'notes': '',
        'created_at': '2026-01-01T00:00:00.000Z',
        'modified_at': '2026-01-01T00:00:00.000Z',
      });
      await db.insert('meal_plan_items', {
        'id': 'item-$recipeId',
        'meal_plan_id': 'plan-$recipeId',
        'planned_date': '2026-01-01',
        'meal_type': 'dinner',
        'notes': '',
        'has_been_cooked': 0,
        'planned_servings': 4,
      });
      await db.insert('meal_plan_item_recipes', {
        'id': 'mpir-$recipeId',
        'meal_plan_item_id': 'item-$recipeId',
        'recipe_id': recipeId,
        'is_primary_dish': 1,
        'notes': null,
      });
    }

    test('meal_recipes rows survive replace strategy (same UUID)', () async {
      await db.insert('recipes', {
        'id': 'r1',
        'name': 'Test Recipe',
        'desired_frequency': 'weekly',
        'created_at': '2026-01-01T00:00:00.000Z',
      });
      await _seedMealRecipe(db, 'r1');

      // Import same recipe name with same UUID → replace
      final bytes = _toBytes([_buildRecipeJson(id: 'r1', name: 'Test Recipe')]);
      final preview = await importService.previewImport(bytes);
      await importService.executeImport(preview, DuplicateStrategy.replace);

      final rows = await db.query('meal_recipes');
      expect(rows, hasLength(1));
      expect(rows.first['id'], equals('mr-r1'));
    });

    test('meal_plan_item_recipes rows survive replace strategy', () async {
      await db.insert('recipes', {
        'id': 'r1',
        'name': 'Test Recipe',
        'desired_frequency': 'weekly',
        'created_at': '2026-01-01T00:00:00.000Z',
      });
      await _seedMealPlanItemRecipe(db, 'r1');

      final bytes = _toBytes([_buildRecipeJson(id: 'r1', name: 'Test Recipe')]);
      final preview = await importService.previewImport(bytes);
      await importService.executeImport(preview, DuplicateStrategy.replace);

      final rows = await db.query('meal_plan_item_recipes');
      expect(rows, hasLength(1));
      expect(rows.first['id'], equals('mpir-r1'));
    });

    test('junction rows for non-imported recipes are NOT dropped', () async {
      // Two recipes; both seeded; only r1 will be in the import file.
      // New merge behavior: r2 is untouched (stays in DB with its junction rows).
      for (final id in ['r1', 'r2']) {
        await db.insert('recipes', {
          'id': id,
          'name': 'Recipe $id',
          'desired_frequency': 'weekly',
          'created_at': '2026-01-01T00:00:00.000Z',
        });
        await _seedMealRecipe(db, id);
      }

      // Import only r1 (name "Test Recipe" — no collision with existing names)
      final bytes = _toBytes([_buildRecipeJson(id: 'r1', name: 'Test Recipe')]);
      final preview = await importService.previewImport(bytes);
      await importService.executeImport(preview, DuplicateStrategy.skip);

      // r2 was NOT in the import file — it stays in the DB with its junction row
      final rows = await db.query('meal_recipes', orderBy: 'id');
      expect(rows, hasLength(2));
    });

    test('import succeeds with no prior junction data', () async {
      final bytes = _toBytes([_buildRecipeJson(id: 'r1')]);
      final preview = await importService.previewImport(bytes);
      final result =
          await importService.executeImport(preview, DuplicateStrategy.skip);

      expect(result.recipesAdded, equals(1));
      expect(await db.query('meal_recipes'), isEmpty);
      expect(await db.query('meal_plan_item_recipes'), isEmpty);
    });
  });
}
