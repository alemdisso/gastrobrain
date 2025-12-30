# Boundary Conditions Tests

This directory contains tests for boundary values and extreme inputs.

## What are Boundary Conditions?

Boundary conditions are the extreme or edge values that inputs can take:
- Numeric: zero, negative, maximum values
- Text: empty, very long, special characters
- Collections: empty lists, single item, very large lists
- Dates: past dates, future dates, invalid dates

## Why Test Boundary Conditions?

Boundary conditions often reveal bugs because:
- Off-by-one errors in validation logic
- UI layout breaks with extreme text lengths
- Performance degrades with large datasets
- Integer overflow or underflow
- Null pointer exceptions with empty collections

## Test Categories

### Numeric Boundaries
- `servings_boundary_test.dart` - Servings: 0, 1, 999, negative
- `time_boundary_test.dart` - Prep/cook times: 0, negative, 9999
- `rating_difficulty_boundary_test.dart` - Rating/difficulty: 0, 1, 5, 6, negative
- `date_boundary_test.dart` - Dates: year 2000, 2100, future, invalid

### Text Boundaries
- `text_length_boundary_test.dart` - Empty, 1 char, 1000+ chars, 10000+ chars
- `special_characters_test.dart` - HTML chars, emoji, unicode, SQL injection
- `whitespace_boundary_test.dart` - Whitespace-only, leading/trailing spaces

### Collection Boundaries
- `list_size_boundary_test.dart` - 0, 1, 100+, 1000+ items
- `duplicates_boundary_test.dart` - Duplicate names, constraints

## Testing Pattern

```dart
testWidgets('rejects servings = 0', (tester) async {
  await EdgeCaseTestHelpers.fillFieldWithBoundaryValue(
    tester,
    fieldLabel: 'Servings',
    boundaryType: BoundaryType.zero,
  );

  await EdgeCaseTestHelpers.triggerFormValidation(
    tester,
    submitButtonText: 'Save',
  );

  EdgeCaseTestHelpers.verifyValidationError(
    tester,
    expectedError: 'Servings must be at least 1',
  );
});
```

## Boundary Value Fixtures

Use `BoundaryValues` class for standardized test data:

```dart
import '../../fixtures/boundary_fixtures.dart';

// Numeric boundaries
BoundaryValues.zero
BoundaryValues.negative
BoundaryValues.maxReasonable

// Text boundaries
BoundaryValues.emptyString
BoundaryValues.veryLongText
BoundaryValues.specialChars

// Collection sizes
BoundaryValues.listEmpty
BoundaryValues.listVeryLarge
```

## Key Assertions

- ✅ Invalid values are rejected with clear error messages
- ✅ Valid boundary values are accepted
- ✅ UI handles extreme values without overflow
- ✅ Performance remains acceptable with large inputs
- ✅ No crashes or exceptions with boundary values

## Related Documentation

- [Edge Case Catalog](../../../docs/EDGE_CASE_CATALOG.md#boundary-conditions---numeric)
- [BoundaryFixtures](../../fixtures/boundary_fixtures.dart)
- [EdgeCaseTestHelpers](../../helpers/edge_case_test_helpers.dart)
