// test/helpers/snackbar_test_helpers.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Snackbar Test Helpers
///
/// Common utilities for testing SnackBar widgets in Flutter tests.
/// These helpers make it easier to find, verify, and interact with
/// snackbars during widget testing.
class SnackbarTestHelpers {
  /// Finds a SnackBar widget containing the specified text.
  ///
  /// This helper searches for a SnackBar and verifies it contains
  /// the expected text message.
  ///
  /// Example:
  /// ```dart
  /// expect(SnackbarTestHelpers.findSnackBarWithText('Success!'), findsOneWidget);
  /// ```
  static Finder findSnackBarWithText(String text) {
    return find.descendant(
      of: find.byType(SnackBar),
      matching: find.text(text),
    );
  }

  /// Expects a success snackbar with the given text to be present.
  ///
  /// This is a convenience method that verifies a snackbar with the
  /// expected success message is currently displayed.
  ///
  /// Example:
  /// ```dart
  /// await tester.tap(find.byType(SaveButton));
  /// await SnackbarTestHelpers.waitForSnackBar(tester);
  /// SnackbarTestHelpers.expectSuccessSnackBar('Saved successfully');
  /// ```
  static void expectSuccessSnackBar(String expectedText) {
    expect(findSnackBarWithText(expectedText), findsOneWidget);
  }

  /// Expects an error snackbar with the given text to be present.
  ///
  /// This is a convenience method that verifies a snackbar with the
  /// expected error message is currently displayed.
  ///
  /// Example:
  /// ```dart
  /// await tester.tap(find.byType(SaveButton));
  /// await SnackbarTestHelpers.waitForSnackBar(tester);
  /// SnackbarTestHelpers.expectErrorSnackBar('Error saving data');
  /// ```
  static void expectErrorSnackBar(String expectedText) {
    expect(findSnackBarWithText(expectedText), findsOneWidget);
  }

  /// Waits for a snackbar to appear and complete its entrance animation.
  ///
  /// Call this after triggering an action that should show a snackbar.
  /// This ensures the snackbar has been rendered and is visible before
  /// making assertions.
  ///
  /// Example:
  /// ```dart
  /// await tester.tap(find.byType(SaveButton));
  /// await SnackbarTestHelpers.waitForSnackBar(tester);
  /// expect(find.text('Saved!'), findsOneWidget);
  /// ```
  static Future<void> waitForSnackBar(WidgetTester tester) async {
    // Trigger the frame that builds the snackbar
    await tester.pump();
    // Wait for the entrance animation to complete (default is ~150ms)
    await tester.pump(const Duration(milliseconds: 200));
  }

  /// Dismisses the currently visible snackbar by swiping it away.
  ///
  /// This simulates the user dismissing the snackbar and waits for
  /// the dismiss animation to complete.
  ///
  /// Example:
  /// ```dart
  /// await SnackbarTestHelpers.dismissSnackBar(tester);
  /// expect(find.byType(SnackBar), findsNothing);
  /// ```
  static Future<void> dismissSnackBar(WidgetTester tester) async {
    // Swipe the snackbar down to dismiss it
    await tester.drag(find.byType(SnackBar), const Offset(0, 100));
    // Wait for the dismiss animation to complete
    await tester.pumpAndSettle();
  }

  /// Waits for the snackbar to auto-dismiss after its duration expires.
  ///
  /// By default, snackbars in the app are shown for 3 seconds.
  /// This helper waits for that duration plus animation time.
  ///
  /// Example:
  /// ```dart
  /// await SnackbarTestHelpers.waitForSnackBar(tester);
  /// expect(find.byType(SnackBar), findsOneWidget);
  /// await SnackbarTestHelpers.waitForSnackBarDismiss(tester);
  /// expect(find.byType(SnackBar), findsNothing);
  /// ```
  static Future<void> waitForSnackBarDismiss(
    WidgetTester tester, {
    Duration duration = const Duration(seconds: 3),
  }) async {
    // Wait for the duration + animation time
    await tester.pump(duration);
    await tester.pumpAndSettle();
  }
}
