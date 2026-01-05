# Issue #247: Improve Test Coverage for AddIngredientDialog (75.6% → 90%)

**Issue:** [#247](https://github.com/alemdisso/gastrobrain/issues/247)
**Type:** Testing
**Priority:** P2 - Medium
**Estimate:** S = 2 points (~3-5 hours)
**Status:** Planning

---

## Overview

Improve test coverage for `AddIngredientDialog` from 75.6% to >90%.

**Current State:**
- **Coverage:** 75.6% (220/291 lines)
- **Target:** >90%
- **Gap:** ~44 lines need coverage
- **Existing tests:** 19 tests in `add_ingredient_dialog_test.dart` (735 lines)

**Widget:** `lib/widgets/add_ingredient_dialog.dart` (618 lines)

---

## Prerequisites

- **#230 must be completed first** - Need coverage tooling to identify exact gaps
- Familiarity with `DialogTestHelpers` patterns
- Understanding of `MockDatabaseHelper` for error simulation

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
- [ ] Open `coverage/html/lib/widgets/add_ingredient_dialog.dart.html`
- [ ] Document all uncovered lines (red highlighted)
- [ ] Categorize uncovered code:
  - Error handling paths
  - Edge cases (empty states, boundary conditions)
  - Alternative code branches (conditional rendering)
  - State transitions

**Output:** List of uncovered lines with categorization

**Estimated time:** 30-45 minutes

---

### Phase 2: Identify Test Scenarios

**Objective:** Plan tests for uncovered code

**Likely uncovered scenarios based on common patterns:**

#### Error Handling
- [ ] Database error when loading ingredients
- [ ] Error during ingredient creation/update
- [ ] Network/timeout errors (if applicable)

#### Edge Cases
- [ ] Empty ingredient list from database
- [ ] Very long ingredient names (boundary)
- [ ] Special characters in names
- [ ] Invalid characters handling

#### State Transitions
- [ ] Switching between database/custom ingredient modes
- [ ] Cancellation during various states
- [ ] Multiple rapid interactions

#### Alternative Code Paths
- [ ] Optional parameters handling
- [ ] Conditional rendering branches
- [ ] Different dialog initialization states

**Tasks:**
- [ ] Review uncovered lines from Phase 1
- [ ] Map each uncovered section to a test scenario
- [ ] Prioritize by value (error handling > edge cases > minor branches)
- [ ] Mark any lines as "impractical to test" if appropriate

**Output:** Prioritized list of test scenarios to implement

**Estimated time:** 30-45 minutes

---

### Phase 3: Implement High-Priority Tests

**Objective:** Add tests for error handling and critical paths

**Test patterns to follow** (from DIALOG_TESTING_GUIDE.md):

```dart
// Error handling test template
testWidgets('handles database error gracefully', (WidgetTester tester) async {
  final mockDbHelper = TestSetup.setupMockDatabase();

  // Configure mock to fail
  mockDbHelper.failOnOperation('getAllIngredients');

  await DialogTestHelpers.openDialog(
    tester,
    dialogBuilder: (context) => AddIngredientDialog(
      databaseHelper: mockDbHelper,
    ),
  );

  await tester.pumpAndSettle();

  // Verify error handling
  expect(find.text('Error loading ingredients'), findsOneWidget);
  // OR verify snackbar, dialog remains open, etc.
});
```

**Tasks:**
- [ ] Implement error handling tests
- [ ] Run tests to verify they pass
- [ ] Check coverage improvement after each test

**Estimated time:** 1-1.5 hours

---

### Phase 4: Implement Edge Case Tests

**Objective:** Cover boundary conditions and unusual states

**Test patterns:**

```dart
// Empty state test
testWidgets('handles empty ingredient list', (WidgetTester tester) async {
  final mockDbHelper = TestSetup.setupMockDatabase();
  mockDbHelper.setIngredients([]); // Empty list

  await DialogTestHelpers.openDialog(
    tester,
    dialogBuilder: (context) => AddIngredientDialog(
      databaseHelper: mockDbHelper,
    ),
  );

  await tester.pumpAndSettle();

  // Verify empty state handling
  expect(find.text('No ingredients found'), findsOneWidget);
});

// Boundary value test
testWidgets('accepts maximum length ingredient name', (WidgetTester tester) async {
  final longName = 'A' * 100; // Test boundary

  // ... test implementation
});
```

**Tasks:**
- [ ] Implement empty state tests
- [ ] Implement boundary value tests
- [ ] Implement special character handling tests
- [ ] Run tests and verify coverage improvement

**Estimated time:** 1 hour

---

### Phase 5: Implement State Transition Tests

**Objective:** Cover mode switches and complex state changes

**Tasks:**
- [ ] Test mode switching (database ↔ custom ingredient)
- [ ] Test cancellation from various states
- [ ] Test rapid interactions if applicable
- [ ] Run tests and verify coverage

**Estimated time:** 30-45 minutes

---

### Phase 6: Coverage Verification

**Objective:** Confirm >90% coverage achieved

**Tasks:**
- [ ] Generate final coverage report
- [ ] Verify AddIngredientDialog coverage >90%
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

- [ ] Coverage increased from 75.6% to >90%
- [ ] Error handling paths tested
- [ ] Edge cases documented and tested
- [ ] All new tests follow established patterns
- [ ] Test file remains well-organized
- [ ] No flaky tests introduced

---

## Test Organization

Add new tests to `test/widgets/add_ingredient_dialog_test.dart` in appropriate groups:

```dart
void main() {
  // Existing test groups...

  group('Error Handling', () {
    // New error handling tests
  });

  group('Edge Cases', () {
    // New edge case tests
  });

  group('State Transitions', () {
    // New state transition tests
  });
}
```

---

## Risk Assessment

**Low Risk:**
- Adding tests only, no widget changes
- Following established patterns
- Mock infrastructure already exists

**Potential Issues:**
- Some code paths may be genuinely impractical to test
- Coverage tool might have quirks with certain constructs

**Mitigations:**
- Document any intentionally uncovered lines
- Use pragmatic approach - aim for ~90%, not 100%
- Consult DIALOG_TESTING_GUIDE.md for edge cases

---

## Success Criteria

- [ ] `AddIngredientDialog` coverage >90%
- [ ] All error paths have dedicated tests
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

- Focus on practical coverage - don't test impractical/unnecessary lines
- Error simulation now available via #244 (completed in 0.1.4)
- Use `MockDatabaseHelper.failOnOperation()` for error tests
