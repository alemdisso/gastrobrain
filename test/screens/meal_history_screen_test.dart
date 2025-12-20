// test/screens/meal_history_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/meal.dart';
import 'package:gastrobrain/models/meal_recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/screens/meal_history_screen.dart';
import 'package:gastrobrain/l10n/app_localizations.dart';
import '../mocks/mock_database_helper.dart';

void main() {
  late MockDatabaseHelper mockDbHelper;
  late Recipe testRecipe;
  late Recipe sideRecipe1;
  late Recipe sideRecipe2;

  Widget createTestableWidget(Widget child,
      {Locale locale = const Locale('en', '')}) {
    return MaterialApp(
      locale: locale,
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
      home: child,
    );
  }

  setUp(() async {
    mockDbHelper = MockDatabaseHelper();

    testRecipe = Recipe(
      id: 'test-recipe-1',
      name: 'Grilled Chicken',
      desiredFrequency: FrequencyType.weekly,
      createdAt: DateTime.now(),
    );

    sideRecipe1 = Recipe(
      id: 'side-recipe-1',
      name: 'Rice Pilaf',
      desiredFrequency: FrequencyType.weekly,
      createdAt: DateTime.now(),
    );

    sideRecipe2 = Recipe(
      id: 'side-recipe-2',
      name: 'Green Salad',
      desiredFrequency: FrequencyType.weekly,
      createdAt: DateTime.now(),
    );

    // Add recipes to mock database
    await mockDbHelper.insertRecipe(testRecipe);
    await mockDbHelper.insertRecipe(sideRecipe1);
    await mockDbHelper.insertRecipe(sideRecipe2);
  });

  tearDown(() async {
    mockDbHelper.resetAllData();
  });

  group('MealHistoryScreen Widget Tests', () {
    testWidgets('displays app bar and basic structure',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper, // Add the mock database helper
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Wait for async loading to complete
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Should show app bar with recipe name (without "History:" prefix)
      expect(find.text(testRecipe.name), findsOneWidget);

      // Should show floating action button
      expect(find.byIcon(Icons.add), findsOneWidget);

      // The widget should render without errors (basic structure test)
      expect(find.byType(MealHistoryScreen), findsOneWidget);
    });
    testWidgets('displays single recipe meal correctly',
        (WidgetTester tester) async {
      // Force larger screen size just in case
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;

      // Create a meal with single recipe using junction table approach
      final meal = Meal(
        id: 'test-meal-1',
        recipeId: null, // Using junction table
        cookedAt: DateTime.now().subtract(const Duration(days: 2)),
        servings: 4,
        notes: 'Test meal notes',
        wasSuccessful: true,
        actualPrepTime: 20.0,
        actualCookTime: 30.0,
      );

      // Add meal to mock database
      await mockDbHelper.insertMeal(meal);

      // Add junction record
      final mealRecipe = MealRecipe(
        mealId: meal.id,
        recipeId: testRecipe.id,
        isPrimaryDish: true,
        notes: 'Main dish',
      );
      await mockDbHelper.insertMealRecipe(mealRecipe);

      await tester.pumpWidget(
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper, // Add the mock database helper
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Should show meal with success indicator
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Should show serving count
      expect(find.text('4'), findsOneWidget);
      expect(find.byIcon(Icons.people), findsOneWidget);

      // Should show recipe name in app bar (not in card body)
      expect(find.text(testRecipe.name), findsOneWidget);

      // Should NOT show recipe count badge for single recipe
      expect(find.textContaining('recipes'), findsNothing);
    });
    testWidgets('displays multi-recipe meal with count badge',
        (WidgetTester tester) async {
      // Create a meal with multiple recipes
      final meal = Meal(
        id: 'multi-meal-1',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 3,
        notes: 'Multi-recipe test meal',
        wasSuccessful: true,
      );

      await mockDbHelper.insertMeal(meal);

      // Add multiple junction records
      final primaryMealRecipe = MealRecipe(
        mealId: meal.id,
        recipeId: testRecipe.id,
        isPrimaryDish: true,
        notes: 'Main dish',
      );

      final sideMealRecipe1 = MealRecipe(
        mealId: meal.id,
        recipeId: sideRecipe1.id,
        isPrimaryDish: false,
        notes: 'Side dish',
      );

      final sideMealRecipe2 = MealRecipe(
        mealId: meal.id,
        recipeId: sideRecipe2.id,
        isPrimaryDish: false,
        notes: 'Side dish',
      );

      await mockDbHelper.insertMealRecipe(primaryMealRecipe);
      await mockDbHelper.insertMealRecipe(sideMealRecipe1);
      await mockDbHelper.insertMealRecipe(sideMealRecipe2);

      await tester.pumpWidget(
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show side dish count badge for multiple recipes
      expect(find.text('2 side dishes'), findsOneWidget);

      // Should show primary recipe name in app bar (not in card body)
      expect(find.text(testRecipe.name), findsOneWidget);

      // Should show ONLY side recipes in card (not primary recipe)
      expect(find.text(sideRecipe1.name), findsOneWidget);
      expect(find.text(sideRecipe2.name), findsOneWidget);
      expect(find.byIcon(Icons.restaurant_menu), findsNWidgets(2));
    });
    testWidgets('shows primary dish vs side dish indicators correctly',
        (WidgetTester tester) async {
      // Create a meal where primary dish is not first in the list
      final meal = Meal(
        id: 'indicator-test-meal',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(hours: 12)),
        servings: 2,
        wasSuccessful: true,
      );

      await mockDbHelper.insertMeal(meal);

      // Add side dish first, then primary dish
      final sideMealRecipe = MealRecipe(
        mealId: meal.id,
        recipeId: sideRecipe1.id,
        isPrimaryDish: false,
        notes: 'Side dish',
      );

      final primaryMealRecipe = MealRecipe(
        mealId: meal.id,
        recipeId: testRecipe.id,
        isPrimaryDish: true,
        notes: 'Main dish',
      );

      await mockDbHelper.insertMealRecipe(sideMealRecipe);
      await mockDbHelper.insertMealRecipe(primaryMealRecipe);

      await tester.pumpWidget(
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show primary recipe name in app bar only (not in card)
      expect(find.text(testRecipe.name), findsOneWidget);

      // Should show side recipe in card with grey icon
      expect(find.text(sideRecipe1.name), findsOneWidget);
      expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);

      // Should show correct side dish count badge
      expect(find.text('1 side dish'), findsOneWidget);
    });
    testWidgets('handles mixed single and multi-recipe meals in history',
        (WidgetTester tester) async {
      // Create a single-recipe meal
      final singleMeal = Meal(
        id: 'single-meal',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 2,
        wasSuccessful: true,
      );

      await mockDbHelper.insertMeal(singleMeal);
      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: singleMeal.id,
        recipeId: testRecipe.id,
        isPrimaryDish: true,
      ));

      // Create a multi-recipe meal
      final multiMeal = Meal(
        id: 'multi-meal',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 2)),
        servings: 4,
        wasSuccessful: false, // Different success status
      );

      await mockDbHelper.insertMeal(multiMeal);
      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: multiMeal.id,
        recipeId: testRecipe.id,
        isPrimaryDish: true,
      ));
      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: multiMeal.id,
        recipeId: sideRecipe1.id,
        isPrimaryDish: false,
      ));

      await tester.pumpWidget(
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show both meals
      expect(
          find.byIcon(Icons.check_circle), findsOneWidget); // Success indicator
      expect(find.byIcon(Icons.warning), findsOneWidget); // Failure indicator

      // Should show side dish count badge only for multi-recipe meal
      expect(find.text('1 side dish'), findsOneWidget);

      // Should show both serving counts
      expect(find.text('2'), findsOneWidget); // Single meal servings
      expect(find.text('4'), findsOneWidget); // Multi meal servings
    });

    testWidgets('meal history shows edit option for cooked meals',
        (WidgetTester tester) async {
      // Create a cooked meal
      final meal = Meal(
        id: 'cooked-meal-edit',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 2,
        notes: 'Cooked meal notes',
        wasSuccessful: true,
      );

      await mockDbHelper.insertMeal(meal);
      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: meal.id,
        recipeId: testRecipe.id,
        isPrimaryDish: true,
      ));

      await tester.pumpWidget(
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Just verify that an edit icon/button exists
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets(
        'meal history displays date in English locale format (MM/DD/YYYY)',
        (WidgetTester tester) async {
      final cookedDate = DateTime(
          2023, 12, 25, 14, 30); // Includes time that should NOT be displayed

      final meal = Meal(
        id: 'date-test-meal-en',
        recipeId: null,
        cookedAt: cookedDate,
        servings: 2,
        wasSuccessful: true,
      );

      await mockDbHelper.insertMeal(meal);
      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: meal.id,
        recipeId: testRecipe.id,
        isPrimaryDish: true,
      ));

      await tester.pumpWidget(
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
          locale: const Locale('en', 'US'),
        ),
      );

      await tester.pumpAndSettle();

      // Should display date in English format (MM/DD/YYYY) WITHOUT time
      expect(find.textContaining('12/25/2023'), findsOneWidget);
    });

    testWidgets(
        'meal history displays date in Portuguese locale format (DD/MM/YYYY)',
        (WidgetTester tester) async {
      final cookedDate = DateTime(
          2023, 12, 25, 14, 30); // Includes time that should NOT be displayed

      final meal = Meal(
        id: 'date-test-meal-pt',
        recipeId: null,
        cookedAt: cookedDate,
        servings: 2,
        wasSuccessful: true,
      );

      await mockDbHelper.insertMeal(meal);
      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: meal.id,
        recipeId: testRecipe.id,
        isPrimaryDish: true,
      ));

      await tester.pumpWidget(
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
          locale: const Locale('pt', 'BR'),
        ),
      );

      await tester.pumpAndSettle();

      // Should display date in Portuguese format (DD/MM/YYYY) WITHOUT time
      expect(find.textContaining('25/12/2023'), findsOneWidget);
    });

    testWidgets(
        'displays recipe when it was used as a side dish (not primary)',
        (WidgetTester tester) async {
      // This tests the use case where we're viewing the history of a recipe
      // that's often used as a SIDE DISH (like Rice or Salad)
      // In this case, we WANT to see it listed in the meal card

      final meal = Meal(
        id: 'side-dish-view-meal',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 3,
        wasSuccessful: true,
      );

      await mockDbHelper.insertMeal(meal);

      // sideRecipe1 is the PRIMARY dish this time
      final primaryMealRecipe = MealRecipe(
        mealId: meal.id,
        recipeId: sideRecipe1.id,
        isPrimaryDish: true,
        notes: 'Main dish',
      );

      // testRecipe (the one we're viewing) is used as a SIDE dish
      final sideMealRecipe = MealRecipe(
        mealId: meal.id,
        recipeId: testRecipe.id,
        isPrimaryDish: false,
        notes: 'Side dish',
      );

      await mockDbHelper.insertMealRecipe(primaryMealRecipe);
      await mockDbHelper.insertMealRecipe(sideMealRecipe);

      // View the history for testRecipe (which was used as a side dish)
      await tester.pumpWidget(
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show testRecipe in app bar
      expect(find.text(testRecipe.name), findsAtLeastNWidgets(1));

      // IMPORTANT: Should also show testRecipe in the side dishes list
      // because it was used as a side dish (not primary) in this meal
      // This provides context about which meal it was part of
      expect(find.text(sideRecipe1.name), findsOneWidget);

      // Should show side dish count (1 side dish: testRecipe)
      expect(find.text('1 side dish'), findsOneWidget);
    });
  });
}
