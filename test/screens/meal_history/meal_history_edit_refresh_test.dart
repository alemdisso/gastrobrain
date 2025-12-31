// test/screens/meal_history/meal_history_edit_refresh_test.dart

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
  group('UI Refresh After Edit', () {
    testWidgets('meal list updates immediately after successful edit',
        (WidgetTester tester) async {
      // Clear any meals from setUp to avoid interference
      mockDbHelper.resetAllData();
      await mockDbHelper.insertRecipe(testRecipe);

      // 1. Set up a meal with specific data in database
      final meal = Meal(
        id: 'refresh-test-meal',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 2,
        notes: 'Original notes',
        wasSuccessful: true,
        actualPrepTime: 10.0,
        actualCookTime: 20.0,
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

      // 3. Verify initial state in UI
      expect(find.text('Original notes'), findsOneWidget,
          reason: 'Original notes should be displayed');
      expect(find.text('2'), findsWidgets,
          reason: 'Original servings count should be displayed');

      // 4. Open edit dialog
      // Tap menu button then Edit
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // 5. Change servings
      await tester.enterText(
        find.byKey(const Key('edit_meal_recording_servings_field')),
        '4',
      );
      await tester.pump(); // Allow text to be processed

      // 6. Save changes
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // 7. Verify UI updated immediately with new servings
      expect(find.text('4'), findsWidgets,
          reason: 'UI should immediately show updated servings after save');

      // 8. Verify database state matches UI
      final updatedMeal = await mockDbHelper.getMeal(meal.id);
      expect(updatedMeal, isNotNull,
          reason: 'Meal should still exist in database');
      expect(updatedMeal!.servings, 4,
          reason: 'Database should have updated servings value');
    });

    testWidgets('edited meal data appears correctly in UI',
        (WidgetTester tester) async {
      // Clear any meals from setUp to avoid interference
      mockDbHelper.resetAllData();
      await mockDbHelper.insertRecipe(testRecipe);

      // 1. Set up a meal with initial data
      final meal = Meal(
        id: 'multi-field-edit-meal',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 2,
        notes: 'Original notes',
        wasSuccessful: true,
        actualPrepTime: 10.0,
        actualCookTime: 20.0,
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

      // 4. Edit multiple fields
      await tester.enterText(
        find.byKey(const Key('edit_meal_recording_servings_field')),
        '5',
      );

      await tester.enterText(
        find.byKey(const Key('edit_meal_recording_notes_field')),
        'Updated notes with new information',
      );

      await tester.enterText(
        find.byKey(const Key('edit_meal_recording_prep_time_field')),
        '15',
      );

      await tester.enterText(
        find.byKey(const Key('edit_meal_recording_cook_time_field')),
        '30',
      );

      // 5. Save changes
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // 6. Verify all edited fields appear correctly in UI
      expect(find.text('5'), findsWidgets,
          reason: 'Updated servings should be displayed');
      expect(find.text('Updated notes with new information'), findsOneWidget,
          reason: 'Updated notes should be displayed');

      // 7. Verify database contains all updates
      final updatedMeal = await mockDbHelper.getMeal(meal.id);
      expect(updatedMeal!.servings, 5,
          reason: 'Database should have updated servings');
      expect(updatedMeal.notes, 'Updated notes with new information',
          reason: 'Database should have updated notes');
      expect(updatedMeal.actualPrepTime, 15.0,
          reason: 'Database should have updated prep time');
      expect(updatedMeal.actualCookTime, 30.0,
          reason: 'Database should have updated cook time');
    });

    testWidgets('UI refresh works for single-recipe meals',
        (WidgetTester tester) async {
      // 1. Set up a single-recipe meal
      final meal = Meal(
        id: 'single-recipe-refresh',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 3,
        notes: 'Single recipe meal',
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

      // 3. Verify initial state (single recipe, no side dishes)
      expect(find.text('3'), findsWidgets,
          reason: 'Original servings count should be displayed');
      expect(find.text('1 side dish'), findsNothing,
          reason: 'Should not show side dish indicator for single recipe');

      // 4. Edit the meal
      // Tap menu button then Edit
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('edit_meal_recording_servings_field')),
        '6',
      );

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // 5. Verify UI refreshed correctly
      expect(find.text('6'), findsWidgets,
          reason: 'Single-recipe meal should show updated servings');
      expect(find.text('1 side dish'), findsNothing,
          reason: 'Should still not show side dish indicator');
    });

    testWidgets('UI refresh works for multi-recipe meals',
        (WidgetTester tester) async {
      // 1. Set up a multi-recipe meal
      final meal = Meal(
        id: 'multi-recipe-refresh',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 4,
        notes: 'Multi recipe meal',
        wasSuccessful: true,
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

      // 3. Verify initial multi-recipe state
      expect(find.text('4'), findsWidgets,
          reason: 'Original servings count should be displayed');
      expect(find.text('1 side dish'), findsOneWidget,
          reason: 'Should show side dish indicator');

      // 4. Edit the meal
      // Tap menu button then Edit
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('edit_meal_recording_servings_field')),
        '8',
      );

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // 5. Verify UI refreshed correctly with side dishes still shown
      expect(find.text('8'), findsWidgets,
          reason: 'Multi-recipe meal should show updated servings');
      expect(find.text('1 side dish'), findsOneWidget,
          reason: 'Side dish indicator should still be present after edit');
    });

    testWidgets('edited meal maintains correct position in history list',
        (WidgetTester tester) async {
      // 1. Set up multiple meals at different dates
      final oldMeal = Meal(
        id: 'old-meal',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 5)),
        servings: 1,
        notes: 'Old meal',
        wasSuccessful: true,
      );

      final middleMeal = Meal(
        id: 'middle-meal',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 3)),
        servings: 2,
        notes: 'Middle meal',
        wasSuccessful: true,
      );

      final recentMeal = Meal(
        id: 'recent-meal',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 3,
        notes: 'Recent meal',
        wasSuccessful: true,
      );

      // Insert meals in random order
      await mockDbHelper.insertMeal(middleMeal);
      await mockDbHelper.insertMeal(recentMeal);
      await mockDbHelper.insertMeal(oldMeal);

      // Add recipe associations
      for (var meal in [oldMeal, middleMeal, recentMeal]) {
        await mockDbHelper.insertMealRecipe(MealRecipe(
          mealId: meal.id,
          recipeId: testRecipe.id,
          isPrimaryDish: true,
        ));
      }

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

      // 3. Capture time before edit for timestamp verification
      final timeBeforeEdit = DateTime.now();

      // 4. Verify initial order (most recent first)
      expect(find.text('Recent meal'), findsOneWidget);
      expect(find.text('Middle meal'), findsOneWidget);
      expect(find.text('Old meal'), findsOneWidget);

      // 5. Edit the middle meal
      final menuButtons = find.byIcon(Icons.more_vert);
      // Find the menu button for the middle meal (second in the list)
      await tester.tap(menuButtons.at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // 6. Change only the notes (not the date)
      await tester.enterText(
        find.byKey(const Key('edit_meal_recording_notes_field')),
        'Updated middle meal notes',
      );

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // 7. Verify meal order is maintained
      expect(find.text('Recent meal'), findsOneWidget,
          reason: 'Most recent meal should still be first');
      expect(find.text('Updated middle meal notes'), findsOneWidget,
          reason: 'Edited middle meal should show updated notes');
      expect(find.text('Old meal'), findsOneWidget,
          reason: 'Oldest meal should still be last');

      // 8. Verify database state
      final updatedMiddleMeal = await mockDbHelper.getMeal(middleMeal.id);
      expect(updatedMiddleMeal!.notes, 'Updated middle meal notes',
          reason: 'Database should have updated notes');
      expect(
          updatedMiddleMeal.cookedAt.difference(middleMeal.cookedAt).inSeconds,
          0,
          reason: 'Meal date should remain unchanged');
      expect(updatedMiddleMeal.modifiedAt, isNotNull,
          reason: 'modifiedAt should be set after edit');
      expect(
          updatedMiddleMeal.modifiedAt!.isAfter(timeBeforeEdit) ||
              updatedMiddleMeal.modifiedAt!.isAtSameMomentAs(timeBeforeEdit),
          true,
          reason:
              'modifiedAt should be updated to current time when meal is edited');
    });
  });
}
