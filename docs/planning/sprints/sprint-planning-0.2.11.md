# Sprint Plan: 0.2.11 — DB Safety Foundation + UX Polish

**Sprint Period**: After 0.2.10 lands — est. ~5 working days
**Milestone**: 0.2.11 — DB Safety Foundation + UX Polish
**Total Story Points**: 28 raw (31 adjusted)
**Target Velocity**: 6.5 points/day (cruising, 30 pts/week)

> **Prerequisite**: 0.2.10 must be merged and tagged before this sprint starts.
> **Priority rule**: #382 is P1-High. It ships first, regardless of sprint order.
> **Dependency forward**: #383 (0.2.12) cannot start until #382 is merged — the
> `schema_migrations_errors` table and `recordError()` method must exist first.

---

## Sprint Goal

Close the database safety gap that allowed the 0.2.8 silent-failure incident to
occur and go undetected until post-release. Then ship four UX improvements that
have been in the backlog since real-world usage revealed friction points.

Key deliverables:
- Migration failures are now recorded persistently and surfaced as a visible
  warning on the home screen — the app never again fails silently
- An integration test validates the full migration sequence against a realistically
  populated database, providing a pre-release regression gate
- Meal options, week plan status, ingredient dialog, and recipe scroll all refined

---

## Capacity Analysis

### Base Calculation
- **Available days**: 5 days
- **Cruising velocity**: 6.5 pts/day (30 pts/week, validated across 0.1.7b–0.2.7)
- **Base capacity**: 5 × 6.5 = 32.5 pts raw

### Work Type Adjustments

| Issue | Raw pts | Multiplier | Reason | Adjusted |
|-------|---------|------------|--------|----------|
| #382 DB safety infra | 8 | 1.0x | Backend + new test infrastructure; well-specified; 6 files touched | 8.0 |
| #365 Ingredient dialog fix | 3 | 0.9x | Known area, targeted fix, established dialog pattern | 2.7 |
| #346 Scroll affordance | 2 | 1.0x | Small UI addition, visual only | 2.0 |
| #376 Week plan meal status | 5 | 1.1x | Grouping logic (data exists); new visual states + L10N | 5.5 |
| #316 Meal Options redesign | 10 | 1.3x | New unified dialog; richest UI item in sprint; expect one iteration cycle | 13.0 |

**Total adjusted**: 31.2 pts
**Days at cruising**: 31.2 ÷ 6.5 = 4.8 days → plan for 5 days, #316 is the flex lever

### Capacity Decision
- **Target**: 28 raw / 31 adjusted
- **Confidence**: Medium — #316 carries UI iteration risk; all other items are well-bounded
- **Flex lever**: If #316 runs long, its polish phase absorbs into early days of 0.2.12.
  The core dialog structure is the must-ship; visual refinement is deferrable.

---

## Issues Breakdown

### Theme 1: DB Safety Foundation (1 issue, 8 pts)

#### #382 — Migration error surfacing + integration test coverage
- **Story Points**: 8 (8.0 adjusted)
- **Type**: Technical debt / Architecture
- **Priority**: P1-High
- **Multiplier**: 1.0x — well-specified, backend work, new test file follows established sqflite_ffi pattern
- **Dependencies**: None (anchors the sprint)
- **Risk**: Medium — MigrationProvider→DatabaseHelper wiring has a small risk of
  touching more delegation methods than expected; budget an extra hour here
- **Acceptance Criteria**:
  - [ ] `schema_migrations_errors` table created in `MigrationRunner.initialize()`
  - [ ] `recordError(version, message)`, `getUnsurfacedErrors()`, `markErrorsSurfaced()` implemented
  - [ ] `_initializeMigrationSystem` catch calls `recordError` instead of printing silently
  - [ ] `MigrationProvider.initialize()` checks for unsurfaced errors, exposes `hasMigrationWarning`
  - [ ] Home screen shows localized Snackbar when `hasMigrationWarning` is true
  - [ ] Warning absent when all migrations succeed
  - [ ] `test/database/migration_integration_test.dart` passes: v108 + realistic data → 109→110→111
  - [ ] Integration test also validates error recording path (injected failing migration)
  - [ ] Localized in EN and PT-BR
  - [ ] `flutter test && flutter analyze` pass

**Implementation notes**:
- Add `schema_migrations_errors` in `migration_runner.dart:initialize()` — same session as creating `schema_migrations`
- The `severity` column (`warning` | `fatal`) should be added here to avoid a schema change in 0.2.12 when #383 needs it — coordinate with #383's design
- Expose runner methods via `DatabaseHelper` delegation before wiring `MigrationProvider`
- Integration test: use sqflite_ffi; follow `migration_consolidation_test.dart` pattern; seed 3 recipes + 4 ingredients + 6 recipe_ingredients at v108 state

---

### Theme 2: UX Polish (4 issues, 20 pts)

#### #365 — Fix edit ingredient dialog to anchor on current ingredient
- **Story Points**: 3 (2.7 adjusted)
- **Type**: UX fix
- **Multiplier**: 0.9x — known area, targeted scope
- **Dependencies**: None
- **Risk**: Low
- **Acceptance Criteria**:
  - [ ] Dialog opens pre-populated with current ingredient values
  - [ ] Search is gated behind explicit user intent (not auto-triggered on open)
  - [ ] Cancellation leaves ingredient unchanged
  - [ ] Localized in EN and PT-BR

#### #346 — Visual affordance for scrollable content above filter bar
- **Story Points**: 2 (2.0 adjusted)
- **Type**: UI enhancement
- **Multiplier**: 1.0x — small visual addition
- **Dependencies**: None
- **Risk**: Low
- **Acceptance Criteria**:
  - [ ] Visual hint (fade/shadow/indicator) visible when content exists above the filter bar
  - [ ] Hint disappears when user has scrolled to top
  - [ ] No layout regressions on other screen sizes

#### #376 — Week plan summary — temporal meal status
- **Story Points**: 5 (5.5 adjusted)
- **Type**: Enhancement
- **Multiplier**: 1.1x — grouping logic (date comparisons), new visual states, L10N
- **Dependencies**: None
- **Risk**: Low-Medium — visual treatment (icons, colors, section headers) needs a design decision; make it before implementing
- **Acceptance Criteria**:
  - [ ] Past cooked meals shown as "Cooked" with distinct visual treatment
  - [ ] Past unconfirmed meals shown as "Unconfirmed" with distinct visual treatment
  - [ ] Future meals shown as "Upcoming"
  - [ ] Today's meals handled correctly (grouped with "Upcoming")
  - [ ] Grouping uses current date, not hardcoded
  - [ ] Localized in EN and PT-BR

#### #316 — Redesign Meal Options menu into a unified rich experience
- **Story Points**: 10 (13.0 adjusted)
- **Type**: UX redesign
- **Multiplier**: 1.3x — new dialog, replaces SimpleDialog; rich layout; one iteration cycle expected
- **Dependencies**: None
- **Risk**: Medium-High — biggest UI item in the sprint; iteration likely
- **Flex rule**: Core dialog structure (recipe display, side dishes, servings, action buttons)
  is the must-ship. Visual polish and animation can be trimmed if Day 5 runs short.
- **Acceptance Criteria**:
  - [ ] Single dialog replaces both the bare SimpleDialog and RecipeSelectionDialog._buildMenu()
  - [ ] Prominent recipe display (name, tags)
  - [ ] Side dishes section (inline, not buried)
  - [ ] Servings stepper
  - [ ] Clear action buttons: Change Recipe, Mark as Cooked, Remove
  - [ ] Localized in EN and PT-BR
  - [ ] Widget tests cover main interactions and dismissal

---

## Day-by-Day Breakdown

### Day 1: DB Safety — Infrastructure (P1-High)

**Goal**: Build the error recording layer completely. By end of day, migration
failures are persistently recorded — even if the UI wiring comes Day 2.

**Issues**:
- **#382 Part 1** — `MigrationRunner` + `DatabaseHelper` changes
  - Add `schema_migrations_errors` table (with `severity` column) to `initialize()`
  - Implement `recordError()`, `getUnsurfacedErrors()`, `markErrorsSurfaced()`
  - Add `severity TEXT NOT NULL DEFAULT 'warning'` now — #383 will use it, avoids future schema change
  - Update `_initializeMigrationSystem` catch to call `recordError` instead of printing
  - Expose runner methods as `DatabaseHelper` delegation methods

**Testing**: Unit tests for `recordError()` and `getUnsurfacedErrors()` — write inline
**Risk**: Delegation method count — if `DatabaseHelper` grows more than 3 new methods, consider a thinner interface

---

### Day 2: DB Safety — UI Wiring + Integration Test

**Goal**: Complete #382. By end of day, the user sees a Snackbar after a failed
migration, and the integration test is green.

**Issues**:
- **#382 Part 2** — `MigrationProvider` + `HomeScreen` + L10N + integration test
  - Add `hasMigrationWarning`, `migrationWarningMessage` to `MigrationProvider`
  - Call `acknowledgeMigrationWarning()` in `MigrationProvider` to mark errors surfaced
  - Show Snackbar in `HomeScreen.initState` via `addPostFrameCallback`
  - Add 2 warning strings to `app_en.arb` and `app_pt.arb`; run `flutter gen-l10n`
  - Write `test/database/migration_integration_test.dart`:
    - Seed v108 state: 3 recipes, 4 ingredients, 6 recipe_ingredients, schema_migrations 101-108
    - Run migrations 109→110→111; assert all pass and data intact
    - Inject failing migration; assert `schema_migrations_errors` row recorded

**Testing**: Integration test IS the deliverable for this day
**Risk**: sqflite_ffi setup for the new test file — `setUpAll` pattern is established in
`migration_consolidation_test.dart`; copy verbatim

---

### Day 3: UX Quick Wins — #365 + #346

**Goal**: Clear both small UX items in a single focused day. Context switch is
minimal — both are dialog/list UI fixes with no shared state.

**Issues**:
- **#365** (2.7 adj) — ingredient dialog anchor fix (morning)
- **#346** (2.0 adj) — scroll affordance visual hint (afternoon)

**Testing**: Widget tests for #365 cancellation path; visual check for #346 on device
**Risk**: Low — both items are contained

---

### Day 4: UX — Week Plan Temporal Status (#376)

**Goal**: Ship the three-state meal status grouping in the week plan summary.
Make the visual treatment decision first (10 min design sketch), then implement.

**Issues**:
- **#376** (5.5 adj) — date comparison logic + section headers + visual states + L10N

**Testing**: Widget tests for grouping logic with mock dates (past-cooked, past-unconfirmed, future)
**Risk**: Low-Medium — decide visual treatment before opening the editor

---

### Day 5: UX Redesign — Meal Options Dialog (#316)

**Goal**: Ship the unified Meal Options dialog. Core structure must land; polish
is the flex lever if Day 5 runs short.

**Issues**:
- **#316** (13.0 adj) — unified rich dialog replacing SimpleDialog

**Sequencing within Day 5**:
- Morning: Dialog skeleton (layout, sections, routing from weekly calendar tap)
- Afternoon: Action buttons, servings stepper, side dish section, L10N
- End of day: Widget tests for main interactions; device test

**Stretch Goals** (if time permits):
- Animation / transition polish on dialog open
- Unconfirmed past meal visual treatment (bridges to #376)

**Testing**: Widget tests for dialog open, action taps, dismissal, cancellation
**Risk**: Medium-High — if the redesign reveals unexpected state management complexity,
defer the side dish section to a follow-up issue rather than slipping the sprint

---

## Risk Assessment

### High Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| #316 UI iteration runs past Day 5 | Sprint slips 1 day | Medium | Defer polish; ship core structure; flag as known |
| #382 MigrationProvider wiring touches more than expected | +2-3 hrs on Day 2 | Low-Medium | Do `DatabaseHelper` delegation first; scope clearly before coding |

### Medium Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Integration test sqflite_ffi setup friction | +1-2 hrs on Day 2 | Low | Pattern established; copy `setUpAll` from `migration_consolidation_test.dart` |
| #376 visual treatment decision delays implementation | +1 hr | Low | Sketch in 10 min before coding; MVP visual is always acceptable |

### Low Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| `severity` column addition creates migration conflict with #383 | Schema coordination | Low | Adding it in this sprint prevents it; note in #383 technical notes |

### Risk Mitigation Summary
- **Flex lever**: #316 polish is cuttable; core dialog is not
- **Forward dependency**: `severity` column added in this sprint to avoid #383 friction
- **Scope rule**: If any item runs 2x estimate, stop and create a follow-up issue

---

## Testing Strategy

### #382 — Integration test is the primary deliverable
- New file: `test/database/migration_integration_test.dart`
- Pattern: sqflite_ffi, follows `migration_consolidation_test.dart`
- Coverage: v108 schema + realistic data → 109→110→111; error recording path
- Must also include: `getUnsurfacedErrors()` returns rows; `markErrorsSurfaced()` clears them

### #365, #346, #376, #316 — Widget tests
- #365: cancellation path (no side effects), save path (values updated), back button
- #346: visual state present/absent based on scroll position
- #376: grouping logic with mock `DateTime.now()` — past-cooked, past-unconfirmed, future
- #316: dialog open, each action button, servings stepper, dismissal

### Localization Testing
- **Issues with new strings**: #382 (2 warning strings), #376 (3 status labels), #316 (action buttons)
- Run `flutter gen-l10n` after each ARB update
- Test both languages on device before shipping

---

## Dependencies & Prerequisites

### Blocking
- #382 must complete before 0.2.12 starts — `schema_migrations_errors` + `recordError()` are #383's foundation

### Internal
- `severity` column: add in #382 implementation to avoid a schema coordination issue in #383

---

## Success Criteria

### Primary Goals (Must Complete)
- [ ] #382 merged — migration failures recorded + Snackbar warning shown
- [ ] #382 integration test green — v108 + realistic data → 109→111 passes
- [ ] #365, #346 merged — ingredient dialog and scroll affordance fixed
- [ ] #376 merged — week plan shows temporal meal status
- [ ] #316 merged — unified Meal Options dialog live (core structure)
- [ ] `flutter test && flutter analyze` pass
- [ ] Both EN and PT-BR tested

### Secondary Goals
- [ ] `severity` column present in `schema_migrations_errors` (enables #383)
- [ ] #316 visual polish complete (not just structure)

### Stretch Goals
- [ ] Animation/transition on Meal Options dialog open

---

**Plan Created**: 2026-05-16
**Plan Author**: Claude Code
