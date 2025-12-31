<!-- markdownlint-disable -->
# Edge Case Testing Guide

**Version**: 1.0
**Created**: 2025-12-30
**Issue**: #39 - Edge Case Test Suite
**Milestone**: 0.1.3

## Overview

This guide provides comprehensive instructions for identifying, implementing, and maintaining edge case tests in the Gastrobrain application. It complements the [EDGE_CASE_CATALOG.md](EDGE_CASE_CATALOG.md) which catalogs what to test, while this guide explains how to test it.

## Table of Contents

1. [Edge Case Identification Process](#edge-case-identification-process)
2. [Test File Templates](#test-file-templates)
3. [Using EdgeCaseTestHelpers](#using-edgecasetesthelpers)
4. [Error Injection Techniques](#error-injection-techniques)
5. [Boundary Value Testing](#boundary-value-testing)
6. [Troubleshooting](#troubleshooting)
7. [Examples](#examples)

---

## Edge Case Identification Process

### Step 1: Identify Edge Case Categories

For any new feature, consider these categories:

#### 1. **Empty States**
- What happens with no data?
- First-time user scenarios
- After deletion scenarios

**Questions to ask:**
- What if the database is empty?
- What if a search returns no results?
- What if a list has zero items?

#### 2. **Boundary Conditions**
- Minimum values (0, 1)
- Maximum values (999, max int)
- Just outside valid range (-1, 1000)

**Questions to ask:**
- What are the numeric limits?
- How long can text fields be?
- How many items can a collection hold?

#### 3. **Error Scenarios**
- Database failures
- Network errors
- Validation failures

**Questions to ask:**
- What if the database is unavailable?
- What if data is corrupted?
- What if user input is invalid?

#### 4. **Interaction Patterns**
- Rapid taps
- Concurrent actions
- Unexpected navigation

**Questions to ask:**
- What if the user taps a button 10 times?
- What if they navigate away during a save?
- What if they press back during loading?

### Step 2: Prioritize Edge Cases

Use the priority system:

- **🔴 CRITICAL**: Data loss or crashes
- **🟠 HIGH**: Significant UX impact
- **🟡 MEDIUM**: Edge cases users may encounter
- **🟢 LOW**: Rare scenarios

### Step 3: Document in Catalog

Add to `docs/EDGE_CASE_CATALOG.md`:

```markdown
| Edge Case | Priority | Status | Test Location | Notes |
|-----------|----------|--------|---------------|-------|
| Feature with empty data | 🟠 HIGH | ⏳ Planned | Phase X.Y | Description |
```

---

## Test File Templates

### Template 1: Empty State Tests

```dart
// test/edge_cases/empty_states/feature_empty_state_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/screens/feature_screen.dart';
import 'package:gastrobrain/core/di/providers/database_provider.dart';
import '../../mocks/mock_database_helper.dart';
import '../../helpers/edge_case_test_helpers.dart';

/// Tests for [FeatureScreen] empty state handling.
///
/// Verifies that the application handles the empty state gracefully when:
/// - No data exists in the database
/// - Search/filter returns no results
/// - First-time user scenario
void main() {
  group('Feature - Empty States', () {
    late MockDatabaseHelper mockDbHelper;

    setUp(() {
      mockDbHelper = MockDatabaseHelper();
      DatabaseProvider().setDatabaseHelper(mockDbHelper);
    });

    tearDown(() {
      mockDbHelper.resetAllData();
    });

    testWidgets('shows empty state when no data exists',
        (WidgetTester tester) async {
      // Setup: Empty database (mockDbHelper has no data by default)
      expect(mockDbHelper.items.isEmpty, isTrue);

      // Build the screen
      await tester.pumpWidget(buildFeatureScreen());
      await tester.pumpAndSettle();

      // Verify empty state
      EdgeCaseTestHelpers.verifyEmptyState(
        tester,
        expectedMessage: 'No items found',
      );
    });
  });
}
```

### Template 2: Boundary Condition Tests

```dart
// test/edge_cases/boundary_conditions/feature_boundary_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/feature.dart';
import '../../fixtures/boundary_fixtures.dart';

/// Tests for [Feature] boundary conditions.
///
/// Verifies that the model handles extreme values correctly:
/// - Minimum/maximum numeric values
/// - Very long text
/// - Empty/null values
void main() {
  group('Feature - Boundary Conditions', () {
    test('handles zero value correctly', () {
      final feature = Feature(
        id: 'test',
        value: BoundaryValues.zero,
      );

      expect(feature.value, equals(0));
      expect(() => feature.toMap(), returnsNormally);
    });

    test('handles very long text without overflow', () {
      final feature = Feature(
        id: 'test',
        description: BoundaryValues.veryLongText,
      );

      expect(feature.description.length, greaterThan(1000));
      expect(() => feature.toMap(), returnsNormally);
    });
  });
}
```

### Template 3: Error Scenario Tests

```dart
// test/edge_cases/error_scenarios/feature_errors_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/services/feature_service.dart';
import '../../mocks/mock_database_helper.dart';
import '../../helpers/error_injection_helpers.dart';

/// Tests for [FeatureService] error handling.
///
/// Verifies that the service handles errors gracefully:
/// - Database failures
/// - Validation errors
/// - Recovery paths
void main() {
  group('Feature Service - Error Scenarios', () {
    late MockDatabaseHelper mockDbHelper;
    late FeatureService service;

    setUp(() {
      mockDbHelper = MockDatabaseHelper();
      service = FeatureService(mockDbHelper);
    });

    tearDown(() {
      ErrorInjectionHelpers.resetErrorInjection(mockDbHelper);
      mockDbHelper.resetAllData();
    });

    test('handles database failure gracefully', () async {
      // Inject error
      ErrorInjectionHelpers.injectDatabaseError(
        mockDbHelper,
        ErrorType.queryFailed,
      );

      // Attempt operation
      expect(
        () => service.getItems(),
        throwsA(isA<DatabaseException>()),
      );

      // Verify no side effects
      expect(mockDbHelper.dataUnchanged, isTrue);
    });
  });
}
```

---

## Using EdgeCaseTestHelpers

The `EdgeCaseTestHelpers` class provides utilities for common edge case testing patterns.

### Available Methods

#### `verifyEmptyState()`

Verifies that an empty state is displayed correctly.

```dart
EdgeCaseTestHelpers.verifyEmptyState(
  tester,
  expectedMessage: 'No recipes found',
  iconMatcher: Icons.restaurant, // Optional
);
```

#### `fillFieldWithBoundaryValue()`

Fills a form field with a boundary value for testing.

```dart
await EdgeCaseTestHelpers.fillFieldWithBoundaryValue(
  tester,
  fieldLabel: 'Servings',
  boundaryType: BoundaryType.zero,
);
```

#### `triggerFormValidation()`

Triggers form validation by attempting to submit.

```dart
await EdgeCaseTestHelpers.triggerFormValidation(
  tester,
  submitButtonText: 'Save',
);
```

#### `verifyValidationError()`

Verifies that a validation error is displayed.

```dart
EdgeCaseTestHelpers.verifyValidationError(
  tester,
  expectedError: 'Servings must be at least 1',
);
```

#### `verifyErrorDisplayed()`

Verifies that an error message is shown to the user.

```dart
EdgeCaseTestHelpers.verifyErrorDisplayed(
  tester,
  expectedError: 'Failed to save recipe',
);
```

#### `verifyRecoveryPath()`

Verifies that a recovery option (like Retry) is available.

```dart
EdgeCaseTestHelpers.verifyRecoveryPath(
  tester,
  recoveryButtonText: 'Retry',
);
```

### BoundaryValues Fixture

Use predefined boundary values from `BoundaryValues`:

```dart
import '../../fixtures/boundary_fixtures.dart';

// Numeric boundaries
BoundaryValues.zero              // 0
BoundaryValues.one               // 1
BoundaryValues.maxInt            // 2^63 - 1
BoundaryValues.minusOne          // -1

// Text boundaries
BoundaryValues.emptyString       // ''
BoundaryValues.veryLongText      // 1000+ characters
BoundaryValues.extremelyLongText // 10000+ characters
BoundaryValues.specialCharacters // HTML/SQL chars

// Date boundaries
BoundaryValues.veryOldDate       // Year 2000
BoundaryValues.futureDate        // 10 years from now

// Collections
BoundaryValues.emptyList         // []
BoundaryValues.largeList         // 100+ items
```

---

## Error Injection Techniques

### ErrorInjectionHelpers

Use `ErrorInjectionHelpers` to simulate errors in tests.

#### Inject Database Errors

```dart
import '../../helpers/error_injection_helpers.dart';

ErrorInjectionHelpers.injectDatabaseError(
  mockDbHelper,
  ErrorType.connectionFailed,
);

// Available error types:
// - ErrorType.connectionFailed
// - ErrorType.queryFailed
// - ErrorType.insertFailed
// - ErrorType.updateFailed
// - ErrorType.deleteFailed
// - ErrorType.locked
```

#### Inject Validation Errors

```dart
ErrorInjectionHelpers.injectValidationError(
  mockDbHelper,
  field: 'name',
  errorType: 'required',
);
```

#### Reset After Tests

**CRITICAL**: Always reset error injection in `tearDown()`:

```dart
tearDown(() {
  ErrorInjectionHelpers.resetErrorInjection(mockDbHelper);
  mockDbHelper.resetAllData();
});
```

### Testing Error Recovery

```dart
test('recovers from database error after retry', () async {
  // Inject error for first attempt
  ErrorInjectionHelpers.injectDatabaseError(
    mockDbHelper,
    ErrorType.queryFailed,
  );

  // First attempt fails
  expect(() => service.getData(), throwsException);

  // Reset error (simulating recovery)
  ErrorInjectionHelpers.resetErrorInjection(mockDbHelper);

  // Retry succeeds
  final result = await service.getData();
  expect(result, isNotNull);
});
```

---

## Boundary Value Testing

### Numeric Boundaries

Test these values for all numeric fields:

```dart
group('Servings Boundaries', () {
  test('rejects zero', () {
    expect(() => Recipe(servings: 0), throwsException);
  });

  test('accepts minimum (1)', () {
    final recipe = Recipe(servings: 1);
    expect(recipe.servings, equals(1));
  });

  test('accepts high values (999)', () {
    final recipe = Recipe(servings: 999);
    expect(recipe.servings, equals(999));
  });

  test('handles very large values', () {
    final recipe = Recipe(servings: 50000);
    expect(recipe.servings, equals(50000));
  });
});
```

### Text Boundaries

Test these scenarios for text fields:

```dart
group('Name Boundaries', () {
  test('rejects empty string', () {
    expect(() => Recipe(name: ''), throwsException);
  });

  test('accepts single character', () {
    final recipe = Recipe(name: 'A');
    expect(recipe.name, equals('A'));
  });

  test('handles very long names', () {
    final recipe = Recipe(name: BoundaryValues.veryLongText);
    expect(recipe.name.length, greaterThan(1000));
  });
});
```

### Collection Boundaries

Test these scenarios for collections:

```dart
group('Ingredient List Boundaries', () {
  test('allows zero ingredients', () {
    final recipe = Recipe(ingredients: []);
    expect(recipe.ingredients, isEmpty);
  });

  test('handles 100+ ingredients', () {
    final ingredients = List.generate(150, (i) => Ingredient(name: 'Item $i'));
    final recipe = Recipe(ingredients: ingredients);
    expect(recipe.ingredients.length, equals(150));
  });
});
```

---

## Troubleshooting

### Common Issues

#### 1. Test Fails: "Expected empty state message not found"

**Cause**: Empty state UI doesn't match expected text.

**Solution**:
```dart
// Don't hardcode exact text
EdgeCaseTestHelpers.verifyEmptyState(
  tester,
  expectedMessage: 'No', // Partial match
);

// Or check multiple possibilities
expect(
  find.textContaining('No').evaluate().isNotEmpty ||
  find.textContaining('Empty').evaluate().isNotEmpty,
  isTrue,
);
```

#### 2. Test Fails: "Error injection not working"

**Cause**: Forgot to reset error injection.

**Solution**:
```dart
tearDown(() {
  ErrorInjectionHelpers.resetErrorInjection(mockDbHelper); // ← Add this
  mockDbHelper.resetAllData();
});
```

#### 3. Test Fails: "Widget overflow"

**Cause**: Long text causing UI overflow.

**Solution**:
```dart
// Use Text with overflow handling
Text(
  longText,
  overflow: TextOverflow.ellipsis,
  maxLines: 3,
)

// Test verifies no exception
expect(tester.takeException(), isNull);
```

#### 4. MockDatabaseHelper Doesn't Support Operation

**Cause**: MockDatabaseHelper missing method implementation.

**Solution**:
- Check if method exists in MockDatabaseHelper
- Add implementation if missing
- Document limitation in test comments
- Use real database for integration test if needed

---

## Examples

### Example 1: Empty State with Search

```dart
testWidgets('shows empty state when search returns no results',
    (WidgetTester tester) async {
  // Add some recipes
  await mockDbHelper.insertRecipe(Recipe(name: 'Pasta'));
  await mockDbHelper.insertRecipe(Recipe(name: 'Pizza'));

  await tester.pumpWidget(buildRecipeListScreen());
  await tester.pumpAndSettle();

  // Search for non-existent recipe
  await tester.enterText(find.byType(TextField), 'Tacos');
  await tester.pumpAndSettle();

  // Verify empty search result message
  EdgeCaseTestHelpers.verifyEmptyState(
    tester,
    expectedMessage: 'No recipes match',
  );
});
```

### Example 2: Boundary with Form Validation

```dart
testWidgets('validates servings minimum value',
    (WidgetTester tester) async {
  await tester.pumpWidget(buildRecipeForm());
  await tester.pumpAndSettle();

  // Try to enter zero servings
  await EdgeCaseTestHelpers.fillFieldWithBoundaryValue(
    tester,
    fieldLabel: 'Servings',
    boundaryType: BoundaryType.zero,
  );

  // Attempt submit
  await EdgeCaseTestHelpers.triggerFormValidation(tester, submitButtonText: 'Save');

  // Verify validation error
  EdgeCaseTestHelpers.verifyValidationError(
    tester,
    expectedError: 'must be at least 1',
  );
});
```

### Example 3: Error Recovery

```dart
test('retries after database error', () async {
  // Simulate database failure
  ErrorInjectionHelpers.injectDatabaseError(
    mockDbHelper,
    ErrorType.queryFailed,
  );

  // First attempt fails
  await expectLater(
    service.getRecipes(),
    throwsA(isA<DatabaseException>()),
  );

  // Simulate recovery
  ErrorInjectionHelpers.resetErrorInjection(mockDbHelper);

  // Retry succeeds
  final recipes = await service.getRecipes();
  expect(recipes, isNotNull);
  expect(recipes, isEmpty); // No recipes in mock DB
});
```

### Example 4: Large Dataset Performance

```dart
testWidgets('handles 1000+ recipes without performance issues',
    (WidgetTester tester) async {
  // Create 1500 recipes
  for (int i = 0; i < 1500; i++) {
    await mockDbHelper.insertRecipe(
      Recipe(id: 'recipe-$i', name: 'Recipe $i'),
    );
  }

  // Build screen
  await tester.pumpWidget(buildRecipeListScreen());
  await tester.pumpAndSettle();

  // Verify screen renders
  expect(find.byType(RecipeListScreen), findsOneWidget);

  // Verify no performance-related crashes
  expect(tester.takeException(), isNull);
});
```

---

## Best Practices

### 1. Test One Edge Case at a Time

```dart
// ❌ Bad: Testing multiple edge cases in one test
test('handles all edge cases', () {
  expect(Recipe(servings: 0), throwsException);
  expect(Recipe(name: ''), throwsException);
  expect(Recipe(ingredients: []), isNotNull);
});

// ✅ Good: Separate tests
test('rejects zero servings', () {
  expect(() => Recipe(servings: 0), throwsException);
});

test('rejects empty name', () {
  expect(() => Recipe(name: ''), throwsException);
});
```

### 2. Use Descriptive Test Names

```dart
// ❌ Bad
test('test servings', () { ... });

// ✅ Good
test('rejects servings less than 1', () { ... });
test('accepts servings up to 999', () { ... });
```

### 3. Document Assumptions

```dart
test('allows recipe with no ingredients', () {
  // ASSUMPTION: Business rule allows recipes without ingredients
  // This is intentional for "placeholder" recipes
  final recipe = Recipe(ingredients: []);
  expect(recipe.ingredients, isEmpty);
});
```

### 4. Test Negative Cases

```dart
// Test both what should work AND what shouldn't
test('accepts valid difficulty (1-5)', () {
  for (int diff = 1; diff <= 5; diff++) {
    expect(Recipe(difficulty: diff), isNotNull);
  }
});

test('rejects difficulty outside range', () {
  expect(() => Recipe(difficulty: 0), throwsException);
  expect(() => Recipe(difficulty: 6), throwsException);
});
```

### 5. Clean Up After Tests

```dart
tearDown(() {
  // ALWAYS reset state
  ErrorInjectionHelpers.resetErrorInjection(mockDbHelper);
  mockDbHelper.resetAllData();
});
```

---

## Quick Reference Card

| Category | Helper Method | Usage |
|----------|---------------|-------|
| Empty State | `EdgeCaseTestHelpers.verifyEmptyState()` | Verify empty UI displayed |
| Boundary | `BoundaryValues.*` | Use predefined extreme values |
| Validation | `EdgeCaseTestHelpers.verifyValidationError()` | Check validation messages |
| Errors | `ErrorInjectionHelpers.injectDatabaseError()` | Simulate database failures |
| Recovery | `EdgeCaseTestHelpers.verifyRecoveryPath()` | Check retry/cancel options |
| Performance | Large dataset + `takeException()` | Verify no crashes |

---

## Additional Resources

- **Edge Case Catalog**: `docs/EDGE_CASE_CATALOG.md` - Complete list of edge cases
- **Dialog Testing Guide**: `docs/DIALOG_TESTING_GUIDE.md` - Dialog-specific patterns
- **Test Helpers Source**: `test/helpers/edge_case_test_helpers.dart`
- **Boundary Fixtures**: `test/fixtures/boundary_fixtures.dart`
- **Error Injection**: `test/helpers/error_injection_helpers.dart`

---

**Document Version**: 1.0
**Last Updated**: 2025-12-30
**Maintained By**: Issue #39 Team
