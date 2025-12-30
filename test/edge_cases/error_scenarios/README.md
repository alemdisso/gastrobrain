# Error Scenarios Tests

This directory contains tests for error handling and failure scenarios.

## What are Error Scenarios?

Error scenarios test how the application handles failures:
- Database errors (locked, corrupted, query failures)
- Validation errors (invalid input, constraint violations)
- Service layer errors (recommendations fail, parsing errors)
- Concurrent modification conflicts
- Recovery paths after errors

## Why Test Error Scenarios?

Error handling is critical because:
- Errors are inevitable in production
- Poor error handling causes data loss or corruption
- Users need clear feedback about what went wrong
- Recovery paths must work correctly
- Graceful degradation improves user experience

## Test Categories

### Database Errors
- `database_connection_test.dart` - Init failure, locked, corrupted
- `database_crud_failures_test.dart` - Insert/update/delete failures
- `concurrent_modification_test.dart` - Race conditions, conflicts

### Validation Errors
- `validation_failures_test.dart` - Field validation, form validation
- `business_rule_violations_test.dart` - Business logic constraints

### Service Layer Errors
- `recommendation_failures_test.dart` - Recommendation service errors
- `parsing_failures_test.dart` - Import/ingredient parsing errors
- `export_failures_test.dart` - Export service errors

### Recovery Paths
- `error_recovery_test.dart` - Retry after error, recovery workflows
- `data_consistency_test.dart` - Data integrity after errors

## Testing Pattern

```dart
testWidgets('handles database error gracefully', (tester) async {
  final mockDb = TestSetup.setupMockDatabase();

  // Inject error
  ErrorInjectionHelpers.injectDatabaseError(
    mockDb,
    ErrorType.insertFailed,
    operation: 'insertRecipe',
  );

  // Attempt operation
  await tester.pumpWidget(/*...*/);
  // ... trigger save ...

  // Verify error handling
  EdgeCaseTestHelpers.verifyErrorDisplayed(
    tester,
    expectedError: 'Failed to save recipe',
  );

  // Verify recovery path
  EdgeCaseTestHelpers.verifyRecoveryPath(
    tester,
    recoveryButtonText: 'Retry',
  );

  // Clean up
  ErrorInjectionHelpers.resetErrorInjection(mockDb);
});
```

## Error Injection Helpers

Use `ErrorInjectionHelpers` for simulating errors:

```dart
import '../../helpers/error_injection_helpers.dart';

// Database errors
ErrorInjectionHelpers.injectDatabaseError(mockDb, ErrorType.insertFailed);
ErrorInjectionHelpers.simulateDatabaseLocked(mockDb);
ErrorInjectionHelpers.simulateConstraintViolation(mockDb);

// Operation-specific errors
ErrorInjectionHelpers.injectOperationError(
  mockDb,
  operation: 'getAllRecipes',
  errorMessage: 'Query failed',
);

// Reset after test
ErrorInjectionHelpers.resetErrorInjection(mockDb);
```

## Key Assertions

- ✅ Error is caught and doesn't crash app
- ✅ User-friendly error message is displayed
- ✅ Recovery path is available (retry, cancel, etc.)
- ✅ No data corruption after error
- ✅ UI remains consistent and responsive
- ✅ Error state clears after successful retry

## Recovery Path Verification

```dart
// Verify retry is available
RecoveryPathHelpers.verifyRetryAvailable(tester);

// Perform retry
ErrorInjectionHelpers.resetErrorInjection(mockDb); // Allow success
await tester.tap(find.text('Retry'));
await tester.pumpAndSettle();

// Verify error cleared
RecoveryPathHelpers.verifyErrorCleared(tester);

// Verify data consistency
RecoveryPathHelpers.verifyDataConsistency(
  mockDb,
  expectedRecipeCount: 5,
);
```

## Related Documentation

- [Edge Case Catalog](../../../docs/EDGE_CASE_CATALOG.md#error-scenarios)
- [ErrorInjectionHelpers](../../helpers/error_injection_helpers.dart)
- [EdgeCaseTestHelpers](../../helpers/edge_case_test_helpers.dart)
