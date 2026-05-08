# Database Migration Workflow

This document captures the rules, conventions, and checklists for Gastrobrain's database migration system. It was written after the 0.2.6 emergency release (issue #372) to prevent the same class of failure from recurring.

---

## Migration System Overview

Gastrobrain uses a custom `MigrationRunner` backed by a `schema_migrations` table with four columns:

```
version INTEGER PRIMARY KEY
applied_at TEXT NOT NULL
description TEXT NOT NULL
duration_ms INTEGER NOT NULL
```

The runner detects pending work by **set membership**: it fetches all applied version numbers and runs any registered migration whose version is not in that set. This replaced the old `MAX(version)` approach after issue #372 revealed that MAX-based detection silently skips migrations when legacy version numbers (1–11) are higher than newly-added migration numbers (2–8).

---

## Version Numbering Convention

### Current era: 101–199

After the 0.2.4 consolidation (issue #292), the active migration range is **101–199**:

| File | Class | Version |
|---|---|---|
| `001_initial_schema.dart` | `InitialSchemaMigration` | 101 |
| `002_add_ingredient_aliases.dart` | `AddIngredientAliasesMigration` | 102 |
| `003_add_marinating_time.dart` | `AddMarinatingTimeMigration` | 103 |
| `004_add_recipe_story.dart` | `AddRecipeStoryMigration` | 104 |
| `005_add_tags.dart` | `AddTagsMigration` | 105 |
| `006_add_meal_role_food_type.dart` | `AddMealRoleFoodTypeMigration` | 106 |
| `007_migrate_category_to_tags.dart` | `MigrateCategoryToTagsMigration` | 107 |
| `008_add_sauce_food_type.dart` | `AddSauceFoodTypeMigration` | 108 |

**Why 101+?** Existing users' `schema_migrations` tables contain rows v1–v11 from before the consolidation. Numbering new migrations in the 101+ range ensures set membership never confuses legacy markers with current migrations.

### Adding a new migration

The next migration must be **109**, using filename `009_<description>.dart`. Continue incrementing from there: 110, 111, etc.

**Never reuse numbers 1–11** — those are permanently reserved by legacy device state.

### Future consolidation events

If a second consolidation ever happens (collapsing 101–1xx into a new baseline), the next era starts at **201**. The same principle applies: the new floor must exceed the highest number that any live device could have in `schema_migrations`.

---

## Rules

### 1. Test changes are atomic with code changes

When you change a migration's version number, rename a migration class, or change what `up()` creates — **update the corresponding tests in the same commit**. Do not leave tests that assert stale version numbers.

Files to check whenever migration code changes:
- `test/database/migration_consolidation_test.dart`
- `test/core/services/database_backup_service_test.dart`
- Any test that references a migration class or version number literal

### 2. Backup service setUp must match the service's table scope

`DatabaseBackupService.restoreDatabaseFromString()` clears and restores every table it knows about. If you add a new table to that scope, **also apply the migration that creates that table in the test setUp**:

```dart
setUp(() async {
  db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
  await InitialSchemaMigration().up(DatabaseWrapper(db));  // tables 001→101
  await AddTagsMigration().up(DatabaseWrapper(db));        // adds recipe_tags — required if backup clears it
  // ... add further migrations as needed
});
```

Failing to do this produces a `no such table` exception at `DELETE FROM <table>` — the exact failure from the 0.2.6 post-mortem.

### 3. New migrations must be idempotent

All `CREATE TABLE` and `CREATE INDEX` statements must use `IF NOT EXISTS`. All seed `INSERT` statements must use `INSERT OR IGNORE`. This allows `up()` to be called safely on a database that partially ran the migration.

### 4. validate() must reflect the actual contract

Every migration must implement `validate()` to return `false` before `up()` and `true` after. Tests must cover both states. This is what lets the Schema Inspector (developer tools) confirm production DB health.

---

## Checklist: Adding a New Migration

- [ ] File named `00N_<description>.dart`, class named `<Description>Migration`
- [ ] `version` getter returns the **next number in the 101+ sequence**
- [ ] `up()` uses `IF NOT EXISTS` on all `CREATE TABLE` / `CREATE INDEX`
- [ ] `up()` uses `INSERT OR IGNORE` on all seed data
- [ ] `down()` undoes exactly what `up()` did (or is documented as a no-op)
- [ ] `validate()` returns `false` before `up()`, `true` after
- [ ] Migration registered in `DatabaseHelper._migrations` list
- [ ] Tests cover: `up()`, `validate()` before and after, `down()` if reversible
- [ ] If the migration adds a table that the backup service clears → update backup service + backup service test setUp
- [ ] `flutter test test/database/migration_consolidation_test.dart` passes
- [ ] `flutter test test/core/services/database_backup_service_test.dart` passes
- [ ] `flutter analyze` clean

---

## Checklist: Changing Migration Version Numbers

- [ ] Identify every test that asserts the old version number as a literal
- [ ] Update those assertions in the **same commit** as the version change
- [ ] Re-check Scenario 3 in `migration_consolidation_test.dart` — it simulates a "fully migrated device" and seeds specific version numbers into `schema_migrations`
- [ ] Run `flutter test` before committing

---

## What the 0.2.6 Emergency Taught Us

**Root cause chain:**

1. Issue #292 consolidated migrations 001–011 → single baseline at version=1. New migrations after that were numbered 2–8.
2. The runner used `MAX(version)` to detect pending work.
3. Existing users had legacy rows v1–v11. `MAX(11) > 8` → migrations 2–8 silently skipped on every existing device.
4. Tags, recipe editing, meal_role, food_type — broken since 0.2.4. No error, no crash.

**Fix (#372):**
- Renumbered migrations to 101–108 (safely above the legacy ceiling of 11)
- Switched detection to set membership (`_getAppliedVersions`)
- Added `IF NOT EXISTS` to migration 101 for safe re-execution

**What wasn't done at the time of the fix (test debt):**
- `migration_consolidation_test.dart` Scenario 3 still asserted `getLatestVersion() == 1` and `needsMigration() == false` for a DB seeded with v1–v11 — both now wrong
- `database_backup_service_test.dart` setUp was not updated after `73d1522` expanded the backup service to cover tag tables

These are tracked in issues #373 and #374.
