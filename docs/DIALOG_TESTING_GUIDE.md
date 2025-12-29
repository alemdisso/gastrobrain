<!-- markdownlint-disable -->
# Dialog Testing Guide

**Version**: 1.1
**Last Updated**: 2025-12-28 (Phase 3 learnings added)
**Related Issue**: #38
**Related Issues**: #244 (MockDB gaps), #245 (Deferred tests), #237 (DI improvements)

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

## Common Pitfalls

### 1. Forgetting to Test Cancellation

**Mistake**: Only testing the "happy path" (successful save).

**Why it's bad**: Controller disposal crashes only occur on cancellation, not on save.

**Fix**: Always include cancellation tests:
```dart
testWidgets('returns null when cancelled', (tester) async { ... });
testWidgets('safely disposes controllers on cancel', (tester) async { ... });
```

**Reference**: All 6 dialog test files include disposal tests (Phase 2.2.2).

### 2. Not Resetting Mock State Between Tests

**Mistake**: Assuming clean state without explicit reset.

**Why it's bad**: Data from previous tests can leak and cause flaky failures.

**Fix**: Always reset in setUp/tearDown:
```dart
setUp(() {
  mockDbHelper = TestSetup.setupMockDatabase();
});

tearDown(() {
  mockDbHelper.resetAllData();
  mockDbHelper.resetErrorSimulation();
});
```

### 3. Using Hardcoded Strings Instead of Localization

**Mistake**: Looking for English text in widget tree:
```dart
// ❌ WRONG - breaks in Portuguese locale
await tester.tap(find.text('Save'));
```

**Why it's bad**: Tests fail when run with different locales.

**Fix**: Use keys or localized lookups:
```dart
// ✅ CORRECT
await tester.tap(find.byKey(const Key('save_button')));

// OR use the localized text
final l10n = await AppLocalizations.delegate.load(const Locale('en'));
await tester.tap(find.text(l10n.save));
```

### 4. Not Waiting for Animations

**Mistake**: Immediately asserting after triggering action:
```dart
// ❌ WRONG
await tester.tap(find.text('Open Dialog'));
expect(find.byType(MyDialog), findsOneWidget); // Fails!
```

**Why it's bad**: Dialog animation hasn't completed.

**Fix**: Always call `pumpAndSettle`:
```dart
// ✅ CORRECT
await tester.tap(find.text('Open Dialog'));
await tester.pumpAndSettle(); // Wait for animation
expect(find.byType(MyDialog), findsOneWidget);
```

### 5. Testing Implementation Details Instead of Behavior

**Mistake**: Testing internal widget structure:
```dart
// ❌ WRONG - fragile test
expect(find.byType(TextField), findsNWidgets(5));
expect(find.byType(ElevatedButton), findsNWidgets(2));
```

**Why it's bad**: Breaks when refactoring UI without changing behavior.

**Fix**: Test user-visible behavior:
```dart
// ✅ CORRECT - tests what users see/do
expect(find.text('Servings'), findsOneWidget);
expect(find.text('Save'), findsOneWidget);
expect(find.text('Cancel'), findsOneWidget);

// Test interactions
await DialogTestHelpers.fillTextField(tester, 'Servings', '4');
await DialogTestHelpers.tapDialogButton(tester, 'Save');
expect(result.value?['servings'], equals(4));
```

### 6. Not Testing Alternative Dismissal Methods

**Mistake**: Only testing "Cancel" button, not back button or tap-outside.

**Why it's bad**: Users can dismiss dialogs multiple ways - all must be safe.

**Fix**: Test all dismissal methods (Phase 2.2.2):
```dart
testWidgets('safely disposes on back button', (tester) async {
  await DialogTestHelpers.openDialog(tester, dialogBuilder: ...);
  await DialogTestHelpers.pressBackButton(tester);
  await tester.pumpAndSettle();
  // Should not crash
});

testWidgets('safely disposes when tapping outside', (tester) async {
  await DialogTestHelpers.openDialog(tester, dialogBuilder: ...);
  await DialogTestHelpers.tapOutsideDialog(tester);
  await tester.pumpAndSettle();
  // Should not crash
});
```

### 7. Mixing Test Concerns

**Mistake**: Testing dialog logic AND screen logic in same test.

**Why it's bad**: Unclear what's being tested, hard to debug failures.

**Fix**: Separate dialog widget tests from screen integration tests:
- **Dialog tests**: Test dialog in isolation with mock dependencies
- **Screen tests**: Test screen's dialog interactions via E2E tests

### 8. Ignoring Database Side Effects

**Mistake**: Not verifying that cancellation doesn't save to database.

**Why it's bad**: Canceled operations might still persist data.

**Fix**: Verify no side effects:
```dart
testWidgets('no database side effects on cancel', (tester) async {
  final initialCount = mockDbHelper.meals.length;

  await DialogTestHelpers.openDialog(tester, dialogBuilder: ...);
  await DialogTestHelpers.fillTextField(tester, 'Servings', '4');
  await DialogTestHelpers.tapDialogButton(tester, 'Cancel');
  await tester.pumpAndSettle();

  // Verify nothing was saved
  expect(mockDbHelper.meals.length, equals(initialCount));
});
```

### 9. Not Testing Edge Cases

**Mistake**: Only testing with valid, typical data.

**Why it's bad**: Edge cases often reveal bugs.

**Fix**: Test boundaries:
```dart
testWidgets('handles empty string input', (tester) async { ... });
testWidgets('handles very long text (>1000 chars)', (tester) async { ... });
testWidgets('handles negative numbers', (tester) async { ... });
testWidgets('handles special characters in names', (tester) async { ... });
```

### 10. Assuming DI Support Without Verification

**Mistake**: Writing error simulation tests without checking if dialog supports DI.

**Why it's bad**: Test will fail if dialog creates its own DatabaseHelper.

**Fix**: Check "Known Limitations" section first:
- ✅ `AddNewIngredientDialog` - Has DI
- ✅ `AddIngredientDialog` - Has DI
- ✅ `EditMealRecordingDialog` - Has DI
- ❌ `MealRecordingDialog` - No DI (issue #237)
- ❌ `AddSideDishDialog` - Doesn't load DB directly

**See**: Issue #237 for DI improvements, Issue #245 for deferred tests.

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

### Debugging Techniques

#### Using debugDumpApp() to Inspect Widget Tree

When tests fail with "Widget not found", inspect the widget tree:

```dart
testWidgets('debug example', (tester) async {
  await tester.pumpWidget(...);
  await tester.pumpAndSettle();

  // Print entire widget tree
  debugDumpApp();

  // Or print specific finder results
  print('Found ${find.byType(TextField).evaluate().length} TextFields');
});
```

**Tip**: Run with `flutter test --verbose` to see all print output.

#### Using tester.printToConsole() for Rendered Text

Find what text is actually rendered:

```dart
testWidgets('check rendered text', (tester) async {
  await tester.pumpWidget(...);

  // Print all Text widgets
  find.byType(Text).evaluate().forEach((element) {
    final widget = element.widget as Text;
    print('Text widget: ${widget.data}');
  });
});
```

#### Using Keys to Debug Complex Layouts

Add keys during development for easier debugging:

```dart
// In dialog implementation
TextField(
  key: const Key('servings_field'),  // Add during debugging
  decoration: InputDecoration(labelText: 'Servings'),
)

// In test
expect(find.byKey(const Key('servings_field')), findsOneWidget);
```

#### Checking for Exceptions During Pump

Catch exceptions that occur during rendering:

```dart
testWidgets('detect rendering errors', (tester) async {
  await tester.pumpWidget(...);

  try {
    await tester.pumpAndSettle();
  } catch (e) {
    print('Exception during pump: $e');
    rethrow;
  }

  // Check if any exception was thrown but swallowed
  final exception = tester.takeException();
  if (exception != null) {
    print('Swallowed exception: $exception');
  }
});
```

#### Using Flutter DevTools with Tests

Run tests in debug mode and attach DevTools:

```bash
# Run test in debug mode (slower but allows DevTools)
flutter run test/widgets/my_dialog_test.dart

# Then open DevTools at the provided URL
# Use Widget Inspector to examine dialog structure
```

#### Isolating Test Failures

When multiple tests fail, isolate the problem:

```dart
// Run only one test
testWidgets('specific test', (tester) async { ... }, skip: false);

// Skip other tests temporarily
testWidgets('other test', (tester) async { ... }, skip: true);
```

Or use command line:

```bash
# Run only tests matching pattern
flutter test --plain-name "returns correct data on save"

# Run only one test file
flutter test test/widgets/meal_recording_dialog_test.dart
```

#### Checking Mock State

Debug mock database state issues:

```dart
testWidgets('debug mock state', (tester) async {
  setUp(() {
    mockDbHelper = TestSetup.setupMockDatabase();
  });

  // Print mock state
  print('Recipes in mock DB: ${mockDbHelper.recipes.length}');
  print('Ingredients in mock DB: ${mockDbHelper.ingredients.length}');

  // Verify mock configuration
  expect(mockDbHelper.recipes, isNotEmpty,
    reason: 'Mock DB should have test data');
});
```

#### Using Breakpoints in Tests

Set breakpoints in your IDE and run tests in debug mode:

```dart
testWidgets('with breakpoint', (tester) async {
  await tester.pumpWidget(...);
  await tester.pumpAndSettle();

  debugger(); // Breakpoint - execution pauses here

  // Continue stepping through test
  await tester.tap(find.text('Save'));
});
```

**VSCode**: Set breakpoint on line, run "Debug Test" from code lens
**Android Studio**: Right-click test → "Debug 'testName'"

#### Comparing Expected vs Actual Widget Trees

Use `matchesGoldenFile` for visual regression testing:

```dart
testWidgets('visual regression test', (tester) async {
  await tester.pumpWidget(...);
  await tester.pumpAndSettle();

  // Generate golden file first time
  await expectLater(
    find.byType(MealRecordingDialog),
    matchesGoldenFile('meal_recording_dialog.png'),
  );
});
```

Run with `flutter test --update-goldens` to create baseline images.

---

## Known Limitations & Workarounds

### Dependency Injection Limitations

**Issue**: Some dialogs create their own `DatabaseHelper` instance instead of accepting one via constructor.

**Impact**: Cannot test database error scenarios for these dialogs.

**Affected Dialogs**:
- `MealRecordingDialog` - Creates own DB instance
- `AddSideDishDialog` - Doesn't directly interact with DB

**Workaround**: Tests for these dialogs are deferred to issue #245, blocked by #237 (DI improvements).

**Testable Dialogs** (have DI support):
- `AddNewIngredientDialog` ✓
- `AddIngredientDialog` ✓
- `EditMealRecordingDialog` ✓

### MockDatabaseHelper Error Simulation Gaps

**Issue**: Not all `MockDatabaseHelper` methods support error simulation via `failOnOperation()`.

**Supported Operations**:
- `getAllRecipes()` ✓
- `insertIngredient()` ✓
- `updateMeal()` ✓
- `getMeal()` ✓

**Unsupported Operations**:
- `getAllIngredients()` ✗ - Issue #244

**Workaround**: Tests requiring unsupported operations are deferred to issue #245.

### Nested Dialog Testing

**Issue**: Testing workflows that open dialogs from within dialogs (e.g., adding side dishes from MealRecordingDialog).

**Impact**: Multi-step operations requiring nested dialogs cannot be fully tested.

**Workaround**: Deferred to issue #245, blocked by #237 (DI improvements).

---

## Real-World Examples from Codebase

### Example 1: Complete Return Value Test

From `test/widgets/meal_cooked_dialog_test.dart`:

```dart
testWidgets('returns correct cooking details on save',
  (WidgetTester tester) async {
  final testRecipe = DialogFixtures.createTestRecipe(
    prepTimeMinutes: 15,
    cookTimeMinutes: 30,
  );
  final plannedDate = DateTime(2025, 1, 15, 18, 0);

  final result = await DialogTestHelpers.openDialogAndCapture<Map<String, dynamic>>(
    tester,
    dialogBuilder: (context) => MealCookedDialog(
      recipe: testRecipe,
      plannedDate: plannedDate,
    ),
  );

  // Fill in servings
  await tester.enterText(
    find.byKey(const Key('meal_cooked_servings_field')),
    '4',
  );
  await tester.pumpAndSettle();

  // Fill in notes
  await tester.enterText(
    find.byKey(const Key('meal_cooked_notes_field')),
    'Delicious meal',
  );
  await tester.pumpAndSettle();

  // Save
  await tester.tap(find.text('Salvar'));
  await tester.pumpAndSettle();

  // Verify return value
  expect(result.hasValue, isTrue);
  expect(result.value!['servings'], equals(4));
  expect(result.value!['notes'], equals('Delicious meal'));
  expect(result.value!['wasSuccessful'], isTrue);
});
```

**Key points**:
- Uses `DialogTestHelpers.openDialogAndCapture` to capture return value
- Uses `DialogFixtures` for test data
- Uses keys for reliable field finding
- Verifies all returned fields

### Example 2: Cancellation with No Side Effects

From `test/widgets/add_new_ingredient_dialog_test.dart`:

```dart
testWidgets('returns null when cancelled',
  (WidgetTester tester) async {
  final mockDbHelper = TestSetup.setupMockDatabase();

  final result = await DialogTestHelpers.openDialogAndCapture<Ingredient>(
    tester,
    dialogBuilder: (context) => AddNewIngredientDialog(
      databaseHelper: mockDbHelper,
    ),
  );

  // Fill in some data
  await tester.enterText(
    find.byKey(const Key('add_new_ingredient_name_field')),
    'Temporary Ingredient',
  );
  await tester.pumpAndSettle();

  // Cancel without saving
  await DialogTestHelpers.tapDialogButton(tester, 'Cancelar');
  await tester.pumpAndSettle();

  // Verify null returned
  expect(result.hasValue, isFalse);
  expect(result.value, isNull);

  // Verify no database side effects
  expect(mockDbHelper.ingredients.isEmpty, isTrue);
});
```

**Key points**:
- Fills data but doesn't save
- Verifies null return on cancel
- Verifies database unchanged (no side effects)

### Example 3: Alternative Dismissal Methods

From `test/widgets/add_side_dish_dialog_test.dart`:

```dart
testWidgets('safely disposes controllers when dismissed by tapping outside',
  (WidgetTester tester) async {
  await DialogTestHelpers.openDialog(
    tester,
    dialogBuilder: (context) => AddSideDishDialog(
      availableRecipes: availableRecipes,
      primaryRecipe: primaryRecipe,
      excludeRecipes: [primaryRecipe],
    ),
  );

  // Verify dialog is displayed
  expect(find.byType(AddSideDishDialog), findsOneWidget);

  // Dismiss by tapping outside dialog
  await DialogTestHelpers.tapOutsideDialog(tester);
  await tester.pumpAndSettle();

  // Dialog should be closed (test passes if no crash)
  expect(find.byType(AddSideDishDialog), findsNothing);
});

testWidgets('safely disposes controllers when back button is pressed',
  (WidgetTester tester) async {
  await DialogTestHelpers.openDialog(
    tester,
    dialogBuilder: (context) => AddSideDishDialog(
      availableRecipes: availableRecipes,
      primaryRecipe: primaryRecipe,
      excludeRecipes: [primaryRecipe],
    ),
  );

  // Verify dialog is displayed
  expect(find.byType(AddSideDishDialog), findsOneWidget);

  // Dismiss by pressing back button
  await DialogTestHelpers.pressBackButton(tester);
  await tester.pumpAndSettle();

  // Dialog should be closed (test passes if no crash)
  expect(find.byType(AddSideDishDialog), findsNothing);
});
```

**Key points**:
- Tests all dismissal methods (not just Cancel button)
- Verifies safe controller disposal (no crash = pass)
- Uses `DialogTestHelpers` for consistent test behavior

### Example 4: Error Handling Test

From `test/widgets/add_new_ingredient_dialog_test.dart`:

```dart
testWidgets('shows error when database save fails',
  (WidgetTester tester) async {
  final mockDbHelper = TestSetup.setupMockDatabase();

  // Configure mock to fail on insert
  mockDbHelper.failOnOperation('insertIngredient');

  await DialogTestHelpers.openDialog(
    tester,
    dialogBuilder: (context) => AddNewIngredientDialog(
      databaseHelper: mockDbHelper,
    ),
  );

  // Fill in valid data
  await tester.enterText(
    find.byKey(const Key('add_new_ingredient_name_field')),
    'Test Ingredient',
  );
  await tester.pumpAndSettle();

  // Attempt to save
  await DialogTestHelpers.tapDialogButton(tester, 'Salvar');
  await tester.pumpAndSettle();

  // Verify error is shown
  expect(find.text('Erro ao salvar ingrediente'), findsOneWidget);

  // Verify dialog remains open (not closed on error)
  expect(find.byType(AddNewIngredientDialog), findsOneWidget);
});
```

**Key points**:
- Uses `failOnOperation()` to simulate database errors
- Verifies error message is displayed
- Verifies dialog doesn't auto-close on error

### Example 5: Multi-Field Complex Dialog

From `test/widgets/edit_meal_recording_dialog_test.dart`:

```dart
testWidgets('returns updated meal data on save',
  (WidgetTester tester) async {
  final result = await DialogTestHelpers.openDialogAndCapture<Map>(
    tester,
    dialogBuilder: (context) => EditMealRecordingDialog(
      meal: testMeal,
      primaryRecipe: testRecipe,
      databaseHelper: mockDbHelper,
    ),
  );

  // Modify servings
  await tester.enterText(
    find.widgetWithText(TextFormField, testMeal.servings.toString()),
    '5',
  );
  await tester.pumpAndSettle();

  // Modify notes
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Original test notes'),
    'Updated test notes',
  );
  await tester.pumpAndSettle();

  // Toggle success switch
  await tester.tap(find.byKey(const Key('edit_meal_success_switch')));
  await tester.pumpAndSettle();

  // Save changes
  await tester.tap(find.text('Salvar Alterações'));
  await tester.pumpAndSettle();

  // Verify all updated fields in return value
  expect(result.hasValue, isTrue);
  expect(result.value!['servings'], equals(5));
  expect(result.value!['notes'], equals('Updated test notes'));
  expect(result.value!['wasSuccessful'], isFalse); // Toggled from true
});
```

**Key points**:
- Tests pre-populated data (edit dialog)
- Modifies multiple fields
- Verifies all changes reflected in return value

### Reference Files

**Test Files** (browse for more examples):
- `test/widgets/meal_cooked_dialog_test.dart` - 12 tests
- `test/widgets/add_ingredient_dialog_test.dart` - 14 tests
- `test/widgets/meal_recording_dialog_test.dart` - 20 tests
- `test/widgets/add_side_dish_dialog_test.dart` - 24 tests
- `test/widgets/add_new_ingredient_dialog_test.dart` - 9 tests
- `test/widgets/edit_meal_recording_dialog_test.dart` - 21 tests
- `test/regression/dialog_regression_test.dart` - Regression tests for known bugs

**Helper/Utility Files**:
- `test/helpers/dialog_test_helpers.dart` - 18 helper methods
- `test/test_utils/dialog_fixtures.dart` - Test data factories
- `test/mocks/mock_database_helper.dart` - Mock with error simulation
- `test/test_utils/test_setup.dart` - Standardized test setup

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
