// integration_test/TEST_TEMPLATE.dart
//
// Template for creating new E2E integration tests
// Copy this file and modify for your specific test scenario

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gastrobrain/database/database_helper.dart';
import 'helpers/e2e_test_helpers.dart';

/// [REPLACE WITH YOUR TEST DESCRIPTION]
///
/// This test verifies [DESCRIBE WHAT THIS TEST DOES]:
/// 1. [Step 1]
/// 2. [Step 2]
/// 3. [Step 3]
/// ...
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E - [TEST CATEGORY]', () {
    testWidgets('[TEST NAME]', (WidgetTester tester) async {
      // ========================================================================
      // TEST DATA SETUP
      // ========================================================================

      // Define test data
      final testData = 'Test Data ${DateTime.now().millisecondsSinceEpoch}';
      String? createdResourceId; // For cleanup

      try {
        // ======================================================================
        // SETUP: Launch and Initialize
        // ======================================================================

        print('=== LAUNCHING APP ===');
        await E2ETestHelpers.launchApp(tester);
        print('✓ App launched and initialized');

        // ignore: unused_local_variable
        final dbHelper = DatabaseHelper();

        // Optional: Check initial state
        // final initialData = await dbHelper.getSomeData();
        // print('Initial state: ${initialData.length} items');

        // Verify starting screen
        E2ETestHelpers.verifyOnMainScreen();
        print('✓ On main screen');

        // ======================================================================
        // ACT: Perform Test Actions
        // ======================================================================

        // Example: Navigate to a form
        print('\n=== NAVIGATING TO FORM ===');
        final fieldCount = await E2ETestHelpers.openAddRecipeForm(tester);
        print('✓ Form opened with $fieldCount fields');

        // Example: Fill form fields
        print('\n=== FILLING FORM ===');
        await E2ETestHelpers.fillTextFieldByIndex(tester, 0, testData);
        print('✓ Data entered');

        // Verify field was filled
        expect(find.text(testData), findsOneWidget);

        // Example: Save/Submit
        print('\n=== SAVING ===');
        await E2ETestHelpers.tapSaveButton(tester);
        print('✓ Save button tapped');

        // Wait for async operations
        await E2ETestHelpers.waitForAsyncOperations();

        // ======================================================================
        // VERIFY: Check Results
        // ======================================================================

        // Verify navigation/state
        print('\n=== VERIFYING STATE ===');
        try {
          E2ETestHelpers.verifyOnMainScreen();
          print('✓ Back on main screen');
        } catch (e) {
          print('⚠ Not on main screen - action may have failed');
          E2ETestHelpers.printScreenState('Current state');
        }

        // Verify database
        print('\n=== VERIFYING DATABASE ===');
        // createdResourceId = await E2ETestHelpers.verifySomethingInDatabase(
        //   dbHelper,
        //   testData,
        // );

        // Add your custom database verification here
        // final results = await dbHelper.getSomeData();
        // expect(results.where((r) => r.name == testData), isNotEmpty);

        // ignore: unnecessary_null_comparison
        if (createdResourceId != null) {
          print('✅ SUCCESS! Data verified in database');
          print('Resource ID: $createdResourceId');

          // Verify UI
          print('\n=== VERIFYING UI ===');
          // final foundInUI = await E2ETestHelpers.verifySomethingInUI(
          //   tester,
          //   testData,
          // );

          // if (foundInUI) {
          //   print('✅ Data appears in UI!');
          // }

          print('\n=== 🎉 TEST PASSED! 🎉 ===');
        } else {
          print('⚠ Expected data not found');
          print('Test failed - check logs above for details');
        }
      } finally {
        // ======================================================================
        // CLEANUP: Remove Test Data
        // ======================================================================

        // ignore: unnecessary_null_comparison
        if (createdResourceId != null) {
          print('\n=== CLEANUP ===');
          // ignore: unused_local_variable
          final dbHelper = DatabaseHelper();

          // Add your cleanup logic here
          // await E2ETestHelpers.deleteTestResource(dbHelper, createdResourceId);

          print('✓ Test data cleaned up');
        } else {
          print('\n=== NO CLEANUP NEEDED ===');
        }
      }
    });
  });
}

// ============================================================================
// TEMPLATE USAGE INSTRUCTIONS
// ============================================================================
//
// 1. Copy this file to a new test file with a descriptive name:
//    Example: e2e_meal_planning_test.dart
//
// 2. Update the file header comment with your test description
//
// 3. Replace [TEST CATEGORY] and [TEST NAME] with appropriate values:
//    Example: 'E2E - Meal Planning' and 'Create weekly meal plan'
//
// 4. Define your test data in the TEST DATA SETUP section
//
// 5. Implement your test actions using helper methods:
//    - Navigation: tapBottomNavTab(), openAddRecipeForm(), etc.
//    - Forms: fillTextFieldByIndex/ByKey(), tapSaveButton()
//    - Verification: verifyOnMainScreen(), verifyInDatabase/UI()
//
// 6. Add custom verification logic for your specific test case
//
// 7. Implement cleanup to remove any test data created
//
// 8. Run your test:
//    flutter test integration_test/your_test_file.dart
//
// ============================================================================
// AVAILABLE HELPER METHODS
// ============================================================================
//
// See integration_test/helpers/e2e_test_helpers.dart for full list:
//
// App Initialization:
//   - launchApp(tester)
//
// Navigation:
//   - tapBottomNavTab(tester, icon)
//   - openAddRecipeForm(tester)
//   - closeFormWithBackButton(tester)
//
// Form Interaction:
//   - fillTextFieldByIndex(tester, index, text)
//   - fillTextFieldByKey(tester, key, text)
//   - scrollDown/Up(tester, offset: 500)
//   - tapSaveButton(tester)
//
// Verification:
//   - verifyOnMainScreen()
//   - verifyOnFormScreen(expectedFieldCount: n)
//   - verifyRecipeInDatabase(dbHelper, name)
//   - verifyRecipeInUI(tester, name)
//
// Cleanup:
//   - deleteTestRecipe(dbHelper, id)
//
// Diagnostics:
//   - printScreenState(label)
//   - waitForAsyncOperations(duration: ...)
//
// ============================================================================
// BEST PRACTICES
// ============================================================================
//
// 1. Use descriptive test names that explain what's being tested
//
// 2. Always include cleanup in a try-finally block
//
// 3. Use unique test data (timestamp) to avoid conflicts
//
// 4. Add print statements to track test progress
//
// 5. Verify both database state AND UI state when relevant
//
// 6. Use helper methods instead of direct widget interaction
//
// 7. Wait for async operations (database, navigation) before verifying
//
// 8. Handle failure cases gracefully (try-catch where appropriate)
//
// 9. Keep tests focused on one user workflow
//
// 10. Document what the test is verifying in comments
//
// ============================================================================
