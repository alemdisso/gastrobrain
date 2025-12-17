<!-- markdownlint-disable -->
# Issue #126: E2E Meal Editing Workflow Tests - Implementation Roadmap

**Issue:** Add comprehensive integration tests for the meal editing workflow
**Created:** 2025-12-12
**Related Issue:** [#126](https://github.com/alemdisso/gastrobrain/issues/126)

---

## Overview

This roadmap outlines the implementation plan for comprehensive end-to-end integration tests that validate the complete meal editing workflow. The tests will ensure all components work together seamlessly from the user's perspective.

### Reference Files
- **Existing Widget Tests:** `test/screens/meal_history_edit_test.dart`
- **E2E Test Example:** `integration_test/e2e_recipe_editing_workflow_test.dart`
- **E2E Guidelines:** `docs/testing/E2E_TESTING.md`
- **E2E Helpers:** `integration_test/helpers/e2e_test_helpers.dart`
- **Edit Dialog Implementation:** `lib/widgets/edit_meal_recording_dialog.dart`
- **Meal History Screen:** `lib/screens/meal_history_screen.dart`

### Test Types to Implement
1. **E2E Integration Tests** - Full workflow with real database (run manually)
2. **Service Integration Tests** - Database operations with MockDatabaseHelper (run in CI)

---

## Available Form Field Keys

The `EditMealRecordingDialog` has the following keys available for testing:

| Key | Widget Type | Description |
|-----|-------------|-------------|
| `edit_meal_recording_servings_field` | TextFormField | Number of servings |
| `edit_meal_recording_prep_time_field` | TextFormField | Actual prep time (minutes) |
| `edit_meal_recording_cook_time_field` | TextFormField | Actual cook time (minutes) |
| `edit_meal_recording_notes_field` | TextFormField | Notes (optional) |
| `edit_meal_recording_success_switch` | Switch | Was it successful toggle |

### Features Available in Edit Dialog
- **Date picker**: Tap on date ListTile to open date picker
- **Add side dish**: "Add Recipe" button opens recipe selection dialog
- **Remove side dish**: Delete icon on each side dish ListTile
- **wasSuccessful toggle**: Switch widget

---

## Existing E2E Helpers Analysis

### Available Helpers (for MEAL CREATION - `meal_recording_*` keys)
These helpers exist but use **different keys** than the edit dialog:
- `openMealRecordingDialog(tester)` - Opens from CookMealScreen
- `fillMealRecordingDialog(tester, {...})` - Uses `meal_recording_*` keys
- `saveMealRecordingDialog(tester)` - Uses `meal_recording_save_button` key
- `verifyMealInDatabase(dbHelper, recipeId, {...})` - Verifies meal exists
- `deleteTestMeal(dbHelper, mealId)` - Cleanup helper

### Helpers Needed for MEAL EDITING
New helpers required (use `edit_meal_recording_*` keys):
- `navigateToMealHistory(tester, recipeName)` - Navigate to meal history for a recipe
- `openMealEditDialog(tester, {index})` - Tap edit button on a meal card
- `fillMealEditDialog(tester, {...})` - Fill edit dialog fields
- `saveMealEditDialog(tester)` - Save edit changes
- `cancelMealEditDialog(tester)` - Cancel edit dialog
- `addSideDishInEditDialog(tester, recipeName)` - Add side dish
- `removeSideDishInEditDialog(tester, index)` - Remove side dish
- `selectDateInEditDialog(tester, date)` - Change cooked date

---

## Phase 1: Infrastructure & Basic Workflow

**Goal:** Establish test infrastructure and implement the basic happy-path workflow test.

### Pre-requisites
- [x] Review existing `E2ETestHelpers` for available helper methods
- [x] Identify any missing helper methods needed for meal editing
- [x] Verify form field keys exist for meal edit dialog (check for `edit_meal_recording_*` keys)

### Tasks

#### 1.1 Create Test File Structure
- [X] Create `integration_test/e2e_meal_editing_workflow_test.dart`
- [X] Add proper file header documentation following existing patterns:
  ```dart
  /// Meal Editing Workflow E2E Test
  ///
  /// This test verifies the complete meal editing workflow:
  /// 1. Navigate to meal history for a recipe
  /// 2. Open the edit dialog for an existing meal
  /// 3. Modify meal fields
  /// 4. Save changes
  /// 5. Verify UI updates immediately
  /// 6. Verify database persistence
  ```
- [X] Import required packages and helpers
- [X] Set up `IntegrationTestWidgetsFlutterBinding.ensureInitialized()`

#### 1.2 Add Helper Methods to `E2ETestHelpers`
Add these new helpers to `integration_test/helpers/e2e_test_helpers.dart`:

```dart
// MEAL EDITING HELPERS section

/// Navigate to meal history screen for a recipe
static Future<void> navigateToMealHistory(
  WidgetTester tester,
  String recipeName,
) async { ... }

/// Open the edit dialog for a meal at the given index
static Future<void> openMealEditDialog(
  WidgetTester tester, {
  int mealIndex = 0,
}) async {
  final editButtons = find.byIcon(Icons.edit);
  expect(editButtons.evaluate().length, greaterThan(mealIndex));
  await tester.tap(editButtons.at(mealIndex));
  await tester.pumpAndSettle();
}

/// Fill in the meal edit dialog fields
/// Uses edit_meal_recording_* keys
static Future<void> fillMealEditDialog(
  WidgetTester tester, {
  String? servings,
  String? prepTime,
  String? cookTime,
  String? notes,
  bool? toggleSuccess,
}) async {
  if (servings != null) {
    final field = find.byKey(const Key('edit_meal_recording_servings_field'));
    await tester.enterText(field, servings);
  }
  // ... similar for other fields
}

/// Save the meal edit dialog
static Future<void> saveMealEditDialog(WidgetTester tester) async {
  final saveButton = find.text('Save Changes'); // or localized text
  await tester.tap(saveButton);
  await tester.pumpAndSettle(standardSettleDuration);
}

/// Cancel the meal edit dialog
static Future<void> cancelMealEditDialog(WidgetTester tester) async {
  final cancelButton = find.text('Cancel'); // or localized text
  await tester.tap(cancelButton);
  await tester.pumpAndSettle();
}

/// Add a side dish in the edit dialog
static Future<void> addSideDishInEditDialog(
  WidgetTester tester,
  String recipeName,
) async {
  final addButton = find.text('Add Recipe'); // localized
  await tester.tap(addButton);
  await tester.pumpAndSettle();

  final recipeItem = find.text(recipeName);
  await tester.tap(recipeItem);
  await tester.pumpAndSettle();
}

/// Remove a side dish in the edit dialog by index
static Future<void> removeSideDishInEditDialog(
  WidgetTester tester,
  int index,
) async {
  final deleteButtons = find.byIcon(Icons.delete_outline);
  await tester.tap(deleteButtons.at(index));
  await tester.pumpAndSettle();
}

/// Verify meal in database with specific field values
static Future<void> verifyMealFieldsInDatabase(
  DatabaseHelper dbHelper,
  String mealId, {
  int? expectedServings,
  String? expectedNotes,
  double? expectedPrepTime,
  double? expectedCookTime,
  bool? expectedWasSuccessful,
}) async {
  final meal = await dbHelper.getMeal(mealId);
  expect(meal, isNotNull);
  if (expectedServings != null) expect(meal!.servings, expectedServings);
  if (expectedNotes != null) expect(meal!.notes, expectedNotes);
  // ... etc
}
```

- [X] Add `navigateToMealHistory(tester, recipeName)` helper
- [X] Add `openMealEditDialog(tester, {mealIndex})` helper
- [X] Add `fillMealEditDialog(tester, {...})` helper (uses `edit_meal_recording_*` keys)
- [X] Add `saveMealEditDialog(tester)` helper
- [X] Add `cancelMealEditDialog(tester)` helper
- [X] Add `addSideDishInEditDialog(tester, recipeName)` helper
- [X] Add `removeSideDishInEditDialog(tester, index)` helper
- [X] Add `verifyMealFieldsInDatabase(dbHelper, mealId, {...})` helper

#### 1.3 Basic Happy-Path Test (Single-Recipe Meal)
```dart
testWidgets('Complete workflow: open meal history, edit meal, save changes, verify UI update',
    (WidgetTester tester) async {
  // Test implementation
});
```

- [X] Create test with proper structure (try/finally for cleanup)
- [X] **Setup:** Create test recipe and test meal via database
  ```dart
  final testRecipe = Recipe(
    id: 'e2e-edit-recipe-${DateTime.now().millisecondsSinceEpoch}',
    name: 'E2E Edit Test Recipe',
    ...
  );
  await dbHelper.insertRecipe(testRecipe);

  final testMeal = Meal(
    id: 'e2e-edit-meal-${DateTime.now().millisecondsSinceEpoch}',
    servings: 2,
    notes: 'Original notes',
    ...
  );
  await dbHelper.insertMeal(testMeal);
  await dbHelper.insertMealRecipe(MealRecipe(...));
  ```
- [X] **Navigate:** Launch app → Find recipe in list → Tap to open → Open meal history
- [X] **Act:** Tap edit button → Modify servings field → Save changes
- [X] **Verify UI:** Confirm snackbar shows success message
- [X] **Verify UI:** Confirm meal card shows updated servings value
- [X] **Verify Database:** Confirm `dbHelper.getMeal(mealId)` has updated value
- [X] **Cleanup:** Delete test meal and recipe in `finally` block

#### 1.4 Document Test Progress
- [X] Add print statements for each major step:
  ```dart
  print('=== LAUNCHING APP ===');
  print('✓ App launched');
  print('\\n=== NAVIGATING TO MEAL HISTORY ===');
  // etc.
  ```
- [X] Verify test runs successfully on Windows environment
- [X] Record test execution time for baseline (target: < 60 seconds)

---

## Phase 2: Multi-Recipe Meal Workflows

**Goal:** Test the complete workflow for meals with multiple recipes (primary + side dishes).

### Tasks

#### 2.1 Multi-Recipe Meal Edit Test
- [X] Create test: `'Edit multi-recipe meal and verify all recipes preserved'`
- [X] Setup: Create test recipe, side recipe, and multi-recipe meal
- [X] Navigate: Launch app → Navigate to recipe → Open meal history
- [X] Verify: UI displays side dish count correctly (e.g., "1 side dish")
- [X] Act: Tap edit button → Modify servings → Save
- [X] Verify: Side dishes still displayed after edit
- [X] Verify: Database maintains all meal-recipe associations
- [X] Cleanup: Delete all test data

#### 2.2 Add Side Dish During Edit Test
- [X] Create test: `'Add side dish to existing meal during edit workflow'`
- [X] Setup: Create test recipe, side recipe, and single-recipe meal
- [X] Navigate: Launch app → Navigate to recipe → Open meal history
- [X] Act: Tap edit button → Add side dish → Save
- [X] Verify: UI shows updated side dish count
- [X] Verify: Database has new MealRecipe association
- [X] Cleanup: Delete all test data

#### 2.3 Remove Side Dish During Edit Test
- [X] Create test: `'Remove side dish from meal during edit workflow'`
- [X] Setup: Create test recipe, side recipe, and multi-recipe meal
- [X] Act: Tap edit button → Remove side dish → Save
- [X] Verify: UI no longer shows side dish
- [X] Verify: Database MealRecipe association removed
- [X] Cleanup: Delete all test data

---

## Phase 3: Field Combinations & Data Consistency

**Goal:** Test editing multiple fields simultaneously and verify data consistency.

### Tasks

#### 3.1 Multiple Fields Edit Test
- [X] Create test: `'Edit multiple fields simultaneously and verify all changes saved'`
- [X] Setup: Create meal with all fields populated
- [X] Act: Edit servings, notes, prep time, and cook time in single session
- [X] Verify: All fields updated in UI
- [X] Verify: All fields updated in database
- [X] Verify: Other fields (cookedAt, wasSuccessful) unchanged
- [X] Cleanup: Delete test data

#### 3.2 Notes Field Edit Test
- [X] Create test: `'Edit notes field with various content types'`
- [X] Test cases: empty → filled, filled → empty, filled → different, special characters
- [X] Verify: Notes display correctly in UI after each change
- [X] Cleanup: Delete test data
- [X] Note: Implemented as 4 separate independent tests for better isolation

#### 3.3 Time Fields Edit Test
- [X] Create test: `'Edit prep and cook times and verify time display updates'`
- [X] Test cases: null → value, value → null, value → different value
- [X] Verify: Time display format correct (e.g., "15 min prep, 30 min cook")
- [X] Cleanup: Delete test data
- [X] Note: Implemented as 3 separate independent tests for better isolation

#### 3.4 Data Consistency Test
- [X] Create test: `'Verify meal position in history maintained after edit'`
- [X] Setup: Create multiple meals at different dates
- [X] Act: Edit middle meal in list
- [X] Verify: Meal order unchanged (sorted by cookedAt)
- [X] Verify: modifiedAt timestamp updated
- [X] Cleanup: Delete test data

---

## Phase 4: Edge Cases & Validation

**Goal:** Test edge cases, validation errors, and cancellation workflows.

### Tasks

#### 4.1 Validation Error Tests
- [X] Create test: `'Workflow handles validation errors without data corruption'`
- [X] Test case: Enter invalid servings (0, negative, non-numeric)
- [X] Verify: Inline error appears
- [X] Verify: Dialog remains open
- [X] Verify: Database unchanged
- [X] Act: Fix error → Save successfully
- [X] Cleanup: Delete test data

#### 4.2 Empty Required Field Test
- [X] Create test: `'Workflow prevents saving with empty required fields'`
- [X] Act: Clear servings field → Try to save
- [X] Verify: Validation error shown
- [X] Verify: Dialog stays open
- [X] Cleanup: Delete test data

#### 4.3 Cancellation Workflow Test
- [X] Create test: `'Cancellation discards all changes and returns to original state'`
- [X] Setup: Create meal with known values
- [X] Act: Open edit → Modify multiple fields → Cancel
- [X] Verify: UI shows original values
- [X] Verify: Database unchanged
- [X] Cleanup: Delete test data

#### 4.4 Cancel After Partial Edit Test
- [X] Create test: `'Cancel after editing some fields discards all changes'`
- [X] Setup: Create meal
- [X] Act: Edit servings → Edit notes → Cancel
- [X] Verify: Both fields show original values
- [X] Cleanup: Delete test data

---

## Phase 5: Error Handling & Recovery

**Goal:** Test database error scenarios and recovery workflows.

### Tasks

#### 5.1 Database Update Failure Test
- [X] Create test: `'Workflow handles database update failure gracefully'`
- [X] Note: This should be a **service integration test** using MockDatabaseHelper
- [X] Setup: Create meal, configure mock to fail on updateMeal
- [X] Act: Edit meal → Save (simulated at service level)
- [X] Verify: Exception thrown with appropriate error message
- [X] Verify: Error message indicates database failure
- [X] Verify: Original data preserved (database not corrupted)
- [X] Verify: Error simulation resets after single use

#### 5.2 Concurrent Modification Test
- [X] Create test: `'Workflow handles meal deleted during edit'`
- [X] Note: This should be a **service integration test** using MockDatabaseHelper
- [X] Setup: Create meal
- [X] Act: Delete meal from database → Attempt to update (simulates concurrent modification)
- [X] Verify: Exception thrown with "Meal not found" message
- [X] Verify: No phantom data created
- [X] Verify: Database remains functional after error

#### 5.3 Recipe Loading Failure Test
- [X] Create test: `'Workflow handles recipe loading failure in edit dialog'`
- [X] Note: This should be a **service integration test**
- [X] Setup: Create test recipes, configure mock to fail on getAllRecipes
- [X] Act: Attempt to load recipes (simulates opening edit dialog)
- [X] Verify: Exception thrown with appropriate error message
- [X] Verify: Error simulation resets after single use
- [X] Verify: All recipes remain accessible after error
- [X] Verify: Database remains fully functional

---

## Phase 6: Accessibility & Performance

**Goal:** Verify accessibility and ensure acceptable performance.

### Tasks

#### 6.1 Keyboard Navigation Test - **DEFERRED**
- [ ] **DEFERRED to Issue #239** - Complex focus management testing
- [ ] Create test: `'Complete workflow accessible via keyboard navigation'`
- [ ] Act: Tab through edit dialog fields
- [ ] Verify: All fields focusable
- [ ] Verify: Save button accessible via keyboard
- [ ] Note: May need `FocusScope` testing utilities

#### 6.2 Screen Reader Semantics Test
- [X] Create test: `'Edit dialog has proper semantic labels'`
- [X] Verify: Edit button has tooltip ("Edit meal")
- [X] Verify: Form fields have semantic labels (Portuguese locale)
- [X] Verify: Error messages displayed and accessible

#### 6.3 Performance Baseline Test
- [X] Create test: `'Complete edit workflow completes within acceptable time'`
- [X] Measure: Time from edit button tap to save complete
- [X] Baseline: Should complete within 12 seconds (adjusted based on actual device performance: 10.54s)
- [X] Log: Detailed performance breakdown (dialog open, field edit, save & update)

#### 6.4 Large Data Performance Test - **DEFERRED**
- [ ] **DEFERRED to Issue #240** - Tedious setup, lower priority
- [ ] Create test: `'Edit workflow performs well with many meals in history'`
- [ ] Setup: Create 50+ meals for a recipe
- [ ] Act: Edit one meal
- [ ] Verify: UI remains responsive
- [ ] Verify: Workflow completes in acceptable time

---

## Phase 7: Complex Scenarios & Integration

**Goal:** Test complex real-world scenarios.

### Tasks

#### 7.1 Meal Plan Origin Preservation Test - **INVALID**
- [ ] **INVALID** - Feature was designed but never implemented
- [ ] UI code checked for "From planned meal" in MealRecipe.notes to display Icons.event_available
- [ ] However, production code never sets this note when cooking from weekly plan
- [ ] Tests manually set this note but no real workflow creates it
- [ ] **Resolution:** Removed non-functional UI code and tests (2025-12-17)

#### 7.2 Success Flag Edit Test
- [X] Create test: `'Edit wasSuccessful flag and verify UI indicator updates'`
- [X] Setup: Create successful meal
- [X] Act: Change wasSuccessful to false via Switch widget
- [X] Verify: UI indicator changes from Icons.check_circle (green) to Icons.warning (orange)
- [X] Verify: Database updated correctly
- [X] Bonus: Test toggling back to successful state
- [X] Cleanup: Delete test data
- [X] Test file: `integration_test/e2e_meal_editing_integration_test.dart`

#### 7.3 Date Edit Test - **DEFERRED**
- [ ] **DEFERRED to Issue #241** - Date picker interaction complexity
- [ ] Create test: `'Edit meal date and verify history reorders correctly'`
- [ ] Note: Date editing IS supported via date picker in edit dialog
- [ ] Setup: Create multiple meals at different dates (day 1, day 3, day 5)
- [ ] Act: Open edit for day 3 meal → Change date to day 0 (oldest)
- [ ] Verify: History list reorders (edited meal now at bottom)
- [ ] Verify: Database `cookedAt` field updated correctly
- [ ] Cleanup: Delete test data

#### 7.4 Date Picker Navigation Test - **DEFERRED**
- [ ] **DEFERRED to Issue #241** - Date picker validation complexity
- [ ] Create test: `'Date picker allows selecting valid dates only'`
- [ ] Verify: Date picker opens when tapping date ListTile
- [ ] Verify: Cannot select future dates (lastDate: DateTime.now())
- [ ] Verify: Can select past dates within valid range
- [ ] Cleanup: Delete test data

#### 7.5 Rapid Sequential Edits Test
- [X] Create test: `'Multiple rapid edits maintain data integrity'`
- [X] Act: Perform 5 sequential edits (servings, notes, prep time, success flag, cook time)
- [X] Verify: Each edit persisted correctly after every save
- [X] Verify: Previous edits remain intact after subsequent edits
- [X] Verify: UI correctly reflects all accumulated changes
- [X] Verify: No race conditions or data loss (no duplicate meals created)
- [X] Verify: modifiedAt timestamp updated
- [X] Test file: `integration_test/e2e_meal_editing_integration_test.dart`

---

## Implementation Decision (2025-12-16)

**Strategy: Option A - Focus on Value**

After completing Phases 1-4 (70% acceptance criteria coverage), we've decided to:

**COMPLETE:**
- ✓ Phase 5: Error Handling & Recovery (all tests - important for robustness)
- ✓ Phase 6: Tests 6.2 and 6.3 (screen reader semantics, performance baseline)
- Phase 7: Tests 7.2, 7.5 (success flag, rapid edits) - **7.1 marked as INVALID**

**DEFER to separate issues:**
- Phase 6.1: Keyboard Navigation → Issue #239
- Phase 6.4: Large Data Performance → Issue #240
- Phase 7.3 & 7.4: Date Picker Tests → Issue #241

**Rationale:** We have strong test coverage for the core workflow. The deferred tests are either:
1. Complex with lower immediate value (keyboard nav, date pickers)
2. Optimization tests that can wait for actual performance issues (large data)

---

## Test File Organization

```
integration_test/
├── e2e_meal_editing_workflow_test.dart      # Phase 1-4, 6-7 E2E tests
└── helpers/
    └── e2e_test_helpers.dart                # Meal editing E2E helpers

test/
└── services/
    └── meal_editing_error_scenarios_test.dart  # Phase 5 service integration tests
```

**Note:** Phase 5 tests are in `test/services/` (not `integration_test/`) because they use MockDatabaseHelper and don't require UI/windowing system. This allows them to run in CI and in WSL environments.

---

## Success Criteria

### Phase Completion Checklist
- [X] **Phase 1:** Basic workflow test passing
- [X] **Phase 2:** Multi-recipe meal tests passing
- [X] **Phase 3:** Field combination tests passing
- [X] **Phase 4:** Edge case and validation tests passing
- [X] **Phase 5:** Error handling tests passing (all 3 tests complete)
- [ ] **Phase 6:** Accessibility and performance tests passing (6.2, 6.3 in scope; 6.1, 6.4 deferred)
- [ ] **Phase 7:** Complex scenario tests passing (7.1, 7.2, 7.5 in scope; 7.3, 7.4 deferred)

### Final Acceptance Criteria (from Issue #126)
- [ ] Integration test for complete workflow: meal history → edit button → dialog → save → updated display
- [ ] Test the workflow with different meal types (single-recipe vs multi-recipe meals)
- [ ] Verify workflow handles edge cases (empty fields, invalid data, cancellation)
- [ ] Add test for editing meal with side dishes (recipe management within edit dialog)
- [ ] Test workflow with various field combinations being edited simultaneously
- [ ] Verify workflow maintains data consistency throughout the entire process
- [ ] Add test for workflow cancellation (no changes saved, UI returns to original state)
- [ ] Test workflow with database errors and recovery scenarios
- [ ] Verify accessibility and keyboard navigation through the complete workflow
- [ ] Add performance test to ensure workflow completes within reasonable time

---

## Notes

### Running E2E Tests
E2E tests require a windowing system and must be run manually:
```bash
# On Windows (not WSL)
flutter test integration_test/e2e_meal_editing_workflow_test.dart
```

### Running Service Integration Tests
Service integration tests can run in CI:
```bash
flutter test integration_test/services/meal_editing_error_scenarios_test.dart
```

### Test Data Management
- Always use unique identifiers with timestamps: `'test-meal-${DateTime.now().millisecondsSinceEpoch}'`
- Always clean up in `finally` blocks
- Use existing `MockDatabaseHelper` for service integration tests
- Use real `DatabaseHelper` for E2E tests

---

**Last Updated:** 2025-12-12
**Status:** Planning Complete - Ready for Implementation