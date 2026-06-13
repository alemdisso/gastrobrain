import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide DatabaseExecutor;
import 'package:gastrobrain/core/migration/migration.dart';
import 'package:gastrobrain/core/migration/migrations/001_initial_schema.dart';
import 'package:gastrobrain/core/migration/migrations/005_add_tags.dart';
import 'package:gastrobrain/core/migration/migrations/006_add_meal_role_food_type.dart';
import 'package:gastrobrain/core/migration/migrations/008_add_sauce_food_type.dart';
import 'package:gastrobrain/core/migration/tag_vocabulary_seed.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('seedBuiltInTagVocabulary', () {
    late Database db;
    late DatabaseWrapper wrapper;

    setUp(() async {
      db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      wrapper = DatabaseWrapper(db);
      await InitialSchemaMigration().up(wrapper);
      await AddTagsMigration().up(wrapper);
      await AddMealRoleFoodTypeMigration().up(wrapper);
      await AddSauceFoodTypeMigration().up(wrapper);
    });

    tearDown(() async => db.close());

    test('seeds empty tag_types/tags tables to exactly 5/22', () async {
      await db.delete('tags');
      await db.delete('tag_types');

      await seedBuiltInTagVocabulary(wrapper);

      expect((await db.query('tag_types')).length, equals(5));
      expect((await db.query('tags')).length, equals(22));
    });

    test('is a no-op on an already fully-seeded database', () async {
      final beforeTypes = await db.query('tag_types', orderBy: 'id');
      final beforeTags = await db.query('tags', orderBy: 'id');
      expect(beforeTypes.length, equals(5));
      expect(beforeTags.length, equals(22));

      await seedBuiltInTagVocabulary(wrapper);

      expect(await db.query('tag_types', orderBy: 'id'), equals(beforeTypes));
      expect(await db.query('tags', orderBy: 'id'), equals(beforeTags));
    });

    test('heals a partially-wiped vocabulary without touching dietary',
        () async {
      // Simulate the #399 scenario: meal_role/food_type vocabulary lost.
      await db.delete('tags', where: "type_id IN ('meal_role', 'food_type')");
      await db.delete('tag_types', where: "id IN ('meal_role', 'food_type')");

      final dietaryBefore =
          await db.query('tags', where: "type_id = 'dietary'", orderBy: 'id');

      await seedBuiltInTagVocabulary(wrapper);

      expect((await db.query('tag_types')).length, equals(5));
      expect((await db.query('tags')).length, equals(22));
      expect(
        await db.query('tags', where: "type_id = 'dietary'", orderBy: 'id'),
        equals(dietaryBefore),
      );
    });
  });
}
