// test/helpers/edge_case_test_helpers.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../mocks/mock_database_helper.dart';

/// Edge Case Test Helpers
///
/// Utilities for testing edge cases, boundary conditions, and error scenarios
/// across the Gastrobrain application. Extends patterns from DialogTestHelper
/// for app-wide edge case testing.
///
/// Example usage:
/// ```dart
/// testWidgets('handles empty state', (tester) async {
///   await EdgeCaseTestHelpers.verifyEmptyState(
///     tester,
///     expectedMessage: 'No recipes found',
///   );
/// });
///
/// testWidgets('handles boundary values', (tester) async {
///   await EdgeCaseTestHelpers.fillWithBoundaryValue(
///     tester,
///     fieldFinder: find.byKey(Key('servings')),
///     boundaryType: BoundaryType.maxInt,
///   );
/// });
/// ```
class EdgeCaseTestHelpers {
  /// Verifies that an empty state is displayed with the expected message.
  ///
  /// Use this to test screens/widgets when they have no data to display.
  ///
  /// Example:
  /// ```dart
  /// await EdgeCaseTestHelpers.verifyEmptyState(
  ///   tester,
  ///   expectedMessage: 'No recipes found',
  /// );
  /// ```
  static void verifyEmptyState(
    WidgetTester tester, {
    required String expectedMessage,
  }) {
    expect(find.text(expectedMessage), findsOneWidget,
        reason: 'Empty state message should be displayed');
  }

  /// Verifies that an empty state with a specific widget is displayed.
  ///
  /// Use when empty states use custom widgets instead of just text.
  ///
  /// Example:
  /// ```dart
  /// EdgeCaseTestHelpers.verifyEmptyStateWidget<EmptyRecipeList>(tester);
  /// ```
  static void verifyEmptyStateWidget<T>(WidgetTester tester) {
    expect(find.byType(T), findsOneWidget,
        reason: 'Empty state widget should be displayed');
  }

  /// Fills a text field with a boundary value based on the specified type.
  ///
  /// Use this to test how forms handle extreme values.
  ///
  /// Example:
  /// ```dart
  /// await EdgeCaseTestHelpers.fillWithBoundaryValue(
  ///   tester,
  ///   fieldFinder: find.byKey(Key('servings')),
  ///   boundaryType: BoundaryType.maxInt,
  /// );
  /// ```
  static Future<void> fillWithBoundaryValue(
    WidgetTester tester, {
    required Finder fieldFinder,
    required BoundaryType boundaryType,
  }) async {
    final value = _getBoundaryValue(boundaryType);
    await tester.enterText(fieldFinder, value);
    await tester.pump();
  }

  /// Fills a text field by label with a boundary value.
  ///
  /// Convenience method that finds field by label text.
  ///
  /// Example:
  /// ```dart
  /// await EdgeCaseTestHelpers.fillFieldWithBoundaryValue(
  ///   tester,
  ///   fieldLabel: 'Servings',
  ///   boundaryType: BoundaryType.zero,
  /// );
  /// ```
  static Future<void> fillFieldWithBoundaryValue(
    WidgetTester tester, {
    required String fieldLabel,
    required BoundaryType boundaryType,
  }) async {
    final field = find.widgetWithText(TextFormField, fieldLabel);
    await fillWithBoundaryValue(
      tester,
      fieldFinder: field,
      boundaryType: boundaryType,
    );
  }

  /// Simulates rapid taps on a target widget.
  ///
  /// Use this to test debouncing and duplicate operation prevention.
  ///
  /// Example:
  /// ```dart
  /// await EdgeCaseTestHelpers.simulateRapidTaps(
  ///   tester,
  ///   target: find.text('Save'),
  ///   tapCount: 10,
  /// );
  /// ```
  static Future<void> simulateRapidTaps(
    WidgetTester tester, {
    required Finder target,
    required int tapCount,
  }) async {
    for (int i = 0; i < tapCount; i++) {
      await tester.tap(target);
      // Small delay to avoid tester issues, but still rapid
      await tester.pump(const Duration(milliseconds: 10));
    }
  }

  /// Simulates concurrent operations by triggering multiple async functions.
  ///
  /// Use this to test race conditions and concurrent state modifications.
  ///
  /// Example:
  /// ```dart
  /// await EdgeCaseTestHelpers.simulateConcurrentOperations([
  ///   () async => await service.saveRecipe(recipe1),
  ///   () async => await service.saveRecipe(recipe2),
  /// ]);
  /// ```
  static Future<void> simulateConcurrentOperations(
    List<Future<void> Function()> operations,
  ) async {
    await Future.wait(operations.map((op) => op()));
  }

  /// Verifies that a loading state is displayed.
  ///
  /// Use this to verify async operations show appropriate loading indicators.
  ///
  /// Example:
  /// ```dart
  /// EdgeCaseTestHelpers.verifyLoadingState(tester);
  /// ```
  static void verifyLoadingState(WidgetTester tester) {
    expect(
      find.byType(CircularProgressIndicator),
      findsOneWidget,
      reason: 'Loading indicator should be displayed',
    );
  }

  /// Verifies that a loading state is NOT displayed.
  ///
  /// Use after async operations complete to ensure loading indicator is hidden.
  ///
  /// Example:
  /// ```dart
  /// await tester.pumpAndSettle();
  /// EdgeCaseTestHelpers.verifyNotLoadingState(tester);
  /// ```
  static void verifyNotLoadingState(WidgetTester tester) {
    expect(
      find.byType(CircularProgressIndicator),
      findsNothing,
      reason: 'Loading indicator should not be displayed',
    );
  }

  /// Verifies that an error message is displayed.
  ///
  /// Example:
  /// ```dart
  /// EdgeCaseTestHelpers.verifyErrorDisplayed(
  ///   tester,
  ///   expectedError: 'Failed to save recipe',
  /// );
  /// ```
  static void verifyErrorDisplayed(
    WidgetTester tester, {
    required String expectedError,
  }) {
    expect(
      find.textContaining(expectedError),
      findsOneWidget,
      reason: 'Error message should be displayed',
    );
  }

  /// Verifies that a recovery path is available after an error.
  ///
  /// Looks for common recovery actions like retry buttons or back navigation.
  ///
  /// Example:
  /// ```dart
  /// EdgeCaseTestHelpers.verifyRecoveryPath(
  ///   tester,
  ///   recoveryButtonText: 'Retry',
  /// );
  /// ```
  static void verifyRecoveryPath(
    WidgetTester tester, {
    String recoveryButtonText = 'Retry',
  }) {
    expect(
      find.text(recoveryButtonText),
      findsOneWidget,
      reason: 'Recovery action should be available',
    );
  }

  /// Verifies that the UI state is consistent after an error.
  ///
  /// Ensures forms, lists, and other UI elements remain usable after errors.
  ///
  /// Example:
  /// ```dart
  /// await EdgeCaseTestHelpers.verifyUIStateConsistent(
  ///   tester,
  ///   mockDbHelper,
  /// );
  /// ```
  static Future<void> verifyUIStateConsistent(
    WidgetTester tester,
    MockDatabaseHelper mockDbHelper,
  ) async {
    // Verify UI is responsive (can still interact)
    await tester.pumpAndSettle();

    // Common checks - screens should still be navigable
    // This is a basic check; specific tests should add their own verifications
    expect(find.byType(Scaffold), findsOneWidget,
        reason: 'Screen should still be rendered');
  }

  /// Verifies that list is scrollable when it contains many items.
  ///
  /// Example:
  /// ```dart
  /// EdgeCaseTestHelpers.verifyListScrollable(
  ///   tester,
  ///   listFinder: find.byType(ListView),
  /// );
  /// ```
  static void verifyListScrollable(
    WidgetTester tester, {
    required Finder listFinder,
  }) {
    final listView = tester.widget<ListView>(listFinder);
    expect(
      listView.physics,
      isNot(const NeverScrollableScrollPhysics()),
      reason: 'List should be scrollable',
    );
  }

  /// Scrolls a list to test performance with large datasets.
  ///
  /// Example:
  /// ```dart
  /// await EdgeCaseTestHelpers.scrollLargeList(
  ///   tester,
  ///   listFinder: find.byType(ListView),
  ///   scrollAmount: 5000.0,
  /// );
  /// ```
  static Future<void> scrollLargeList(
    WidgetTester tester, {
    required Finder listFinder,
    double scrollAmount = 1000.0,
  }) async {
    await tester.drag(listFinder, Offset(0, -scrollAmount));
    await tester.pumpAndSettle();
  }

  /// Verifies form validation triggers on submit.
  ///
  /// Example:
  /// ```dart
  /// await EdgeCaseTestHelpers.triggerFormValidation(
  ///   tester,
  ///   submitButtonText: 'Save',
  /// );
  /// ```
  static Future<void> triggerFormValidation(
    WidgetTester tester, {
    required String submitButtonText,
  }) async {
    await tester.tap(find.text(submitButtonText));
    await tester.pumpAndSettle();
  }

  /// Verifies that a validation error message is displayed.
  ///
  /// Example:
  /// ```dart
  /// EdgeCaseTestHelpers.verifyValidationError(
  ///   tester,
  ///   expectedError: 'Servings is required',
  /// );
  /// ```
  static void verifyValidationError(
    WidgetTester tester, {
    required String expectedError,
  }) {
    expect(
      find.text(expectedError),
      findsOneWidget,
      reason: 'Validation error should be displayed',
    );
  }

  /// Verifies no validation errors are displayed.
  ///
  /// Example:
  /// ```dart
  /// EdgeCaseTestHelpers.verifyNoValidationErrors(tester);
  /// ```
  static void verifyNoValidationErrors(WidgetTester tester) {
    // Common validation error patterns - adjust based on app's error display
    expect(
      find.textContaining('required'),
      findsNothing,
      reason: 'No required field errors should be displayed',
    );
    expect(
      find.textContaining('invalid'),
      findsNothing,
      reason: 'No invalid field errors should be displayed',
    );
  }

  /// Helper method to get boundary value string based on type.
  static String _getBoundaryValue(BoundaryType type) {
    switch (type) {
      case BoundaryType.empty:
        return '';
      case BoundaryType.whitespace:
        return '   ';
      case BoundaryType.zero:
        return '0';
      case BoundaryType.negative:
        return '-1';
      case BoundaryType.maxInt:
        return '999999';
      case BoundaryType.minInt:
        return '1';
      case BoundaryType.decimal:
        return '2.5';
      case BoundaryType.veryLongText:
        return 'A' * 1000;
      case BoundaryType.extremelyLongText:
        return 'B' * 10000;
      case BoundaryType.specialChars:
        return '<>"\'&';
      case BoundaryType.emoji:
        return '😀🎉🍕';
      case BoundaryType.unicode:
        return 'Crème brûlée';
      case BoundaryType.newlines:
        return 'Line 1\nLine 2\nLine 3';
    }
  }
}

/// Boundary value types for testing edge cases.
///
/// Use these with [EdgeCaseTestHelpers.fillWithBoundaryValue] to test
/// how forms and inputs handle extreme values.
enum BoundaryType {
  /// Empty string
  empty,

  /// Whitespace-only string
  whitespace,

  /// Zero (0)
  zero,

  /// Negative number (-1)
  negative,

  /// Very large integer (999999)
  maxInt,

  /// Minimum valid integer (1)
  minInt,

  /// Decimal number (2.5)
  decimal,

  /// Very long text (1000 characters)
  veryLongText,

  /// Extremely long text (10000 characters)
  extremelyLongText,

  /// Special HTML/XML characters
  specialChars,

  /// Emoji characters
  emoji,

  /// Unicode characters
  unicode,

  /// Text with newlines
  newlines,
}

/// Error types for error injection testing.
///
/// Use these to simulate different types of errors in tests.
enum ErrorType {
  /// Database not initialized
  databaseNotInitialized,

  /// Database locked
  databaseLocked,

  /// Insert operation failed
  insertFailed,

  /// Update operation failed
  updateFailed,

  /// Delete operation failed
  deleteFailed,

  /// Query failed
  queryFailed,

  /// Constraint violation
  constraintViolation,

  /// Timeout error
  timeout,

  /// Validation error
  validation,

  /// Network error (if applicable)
  network,

  /// Generic error
  generic,
}

/// Result wrapper for capturing operation results in tests.
///
/// Similar to DialogResult but for general operations.
///
/// Example:
/// ```dart
/// final result = OperationResult<Recipe>();
/// // ... perform operation ...
/// expect(result.isSuccess, isTrue);
/// expect(result.value, isNotNull);
/// ```
class OperationResult<T> {
  T? _value;
  String? _error;

  /// The value returned by the operation, or null if failed.
  T? get value => _value;

  /// Error message if operation failed, or null if successful.
  String? get error => _error;

  /// Whether the operation succeeded.
  bool get isSuccess => _value != null && _error == null;

  /// Whether the operation failed.
  bool get isFailure => _error != null;

  /// Sets the operation as successful with a value.
  void setSuccess(T value) {
    _value = value;
    _error = null;
  }

  /// Sets the operation as failed with an error message.
  void setError(String error) {
    _error = error;
    _value = null;
  }
}
