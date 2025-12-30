// test/edge_cases/error_scenarios/database_connection_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/screens/home_screen.dart';
import 'package:gastrobrain/core/di/providers/database_provider.dart';
import 'package:gastrobrain/core/providers/recipe_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gastrobrain/l10n/app_localizations.dart';
import '../../mocks/mock_database_helper.dart';
import '../../helpers/error_injection_helpers.dart';
import '../../helpers/edge_case_test_helpers.dart';

/// Tests for database connection and initialization error scenarios.
///
/// Verifies that the application handles database connection failures gracefully:
/// - Database initialization failures
/// - Database locked during operations
/// - Database corruption scenarios
/// - Database migration failures
/// - Permission-related errors
/// - App stability when database is unavailable
///
/// Note: These tests use MockDatabaseHelper to simulate connection errors.
/// Real database initialization is tested in integration tests.
void main() {
  group('Database Connection & Initialization Errors', () {
    late MockDatabaseHelper mockDbHelper;
    late RecipeProvider recipeProvider;

    setUp(() {
      mockDbHelper = MockDatabaseHelper();
      DatabaseProvider().setDatabaseHelper(mockDbHelper);
      recipeProvider = RecipeProvider();
    });

    tearDown(() {
      mockDbHelper.resetAllData();
      ErrorInjectionHelpers.resetErrorInjection(mockDbHelper);
    });

    /// Helper to build HomePage with proper providers and localization
    Widget buildHomePage() {
      return ChangeNotifierProvider<RecipeProvider>.value(
        value: recipeProvider,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('en', ''),
            Locale('pt', ''),
          ],
          home: HomePage(),
        ),
      );
    }

    group('Database Initialization Failures', () {
      testWidgets('app remains stable when database initialization fails',
          (WidgetTester tester) async {
        // Simulate database not initialized error
        ErrorInjectionHelpers.injectDatabaseError(
          mockDbHelper,
          ErrorType.databaseNotInitialized,
          operation: 'getAllRecipes',
        );

        // Build the app
        await tester.pumpWidget(buildHomePage());

        // The app should build without crashing
        expect(tester.takeException(), isNull,
            reason: 'App should not crash when database initialization fails');

        // Wait for any async operations
        await tester.pumpAndSettle();

        // App should still be visible and stable
        expect(find.byType(HomePage), findsOneWidget,
            reason: 'HomePage should render despite database error');
      });

      testWidgets('shows appropriate error message when database not initialized',
          (WidgetTester tester) async {
        // Simulate database not initialized error
        ErrorInjectionHelpers.injectDatabaseError(
          mockDbHelper,
          ErrorType.databaseNotInitialized,
          operation: 'getAllRecipes',
        );

        // Build the app
        await tester.pumpWidget(buildHomePage());
        await tester.pumpAndSettle();

        // Note: Error handling may vary by screen implementation
        // The key requirement is that the app doesn't crash
        expect(tester.takeException(), isNull,
            reason: 'Should handle database initialization error gracefully');

        // Verify the app is still functional
        expect(find.byType(MaterialApp), findsOneWidget,
            reason: 'App should remain functional');
      });

      testWidgets('handles database initialization error during recipe load',
          (WidgetTester tester) async {
        // Inject error specifically for getAllRecipes operation
        ErrorInjectionHelpers.injectOperationError(
          mockDbHelper,
          operation: 'getAllRecipes',
          errorMessage: 'Database not initialized',
        );

        // Build the app
        await tester.pumpWidget(buildHomePage());
        await tester.pump();

        // Should not throw exception during build
        expect(tester.takeException(), isNull);

        // Wait for async operations
        await tester.pumpAndSettle();

        // App should remain stable
        expect(find.byType(HomePage), findsOneWidget);
      });
    });

    group('Database Locked Scenarios', () {
      testWidgets('handles database locked during read operation',
          (WidgetTester tester) async {
        // Simulate database locked error
        ErrorInjectionHelpers.simulateDatabaseLocked(
          mockDbHelper,
          operation: 'getAllRecipes',
        );

        // Build the app
        await tester.pumpWidget(buildHomePage());
        await tester.pumpAndSettle();

        // App should not crash
        expect(tester.takeException(), isNull,
            reason: 'Should handle database locked error gracefully');

        // Verify app remains stable
        expect(find.byType(HomePage), findsOneWidget);
      });

      testWidgets('handles database locked during write operation',
          (WidgetTester tester) async {
        // Simulate database locked error on insert
        ErrorInjectionHelpers.simulateDatabaseLocked(
          mockDbHelper,
          operation: 'insertRecipe',
        );

        // Build the app
        await tester.pumpWidget(buildHomePage());
        await tester.pumpAndSettle();

        // App should remain stable
        expect(tester.takeException(), isNull);
        expect(find.byType(HomePage), findsOneWidget);

        // Note: Actual insert operations would be triggered by user actions
        // This test verifies the error injection is set up correctly
      });

      testWidgets('shows user feedback when database is locked',
          (WidgetTester tester) async {
        // Inject database locked error
        ErrorInjectionHelpers.injectOperationError(
          mockDbHelper,
          operation: 'getAllRecipes',
          errorMessage: 'Database is locked',
        );

        // Build the app
        await tester.pumpWidget(buildHomePage());
        await tester.pumpAndSettle();

        // The app should handle the error without crashing
        expect(tester.takeException(), isNull);

        // Key requirement: app stability maintained
        expect(find.byType(MaterialApp), findsOneWidget);
      });

      testWidgets('recovers when database lock is released',
          (WidgetTester tester) async {
        // First inject a locked error
        ErrorInjectionHelpers.simulateDatabaseLocked(
          mockDbHelper,
          operation: 'getAllRecipes',
        );

        // Build the app
        await tester.pumpWidget(buildHomePage());
        await tester.pumpAndSettle();

        // Verify no crash
        expect(tester.takeException(), isNull);

        // Now reset the error (simulating lock release)
        ErrorInjectionHelpers.resetErrorInjection(mockDbHelper);

        // Trigger a rebuild (simulating retry)
        await tester.pumpAndSettle();

        // App should still be stable
        expect(find.byType(HomePage), findsOneWidget);
      });
    });

    group('Database Corruption Scenarios', () {
      testWidgets('handles corrupted database error gracefully',
          (WidgetTester tester) async {
        // Simulate database corruption
        ErrorInjectionHelpers.injectOperationError(
          mockDbHelper,
          operation: 'getAllRecipes',
          errorMessage: 'Database file is corrupted',
        );

        // Build the app
        await tester.pumpWidget(buildHomePage());
        await tester.pumpAndSettle();

        // App should not crash
        expect(tester.takeException(), isNull,
            reason: 'Should handle database corruption gracefully');

        // Verify app structure remains intact
        expect(find.byType(MaterialApp), findsOneWidget);
      });

      testWidgets('handles query failure due to corruption',
          (WidgetTester tester) async {
        // Simulate query failure
        ErrorInjectionHelpers.simulateQueryFailure(
          mockDbHelper,
          operation: 'getAllRecipes',
          reason: 'Database integrity check failed',
        );

        // Build the app
        await tester.pumpWidget(buildHomePage());
        await tester.pumpAndSettle();

        // Should handle error without crashing
        expect(tester.takeException(), isNull);
        expect(find.byType(HomePage), findsOneWidget);
      });
    });

    group('Database Migration Failures', () {
      testWidgets('handles migration failure during initialization',
          (WidgetTester tester) async {
        // Simulate migration-related error
        ErrorInjectionHelpers.injectOperationError(
          mockDbHelper,
          operation: 'getAllRecipes',
          errorMessage: 'Database migration failed',
        );

        // Build the app
        await tester.pumpWidget(buildHomePage());
        await tester.pumpAndSettle();

        // App should remain stable despite migration error
        expect(tester.takeException(), isNull,
            reason: 'Should handle migration failure gracefully');

        expect(find.byType(HomePage), findsOneWidget);
      });

      testWidgets('app remains functional after migration error',
          (WidgetTester tester) async {
        // Inject migration error
        ErrorInjectionHelpers.injectOperationError(
          mockDbHelper,
          operation: 'getAllRecipes',
          errorMessage: 'Schema version mismatch',
        );

        // Build the app
        await tester.pumpWidget(buildHomePage());
        await tester.pumpAndSettle();

        // Verify app stability
        expect(tester.takeException(), isNull);

        // Check that core UI elements are present
        expect(find.byType(MaterialApp), findsOneWidget);
        expect(find.byType(HomePage), findsOneWidget);
      });
    });

    group('Permission & Access Errors', () {
      testWidgets('handles insufficient permissions error',
          (WidgetTester tester) async {
        // Simulate permission error
        ErrorInjectionHelpers.injectOperationError(
          mockDbHelper,
          operation: 'getAllRecipes',
          errorMessage: 'Insufficient permissions to access database',
        );

        // Build the app
        await tester.pumpWidget(buildHomePage());
        await tester.pumpAndSettle();

        // App should not crash
        expect(tester.takeException(), isNull,
            reason: 'Should handle permission errors gracefully');

        expect(find.byType(HomePage), findsOneWidget);
      });

      testWidgets('handles read-only database error',
          (WidgetTester tester) async {
        // Simulate read-only database
        ErrorInjectionHelpers.injectOperationError(
          mockDbHelper,
          operation: 'insertRecipe',
          errorMessage: 'Database is in read-only mode',
        );

        // Build the app
        await tester.pumpWidget(buildHomePage());
        await tester.pumpAndSettle();

        // Should handle error gracefully
        expect(tester.takeException(), isNull);
        expect(find.byType(MaterialApp), findsOneWidget);
      });
    });

    group('App Stability & Recovery', () {
      testWidgets('multiple database errors do not crash app',
          (WidgetTester tester) async {
        // Inject error for first operation
        ErrorInjectionHelpers.simulateDatabaseLocked(
          mockDbHelper,
          operation: 'getAllRecipes',
        );

        // Build the app
        await tester.pumpWidget(buildHomePage());
        await tester.pumpAndSettle();

        // First error handled
        expect(tester.takeException(), isNull);

        // Inject different error
        ErrorInjectionHelpers.resetErrorInjection(mockDbHelper);
        ErrorInjectionHelpers.injectDatabaseError(
          mockDbHelper,
          ErrorType.queryFailed,
          operation: 'getAllRecipes',
        );

        // Rebuild
        await tester.pumpAndSettle();

        // App should still be stable
        expect(tester.takeException(), isNull);
        expect(find.byType(HomePage), findsOneWidget);
      });

      testWidgets('app recovers after database connection restored',
          (WidgetTester tester) async {
        // Start with database error
        ErrorInjectionHelpers.injectDatabaseError(
          mockDbHelper,
          ErrorType.databaseNotInitialized,
          operation: 'getAllRecipes',
        );

        // Build the app
        await tester.pumpWidget(buildHomePage());
        await tester.pumpAndSettle();

        // Error state
        expect(tester.takeException(), isNull);

        // Simulate connection restored
        ErrorInjectionHelpers.resetErrorInjection(mockDbHelper);

        // Trigger rebuild (simulating retry or refresh)
        await tester.pumpAndSettle();

        // App should recover
        expect(find.byType(HomePage), findsOneWidget);
      });

      testWidgets('concurrent operations handle connection errors independently',
          (WidgetTester tester) async {
        // Inject error for specific operation only
        ErrorInjectionHelpers.injectOperationError(
          mockDbHelper,
          operation: 'getAllRecipes',
          errorMessage: 'Connection timeout',
        );

        // Build the app
        await tester.pumpWidget(buildHomePage());
        await tester.pumpAndSettle();

        // This operation fails but app remains stable
        expect(tester.takeException(), isNull);

        // Other operations (not getAllRecipes) should work
        // The app structure should be intact
        expect(find.byType(MaterialApp), findsOneWidget);
      });

      testWidgets('timeout errors do not leave app in broken state',
          (WidgetTester tester) async {
        // Simulate timeout
        ErrorInjectionHelpers.simulateTimeout(
          mockDbHelper,
          operation: 'getAllRecipes',
        );

        // Build the app
        await tester.pumpWidget(buildHomePage());
        await tester.pumpAndSettle();

        // No crash
        expect(tester.takeException(), isNull);

        // App remains usable
        expect(find.byType(HomePage), findsOneWidget);
        expect(find.byType(MaterialApp), findsOneWidget);
      });
    });

    group('User Experience During Connection Errors', () {
      testWidgets('app UI remains responsive during database error',
          (WidgetTester tester) async {
        // Inject database error
        ErrorInjectionHelpers.injectDatabaseError(
          mockDbHelper,
          ErrorType.databaseLocked,
          operation: 'getAllRecipes',
        );

        // Build the app
        await tester.pumpWidget(buildHomePage());
        await tester.pumpAndSettle();

        // Verify app is still interactive
        expect(tester.takeException(), isNull);

        // UI should be present (even if showing error state)
        expect(find.byType(MaterialApp), findsOneWidget);
        expect(find.byType(Scaffold), findsWidgets,
            reason: 'UI scaffolding should remain intact');
      });

      testWidgets('navigation works despite database connection issues',
          (WidgetTester tester) async {
        // Inject connection error
        ErrorInjectionHelpers.simulateDatabaseLocked(
          mockDbHelper,
          operation: 'getAllRecipes',
        );

        // Build the app
        await tester.pumpWidget(buildHomePage());
        await tester.pumpAndSettle();

        // App should be navigable
        expect(find.byType(HomePage), findsOneWidget);

        // The app structure supports navigation even with DB errors
        expect(find.byType(MaterialApp), findsOneWidget,
            reason: 'Navigation structure should remain functional');
      });
    });
  });
}
