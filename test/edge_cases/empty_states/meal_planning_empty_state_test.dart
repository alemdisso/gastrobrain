// test/edge_cases/empty_states/meal_planning_empty_state_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/screens/weekly_plan_screen.dart';
import 'package:gastrobrain/core/di/providers/database_provider.dart';
import 'package:gastrobrain/core/providers/recipe_provider.dart';
import 'package:gastrobrain/core/providers/meal_provider.dart';
import 'package:gastrobrain/core/providers/meal_plan_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gastrobrain/l10n/app_localizations.dart';
import '../../mocks/mock_database_helper.dart';

/// Tests for meal planning empty state handling.
///
/// Verifies that the application handles the empty state gracefully when:
/// - No meal plan exists for the current week
/// - No recipes exist in the database
/// - All meal slots are empty
void main() {
  group('Meal Planning - Empty States', () {
    late MockDatabaseHelper mockDbHelper;
    late RecipeProvider recipeProvider;
    late MealProvider mealProvider;
    late MealPlanProvider mealPlanProvider;

    setUp(() {
      mockDbHelper = MockDatabaseHelper();
      DatabaseProvider().setDatabaseHelper(mockDbHelper);
      recipeProvider = RecipeProvider();
      mealProvider = MealProvider();
      mealPlanProvider = MealPlanProvider();
    });

    tearDown(() {
      mockDbHelper.resetAllData();
    });

    /// Helper to build WeeklyPlanScreen with proper providers and localization
    Widget buildWeeklyPlanScreen({Locale locale = const Locale('en', '')}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<RecipeProvider>.value(value: recipeProvider),
          ChangeNotifierProvider<MealProvider>.value(value: mealProvider),
          ChangeNotifierProvider<MealPlanProvider>.value(
              value: mealPlanProvider),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
            Locale('pt', ''),
          ],
          locale: locale,
          home: WeeklyPlanScreen(databaseHelper: mockDbHelper),
        ),
      );
    }

    testWidgets('shows empty meal slots when no meal plan exists',
        (WidgetTester tester) async {
      // Setup: Empty database (no meal plans by default)
      expect(mockDbHelper.mealPlans.isEmpty, isTrue,
          reason: 'Test precondition: no meal plans should exist');

      // Build the WeeklyPlanScreen
      await tester.pumpWidget(buildWeeklyPlanScreen());

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Verify screen builds successfully
      expect(find.byType(WeeklyPlanScreen), findsOneWidget,
          reason: 'WeeklyPlanScreen should build successfully');

      // Verify "Add meal" text appears in empty slots
      // Note: There are 14 meal slots per week (7 days * 2 meals)
      // But we only need to verify at least one appears
      expect(find.text('Add meal'), findsWidgets,
          reason: 'Empty meal slots should show "Add meal" text');
    });

    testWidgets('shows correct app bar title', (WidgetTester tester) async {
      // Build the WeeklyPlanScreen
      await tester.pumpWidget(buildWeeklyPlanScreen());
      await tester.pumpAndSettle();

      // Verify app bar title
      expect(find.text('Weekly Meal Plan'), findsOneWidget,
          reason: 'App bar should show correct title');
    });

    testWidgets('shows refresh button in app bar', (WidgetTester tester) async {
      // Build the WeeklyPlanScreen
      await tester.pumpWidget(buildWeeklyPlanScreen());
      await tester.pumpAndSettle();

      // Verify refresh button is present
      expect(find.byIcon(Icons.refresh), findsOneWidget,
          reason: 'App bar should have refresh button');

      // Verify refresh button has correct tooltip
      final refreshButton = find.byIcon(Icons.refresh);
      final iconButton = tester.widget<IconButton>(
        find.ancestor(
          of: refreshButton,
          matching: find.byType(IconButton),
        ),
      );
      expect(iconButton.tooltip, equals('Refresh'),
          reason: 'Refresh button should have tooltip');
    });

    testWidgets('empty state UI renders correctly without overflow',
        (WidgetTester tester) async {
      // Build the WeeklyPlanScreen
      await tester.pumpWidget(buildWeeklyPlanScreen());
      await tester.pumpAndSettle();

      // Verify no rendering exceptions
      expect(tester.takeException(), isNull,
          reason: 'Empty state should render without exceptions');

      // Verify "Add meal" text is present
      expect(find.text('Add meal'), findsWidgets,
          reason: 'Empty slots should show add meal text');
    });

    testWidgets('shows week navigation controls', (WidgetTester tester) async {
      // Build the WeeklyPlanScreen
      await tester.pumpWidget(buildWeeklyPlanScreen());
      await tester.pumpAndSettle();

      // Verify previous week button
      expect(find.byIcon(Icons.chevron_left), findsOneWidget,
          reason: 'Should show previous week button');

      // Verify next week button
      expect(find.byIcon(Icons.chevron_right), findsOneWidget,
          reason: 'Should show next week button');

      // Verify week navigation works by tapping next week
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      // Should still show empty slots after navigation
      expect(find.text('Add meal'), findsWidgets,
          reason: 'Empty slots should persist after week navigation');
    });

    testWidgets('empty state is localized to Portuguese',
        (WidgetTester tester) async {
      // Build with Portuguese locale
      await tester.pumpWidget(
        buildWeeklyPlanScreen(locale: const Locale('pt', '')),
      );
      await tester.pumpAndSettle();

      // Verify Portuguese app bar title
      expect(find.text('Refeições da Semana'), findsOneWidget,
          reason: 'App bar title should be in Portuguese');

      // Verify Portuguese "Add meal" text
      expect(find.text('Adicionar refeição'), findsWidgets,
          reason: 'Empty slots should show Portuguese text');
    });

    testWidgets('handles empty state with no recipes in database',
        (WidgetTester tester) async {
      // Setup: Empty database (no recipes or meal plans)
      expect(mockDbHelper.recipes.isEmpty, isTrue,
          reason: 'Test precondition: database should have no recipes');

      // Build the WeeklyPlanScreen
      await tester.pumpWidget(buildWeeklyPlanScreen());
      await tester.pumpAndSettle();

      // Verify screen builds without crashing
      expect(find.byType(WeeklyPlanScreen), findsOneWidget,
          reason: 'Screen should handle empty recipe database gracefully');

      // Empty slots should still be tappable
      final addMealSlots = find.text('Add meal');
      expect(addMealSlots, findsWidgets,
          reason: 'Empty meal slots should be present');
    });

    testWidgets('empty state persists across multiple weeks',
        (WidgetTester tester) async {
      // Build the WeeklyPlanScreen
      await tester.pumpWidget(buildWeeklyPlanScreen());
      await tester.pumpAndSettle();

      // Navigate to next week
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      // Verify empty state persists
      expect(find.text('Add meal'), findsWidgets,
          reason: 'Next week should also show empty state');

      // Navigate to previous week (2 weeks back from current)
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      // Verify empty state still persists
      expect(find.text('Add meal'), findsWidgets,
          reason: 'Previous weeks should also show empty state');
    });

    testWidgets('refresh button reloads data without errors',
        (WidgetTester tester) async {
      // Build the WeeklyPlanScreen
      await tester.pumpWidget(buildWeeklyPlanScreen());
      await tester.pumpAndSettle();

      // Tap refresh button
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      // Verify screen reloads without errors
      expect(tester.takeException(), isNull,
          reason: 'Refresh should complete without exceptions');

      // Empty state should still be shown
      expect(find.text('Add meal'), findsWidgets,
          reason: 'Empty state should persist after refresh');
    });
  });

  group('Meal Planning - Empty State Edge Cases', () {
    late MockDatabaseHelper mockDbHelper;
    late RecipeProvider recipeProvider;
    late MealProvider mealProvider;
    late MealPlanProvider mealPlanProvider;

    setUp(() {
      mockDbHelper = MockDatabaseHelper();
      DatabaseProvider().setDatabaseHelper(mockDbHelper);
      recipeProvider = RecipeProvider();
      mealProvider = MealProvider();
      mealPlanProvider = MealPlanProvider();
    });

    tearDown(() {
      mockDbHelper.resetAllData();
    });

    Widget buildWeeklyPlanScreen() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<RecipeProvider>.value(value: recipeProvider),
          ChangeNotifierProvider<MealProvider>.value(value: mealProvider),
          ChangeNotifierProvider<MealPlanProvider>.value(
              value: mealPlanProvider),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
            Locale('pt', ''),
          ],
          home: WeeklyPlanScreen(databaseHelper: mockDbHelper),
        ),
      );
    }

    testWidgets('handles rapid week navigation without errors',
        (WidgetTester tester) async {
      // Build the WeeklyPlanScreen
      await tester.pumpWidget(buildWeeklyPlanScreen());
      await tester.pumpAndSettle();

      // Rapidly tap next week multiple times
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byIcon(Icons.chevron_right));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();

      // Verify no errors occurred
      expect(tester.takeException(), isNull,
          reason: 'Rapid navigation should not cause exceptions');

      // Empty state should still be shown
      expect(find.text('Add meal'), findsWidgets,
          reason: 'Empty state should remain after rapid navigation');
    });

    testWidgets('empty meal slots are tappable', (WidgetTester tester) async {
      // Build the WeeklyPlanScreen
      await tester.pumpWidget(buildWeeklyPlanScreen());
      await tester.pumpAndSettle();

      // Find first "Add meal" text
      final firstAddMeal = find.text('Add meal').first;

      // Tap on empty slot - this would normally open recipe selection dialog
      // Since we have no recipes, it should show a snackbar
      await tester.tap(firstAddMeal);
      await tester.pumpAndSettle();

      // The tap should be handled (no exception)
      expect(tester.takeException(), isNull,
          reason: 'Tapping empty slot should be handled gracefully');

      // Note: If there are no recipes, a snackbar would appear with "No recipes available"
      // but we can't easily test for that without widget interaction
    });
  });
}
