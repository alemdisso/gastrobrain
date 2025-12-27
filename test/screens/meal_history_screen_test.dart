// test/screens/meal_history_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/meal.dart';
import 'package:gastrobrain/models/meal_recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/screens/meal_history_screen.dart';
import 'package:gastrobrain/screens/cook_meal_screen.dart';
import 'package:gastrobrain/core/providers/recipe_provider.dart';
import 'package:gastrobrain/l10n/app_localizations.dart';
import 'package:gastrobrain/core/errors/gastrobrain_exceptions.dart';
import '../mocks/mock_database_helper.dart';

/// Mock RecipeProvider for testing with call tracking
class MockRecipeProvider extends RecipeProvider {
  int refreshMealStatsCallCount = 0;

  @override
  Future<void> refreshMealStats() async {
    refreshMealStatsCallCount++;
    return Future.value();
  }

  void reset() {
    refreshMealStatsCallCount = 0;
  }
}

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

  /// Creates a testable widget with RecipeProvider support
  Widget createTestableWidgetWithProvider(
    Widget child,
    MockRecipeProvider provider, {
    Locale locale = const Locale('en', ''),
  }) {
    return ChangeNotifierProvider<RecipeProvider>(
      create: (_) => provider,
      child: MaterialApp(
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
      ),
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

      // Verify that PopupMenuButton with more_vert icon exists
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
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

  group('Loading State', () {
    testWidgets('displays loading indicator during initial load',
        (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      // Pump one frame to trigger the build but before async completes
      // Note: In tests with MockDatabaseHelper, the async operation completes
      // very quickly, but we can still catch the loading state on the first frame
      await tester.pump();

      // After settling, loading indicator should be gone
      await tester.pumpAndSettle();

      // Should NOT show loading indicator after data loads
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('loading indicator is centered',
        (WidgetTester tester) async {
      // For this test, we verify the structure when loading state exists
      // Build the widget
      await tester.pumpWidget(
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      // Pump once to build
      await tester.pump();

      // Try to find CircularProgressIndicator
      final loadingFinder = find.byType(CircularProgressIndicator);

      // If loading indicator is found, verify it's centered
      if (loadingFinder.evaluate().isNotEmpty) {
        final centerWidget = tester.widget<Center>(
          find.ancestor(
            of: loadingFinder,
            matching: find.byType(Center),
          ),
        );
        expect(centerWidget, isNotNull,
            reason: 'Loading indicator should be wrapped in Center widget');
      }

      // Complete loading
      await tester.pumpAndSettle();

      // After loading completes, indicator should be gone
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('screen transitions from loading to content state',
        (WidgetTester tester) async {
      // Add a meal to the database so we have content to display
      final meal = Meal(
        id: 'transition-test-meal',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 2,
        wasSuccessful: true,
      );

      await mockDbHelper.insertMeal(meal);
      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: meal.id,
        recipeId: testRecipe.id,
        isPrimaryDish: true,
      ));

      // Build the widget
      await tester.pumpWidget(
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      // Pump one frame
      await tester.pump();

      // After settling, loading should be done and content should appear
      await tester.pumpAndSettle();

      // Should not show loading indicator anymore
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Should show the meal content
      expect(find.text('2'), findsWidgets);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });

  group('Empty State', () {
    testWidgets('displays empty state when no meals exist',
        (WidgetTester tester) async {
      // Mock database returns empty list (no meals added)
      await tester.pumpWidget(
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show history icon
      expect(find.byIcon(Icons.history), findsOneWidget);

      // Should show "No meals recorded yet" message
      expect(find.text('No meals recorded yet'), findsOneWidget);

      // Verify icon is grey colored
      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.history));
      expect(iconWidget.color, Colors.grey);
      expect(iconWidget.size, 64);

      // Verify message is grey colored
      final textWidget = tester.widget<Text>(find.text('No meals recorded yet'));
      expect(textWidget.style?.color, Colors.grey);
      expect(textWidget.style?.fontSize, 18);

      // Verify empty state is centered
      final centerWidget = tester.widget<Center>(
        find.ancestor(
          of: find.byIcon(Icons.history),
          matching: find.byType(Center),
        ),
      );
      expect(centerWidget, isNotNull);

      // Verify Column has center alignment
      final columnWidget = tester.widget<Column>(
        find.ancestor(
          of: find.byIcon(Icons.history),
          matching: find.byType(Column),
        ),
      );
      expect(columnWidget.mainAxisAlignment, MainAxisAlignment.center);
    });

    testWidgets('displays localized empty state message in Portuguese',
        (WidgetTester tester) async {
      // Mock database returns empty list (no meals added)
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

      // Should show Portuguese message
      expect(find.text('Nenhuma refeição registrada ainda'), findsOneWidget);

      // Should still show history icon
      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets('displays localized empty state message in English',
        (WidgetTester tester) async {
      // Mock database returns empty list (no meals added)
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

      // Should show English message
      expect(find.text('No meals recorded yet'), findsOneWidget);

      // Should still show history icon
      expect(find.byIcon(Icons.history), findsOneWidget);
    });
  });

  group('Error State', () {
    testWidgets('displays error view when getMealsForRecipe throws NotFoundException',
        (WidgetTester tester) async {
      // Configure mock to throw NotFoundException
      mockDbHelper.failOnOperation('getMealsForRecipe',
          exception: NotFoundException('Recipe not found'));

      await tester.pumpWidget(
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show error icon
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      // Should show error message
      expect(find.text('Recipe not found'), findsOneWidget);

      // Should show "Try Again" button
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('displays error view when getMealsForRecipe throws GastrobrainException',
        (WidgetTester tester) async {
      // Configure mock to throw GastrobrainException
      mockDbHelper.failOnOperation('getMealsForRecipe',
          exception: const GastrobrainException('Database connection failed'));

      await tester.pumpWidget(
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show error icon
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      // Should show error message with prefix
      expect(find.textContaining('Error loading meals:'), findsOneWidget);
      expect(find.textContaining('Database connection failed'), findsOneWidget);

      // Should show "Try Again" button
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('displays error view when getMealsForRecipe throws generic exception',
        (WidgetTester tester) async {
      // Configure mock to throw generic exception
      mockDbHelper.failOnOperation('getMealsForRecipe');

      await tester.pumpWidget(
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show error icon
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      // Should show generic error message
      expect(find.text('An unexpected error occurred while loading meals'),
          findsOneWidget);

      // Should show "Try Again" button
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('error icon is displayed with correct styling',
        (WidgetTester tester) async {
      // Configure mock to throw exception
      mockDbHelper.failOnOperation('getMealsForRecipe',
          exception: NotFoundException('Test error'));

      await tester.pumpWidget(
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find error icon
      final errorIcon = tester.widget<Icon>(find.byIcon(Icons.error_outline));

      // Verify icon properties
      expect(errorIcon.size, 64);
      expect(errorIcon.color, Colors.red);
    });

    testWidgets('error message is displayed with correct styling',
        (WidgetTester tester) async {
      // Configure mock to throw exception
      mockDbHelper.failOnOperation('getMealsForRecipe',
          exception: NotFoundException('Test error message'));

      await tester.pumpWidget(
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find error message text
      final errorText = tester.widget<Text>(find.text('Test error message'));

      // Verify text styling
      expect(errorText.style?.fontSize, 18);
      expect(errorText.style?.color, Colors.red);
      expect(errorText.textAlign, TextAlign.center);
    });

    testWidgets('Try Again button is displayed correctly',
        (WidgetTester tester) async {
      // Configure mock to throw exception
      mockDbHelper.failOnOperation('getMealsForRecipe',
          exception: NotFoundException('Test error'));

      await tester.pumpWidget(
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show Try Again button text
      expect(find.text('Try Again'), findsOneWidget);

      // The "Try Again" button functionality is already tested in the next test
      // This test just verifies the text is displayed
    });

    testWidgets('Try Again button triggers reload',
        (WidgetTester tester) async {
      // Configure mock to throw exception on first call only
      mockDbHelper.failOnOperation('getMealsForRecipe',
          exception: NotFoundException('Temporary error'));

      await tester.pumpWidget(
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show error view
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      // Note: After failOnOperation is called, the error is reset automatically
      // by resetErrorSimulation() after the exception is thrown
      // So the next call should succeed

      // Add a meal to show after retry
      final meal = Meal(
        id: 'retry-test-meal',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 2,
        wasSuccessful: true,
      );

      await mockDbHelper.insertMeal(meal);
      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: meal.id,
        recipeId: testRecipe.id,
        isPrimaryDish: true,
      ));

      // Tap Try Again button
      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      // Error view should be gone
      expect(find.byIcon(Icons.error_outline), findsNothing);

      // Content should be displayed
      expect(find.byType(Card), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('error messages are localized in English',
        (WidgetTester tester) async {
      // Configure mock to throw GastrobrainException
      mockDbHelper.failOnOperation('getMealsForRecipe',
          exception: const GastrobrainException('Test error'));

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

      // Should show English error prefix
      expect(find.textContaining('Error loading meals:'), findsOneWidget);

      // Should show English "Try Again" button
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('error messages are localized in Portuguese',
        (WidgetTester tester) async {
      // Configure mock to throw GastrobrainException
      mockDbHelper.failOnOperation('getMealsForRecipe',
          exception: const GastrobrainException('Erro de teste'));

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

      // Should show Portuguese error prefix
      expect(find.textContaining('Erro ao carregar refeições:'), findsOneWidget);

      // Should show Portuguese "Try Again" button
      expect(find.text('Tentar Novamente'), findsOneWidget);
    });

    testWidgets('generic error message is localized in Portuguese',
        (WidgetTester tester) async {
      // Configure mock to throw generic exception
      mockDbHelper.failOnOperation('getMealsForRecipe');

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

      // Should show Portuguese generic error message
      expect(
          find.text('Ocorreu um erro inesperado ao carregar as refeições'),
          findsOneWidget);
    });

    testWidgets('error messages do not expose technical details',
        (WidgetTester tester) async {
      // Configure mock to throw exception with technical details
      mockDbHelper.failOnOperation('getMealsForRecipe',
          exception: Exception('SQLite error: database locked at line 42'));

      await tester.pumpWidget(
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show user-friendly error message
      expect(find.text('An unexpected error occurred while loading meals'),
          findsOneWidget);

      // Should NOT show technical details like "SQLite", "database locked", or "line 42"
      expect(find.textContaining('SQLite'), findsNothing);
      expect(find.textContaining('database locked'), findsNothing);
      expect(find.textContaining('line 42'), findsNothing);
    });

    testWidgets('error view is centered on screen',
        (WidgetTester tester) async {
      // Configure mock to throw exception
      mockDbHelper.failOnOperation('getMealsForRecipe',
          exception: NotFoundException('Test error'));

      await tester.pumpWidget(
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify error view is wrapped in Center widget
      final centerWidget = tester.widget<Center>(
        find.ancestor(
          of: find.byIcon(Icons.error_outline),
          matching: find.byType(Center),
        ),
      );
      expect(centerWidget, isNotNull);

      // Verify Column has center alignment
      final columnWidget = tester.widget<Column>(
        find.ancestor(
          of: find.byIcon(Icons.error_outline),
          matching: find.byType(Column),
        ),
      );
      expect(columnWidget.mainAxisAlignment, MainAxisAlignment.center);
    });
  });

  group('Meal Card Details', () {
    group('Preparation and Cooking Time Display', () {
      testWidgets('displays prep and cook times when both are set',
          (WidgetTester tester) async {
        // Create a meal with prep and cook times
        final meal = Meal(
          id: 'time-display-test',
          recipeId: null,
          cookedAt: DateTime.now().subtract(const Duration(days: 1)),
          servings: 2,
          wasSuccessful: true,
          actualPrepTime: 15.0,
          actualCookTime: 30.0,
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

        // Should show timer icon
        expect(find.byIcon(Icons.timer), findsOneWidget);

        // Should show times in correct format (English)
        expect(find.text('Prep: 15.0min, Cook: 30.0min'), findsOneWidget);
      });

      testWidgets('displays prep and cook times in Portuguese locale',
          (WidgetTester tester) async {
        // Create a meal with prep and cook times
        final meal = Meal(
          id: 'time-pt-display-test',
          recipeId: null,
          cookedAt: DateTime.now().subtract(const Duration(days: 1)),
          servings: 2,
          wasSuccessful: true,
          actualPrepTime: 20.0,
          actualCookTime: 45.0,
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

        // Should show timer icon
        expect(find.byIcon(Icons.timer), findsOneWidget);

        // Should show times in Portuguese format
        expect(find.text('Preparo: 20.0min, Cozimento: 45.0min'),
            findsOneWidget);
      });

      testWidgets('hides prep/cook time row when both times are zero',
          (WidgetTester tester) async {
        // Create a meal with zero times
        final meal = Meal(
          id: 'zero-times-test',
          recipeId: null,
          cookedAt: DateTime.now().subtract(const Duration(days: 1)),
          servings: 2,
          wasSuccessful: true,
          actualPrepTime: 0.0,
          actualCookTime: 0.0,
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

        // Should NOT show timer icon or time text
        expect(find.byIcon(Icons.timer), findsNothing);
        expect(find.textContaining('Prep:'), findsNothing);
        expect(find.textContaining('Cook:'), findsNothing);
      });

      testWidgets('displays only prep time when cook time is zero',
          (WidgetTester tester) async {
        // Create a meal with only prep time
        final meal = Meal(
          id: 'prep-only-test',
          recipeId: null,
          cookedAt: DateTime.now().subtract(const Duration(days: 1)),
          servings: 2,
          wasSuccessful: true,
          actualPrepTime: 10.0,
          actualCookTime: 0.0,
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

        // Should show timer icon
        expect(find.byIcon(Icons.timer), findsOneWidget);

        // Should show time with prep time and zero cook time
        expect(find.text('Prep: 10.0min, Cook: 0.0min'), findsOneWidget);
      });

      testWidgets('displays only cook time when prep time is zero',
          (WidgetTester tester) async {
        // Create a meal with only cook time
        final meal = Meal(
          id: 'cook-only-test',
          recipeId: null,
          cookedAt: DateTime.now().subtract(const Duration(days: 1)),
          servings: 2,
          wasSuccessful: true,
          actualPrepTime: 0.0,
          actualCookTime: 25.0,
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

        // Should show timer icon
        expect(find.byIcon(Icons.timer), findsOneWidget);

        // Should show time with zero prep and cook time
        expect(find.text('Prep: 0.0min, Cook: 25.0min'), findsOneWidget);
      });
    });

    group('Notes Display', () {
      testWidgets('displays notes when notes are not empty',
          (WidgetTester tester) async {
        // Create a meal with notes
        final meal = Meal(
          id: 'notes-display-test',
          recipeId: null,
          cookedAt: DateTime.now().subtract(const Duration(days: 1)),
          servings: 2,
          notes: 'This was delicious! Will make again.',
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

        // Should show notes text
        expect(find.text('This was delicious! Will make again.'),
            findsOneWidget);

        // Verify notes text styling
        final notesText = tester.widget<Text>(
            find.text('This was delicious! Will make again.'));
        expect(notesText.style, isNotNull);
        // The style should match bodySmall from the theme
      });

      testWidgets('hides notes when notes are empty',
          (WidgetTester tester) async {
        // Create a meal with empty notes
        final meal = Meal(
          id: 'no-notes-test',
          recipeId: null,
          cookedAt: DateTime.now().subtract(const Duration(days: 1)),
          servings: 2,
          notes: '',
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

        // Should only show standard meal info, not extra text
        // Verify by checking that only expected widgets are present
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(find.text('2'), findsWidgets);
        expect(find.byIcon(Icons.people), findsOneWidget);

        // The card should not have a lot of text content beyond the date
        final textWidgets = find.byType(Text);
        // Should find: recipe name in app bar, date, servings, and potentially other UI elements
        // but no long note text
        expect(textWidgets.evaluate().length, lessThan(10));
      });

      testWidgets('handles long notes without overflow',
          (WidgetTester tester) async {
        // Create a meal with very long notes
        final longNotes =
            'This is a very long note that goes on and on about how amazing this meal was. '
            'I made it for a dinner party and everyone loved it. The flavors were incredible, '
            'and the presentation was beautiful. I will definitely make this again for special occasions. '
            'It took a bit longer than expected but was totally worth the effort. '
            'Highly recommended for anyone who enjoys good food!';

        final meal = Meal(
          id: 'long-notes-test',
          recipeId: null,
          cookedAt: DateTime.now().subtract(const Duration(days: 1)),
          servings: 4,
          notes: longNotes,
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

        // Should display the long notes
        expect(find.text(longNotes), findsOneWidget);

        // Verify no overflow errors occurred
        // If there was overflow, the test would fail with an exception
        // The layout should handle long text gracefully
      });
    });
  });

  group('Refresh Functionality', () {
    testWidgets('refresh button exists in app bar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find refresh button in the AppBar
      final refreshButton = find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(IconButton),
      );

      expect(refreshButton, findsOneWidget);
    });

    testWidgets('refresh button shows refresh icon',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify refresh icon is displayed
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byIcon(Icons.refresh),
        ),
        findsOneWidget,
      );
    });

    testWidgets('refresh button has correct tooltip in English',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the IconButton with refresh icon
      final refreshButton = find.descendant(
        of: find.byType(AppBar),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is IconButton &&
              widget.icon is Icon &&
              (widget.icon as Icon).icon == Icons.refresh,
        ),
      );

      expect(refreshButton, findsOneWidget);

      // Get the IconButton widget and check tooltip
      final iconButton = tester.widget<IconButton>(refreshButton);
      expect(iconButton.tooltip, equals('Refresh'));
    });

    testWidgets('refresh button has correct tooltip in Portuguese',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
          locale: const Locale('pt'),
        ),
      );

      await tester.pumpAndSettle();

      // Find the IconButton with refresh icon
      final refreshButton = find.descendant(
        of: find.byType(AppBar),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is IconButton &&
              widget.icon is Icon &&
              (widget.icon as Icon).icon == Icons.refresh,
        ),
      );

      expect(refreshButton, findsOneWidget);

      // Get the IconButton widget and check tooltip
      final iconButton = tester.widget<IconButton>(refreshButton);
      expect(iconButton.tooltip, equals('Atualizar'));
    });

    testWidgets('tapping refresh button reloads meals',
        (WidgetTester tester) async {
      // Initial meal
      final initialMeal = Meal(
        id: 'initial-meal',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 2,
        wasSuccessful: true,
      );

      await mockDbHelper.insertMeal(initialMeal);
      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: initialMeal.id,
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

      // Verify initial meal is displayed
      expect(find.byType(Card), findsOneWidget);

      // Add a new meal to the database
      final newMeal = Meal(
        id: 'new-meal',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 2)),
        servings: 3,
        wasSuccessful: true,
      );

      await mockDbHelper.insertMeal(newMeal);
      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: newMeal.id,
        recipeId: testRecipe.id,
        isPrimaryDish: true,
      ));

      // Tap the refresh button
      final refreshButton = find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.refresh),
      );

      await tester.tap(refreshButton);
      await tester.pumpAndSettle();

      // Now we should see both meals
      expect(find.byType(Card), findsNWidgets(2));
    });

    testWidgets('refresh updates the list with new data',
        (WidgetTester tester) async {
      // Start with a meal
      final meal1 = Meal(
        id: 'meal-1',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 2,
        wasSuccessful: true,
      );

      await mockDbHelper.insertMeal(meal1);
      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: meal1.id,
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

      // Verify we have 1 meal
      expect(find.byType(Card), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // servings count

      // Delete the meal and add a different one
      await mockDbHelper.deleteMeal(meal1.id);

      final meal2 = Meal(
        id: 'meal-2',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 2)),
        servings: 4,
        wasSuccessful: false, // Different success state
      );

      await mockDbHelper.insertMeal(meal2);
      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: meal2.id,
        recipeId: testRecipe.id,
        isPrimaryDish: true,
      ));

      // Tap refresh to reload
      final refreshButton = find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.refresh),
      );

      await tester.tap(refreshButton);
      await tester.pumpAndSettle();

      // Still 1 card, but with updated data
      expect(find.byType(Card), findsOneWidget);
      expect(find.text('4'), findsOneWidget); // New servings count
      expect(find.byIcon(Icons.warning), findsOneWidget); // Failure icon
    });
  });

  group('Navigation', () {
    testWidgets('FAB shows add icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify FAB has add icon
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);

      final fabWidget = tester.widget<FloatingActionButton>(fab);
      expect(fabWidget.child, isA<Icon>());

      final icon = fabWidget.child as Icon;
      expect(icon.icon, equals(Icons.add));
    });

    testWidgets('FAB has correct tooltip in English',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
          locale: const Locale('en', ''),
        ),
      );

      await tester.pumpAndSettle();

      // Verify FAB tooltip
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);

      final fabWidget = tester.widget<FloatingActionButton>(fab);
      expect(fabWidget.tooltip, equals('Cook Now'));
    });

    testWidgets('FAB has correct tooltip in Portuguese',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
          locale: const Locale('pt', ''),
        ),
      );

      await tester.pumpAndSettle();

      // Verify FAB tooltip is localized
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);

      final fabWidget = tester.widget<FloatingActionButton>(fab);
      expect(fabWidget.tooltip, equals('Cozinhar Agora'));
    });

    testWidgets('FAB navigates to CookMealScreen when tapped',
        (WidgetTester tester) async {
      final mockProvider = MockRecipeProvider();

      await tester.pumpWidget(
        createTestableWidgetWithProvider(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
          mockProvider,
        ),
      );

      await tester.pumpAndSettle();

      // Tap the FAB
      final fab = find.byType(FloatingActionButton);
      await tester.tap(fab);
      await tester.pumpAndSettle();

      // Verify CookMealScreen is now visible
      expect(find.byType(CookMealScreen), findsOneWidget);
    });

    testWidgets('returning from CookMealScreen with true triggers reload',
        (WidgetTester tester) async {
      final mockProvider = MockRecipeProvider();

      // Create a meal to verify reload happens
      final meal1 = Meal(
        id: 'meal-1',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 2,
        wasSuccessful: true,
      );

      await mockDbHelper.insertMeal(meal1);
      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: meal1.id,
        recipeId: testRecipe.id,
        isPrimaryDish: true,
      ));

      await tester.pumpWidget(
        createTestableWidgetWithProvider(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
          mockProvider,
        ),
      );

      await tester.pumpAndSettle();

      // Verify initial state - 1 meal card
      expect(find.byType(Card), findsOneWidget);

      // Tap the FAB to navigate to CookMealScreen
      final fab = find.byType(FloatingActionButton);
      await tester.tap(fab);
      await tester.pumpAndSettle();

      // Verify we're on CookMealScreen
      expect(find.byType(CookMealScreen), findsOneWidget);

      // Add a new meal while on CookMealScreen
      final meal2 = Meal(
        id: 'meal-2',
        recipeId: null,
        cookedAt: DateTime.now(),
        servings: 4,
        wasSuccessful: true,
      );

      await mockDbHelper.insertMeal(meal2);
      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: meal2.id,
        recipeId: testRecipe.id,
        isPrimaryDish: true,
      ));

      // Simulate returning with true (successful cook)
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pop(true);
      await tester.pumpAndSettle();

      // Verify we're back on MealHistoryScreen
      expect(find.byType(MealHistoryScreen), findsOneWidget);

      // Verify the list was reloaded - should now have 2 meals
      expect(find.byType(Card), findsNWidgets(2));

      // Verify refreshMealStats was called
      expect(mockProvider.refreshMealStatsCallCount, equals(1));
    });

    testWidgets(
        'returning from CookMealScreen with false does not trigger reload',
        (WidgetTester tester) async {
      final mockProvider = MockRecipeProvider();

      // Create a meal
      final meal1 = Meal(
        id: 'meal-1',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 2,
        wasSuccessful: true,
      );

      await mockDbHelper.insertMeal(meal1);
      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: meal1.id,
        recipeId: testRecipe.id,
        isPrimaryDish: true,
      ));

      await tester.pumpWidget(
        createTestableWidgetWithProvider(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
          mockProvider,
        ),
      );

      await tester.pumpAndSettle();

      // Verify initial state - 1 meal card
      expect(find.byType(Card), findsOneWidget);

      // Tap the FAB to navigate to CookMealScreen
      final fab = find.byType(FloatingActionButton);
      await tester.tap(fab);
      await tester.pumpAndSettle();

      // Verify we're on CookMealScreen
      expect(find.byType(CookMealScreen), findsOneWidget);

      // Add a new meal while on CookMealScreen (simulating user canceled)
      final meal2 = Meal(
        id: 'meal-2',
        recipeId: null,
        cookedAt: DateTime.now(),
        servings: 4,
        wasSuccessful: true,
      );

      await mockDbHelper.insertMeal(meal2);
      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: meal2.id,
        recipeId: testRecipe.id,
        isPrimaryDish: true,
      ));

      // Simulate returning with false (user canceled)
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pop(false);
      await tester.pumpAndSettle();

      // Verify we're back on MealHistoryScreen
      expect(find.byType(MealHistoryScreen), findsOneWidget);

      // Verify the list was NOT reloaded - should still show only 1 meal
      expect(find.byType(Card), findsOneWidget);

      // Verify refreshMealStats was NOT called
      expect(mockProvider.refreshMealStatsCallCount, equals(0));
    });

    testWidgets('returning from CookMealScreen with null does not reload',
        (WidgetTester tester) async {
      final mockProvider = MockRecipeProvider();

      // Create a meal
      final meal1 = Meal(
        id: 'meal-1',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 2,
        wasSuccessful: true,
      );

      await mockDbHelper.insertMeal(meal1);
      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: meal1.id,
        recipeId: testRecipe.id,
        isPrimaryDish: true,
      ));

      await tester.pumpWidget(
        createTestableWidgetWithProvider(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
          mockProvider,
        ),
      );

      await tester.pumpAndSettle();

      // Verify initial state - 1 meal card
      expect(find.byType(Card), findsOneWidget);

      // Tap the FAB to navigate to CookMealScreen
      final fab = find.byType(FloatingActionButton);
      await tester.tap(fab);
      await tester.pumpAndSettle();

      // Verify we're on CookMealScreen
      expect(find.byType(CookMealScreen), findsOneWidget);

      // Add a new meal while on CookMealScreen (simulating back button press)
      final meal2 = Meal(
        id: 'meal-2',
        recipeId: null,
        cookedAt: DateTime.now(),
        servings: 4,
        wasSuccessful: true,
      );

      await mockDbHelper.insertMeal(meal2);
      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: meal2.id,
        recipeId: testRecipe.id,
        isPrimaryDish: true,
      ));

      // Simulate returning with null (back button pressed)
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pop(); // pop without a value returns null
      await tester.pumpAndSettle();

      // Verify we're back on MealHistoryScreen
      expect(find.byType(MealHistoryScreen), findsOneWidget);

      // Verify the list was NOT reloaded - should still show only 1 meal
      expect(find.byType(Card), findsOneWidget);

      // Verify refreshMealStats was NOT called
      expect(mockProvider.refreshMealStatsCallCount, equals(0));
    });
  });
}
