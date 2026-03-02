# Sprint Plan: 0.1.13 — Meal Planning & Shopping Enhancements

**Sprint Period**: TBD (~4 working days)
**Milestone**: 0.1.13 - Meal Planning & Shopping Enhancements
**Total Story Points**: 23 pts (21 features + 2 refactoring)
**Target Velocity**: 6 pts/day (30 pts/week cruising)

---

## Sprint Goal

Complete the servings awareness story started in 0.1.12 (display + consistent UI), introduce "simple sides" so users can add bare ingredients to a meal without creating a full recipe, and round out the shopping list with manual item support.

Key deliverables:
- Servings displayed in recipe details and consistently input via stepper across all recipe forms (#314, #313)
- Simple sides — add DB-linked or free-text ingredients as meal sides in planning and recording (#311)
- Manual shopping list items — add one-off items without affecting the meal plan (#312)
- Opportunistic refactoring of all files touched during the sprint (#315 + criteria in #313, #314)

---

## Capacity Analysis

| Metric | Value |
|--------|-------|
| Available days | ~4 |
| Cruising velocity | 6.0 pts/day |
| Base capacity | 24 pts |
| Sprint total | 21 pts |
| Fit | Comfortable — 1 pt buffer for #311 complexity |

**Sprint profile**: Mixed execution + moderate discovery.
- **Execution mode** (#314, #313): ServingsStepper already exists from #307; these are targeted additions following established patterns.
- **Discovery-adjacent** (#311, #312): New DB tables and models in #311; #312 is simpler but benefits from #311's dialog pattern.

**Key dependency**: #311 before #312 — `AddSimpleSideDialog` from #311 is explicitly referenced as a reuse opportunity in #312. Sequencing these back-to-back captures the efficiency gain and reduces #312 to pattern extension.

---

## Issues by Theme

### Theme 1: Servings Completion (8 pts)

| # | Title | Est | Risk | Notes |
|---|-------|-----|------|-------|
| #314 | Display servings in recipe details screen | 3 | Low | Single file (`recipe_details_screen.dart`) + 2 ARB files. Also fixes silent data loss bug in `_saveInstructions()`. |
| #313 | Servings stepper in recipe forms | 5 | Low | Applies `ServingsStepper` (exists from #307) to 4 locations. Fixes data loss bug in `recipe_editor_screen._saveIngredients()`. |

### Theme 2: Meal Planning Extensions (13 pts)

| # | Title | Est | Risk | Notes |
|---|-------|-----|------|-------|
| #311 | Simple sides — ingredients as meal sides | 8 | Medium-High | 2 new DB tables, 2 new models, CRUD in DatabaseHelper, UI in 2 screens, shopping list integration, l10n. Highest complexity in sprint. |
| #312 | Manual items in shopping list | 5 | Medium | New dialog + in-memory state; no DB work. Reuses `AddSimpleSideDialog` pattern from #311. |

### Theme 3: Refactoring (2 pts)

| # | Title | Est | Risk | Notes |
|---|-------|-----|------|-------|
| — | Opportunistic refactors (#313, #314) | 0 | Low | Included in feature issue estimates. Named tasks in day breakdown. |
| #315 | Extract UnitConverter + IngredientAggregator from ShoppingListService | 2 | Low | Sequenced after #311; mechanical extraction while code is fresh. |

---

## Day-by-Day Breakdown

### Day 1: Servings completion

**Goal**: Close out the 0.1.12 servings story — display and consistent input across the app.

| Issue | Pts | Notes |
|-------|-----|-------|
| #314 | 3 | Morning: add `_buildInfoRow` for servings in Overview tab, ingredients header in Ingredients tab, fix `_saveInstructions()` data loss bug, l10n string (`ingredientsForServings`), widget + regression tests. **Refactor**: extract `_OverviewTab` and `_IngredientsTab` as private StatelessWidgets → `recipe_details_screen.dart` under 600 lines. |
| #313 | 5 | Afternoon: apply `ServingsStepper` to `add_recipe_screen`, `edit_recipe_screen`, `recipe_editor_screen` (+ fix data loss bug), `recipe_selection_dialog`. Update E2E tests. **Refactor**: extract form section widgets in `add_recipe_screen` (<400 lines), `edit_recipe_screen` (<300 lines), `recipe_selection_dialog` (<400 lines). |

- **Batching rationale**: Both issues are in the servings domain, share the same mental model, and are pure pattern extension — no context switching.
- **#314 first**: Smaller and independent; builds momentum. The `_saveInstructions()` bug fix is a prerequisite insight before touching `recipe_editor_screen` in #313.
- **Refactors are part of the issue definition of done** — not optional polish. Each file has a named line-count target in the issue acceptance criteria.
- **Risk**: `recipe_editor_screen` in #313 is the most complex location (4 navigation methods to wire). If it overruns, #313 spills into Day 2 morning — buffer exists.

### Day 2: Simple sides — data layer

**Goal**: Establish the DB foundation and service layer for simple sides before any UI.

| Focus | Details |
|-------|---------|
| #311 — DB migration | Add `meal_plan_item_ingredients` and `meal_ingredients` tables. Idempotent migration (non-negotiable baseline). |
| #311 — Models | Implement `MealPlanItemIngredient` and `MealIngredient` (dual-mode: `ingredientId` nullable + `customName` fallback). Follow `MealPlanItemRecipe` / `MealRecipe` pattern. |
| #311 — DatabaseHelper | Add CRUD methods for both new tables. Unit tests for all methods. |
| #311 — Shopping list | Integrate DB-linked simple sides into `ShoppingListService` ingredient aggregation. Free-text sides skipped gracefully. |

- **Migration early**: DB work on Day 2 leaves 2 full days for UI and recovery if issues surface.
- **Pattern reference**: `RecipeIngredient` (dual-mode linking), `MealPlanItemRecipe` / `MealRecipe` (junction model structure).

### Day 3: Simple sides — UI layer + #311 completion

**Goal**: Build the UI entry points and `AddSimpleSideDialog`; ship #311.

| Focus | Details |
|-------|---------|
| #311 — AddSimpleSideDialog | Ingredient search (DB-linked or free-text), optional notes, no quantity required. Validation: reject empty/whitespace-only free-text. |
| #311 — Meal planning UI | "Add Simple Side" entry point in meal planning screen. Display simple sides alongside recipe sides. |
| #311 — Meal recording UI | "Add Simple Side" entry point in meal recording screen. Display simple sides alongside recipe sides. |
| #311 — l10n | All new strings to `app_en.arb` and `app_pt.arb`. Run `flutter gen-l10n`. |
| #311 — Tests | Widget tests: add DB-linked side, add free-text side, delete side (no orphaned records), meal with only simple sides handled gracefully, mix of recipe + simple sides. |

- **Dialog first**: `AddSimpleSideDialog` is the reuse anchor for #312 — completing it today makes Day 4 faster.

### Day 4: Manual shopping list items + refactor + full validation

**Goal**: Ship #312, extract ShoppingListService (#315), full suite validation.

| Issue | Pts | Notes |
|-------|-----|-------|
| #312 | 5 | Morning: in-memory `_manualItems` state in shopping list screen. "Add item" button → `AddShoppingItemDialog` (reuses `AddSimpleSideDialog` structure, adds optional quantity). Merge with recipe-generated items. Distinguishing icon. Clear on list regeneration. l10n. Tests. |
| #315 | 2 | After #312: extract `UnitConverter` and `IngredientAggregator` from `ShoppingListService`. Mechanical move while the code is fresh from #311. `ShoppingListService` under 300 lines. |

**Afternoon: Full validation**
- `flutter analyze && flutter test` — full suite
- Manual walkthrough: plan meal with simple side → check shopping list → add manual item → regenerate list (manual items cleared)
- Verify both EN and PT-BR for all new strings
- Verify refactoring line-count targets met for all flagged files
- Release prep: version bump, release branch

---

## Risk Assessment

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| `recipe_editor_screen` (#313) more complex than expected — 4 navigation methods to wire | Medium | Medium | Scheduled Day 1 afternoon with buffer into Day 2 morning |
| DB migration (#311) breaks existing meal data | High | Low | Additive new tables only; no changes to existing schema; idempotent migration |
| `AddSimpleSideDialog` design decisions slow #311 (optional quantity? icons?) | Medium | Medium | Issue body says "lean toward optional quantity" — default to optional, don't over-design |
| #312 dialog reuse from #311 requires more adaptation than expected | Low | Low | #312 is in-memory only; if dialog reuse is awkward, build standalone — still a 1-day effort |
| Shopping list integration for simple sides (#311) reveals edge cases | Medium | Low | Free-text sides skipped gracefully; only DB-linked sides aggregate — clean separation |

**Scope flexibility**: #312 is P2 and entirely self-contained. If #311 overruns, #312 can slide to 0.1.14 without affecting any other deliverable.

---

## Testing Strategy

| Issue | Test Types | l10n |
|-------|-----------|------|
| #314 | Widget (servings row in Overview, header in Ingredients tab, header absent on empty/error), Regression (`_saveInstructions` preserves servings) | Yes — `ingredientsForServings` |
| #313 | Widget (stepper in all 4 locations, increment/decrement/bounds), Regression (`_saveIngredients` preserves servings in recipe_editor), E2E (update existing servings field finders) | No |
| #311 | Unit (CRUD for both new tables, shopping list aggregation with DB-linked sides), Widget (AddSimpleSideDialog: add DB-linked, add free-text, reject empty), Integration (delete side → no orphaned records, meal with only simple sides) | Yes — all new UI strings |
| #312 | Widget (add DB-linked item, add free-text item, re-sort → items remain, regenerate → manual items cleared), Validation (empty free-text rejected) | Yes — dialog strings |
| #315 | Existing unit tests pass with updated imports only — no new tests needed | No |

---

## Success Criteria

### Must Complete
- [ ] Servings displayed in Overview and Ingredients tabs of recipe details (#314)
- [ ] `_saveInstructions()` data loss bug fixed — servings preserved (#314)
- [ ] `recipe_details_screen.dart` under 600 lines (#314 refactor)
- [ ] `ServingsStepper` replaces text fields in all 4 recipe form locations (#313)
- [ ] `_saveIngredients()` data loss bug fixed — servings preserved (#313)
- [ ] `add_recipe_screen.dart` under 400 lines, `edit_recipe_screen.dart` under 300 lines, `recipe_selection_dialog.dart` under 400 lines (#313 refactor)
- [ ] `meal_plan_item_ingredients` and `meal_ingredients` DB tables created with idempotent migration (#311)
- [ ] Simple sides addable in meal planning and meal recording screens (#311)
- [ ] DB-linked simple sides contribute to shopping list generation (#311)
- [ ] Manual items addable to shopping list; cleared on regeneration (#312)
- [ ] `ShoppingListService` under 300 lines; `UnitConverter` and `IngredientAggregator` extracted (#315)
- [ ] All new tests pass; no regressions in full suite
- [ ] Localized in EN and PT-BR for all new user-facing strings
- [ ] `flutter analyze` clean

### Sprint Completion
- [ ] Release 0.1.13 created and merged to main
- [ ] 0.1.13 milestone closed

---

**Plan Created**: 2026-03-02
**Plan Author**: Claude Code (sprint planner skill)
