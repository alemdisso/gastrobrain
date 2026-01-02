# Roadmap: Issue #244 - Error Simulation Support for MockDatabaseHelper

**Issue:** [#244 - Add comprehensive error simulation support to MockDatabaseHelper](https://github.com/alemdisso/gastrobrain/issues/244)
**Milestone:** 0.1.4 - Architecture & Critical Bug Fixes
**Priority:** P2-Medium
**Labels:** technical-debt, testing
**Estimated Effort:** M - 3 points (~3-4 hours)

---

## Confirmed Scope: Option B

Based on [planning discussion](https://github.com/alemdisso/gastrobrain/issues/244#issuecomment-3702843042), the scope is focused on **High + Medium Priority Methods (~10 methods)** rather than all 50+ methods.

### Why This Scope

- **Focused** - Covers methods actually used in dialog/screen tests
- **Practical** - Implements capability now, tests added as needed
- **Maintainable** - Documentation ensures future developers know what's available
- **Extensible** - Pattern established for adding more methods in the future

---

## Phase 1: High Priority Methods (6 methods)

**Goal:** Enable error testing for methods needed by current/near-future tests.

**Estimated Time:** ~1-1.5 hours

### 1.1 Ingredient Operations
- [ ] Add error simulation to `getAllIngredients()`
  - **Used by:** `AddIngredientDialog`, `IngredientsScreen`
  - **Unblocks:** #38 Phase 3.1

### 1.2 Recipe Operations
- [ ] Add error simulation to `getRecipe()`
  - **Used by:** Edit recipe screens

### 1.3 Meal Operations
- [ ] Add error simulation to `getRecentMeals()`
  - **Used by:** Meal history screens
- [ ] Add error simulation to `getAllMeals()`
  - **Used by:** Meal history screen
- [ ] Add error simulation to `getMealRecipesForMeal()`
  - **Used by:** Multi-recipe meal handling

### 1.4 Refactor Existing Error Simulation
- [ ] Refactor `deleteMeal()` from custom `shouldThrowOnDelete` to standard pattern
  - **Note:** Currently uses legacy flag, should use `failOnOperation()` for consistency

---

## Phase 2: Medium Priority Methods (4 methods)

**Goal:** Enable error testing for operations that might be useful.

**Estimated Time:** ~30-45 minutes

### 2.1 Recipe Filter Operations
- [ ] Add error simulation to `getRecipesWithSortAndFilter()`
  - **Used by:** Filter error scenarios on recipe list

### 2.2 Meal Plan Operations
- [ ] Add error simulation to `getMealPlan()`
  - **Used by:** Weekly plan screen
- [ ] Add error simulation to `getMealPlanForWeek()`
  - **Used by:** Weekly plan screen
- [ ] Add error simulation to `getMealPlanItemsForDate()`
  - **Used by:** Weekly plan screen

---

## Phase 3: Documentation

**Goal:** Ensure discoverability and maintainability.

**Estimated Time:** ~30-60 minutes

### 3.1 Create Documentation File
- [ ] Create `docs/testing/MOCK_DATABASE_ERROR_SIMULATION.md` with:
  - List of all methods with error simulation support (existing + new)
  - Usage examples with `failOnOperation()`
  - Best practices for error testing in dialogs/screens

### 3.2 Update Existing Documentation
- [ ] Update `CLAUDE.md` testing section to reference error simulation docs
- [ ] Update `docs/testing/DIALOG_TESTING_GUIDE.md` to reference error simulation

---

## Phase 4: Verification

**Goal:** Confirm implementation works correctly.

**Estimated Time:** ~30 minutes

### 4.1 Manual Verification
- [ ] Verify error simulation works for `getAllIngredients()` (sample high priority)
- [ ] Verify error simulation works for `getMealPlan()` (sample medium priority)
- [ ] Verify `deleteMeal()` refactor works correctly

### 4.2 Regression Check
- [ ] Run `flutter test` to ensure no regressions
- [ ] Run `flutter analyze` to ensure no new warnings

---

## Implementation Details

### Standard Error Simulation Pattern

Add this block at the start of each method:

```dart
Future<T> methodName() async {
  // Check if error simulation is enabled for this operation
  if (_shouldFailNextOperation &&
      (_failOnSpecificOperation == null ||
          _failOnSpecificOperation == 'methodName')) {
    final exception = _customException ?? Exception(_nextOperationError);
    resetErrorSimulation();
    throw exception;
  }

  // ... actual implementation
}
```

### deleteMeal() Refactor

**Before (legacy pattern):**
```dart
Future<int> deleteMeal(String id) async {
  if (shouldThrowOnDelete) {
    throw Exception('Simulated delete error');
  }
  // ...
}
```

**After (standard pattern):**
```dart
Future<int> deleteMeal(String id) async {
  if (_shouldFailNextOperation &&
      (_failOnSpecificOperation == null ||
          _failOnSpecificOperation == 'deleteMeal')) {
    final exception = _customException ?? Exception(_nextOperationError);
    resetErrorSimulation();
    throw exception;
  }
  // ...
}
```

**Note:** Keep `shouldThrowOnDelete` temporarily for backwards compatibility, or update any existing tests that use it.

---

## Methods Summary

### After Implementation - Methods WITH Error Simulation

| Method | Category | Priority | Status |
|--------|----------|----------|--------|
| `insertRecipe()` | Recipe | - | ✅ Existing |
| `getAllRecipes()` | Recipe | - | ✅ Existing |
| `updateRecipe()` | Recipe | - | ✅ Existing |
| `deleteRecipe()` | Recipe | - | ✅ Existing |
| `getRecipe()` | Recipe | High | ⬜ New |
| `getRecipesWithSortAndFilter()` | Recipe | Medium | ⬜ New |
| `insertMeal()` | Meal | - | ✅ Existing |
| `getMeal()` | Meal | - | ✅ Existing |
| `getMealsForRecipe()` | Meal | - | ✅ Existing |
| `updateMeal()` | Meal | - | ✅ Existing |
| `deleteMeal()` | Meal | High | 🔄 Refactor |
| `getRecentMeals()` | Meal | High | ⬜ New |
| `getAllMeals()` | Meal | High | ⬜ New |
| `getMealRecipesForMeal()` | MealRecipe | High | ⬜ New |
| `insertMealRecipe()` | MealRecipe | - | ✅ Existing |
| `insertIngredient()` | Ingredient | - | ✅ Existing |
| `updateIngredient()` | Ingredient | - | ✅ Existing |
| `deleteIngredient()` | Ingredient | - | ✅ Existing |
| `getAllIngredients()` | Ingredient | High | ⬜ New |
| `getMealPlan()` | MealPlan | Medium | ⬜ New |
| `getMealPlanForWeek()` | MealPlan | Medium | ⬜ New |
| `getMealPlanItemsForDate()` | MealPlan | Medium | ⬜ New |

**Legend:** ✅ Existing | ⬜ New | 🔄 Refactor

---

## Out of Scope

- Adding error simulation to ALL methods (50+ methods) - too much overhead for limited benefit
- Writing dedicated test suite for error simulation - tests will be added as needed when writing dialog/screen tests
- Lower priority methods (stats, recommendation history, rarely-used operations)

---

## Benefits

- Unblocks error handling tests for `AddIngredientDialog` (#38 Phase 3.1)
- Enables comprehensive error testing for meal history screens
- Enables error testing for weekly plan operations
- Standardizes error simulation pattern across all methods
- Documents error simulation capabilities for future test writing

---

## Related Issues

- **#38 Phase 3.1** - Error handling tests depend on this (specifically `getAllIngredients()`)
- **#237** - DI improvements will make error testing easier overall

---

## Acceptance Criteria

From issue #244:

- [ ] All database read operations **in scope** support error simulation
- [ ] All database write operations **in scope** support error simulation
- [ ] Documentation updated showing which operations support error simulation
- [ ] Manual verification that error simulation works for new methods

---

## Changelog

| Date | Version | Notes |
|------|---------|-------|
| 2026-01-02 | 1.0 | Initial roadmap (comprehensive scope) |
| 2026-01-02 | 2.0 | Updated to confirmed Option B scope (~10 methods) |
