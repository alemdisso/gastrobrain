# Sprint Plan: 0.2.7 — Code Health

**Sprint Period**: May 6–8, 2026 (~2 working days)
**Milestone**: 0.2.7 — Code Health
**Total Story Points**: 15 raw (8.3 adjusted)
**Target Velocity**: 6 pts/day (cruising, 30 pts/week)

> **Gate for 0.2.8**: This sprint must land before 0.2.8 starts. P1 test fixes
> (#378, #379) and the parser confidence bug (#364) need to be clean before
> range quantity parsing is added on top of the same service.

---

## Sprint Goal

Clear the P1 test failures left by the 0.2.6 schema migration, fix the two
most friction-producing UX bugs reported during real-world testing, and do the
category column cleanup promised after #335. Small enough to finish in ~2 days;
disciplined enough to leave the codebase genuinely cleaner.

Key deliverables:
- CI green: both P1 test failures resolved
- `recipes.category` column permanently dropped from schema
- Parser no longer traps users behind a low-confidence auto-selection
- "Voltar" in Opções de Refeição navigates to the right screen

---

## Capacity Analysis

### Base Calculation
- **Available days**: 2 days
- **Cruising velocity**: 6 pts/day
- **Base capacity**: 12 pts raw

### Work Type Adjustments

| Issue | Raw pts | Multiplier | Reason | Adjusted |
|-------|---------|------------|--------|----------|
| #378 Fix migration_consolidation_test | 1 | 0.3x | Known target — specific assertion update, post-usage fix pattern | 0.3 |
| #379 Fix database_backup_service_test | 2 | 0.3x | Known target — add tag migrations to setUp | 0.6 |
| #375 Fix 'Variedade' empty header | 1 | 0.3x | Trivial — remove orphaned header widget | 0.3 |
| #367 App version in Settings | 1 | 0.5x | Quick feature — add `package_info_plus`, display in Settings | 0.5 |
| #364 Parser auto-selects low confidence | 3 | 0.5x | 1-line condition at exact location; well-specified bug | 1.5 |
| #366 Fix 'Voltar' navigation | 3 | 0.5x | 1-line if-else at exact location; well-specified bug | 1.5 |
| #377 Drop recipes.category column | 2 | 1.0x | Simple migration; must verify no remaining Dart references | 2.0 |
| #355 DI for IngredientsScreen | 2 | 0.8x | Mechanical wire-up, established pattern from other screens | 1.6 |

**Total adjusted**: 8.3 pts
**Days at cruising**: 8.3 ÷ 6 = 1.4 days → plan for 2 days; likely finishes Day 2 by noon

### Capacity Decision
- **Target**: 15 raw / 8.3 adjusted
- **Confidence**: High — every issue has exact file+line or is a trivial removal
- **Note**: This sprint runs fast. If all 8 issues close by noon Day 2, pull #374 from 0.2.9 as a stretch goal

---

## Issues Breakdown

### Theme 1: P1 Test Fixes (2 issues, 3 pts)

#### #378 — testing: fix migration_consolidation_test Scenario 3 after #372 renumbering
- **Story Points**: 1 (0.3 adjusted)
- **Type**: Test fix — known target
- **Risk**: Low — well-isolated test assertion update
- **Context**: #372 renumbered post-consolidation migrations to 101–108 and switched to set-membership detection. Scenario 3 assertions reference old version numbers.

#### #379 — testing: fix database_backup_service_test setUp missing tag table migrations
- **Story Points**: 2 (0.6 adjusted)
- **Type**: Test fix — known target
- **Risk**: Low
- **Context**: `restoreDatabaseFromString()` now clears/restores tag tables, but test setUp only runs `InitialSchemaMigration().up()` — missing the tag migrations that create `tags`, `tag_types`, `recipe_tags`.

---

### Theme 2: DB Housekeeping (1 issue, 2 pts)

#### #377 — chore: drop recipes.category column from DB schema
- **Story Points**: 2 (2.0 adjusted)
- **Type**: DB chore
- **Risk**: Low — #335 already removed all Dart code references; this is the deferred column drop
- **Key tasks**:
  - Confirm no remaining `category` references: `grep -r "\.category" lib/` and `grep -r "category" lib/database/`
  - Write migration: `ALTER TABLE recipes DROP COLUMN category` (SQLite 3.35+ supports DROP COLUMN)
  - Verify existing data unaffected
  - Update any mock/test database setup that creates the `recipes` table

---

### Theme 3: UX Bugs (2 issues, 6 pts)

#### #364 — bug: ingredient parser auto-selects low-confidence matches
- **Story Points**: 3 (1.5 adjusted)
- **Type**: Bug — well-specified, 1-line fix
- **Risk**: Low-Medium — fix is trivial; regression risk is that high-confidence matches still auto-select correctly
- **Root cause**: `lib/screens/recipe_editor_screen.dart:415-416` — no confidence threshold on auto-selection
- **Fix**: Add `&& result.matches.first.confidence >= 0.80` to the auto-selection condition
  - Threshold 0.80 already established in `IngredientMatchingService` as the medium/high boundary
- **Scope warning**: `recipe_editor_screen.dart` is 2,305 lines (🔴 Critical in backlog). Fix the bug only — do not refactor surrounding code.

#### #366 — bug: 'Voltar' in Opções de Refeição navigates to wrong screen
- **Story Points**: 3 (1.5 adjusted)
- **Type**: Bug — well-specified, 1-line fix
- **Risk**: Low
- **Root cause**: `lib/widgets/recipe_selection_dialog.dart:468` — "Voltar" always sets `_showingMenu = false` regardless of entry flow
- **Fix**: `if (widget.initialPrimaryRecipe != null) Navigator.pop(context) else setState(() { _showingMenu = false; _selectedRecipe = null; })`
  - `initialPrimaryRecipe` is already the correct discriminator (non-null only in edit/week-plan flow)
- **Scope warning**: `recipe_selection_dialog.dart` is 558 lines (🔴 Critical in backlog). Fix navigation only.

---

### Theme 4: Quick Enhancement + DI Refactor (2 issues, 3 pts)

#### #367 — enhancement: show app version in Settings screen
- **Story Points**: 1 (0.5 adjusted)
- **Type**: Enhancement — trivial
- **Risk**: Low
- **Key tasks**: Add `package_info_plus` to pubspec (`flutter pub add package_info_plus`); call `PackageInfo.fromPlatform()` in Settings screen; display `version` + `buildNumber`; EN + PT-BR strings

#### #355 — refactor: add DatabaseHelper DI to IngredientsScreen for testability
- **Story Points**: 2 (1.6 adjusted)
- **Type**: Refactor — mechanical DI wire-up
- **Risk**: Low — follow existing pattern from `RecipeDetailsScreen`, `WeeklyPlanScreen`, etc.
- **Key tasks**: Add `final DatabaseHelper? databaseHelper` optional parameter to `IngredientsScreen`; replace singleton `DatabaseHelper()` with `databaseHelper ?? DatabaseHelper()`; add basic tests using `MockDatabaseHelper`

---

## Day-by-Day Breakdown

### Day 1: P1 Fixes + UX Bugs (11 pts raw / 4.2 adjusted)

**Goal**: CI green by mid-morning. Both UX bugs fixed by end of day.

- **#378** (1 pt → 0.3 adj) — Fix migration_consolidation_test Scenario 3
  - Why first: P1 — unblock CI immediately; known fix, no analysis needed
  - Deliverable: Scenario 3 assertions updated; `flutter test` passes for this file

- **#379** (2 pts → 0.6 adj) — Fix database_backup_service_test setUp
  - Why second: P1 — same CI-green goal; setUp needs the missing tag migrations
  - Deliverable: Tag table migrations added to setUp; all backup service tests pass

- **#375** (1 pt → 0.3 adj) — Remove 'Variedade de Receitas' orphaned header
  - Why now: Trivial removal while still in "bug-fix" mode; 10 minutes
  - Deliverable: Header widget removed; week plan summary shows no orphaned section

- **#364** (3 pts → 1.5 adj) — Parser confidence threshold
  - Why now: Stays in parser/ingredient mental context after #379; fix is 1-line at exact location
  - Deliverable: `recipe_editor_screen.dart:415-416` updated; "Create New Ingredient" button visible for low-confidence matches; high-confidence auto-select unchanged; regression tests added

- **#366** (3 pts → 1.5 adj) — Fix 'Voltar' navigation
  - Why now: Second well-specified bug fix; independent of everything else
  - Deliverable: `recipe_selection_dialog.dart:468` updated; edit-mode "Voltar" closes dialog; add-mode "Voltar" returns to selection (regression covered)

**Testing**: Unit test for confidence threshold (#364); widget tests for both navigation flows (#366). Run `flutter test` before end of day.

**Risks**: #364 regression — high-confidence auto-select must still work. Test this explicitly.

---

### Day 2: DB Cleanup + Enhancement + Refactor (4 pts raw / 4.1 adjusted)

**Goal**: Drop the category column, ship app version, wire up DI. Done by noon.

- **#377** (2 pts → 2.0 adj) — Drop recipes.category column
  - Why first: DB migration early in the day (small recovery window if issues)
  - Start by confirming zero remaining `.category` references in Dart code
  - Deliverable: Migration runs; `recipes` table has no `category` column; all tests pass; mock DB setUp updated if needed

- **#367** (1 pt → 0.5 adj) — App version in Settings
  - Why now: Quick feature; add `package_info_plus`, display version, localize
  - Deliverable: Settings screen shows version + build number; both EN + PT-BR

- **#355** (2 pts → 1.6 adj) — DI for IngredientsScreen
  - Why last: Mechanical refactor, best when other issues are done; lowest risk if interrupted
  - Reference pattern: `lib/screens/weekly_plan_screen.dart` constructor for DI pattern
  - Deliverable: `IngredientsScreen` accepts optional `databaseHelper`; unit tests with `MockDatabaseHelper`

**Stretch Goals** (if done before noon):
- **#374** — Show side dish recipe names in week plan card (3 pts, from 0.2.9) — a natural pull-in given the small sprint size

**Testing**: Run full `flutter test && flutter analyze` before closing the sprint.

---

## Risk Assessment

### Medium Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| #364 regression — high-confidence auto-select breaks | CI failure | Low | Explicit test: `cebola` still auto-selects; run existing parser tests first |
| #377 — SQLite version on device doesn't support `DROP COLUMN` (requires 3.35+) | Blocker | Low | Flutter/Android ships SQLite 3.39+; verify in migration runner; fallback: recreate table |
| #355 — `IngredientsScreen` has unexpected DB call patterns | Extra scope | Low | Read file before starting; scope to constructor param only |

### Low Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| `package_info_plus` pub.dev fetch blocked by Windows Defender | Day 2 delay | Low | Known risk (see memory); if blocked, add firewall exception for Dart |

---

## Testing Strategy

### #378 / #379 — Test fixes
- Target files: `test/database/migration_consolidation_test.dart`, `test/services/database_backup_service_test.dart`
- Verify the specific failing assertions; run full test file after fix

### #364 — Parser confidence threshold
- Regression: existing high-confidence cases still auto-select
- New: low-confidence case shows "Create New Ingredient" button
- New: user manual selection of low-confidence match is respected

### #366 — Navigation fix
- Widget test: edit mode → "Voltar" → dialog dismissed
- Widget test: add mode → "Voltar" → back to recipe selection (regression)
- Widget test: "Cancelar" still works in both modes

### #355 — DI refactor
- `MockDatabaseHelper` passed → used (not the singleton)
- No `MockDatabaseHelper` passed → singleton used (backward compat)

### Localization
- #367 only: add `appVersion` / `buildNumber` strings to `app_en.arb` + `app_pt.arb`; run `flutter gen-l10n`

---

## Database Migration Plan

### Migration: Drop `recipes.category` column
- **Issue**: #377
- **Type**: Simple column removal
- **Pre-check**: `grep -r "\.category\b" lib/` must return zero results
- **Change**: `ALTER TABLE recipes DROP COLUMN category` (SQLite ≥ 3.35)
- **Fallback if DROP COLUMN unsupported**: Recreate `recipes` table without column + copy data (migration runner handles versioning)
- **Testing**:
  - [ ] Existing recipes load correctly post-migration
  - [ ] No Dart code references `.category` on a `Recipe`
  - [ ] Mock DB setUp files updated if they CREATE TABLE recipes with category column

---

## Success Criteria

### Primary Goals (Must Complete)
- [ ] `flutter test` passes — zero failures (#378, #379 resolved)
- [ ] `recipes.category` column gone from schema (#377)
- [ ] Parser no longer auto-selects confidence < 0.80 (#364)
- [ ] "Voltar" navigation correct in both flows (#366)
- [ ] `flutter analyze` passes clean

### Secondary Goals (Should Complete)
- [ ] App version visible in Settings (#367)
- [ ] `IngredientsScreen` accepts DI (#355)
- [ ] Both EN + PT-BR tested for #367

### Stretch Goals (If Done Before Noon Day 2)
- [ ] #374 — Side dish recipe names in week plan card (from 0.2.9)

### Quality Gates
- [ ] No scope creep into refactoring on #364 or #366 (both touch 🔴 Critical files)
- [ ] Category column confirmed absent from all test fixtures and mock DB setups
- [ ] High-confidence auto-select regression explicitly tested after #364

---

## Notes & Assumptions

### Assumptions
- SQLite ≥ 3.35 available on target devices (supports `DROP COLUMN`)
- `IngredientParserService` at `lib/core/services/ingredient_parser_service.dart` (confirmed) — #364 touches `recipe_editor_screen.dart:415` which calls it

### Known Limitations
- #364 and #366 both touch 🔴 Critical files in the refactoring backlog. Scope strictly to the bug fix — no opportunistic cleanup.

### Follow-Up Work
- Once this sprint lands, #357 (range quantities) can safely extend `IngredientParserService` on a clean confidence-threshold baseline

### References
- Sprint Estimation Diary: `docs/archive/Sprint-Estimation-Diary.md`
- Refactoring Backlog: `.github/refactoring-backlog.md`
- Migration runner: `lib/core/migration/migration_runner.dart`

---

**Plan Created**: 2026-05-06
**Plan Author**: Claude Code + alemdisso
**Last Updated**: 2026-05-06
