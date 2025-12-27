<!-- markdownlint-disable -->
# Dialog Testing Guide

**Version**: 1.0
**Last Updated**: 2025-12-27
**Related Issue**: #38

## Overview

This guide covers best practices and patterns for testing dialog widgets in the Gastrobrain app. Proper dialog testing ensures that user interactions through dialogs work correctly, data is properly captured and validated, and critical bugs (like the controller disposal crash) are prevented.

## Table of Contents

1. [Why Test Dialogs](#why-test-dialogs)
2. [Testing Infrastructure](#testing-infrastructure)
3. [Basic Dialog Testing Pattern](#basic-dialog-testing-pattern)
4. [Common Test Scenarios](#common-test-scenarios)
5. [Advanced Patterns](#advanced-patterns)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

---

## Why Test Dialogs

Dialog widgets are critical user interaction points that:
- Capture and validate user input
- Handle state management (often with controllers)
- Return data to calling screens
- Can cause crashes if not properly implemented (e.g., controller disposal issues)

**Critical Regression Test**: The controller disposal crash (commit 07058a2) highlighted the importance of testing dialog lifecycle, especially cancellation scenarios.

### What to Test

For each dialog, verify:
1. **Return Values**: Dialog returns correct data structure on save
2. **Cancellation**: Dialog returns null when cancelled (no side effects)
3. **Input Validation**: Invalid inputs are rejected with proper error messages
4. **State Management**: Controllers and state are properly disposed
5. **Error Handling**: Database errors and async failures are handled gracefully

---

## Testing Infrastructure

### Available Tools

#### 1. DialogTestHelpers (`test/helpers/dialog_test_helpers.dart`)

Reusable utilities for common dialog testing operations.

**Key Methods**:
```dart
// Open dialog and capture return value
DialogTestHelpers.openDialogAndCapture<T>(...)

// Tap a dialog button
DialogTestHelpers.tapDialogButton(tester, 'Save')

// Fill text fields
DialogTestHelpers.fillTextField(tester, 'Notes', 'value')

// Verify dialog closed
DialogTestHelpers.verifyDialogClosed<MyDialog>()

// Verify return value
DialogTestHelpers.verifyDialogReturnValue(result, expectedValue)

// Verify cancellation
DialogTestHelpers.verifyDialogCancelled(result)

// Verify no database side effects
DialogTestHelpers.verifyNoSideEffects(mockDbHelper, beforeAction: ...)
```

#### 2. DialogFixtures (`test/test_utils/dialog_fixtures.dart`)

Pre-configured test data for consistent testing.

**Available Fixtures**:
```dart
// Recipes
DialogFixtures.createTestRecipe()
DialogFixtures.createPrimaryRecipe()
DialogFixtures.createSideRecipe()

// Meals
DialogFixtures.createTestMeal()
DialogFixtures.createEditableMeal()
DialogFixtures.createUnsuccessfulMeal()

// Ingredients
DialogFixtures.createVegetableIngredient()
DialogFixtures.createProteinIngredient()
DialogFixtures.createMultipleIngredients()

// Validation data
DialogFixtures.invalidServingsValues()
DialogFixtures.veryLongText(length: 1000)
```

#### 3. MockDatabaseHelper (`test/mocks/mock_database_helper.dart`)

In-memory database for isolated testing.

**Key Features**:
```dart
// Error simulation
mockDb.failOnOperation('updateMeal')
mockDb.resetErrorSimulation()

// Direct data access
mockDb.recipes  // Map<String, Recipe>
mockDb.meals    // Map<String, Meal>
mockDb.ingredients  // Map<String, Ingredient>

// Reset state
mockDb.resetAllData()
```

---

## Basic Dialog Testing Pattern

### Template

```dart
import 'package:flutter_test/flutter_test.dart';
import '../helpers/dialog_test_helpers.dart';
import '../test_utils/dialog_fixtures.dart';
import '../mocks/mock_database_helper.dart';

void main() {
  late MockDatabaseHelper mockDbHelper;

  setUp(() {
    mockDbHelper = MockDatabaseHelper();
    // Setup test data if needed
  });

  tearDown(() {
    mockDbHelper.resetAllData();
    mockDbHelper.resetErrorSimulation();
  });

  group('MyDialog', () {
    testWidgets('returns data on save', (tester) async {
      // Arrange: Open dialog and capture result
      final result = await DialogTestHelpers.openDialogAndCapture<Map<String, dynamic>>(
        tester,
        dialogBuilder: (context) => MyDialog(
          recipe: DialogFixtures.createTestRecipe(),
        ),
      );

      // Act: Fill form and save
      await DialogTestHelpers.fillTextField(tester, 'Notes', 'Test notes');
      await DialogTestHelpers.tapDialogButton(tester, 'Save');
      await tester.pumpAndSettle();

      // Assert: Verify return value
      expect(result.hasValue, isTrue);
      expect(result.value?['notes'], equals('Test notes'));
      DialogTestHelpers.verifyDialogClosed<MyDialog>();
    });

    testWidgets('returns null on cancel', (tester) async {
      // Arrange
      final result = await DialogTestHelpers.openDialogAndCapture<Map<String, dynamic>>(
        tester,
        dialogBuilder: (context) => MyDialog(
          recipe: DialogFixtures.createTestRecipe(),
        ),
      );

      // Act: Cancel dialog
      await DialogTestHelpers.tapDialogButton(tester, 'Cancel');
      await tester.pumpAndSettle();

      // Assert: Verify cancellation
      DialogTestHelpers.verifyDialogCancelled(result);
      DialogTestHelpers.verifyDialogClosed<MyDialog>();
    });
  });
}
```

---

## Common Test Scenarios

### 1. Return Value Testing

**Verify dialog returns correct data structure:**

```dart
testWidgets('returns meal data with all fields', (tester) async {
  final result = await DialogTestHelpers.openDialogAndCapture<Map<String, dynamic>>(
    tester,
    dialogBuilder: (context) => MealRecordingDialog(
      recipe: DialogFixtures.createTestRecipe(),
    ),
  );

  // Fill form
  await DialogTestHelpers.fillTextField(tester, 'Servings', '4');
  await DialogTestHelpers.fillTextField(tester, 'Notes', 'Delicious!');

  // Save
  await DialogTestHelpers.tapDialogButton(tester, 'Save');
  await tester.pumpAndSettle();

  // Verify structure
  expect(result.hasValue, isTrue);
  expect(result.value, containsPair('servings', 4));
  expect(result.value, containsPair('notes', 'Delicious!'));
  expect(result.value, contains('cookedAt'));
  expect(result.value, contains('wasSuccessful'));
});
```

### 2. Cancellation Testing (Critical!)

**Verify no side effects on cancellation:**

```dart
testWidgets('no database changes on cancel', (tester) async {
  final recipe = DialogFixtures.createTestRecipe();
  mockDbHelper.recipes[recipe.id] = recipe;

  await DialogTestHelpers.openDialogAndCapture<Map<String, dynamic>>(
    tester,
    dialogBuilder: (context) => MealRecordingDialog(recipe: recipe),
  );

  // Verify no side effects
  await DialogTestHelpers.verifyNoSideEffects(
    mockDbHelper,
    beforeAction: () async {
      await DialogTestHelpers.tapDialogButton(tester, 'Cancel');
      await tester.pumpAndSettle();
    },
  );
});
```

**Test multiple cancellation methods:**

```dart
group('cancellation methods', () {
  testWidgets('cancel button', (tester) async {
    final result = await DialogTestHelpers.openDialogAndCapture<Map>(
      tester,
      dialogBuilder: (context) => MyDialog(),
    );

    await DialogTestHelpers.tapDialogButton(tester, 'Cancel');
    await tester.pumpAndSettle();

    DialogTestHelpers.verifyDialogCancelled(result);
  });

  testWidgets('back button', (tester) async {
    final result = await DialogTestHelpers.openDialogAndCapture<Map>(
      tester,
      dialogBuilder: (context) => MyDialog(),
    );

    await DialogTestHelpers.pressBackButton(tester);
    await tester.pumpAndSettle();

    DialogTestHelpers.verifyDialogCancelled(result);
  });

  testWidgets('tap outside (barrier)', (tester) async {
    final result = await DialogTestHelpers.openDialogAndCapture<Map>(
      tester,
      dialogBuilder: (context) => MyDialog(),
    );

    await DialogTestHelpers.tapOutsideDialog(tester);
    await tester.pumpAndSettle();

    DialogTestHelpers.verifyDialogCancelled(result);
  });
});
```

### 3. Input Validation Testing

**Test boundary conditions:**

```dart
group('input validation', () {
  testWidgets('rejects invalid servings', (tester) async {
    await DialogTestHelpers.openDialog(
      tester,
      dialogBuilder: (context) => MealRecordingDialog(
        recipe: DialogFixtures.createTestRecipe(),
      ),
    );

    for (final invalidValue in DialogFixtures.invalidServingsValues()) {
      await DialogTestHelpers.fillTextField(tester, 'Servings', invalidValue);
      await tester.pump();

      // Verify error message appears
      expect(find.text('Invalid servings'), findsOneWidget);
    }
  });

  testWidgets('accepts valid servings', (tester) async {
    await DialogTestHelpers.openDialog(
      tester,
      dialogBuilder: (context) => MealRecordingDialog(
        recipe: DialogFixtures.createTestRecipe(),
      ),
    );

    for (final validValue in DialogFixtures.validServingsValues()) {
      await DialogTestHelpers.fillTextField(tester, 'Servings', validValue);
      await tester.pump();

      // Verify no error message
      expect(find.text('Invalid servings'), findsNothing);
    }
  });
});
```

### 4. Error Handling Testing

**Test database error scenarios:**

```dart
testWidgets('handles database errors gracefully', (tester) async {
  // Simulate database error
  mockDbHelper.failOnOperation('insertMeal');

  await DialogTestHelpers.openDialog(
    tester,
    dialogBuilder: (context) => MealRecordingDialog(
      recipe: DialogFixtures.createTestRecipe(),
    ),
  );

  // Fill and submit
  await DialogTestHelpers.fillTextField(tester, 'Servings', '2');
  await DialogTestHelpers.tapDialogButton(tester, 'Save');
  await tester.pumpAndSettle();

  // Verify error message shown
  expect(find.text('Error saving meal'), findsOneWidget);

  // Verify dialog remains open
  expect(find.byType(MealRecordingDialog), findsOneWidget);

  mockDbHelper.resetErrorSimulation();
});
```

---

## Advanced Patterns

### 1. Testing Dialog with Dependencies

```dart
testWidgets('dialog loads data from database', (tester) async {
  // Setup test data
  final meal = DialogFixtures.createEditableMeal();
  mockDbHelper.meals[meal.id] = meal;

  await DialogTestHelpers.openDialog(
    tester,
    dialogBuilder: (context) => EditMealRecordingDialog(
      mealId: meal.id,
      dbHelper: mockDbHelper,
    ),
  );

  await tester.pumpAndSettle();

  // Verify form pre-filled with meal data
  expect(find.text(meal.servings.toString()), findsOneWidget);
  expect(find.text(meal.notes ?? ''), findsOneWidget);
});
```

### 2. Testing Complex Forms

```dart
testWidgets('handles multi-step form', (tester) async {
  final result = await DialogTestHelpers.openDialogAndCapture<Map<String, dynamic>>(
    tester,
    dialogBuilder: (context) => AddSideDishDialog(
      primaryRecipe: DialogFixtures.createPrimaryRecipe(),
      availableRecipes: DialogFixtures.createMultipleRecipes(5),
    ),
  );

  // Fill multiple fields
  await DialogTestHelpers.fillDialogForm(tester, {
    'Servings': '4',
    'Notes': 'Test meal',
  });

  // Select from dropdown
  await tester.tap(find.text('Select Side Dish'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Rice Pilaf').last);
  await tester.pumpAndSettle();

  // Save
  await DialogTestHelpers.tapDialogButton(tester, 'Save');
  await tester.pumpAndSettle();

  // Verify all data captured
  expect(result.value?['servings'], equals(4));
  expect(result.value?['notes'], equals('Test meal'));
  expect(result.value?['sideDishId'], isNotNull);
});
```

### 3. Testing Controller Disposal (Regression)

**Critical test for controller disposal crash:**

```dart
group('controller disposal (regression for commit 07058a2)', () {
  testWidgets('safely disposes controllers on cancel', (tester) async {
    await DialogTestHelpers.openDialog(
      tester,
      dialogBuilder: (context) => MealRecordingDialog(
        recipe: DialogFixtures.createTestRecipe(),
      ),
    );

    // Interact with fields to initialize controllers
    await DialogTestHelpers.fillTextField(tester, 'Servings', '3');
    await tester.pump();

    // Cancel dialog
    await DialogTestHelpers.tapDialogButton(tester, 'Cancel');
    await tester.pumpAndSettle();

    // If controller disposal is broken, this will throw
    // No assertion needed - test passes if no crash occurs
  });

  testWidgets('handles rapid open/close cycles', (tester) async {
    for (int i = 0; i < 5; i++) {
      await DialogTestHelpers.openDialog(
        tester,
        dialogBuilder: (context) => MealRecordingDialog(
          recipe: DialogFixtures.createTestRecipe(),
        ),
      );

      await DialogTestHelpers.tapDialogButton(tester, 'Cancel');
      await tester.pumpAndSettle();
    }

    // Test passes if no crash occurs during repeated cycles
  });
});
```

---

## Best Practices

### 1. Use Fixtures for Consistency

**Good**:
```dart
final recipe = DialogFixtures.createTestRecipe(name: 'Custom Name');
```

**Avoid**:
```dart
final recipe = Recipe(
  id: 'test-id',
  name: 'Custom Name',
  desiredFrequency: FrequencyType.weekly,
  createdAt: DateTime.now(),
  // ... many more fields
);
```

### 2. Test Cancellation for Every Dialog

Every dialog MUST have cancellation tests to prevent controller disposal crashes:

```dart
testWidgets('returns null on cancel', (tester) async { ... });
testWidgets('no database side effects on cancel', (tester) async { ... });
```

### 3. Reset State Between Tests

Always reset mock state in `tearDown`:

```dart
tearDown(() {
  mockDbHelper.resetAllData();
  mockDbHelper.resetErrorSimulation();
});
```

### 4. Test Both Success and Failure Paths

```dart
group('MyDialog', () {
  group('success scenarios', () {
    testWidgets('saves valid data', ...);
  });

  group('error scenarios', () {
    testWidgets('handles database errors', ...);
    testWidgets('validates input', ...);
  });
});
```

### 5. Use Descriptive Test Names

**Good**:
```dart
testWidgets('returns meal data with servings and notes on save', ...);
testWidgets('shows error message when database insert fails', ...);
```

**Avoid**:
```dart
testWidgets('test save', ...);
testWidgets('test error', ...);
```

---

## Troubleshooting

### Common Issues

#### 1. "Dialog not found in widget tree"

**Problem**: Dialog didn't open or already closed.

**Solution**:
```dart
// Ensure you call pumpAndSettle after opening
await tester.tap(find.text('Show Dialog'));
await tester.pumpAndSettle(); // Wait for animation

// Or use DialogTestHelpers which handles this
await DialogTestHelpers.openDialog(tester, ...);
```

#### 2. "TextField not found"

**Problem**: Field label doesn't match or field not yet rendered.

**Solution**:
```dart
// Wait for dialog animation
await DialogTestHelpers.waitForDialogAnimation(tester);

// Use exact label text
await DialogTestHelpers.fillTextField(tester, 'Servings', '4');
```

#### 3. "Button tap has no effect"

**Problem**: Need to wait for async operations to complete.

**Solution**:
```dart
await DialogTestHelpers.tapDialogButton(tester, 'Save');
await tester.pumpAndSettle(); // Wait for all animations and async ops
```

#### 4. "Controller disposal error"

**Problem**: Controllers not properly disposed on dialog close.

**Solution**: Ensure dialog implementation follows this pattern:
```dart
@override
void dispose() {
  if (mounted) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.dispose();
    });
  }
  super.dispose();
}
```

---

## Examples in Codebase

### Reference Tests

- **Basic Dialog Test**: `test/widgets/dialogs/add_ingredient_dialog_test.dart`
- **Advanced Dialog Test**: (To be added in Phase 2)

### Reference Implementation

- **DialogTestHelpers**: `test/helpers/dialog_test_helpers.dart`
- **DialogFixtures**: `test/test_utils/dialog_fixtures.dart`
- **MockDatabaseHelper**: `test/mocks/mock_database_helper.dart`

---

## Checklist for New Dialog Tests

When writing tests for a new dialog, ensure you cover:

- [ ] Return value structure on save
- [ ] Returns null on cancel
- [ ] No database side effects on cancel
- [ ] Input validation (boundary conditions)
- [ ] Error handling (database failures)
- [ ] Controller disposal (cancel button)
- [ ] Controller disposal (back button)
- [ ] Controller disposal (tap outside)
- [ ] Pre-filled data loads correctly (for edit dialogs)
- [ ] All required fields are validated

---

## Related Documentation

- **Issue #38 Roadmap**: `docs/ISSUE_38_ROADMAP.md`
- **Testing Roadmap Summary**: `docs/TESTING_ROADMAP_SUMMARY.md`
- **Codebase Overview**: `docs/Gastrobrain-Codebase-Overview.md`

---

**Questions or Issues?**

If you encounter problems not covered in this guide, refer to existing tests or create a new issue in the repository.
