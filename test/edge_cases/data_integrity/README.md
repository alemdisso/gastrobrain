# Data Integrity Tests

This directory contains tests for data consistency and integrity.

## What is Data Integrity?

Data integrity tests verify that:
- No orphaned records exist (meals with deleted recipes)
- Foreign key relationships are maintained
- Transactions maintain consistency
- No partial updates occur on errors
- Cache stays synchronized with database
- Concurrent modifications don't corrupt data

## Why Test Data Integrity?

Data integrity issues can:
- Cause crashes when accessing deleted records
- Lead to data loss
- Create inconsistent UI state
- Break foreign key constraints
- Corrupt the database

## Test Categories

### Orphaned Records
- Tests for meals referencing deleted recipes
- Tests for recipe ingredients with deleted ingredients
- Tests for meal plans with deleted meals
- Cascade delete behavior verification

### Missing Data
- Tests for missing foreign keys
- Tests for missing required fields
- Tests for null where not expected

### Stale Data
- Tests for displaying stale data after updates
- Tests for cache invalidation
- Tests for concurrent modification conflicts

### Transaction Consistency
- Tests for transaction rollback on error
- Tests for no partial updates
- Tests for atomic operations

## Testing Pattern

### Orphaned Record Detection

```dart
testWidgets('handles meal with deleted recipe', (tester) async {
  final mockDb = TestSetup.setupMockDatabase();

  // Create meal with recipe
  final recipe = await mockDb.insertRecipe(testRecipe);
  final meal = await mockDb.insertMeal(testMeal);
  await mockDb.insertMealRecipe(MealRecipe(
    mealId: meal.id,
    recipeId: recipe.id,
    isPrimaryDish: true,
  ));

  // Delete recipe
  await mockDb.deleteRecipe(recipe.id);

  // Attempt to load meal
  await tester.pumpWidget(/*...*/);

  // Should handle gracefully (not crash)
  // Should show error or prompt to fix
  EdgeCaseTestHelpers.verifyErrorDisplayed(
    tester,
    expectedError: 'Recipe no longer exists',
  );
});
```

### Transaction Consistency

```dart
testWidgets('rolls back transaction on error', (tester) async {
  final mockDb = TestSetup.setupMockDatabase();

  // Get initial state
  final initialRecipeCount = mockDb.recipes.length;

  // Inject error mid-transaction
  ErrorInjectionHelpers.injectDatabaseError(
    mockDb,
    ErrorType.insertFailed,
    operation: 'insertRecipeIngredient',
  );

  // Attempt to create recipe with ingredients
  try {
    await service.createRecipeWithIngredients(recipe, ingredients);
  } catch (e) {
    // Expected error
  }

  // Verify no partial data saved
  expect(mockDb.recipes.length, equals(initialRecipeCount),
      reason: 'Recipe should not be saved if ingredient insert fails');
});
```

### Concurrent Modification Handling

```dart
testWidgets('detects concurrent modification', (tester) async {
  final mockDb = TestSetup.setupMockDatabase();

  // User A starts editing recipe
  final recipe = await mockDb.getRecipe('recipe-1');

  // User B updates recipe
  final updatedRecipe = recipe.copyWith(name: 'Updated by User B');
  await mockDb.updateRecipe(updatedRecipe);

  // User A tries to save
  final userARecipe = recipe.copyWith(name: 'Updated by User A');
  // Should detect conflict or use last-write-wins
  // Verify behavior matches expected strategy
});
```

### Cache Consistency

```dart
testWidgets('invalidates cache after update', (tester) async {
  final service = RecommendationService(mockDb);

  // Get recommendations (populates cache)
  final recommendations1 = await service.getRecommendations();

  // Update recipe that affects recommendations
  await mockDb.updateRecipe(recipe);

  // Get recommendations again
  final recommendations2 = await service.getRecommendations();

  // Should reflect updated data
  expect(recommendations1, isNot(equals(recommendations2)),
      reason: 'Cache should be invalidated after update');
});
```

## Key Assertions

- ✅ No orphaned records in database
- ✅ Foreign key constraints are enforced
- ✅ Transactions rollback completely on error
- ✅ No partial updates occur
- ✅ Cache invalidated when data changes
- ✅ Concurrent modifications handled correctly
- ✅ UI state reflects actual database state

## Database Consistency Checks

```dart
// Verify no orphaned records
void verifyNoOrphanedRecords(MockDatabaseHelper mockDb) {
  // Check all meals have valid recipes
  for (final meal in mockDb.meals.values) {
    final mealRecipes = mockDb.getMealRecipesForMeal(meal.id);
    for (final mealRecipe in mealRecipes) {
      expect(
        mockDb.recipes.containsKey(mealRecipe.recipeId),
        isTrue,
        reason: 'Meal ${meal.id} references non-existent recipe ${mealRecipe.recipeId}',
      );
    }
  }

  // Check all recipe ingredients have valid ingredients
  for (final recipeIngredient in mockDb.recipeIngredients) {
    expect(
      mockDb.ingredients.containsKey(recipeIngredient.ingredientId),
      isTrue,
      reason: 'Recipe ingredient references non-existent ingredient',
    );
  }
}
```

## Recovery Path Helpers

```dart
// Verify data consistency after recovery
RecoveryPathHelpers.verifyDataConsistency(
  mockDb,
  expectedRecipeCount: 5,
  expectedMealCount: 3,
  expectedIngredientCount: 20,
);
```

## Related Documentation

- [Edge Case Catalog](../../../docs/EDGE_CASE_CATALOG.md#data-integrity)
- [ErrorInjectionHelpers](../../helpers/error_injection_helpers.dart)
- [EdgeCaseTestHelpers](../../helpers/edge_case_test_helpers.dart)
