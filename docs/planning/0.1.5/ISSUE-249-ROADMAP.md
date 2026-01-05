# Issue #249: Improve Test Coverage for MealRecordingDialog (75.5% → 90%)

**Issue:** [#249](https://github.com/alemdisso/gastrobrain/issues/249)
**Type:** Testing
**Priority:** P2 - Medium
**Estimate:** S = 2 points (~3-5 hours)
**Status:** Planning

---

## Overview

Improve test coverage for `MealRecordingDialog` from 75.5% to >90%.

**Current State:**
- **Coverage:** 75.5% (157/208 lines)
- **Target:** >90%
- **Gap:** ~30 lines need coverage
- **Existing tests:** 24 tests in `meal_recording_dialog_test.dart` (891 lines)

**Widget:** `lib/widgets/meal_recording_dialog.dart` (470 lines)

**Important Note:** This is the PRIMARY dialog for meal planning - high coverage is critical.

---

## Prerequisites

- **#230 must be completed first** - Need coverage tooling to identify exact gaps
- Familiarity with `DialogTestHelpers` patterns
- Understanding of multi-recipe meal system

## Dependencies

- **Blocked by:** #230 (coverage reporting)
- **Related to:** #38 (dialog testing - Phase 4.3.2)
- **Note:** DI limitations acknowledged - error testing may be constrained

---

## Implementation Phases

### Phase 1: Coverage Analysis

**Objective:** Identify exactly which lines/branches are uncovered

**Tasks:**
- [ ] Generate coverage report: `flutter test --coverage`
- [ ] Generate HTML report: `genhtml coverage/lcov.info -o coverage/html`
- [ ] Open `coverage/html/lib/widgets/meal_recording_dialog.dart.html`
- [ ] Document all uncovered lines (red highlighted)
- [ ] Categorize uncovered code:
  - Complex multi-recipe meal scenarios (3+ recipes)
  - Edge cases (very long notes, extreme servings values)
  - Date selection edge cases (past dates, far future dates)
  - Alternative code branches (optional prep/cook times)
  - Complex state management (adding/removing multiple side dishes)

**Output:** List of uncovered lines with categorization

**Estimated time:** 30-45 minutes

---

### Phase 2: Identify Test Scenarios

**Objective:** Plan tests for uncovered code

**Likely uncovered scenarios based on issue description:**

#### Multi-Recipe Scenarios
- [ ] Meal with 3+ recipes
- [ ] Meal with multiple side dishes
- [ ] Changing primary dish among multiple options
- [ ] Reordering recipes

#### Edge Cases - Input Values
- [ ] Very long notes text (boundary)
- [ ] Maximum servings value
- [ ] Minimum servings value (1)
- [ ] Empty notes (valid)
- [ ] Special characters in notes

#### Date Selection
- [ ] Selecting past dates
- [ ] Selecting far future dates
- [ ] Date at month boundaries
- [ ] Leap year edge cases (if applicable)

#### Optional Fields
- [ ] With prep time / without prep time
- [ ] With cook time / without cook time
- [ ] Various combinations of optional fields

#### State Management
- [ ] Adding multiple side dishes in sequence
- [ ] Removing side dishes then adding new ones
- [ ] Rapid add/remove operations

**Tasks:**
- [ ] Review uncovered lines from Phase 1
- [ ] Map each uncovered section to a test scenario
- [ ] Prioritize by value (multi-recipe > edge cases > optional fields)
- [ ] Mark any lines as "impractical to test" if appropriate

**Output:** Prioritized list of test scenarios to implement

**Estimated time:** 30-45 minutes

---

### Phase 3: Implement Multi-Recipe Tests

**Objective:** Cover complex meal composition scenarios

**Test patterns:**

```dart
testWidgets('handles meal with 3+ recipes', (WidgetTester tester) async {
  final mockDbHelper = TestSetup.setupMockDatabase();

  await DialogTestHelpers.openDialog(
    tester,
    dialogBuilder: (context) => MealRecordingDialog(
      databaseHelper: mockDbHelper,
    ),
  );

  // Select primary recipe
  await tester.tap(find.text('Select Recipe'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Main Dish'));
  await tester.pumpAndSettle();

  // Add first side dish
  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();
  // Select side dish...

  // Add second side dish
  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();
  // Select another side dish...

  // Add third side dish
  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();
  // Select another side dish...

  // Save and verify
  await DialogTestHelpers.tapDialogButton(tester, 'Save');
  await tester.pumpAndSettle();

  // Verify all recipes recorded
});

testWidgets('can change primary dish among multiple', (WidgetTester tester) async {
  // Setup meal with multiple recipes
  // Change which recipe is primary
  // Verify change persists
});
```

**Tasks:**
- [ ] Test meal with 3+ recipes
- [ ] Test changing primary dish
- [ ] Test side dish management with multiple dishes
- [ ] Verify correct recipe associations

**Estimated time:** 1 hour

---

### Phase 4: Implement Edge Case Tests

**Objective:** Cover boundary conditions

**Test scenarios:**

```dart
// Long notes test
testWidgets('accepts very long notes text', (WidgetTester tester) async {
  final mockDbHelper = TestSetup.setupMockDatabase();
  final longNotes = 'A' * 500; // Test boundary

  await DialogTestHelpers.openDialog(
    tester,
    dialogBuilder: (context) => MealRecordingDialog(
      databaseHelper: mockDbHelper,
    ),
  );

  // Select a recipe first
  await selectTestRecipe(tester);

  // Enter long notes
  await tester.enterText(find.byKey(Key('notesField')), longNotes);
  await DialogTestHelpers.tapDialogButton(tester, 'Save');
  await tester.pumpAndSettle();

  // Verify saves successfully
});

// Servings boundary tests
testWidgets('accepts minimum servings (1)', (WidgetTester tester) async {
  // ...
});

testWidgets('accepts maximum reasonable servings', (WidgetTester tester) async {
  // ...
});
```

**Tasks:**
- [ ] Test very long notes
- [ ] Test minimum servings (1)
- [ ] Test maximum servings
- [ ] Test special characters in notes
- [ ] Test empty notes (valid case)

**Estimated time:** 45 minutes

---

### Phase 5: Implement Date Selection Tests

**Objective:** Cover date picker edge cases

**Test scenarios:**

```dart
testWidgets('allows selecting past dates', (WidgetTester tester) async {
  // Open dialog
  // Select date picker
  // Choose a date in the past
  // Verify date accepted
});

testWidgets('allows selecting future dates', (WidgetTester tester) async {
  // Open dialog
  // Select date picker
  // Choose a date far in future
  // Verify date accepted
});
```

**Tasks:**
- [ ] Test past date selection
- [ ] Test far future date selection
- [ ] Test date at month boundaries
- [ ] Verify date persists after selection

**Estimated time:** 30-45 minutes

---

### Phase 6: Implement Optional Field Tests

**Objective:** Cover optional prep/cook time paths

**Test scenarios:**

```dart
testWidgets('saves meal without prep time', (WidgetTester tester) async {
  // Leave prep time empty
  // Fill other required fields
  // Save and verify
});

testWidgets('saves meal with all optional fields', (WidgetTester tester) async {
  // Fill all optional fields
  // Save and verify all persisted
});
```

**Tasks:**
- [ ] Test with prep time only
- [ ] Test with cook time only
- [ ] Test with neither optional time
- [ ] Test with both optional times

**Estimated time:** 30 minutes

---

### Phase 7: Coverage Verification

**Objective:** Confirm >90% coverage achieved

**Tasks:**
- [ ] Generate final coverage report
- [ ] Verify MealRecordingDialog coverage >90%
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
- [ ] Multi-recipe scenarios tested
- [ ] Edge cases documented and tested
- [ ] Date selection scenarios tested
- [ ] Optional field combinations tested
- [ ] All new tests follow established patterns
- [ ] No flaky tests introduced

---

## Test Organization

Add new tests to `test/widgets/meal_recording_dialog_test.dart`:

```dart
void main() {
  // Existing test groups...

  group('Multi-Recipe Scenarios', () {
    testWidgets('handles meal with 3+ recipes', ...);
    testWidgets('can change primary dish', ...);
  });

  group('Edge Cases', () {
    testWidgets('accepts very long notes', ...);
    testWidgets('handles boundary servings values', ...);
  });

  group('Date Selection', () {
    testWidgets('allows past dates', ...);
    testWidgets('allows future dates', ...);
  });

  group('Optional Fields', () {
    testWidgets('saves without optional times', ...);
    testWidgets('saves with all optional fields', ...);
  });
}
```

---

## Risk Assessment

**Low Risk:**
- Adding tests only, no widget changes
- Following established patterns
- Good existing test foundation (24 tests)

**Medium Risk:**
- Multi-recipe scenarios are complex
- Date picker testing can be platform-dependent

**Constraints:**
- DI limitations may restrict some error testing
- Focus on what's testable within current constraints

**Mitigations:**
- Use TestFixtures for complex meal setups
- Use Flutter's date picker testing utilities
- Document any coverage gaps due to DI limitations

---

## Success Criteria

- [ ] `MealRecordingDialog` coverage >90%
- [ ] Complex multi-recipe scenarios tested
- [ ] All edge cases documented and tested
- [ ] Tests follow patterns in DIALOG_TESTING_GUIDE.md
- [ ] No regressions in existing tests

---

## Reference Documentation

- [docs/testing/DIALOG_TESTING_GUIDE.md](../../testing/DIALOG_TESTING_GUIDE.md)
- [docs/testing/MOCK_DATABASE_ERROR_SIMULATION.md](../../testing/MOCK_DATABASE_ERROR_SIMULATION.md)
- [docs/testing/EDGE_CASE_TESTING_GUIDE.md](../../testing/EDGE_CASE_TESTING_GUIDE.md)

---

## Notes

- This is the PRIMARY meal planning dialog - quality matters
- Multi-recipe support is a key feature, must be well-tested
- Error testing limited by DI constraints (acknowledged in issue)
- Focus on state management and complex scenarios
- #245 will add specific error tests after this
