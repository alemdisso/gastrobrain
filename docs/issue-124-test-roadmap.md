<!-- markdownlint-disable -->
# Issue #124: Meal Edit Feedback Messages Test Roadmap

## Overview

This roadmap outlines the implementation plan for comprehensive tests verifying feedback messages (success and error snackbars) when editing meal records.

## Current State Analysis

### Feedback Message Sources

| Screen/Widget | Success Message | Error Message |  Source File  | 
|---------------|-----------------|---------------|---------------|
| `MealHistoryScreen._handleEditMeal()` | `mealUpdatedSuccessfully` | `errorEditingMeal + e` | `lib/screens/meal_history_screen.dart` |
| `WeeklyPlanScreen._handleEditCookedMeal()` | `mealUpdatedSuccessfully` | `errorEditingMeal(e.toString())` | `lib/screens/weekly_plan_screen.dart` |
| `EditMealRecordingDialog._saveChanges()` | N/A (returns data) | `errorPrefix + e` | `lib/widgets/edit_meal_recording_dialog.dart` |
| `EditMealRecordingDialog._loadAvailableRecipes()` | N/A | `errorLoadingRecipes + e` | `lib/widgets/edit_meal_recording_dialog.dart` |
| `EditMealRecordingDialog._selectDate()` | N/A | `errorSelectingDate` | `lib/widgets/edit_meal_recording_dialog.dart` |

### Snackbar Implementation

The app uses two patterns:
1. **SnackbarService** (`lib/core/services/snackbar_service.dart`):
   - `showSuccess()` - green background, 3 seconds duration
   - `showError()` - error color background, 3 seconds duration

2. **Direct ScaffoldMessenger** usage in dialogs

### Validation Rules (from `EntityValidator`)

| Validation | Rule | Error Type |
|------------|------|------------|
| `validateServings()` | servings > 0 | `ValidationException` |
| `validateTime()` | time >= 0 (if provided) | `ValidationException` |
| `validateMeal()` | name not empty, date not future, recipeIds not empty | `ValidationException` |

### MockDatabaseHelper Capabilities

Current state:
- Supports basic CRUD operations for meals, recipes, meal_recipes
- Does NOT currently have explicit error simulation methods
- Will need extension for database error testing

---

## Phase 1: Infrastructure Setup

### 1.1 Extend MockDatabaseHelper for Error Simulation

**File:** `test/mocks/mock_database_helper.dart`

**Tasks:**
- [X] Add `shouldFailNextOperation` flag
- [X] Add `nextOperationError` message property
- [X] Add `failOnOperation(String operationName)` method
- [X] Add `resetErrorSimulation()` method
- [X] Implement error throwing in `updateMeal()` when flag is set
- [X] Implement error throwing in `getMeal()` when flag is set

**Example Implementation:**
```dart
// Error simulation properties
bool _shouldFailNextOperation = false;
String _nextOperationError = 'Simulated database error';
String? _failOnSpecificOperation;

void simulateError({String? onOperation, String? errorMessage}) {
  _shouldFailNextOperation = true;
  _failOnSpecificOperation = onOperation;
  if (errorMessage != null) _nextOperationError = errorMessage;
}

void resetErrorSimulation() {
  _shouldFailNextOperation = false;
  _failOnSpecificOperation = null;
  _nextOperationError = 'Simulated database error';
}
```

### 1.2 Create Test Helper Functions

**File:** `test/helpers/snackbar_test_helpers.dart` (new file)

**Tasks:**
- [X] Create `findSnackBarWithText(String text)` helper
- [X] Create `expectSuccessSnackBar(String expectedText)` helper
- [X] Create `expectErrorSnackBar(String expectedText)` helper
- [X] Create `waitForSnackBar(WidgetTester tester)` helper
- [X] Create `dismissSnackBar(WidgetTester tester)` helper

### 1.3 Review Existing Test Patterns

**Reference files:**
- `test/screens/meal_history_screen_test.dart`
- `test/screens/meal_history_edit_test.dart` (if exists)

**Tasks:**
- [X] Document existing `createTestableWidget()` pattern
- [X] Verify Provider setup for `RecipeProvider` (required by `_handleEditMeal`)
- [X] Identify any existing snackbar test patterns to follow

---

## Phase 2: Success Feedback Tests

### 2.1 MealHistoryScreen Success Tests

**File:** `test/screens/meal_history_edit_feedback_test.dart` (new file)

**Test Cases:**

#### Test 2.1.1: Success message appears after successful edit
```dart
testWidgets('shows success snackbar after successful meal edit', (tester) async {
  // Setup: Create meal, show edit dialog, save changes
  // Verify: SnackBar with 'mealUpdatedSuccessfully' text appears
});
```
- [X] Create test meal with mock database
- [X] Tap edit button to open dialog
- [X] Modify a field (e.g., servings)
- [X] Tap save button
- [X] Verify success snackbar appears
- [X] Verify snackbar contains correct localized text

#### Test 2.1.2: Success message content is user-friendly
```dart
testWidgets('success message contains appropriate content', (tester) async {
  // Verify the actual message text is meaningful
});
```
- [X] Verify message is localized
- [X] Verify message is concise and clear
- [X] Test in both English and Portuguese locales

#### Test 2.1.3: Success message timing
```dart
testWidgets('success message appears after save operation completes', (tester) async {
  // Verify timing: message shows AFTER database update, not before
});
```
- [x] Verify snackbar appears after dialog closes
- [x] Verify snackbar appears after `_loadMeals()` completes

### 2.2 WeeklyPlanScreen Success Tests

**File:** `test/screens/weekly_plan_edit_feedback_test.dart` (new file or add to existing)

**Test Cases:**

#### Test 2.2.1: Success message after editing cooked meal from weekly plan
```dart
testWidgets('shows success snackbar when editing cooked meal from weekly plan', (tester) async {
  // Setup: Create meal plan with cooked meal
  // Edit the cooked meal
  // Verify success message
});
```
BLOCKED: This test is blocked by issue #234
WeeklyPlanScreen uses raw database access (_updateMealRecord calls db.update directly) which cannot be mocked. Need to refactor to use DatabaseHelper.updateMeal() first.
See: https://github.com/alemdisso/gastrobrain/issues/234

- [ ] Create meal plan with cooked item
- [ ] Navigate to edit cooked meal
- [ ] Save changes
- [ ] Verify success snackbar

---

## Phase 3: Error Feedback Tests

### 3.1 Validation Error Tests

**File:** `test/screens/meal_history_edit_feedback_test.dart`

#### Test 3.1.1: Invalid servings shows error
```dart
testWidgets('shows error when servings is invalid', (tester) async {
  // Enter 0 or negative servings
  // Verify form validation error OR snackbar error
});
```
- [X] Test servings = 0
- [X] Test servings = -1
- [X] Test servings = empty string
- [X] Verify appropriate error feedback

#### Test 3.1.2: Invalid prep time shows error
```dart
testWidgets('shows error when prep time is negative', (tester) async {
  // Enter negative prep time
  // Verify error message
});
```
- [X] Test negative prep time
- [X] Test invalid format (non-numeric)

#### Test 3.1.3: Invalid cook time shows error
```dart
testWidgets('shows error when cook time is negative', (tester) async {
  // Enter negative cook time
  // Verify error message
});
```
- [X] Test negative cook time
- [X] Test invalid format (non-numeric)

### 3.2 Database Error Tests

**File:** `test/screens/meal_history_edit_feedback_test.dart`

#### Test 3.2.1: Database update failure shows error snackbar
```dart
testWidgets('shows error snackbar when database update fails', (tester) async {
  // Configure mock to fail on updateMeal
  // Attempt to save
  // Verify error snackbar appears
});
```
- [X] Configure `MockDatabaseHelper` to simulate failure
- [X] Attempt save operation
- [X] Verify error snackbar appears with `errorEditingMeal` text

#### Test 3.2.2: Meal not found error
```dart
testWidgets('shows error when meal is not found during edit', (tester) async {
  // Delete meal after dialog opens but before save
  // Attempt to save
  // Verify error feedback
});
```
- [X] Simulate meal deletion during edit
- [X] Verify appropriate error message

#### Test 3.2.3: Recipe loading error in dialog
```dart
testWidgets('shows error snackbar when loading recipes fails', (tester) async {
  // Configure mock to fail on getAllRecipes
  // Open edit dialog
  // Verify error snackbar with 'errorLoadingRecipes'
});
```
- [X] Configure `MockDatabaseHelper.getAllRecipes()` to throw
- [X] Open edit dialog
- [X] Verify error snackbar appears

### 3.3 Error Message Content Tests

#### Test 3.3.1: Error messages are user-friendly
```dart
testWidgets('error messages do not expose technical details', (tester) async {
  // Verify error messages are appropriate for end users
});s
```
- [X] Verify no stack traces in user-facing messages
- [X] Verify messages are localized
- [ ] Verify messages provide actionable information (WILL NOT BE DONE NOW)

---

## Phase 4: Edge Cases and Polish

### 4.1 Multi-Recipe Meal Tests

**File:** `test/screens/meal_history_edit_feedback_test.dart`

#### Test 4.1.1: Success message after editing multi-recipe meal
```dart
testWidgets('shows success message after editing meal with multiple recipes', (tester) async {
  // Create meal with primary + side dishes
  // Edit and save
  // Verify success message
});
```
- [ ] Create meal with primary recipe + 2 side dishes
- [ ] Modify servings and/or side dishes
- [ ] Save and verify success message

#### Test 4.1.2: Error handling when adding/removing side dishes
```dart
testWidgets('shows appropriate feedback when side dish operations fail', (tester) async {
  // Test adding side dish failure
  // Test removing side dish failure
});
```
- [ ] Test add side dish database failure
- [ ] Test remove side dish database failure

### 4.2 Single-Recipe Meal Tests

#### Test 4.2.1: Success message after editing single-recipe meal
```dart
testWidgets('shows success message after editing single-recipe meal', (tester) async {
  // Create meal with single recipe
  // Edit and save
  // Verify success message
});
```
- [ ] Create simple meal
- [ ] Edit and verify feedback

### 4.3 Snackbar Behavior Tests

#### Test 4.3.1: Snackbar duration
```dart
testWidgets('snackbar displays for appropriate duration', (tester) async {
  // Verify snackbar stays visible for ~3 seconds
});
```
- [X] Verify snackbar is visible immediately after action
- [X] Verify snackbar auto-dismisses after duration
- [X] Note: Duration is 3 seconds per `SnackbarService`

#### Test 4.3.2: Snackbar dismissal
```dart
testWidgets('snackbar can be manually dismissed', (tester) async {
  // Show snackbar
  // Swipe to dismiss
  // Verify dismissed
});
```
- [X] Test swipe-to-dismiss functionality
- [X] Verify no lingering snackbars

#### Test 4.3.3: Multiple rapid edits don't stack snackbars poorly
```dart
testWidgets('handles multiple rapid edit operations gracefully', (tester) async {
  // Perform multiple edits quickly
  // Verify snackbar behavior is reasonable
});
```
- [X] Test rapid successive edits
- [X] Verify snackbar queue behavior

### 4.4 Accessibility Tests

#### Test 4.4.1: Snackbar is accessible
```dart
testWidgets('snackbar meets accessibility requirements', (tester) async {
  // Verify snackbar has semantic label
  // Verify sufficient contrast
});
```
- [ ] Verify snackbar has appropriate semantics
- [ ] Test with screen reader compatibility considerations

### 4.5 Locale Tests

#### Test 4.5.1: Messages display correctly in English
```dart
testWidgets('feedback messages display correctly in English locale', (tester) async {
  // Set English locale
  // Trigger success/error
  // Verify English message
});
```
- [ ] Test success message in English
- [ ] Test error messages in English

#### Test 4.5.2: Messages display correctly in Portuguese
```dart
testWidgets('feedback messages display correctly in Portuguese locale', (tester) async {
  // Set Portuguese locale
  // Trigger success/error
  // Verify Portuguese message
});
```
- [ ] Test success message in Portuguese
- [ ] Test error messages in Portuguese

---

## Implementation Order

### Recommended sequence:

1. **Phase 1.1**: Extend MockDatabaseHelper (required for error tests)
2. **Phase 1.2**: Create test helpers (improves test readability)
3. **Phase 2.1.1**: Basic success test (validates test setup works)
4. **Phase 3.1**: Validation error tests (uses existing infrastructure)
5. **Phase 3.2**: Database error tests (uses new mock capabilities)
6. **Phase 4.1-4.2**: Multi/single recipe edge cases
7. **Phase 4.3-4.5**: Behavior, accessibility, and locale tests

---

## Test File Structure

```
test/
├── helpers/
│   └── snackbar_test_helpers.dart (new)
├── mocks/
│   └── mock_database_helper.dart (extend)
└── screens/
    ├── meal_history_screen_test.dart (existing)
    ├── meal_history_edit_feedback_test.dart (new)
    └── weekly_plan_edit_feedback_test.dart (new or extend existing)
```

---

## Acceptance Criteria Mapping

| Acceptance Criteria | Test(s) |
|---------------------|---------|
| Success snackbar after meal edit | 2.1.1, 2.2.1, 4.1.1, 4.2.1 |
| Error feedback for failed edits | 3.2.1, 3.2.2, 3.2.3 |
| Appropriate message content | 2.1.2, 3.3.1 |
| Correct timing | 2.1.3 |
| Validation error tests | 3.1.1, 3.1.2, 3.1.3 |
| Database error tests | 3.2.1, 3.2.2 |
| Accessible and visible | 4.4.1 |
| Duration and dismissal | 4.3.1, 4.3.2 |
| Single and multi-recipe meals | 4.1.1, 4.2.1 |

---

## Dependencies

- `flutter_test` package
- `provider` package (for RecipeProvider mocking)
- Existing `MockDatabaseHelper`
- Existing localization setup

---

## Notes

1. **Provider Setup**: Tests for `MealHistoryScreen` need `RecipeProvider` in the widget tree since `_handleEditMeal` calls `context.read<RecipeProvider>().refreshMealStats()`

2. **Dialog Testing**: The edit dialog returns data to the caller; the actual database update and snackbar display happen in the calling screen (`MealHistoryScreen` or `WeeklyPlanScreen`)

3. **Existing Test Reference**: Use `test/screens/meal_history_screen_test.dart` patterns for consistency

4. **Form Validation vs Snackbar**: Some errors show as form field validation errors (inline), others show as snackbars. Tests should cover both patterns.
