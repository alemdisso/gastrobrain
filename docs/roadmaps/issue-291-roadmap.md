# Issue #291: Allow Per-Recipe Notes in Multi-Dish Meals

**Milestone**: 0.2.4 - Recipe Enhancement  
**Labels**: enhancement, model, UI, UX, P2  
**Estimate**: 5 points | **Size**: M  
**Branch**: `feature/291-per-recipe-notes`

---

## Phase 1: Analysis & Understanding

### Requirements Summary

When a meal has multiple recipes, the single meal-level `notes` field causes every recipe in that meal to show the same note in its history, regardless of relevance. The fix is to allow the user to add a note per recipe (stored in `MealRecipe.notes`) alongside the existing general meal note.

### Key Findings (pre-analysis complete)

- **No schema or model migration needed.** `meal_recipes.notes TEXT` column exists in the initial schema (`001_initial_schema.dart:104`). `MealRecipe.notes` field already declared and wired in `toMap()` / `fromMap()` / `copyWith()`.
- **The `notes` field is squatted.** `meal_edit_service.dart:110,120` and `weekly_plan_screen.dart:625,635` hardcode `notes: 'Main dish'` / `notes: 'Side dish'`. These labels are redundant — `isPrimaryDish` already encodes that distinction.
- **`mealRecipe.notes` is never displayed.** `meal_history_screen.dart` renders only `meal.notes` (line 577). The data plumbing exists; only the read path is missing.
- **`EditMealRecordingDialog` needs `List<MealRecipe>` for pre-population.** The dialog currently receives only `List<Recipe>`. It must also receive the existing `MealRecipe` list (already loaded at `meal_history_screen.dart:56`) to pre-fill each recipe's note controller.

### Patterns to Follow

| Pattern | Location |
|---|---|
| Per-controller state for dynamic list | `meal_recording_dialog.dart` (`_additionalRecipes` list) |
| Dialog result as Map | `_saveMeal()` returning keyed map |
| Pre-population from model | `edit_meal_recording_dialog.dart` `initState()` |
| Conditional display guard | `meal_history_screen.dart:577` `if (meal.notes.isNotEmpty)` |

### Pre-Implementation Checklist

- [ ] Confirm no other site hardcodes `'Main dish'`/`'Side dish'` into `MealRecipe.notes`
  ```bash
  grep -rn "Main dish\|Side dish" lib/ --include="*.dart"
  ```
- [ ] Confirm `DatabaseHelper.updateMealRecipe()` exists (or identify update path for per-recipe notes on edit)
  ```bash
  grep -n "updateMealRecipe\|insertMealRecipe" lib/database/database_helper.dart
  ```
- [ ] Review full `EditMealRecordingDialog` to understand current `additionalRecipes` flow

---

## Phase 2: Implementation

### Step A — Clear the squatter: service layer

**`lib/core/services/meal_edit_service.dart`**
- [ ] `recordMealWithRecipes()`: remove `notes: 'Main dish'` and `notes: 'Side dish'`; set `notes: null`
- [ ] `recordMealWithRecipes()`: add `Map<String, String?>? recipeNotes` parameter; pass `recipeNotes?[recipe.id]` to each `MealRecipe` constructor
- [ ] `updateMealRecord()`: same — accept `recipeNotes` map; pass through to `MealRecipe` update calls

**`lib/screens/weekly_plan_screen.dart`**
- [ ] Remove `notes: AppLocalizations.of(context)!.mainDish` (line 625)
- [ ] Remove `notes: AppLocalizations.of(context)!.sideDish` (line 635)
- [ ] Update all `recordMealWithRecipes` / `updateMealRecord` call sites to pass `recipeNotes` once available from dialog (Step B)

### Step B — Dialog input: per-recipe note fields

**`lib/widgets/meal_recording_dialog.dart`**
- [ ] Add `Map<String, TextEditingController> _recipeNoteControllers` to state
- [ ] In `initState()`: create a controller for `widget.primaryRecipe.id`; create controllers for each recipe in `widget.additionalRecipes`
- [ ] In `_showAddRecipeDialog()` callback: create controller for newly added recipe
- [ ] When removing a side dish: dispose and remove its controller
- [ ] In `dispose()`: dispose all controllers in `_recipeNoteControllers`
- [ ] In the recipe list section: render a `TextFormField` below each recipe tile
  - Hint text: `AppLocalizations.of(context)!.recipeNoteHint` (e.g. "Note about this dish (optional)")
  - `maxLines: 2`, compact styling
- [ ] In `_saveMeal()`: collect `recipeNotes` map (`recipe.id → controller.text`, skip empty); include as `'recipeNotes': recipeNotes` in returned map

**`lib/widgets/edit_meal_recording_dialog.dart`**
- [ ] Add `final List<MealRecipe> mealRecipes` constructor parameter
- [ ] Add `Map<String, TextEditingController> _recipeNoteControllers` to state
- [ ] In `initState()`: initialise controllers from `mealRecipes` — match `mealRecipe.recipeId` to pre-fill text
- [ ] Mirror the per-recipe note UI from `MealRecordingDialog`
- [ ] In result map: include `'recipeNotes'` the same way
- [ ] In `dispose()`: dispose all controllers

**`lib/screens/cook_meal_screen.dart`**
- [ ] Read `recipeNotes` from dialog result map
- [ ] Pass to `mealEditService.recordMealWithRecipes(recipeNotes: recipeNotes)`

**`lib/screens/weekly_plan_screen.dart`** (three call sites)
- [ ] Each `MealRecordingDialog` result: extract `recipeNotes` and pass to service
- [ ] `EditMealRecordingDialog` instantiation: pass `mealRecipes` list (already available from context)
- [ ] Each `EditMealRecordingDialog` result: extract `recipeNotes` and pass to `updateMealRecord`

**`lib/screens/meal_history_screen.dart`**
- [ ] `EditMealRecordingDialog` instantiation (line ~857): pass loaded `mealRecipes` list

### Step C — Localization

**`lib/l10n/app_en.arb`**
- [ ] `"recipeNoteHint": "Note about this dish (optional)"`
- [ ] `"mealNoteLabel": "Meal note"`
- [ ] `"recipeNoteLabel": "Note"`

**`lib/l10n/app_pt.arb`**
- [ ] `"recipeNoteHint": "Nota sobre este prato (opcional)"`
- [ ] `"mealNoteLabel": "Nota da refeição"`
- [ ] `"recipeNoteLabel": "Nota"`

- [ ] Run `flutter gen-l10n`

### Step D — Display: per-recipe notes in history

**`lib/screens/meal_history_screen.dart`**
- [ ] Locate the recipe-specific `MealRecipe` for the current recipe in `meal.mealRecipes`
- [ ] Replace the existing `if (meal.notes.isNotEmpty)` block with a two-layer display:
  ```dart
  // Recipe-specific note (primary)
  final mealRecipe = meal.mealRecipes?.firstWhere(
    (mr) => mr.recipeId == widget.recipe.id,
    orElse: () => ...,
  );
  if (mealRecipe?.notes != null && mealRecipe!.notes!.isNotEmpty) {
    // Show recipe note prominently
  }
  // General meal note (contextual, secondary style)
  if (meal.notes.isNotEmpty) {
    // Show meal note in bodySmall / muted style
  }
  ```
- [ ] Use `AppLocalizations` labels to visually distinguish the two when both are present

- [ ] Run `flutter analyze` — no warnings

---

## Phase 3: Testing

### Unit Tests — `test/unit/meal_edit_service_test.dart`

- [ ] `recordMealWithRecipes` stores per-recipe notes on `MealRecipe` records
- [ ] `recordMealWithRecipes` with no `recipeNotes` map → all `MealRecipe.notes` are null
- [ ] `recordMealWithRecipes` with partial map (only some recipes) → unmatched recipes get null notes
- [ ] `updateMealRecord` updates per-recipe notes on existing `MealRecipe` records

### Widget Tests — `test/widget/meal_recording_dialog_test.dart`

- [ ] Dialog renders a note field for the primary recipe
- [ ] Dialog renders note fields for all additional recipes
- [ ] Adding a side dish adds a note field for it
- [ ] Removing a side dish removes its note field
- [ ] Notes entered per recipe are returned in `recipeNotes` map on save
- [ ] Empty note fields are omitted from `recipeNotes` map (not stored as `""`)
- [ ] Cancelling dialog returns null (no notes saved)

### Widget Tests — `test/widget/edit_meal_recording_dialog_test.dart`

- [ ] Dialog pre-populates recipe note fields from existing `MealRecipe.notes`
- [ ] Editing a note and saving reflects updated value in result map
- [ ] Recipe with null existing note shows empty field (not a crash)

### Widget Tests — `test/widget/meal_history_screen_test.dart`

- [ ] Meal with recipe-specific note → note shown in that recipe's history
- [ ] Meal with recipe-specific note → note NOT shown in other recipes' histories
- [ ] Meal with only meal-level note → shown in all recipes' histories
- [ ] Meal with both meal-level and recipe note → both shown, recipe note primary
- [ ] Meal with no notes → no notes section rendered (no empty widget)
- [ ] Legacy meal (has `MealRecipe.notes = 'Main dish'` from old data) → 'Main dish' text not surfaced to user (regression guard)

### Edge Cases — `test/edge_cases/`

- [ ] Multi-recipe meal where only some recipes have per-recipe notes
- [ ] Very long note text (>200 chars) — ensure it doesn't overflow the history card
- [ ] Single-recipe meal — note field shown for the one recipe only

### Integration Test — `test/integration/`

- [ ] Full flow: record multi-recipe meal with per-recipe notes → open recipe history → correct notes shown per recipe
- [ ] Full flow: edit meal, change a per-recipe note → history reflects updated note

### Run Final Test Suite

- [ ] `flutter test test/unit/meal_edit_service_test.dart`
- [ ] `flutter test test/widget/meal_recording_dialog_test.dart`
- [ ] `flutter test test/widget/edit_meal_recording_dialog_test.dart`
- [ ] `flutter test test/widget/meal_history_screen_test.dart`
- [ ] `flutter test` — full suite, no regressions

---

## Phase 4: Documentation & Cleanup

- [ ] Run `flutter analyze` — zero warnings
- [ ] Run `flutter test` — all pass
- [ ] Verify localization renders correctly in EN and PT (visual spot-check in simulator)
- [ ] Commit:
  ```
  feature: allow per-recipe notes in multi-dish meals (#291)

  - Remove 'Main dish'/'Side dish' labels from MealRecipe.notes
  - Add per-recipe TextFormField to MealRecordingDialog and EditMealRecordingDialog
  - EditMealRecordingDialog now receives List<MealRecipe> for pre-population
  - meal_edit_service accepts recipeNotes map and stores on MealRecipe
  - meal_history_screen displays recipe-specific note (primary) and
    meal-level note (contextual) independently per recipe

  Closes #291
  ```
- [ ] `git checkout develop && git merge feature/291-per-recipe-notes`
- [ ] `git push origin develop`
- [ ] Delete branch: `git branch -d feature/291-per-recipe-notes`

---

## Files to Modify

```
lib/core/services/meal_edit_service.dart        ← remove labels, add recipeNotes param
lib/widgets/meal_recording_dialog.dart          ← per-recipe note fields
lib/widgets/edit_meal_recording_dialog.dart     ← per-recipe note fields + List<MealRecipe>
lib/screens/cook_meal_screen.dart               ← pass recipeNotes from dialog
lib/screens/weekly_plan_screen.dart             ← 3 call sites: remove labels, pass recipeNotes
lib/screens/meal_history_screen.dart            ← display recipe note + meal note separately
lib/l10n/app_en.arb                             ← 3 new strings
lib/l10n/app_pt.arb                             ← 3 new strings
```

---

## Acceptance Criteria

- [ ] `MealRecipe.notes` is `null` on all newly recorded meals (no "Main dish"/"Side dish")
- [ ] User can add an optional note per recipe in the meal recording dialog
- [ ] Edit dialog pre-populates existing per-recipe notes correctly
- [ ] Meal-level notes field still available for general observations
- [ ] Recipe history shows recipe-specific note prominently; meal-level note contextually
- [ ] No notes section rendered when both are null/empty
- [ ] Existing meals with only meal-level notes display correctly — no regression
- [ ] Localized in EN and PT
- [ ] All new tests pass; no existing tests broken
