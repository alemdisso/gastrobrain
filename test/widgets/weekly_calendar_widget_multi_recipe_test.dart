// test/widgets/weekly_calendar_widget_multi_recipe_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/meal_plan.dart';
import 'package:gastrobrain/models/meal_plan_item.dart';
import 'package:gastrobrain/models/meal_plan_item_recipe.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/models/time_context.dart';
import 'package:gastrobrain/widgets/weekly_calendar_widget.dart';
import '../mocks/mock_database_helper.dart';
import '../test_utils/test_app_wrapper.dart';
import '../test_utils/test_setup.dart';

void main() {
  late DateTime testWeekStart;
  late MockDatabaseHelper mockDbHelper;
  late Recipe primaryRecipe;
  late Recipe sideRecipe1;
  late Recipe sideRecipe2;

  setUp(() async {
    mockDbHelper = TestSetup.setupMockDatabase();
    testWeekStart = DateTime(2024, 3, 1); // Friday

    // Create test recipes
    primaryRecipe = Recipe(
      id: 'primary-recipe',
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
    await mockDbHelper.insertRecipe(primaryRecipe);
    await mockDbHelper.insertRecipe(sideRecipe1);
    await mockDbHelper.insertRecipe(sideRecipe2);
  });

  tearDown(() {
    TestSetup.cleanupMockDatabase(mockDbHelper);
  });

  group('WeeklyCalendarWidget Multi-Recipe Tests', () {
    testWidgets('displays single recipe meal without badge',
        (WidgetTester tester) async {
      // Create meal plan with single recipe
      final mealPlanItem = MealPlanItem(
        id: 'single-item',
        mealPlanId: 'test-plan',
        plannedDate: '2024-03-01',
        mealType: MealPlanItem.lunch,
      );

      mealPlanItem.mealPlanItemRecipes = [
        MealPlanItemRecipe(
          mealPlanItemId: 'single-item',
          recipeId: primaryRecipe.id,
          isPrimaryDish: true,
        ),
      ];

      final mealPlan = MealPlan(
        id: 'test-plan',
        weekStartDate: testWeekStart,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        items: [mealPlanItem],
      );

      await tester.pumpWidget(
        wrapWithLocalizations(Scaffold(
          body: WeeklyCalendarWidget(
            weekStartDate: testWeekStart,
            mealPlan: mealPlan,
            timeContext: TimeContext.current,
            databaseHelper: mockDbHelper,
          ),
        )),
      );

      await tester.pumpAndSettle();

      // Should show recipe name but no count badge for single recipe
      expect(find.text(primaryRecipe.name), findsOneWidget);
      expect(find.textContaining('receitas'), findsNothing);
    });
    testWidgets('displays multi-recipe meal with count badge in regular layout',
        (WidgetTester tester) async {
      // Force regular layout with larger screen size
      tester.view.physicalSize =
          const Size(800, 1200); // Wide enough for regular layout
      tester.view.devicePixelRatio = 1.0;

      // Create meal plan with multiple recipes
      final mealPlanItem = MealPlanItem(
        id: 'multi-item',
        mealPlanId: 'test-plan',
        plannedDate: '2024-03-01',
        mealType: MealPlanItem.dinner,
      );

      mealPlanItem.mealPlanItemRecipes = [
        MealPlanItemRecipe(
          mealPlanItemId: 'multi-item',
          recipeId: primaryRecipe.id,
          isPrimaryDish: true,
        ),
        MealPlanItemRecipe(
          mealPlanItemId: 'multi-item',
          recipeId: sideRecipe1.id,
          isPrimaryDish: false,
        ),
        MealPlanItemRecipe(
          mealPlanItemId: 'multi-item',
          recipeId: sideRecipe2.id,
          isPrimaryDish: false,
        ),
      ];

      final mealPlan = MealPlan(
        id: 'test-plan',
        weekStartDate: testWeekStart,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        items: [mealPlanItem],
      );

      await tester.pumpWidget(
        wrapWithLocalizations(Scaffold(
          body: WeeklyCalendarWidget(
            weekStartDate: testWeekStart,
            mealPlan: mealPlan,
            timeContext: TimeContext.current,
            databaseHelper: mockDbHelper,
          ),
        )),
      );

      await tester.pumpAndSettle();

      // Should show count badge for multiple recipes (3 total - 1 = 2 additional) - Portuguese
      expect(find.text('2 receitas'), findsOneWidget);

      // Reset view for other tests
      addTearDown(tester.view.reset);
    });
    testWidgets('shows different badge counts correctly',
        (WidgetTester tester) async {
      // Force regular layout
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;

      // Create meal plan with 2 recipes (should show "1 recipes")
      final mealPlanItem = MealPlanItem(
        id: 'two-recipe-item',
        mealPlanId: 'test-plan',
        plannedDate: '2024-03-01',
        mealType: MealPlanItem.lunch,
      );

      mealPlanItem.mealPlanItemRecipes = [
        MealPlanItemRecipe(
          mealPlanItemId: 'two-recipe-item',
          recipeId: primaryRecipe.id,
          isPrimaryDish: true,
        ),
        MealPlanItemRecipe(
          mealPlanItemId: 'two-recipe-item',
          recipeId: sideRecipe1.id,
          isPrimaryDish: false,
        ),
      ];

      final mealPlan = MealPlan(
        id: 'test-plan',
        weekStartDate: testWeekStart,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        items: [mealPlanItem],
      );

      await tester.pumpWidget(
        wrapWithLocalizations(Scaffold(
          body: WeeklyCalendarWidget(
            weekStartDate: testWeekStart,
            mealPlan: mealPlan,
            timeContext: TimeContext.current,
            databaseHelper: mockDbHelper,
          ),
        )),
      );

      await tester.pumpAndSettle();

      // Should show "1 recipes" for 2 total recipes (2-1=1 additional)
      expect(find.text('1 receita'), findsOneWidget);

      addTearDown(tester.view.reset);
    });
    testWidgets('handles mixed single and multi-recipe meals in same week',
        (WidgetTester tester) async {
      // Force regular layout
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;

      // Create meal plan with both single and multi-recipe meals
      final singleRecipeMeal = MealPlanItem(
        id: 'single-meal',
        mealPlanId: 'test-plan',
        plannedDate: '2024-03-01', // Friday
        mealType: MealPlanItem.lunch,
      );
      singleRecipeMeal.mealPlanItemRecipes = [
        MealPlanItemRecipe(
          mealPlanItemId: 'single-meal',
          recipeId: primaryRecipe.id,
          isPrimaryDish: true,
        ),
      ];

      final multiRecipeMeal = MealPlanItem(
        id: 'multi-meal',
        mealPlanId: 'test-plan',
        plannedDate: '2024-03-01', // Friday
        mealType: MealPlanItem.dinner,
      );
      multiRecipeMeal.mealPlanItemRecipes = [
        MealPlanItemRecipe(
          mealPlanItemId: 'multi-meal',
          recipeId: sideRecipe1.id,
          isPrimaryDish: true,
        ),
        MealPlanItemRecipe(
          mealPlanItemId: 'multi-meal',
          recipeId: sideRecipe2.id,
          isPrimaryDish: false,
        ),
      ];

      final mealPlan = MealPlan(
        id: 'test-plan',
        weekStartDate: testWeekStart,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        items: [singleRecipeMeal, multiRecipeMeal],
      );

      await tester.pumpWidget(
        wrapWithLocalizations(Scaffold(
          body: WeeklyCalendarWidget(
            weekStartDate: testWeekStart,
            mealPlan: mealPlan,
            timeContext: TimeContext.current,
            databaseHelper: mockDbHelper,
          ),
        )),
      );

      await tester.pumpAndSettle();

      // Single recipe meal should not show badge
      expect(find.text(primaryRecipe.name), findsOneWidget);

      // Multi-recipe meal should show badge
      expect(find.text(sideRecipe1.name), findsOneWidget);
      expect(find.text('1 receita'), findsOneWidget);

      addTearDown(tester.view.reset);
    });
  });
}
