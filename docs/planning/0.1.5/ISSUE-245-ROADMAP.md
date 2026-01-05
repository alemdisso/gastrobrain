# Issue #245: Implement Deferred Phase 3 Error Handling Tests

**Issue:** [#245](https://github.com/alemdisso/gastrobrain/issues/245)
**Type:** Testing
**Priority:** P3 - Low
**Estimate:** S = 1 point (~1-1.5 hours)
**Status:** Planning

---

## Overview

Implement 2 specific error handling tests that were deferred during Issue #38 due to architectural limitations. These blockers are now resolved.

**Scope:** Very small and focused - only 2 tests to implement.

**Deferred Tests:**
1. `AddIngredientDialog` - loading ingredients error test
2. `MealRecordingDialog` - loading recipes error test

---

## Prerequisites

- **#244 completed (0.1.4):** MockDatabaseHelper now has `getAllIngredients()` error simulation
- **#237 completed (0.1.4):** Meal editing service consolidation improves DI support
- Familiarity with `MockDatabaseHelper.failOnOperation()` pattern

## Dependencies

- **Was blocked by:** #244 (CLOSED), #237 (CLOSED)
- **Related to:** #38 (dialog testing)
- **Recommended after:** #247, #248, #249 (coverage work)

---

## Implementation Phases

### Phase 1: Implement AddIngredientDialog Error Test

**Objective:** Test error handling when loading ingredients fails

**Test location:** `test/widgets/add_ingredient_dialog_test.dart`

**Test implementation:**

```dart
group('Error Handling', () {
  testWidgets('shows error when loading ingredients fails', (WidgetTester tester) async {
    final mockDbHelper = TestSetup.setupMockDatabase();

    // Configure mock to fail on getAllIngredients
    mockDbHelper.failOnOperation('getAllIngredients');

    await DialogTestHelpers.openDialog(
      tester,
      dialogBuilder: (context) => AddIngredientDialog(
        databaseHelper: mockDbHelper,
      ),
    );

    await tester.pumpAndSettle();

    // Verify error handling
    // Expected behavior:
    // - Error snackbar/message shown
    // - Dialog remains open
    // - Loading state reset
    expect(find.textContaining('error'), findsOneWidget);
    // OR check for specific error UI
  });
});
```

**Tasks:**
- [ ] Open `add_ingredient_dialog_test.dart`
- [ ] Add test to appropriate group (or create 'Error Handling' group)
- [ ] Configure mock to fail with `failOnOperation('getAllIngredients')`
- [ ] Verify error UI displays correctly
- [ ] Verify dialog remains open and recoverable
- [ ] Run test to ensure it passes

**Expected behavior to verify:**
- Error snackbar/message displayed
- Dialog remains open
- Loading state properly reset
- User can retry or dismiss

**Estimated time:** 30-45 minutes

---

### Phase 2: Implement MealRecordingDialog Error Test

**Objective:** Test error handling when loading recipes fails

**Test location:** `test/widgets/meal_recording_dialog_test.dart`

**Test implementation:**

```dart
group('Error Handling', () {
  testWidgets('shows error when loading recipes fails', (WidgetTester tester) async {
    final mockDbHelper = TestSetup.setupMockDatabase();

    // Configure mock to fail on getAllRecipes
    mockDbHelper.failOnOperation('getAllRecipes');

    await DialogTestHelpers.openDialog(
      tester,
      dialogBuilder: (context) => MealRecordingDialog(
        databaseHelper: mockDbHelper,
      ),
    );

    await tester.pumpAndSettle();

    // Verify error handling
    // Expected behavior:
    // - Error snackbar/message shown
    // - Dialog remains open
    // - "Add Recipe" button still functional (or shows retry)
    expect(find.textContaining('error'), findsOneWidget);
  });
});
```

**Tasks:**
- [ ] Open `meal_recording_dialog_test.dart`
- [ ] Add test to appropriate group (or create 'Error Handling' group)
- [ ] Configure mock to fail with `failOnOperation('getAllRecipes')`
- [ ] Verify error UI displays correctly
- [ ] Verify dialog remains functional
- [ ] Run test to ensure it passes

**Expected behavior to verify:**
- Error snackbar/message displayed
- Dialog remains open
- "Add Recipe" button still accessible (or retry available)

**Estimated time:** 30-45 minutes

---

### Phase 3: Verification

**Objective:** Confirm tests work correctly

**Tasks:**
- [ ] Run both new tests individually
- [ ] Run full test suite: `flutter test`
- [ ] Run analysis: `flutter analyze`
- [ ] Verify no flaky behavior (run tests 3x)

**Verification checklist:**
- [ ] AddIngredientDialog error test passes
- [ ] MealRecordingDialog error test passes
- [ ] No existing tests broken
- [ ] No analysis issues

**Estimated time:** 15 minutes

---

## Deliverables Checklist

- [ ] AddIngredientDialog error test implemented
- [ ] MealRecordingDialog error test implemented
- [ ] Both tests pass consistently
- [ ] Tests follow DIALOG_TESTING_GUIDE.md patterns
- [ ] No regressions in existing tests

---

## Test Template Reference

From the issue description, use this template:

```dart
testWidgets('shows error when loading X fails', (WidgetTester tester) async {
  final mockDbHelper = TestSetup.setupMockDatabase();

  // Configure mock to fail
  mockDbHelper.failOnOperation('getX');

  await DialogTestHelpers.openDialog(
    tester,
    dialogBuilder: (context) => MyDialog(databaseHelper: mockDbHelper),
  );

  await tester.pumpAndSettle();

  // Verify error handling
  expect(find.textContaining('error'), findsOneWidget);
  // Dialog remains open
  expect(find.byType(MyDialog), findsOneWidget);
});
```

---

## Risk Assessment

**Very Low Risk:**
- Only 2 small tests
- Using established patterns
- Infrastructure already verified working (#244)
- Clear test template provided

**Potential Issues:**
- Exact error message text may differ from expectation
- Dialog error handling implementation may vary

**Mitigations:**
- Use flexible matchers (`textContaining` vs exact match)
- Review actual dialog code if test fails
- Adjust assertions to match actual behavior

---

## Success Criteria

- [ ] 2 deferred error tests implemented
- [ ] Both tests pass consistently
- [ ] Tests verify meaningful error handling behavior
- [ ] No side effects on existing tests

---

## Reference Documentation

- [docs/testing/MOCK_DATABASE_ERROR_SIMULATION.md](../../testing/MOCK_DATABASE_ERROR_SIMULATION.md)
- [docs/testing/DIALOG_TESTING_GUIDE.md](../../testing/DIALOG_TESTING_GUIDE.md)

---

## Notes

- This is a cleanup task - small scope, clear deliverables
- Was blocked for months, now unblocked by 0.1.4 work
- Completes Phase 3 error handling from #38
- Consider doing after #247/#249 since those files will be modified anyway
