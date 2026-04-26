import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gastrobrain/core/services/recipe_import_service.dart';
import 'package:gastrobrain/core/migration/migration.dart';
import 'package:gastrobrain/core/migration/migrations/001_initial_schema.dart';
import 'package:gastrobrain/core/migration/migrations/003_add_marinating_time.dart';
import '../../mocks/mock_database_helper.dart';

Future<Database> _openInMemoryDb() async {
  final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
  await InitialSchemaMigration().up(DatabaseWrapper(db));
  await AddMarinatingTimeMigration().up(DatabaseWrapper(db));
  return db;
}

Future<File> _writeTempJson(List<Map<String, dynamic>> data) async {
  final file = File(
    '${Directory.systemTemp.path}/import_test_${DateTime.now().microsecondsSinceEpoch}.json',
  );
  await file.writeAsString(jsonEncode(data));
  return file;
}

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
      'category': 'main_course',
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
      final jsonData = [_buildRecipeJson(instructions: expected)];

      final file = await _writeTempJson(jsonData);
      await importService.importRecipesFromJson(file.path);

      final rows =
          await db.query('recipes', where: 'id = ?', whereArgs: ['r1']);
      expect(rows, hasLength(1));
      expect(rows.first['instructions'], equals(expected));

      await file.delete();
    });

    test('restores multiline instructions correctly', () async {
      const expected = 'Step 1: Prep.\nStep 2: Cook.\nStep 3: Serve.';
      final jsonData = [_buildRecipeJson(instructions: expected)];

      final file = await _writeTempJson(jsonData);
      await importService.importRecipesFromJson(file.path);

      final rows =
          await db.query('recipes', where: 'id = ?', whereArgs: ['r1']);
      expect(rows.first['instructions'], equals(expected));

      await file.delete();
    });

    test('defaults to empty string when instructions key is absent', () async {
      final jsonMap = _buildRecipeJson();
      jsonMap.remove('instructions');
      final jsonData = [jsonMap];

      final file = await _writeTempJson(jsonData);
      await importService.importRecipesFromJson(file.path);

      final rows =
          await db.query('recipes', where: 'id = ?', whereArgs: ['r1']);
      expect(rows.first['instructions'], equals(''));

      await file.delete();
    });

    test('defaults to empty string when instructions value is null', () async {
      final jsonData = [_buildRecipeJson(instructions: null)];

      final file = await _writeTempJson(jsonData);
      await importService.importRecipesFromJson(file.path);

      final rows =
          await db.query('recipes', where: 'id = ?', whereArgs: ['r1']);
      expect(rows.first['instructions'], equals(''));

      await file.delete();
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

    /// Seeds a minimal meal + meal_recipes row referencing [recipeId].
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

    /// Seeds a minimal meal plan + item + meal_plan_item_recipes row.
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

    test('meal_recipes rows survive recipe import', () async {
      // Seed: recipe + meal history referencing it
      await db.insert('recipes', {
        'id': 'r1',
        'name': 'Pasta',
        'desired_frequency': 'weekly',
        'created_at': '2026-01-01T00:00:00.000Z',
      });
      await _seedMealRecipe(db, 'r1');

      // Import same recipe (same UUID preserved)
      final file = await _writeTempJson([_buildRecipeJson(id: 'r1')]);
      await importService.importRecipesFromJson(file.path);
      await file.delete();

      final rows = await db.query('meal_recipes');
      expect(rows, hasLength(1));
      expect(rows.first['id'], equals('mr-r1'));
    });

    test('meal_plan_item_recipes rows survive recipe import', () async {
      await db.insert('recipes', {
        'id': 'r1',
        'name': 'Pasta',
        'desired_frequency': 'weekly',
        'created_at': '2026-01-01T00:00:00.000Z',
      });
      await _seedMealPlanItemRecipe(db, 'r1');

      final file = await _writeTempJson([_buildRecipeJson(id: 'r1')]);
      await importService.importRecipesFromJson(file.path);
      await file.delete();

      final rows = await db.query('meal_plan_item_recipes');
      expect(rows, hasLength(1));
      expect(rows.first['id'], equals('mpir-r1'));
    });

    test('junction rows for recipes not in import file are dropped', () async {
      // Two recipes; only r1 will be in the import
      for (final id in ['r1', 'r2']) {
        await db.insert('recipes', {
          'id': id,
          'name': 'Recipe $id',
          'desired_frequency': 'weekly',
          'created_at': '2026-01-01T00:00:00.000Z',
        });
        await _seedMealRecipe(db, id);
      }

      // Import only r1
      final file = await _writeTempJson([_buildRecipeJson(id: 'r1')]);
      await importService.importRecipesFromJson(file.path);
      await file.delete();

      final rows = await db.query('meal_recipes');
      expect(rows, hasLength(1));
      expect(rows.first['recipe_id'], equals('r1'));
    });

    test('import succeeds with no prior junction data', () async {
      // No meal history seeded — snapshot is empty, restore is a no-op
      final file = await _writeTempJson([_buildRecipeJson(id: 'r1')]);
      await expectLater(
        importService.importRecipesFromJson(file.path),
        completes,
      );
      await file.delete();

      expect(await db.query('meal_recipes'), isEmpty);
      expect(await db.query('meal_plan_item_recipes'), isEmpty);
    });
  });
}
