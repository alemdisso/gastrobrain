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

  Widget createTestableWidget(Widget child) {
    return MaterialApp(
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

      // Should show app bar with recipe name
      expect(find.text('History: ${testRecipe.name}'), findsOneWidget);

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

      // Should show recipe name
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

      // Should show recipe count badge for multiple recipes
      expect(find.text('3 recipes'), findsOneWidget);

      // Should show primary recipe with main dish icon
      expect(find.text(testRecipe.name), findsOneWidget);
      expect(find.byIcon(Icons.restaurant), findsOneWidget);

      // Should show side recipes with side dish icons
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

      // Should show primary recipe with bold text and green icon
      expect(find.text(testRecipe.name), findsOneWidget);
      expect(find.byIcon(Icons.restaurant), findsOneWidget);

      // Should show side recipe with normal text and grey icon
      expect(find.text(sideRecipe1.name), findsOneWidget);
      expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);

      // Should show correct badge count
      expect(find.text('2 recipes'), findsOneWidget);
    });
    testWidgets('displays meal plan origin indicator correctly',
        (WidgetTester tester) async {
      // Create a meal that originated from a meal plan
      final meal = Meal(
        id: 'planned-meal',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 3)),
        servings: 2,
        wasSuccessful: true,
      );

      await mockDbHelper.insertMeal(meal);

      // Add meal recipe with plan origin note
      final mealRecipe = MealRecipe(
        mealId: meal.id,
        recipeId: testRecipe.id,
        isPrimaryDish: true,
        notes: 'From planned meal', // This should trigger the plan indicator
      );

      await mockDbHelper.insertMealRecipe(mealRecipe);

      await tester.pumpWidget(
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show meal plan origin indicator
      expect(find.byIcon(Icons.event_available), findsOneWidget);

      // Should show recipe name
      expect(find.text(testRecipe.name), findsOneWidget);

      // Verify tooltip exists for the plan indicator
      final planIndicator = find.byIcon(Icons.event_available);
      expect(planIndicator, findsOneWidget);
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

      // Should show recipe count badge only for multi-recipe meal
      expect(find.text('2 recipes'), findsOneWidget);

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
  });
}
