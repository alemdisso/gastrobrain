# Sprint Plan: 0.1.12 — Servings & Quantity Tracking

**Sprint Period**: TBD (5 working days)
**Milestone**: 0.1.12 - Servings & Quantity Tracking
**Total Story Points**: 17 pts
**Target Velocity**: 6 pts/day (30 pts/week cruising)

---

## Sprint Goal

Introduce servings awareness across the app: add a `servings` field to the Recipe model, carry planned servings through the meal planning slot, and scale shopping list ingredient quantities accordingly. Round out the milestone with three targeted UX improvements — "to taste" ingredient support, search whitespace trimming, and alphabetically sorted category dropdowns.

Key deliverables:
- Servings field on Recipe model with DB migration (#304)
- Planned servings in meal planning slots (#305)
- Quantity scaling in shopping list by planned servings (#306)
- Servings stepper in meal recording dialogs (#307)
- "To taste" toggle in AddIngredientDialog (#308)
- Whitespace trimming across all search fields (#309)
- Alphabetical category dropdown (#310)

---

## Capacity Analysis

| Metric | Value |
|--------|-------|
| Available days | 5 |
| Cruising velocity | 6.0 pts/day |
| Base capacity | 30 pts |
| Sprint total | 17 pts |
| Fit | Comfortable — leaves ~2 days buffer for DB migration complexity and testing |

**Sprint profile**: Mixed feature + UX polish. Core work is a dependency chain (#304 → #305 → #306) requiring careful sequencing. Three independent UX improvements (#307, #308, #309, #310) batch well and front-load quick wins. No discovery work — requirements are fully specified.

**Notable interaction**: #308 (to taste, quantity=0) and #306 (scale by servings). Scaling `0 × servings = 0` is correct behaviour, but worth an explicit test case.

---

## Issues by Theme

### Theme 1: Servings Chain — Model & Data (6 pts)

| # | Title | Est | Risk | Notes |
|---|-------|-----|------|-------|
| #304 | Add servings field to Recipe model | 3 | Medium | DB migration + cascade to services + tests; gates entire chain |
| #305 | Add planned servings to meal planning slot | 3 | Low-Med | UI + model change; depends on #304 |

### Theme 2: Servings Chain — Shopping List (3 pts)

| # | Title | Est | Risk | Notes |
|---|-------|-----|------|-------|
| #306 | Scale ingredient quantities by planned servings | 3 | Medium | Edge cases: quantity=0 (to taste), unset servings → default 1, fractional results; depends on #305 |

### Theme 3: UX Polish (9 pts)

| # | Title | Est | Risk | Notes |
|---|-------|-----|------|-------|
| #307 | Stepper for servings in meal recording dialogs | 3 | Low | UI widget swap; independent |
| #308 | "To taste" toggle in AddIngredientDialog | 2 | Low | Isolated dialog change; groundwork exists in RecipeEditorScreen |
| #309 | Trim whitespace from search queries | 2 | Very low | One-liner per search handler across 3–4 files |
| #310 | Sort category dropdown alphabetically | 1 | Very low | Single sort call at build time |

---

## Day-by-Day Breakdown

### Day 1: Quick wins + foundational prerequisite

**Goal**: Clear the trivial issues, land the DB migration that gates the entire chain

| Issue | Pts | Rationale |
|-------|-----|-----------|
| #310 | 1 | Trivial — one sort call; instant momentum |
| #309 | 2 | One-liner per file; touch multiple files but no logic risk |
| #304 | 3 | DB migration + servings field on Recipe model; must land today to unblock Days 2–3 |

- **#310 + #309 morning**: Warmup. Sort the dropdown, trim search queries across all 4 contexts. Verify with `flutter analyze`.
- **#304 afternoon**: Write migration, update Recipe model, cascade to DatabaseHelper and services, unit tests for serialization and migration path.
- **Risk**: Migration issues here have 4 days of recovery time — ideal placement.

### Day 2: Continue chain + isolated improvement

**Goal**: Extend servings into meal planning; deliver "to taste" as an isolated win

| Issue | Pts | Rationale |
|-------|-----|-----------|
| #308 | 2 | Isolated dialog change; validates entity_validator relaxation before #306 touches quantities |
| #305 | 3 | Planned servings in meal planning slot; depends on #304 (Day 1) |

- **#308 morning**: Add `_isToTaste` toggle to AddIngredientDialog, relax EntityValidator, l10n strings. Validates that `quantity=0` flows correctly — important before #306 uses it.
- **#305 afternoon**: Add servings field to meal planning slot UI, persist via DatabaseHelper, default to recipe's own servings value if set.
- **Testing**: Widget test for #308 toggle; unit test for #305 model persistence.

### Day 3: Complete the chain + batch UI

**Goal**: Close the servings chain; batch remaining UI work together

| Issue | Pts | Rationale |
|-------|-----|-----------|
| #306 | 3 | Scale quantities in shopping list; depends on #305 (Day 2) |
| #307 | 3 | Stepper widget in meal recording; independent — good to batch UI work on same day as #306 touches shopping list |

- **#306 morning**: Implement quantity scaling in shopping list service. Edge cases: `quantity=0` → stays 0, unset servings → default to 1, fractional results → round appropriately. Unit tests covering all edge cases including interaction with "to taste" items.
- **#307 afternoon**: Swap servings `TextField` for a `Stepper` widget in meal recording dialogs. Widget test for increment/decrement/bounds.

### Day 4: Testing & integration

**Goal**: Full test coverage for all implemented features; cross-feature integration

| Focus | Details |
|-------|---------|
| Widget tests | #307 stepper bounds and interaction; #308 toggle hides fields correctly |
| Unit tests | #304 Recipe serialization; #305 planned servings default logic; #306 scaling math (full edge case matrix) |
| Integration | Full flow: plan meal with servings → cook → check shopping list quantities |
| l10n | Verify #308 and #309 strings in both EN and PT-BR |
| Edge cases | quantity=0 survives scaling; unset servings defaults to 1; fractional quantities |

### Day 5: Polish & flex

**Goal**: Full suite validation, release prep, stretch work

| Focus | Details |
|-------|---------|
| `flutter analyze && flutter test` | Full suite — confirm zero regressions |
| Emulator validation | Manual walkthrough of servings flow end-to-end |
| Release prep | Version bump, release branch, changelog |
| Stretch | Any polish discovered during validation |

---

## Risk Assessment

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| DB migration (#304) breaks existing Recipe data | High | Low | Test on empty DB + existing DB; migration is additive (new column with default) |
| Quantity scaling (#306) edge case: quantity=0 not handled | Medium | Low | #308 lands Day 2 and validates the zero-quantity path before #306 uses it |
| Fractional scaled quantities look odd in UI | Low | Medium | Round to 1 decimal; apply same formatting as existing `QuantityFormatter` |
| Stepper (#307) bounds unclear (min/max servings) | Low | Low | Min=1, max=TBD during implementation (reasonable default: 20 or 99) |

**Scope flexibility**: #307 (stepper) is independent and can be deferred to 0.1.13 if the servings chain overruns. The UX polish issues (#308, #309, #310) are low-risk and front-loaded so they won't block the chain.

---

## Testing Strategy

| Issue | Test Types | l10n |
|-------|-----------|------|
| #304 | Unit (model serialization, migration), Integration (upgrade path) | No |
| #305 | Unit (default servings logic), Widget (slot UI) | No |
| #306 | Unit (scaling math, all edge cases including quantity=0 and unset servings) | No |
| #307 | Widget (stepper increment/decrement/bounds) | No |
| #308 | Widget (toggle hides fields, saves quantity=0, existing flow unaffected), Unit (EntityValidator accepts 0) | Yes — toggle label |
| #309 | Unit (trim applied in each of the 4 search contexts) | No |
| #310 | Widget (dropdown order is A→Z in EN and PT-BR) | No |

---

## Success Criteria

### Must Complete
- [ ] Recipe model has `servings` field persisted to DB (#304)
- [ ] Meal planning slots display and save planned servings (#305)
- [ ] Shopping list quantities scale correctly by planned servings (#306)
- [ ] Servings stepper works in meal recording dialogs (#307)
- [ ] "To taste" ingredients addable without quantity/unit (#308)
- [ ] All 4 search contexts trim leading/trailing whitespace (#309)
- [ ] Ingredient category dropdown is alphabetical in both EN and PT-BR (#310)
- [ ] All new tests pass; no regressions in full suite
- [ ] Localized in EN and PT-BR where applicable
- [ ] `flutter analyze` clean

### Sprint Completion
- [ ] Release 0.1.12 created and merged to main
- [ ] 0.1.12 milestone closed

---

**Plan Created**: 2026-02-27
**Plan Author**: Claude Code (sprint planner skill)
