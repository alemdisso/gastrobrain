// test/screens/meal_history/meal_history_edit_basic_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/meal.dart';
import 'package:gastrobrain/models/meal_recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/screens/meal_history_screen.dart';
import 'package:gastrobrain/l10n/app_localizations.dart';
import 'package:gastrobrain/core/providers/recipe_provider.dart';
import 'package:provider/provider.dart';
import '../../mocks/mock_database_helper.dart';

// Simple mock RecipeProvider for testing
class MockRecipeProvider extends RecipeProvider {
  @override
  Future<void> refreshMealStats() async {
    // No-op for testing
    return Future.value();
  }
}

void main() {
  late MockDatabaseHelper mockDbHelper;
  late Recipe testRecipe;
  late Recipe sideRecipe;
  late Meal testMeal;

  Widget createTestableWidget(Widget child) {
    return ChangeNotifierProvider<RecipeProvider>(
      create: (_) => MockRecipeProvider(),
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

  group('Basic Edit Functionality', () {
    testWidgets('displays edit button for each meal',
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

      // Should show PopupMenuButton with more_vert icon
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
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
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the menu button and then Edit
      final menuButtons = find.byIcon(Icons.more_vert);
      if (menuButtons.evaluate().isNotEmpty) {
        await tester.tap(menuButtons.first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Edit'));
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
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show side dish count badge for multi-recipe meal
      expect(find.text('1 side dish'), findsOneWidget);

      // Should still show PopupMenuButton
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
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
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the multi-recipe meal is displayed correctly
      expect(find.text('1 side dish'), findsOneWidget);

      // Check for side dish icons (primary dish not shown in cards)
      expect(find.byIcon(Icons.restaurant_menu),
          findsWidgets); // Side dish icon(s)

      // Verify both recipe names are present
      expect(find.textContaining('Grilled Chicken'), findsWidgets);
      expect(find.textContaining('Rice Pilaf'), findsWidgets);

      // Verify edit functionality exists via PopupMenuButton
      final menuButtons = find.byIcon(Icons.more_vert);
      expect(menuButtons, findsWidgets,
          reason: 'PopupMenuButton should be present');
    });

    testWidgets('PopupMenuButton is properly sized and positioned',
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

      // Find the PopupMenuButton
      final menuButtonFinder = find.byIcon(Icons.more_vert);
      expect(menuButtonFinder, findsOneWidget);

      // Verify it's a PopupMenuButton
      final popupMenuButton = tester.widget<PopupMenuButton<String>>(
        find.ancestor(
          of: menuButtonFinder,
          matching: find.byType(PopupMenuButton<String>),
        ),
      );

      // Verify button properties
      expect(popupMenuButton.padding, const EdgeInsets.all(4));
      expect(popupMenuButton.constraints?.minWidth, 36);
      expect(popupMenuButton.constraints?.minHeight, 36);
    });
  });

  group('Editing Workflow', () {
    testWidgets('edits servings and saves changes', (WidgetTester tester) async {
      // Create a meal with specific servings
      final meal = Meal(
        id: 'edit-servings-meal',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 3, // Original servings
        notes: 'Test meal',
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
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the menu button - there are 2 meals, we want the second one (our test meal)
      final menuButtons = find.byIcon(Icons.more_vert);
      expect(menuButtons, findsWidgets);
      await tester.tap(menuButtons.last); // Use 'last' to get our test meal, not the setUp meal
      await tester.pumpAndSettle();

      // Tap Edit
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Find servings field and clear it, then enter new value
      final servingsField = find.ancestor(
        of: find.text('Number of Servings'),
        matching: find.byType(TextFormField),
      );
      expect(servingsField, findsOneWidget);

      await tester.tap(servingsField);
      await tester.pumpAndSettle();

      // Clear existing value and enter new one
      await tester.enterText(servingsField, '5');
      await tester.pumpAndSettle();

      // Tap Save Changes button (EditMealRecordingDialog)
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Wait for async database operations to complete and screen to rebuild
      await tester.pumpAndSettle();

      // Verify the meal was updated in the database
      final updatedMeal = mockDbHelper.meals[meal.id];
      expect(updatedMeal, isNotNull);
      expect(updatedMeal!.servings, equals(5),
          reason: 'Servings should be updated to 5');
    });

    testWidgets('edits notes and saves changes', (WidgetTester tester) async {
      // Create a meal with specific notes
      final meal = Meal(
        id: 'edit-notes-meal',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 3,
        notes: 'Original notes',
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
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the menu button - there are 3 meals now, we want the last one
      final menuButtons = find.byIcon(Icons.more_vert);
      expect(menuButtons, findsWidgets);
      await tester.tap(menuButtons.last);
      await tester.pumpAndSettle();

      // Tap Edit
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Find notes field and enter new value
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Original notes'),
        'Updated notes text',
      );
      await tester.pumpAndSettle();

      // Tap Save Changes button
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Wait for async database operations to complete
      await tester.pumpAndSettle();

      // Verify the meal was updated in the database
      final updatedMeal = mockDbHelper.meals[meal.id];
      expect(updatedMeal, isNotNull);
      expect(updatedMeal!.notes, equals('Updated notes text'),
          reason: 'Notes should be updated to new text');
    });

    testWidgets('edits prep time and saves changes', (WidgetTester tester) async {
      // Create a meal with specific prep time
      final meal = Meal(
        id: 'edit-prep-time-meal',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 3,
        notes: 'Test meal',
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
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the menu button - use last to get our test meal
      final menuButtons = find.byIcon(Icons.more_vert);
      await tester.tap(menuButtons.last);
      await tester.pumpAndSettle();

      // Tap Edit
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Find prep time field and enter new value
      await tester.enterText(
        find.widgetWithText(TextFormField, '15.0'),
        '22.5',
      );
      await tester.pumpAndSettle();

      // Tap Save Changes button
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Wait for async database operations to complete
      await tester.pumpAndSettle();

      // Verify the meal was updated in the database
      final updatedMeal = mockDbHelper.meals[meal.id];
      expect(updatedMeal, isNotNull);
      expect(updatedMeal!.actualPrepTime, equals(22.5),
          reason: 'Prep time should be updated to 22.5');
    });

    testWidgets('edits cook time and saves changes', (WidgetTester tester) async {
      // Create a meal with specific cook time
      final meal = Meal(
        id: 'edit-cook-time-meal',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 3,
        notes: 'Test meal',
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
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the menu button - use last to get our test meal
      final menuButtons = find.byIcon(Icons.more_vert);
      await tester.tap(menuButtons.last);
      await tester.pumpAndSettle();

      // Tap Edit
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Find cook time field and enter new value
      await tester.enterText(
        find.widgetWithText(TextFormField, '25.0'),
        '35.5',
      );
      await tester.pumpAndSettle();

      // Tap Save Changes button
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Wait for async database operations to complete
      await tester.pumpAndSettle();

      // Verify the meal was updated in the database
      final updatedMeal = mockDbHelper.meals[meal.id];
      expect(updatedMeal, isNotNull);
      expect(updatedMeal!.actualCookTime, equals(35.5),
          reason: 'Cook time should be updated to 35.5');
    });

    testWidgets('edits success flag and saves changes', (WidgetTester tester) async {
      // Create a meal with wasSuccessful = true
      final meal = Meal(
        id: 'edit-success-flag-meal',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 3,
        notes: 'Test meal',
        wasSuccessful: true, // Start as successful
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
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the menu button - use last to get our test meal
      final menuButtons = find.byIcon(Icons.more_vert);
      await tester.tap(menuButtons.last);
      await tester.pumpAndSettle();

      // Tap Edit
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Find and toggle the success switch
      final successSwitch = find.byKey(const Key('edit_meal_recording_success_switch'));
      expect(successSwitch, findsOneWidget);
      await tester.tap(successSwitch);
      await tester.pumpAndSettle();

      // Tap Save Changes button
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Wait for async database operations to complete
      await tester.pumpAndSettle();

      // Verify the meal was updated in the database
      final updatedMeal = mockDbHelper.meals[meal.id];
      expect(updatedMeal, isNotNull);
      expect(updatedMeal!.wasSuccessful, equals(false),
          reason: 'Success flag should be toggled to false');
    });

    testWidgets('cancel button dismisses dialog without saving', (WidgetTester tester) async {
      // Create a meal with known values
      final meal = Meal(
        id: 'cancel-test-meal',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 3,
        notes: 'Original notes',
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
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the menu button - use last to get our test meal
      final menuButtons = find.byIcon(Icons.more_vert);
      await tester.tap(menuButtons.last);
      await tester.pumpAndSettle();

      // Tap Edit
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Make changes to servings
      await tester.enterText(
        find.widgetWithText(TextFormField, '3'),
        '999',
      );
      await tester.pumpAndSettle();

      // Tap Cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Wait for any async operations
      await tester.pumpAndSettle();

      // Verify the meal was NOT updated in the database
      final unchangedMeal = mockDbHelper.meals[meal.id];
      expect(unchangedMeal, isNotNull);
      expect(unchangedMeal!.servings, equals(3),
          reason: 'Servings should remain unchanged after cancel');
      expect(unchangedMeal.notes, equals('Original notes'),
          reason: 'Notes should remain unchanged after cancel');
    });

    testWidgets('back button dismisses dialog without saving', (WidgetTester tester) async {
      // Create a meal with known values
      final meal = Meal(
        id: 'back-button-test-meal',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 3,
        notes: 'Original notes',
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
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the menu button - use last to get our test meal
      final menuButtons = find.byIcon(Icons.more_vert);
      await tester.tap(menuButtons.last);
      await tester.pumpAndSettle();

      // Tap Edit
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Make changes to servings
      await tester.enterText(
        find.widgetWithText(TextFormField, '3'),
        '888',
      );
      await tester.pumpAndSettle();

      // Press back button to dismiss dialog
      final NavigatorState navigator = tester.state(find.byType(Navigator));
      navigator.pop();
      await tester.pumpAndSettle();

      // Wait for any async operations
      await tester.pumpAndSettle();

      // Verify the meal was NOT updated in the database
      final unchangedMeal = mockDbHelper.meals[meal.id];
      expect(unchangedMeal, isNotNull);
      expect(unchangedMeal!.servings, equals(3),
          reason: 'Servings should remain unchanged after back button');
    });

    testWidgets('shows validation error for invalid servings', (WidgetTester tester) async {
      // Create a meal with valid values
      final meal = Meal(
        id: 'validation-test-meal',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 3,
        notes: 'Test notes',
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
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the menu button - use last to get our test meal
      final menuButtons = find.byIcon(Icons.more_vert);
      await tester.tap(menuButtons.last);
      await tester.pumpAndSettle();

      // Tap Edit
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Enter invalid servings (0)
      await tester.enterText(
        find.widgetWithText(TextFormField, '3'),
        '0',
      );
      await tester.pumpAndSettle();

      // Try to save - should trigger validation
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Verify validation error is shown
      expect(find.text('Please enter a valid number'), findsOneWidget,
          reason: 'Should show validation error for servings = 0');

      // Verify dialog is still open (not closed)
      expect(find.text('Save Changes'), findsOneWidget,
          reason: 'Dialog should remain open with validation error');

      // Verify the meal was NOT updated in the database
      final unchangedMeal = mockDbHelper.meals[meal.id];
      expect(unchangedMeal!.servings, equals(3),
          reason: 'Servings should remain unchanged due to validation error');
    });

    testWidgets('shows validation error for empty servings', (WidgetTester tester) async {
      // Create a meal with valid values
      final meal = Meal(
        id: 'empty-validation-meal',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 3,
        notes: 'Test notes',
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
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the menu button - use last to get our test meal
      final menuButtons = find.byIcon(Icons.more_vert);
      await tester.tap(menuButtons.last);
      await tester.pumpAndSettle();

      // Tap Edit
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Clear servings field (make it empty)
      await tester.enterText(
        find.widgetWithText(TextFormField, '3'),
        '',
      );
      await tester.pumpAndSettle();

      // Try to save - should trigger validation
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Verify validation error is shown
      expect(find.text('Please enter number of servings'), findsOneWidget,
          reason: 'Should show validation error for empty servings');

      // Verify dialog is still open
      expect(find.text('Save Changes'), findsOneWidget,
          reason: 'Dialog should remain open with validation error');

      // Verify the meal was NOT updated in the database
      final unchangedMeal = mockDbHelper.meals[meal.id];
      expect(unchangedMeal!.servings, equals(3),
          reason: 'Servings should remain unchanged due to validation error');
    });

    testWidgets('handles large servings value correctly', (WidgetTester tester) async {
      // Create a meal with normal servings
      final meal = Meal(
        id: 'large-servings-meal',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 3,
        notes: 'Test notes',
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
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the menu button - use last to get our test meal
      final menuButtons = find.byIcon(Icons.more_vert);
      await tester.tap(menuButtons.last);
      await tester.pumpAndSettle();

      // Tap Edit
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Enter large servings value
      await tester.enterText(
        find.widgetWithText(TextFormField, '3'),
        '999',
      );
      await tester.pumpAndSettle();

      // Save changes
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Wait for async operations
      await tester.pumpAndSettle();

      // Verify the large value was saved correctly
      final updatedMeal = mockDbHelper.meals[meal.id];
      expect(updatedMeal, isNotNull);
      expect(updatedMeal!.servings, equals(999),
          reason: 'Should handle large servings value (999)');
    });

    testWidgets('edits very old meal correctly', (WidgetTester tester) async {
      // Create a meal from 2 years ago
      final meal = Meal(
        id: 'old-meal',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 730)), // 2 years ago
        servings: 4,
        notes: 'Old meal notes',
        wasSuccessful: true,
        actualPrepTime: 20.0,
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

      // Tap the menu button - use last to get our test meal
      final menuButtons = find.byIcon(Icons.more_vert);
      await tester.tap(menuButtons.last);
      await tester.pumpAndSettle();

      // Tap Edit
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Update notes for the old meal
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Old meal notes'),
        'Updated notes for old meal',
      );
      await tester.pumpAndSettle();

      // Save changes
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Wait for async operations
      await tester.pumpAndSettle();

      // Verify the old meal was updated correctly
      final updatedMeal = mockDbHelper.meals[meal.id];
      expect(updatedMeal, isNotNull);
      expect(updatedMeal!.notes, equals('Updated notes for old meal'),
          reason: 'Should handle editing very old meals');
      expect(updatedMeal.cookedAt, equals(meal.cookedAt),
          reason: 'Original cooked date should be preserved');
    });

    testWidgets('handles very long notes text', (WidgetTester tester) async {
      // Create a meal with short notes
      final meal = Meal(
        id: 'long-notes-meal',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 3,
        notes: 'Short notes',
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
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the menu button - use last to get our test meal
      final menuButtons = find.byIcon(Icons.more_vert);
      await tester.tap(menuButtons.last);
      await tester.pumpAndSettle();

      // Tap Edit
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Create very long notes (500+ characters)
      final longNotes = 'This is a very long notes text. ' * 20; // ~640 characters

      // Update with long notes
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Short notes'),
        longNotes,
      );
      await tester.pumpAndSettle();

      // Save changes
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Wait for async operations
      await tester.pumpAndSettle();

      // Verify the long notes were saved correctly
      final updatedMeal = mockDbHelper.meals[meal.id];
      expect(updatedMeal, isNotNull);
      expect(updatedMeal!.notes, equals(longNotes),
          reason: 'Should handle very long notes text');
      expect(updatedMeal.notes.length, greaterThan(500),
          reason: 'Notes should be longer than 500 characters');
    });

    testWidgets('edits multi-recipe meal correctly', (WidgetTester tester) async {
      // Create a meal with multiple recipes (primary + side)
      final meal = Meal(
        id: 'multi-recipe-meal',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 4,
        notes: 'Multi-recipe meal',
        wasSuccessful: true,
        actualPrepTime: 20.0,
        actualCookTime: 35.0,
      );

      await mockDbHelper.insertMeal(meal);

      // Add primary recipe
      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: meal.id,
        recipeId: testRecipe.id,
        isPrimaryDish: true,
      ));

      // Add side recipe
      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: meal.id,
        recipeId: sideRecipe.id,
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

      // Verify side dish badge is shown
      expect(find.text('1 side dish'), findsOneWidget,
          reason: 'Should show side dish count badge');

      // Tap the menu button - use last to get our test meal
      final menuButtons = find.byIcon(Icons.more_vert);
      await tester.tap(menuButtons.last);
      await tester.pumpAndSettle();

      // Tap Edit
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Update servings for multi-recipe meal
      await tester.enterText(
        find.widgetWithText(TextFormField, '4'),
        '6',
      );
      await tester.pumpAndSettle();

      // Save changes
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Wait for async operations
      await tester.pumpAndSettle();

      // Verify the meal was updated correctly
      final updatedMeal = mockDbHelper.meals[meal.id];
      expect(updatedMeal, isNotNull);
      expect(updatedMeal!.servings, equals(6),
          reason: 'Multi-recipe meal servings should be updated');

      // Verify recipe associations are still intact
      final mealRecipes = await mockDbHelper.getMealRecipesForMeal(meal.id);
      expect(mealRecipes.length, equals(2),
          reason: 'Should still have 2 recipe associations after edit');
      expect(mealRecipes.where((mr) => mr.isPrimaryDish).length, equals(1),
          reason: 'Should still have 1 primary dish');
      expect(mealRecipes.where((mr) => !mr.isPrimaryDish).length, equals(1),
          reason: 'Should still have 1 side dish');
    });
  });
}
