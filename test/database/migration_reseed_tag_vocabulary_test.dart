import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide DatabaseExecutor;
import 'package:gastrobrain/core/migration/migration.dart';
import 'package:gastrobrain/core/migration/migrations/001_initial_schema.dart';
import 'package:gastrobrain/core/migration/migrations/005_add_tags.dart';
import 'package:gastrobrain/core/migration/migrations/006_add_meal_role_food_type.dart';
import 'package:gastrobrain/core/migration/migrations/008_add_sauce_food_type.dart';
import 'package:gastrobrain/core/migration/migrations/013_reseed_tag_vocabulary.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  // Builds a database with the tag vocabulary fully seeded by migrations
  // 005/006/008 — equivalent to "intact v112" with respect to tag_types/tags,
  // since migrations 009-012 don't touch those tables.
  Future<Database> buildSeededDb() async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    final wrapper = DatabaseWrapper(db);
    await InitialSchemaMigration().up(wrapper);
    await AddTagsMigration().up(wrapper);
    await AddMealRoleFoodTypeMigration().up(wrapper);
    await AddSauceFoodTypeMigration().up(wrapper);
    return db;
  }

  group('ReseedTagVocabularyMigration (v113)', () {
    late Database db;
    late DatabaseWrapper wrapper;
    late ReseedTagVocabularyMigration migration;

    setUp(() async {
      db = await buildSeededDb();
      wrapper = DatabaseWrapper(db);
      migration = ReseedTagVocabularyMigration();
    });

    tearDown(() async => db.close());

    test('up() on an intact database is a no-op: counts stay 5/22', () async {
      final beforeTypes = await db.query('tag_types', orderBy: 'id');
      final beforeTags = await db.query('tags', orderBy: 'id');
      expect(beforeTypes.length, equals(5));
      expect(beforeTags.length, equals(22));

      await migration.up(wrapper);

      expect(await db.query('tag_types', orderBy: 'id'), equals(beforeTypes));
      expect(await db.query('tags', orderBy: 'id'), equals(beforeTags));
    });

    test('validate() passes on an intact database', () async {
      expect(await migration.validate(wrapper), isTrue);
    });

    test('up() heals a database with empty tag_types/tags', () async {
      await db.delete('tags');
      await db.delete('tag_types');

      await migration.up(wrapper);

      expect((await db.query('tag_types')).length, equals(5));
      expect((await db.query('tags')).length, equals(22));
      expect(await migration.validate(wrapper), isTrue);
    });

    test(
        'up() heals a partially-wiped database without duplicating remaining rows',
        () async {
      // Simulate the #399 scenario: meal_role/food_type vocabulary lost.
      await db.delete('tags', where: "type_id IN ('meal_role', 'food_type')");
      await db.delete('tag_types', where: "id IN ('meal_role', 'food_type')");

      final dietaryBefore =
          await db.query('tags', where: "type_id = 'dietary'", orderBy: 'id');

      await migration.up(wrapper);

      expect((await db.query('tag_types')).length, equals(5));
      expect((await db.query('tags')).length, equals(22));
      expect(
        await db.query('tags', where: "type_id = 'dietary'", orderBy: 'id'),
        equals(dietaryBefore),
      );
    });

    test('down() is a documented no-op — seed rows remain', () async {
      await migration.down(wrapper);

      expect((await db.query('tag_types')).length, equals(5));
      expect((await db.query('tags')).length, equals(22));
    });

    test('validate() fails on a database with empty tag_types/tags', () async {
      await db.delete('tags');
      await db.delete('tag_types');

      expect(await migration.validate(wrapper), isFalse);
    });
  });
}
