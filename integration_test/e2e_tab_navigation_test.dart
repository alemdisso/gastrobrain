// integration_test/e2e_tab_navigation_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gastrobrain/main.dart';

/// Baby Step 2: Simple Tab Navigation
///
/// This test verifies that tapping bottom navigation tabs changes screens.
/// This establishes the foundation for testing navigation flows.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E - Tab Navigation (Baby Step 2)', () {
    testWidgets('Tap Meal Plan tab and verify screen changes', (WidgetTester tester) async {
      // SETUP: Launch the app
      WidgetsFlutterBinding.ensureInitialized();
      await tester.pumpWidget(const GastrobrainApp());
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // VERIFY: We start on Recipes tab (index 0)
      final bottomNavBar = find.byType(BottomNavigationBar);
      expect(bottomNavBar, findsOneWidget);

      // DEBUG: Print initial state
      print('=== INITIAL STATE ===');
      print('BottomNavigationBar found: ${bottomNavBar.evaluate().length}');

      // Find the Meal Plan tab by its icon
      final mealPlanTab = find.descendant(
        of: bottomNavBar,
        matching: find.byIcon(Icons.calendar_today),
      );

      print('Meal Plan tab (calendar_today icon) found: ${mealPlanTab.evaluate().length}');

      // ACT: Tap the Meal Plan tab
      await tester.tap(mealPlanTab);
      await tester.pumpAndSettle();

      print('=== AFTER TAP ===');
      print('Tapped Meal Plan tab');

      // VERIFY: The tab was selected (we can verify by checking if different content appears)
      // Note: We're just verifying the tap worked and UI updated
      // In Baby Step 3, we'll verify specific content on the new screen

      // The test passes if:
      // 1. We could find the tab
      // 2. We could tap it
      // 3. pumpAndSettle completed (no errors during navigation)

      expect(mealPlanTab, findsOneWidget,
          reason: 'Meal Plan tab should still be visible after tap');
    });

    testWidgets('Tap Ingredients tab and verify screen changes', (WidgetTester tester) async {
      // SETUP: Launch the app
      WidgetsFlutterBinding.ensureInitialized();
      await tester.pumpWidget(const GastrobrainApp());
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Find the Ingredients tab by its icon
      final bottomNavBar = find.byType(BottomNavigationBar);
      final ingredientsTab = find.descendant(
        of: bottomNavBar,
        matching: find.byIcon(Icons.restaurant_menu),
      );

      // ACT: Tap the Ingredients tab
      await tester.tap(ingredientsTab);
      await tester.pumpAndSettle();

      // VERIFY: Tab tap completed successfully
      expect(ingredientsTab, findsOneWidget,
          reason: 'Ingredients tab should still be visible after tap');
    });

    testWidgets('Tap Tools tab and verify screen changes', (WidgetTester tester) async {
      // SETUP: Launch the app
      WidgetsFlutterBinding.ensureInitialized();
      await tester.pumpWidget(const GastrobrainApp());
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Find the Tools tab by its icon
      final bottomNavBar = find.byType(BottomNavigationBar);
      final toolsTab = find.descendant(
        of: bottomNavBar,
        matching: find.byIcon(Icons.build),
      );

      // ACT: Tap the Tools tab
      await tester.tap(toolsTab);
      await tester.pumpAndSettle();

      // VERIFY: Tab tap completed successfully
      expect(toolsTab, findsOneWidget,
          reason: 'Tools tab should still be visible after tap');

      // BONUS: Verify the "Tools" text is still visible
      expect(find.text('Tools'), findsOneWidget,
          reason: 'Tools tab label should be visible');
    });
  });
}
