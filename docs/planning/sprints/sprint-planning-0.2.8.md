# Sprint Plan: 0.2.8 — Range Quantities + Import

**Sprint Period**: After 0.2.7 lands (est. ~May 12) — ~6 working days
**Milestone**: 0.2.8 — Range Quantities + Import
**Total Story Points**: 27 raw (31 adjusted)
**Target Velocity**: 6 points/day (cruising, 30 pts/week)

> **Prerequisite**: 0.2.7 (Code Health) must land before this sprint starts. P1 test
> fixes (#378, #379) and the parser bug (#364) need to be clean before adding
> range quantity parsing on top.

> **Housekeeping**: #150 ("range formatting") is superseded by #357–359 and
> should be closed before the sprint starts.

---

## Sprint Goal

Ship the full range ingredient quantities feature (data → editor → shopping list)
and import tools, establishing the two major data-enrichment capabilities that
make Gastrobrain useful for real-world recipe management. Three small UX polish
items are bundled as quick wins at the start.

Key deliverables:
- Range quantities end-to-end: parse, store, display, and scale `2–3 cloves`-style ingredients
- Import recipes and ingredients from JSON with merge/duplicate handling
- FAB on recipe overview opens the full editor; story edit field has markdown preview; recipe list sortable by creation date

---

## Capacity Analysis

### Base Calculation
- **Available days**: 6 days
- **Cruising velocity**: 6 pts/day (30 pts/week, validated across 0.1.7b–0.2.2)
- **Base capacity**: 6 × 6 = 36 pts raw

### Work Type Adjustments

| Issue | Raw pts | Multiplier | Reason | Adjusted |
|-------|---------|------------|--------|----------|
| #380 FAB fix | 2 | 0.5x | Trivial rewire, established pattern | 1.0 |
| #373 Markdown preview | 2 | 0.8x | Direct parallel to instructions tab | 1.6 |
| #368 Sort by creation date | 2 | 0.8x | Adds to existing sort options, same pattern | 1.6 |
| #357 Range quantities — data | 5 | 1.1x | Well-specified; cascading `.quantity`→`.quantityMin` rename adds mechanical overhead | 5.5 |
| #358 Range quantities — editor | 5 | 1.3x | New UI input pattern, range display in ingredient list | 6.5 |
| #359 Range quantities — shopping list | 3 | 1.2x | Aggregation logic extension, simpler than editor UI | 3.6 |
| #216 Import tools | 8 | 1.4x | Discovery elements (conflict UI design, merge edge cases); `file_picker` already available | 11.2 |

**Total adjusted**: 31 pts
**Days at cruising**: 31 ÷ 6 = 5.2 days → plan for 6 days with buffer

### Capacity Decision
- **Target**: 27 pts raw / 31 pts adjusted
- **Confidence**: Medium — #216 has the most discovery risk; #357's rename cascade is mechanical but broad
- **Buffer day**: Day 6 provides recovery room for #216 overrun

---

## Issues Breakdown

### Theme 1: Quick Wins (3 issues, 6 pts)

#### #380 — ux: recipe details overview FAB should open full recipe editor
- **Story Points**: 2 (1.0 adjusted)
- **Type**: UX fix
- **Multiplier**: 0.5x — trivial rewire, `_editRecipe()` already exists
- **Dependencies**: None
- **Risk**: Low
- **Key tasks**: Rewire case 2 in `_buildFloatingActionButton()`, delete `_editStory()` + `_saveStory()`, remove `editStory`/`addStory` ARB keys, run `flutter gen-l10n`

#### #373 — add markdown preview to recipe history/story edit field
- **Story Points**: 2 (1.6 adjusted)
- **Type**: Enhancement
- **Multiplier**: 0.8x — instructions tab already has a markdown preview toggle; copy the pattern
- **Dependencies**: None
- **Risk**: Low

#### #368 — add sort by creation date option to recipe list
- **Story Points**: 2 (1.6 adjusted)
- **Type**: Enhancement
- **Multiplier**: 0.8x — adds to existing sort options; `recipes.created_at` column exists
- **Dependencies**: None
- **Risk**: Low

---

### Theme 2: Range Quantities (3 issues, 13 pts)

#### #357 — feature: range quantities — data foundation
- **Story Points**: 5 (5.5 adjusted)
- **Type**: Feature — backend/data
- **Multiplier**: 1.1x — well-specified; main risk is breadth of `.quantity`→`.quantityMin` rename across all `RecipeIngredient` call sites
- **Dependencies**: None (but must complete before #358 and #359)
- **Risk**: Medium — rename cascade; parser regression risk (existing single-value parsing must not break)
- **Key tasks**:
  - DB migration: add `quantity_max REAL` nullable to `recipe_ingredients`
  - `RecipeIngredient`: rename `quantity`→`quantityMin`, add `quantityMax`, add `isRange` getter, update `toMap`/`fromMap`/`copyWith`; update all call sites
  - `IngredientParserService` (`lib/core/services/ingredient_parser_service.dart`): extend to detect `2-3`, `½-1`, `1/2-1`, `1½-2` notation; update `ParsedIngredientResult` with `quantityMax`
  - `QuantityFormatter`: add `formatRange(min, max)` method
  - Scaling logic: apply factor to both bounds
- **Critical**: Run full test suite after the rename; existing parser tests must pass unchanged

#### #358 — feature: range quantities — recipe editor input and ingredient display
- **Story Points**: 5 (6.5 adjusted)
- **Type**: Feature — UI
- **Multiplier**: 1.3x — new UI input pattern; design decision needed on single field ("2-3") vs two separate fields
- **Dependencies**: #357 must be merged first
- **Risk**: Medium — UI iteration likely on the range input affordance

#### #359 — feature: range quantities — shopping list aggregation and display
- **Story Points**: 3 (3.6 adjusted)
- **Type**: Feature — UI/logic
- **Multiplier**: 1.2x — aggregation extension; shopping list already handles unit merging
- **Dependencies**: #357 must be merged first; #358 can be in progress in parallel
- **Risk**: Low-Medium — aggregation edge cases (min+min, max+max, display when max is null)

---

### Theme 3: Import Tools (1 issue, 8 pts)

#### #216 — Add import tools and reorganize data management in Tools tab
- **Story Points**: 8 (11.2 adjusted)
- **Type**: Feature — major
- **Multiplier**: 1.4x — conflict resolution UI has discovery elements; merge strategy implementation; `file_picker` already in pubspec (from #223 backup/restore), reducing setup friction
- **Dependencies**: None (standalone feature)
- **Risk**: High — largest single issue; merge/duplicate logic has edge cases; conflict resolution UI design may iterate
- **Key tasks**:
  - File picker for JSON selection (reuse `file_picker` from #223)
  - Recipe import with duplicate detection (by ID, fallback to name)
  - Ingredient import with same strategy
  - Conflict resolution UI (skip / merge / replace / add new)
  - Import summary dialog (added / updated / skipped / errors)
  - Transaction/rollback for failed imports
  - Full relational test data (per diary rule: must include meals, history, plans, instructions)
  - EN + PT-BR localization
- **Note**: Per sprint diary insight from 0.1.14/0.1.15 — "Import integration tests must include full relational data." This is non-negotiable AC.

---

## Day-by-Day Breakdown

### Day 1: Quick Wins (6 pts raw / 4.2 adjusted)

**Goal**: Clear all three small issues, build momentum, touch diverse parts of the app.

- **#380** (2 pts → 1 adj) — FAB rewire + dead code removal
  - Why first: Trivial, established pattern; clears a daily annoyance noted during testing
  - Deliverable: FAB opens full editor; `_editStory`/`_saveStory` deleted; ARB keys removed; `flutter gen-l10n` run; tests pass
- **#373** (2 pts → 1.6 adj) — Markdown preview for story edit
  - Why now: Directly parallel to instructions tab; follow that pattern exactly
  - Deliverable: Story edit field has edit/preview toggle; both languages tested
- **#368** (2 pts → 1.6 adj) — Sort by creation date
  - Why now: Simple sort option; good end-of-day if #380+#373 complete early
  - Deliverable: "Newest first" / "Oldest first" available in recipe list sort options

**Testing**: Widget test for #380 (FAB navigates to editor); regression check that story card still renders.

---

### Day 2: Range Data Foundation (5 pts raw / 5.5 adjusted)

**Goal**: Land the backend foundation that unblocks Days 3 and 4.

- **#357** (5 pts → 5.5 adj) — Range quantities data foundation
  - Why now: Prerequisite for both #358 and #359; backend-only day (no UI), stay in one mental context
  - Why all day: `.quantity`→`.quantityMin` rename is mechanical but broad; parser extension needs careful regression testing
  - Deliverable: Migration runs clean; `RecipeIngredient` updated with `quantityMin`/`quantityMax`/`isRange`; parser detects `2-3` notation; `QuantityFormatter.formatRange()` works; all existing tests pass; new unit tests for migration compat, parser range cases, formatter, scaling

**Testing**: Thorough unit tests inline — parser regression risk is real. Run `flutter test` before calling this done.

**Risks**: Parser regression (single-value parsing broken by range changes). Mitigation: add regression tests first, then implement.

---

### Day 3: Range Editor UI (5 pts raw / 6.5 adjusted)

**Goal**: Range quantities visible and editable in the recipe editor.

- **#358** (5 pts → 6.5 adj) — Recipe editor range input + ingredient display
  - Why now: #357 landed yesterday; pick up while context is fresh
  - Design decision to make early: single input field accepting "2-3" syntax vs two separate min/max fields → lean toward single field (consistent with parser)
  - Deliverable: Ingredient parser in recipe editor accepts range notation; ingredient list displays `2–3 cloves` format; `isRange` used to conditionally show range display

**Testing**: Widget tests for range input field; display tests for range formatting in ingredient list; device validation.

**Risks**: UI iteration on range input affordance. If the single-field approach feels unclear, two fields are the fallback — budget 30% extra on Day 3 for this.

---

### Day 4: Range Shopping List + Import Setup (3+? pts)

**Goal**: Complete range quantities trilogy; begin import investigation.

- **#359** (3 pts → 3.6 adj) — Range quantities shopping list
  - Why now: Completes the range trilogy; shopping list aggregation already has unit-merge patterns to follow
  - Deliverable: Shopping list aggregates range quantities correctly (`min1+min2`–`max1+max2`); displays ranges when applicable; null `quantityMax` handled gracefully

- **#216 investigation** (no points charged today)
  - Review existing backup/restore flow from #223 — import will share file picker and transaction patterns
  - Sketch conflict resolution UI states before writing code
  - Identify all test data scenarios needed (full relational data per diary rule)
  - This half-day investment prevents discovery surprises on Days 5–6

**Testing**: Unit tests for range aggregation edge cases (both null, one null, mismatched units).

---

### Day 5: Import Core (4 pts focus)

**Goal**: Import file parsing, validation, and core merge logic working.

- **#216 Part 1** — File picker → parse → validate → dry-run
  - Reuse `file_picker` from `#223` backup/restore (already in pubspec, existing usage to reference)
  - File selection → JSON parse → schema validation → identify duplicates (by ID, fallback name)
  - Dry-run import showing what would be added / skipped / merged
  - Deliverable: Can select a file, parse it, and produce a structured import plan (no DB writes yet)

**Testing**: Unit tests for JSON parsing, duplicate detection, and validation logic.

**Risks**: Discovery in duplicate detection algorithm. If name-matching is ambiguous (plurals, accents), time-box at 2 hours and ship conservative version (ID-only match, name as secondary manual review).

---

### Day 6: Import UI + Tests + Polish (flex)

**Goal**: Complete import UI, write tests, validate round-trip.

- **#216 Part 2** — Conflict resolution UI + import execution + summary dialog
  - Conflict resolution dialog: Skip / Merge / Replace / Add new
  - Execute import in a transaction; rollback on failure
  - Summary dialog: X added, Y updated, Z skipped, N errors
  - EN + PT-BR localization
  - Integration test with full relational data (meals, history, plans, instructions)
  - Export → import round-trip test

**Stretch Goals** (if Days 1–5 came in under):
- #374 — Show side dish recipe names in week plan card (3 pts, in 0.2.9 but simple enough to pull in)

**Testing**: Full integration test suite for import. This is the most test-heavy day.

---

## Risk Assessment

### High Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| #216 conflict resolution UI iterates beyond Day 6 | Sprint overrun | Medium | Ship conservative UI (skip/add only) as MVP; merge/replace as stretch |
| #357 `.quantity` rename breaks unexpected call sites | Day 2 slip | Low-Medium | Search all `.quantity` usages before starting; fix mechanically first, then implement new logic |

### Medium Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| #357 parser regression breaks existing single-value parsing | Day 2 test failures | Low-Medium | Write regression tests before modifying parser; commit parser tests first |
| #358 range input UX needs redesign mid-day | Day 3 slip | Medium | Decision on single vs two fields made first thing Day 3; one approach committed to |
| #216 import test data setup (full relational data) takes longer than expected | Day 5–6 slip | Low | Reuse seed data from `test/fixtures` if available; draft test data structure on Day 4 investigation |

### Low Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| #380/#373/#368 reveal unexpected complexity | Minor | Low | All three are small and well-understood; abort if any takes >2h and triage |

### Risk Mitigation Summary
- **Scope flexibility**: If #216 overruns, ship import with skip-only duplicate handling (MVP). Full merge/replace moves to 0.2.9.
- **Dependency management**: #357 gates Days 3 and 4 — do not start #358/#359 until #357's tests pass
- **Discovery time-box**: #216 duplicate detection algorithm capped at 2h on Day 5 if ambiguous

---

## Database Migration Plan

### Migration: Add `quantity_max` to `recipe_ingredients`
- **Issue**: #357
- **Type**: Simple addition (nullable column, no data migration needed)
- **Change**: `ALTER TABLE recipe_ingredients ADD COLUMN quantity_max REAL`
- **Existing rows**: `quantity_max = NULL` → treated as single value (backward compatible)
- **Rollback**: Unneeded in practice (nullable addition is safe), but migration runner handles via version set membership
- **Testing**:
  - [ ] Migration runs on empty database
  - [ ] Migration runs on database with existing `recipe_ingredients` rows
  - [ ] `quantity_max = NULL` rows read correctly as non-range

### Migration Schedule
- **Day 2** (first thing) — migrate before any model changes
- **Validation**: Run all existing `recipe_ingredients` tests before proceeding with model rename

---

## Testing Strategy

### #357 — Range data foundation
- Unit: migration backward compat, parser range cases (all notations), formatter range output, scaling both bounds
- Regression: all existing single-value parser tests must pass unchanged

### #358 — Range recipe editor
- Widget: range input field accepts "2-3" notation; ingredient card displays range format
- Edge cases: null `quantityMax` (single value) displays as before

### #359 — Range shopping list
- Unit: aggregation with both ranges, one range + one single, two singles, mismatched units
- Edge cases: null `quantityMax` in aggregation produces correct display

### #216 — Import tools
- Unit: JSON parse, duplicate detection, merge logic
- Integration: full relational test data (meals, history, plans, instructions) — **mandatory per diary rule**
- E2E: export → import round-trip preserves all data
- Edge cases: malformed JSON, partial import failure triggers rollback, empty file, duplicate IDs vs duplicate names

### #380 / #373 / #368
- Widget tests: FAB navigates to editor; markdown preview renders; sort option appears and works

### Localization
- Issues with new strings: #216 (conflict UI + summary dialog), #373 (toggle labels), #368 (sort option labels), #380 (tooltip change)
- Run `flutter gen-l10n` after each ARB change

---

## Dependencies & Prerequisites

| Issue | Prerequisite | Status |
|-------|--------------|--------|
| #358 Range editor | #357 data foundation merged | Must complete Day 2 |
| #359 Range shopping list | #357 data foundation merged | Must complete Day 2 |
| 0.2.8 sprint start | 0.2.7 Code Health landed | P1 test fixes (#378, #379) must be clean |

**Blocking chain**: #357 → #358, #357 → #359 (can run in parallel after #357)

**External dependency**: `file_picker` — already in `pubspec.yaml` (from #223). No new package needed.

---

## Success Criteria

### Primary Goals (Must Complete)
- [ ] Range quantities parse, store, display, and scale correctly end-to-end
- [ ] Import tools functional with JSON file selection and duplicate handling
- [ ] Recipe overview FAB opens full editor (#380)
- [ ] All tests pass (`flutter test`)
- [ ] No analysis warnings (`flutter analyze`)

### Secondary Goals (Should Complete)
- [ ] Markdown preview for story edit field (#373)
- [ ] Sort by creation date in recipe list (#368)
- [ ] Import conflict resolution UI covers Skip + Add New at minimum
- [ ] Both EN and PT-BR tested manually

### Stretch Goals (If Time Permits)
- [ ] #374 — Side dish recipe names in week plan card (from 0.2.9)
- [ ] Import conflict resolution covers full Merge + Replace strategies

### Quality Gates
- [ ] Import integration test uses full relational test data (meals, history, plans, instructions)
- [ ] Parser regression: all existing single-value ingredient parsing tests pass unchanged
- [ ] `quantity_max = NULL` semantics consistent across all `RecipeIngredient` read/write paths
- [ ] `file_picker` usage consistent with #223 backup/restore pattern
- [ ] No hardcoded strings (EN + PT-BR complete)

---

## Notes & Assumptions

### Assumptions
- 0.2.7 lands before this sprint (P1 bugs and test fixes cleared)
- `IngredientParserService` already lives at `lib/core/services/ingredient_parser_service.dart` (confirmed)
- `file_picker` already in pubspec from #223 (confirmed)
- #150 is closed as superseded by #357–359 before sprint starts

### Known Limitations
- Import scope: recipe + ingredient JSON only (not full database backup — that's #223)
- Range quantities scope: `recipe_ingredients` only; shopping list scaling is in scope but meal scaling is not

### Follow-Up Work
- #371 (ingredient parser UX redesign) in 0.2.10 will build on `IngredientParserService` extended in #357
- Import of other data types (meal history, meal plans) is future work — not in scope here

### References
- Sprint Estimation Diary: `docs/archive/Sprint-Estimation-Diary.md`
- Edge Case Testing Guide: `docs/testing/EDGE_CASE_TESTING_GUIDE.md`
- Localization Protocol: `docs/workflows/L10N_PROTOCOL.md`
- Backup/Restore pattern (reference for #216): `lib/core/services/database_backup_service.dart`
- Range quantities parent: #150 (superseded)

---

**Plan Created**: 2026-05-06
**Plan Author**: Claude Code + alemdisso
**Last Updated**: 2026-05-06
