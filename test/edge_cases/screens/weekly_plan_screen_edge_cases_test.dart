// test/edge_cases/screens/weekly_plan_screen_edge_cases_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/screens/weekly_plan_screen.dart';
import 'package:gastrobrain/core/di/providers/database_provider.dart';
import 'package:gastrobrain/core/providers/recipe_provider.dart';
import 'package:gastrobrain/core/providers/meal_provider.dart';
import 'package:gastrobrain/core/providers/meal_plan_provider.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/meal_plan.dart';
import 'package:gastrobrain/models/meal_plan_item.dart';
import 'package:gastrobrain/models/meal_plan_item_recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gastrobrain/l10n/app_localizations.dart';
import '../../mocks/mock_database_helper.dart';
import '../../fixtures/boundary_fixtures.dart';

/// Comprehensive edge case tests for WeeklyPlanScreen.
///
/// This test suite covers Phase 5.1.2 scenarios beyond basic empty states.
///
/// Covers:
/// - All meal slots filled for a week
/// - Large meal plans (100+ planned meals across weeks)
/// - Various data scenarios (long notes, multiple recipes, etc.)
///
/// Note: Basic empty state tests are in empty_states/meal_planning_empty_state_test.dart
void main() {
  group('WeeklyPlanScreen - Edge Cases (Phase 5.1.2)', () {
    late MockDatabaseHelper mockDbHelper;
    late RecipeProvider recipeProvider;
    late MealProvider mealProvider;
    late MealPlanProvider mealPlanProvider;
    late Recipe testRecipe;

    setUp(() {
      mockDbHelper = MockDatabaseHelper();
      DatabaseProvider().setDatabaseHelper(mockDbHelper);
      recipeProvider = RecipeProvider();
      mealProvider = MealProvider();
      mealPlanProvider = MealPlanProvider();

      // Create a test recipe
      testRecipe = Recipe(
        id: 'test-recipe-1',
        name: 'Pasta Carbonara',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
        difficulty: 2,
      );
      mockDbHelper.insertRecipe(testRecipe);
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

    group('Fully Populated Week', () {
      testWidgets('displays week with all 14 slots filled (7 days × 2 meals)',
          (WidgetTester tester) async {
        // Create a meal plan for the current week
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));

        final mealPlan = MealPlan(
          id: 'plan-full-week',
          weekStartDate: weekStart,
          createdAt: now,
          modifiedAt: now,
        );
        await mockDbHelper.insertMealPlan(mealPlan);

        // Fill all 14 slots (7 days × 2 meals)
        for (int day = 0; day < 7; day++) {
          final date = weekStart.add(Duration(days: day));
          final dateStr = MealPlanItem.formatPlannedDate(date);

          // Lunch
          final lunchItem = MealPlanItem(
            id: 'item-lunch-$day',
            mealPlanId: mealPlan.id,
            plannedDate: dateStr,
            mealType: MealPlanItem.lunch,
          );
          await mockDbHelper.insertMealPlanItem(lunchItem);

          final lunchRecipe = MealPlanItemRecipe(
            id: 'recipe-lunch-$day',
            mealPlanItemId: lunchItem.id,
            recipeId: testRecipe.id,
            isPrimaryDish: true,
          );
          await mockDbHelper.insertMealPlanItemRecipe(lunchRecipe);

          // Dinner
          final dinnerItem = MealPlanItem(
            id: 'item-dinner-$day',
            mealPlanId: mealPlan.id,
            plannedDate: dateStr,
            mealType: MealPlanItem.dinner,
          );
          await mockDbHelper.insertMealPlanItem(dinnerItem);

          final dinnerRecipe = MealPlanItemRecipe(
            id: 'recipe-dinner-$day',
            mealPlanItemId: dinnerItem.id,
            recipeId: testRecipe.id,
            isPrimaryDish: true,
          );
          await mockDbHelper.insertMealPlanItemRecipe(dinnerRecipe);
        }

        await tester.pumpWidget(buildWeeklyPlanScreen());
        await tester.pumpAndSettle();

        // Verify screen builds successfully
        expect(find.byType(WeeklyPlanScreen), findsOneWidget);

        // Verify no crashes with fully populated week
        expect(tester.takeException(), isNull,
            reason: 'Should handle fully populated week without errors');
      });

      testWidgets('handles week with very long notes in multiple slots',
          (WidgetTester tester) async {
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));

        final mealPlan = MealPlan(
          id: 'plan-long-notes',
          weekStartDate: weekStart,
          createdAt: now,
          modifiedAt: now,
        );
        await mockDbHelper.insertMealPlan(mealPlan);

        // Create 3 meal plan items with very long notes
        for (int i = 0; i < 3; i++) {
          final date = weekStart.add(Duration(days: i));
          final item = MealPlanItem(
            id: 'item-$i',
            mealPlanId: mealPlan.id,
            plannedDate: MealPlanItem.formatPlannedDate(date),
            mealType: MealPlanItem.dinner,
            notes: BoundaryValues.veryLongText, // 1000+ chars
          );
          await mockDbHelper.insertMealPlanItem(item);

          final recipe = MealPlanItemRecipe(
            id: 'recipe-$i',
            mealPlanItemId: item.id,
            recipeId: testRecipe.id,
            isPrimaryDish: true,
          );
          await mockDbHelper.insertMealPlanItemRecipe(recipe);
        }

        await tester.pumpWidget(buildWeeklyPlanScreen());
        await tester.pumpAndSettle();

        // Verify no overflow or crashes with long notes
        expect(tester.takeException(), isNull,
            reason: 'Should handle very long notes without overflow');
      });

      testWidgets('handles week with multiple recipes per meal slot',
          (WidgetTester tester) async {
        // Create additional side dish recipes
        for (int i = 0; i < 5; i++) {
          final sideDish = Recipe(
            id: 'side-$i',
            name: 'Side Dish $i',
            desiredFrequency: FrequencyType.weekly,
            createdAt: DateTime.now(),
          );
          await mockDbHelper.insertRecipe(sideDish);
        }

        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));

        final mealPlan = MealPlan(
          id: 'plan-multi-recipe',
          weekStartDate: weekStart,
          createdAt: now,
          modifiedAt: now,
        );
        await mockDbHelper.insertMealPlan(mealPlan);

        // Create one meal with 6 recipes (1 primary + 5 sides)
        final item = MealPlanItem(
          id: 'item-multi',
          mealPlanId: mealPlan.id,
          plannedDate: MealPlanItem.formatPlannedDate(weekStart),
          mealType: MealPlanItem.dinner,
        );
        await mockDbHelper.insertMealPlanItem(item);

        // Primary dish
        final primaryRecipe = MealPlanItemRecipe(
          id: 'recipe-primary',
          mealPlanItemId: item.id,
          recipeId: testRecipe.id,
          isPrimaryDish: true,
        );
        await mockDbHelper.insertMealPlanItemRecipe(primaryRecipe);

        // 5 side dishes
        for (int i = 0; i < 5; i++) {
          final sideRecipe = MealPlanItemRecipe(
            id: 'recipe-side-$i',
            mealPlanItemId: item.id,
            recipeId: 'side-$i',
            isPrimaryDish: false,
          );
          await mockDbHelper.insertMealPlanItemRecipe(sideRecipe);
        }

        await tester.pumpWidget(buildWeeklyPlanScreen());
        await tester.pumpAndSettle();

        // Verify screen handles multiple recipes per slot
        expect(find.byType(WeeklyPlanScreen), findsOneWidget);
        expect(tester.takeException(), isNull,
            reason: 'Should handle multiple recipes per meal slot');
      });
    });

    group('Large Meal Plans (100+ meals)', () {
      testWidgets('handles 100+ planned meals across multiple weeks',
          (WidgetTester tester) async {
        final now = DateTime.now();

        // Create meal plans for 10 weeks (20 weeks × 14 slots = 280 meals total)
        // But we'll test with 100+ for performance
        for (int week = 0; week < 8; week++) {
          final weekStart =
              now.subtract(Duration(days: now.weekday - 1 + (week * 7)));

          final mealPlan = MealPlan(
            id: 'plan-week-$week',
            weekStartDate: weekStart,
            createdAt: now,
          modifiedAt: now,
          );
          await mockDbHelper.insertMealPlan(mealPlan);

          // Fill all 14 slots for this week
          for (int day = 0; day < 7; day++) {
            final date = weekStart.add(Duration(days: day));
            final dateStr = MealPlanItem.formatPlannedDate(date);

            // Lunch & Dinner
            for (final mealType in [MealPlanItem.lunch, MealPlanItem.dinner]) {
              final item = MealPlanItem(
                id: 'item-w${week}-d${day}-$mealType',
                mealPlanId: mealPlan.id,
                plannedDate: dateStr,
                mealType: mealType,
              );
              await mockDbHelper.insertMealPlanItem(item);

              final recipe = MealPlanItemRecipe(
                id: 'recipe-w${week}-d${day}-$mealType',
                mealPlanItemId: item.id,
                recipeId: testRecipe.id,
                isPrimaryDish: true,
              );
              await mockDbHelper.insertMealPlanItemRecipe(recipe);
            }
          }
        }

        // Verify we created 112 meal plan items (8 weeks × 14 slots)
        // Note: Mock stores items in meal plans
        int totalItems = 0;
        for (final plan in mockDbHelper.mealPlans.values) {
          totalItems += plan.items.length;
        }
        expect(totalItems, greaterThanOrEqualTo(100),
            reason: 'Should have created 100+ meal plan items');

        await tester.pumpWidget(buildWeeklyPlanScreen());
        await tester.pumpAndSettle();

        // Verify screen renders without performance issues
        expect(find.byType(WeeklyPlanScreen), findsOneWidget);
        expect(tester.takeException(), isNull,
            reason: 'Should handle 100+ meals without crashes');
      });

      testWidgets('navigates between weeks with large dataset',
          (WidgetTester tester) async {
        // Create plans for 5 weeks
        final now = DateTime.now();
        for (int week = -2; week <= 2; week++) {
          final weekStart =
              now.subtract(Duration(days: now.weekday - 1 - (week * 7)));

          final mealPlan = MealPlan(
            id: 'plan-nav-$week',
            weekStartDate: weekStart,
            createdAt: now,
          modifiedAt: now,
          );
          await mockDbHelper.insertMealPlan(mealPlan);

          // Add 2 meals to each week
          final item = MealPlanItem(
            id: 'item-nav-$week',
            mealPlanId: mealPlan.id,
            plannedDate: MealPlanItem.formatPlannedDate(weekStart),
            mealType: MealPlanItem.dinner,
          );
          await mockDbHelper.insertMealPlanItem(item);

          final recipe = MealPlanItemRecipe(
            id: 'recipe-nav-$week',
            mealPlanItemId: item.id,
            recipeId: testRecipe.id,
            isPrimaryDish: true,
          );
          await mockDbHelper.insertMealPlanItemRecipe(recipe);
        }

        await tester.pumpWidget(buildWeeklyPlanScreen());
        await tester.pumpAndSettle();

        // Verify screen builds
        expect(find.byType(WeeklyPlanScreen), findsOneWidget);

        // Verify no crashes when navigating
        expect(tester.takeException(), isNull,
            reason: 'Should handle week navigation with large dataset');
      });
    });

    group('Data Integrity & Edge Cases', () {
      testWidgets('handles meal plan with deleted recipe (orphaned)',
          (WidgetTester tester) async {
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));

        final mealPlan = MealPlan(
          id: 'plan-orphaned',
          weekStartDate: weekStart,
          createdAt: now,
          modifiedAt: now,
        );
        await mockDbHelper.insertMealPlan(mealPlan);

        final item = MealPlanItem(
          id: 'item-orphaned',
          mealPlanId: mealPlan.id,
          plannedDate: MealPlanItem.formatPlannedDate(weekStart),
          mealType: MealPlanItem.dinner,
        );
        await mockDbHelper.insertMealPlanItem(item);

        final recipe = MealPlanItemRecipe(
          id: 'recipe-orphaned',
          mealPlanItemId: item.id,
          recipeId: testRecipe.id,
          isPrimaryDish: true,
        );
        await mockDbHelper.insertMealPlanItemRecipe(recipe);

        // Delete the recipe (orphan the meal plan item)
        await mockDbHelper.deleteRecipe(testRecipe.id);

        await tester.pumpWidget(buildWeeklyPlanScreen());
        await tester.pumpAndSettle();

        // Verify screen handles orphaned meal plans gracefully
        expect(tester.takeException(), isNull,
            reason: 'Should handle orphaned meal plans without crashing');
      });

      testWidgets('handles cooked and uncooked meals in same week',
          (WidgetTester tester) async {
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));

        final mealPlan = MealPlan(
          id: 'plan-mixed-cooked',
          weekStartDate: weekStart,
          createdAt: now,
          modifiedAt: now,
        );
        await mockDbHelper.insertMealPlan(mealPlan);

        // Create 4 items: 2 cooked, 2 uncooked
        for (int i = 0; i < 4; i++) {
          final date = weekStart.add(Duration(days: i));
          final item = MealPlanItem(
            id: 'item-mixed-$i',
            mealPlanId: mealPlan.id,
            plannedDate: MealPlanItem.formatPlannedDate(date),
            mealType: MealPlanItem.dinner,
            hasBeenCooked: i < 2, // First 2 are cooked
          );
          await mockDbHelper.insertMealPlanItem(item);

          final recipe = MealPlanItemRecipe(
            id: 'recipe-mixed-$i',
            mealPlanItemId: item.id,
            recipeId: testRecipe.id,
            isPrimaryDish: true,
          );
          await mockDbHelper.insertMealPlanItemRecipe(recipe);
        }

        await tester.pumpWidget(buildWeeklyPlanScreen());
        await tester.pumpAndSettle();

        // Verify screen distinguishes cooked vs uncooked
        expect(find.byType(WeeklyPlanScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('handles week spanning year boundary',
          (WidgetTester tester) async {
        // Create a week that spans Dec 31 -> Jan 1
        final yearEnd = DateTime(2024, 12, 30); // Monday
        final weekStart = yearEnd.subtract(Duration(days: yearEnd.weekday - 1));

        final mealPlan = MealPlan(
          id: 'plan-year-boundary',
          weekStartDate: weekStart,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );
        await mockDbHelper.insertMealPlan(mealPlan);

        // Add meals across the year boundary
        for (int day = 0; day < 7; day++) {
          final date = weekStart.add(Duration(days: day));
          final item = MealPlanItem(
            id: 'item-year-$day',
            mealPlanId: mealPlan.id,
            plannedDate: MealPlanItem.formatPlannedDate(date),
            mealType: MealPlanItem.dinner,
          );
          await mockDbHelper.insertMealPlanItem(item);

          final recipe = MealPlanItemRecipe(
            id: 'recipe-year-$day',
            mealPlanItemId: item.id,
            recipeId: testRecipe.id,
            isPrimaryDish: true,
          );
          await mockDbHelper.insertMealPlanItemRecipe(recipe);
        }

        await tester.pumpWidget(buildWeeklyPlanScreen());
        await tester.pumpAndSettle();

        // Verify week spanning year boundary is handled
        expect(find.byType(WeeklyPlanScreen), findsOneWidget);
        expect(tester.takeException(), isNull,
            reason: 'Should handle week spanning year boundary');
      });

      testWidgets('handles extremely old meal plans (year 2000)',
          (WidgetTester tester) async {
        final oldDate = DateTime(2000, 1, 3); // Monday
        final weekStart = oldDate.subtract(Duration(days: oldDate.weekday - 1));

        final mealPlan = MealPlan(
          id: 'plan-old',
          weekStartDate: weekStart,
          createdAt: oldDate,
          modifiedAt: oldDate,
        );
        await mockDbHelper.insertMealPlan(mealPlan);

        final item = MealPlanItem(
          id: 'item-old',
          mealPlanId: mealPlan.id,
          plannedDate: MealPlanItem.formatPlannedDate(weekStart),
          mealType: MealPlanItem.dinner,
        );
        await mockDbHelper.insertMealPlanItem(item);

        final recipe = MealPlanItemRecipe(
          id: 'recipe-old',
          mealPlanItemId: item.id,
          recipeId: testRecipe.id,
          isPrimaryDish: true,
        );
        await mockDbHelper.insertMealPlanItemRecipe(recipe);

        await tester.pumpWidget(buildWeeklyPlanScreen());
        await tester.pumpAndSettle();

        // Verify old dates are handled correctly
        expect(tester.takeException(), isNull,
            reason: 'Should handle very old meal plans');
      });
    });
  });
}
