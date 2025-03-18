// test/widgets/weekly_calendar_widget_mock_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/meal_plan.dart';
import 'package:gastrobrain/models/meal_plan_item.dart';
import 'package:gastrobrain/models/meal_plan_item_recipe.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/widgets/weekly_calendar_widget.dart';

// Import our MockDatabaseHelper
import '../mocks/mock_database_helper.dart';

void main() {
  late DateTime testWeekStart;
  late MealPlan testMealPlan;
  late MockDatabaseHelper mockDbHelper;

  setUp(() {
    // Initialize our mock database
    mockDbHelper = MockDatabaseHelper();

    // Set up a Friday as the week start date
    testWeekStart = DateTime(2024, 3, 1); // March 1, 2024 is a Friday

    // Create test recipes that will be referenced by the meal plan
    final recipe1 = Recipe(
      id: 'recipe-1',
      name: 'Test Recipe 1',
      desiredFrequency: FrequencyType.weekly,
      createdAt: DateTime.now(),
    );

    final recipe2 = Recipe(
      id: 'recipe-2',
      name: 'Test Recipe 2',
      desiredFrequency: FrequencyType.weekly,
      createdAt: DateTime.now(),
    );

    final recipe3 = Recipe(
      id: 'recipe-3',
      name: 'Test Recipe 3',
      desiredFrequency: FrequencyType.weekly,
      createdAt: DateTime.now(),
    );

    // Add recipes to the mock database
    mockDbHelper.insertRecipe(recipe1);
    mockDbHelper.insertRecipe(recipe2);
    mockDbHelper.insertRecipe(recipe3);

    // Create a test meal plan with sample items
    final fridayLunch = MealPlanItem(
      id: 'test-item-1',
      mealPlanId: 'test-meal-plan',
      plannedDate: '2024-03-01', // Friday
      mealType: MealPlanItem.lunch,
    );

    // Add recipe association
    fridayLunch.mealPlanItemRecipes = [
      MealPlanItemRecipe(
        mealPlanItemId: 'test-item-1',
        recipeId: 'recipe-1',
        isPrimaryDish: true,
      )
    ];

    final fridayDinner = MealPlanItem(
      id: 'test-item-2',
      mealPlanId: 'test-meal-plan',
      plannedDate: '2024-03-01', // Friday
      mealType: MealPlanItem.dinner,
    );

    // Add recipe association
    fridayDinner.mealPlanItemRecipes = [
      MealPlanItemRecipe(
        mealPlanItemId: 'test-item-2',
        recipeId: 'recipe-2',
        isPrimaryDish: true,
      )
    ];

    final mondayLunch = MealPlanItem(
      id: 'test-item-3',
      mealPlanId: 'test-meal-plan',
      plannedDate: '2024-03-04', // Monday
      mealType: MealPlanItem.lunch,
    );

    // Add recipe association
    mondayLunch.mealPlanItemRecipes = [
      MealPlanItemRecipe(
        mealPlanItemId: 'test-item-3',
        recipeId: 'recipe-3',
        isPrimaryDish: true,
      )
    ];

    testMealPlan = MealPlan(
      id: 'test-meal-plan',
      weekStartDate: testWeekStart,
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
      items: [fridayLunch, fridayDinner, mondayLunch],
    );

    // Add test meal plan to our mock database
    mockDbHelper.insertMealPlan(testMealPlan);
  });

  tearDown(() {
    // Clean up after each test
    mockDbHelper.resetAllData();
  });

  testWidgets('WeeklyCalendarWidget renders correctly with mock database',
      (WidgetTester tester) async {
    // Set a consistent size for testing
    tester.view.physicalSize = const Size(1080, 1920); // Phone size
    tester.view.devicePixelRatio = 3.0;

    // Build the widget with empty meal plan
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WeeklyCalendarWidget(
            weekStartDate: testWeekStart,
            mealPlan: null,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify that at least some day text is shown
    expect(find.textContaining('day'), findsWidgets);

    // Verify meal type sections are shown
    expect(find.text('Lunch'), findsWidgets);
    expect(find.text('Dinner'), findsWidgets);

    // Verify empty state is shown
    expect(find.text('Add meal'), findsWidgets);

    // Reset the test environment
    addTearDown(tester.view.reset);
  });

  testWidgets('WeeklyCalendarWidget shows meal plan data with mock database',
      (WidgetTester tester) async {
    // Set a consistent size for testing
    tester.view.physicalSize = const Size(1080, 1920); // Phone size
    tester.view.devicePixelRatio = 3.0;

    // Build the widget with our test meal plan
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WeeklyCalendarWidget(
            weekStartDate: testWeekStart,
            mealPlan: testMealPlan,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify weekday labels
    expect(find.text('Friday'), findsWidgets);
    expect(find.text('Monday'), findsWidgets);

    // Verify meal type labels
    expect(find.text('Lunch'), findsWidgets);
    expect(find.text('Dinner'), findsWidgets);

    // Reset the test environment
    addTearDown(tester.view.reset);
  });
}
