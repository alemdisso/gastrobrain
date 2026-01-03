# MockDatabaseHelper Error Simulation Guide

This guide documents the error simulation capabilities of `MockDatabaseHelper` and provides best practices for testing error handling in dialogs and screens.

## Overview

`MockDatabaseHelper` provides comprehensive error simulation support for testing how your code handles database failures. This allows you to write robust tests that verify error handling, user feedback, and data integrity when database operations fail.

## How Error Simulation Works

The mock database uses a simple, consistent pattern for error injection:

```dart
// Configure the mock to fail on the next operation
mockDb.failOnOperation('methodName');

// The next call to that method will throw an exception
await mockDb.methodName(); // Throws Exception('Simulated database error')

// Error simulation is automatically reset after throwing
await mockDb.methodName(); // Succeeds normally
```

### Key Features

- **Operation-specific errors**: Target specific database methods
- **Custom exceptions**: Provide your own exception types
- **Auto-reset**: Error simulation automatically resets after throwing
- **Manual reset**: Use `resetErrorSimulation()` to clear state between tests

## Basic Usage

### Simple Error Injection

```dart
testWidgets('handles database error gracefully', (tester) async {
  final mockDb = TestSetup.setupMockDatabase();

  // Configure mock to fail on next getAllIngredients call
  mockDb.failOnOperation('getAllIngredients');

  await tester.pumpWidget(MyApp(databaseHelper: mockDb));

  // The widget attempts to load ingredients and should handle the error
  await tester.pump();

  // Verify error message is displayed
  expect(find.text('Failed to load ingredients'), findsOneWidget);
});
```

### Custom Exception

```dart
testWidgets('handles validation error specifically', (tester) async {
  final mockDb = TestSetup.setupMockDatabase();

  // Provide a custom exception
  mockDb.failOnOperation(
    'insertIngredient',
    exception: ValidationException('Name is required'),
  );

  // ... test code ...
});
```

### Manual Reset

```dart
test('can reset error simulation', () async {
  final mockDb = MockDatabaseHelper();

  mockDb.failOnOperation('getRecipe');

  // Decide not to test error case
  mockDb.resetErrorSimulation();

  // Operation now succeeds
  final recipe = await mockDb.getRecipe('123'); // Works normally
});
```

## Supported Methods

The following methods support error simulation via `failOnOperation()`:

### Recipe Operations

| Method | Category | Added | Used By |
|--------|----------|-------|---------|
| `insertRecipe()` | Write | Existing | Recipe creation dialogs |
| `getRecipe()` | Read | Issue #244 | Recipe edit screens |
| `getAllRecipes()` | Read | Existing | Recipe list screens |
| `getRecipesWithSortAndFilter()` | Read | Issue #244 | Recipe filtering |
| `updateRecipe()` | Write | Existing | Recipe edit dialogs |
| `deleteRecipe()` | Write | Existing | Recipe deletion |

### Meal Operations

| Method | Category | Added | Used By |
|--------|----------|-------|---------|
| `insertMeal()` | Write | Existing | Meal recording dialogs |
| `getMeal()` | Read | Existing | Meal detail screens |
| `getRecentMeals()` | Read | Issue #244 | Meal history screens |
| `getAllMeals()` | Read | Issue #244 | Meal history screens |
| `getMealsForRecipe()` | Read | Existing | Recipe statistics |
| `updateMeal()` | Write | Existing | Meal edit dialogs |
| `deleteMeal()` | Write | Issue #244 (refactored) | Meal deletion |

### MealRecipe Operations (Junction Table)

| Method | Category | Added | Used By |
|--------|----------|-------|---------|
| `insertMealRecipe()` | Write | Existing | Multi-recipe meal recording |
| `getMealRecipesForMeal()` | Read | Issue #244 | Multi-recipe meal handling |

### Ingredient Operations

| Method | Category | Added | Used By |
|--------|----------|-------|---------|
| `insertIngredient()` | Write | Existing | Add ingredient dialog |
| `getAllIngredients()` | Read | Issue #244 | Ingredient screens, dialogs |
| `updateIngredient()` | Write | Existing | Edit ingredient dialog |
| `deleteIngredient()` | Write | Existing | Ingredient deletion |

### Meal Plan Operations

| Method | Category | Added | Used By |
|--------|----------|-------|---------|
| `getMealPlan()` | Read | Issue #244 | Weekly plan screens |
| `getMealPlanForWeek()` | Read | Issue #244 | Weekly plan screens |
| `getMealPlanItemsForDate()` | Read | Issue #244 | Daily plan screens |

## Testing Patterns

### Dialog Error Handling

When testing dialogs that perform database operations:

```dart
testWidgets('shows error message on save failure', (tester) async {
  final mockDb = TestSetup.setupMockDatabase();

  // Inject error
  mockDb.failOnOperation('insertIngredient');

  // Open dialog
  final result = await DialogTestHelpers.openDialogAndCapture<Ingredient>(
    tester,
    dialogBuilder: (context) => AddIngredientDialog(databaseHelper: mockDb),
  );

  // Fill form
  await DialogTestHelpers.fillDialogForm(tester, {
    'Name': 'Tomato',
    'Category': 'Vegetable',
  });

  // Attempt save
  await DialogTestHelpers.tapDialogButton(tester, 'Save');
  await tester.pump();

  // Verify error handling
  expect(find.text('Failed to save ingredient'), findsOneWidget);
  expect(result.hasValue, isFalse); // Dialog should not return value
});
```

### Verify Data Integrity

Ensure database remains unchanged when operations fail:

```dart
testWidgets('does not modify data on error', (tester) async {
  final mockDb = TestSetup.setupMockDatabase();
  final initialCount = mockDb.ingredients.length;

  mockDb.failOnOperation('insertIngredient');

  // Attempt operation that fails
  try {
    await mockDb.insertIngredient(testIngredient);
  } catch (e) {
    // Expected
  }

  // Verify no data was added
  expect(mockDb.ingredients.length, equals(initialCount));
});
```

### Error Recovery Testing

Test that users can retry after an error:

```dart
testWidgets('allows retry after error', (tester) async {
  final mockDb = TestSetup.setupMockDatabase();

  // First attempt fails
  mockDb.failOnOperation('insertIngredient');

  await tester.pumpWidget(MyApp(databaseHelper: mockDb));

  // Fill form and save
  await tester.enterText(find.byKey(Key('nameField')), 'Tomato');
  await tester.tap(find.text('Save'));
  await tester.pump();

  // Error is shown
  expect(find.text('Failed to save'), findsOneWidget);

  // Tap retry button (error simulation auto-reset after first throw)
  await tester.tap(find.text('Retry'));
  await tester.pump();

  // Should succeed
  expect(find.text('Saved successfully'), findsOneWidget);
});
```

### Testing Multiple Operations

When a widget performs multiple database operations, you can target specific ones:

```dart
testWidgets('handles error in second operation', (tester) async {
  final mockDb = TestSetup.setupMockDatabase();

  // Add test data for first operation to succeed
  mockDb.recipes.addAll(/* test recipes */);

  // Make second operation fail
  mockDb.failOnOperation('getMealRecipesForMeal');

  await tester.pumpWidget(MyApp(databaseHelper: mockDb));

  // First operation (getAllRecipes) succeeds
  await tester.pump();
  expect(find.text('Recipes loaded'), findsOneWidget);

  // Second operation (getMealRecipesForMeal) fails
  await tester.tap(find.text('View meal details'));
  await tester.pump();
  expect(find.text('Failed to load meal details'), findsOneWidget);
});
```

## Best Practices

### 1. Test All Error Paths

Every database operation should have error handling tests:

```dart
// ✅ GOOD: Test both success and error cases
testWidgets('saves ingredient successfully', ...);
testWidgets('shows error when save fails', ...);
testWidgets('allows retry after error', ...);

// ❌ BAD: Only testing happy path
testWidgets('saves ingredient successfully', ...);
```

### 2. Reset Between Tests

Always use `setUp()` to ensure clean state:

```dart
setUp(() {
  mockDb = TestSetup.setupMockDatabase();
  // Error simulation is automatically clean
});
```

### 3. Verify No Side Effects

When operations fail, verify database remains unchanged:

```dart
testWidgets('no data added on error', (tester) async {
  final initialData = Map.from(mockDb.ingredients);

  mockDb.failOnOperation('insertIngredient');

  // Attempt operation...

  expect(mockDb.ingredients, equals(initialData));
});
```

### 4. Test User Feedback

Verify users receive clear error messages:

```dart
// ✅ GOOD: Specific, actionable message
expect(find.text('Failed to save ingredient. Please try again.'), findsOneWidget);

// ❌ BAD: Generic or missing message
expect(find.text('Error'), findsOneWidget);
```

### 5. Use Error Simulation for Edge Cases

Don't manually create error conditions when error simulation is available:

```dart
// ✅ GOOD: Use error simulation
mockDb.failOnOperation('getAllIngredients');

// ❌ BAD: Trying to create error conditions manually
mockDb.setDatabase(null); // Fragile and unclear
```

## Troubleshooting

### Error Simulation Not Working

**Problem**: Operation succeeds when it should fail.

**Solution**: Check the operation name matches exactly:

```dart
// ❌ Wrong: Method name mismatch
mockDb.failOnOperation('getIngredients'); // Method is 'getAllIngredients'

// ✅ Correct: Exact method name
mockDb.failOnOperation('getAllIngredients');
```

### Error Persists Across Tests

**Problem**: Error simulation affects subsequent tests.

**Solution**: Error simulation auto-resets after throwing. If not throwing, manually reset:

```dart
tearDown(() {
  mockDb.resetErrorSimulation();
});
```

### Can't Test Specific Error Type

**Problem**: Need to test handling of `ValidationException` vs `Exception`.

**Solution**: Use the `exception` parameter:

```dart
mockDb.failOnOperation(
  'insertIngredient',
  exception: ValidationException('Invalid data'),
);
```

## Legacy Error Simulation

### `shouldThrowOnDelete` (Deprecated)

The `deleteMeal()` method previously used a `shouldThrowOnDelete` flag. This is still supported for backwards compatibility but new code should use `failOnOperation()`:

```dart
// ❌ Legacy pattern (still works)
mockDb.shouldThrowOnDelete = true;
await mockDb.deleteMeal('123'); // Throws

// ✅ Modern pattern (recommended)
mockDb.failOnOperation('deleteMeal');
await mockDb.deleteMeal('123'); // Throws
```

## Related Documentation

- [Dialog Testing Guide](./DIALOG_TESTING_GUIDE.md) - Comprehensive dialog testing patterns
- [Edge Case Testing Guide](./EDGE_CASE_TESTING_GUIDE.md) - Testing edge cases and boundary conditions
- [Edge Case Catalog](./EDGE_CASE_CATALOG.md) - Complete catalog of edge cases to test

## Examples in Codebase

See these test files for real-world examples:

- `test/widgets/dialogs/add_ingredient_dialog_test.dart` - Dialog error handling
- `test/edge_cases/error_scenarios/` - Error scenario tests
- `test/regression/dialog_regression_test.dart` - Error-related regression tests

## Summary

Error simulation in `MockDatabaseHelper` provides a powerful, consistent way to test error handling across your application. By following the patterns and best practices in this guide, you can ensure your app handles database failures gracefully and provides a good user experience even when things go wrong.

**Key Takeaways:**
- Use `failOnOperation('methodName')` for consistent error injection
- Test all error paths, not just happy paths
- Verify data integrity when operations fail
- Provide clear error messages and recovery options to users
- Use error simulation for 22 supported database methods (and growing)
