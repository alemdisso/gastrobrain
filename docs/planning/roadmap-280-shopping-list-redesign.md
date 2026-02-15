# Roadmap: #280 — Redesign Shopping List Generation Flow

| Field       | Value                                      |
|-------------|--------------------------------------------|
| **Type**    | UX / UI Redesign                           |
| **Priority**| P1                                         |
| **Estimate**| 8 points (absorbs #277 — 5 points)         |
| **Milestone**| 0.1.9 - Meal Planning UX Redesign         |
| **Depends on**| #279 ✅, #271 ✅                          |
| **Absorbs** | #277 (bottom sheets → full-screen)         |
| **Branch**  | `ux/280-shopping-list-redesign`            |

## Overview

Replace the fragmented 3-path menu system (preview bottom sheet, refinement bottom sheet, saved list screen) with a unified full-screen flow using navigator stack: FAB → Preview → Refinement → Saved. Remove the bottom bar entirely. Move summary to app bar. Add stale list detection.

## UX Design Reference

Full UX exploration completed in-session (Checkpoints 1-6). Key decisions:

- **Navigator stack** (Option B): Each mode is a separate route with natural back behavior
- **FAB entry**: One-tap access, no menu intermediary
- **Bottom bar removed**: Summary → app bar icon, shopping list → FAB
- **Stale detection**: Compare `mealPlan.modifiedAt` at save time vs current
- **Future-ready**: Category grouping preserved as pivot for future exclusion filters and multi-store lists

## Prerequisites

- [x] #279 color system merged
- [x] #271 meal slot redesign merged
- [ ] Read current implementation of all affected files
- [ ] Understand `ShoppingListService` API surface

---

## Phase 1: Analysis & Understanding

- [ ] Read `lib/screens/weekly_plan_screen.dart` — bottom bar (`_buildBottomBar`), shopping menu (`_buildShoppingListOptions`), summary sheet (`_openSummarySheet`), all shopping-related methods
- [ ] Read `lib/widgets/shopping_list_preview_bottom_sheet.dart` (180 lines) — understand ingredient display logic
- [ ] Read `lib/widgets/shopping_list_refinement_bottom_sheet.dart` (406 lines) — understand checkbox state model, return value pattern
- [ ] Read `lib/screens/shopping_list_screen.dart` (296 lines) — understand saved list display, filters, toggle logic
- [ ] Read `lib/core/services/shopping_list_service.dart` (405 lines) — understand `calculateProjectedIngredients()` and `generateFromCuratedIngredients()`
- [ ] Read `lib/models/shopping_list.dart` and `shopping_list_item.dart` — understand data model
- [ ] Read `lib/widgets/weekly_summary_widget.dart` (312 lines) — understand summary content for relocation
- [ ] Review skipped tests in `test/screens/weekly_plan_screen_test.dart` — understand what the 6 skipped summary tests expect
- [ ] Map all localization keys currently used across these files
- [ ] Identify all call sites that reference the bottom bar, shopping menu, or summary sheet

---

## Phase 2: Implementation

### 2.1 — Weekly Plan Screen: Remove Bottom Bar, Add FAB + App Bar Summary

**Goal**: Clean entry points — FAB for shopping, app bar for summary.

- [ ] Remove `_buildBottomBar()` method and its call site
- [ ] Remove `_isSummarySheetOpen` / `_isShoppingSheetOpen` state variables
- [ ] Remove `_buildShoppingListOptions()` menu method
- [ ] Remove `_openShoppingSheet()` / `_showShoppingPreview()` methods
- [ ] Add `FloatingActionButton` with shopping cart icon to `Scaffold`
- [ ] FAB `onPressed`: Check for existing saved list → navigate to Preview or Saved accordingly
- [ ] Add summary `IconButton` to app bar actions (analytics/bar_chart icon, near refresh)
- [ ] Summary button opens `_openSummarySheet()` (keep as bottom sheet — it's lightweight, no redesign needed)
- [ ] Update `_openSummarySheet()` if needed (remove bottom-bar-related state tracking)
- [ ] Run `flutter analyze`

### 2.2 — New Preview Screen

**Goal**: Full-screen read-only ingredient list, replaces preview bottom sheet.

- [ ] Create `lib/screens/shopping_list_preview_screen.dart`
- [ ] `Scaffold` with `AppBar` (title: localized "Ingredients", back button)
- [ ] Receive `weekStartDate` and `weekEndDate` parameters
- [ ] Call `ShoppingListService.calculateProjectedIngredients()` on init
- [ ] Show loading state (`CircularProgressIndicator`) while calculating
- [ ] Display grouped ingredient list with `ExpansionTile` per category (expanded by default)
- [ ] Each ingredient: `ListTile` with name + formatted quantity
- [ ] Bottom action bar with two buttons: "Refine" and "Generate List"
- [ ] "Refine" → `Navigator.push` to Refinement screen (pass grouped ingredients)
- [ ] "Generate List" → call service to save all ingredients, then `Navigator.pushReplacement` to Saved screen
- [ ] Empty state: Cart icon + "No meals planned" message
- [ ] Run `flutter analyze`

### 2.3 — New Refinement Screen

**Goal**: Full-screen checkbox ingredient list, replaces refinement bottom sheet.

- [ ] Create `lib/screens/shopping_list_refinement_screen.dart`
- [ ] `Scaffold` with `AppBar` (title: localized "Refine List", back returns to Preview)
- [ ] Receive `groupedIngredients` parameter (already calculated by Preview)
- [ ] Initialize all checkboxes to `true` (opt-out model)
- [ ] Select/deselect all with tri-state `CheckboxListTile` + count text ("X of Y selected")
- [ ] Category `ExpansionTile` groups (expanded by default)
- [ ] Each ingredient: `CheckboxListTile` with strikethrough on unchecked
- [ ] Bottom action bar: "Generate Shopping List (N)" button
- [ ] Validate at least 1 item selected (SnackBar error if empty)
- [ ] On generate: call `ShoppingListService.generateFromCuratedIngredients()`, then `Navigator.pushReplacement` to Saved screen (clearing Preview from stack)
- [ ] Run `flutter analyze`

### 2.4 — Update Saved List Screen (Stale Detection + Collapsed Categories)

**Goal**: Add stale warning, collapse categories by default, integrate into new flow.

- [ ] Add stale detection: compare saved `mealPlanModifiedAt` vs current `mealPlan.modifiedAt`
- [ ] Add `MaterialBanner` for stale warning with "Update" action button
- [ ] "Update" action: navigate to Preview screen (regenerate flow)
- [ ] Change categories to collapsed by default (user is shopping, focuses per section)
- [ ] Add item count to category headers (e.g., "Vegetais (3)")
- [ ] Ensure back button returns to weekly plan screen (not Preview)
- [ ] Run `flutter analyze`

### 2.5 — Model Update: Store Meal Plan Timestamp

**Goal**: Enable stale detection by storing when the list was generated.

- [ ] Add `mealPlanModifiedAt` field to `ShoppingList` model
- [ ] Create database migration to add column to `shopping_lists` table
- [ ] Update `ShoppingListService.generateFromCuratedIngredients()` to store the timestamp
- [ ] Update `fromMap` / `toMap` in model
- [ ] Run `flutter analyze`

### 2.6 — Delete Old Files

- [ ] Delete `lib/widgets/shopping_list_preview_bottom_sheet.dart`
- [ ] Delete `lib/widgets/shopping_list_refinement_bottom_sheet.dart`
- [ ] Remove any remaining imports/references to deleted files
- [ ] Run `flutter analyze`

### 2.7 — Localization

- [ ] Add new strings to `lib/l10n/app_en.arb` (preview title, refine title, refine action, generate all, generate count, stale warning, stale action, empty title, empty subtitle)
- [ ] Add translations to `lib/l10n/app_pt.arb`
- [ ] Run `flutter gen-l10n`
- [ ] Verify no hardcoded strings remain in new files
- [ ] Run `flutter analyze`

### 2.8 — Navigation Wiring & Integration Test

- [ ] Verify full flow: FAB → Preview → Refine → Generate → Saved
- [ ] Verify shortcut flow: FAB → Preview → Generate All → Saved
- [ ] Verify returning user flow: FAB → Saved (when list exists)
- [ ] Verify stale flow: FAB → Saved (stale) → Update → Preview → Refine → Saved
- [ ] Verify summary opens from app bar icon
- [ ] Verify back navigation at each step
- [ ] Run `flutter analyze`

---

## Phase 3: Testing

### 3.1 — Update Existing Tests

- [ ] Update `test/screens/weekly_plan_screen_test.dart` — remove bottom bar assertions, add FAB assertions, add app bar summary button assertions
- [ ] Fix 6 skipped summary tests for new app bar architecture
- [ ] Delete `test/widgets/shopping_list_preview_bottom_sheet_test.dart` (if exists)
- [ ] Delete `test/widgets/shopping_list_refinement_bottom_sheet_test.dart` (if exists)
- [ ] Update any other tests that reference deleted files or bottom bar

### 3.2 — New Widget Tests: Preview Screen

- [ ] Renders ingredient list grouped by category
- [ ] Categories expanded by default
- [ ] Shows loading state while calculating
- [ ] Shows empty state when no meals planned
- [ ] "Refine" button navigates to refinement screen
- [ ] "Generate List" button creates saved list and navigates to saved screen
- [ ] Back button returns to weekly plan

### 3.3 — New Widget Tests: Refinement Screen

- [ ] All checkboxes initially checked
- [ ] Unchecking item shows strikethrough
- [ ] Select/deselect all works (tri-state)
- [ ] Count text updates on selection changes ("X of Y selected")
- [ ] Generate button shows selected count
- [ ] Validation: error when no items selected
- [ ] Generate creates list and navigates to saved screen
- [ ] Back button returns to preview

### 3.4 — New Widget Tests: Saved Screen (Stale Detection)

- [ ] Stale warning shown when `mealPlanModifiedAt` differs from current
- [ ] Stale warning NOT shown when timestamps match
- [ ] "Update" action navigates to preview (regenerate flow)
- [ ] Categories collapsed by default
- [ ] Category headers show item count

### 3.5 — Flow / Integration Tests

- [ ] Full flow: FAB → Preview → Refine → Generate → Saved
- [ ] Shortcut flow: FAB → Preview → Generate All → Saved
- [ ] Return flow: FAB → Saved (existing list)
- [ ] Stale regenerate flow: FAB → Saved (stale) → Update → Preview
- [ ] Summary from app bar

### 3.6 — Edge Case Tests

- [ ] Empty meal plan → empty state in preview
- [ ] All ingredients are excluded staples → appropriate message
- [ ] Very long ingredient list → scrolls without overflow
- [ ] Refinement: uncheck all → try generate → error message
- [ ] Database error during generation → error snackbar, stays in refinement

### 3.7 — Regression Tests

- [ ] Ingredient calculation unchanged (existing service tests should pass)
- [ ] Saved list toggle toBuy still works
- [ ] Filter chips still work on saved list
- [ ] Week navigation on weekly plan unaffected
- [ ] Meal slot interactions unaffected

### 3.8 — Run Full Suite

- [ ] `flutter test` — all pass
- [ ] `flutter analyze` — clean

---

## Phase 4: Documentation & Cleanup

- [ ] Close #277 as "resolved by #280"
- [ ] Update code comments where complex logic exists (stale detection, navigation flow)
- [ ] Run final `flutter analyze && flutter test`
- [ ] Commit: `ux: redesign shopping list flow with unified state-based interface (#280)`
- [ ] Push to `ux/280-shopping-list-redesign`
- [ ] Merge to develop
- [ ] Close issue #280

---

## Files to Create

| File | Purpose |
|------|---------|
| `lib/screens/shopping_list_preview_screen.dart` | New preview screen (full-screen) |
| `lib/screens/shopping_list_refinement_screen.dart` | New refinement screen (full-screen) |
| `lib/core/database/migrations/add_meal_plan_modified_at_to_shopping_list.dart` | Migration for stale detection |
| `test/screens/shopping_list_preview_screen_test.dart` | Preview screen tests |
| `test/screens/shopping_list_refinement_screen_test.dart` | Refinement screen tests |

## Files to Modify

| File | Changes |
|------|---------|
| `lib/screens/weekly_plan_screen.dart` | Remove bottom bar, add FAB, move summary to app bar |
| `lib/screens/shopping_list_screen.dart` | Add stale banner, collapse categories, item counts |
| `lib/models/shopping_list.dart` | Add `mealPlanModifiedAt` field |
| `lib/core/services/shopping_list_service.dart` | Store timestamp on generation |
| `lib/core/database/database_helper.dart` | Register new migration |
| `lib/l10n/app_en.arb` | New localization strings |
| `lib/l10n/app_pt.arb` | Portuguese translations |
| `test/screens/weekly_plan_screen_test.dart` | Update for FAB/app bar, fix 6 skipped tests |
| `test/screens/shopping_list_screen_test.dart` | Add stale detection tests |

## Files to Delete

| File | Reason |
|------|--------|
| `lib/widgets/shopping_list_preview_bottom_sheet.dart` | Replaced by preview screen |
| `lib/widgets/shopping_list_refinement_bottom_sheet.dart` | Replaced by refinement screen |

---

## Suggested Implementation Order

Given the 8-point size, I recommend splitting into focused commits:

1. **Commit 1** — Weekly plan screen: remove bottom bar, add FAB + app bar summary
2. **Commit 2** — Preview screen + localization strings
3. **Commit 3** — Refinement screen
4. **Commit 4** — Model update + migration + stale detection in saved screen
5. **Commit 5** — Delete old files, wire navigation, fix all tests
6. **Commit 6** — Close #277, final cleanup

This keeps each commit reviewable and testable independently.

---

## Acceptance Criteria

From issue + UX design + implicit requirements:

- [ ] Bottom bar removed from weekly plan screen
- [ ] FAB opens shopping list flow (one tap, no menu)
- [ ] Summary accessible from app bar icon button
- [ ] Preview screen: full-screen, read-only ingredient list, "Refine" and "Generate" actions
- [ ] Refinement screen: full-screen, checkbox list, select/deselect all, generate with count
- [ ] Saved screen: stale warning when meal plan changed, collapsed categories with counts
- [ ] Navigator stack: natural back behavior between modes
- [ ] Existing saved list: FAB goes directly to Saved mode
- [ ] No existing list: FAB goes to Preview mode
- [ ] 6 previously-skipped summary tests fixed and passing
- [ ] Old bottom sheet files deleted
- [ ] #277 closed as resolved by #280
- [ ] Localized in EN and PT-BR
- [ ] All tests pass (`flutter test && flutter analyze`)
- [ ] No regressions in meal planning, ingredient calculation, or saved list functionality
