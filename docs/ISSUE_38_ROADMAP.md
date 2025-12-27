<!-- markdownlint-disable -->
# Issue #38: Dialog and State Management Testing Roadmap

## Executive Summary

This document provides a comprehensive roadmap for implementing dialog and state management testing across the Gastrobrain application. The roadmap is organized into phases with detailed to-do lists to guide implementation.

## Current State Assessment

### What Has Been Done ✓

1. **Existing Dialog Tests (2/6 dialogs)**
   - `test/widgets/add_ingredient_dialog_test.dart` - Basic UI tests
   - `test/widgets/edit_meal_recording_dialog_test.dart` - More comprehensive tests including pre-population, validation, and cancellation

2. **Test Infrastructure in Place**
   - `TestSetup.setupMockDatabase()` - Standardized mock database setup
   - `wrapWithLocalizations()` - Widget wrapper with localization support
   - `SnackbarTestHelpers` - Utilities for snackbar testing
   - `MockDatabaseHelper` - Comprehensive mock for database operations

3. **E2E Integration Tests**
   - Multiple end-to-end tests that exercise dialogs in full workflows
   - Examples: `e2e_meal_editing_workflow_test.dart`, `e2e_meal_recording_workflow_test.dart`

4. **Partial Coverage**
   - Form validation testing (limited to 2 dialogs)
   - Basic cancellation behavior (1 dialog)
   - Pre-population of dialog fields (1 dialog)

### Gaps Identified ✗

Based on the acceptance criteria from issue #38:

| Acceptance Criterion | Status | Coverage |
|---------------------|--------|----------|
| Create test utilities for simulating dialog interactions | ✗ Missing | 0% - No DialogTestHelper exists |
| Implement tests for dialog return value handling in at least 3 workflows | ⚠️ Partial | 33% - Only 2/6 dialogs tested, return values not comprehensively verified |
| Add specific tests for temporary object creation and persistence | ✗ Missing | 0% - No tests for temporary state |
| Test dialog cancellation paths and verify no side effects | ⚠️ Partial | 17% - Only 1 basic cancellation test |
| Verify form validation behaves correctly within dialog contexts | ⚠️ Partial | 33% - 2/6 dialogs have validation tests |
| Test error handling scenarios within dialogs | ✗ Missing | 0% - No systematic error handling tests |
| Create regression tests for identified dialog bugs | ❓ Unknown | Need user input on known bugs |
| Document patterns for testing dialogs and state management | ✗ Missing | 0% - No documentation |

### Dialogs Requiring Test Coverage

1. ✗ **meal_cooked_dialog.dart** - Returns cooking details (Map)
2. ⚠️ **add_ingredient_dialog.dart** - Returns RecipeIngredient (has basic tests, needs expansion)
3. ✗ **add_new_ingredient_dialog.dart** - Returns Ingredient (no tests)
4. ✗ **meal_recording_dialog.dart** - Returns meal data (Map) (no tests)
5. ✗ **add_side_dish_dialog.dart** - Returns recipe selection (Map) (no tests)
6. ⚠️ **edit_meal_recording_dialog.dart** - Returns updated Meal (has tests, needs expansion)

## Roadmap Organization

The roadmap is divided into 4 phases:
- **Phase 1**: Foundation & Utilities (Infrastructure)
- **Phase 2**: Core Dialog Testing (Return values & cancellation)
- **Phase 3**: Advanced Scenarios (Error handling & edge cases)
- **Phase 4**: Documentation & Regression Tests

---

## PHASE 1: Foundation & Utilities

**Goal**: Establish reusable test infrastructure and patterns for dialog testing

### Phase 1 Tasks ✅ COMPLETE

#### 1.1: Create DialogTestHelper Utility Class
- [x] Create `test/helpers/dialog_test_helpers.dart`
- [x] Implement `openDialog()` - Helper to show dialogs in tests
- [x] Implement `closeDialog()` - Helper to close/cancel dialogs (pressBackButton, tapOutsideDialog)
- [x] Implement `findDialogByType<T>()` - Type-safe dialog finder
- [x] Implement `tapDialogButton(String buttonText)` - Tap buttons by text
- [x] Implement `fillDialogForm(Map<String, dynamic> fields)` - Fill form fields
- [x] Implement `verifyDialogReturnValue<T>(T expected)` - Verify return values
- [x] Implement `verifyDialogClosed()` - Verify dialog dismissed
- [x] Add comprehensive documentation with examples (inline dartdoc)

#### 1.2: Extend Existing Test Utilities
- [x] Add `captureDialogReturnValue<T>()` to DialogTestHelper (openDialogAndCapture)
- [x] Add `verifyNoSideEffects(MockDatabaseHelper)` - Verify DB unchanged after cancel
- [x] Add error simulation support via MockDatabaseHelper.failOnOperation()
- [x] Create fixtures for common dialog test data in `test/test_utils/dialog_fixtures.dart`

#### 1.3: Document Dialog Testing Patterns
- [x] Create `docs/DIALOG_TESTING_GUIDE.md`
- [x] Document the standard dialog test structure
- [x] Document return value testing pattern
- [x] Document cancellation testing pattern
- [x] Document error handling testing pattern
- [x] Add code examples for each pattern
- [x] Document best practices for temporary state testing

**Phase 1 Completion Criteria:** ✅
- ✅ DialogTestHelper class exists with all core methods (18 methods)
- ✅ Documentation guide is complete (645 lines)
- ✅ At least one existing dialog test updated to use new utilities (add_ingredient_dialog_test.dart)
- ✅ DialogFixtures created with Recipe, Meal, Ingredient fixtures
- ✅ MockDatabaseHelper extended with public meals getter

---

## PHASE 2: Core Dialog Testing

**Goal**: Implement comprehensive tests for all dialogs covering return values and cancellation

### Phase 2.1: Return Value Testing

#### 2.1.1: MealCookedDialog Tests
Create `test/widgets/meal_cooked_dialog_test.dart`:
- [ ] Test: Dialog opens with correct initial state
- [ ] Test: Returns correct cooking details on save
- [ ] Test: Date picker updates cookedAt correctly
- [ ] Test: Pre-fills with recipe's expected prep/cook times
- [ ] Test: Validates servings input
- [ ] Test: Validates prep time input
- [ ] Test: Validates cook time input
- [ ] Test: wasSuccessful switch toggles correctly
- [ ] Test: Returns null when cancelled
- [ ] Test: Notes field preserves user input

#### 2.1.2: MealRecordingDialog Tests
Create `test/widgets/meal_recording_dialog_test.dart`:
- [ ] Test: Dialog opens with correct initial state
- [ ] Test: Returns correct meal data on save
- [ ] Test: Pre-fills notes when provided
- [ ] Test: Pre-fills planned date when provided
- [ ] Test: Pre-fills additional recipes when provided
- [ ] Test: Allows adding side dishes
- [ ] Test: Allows removing side dishes
- [ ] Test: Validates all required fields
- [ ] Test: Returns null when cancelled
- [ ] Test: Loads available recipes correctly

#### 2.1.3: AddSideDishDialog Tests
Create `test/widgets/add_side_dish_dialog_test.dart`:
- [ ] Test: Dialog opens with available recipes
- [ ] Test: Returns selected recipes on save
- [ ] Test: Excludes already selected recipes from list
- [ ] Test: Excludes primary recipe from list
- [ ] Test: Search functionality filters recipes
- [ ] Test: Can add multiple side dishes
- [ ] Test: Can remove selected side dishes
- [ ] Test: Returns null when cancelled
- [ ] Test: Shows current side dishes correctly
- [ ] Test: onSideDishesChanged callback fires correctly

#### 2.1.4: AddNewIngredientDialog Tests
Create `test/widgets/add_new_ingredient_dialog_test.dart`:
- [ ] Test: Dialog opens with empty form
- [ ] Test: Returns created Ingredient on save
- [ ] Test: Validates ingredient name
- [ ] Test: Category dropdown works correctly
- [ ] Test: Unit dropdown works correctly
- [ ] Test: Protein type shown only for protein category
- [ ] Test: Returns null when cancelled
- [ ] Test: Saves ingredient to database
- [ ] Test: Error handling when save fails

#### 2.1.5: Expand AddIngredientDialog Tests
Update `test/widgets/add_ingredient_dialog_test.dart`:
- [ ] Test: Returns RecipeIngredient on save
- [ ] Test: Verifies RecipeIngredient has correct recipeId
- [ ] Test: Verifies RecipeIngredient has correct ingredientId
- [ ] Test: Verifies RecipeIngredient has correct quantity
- [ ] Test: Verifies RecipeIngredient has correct unit
- [ ] Test: Custom ingredient creation returns correct object
- [ ] Test: Database ingredient selection returns correct object

#### 2.1.6: Expand EditMealRecordingDialog Tests
Update `test/widgets/edit_meal_recording_dialog_test.dart`:
- [ ] Test: Returns updated Meal object on save
- [ ] Test: Verifies only changed fields are different
- [ ] Test: Verifies unchanged fields remain the same
- [ ] Test: Database update is called with correct values
- [ ] Test: Multiple recipe meals return correctly

### Phase 2.2: Cancellation & No Side Effects Testing

#### 2.2.1: Cancellation Tests for All Dialogs
For each dialog test file:
- [ ] MealCookedDialog: Cancel returns null, DB unchanged
- [ ] MealRecordingDialog: Cancel returns null, DB unchanged, temp recipes not saved
- [ ] AddSideDishDialog: Cancel returns null, selections not persisted
- [ ] AddNewIngredientDialog: Cancel returns null, ingredient not created in DB
- [ ] AddIngredientDialog: Cancel returns null, recipe ingredient not added
- [ ] EditMealRecordingDialog: Cancel returns null, meal not updated in DB

#### 2.2.2: Back Button / Dismiss Testing
For each dialog:
- [ ] Test: Tapping outside dialog dismisses and returns null
- [ ] Test: Back button dismisses and returns null
- [ ] Test: No database changes after dismiss
- [ ] Test: Temporary state is cleaned up

**Phase 2 Completion Criteria:**
- All 6 dialogs have comprehensive test files
- All dialogs have return value tests
- All dialogs have cancellation tests with side effect verification
- Test coverage for dialogs reaches >80%

---

## PHASE 3: Advanced Scenarios

**Goal**: Cover error handling, temporary state, and edge cases

### Phase 3.1: Error Handling Tests

#### 3.1.1: Database Error Scenarios
For dialogs that interact with database:
- [ ] MealRecordingDialog: Test error when loading recipes fails
- [ ] MealRecordingDialog: Test error when saving meal fails
- [ ] AddIngredientDialog: Test error when loading ingredients fails
- [ ] AddNewIngredientDialog: Test error when creating ingredient fails
- [ ] EditMealRecordingDialog: Test error when updating meal fails
- [ ] Verify appropriate error messages shown to user
- [ ] Verify dialog remains open on error (doesn't auto-close)

#### 3.1.2: Validation Error Scenarios
For each dialog with forms:
- [ ] Test: Invalid servings (negative, zero, non-numeric)
- [ ] Test: Invalid times (negative, non-numeric)
- [ ] Test: Invalid dates (future dates where not allowed)
- [ ] Test: Required field validation (empty fields)
- [ ] Test: Save button disabled when validation fails
- [ ] Test: Error messages displayed correctly

#### 3.1.3: Network/Async Error Scenarios
- [ ] Test: Loading state displayed while async operations run
- [ ] Test: Graceful handling of slow database operations
- [ ] Test: Timeout scenarios (if applicable)

### Phase 3.2: Temporary State & Multi-Step Operations

#### 3.2.1: Temporary State Tests
- [ ] MealRecordingDialog: Test temporary side dish additions before save
- [ ] MealRecordingDialog: Test removing temp side dishes doesn't affect DB
- [ ] AddSideDishDialog: Test temporary recipe selections
- [ ] AddIngredientDialog: Test switching between DB/custom mode preserves form
- [ ] Test: Form state persists across dialog rebuilds
- [ ] Test: Temporary objects are created with correct IDs

#### 3.2.2: Multi-Step Operation Tests
- [ ] MealRecordingDialog: Add multiple side dishes, verify all returned
- [ ] MealRecordingDialog: Add and remove side dishes, verify final state
- [ ] AddIngredientDialog: Create custom ingredient then add to recipe
- [ ] Test: State transitions between steps are correct
- [ ] Test: Can navigate back and forth without losing data

### Phase 3.3: Edge Cases & Boundary Conditions

#### 3.3.1: Edge Case Tests
For each dialog:
- [ ] Test: Very long text input in notes fields (> 1000 chars)
- [ ] Test: Special characters in text fields
- [ ] Test: Maximum/minimum numeric values
- [ ] Test: Empty optional fields
- [ ] Test: Rapid repeated button clicks (prevent double-submit)
- [ ] Test: Opening dialog while another is open

#### 3.3.2: Data Consistency Tests
- [ ] Test: Dialog displays stale data after external update
- [ ] Test: Concurrent modifications handling
- [ ] Test: Recipe deleted while dialog open
- [ ] Test: Ingredient deleted while selecting

**Phase 3 Completion Criteria:**
- All error scenarios have tests
- All temporary state scenarios have tests
- Common edge cases are covered
- Test coverage for dialogs reaches >90%

---

## PHASE 4: Documentation & Regression Tests

**Goal**: Document patterns, create regression tests, and ensure maintainability

### Phase 4.1: Regression Tests

#### 4.1.1: Identify Known Dialog Bugs
- [ ] **USER INPUT NEEDED**: List any known dialog-related bugs that have been fixed
- [ ] Review GitHub issues for dialog bugs
- [ ] Review commit history for dialog fixes
- [ ] Document bugs in `docs/DIALOG_KNOWN_ISSUES.md`

#### 4.1.2: Create Regression Test Suite
- [ ] Create `test/regression/dialog_regression_test.dart`
- [ ] Add regression test for each identified bug
- [ ] Document the bug being tested in test comments
- [ ] Link tests to original issue numbers

### Phase 4.2: Documentation Completion

#### 4.2.1: Testing Pattern Documentation
- [ ] Complete `docs/DIALOG_TESTING_GUIDE.md`
- [ ] Add section on common pitfalls
- [ ] Add section on debugging dialog tests
- [ ] Add troubleshooting guide
- [ ] Add examples from actual tests

#### 4.2.2: Code Documentation
- [ ] Add comprehensive dartdoc comments to DialogTestHelper
- [ ] Add examples to test utility methods
- [ ] Document mock database setup for dialogs
- [ ] Add inline comments to complex test scenarios

#### 4.2.3: Update Project Documentation
- [ ] Update `CLAUDE.md` with dialog testing patterns
- [ ] Update `docs/Gastrobrain-Codebase-Overview.md` with testing section
- [ ] Add dialog testing to PR checklist
- [ ] Update test running instructions

### Phase 4.3: Code Review & Quality Assurance

#### 4.3.1: Test Quality Review
- [ ] Review all dialog tests for consistency
- [ ] Ensure all tests use DialogTestHelper where appropriate
- [ ] Verify test naming conventions are followed
- [ ] Check test isolation (no dependencies between tests)
- [ ] Verify proper setup/tearDown in all test files

#### 4.3.2: Coverage Analysis
- [ ] Run `flutter test --coverage`
- [ ] Analyze coverage report for dialog files
- [ ] Identify any untested code paths
- [ ] Add tests for uncovered scenarios
- [ ] Target: >90% coverage for all dialog widgets

#### 4.3.3: Performance & Maintainability
- [ ] Verify tests run quickly (< 5s per dialog test file)
- [ ] Check for flaky tests (run suite 10 times)
- [ ] Ensure tests are deterministic
- [ ] Review test readability and clarity
- [ ] Refactor duplicated test code

**Phase 4 Completion Criteria:**
- All regression tests created
- Documentation is complete and comprehensive
- Test coverage exceeds 90% for dialogs
- All tests pass consistently
- Code review complete

---

## Acceptance Criteria Mapping

This roadmap addresses all acceptance criteria from issue #38:

| Acceptance Criterion | Addressed In |
|---------------------|--------------|
| Create test utilities for simulating dialog interactions | Phase 1.1, 1.2 |
| Implement tests for dialog return value handling in at least 3 workflows | Phase 2.1 (all 6 dialogs) |
| Add specific tests for temporary object creation and persistence | Phase 3.2 |
| Test dialog cancellation paths and verify no side effects occur | Phase 2.2 |
| Verify form validation behaves correctly within dialog contexts | Phase 2.1, Phase 3.1.2 |
| Test error handling scenarios within dialogs | Phase 3.1 |
| Create regression tests for previously identified dialog-related bugs | Phase 4.1 |
| Document patterns for testing dialogs and state management | Phase 1.3, Phase 4.2 |

---

## Estimated Effort

| Phase | Tasks | Estimated Effort |
|-------|-------|-----------------|
| Phase 1: Foundation | 3 major tasks | 2-3 work sessions |
| Phase 2: Core Testing | 8 major tasks | 4-5 work sessions |
| Phase 3: Advanced Scenarios | 9 major tasks | 3-4 work sessions |
| Phase 4: Documentation | 9 major tasks | 2-3 work sessions |
| **Total** | **29 major tasks** | **11-15 work sessions** |

*Note: Effort estimates assume focused work sessions of 2-3 hours each*

---

## Success Metrics

When this issue is complete, we will have achieved:

1. ✅ DialogTestHelper utility class with comprehensive API
2. ✅ 100% dialog test coverage (6/6 dialogs have test files)
3. ✅ >90% code coverage for all dialog widgets
4. ✅ All return value scenarios tested
5. ✅ All cancellation scenarios tested with side effect verification
6. ✅ Comprehensive error handling tests
7. ✅ Regression test suite for known bugs
8. ✅ Complete documentation of patterns and best practices
9. ✅ All tests passing in CI/CD
10. ✅ Zero flaky dialog tests

---

## Getting Started

To begin work on this issue:

1. **Review this roadmap** and clarify any questions about scope or approach
2. **Start with Phase 1** - the foundation utilities will make subsequent phases easier
3. **Work incrementally** - complete each phase before moving to the next
4. **Update this document** - check off tasks as they're completed
5. **Ask for feedback** - get user input on regression bugs and approach

## User Input & Priorities

### Known Dialog Bugs (Regression Tests Required)

**Critical: Controller Disposal Crash (commit 07058a2)**
- **Issue**: Dialog cancellation caused crash when disposing controller still in use
- **Fix**: Used `WidgetsBinding.instance.addPostFrameCallback((_) { controller.dispose(); })`
- **Test Required**: Verify all dialogs safely dispose controllers on cancellation
- **Location**: Phase 4.1 - Regression Tests

### Priority Dialogs

Based on user input and Issue #237:

1. **HIGH PRIORITY**: AddSideDishDialog - Part of critical meal editing workflow
2. **HIGH PRIORITY**: EditMealRecordingDialog - Core meal editing
3. **HIGH PRIORITY**: MealRecordingDialog - Core meal planning
4. **MEDIUM**: AddIngredientDialog - Already has basic tests
5. **MEDIUM**: MealCookedDialog - Planning workflow
6. **LOW**: AddNewIngredientDialog - Less frequently used

### Timeline & Scope

**Target**: Maximum 10 work sessions (user constraint)
**Estimated**: 11-15 sessions (original estimate)
**Strategy**: Prioritize high-impact dialogs, streamline documentation

**Recommended Approach**:
- Focus on 3 priority dialogs in Phase 2
- Streamline Phase 4 documentation
- Defer low-priority dialogs if needed

### Coverage Target

- **85%** code coverage for dialog widgets (user-approved)
- **100%** for critical cancellation paths
- **100%** for regression test (controller disposal)

### Testing Scope

- Focus on dialog widget tests
- Screen-level `showDialog()` calls covered in integration tests (out of scope)

---

**Document Version**: 1.1
**Last Updated**: 2025-12-27
**Issue**: #38
**Milestone**: 0.1.3 - User Features & Critical Foundation
**Timeline**: Max 10 work sessions
