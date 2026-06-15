# Issue #401 Roadmap — Tag vocabulary health check and reseed tool

**Issue**: enhancement: tag vocabulary health check and reseed tool
**Branch**: feature/401-tag-vocabulary-health-check
**Milestone**: 0.2.15 — Tag Vocabulary & Backup Integrity
**Story Points**: 3

---

## Phase 1: Analysis & Understanding ✅ COMPLETE

### Requirements Summary
On startup, compare the built-in tag vocabulary (5 `tag_types` + 22 `tags`, the
same 27 rows seeded by #399's `seedBuiltInTagVocabulary`) against the database.
If anything is missing — e.g. a recurrence of the #399/#402-style wipe — show a
banner with a one-tap, idempotent "Repair" action that re-runs the seeder.
Healthy databases (the common case) see nothing at all. Out of scope: tag
browsing, usage counts, and custom tag management.

### Technical Design Decision

**Selected Approach:** TagRepository health-check + repair, reusing the existing
migration-alert banner infrastructure

Two new `TagRepository` methods:
- `hasIncompleteBuiltInVocabulary()` — boolean check (mirrors
  `DatabaseHelper.hasPendingMigrationFailure()`'s shape): queries `tag_types`
  and `tags` for the built-in IDs and returns `true` if any are missing.
  Returns `false` on a query error (safe default — never blocks startup).
- `repairBuiltInVocabulary()` — re-runs `seedBuiltInTagVocabulary`
  (`INSERT OR IGNORE`, already idempotent from #399). Throws
  `GastrobrainException` on failure, per `TagRepository`'s existing
  exception-handling convention.

`home_screen.dart`'s `initState` postFrameCallback gets a third check block
(alongside the existing `hasFatalMigrationError`/`hasPendingMigrationFailure`
checks), showing a `SnackBar` with a "Repair" `SnackBarAction` when the
vocabulary is incomplete.

No schema/migration version change — purely an additive, idempotent read +
write using existing tables and the existing #399 seeder.

**Alternatives Considered:**
- DatabaseHelper-based health-check (add the two methods directly to
  `database_helper.dart`, mirroring `hasPendingMigrationFailure` exactly so
  `home_screen.dart` calls `dbHelper.*` with no new object): rejected — would
  give the already-large `database_helper.dart` tag-table-specific knowledge
  that `TagRepository` already owns, and the issue's own "Affected files"
  section names `tag_repository.dart`.

### Patterns to Follow

| Pattern | Location | Usage |
|---------|----------|-------|
| Boolean health-flag check | `lib/database/database_helper.dart:85-130` (`hasPendingMigrationFailure`) | Shape for `hasIncompleteBuiltInVocabulary()` — async bool, safe default on error |
| Post-frame SnackBar + action banner | `lib/screens/home_screen.dart` `initState` | Third check block, same structure as the migration-failure block |
| Idempotent `INSERT OR IGNORE` seed/repair | `lib/core/migration/tag_vocabulary_seed.dart` (#399) | `repairBuiltInVocabulary()` is a thin wrapper calling this again |
| `DatabaseExecutor`/`DatabaseWrapper` | `lib/core/migration/migration.dart`; usage at `database_backup_service.dart:391` | Adapts raw `Database` (from `_dbHelper.database`) to call `seedBuiltInTagVocabulary` |
| Ad-hoc repository instantiation | `recipes_screen.dart:42`, `recipe_details_screen.dart:81` (`TagRepository(dbHelper)`) | `home_screen.dart` follows the same pattern — no `ServiceProvider` registration needed |
| Real in-memory DB + `MockDatabaseHelper.setDatabase()` | `test/core/services/database_backup_service_test.dart` | Test harness for `TagRepository` methods that run real SQL |

### Code Examples

#### Extracted constants — `lib/core/migration/tag_vocabulary_seed.dart`
```dart
/// Built-in tag_types seeded by migrations 005/006/008 (#399).
/// Tuple shape: (id, name, isHard, isOpen)
const builtInTagTypes = <(String, String, int, int)>[
  ('cuisine', 'Cuisine', 0, 1),
  ('occasion', 'Occasion', 0, 1),
  ('dietary', 'Dietary', 1, 0),
  ('meal_role', 'Meal Role', 0, 0),
  ('food_type', 'Food Type', 0, 0),
];

/// Built-in tags seeded by migrations 005/006/008 (#399).
/// Tuple shape: (id, name, typeId)
const builtInTags = <(String, String, String)>[
  // ... 22 tuples, same as today's local `tags` const ...
];

Future<void> seedBuiltInTagVocabulary(DatabaseExecutor db) async {
  for (final (id, name, isHard, isOpen) in builtInTagTypes) {
    await db.execute(
      'INSERT OR IGNORE INTO tag_types (id, name, is_hard, is_open) VALUES (?, ?, ?, ?)',
      [id, name, isHard, isOpen],
    );
  }
  for (final (id, name, typeId) in builtInTags) {
    await db.execute(
      'INSERT OR IGNORE INTO tags (id, name, type_id) VALUES (?, ?, ?)',
      [id, name, typeId],
    );
  }
}
```

#### Health-check + repair — `lib/core/repositories/tag_repository.dart`
```dart
import '../migration/migration.dart'; // for DatabaseWrapper
import '../migration/tag_vocabulary_seed.dart';

/// Returns true if any built-in tag_type or tag (#399 seed set) is
/// missing from the database — e.g. after a wipe like #399/#402.
Future<bool> hasIncompleteBuiltInVocabulary() async {
  try {
    final db = await _dbHelper.database;

    final typeIds = builtInTagTypes.map((t) => t.$1).toList();
    final typeRows = await db.query(
      'tag_types',
      where: 'id IN (${List.filled(typeIds.length, '?').join(',')})',
      whereArgs: typeIds,
    );
    if (typeRows.length != typeIds.length) return true;

    final tagIds = builtInTags.map((t) => t.$1).toList();
    final tagRows = await db.query(
      'tags',
      where: 'id IN (${List.filled(tagIds.length, '?').join(',')})',
      whereArgs: tagIds,
    );
    return tagRows.length != tagIds.length;
  } catch (_) {
    return false;
  }
}

/// Re-seeds any missing built-in tag_types/tags. Idempotent — safe to
/// call even when the vocabulary is already complete.
Future<void> repairBuiltInVocabulary() async {
  try {
    final db = await _dbHelper.database;
    await seedBuiltInTagVocabulary(DatabaseWrapper(db));
  } catch (e) {
    throw GastrobrainException('Failed to repair tag vocabulary: $e');
  }
}
```

#### Banner — `lib/screens/home_screen.dart` `initState`
```dart
final tagRepository = TagRepository(dbHelper);
if (await tagRepository.hasIncompleteBuiltInVocabulary()) {
  if (!mounted) return;
  final l10n = AppLocalizations.of(context)!;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(l10n.tagVocabularyIncompleteWarning),
    action: SnackBarAction(
      label: l10n.buttonRepair,
      onPressed: () async {
        try {
          await tagRepository.repairBuiltInVocabulary();
        } catch (_) {
          // Best-effort; user can retry by restarting the app.
        }
      },
    ),
    duration: const Duration(seconds: 10),
  ));
}
```

### Edge Cases Identified

| Edge Case | Handling Strategy |
|-----------|-------------------|
| Fresh DB / vocabulary never seeded (0/27 present) | `hasIncompleteBuiltInVocabulary()` → `true`; repair seeds all 27 |
| Partial wipe (#399-style — `meal_role`/`food_type` missing, others intact) | `hasIncompleteBuiltInVocabulary()` → `true`; repair restores only the missing rows via `INSERT OR IGNORE` |
| Fully healthy DB (common case) | `hasIncompleteBuiltInVocabulary()` → `false`; no banner shown |
| Repair tapped while already healthy (double-tap / race) | No-op — `INSERT OR IGNORE` idempotent |
| Repair write fails (disk full, locked DB) | `repairBuiltInVocabulary()` throws `GastrobrainException`; `home_screen.dart` catches it, no crash |
| Health-check query errors (transient DB issue) | Returns `false` (safe default) — no confusing banner on a transient error |
| Both migration-failure and vocabulary banners trigger | `ScaffoldMessenger` queues SnackBars sequentially — no crash |

### Risk Assessment

| Risk | Level | Mitigation |
|------|-------|------------|
| Health-check error masks a real problem (returns `false`) | Low | Accepted by design — mirrors `hasPendingMigrationFailure`'s safe-default |
| Two SnackBars fire in same `initState` | Low | `ScaffoldMessenger` queues them; not a blocker |
| Repair tap throws | Medium | try/catch around `onPressed` in `home_screen.dart` |
| Constant extraction breaks existing seed test | Low | Pure hoist of same tuples; existing 3 tests + magic-number cleanup verify it |

### Testing Requirements

**Unit Tests** (`test/core/repositories/tag_repository_test.dart` — new):
- [x] `hasIncompleteBuiltInVocabulary()` is `false` on a fully-seeded DB
- [x] `hasIncompleteBuiltInVocabulary()` is `true` when a `tag_type` is missing
- [x] `hasIncompleteBuiltInVocabulary()` is `true` when a `tag` is missing
- [x] `repairBuiltInVocabulary()` heals a fully-wiped vocabulary (0/27 → 27/27)
- [x] `repairBuiltInVocabulary()` heals a partial wipe without touching unrelated tags (#399 scenario)
- [x] `repairBuiltInVocabulary()` is a no-op on an already-healthy DB

**Seed Test Update** (`test/core/migration/tag_vocabulary_seed_test.dart`):
- [x] Replace hardcoded `5`/`22` with `builtInTagTypes.length`/`builtInTags.length`

**Widget Tests** (`test/screens/home_screen_test.dart` — new):
- [x] Healthy vocabulary → no "Repair" SnackBar
- [x] Incomplete vocabulary → SnackBar with warning text + "Repair" action
- [x] Tapping "Repair" invokes `repairBuiltInVocabulary()` without crashing
- [x] Migration-failure banner and vocabulary banner can both fire without crashing

### Implementation Checklist (Phase 2)

- [x] Step 1: Extract `builtInTagTypes`/`builtInTags` to top-level consts in `tag_vocabulary_seed.dart`
- [x] Step 2: Add `hasIncompleteBuiltInVocabulary()` + `repairBuiltInVocabulary()` to `TagRepository`
- [x] Step 3: Wire up third check block in `home_screen.dart` `initState`
- [x] Step 4: Localization — `tagVocabularyIncompleteWarning` + `buttonRepair` in `app_en.arb`/`app_pt.arb`, run `flutter gen-l10n`
- [x] Step 5: Tests — `tag_repository_test.dart` (new) + seed test magic-number cleanup
- [x] Step 6: Widget tests — `home_screen_test.dart` (new)
- [x] Step 7: `flutter analyze && flutter test` — clean

### Files Summary

**To Create:**
- `test/core/repositories/tag_repository_test.dart`
- `test/screens/home_screen_test.dart`

**To Modify:**
- `lib/core/migration/tag_vocabulary_seed.dart` (extract constants)
- `lib/core/repositories/tag_repository.dart` (health-check + repair methods)
- `lib/screens/home_screen.dart` (banner wiring)
- `lib/l10n/app_en.arb`, `lib/l10n/app_pt.arb` (2 new strings)
- `test/core/migration/tag_vocabulary_seed_test.dart` (magic-number cleanup)

---

*Phase 1 analysis completed: 2026-06-13*
*Ready for Phase 2 implementation*
