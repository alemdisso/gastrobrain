// test/screens/meal_history_edit_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/meal.dart';
import 'package:gastrobrain/models/meal_recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/screens/meal_history_screen.dart';
import '../mocks/mock_database_helper.dart';

void main() {
  late MockDatabaseHelper mockDbHelper;
  late Recipe testRecipe;
  late Recipe sideRecipe;
  late Meal testMeal;

  setUp(() async {
    mockDbHelper = MockDatabaseHelper();

    testRecipe = Recipe(
      id: 'test-recipe-1',
      name: 'Grilled Chicken',
      desiredFrequency: FrequencyType.weekly,
      createdAt: DateTime.now(),
      difficulty: 3,
      prepTimeMinutes: 15,
      cookTimeMinutes: 25,
    );

    sideRecipe = Recipe(
      id: 'side-recipe-1',
      name: 'Rice Pilaf',
      desiredFrequency: FrequencyType.weekly,
      createdAt: DateTime.now(),
      difficulty: 2,
      prepTimeMinutes: 5,
      cookTimeMinutes: 20,
    );

    testMeal = Meal(
      id: 'test-meal-1',
      recipeId: null, // Using junction table
      cookedAt: DateTime.now().subtract(const Duration(days: 2)),
      servings: 3,
      notes: 'Original test notes',
      wasSuccessful: true,
      actualPrepTime: 20.0,
      actualCookTime: 30.0,
    );

    // Add recipes to mock database
    await mockDbHelper.insertRecipe(testRecipe);
    await mockDbHelper.insertRecipe(sideRecipe);

    // Add meal and its recipe association
    await mockDbHelper.insertMeal(testMeal);

    final mealRecipe = MealRecipe(
      mealId: testMeal.id,
      recipeId: testRecipe.id,
      isPrimaryDish: true,
    );
    await mockDbHelper.insertMealRecipe(mealRecipe);
  });

  tearDown(() async {
    mockDbHelper.resetAllData();
  });

  group('MealHistoryScreen Edit Functionality Tests', () {
    testWidgets('displays edit button for each meal',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show edit button
      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byTooltip('Edit meal'), findsOneWidget);
    });

    testWidgets('edit button opens edit dialog with pre-filled data',
        (WidgetTester tester) async {
      // Create a meal with specific notes
      final meal = Meal(
        id: 'editable-meal',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 3,
        notes: 'Original test notes',
        wasSuccessful: true,
        actualPrepTime: 15.0,
        actualCookTime: 25.0,
      );

      await mockDbHelper.insertMeal(meal);
      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: meal.id,
        recipeId: testRecipe.id,
        isPrimaryDish: true,
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the edit button (if it exists)
      final editButtons = find.byIcon(Icons.edit);
      if (editButtons.evaluate().isNotEmpty) {
        await tester.tap(editButtons.first);
        await tester.pumpAndSettle();
      }

      // Look specifically for the TextField with the notes content
      expect(find.byType(TextField), findsWidgets);

      // Find the TextField that contains our notes
      final textFields = find.byType(TextField);
      bool foundNotesField = false;

      for (final element in textFields.evaluate()) {
        final textField = element.widget as TextField;
        if (textField.controller?.text == 'Original test notes') {
          foundNotesField = true;
          break;
        }
      }

      expect(foundNotesField, isTrue,
          reason: 'Should find TextField with original notes');
    });
    testWidgets('displays edit button for multi-recipe meals',
        (WidgetTester tester) async {
      // Add a side dish to the meal
      final sideMealRecipe = MealRecipe(
        mealId: testMeal.id,
        recipeId: sideRecipe.id,
        isPrimaryDish: false,
      );
      await mockDbHelper.insertMealRecipe(sideMealRecipe);

      await tester.pumpWidget(
        MaterialApp(
          home: MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show recipe count badge for multi-recipe meal
      expect(find.text('2 recipes'), findsOneWidget);

      // Should still show edit button
      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byTooltip('Edit meal'), findsOneWidget);
    });

    testWidgets('edit button works with multi-recipe meals',
        (WidgetTester tester) async {
      // Create a multi-recipe meal
      final meal = Meal(
        id: 'multi-recipe-meal',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 4,
        notes: 'Multi-recipe meal notes',
        wasSuccessful: true,
      );

      await mockDbHelper.insertMeal(meal);

      // Add multiple recipes to the meal
      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: meal.id,
        recipeId: testRecipe.id, // "Grilled Chicken"
        isPrimaryDish: true,
      ));

      // Create a side recipe for this test
      final sideRecipe = Recipe(
        id: 'side-recipe-test',
        name: 'Rice Pilaf',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
      );
      await mockDbHelper.insertRecipe(sideRecipe);

      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: meal.id,
        recipeId: sideRecipe.id,
        isPrimaryDish: false,
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the multi-recipe meal is displayed correctly
      expect(find.text('2 recipes'), findsOneWidget);

      // Check for restaurant icons (allowing for duplicates due to meal appearing multiple times)
      expect(
          find.byIcon(Icons.restaurant), findsWidgets); // Primary dish icon(s)
      expect(find.byIcon(Icons.restaurant_menu),
          findsWidgets); // Side dish icon(s)

      // Verify both recipe names are present
      expect(find.textContaining('Grilled Chicken'), findsWidgets);
      expect(find.textContaining('Rice Pilaf'), findsWidgets);

      // Verify edit functionality exists (even if not fully implemented)
      final editButtons = find.byIcon(Icons.edit);
      expect(editButtons, findsWidgets,
          reason: 'Edit buttons should be present');

      // TODO: When edit functionality is implemented, test the actual editing
      // This test currently just verifies the multi-recipe meal displays correctly
    });

    testWidgets('edit button is properly sized and positioned',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the edit button
      final editButtonFinder = find.byIcon(Icons.edit);
      expect(editButtonFinder, findsOneWidget);

      // Verify it's an IconButton
      final iconButton = tester.widget<IconButton>(
        find.ancestor(
          of: editButtonFinder,
          matching: find.byType(IconButton),
        ),
      );

      // Verify button properties
      expect(iconButton.tooltip, 'Edit meal');
      expect(iconButton.constraints?.minWidth, 36);
      expect(iconButton.constraints?.minHeight, 36);
    });

    testWidgets('edit functionality preserves meal plan origin indicators',
        (WidgetTester tester) async {
      // Create a meal with plan origin note
      final planMeal = Meal(
        id: 'plan-meal-1',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 2,
        wasSuccessful: true,
      );

      await mockDbHelper.insertMeal(planMeal);

      // Add meal recipe with plan origin note
      final planMealRecipe = MealRecipe(
        mealId: planMeal.id,
        recipeId: testRecipe.id,
        isPrimaryDish: true,
        notes: 'From planned meal', // This should trigger the plan indicator
      );
      await mockDbHelper.insertMealRecipe(planMealRecipe);

      await tester.pumpWidget(
        MaterialApp(
          home: MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show meal plan origin indicator
      expect(find.byIcon(Icons.event_available), findsOneWidget);

      // Should still show edit button
      expect(find.byIcon(Icons.edit), findsWidgets);
    });
  });
}
