// integration_test/e2e_database_verification_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gastrobrain/main.dart';
import 'package:gastrobrain/database/database_helper.dart';

/// Baby Step 4: Database Verification
///
/// This test verifies database interaction patterns:
/// 1. Opens Add Recipe form
/// 2. Fills minimal required data
/// 3. Closes without saving (using back button)
/// 4. Verifies database query and cleanup patterns work correctly
///
/// This establishes database interaction patterns for future tests.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E - Database Verification (Baby Step 4)', () {
    testWidgets('Verify database query patterns and cleanup',
        (WidgetTester tester) async {
      // Test data setup
      final testRecipeName = 'E2E DB Test ${DateTime.now().millisecondsSinceEpoch}';

      // SETUP: Launch the app
      WidgetsFlutterBinding.ensureInitialized();
      await tester.pumpWidget(const GastrobrainApp());
      await tester.pumpAndSettle(const Duration(seconds: 10));

      print('=== SETUP COMPLETE ===');
      print('App launched and settled');

      // Get database helper
      final dbHelper = DatabaseHelper();

      // VERIFY: Can query database
      print('=== TESTING DATABASE ACCESS ===');
      final initialRecipes = await dbHelper.getAllRecipes();
      final initialCount = initialRecipes.length;
      print('✓ Successfully queried database');
      print('Initial recipe count: $initialCount');

      // VERIFY: Can search for specific recipe (should not exist)
      final searchResults = initialRecipes.where((r) => r.name == testRecipeName).toList();
      expect(searchResults.isEmpty, isTrue,
          reason: 'Test recipe should not exist yet');
      print('✓ Successfully searched database');

      // Open form to verify UI interaction
      final bottomNavBar = find.byType(BottomNavigationBar);
      expect(bottomNavBar, findsOneWidget);

      print('=== OPENING ADD RECIPE FORM ===');
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);
      await tester.tap(fab);
      await tester.pumpAndSettle();

      // VERIFY: Form opened
      final textFields = find.byType(TextFormField);
      expect(textFields, findsWidgets);
      print('✓ Form opened successfully');

      // Enter some text
      print('=== INTERACTING WITH FORM ===');
      await tester.enterText(textFields.first, testRecipeName);
      await tester.pumpAndSettle();
      expect(find.text(testRecipeName), findsOneWidget);
      print('✓ Entered text in form');

      // Close form WITHOUT saving
      print('=== CLOSING FORM WITHOUT SAVING ===');
      final backButton = find.byType(BackButton);
      if (backButton.evaluate().isEmpty) {
        final backIcon = find.byIcon(Icons.arrow_back);
        expect(backIcon, findsOneWidget);
        await tester.tap(backIcon);
      } else {
        await tester.tap(backButton);
      }
      await tester.pumpAndSettle();
      print('✓ Form closed');

      // VERIFY: Back on main screen
      expect(bottomNavBar, findsOneWidget);
      expect(fab, findsOneWidget);
      print('✓ Back on main screen');

      // VERIFY: Database unchanged (no save occurred)
      print('=== VERIFYING DATABASE STATE ===');
      final finalRecipes = await dbHelper.getAllRecipes();
      final finalCount = finalRecipes.length;

      expect(finalCount, equals(initialCount),
          reason: 'Recipe count should not change when closing without saving');
      print('✓ Database unchanged (count: $finalCount)');

      // Verify test recipe doesn't exist
      final testRecipes = finalRecipes.where((r) => r.name == testRecipeName).toList();
      expect(testRecipes.isEmpty, isTrue,
          reason: 'Test recipe should not exist in database');
      print('✓ Test recipe not in database');

      print('');
      print('=== 🎉 DATABASE VERIFICATION TEST PASSED! 🎉 ===');
      print('✓ Database query operations work correctly');
      print('✓ Can search and filter recipes');
      print('✓ Form interaction works without affecting database');
      print('✓ Verified cleanup patterns (no test data left behind)');
    });
  });
}
