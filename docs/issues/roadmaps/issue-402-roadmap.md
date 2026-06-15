# Issue #402: test: backup round-trip schema coverage test and restore fixtures

<!-- Save to: docs/issues/roadmaps/issue-402-roadmap.md -->

**Type**: Testing (+ small Implementation component, see Phase 2)
**Priority**: P1-High
**Estimate**: 3 story points
**Size**: M
**Dependencies**: #399 (merged), #400 (merged) — both closed, prerequisites met
**Branch**: `test/402-backup-round-trip-coverage`

---

## Overview

The backup service drifted from the real schema (#399, #400) and nothing
caught it: no test round-trips an export through a restore, and existing
coverage is hand-written expectations that go stale as the schema evolves.
This issue builds the structural guardrail — a round-trip test whose
expectations are derived from the **live schema** (`sqlite_master`), so any
future migration that adds/alters a table forces a conscious backup-coverage
decision, plus frozen restore fixtures that prove old backup formats still
restore safely.

**Expected Outcome**: A new integration test enumerates every table in
`sqlite_master`, fails if any non-allowlisted table isn't faithfully
round-tripped, and a second test restores frozen fixture JSONs (pre-tagging
format + sanitized real-device export) and checks tag-vocabulary/FK
invariants.

---

## Prerequisites Check

- [x] #399 (reseed tag vocabulary) merged to develop
- [x] #400 (tag_types column fix + schema stamp) merged to develop
- [x] On `test/402-backup-round-trip-coverage` (branched from develop)
- [ ] `flutter test && flutter analyze` clean before starting

---

## Phase 1: Analysis & Understanding — findings from this session

### Full table enumeration (current schema, post-#399/#400/#401)

From `001_initial_schema.dart` (13 tables) + `005_add_tags.dart` (3 tables) =
**16 user-data tables**:

| Table | Currently in `DatabaseBackupService`? |
|---|---|
| `recipes` (+ `recipe_ingredients`, `recipe_tags` nested) | ✅ |
| `ingredients` | ✅ |
| `recipe_ingredients` | ✅ (nested under recipes) |
| `tag_types` | ✅ |
| `tags` | ✅ |
| `recipe_tags` | ✅ (nested under recipes as `tag_ids`) |
| `meals` (+ `meal_recipes` nested) | ✅ |
| `meal_recipes` | ✅ (nested under meals) |
| `meal_plans` (+ items + item_recipes nested) | ✅ |
| `meal_plan_items` | ✅ (nested under meal_plans) |
| `meal_plan_item_recipes` | ✅ (nested under items) |
| `recommendation_history` | ✅ |
| **`meal_ingredients`** (meal "simple sides") | ❌ **gap** |
| **`meal_plan_item_ingredients`** (planned "simple sides") | ❌ **gap** |
| **`shopping_lists`** | ❌ (likely derived — see Q2) |
| **`shopping_list_items`** | ❌ (likely derived — see Q2) |

Plus system/internal tables expected in `sqlite_master` that are not
user-data: `schema_migrations` (defined in `migration_runner.dart:264`),
`android_metadata` (Android-only), `sqlite_sequence` (auto, from
`AUTOINCREMENT` on `shopping_lists`/`shopping_list_items`). `migration_runner`
should be checked for a `schema_migrations_errors` table too (issue mentions
it as an allowlist candidate — confirm it exists before allowlisting).

### Key finding — two real coverage gaps, not just system tables

`meal_ingredients` and `meal_plan_item_ingredients` ("simple sides" — e.g. "side:
steamed broccoli, 200g" attached directly to a meal/planned meal, models in
`lib/models/meal_ingredient.dart` / `meal_plan_item_ingredient.dart`) are
**primary user data with no other source of truth**. They are currently:
- Not exported by `_exportMeals()` / `_exportMealPlans()`
- Deleted via FK `ON DELETE CASCADE` when `meals`/`meal_plan_items` are wiped
  during restore, but never re-inserted

This is the same class of silent data loss as the #399 tag-vocabulary wipe —
restoring a backup silently drops every "side dish" a user ever recorded or
planned. See **Question 1**.

`shopping_lists`/`shopping_list_items` appear to be fully derived/regenerable
via `ShoppingListService.generateFromDateRange()` from meal-plan data — a
reasonable allowlist candidate (see **Question 2**), but confirm no
manually-edited state (e.g. `to_buy` checkbox toggles) would be silently lost.

### Patterns to follow

| Pattern | Location | Usage |
|---|---|---|
| Real in-memory DB + migrations | `test/core/services/database_backup_service_test.dart` setUp | Boots a real sqflite_ffi DB via `InitialSchemaMigration().up()` + later migrations — use same approach but run **all** migrations through `013_reseed_tag_vocabulary` |
| Real `DatabaseHelper` integration test | `integration_test/services/database_backup_service_test.dart` | Existing `cleanDatabase()` pattern, FK-order delete list — extend, don't duplicate |
| Nested export per parent | `_exportRecipes()` nests `recipe_ingredients`/`tag_ids` | Same shape for `_exportMeals()` → nest `meal_ingredients`; `_exportMealPlans()` items → nest `meal_plan_item_ingredients` |
| `INSERT OR IGNORE` + post-seed reconciliation | `tag_vocabulary_seed.dart`, used in `_restoreFromJson` | Reference for "fill gaps after restore" pattern if needed for sides |

---

## Phase 2: Implementation — extend `DatabaseBackupService`

**Decision (2026-06-15)**: Extend coverage for `meal_ingredients` /
`meal_plan_item_ingredients` now (Question 1, Option A).

- [x] `_exportMeals()` (`lib/core/services/database_backup_service.dart`):
  add `meal_ingredients` array per meal from `MealIngredient.toMap()`
  (via `meal.mealIngredients`, already loaded by `MealDao.getAllMeals()`)
- [x] `_exportMealPlans()` items loop: add `ingredients` array per item from
  `MealPlanItemIngredient.toMap()` (via `item.mealPlanItemIngredients`)
- [x] `_restoreFromJson()`: after inserting each `meal`/`meal_plan_item`,
  insert its `meal_ingredients`/`meal_plan_item_ingredients` rows
  (mirrors existing `recipe_ingredients` insert-after-recipe pattern)
- [x] Update class-level doc comment (lines 10-21) to list the two newly
  covered tables
- [x] `flutter analyze` — note: file is already flagged in
  `.github/refactoring-backlog.md` (546 lines, threshold 350); this adds
  ~30-40 lines. No new backlog entry needed (existing entry covers it), but
  don't make it materially worse than necessary — keep new methods small and
  delegate to the existing per-table private-method pattern.

**Additional finding during Phase 3 seeding**: `meal_plan_items.planned_servings`
was not exported or restored at all — every restore silently reset it to the
column default (4). Same bug class as the simple-sides gap, and the fix is the
same 2-line pattern (one line in `_exportMealPlans()`, one in
`_restoreFromJson()`'s `meal_plan_items` insert, with `?? 4` fallback for
older backups). Fixed as part of this Phase 2 slice rather than filed
separately, and the round-trip test seeds a non-default value (6) so this
column is actually exercised by the guardrail.

---

## Phase 3: Testing — main deliverable

### 3.1 Seed helper

- [x] `test/integration/helpers/backup_seed_helper.dart` — populates every
  covered table with realistic relational data in one call, per
  [[feedback_import_test_data]]-style conventions (meals, history, plans,
  instructions — not just recipes+ingredients):
  - 2 ingredients (one with `aliases`, one with `protein_type`)
  - 1 custom (open-vocabulary) tag + use of 2 built-in tags
  - 2 recipes (with `recipe_ingredients`, `recipe_tags`, `story`,
    `marinating_time_minutes`, non-default `servings`)
  - 1 meal_plan with 1 item that has both a recipe (`meal_plan_item_recipes`)
    and a simple side (`meal_plan_item_ingredients`), with non-default
    `planned_servings` (6) to exercise the Phase 2 fix above
  - 1 meal with `meal_recipes` and a simple side (`meal_ingredients`)
  - 2 `recommendation_history` rows

  **Deviation from spec**: returns `Future<void>` instead of a snapshot map
  `{table: [rows]}`. `recipe_tags` has a composite PK (no `id` column), so a
  uniform `ORDER BY id` snapshot can't cover every table — the round-trip
  test (3.2) takes its own before/after `sqlite_master` snapshots with a
  per-table `ORDER BY` (`_orderByFor()`), making a snapshot returned from the
  seed helper redundant.

### 3.2 Dynamic round-trip test

- [x] `test/integration/backup_round_trip_test.dart`:
  - `setUp`: real `DatabaseHelper` (per project integration-test convention),
    clean all tables (`_resetDatabase`, FK-safe order), reseed built-in tag
    vocabulary, then seed via `backup_seed_helper.dart`
  - Enumerate every table in `sqlite_master` (`type='table'`)
  - For each table: if allowlisted → skip; if not in `_coveredTables` →
    `fail()` naming the table; else snapshot via
    `SELECT * FROM <table> ORDER BY <pk>` (`_orderByFor()` special-cases
    `recipe_tags` → `ORDER BY recipe_id, tag_id`, all others → `ORDER BY id`)
  - `final backupJson = jsonEncode(await backupService.buildBackupData())`
  - `restoreDatabaseFromString(backupJson)` (restore already wipes+rebuilds
    the 14 covered tables inside its own transaction — no separate wipe step
    needed)
  - Re-snapshot each covered table and assert deep-equality (`equals()`) vs.
    the pre-export snapshot
  - Verified: guardrail tested manually both ways — removing a table from
    `_coveredTables` (while leaving it in `_tablesToClean`) produces the
    friendly `fail()` message naming the table; removing it from both
    produces a hard failure. Both correctly fail the test.

### 3.3 Frozen restore fixtures

- [x] `test/fixtures/backups/pre_tagging_backup_v1.json` — hand-authored,
  matches the format from before #399 (no `tag_types`/`tags`/`schema_version`
  keys, recipes without `tag_ids`), but **relationally complete**: includes
  recipes, ingredients, meal_plans w/ items, meals w/ history — per
  [[feedback_import_test_data]]
- [x] `test/fixtures/backups/real_device_backup_v1.json` — sanitized excerpt
  of Rodrigo's real export (`gastrobrain_backup_2026-06-15_124709.json`,
  217 recipes / 266 ingredients / 27 meal plans / 111 meals in full). Trimmed
  to a relationally-complete subset: 8 recipes (all `recipe_ingredients`
  preserved), 41 ingredients, 1 meal plan with 4 items (incl. a multi-recipe
  item — primary + side dish), 2 meals (incl. a multi-recipe meal), 1
  `recommendation_history` row. `tag_types`/`tags` arrays are empty (real
  evidence of the #399 wipe — this device's tables were empty), no
  `schema_version` key, no simple-side `ingredients`/`meal_ingredients`, no
  `planned_servings` — i.e. the realistic "current real-world backup" format
  this whole issue exists to guard. Sanitized: recipe `name`/`notes`/`story`/
  `instructions` → generic placeholders; one meal's personal `notes` →
  "Sanitized meal notes." Everything else (ingredient names/units/quantities,
  dates, scores) is real data. The raw unsanitized export was deleted from
  `assets/` after extraction — not committed.
- [x] `test/integration/backup_restore_fixtures_test.dart`:
  - For each fixture: `restoreDatabaseFromString(fixtureContent)`, then assert
    - built-in tag vocabulary present (27 rows: 5 `tag_types` + 22 `tags`,
      per #401)
    - `PRAGMA foreign_key_check` returns empty
    - `recipes` and `ingredients` row counts > 0
  - Both fixtures pass.

### Test execution

- [ ] `flutter test test/integration/backup_round_trip_test.dart`
- [ ] `flutter test test/integration/backup_restore_fixtures_test.dart`
- [ ] `flutter test && flutter analyze` (full suite)

---

## Phase 4: Documentation & Cleanup

- [x] Document the fixture-freezing practice — `docs/testing/BACKUP_FIXTURE_PROTOCOL.md`:
  any backup export format change adds a **new** frozen fixture file;
  existing fixtures are never edited, only added
- [x] `flutter analyze` — no issues (full project)
- [x] `flutter test` — all 2092 tests pass (full suite; one transient flake
  on first run did not reproduce on retry)
- [x] Task #5 (Phase 3.3 real-device fixture) — Rodrigo provided a real
  export; sanitized and added as `test/fixtures/backups/real_device_backup_v1.json`
  + corresponding restore test
- [ ] Commit: `test: add backup round-trip schema coverage and restore fixtures (#402)`
- [ ] Push branch, merge to develop (solo workflow)
- [ ] Close #402

---

## Files to Modify

### Core (Phase 2, pending Q1)
- `lib/core/services/database_backup_service.dart` — add simple-sides export/import

### Test Files
- `test/integration/helpers/backup_seed_helper.dart` — new
- `test/integration/backup_round_trip_test.dart` — new
- `test/integration/backup_restore_fixtures_test.dart` — new
- `test/fixtures/backups/pre_tagging_backup_v1.json` — new
- `test/fixtures/backups/real_device_backup_v1.json` — new

### Documentation
- `docs/testing/BACKUP_FIXTURE_PROTOCOL.md` — new (or append to existing doc)

---

## Acceptance Criteria

### From Issue
- [ ] Round-trip test fails if any non-allowlisted table is not faithfully
  backed up and restored
- [ ] Adding a table via migration without updating backup or allowlist
  breaks the test
- [ ] All frozen fixtures restore successfully with invariants satisfied
- [ ] Real-device fixture included and sanitized
- [ ] All existing tests pass

### Implicit
- [ ] `flutter analyze` clean
- [ ] `flutter test` all pass
- [ ] No new 🔴 Critical watchdog entries beyond the pre-existing
  `database_backup_service.dart` flag

---

## Risk Assessment

**Medium risk** — scope now confirmed larger than the original 3-point
estimate (Phase 2 implementation slice added).

1. **Scope beyond 3 points** — simple-sides coverage (Phase 2) is a real
   implementation slice on top of the testing work. *Mitigation*: none
   needed for execution; flag actual effort vs. estimate at retro time
   ([[feedback_estimation_multipliers]] — informs future estimates, not
   this one).
2. **Real-device fixture is a manual step** — Rodrigo provides the export;
   Claude sanitizes. *Mitigation*: can proceed with everything else first
   and slot the fixture in at Phase 3.3.
3. **`database_backup_service.dart` already over length threshold** — any
   edit makes an already-flagged file larger. *Mitigation*: keep additions
   minimal and pattern-consistent; no speculative refactor in this issue.

---

## Decisions (2026-06-15)

1. **Simple-sides coverage**: Extend `DatabaseBackupService` now (Phase 2,
   Option A). Closes a real data-loss gap before it becomes a second
   incident.
2. **Shopping list tables**: Allowlist `shopping_lists`/`shopping_list_items`
   as regenerable via `ShoppingListService.generateFromDateRange()`. Note the
   `to_buy` checkbox caveat in the allowlist comment — minor UX loss, not
   data loss; revisit only if it matters later.
3. **Real-device fixture**: Rodrigo will provide a real export now (Option A)
   — Claude sanitizes recipe names/notes/story text and adds it as
   `test/fixtures/backups/real_device_backup_sanitized.json`.

## Notes

**Assumptions**:
- "Faithfully backed up and restored" means row-count + per-column value
  equality after `ORDER BY id`, not byte-identical JSON.
- `schema_migrations` / `android_metadata` / `sqlite_sequence` /
  `schema_migrations_errors` (if present) are allowlisted as system tables —
  confirm `schema_migrations_errors` exists during Phase 1 kickoff.

**Follow-Up Work**:
- `database_backup_service.dart` split/refactor remains in
  `.github/refactoring-backlog.md` — not addressed here.

**References**:
- Issue: #402
- Related: #399, #400, #401
- Memory: [[project_backup_guardrails]], [[feedback_import_test_data]]

---

**Roadmap Created**: 2026-06-15
**Last Updated**: 2026-06-15
**Status**: Phases 1-4 complete. Only the final commit/push/merge/close
remains, pending Rodrigo's go-ahead.
