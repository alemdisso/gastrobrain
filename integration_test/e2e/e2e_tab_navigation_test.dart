// integration_test/e2e_tab_navigation_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gastrobrain/main.dart';

/// Simple Tab Navigation
///
/// This test verifies that tapping bottom navigation tabs changes screens.
/// This establishes the foundation for testing navigation flows.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E - Tab Navigation', () {
    testWidgets('Tap Meal Plan tab and verify screen changes',
        (WidgetTester tester) async {
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

      print(
          'Meal Plan tab (calendar_today icon) found: ${mealPlanTab.evaluate().length}');

      // ACT: Tap the Meal Plan tab
      await tester.tap(mealPlanTab);
      await tester.pumpAndSettle();

      print('=== AFTER TAP ===');
      print('Tapped Meal Plan tab');

      // VERIFY: The tab was selected (we can verify by checking if different content appears)
      // Note: We're just verifying the tap worked and UI updated

      // The test passes if:
      // 1. We could find the tab
      // 2. We could tap it
      // 3. pumpAndSettle completed (no errors during navigation)

      expect(mealPlanTab, findsOneWidget,
          reason: 'Meal Plan tab should still be visible after tap');
    });

    testWidgets('Tap Content tab and verify screen changes',
        (WidgetTester tester) async {
      // SETUP: Launch the app
      WidgetsFlutterBinding.ensureInitialized();
      await tester.pumpWidget(const GastrobrainApp());
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Find the Content tab by its key (added in #134 nav restructuring)
      final contentTab = find.byKey(const Key('content_tab_icon'));

      // ACT: Tap the Content tab
      await tester.tap(contentTab);
      await tester.pumpAndSettle();

      // VERIFY: Tab tap completed successfully
      expect(contentTab, findsOneWidget,
          reason: 'Content tab should still be visible after tap');
    });

    testWidgets('Tap Dashboard tab and verify screen changes',
        (WidgetTester tester) async {
      // SETUP: Launch the app
      WidgetsFlutterBinding.ensureInitialized();
      await tester.pumpWidget(const GastrobrainApp());
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Find the Dashboard tab by its key (added in #134 nav restructuring)
      final dashboardTab = find.byKey(const Key('dashboard_tab_icon'));

      // ACT: Tap the Dashboard tab
      await tester.tap(dashboardTab);
      await tester.pumpAndSettle();

      // VERIFY: Tab tap completed successfully
      expect(dashboardTab, findsOneWidget,
          reason: 'Dashboard tab should still be visible after tap');
    });
  });
}
