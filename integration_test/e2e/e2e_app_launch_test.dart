// integration_test/e2e_app_launch_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gastrobrain/main.dart';

/// Minimal E2E Test - App Launch
///
/// This test verifies that the app can launch and render the home screen.
/// This is the foundation for more complex E2E tests.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E - App Launch', () {
    testWidgets('App launches and home screen appears',
        (WidgetTester tester) async {
      // SETUP: Initialize Flutter bindings
      WidgetsFlutterBinding.ensureInitialized();

      // SETUP: Pump the app widget into the test framework
      await tester.pumpWidget(const GastrobrainApp());

      // Wait for the app to initialize and render
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // DEBUG: Print what widgets are actually rendered
      print('=== WIDGETS FOUND ===');
      print('MaterialApp: ${find.byType(MaterialApp).evaluate().length}');
      print('Scaffold: ${find.byType(Scaffold).evaluate().length}');
      print(
          'BottomNavigationBar: ${find.byType(BottomNavigationBar).evaluate().length}');
      print(
          'CircularProgressIndicator: ${find.byType(CircularProgressIndicator).evaluate().length}');

      // VERIFY: Bottom navigation bar appears
      expect(find.byType(BottomNavigationBar), findsOneWidget,
          reason: 'Expected to find BottomNavigationBar on home screen');

      // VERIFY: The "Tools" tab is visible (hardcoded text, no localization)
      expect(find.text('Tools'), findsOneWidget);

      // VERIFY: We can see navigation icons
      expect(find.byIcon(Icons.menu_book), findsOneWidget); // Recipes tab
      expect(find.byIcon(Icons.build), findsOneWidget); // Tools tab
    });
  });
}
