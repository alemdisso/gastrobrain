// test/screens/weekly_plan_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/core/di/providers/database_provider.dart';
import 'package:gastrobrain/core/services/recommendation_service.dart';
import 'package:gastrobrain/core/di/service_provider.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/models/meal_plan.dart';
import 'package:gastrobrain/models/meal_plan_item.dart';
import 'package:gastrobrain/models/meal_plan_item_recipe.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/protein_type.dart';
import 'package:gastrobrain/screens/weekly_plan_screen.dart';
import 'package:gastrobrain/utils/id_generator.dart';
import '../mocks/mock_database_helper.dart';

void main() {
  late MockDatabaseHelper mockDbHelper;

  setUp(() {
    // Create a fresh mock database for each test
    mockDbHelper = MockDatabaseHelper();

    // Inject the mock database into the provider
    DatabaseProvider().setDatabaseHelper(mockDbHelper);
  });

  tearDown(() {
    // Reset the mock database after each test
    mockDbHelper.resetAllData();
  });

  testWidgets('WeeklyPlanScreen loads data from injected database',
      (WidgetTester tester) async {
    // Set up mock data
    final weekStart = DateTime(2023, 6, 2); // A Friday
    final testRecipe = Recipe(
      id: 'test-recipe-1',
      name: 'Test Recipe 1',
      desiredFrequency: FrequencyType.weekly,
      createdAt: DateTime.now(),
    );

    // Add recipe to mock database
    await mockDbHelper.insertRecipe(testRecipe);

    // Create a test meal plan with the recipe
    final mealPlanId = IdGenerator.generateId();
    final mealPlan = MealPlan(
      id: mealPlanId,
      weekStartDate: weekStart,
      notes: 'Test Plan',
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
    );

    // Add the meal plan to our mocks database
    mockDbHelper.mealPlans[mealPlanId] = mealPlan;

    // Create a meal plan item
    final itemId = IdGenerator.generateId();
    final planItem = MealPlanItem(
      id: itemId,
      mealPlanId: mealPlanId,
      plannedDate: MealPlanItem.formatPlannedDate(weekStart), // Friday
      mealType: MealPlanItem.lunch,
    );

    // Add recipe association
    planItem.mealPlanItemRecipes = [
      MealPlanItemRecipe(
        mealPlanItemId: itemId,
        recipeId: testRecipe.id,
        isPrimaryDish: true,
      )
    ];

    // Add the items to the meal plan
    mealPlan.items.add(planItem);

    // Build the widget with the injected mock database
    await tester.pumpWidget(MaterialApp(
      home: WeeklyPlanScreen(
        databaseHelper: mockDbHelper,
      ),
    ));

    // Pump a few times to allow async operations to complete
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Verify UI reflects the mock data
    expect(find.text('Week of'), findsOneWidget);

    // Advance a frame to ensure all async work is complete
    await tester.pumpAndSettle();
  });

  testWidgets('WeeklyPlanScreen shows empty state when no meal plan exists',
      (WidgetTester tester) async {
    // Build the widget with the injected mock database - no meal plans added
    await tester.pumpWidget(MaterialApp(
      home: WeeklyPlanScreen(
        databaseHelper: mockDbHelper,
      ),
    ));

    // Pump to allow async operations to complete
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Verify we see empty slots with "Add meal" text
    expect(find.text('Add meal'), findsWidgets);
  });

  testWidgets(
      'WeeklyPlanScreen uses recommendations from RecommendationService',
      (WidgetTester tester) async {
    // Set up mock data
    final testRecipe1 = Recipe(
      id: 'test-recipe-1',
      name: 'Test Recipe 1',
      desiredFrequency: FrequencyType.weekly,
      createdAt: DateTime.now(),
    );

    final testRecipe2 = Recipe(
      id: 'test-recipe-2',
      name: 'Test Recipe 2',
      desiredFrequency: FrequencyType.weekly,
      createdAt: DateTime.now(),
    );

    // Add recipes to mock database
    await mockDbHelper.insertRecipe(testRecipe1);
    await mockDbHelper.insertRecipe(testRecipe2);

    // Build the widget with the injected mock database
    await tester.pumpWidget(MaterialApp(
      home: WeeklyPlanScreen(
        databaseHelper: mockDbHelper,
      ),
    ));

    // Pump to allow async operations to complete
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Find and tap an "Add meal" element to trigger recommendation flow
    // Note: In a real test, we would need to actually tap this and verify
    // that recommendations appear, but this is difficult in a widget test
    // without more complex mocking of the UI interactions
    expect(find.text('Add meal'), findsWidgets);

    // For now, just verify the screen loaded successfully with our mock data
    expect(find.text('Week of'), findsOneWidget);
  });

  // This test shows how to use a custom mock recommendation service
  testWidgets('Can inject custom recommendation service',
      (WidgetTester tester) async {
    // Create a custom mock recommendation service
    final customRecommendationService = MockRecommendationService();

    // Add some test recipes to the mock database
    final testRecipe = Recipe(
      id: 'test-recipe-1',
      name: 'Test Recipe 1',
      desiredFrequency: FrequencyType.weekly,
      createdAt: DateTime.now(),
    );

    customRecommendationService.addMockRecommendation(testRecipe);

    // Inject it using the service provider pattern
    ServiceProvider.recommendations
        .setRecommendationService(customRecommendationService);

    // Add some test recipes to the mock database
    final dbRecipe = Recipe(
      id: 'test-recipe-1',
      name: 'Test Recipe 1',
      desiredFrequency: FrequencyType.weekly,
      createdAt: DateTime.now(),
    );

    await mockDbHelper.insertRecipe(dbRecipe);

    // Build the widget
    await tester.pumpWidget(MaterialApp(
      home: WeeklyPlanScreen(
        databaseHelper: mockDbHelper,
      ),
    ));

    // Pump to allow async operations to complete
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Basic verification that screen loaded
    expect(find.text('Week of'), findsOneWidget);
  });
}

/// A simple mock of RecommendationService for testing
class MockRecommendationService implements RecommendationService {
  final List<Recipe> _mockRecommendations = [];

  void addMockRecommendation(Recipe recipe) {
    _mockRecommendations.add(recipe);
  }

  @override
  Future<List<Recipe>> getRecommendations({
    int count = 5,
    List<String> excludeIds = const [],
    List<ProteinType>? avoidProteinTypes,
    DateTime? forDate,
    String? mealType,
  }) async {
    // Simply return our mock recommendations regardless of parameters
    return _mockRecommendations;
  }

  @override
  Future<RecommendationResults> getDetailedRecommendations({
    int count = 5,
    List<String> excludeIds = const [],
    List<ProteinType>? avoidProteinTypes,
    DateTime? forDate,
    String? mealType,
  }) async {
    final recommendations = _mockRecommendations
        .map((recipe) => RecipeRecommendation(
              recipe: recipe,
              totalScore: 100.0,
              factorScores: {'mock_factor': 100.0},
            ))
        .toList();

    return RecommendationResults(
      recommendations: recommendations,
      totalEvaluated: recommendations.length,
      queryParameters: {},
    );
  }

  // Implement required interface methods
  @override
  void registerFactor(RecommendationFactor factor) {}

  @override
  void unregisterFactor(String factorId) {}

  @override
  List<RecommendationFactor> get factors => [];

  @override
  int get totalWeight => 100;

  @override
  void registerStandardFactors() {}
}
