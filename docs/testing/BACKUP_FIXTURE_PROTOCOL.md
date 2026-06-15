# Backup Fixture Protocol

This document describes how frozen backup fixtures are used to prove that old
`DatabaseBackupService` export formats continue to restore safely as the
schema evolves (issue #402).

## Why frozen fixtures

`DatabaseBackupService.buildBackupData()` reflects the *current* schema.
Without a frozen copy of what older versions of the app actually exported,
a change to `_restoreFromJson()` could silently break restores for users who
still have backups from an older app version. Each fixture is a snapshot of a
real (or realistic) backup format from a specific point in the app's history.

## Location

```
test/fixtures/backups/
```

## The rule: never edit, only add

**Existing fixture files are immutable.** If a backup format change is made
(a new exported key, a renamed column, a new table), add a **new** fixture
file capturing the new format — do not modify an existing fixture.

This means the fixture set grows over time, and each fixture continues to
prove that its corresponding historical format restores correctly.

Naming convention: `<descriptive_name>_v<N>.json`, e.g.
`pre_tagging_backup_v1.json`.

## Current fixtures

| Fixture | Represents |
|---|---|
| `pre_tagging_backup_v1.json` | A backup created before #399 — no `tag_types`/`tags`/`schema_version` keys, recipes without `tag_ids`, meal plan items without simple-side `ingredients`/`planned_servings`, meals without `meal_ingredients`. Relationally complete: recipes, ingredients, a meal plan with an item, a cooked meal, and recommendation history. |
| `real_device_backup_v1.json` | A sanitized excerpt of a real export taken from Rodrigo's device (2026-06-15), trimmed to a relationally-complete subset (8 recipes, 41 ingredients, 1 meal plan with 4 items including a multi-recipe item, 2 meals including a multi-recipe meal, 1 recommendation history record). `tag_types`/`tags` keys are present but **empty** — the real-world #399 tag-wipe scenario — and there is no `schema_version` key, no simple-side `ingredients`/`meal_ingredients`, and no `planned_servings`. Recipe `name`/`notes`/`story`/`instructions` and one meal's personal `notes` are replaced with generic placeholder text; all other fields (ingredients, quantities, units, dates, scores) are real. |

## Invariants every fixture restore must satisfy

`test/integration/backup_restore_fixtures_test.dart` restores each fixture
via `restoreDatabaseFromString()` and asserts:

- Built-in tag vocabulary is present: 5 `tag_types` + 22 `tags` (#401) — this
  is the self-healing behavior from #399/#400, which fills in tag vocabulary
  missing from older backups via `seedBuiltInTagVocabulary()`.
- `PRAGMA foreign_key_check` returns no rows (no dangling references).
- `recipes` and `ingredients` are non-empty.

## Adding a new fixture

1. Hand-author (or sanitize a real export into) a new JSON file under
   `test/fixtures/backups/`, following the naming convention above.
2. Add a restore test for it in `test/integration/backup_restore_fixtures_test.dart`
   using `_expectValidRestore()`.
3. If the fixture represents real user data, sanitize recipe names, notes,
   story text, and any other free-text fields before committing.

## Related test

`test/integration/backup_round_trip_test.dart` is the complementary
guardrail: it enumerates every table in `sqlite_master` against the *current*
schema and fails if a table is neither exported/restored by
`DatabaseBackupService` nor explicitly allowlisted. Together, the two tests
cover both directions — "does the current schema stay fully covered" and
"do old backup formats still restore".
