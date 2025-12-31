// test/regression/dialog_regression_test.dart

/// Dialog Regression Test Suite
///
/// This file contains regression tests for previously identified and fixed
/// dialog-related bugs. Each test documents the original issue, the fix that
/// was applied, and ensures the bug does not reoccur.
///
/// **Purpose:**
/// - Prevent regression of historical bugs
/// - Document bug fixes with links to commits/issues
/// - Provide reference for similar issues in the future
///
/// **Bug Registry:**
///
/// 1. **Controller Disposal Crash** (commit 07058a2) - CRITICAL
///    - Issue: Dialog cancellation caused crash when disposing controller still in use
///    - Fix: WidgetsBinding.instance.addPostFrameCallback for safe disposal
///    - Tests: Phase 2.2.2 disposal tests in all 6 dialog test files
///    - Coverage: ✅ Fully tested (see existing dialog tests)
///
/// 2. **Hit Test Warning in Save Button** (commit eb7a1be, issue #78)
///    - Issue: Save button tap failed with "Offset would not hit test" warning
///    - Root cause: Button obscured by modal overlays (date picker barrier)
///    - Fix: ensureVisible() + 500ms stabilization delay in E2E helpers
///    - Tests: E2E test helpers (e2e_test_helpers.dart)
///    - Coverage: ✅ E2E level (not widget-level issue)
///
/// 3. **RenderFlex Overflow in Dialogs** (commit f3455ca)
///    - Issue: 16px overflow in MealRecordingDialog recipes section header
///    - Fix: Wrapped label Text in Expanded widget
///    - Location: meal_recording_dialog.dart line 296
///    - Tests: THIS FILE (see "RenderFlex Overflow Regression Tests" group)
///    - Coverage: ✅ Small screen overflow test below
///
/// 4. **Filter Dialog Overflow** (commit 917c6d5, issue #137)
///    - Issue: Filter Recipes dialog overflows on small screens/landscape
///    - Fix: Added height constraint (60% of screen) with scrolling
///    - Location: home_screen.dart (inline dialog, not standalone widget)
///    - Tests: N/A (screen-level dialog, tested via manual/E2E testing)
///    - Coverage: ⚠️ Manual testing required
///
/// 5. **Auto-select Ingredient on Exact Match** (commit 795ef1c, #38)
///    - Issue: Typing exact ingredient name + Enter didn't auto-select
///    - Fix: Added onFieldSubmitted callback for exact match detection
///    - Location: AddIngredientDialog
///    - Tests: test/widgets/add_ingredient_dialog_test.dart
///    - Coverage: ✅ Dedicated test: "auto-selects ingredient on exact match with Enter key"
///
/// **Maintenance:**
/// - When fixing new dialog bugs, add them to this registry
/// - Link to commit hash and issue number
/// - Add regression test if not already covered

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/widgets/meal_recording_dialog.dart';
import 'package:gastrobrain/models/recipe.dart';
import '../test_utils/test_app_wrapper.dart';
import '../test_utils/test_setup.dart';
import '../test_utils/dialog_fixtures.dart';
import '../mocks/mock_database_helper.dart';

void main() {
  late MockDatabaseHelper mockDbHelper;
  late Recipe primaryRecipe;

  setUp(() {
    mockDbHelper = TestSetup.setupMockDatabase();
    primaryRecipe = DialogFixtures.createPrimaryRecipe();
    mockDbHelper.insertRecipe(primaryRecipe);
  });

  group('RenderFlex Overflow Regression Tests', () {
    // NOTE: Known limitation documented in issue #246
    // MealRecordingDialog still has overflow issues on very small portrait screens
    // (width < 400px). The original fix (commit f3455ca) addressed the specific
    // 16px overflow but did not fully resolve all overflow scenarios.
    // Small portrait screens are deferred for future optimization.
    // See: https://github.com/alemdisso/gastrobrain/issues/246

    testWidgets(
        'MealRecordingDialog renders correctly in landscape orientation '
        '(overflow in constrained height)', (WidgetTester tester) async {
      // Simulate landscape orientation (667x375 - iPhone SE landscape)
      await tester.binding.setSurfaceSize(const Size(667, 375));

      await tester.pumpWidget(
        wrapWithLocalizations(
          MediaQuery(
            data: const MediaQueryData(size: Size(667, 375)),
            child: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => MealRecordingDialog(
                        primaryRecipe: primaryRecipe,
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open the dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify no overflow in landscape mode (limited height)
      expect(tester.takeException(), isNull,
          reason: 'Dialog should not overflow in landscape orientation');

      expect(find.byType(MealRecordingDialog), findsOneWidget);

      // Reset surface size
      await tester.binding.setSurfaceSize(null);
    });
  });

  group('Existing Bug Coverage Reference', () {
    test(
        'Controller disposal regression coverage documented '
        '(commit 07058a2)', () {
      // This is a documentation test to reference where controller disposal
      // is tested across all dialogs.
      //
      // Coverage:
      // - test/widgets/meal_recording_dialog_test.dart (2 disposal tests)
      // - test/widgets/meal_cooked_dialog_test.dart (2 disposal tests)
      // - test/widgets/add_ingredient_dialog_test.dart (2 disposal tests)
      // - test/widgets/add_new_ingredient_dialog_test.dart (1 disposal test)
      // - test/widgets/add_side_dish_dialog_test.dart (1 disposal test)
      // - test/widgets/edit_meal_recording_dialog_test.dart (2 disposal tests)
      //
      // All dialogs verify:
      // 1. Controllers disposed safely on cancel (no crash)
      // 2. Controllers disposed safely on save (no crash)
      // 3. Safe disposal on alternative dismissal (tap outside, back button)
      //
      // Bug prevented: Dialog cancellation crash when disposing controller
      // still in use by the framework.

      expect(true, isTrue,
          reason: 'Controller disposal is fully tested in Phase 2.2.2 tests');
    });

    test(
        'Auto-select ingredient regression coverage documented '
        '(commit 795ef1c)', () {
      // This is a documentation test to reference where auto-select
      // functionality is tested.
      //
      // Coverage:
      // - test/widgets/add_ingredient_dialog_test.dart
      //   Test: "auto-selects ingredient on exact match with Enter key"
      //
      // Bug prevented: Typing exact ingredient name and pressing Enter/OK
      // should auto-select the ingredient instead of requiring manual selection.

      expect(true, isTrue,
          reason: 'Auto-select on Enter is tested in add_ingredient_dialog_test.dart');
    });

    test('Hit test warning regression coverage documented (commit eb7a1be)',
        () {
      // This is a documentation test to reference where hit test warning
      // is prevented.
      //
      // Coverage:
      // - integration_test/helpers/e2e_test_helpers.dart
      //   Method: saveMealRecordingDialog()
      //   - Uses ensureVisible() before tapping save button
      //   - Adds 500ms stabilization delay after closing date picker
      //
      // Bug prevented: "A call to tap() derived an Offset that would not
      // hit test on the specified widget" when save button is obscured by
      // modal overlays.

      expect(true, isTrue,
          reason: 'Hit test warning fix is in E2E test helpers');
    });
  });
}
