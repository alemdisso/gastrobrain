# Sprint Plan: 0.2.3 — UX Polish

**Sprint Period**: TBD (~6 working days)
**Milestone**: 0.2.3 - UX Polish
**Total Story Points**: 33 pts
**Target Velocity**: 6 pts/day (30 pts/week cruising)

---

## Sprint Goal

Close five outstanding UX bugs — including the cooked_at / ordering pair carried over from 0.2.2 — then deliver three layers of UX polish: tighter ingredient spacing, Plan Today scroll-to-today, and a new ingredient detail screen with a usage-history tab. Cap the milestone with the highest-value feature in the sprint: the multi-recipe UX overhaul (#121, P1). Per-recipe notes (#291) follows as a stretch goal and can be deferred to a later milestone without affecting the milestone theme.

Key deliverables:
- `cooked_at` bug and same-day ordering definitively fixed (#352, #351 — 0.2.2 validation debt repaid)
- Unit strings localized in three affected dialogs/screens (#345)
- `AddSimpleSideDialog` layout and button bugs fixed (#339, #340 — same file, batched)
- Ingredient cards tighter in recipe details and ingredients screens (#296)
- "Plan Today" navigates and scrolls to today's meal slot (#295)
- Ingredient detail screen with "Used In" and "Meal History" tabs (#193, #329)
- Multi-recipe planning discoverable and intuitive — **P1, must-complete** (#121)
- Per-recipe notes in meal recording — **stretch/deferrable to 0.2.4+** (#291)

---

## Capacity Analysis

| Metric | Value |
|--------|-------|
| Available days | ~6 |
| Cruising velocity | 6.0 pts/day |
| Base capacity | 36 pts |
| Sprint total | 33 pts |
| Fit | Comfortable — 3 pt buffer; #291 is explicitly deferrable |

**Sprint profile**: Bugs-first execution mode, then cruising into features, capped by a discovery-adjacent P1.

- **Execution mode** (Days 1–2): 5 bugs + 1 UX polish = 11 pts. All well-specified, small scopes. Historical pattern: post-usage bugs execute at 0.10x–0.20x; expect ~0.5–1 actual day for this block.
- **Cruising mode** (Days 3–4): #295, #193, #329 = 7 pts. Reasonably well-specified; #295 has a documented technical challenge (failed prior attempt).
- **Discovery-adjacent** (Day 5): #121 = 8 pts. Unmade design decisions in its acceptance criteria. Requires scope lock before coding.
- **Stretch** (Day 6): #291 = 5 pts. Full DB migration + UI. Can be deferred to 0.2.4 or 0.2.7 without affecting the milestone theme.

**Key dependencies:**
- #352 before #351 — fixing `cooked_at` before the ordering query makes the ordering fix fully reliable
- #193 before #329 — #329 is the second tab of the screen built in #193

---

## Issues by Theme

### Theme 1: Bug Batch — 0.2.2 Validation Debt + Outstanding UX Bugs (10 pts)

| # | Title | Est | Risk | Notes |
|---|-------|-----|------|-------|
| #352 | `MealCookedDialog` uses current time for `cooked_at` | 1 | Low | One-line fix: `_cookedAt = widget.plannedDate` in `initState`. Pattern already exists in `MealRecordingDialog`. |
| #351 | Same-day meal ordering broken after #341 | 2 | Low | Change `cooked_at DESC` → `date(cooked_at) DESC` in 3 queries in `database_helper.dart`. Must verify on device — this was 0.2.2 validation debt. |
| #345 | Unit strings not localized (3 sites) | 2 | Low | Apply `MeasurementUnit.fromString().getLocalizedQuantityName()` pattern from `shopping_list_screen.dart`. No ARB changes — keys exist. |
| #339 | Add button unlabelled grey box in `AddSimpleSideDialog` | 2 | Low | UI state bug before ingredient selection. Same file as #340 — batch together. |
| #340 | Dialog layout breaks when suggestions list visible | 3 | Low-Medium | Layout constraint issue in `AddSimpleSideDialog`. Sequenced immediately after #339 while the file is hot. |

### Theme 2: UX Polish (2 pts)

| # | Title | Est | Risk | Notes |
|---|-------|-----|------|-------|
| #296 | Reduce whitespace in ingredient cards (2 screens) | 2 | Low | `recipe_ingredients_screen.dart` Card margin + `ingredients_screen.dart` ListTile density. Visual validation required. |

### Theme 3: UX Features (8 pts)

| # | Title | Est | Risk | Notes |
|---|-------|-----|------|-------|
| #295 | Plan Today scrolls to today's meal slot | 3 | Medium | Prior attempt failed (`maxScrollExtent` returned 0). Issue body has sound diagnosis: `GlobalKey<WeeklyPlanScreenState>` + `scrollToToday()` with pre-calculated offset. Timebox investigation to 1 hour. |
| #193 | Ingredient detail screen — "Used In" tab | 3 | Low-Medium | New screen + tab scaffold. New `getRecipesByIngredientId` DB method. Navigation from ingredient list. Well-specified. |
| #329 | Ingredient usage frequency (meal history tab) | 2 | Low | Second tab on the ingredient detail screen. Strictly depends on #193 being done first. |

### Theme 4: P1 Feature (8 pts)

| # | Title | Est | Risk | Notes |
|---|-------|-----|------|-------|
| #121 | Refine Multi-Recipe User Experience | 8 | **High** | **Design decisions unmade.** AC includes "toggle, tab, or clear option", contextual guidance, visual feedback. Lock the UI approach before Day 1 of this phase. See risk section. |

### Theme 5: Stretch — Deferrable to 0.2.4+ (5 pts)

| # | Title | Est | Risk | Notes |
|---|-------|-----|------|-------|
| #291 | Per-recipe notes in multi-dish meals | 5 | Medium | DB migration + model + UI + history display. Well-specified but heavy. Complete only if #121 is shipped and time remains. |

---

## Day-by-Day Breakdown

### Day 1: Bug Batch — Ordering Debt + i18n + Warm-up

**Goal**: Close 0.2.2 validation debt. Apply the i18n fix. End the day with all "known pattern" bugs done.

| Issue | Pts | Notes |
|-------|-----|-------|
| #352 | 1 | Morning: `late DateTime _cookedAt` + `_cookedAt = widget.plannedDate` in `initState`. Verify date picker pre-fills. Tests. |
| #351 | 2 | After #352: update 3 queries in `database_helper.dart`. **Device validation required** — verify same-day dinner appears above lunch. |
| #345 | 2 | Apply `MeasurementUnit.fromString()` pattern to 3 sites. Test PT-BR (known units translated, free-text unchanged). |

- **#352 before #351**: Makes the ordering fix fully reliable — `cooked_at` is now the slot date, so `date(cooked_at)` comparison is meaningful.
- **#345 third**: Touches `add_simple_side_dialog.dart` — good warm-up before Day 2's deeper work in the same dialog.

### Day 2: `AddSimpleSideDialog` Bugs + UX Polish

**Goal**: Complete the `AddSimpleSideDialog` fix pair. Tighten ingredient card spacing.

| Issue | Pts | Notes |
|-------|-----|-------|
| #339 | 2 | Morning: fix add button as unlabelled grey box before ingredient selection. Widget test at all selection states. |
| #340 | 3 | After #339 (same file, full context): fix layout break when suggestions list visible. Widget test for suggestions-visible state. |
| #296 | 2 | Afternoon: reduce Card vertical margin in `recipe_ingredients_screen.dart`; `dense: true` or reduced `contentPadding` in `ingredients_screen.dart`. Visual check both screens consistent. |

- **#339 before #340**: Same file; #339 reveals widget tree, reducing investigation time for #340.

### Day 3: Plan Today + Ingredient Detail Screen

**Goal**: Ship #295 and the ingredient detail screen foundation (#193). Follow immediately with #329 while the screen is fresh.

| Issue | Pts | Notes |
|-------|-----|-------|
| #295 | 3 | Morning: `scrollToToday()` on `WeeklyPlanScreenState` via `GlobalKey` + pre-calculated offset. Trigger from Dashboard. `planTodaysMeal` l10n key already exists. Timebox initial investigation to 1 hour. |
| #193 | 3 | Afternoon: new `ingredient_detail_screen.dart` with tab scaffold. `getRecipesByIngredientId()` in `DatabaseHelper`. Navigation from `ingredients_screen.dart`. "Used In" tab: recipe cards, quantity, empty state, usage count. Widget + unit tests. |

### Day 4: Ingredient Meal History Tab + Sprint Buffer

**Goal**: Close the ingredient detail story with the second tab (#329). Use remaining time as buffer or pre-work for #121.

| Issue | Pts | Notes |
|-------|-----|-------|
| #329 | 2 | Morning: "Meal History" tab on ingredient detail screen. New DB query for ingredient frequency. Optional time-range breakdown. Tests. |
| Pre-work for #121 | — | Afternoon: review `weekly_plan_screen.dart` and `recipe_selection_dialog.dart`. Lock scope decision (see Pre-Sprint Checklist). No code yet. |

- **#329 immediately after #193**: Tab scaffold exists; this is pure pattern extension in the same file. Calibration: follow-on work in same screen ≈ 0.3–0.4x.
- **#121 pre-work on Day 4**: The design decision must be locked before any code is written. Use the afternoon to review the codebase entry points and commit to one approach.

### Day 5: Multi-Recipe UX Overhaul (#121)

**Goal**: Make multi-recipe planning discoverable. Ship a meaningful UX improvement that users notice.

| Focus | Details |
|-------|---------|
| Entry point | Make "Add Side Dish" capability visible without requiring menu navigation. Apply chosen approach from pre-work (inline affordance, toggle, or tab). |
| Visual cues | Recipe count indicator. Clear primary vs side dish distinction in the planning slot UI. |
| Contextual guidance | Help text or tooltip explaining the multi-recipe concept. Progressive disclosure — don't overwhelm single-recipe users. |
| Backward compatibility | Single-recipe workflow unchanged. Existing multi-recipe data unaffected. |
| Tests | Widget tests: multi-recipe entry discoverable; single-recipe regression; count indicator correct. |

- **Scope guard**: Implement the chosen entry point approach and visual cues. Defer "onboarding hints for first-time users" and "user testing validation" ACs to 0.2.7 if Day 5 is tight.
- **Day 5 is the milestone's quality gate**: If #121 ships and is solid, the sprint is a success regardless of #291.

### Day 6: Per-Recipe Notes (#291) — Stretch Only

**Goal**: If #121 is complete and time allows, start #291. Otherwise, defer to 0.2.4 or 0.2.7.

| Focus | Details |
|-------|---------|
| DB layer | `ALTER TABLE meal_recipes ADD COLUMN notes TEXT` (idempotent). Update `MealRecipe` model. `DatabaseHelper` CRUD. Unit tests. |
| UI | Per-recipe note fields in `MealRecordingDialog`. General meal note preserved. Optional — don't force notes. |
| History display | `recipe_details_screen.dart`: recipe-specific note (primary) + meal-level note (secondary/contextual). |
| l10n | New strings to both ARB files. `flutter gen-l10n`. |

- **Explicitly deferrable**: If Day 5 required iteration on #121 or there is any doubt about quality, defer #291. It does not belong to the "UX Polish" theme — it is a data model enhancement. It fits equally well in 0.2.4 (Recipe Enhancement) or 0.2.7 (Import & Remaining UX).

---

## Risk Assessment

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| **#121 design decisions unmade** — AC lists multiple UI approaches without choosing | High | High | Lock scope on Day 4 afternoon. Choose simplest approach that satisfies "discoverable without menu navigation." Defer onboarding hints to 0.2.7. |
| **#295 prior attempt failed** — `maxScrollExtent` returned 0 | Medium | Medium | Timebox investigation to 1 hour. Fallback: `WidgetsBinding.addPostFrameCallback` with frame delay after tab switch. |
| **#351 device validation fails again** | High | Low | `date(cooked_at)` is analytically correct. Validate on device on Day 1. If it still fails, treat as P0 before moving on. |
| **#291 `MealRecordingDialog` lacks DI** (CLAUDE.md issue #237) | Medium | Medium | Known limitation. Unit-test DB layer and model separately. Accept reduced dialog test coverage per existing guidance. Deferred anyway if time is tight. |
| **#121 overruns** | Low | Medium | #121 is second-to-last. #291 absorbs any overrun as the explicit stretch item. Milestone still ships clean without #291. |

---

## Testing Strategy

| Issue | Test Types | l10n | Device Validation |
|-------|-----------|------|------------------|
| #352 | Widget (date picker pre-filled with slot date) | No | Verified via #351 device test |
| #351 | Unit (query), Manual (same-day ordering on device) | No | **Required** |
| #345 | Widget (PT-BR units in 3 sites; free-text passthrough) | No (keys exist) | Optional |
| #339 | Widget (button state at each selection stage) | No | Optional |
| #340 | Widget (suggestions-visible layout, no overflow) | No | Optional |
| #296 | Existing suite passes — no new tests | No | Recommended |
| #295 | Widget (Plan Today scrolls; other paths unchanged) | No (key exists) | Recommended |
| #193 | Unit (getRecipesByIngredientId), Widget (Used In tab, empty state, navigation) | No | Optional |
| #329 | Unit (frequency query), Widget (Meal History tab, time-range, empty state) | No | Optional |
| #121 | Widget (entry discoverable, single-recipe regression, count indicator) | No | Required |
| #291 | Unit (model + CRUD), Widget (dialog notes), Integration (history both note types) | Yes | Required (if done) |

---

## Dependencies Map

```
#352 → #351      (cooked_at correct → ordering reliable)
#193 → #329      (ingredient detail screen → meal history tab)
All others: independent
```

---

## Success Criteria

### Must Complete
- [ ] `MealCookedDialog` stores `cooked_at = plannedDate` (#352)
- [ ] Same-day ordering correct — **validated on device** (#351)
- [ ] Unit strings localized in PT-BR across 3 sites (#345)
- [ ] `AddSimpleSideDialog` add button visible at all selection states (#339)
- [ ] `AddSimpleSideDialog` layout intact with suggestions visible (#340)
- [ ] Ingredient cards tighter in recipe details and ingredients screens (#296)
- [ ] "Plan Today" navigates and scrolls to today's slot (#295)
- [ ] Ingredient detail screen with "Used In" tab, navigable from ingredient list (#193)
- [ ] Ingredient detail screen shows usage frequency (meal history tab) (#329)
- [ ] Multi-recipe planning discoverable without menu navigation — **P1** (#121)

### Stretch (Defer to 0.2.4+ if needed)
- [ ] `meal_recipes.notes` column added via idempotent migration (#291)
- [ ] `MealRecordingDialog` accepts per-recipe notes; history displays both note types (#291)

### Sprint Completion
- [ ] `flutter analyze` clean
- [ ] Full test suite passes
- [ ] Release 0.2.3 created and merged to main
- [ ] 0.2.3 milestone closed

---

## Pre-Sprint Checklist

- [ ] **Lock #121 scope** (Day 4 afternoon): choose one UI approach. Candidates: (a) inline "Add side dish" affordance directly in planning slot, (b) toggle at top of recipe selection dialog ("Single Recipe" / "Complete Meal"), (c) tab layout in dialog. Document the decision before writing any code.
- [ ] Confirm `MealCookedDialog` receives `plannedDate` at all call sites (precondition for #352)
- [ ] Confirm `AddSimpleSideDialog` call sites for regression scope (#339, #340)

---

**Plan Created**: 2026-04-16
**Plan Author**: Claude Code (sprint planner skill)
