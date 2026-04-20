import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gastrobrain/core/services/database_backup_service.dart';
import 'package:gastrobrain/core/errors/gastrobrain_exceptions.dart';
import 'package:gastrobrain/core/migration/migration.dart';
import 'package:gastrobrain/core/migration/migrations/001_initial_schema.dart';
import '../../mocks/mock_database_helper.dart';

String _validBackupJson({
  List<Map<String, dynamic>> ingredients = const [],
  List<Map<String, dynamic>> recipes = const [],
}) {
  return jsonEncode({
    'version': '1.0',
    'backup_date': '2026-04-20T10:00:00.000Z',
    'ingredients': ingredients,
    'recipes': recipes,
    'meal_plans': [],
    'meals': [],
    'recommendation_history': [],
  });
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseBackupService — restoreDatabaseFromString()', () {
    late Database db;
    late MockDatabaseHelper mockDbHelper;
    late DatabaseBackupService backupService;

    setUp(() async {
      db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      await InitialSchemaMigration().up(DatabaseWrapper(db));
      mockDbHelper = MockDatabaseHelper();
      mockDbHelper.setDatabase(db);
      backupService = DatabaseBackupService(mockDbHelper);
    });

    tearDown(() async {
      await db.close();
    });

    test('restores ingredients from JSON string', () async {
      final json = _validBackupJson(
        ingredients: [
          {
            'id': 'ing-1',
            'name': 'Tomato',
            'category': 'vegetable',
            'unit': 'piece',
            'protein_type': null,
            'notes': 'Fresh',
          },
        ],
      );

      await backupService.restoreDatabaseFromString(json);

      final rows = await db.query('ingredients');
      expect(rows.length, equals(1));
      expect(rows.first['id'], equals('ing-1'));
      expect(rows.first['name'], equals('Tomato'));
    });

    test('restores recipes from JSON string', () async {
      final json = _validBackupJson(
        recipes: [
          {
            'id': 'rec-1',
            'name': 'Pasta',
            'difficulty': 2,
            'prep_time_minutes': 10,
            'cook_time_minutes': 20,
            'rating': 4,
            'category': 'main_course',
            'desired_frequency': 'weekly',
            'notes': null,
            'instructions': 'Boil pasta.',
            'created_at': '2026-01-01T00:00:00.000Z',
            'recipe_ingredients': [],
          },
        ],
      );

      await backupService.restoreDatabaseFromString(json);

      final rows = await db.query('recipes');
      expect(rows.length, equals(1));
      expect(rows.first['id'], equals('rec-1'));
      expect(rows.first['name'], equals('Pasta'));
    });

    test('clears existing data before restoring', () async {
      // Pre-populate an ingredient directly in the DB
      await db.insert('ingredients', {
        'id': 'old-ing',
        'name': 'OldIngredient',
        'category': 'other',
      });

      // Restore an empty backup
      await backupService.restoreDatabaseFromString(_validBackupJson());

      final rows = await db.query('ingredients');
      expect(rows, isEmpty);
    });

    test('throws GastrobrainException on malformed JSON', () async {
      await expectLater(
        () => backupService.restoreDatabaseFromString('not valid json {{{'),
        throwsA(isA<GastrobrainException>()),
      );
    });

    test('throws GastrobrainException when version field is missing', () async {
      final jsonWithoutVersion = jsonEncode({
        'backup_date': '2026-04-20T10:00:00.000Z',
        'ingredients': [],
        'recipes': [],
        'meal_plans': [],
        'meals': [],
        'recommendation_history': [],
      });

      await expectLater(
        () => backupService.restoreDatabaseFromString(jsonWithoutVersion),
        throwsA(isA<GastrobrainException>()),
      );
    });
  });
}
