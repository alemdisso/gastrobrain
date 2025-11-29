# End-to-End Testing Best Practices

**Related Issue:** [#36 Establish End-to-End Flow Testing Framework](https://github.com/alemdisso/gastrobrain/issues/36)

This document outlines best practices for writing end-to-end (E2E) integration tests in Gastrobrain using Flutter's `integration_test` package.

---

## Table of Contents

1. [Overview](#overview)
2. [Types of Integration Tests](#types-of-integration-tests)
3. [When to Write E2E Tests](#when-to-write-e2e-tests)
4. [Test Structure](#test-structure)
5. [Best Practices](#best-practices)
6. [Helper Methods](#helper-methods)
7. [Widget Finding Strategies](#widget-finding-strategies)
8. [Common Patterns](#common-patterns)
9. [Troubleshooting](#troubleshooting)

---

## Overview

E2E tests verify complete user workflows by:
- Testing real UI interactions (taps, text entry, navigation)
- Verifying database state changes
- Confirming UI updates reflect data changes
- Testing the full application stack (UI → State → Database → UI)

**Key characteristics:**
- Use real database (not mocked)
- Include app initialization time for database migrations and asset loading
- Test from user perspective, not internal implementation
- Always clean up test data to prevent pollution

---

## Types of Integration Tests

Gastrobrain uses two types of integration tests that serve different purposes:

### Service Integration Tests

**Location:** `integration_test/*_flow_test.dart`, `integration_test/*_integration_test.dart`

**Purpose:** Test business logic and service layer interactions without UI

**Characteristics:**
- Use `MockDatabaseHelper` from test mocks
- No UI interaction or rendering
- Fast execution (~100-500ms per test)
- Can run in CI/CD pipelines (Linux/WSL compatible)
- Focus on data operations, state management, and business rules

**Example:**
```dart
testWidgets('Test database operations for meal plans', (tester) async {
  late MockDatabaseHelper mockDbHelper;
  mockDbHelper = TestSetup.setupMockDatabase();

  // Test business logic without UI
  await mockDbHelper.insertMealPlan(mealPlan);
  final result = await mockDbHelper.getMealPlanForWeek(weekStart);
  expect(result, isNotNull);
});
```

**When to use:**
- Testing database operations and data validation
- Testing service layer logic (recommendations, calculations)
- Testing state management without UI
- Quick feedback during development

### E2E Integration Tests

**Location:** `integration_test/e2e_*.dart`

**Purpose:** Test complete user workflows from UI to database and back

**Characteristics:**
- Use real `DatabaseHelper` (not mocked)
- Test actual UI interactions (taps, text entry, navigation)
- Slower execution (~20-60 seconds per test)
- Require windowing system (currently run manually on Windows)
- Focus on user experience and end-to-end workflows

**Example:**
```dart
testWidgets('Create a minimal recipe and verify full workflow', (tester) async {
  await E2ETestHelpers.launchApp(tester);

  // User opens form
  await E2ETestHelpers.openAddRecipeForm(tester);

  // User fills fields
  await E2ETestHelpers.fillTextFieldByKey(
    tester,
    const Key('add_recipe_name_field'),
    'Test Recipe',
  );

  // User saves
  await E2ETestHelpers.tapSaveButton(tester);

  // Verify UI and database
  expect(find.text('Test Recipe'), findsOneWidget);
  final recipe = await dbHelper.getRecipe(id);
  expect(recipe, isNotNull);
});
```

**When to use:**
- Testing critical user workflows (recipe creation, meal planning, editing)
- Testing multi-screen navigation flows
- Verifying UI reflects database changes
- Testing complete feature integration

### Testing Strategy

Both types of tests are valuable and complementary:

**Testing Pyramid:**
```
     /\
    /  \    ← E2E Tests (Few, slow, high-level)
   /----\
  /      \  ← Service Integration Tests (Some, fast, mid-level)
 /--------\
/          \ ← Unit Tests (Many, very fast, low-level)
```

**Guidelines:**
- Write **many** unit tests for individual functions and classes
- Write **some** service integration tests for business logic flows
- Write **few** E2E tests for critical user workflows
- Service integration tests run in CI; E2E tests run manually
- Both test types should clean up test data in `finally` blocks

**Current test organization:**
See [Issue #221](https://github.com/alemdisso/gastrobrain/issues/221) for planned reorganization into `e2e/` and `services/` directories.

---

## When to Write E2E Tests

Write E2E tests for:
- **Critical user workflows** - Recipe creation, meal planning, shopping list generation
- **Multi-step processes** - Workflows requiring navigation across multiple screens
- **Database interactions** - Features that create, update, or delete persistent data
- **Complex UI state** - Features involving multiple components working together

**Don't write E2E tests for:**
- Simple widget rendering (use widget tests)
- Business logic (use unit tests)
- Error messages or validation (use widget tests with mocked states)

---

## Test Structure

All E2E tests should follow this structure:

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E - [Feature Category]', () {
    testWidgets('[Specific workflow description]', (WidgetTester tester) async {
      // ======================================================================
      // TEST DATA SETUP
      // ======================================================================
      final testData = 'Test Data ${DateTime.now().millisecondsSinceEpoch}';
      String? createdResourceId;

      try {
        // ==================================================================
        // SETUP: Launch and Initialize
        // ==================================================================
        await E2ETestHelpers.launchApp(tester);
        final dbHelper = DatabaseHelper();

        // ==================================================================
        // ACT: Perform Test Actions
        // ==================================================================
        // Navigate, fill forms, tap buttons, etc.

        // ==================================================================
        // VERIFY: Check Results
        // ==================================================================
        // Verify UI state
        // Verify database state

      } finally {
        // ==================================================================
        // CLEANUP: Remove Test Data
        // ==================================================================
        if (createdResourceId != null) {
          await E2ETestHelpers.deleteTestResource(dbHelper, createdResourceId);
        }
      }
    });
  });
}
```

### Key Sections

1. **Test Data Setup** - Define unique test data using timestamps
2. **Setup** - Launch app, get database helper, verify initial state
3. **Act** - Perform user actions (navigation, form filling, button taps)
4. **Verify** - Check both UI state AND database state
5. **Cleanup** - Always in `finally` block to run even if test fails

---

## Best Practices

### 1. Use Descriptive Test Names

❌ **Bad:**
```dart
testWidgets('test recipe', (tester) async { ... });
```

✅ **Good:**
```dart
testWidgets('Create a minimal recipe and verify full workflow', (tester) async { ... });
```

### 2. Always Include Cleanup in try-finally

❌ **Bad:**
```dart
testWidgets('Create recipe', (tester) async {
  final id = await createTestRecipe();
  // Test logic...
  await deleteTestRecipe(id); // ⚠️ Won't run if test fails!
});
```

✅ **Good:**
```dart
testWidgets('Create recipe', (tester) async {
  String? createdId;
  try {
    createdId = await createTestRecipe();
    // Test logic...
  } finally {
    if (createdId != null) {
      await deleteTestRecipe(createdId);
    }
  }
});
```

### 3. Use Unique Test Data with Timestamps

❌ **Bad:**
```dart
final testName = 'Test Recipe'; // ⚠️ Will conflict if test runs multiple times
```

✅ **Good:**
```dart
final testName = 'Test Recipe ${DateTime.now().millisecondsSinceEpoch}';
```

### 4. Add Print Statements for Progress Tracking

```dart
print('=== LAUNCHING APP ===');
await E2ETestHelpers.launchApp(tester);
print('✓ App launched and initialized');

print('\n=== OPENING ADD RECIPE FORM ===');
final fieldCount = await E2ETestHelpers.openAddRecipeForm(tester);
print('✓ Form opened with $fieldCount fields');
```

**Benefits:**
- See exactly where test fails
- Track test progress in CI logs
- Debug timing issues

### 5. Verify BOTH Database State AND UI State

❌ **Incomplete:**
```dart
// Only verify database
final recipe = await dbHelper.getRecipe(id);
expect(recipe, isNotNull);
```

✅ **Complete:**
```dart
// Verify database
final recipeId = await E2ETestHelpers.verifyRecipeInDatabase(dbHelper, testName);
expect(recipeId, isNotNull);

// Verify UI
final foundInUI = await E2ETestHelpers.verifyRecipeInUI(tester, testName);
expect(foundInUI, isTrue);
```

### 6. Use Helper Methods Instead of Direct Widget Interaction

❌ **Bad:**
```dart
final fab = find.byType(FloatingActionButton);
await tester.tap(fab);
await tester.pumpAndSettle();
final fields = find.byType(TextFormField);
await tester.enterText(fields.at(0), 'Recipe Name');
```

✅ **Good:**
```dart
await E2ETestHelpers.openAddRecipeForm(tester);
await E2ETestHelpers.fillTextFieldByIndex(tester, 0, 'Recipe Name');
```

**Benefits:**
- Consistent behavior across tests
- Easier to update if UI changes
- More readable test code

### 7. Wait for Async Operations Before Verifying

```dart
await E2ETestHelpers.tapSaveButton(tester);

// ⚠️ Database operations are async!
await E2ETestHelpers.waitForAsyncOperations();

// Now safe to verify
final recipeId = await E2ETestHelpers.verifyRecipeInDatabase(...);
```

### 8. Handle Failure Cases Gracefully

```dart
try {
  E2ETestHelpers.verifyOnMainScreen();
  print('✓ Back on main screen');
} catch (e) {
  print('⚠ Not on main screen - action may have failed');
  E2ETestHelpers.printScreenState('Current state');

  // Check if we're still on form due to validation
  E2ETestHelpers.verifyOnFormScreen();
}
```

### 9. Keep Tests Focused on One User Workflow

❌ **Bad:**
```dart
testWidgets('Test everything', (tester) async {
  // Create recipe
  // Edit recipe
  // Delete recipe
  // Create meal plan
  // ... ⚠️ Too much in one test!
});
```

✅ **Good:**
```dart
testWidgets('Create a minimal recipe and verify workflow', (tester) async {
  // Just test recipe creation
});

testWidgets('Edit existing recipe and verify changes', (tester) async {
  // Just test recipe editing
});
```

### 10. Document What the Test is Verifying

```dart
/// Complete Recipe Creation Workflow Test
///
/// This test verifies the complete recipe creation workflow:
/// 1. Navigate to Add Recipe screen
/// 2. Fill required field (name)
/// 3. Save the recipe
/// 4. Verify it appears in the recipe list UI
/// 5. Verify it exists in the database with correct data
/// 6. Clean up test data
void main() { ... }
```

---

## Helper Methods

All helper methods are in `integration_test/helpers/e2e_test_helpers.dart`.

### App Initialization

```dart
await E2ETestHelpers.launchApp(tester);
```
Launches app and waits for complete initialization (database migrations, asset loading, provider setup).

### Navigation

```dart
// Tap bottom navigation tab
await E2ETestHelpers.tapBottomNavTab(tester, Icons.calendar_today);

// Open Add Recipe form
final fieldCount = await E2ETestHelpers.openAddRecipeForm(tester);

// Close form with back button
await E2ETestHelpers.closeFormWithBackButton(tester);
```

### Form Interaction

```dart
// Fill text field by index (current approach)
await E2ETestHelpers.fillTextFieldByIndex(tester, 0, 'Recipe Name');

// Fill text field by key (future approach - requires form field keys)
await E2ETestHelpers.fillTextFieldByKey(
  tester,
  Key('add_recipe_name_field'),
  'Recipe Name'
);

// Scroll in form
await E2ETestHelpers.scrollDown(tester, offset: 500);
await E2ETestHelpers.scrollUp(tester, offset: 500);

// Tap save button
await E2ETestHelpers.tapSaveButton(tester);
```

### Verification

```dart
// Verify screen state
E2ETestHelpers.verifyOnMainScreen();
E2ETestHelpers.verifyOnFormScreen(expectedFieldCount: 4);

// Verify database
final recipeId = await E2ETestHelpers.verifyRecipeInDatabase(
  dbHelper,
  'Test Recipe'
);

// Verify UI
final foundInUI = await E2ETestHelpers.verifyRecipeInUI(
  tester,
  'Test Recipe'
);
```

### Cleanup

```dart
await E2ETestHelpers.deleteTestRecipe(dbHelper, recipeId);
```

### Diagnostics

```dart
// Print widget counts
E2ETestHelpers.printScreenState('After save button tap');

// Wait for async operations
await E2ETestHelpers.waitForAsyncOperations(duration: Duration(seconds: 2));
```

---

## Widget Finding Strategies

### Current Approach: Index-based Access

**Used for:** Current tests while form field keys are being added

```dart
final textFields = find.byType(TextFormField);
await tester.enterText(textFields.at(0), 'Recipe Name');
```

**Pros:**
- Works immediately without code changes
- Simple to implement

**Cons:**
- ⚠️ Fragile - breaks if field order changes
- ⚠️ Non-deterministic - unclear which field index refers to
- ⚠️ Hard to debug when wrong field is accessed

### Future Approach: Key-based Access

**Will be used once [Issue #219](https://github.com/alemdisso/gastrobrain/issues/219) is complete**

```dart
final nameField = find.byKey(Key('add_recipe_name_field'));
await tester.enterText(nameField, 'Recipe Name');
```

**Pros:**
- ✅ Deterministic - always finds the correct field
- ✅ Resilient to UI changes
- ✅ Self-documenting test code

**Requires:**
- Adding `key:` parameter to form fields (see [Form Field Keys Standard](Gastrobrain-Codebase-Overview.md#form-field-keys))

### Other Strategies

**Find by label text:**
```dart
final nameField = find.widgetWithText(TextFormField, 'Recipe Name');
await tester.enterText(nameField, 'My Recipe');
```
- ⚠️ Fragile - breaks if label text changes
- ⚠️ Doesn't work well with localized apps

**Find by semantics:**
```dart
final nameField = find.bySemanticsLabel('Recipe Name');
```
- ✅ Good for accessibility testing
- ⚠️ Requires semantic labels on widgets

---

## Common Patterns

### Pattern: Form Fill and Save

```dart
// Open form
await E2ETestHelpers.openAddRecipeForm(tester);

// Fill required fields
await E2ETestHelpers.fillTextFieldByIndex(tester, 0, 'Recipe Name');

// Save
await E2ETestHelpers.tapSaveButton(tester);
await E2ETestHelpers.waitForAsyncOperations();

// Verify navigation
E2ETestHelpers.verifyOnMainScreen();
```

### Pattern: Database Verification with Cleanup

```dart
String? createdId;

try {
  // Perform action that creates data
  createdId = await E2ETestHelpers.verifyRecipeInDatabase(dbHelper, testName);

  // Verify it worked
  expect(createdId, isNotNull);

} finally {
  // Always clean up
  if (createdId != null) {
    await E2ETestHelpers.deleteTestRecipe(dbHelper, createdId);
  }
}
```

### Pattern: Conditional Verification

```dart
try {
  E2ETestHelpers.verifyOnMainScreen();
  print('✓ Save succeeded - back on main screen');
} catch (e) {
  print('⚠ Save may have failed - still on form');
  E2ETestHelpers.verifyOnFormScreen();

  // Scroll to check for validation errors
  await E2ETestHelpers.scrollUp(tester);
}
```

### Pattern: Scrolling to Find Items

```dart
// Verify in UI (may require scrolling)
final foundInUI = await E2ETestHelpers.verifyRecipeInUI(tester, testName);

if (foundInUI) {
  print('✅ Recipe appears in the UI list!');
} else {
  print('⚠ Recipe not visible in UI (might need more scrolling)');
}
```

---

## Troubleshooting

### Test Fails with "Service has disappeared"

**Symptom:** Error message: `getVersion: (112) Service has disappeared`

**Cause:** App crashed or form validation failed, causing the test framework to lose connection

**Solutions:**
1. Check for validation errors - test may be submitting invalid data
2. Verify all required fields are filled
3. Check for type mismatches (entering text in number fields)
4. Add `printScreenState()` calls to see where app crashed

### Test Can't Find Save Button

**Symptom:** `expect(find.byType(ElevatedButton), findsOneWidget)` fails

**Cause:** Save button is not visible (may be scrolled off screen)

**Solution:**
```dart
await E2ETestHelpers.scrollDown(tester);  // Scroll to reveal button
await E2ETestHelpers.tapSaveButton(tester);  // Helper already handles this
```

### Data Not Persisting to Database

**Symptom:** `verifyRecipeInDatabase()` returns null even though save button was tapped

**Causes:**
1. Form validation failed (still on form screen)
2. Wrong fields filled (entered text in number fields)
3. Required fields not filled
4. Database operation not completed yet

**Solutions:**
1. Verify you're back on main screen after save
2. Use `waitForAsyncOperations()` after save
3. Fill ONLY required fields first (minimal test)
4. Check you're using correct field indices

### Test is Flaky (Sometimes Passes, Sometimes Fails)

**Causes:**
1. Not waiting for async operations
2. Not waiting for animations to complete
3. Timing-dependent assertions
4. Shared test data (multiple tests using same data)

**Solutions:**
1. Add `await tester.pumpAndSettle()` after interactions
2. Use `waitForAsyncOperations()` after database operations
3. Use unique test data with timestamps
4. Ensure cleanup runs even if test fails

### Wrong Form Field Being Filled

**Symptom:** Test fills wrong field or enters text in number field

**Cause:** Using index-based access (`.at(index)`) without knowing field order

**Short-term solution:**
```dart
// Fill ONLY fields you're certain about
await E2ETestHelpers.fillTextFieldByIndex(tester, 0, 'Recipe Name');  // Usually safe - first field
```

**Long-term solution:**
- Add form field keys (see [Issue #219](https://github.com/alemdisso/gastrobrain/issues/219))
- Switch to key-based access:
```dart
await E2ETestHelpers.fillTextFieldByKey(
  tester,
  Key('add_recipe_name_field'),
  'Recipe Name'
);
```

---

## Creating New E2E Tests

### Quick Start

1. **Copy the template:**
   ```bash
   cp integration_test/TEST_TEMPLATE.dart integration_test/e2e_your_feature_test.dart
   ```

2. **Update the header:**
   ```dart
   /// Your Feature Workflow Test
   ///
   /// This test verifies [describe workflow]:
   /// 1. [Step 1]
   /// 2. [Step 2]
   /// ...
   ```

3. **Update test metadata:**
   ```dart
   group('E2E - Your Feature Category', () {
     testWidgets('Specific workflow description', (WidgetTester tester) async {
   ```

4. **Define test data:**
   ```dart
   final testData = 'Test Data ${DateTime.now().millisecondsSinceEpoch}';
   String? createdResourceId;
   ```

5. **Implement workflow using helper methods:**
   - Launch app: `await E2ETestHelpers.launchApp(tester);`
   - Navigate: `await E2ETestHelpers.tapBottomNavTab(tester, icon);`
   - Fill forms: `await E2ETestHelpers.fillTextFieldByIndex(tester, 0, data);`
   - Save: `await E2ETestHelpers.tapSaveButton(tester);`
   - Verify: `await E2ETestHelpers.verifyRecipeInDatabase(dbHelper, data);`
   - Clean up: `await E2ETestHelpers.deleteTestRecipe(dbHelper, id);`

6. **Run the test:**
   ```bash
   flutter test integration_test/e2e_your_feature_test.dart
   ```

### Test Template

See `integration_test/TEST_TEMPLATE.dart` for a complete, documented template.

---

## Related Documentation

- **[Form Field Keys Standard](Gastrobrain-Codebase-Overview.md#form-field-keys)** - Guidelines for adding keys to form fields
- **[Issue #36](https://github.com/alemdisso/gastrobrain/issues/36)** - E2E testing framework implementation
- **[Issue #219](https://github.com/alemdisso/gastrobrain/issues/219)** - Form field keys refactoring
- **[Flutter integration_test package](https://docs.flutter.dev/testing/integration-tests)** - Official documentation

---

**Last Updated:** 2025-11-25
**Status:** Active - Framework established, ongoing test development
