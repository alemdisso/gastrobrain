// test/edge_cases/screens/meal_history_screen_edge_cases_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/screens/meal_history_screen.dart';
import 'package:gastrobrain/core/di/providers/database_provider.dart';
import 'package:gastrobrain/core/providers/recipe_provider.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/meal.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gastrobrain/l10n/app_localizations.dart';
import '../../mocks/mock_database_helper.dart';
import '../../fixtures/boundary_fixtures.dart';

/// Comprehensive edge case tests for MealHistoryScreen.
///
/// This test suite incorporates Phase 4 tests from Issue #77 that were
/// deferred and integrated into Issue #39 Phase 5.1.1.
///
/// Covers:
/// - Various history lengths (0, 1, 10+, 100+ meals)
/// - Meal data variations (optional fields, boundary values)
/// - Data integrity issues (orphaned meals, missing data)
///
/// Note: Basic empty state tests are in empty_states/meal_history_empty_state_test.dart
void main() {
  group('MealHistoryScreen - Edge Cases (Issue #77 Phase 4)', () {
    late MockDatabaseHelper mockDbHelper;
    late RecipeProvider recipeProvider;
    late Recipe testRecipe;

    setUp(() {
      mockDbHelper = MockDatabaseHelper();
      DatabaseProvider().setDatabaseHelper(mockDbHelper);
      recipeProvider = RecipeProvider();

      // Create a test recipe for the meal history screen
      testRecipe = Recipe(
        id: 'test-recipe-1',
        name: 'Spaghetti Carbonara',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
        difficulty: 3,
        prepTimeMinutes: 15,
        cookTimeMinutes: 20,
      );
      mockDbHelper.insertRecipe(testRecipe);
    });

    tearDown(() {
      mockDbHelper.resetAllData();
    });

    /// Helper to build MealHistoryScreen with proper providers and localization
    Widget buildMealHistoryScreen({
      Recipe? recipe,
      Locale locale = const Locale('en', ''),
    }) {
      return ChangeNotifierProvider<RecipeProvider>.value(
        value: recipeProvider,
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
          home: MealHistoryScreen(
            recipe: recipe ?? testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );
    }

    group('Various History Lengths', () {
      testWidgets('handles exactly 1 meal item', (WidgetTester tester) async {
        // Create exactly one meal
        final meal = Meal(
          id: 'meal-1',
          recipeId: testRecipe.id,
          cookedAt: DateTime.now().subtract(const Duration(days: 1)),
          servings: 4,
        );
        await mockDbHelper.insertMeal(meal);

        await tester.pumpWidget(buildMealHistoryScreen());
        await tester.pumpAndSettle();

        // Verify one meal is displayed
        expect(find.byType(Card), findsOneWidget,
            reason: 'Should display exactly one meal card');

        // Verify no empty state
        expect(find.text('No meals recorded yet'), findsNothing,
            reason: 'Should not show empty state with 1 meal');
      });

      testWidgets('handles 10+ meal items', (WidgetTester tester) async {
        // Create 15 meals
        for (int i = 0; i < 15; i++) {
          final meal = Meal(
            id: 'meal-$i',
            recipeId: testRecipe.id,
            cookedAt: DateTime.now().subtract(Duration(days: i)),
            servings: 4,
          );
          await mockDbHelper.insertMeal(meal);
        }

        await tester.pumpWidget(buildMealHistoryScreen());
        await tester.pumpAndSettle();

        // Verify multiple meals are displayed
        // Note: Screen may limit initial display or use pagination
        expect(find.byType(Card), findsAtLeastNWidgets(5),
            reason: 'Should display at least 5 meal cards');

        // Verify list is scrollable
        final listFinder = find.byType(ListView);
        expect(listFinder, findsOneWidget,
            reason: 'Should use ListView for scrollable list');
      });

      testWidgets('handles 100+ meal items (performance)',
          (WidgetTester tester) async {
        // Create 120 meals
        for (int i = 0; i < 120; i++) {
          final meal = Meal(
            id: 'meal-$i',
            recipeId: testRecipe.id,
            cookedAt: DateTime.now().subtract(Duration(days: i)),
            servings: 4,
          );
          await mockDbHelper.insertMeal(meal);
        }

        await tester.pumpWidget(buildMealHistoryScreen());
        await tester.pumpAndSettle();

        // Verify screen builds without performance issues
        expect(find.byType(MealHistoryScreen), findsOneWidget,
            reason: 'Screen should render successfully with 100+ meals');

        // Verify ListView is used (efficient for large lists)
        expect(find.byType(ListView), findsOneWidget,
            reason: 'Should use ListView for efficient rendering');
      });

      testWidgets('scrolling behavior with many items',
          (WidgetTester tester) async {
        // Create 50 meals
        for (int i = 0; i < 50; i++) {
          final meal = Meal(
            id: 'meal-$i',
            recipeId: testRecipe.id,
            cookedAt: DateTime.now().subtract(Duration(days: i)),
            servings: 4,
          );
          await mockDbHelper.insertMeal(meal);
        }

        await tester.pumpWidget(buildMealHistoryScreen());
        await tester.pumpAndSettle();

        // Find the ListView
        final listViewFinder = find.byType(ListView);
        expect(listViewFinder, findsOneWidget);

        // Scroll down significantly
        await tester.drag(listViewFinder, const Offset(0, -2000));
        await tester.pumpAndSettle();

        // Verify scrolling works without errors
        expect(tester.takeException(), isNull,
            reason: 'Scrolling should not throw exceptions');
      });

      testWidgets('UI performance with large datasets remains acceptable',
          (WidgetTester tester) async {
        // Create 100 meals with various data
        for (int i = 0; i < 100; i++) {
          final meal = Meal(
            id: 'meal-$i',
            recipeId: testRecipe.id,
            cookedAt: DateTime.now().subtract(Duration(days: i)),
            servings: i % 10 + 1,
            notes: i % 5 == 0 ? 'Notes for meal $i' : '',
            wasSuccessful: i % 3 != 0,
          );
          await mockDbHelper.insertMeal(meal);
        }

        await tester.pumpWidget(buildMealHistoryScreen());
        await tester.pumpAndSettle();

        // Verify screen renders
        expect(find.byType(MealHistoryScreen), findsOneWidget);

        // Verify no performance-related crashes
        expect(tester.takeException(), isNull,
            reason: 'Large dataset should not cause crashes');
      });
    });

    group('Meal Data Variations', () {
      testWidgets('displays meal with all optional fields populated',
          (WidgetTester tester) async {
        final meal = Meal(
          id: 'meal-full',
          recipeId: testRecipe.id,
          cookedAt: DateTime.now().subtract(const Duration(days: 1)),
          servings: 4,
          notes: 'Delicious! Added extra garlic.',
          wasSuccessful: true,
          actualPrepTime: 20.0,
          actualCookTime: 25.0,
        );
        await mockDbHelper.insertMeal(meal);

        await tester.pumpWidget(buildMealHistoryScreen());
        await tester.pumpAndSettle();

        // Verify meal card is displayed
        expect(find.byType(Card), findsOneWidget);

        // Verify notes are shown
        expect(find.text('Delicious! Added extra garlic.'), findsOneWidget,
            reason: 'Should display meal notes');
      });

      testWidgets('displays meal with minimal fields (only required)',
          (WidgetTester tester) async {
        final meal = Meal(
          id: 'meal-minimal',
          recipeId: testRecipe.id,
          cookedAt: DateTime.now().subtract(const Duration(days: 1)),
          servings: 1,
          // All optional fields null
        );
        await mockDbHelper.insertMeal(meal);

        await tester.pumpWidget(buildMealHistoryScreen());
        await tester.pumpAndSettle();

        // Verify meal card is displayed
        expect(find.byType(Card), findsOneWidget,
            reason: 'Should display meal with minimal fields');

        // Verify no crash with null optional fields
        expect(tester.takeException(), isNull);
      });

      testWidgets('displays meal with very long notes (1000+ chars)',
          (WidgetTester tester) async {
        final meal = Meal(
          id: 'meal-long-notes',
          recipeId: testRecipe.id,
          cookedAt: DateTime.now().subtract(const Duration(days: 1)),
          servings: 4,
          notes: BoundaryValues.veryLongText, // 1000+ chars
        );
        await mockDbHelper.insertMeal(meal);

        await tester.pumpWidget(buildMealHistoryScreen());
        await tester.pumpAndSettle();

        // Verify meal card is displayed
        expect(find.byType(Card), findsOneWidget);

        // Verify long notes don't cause overflow
        expect(tester.takeException(), isNull,
            reason: 'Long notes should not cause overflow errors');
      });

      testWidgets('displays meal with extremely long notes (10000+ chars)',
          (WidgetTester tester) async {
        final meal = Meal(
          id: 'meal-extreme-notes',
          recipeId: testRecipe.id,
          cookedAt: DateTime.now().subtract(const Duration(days: 1)),
          servings: 4,
          notes: BoundaryValues.extremelyLongText, // 10000+ chars
        );
        await mockDbHelper.insertMeal(meal);

        await tester.pumpWidget(buildMealHistoryScreen());
        await tester.pumpAndSettle();

        // Verify meal card is displayed
        expect(find.byType(Card), findsOneWidget);

        // Verify extremely long notes don't cause crashes
        expect(tester.takeException(), isNull,
            reason: 'Extremely long notes should not cause crashes');
      });

      testWidgets('displays meal with very high servings count (999)',
          (WidgetTester tester) async {
        final meal = Meal(
          id: 'meal-high-servings',
          recipeId: testRecipe.id,
          cookedAt: DateTime.now().subtract(const Duration(days: 1)),
          servings: 999,
        );
        await mockDbHelper.insertMeal(meal);

        await tester.pumpWidget(buildMealHistoryScreen());
        await tester.pumpAndSettle();

        // Verify meal card is displayed
        expect(find.byType(Card), findsOneWidget);

        // Verify servings displayed (as text somewhere in the widget tree)
        expect(find.textContaining('999'), findsAtLeastNWidgets(1),
            reason: 'Should display high servings count');
      });

      testWidgets('displays meal with decimal prep/cook times (15.5)',
          (WidgetTester tester) async {
        final meal = Meal(
          id: 'meal-decimal-times',
          recipeId: testRecipe.id,
          cookedAt: DateTime.now().subtract(const Duration(days: 1)),
          servings: 4,
          actualPrepTime: 15.5,
          actualCookTime: 22.5,
        );
        await mockDbHelper.insertMeal(meal);

        await tester.pumpWidget(buildMealHistoryScreen());
        await tester.pumpAndSettle();

        // Verify meal card is displayed
        expect(find.byType(Card), findsOneWidget);

        // Verify decimal times handled correctly (no crashes)
        expect(tester.takeException(), isNull,
            reason: 'Decimal times should be handled without errors');
      });

      testWidgets('displays meal with zero prep time',
          (WidgetTester tester) async {
        final meal = Meal(
          id: 'meal-zero-prep',
          recipeId: testRecipe.id,
          cookedAt: DateTime.now().subtract(const Duration(days: 1)),
          servings: 4,
          actualPrepTime: 0,
          actualCookTime: 30,
        );
        await mockDbHelper.insertMeal(meal);

        await tester.pumpWidget(buildMealHistoryScreen());
        await tester.pumpAndSettle();

        // Verify meal card is displayed
        expect(find.byType(Card), findsOneWidget,
            reason: 'Should display meal with zero prep time');
      });

      testWidgets('displays meal with zero cook time',
          (WidgetTester tester) async {
        final meal = Meal(
          id: 'meal-zero-cook',
          recipeId: testRecipe.id,
          cookedAt: DateTime.now().subtract(const Duration(days: 1)),
          servings: 4,
          actualPrepTime: 15,
          actualCookTime: 0,
        );
        await mockDbHelper.insertMeal(meal);

        await tester.pumpWidget(buildMealHistoryScreen());
        await tester.pumpAndSettle();

        // Verify meal card is displayed
        expect(find.byType(Card), findsOneWidget,
            reason: 'Should display meal with zero cook time');
      });

      testWidgets('displays unsuccessful meal appropriately',
          (WidgetTester tester) async {
        final meal = Meal(
          id: 'meal-unsuccessful',
          recipeId: testRecipe.id,
          cookedAt: DateTime.now().subtract(const Duration(days: 1)),
          servings: 4,
          wasSuccessful: false,
          notes: 'Burned the pasta',
        );
        await mockDbHelper.insertMeal(meal);

        await tester.pumpWidget(buildMealHistoryScreen());
        await tester.pumpAndSettle();

        // Verify meal card is displayed
        expect(find.byType(Card), findsOneWidget);

        // Verify unsuccessful indicator or notes visible
        expect(find.textContaining('Burned the pasta'), findsOneWidget,
            reason: 'Should show notes explaining unsuccessful meal');
      });

      testWidgets('displays meal with multiple recipes (multi-dish)',
          (WidgetTester tester) async {
        // Create a side dish recipe
        final sideDish = Recipe(
          id: 'side-dish-1',
          name: 'Garlic Bread',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
        );
        await mockDbHelper.insertRecipe(sideDish);

        // Create a meal
        final meal = Meal(
          id: 'meal-multi',
          recipeId: testRecipe.id,
          cookedAt: DateTime.now().subtract(const Duration(days: 1)),
          servings: 4,
        );
        await mockDbHelper.insertMeal(meal);

        // Note: MealHistoryScreen shows meals for a specific recipe
        // Multi-recipe information would be in meal_recipes junction table
        // This test verifies the screen handles primary dish correctly

        await tester.pumpWidget(buildMealHistoryScreen());
        await tester.pumpAndSettle();

        // Verify meal card is displayed
        expect(find.byType(Card), findsOneWidget,
            reason: 'Should display meal even if part of multi-dish');
      });

      testWidgets('displays meal with 10+ side dishes',
          (WidgetTester tester) async {
        // Create 12 side dish recipes
        for (int i = 0; i < 12; i++) {
          final sideDish = Recipe(
            id: 'side-$i',
            name: 'Side Dish $i',
            desiredFrequency: FrequencyType.weekly,
            createdAt: DateTime.now(),
          );
          await mockDbHelper.insertRecipe(sideDish);
        }

        // Create a meal
        final meal = Meal(
          id: 'meal-many-sides',
          recipeId: testRecipe.id,
          cookedAt: DateTime.now().subtract(const Duration(days: 1)),
          servings: 4,
        );
        await mockDbHelper.insertMeal(meal);

        await tester.pumpWidget(buildMealHistoryScreen());
        await tester.pumpAndSettle();

        // Verify meal card is displayed
        expect(find.byType(Card), findsOneWidget);

        // Verify no crashes with many side dishes
        expect(tester.takeException(), isNull,
            reason: 'Many side dishes should not cause crashes');
      });
    });

    group('Data Integrity', () {
      testWidgets('handles meal with deleted recipe (orphaned)',
          (WidgetTester tester) async {
        // Create a meal
        final meal = Meal(
          id: 'meal-orphaned',
          recipeId: testRecipe.id,
          cookedAt: DateTime.now().subtract(const Duration(days: 1)),
          servings: 4,
        );
        await mockDbHelper.insertMeal(meal);

        // Delete the recipe (creating orphaned meal)
        await mockDbHelper.deleteRecipe(testRecipe.id);

        // Note: We still pass the recipe object to the screen
        // This simulates the screen being opened before deletion
        await tester.pumpWidget(buildMealHistoryScreen(recipe: testRecipe));
        await tester.pumpAndSettle();

        // Verify screen handles gracefully (no crash)
        expect(tester.takeException(), isNull,
            reason: 'Should handle orphaned meals gracefully');
      });

      testWidgets('handles meal with missing recipe data',
          (WidgetTester tester) async {
        // Create a meal with non-existent recipeId
        final meal = Meal(
          id: 'meal-missing-recipe',
          recipeId: 'non-existent-recipe',
          cookedAt: DateTime.now().subtract(const Duration(days: 1)),
          servings: 4,
        );
        await mockDbHelper.insertMeal(meal);

        // Try to build screen with the orphaned meal's recipe ID
        // (This tests error handling)
        await tester.pumpWidget(buildMealHistoryScreen(recipe: testRecipe));
        await tester.pumpAndSettle();

        // Verify screen doesn't crash
        expect(tester.takeException(), isNull,
            reason: 'Should handle missing recipe data gracefully');
      });

      testWidgets('handles meals with same timestamp',
          (WidgetTester tester) async {
        final sameDate = DateTime.now().subtract(const Duration(days: 1));

        // Create 3 meals with identical timestamps
        for (int i = 0; i < 3; i++) {
          final meal = Meal(
            id: 'meal-same-time-$i',
            recipeId: testRecipe.id,
            cookedAt: sameDate,
            servings: 4,
          );
          await mockDbHelper.insertMeal(meal);
        }

        await tester.pumpWidget(buildMealHistoryScreen());
        await tester.pumpAndSettle();

        // Verify all 3 meals are displayed
        expect(find.byType(Card), findsNWidgets(3),
            reason: 'Should display all meals even with same timestamp');
      });

      testWidgets('handles meals spanning multiple years',
          (WidgetTester tester) async {
        // Create meals from different years
        final now = DateTime.now();
        final dates = [
          DateTime(now.year - 2, 6, 15), // 2 years ago
          DateTime(now.year - 1, 3, 20), // 1 year ago
          DateTime(now.year, 1, 10), // This year
          now, // Today
        ];

        for (int i = 0; i < dates.length; i++) {
          final meal = Meal(
            id: 'meal-year-$i',
            recipeId: testRecipe.id,
            cookedAt: dates[i],
            servings: 4,
          );
          await mockDbHelper.insertMeal(meal);
        }

        await tester.pumpWidget(buildMealHistoryScreen());
        await tester.pumpAndSettle();

        // Verify all meals are displayed
        expect(find.byType(Card), findsNWidgets(4),
            reason: 'Should display meals from multiple years');

        // Verify dates are formatted correctly (no overflow/crash)
        expect(tester.takeException(), isNull,
            reason: 'Multi-year date handling should not crash');
      });

      testWidgets('date filtering edge cases - very old dates',
          (WidgetTester tester) async {
        // Create meal from year 2000
        final oldMeal = Meal(
          id: 'meal-old',
          recipeId: testRecipe.id,
          cookedAt: DateTime(2000, 1, 1),
          servings: 4,
        );
        await mockDbHelper.insertMeal(oldMeal);

        await tester.pumpWidget(buildMealHistoryScreen());
        await tester.pumpAndSettle();

        // Verify old meal is displayed
        expect(find.byType(Card), findsOneWidget);

        // Verify date formatting handles old dates correctly
        expect(tester.takeException(), isNull,
            reason: 'Should handle very old dates correctly');
      });
    });
  });
}
