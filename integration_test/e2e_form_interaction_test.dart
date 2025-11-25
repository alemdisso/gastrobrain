// integration_test/e2e_form_interaction_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gastrobrain/main.dart';
import 'package:gastrobrain/database/database_helper.dart';

/// Baby Step 3: Form Interaction
///
/// This test verifies that we can:
/// 1. Navigate to a form screen (Add Recipe)
/// 2. Interact with form fields
/// 3. Close without saving
/// 4. Verify no data was persisted
///
/// This establishes the foundation for testing form workflows.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E - Form Interaction (Baby Step 3)', () {
    testWidgets('Open Add Recipe form, enter text, and close without saving',
        (WidgetTester tester) async {
      // SETUP: Launch the app
      WidgetsFlutterBinding.ensureInitialized();
      await tester.pumpWidget(const GastrobrainApp());
      await tester.pumpAndSettle(const Duration(seconds: 10));

      print('=== SETUP COMPLETE ===');
      print('App launched and settled');

      // Get initial recipe count
      final dbHelper = DatabaseHelper();
      final initialRecipes = await dbHelper.getAllRecipes();
      final initialCount = initialRecipes.length;
      print('Initial recipe count: $initialCount');

      // VERIFY: We're on the Recipes tab (default)
      final bottomNavBar = find.byType(BottomNavigationBar);
      expect(bottomNavBar, findsOneWidget);

      // Find and tap the FAB (FloatingActionButton)
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget, reason: 'FAB should be visible on Recipes tab');

      print('=== TAPPING FAB ===');
      await tester.tap(fab);
      await tester.pumpAndSettle();
      print('FAB tapped, waiting for Add Recipe screen');

      // VERIFY: Add Recipe screen opened
      // Look for the app bar title or a specific widget on the Add Recipe screen
      final appBar = find.byType(AppBar);
      expect(appBar, findsWidgets, reason: 'AppBar should be present');

      // Find the recipe name TextField
      // We'll look for a TextField that's likely the name field (first one)
      final textFields = find.byType(TextFormField);
      expect(textFields, findsWidgets,
          reason: 'Add Recipe screen should have form fields');

      print('=== INTERACTING WITH FORM ===');
      print('Found ${textFields.evaluate().length} text fields');

      // Enter text in the first TextField (recipe name)
      final firstTextField = textFields.first;
      await tester.enterText(firstTextField, 'Test Recipe E2E');
      await tester.pumpAndSettle();
      print('Entered text: "Test Recipe E2E"');

      // VERIFY: Text was entered
      expect(find.text('Test Recipe E2E'), findsOneWidget,
          reason: 'Entered text should be visible in the form');

      // ACT: Close without saving by tapping back button
      final backButton = find.byType(BackButton);
      if (backButton.evaluate().isEmpty) {
        // If no BackButton, try finding back arrow icon
        final backIcon = find.byIcon(Icons.arrow_back);
        expect(backIcon, findsOneWidget,
            reason: 'Back button should be present');
        await tester.tap(backIcon);
      } else {
        await tester.tap(backButton);
      }

      await tester.pumpAndSettle();
      print('=== CLOSED FORM ===');
      print('Back button tapped, should be back on Recipes screen');

      // VERIFY: We're back on the Recipes tab
      expect(bottomNavBar, findsOneWidget,
          reason: 'Should be back on main screen with bottom nav');
      expect(fab, findsOneWidget,
          reason: 'FAB should be visible again on Recipes tab');

      // VERIFY: No data was persisted
      final finalRecipes = await dbHelper.getAllRecipes();
      final finalCount = finalRecipes.length;
      print('Final recipe count: $finalCount');

      expect(finalCount, equals(initialCount),
          reason: 'Recipe count should not change when closing without saving');

      // Double-check: No recipe with our test name exists
      final testRecipe = finalRecipes.where((r) => r.name == 'Test Recipe E2E');
      expect(testRecipe.isEmpty, isTrue,
          reason: 'Test recipe should not exist in database');

      print('=== TEST COMPLETE ===');
      print('✓ Successfully opened form');
      print('✓ Successfully entered text');
      print('✓ Successfully closed without saving');
      print('✓ Verified no data was persisted');
    });
  });
}
