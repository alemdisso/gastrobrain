import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gastrobrain/core/services/recipe_import_service.dart';
import 'package:gastrobrain/core/migration/migration.dart';
import 'package:gastrobrain/core/migration/migrations/001_initial_schema.dart';
import '../../mocks/mock_database_helper.dart';

Future<Database> _openInMemoryDb() async {
  final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
  await InitialSchemaMigration().up(DatabaseWrapper(db));
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
}
