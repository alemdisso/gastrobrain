# Roadmap: Issue #237 - Consolidate Meal Editing Logic into Shared Service

**Issue:** [#237 - Consolidate meal editing logic into shared service](https://github.com/alemdisso/gastrobrain/issues/237)
**Milestone:** 0.1.4 - Architecture & Critical Bug Fixes
**Priority:** P2-Medium
**Labels:** architecture, technical-debt
**Estimated Effort:** M - 5 points

---

## Confirmed Implementation Approach

Based on [planning discussion](https://github.com/alemdisso/gastrobrain/issues/237#issuecomment-3702878783):

- **Service Design:** Create new `MealEditService` for clean separation of concerns (not extending `MealProvider`)
- **Testing Strategy:** Use existing integration tests to verify refactoring (no new integration tests required)
- **Prerequisites:** Issues #234, #235, #236 must be completed first

---

## Problem Statement

Three screens implement ~85% duplicated meal editing logic:

| Screen | Helper Methods | Lines |
|--------|----------------|-------|
| `MealHistoryScreen` | `_updateMealInDatabase()`, `_updateMealRecipeAssociations()` | ~55 |
| `WeeklyPlanScreen` | `_updateMealRecord()`, `_updateMealRecipes()` | ~50 |
| `CookMealScreen` | `_saveMeal()` logic | ~20 |
| **Total Duplicated** | | **~125 lines** |

### Current Architecture (After Phase 1)

```
┌─────────────────────┐         ┌─────────────────────┐
│ MealHistoryScreen   │         │ WeeklyPlanScreen    │
│  _updateMealInDB    │         │  _updateMealRecord  │
│  _updateRecipes     │         │  _updateMealRecipes │
└──────────┬──────────┘         └──────────┬──────────┘
           │                               │
           │   Both use DatabaseHelper    │
           └───────────┬───────────────────┘
                       ▼
           ┌───────────────────────┐
           │   DatabaseHelper      │
           └───────────────────────┘
```

### Target Architecture (After This Issue)

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
           └───────────┬───────────┘
                       ▼
           ┌───────────────────────┐
           │   DatabaseHelper      │
           └───────────────────────┘
```

---

## Prerequisites

**Must be completed before starting this issue:**

| Issue | Description | Status |
|-------|-------------|--------|
| #234 | Refactor `_updateMealRecord()` and `_updateMealRecipes()` | ⬜ Pending |
| #235 | Refactor `_handleMarkAsCooked()` | ⬜ Pending |
| #236 | Refactor `_updateMealPlanItemRecipes()` | ⬜ Pending |

**Why this order:**
- Phase 1 (#234-236) brings both implementations to architectural parity
- Makes consolidation straightforward "extract to service" refactoring
- Provides stable fallback if Phase 2 has issues

---

## Phase 1: Create MealEditService

**Goal:** Create the shared service with core methods.

**Estimated Time:** ~2-3 hours

### 1.1 Create Service File
- [ ] Create `lib/core/services/meal_edit_service.dart`
- [ ] Implement `MealEditService` class with `DatabaseHelper` dependency

### 1.2 Implement Core Methods
- [ ] Implement `updateMealWithRecipes()` method
  - Consolidates logic from `MealHistoryScreen._updateMealInDatabase()` and `WeeklyPlanScreen._updateMealRecord()`
  - Handles meal update and recipe association updates atomically

```dart
Future<void> updateMealWithRecipes({
  required String mealId,
  required DateTime cookedAt,
  required int servings,
  required String notes,
  required bool wasSuccessful,
  required double actualPrepTime,
  required double actualCookTime,
  required List<Recipe> additionalRecipes,
}) async { ... }
```

- [ ] Implement `recordMealWithRecipes()` method
  - Consolidates logic from `CookMealScreen._saveMeal()` and `WeeklyPlanScreen._handleMarkAsCooked()`
  - Handles meal creation with primary and side dish recipes

```dart
Future<String> recordMealWithRecipes({
  required Meal meal,
  required Recipe primaryRecipe,
  required List<Recipe> additionalRecipes,
}) async { ... }
```

### 1.3 Register Service
- [ ] Add `MealEditService` to `ServiceProvider`
- [ ] Update dependency injection setup

---

## Phase 2: Refactor MealHistoryScreen

**Goal:** Replace helper methods with service calls.

**Estimated Time:** ~1-2 hours

### 2.1 Update Dependencies
- [ ] Add `MealEditService` field to screen
- [ ] Initialize service in `initState()` or via constructor

### 2.2 Refactor Edit Meal Handler
- [ ] Replace `_updateMealInDatabase()` + `_updateMealRecipeAssociations()` with `_mealEditService.updateMealWithRecipes()`

**Before:**
```dart
Future<void> _handleEditMeal(Map<String, dynamic> result) async {
  try {
    await _updateMealInDatabase(...);
    await _updateMealRecipeAssociations(...);
    await _loadMeals();
    // ...
  } catch (e) { ... }
}
```

**After:**
```dart
Future<void> _handleEditMeal(Map<String, dynamic> result) async {
  try {
    await _mealEditService.updateMealWithRecipes(
      mealId: mealId,
      cookedAt: cookedAt,
      servings: servings,
      notes: notes,
      wasSuccessful: wasSuccessful,
      actualPrepTime: actualPrepTime,
      actualCookTime: actualCookTime,
      additionalRecipes: additionalRecipes,
    );
    await _loadMeals();
    // ...
  } catch (e) { ... }
}
```

### 2.3 Remove Helper Methods
- [ ] Delete `_updateMealInDatabase()` method (~30 lines)
- [ ] Delete `_updateMealRecipeAssociations()` method (~25 lines)

### 2.4 Verify
- [ ] Run MealHistoryScreen tests
- [ ] Manual testing of edit meal flow

---

## Phase 3: Refactor WeeklyPlanScreen

**Goal:** Replace helper methods with service calls.

**Estimated Time:** ~1-2 hours

### 3.1 Update Dependencies
- [ ] Add `MealEditService` field to screen
- [ ] Initialize service appropriately

### 3.2 Refactor Edit Cooked Meal Handler
- [ ] Replace `_updateMealRecord()` + `_updateMealRecipes()` with `_mealEditService.updateMealWithRecipes()`

**Before:**
```dart
Future<void> _handleEditCookedMeal(...) async {
  try {
    await _updateMealRecord(...);
    await _updateMealRecipes(...);
    // ...
  } catch (e) { ... }
}
```

**After:**
```dart
Future<void> _handleEditCookedMeal(...) async {
  try {
    await _mealEditService.updateMealWithRecipes(
      mealId: mealId,
      cookedAt: cookedAt,
      // ...
    );
    // ...
  } catch (e) { ... }
}
```

### 3.3 Refactor Mark As Cooked Handler (if applicable)
- [ ] Replace meal recording logic with `_mealEditService.recordMealWithRecipes()`

### 3.4 Remove Helper Methods
- [ ] Delete `_updateMealRecord()` method (~25 lines)
- [ ] Delete `_updateMealRecipes()` method (~25 lines)

### 3.5 Verify
- [ ] Run WeeklyPlanScreen tests
- [ ] Manual testing of edit meal and mark as cooked flows

---

## Phase 4: Refactor CookMealScreen

**Goal:** Simplify meal recording with service.

**Estimated Time:** ~1 hour

### 4.1 Update Dependencies
- [ ] Add `MealEditService` field to screen

### 4.2 Refactor Save Meal Method
- [ ] Replace meal creation and recipe association logic with `_mealEditService.recordMealWithRecipes()`

**Before:**
```dart
Future<void> _saveMeal(Map<String, dynamic> mealData) async {
  final meal = Meal(...);
  final mealProvider = context.read<MealProvider>();

  await mealProvider.recordMeal(meal);
  await mealProvider.addMealRecipe(primaryMealRecipe);
  for (final recipe in additionalRecipes) {
    await mealProvider.addMealRecipe(sideDishMealRecipe);
  }
  // ...
}
```

**After:**
```dart
Future<void> _saveMeal(Map<String, dynamic> mealData) async {
  final meal = Meal(...);

  await _mealEditService.recordMealWithRecipes(
    meal: meal,
    primaryRecipe: primaryRecipe,
    additionalRecipes: additionalRecipes,
  );
  // ...
}
```

### 4.3 Verify
- [ ] Run CookMealScreen tests
- [ ] Manual testing of meal recording flow

---

## Phase 5: Cleanup & Verification

**Goal:** Ensure everything works correctly.

**Estimated Time:** ~1 hour

### 5.1 Code Cleanup
- [ ] Remove any unused imports from refactored screens
- [ ] Remove any unused helper methods
- [ ] Ensure consistent error handling across all screens

### 5.2 Run All Tests
- [ ] Run `flutter test` - all tests must pass
- [ ] Run `flutter analyze` - no new warnings

### 5.3 Manual Testing Checklist
- [ ] MealHistoryScreen: Edit a meal with side dishes
- [ ] WeeklyPlanScreen: Edit a cooked meal
- [ ] WeeklyPlanScreen: Mark a planned meal as cooked
- [ ] CookMealScreen: Record a new meal with side dishes

### 5.4 Documentation
- [ ] Update `docs/meal-editing-refactoring-plan.md` with completion status
- [ ] Add service to architecture documentation if needed

---

## Implementation Details

### MealEditService Structure

```dart
// lib/core/services/meal_edit_service.dart
import 'package:gastrobrain/database/database_helper.dart';
import 'package:gastrobrain/models/meal.dart';
import 'package:gastrobrain/models/meal_recipe.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/core/errors/gastrobrain_exceptions.dart';

class MealEditService {
  final DatabaseHelper _dbHelper;

  MealEditService(this._dbHelper);

  /// Update a meal record with new values and recipe associations
  Future<void> updateMealWithRecipes({
    required String mealId,
    required DateTime cookedAt,
    required int servings,
    required String notes,
    required bool wasSuccessful,
    required double actualPrepTime,
    required double actualCookTime,
    required List<Recipe> additionalRecipes,
  }) async {
    // 1. Get current meal
    final currentMeal = await _dbHelper.getMeal(mealId);
    if (currentMeal == null) {
      throw NotFoundException('Meal not found: $mealId');
    }

    // 2. Update meal
    final updatedMeal = Meal(
      id: mealId,
      recipeId: currentMeal.recipeId,
      cookedAt: cookedAt,
      servings: servings,
      notes: notes,
      wasSuccessful: wasSuccessful,
      actualPrepTime: actualPrepTime,
      actualCookTime: actualCookTime,
      modifiedAt: DateTime.now(),
    );
    await _dbHelper.updateMeal(updatedMeal);

    // 3. Update recipe associations
    // Delete existing side dishes (keep primary)
    await _dbHelper.deleteMealRecipesByMealId(mealId, excludePrimary: true);

    // Add new side dishes
    for (final recipe in additionalRecipes) {
      final sideDishMealRecipe = MealRecipe(
        mealId: mealId,
        recipeId: recipe.id,
        isPrimaryDish: false,
        notes: 'Side dish',
      );
      await _dbHelper.insertMealRecipe(sideDishMealRecipe);
    }
  }

  /// Record a new meal with primary and additional recipes
  Future<String> recordMealWithRecipes({
    required Meal meal,
    required Recipe primaryRecipe,
    required List<Recipe> additionalRecipes,
  }) async {
    // 1. Record meal
    await _dbHelper.insertMeal(meal);

    // 2. Add primary recipe
    final primaryMealRecipe = MealRecipe(
      mealId: meal.id,
      recipeId: primaryRecipe.id,
      isPrimaryDish: true,
      notes: 'Main dish',
    );
    await _dbHelper.insertMealRecipe(primaryMealRecipe);

    // 3. Add side dishes
    for (final recipe in additionalRecipes) {
      final sideDishMealRecipe = MealRecipe(
        mealId: meal.id,
        recipeId: recipe.id,
        isPrimaryDish: false,
        notes: 'Side dish',
      );
      await _dbHelper.insertMealRecipe(sideDishMealRecipe);
    }

    return meal.id;
  }
}
```

### ServiceProvider Registration

```dart
// In lib/core/di/service_provider.dart
class ServiceProvider {
  // ... existing code ...

  static MealEditService get mealEdit => MealEditService(database.helper);
}
```

---

## Code Impact Summary

| Component | Change | Lines |
|-----------|--------|-------|
| `MealEditService` | New file | +100 |
| `MealHistoryScreen` | Remove helper methods | -55 |
| `WeeklyPlanScreen` | Remove helper methods | -50 |
| `CookMealScreen` | Simplify `_saveMeal()` | -20 |
| **Net Change** | | **-25 lines** |

Plus improved architecture, maintainability, and testability.

---

## Benefits

- **~125 lines of duplicated code eliminated**
- **Single source of truth** for meal editing operations
- **Easier to maintain** - changes only in one place
- **Better testability** - centralized unit tests possible
- **Consistent error handling** across all screens
- **Easier to add features** - only update the service
- **Unblocks DI improvements** - enables `MealRecordingDialog` to use proper DI

---

## Related Issues

| Issue | Relationship |
|-------|--------------|
| #234 | **Prerequisite** - Refactor `_updateMealRecord()` and `_updateMealRecipes()` |
| #235 | **Prerequisite** - Refactor `_handleMarkAsCooked()` |
| #236 | **Prerequisite** - Refactor `_updateMealPlanItemRecipes()` |
| #124 | Related - Meal edit feedback messages test roadmap |
| #244 | Related - Error simulation improvements |

---

## Testing Limitation Note

From [comment on Dec 27](https://github.com/alemdisso/gastrobrain/issues/237#issuecomment-3694224600):

`MealRecordingDialog` creates its own `DatabaseHelper` instance, blocking proper DI testing. Once this issue is complete, consider:
1. Refactoring `MealRecordingDialog` to accept `DatabaseHelper` via constructor or use `ServiceProvider`
2. Adding comprehensive tests for side dish management via nested dialogs

---

## Acceptance Criteria

From issue #237:

- [ ] `MealEditService` created with proper DI
- [ ] `updateMealWithRecipes()` method implemented
- [ ] `recordMealWithRecipes()` method implemented
- [ ] `MealHistoryScreen` uses shared service
- [ ] `WeeklyPlanScreen` uses shared service
- [ ] `CookMealScreen` uses shared service
- [ ] No duplicated meal editing logic remains
- [ ] All existing functionality works correctly
- [ ] All tests pass (existing integration tests)
- [ ] `flutter analyze` shows no issues

---

## Changelog

| Date | Version | Notes |
|------|---------|-------|
| 2026-01-02 | 1.0 | Initial roadmap created |
