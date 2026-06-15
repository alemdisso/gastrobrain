import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:gastrobrain/core/services/database_backup_service.dart';
import 'package:gastrobrain/database/database_helper.dart';

/// Restores a frozen backup fixture and checks the invariants every backup
/// — old or new — must satisfy after a restore.
Future<void> _expectValidRestore(
  DatabaseBackupService backupService,
  DatabaseHelper dbHelper,
  String fixturePath,
) async {
  final fixture = await File(fixturePath).readAsString();
  await backupService.restoreDatabaseFromString(fixture);

  final db = await dbHelper.database;

  final tagTypes = await db.query('tag_types');
  final tags = await db.query('tags');
  expect(tagTypes, hasLength(5),
      reason: 'Built-in tag_types must be present after restore (#401)');
  expect(tags, hasLength(22),
      reason: 'Built-in tags must be present after restore (#401)');

  final fkViolations = await db.rawQuery('PRAGMA foreign_key_check');
  expect(fkViolations, isEmpty,
      reason: 'Restored data must not violate foreign key constraints');

  final recipes = await db.query('recipes');
  final ingredients = await db.query('ingredients');
  expect(recipes, isNotEmpty);
  expect(ingredients, isNotEmpty);
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseBackupService — frozen fixture restores', () {
    late DatabaseHelper dbHelper;
    late DatabaseBackupService backupService;

    setUp(() {
      dbHelper = DatabaseHelper();
      backupService = DatabaseBackupService(dbHelper);
    });

    test('pre-tagging backup (v1) restores with self-healed tag vocabulary',
        () async {
      await _expectValidRestore(
        backupService,
        dbHelper,
        'test/fixtures/backups/pre_tagging_backup_v1.json',
      );
    });

    test(
        'real-device backup (v1) restores with self-healed tag vocabulary '
        'and simple-side defaults', () async {
      await _expectValidRestore(
        backupService,
        dbHelper,
        'test/fixtures/backups/real_device_backup_v1.json',
      );
    });
  });
}
