# Edge Case Tests

This directory contains comprehensive edge case tests for the Gastrobrain application, organized by category.

## Overview

Edge case testing ensures the application handles extreme values, unusual interactions, and error conditions gracefully. These tests go beyond happy-path scenarios to verify robustness and reliability.

## Directory Structure

```
test/edge_cases/
├── empty_states/          # Tests for empty data scenarios
├── boundary_conditions/   # Tests for extreme values and limits
├── error_scenarios/       # Tests for error handling and recovery
├── interaction_patterns/  # Tests for unusual user interactions
└── data_integrity/        # Tests for data consistency
```

## Test Categories

### 1. [Empty States](./empty_states/)
Tests for when there's no data to display:
- No recipes in database
- No ingredients available
- No planned meals
- Empty search results

**Example**: First-time user experience

### 2. [Boundary Conditions](./boundary_conditions/)
Tests for extreme input values:
- Numeric: zero, negative, maximum values
- Text: empty, single char, very long text
- Collections: empty lists, very large lists
- Dates: past, future, invalid dates

**Example**: Recipe with 10,000 character notes

### 3. [Error Scenarios](./error_scenarios/)
Tests for error handling and recovery:
- Database errors (locked, corrupted, query failures)
- Validation errors
- Service layer errors
- Recovery paths

**Example**: Database locked during save operation

### 4. [Interaction Patterns](./interaction_patterns/)
Tests for unusual user behaviors:
- Rapid button tapping
- Concurrent actions
- Navigation during async operations
- Orientation changes
- Device-specific conditions

**Example**: User taps save button 10 times rapidly

### 5. [Data Integrity](./data_integrity/)
Tests for data consistency:
- Orphaned records
- Foreign key violations
- Transaction rollbacks
- Cache consistency

**Example**: Meal references deleted recipe

## Quick Start

### Running Edge Case Tests

```bash
# Run all edge case tests
flutter test test/edge_cases/

# Run specific category
flutter test test/edge_cases/empty_states/
flutter test test/edge_cases/boundary_conditions/

# Run specific test file
flutter test test/edge_cases/error_scenarios/database_crud_failures_test.dart
```

### Creating a New Edge Case Test

1. **Identify the category** - Choose the appropriate subdirectory
2. **Check the catalog** - See [EDGE_CASE_CATALOG.md](../../docs/EDGE_CASE_CATALOG.md)
3. **Use test helpers** - Import `EdgeCaseTestHelpers`, `BoundaryFixtures`, `ErrorInjectionHelpers`
4. **Follow naming convention** - `{feature}_{category}_test.dart`
5. **Update catalog** - Mark as tested when complete

### Example Test

```dart
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/edge_case_test_helpers.dart';
import '../../fixtures/boundary_fixtures.dart';
import '../../test_utils/test_setup.dart';

void main() {
  group('Recipe Boundary Conditions', () {
    late MockDatabaseHelper mockDb;

    setUp(() {
      mockDb = TestSetup.setupMockDatabase();
    });

    testWidgets('rejects recipe with empty name', (tester) async {
      await tester.pumpWidget(/* build recipe form */);

      // Fill with boundary value
      await EdgeCaseTestHelpers.fillFieldWithBoundaryValue(
        tester,
        fieldLabel: 'Recipe Name',
        boundaryType: BoundaryType.empty,
      );

      // Trigger validation
      await EdgeCaseTestHelpers.triggerFormValidation(
        tester,
        submitButtonText: 'Save',
      );

      // Verify error
      EdgeCaseTestHelpers.verifyValidationError(
        tester,
        expectedError: 'Recipe name is required',
      );
    });
  });
}
```

## Test Utilities

### EdgeCaseTestHelpers
Main utility for edge case testing:
- `verifyEmptyState()` - Check empty state display
- `fillWithBoundaryValue()` - Fill fields with extreme values
- `simulateRapidTaps()` - Test rapid user interactions
- `verifyErrorDisplayed()` - Check error messages
- `verifyRecoveryPath()` - Verify recovery actions

See: [edge_case_test_helpers.dart](../helpers/edge_case_test_helpers.dart)

### BoundaryFixtures
Pre-defined boundary values:
- `BoundaryValues.veryLongText` - 1000 char string
- `BoundaryValues.zero` - Zero value
- `BoundaryValues.specialChars` - HTML/XML special chars
- `BoundaryValues.listVeryLarge` - 1000+ items

See: [boundary_fixtures.dart](../fixtures/boundary_fixtures.dart)

### ErrorInjectionHelpers
Simulate errors for testing:
- `injectDatabaseError()` - Trigger DB failures
- `simulateConstraintViolation()` - FK/unique violations
- `simulateTimeout()` - Timeout scenarios
- `resetErrorInjection()` - Clean up after tests

See: [error_injection_helpers.dart](../helpers/error_injection_helpers.dart)

## Testing Principles

### 1. Test Real Edge Cases
Focus on scenarios that actually happen:
- ✅ User has no recipes (common for new users)
- ✅ Recipe name is very long (users paste content)
- ✅ Database locked (concurrent access)
- ❌ Recipe name is exactly 743 characters (arbitrary, unlikely)

### 2. Verify Graceful Handling
Edge cases shouldn't crash the app:
- Show helpful error messages
- Provide recovery actions
- Maintain data integrity
- Keep UI responsive

### 3. Use Realistic Data
Use `BoundaryFixtures` for consistency:
```dart
// Good - realistic long text
BoundaryValues.veryLongText

// Bad - arbitrary test data
'a' * 9999
```

### 4. Test Recovery Paths
Don't just test that errors occur:
```dart
// 1. Trigger error
ErrorInjectionHelpers.injectDatabaseError(/*...*/);

// 2. Verify error handling
EdgeCaseTestHelpers.verifyErrorDisplayed(/*...*/);

// 3. Test recovery
EdgeCaseTestHelpers.verifyRecoveryPath(/*...*/);
await tester.tap(find.text('Retry'));

// 4. Verify success
expect(/* operation succeeded */, isTrue);
```

### 5. Clean Up After Tests
Always reset error injection:
```dart
tearDown(() {
  ErrorInjectionHelpers.resetErrorInjection(mockDb);
});
```

## Naming Conventions

### Test Files
`{feature}_{category}_test.dart`

Examples:
- `recipes_empty_state_test.dart`
- `servings_boundary_test.dart`
- `database_crud_failures_test.dart`
- `rapid_tap_test.dart`

### Test Groups
Use descriptive group names:
```dart
group('Recipe Management - Empty States', () {
  group('No recipes in database', () {
    testWidgets('shows helpful empty state message', /*...*/);
    testWidgets('shows add recipe button', /*...*/);
  });
});
```

### Test Names
Use clear, descriptive test names:
```dart
// Good
testWidgets('rejects servings = 0 with validation error', /*...*/);
testWidgets('handles database locked error gracefully', /*...*/);

// Bad
testWidgets('test servings', /*...*/);
testWidgets('error test', /*...*/);
```

## Coverage Goals

| Category | Coverage Target | Priority |
|----------|----------------|----------|
| Empty States | 90% | High |
| Boundary Conditions (Critical) | 100% | Critical |
| Boundary Conditions (Other) | 85% | Medium |
| Error Scenarios (Critical) | 100% | Critical |
| Error Scenarios (Other) | 90% | High |
| Interaction Patterns | 85% | Medium |
| Data Integrity | 100% | Critical |

## Related Documentation

- **[Edge Case Catalog](../../docs/EDGE_CASE_CATALOG.md)** - Comprehensive list of all edge cases
- **[Issue #39 Roadmap](../../docs/ISSUE_39_ROADMAP.md)** - Implementation roadmap
- **[Dialog Testing Guide](../../docs/DIALOG_TESTING_GUIDE.md)** - Similar patterns from Issue #38

## Progress Tracking

Track progress in:
- [EDGE_CASE_CATALOG.md](../../docs/EDGE_CASE_CATALOG.md) - Update status as tests are written
- [ISSUE_39_ROADMAP.md](../../docs/ISSUE_39_ROADMAP.md) - Phase completion tracking

## Questions?

Refer to:
- Category READMEs in each subdirectory
- Test utilities source code
- Edge Case Catalog for specific scenarios
- Issue #39 for project context
