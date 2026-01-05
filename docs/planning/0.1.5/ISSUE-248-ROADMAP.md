# Issue #248: Improve Test Coverage for EditMealRecordingDialog (75.5% → 90%)

**Issue:** [#248](https://github.com/alemdisso/gastrobrain/issues/248)
**Type:** Testing
**Priority:** P2 - Medium
**Estimate:** S = 2 points (~3-5 hours)
**Status:** Planning

---

## Overview

Improve test coverage for `EditMealRecordingDialog` from 75.5% to >90%.

**Current State:**
- **Coverage:** 75.5% (145/192 lines)
- **Target:** >90%
- **Gap:** ~28 lines need coverage
- **Existing tests:** 26 tests in `edit_meal_recording_dialog_test.dart` (1034 lines)

**Widget:** `lib/widgets/edit_meal_recording_dialog.dart` (428 lines)

---

## Prerequisites

- **#230 must be completed first** - Need coverage tooling to identify exact gaps
- Familiarity with `DialogTestHelpers` patterns
- Understanding of `MockDatabaseHelper` for error simulation
- Note: DI support improved via #237 (completed in 0.1.4)

## Dependencies

- **Blocked by:** #230 (coverage reporting)
- **Related to:** #38 (dialog testing - Phase 4.3.2)

---

## Implementation Phases

### Phase 1: Coverage Analysis

**Objective:** Identify exactly which lines/branches are uncovered

**Tasks:**
- [ ] Generate coverage report: `flutter test --coverage`
- [ ] Generate HTML report: `genhtml coverage/lcov.info -o coverage/html`
- [ ] Open `coverage/html/lib/widgets/edit_meal_recording_dialog.dart.html`
- [ ] Document all uncovered lines (red highlighted)
- [ ] Categorize uncovered code:
  - Error handling paths (database update failures)
  - Edge cases (editing meals with no side dishes, removing all recipes)
  - Alternative code branches (optional fields like prep/cook time)
  - Complex state transitions (adding/removing side dishes during edit)
  - Validation edge cases (invalid time formats, negative servings)

**Output:** List of uncovered lines with categorization

**Estimated time:** 30-45 minutes

---

### Phase 2: Identify Test Scenarios

**Objective:** Plan tests for uncovered code

**Likely uncovered scenarios based on issue description:**

#### Error Handling
- [ ] Database update failure during save
- [ ] Error loading meal data
- [ ] Error updating meal recipes

#### Edge Cases
- [ ] Editing meal with no side dishes
- [ ] Removing all recipes from meal
- [ ] Editing meal with maximum side dishes
- [ ] Empty notes field handling
- [ ] Very long notes text

#### State Transitions
- [ ] Adding side dishes during edit
- [ ] Removing side dishes during edit
- [ ] Changing primary dish
- [ ] Multiple rapid state changes

#### Validation
- [ ] Invalid time format inputs
- [ ] Negative servings values
- [ ] Zero servings handling
- [ ] Optional field validation (prep/cook time)

**Tasks:**
- [ ] Review uncovered lines from Phase 1
- [ ] Map each uncovered section to a test scenario
- [ ] Prioritize by value (error handling > edge cases > validation)
- [ ] Mark any lines as "impractical to test" if appropriate

**Output:** Prioritized list of test scenarios to implement

**Estimated time:** 30-45 minutes

---

### Phase 3: Implement Error Handling Tests

**Objective:** Cover database error scenarios

**Test patterns:**

```dart
testWidgets('handles database update failure', (WidgetTester tester) async {
  final mockDbHelper = TestSetup.setupMockDatabase();
  final testMeal = TestFixtures.createMeal();

  // Configure mock to fail on update
  mockDbHelper.failOnOperation('updateMeal');

  await DialogTestHelpers.openDialog(
    tester,
    dialogBuilder: (context) => EditMealRecordingDialog(
      meal: testMeal,
      databaseHelper: mockDbHelper,
    ),
  );

  // Make a change and try to save
  await DialogTestHelpers.fillDialogForm(tester, {'Notes': 'Updated notes'});
  await DialogTestHelpers.tapDialogButton(tester, 'Save');
  await tester.pumpAndSettle();

  // Verify error handling
  expect(find.text('Failed to update meal'), findsOneWidget);
  // Dialog should remain open
  expect(find.byType(EditMealRecordingDialog), findsOneWidget);
});
```

**Tasks:**
- [ ] Test database update failure
- [ ] Test error loading related data
- [ ] Verify error messages display correctly
- [ ] Verify dialog recovery behavior

**Estimated time:** 1 hour

---

### Phase 4: Implement Edge Case Tests

**Objective:** Cover boundary conditions and unusual states

**Test scenarios:**

```dart
// Editing meal with no side dishes
testWidgets('handles meal with no side dishes', (WidgetTester tester) async {
  final mockDbHelper = TestSetup.setupMockDatabase();
  final mealWithNoSides = TestFixtures.createMeal(sideCount: 0);

  await DialogTestHelpers.openDialog(
    tester,
    dialogBuilder: (context) => EditMealRecordingDialog(
      meal: mealWithNoSides,
      databaseHelper: mockDbHelper,
    ),
  );

  await tester.pumpAndSettle();

  // Verify empty side dishes state
  expect(find.text('No side dishes'), findsOneWidget);
  // Verify add button is available
  expect(find.byIcon(Icons.add), findsOneWidget);
});

// Removing all recipes
testWidgets('prevents removing last recipe', (WidgetTester tester) async {
  // ... implementation
});
```

**Tasks:**
- [ ] Test meal with no side dishes
- [ ] Test removing all recipes (should prevent or warn)
- [ ] Test empty notes handling
- [ ] Test very long notes text

**Estimated time:** 45 minutes

---

### Phase 5: Implement State Transition Tests

**Objective:** Cover complex edit workflows

**Test scenarios:**

```dart
// Adding side dish during edit
testWidgets('can add side dish during edit', (WidgetTester tester) async {
  // Start with meal having 1 side dish
  // Open edit dialog
  // Add another side dish
  // Save and verify
});

// Changing primary dish
testWidgets('can change primary dish', (WidgetTester tester) async {
  // Start with meal having main + side
  // Open edit dialog
  // Change which is primary
  // Save and verify
});
```

**Tasks:**
- [ ] Test adding side dishes during edit
- [ ] Test removing side dishes during edit
- [ ] Test changing primary dish designation
- [ ] Test rapid state changes don't cause issues

**Estimated time:** 45 minutes

---

### Phase 6: Implement Validation Tests

**Objective:** Cover input validation edge cases

**Tasks:**
- [ ] Test invalid time format handling
- [ ] Test negative servings rejection
- [ ] Test zero servings handling
- [ ] Test optional field validation

**Estimated time:** 30 minutes

---

### Phase 7: Coverage Verification

**Objective:** Confirm >90% coverage achieved

**Tasks:**
- [ ] Generate final coverage report
- [ ] Verify EditMealRecordingDialog coverage >90%
- [ ] Document any remaining uncovered lines and justification
- [ ] Run full test suite: `flutter test`
- [ ] Run analysis: `flutter analyze`

**Acceptance criteria check:**
- [ ] Coverage >90%
- [ ] All tests pass
- [ ] No analysis issues
- [ ] Tests follow DIALOG_TESTING_GUIDE.md patterns

**Estimated time:** 15-30 minutes

---

## Deliverables Checklist

- [ ] Coverage increased from 75.5% to >90%
- [ ] Error handling paths tested
- [ ] Edge cases documented and tested
- [ ] State transition scenarios tested
- [ ] All new tests follow established patterns
- [ ] No flaky tests introduced

---

## Test Organization

Add new tests to `test/widgets/edit_meal_recording_dialog_test.dart`:

```dart
void main() {
  // Existing test groups...

  group('Error Handling', () {
    testWidgets('handles database update failure', ...);
  });

  group('Edge Cases', () {
    testWidgets('handles meal with no side dishes', ...);
    testWidgets('handles very long notes', ...);
  });

  group('State Transitions', () {
    testWidgets('can add side dish during edit', ...);
    testWidgets('can remove side dish during edit', ...);
  });

  group('Validation', () {
    testWidgets('rejects negative servings', ...);
  });
}
```

---

## Risk Assessment

**Low Risk:**
- Adding tests only, no widget changes
- Following established patterns
- Good existing test foundation (26 tests)

**Potential Issues:**
- Complex state management may require careful test setup
- Some edit scenarios may need specific meal fixtures

**Mitigations:**
- Use TestFixtures for consistent test data
- Leverage existing test patterns from file
- Document any intentionally uncovered lines

---

## Success Criteria

- [ ] `EditMealRecordingDialog` coverage >90%
- [ ] All error paths have dedicated tests
- [ ] All state transition scenarios tested
- [ ] Tests follow patterns in DIALOG_TESTING_GUIDE.md
- [ ] No regressions in existing tests

---

## Reference Documentation

- [docs/testing/DIALOG_TESTING_GUIDE.md](../../testing/DIALOG_TESTING_GUIDE.md)
- [docs/testing/MOCK_DATABASE_ERROR_SIMULATION.md](../../testing/MOCK_DATABASE_ERROR_SIMULATION.md)
- [docs/testing/EDGE_CASE_TESTING_GUIDE.md](../../testing/EDGE_CASE_TESTING_GUIDE.md)

---

## Notes

- This dialog edits existing meals, so tests need meal fixtures
- DI support improved in 0.1.4 (#237) - error testing now easier
- Focus on edit-specific scenarios (not creation)
- State management is key focus area
