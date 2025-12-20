<!-- markdownlint-disable -->
# Meal Editing Refactoring Plan

## Overview

This document outlines the comprehensive plan to refactor meal editing functionality across two UI flows that currently have ~85% duplicated logic but different implementations.

**Related Issues:**
- #124 - Meal edit feedback messages test roadmap
- #234 - Refactor `_updateMealRecord()` and `_updateMealRecipes()`
- #235 - Refactor `_handleMarkAsCooked()`
- #236 - Refactor `_updateMealPlanItemRecipes()`
- [#237](https://github.com/alemdisso/gastrobrain/issues/237) - Consolidate meal editing logic into shared service

**Last Updated:** 2025-12-12

---

## Problem Statement

### Current State: Two Flows, Duplicated Logic

The application has two UI flows for editing meals that implement identical business logic differently:

#### Flow 1: MealHistoryScreen (From Recipe List)
- **Path:** Recipe List → Recipe Card → Meal History → Edit Meal
- **Implementation:** ✅ Uses proper abstraction (DatabaseHelper)
- **Code:** `lib/screens/meal_history_screen.dart`
- **Pattern:** Screen → DatabaseHelper → Database
- **Testing:** ✅ Comprehensive (2,365 lines of tests)

#### Flow 2: WeeklyPlanScreen (From Weekly Plan)
- **Path:** Weekly Plan → Meal Slot → Edit Cooked Meal / Mark as Cooked
- **Implementation:** ❌ Uses raw database access
- **Code:** `lib/screens/weekly_plan_screen.dart`
- **Pattern:** Screen → Raw DB Transactions → Database
- **Testing:** ❌ Blocked (1 test commented out, cannot run)

### Duplication Analysis

| Functionality | MealHistoryScreen | WeeklyPlanScreen | Duplication |
|---------------|-------------------|------------------|-------------|
| Update meal record | `_updateMealInDatabase()` (30 lines) | `_updateMealRecord()` (25 lines) | ~80% |
| Update meal recipes | `_updateMealRecipeAssociations()` (25 lines) | `_updateMealRecipes()` (25 lines) | ~90% |
| Record new meal | Uses `CookMealScreen` | `_handleMarkAsCooked()` (70 lines) | ~85% |
| **Total duplicated** | **~55 lines** | **~120 lines** | **~85%** |

**Impact:**
- ~175 lines of duplicated business logic
- Two different implementations of the same operations
- Tests blocked for WeeklyPlanScreen flow
- Maintenance burden (bugs need fixing in two places)
- Architectural inconsistency

---

## Root Cause Analysis

### Why This Happened

1. **WeeklyPlanScreen implemented later** without reusing existing abstractions
2. **Different developer patterns** - bypassed established architecture
3. **No shared service layer** - no `MealEditService` to centralize logic
4. **Lack of code review** - duplication not caught during development

### The Architectural Gap

**Current State:**
```
┌─────────────────────┐         ┌─────────────────────┐
│ MealHistoryScreen   │         │ WeeklyPlanScreen    │
└──────────┬──────────┘         └──────────┬──────────┘
           │                               │
           ▼                               ▼
   DatabaseHelper                   Raw DB Transactions
           │                               │
           └───────────┬───────────────────┘
                       ▼
                   Database
```

**Desired State:**
```
┌─────────────────────┐         ┌─────────────────────┐
│ MealHistoryScreen   │         │ WeeklyPlanScreen    │
└──────────┬──────────┘         └──────────┬──────────┘
           │                               │
           │   Both use shared service     │
           └───────────┬───────────────────┘
                       ▼
           ┌───────────────────────┐
           │   MealEditService     │
           │   or MealProvider     │
           └───────────┬───────────┘
                       ▼
           ┌───────────────────────┐
           │   DatabaseHelper      │
           └───────────┬───────────┘
                       ▼
                   Database
```

---

## Refactoring Strategy: Phased Approach

### Why Phased?

**Pros:**
- ✅ Quick wins - unblock tests immediately
- ✅ Low risk - small, incremental changes
- ✅ Easy review - each PR is focused and manageable
- ✅ Flexible - can pause between phases if needed
- ✅ Safe rollback - easier to revert small changes
- ✅ Learn first - understand both implementations before consolidating

**Cons:**
- ⚠️ Code churn - two refactoring passes
- ⚠️ Temporary duplication - exists between Phase 1 and Phase 2

### Alternative: Integrated Approach (Not Recommended)

Create shared service and migrate both screens simultaneously:
- ❌ Slower to unblock tests (3-5 days vs 1-2 days)
- ❌ Higher risk (large PR, many moving parts)
- ❌ Harder to review and debug
- ❌ Tests might break during transition

**Decision:** Use Phased Approach

---

## Phase 1: Achieve Architectural Parity

**Goal:** Make WeeklyPlanScreen use the same patterns as MealHistoryScreen

**Timeline:** Sprint N (1-2 weeks)

**Outcome:**
- ✅ All tests unblocked
- ✅ WeeklyPlanScreen uses DatabaseHelper/MealProvider
- ✅ No raw database access
- ✅ Consistent architecture across both screens
- ⚠️ Duplication still exists (but it's "good" duplication)

### Issue #235: Refactor `_handleMarkAsCooked()` (CRITICAL)

**Priority:** P1-High
**Blocking:** Test 2.2.1 from #124 roadmap

**Problem:**
```dart
// Current - Raw DB access at line 741
await _dbHelper.database.then((db) async {
  return await db.transaction((txn) async {
    await txn.insert('meals', mealMap);
    await txn.insert('meal_recipes', primaryMealRecipe.toMap());
  });
});
```

**Solution:**
Use `MealProvider` pattern like `CookMealScreen` does:
```dart
final mealProvider = context.read<MealProvider>();
await mealProvider.recordMeal(meal);
await mealProvider.addMealRecipe(primaryMealRecipe);
await mealProvider.addMealRecipe(sideDishMealRecipe);
```

**Files Changed:**
- `lib/screens/weekly_plan_screen.dart:672-807`

**Lines Changed:** ~70 lines

**Acceptance Criteria:**
- [ ] `_handleMarkAsCooked()` uses MealProvider abstraction
- [ ] No raw database access in this method
- [ ] Existing "Mark as Cooked" functionality works
- [ ] Test 2.2.1 can be uncommented and passes

### Issue #234: Refactor `_updateMealRecord()` and `_updateMealRecipes()` (HIGH)

**Priority:** P1-High
**Blocking:** Edit cooked meal tests

**Problem:**
```dart
// Current - Raw DB access at lines 1048, 1142
final db = await _dbHelper.database;
await db.update('meals', {...});
await db.transaction((txn) => txn.delete('meal_recipes', ...));
```

**Solution:**
Use `DatabaseHelper` pattern like `MealHistoryScreen` does:
```dart
// Update meal
final updatedMeal = Meal(/* ... */);
await _dbHelper.updateMeal(updatedMeal);

// Update recipes
final currentMealRecipes = await _dbHelper.getMealRecipesForMeal(mealId);
for (final mealRecipe in currentMealRecipes) {
  if (!mealRecipe.isPrimaryDish) {
    await _dbHelper.deleteMealRecipe(mealRecipe.id);
  }
}
await _dbHelper.insertMealRecipe(sideDishMealRecipe);
```

**Files Changed:**
- `lib/screens/weekly_plan_screen.dart:1038-1064` (updateMealRecord)
- `lib/screens/weekly_plan_screen.dart:1140-1163` (updateMealRecipes)

**Lines Changed:** ~50 lines

**Acceptance Criteria:**
- [ ] `_updateMealRecord()` uses `DatabaseHelper.updateMeal()`
- [ ] `_updateMealRecipes()` uses DatabaseHelper methods
- [ ] No raw database access in these methods
- [ ] Existing edit functionality works
- [ ] Edit meal tests can be written and pass

### Issue #236: Refactor `_updateMealPlanItemRecipes()` (MEDIUM)

**Priority:** P2-Medium
**Blocking:** Manage recipes tests

**Problem:**
```dart
// Current - Raw DB access at line 1176
await _dbHelper.database.then((db) async {
  return await db.transaction((txn) async {
    await txn.delete('meal_plan_item_recipes', ...);
    await txn.insert('meal_plan_item_recipes', ...);
  });
});
```

**Solution:**
Add and use DatabaseHelper methods:
```dart
// Option 1: Add specific method
await _dbHelper.updateMealPlanItemRecipes(itemId, recipes);

// Option 2: Use existing methods
await _dbHelper.deleteMealPlanItemRecipes(itemId);
await _dbHelper.insertMealPlanItemRecipe(recipe);
```

**Files Changed:**
- `lib/screens/weekly_plan_screen.dart:1171-1210`
- `lib/database/database_helper.dart` (add methods if needed)
- `test/mocks/mock_database_helper.dart` (mock new methods)

**Lines Changed:** ~35 lines

**Acceptance Criteria:**
- [ ] `_updateMealPlanItemRecipes()` uses DatabaseHelper abstraction
- [ ] No raw database access
- [ ] Existing manage recipes functionality works
- [ ] Mockable with `MockDatabaseHelper`

---

## Phase 2: Eliminate Duplication

**Goal:** Consolidate duplicated meal editing logic into a shared service

**Timeline:** Sprint N+1 or N+2 (1-2 weeks after Phase 1)

**Outcome:**
- ✅ Zero duplication
- ✅ Single source of truth for meal editing
- ✅ Easier to maintain and extend
- ✅ Better testability

### Issue #237: Consolidate Meal Editing Logic

**Priority:** P2-Medium
**Type:** Technical Debt / Refactoring

**Scope:** Create shared service and refactor all meal editing screens

**See Issue #237 for detailed implementation plan**

---

## Implementation Guidelines

### For Issues #234, #235, #236: Structure for Easy Consolidation

When fixing raw database access, follow these principles:

#### ✅ DO:
- **Mirror existing patterns** - Use the same approach as MealHistoryScreen/CookMealScreen
- **Same method signatures** - Keep parameter names and order consistent
- **Same error handling** - Use the same exception patterns
- **Same DatabaseHelper methods** - Don't create divergent APIs
- **Same operation sequence** - Follow the same order of operations

#### ❌ DON'T:
- **Create new custom helpers** - Use existing DatabaseHelper methods
- **Use different methods** - Don't create WeeklyPlanScreen-specific APIs
- **Add screen-specific logic** - Keep business logic in DatabaseHelper/Provider
- **Skip error handling** - Match existing error patterns
- **Change operation order** - Follow established sequences

#### Example: Fix #234 the Right Way

**✅ GOOD - Mirrors MealHistoryScreen:**
```dart
Future<void> _updateMealRecord(...) async {
  // Same pattern as MealHistoryScreen._updateMealInDatabase
  final currentMeal = await _dbHelper.getMeal(mealId);
  if (currentMeal == null) {
    throw Exception('Meal not found');
  }

  final updatedMeal = Meal(
    id: mealId,
    recipeId: currentMeal.recipeId,
    cookedAt: cookedAt,
    servings: servings,
    notes: notes,
    wasSuccessful: wasSuccessful,
    actualPrepTime: actualPrepTime,
    actualCookTime: actualCookTime,
    modifiedAt: modifiedAt,
  );

  await _dbHelper.updateMeal(updatedMeal);  // Same method!
}
```

**❌ BAD - Creates divergence:**
```dart
Future<void> _updateMealRecord(...) async {
  // Different pattern - uses different method
  await _dbHelper.updateMealFields(mealId, {
    'servings': servings,
    'notes': notes,
    // ...
  });
}
```

### Testing Requirements

Each issue must include:

1. **Unit Tests**
   - All new/modified code paths tested
   - Error conditions tested
   - Mock database operations

2. **Integration Tests**
   - Full user flows tested
   - Multi-recipe scenarios tested
   - Edge cases covered

3. **Regression Tests**
   - Existing functionality still works
   - No breaking changes to API
   - Performance not degraded

4. **Test Coverage**
   - Maintain or improve coverage %
   - No decrease in test quality

---

## Success Metrics

### Phase 1 Success Criteria

- [ ] All 4 instances of raw DB access eliminated
- [ ] WeeklyPlanScreen uses same patterns as MealHistoryScreen
- [ ] Test 2.2.1 from #124 uncommented and passing
- [ ] All existing functionality works
- [ ] `flutter test` passes
- [ ] `flutter analyze` shows no issues

### Phase 2 Success Criteria

- [ ] ~175 lines of duplicated code eliminated
- [ ] Single `MealEditService` or extended `MealProvider`
- [ ] Both screens use the shared service
- [ ] All tests still passing
- [ ] No regression in functionality
- [ ] Code coverage maintained or improved

### Quality Gates

Before merging any PR:
1. ✅ All tests pass (`flutter test`)
2. ✅ No analysis issues (`flutter analyze`)
3. ✅ Code review approved by 1+ reviewers
4. ✅ Manual testing completed
5. ✅ Documentation updated (if needed)
6. ✅ No performance regression

---

## Risk Assessment

### Phase 1 Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Tests fail after refactoring | Medium | High | Comprehensive test coverage, incremental changes |
| Breaking existing functionality | Low | High | Manual testing, regression test suite |
| Performance degradation | Low | Medium | Benchmark critical paths |
| Merge conflicts | Medium | Low | Small PRs, frequent merges |

### Phase 2 Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Service API design issues | Medium | Medium | Design review before implementation |
| Both screens break simultaneously | Low | High | Feature flags, careful rollout |
| Tests become flaky | Medium | Medium | Improve test reliability first |
| Scope creep | High | Medium | Strict adherence to plan |

---

## Dependencies

### Technical Dependencies
- Flutter SDK (current version)
- `provider` package
- `sqflite` package
- Existing `MockDatabaseHelper`

### Code Dependencies
- `DatabaseHelper` API stability
- `MealProvider` API stability
- `EditMealRecordingDialog` widget
- `MealRecordingDialog` widget

### Team Dependencies
- Code review capacity
- QA testing capacity
- No conflicting refactoring efforts

---

## Timeline Estimate

### Optimistic (Everything Goes Well)
- **Phase 1:** 1 week
  - Issue #235: 1-2 days
  - Issue #234: 1-2 days
  - Issue #236: 1 day
- **Phase 2:** 1 week
  - Issue #237: 3-5 days

**Total:** 2 weeks

### Realistic (Expected Path)
- **Phase 1:** 2 weeks
  - Issue #235: 2-3 days (critical, needs thorough testing)
  - Issue #234: 2-3 days
  - Issue #236: 1-2 days
  - Buffer: 2 days
- **Phase 2:** 2 weeks
  - Issue #237: 5-7 days
  - Testing & refinement: 2-3 days

**Total:** 4 weeks

### Pessimistic (If Issues Arise)
- **Phase 1:** 3 weeks
- **Phase 2:** 3 weeks

**Total:** 6 weeks

---

## Rollback Plan

If issues arise during implementation:

### Phase 1 Rollback
Each issue (#234, #235, #236) is independent:
- Revert the specific PR
- Tests continue to work with previous implementation
- Other fixes remain in place

### Phase 2 Rollback
If consolidation causes issues:
- Revert Issue #237 PR
- Fall back to Phase 1 state (working, just duplicated)
- All tests still pass
- Functionality intact

**Safety:** Phase 1 provides a stable fallback state.

---

## Communication Plan

### Stakeholders
- Development team
- QA team
- Product owner
- Users (indirectly, through improved reliability)

### Updates
- **Weekly:** Progress update in team standup
- **Per Issue:** PR created with detailed description
- **Phase Complete:** Demo of improvements
- **Final:** Summary of benefits achieved

---

## Next Steps

1. **Immediate:** Begin Issue #235 (highest priority, unblocks Test 2.2.1)
2. **Week 1:** Complete Issues #235 and #234
3. **Week 2:** Complete Issue #236, verify all tests pass
4. **Week 3:** Plan Phase 2 (Issue #237) details
5. **Week 4:** Implement consolidation

---

## References

- [Issue #124: Meal Edit Feedback Messages Test Roadmap](https://github.com/alemdisso/gastrobrain/issues/124)
- [Issue #234: Refactor _updateMealRecord and _updateMealRecipes](https://github.com/alemdisso/gastrobrain/issues/234)
- [Issue #235: Refactor _handleMarkAsCooked](https://github.com/alemdisso/gastrobrain/issues/235)
- [Issue #236: Refactor _updateMealPlanItemRecipes](https://github.com/alemdisso/gastrobrain/issues/236)
- [Issue #237: Consolidate Meal Editing Logic](https://github.com/alemdisso/gastrobrain/issues/237)
- [Code Analysis: Meal Editing Flows](meal-editing-flow-analysis.md) (this session)
- [Test Roadmap: docs/issue-124-test-roadmap.md](issue-124-test-roadmap.md)

---

**Document Status:** Draft → Review → Approved → In Progress → Complete
**Current Status:** Draft
**Owner:** Development Team
**Last Reviewed:** 2025-12-12