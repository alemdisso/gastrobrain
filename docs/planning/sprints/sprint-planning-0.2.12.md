# Sprint Plan: 0.2.12 — Architecture & Editor

**Sprint Period**: After 0.2.11 lands — est. ~5 working days
**Milestone**: 0.2.12 — Architecture & Editor
**Total Story Points**: 34 raw (33.5 adjusted)
**Target Velocity**: 6.5 points/day (cruising, 30 pts/week)

> **Prerequisite**: 0.2.11 must be fully merged before this sprint starts.
> #383 depends on the `schema_migrations_errors` table and `recordError()` from #382.
> **Sprint character**: Pure architecture — no UI work, no mobile tooling overhead,
> no L10N changes. Expect execution-mode velocity on well-scoped refactors.

---

## Sprint Goal

Complete the database safety layer (auto-rollback) and clean up the two largest
architectural bottlenecks before the recipe redesign work in 0.2.13 builds on top
of them. By end of sprint: migration failures recover automatically; `DatabaseHelper`
is no longer a 2,255-line god class; recipe editor and ingredient parser are each
behind their own service boundary.

Key deliverables:
- Migration failure → automatic rollback to last known good schema; fatal failures
  route to a blocking error screen instead of launching with broken state
- `database_helper.dart` split into domain-specific DAOs
- `recipe_editor_screen.dart` split into focused components
- `IngredientParserService` extracted as a standalone, reusable service

---

## Capacity Analysis

### Base Calculation
- **Available days**: 5 days
- **Cruising velocity**: 6.5 pts/day (30 pts/week)
- **Base capacity**: 5 × 6.5 = 32.5 pts raw

### Work Type Adjustments

| Issue | Raw pts | Multiplier | Reason | Adjusted |
|-------|---------|------------|--------|----------|
| #383 DB rollback | 8 | 1.0x | Well-specified backend; `rollbackToVersion()` already exists; new screen is contained | 8.0 |
| #283 Extract IngredientParserService | 5 | 0.8x | Mechanical extraction; established service pattern; enabler for 0.2.13 | 4.0 |
| #337 Split database_helper into DAOs | 13 | 1.1x | 2,255-line file; DAO boundaries need upfront decision; MockDatabaseHelper update cascades | 14.3 |
| #336 Split recipe_editor_screen | 8 | 0.9x | Component extraction; established pattern (post-#337 architecture is cleaner template) | 7.2 |

**Total adjusted**: 33.5 pts
**Days at cruising**: 33.5 ÷ 6.5 = 5.2 days → plan for 5 days; pure architecture
work at this stage of the project typically runs at or above cruising

### Capacity Decision
- **Target**: 34 raw / 33.5 adjusted
- **Confidence**: Medium-High — no UI work, no discovery overhead; risk is
  #337's MockDatabaseHelper cascade and call site updates taking longer than expected
- **Flex lever**: #336 component polish (after extraction, fine-grained widget splitting
  can be deferred)

---

## Issues Breakdown

### Theme 1: DB Safety Completion (1 issue, 8 pts)

#### #383 — Auto-rollback to last known good schema version on migration failure
- **Story Points**: 8 (8.0 adjusted)
- **Type**: Technical debt / Safety
- **Priority**: P2-Medium (anchors sprint; completes the safety layer started in #382)
- **Multiplier**: 1.0x — `rollbackToVersion()` exists; `severity` column added in #382
- **Dependencies**: #382 must be merged (provides `schema_migrations_errors` + `recordError()`)
- **Risk**: Medium — `MigrationErrorScreen` routing through `main.dart` may have edge
  cases around widget tree readiness; plan for one debugging cycle
- **Acceptance Criteria**:
  - [ ] `_initializeMigrationSystem` captures `versionBeforeMigrations` before any migration runs
  - [ ] On migration failure: `rollbackToVersion(versionBeforeMigrations)` attempted before recording error
  - [ ] Rollback success → `severity = 'warning'`; Snackbar shown; app launches normally
  - [ ] Rollback failure → `severity = 'fatal'`; app routes to `MigrationErrorScreen`
  - [ ] `MigrationErrorScreen` shows no raw stack traces in release mode; technical detail in debug mode
  - [ ] Migrations with no-op `down()` (e.g. 107) do not cause rollback to be treated as failed
  - [ ] No warning/fatal screen when all migrations succeed
  - [ ] Localized in EN and PT-BR
  - [ ] `test/database/migration_rollback_test.dart` covers: success path, fatal path, no-op down()

**Implementation notes**:
- `severity` column already exists (added in #382's `schema_migrations_errors` table)
- No-op `down()` constraint: document at the rollback call site — rollback proceeds;
  data changes from migrations like 107 persist; this is by design
- Fatal routing: check `getUnsurfacedErrors(severity: 'fatal')` in `HomePage.initState()`
  via `addPostFrameCallback` — same pattern as #382's Snackbar check

---

### Theme 2: Architecture Cleanup (3 issues, 26 pts)

#### #283 — Extract IngredientParserService as reusable ingredient entry method
- **Story Points**: 5 (4.0 adjusted)
- **Type**: Refactor / Technical debt
- **Multiplier**: 0.8x — mechanical extraction, established `ServiceProvider` pattern
- **Dependencies**: None (do before #337 and #336 — it's a clean extraction that informs DAO boundaries)
- **Risk**: Low
- **Acceptance Criteria**:
  - [ ] `IngredientParserService` exists as a standalone service registered in `ServiceProvider`
  - [ ] All call sites updated to use `ServiceProvider.ingredientParser`
  - [ ] No parsing logic remains in screens or other services
  - [ ] All existing parser tests pass unchanged
  - [ ] Enables 0.2.13 (#371) to build a UX layer on top of this service

#### #337 — Split database_helper.dart into domain-specific DAOs
- **Story Points**: 13 (14.3 adjusted)
- **Type**: Refactor / Architecture
- **Multiplier**: 1.1x — 2,255-line file; DAO boundary decisions need upfront design;
  `MockDatabaseHelper` must be updated in parallel
- **Dependencies**: After #283 (parser service already extracted, reducing scope)
- **Risk**: Medium-High — largest item in sprint; MockDatabaseHelper cascade is the
  main risk (every DAO split requires updating mock + tests)
- **Acceptance Criteria**:
  - [ ] Domain DAOs created: `RecipeDao`, `IngredientDao`, `MealDao`, `MealPlanDao`,
        `ShoppingListDao`, `RecommendationDao`
  - [ ] `DatabaseHelper` becomes a thin coordinator or migrates to `ServiceProvider` pattern
  - [ ] `MockDatabaseHelper` updated to reflect new DAO structure
  - [ ] All existing tests pass unchanged
  - [ ] No functionality changes — pure structural refactor

**Implementation notes**:
- Spend 30 min upfront defining DAO boundaries before touching code — prevents mid-refactor backtracking
- Extract one DAO at a time, run `flutter test` after each; don't batch multiple DAOs in one commit
- MockDatabaseHelper is the largest overhead — budget half a day for its update

#### #336 — Split recipe_editor_screen.dart into focused components
- **Story Points**: 8 (7.2 adjusted)
- **Type**: Refactor
- **Multiplier**: 0.9x — established extraction pattern (after #337, architecture template is cleaner)
- **Dependencies**: After #337 (editor can use new DAO/service architecture directly)
- **Risk**: Low-Medium
- **Acceptance Criteria**:
  - [ ] `RecipeEditorScreen` split into focused sub-components (e.g. BasicInfoSection,
        IngredientsSection, TimingSection, TagsSection)
  - [ ] Each component has a single responsibility
  - [ ] File length < 300 lines for each resulting file
  - [ ] All existing editor tests pass
  - [ ] No functionality changes

---

## Day-by-Day Breakdown

### Day 1: DB Safety Completion — #383

**Goal**: Complete the migration safety layer. By end of day, migration failures
auto-rollback and the fatal error screen is routing correctly.

**Issues**:
- **#383** (8.0 adj) — rollback wiring + `MigrationErrorScreen` + routing + L10N + tests
  - Capture `versionBeforeMigrations` in `_initializeMigrationSystem`
  - Wire `rollbackToVersion()` into catch block; record severity
  - Create `lib/screens/migration_error_screen.dart`
  - Add fatal check in `HomePage.initState()` via `addPostFrameCallback`
  - Add EN/PT-BR strings; run `flutter gen-l10n`
  - Write `test/database/migration_rollback_test.dart`

**Testing**: Rollback test file is the Day 1 deliverable alongside implementation
**Risk**: Widget tree readiness for fatal routing — test this path manually on device

---

### Day 2: Architecture — Extract IngredientParserService (#283)

**Goal**: IngredientParserService is standalone, registered in ServiceProvider, all
call sites updated. Clean foundation for 0.2.13's UX work.

**Issues**:
- **#283** (4.0 adj) — extract parser; update call sites; verify tests pass

**Why before #337**: Extracting the parser first reduces the scope of #337 (one fewer
responsibility in `DatabaseHelper` or wherever the parser currently lives).

**Testing**: All existing parser tests must pass unchanged after extraction
**Risk**: Low — pattern is well-established

---

### Days 3–4: Architecture — Split DatabaseHelper (#337)

**Goal**: `database_helper.dart` is no longer a god class. One DAO per domain.
`MockDatabaseHelper` updated in parallel.

**Issues**:
- **#337** (14.3 adj) — DAO design (30 min) → extract one DAO at a time → update mock → tests

**Day 3 plan**: Design DAO boundaries (sketch, 30 min) → extract `RecipeDao` + `IngredientDao`
**Day 4 plan**: Extract `MealDao` + `MealPlanDao` + `ShoppingListDao` + `RecommendationDao`;
update `MockDatabaseHelper`; run full test suite; verify no functionality changes

**Testing**: `flutter test` after each DAO extraction — catch regressions immediately
**Risk**: MockDatabaseHelper update cascade — largest hidden overhead in this sprint

---

### Day 5: Architecture — Split Recipe Editor (#336)

**Goal**: `recipe_editor_screen.dart` is split into focused components, each under 300 lines.

**Issues**:
- **#336** (7.2 adj) — identify component boundaries → extract sections → verify tests

**Why last**: Cleanest to do after #337 — the new DAO/service architecture provides
a cleaner template for how editor components should access data.

**Stretch Goals** (if Day 5 finishes early):
- Add size labels to new files in refactoring-backlog (housekeeping)
- Begin UX design sketching for 0.2.13 (#370, #371) — no code, just notes

**Testing**: All existing editor tests pass; no visual regressions
**Risk**: Low — mechanical extraction following established pattern

---

## Risk Assessment

### High Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| #337 MockDatabaseHelper cascade larger than expected | +1 day | Medium | Extract one DAO at a time; `flutter test` after each; stop and assess if cascade grows |
| #383 fatal routing edge cases | +2-4 hrs | Low-Medium | Test fatal path manually on device Day 1 |

### Medium Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| #337 DAO boundary decisions cause mid-refactor backtracking | +2-4 hrs | Low-Medium | 30-min design sketch before first line of code |

### Low Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| #336 reveals unexpected state management coupling | +2-4 hrs | Low | Assess coupling during #337 — flag as follow-up if too deep |

### Risk Mitigation Summary
- **Pure architecture sprint**: No UI, no mobile tooling overhead, no L10N churn — expect cruising-to-execution velocity
- **One DAO at a time**: #337's risk is bounded by running tests after each extraction
- **Flex lever**: #336 component granularity — must-ship is under-300-line files; additional splitting is deferrable

---

## Testing Strategy

### #383 — New test file
- `test/database/migration_rollback_test.dart` (sqflite_ffi)
- Inject failing migration → assert rollback runs → assert DB at `versionBeforeMigrations`
- Inject failing `down()` → assert `severity = 'fatal'` recorded
- No-op `down()` migration that fails `up()` → assert rollback treated as success
- Happy path: all migrations succeed → no error table rows

### #283, #337, #336 — Existing tests must pass unchanged
- Run `flutter test` after every extraction step
- No new test files required (functionality unchanged)
- MockDatabaseHelper update: verify all mock-based unit tests still pass

### No L10N testing required
- Only #383 has new strings (2 fatal error screen strings); test both languages manually

---

## Dependencies & Prerequisites

### Blocking
- #383 blocked on #382 (must be merged before Day 1 starts)

### Ordering within sprint
- #283 before #337 (reduces DAO scope)
- #337 before #336 (architecture template established)
- #383 is independent; do first (anchors sprint, highest safety priority)

---

## Success Criteria

### Primary Goals (Must Complete)
- [ ] #383 merged — migration failures auto-rollback; fatal state routes to error screen
- [ ] #283 merged — IngredientParserService standalone in ServiceProvider
- [ ] #337 merged — DatabaseHelper split into domain DAOs
- [ ] #336 merged — RecipeEditorScreen split into focused components
- [ ] All files under 300 lines post-refactor
- [ ] `flutter test && flutter analyze` pass
- [ ] MockDatabaseHelper fully updated

### Secondary Goals
- [ ] #337 DAO design document (even 10 lines in a comment) preserved as reference
- [ ] `refactoring-backlog.md` entries for #337 and #336 closed

### Stretch Goals
- [ ] Preliminary UX notes for 0.2.13 (#370, #371) — no code, just design thinking

---

**Plan Created**: 2026-05-16
**Plan Author**: Claude Code
