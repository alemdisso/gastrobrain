// test/screens/meal_history/meal_history_edit_validation_test.dart

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
  group('Validation Error Feedback', () {
    testWidgets('shows inline error when servings is zero',
        (WidgetTester tester) async {
      // 0. Clear and setup
      mockDbHelper.resetAllData();
      await mockDbHelper.insertRecipe(testRecipe);

      // 1. Set up a meal with valid initial servings
      final meal = Meal(
        id: 'validation-test-meal',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 2,
        notes: 'Test meal for validation',
        wasSuccessful: true,
      );

      await mockDbHelper.insertMeal(meal);
      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: meal.id,
        recipeId: testRecipe.id,
        isPrimaryDish: true,
      ));

      // 2. Launch the screen
      await tester.pumpWidget(
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 3. Open edit dialog
      // Tap menu button then Edit
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // 4. Enter invalid servings (0)
      await tester.enterText(
        find.byKey(const Key('edit_meal_recording_servings_field')),
        '0',
      );

      // 5. Try to save - this triggers form validation
      await tester.tap(find.text('Save Changes'));
      await tester.pump(); // Trigger validation but don't settle yet

      // 6. Verify inline validation error appears
      expect(find.text('Please enter a valid number'), findsOneWidget,
          reason:
              'Inline validation error should appear for servings = 0 (pleaseEnterValidNumber)');

      // 7. Verify dialog is still open (didn't close on error)
      expect(find.byType(Dialog), findsOneWidget,
          reason: 'Dialog should remain open after validation error');

      // 8. Verify database was NOT updated
      final unchangedMeal = await mockDbHelper.getMeal(meal.id);
      expect(unchangedMeal!.servings, 2,
          reason: 'Database should not be updated when validation fails');
    });

    testWidgets('shows inline error when servings is negative',
        (WidgetTester tester) async {
      // 0. Clear and setup
      mockDbHelper.resetAllData();
      await mockDbHelper.insertRecipe(testRecipe);

      // 1. Set up a meal
      final meal = Meal(
        id: 'negative-servings-test',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 3,
        notes: 'Test meal',
        wasSuccessful: true,
      );

      await mockDbHelper.insertMeal(meal);
      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: meal.id,
        recipeId: testRecipe.id,
        isPrimaryDish: true,
      ));

      // 2. Launch the screen
      await tester.pumpWidget(
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 3. Open edit dialog
      // Tap menu button then Edit
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // 4. Enter negative servings
      await tester.enterText(
        find.byKey(const Key('edit_meal_recording_servings_field')),
        '-1',
      );

      // 5. Try to save - this triggers form validation
      await tester.tap(find.text('Save Changes'));
      await tester.pump();

      // 6. Verify inline validation error appears
      expect(find.text('Please enter a valid number'), findsOneWidget,
          reason:
              'Inline validation error should appear for negative servings (pleaseEnterValidNumber)');

      // 7. Verify dialog is still open
      expect(find.byType(Dialog), findsOneWidget,
          reason: 'Dialog should remain open after validation error');

      // 8. Verify database was NOT updated
      final unchangedMeal = await mockDbHelper.getMeal(meal.id);
      expect(unchangedMeal!.servings, 3,
          reason: 'Database should not be updated for negative servings');
    });

    testWidgets('shows inline error when servings is empty',
        (WidgetTester tester) async {
      // 0. Clear and setup
      mockDbHelper.resetAllData();
      await mockDbHelper.insertRecipe(testRecipe);

      // 1. Set up a meal
      final meal = Meal(
        id: 'empty-servings-test',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 4,
        notes: 'Test meal',
        wasSuccessful: true,
      );

      await mockDbHelper.insertMeal(meal);
      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: meal.id,
        recipeId: testRecipe.id,
        isPrimaryDish: true,
      ));

      // 2. Launch the screen
      await tester.pumpWidget(
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 3. Open edit dialog
      // Tap menu button then Edit
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // 4. Clear the servings field (make it empty)
      await tester.enterText(
        find.byKey(const Key('edit_meal_recording_servings_field')),
        '',
      );

      // 5. Try to save - this triggers form validation
      await tester.tap(find.text('Save Changes'));
      await tester.pump();

      // 6. Verify inline validation error appears
      expect(find.text('Please enter number of servings'), findsOneWidget,
          reason:
              'Inline validation error should appear for empty servings (pleaseEnterNumberOfServings)');

      // 7. Verify dialog is still open
      expect(find.byType(Dialog), findsOneWidget,
          reason: 'Dialog should remain open after validation error');

      // 8. Verify database was NOT updated
      final unchangedMeal = await mockDbHelper.getMeal(meal.id);
      expect(unchangedMeal!.servings, 4,
          reason: 'Database should not be updated for empty servings');
    });

    testWidgets('shows inline error when prep time is negative',
        (WidgetTester tester) async {
      // 0. Clear and setup
      mockDbHelper.resetAllData();
      await mockDbHelper.insertRecipe(testRecipe);

      // 1. Set up a meal
      final meal = Meal(
        id: 'negative-prep-time-test',
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

      // 2. Launch the screen
      await tester.pumpWidget(
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 3. Open edit dialog
      // Tap menu button then Edit
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // 4. Enter negative prep time
      await tester.enterText(
        find.byKey(const Key('edit_meal_recording_prep_time_field')),
        '-5',
      );

      // 5. Try to save - this triggers form validation
      await tester.tap(find.text('Save Changes'));
      await tester.pump();

      // 6. Verify inline validation error appears
      expect(find.text('Enter a valid time'), findsOneWidget,
          reason:
              'Inline validation error should appear for negative prep time (enterValidTime)');

      // 7. Verify dialog is still open
      expect(find.byType(Dialog), findsOneWidget,
          reason: 'Dialog should remain open after validation error');

      // 8. Verify database was NOT updated
      final unchangedMeal = await mockDbHelper.getMeal(meal.id);
      expect(unchangedMeal!.actualPrepTime, 15.0,
          reason: 'Database should not be updated for negative prep time');
    });

    testWidgets('shows inline error when prep time is invalid format',
        (WidgetTester tester) async {
      // 0. Clear and setup
      mockDbHelper.resetAllData();
      await mockDbHelper.insertRecipe(testRecipe);

      // 1. Set up a meal
      final meal = Meal(
        id: 'invalid-prep-time-test',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 3,
        notes: 'Test meal',
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

      // 2. Launch the screen
      await tester.pumpWidget(
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 3. Open edit dialog
      // Tap menu button then Edit
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // 4. Enter non-numeric prep time
      await tester.enterText(
        find.byKey(const Key('edit_meal_recording_prep_time_field')),
        'abc',
      );

      // 5. Try to save - this triggers form validation
      await tester.tap(find.text('Save Changes'));
      await tester.pump();

      // 6. Verify inline validation error appears
      expect(find.text('Enter a valid time'), findsOneWidget,
          reason:
              'Inline validation error should appear for non-numeric prep time (enterValidTime)');

      // 7. Verify dialog is still open
      expect(find.byType(Dialog), findsOneWidget,
          reason: 'Dialog should remain open after validation error');

      // 8. Verify database was NOT updated
      final unchangedMeal = await mockDbHelper.getMeal(meal.id);
      expect(unchangedMeal!.actualPrepTime, 20.0,
          reason:
              'Database should not be updated for invalid prep time format');
    });
    testWidgets('shows inline error when cook time is negative',
        (WidgetTester tester) async {
      // 0. Clear and setup
      mockDbHelper.resetAllData();
      await mockDbHelper.insertRecipe(testRecipe);

      // 1. Set up a meal
      final meal = Meal(
        id: 'negative-cook-time-test',
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

      // 2. Launch the screen
      await tester.pumpWidget(
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 3. Open edit dialog
      // Tap menu button then Edit
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // 4. Enter negative cook time
      await tester.enterText(
        find.byKey(const Key('edit_meal_recording_cook_time_field')),
        '-1',
      );

      // 5. Try to save - this triggers form validation
      await tester.tap(find.text('Save Changes'));
      await tester.pump();

      // 6. Verify inline validation error appears
      expect(find.text('Enter a valid time'), findsOneWidget,
          reason:
              'Inline validation error should appear for negative cook time (enterValidTime)');

      // 7. Verify dialog is still open
      expect(find.byType(Dialog), findsOneWidget,
          reason: 'Dialog should remain open after validation error');

      // 8. Verify database was NOT updated
      final unchangedMeal = await mockDbHelper.getMeal(meal.id);
      expect(unchangedMeal!.actualCookTime, 25.0,
          reason: 'Database should not be updated for negative cook time');
    });

    testWidgets('shows inline error when cook time is invalid format',
        (WidgetTester tester) async {
      // 0. Clear and setup
      mockDbHelper.resetAllData();
      await mockDbHelper.insertRecipe(testRecipe);

      // 1. Set up a meal
      final meal = Meal(
        id: 'invalid-cook-time-test',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 3,
        notes: 'Test meal',
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

      // 2. Launch the screen
      await tester.pumpWidget(
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 3. Open edit dialog
      // Tap menu button then Edit
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // 4. Enter non-numeric cook time
      await tester.enterText(
        find.byKey(const Key('edit_meal_recording_cook_time_field')),
        'xyz',
      );

      // 5. Try to save - this triggers form validation
      await tester.tap(find.text('Save Changes'));
      await tester.pump();

      // 6. Verify inline validation error appears
      expect(find.text('Enter a valid time'), findsOneWidget,
          reason:
              'Inline validation error should appear for non-numeric cook time (enterValidTime)');

      // 7. Verify dialog is still open
      expect(find.byType(Dialog), findsOneWidget,
          reason: 'Dialog should remain open after validation error');

      // 8. Verify database was NOT updated
      final unchangedMeal = await mockDbHelper.getMeal(meal.id);
      expect(unchangedMeal!.actualCookTime, 30.0,
          reason:
              'Database should not be updated for invalid cook time format');
    });
  });
}
