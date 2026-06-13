import '../migration.dart';
import '../tag_vocabulary_seed.dart';

/// Reseeds the built-in tag vocabulary (tag_types + tags).
///
/// Heals installs whose tag_types/tags were wiped by the restore bug
/// fixed in #399 — DatabaseBackupService._restoreFromJson deleted these
/// tables unconditionally but only reinserted them if the backup JSON
/// happened to contain 'tag_types'/'tags' keys (older backups don't).
/// Also provides the seed source the restore flow itself now calls.
///
/// Purely additive (INSERT OR IGNORE) — safe on fresh, partial, or
/// fully-seeded databases.
class ReseedTagVocabularyMigration extends Migration {
  @override
  int get version => 113;

  @override
  String get description =>
      'Reseed built-in tag vocabulary (tag_types + tags)';

  @override
  bool get requiresBackup => false;

  @override
  Future<void> up(DatabaseExecutor db) async {
    await seedBuiltInTagVocabulary(db);
  }

  @override
  Future<void> down(DatabaseExecutor db) async {
    // No-op by design: seed data is additive-only. Removing healed rows
    // could orphan recipe_tags entries created against a built-in tag
    // after this migration ran.
  }

  @override
  Future<bool> validate(DatabaseExecutor db) async {
    final tagTypes = await db.rawQuery('SELECT COUNT(*) AS c FROM tag_types');
    final tags = await db.rawQuery('SELECT COUNT(*) AS c FROM tags');
    return (tagTypes.first['c'] as int) >= 5 && (tags.first['c'] as int) >= 22;
  }
}
