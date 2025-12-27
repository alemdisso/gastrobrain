// test/helpers/dialog_test_helpers.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_utils/test_app_wrapper.dart';
import '../mocks/mock_database_helper.dart';

/// Dialog Test Helpers
///
/// Common utilities for testing Dialog widgets in Flutter tests.
/// These helpers make it easier to open, interact with, and verify
/// dialog behavior during widget testing.
///
/// Example usage:
/// ```dart
/// testWidgets('dialog returns value on save', (tester) async {
///   final result = await DialogTestHelpers.openDialogAndCapture<MyData>(
///     tester,
///     dialogBuilder: (context) => MyDialog(),
///   );
///
///   await DialogTestHelpers.tapDialogButton(tester, 'Save');
///   await tester.pumpAndSettle();
///
///   expect(result.value, isNotNull);
/// });
/// ```
class DialogTestHelpers {
  /// Opens a dialog and returns a [DialogResult] wrapper for capturing the return value.
  ///
  /// This helper wraps the dialog in a proper test context with localization
  /// and provides a button to trigger the dialog.
  ///
  /// Example:
  /// ```dart
  /// final result = await DialogTestHelpers.openDialogAndCapture<Map<String, dynamic>>(
  ///   tester,
  ///   dialogBuilder: (context) => MealRecordingDialog(recipe: testRecipe),
  /// );
  ///
  /// // Interact with dialog...
  /// await DialogTestHelpers.tapDialogButton(tester, 'Save');
  /// await tester.pumpAndSettle();
  ///
  /// expect(result.value, isNotNull);
  /// expect(result.value['servings'], equals(2));
  /// ```
  static Future<DialogResult<T>> openDialogAndCapture<T>(
    WidgetTester tester, {
    required Widget Function(BuildContext) dialogBuilder,
    String triggerButtonText = 'Show Dialog',
  }) async {
    final result = DialogResult<T>();

    await tester.pumpWidget(
      wrapWithLocalizations(Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              final dialogResult = await showDialog<T>(
                context: context,
                builder: dialogBuilder,
              );
              result._value = dialogResult;
            },
            child: Text(triggerButtonText),
          ),
        ),
      )),
    );

    // Tap button to show dialog
    await tester.tap(find.text(triggerButtonText));
    await tester.pumpAndSettle();

    return result;
  }

  /// Opens a dialog in a test context.
  ///
  /// Use this for simple dialog testing where you don't need to capture
  /// the return value. For return value testing, use [openDialogAndCapture].
  ///
  /// Example:
  /// ```dart
  /// await DialogTestHelpers.openDialog(
  ///   tester,
  ///   dialogBuilder: (context) => AlertDialog(title: Text('Test')),
  /// );
  ///
  /// expect(find.text('Test'), findsOneWidget);
  /// ```
  static Future<void> openDialog(
    WidgetTester tester, {
    required Widget Function(BuildContext) dialogBuilder,
    String triggerButtonText = 'Show Dialog',
  }) async {
    await tester.pumpWidget(
      wrapWithLocalizations(Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: dialogBuilder,
              );
            },
            child: Text(triggerButtonText),
          ),
        ),
      )),
    );

    // Tap button to show dialog
    await tester.tap(find.text(triggerButtonText));
    await tester.pumpAndSettle();
  }

  /// Finds a dialog by its type.
  ///
  /// Type-safe way to locate a specific dialog widget in the widget tree.
  ///
  /// Example:
  /// ```dart
  /// expect(DialogTestHelpers.findDialogByType<MealRecordingDialog>(), findsOneWidget);
  /// ```
  static Finder findDialogByType<T>() {
    return find.byType(T);
  }

  /// Taps a button in the dialog by its text.
  ///
  /// Common button texts: 'Save', 'Cancel', 'Cancelar', 'Salvar Alterações'
  ///
  /// Example:
  /// ```dart
  /// await DialogTestHelpers.tapDialogButton(tester, 'Save');
  /// await tester.pumpAndSettle();
  /// ```
  static Future<void> tapDialogButton(
    WidgetTester tester,
    String buttonText,
  ) async {
    await tester.tap(find.text(buttonText));
  }

  /// Fills a text field in the dialog.
  ///
  /// Example:
  /// ```dart
  /// await DialogTestHelpers.fillTextField(tester, 'Notes', 'Test notes');
  /// await tester.pumpAndSettle();
  /// ```
  static Future<void> fillTextField(
    WidgetTester tester,
    String fieldLabel,
    String value,
  ) async {
    final field = find.widgetWithText(TextFormField, fieldLabel);
    await tester.enterText(field, value);
  }

  /// Fills a text field by finding it with a widget containing specific text.
  ///
  /// Useful when the field doesn't have a label or you need more specific targeting.
  ///
  /// Example:
  /// ```dart
  /// await DialogTestHelpers.fillTextFieldContaining(tester, '3', '5');
  /// ```
  static Future<void> fillTextFieldContaining(
    WidgetTester tester,
    String containingText,
    String newValue,
  ) async {
    final field = find.widgetWithText(TextFormField, containingText);
    await tester.enterText(field, newValue);
  }

  /// Verifies the dialog has closed (is no longer in the widget tree).
  ///
  /// Example:
  /// ```dart
  /// await DialogTestHelpers.tapDialogButton(tester, 'Cancel');
  /// await tester.pumpAndSettle();
  /// DialogTestHelpers.verifyDialogClosed<MyDialog>();
  /// ```
  static void verifyDialogClosed<T>() {
    expect(find.byType(T), findsNothing);
  }

  /// Verifies the dialog returned the expected value.
  ///
  /// Example:
  /// ```dart
  /// final result = await DialogTestHelpers.openDialogAndCapture<int>(
  ///   tester,
  ///   dialogBuilder: (context) => NumberPickerDialog(),
  /// );
  ///
  /// // ... interact with dialog ...
  ///
  /// DialogTestHelpers.verifyDialogReturnValue(result, 5);
  /// ```
  static void verifyDialogReturnValue<T>(DialogResult<T> result, T expected) {
    expect(result.value, equals(expected));
  }

  /// Verifies the dialog returned null (was cancelled).
  ///
  /// Example:
  /// ```dart
  /// final result = await DialogTestHelpers.openDialogAndCapture<Map>(
  ///   tester,
  ///   dialogBuilder: (context) => MyDialog(),
  /// );
  ///
  /// await DialogTestHelpers.tapDialogButton(tester, 'Cancel');
  /// await tester.pumpAndSettle();
  ///
  /// DialogTestHelpers.verifyDialogCancelled(result);
  /// ```
  static void verifyDialogCancelled<T>(DialogResult<T> result) {
    expect(result.value, isNull);
  }

  /// Verifies no side effects occurred in the database after dialog cancellation.
  ///
  /// Takes a snapshot of database state before and after, ensuring they match.
  ///
  /// Example:
  /// ```dart
  /// await DialogTestHelpers.verifyNoSideEffects(
  ///   mockDbHelper,
  ///   beforeAction: () async {
  ///     // Open and cancel dialog
  ///     await DialogTestHelpers.tapDialogButton(tester, 'Cancel');
  ///     await tester.pumpAndSettle();
  ///   },
  /// );
  /// ```
  static Future<void> verifyNoSideEffects(
    MockDatabaseHelper mockDbHelper, {
    required Future<void> Function() beforeAction,
  }) async {
    // Take snapshot before
    final recipesBefore = Map<String, dynamic>.from(mockDbHelper.recipes);
    final ingredientsBefore = Map<String, dynamic>.from(mockDbHelper.ingredients);
    final mealsBefore = Map<String, dynamic>.from(mockDbHelper.meals);

    // Perform action (e.g., cancel dialog)
    await beforeAction();

    // Verify database unchanged
    expect(mockDbHelper.recipes, equals(recipesBefore),
        reason: 'Recipes should not change after cancelled dialog');
    expect(mockDbHelper.ingredients, equals(ingredientsBefore),
        reason: 'Ingredients should not change after cancelled dialog');
    expect(mockDbHelper.meals, equals(mealsBefore),
        reason: 'Meals should not change after cancelled dialog');
  }

  /// Simulates tapping outside the dialog to dismiss it.
  ///
  /// Example:
  /// ```dart
  /// await DialogTestHelpers.tapOutsideDialog(tester);
  /// await tester.pumpAndSettle();
  /// DialogTestHelpers.verifyDialogClosed<MyDialog>();
  /// ```
  static Future<void> tapOutsideDialog(WidgetTester tester) async {
    // Tap on the barrier (outside the dialog)
    await tester.tapAt(const Offset(10, 10));
  }

  /// Simulates pressing the back button to dismiss the dialog.
  ///
  /// Example:
  /// ```dart
  /// await DialogTestHelpers.pressBackButton(tester);
  /// await tester.pumpAndSettle();
  /// DialogTestHelpers.verifyDialogClosed<MyDialog>();
  /// ```
  static Future<void> pressBackButton(WidgetTester tester) async {
    final NavigatorState navigator = tester.state(find.byType(Navigator));
    navigator.pop();
  }

  /// Waits for dialog animation to complete.
  ///
  /// Call this after showing a dialog to ensure it's fully rendered.
  ///
  /// Example:
  /// ```dart
  /// await tester.tap(find.text('Show Dialog'));
  /// await DialogTestHelpers.waitForDialogAnimation(tester);
  /// // Now dialog is fully visible
  /// ```
  static Future<void> waitForDialogAnimation(WidgetTester tester) async {
    // Trigger the frame that builds the dialog
    await tester.pump();
    // Wait for the entrance animation to complete
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// Fills a form in the dialog with multiple fields.
  ///
  /// The fields map should have field labels as keys and values to enter.
  ///
  /// Example:
  /// ```dart
  /// await DialogTestHelpers.fillDialogForm(tester, {
  ///   'Name': 'Test Recipe',
  ///   'Servings': '4',
  ///   'Notes': 'Test notes',
  /// });
  /// ```
  static Future<void> fillDialogForm(
    WidgetTester tester,
    Map<String, String> fields,
  ) async {
    for (final entry in fields.entries) {
      await fillTextField(tester, entry.key, entry.value);
    }
    await tester.pump();
  }
}

/// Wrapper class for capturing dialog return values.
///
/// Used by [DialogTestHelpers.openDialogAndCapture] to capture the value
/// returned when the dialog closes.
///
/// Example:
/// ```dart
/// final result = DialogResult<int>();
/// // ... show dialog and capture result ...
/// print(result.value); // The returned value, or null if cancelled
/// ```
class DialogResult<T> {
  T? _value;

  /// The value returned by the dialog, or null if cancelled.
  T? get value => _value;

  /// Whether the dialog returned a non-null value.
  bool get hasValue => _value != null;

  /// Whether the dialog was cancelled (returned null).
  bool get wasCancelled => _value == null;
}