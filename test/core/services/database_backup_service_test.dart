import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gastrobrain/core/services/database_backup_service.dart';
import 'package:gastrobrain/core/errors/gastrobrain_exceptions.dart';
import 'package:gastrobrain/core/migration/migration.dart';
import 'package:gastrobrain/core/migration/migrations/001_initial_schema.dart';
import 'package:gastrobrain/core/migration/migrations/002_add_ingredient_aliases.dart';
import 'package:gastrobrain/core/migration/migrations/003_add_marinating_time.dart';
import 'package:gastrobrain/core/migration/migrations/004_add_recipe_story.dart';
import 'package:gastrobrain/core/migration/migrations/005_add_tags.dart';
import 'package:gastrobrain/core/migration/migrations/006_add_meal_role_food_type.dart';
import 'package:gastrobrain/core/migration/migrations/008_add_sauce_food_type.dart';
import '../../mocks/mock_database_helper.dart';

String _validBackupJson({
  List<Map<String, dynamic>> ingredients = const [],
  List<Map<String, dynamic>> recipes = const [],
  List<Map<String, dynamic>>? tagTypes,
  List<Map<String, dynamic>>? tags,
  int? schemaVersion,
}) {
  return jsonEncode({
    'version': '1.0',
    if (schemaVersion != null) 'schema_version': schemaVersion,
    'backup_date': '2026-04-20T10:00:00.000Z',
    if (tagTypes != null) 'tag_types': tagTypes,
    if (tags != null) 'tags': tags,
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
      final wrapper = DatabaseWrapper(db);
      await InitialSchemaMigration().up(wrapper);
      await AddIngredientAliasesMigration().up(wrapper);
      await AddMarinatingTimeMigration().up(wrapper);
      await AddRecipeStoryMigration().up(wrapper);
      await AddTagsMigration().up(wrapper);
      await AddMealRoleFoodTypeMigration().up(wrapper);
      await AddSauceFoodTypeMigration().up(wrapper);
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

    test(
        'restores built-in tag vocabulary when backup predates tag_types/tags keys',
        () async {
      // Pre-tagging backups have no 'tag_types'/'tags' keys at all (#399).
      final json = _validBackupJson();

      await backupService.restoreDatabaseFromString(json);

      expect((await db.query('tag_types')).length, equals(5));
      expect((await db.query('tags')).length, equals(22));
    });

    test('restores tag types with is_hard/is_open flags', () async {
      final json = _validBackupJson(
        tagTypes: [
          {'id': 'custom-type', 'name': 'Custom', 'is_hard': 1, 'is_open': 0},
        ],
        tags: [
          {'id': 'custom-tag', 'name': 'custom', 'type_id': 'custom-type'},
        ],
      );

      await backupService.restoreDatabaseFromString(json);

      final typeRows = await db.query('tag_types', orderBy: 'id ASC');
      // 5 built-in tag_types (reseeded post-restore, #399) + 1 custom from backup
      expect(typeRows.length, equals(6));
      final customType =
          typeRows.firstWhere((row) => row['id'] == 'custom-type');
      expect(customType['is_hard'], equals(1));
      expect(customType['is_open'], equals(0));

      final tagRows = await db.query('tags');
      // 22 built-in tags (reseeded post-restore, #399) + 1 custom from backup
      expect(tagRows.length, equals(23));
      final customTag =
          tagRows.firstWhere((row) => row['id'] == 'custom-tag');
      expect(customTag['type_id'], equals('custom-type'));
    });

    test('restores legacy tag types (color/icon keys, no flags) with defaults',
        () async {
      // Backups written before the schema fix carry color/icon and no flags.
      final json = _validBackupJson(
        tagTypes: [
          {
            'id': 'custom-legacy',
            'name': 'Legacy',
            'color': null,
            'icon': null
          },
        ],
      );

      await backupService.restoreDatabaseFromString(json);

      final rows = await db.query('tag_types', orderBy: 'id ASC');
      // 5 built-in tag_types (reseeded post-restore, #399) + 1 legacy custom from backup
      expect(rows.length, equals(6));
      final legacyType =
          rows.firstWhere((row) => row['id'] == 'custom-legacy');
      expect(legacyType['is_hard'], equals(0));
      expect(legacyType['is_open'], equals(1));
    });

    test('refuses backup stamped with newer schema version, data untouched',
        () async {
      await db.execute('''
        CREATE TABLE schema_migrations (
          version INTEGER PRIMARY KEY,
          applied_at TEXT NOT NULL,
          description TEXT NOT NULL,
          duration_ms INTEGER NOT NULL
        )
      ''');
      await db.insert('schema_migrations', {
        'version': 112,
        'applied_at': '2026-06-10T00:00:00.000Z',
        'description': 'test',
        'duration_ms': 0,
      });
      await db.insert('ingredients', {
        'id': 'keep-me',
        'name': 'Existing',
        'category': 'other',
      });

      final json = _validBackupJson(schemaVersion: 113);

      await expectLater(
        () => backupService.restoreDatabaseFromString(json),
        throwsA(isA<BackupVersionException>()),
      );

      final rows = await db.query('ingredients');
      expect(rows.length, equals(1));
      expect(rows.first['id'], equals('keep-me'));
    });

    test('accepts backup stamped with older schema version', () async {
      await db.execute('''
        CREATE TABLE schema_migrations (
          version INTEGER PRIMARY KEY,
          applied_at TEXT NOT NULL,
          description TEXT NOT NULL,
          duration_ms INTEGER NOT NULL
        )
      ''');
      await db.insert('schema_migrations', {
        'version': 112,
        'applied_at': '2026-06-10T00:00:00.000Z',
        'description': 'test',
        'duration_ms': 0,
      });

      final json = _validBackupJson(
        schemaVersion: 105,
        ingredients: [
          {
            'id': 'ing-1',
            'name': 'Tomato',
            'category': 'vegetable',
            'unit': null,
            'protein_type': null,
            'notes': null,
          },
        ],
      );

      await backupService.restoreDatabaseFromString(json);

      final rows = await db.query('ingredients');
      expect(rows.length, equals(1));
    });

    test('export emits is_hard/is_open and round-trips through restore',
        () async {
      // setUp seeded the full vocabulary via migrations 005/006/008.
      final before = await db.query('tag_types', orderBy: 'id ASC');
      expect(before, isNotEmpty);

      final backupData = await backupService.buildBackupData();

      final exportedTypes = backupData['tag_types'] as List;
      expect(exportedTypes.length, equals(before.length));
      for (final tt in exportedTypes) {
        expect(tt.containsKey('is_hard'), isTrue);
        expect(tt.containsKey('is_open'), isTrue);
        expect(tt.containsKey('color'), isFalse);
        expect(tt.containsKey('icon'), isFalse);
      }
      expect(backupData['schema_version'], isA<int>());

      await backupService.restoreDatabaseFromString(jsonEncode(backupData));

      final after = await db.query('tag_types', orderBy: 'id ASC');
      expect(after, equals(before));
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
