# Issue #399 Roadmap — Reseed built-in tag vocabulary on restore

**Issue**: bug: backup restore wipes tag vocabulary and never reseeds
**Branch**: fix/399-reseed-tag-vocabulary
**Milestone**: 0.2.15 — Tag Vocabulary & Backup Integrity
**Story Points**: 5

---

## Phase 1: Analysis & Understanding ✅ COMPLETE

### Requirements Summary
`_restoreFromJson` unconditionally deletes `tag_types`/`tags`/`recipe_tags` but only
reinserts `tag_types`/`tags` if the backup JSON contains those keys. Restoring a
pre-tagging backup (no such keys) leaves the vocabulary empty permanently, since the
seed migrations (v105/v106/v108) are already recorded as applied and never re-run.
Devices already affected today must be healed without requiring another restore.

### Technical Design Decision

**Selected Approach:** Shared seeder module + healing migration v113 + restore-flow call

A single `seedBuiltInTagVocabulary(DatabaseExecutor db)` function (5 tag_types + 22
tags, sourced verbatim from migrations 005/006/008, all `INSERT OR IGNORE`) is called
from two places:
- New migration v113 (`ReseedTagVocabularyMigration`) — heals any install whose
  `tag_types`/`tags` are already empty/partial from a prior buggy restore.
- `_restoreFromJson`, immediately after the existing `tag_types`/`tags` restore block —
  fills any gaps left by backups lacking those keys, before `recipe_tags`/`tag_ids`
  linking happens later in the same transaction.

**Alternatives Considered:**
- Restore-only fix (inline seed statements in `_restoreFromJson`, no new migration):
  rejected — does not heal installs already broken by this bug ("never reseeds" is the
  core complaint), and duplicates seed data with no shared source.

### Patterns to Follow

| Pattern | Location | Usage |
|---------|----------|-------|
| Tuple-list + `INSERT OR IGNORE` loop | `lib/core/migration/migrations/006_add_meal_role_food_type.dart:31-44` | Seed data shape for `tag_vocabulary_seed.dart` |
| Minimal "fix" migration scaffold (`requiresBackup: false`, post-commit `validate()`) | `lib/core/migration/migrations/012_fix_recipe_tags_cascade.dart` | Template for v113 |
| `DatabaseExecutor`/`DatabaseWrapper`/`TransactionWrapper` | `lib/core/migration/migration.dart` | Shared seeder signature works in both migration `up()` and restore `txn` |
| Migration applied via `Migration().up(DatabaseWrapper(db))` chain | `test/database/migration_integration_test.dart` `buildV108Database()` | v113 test setup |

### Code Examples

#### Shared seeder — `lib/core/migration/tag_vocabulary_seed.dart`
```dart
Future<void> seedBuiltInTagVocabulary(DatabaseExecutor db) async {
  const tagTypes = [
    ('cuisine', 'Cuisine', 0, 1),
    ('occasion', 'Occasion', 0, 1),
    ('dietary', 'Dietary', 1, 0),
    ('meal_role', 'Meal Role', 0, 0),
    ('food_type', 'Food Type', 0, 0),
  ];
  for (final (id, name, isHard, isOpen) in tagTypes) {
    await db.execute(
      'INSERT OR IGNORE INTO tag_types (id, name, is_hard, is_open) VALUES (?, ?, ?, ?)',
      [id, name, isHard, isOpen],
    );
  }
  // 22 tags total: 4 dietary + 7 meal_role + 11 food_type (incl. sauce),
  // sourced verbatim from migrations 005/006/008.
  const tags = [/* ... see migrations 005/006/008 ... */];
  for (final (id, name, typeId) in tags) {
    await db.execute(
      'INSERT OR IGNORE INTO tags (id, name, type_id) VALUES (?, ?, ?)',
      [id, name, typeId],
    );
  }
}
```

#### Migration v113 — `lib/core/migration/migrations/013_reseed_tag_vocabulary.dart`
```dart
class ReseedTagVocabularyMigration extends Migration {
  @override
  int get version => 113;

  @override
  String get description =>
      'Reseed built-in tag vocabulary (tag_types + tags)';

  @override
  bool get requiresBackup => false;

  @override
  Future<void> up(DatabaseExecutor db) => seedBuiltInTagVocabulary(db);

  @override
  Future<void> down(DatabaseExecutor db) async {
    // No-op by design: seed data is additive-only; removing healed rows
    // could orphan recipe_tags entries created after the heal.
  }

  @override
  Future<bool> validate(DatabaseExecutor db) async {
    final tagTypes = await db.rawQuery('SELECT COUNT(*) AS c FROM tag_types');
    final tags = await db.rawQuery('SELECT COUNT(*) AS c FROM tags');
    return (tagTypes.first['c'] as int) >= 5 && (tags.first['c'] as int) >= 22;
  }
}
```

#### Restore integration — `database_backup_service.dart` `_restoreFromJson`
```dart
      if (backupData['tags'] != null) {
        // ... existing tags restore loop ...
      }

      // Fill any gaps in the built-in tag vocabulary. INSERT OR IGNORE means
      // rows just restored from the backup win; this only seeds tag_types/
      // tags missing from the backup — e.g. pre-tagging backups (#399).
      await seedBuiltInTagVocabulary(TransactionWrapper(txn));

      if (backupData['ingredients'] != null) {
        // ... existing ingredients restore ...
```

### Edge Cases Identified

| Edge Case | Handling Strategy |
|-----------|-------------------|
| Old-format backup, no `tag_types`/`tags` keys | Seeder fills full 5/22 baseline after delete-without-reinsert |
| New-format backup, full built-in vocabulary present | `INSERT OR IGNORE` no-ops on all 27 ids — round-trip unchanged |
| Backup with a partial built-in set (mid-upgrade export) | Seeder fills only the missing types/tags |
| Already-affected install (empty vocab, no restore this session) | v113 runs as a pending migration on next launch and heals it |
| Fresh install | 005/006/008 seed normally; v113 immediately no-ops |
| User-created custom tag_types/tags | Untouched — seeder only references the 27 fixed built-in ids |

### Risk Assessment

| Risk | Level | Mitigation |
|------|-------|------------|
| Seeder placement vs. `recipe_tags`/`tag_ids` linking later in the restore transaction | Medium | Call seeder immediately after the `tag_types`/`tags` restore block, before `recipes`/`recipe_tags` |
| Exact column/value fidelity vs. migrations 005/006/008 | Low | Copy `INSERT OR IGNORE` statements verbatim into the seeder |
| Migration ordering (v113 must run after v105/106/108) | Low | `MigrationRunner` applies pending migrations in ascending version order; 113 > 108 |
| `down()` as documented no-op | Low | No downgrade path in this project's workflow |

### Testing Requirements

**Unit Tests** (`test/core/migration/tag_vocabulary_seed_test.dart`):
- [x] Seeding empty `tag_types`/`tags` tables → exactly 5/22
- [x] Seeding a fully-seeded database → no-op, values unchanged
- [x] Seeding a partially-seeded database (meal_role/food_type wiped) → heals to 5/22, dietary untouched

**Migration Tests** (`test/database/migrations/013_reseed_tag_vocabulary_test.dart`):
- [ ] Up on intact v112 db → counts stay 5/22, `validate()` passes
- [ ] Up on v112 db with `tag_types`/`tags` manually emptied → heals to 5/22, `validate()` passes
- [ ] Down is a no-op

**Regression Tests** (extend `test/core/services/database_backup_service_test.dart`):
- [x] Restore old-format backup (no `tag_types`/`tags` keys) → 5 `tag_types`, 22 `tags`
- [x] Restore backup with custom (non-built-in) tag_type/tag → custom rows preserved alongside healed built-ins (folded into the existing is_hard/is_open and legacy-flags tests, which needed updating anyway since they previously asserted exact counts of 2/1 using built-in ids)
- [x] Existing "clears existing data" and "export round-trips" tests still pass unchanged

### Implementation Checklist (Phase 2)

- [x] Step 1: Create `lib/core/migration/tag_vocabulary_seed.dart` (`seedBuiltInTagVocabulary`)
- [x] Step 2: Create `lib/core/migration/migrations/013_reseed_tag_vocabulary.dart` (v113)
- [x] Step 3: Register `ReseedTagVocabularyMigration()` in `database_helper.dart`'s `_migrations` + import
- [x] Step 4: Call seeder in `_restoreFromJson` after the `tags` restore block
- [x] Step 5: Tests — seeder unit tests, v113 migration tests, backup-service regression tests
- [x] Step 6: `flutter analyze && flutter test` — both clean (`flutter analyze`: 0 issues; `flutter test`: 100% pass, 2026-06-13). `integration_test` run the same day showed pre-existing, unrelated failures (stale E2E widget keys from #370/#398, and a `database_backup_service_test.dart` integration timeout cascade that fails even on export-only tests) — none touch tag_types/tags/migration-113/restore code paths; tracked separately, not blocking this fix.

### Files Summary

**To Create:**
- `lib/core/migration/tag_vocabulary_seed.dart` ✅
- `lib/core/migration/migrations/013_reseed_tag_vocabulary.dart` ✅
- `test/core/migration/tag_vocabulary_seed_test.dart` ✅
- `test/database/migration_reseed_tag_vocabulary_test.dart` ✅ (named per `test/database/` convention, not under a `migrations/` subdir)

**To Modify:**
- `lib/database/database_helper.dart` (import + `_migrations` registration)
- `lib/core/services/database_backup_service.dart` (import + seeder call in `_restoreFromJson`)
- `test/core/services/database_backup_service_test.dart` (+2 regression tests)

---

*Phase 1 analysis completed: 2026-06-13*
*Ready for Phase 2 implementation*
