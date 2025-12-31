// test/helpers/error_injection_helpers.dart

import 'package:flutter_test/flutter_test.dart';

import '../mocks/mock_database_helper.dart';
import 'edge_case_test_helpers.dart';

/// Error Injection Helpers
///
/// Utilities for simulating various error conditions in tests to verify
/// error handling, recovery paths, and application resilience.
///
/// Example usage:
/// ```dart
/// testWidgets('handles database error gracefully', (tester) async {
///   ErrorInjectionHelpers.injectDatabaseError(
///     mockDbHelper,
///     ErrorType.insertFailed,
///     operation: 'insertMeal',
///   );
///
///   // Attempt operation that should fail...
///   // Verify error handling...
///
///   ErrorInjectionHelpers.resetErrorInjection(mockDbHelper);
/// });
/// ```
class ErrorInjectionHelpers {
  /// Injects a database error for the next operation.
  ///
  /// Use this to test how the application handles database failures.
  ///
  /// Example:
  /// ```dart
  /// ErrorInjectionHelpers.injectDatabaseError(
  ///   mockDbHelper,
  ///   ErrorType.updateFailed,
  ///   operation: 'updateMeal',
  /// );
  ///
  /// // Next updateMeal call will fail
  /// try {
  ///   await mockDbHelper.updateMeal(meal);
  ///   fail('Should have thrown exception');
  /// } catch (e) {
  ///   // Verify error handling
  /// }
  /// ```
  static void injectDatabaseError(
    MockDatabaseHelper mockDbHelper,
    ErrorType errorType, {
    String? operation,
    Exception? customException,
  }) {
    final exception = customException ?? _getExceptionForErrorType(errorType);
    if (operation != null) {
      mockDbHelper.failOnOperation(operation, exception: exception);
    } else {
      mockDbHelper.failOnOperation('', exception: exception);
    }
  }

  /// Injects an error for a specific database operation by name.
  ///
  /// Common operation names:
  /// - 'getAllRecipes'
  /// - 'getMeal'
  /// - 'getMealsForRecipe'
  /// - 'insertMealRecipe'
  /// - 'insertIngredient'
  /// - 'updateMeal'
  /// - 'deleteMeal'
  ///
  /// Example:
  /// ```dart
  /// ErrorInjectionHelpers.injectOperationError(
  ///   mockDbHelper,
  ///   operation: 'getAllRecipes',
  ///   errorMessage: 'Database locked',
  /// );
  /// ```
  static void injectOperationError(
    MockDatabaseHelper mockDbHelper, {
    required String operation,
    String? errorMessage,
    Exception? customException,
  }) {
    mockDbHelper.failOnOperation(
      operation,
      exception: customException ?? Exception(errorMessage ?? 'Operation failed'),
    );
  }

  /// Resets all error injection state.
  ///
  /// Call this in tearDown or after error tests to ensure clean state.
  ///
  /// Example:
  /// ```dart
  /// tearDown(() {
  ///   ErrorInjectionHelpers.resetErrorInjection(mockDbHelper);
  /// });
  /// ```
  static void resetErrorInjection(MockDatabaseHelper mockDbHelper) {
    mockDbHelper.resetErrorSimulation();
  }

  /// Simulates a constraint violation error.
  ///
  /// Use this to test unique constraints, foreign key violations, etc.
  ///
  /// Example:
  /// ```dart
  /// ErrorInjectionHelpers.simulateConstraintViolation(
  ///   mockDbHelper,
  ///   operation: 'insertRecipe',
  ///   constraint: 'unique_recipe_name',
  /// );
  /// ```
  static void simulateConstraintViolation(
    MockDatabaseHelper mockDbHelper, {
    required String operation,
    String constraint = 'UNIQUE constraint failed',
  }) {
    final exception = Exception('$constraint: Constraint violation');
    mockDbHelper.failOnOperation(operation, exception: exception);
  }

  /// Simulates a foreign key constraint error.
  ///
  /// Example:
  /// ```dart
  /// ErrorInjectionHelpers.simulateForeignKeyError(
  ///   mockDbHelper,
  ///   operation: 'deleteMeal',
  ///   message: 'Cannot delete meal with associated recipes',
  /// );
  /// ```
  static void simulateForeignKeyError(
    MockDatabaseHelper mockDbHelper, {
    required String operation,
    String? message,
  }) {
    final errorMsg = message ?? 'FOREIGN KEY constraint failed';
    final exception = Exception(errorMsg);
    mockDbHelper.failOnOperation(operation, exception: exception);
  }

  /// Simulates a database locked error.
  ///
  /// Example:
  /// ```dart
  /// ErrorInjectionHelpers.simulateDatabaseLocked(
  ///   mockDbHelper,
  ///   operation: 'insertMeal',
  /// );
  /// ```
  static void simulateDatabaseLocked(
    MockDatabaseHelper mockDbHelper, {
    String? operation,
  }) {
    final exception = Exception('Database is locked');
    if (operation != null) {
      mockDbHelper.failOnOperation(operation, exception: exception);
    }
  }

  /// Simulates a timeout error.
  ///
  /// Example:
  /// ```dart
  /// ErrorInjectionHelpers.simulateTimeout(
  ///   mockDbHelper,
  ///   operation: 'getAllRecipes',
  /// );
  /// ```
  static void simulateTimeout(
    MockDatabaseHelper mockDbHelper, {
    required String operation,
  }) {
    final exception = Exception('Operation timed out');
    mockDbHelper.failOnOperation(operation, exception: exception);
  }

  /// Simulates a query failure.
  ///
  /// Example:
  /// ```dart
  /// ErrorInjectionHelpers.simulateQueryFailure(
  ///   mockDbHelper,
  ///   operation: 'getMeal',
  ///   reason: 'Invalid SQL syntax',
  /// );
  /// ```
  static void simulateQueryFailure(
    MockDatabaseHelper mockDbHelper, {
    required String operation,
    String? reason,
  }) {
    final errorMsg = reason ?? 'Query execution failed';
    final exception = Exception(errorMsg);
    mockDbHelper.failOnOperation(operation, exception: exception);
  }

  /// Helper to get appropriate exception for error type.
  static Exception _getExceptionForErrorType(ErrorType errorType) {
    switch (errorType) {
      case ErrorType.databaseNotInitialized:
        return Exception('Database not initialized');
      case ErrorType.databaseLocked:
        return Exception('Database is locked');
      case ErrorType.insertFailed:
        return Exception('Insert operation failed');
      case ErrorType.updateFailed:
        return Exception('Update operation failed');
      case ErrorType.deleteFailed:
        return Exception('Delete operation failed');
      case ErrorType.queryFailed:
        return Exception('Query execution failed');
      case ErrorType.constraintViolation:
        return Exception('UNIQUE constraint failed');
      case ErrorType.timeout:
        return Exception('Operation timed out');
      case ErrorType.validation:
        return Exception('Validation failed');
      case ErrorType.network:
        return Exception('Network error');
      case ErrorType.generic:
        return Exception('An error occurred');
    }
  }
}

/// Validation Error Injection Helpers
///
/// Utilities for testing validation error scenarios.
class ValidationErrorHelpers {
  /// Creates a validation error message for a specific field.
  ///
  /// Example:
  /// ```dart
  /// final error = ValidationErrorHelpers.createFieldError(
  ///   fieldName: 'servings',
  ///   errorType: ValidationErrorType.required,
  /// );
  /// // Returns: 'Servings is required'
  /// ```
  static String createFieldError({
    required String fieldName,
    required ValidationErrorType errorType,
  }) {
    switch (errorType) {
      case ValidationErrorType.required:
        return '$fieldName is required';
      case ValidationErrorType.invalid:
        return '$fieldName is invalid';
      case ValidationErrorType.tooShort:
        return '$fieldName is too short';
      case ValidationErrorType.tooLong:
        return '$fieldName is too long';
      case ValidationErrorType.outOfRange:
        return '$fieldName is out of range';
      case ValidationErrorType.invalidFormat:
        return '$fieldName has invalid format';
      case ValidationErrorType.notUnique:
        return '$fieldName must be unique';
    }
  }

  /// Creates a numeric validation error.
  ///
  /// Example:
  /// ```dart
  /// final error = ValidationErrorHelpers.numericError(
  ///   fieldName: 'servings',
  ///   min: 1,
  ///   max: 100,
  /// );
  /// ```
  static String numericError({
    required String fieldName,
    int? min,
    int? max,
  }) {
    if (min != null && max != null) {
      return '$fieldName must be between $min and $max';
    } else if (min != null) {
      return '$fieldName must be at least $min';
    } else if (max != null) {
      return '$fieldName must be at most $max';
    }
    return '$fieldName is invalid';
  }
}

/// Types of validation errors for testing.
enum ValidationErrorType {
  /// Field is required but empty
  required,

  /// Field value is invalid
  invalid,

  /// Text is too short
  tooShort,

  /// Text is too long
  tooLong,

  /// Numeric value out of range
  outOfRange,

  /// Invalid format (e.g., email, date)
  invalidFormat,

  /// Value must be unique
  notUnique,
}

/// Recovery Path Verification Helpers
///
/// Utilities for verifying that error recovery paths work correctly.
class RecoveryPathHelpers {
  /// Verifies that a retry action is available and functional.
  ///
  /// Example:
  /// ```dart
  /// await RecoveryPathHelpers.verifyRetryAvailable(
  ///   tester,
  ///   retryButtonText: 'Try Again',
  /// );
  /// ```
  static Future<void> verifyRetryAvailable(
    tester, {
    String retryButtonText = 'Retry',
  }) async {
    final retryButton = find.text(retryButtonText);
    expect(retryButton, findsOneWidget,
        reason: 'Retry button should be available after error');

    // Verify button is tappable
    await tester.tap(retryButton);
    await tester.pump();
  }

  /// Verifies that error state clears after successful retry.
  ///
  /// Example:
  /// ```dart
  /// await RecoveryPathHelpers.verifyErrorCleared(tester);
  /// ```
  static void verifyErrorCleared(tester) {
    // Verify common error indicators are gone
    expect(
      find.textContaining('error', skipOffstage: false),
      findsNothing,
      reason: 'Error messages should be cleared after successful retry',
    );
    expect(
      find.textContaining('failed', skipOffstage: false),
      findsNothing,
      reason: 'Failure messages should be cleared after successful retry',
    );
  }

  /// Verifies that data remains consistent after error and recovery.
  ///
  /// Example:
  /// ```dart
  /// RecoveryPathHelpers.verifyDataConsistency(
  ///   mockDbHelper,
  ///   expectedRecipeCount: 5,
  ///   expectedMealCount: 3,
  /// );
  /// ```
  static void verifyDataConsistency(
    MockDatabaseHelper mockDbHelper, {
    int? expectedRecipeCount,
    int? expectedMealCount,
    int? expectedIngredientCount,
  }) {
    if (expectedRecipeCount != null) {
      expect(
        mockDbHelper.recipes.length,
        equals(expectedRecipeCount),
        reason: 'Recipe count should match expected after recovery',
      );
    }
    if (expectedMealCount != null) {
      expect(
        mockDbHelper.meals.length,
        equals(expectedMealCount),
        reason: 'Meal count should match expected after recovery',
      );
    }
    if (expectedIngredientCount != null) {
      expect(
        mockDbHelper.ingredients.length,
        equals(expectedIngredientCount),
        reason: 'Ingredient count should match expected after recovery',
      );
    }
  }
}
