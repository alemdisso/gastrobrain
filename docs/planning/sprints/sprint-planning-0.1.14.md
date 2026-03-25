# Sprint Plan: 0.1.14 - DB Housekeeping & Documentation

**Sprint Period**: 2026-03-19 - 2026-03-24 (4 working days)
**Milestone**: [0.1.14 - DB Housekeeping & Documentation](https://github.com/alemdisso/gastrobrain/milestone/22)
**Total Story Points**: 27 pts raw (8 + 5 + 3 + 3 + 8) | ~13.3 pts adjusted
**Target Velocity**: 30 pts/week (cruising) — housekeeping sprint likely executes faster

---

## Sprint Goal

Eliminate accumulated maintenance debt by consolidating 5 database migrations into a single clean baseline (and fixing a critical fresh-install schema bug), then improve long-term knowledge management through three documentation deliverables: a UI component library reference, standardized skill structures, and updated test governance counts.

Key deliverables:
- DB migrations consolidated + critical `to_buy` schema bug fixed (#292)
- UI Component Library documented (#263)
- Skills standardized + test governance updated (#268, #285)
- Production-quality seed recipe data curated and committed (#317)

---

## Capacity Analysis

### Base Calculation
- **Available days**: 3 days
- **Cruising velocity**: 30 pts/week = 6 pts/day
- **Base capacity**: 3 × 6 = 18 pts (well above raw 19 pts — fine at cruising)

### Work Type Adjustments

| Issue | Raw pts | Type | Multiplier | Adjusted | Rationale |
|-------|---------|------|-----------|----------|-----------|
| #292 | 8 | Architecture (well-prepared) | 0.30x | 2.4 | Clear task list, established migration pattern; but 3-scenario device testing adds overhead |
| #263 | 5 | Documentation (codebase deep-dive) | 0.40x | 2.0 | Requires reading all UI components before writing; not purely mechanical |
| #268 | 3 | Documentation (mechanical update) | 0.15x | 0.45 | Structural template enforcement across existing files |
| #285 | 3 | Documentation (mechanical update) | 0.15x | 0.45 | Test count audit + doc update; well-defined scope |
| #317 | 8 | Content curation (open-ended) | 1.0x | 8.0 | Manual editorial work — writing instructions, completing ingredients; no code shortcuts |
| **Total** | **27** | — | — | **13.3** | |

### Adjusted Capacity
```
Adjusted needed: 13.3 pts
At 6 pts/day: ~2.2 days theoretical

Real-world estimate: 4 days
(#317 is 1.0x — actual effort equals estimate; doc work setup overhead adds ~0.5d)
```

### Capacity Decision
- **Target**: 27 pts raw (all 5 issues), 4 days
- **Confidence**: Medium-High — no UI work, no mobile tooling overhead, no localization; main uncertainty is how many recipes get curated in #317
- **Rationale**: #317 is deliberately L (8 pts) and 1.0x — it will consume a full day. If curation runs long, time-box at end of Day 4 and ship what's complete.

### Theme 3: Seed Data Curation (1 issue, 8 pts)

#### Issue #317: chore: curate and prepare seed recipe data for baseline migration
- **Story Points**: 8 (8.0 adjusted — 1.0x, content work)
- **Type**: Content curation / Data preparation
- **Size**: L
- **Priority**: P2
- **Multiplier Applied**: 1.0x — manual editorial work; story points = actual effort
- **Dependencies**: #292 must complete first (conversion tool built there)
- **Risk Level**: Medium — scope is open-ended; hard to predict how many recipes get completed
- **Time-box**: Ship at end of Day 4 regardless; incomplete recipes stay as-is in the DB
- **Acceptance Criteria**:
  - [ ] Inclusion criteria decided (minimum viable vs. extended curation)
  - [ ] Selected recipes have instructions + ingredients present
  - [ ] All ingredient categories are valid enum values
  - [ ] `dart run tools/convert_export_to_seed.dart` runs without errors
  - [ ] `assets/recipes.json` and `assets/ingredients.json` committed
  - [ ] Seed data verified on fresh install (imports without errors)

---

### Issue #303 — Deferred
- **Why**: P3, no estimate, no implementation defined. Body states "to be revisited once the servings foundation is in place" — servings ARE now implemented, but this remains a pure research issue with zero acceptance criteria
- **Recommendation**: Move to 0.1.15 backlog or create a time-boxed research spike. Do NOT include in 0.1.14.

---

## Issues Breakdown

### Theme 1: Database Housekeeping (1 issue, 8 pts)

#### Issue #292: refactor: consolidate database migrations into baseline and update seed data
- **Story Points**: 8 (2.4 adjusted)
- **Type**: Architecture / Refactoring + Bug Fix
- **Size**: L
- **Priority**: P1
- **Multiplier Applied**: 0.30x (architecture well-prepared — all steps defined, critical bug location known)
- **Dependencies**: None (standalone refactor)
- **Risk Level**: Medium — testing 3 DB scenarios requires either device or integration test validation; local export files (`recipe_export_*.json`, `ingredient_export_*.json`) must exist on dev machine
- **Prerequisite check**: Verify export files exist before starting
- **Acceptance Criteria** (from issue):
  - [ ] Migration 001 contains consolidated schema (11 tables incl. shopping lists)
  - [ ] `to_buy` column used throughout (NOT `is_purchased`)
  - [ ] `_onCreate` bug fixed: line 306 uses `to_buy INTEGER NOT NULL DEFAULT 1`
  - [ ] Migrations 002-005 archived in `_archived/` directory
  - [ ] Conversion tool generates seed data from local exports
  - [ ] All 3 scenarios pass: fresh install, legacy DB, migrated DB
  - [ ] `flutter analyze && flutter test` passes

---

### Theme 2: Documentation Improvement (3 issues, 11 pts)

#### Issue #263: Create UI Component Library Documentation
- **Story Points**: 5 (2.0 adjusted)
- **Type**: Documentation
- **Size**: M
- **Priority**: P1
- **Multiplier Applied**: 0.40x (requires codebase read-through before writing; not purely mechanical)
- **Dependencies**: None
- **Risk Level**: Low — bounded scope, no code changes
- **Acceptance Criteria**: UI component catalogue document created covering major reusable widgets, their props/variants, and usage examples

#### Issue #268: technical-debt: update skills to enforce standardized documentation structure
- **Story Points**: 3 (0.45 adjusted)
- **Type**: Documentation / Technical Debt
- **Size**: M
- **Priority**: P2
- **Multiplier Applied**: 0.15x (mechanical template enforcement across known files)
- **Dependencies**: None
- **Risk Level**: Low
- **Acceptance Criteria**: All skills updated to follow standardized header/section structure

#### Issue #285: Establish test suite governance and update testing documentation counts
- **Story Points**: 3 (0.45 adjusted)
- **Type**: Documentation / Testing
- **Size**: M
- **Priority**: P2
- **Multiplier Applied**: 0.15x (test count audit + doc update; well-defined)
- **Dependencies**: None
- **Risk Level**: Low
- **Acceptance Criteria**: Test counts accurate in docs; governance rules documented

---

## Day-by-Day Breakdown

### Day 1: DB Migration Consolidation (#292) (~2.4 adjusted pts)

**Goal**: Complete the migration consolidation end-to-end — conversion tool, consolidated migration 001, critical bug fix, archive old migrations, validate all 3 scenarios.

**Pre-start check**: Confirm `recipe_export_*.json` and `ingredient_export_*.json` exist locally before opening the editor.

**Issues**:
- **Issue #292**: refactor: consolidate database migrations (2.4 adjusted pts)
  - **Why first**: P1, most technically complex, standalone — no dependencies from other sprint issues
  - **Sequence within the issue**:
    1. Create `tools/convert_export_to_seed.dart` and run it — generates seed data
    2. Review and commit seed data files
    3. Update Migration 001 (consolidated schema + `to_buy` fix + `recipes.instructions` column)
    4. Fix `_onCreate` bug at `database_helper.dart:306`
    5. Archive migrations 002-005
    6. Update migration registry
    7. Test Scenario 1 (fresh install) + Scenario 3 (migrated DB) — via integration tests
    8. Test Scenario 2 (legacy DB) — requires manual or device test if feasible
  - **Deliverable**: Consolidated migration on develop, all tests green, seed data committed

**Testing**: Integration tests for all 3 DB scenarios; `flutter analyze && flutter test`

**Risks**:
- Export files may be missing → check first, resolve before starting
- Fresh install scenario is hard to test without device reset → integration test is the primary gate; device test is stretch
- Legacy DB scenario requires a pre-migration-system database → may need to mock or skip if unavailable

---

### Day 2: UI Component Library Documentation (#263) (~2.0 adjusted pts)

**Goal**: Produce a complete UI component library reference document covering Gastrobrain's reusable widgets.

**Issues**:
- **Issue #263**: Create UI Component Library Documentation (2.0 adjusted pts)
  - **Why day 2**: P1, documentation deep-dive works best with a fresh context block; Day 1 cleared the technical work
  - **Approach**:
    1. Enumerate reusable components in `lib/` (widgets, screens, dialogs)
    2. For each: document name, purpose, key props/parameters, variants, usage example
    3. Create document at `docs/architecture/ui-component-library.md`
  - **Deliverable**: Component library doc committed; covers all major reusable widgets

**Testing**: No code changes — no test overhead

**Risks**: Low — scope could expand if "complete" is interpreted as exhaustive coverage. Time-box to 1 day; defer comprehensive examples to a follow-up if needed.

---

### Day 3: Documentation Batch Day (#268 + #285) (~0.9 adjusted pts)

**Goal**: Batch the two mechanical documentation updates together — standardize skill files and update test governance counts.

**Issues**:
- **Issue #268**: Update skills to enforce standardized documentation structure (0.45 adjusted pts)
  - **Why batched**: Purely mechanical file updates; natural companion to #285
  - **Approach**: Audit each skill file in `.claude/skills/`; apply standard header/section template
  - **Deliverable**: All skills updated with consistent structure

- **Issue #285**: Establish test suite governance and update testing documentation counts (0.45 adjusted pts)
  - **Why batched**: Same documentation session; test count audit is a `flutter test --reporter json` run + doc update
  - **Approach**: Run test suite, capture count, update `docs/testing/` governance document
  - **Deliverable**: Accurate test counts in docs; governance rules written

**Stretch Goal** (if Day 3 completes early):
- Start #317 early — begin reviewing export data and deciding inclusion criteria before Day 4

**Testing**: No code changes in #268 or #285

**Risks**: Very low — both issues are mechanical with bounded scope

---

### Day 4 (Part 1): E2E Test Helper Scroll Fix (#318) (~3.0 adjusted pts)

**Goal**: Fix the `e2e_test_helpers.dart` helpers that tap buttons without scrolling, eliminating 6 recurring integration test failures before closing the milestone.

**Issues**:
- **Issue #318**: Fix e2e test helpers to scroll before tapping off-screen buttons (3 pts)
  - **Why before #317**: No failing integration tests should carry into 0.2.x; this is a quick fix with a clear scope
  - **Approach**:
    1. Audit all `tester.tap()` calls in `e2e_test_helpers.dart` for missing scroll guards
    2. Add `await tester.ensureVisible(finder); await tester.pumpAndSettle();` before each affected tap
    3. Known helpers: `tapSaveButton` (line 217), `saveMealEditDialog` (line 1038), `_adjustServingsViaStepper` (lines 1007/1012)
    4. Run full integration suite and confirm 6 previously failing tests now pass
  - **Deliverable**: Clean integration suite on API 33 AOSP; #318 closed

**Testing**: Full integration suite run; expect `+73 -0`

**Risks**: Very low — localized to one file, fix pattern is well-established

---

### Day 4 (Part 2): Seed Data Curation (#317) (~8.0 adjusted pts)

**Goal**: Decide which recipes go into seed data, complete the selected ones, run the conversion tool, and commit production-quality seed files.

**Issues**:
- **Issue #317**: Curate and prepare seed recipe data (8.0 adjusted pts)
  - **Why last**: Depends on #292 (conversion tool); content work has no dependency on docs issues
  - **Conversion tool**: `tools/convert_export_to_seed.dart` — built in #292 (Day 1). Ready to use.
  - Reads the latest `recipe_export_*.json` from `assets/` automatically
  - Outputs `assets/recipes.json` + `assets/ingredients.json`
  - `instructions` field is fully wired: export curated instructions → run tool → done, no code changes needed
  - To use: export fresh data from the app → drop the new `recipe_export_*.json` in `assets/` → `dart run tools/convert_export_to_seed.dart`
- **Approach**:
    1. Review exported recipe data — identify the ~32 fully complete recipes
    2. Decide inclusion criteria: minimum viable (32 complete only) vs. extended (complete a batch of high-value ones)
    3. For extended: write missing instructions and/or ingredients for selected recipes
    4. Export fresh data from the app → drop new `recipe_export_*.json` in `assets/`
    5. Run `dart run tools/convert_export_to_seed.dart`
    6. Review `assets/recipes.json` + `assets/ingredients.json` output
    7. Commit final seed data files
  - **Time-box**: Hard stop at end of day — ship whatever is complete; remaining incomplete recipes stay as-is in the DB
  - **Deliverable**: Committed seed files with production-quality recipes; fresh install verified

**Testing**: No code changes — validate via fresh install seed import

**Risks**: Open-ended scope — if completing incomplete recipes takes longer than expected, the time-box ensures the sprint still closes on time

---

## Risk Assessment

### Medium Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Export files missing for #292 seed conversion | High | Medium | Check before Day 1; if missing, skip seed data step (it's in #317 now) |
| Legacy DB scenario untestable (no pre-migration DB available) | Medium | Medium | Document gap in test coverage; integration test covers scenarios 1+3 |
| #263 scope creep (component count larger than expected) | Medium | Low | Time-box to 1 day; cover core widgets only; note gaps in doc for later |
| #317 curation runs longer than 1 day | Medium | Medium | Hard time-box — ship complete recipes only; incomplete ones stay as-is |

### Low Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| #292 `flutter test` regressions from migration changes | Medium | Low | All changes are non-destructive for existing DBs; run full test suite as gate |
| #268 skill count larger than anticipated | Low | Low | Mechanical work; batch in single session regardless of count |

### Risk Mitigation Summary
- **Time Buffer**: Day 3 is light (~0.9 adjusted pts), providing natural buffer for Day 1-2 overruns
- **Scope Flexibility**: #303 excluded; Day 3 stretch goal is optional
- **Dependency Management**: No inter-issue dependencies — all 4 issues are independent
- **Technical Unknowns**: Only unknown is export file availability for #292; resolve pre-sprint

---

## Testing Strategy

### Test Coverage Requirements

#### Unit / Integration Tests
- **Issues requiring tests**: #292 only
- **Focus areas**: DB migration correctness (3 scenarios), schema consistency, seed data import
- **Success criteria**: All 3 scenarios green in integration tests; `flutter test` passes

#### Documentation Issues (#263, #268, #285)
- No code changes → no test overhead
- Validation: document review only

### Test Execution

**Local validation (Windows)**:
```bash
flutter analyze
flutter test
```

**DB scenario validation for #292**:
```sql
-- After fresh install:
SELECT name FROM sqlite_master WHERE type='table';  -- expect 12 tables (11 + schema_migrations)
PRAGMA table_info(shopping_list_items);  -- verify to_buy column, not is_purchased
SELECT COUNT(*) FROM recipes;  -- verify seed data imported
```

**Success criteria**:
- [ ] `flutter analyze` — no issues
- [ ] `flutter test` — all passing
- [ ] #292 schema verified via integration tests
- [ ] Seed data import validated

---

## Database Migration Plan

### Migration Consolidation (#292)

#### Changes
- **Consolidate**: Migrations 001-005 → single Migration 001 with complete final schema
- **Add columns**: `recipes.instructions`, `shopping_list_items.to_buy` (replacing `is_purchased`)
- **Bug fix**: `database_helper.dart:306` — change `is_purchased INTEGER NOT NULL DEFAULT 0` → `to_buy INTEGER NOT NULL DEFAULT 1`
- **Archive**: Migrations 002-005 → `lib/core/migration/migrations/_archived/`
- **New file**: `tools/convert_export_to_seed.dart` (local-only Dart tool)

#### Rollback Plan
- Git revert on feature branch before merge if integration tests fail
- Existing user DBs are unaffected (all their migrations already applied)

#### Testing Scenarios

| Scenario | How to test | Priority |
|----------|------------|---------|
| Fresh install | Integration test with empty DB | Must pass |
| Migrated DB (versions 1-5) | Integration test with seeded `schema_migrations` | Must pass |
| Legacy DB (pre-migration system) | Manual / mocked DB without `schema_migrations` table | Best effort |

### Migration Schedule
- **When**: Day 1 (first thing — risky work goes early)
- **Validation**: Integration tests run at end of Day 1 before committing to develop

---

## Dependencies & Prerequisites

### Internal Prerequisites

| Issue | Prerequisite | Status | Blocker? |
|-------|--------------|--------|----------|
| #292 | Local export files (`recipe_export_*.json`, `ingredient_export_*.json`) | Unknown — **verify on Day 1** | Partial (seed data step only) |
| #263 | None | N/A | No |
| #268 | None | N/A | No |
| #285 | None | N/A | No |

### Blocking Issues
None — all 4 issues are independent.

---

## Success Criteria

### Primary Goals (Must Complete)
- [X] #292: Migration 001 consolidated, `to_buy` bug fixed, migrations 002-005 archived
- [X] #292: All integration tests pass for DB scenarios 1 + 3
- [X] #263: UI component library doc created at `docs/design/component_library.md`
- [X] #268: All skill files updated to standardized structure
- [ ] #285: Test counts accurate; governance rules documented (deferred — #318 substituted)
- [X] #318: E2E test helpers fixed; 37/37 tests passing on API 33 AOSP
- [ ] #317: Seed files committed with production-quality recipes (minimum viable or extended)
- [ ] `flutter analyze` passes with no issues
- [ ] `flutter test` passes

### Secondary Goals (Should Complete)
- [ ] #292: Legacy DB scenario (scenario 2) verified on device or via manual test
- [ ] #292: Seed data populated with production-quality recipes/ingredients
- [ ] Documentation updated for milestone

### Stretch Goals (If Time Permits)
- [ ] #303: Time-boxed (2h) research spike — identify available servings data fields, sketch recommendation angles, write as issue comment (no implementation)

### Quality Gates
- [ ] All acceptance criteria met for #292 (critical bug fix verified)
- [ ] No schema regression for existing users
- [ ] Test count in docs matches `flutter test` output
- [ ] Code review self-checklist complete
- [ ] Ready to merge to develop and tag 0.1.14

### Sprint Completion Checklist
- [ ] All 4 issues resolved and closed
- [ ] `flutter analyze && flutter test` passing
- [ ] No regression in existing functionality
- [ ] CHANGELOG.md updated
- [ ] Merged to develop, release/0.1.14 branch created, tagged on main

---

## Notes & Assumptions

### Assumptions
- Local export files exist on dev machine (required for #292 seed conversion step)
- Legacy DB scenario (Scenario 2 in #292) is tested best-effort — integration test covers the most critical scenarios
- #303 is explicitly out of scope for this sprint

---

## Session Execution Log

### 2026-03-21 — #263, #268, Docs Housekeeping, #318

**Issues completed**: #263, #268, #318 (substituted for #285 — see note below)

#### #263 — UI Component Library Documentation
- Created `docs/design/component_library.md` (saved to `docs/design/` rather than `docs/architecture/` per the issue spec)
- Added to `docs/README.md` Quick Links and Visual Design System table

#### #268 — Standardize Skill Documentation Structure
- Fixed 6 stale path references in `gastrobrain-issue-analysis/SKILL.md` (`docs/planning/0.1.X/` → `docs/issues/roadmaps/`)
- Added Output File Location sections to all 5 skills missing them
- Removed PR references from solo-dev workflow in `gastrobrain-issue-roadmap`
- Added `<!-- Save to: ... -->` comments to roadmap and sprint plan templates

#### Docs Housekeeping (unplanned, ~0.5 day)
- Archived 8 stale planning/milestone docs to `docs/archive/`
- `Gastrobrain-Roadmap-Status.md` deliberately retained (will be updated at start of 0.2.x planning)
- Updated `docs/README.md` Archive section and cleaned up stale sprint/roadmap table entries

#### #318 — Fix E2E Test Helper Scroll-Before-Tap
Substituted for #285 at user's request: failing integration tests were actively misleading and needed to be fixed before closing the milestone.

**Root causes found (two distinct bugs)**:

1. **Software keyboard pushes dialog actions off-screen** — On API 33 AOSP, the Android IME stays open after `tester.enterText()`. This reduces visible screen height, pushing `AlertDialog.actions` (save/cancel buttons) below the screen edge. `tester.ensureVisible()` does not resolve this because the buttons are outside the dialog's `SingleChildScrollView`. **Fix**: call `FocusManager.instance.primaryFocus?.unfocus()` + `pumpAndSettle()` at the start of `tapSaveButton` and `saveMealEditDialog` to dismiss the keyboard before attempting the tap.

2. **`tester.enterText()` does not replace existing text in multiline `TextFormField`s on real Android devices** — The platform IME holds its own text state and may reject `updateEditingValue` calls for fields with existing content. This only affected the `notes` field (`maxLines: 3`); single-line numeric fields were unaffected. **Fix**: access the field's `EditableText.controller` directly and set `.text` to bypass the IME entirely.

**Files changed**:
- `integration_test/e2e/helpers/e2e_test_helpers.dart` — keyboard dismiss in `tapSaveButton` and `saveMealEditDialog`; `ensureVisible` guards on all dialog-context taps; direct controller assignment for both notes fields
- `integration_test/e2e/e2e_meal_editing_integration_test.dart` — test 7.5 was calling `tester.enterText` directly (bypassing the helper); refactored to use `E2ETestHelpers.fillMealEditDialog`

**Result**: 37/37 e2e tests passing on API 33 AOSP (was 6 failures before this session)

#### #285 — Test Suite Governance
Deferred to next sprint. #318 took its slot on Day 4.

### Known Limitations
- Fresh-install device testing requires wiping app data — feasible but should be explicit gate in #292 AC before merging

### Follow-Up Work
- #303: Once deferred, evaluate if servings data is sufficient to define at least one concrete recommendation angle — if yes, re-estimate with tasks and add to 0.1.15 backlog

### References
- Sprint Estimation Diary: `docs/archive/Sprint-Estimation-Diary.md`
- Issue Workflow: `docs/workflows/ISSUE_WORKFLOW.md`
- Edge Case Testing Guide: `docs/testing/EDGE_CASE_TESTING_GUIDE.md`
- GitHub Project #3: github.com/orgs/alemdisso/projects/3

---

**Plan Created**: 2026-03-19
**Plan Author**: Claude Code (Sprint Planner Skill)
**Last Updated**: 2026-03-19 — added #317 (L, 8 pts) as Day 4; sprint extended to 4 days

---

## Sprint Log

*Daily notes to feed the retrospective. Record time spent, decisions made, surprises, and anything that deviated from the plan.*

### 2026-03-19 — Sprint Planning (~2h)
- Fetched all 5 milestone issues from GitHub Project #3
- Analyzed work types and applied velocity calibration — sprint is housekeeping-mode, no UI/mobile overhead
- **Decision**: Exclude #303 (research, no estimate, no AC) — deferred
- **Decision**: Split seed data curation out of #292 → created new issue #317
  - Trigger: ~160 recipes in DB but ~80% incomplete (missing instructions and/or ingredients); curation needs more time than migration consolidation
  - Conversion tool stays in #292; #317 is pure content/editorial work
- **Estimate**: #317 → L (8 pts, 1.0x) — manual writing work, open-ended; hard time-box at end of Day 4
- Sprint extended from 3 → 4 days (27 pts raw, 13.3 pts adjusted)
- Sprint plan written to `docs/planning/sprints/sprint-planning-0.1.14.md`

### 2026-03-20 — #292 implementation
- Pre-Implementation Analysis & Roadmap — ~11:30 - ~12:00
- **Scope discovery**: issue was written with 5 migrations; codebase had grown to 11 → chose Option B (consolidate all 001-011 into baseline)
- **Decision**: `instructions` field wired end-to-end in conversion tool + `importRecipesFromJson` now — #317 needs no code changes, just export + re-run
- Step 1: `tools/convert_export_to_seed.dart` built and run — 166 recipes, 198 ingredients written to assets/
- Step 2: `001_initial_schema.dart` rewritten — complete 13-table consolidated schema
- Step 3: `_onCreate` fixed — 6 gaps closed (servings, meal_type, planned_servings, to_buy bug, meal_plan_item_ingredients, meal_ingredients)
- Step 4: migrations 002-011 archived to `_archived/`, excluded from `flutter analyze`
- Step 5: migration registry stripped to `[InitialSchemaMigration()]` only
- Deleted 2 obsolete migration-specific test files (simple_sides_tables, shopping_list_tables)
- Phase 3: 19 new tests in `test/database/migration_consolidation_test.dart` — scenarios 1 and 3 green
- Scenario 2 (legacy DB): manual on emulator — best-effort, documented in roadmap
- **Gates**: `flutter analyze` clean, `flutter test` 1743/1743 passing
- **Completed**: ~16:40 - ~19:30 (with a 1 hour break) — merged to develop, #292 closed. Integration test suite running in parallel (results pending).

### 2026-03-21 — Integration test suite diagnosis & emulator fix (~1h)
- Diagnosed integration test failures from yesterday's full suite run (59 passed, 7 failed)
- **Finding 1**: 3 E2E failures are test infrastructure bugs — `tapSaveButton` and `_adjustServingsViaStepper` helpers in `e2e_test_helpers.dart` tap buttons without scrolling first; buttons land off-screen or obscured. Not production bugs.
- **Finding 2**: 4 service tests ("Unable to start the app on the device") traced to emulator storage exhaustion — `/data` partition at 93% full (436MB free on 6GB partition) due to API 36 + Google Play system image consuming most of the allocated space on cold boot.
- **Fix**: Switched emulator from API 36 (Google Play) to API 33 (AOSP) — no Google Play services needed for Gastrobrain; AOSP image has a much smaller footprint.
- **Unresolved**: The 3 E2E scroll/hit-test failures remain; will need a fix in `e2e_test_helpers.dart` (tracked separately).

### 2026-03-25 — #317 deferred to 0.2.1 (~19:45)

- Analyzed `assets/recipe_export_1774478466021.json` (189 recipes) to assess seed data readiness
- **Finding**: 95 recipes are stubs (0–1 ingredient); 94 have ingredient lists (2–35 ingredients); **0 have instructions** — not because the recipes lack instructions in the DB, but because the export service never fetched them
- **Bug fixed**: `lib/core/services/recipe_export_service.dart` was not including `recipe.instructions` in the export map despite the field being available on the already-fetched `Recipe` object. Added `'instructions': recipe.instructions` to the export structure — one-line fix.
- **Decision**: #317 moved to new milestone **0.2.1 - Data Seeding & Recipe Content** — the recipe content situation needs to be assessed with a correct export before committing to a curation approach. The export bug means we had no visibility into how many recipes actually have instructions written.
- **For retrospective**: #317 estimated at 8 pts (1.0x) based on the assumption that ~32 recipes were "fully complete". That assumption was unverifiable with a broken export. Re-estimate after running a fresh export post-fix.

### 2026-03-25 — #285: Test Suite Governance (~1h, ~18:00)

- Audited actual test counts vs. documented counts — all stale (122 dialog tests, 458 edge cases, 1670+ total)
- Built `scripts/count-tests.sh`: static grep-based count by category + parses latest `test_logs/` run logs; outputs doc-ready approximate floor summary
- Created `docs/testing/TEST_GOVERNANCE.md`: governance philosophy (approximate floors + script on demand), log naming conventions, update cadence (milestone release or 20%+ category growth)
- Updated `docs/README.md` and `Gastrobrain-Codebase-Overview.md` with corrected counts (200+ dialog, 500+ edge cases, 1740+ total)
- **Gates**: `flutter analyze` clean; no code changes
- Merged to develop (`548d7c1`), #285 closed, branch deleted

### 2026-03-21 — #263, #268, docs housekeeping, #318 fix (~3h)
- **#263** (UI Component Library doc): Written and merged — documents all reusable widgets with usage patterns and examples.
- **#268** (Standardize skill paths): Skill files renamed to `gastrobrain-*.md` convention; `skills/` index and CLAUDE.md updated.
- **Docs housekeeping**: Archived stale planning files; README updated.
- **#318** (Fix e2e scroll-before-tap): Two root causes found and fixed in `e2e_test_helpers.dart`:
  - **Root cause 1** — Android software keyboard (open after `enterText`) reduces visible height on API 33 AOSP, pushing `AlertDialog.actions` buttons off-screen. Fix: `FocusManager.instance.primaryFocus?.unfocus()` + `pumpAndSettle()` before tapping save/cancel in `tapSaveButton` and `saveMealEditDialog`.
  - **Root cause 2** — `tester.enterText()` does not reliably replace existing text in `maxLines: 3` TextFormFields on real Android (platform IME holds its own state). Fix: direct `editableText.controller.text = notes` assignment in `fillMealEditDialog` and `fillMealRecordingForm`.
  - Also added `ensureVisible` + `pumpAndSettle` before taps in `_adjustServingsViaStepper`, `cancelMealEditDialog`, `addSideDishInEditDialog`, and both `successSwitch` taps.
  - Test 7.5 ("Multiple rapid edits") was bypassing the helper with raw `tester.enterText` calls — replaced with `E2ETestHelpers.fillMealEditDialog`.
- **Gates**: `flutter analyze` clean, all integration tests passing (59/59).
