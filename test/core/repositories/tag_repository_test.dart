import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide DatabaseExecutor;
import 'package:gastrobrain/core/migration/migration.dart';
import 'package:gastrobrain/core/migration/migrations/001_initial_schema.dart';
import 'package:gastrobrain/core/migration/migrations/005_add_tags.dart';
import 'package:gastrobrain/core/migration/migrations/006_add_meal_role_food_type.dart';
import 'package:gastrobrain/core/migration/migrations/008_add_sauce_food_type.dart';
import 'package:gastrobrain/core/migration/tag_vocabulary_seed.dart';
import 'package:gastrobrain/core/repositories/tag_repository.dart';
import '../../mocks/mock_database_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('TagRepository — built-in vocabulary health check', () {
    late Database db;
    late MockDatabaseHelper mockDbHelper;
    late TagRepository repository;

    setUp(() async {
      db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      final wrapper = DatabaseWrapper(db);
      await InitialSchemaMigration().up(wrapper);
      await AddTagsMigration().up(wrapper);
      await AddMealRoleFoodTypeMigration().up(wrapper);
      await AddSauceFoodTypeMigration().up(wrapper);

      mockDbHelper = MockDatabaseHelper();
      mockDbHelper.setDatabase(db);
      repository = TagRepository(mockDbHelper);
    });

    tearDown(() async => db.close());

    test('hasIncompleteBuiltInVocabulary() is false on a fully-seeded DB',
        () async {
      expect(await repository.hasIncompleteBuiltInVocabulary(), isFalse);
    });

    test('hasIncompleteBuiltInVocabulary() is true when a tag_type is missing',
        () async {
      await db.delete('tags', where: "type_id = 'meal_role'");
      await db.delete('tag_types', where: "id = 'meal_role'");

      expect(await repository.hasIncompleteBuiltInVocabulary(), isTrue);
    });

    test('hasIncompleteBuiltInVocabulary() is true when a tag is missing',
        () async {
      await db.delete('tags', where: "id = 'dietary-vegan'");

      expect(await repository.hasIncompleteBuiltInVocabulary(), isTrue);
    });

    test(
        'repairBuiltInVocabulary() heals a fully-wiped vocabulary (0/27 -> 27/27)',
        () async {
      await db.delete('tags');
      await db.delete('tag_types');
      expect((await db.query('tag_types')).length, equals(0));
      expect((await db.query('tags')).length, equals(0));

      await repository.repairBuiltInVocabulary();

      expect((await db.query('tag_types')).length,
          equals(builtInTagTypes.length));
      expect((await db.query('tags')).length, equals(builtInTags.length));
    });

    test(
        'repairBuiltInVocabulary() heals a partial wipe without touching dietary (#399 scenario)',
        () async {
      await db.delete('tags', where: "type_id IN ('meal_role', 'food_type')");
      await db.delete('tag_types', where: "id IN ('meal_role', 'food_type')");

      final dietaryBefore = await db.query('tags',
          where: "type_id = 'dietary'", orderBy: 'id');

      await repository.repairBuiltInVocabulary();

      expect((await db.query('tag_types')).length,
          equals(builtInTagTypes.length));
      expect((await db.query('tags')).length, equals(builtInTags.length));
      expect(
        await db.query('tags', where: "type_id = 'dietary'", orderBy: 'id'),
        equals(dietaryBefore),
      );
    });

    test('repairBuiltInVocabulary() is a no-op on an already-healthy DB',
        () async {
      final beforeTypes = await db.query('tag_types', orderBy: 'id');
      final beforeTags = await db.query('tags', orderBy: 'id');

      await repository.repairBuiltInVocabulary();

      expect(await db.query('tag_types', orderBy: 'id'), equals(beforeTypes));
      expect(await db.query('tags', orderBy: 'id'), equals(beforeTags));
    });
  });
}
