# Issue #316 — Unified Meal Options Dialog: Implementation Roadmap

| Field | Value |
|---|---|
| **Issue** | [#316 — Redesign Meal Options menu into a rich, unified experience](https://github.com/alemdisso/gastrobrain/issues/316) |
| **Milestone** | 0.2.11 — DB Safety Foundation + UX Polish |
| **Type** | UX Redesign |
| **Priority** | P2-Medium |
| **Estimate** | 5 pts (project field) / 10 pts (sprint plan adjusted) |
| **Status** | Ready |
| **UX Design** | [`docs/design/ux/issue-316-ux-design.md`](../../design/ux/issue-316-ux-design.md) |
| **Branch** | `feature/316-unified-meal-options-dialog` |

---

## Overview

Replaces the `showModalBottomSheet` in `_handleMealTap` with the existing
`RecipeSelectionDialog._buildMenu()`, extended with three missing actions
(View Details, Mark as Cooked, Remove). No DB changes, no new L10N strings —
all required keys already exist in both ARB files.

**Two files change.** Everything else is routing cleanup.

---

## Key Findings from Analysis (Phase 1 already done via UX design)

- `_showingMenu` is **already** auto-set in `initState` when `initialPrimaryRecipe != null` — that gap in the issue description is closed
- `_handleManageRecipes` (lines 917–1028) contains the exact data-loading pattern the new `_handleMealTap` needs — extract and reuse it
- All L10N keys needed exist: `saveChanges`, `markAsCooked`, `editCookedMeal`, `changeRecipe`, `removeFromPlan`, `viewRecipeDetails`, `mealOptions`
- `allScoredRecipes` defaults to `[]` — correct for edit mode (no recommendations needed)
- After the rewrite, three private methods in `weekly_plan_screen.dart` become dead code and can be removed: `_handleManageRecipes`, `_handleManageSimpleSides`, `_handleAddSideDish`

---

## Prerequisites

- [ ] Branch `feature/316-unified-meal-options-dialog` created from `develop`
- [ ] UX design doc reviewed: `docs/design/ux/issue-316-ux-design.md`

---

## Phase 1: Analysis ✅

Analysis completed during UX design session. Findings captured above.
No further analysis tasks.

---

## Phase 2: Implementation

### Step 1 — Extend `RecipeSelectionDialog` (`lib/widgets/recipe_selection_dialog.dart`)

- [ ] Add two constructor parameters:
  ```dart
  final bool isEditMode;       // default: false
  final bool initialMealCooked; // default: false
  ```
- [ ] In `_buildMenu()` — recipe header: wrap existing `Container` in `InkWell`; add trailing `IconButton(Icons.info_outline, tooltip: l10n.viewRecipeDetails)` that returns `{'action': 'view'}` via `Navigator.pop` — **visible only when `isEditMode == true`**
- [ ] In `_buildMenu()` — Save button: label becomes `l10n.saveChanges` when `isEditMode`, `l10n.saveMeal` otherwise (unchanged)
- [ ] In `_buildMenu()` — Save button: return value becomes `{'action': 'save', 'primaryRecipe': ..., 'additionalRecipes': ..., 'plannedServings': ..., 'simpleSides': ...}` when `isEditMode`; unchanged map (no `action` key) otherwise — preserves new-meal flow compatibility
- [ ] In `_buildMenu()` — below Save button, **only when `isEditMode == true`**, add:
  ```
  8px gap
  Row [
    Expanded: OutlinedButton.icon — Mark as Cooked (Icons.check_circle_outline)
              or Edit Cooked Meal (Icons.edit_outlined) when initialMealCooked
              returns {'action': 'cooked'} or {'action': 'edit_cooked'}
    SizedBox(width: 8)
    Expanded: OutlinedButton.icon(Icons.swap_horiz) — Change Recipe
              returns {'action': 'change'}
  ]
  Divider(height: 20)
  SizedBox(width: double.infinity):
    TextButton.icon(Icons.delete_outline) — Remove from Plan
    style: foreground = colorScheme.error
    onPressed: _handleRemoveTap()
  ```
- [ ] Add `_handleRemoveTap()` private method:
  - If `widget.initialMealCooked == true`: show `AlertDialog` asking to confirm (removing also deletes cooking record); on confirm → `Navigator.pop(context, {'action': 'remove'})`
  - If `widget.initialMealCooked == false`: `Navigator.pop(context, {'action': 'remove'})` directly
- [ ] In `_buildMenu()` — Back `TextButton`: **hidden** when `isEditMode == true` (Change Recipe replaces it)
- [ ] Run `flutter analyze` — no issues

### Step 2 — Rewrite `_handleMealTap` (`lib/screens/weekly_plan_screen.dart`)

- [ ] Extract private data-loading method (mirrors pattern from `_handleManageRecipes`):
  ```dart
  Future<({MealPlanItem item, Recipe primary, List<Recipe> additional,
            List<Map<String, dynamic>> simpleSides})?> _loadMealItemForEdit(
      DateTime date, String mealType) async { ... }
  ```
  Returns `null` and shows a SnackBar on any error (item not found, primary recipe null, DB error).

- [ ] Remove the entire `showModalBottomSheet` block from `_handleMealTap` (lines 361–465)

- [ ] Replace with:
  1. Call `_loadMealItemForEdit(date, mealType)` — return early if null
  2. Open `RecipeSelectionDialog` with `isEditMode: true`, `initialMealCooked: mealCooked`, all pre-population params (same as current `_handleManageRecipes` call at line 972–984)
  3. If `result == null` → return (user cancelled)
  4. Route on `result['action']`:
     - `'save'` → persist changes (servings + recipes + simple sides) using the logic currently in `_handleManageRecipes` lines 989–1021
     - `'cooked'` → `await _handleMarkAsCooked(date, mealType, recipeId)`
     - `'edit_cooked'` → `await _handleEditCookedMeal(date, mealType, recipeId)`
     - `'view'` → navigate to `RecipeDetailsScreen`, refresh on return
     - `'change'` → `await _handleSlotTap(date, mealType)`
     - `'remove'` → existing remove logic (lines 522–534)

- [ ] Run `flutter analyze` — no issues

### Step 3 — Remove dead code (`lib/screens/weekly_plan_screen.dart`)

These three methods are only called from the routing block being replaced. Once Step 2 is complete they are unreachable:

- [ ] Delete `_handleManageRecipes` (lines 917–1028)
- [ ] Delete `_handleManageSimpleSides` (lines 776–813)
- [ ] Delete `_handleAddSideDish` (lines 663–775)

> Verify with `flutter analyze` that no other caller exists before deleting.

- [ ] Run `flutter analyze` — no issues after deletions

---

## Phase 3: Testing

### `test/widgets/recipe_selection_dialog_test.dart` — new group: Edit Mode

Write one test, run it, verify it passes, then write the next.

- [ ] `edit mode: dialog opens with isEditMode=true, shows recipe name and info icon`
- [ ] `edit mode: Save Changes returns {action: save} with recipe data`
- [ ] `edit mode: Mark as Cooked returns {action: cooked}`
- [ ] `edit mode: Edit Cooked Meal button shown when initialMealCooked=true`
- [ ] `edit mode: Change Recipe returns {action: change}`
- [ ] `edit mode: info icon tap returns {action: view}`
- [ ] `edit mode: Remove (uncooked) returns {action: remove} without confirm dialog`
- [ ] `edit mode: Remove (cooked) shows confirmation dialog before returning {action: remove}`
- [ ] `edit mode: Remove (cooked) cancel does not pop dialog`
- [ ] `edit mode: Back button is not visible`
- [ ] `edit mode: Cancel returns null`
- [ ] `new-meal mode (regression): Back button still visible`
- [ ] `new-meal mode (regression): Save Meal returns map without action key`

### `test/screens/weekly_plan_screen_test.dart` — new group: Unified Meal Tap Flow

- [ ] `_handleMealTap: opens RecipeSelectionDialog in edit mode (not bottom sheet)`
- [ ] `_handleMealTap: save action updates meal plan recipes and servings`
- [ ] `_handleMealTap: remove action removes meal from plan`
- [ ] `_handleMealTap: cancel returns without changes`

### Full suite

- [ ] `flutter test` — all 2037+ tests pass
- [ ] `flutter analyze` — no issues

---

## Phase 4: Documentation & Merge

- [ ] Commit: `feat: unified meal options dialog replaces bottom sheet (#316)`
  - Include `Closes #316` in commit body
- [ ] Merge `feature/316-unified-meal-options-dialog` → `develop`
- [ ] `git push origin develop`
- [ ] Delete local and remote feature branch
- [ ] Verify GitHub auto-closes #316

---

## Files to Modify

```
lib/widgets/recipe_selection_dialog.dart     — add isEditMode/initialMealCooked, extend _buildMenu()
lib/screens/weekly_plan_screen.dart          — rewrite _handleMealTap, extract helper, remove dead methods
test/widgets/recipe_selection_dialog_test.dart  — new edit-mode test group
test/screens/weekly_plan_screen_test.dart    — new unified-tap test group
```

No ARB changes, no migration, no new files.

---

## Acceptance Criteria

From issue:
- [ ] Tapping an existing planned meal opens `RecipeSelectionDialog` in menu mode, pre-populated with current recipe, additional recipes, simple sides, and servings
- [ ] All actions previously in the bottom sheet are preserved and contextually surfaced
- [ ] Bottom sheet (`showModalBottomSheet`) removed from `_handleMealTap`
- [ ] No regression on any existing functionality

From UX design:
- [ ] Recipe name visible immediately on dialog open — no extra tap required
- [ ] Mark as Cooked / Edit Cooked Meal is context-aware (cooked state drives label)
- [ ] Remove from Plan is visually separated (Divider + error color)
- [ ] Remove of a cooked meal shows confirmation warning
- [ ] New-meal flow (`_handleSlotTap`) is completely unaffected

---

## Risk Assessment

| Risk | Impact | Mitigation |
|---|---|---|
| Removing three handler methods breaks a caller not found by grep | Regression | Run `flutter analyze` after each deletion; it catches dead code |
| `_handleMealTap` `'save'` routing misses a persistence step from `_handleManageRecipes` | Data loss | Copy persistence block verbatim before deleting the source method |
| `weekly_plan_screen.dart` already 1380 lines (🔴 Critical) | Maintenance debt | Deletions in Step 3 net-reduce line count; no backlog entry needed if file shrinks |
| Widget test for `_handleMealTap` is harder to write (screen-level, DI-heavy) | Test coverage gap | Mirror the existing `'Manage Recipes Flow'` test group pattern (lines 974–1185) |
