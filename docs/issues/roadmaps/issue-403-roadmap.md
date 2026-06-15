# Issue #403: bug: E2E tests reference stale widget keys after #370 (RecipeFormScreen) and #398 (collapsible time fields)

<!-- Save to: docs/issues/roadmaps/issue-403-roadmap.md -->

**Type**: Bug fix (test maintenance + 1-line implementation changes)
**Priority**: P2
**Estimate**: 3 story points
**Size**: M
**Dependencies**: None — confirmed unrelated to #399-#402 (per issue's "Context" section)
**Branch**: `bugfix/403-stale-e2e-widget-keys`

---

## Overview

Two unrelated UI changes left several E2E tests pointing at widget keys that
no longer exist or aren't reachable without extra interaction, discovered
during the 2026-06-13 full `integration_test/` run:

- **Problem 1**: `RecipeStubCreateScreen` (the #396 hub-and-spoke replacement
  for the old add-recipe form) has a name field with **no `Key`**, and saving
  navigates to `RecipeDetailsScreen` via `pushReplacement` — not back to the
  main screen as the old flow did.
- **Problem 2**: #398 made the prep/cook time fields in
  `edit_meal_recording_dialog.dart` collapsible behind an expand toggle
  (`_timesExpanded`, starts `false`). Several tests call
  `fillMealEditDialog`/`find.byKey` for `edit_meal_recording_prep_time_field`/
  `cook_time_field` directly, without expanding first.

**Expected Outcome**: All 9 listed E2E tests pass again, with minimal,
targeted key additions and helper updates — no behavioral changes to the app.

---

## Prerequisites Check

- [ ] On `bugfix/403-stale-e2e-widget-keys` (branched from develop)
- [ ] `flutter test && flutter analyze` clean before starting

---

## Phase 1: Analysis & Understanding — findings from this session

### Problem 1 — recipe creation flow (#396)

- Confirmed: `lib/screens/recipe_stub_create_screen.dart:96` — the name
  `TextFormField` has no `Key` at all.
- Confirmed: `_save()` (`recipe_stub_create_screen.dart:53`) does
  `Navigator.pushReplacement(... RecipeDetailsScreen(recipe: recipe))`.
  `RecipeDetailsScreen`'s `AppBar.title` is `Text(_currentRecipe.name)`
  (`recipe_details_screen.dart:554`) — so `find.text(testRecipeName)` will
  match post-save.
- `e2e_complete_recipe_creation_test.dart`:
  - Lines 54-58: `fillTextFieldByKey(tester, Key('add_recipe_name_field'), ...)`
    — fails today (no such key exists).
  - Lines 74-84: post-save fallback tries `verifyOnMainScreen()` then
    `verifyOnFormScreen()` — neither matches landing on `RecipeDetailsScreen`.

### Problem 2 — collapsible time fields (#398) — confirmed in BOTH dialogs

- `lib/widgets/edit_meal_recording_dialog.dart`:
  - `_timesExpanded` (line 44) defaults `false`.
  - `_buildTimesSection()` (lines 264-333): collapsed state renders an
    **unkeyed** `TextButton` (lines 327-330,
    `onPressed: () => setState(() => _timesExpanded = true)`); expanded state
    reveals `edit_meal_recording_prep_time_field` (271) /
    `edit_meal_recording_cook_time_field` (290).
  - `fillMealEditDialog` (`e2e_test_helpers.dart:954-1013`), lines 970-986:
    unconditionally does `find.byKey(edit_meal_recording_prep_time_field /
    cook_time_field)` + `expect(findsOneWidget)` — fails while collapsed.

- **New finding**: `lib/widgets/meal_recording_dialog.dart` has the
  **identical pattern**:
  - `_timesExpanded` (line 43) defaults `false`.
  - `_buildTimesSection()` (lines 288-357): collapsed state renders an
    **unkeyed** `TextButton` (lines 351-354, same `setState` pattern);
    expanded state reveals `meal_recording_prep_time_field` (295) /
    `meal_recording_cook_time_field` (314).
  - `fillMealRecordingDialog` (`e2e_test_helpers.dart:428-478`), lines
    443-457: same unconditional `find.byKey(...)` +
    `expect(findsOneWidget)` pattern.
  - This is why `e2e_meal_recording_workflow_test.dart`'s two tests are in
    the affected list even though the issue's prose only names
    `edit_meal_recording_dialog.dart`. **Fixing only the edit dialog would
    leave these two tests failing.**

### Affected-test verification — all 9 listed tests cross-checked

- 7 of 9 tests confirmed: direct `fillMealEditDialog(..., prepTime:...,
  cookTime:...)` calls or direct `find.byKey(edit_meal_recording_*_time_field)`
  while `_timesExpanded` starts `false`.
- `e2e_meal_recording_workflow_test.dart` (2 tests): confirmed via the new
  finding above (`meal_recording_dialog.dart`'s own `_timesExpanded`).
- **"Remove side dish from meal during edit workflow"**
  (`e2e_meal_editing_workflow_test.dart:901`) — read in full (lines 901-1180).
  Does **not** directly touch prep/cook time fields or the expand toggle.
  `openMealEditDialog` / `removeSideDishInEditDialog` / `saveMealEditDialog`
  helpers also don't reference time fields. **No Problem-2 trigger found in
  this test's code path** — see Question 1.

### Watchdog findings (Analysis mode, Trigger 2)

- 🔴 `lib/widgets/edit_meal_recording_dialog.dart` — 506 lines (threshold 250
  for widgets) → added to `.github/refactoring-backlog.md`
- 🔴 `lib/widgets/meal_recording_dialog.dart` — 542 lines (threshold 250 for
  widgets) → added to `.github/refactoring-backlog.md`
- Both pre-existing-violation files grow slightly during Phase 2 (one `Key`
  each) — no refactor in this issue, keep additions minimal.

---

## Phase 2: Implementation

### 2.1 Problem 1 — recipe name field key

- [ ] `lib/screens/recipe_stub_create_screen.dart:96` — add
  `key: const Key('add_recipe_name_field')` to the name `TextFormField`

### 2.2 Problem 2 — expand-toggle keys (both dialogs)

- [ ] `lib/widgets/edit_meal_recording_dialog.dart:327-330` — add
  `key: const Key('edit_meal_recording_expand_times_button')` to the
  `TextButton`
- [ ] `lib/widgets/meal_recording_dialog.dart:351-354` — add
  `key: const Key('meal_recording_expand_times_button')` to the `TextButton`

### 2.3 Helper updates — expand before interacting

- [ ] `fillMealEditDialog` (`e2e_test_helpers.dart:954-1013`): if `prepTime`
  or `cookTime` is non-null, before the existing `find.byKey(...)` checks,
  look for `edit_meal_recording_expand_times_button` — if present (section
  still collapsed), tap it and `pumpAndSettle()` first
- [ ] `fillMealRecordingDialog` (`e2e_test_helpers.dart:428-478`): same change
  using `meal_recording_expand_times_button`
- Pattern (both helpers):
  ```dart
  if (prepTime != null || cookTime != null) {
    final expandButton =
        find.byKey(const Key('edit_meal_recording_expand_times_button'));
    if (expandButton.evaluate().isNotEmpty) {
      await tester.tap(expandButton);
      await tester.pumpAndSettle();
    }
  }
  ```
  then proceed with the existing per-field `find`/`enterText` logic unchanged.

### 2.4 Problem 1 — post-save navigation check

- [ ] `e2e_complete_recipe_creation_test.dart:74-84` — replace the
  `verifyOnMainScreen()` / `verifyOnFormScreen()` fallback with a check that
  the app landed on `RecipeDetailsScreen` for the new recipe:
  `expect(find.text(testRecipeName), findsWidgets)` (matches the AppBar title
  set in `recipe_details_screen.dart:554`). Optionally wrap in a new
  `E2ETestHelpers.verifyOnRecipeDetailsScreen(tester, {String? recipeName})`
  for parity with `verifyOnMainScreen`/`verifyOnFormScreen` — small helper,
  one-line body, only if it reads more clearly than the inline `expect`.
- [ ] Confirm the `finally` cleanup block (line 140,
  `deleteTestRecipe`) still works correctly when the test ends on
  `RecipeDetailsScreen` rather than the main screen (it operates on the
  database directly, so should be unaffected — verify during 3.1).

### flutter analyze

- [ ] Run after 2.1-2.4

---

## Phase 3: Testing

### 3.1 Run each affected E2E test (per 2026-06-13 affected list)

- [ ] `e2e_complete_recipe_creation_test.dart` — "Create a minimal recipe and
  verify full workflow"
- [ ] `e2e_meal_editing_accessibility_test.dart` — 6.2 "Edit dialog has proper
  semantic labels and accessibility"
- [ ] `e2e_meal_editing_edge_cases_test.dart` — "Validation errors prevent
  saving and do not corrupt data", "Empty required fields prevent saving and
  show validation error", "Cancellation discards all changes and returns to
  original state"
- [ ] `e2e_meal_editing_fields_test.dart` — "Edit multiple fields
  simultaneously and verify all changes saved", "Time fields: add times to
  meal with no times", "Time fields: clear existing times", "Time fields:
  change existing times to different values"
- [ ] `e2e_meal_editing_integration_test.dart` — 7.5 "Multiple rapid edits
  maintain data integrity"
- [ ] `e2e_meal_editing_workflow_test.dart` — "Remove side dish from meal
  during edit workflow" (see Question 1 — investigate further if still
  failing after 2.1-2.4)
- [ ] `e2e_meal_recording_workflow_test.dart` — "Record a meal with current
  date and verify in history", "Record a meal with past date and verify in
  history"

### 3.2 Regression check — unaffected tests still pass

- [ ] Spot-check 1-2 tests per helper that were **not** in the affected list
  and call `fillMealEditDialog`/`fillMealRecordingDialog` without
  `prepTime`/`cookTime` (e.g. "Complete workflow: ... save changes, verify UI
  update" in `e2e_meal_editing_workflow_test.dart`, and a notes-only test in
  `e2e_meal_editing_fields_test.dart`) — confirms the "expand before interact"
  branch is correctly skipped when not needed.

### 3.3 Full suite

- [ ] `flutter test && flutter analyze`
- [ ] Full `integration_test/e2e/` run

---

## Phase 4: Documentation & Cleanup

- [ ] `flutter analyze` — no new issues
- [ ] `flutter test` — all pass
- [ ] Commit: `fix: update stale E2E widget key references after #396/#398 (#403)`
- [ ] Push branch, merge to develop (solo workflow)
- [ ] Close #403 (`Closes #403` in commit message auto-closes on push, per
  [[feedback_github_auto_close]])

---

## Files to Modify

### Implementation (1-line changes)
- `lib/screens/recipe_stub_create_screen.dart` — add `Key` to name field
- `lib/widgets/edit_meal_recording_dialog.dart` — add `Key` to expand-toggle
  button
- `lib/widgets/meal_recording_dialog.dart` — add `Key` to expand-toggle button

### Test Helpers
- `integration_test/e2e/helpers/e2e_test_helpers.dart` — `fillMealEditDialog`,
  `fillMealRecordingDialog`, optionally new `verifyOnRecipeDetailsScreen`

### Test Files
- `integration_test/e2e/e2e_complete_recipe_creation_test.dart` — post-save
  navigation check

No other test files need direct edits — they call the updated helpers and
will pick up the fix transitively.

---

## Acceptance Criteria

### From Issue
- [ ] Add a key (e.g. `add_recipe_name_field`) to the name field in
  `RecipeStubCreateScreen`
- [ ] `e2e_complete_recipe_creation_test.dart` updated for the post-save
  navigation to `RecipeDetailsScreen` (hub-and-spoke flow from #396)
- [ ] `edit_meal_recording_dialog.dart`'s time-fields expand-toggle is
  reachable from `e2e_test_helpers.dart` (key added)
- [ ] `e2e_test_helpers.dart` (`fillMealEditDialog` and friends) expand the
  collapsible time-fields section before interacting with prep/cook time
  fields
- [ ] All listed E2E tests pass again

### Implicit (scope clarification from Phase 1 findings — not new work)
- [ ] `meal_recording_dialog.dart`'s expand-toggle also gets a key (same
  pattern as the edit dialog) — required for `e2e_meal_recording_workflow_test.dart`
  to pass, which is on the issue's own affected-test list
- [ ] `fillMealRecordingDialog` also expands before interacting — same
  reasoning
- [ ] `flutter analyze` clean
- [ ] `flutter test` all pass
- [ ] No new 🔴 Critical watchdog entries beyond the two pre-existing dialog
  files flagged this session

---

## Risk Assessment

**Low-medium risk** — mechanical key additions + helper updates, but touches
widely-used dialogs and the E2E suite's largest test files.

1. **Both dialog files already over the widgets 250-line threshold** (506 /
   542 lines). *Mitigation*: adding one `Key` per file is a 1-line change;
   already flagged to the backlog, no refactor in this issue.
2. **"Remove side dish" test cause unconfirmed** — see Question 1.
   *Mitigation*: re-run after 2.1-2.4; if it now passes, the 2026-06-13
   failure was a downstream effect. If it still fails, investigate separately
   rather than blocking the rest of #403.
3. **Helper changes affect all callers** — `fillMealEditDialog`/
   `fillMealRecordingDialog` are used by many tests beyond the affected list.
   *Mitigation*: the "expand before interact" branch only runs when
   `prepTime`/`cookTime` is non-null; Phase 3.2 spot-checks confirm
   unaffected tests are unaffected.

---

## Questions

1. **"Remove side dish from meal during edit workflow" — Problem 2 trigger
   not found**:
   - Context: this test is in the issue's affected-tests list under Problem
     2, but a full read of the test and its helpers shows no reference to
     `edit_meal_recording_prep_time_field`/`cook_time_field` or the expand
     toggle.
   - Impact: Phase 2's fixes may or may not resolve it.
   - Recommendation: proceed with 2.1-2.4, then run this test (3.1). If it
     passes, no further action. If it still fails, capture the new error and
     decide whether to extend #403 or file a follow-up — don't block the rest
     of this issue on one test.

2. **Expand-toggle key naming**:
   - Context: the issue suggests "either a new key on that button or a
     text/type-based finder."
   - Recommendation: proceed with
     `edit_meal_recording_expand_times_button` /
     `meal_recording_expand_times_button` for consistency with each dialog's
     existing `*_field`/`*_button` key naming, unless you'd prefer a
     text/type-based finder instead (no key addition, but more brittle to
     l10n string changes).

---

## Notes

**Assumptions**:
- Issue AC #5 ("All listed E2E tests pass again") is binding — since
  `e2e_meal_recording_workflow_test.dart` is on that list, the symmetric fix
  to `meal_recording_dialog.dart` is in-scope even though the issue's prose
  only names `edit_meal_recording_dialog.dart`.
- The `editTimesButton` l10n string (used by both dialogs' collapsed-state
  `TextButton`) already exists in both ARB files from #398 — no new
  localization needed.

**Follow-Up Work**:
- `edit_meal_recording_dialog.dart` (506 lines) and `meal_recording_dialog.dart`
  (542 lines) refactors remain in `.github/refactoring-backlog.md` — not
  addressed here.

**References**:
- Issue: #403
- Related: #396 (recipe creation hub-and-spoke), #398 (collapsible time
  fields)

---

**Roadmap Created**: 2026-06-15
**Last Updated**: 2026-06-15
**Status**: Phase 1 complete. Ready for Phase 2 implementation pending
Rodrigo's go-ahead.
