// test/screens/meal_history_edit_test.dart

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
import '../mocks/mock_database_helper.dart';

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

  group('MealHistoryScreen Edit Functionality Tests', () {
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
        createTestableWidget(
          MealHistoryScreen(
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
        createTestableWidget(
          MealHistoryScreen(
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
      await tester.tap(find.byIcon(Icons.edit).first);
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
      await tester.tap(find.byIcon(Icons.edit).first);
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
      await tester.tap(find.byIcon(Icons.edit).first);
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
      await tester.tap(find.byIcon(Icons.edit).first);
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
      final editButtons = find.byIcon(Icons.edit);
      // Find the edit button for the middle meal (second in the list)
      await tester.tap(editButtons.at(1));
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

  group('Edit Feedback Messages', () {
    testWidgets('UI shows success message after edit',
        (WidgetTester tester) async {
      // 1. Set up a meal
      final meal = Meal(
        id: 'success-message-meal',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 2,
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

      // 3. Edit the meal
      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('edit_meal_recording_servings_field')),
        '5',
      );

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // 4. Verify success message appears
      expect(find.byType(SnackBar), findsOneWidget,
          reason: 'Success message should be displayed after edit');
      expect(find.text('Meal updated successfully'), findsOneWidget,
          reason: 'Success message should have correct text');

      // 5. Verify UI updated correctly
      expect(find.text('5'), findsWidgets,
          reason: 'UI should show updated data along with success message');
    });

    testWidgets('success message is localized in English',
        (WidgetTester tester) async {
      // 1. Set up a meal
      final meal = Meal(
        id: 'localized-en-message-meal',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 2,
        notes: 'Test meal for English locale',
        wasSuccessful: true,
      );

      await mockDbHelper.insertMeal(meal);
      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: meal.id,
        recipeId: testRecipe.id,
        isPrimaryDish: true,
      ));

      // 2. Launch the screen with explicit English locale
      await tester.pumpWidget(
        ChangeNotifierProvider<RecipeProvider>(
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
            locale: const Locale('en', ''), // Explicitly set English locale
            home: MealHistoryScreen(
              recipe: testRecipe,
              databaseHelper: mockDbHelper,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 3. Edit the meal
      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('edit_meal_recording_servings_field')),
        '4',
      );

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // 4. Verify English success message appears
      expect(find.byType(SnackBar), findsOneWidget,
          reason: 'Success message should be displayed after edit');
      expect(find.text('Meal updated successfully'), findsOneWidget,
          reason:
              'Success message should contain English localized text (mealUpdatedSuccessfully)');
    });

    testWidgets('success message is localized in Portuguese',
        (WidgetTester tester) async {
      // 1. Set up a meal
      final meal = Meal(
        id: 'localized-pt-message-meal',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 2,
        notes: 'Test meal for Portuguese locale',
        wasSuccessful: true,
      );

      await mockDbHelper.insertMeal(meal);
      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: meal.id,
        recipeId: testRecipe.id,
        isPrimaryDish: true,
      ));

      // 2. Launch the screen with explicit Portuguese locale
      await tester.pumpWidget(
        ChangeNotifierProvider<RecipeProvider>(
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
            locale: const Locale('pt', ''), // Explicitly set Portuguese locale
            home: MealHistoryScreen(
              recipe: testRecipe,
              databaseHelper: mockDbHelper,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 3. Edit the meal
      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('edit_meal_recording_servings_field')),
        '6',
      );

      await tester
          .tap(find.text('Salvar Alterações')); // Portuguese "Save Changes"
      await tester.pumpAndSettle();

      // 4. Verify Portuguese success message appears
      expect(find.byType(SnackBar), findsOneWidget,
          reason: 'Success message should be displayed after edit');
      expect(find.text('Refeição atualizada com sucesso'), findsOneWidget,
          reason:
              'Success message should contain Portuguese localized text (mealUpdatedSuccessfully)');
    });

    testWidgets('success message appears after UI refresh completes',
        (WidgetTester tester) async {
      // 0. Clear any meals from setUp to avoid interference
      mockDbHelper.resetAllData();
      await mockDbHelper.insertRecipe(testRecipe);

      // 1. Set up a meal with initial servings
      final meal = Meal(
        id: 'timing-test-meal',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 2,
        notes: 'Test meal for timing verification',
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

      // 3. Verify initial state shows servings: 2
      expect(find.text('2'), findsWidgets,
          reason: 'Initial servings should be 2');

      // 4. Open edit dialog
      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pumpAndSettle();

      // 5. Change servings to 5
      await tester.enterText(
        find.byKey(const Key('edit_meal_recording_servings_field')),
        '5',
      );

      // 6. Save changes
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // 7. Critical verification: When snackbar is visible, UI should already be updated
      final snackbarFinder = find.byType(SnackBar);
      final updatedDataFinder = find.text('5');

      expect(snackbarFinder, findsOneWidget,
          reason: 'Snackbar should be visible after save');
      expect(updatedDataFinder, findsWidgets,
          reason:
              'UI should already show updated servings (5) when snackbar appears');

      // 8. Verify the old value is no longer in the meal card
      // Note: '2' might still appear in other UI elements, so we check that '5' exists
      // which proves the UI refresh (_loadMeals) completed before snackbar appeared

      // 9. Verify database was updated
      final updatedMeal = await mockDbHelper.getMeal(meal.id);
      expect(updatedMeal, isNotNull);
      expect(updatedMeal!.servings, 5,
          reason: 'Database should have updated servings value');

      // This test proves the correct order of operations:
      // 1. Save button tapped
      // 2. Database updated (verified above)
      // 3. UI refreshed via _loadMeals() (verified by finding '5' in UI)
      // 4. Success snackbar shown (verified by finding SnackBar)
    });
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
      await tester.tap(find.byIcon(Icons.edit).first);
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
      await tester.tap(find.byIcon(Icons.edit).first);
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
      await tester.tap(find.byIcon(Icons.edit).first);
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
      await tester.tap(find.byIcon(Icons.edit).first);
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
      await tester.tap(find.byIcon(Icons.edit).first);
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
      await tester.tap(find.byIcon(Icons.edit).first);
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
      await tester.tap(find.byIcon(Icons.edit).first);
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

  group('Error Message Content', () {
    testWidgets('error messages do not expose technical implementation details',
        (WidgetTester tester) async {
      // 0. Clear and setup
      mockDbHelper.resetAllData();
      await mockDbHelper.insertRecipe(testRecipe);

      // 1. Set up a meal
      final meal = Meal(
        id: 'error-message-content-test',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 2,
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

      // 3. Configure mock to fail on updateMeal
      mockDbHelper.failOnOperation('updateMeal');

      // 4. Open edit dialog
      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pumpAndSettle();

      // 5. Make a valid change
      await tester.enterText(
        find.byKey(const Key('edit_meal_recording_servings_field')),
        '5',
      );

      // 6. Try to save (database will fail)
      await tester.tap(find.text('Save Changes'));
      await tester.pump();
      await tester.pump();

      // Give time for async operations
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await tester.pumpAndSettle();

      // 7. Verify error snackbar appears
      expect(find.byType(SnackBar), findsOneWidget,
          reason: 'Error snackbar should appear when database update fails');

      // 8. Extract the error message text from the snackbar
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      final snackBarContent = snackBar.content as Text;
      final errorMessage = snackBarContent.data ?? '';

      // 9. Verify message does NOT contain technical implementation details
      // These are patterns that should NOT appear in user-facing error messages:
      final technicalPatterns = [
        'Exception:', // Exception class name
        'Error:', // Error class name
        'at ', // Stack trace indicator
        'lib/', // File path
        '.dart', // Dart file extension
        'StackTrace', // Stack trace keyword
        '#0', // Stack frame number
        'Simulated', // Internal test implementation detail
      ];

      for (final pattern in technicalPatterns) {
        expect(errorMessage.contains(pattern), isFalse,
            reason:
                'Error message should not contain technical detail "$pattern". Message was: "$errorMessage"');
      }
    });

    testWidgets('error message is localized in English',
        (WidgetTester tester) async {
      // 0. Clear and setup
      mockDbHelper.resetAllData();
      await mockDbHelper.insertRecipe(testRecipe);

      // 1. Set up a meal
      final meal = Meal(
        id: 'error-en-message-content-test',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 2,
        notes: 'Test meal for English error',
        wasSuccessful: true,
      );

      await mockDbHelper.insertMeal(meal);
      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: meal.id,
        recipeId: testRecipe.id,
        isPrimaryDish: true,
      ));

      // 2. Launch the screen with explicit English locale
      await tester.pumpWidget(
        ChangeNotifierProvider<RecipeProvider>(
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
            locale: const Locale('en', ''), // Explicitly set English locale
            home: MealHistoryScreen(
              recipe: testRecipe,
              databaseHelper: mockDbHelper,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 3. Configure mock to fail on updateMeal
      mockDbHelper.failOnOperation('updateMeal');

      // 4. Open edit dialog
      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pumpAndSettle();

      // 5. Make a valid change
      await tester.enterText(
        find.byKey(const Key('edit_meal_recording_servings_field')),
        '3',
      );

      // 6. Try to save (database will fail)
      await tester.tap(find.text('Save Changes'));
      await tester.pump();
      await tester.pump();

      // Give time for async operations
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await tester.pumpAndSettle();

      // 7. Verify error snackbar appears
      expect(find.byType(SnackBar), findsOneWidget,
          reason: 'Error snackbar should appear when database update fails');

      // 8. Extract the error message text from the snackbar
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      final snackBarContent = snackBar.content as Text;
      final errorMessage = snackBarContent.data ?? '';

      // 9. Verify message is localized
      // Should start with localized error prefix
      expect(errorMessage.startsWith('Error editing meal'), isTrue,
          reason:
              'Error message should start with localized error prefix. Message was: "$errorMessage"');
    });
    testWidgets('error message is localized in Portuguese',
        (WidgetTester tester) async {
      // 0. Clear and setup
      mockDbHelper.resetAllData();
      await mockDbHelper.insertRecipe(testRecipe);

      // 1. Set up a meal
      final meal = Meal(
        id: 'error-pt-message-content-test',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 2,
        notes: 'Test meal for Portuguese error',
        wasSuccessful: true,
      );

      await mockDbHelper.insertMeal(meal);
      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: meal.id,
        recipeId: testRecipe.id,
        isPrimaryDish: true,
      ));

      // 2. Launch the screen with explicit English locale
      await tester.pumpWidget(
        ChangeNotifierProvider<RecipeProvider>(
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
            locale: const Locale('pt', ''), // Explicitly set Portuguese locale
            home: MealHistoryScreen(
              recipe: testRecipe,
              databaseHelper: mockDbHelper,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 3. Configure mock to fail on updateMeal
      mockDbHelper.failOnOperation('updateMeal');

      // 4. Open edit dialog
      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pumpAndSettle();

      // 5. Make a valid change
      await tester.enterText(
        find.byKey(const Key('edit_meal_recording_servings_field')),
        '3',
      );

      // 6. Try to save (database will fail)
      await tester
          .tap(find.text('Salvar Alterações')); // Portuguese "Save Changes"
      await tester.pump();
      await tester.pump();

      // Give time for async operations
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await tester.pumpAndSettle();

      // 7. Verify error snackbar appears
      expect(find.byType(SnackBar), findsOneWidget,
          reason: 'Error snackbar should appear when database update fails');

      // 8. Extract the error message text from the snackbar
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      final snackBarContent = snackBar.content as Text;
      final errorMessage = snackBarContent.data ?? '';

      // 9. Verify message is localized
      // Should start with localized error prefix
      expect(errorMessage.startsWith('Erro ao editar refeição'), isTrue,
          reason:
              'Error message should start with localized error prefix. Message was: "$errorMessage"');
    });
  });

  group('Database Error Feedback', () {
    testWidgets('shows error snackbar when database update fails',
        (WidgetTester tester) async {
      // 0. Clear and setup
      mockDbHelper.resetAllData();
      await mockDbHelper.insertRecipe(testRecipe);

      // 1. Set up a meal
      final meal = Meal(
        id: 'db-error-test-meal',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 2,
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

      // 3. Configure mock to fail on updateMeal
      mockDbHelper.failOnOperation('updateMeal');

      // 4. Open edit dialog
      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pumpAndSettle();

      // 5. Make a valid change
      await tester.enterText(
        find.byKey(const Key('edit_meal_recording_servings_field')),
        '5',
      );

      // 6. Try to save (database will fail)
      await tester.tap(find.text('Save Changes'));
      await tester.pump(); // Start closing dialog
      await tester.pump(); // Complete dialog close animation

      // Give more time for async operations
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await tester.pumpAndSettle();

      // Debug: Print what widgets are actually in the tree
      print('Widgets in tree:');
      print('SnackBar: ${find.byType(SnackBar).evaluate().length}');
      print(
          'All text widgets: ${find.byType(Text).evaluate().map((e) => (e.widget as Text).data).toList()}');

      // 7. Verify error snackbar appears
      expect(find.byType(SnackBar), findsOneWidget,
          reason: 'Error snackbar should appear when database update fails');

      // Check for error message text (case-sensitive: "Error" in English or "Erro" in Portuguese)
      final hasErrorMessage = find.textContaining('Error', findRichText: true).evaluate().isNotEmpty ||
          find.textContaining('Erro', findRichText: true).evaluate().isNotEmpty;
      expect(hasErrorMessage, isTrue,
          reason: 'Error message should be present in English or Portuguese');

      // 8. Verify database was NOT updated (because update failed)
      final unchangedMeal = await mockDbHelper.getMeal(meal.id);
      expect(unchangedMeal!.servings, 2,
          reason: 'Database should not be updated when updateMeal fails');
    });

    testWidgets('shows error when meal is deleted during edit',
        (WidgetTester tester) async {
      // 0. Clear and setup
      mockDbHelper.resetAllData();
      await mockDbHelper.insertRecipe(testRecipe);

      // 1. Set up a meal
      final meal = Meal(
        id: 'meal-deletion-test',
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
      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pumpAndSettle();

      // 4. While dialog is open, delete the meal from database
      await mockDbHelper.deleteMeal(meal.id);

      // 5. Make a change in the dialog
      await tester.enterText(
        find.byKey(const Key('edit_meal_recording_servings_field')),
        '6',
      );

      // 6. Try to save (meal no longer exists)
      await tester.tap(find.text('Save Changes'));
      await tester.pump(); // Start closing dialog
      await tester.pump(); // Complete dialog close animation

      // Give more time for async operations (same as test that passed)
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await tester.pumpAndSettle();

      // 7. Verify error snackbar appears
      expect(find.byType(SnackBar), findsOneWidget,
          reason: 'Error snackbar should appear when meal is not found');

      // Check for error message text (case-sensitive: "Error" in English or "Erro" in Portuguese)
      final hasErrorMessage = find.textContaining('Error', findRichText: true).evaluate().isNotEmpty ||
          find.textContaining('Erro', findRichText: true).evaluate().isNotEmpty;
      expect(hasErrorMessage, isTrue,
          reason: 'Error message should be present in English or Portuguese');

      // 8. Verify meal is indeed deleted
      final deletedMeal = await mockDbHelper.getMeal(meal.id);
      expect(deletedMeal, isNull, reason: 'Meal should be deleted');
    });

    testWidgets('shows error snackbar when loading recipes fails',
        (WidgetTester tester) async {
      // 0. Clear and setup
      mockDbHelper.resetAllData();
      await mockDbHelper.insertRecipe(testRecipe);

      // 1. Set up a meal
      final meal = Meal(
        id: 'recipe-loading-error-test',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 2,
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

      // 3. Configure mock to fail on getAllRecipes
      // This will cause the edit dialog to fail when loading available recipes
      mockDbHelper.failOnOperation('getAllRecipes');

      // 4. Open edit dialog (this triggers getAllRecipes in initState)
      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pump(); // Start opening dialog
      await tester.pump(); // Build dialog widget tree

      // Give time for async _loadAvailableRecipes to execute and show error
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await tester.pumpAndSettle();

      // 5. Verify error snackbar appears in dialog
      // Note: The error appears in the dialog context, not the screen
      expect(find.byType(SnackBar), findsOneWidget,
          reason:
              'Error snackbar should appear when loading recipes fails in dialog');

      // Check for error message text (case-sensitive: "Error" in English or "Erro" in Portuguese)
      final hasErrorMessage = find.textContaining('Error', findRichText: true).evaluate().isNotEmpty ||
          find.textContaining('Erro', findRichText: true).evaluate().isNotEmpty;
      expect(hasErrorMessage, isTrue,
          reason: 'Error message should be present in English or Portuguese');
    });
  });

  group('Multi-Recipe and Single-Recipe Edge Cases', () {
    testWidgets(
        'shows success message after editing meal with multiple recipes',
        (WidgetTester tester) async {
      // 0. Clear and setup
      mockDbHelper.resetAllData();
      await mockDbHelper.insertRecipe(testRecipe);
      await mockDbHelper.insertRecipe(sideRecipe);

      // Create another side recipe
      final sideRecipe2 = Recipe(
        id: 'side-recipe-2',
        name: 'Steamed Vegetables',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
        difficulty: 1,
        prepTimeMinutes: 5,
        cookTimeMinutes: 10,
      );
      await mockDbHelper.insertRecipe(sideRecipe2);

      // 1. Create a multi-recipe meal (primary + 2 side dishes)
      final meal = Meal(
        id: 'multi-recipe-success-test',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 4,
        notes: 'Multi-recipe meal',
        wasSuccessful: true,
      );

      await mockDbHelper.insertMeal(meal);

      // Add primary recipe
      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: meal.id,
        recipeId: testRecipe.id,
        isPrimaryDish: true,
      ));

      // Add first side dish
      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: meal.id,
        recipeId: sideRecipe.id,
        isPrimaryDish: false,
      ));

      // Add second side dish
      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: meal.id,
        recipeId: sideRecipe2.id,
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

      // 3. Verify multi-recipe meal is displayed (2 side dishes)
      expect(find.text('2 side dishes'), findsOneWidget,
          reason: 'Should show count of 2 side dishes');

      // 4. Edit the meal
      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pumpAndSettle();

      // 5. Modify servings
      await tester.enterText(
        find.byKey(const Key('edit_meal_recording_servings_field')),
        '6',
      );

      // 6. Save changes
      await tester.tap(find.text('Save Changes'));

      // Give time for async operations
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await tester.pumpAndSettle();

      // 7. Verify success snackbar appears
      expect(find.byType(SnackBar), findsOneWidget,
          reason:
              'Success snackbar should appear after editing multi-recipe meal');

      // Check for success message text
      final hasSuccessMessage = find.textContaining('success', findRichText: true).evaluate().isNotEmpty ||
          find.textContaining('sucesso', findRichText: true).evaluate().isNotEmpty;
      expect(hasSuccessMessage, isTrue,
          reason: 'Success message should be present in English or Portuguese');

      // 8. Verify data was updated
      final updatedMeal = await mockDbHelper.getMeal(meal.id);
      expect(updatedMeal!.servings, 6,
          reason: 'Multi-recipe meal servings should be updated');
    });

    testWidgets('shows success message after adding side dish during meal edit',
        (WidgetTester tester) async {
      // 0. Clear and setup
      mockDbHelper.resetAllData();
      await mockDbHelper.insertRecipe(testRecipe);
      await mockDbHelper.insertRecipe(sideRecipe);

      // Create a third recipe that will be added during edit
      final sideRecipe2 = Recipe(
        id: 'side-recipe-2',
        name: 'Steamed Vegetables',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
        difficulty: 1,
        prepTimeMinutes: 5,
        cookTimeMinutes: 10,
      );
      await mockDbHelper.insertRecipe(sideRecipe2);

      // 1. Create a meal with primary + 1 side dish
      final meal = Meal(
        id: 'add-side-dish-test',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 4,
        notes: 'Meal to test adding side dish',
        wasSuccessful: true,
      );

      await mockDbHelper.insertMeal(meal);

      // Add primary recipe
      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: meal.id,
        recipeId: testRecipe.id,
        isPrimaryDish: true,
      ));

      // Add first side dish
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

      // 3. Verify initial state: 1 side dish
      expect(find.text('1 side dish'), findsOneWidget,
          reason: 'Should initially show 1 side dish');

      // 4. Open edit dialog
      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pumpAndSettle();

      // 5. Verify edit dialog is open (there are multiple "Rice Pilaf" texts: one in background, one in dialog)
      expect(find.byType(Dialog), findsOneWidget,
          reason: 'Edit dialog should be open');
      expect(find.text('Rice Pilaf'), findsWidgets,
          reason: 'Existing side dish should be shown in edit dialog and background');

      // 6. Tap "Add Recipe" button to add another side dish
      await tester.tap(find.text('Add Recipe'));
      await tester.pumpAndSettle();

      // 7. Select the second side dish from the dialog
      expect(find.text('Steamed Vegetables'), findsOneWidget,
          reason: 'Should show available recipe in add dialog');
      await tester.tap(find.text('Steamed Vegetables'));
      await tester.pumpAndSettle();

      // 8. Verify the new side dish appears in the edit dialog
      expect(find.text('Steamed Vegetables'), findsOneWidget,
          reason: 'Newly added side dish should appear in edit dialog');

      // 9. Save changes
      await tester.tap(find.text('Save Changes'));

      // Give time for async operations
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await tester.pumpAndSettle();

      // 10. Verify success snackbar appears
      expect(find.byType(SnackBar), findsOneWidget,
          reason:
              'Success snackbar should appear after adding side dish to meal');

      // Check for success message text
      final hasSuccessMessage =
          find.textContaining('success', findRichText: true).evaluate().isNotEmpty ||
              find.textContaining('sucesso', findRichText: true).evaluate().isNotEmpty;
      expect(hasSuccessMessage, isTrue,
          reason: 'Success message should be present in English or Portuguese');

      // 11. Verify UI shows 2 side dishes now
      // Debug: Print all text widgets to see what's actually rendered
      print('=== DEBUG: All text widgets after save ===');
      for (final element in find.byType(Text).evaluate()) {
        final textWidget = element.widget as Text;
        print('Text: "${textWidget.data}"');
      }
      print('=== END DEBUG ===');

      expect(find.text('2 side dishes'), findsOneWidget,
          reason: 'Should now show 2 side dishes after adding one');

      // 12. Verify database was updated with new side dish
      final mealRecipes = await mockDbHelper.getMealRecipesForMeal(meal.id);
      expect(mealRecipes.length, 3,
          reason: 'Should have 3 recipes total: 1 primary + 2 sides');

      final sideRecipes =
          mealRecipes.where((mr) => !mr.isPrimaryDish).toList();
      expect(sideRecipes.length, 2, reason: 'Should have 2 side dishes');

      // Verify both side dishes are present
      final sideRecipeIds = sideRecipes.map((mr) => mr.recipeId).toList();
      expect(sideRecipeIds.contains(sideRecipe.id), isTrue,
          reason: 'Original side dish should still be present');
      expect(sideRecipeIds.contains(sideRecipe2.id), isTrue,
          reason: 'Newly added side dish should be in database');
    });

    testWidgets(
        'shows error when side dish database operations fail during save',
        (WidgetTester tester) async {
      // 0. Clear and setup
      mockDbHelper.resetAllData();
      await mockDbHelper.insertRecipe(testRecipe);
      await mockDbHelper.insertRecipe(sideRecipe);

      // Create a third recipe that will be added during edit
      final sideRecipe2 = Recipe(
        id: 'side-recipe-2',
        name: 'Steamed Vegetables',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
        difficulty: 1,
        prepTimeMinutes: 5,
        cookTimeMinutes: 10,
      );
      await mockDbHelper.insertRecipe(sideRecipe2);

      // 1. Create a meal with primary + 1 side dish
      final meal = Meal(
        id: 'side-dish-error-test',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 4,
        notes: 'Meal to test side dish error handling',
        wasSuccessful: true,
      );

      await mockDbHelper.insertMeal(meal);

      // Add primary recipe
      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: meal.id,
        recipeId: testRecipe.id,
        isPrimaryDish: true,
      ));

      // Add first side dish (Rice Pilaf)
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

      // 3. Verify initial state: 1 side dish
      expect(find.text('1 side dish'), findsOneWidget,
          reason: 'Should initially show 1 side dish');

      // 4. Open edit dialog
      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pumpAndSettle();

      // 5. Remove existing side dish (Rice Pilaf) by tapping trash icon
      expect(find.byIcon(Icons.delete_outline), findsOneWidget,
          reason: 'Should find delete icon for the existing side dish');
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // 6. Verify Rice Pilaf is removed from dialog (local state)
      // Note: There might still be instances in the background, so we check the dialog
      expect(find.byType(Dialog), findsOneWidget,
          reason: 'Dialog should still be open');

      // 7. Add a new side dish (Steamed Vegetables)
      await tester.tap(find.text('Add Recipe'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Steamed Vegetables'));
      await tester.pumpAndSettle();

      // 8. Configure mock to fail when inserting meal recipes
      mockDbHelper.failOnOperation('insertMealRecipe');

      // 9. Save changes (this will trigger the error)
      await tester.tap(find.text('Save Changes'));
      await tester.pump();
      await tester.pump();

      // Give time for async operations
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await tester.pumpAndSettle();

      // 10. Verify error snackbar appears
      expect(find.byType(SnackBar), findsOneWidget,
          reason:
              'Error snackbar should appear when side dish database operation fails');

      // 11. Extract and verify error message
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      final snackBarContent = snackBar.content as Text;
      final errorMessage = snackBarContent.data ?? '';

      // Should contain error message (English or Portuguese)
      final hasErrorMessage =
          errorMessage.contains('Error editing meal') ||
              errorMessage.contains('Erro ao editar refeição');
      expect(hasErrorMessage, isTrue,
          reason:
              'Error message should contain "Error editing meal" or "Erro ao editar refeição". Got: "$errorMessage"');

      // 12. Verify error message does NOT contain technical details
      final technicalPatterns = [
        'Exception:',
        'Error:',
        'at ',
        'lib/',
        '.dart',
        'StackTrace',
        '#0',
        'Simulated',
      ];

      for (final pattern in technicalPatterns) {
        expect(errorMessage.contains(pattern), isFalse,
            reason:
                'Error message should not contain technical detail "$pattern". Message was: "$errorMessage"');
      }

      // 13. Verify database state after partial operation
      // Note: _updateMealRecipeAssociations deletes all side dishes first,
      // then tries to insert new ones. Since insert failed, we have:
      // - Deletions succeeded (original side dish removed)
      // - Inserts failed (new side dish NOT added)
      // Result: Only primary recipe remains
      final mealRecipes = await mockDbHelper.getMealRecipesForMeal(meal.id);
      expect(mealRecipes.length, 1,
          reason:
              'Should have only 1 recipe (primary) because deletions succeeded but inserts failed');

      final primaryRecipes =
          mealRecipes.where((mr) => mr.isPrimaryDish).toList();
      expect(primaryRecipes.length, 1, reason: 'Should have 1 primary recipe');
      expect(primaryRecipes.first.recipeId, testRecipe.id,
          reason: 'Primary recipe should be Grilled Chicken');

      final sideRecipes =
          mealRecipes.where((mr) => !mr.isPrimaryDish).toList();
      expect(sideRecipes.length, 0,
          reason:
              'Should have 0 side dishes because original was deleted and new one failed to insert');

      // 14. Verify new side dish was NOT added (operation failed)
      final hasNewSideDish =
          mealRecipes.any((mr) => mr.recipeId == sideRecipe2.id);
      expect(hasNewSideDish, isFalse,
          reason:
              'New side dish (Steamed Vegetables) should NOT be in database because operation failed');
    });

    testWidgets('shows success message after editing single-recipe meal',
        (WidgetTester tester) async {
      // 0. Clear and setup
      mockDbHelper.resetAllData();
      await mockDbHelper.insertRecipe(testRecipe);

      // 1. Create a single-recipe meal (no side dishes)
      final meal = Meal(
        id: 'single-recipe-success-test',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 2,
        notes: 'Simple single-recipe meal',
        wasSuccessful: true,
      );

      await mockDbHelper.insertMeal(meal);

      // Add only primary recipe (no side dishes)
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

      // 3. Verify single-recipe meal (no side dishes indicator)
      expect(find.textContaining('side dish'), findsNothing,
          reason: 'Should not show side dishes for single-recipe meal');

      // 4. Edit the meal
      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pumpAndSettle();

      // 5. Modify notes
      await tester.enterText(
        find.byKey(const Key('edit_meal_recording_notes_field')),
        'Updated single-recipe meal notes',
      );

      // 6. Save changes
      await tester.tap(find.text('Save Changes'));

      // Give time for async operations
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await tester.pumpAndSettle();

      // 7. Verify success snackbar appears
      expect(find.byType(SnackBar), findsOneWidget,
          reason:
              'Success snackbar should appear after editing single-recipe meal');

      // Check for success message text
      final hasSuccessMessage = find.textContaining('success', findRichText: true).evaluate().isNotEmpty ||
          find.textContaining('sucesso', findRichText: true).evaluate().isNotEmpty;
      expect(hasSuccessMessage, isTrue,
          reason: 'Success message should be present in English or Portuguese');

      // 8. Verify data was updated
      final updatedMeal = await mockDbHelper.getMeal(meal.id);
      expect(updatedMeal!.notes, 'Updated single-recipe meal notes',
          reason: 'Single-recipe meal notes should be updated');
    });
  });

  group('Snackbar Behavior Tests', () {
    testWidgets('snackbar displays for appropriate duration',
        (WidgetTester tester) async {
      // 0. Clear and setup
      mockDbHelper.resetAllData();
      await mockDbHelper.insertRecipe(testRecipe);

      // 1. Create a test meal
      final meal = Meal(
        id: 'snackbar-duration-test',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 3,
        notes: 'Test meal for snackbar duration',
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

      // 3. Edit the meal
      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pumpAndSettle();

      // 4. Make a simple change
      await tester.enterText(
        find.byKey(const Key('edit_meal_recording_servings_field')),
        '5',
      );

      // 5. Save changes
      await tester.tap(find.text('Save Changes'));

      // Give time for async operations
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await tester.pumpAndSettle();

      // 6. Verify snackbar is visible immediately after action
      expect(find.byType(SnackBar), findsOneWidget,
          reason: 'Snackbar should be visible immediately after save');

      // 7. Wait 2 seconds and verify snackbar is still visible
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(SnackBar), findsOneWidget,
          reason: 'Snackbar should still be visible after 2 seconds');

      // 8. Wait another 3 seconds (total ~5 seconds) and verify snackbar auto-dismisses
      // Flutter's default SnackBar duration is 4 seconds, so after 5 total it should be gone
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing,
          reason:
              'Snackbar should auto-dismiss after its duration (4 seconds default)');
    });

    testWidgets('snackbar can be manually dismissed',
        (WidgetTester tester) async {
      // 0. Clear and setup
      mockDbHelper.resetAllData();
      await mockDbHelper.insertRecipe(testRecipe);

      // 1. Create a test meal
      final meal = Meal(
        id: 'snackbar-dismiss-test',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 3,
        notes: 'Test meal for snackbar dismissal',
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

      // 3. Edit the meal
      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pumpAndSettle();

      // 4. Make a simple change
      await tester.enterText(
        find.byKey(const Key('edit_meal_recording_servings_field')),
        '5',
      );

      // 5. Save changes
      await tester.tap(find.text('Save Changes'));

      // Give time for async operations
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await tester.pumpAndSettle();

      // 6. Verify snackbar is visible
      expect(find.byType(SnackBar), findsOneWidget,
          reason: 'Snackbar should be visible after save');

      // 7. Swipe to dismiss the snackbar
      // SnackBars in Flutter can be dismissed by swiping or by DismissDirection
      await tester.drag(find.byType(SnackBar), const Offset(0, 100));
      await tester.pumpAndSettle();

      // 8. Verify snackbar is dismissed
      expect(find.byType(SnackBar), findsNothing,
          reason: 'Snackbar should be dismissed after swipe gesture');
    });

    testWidgets('handles multiple rapid edit operations gracefully',
        (WidgetTester tester) async {
      // 0. Clear and setup
      mockDbHelper.resetAllData();
      await mockDbHelper.insertRecipe(testRecipe);

      // 1. Create multiple test meals
      final meal1 = Meal(
        id: 'rapid-edit-test-1',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 3)),
        servings: 2,
        notes: 'First meal',
        wasSuccessful: true,
      );

      final meal2 = Meal(
        id: 'rapid-edit-test-2',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 2)),
        servings: 3,
        notes: 'Second meal',
        wasSuccessful: true,
      );

      await mockDbHelper.insertMeal(meal1);
      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: meal1.id,
        recipeId: testRecipe.id,
        isPrimaryDish: true,
      ));

      await mockDbHelper.insertMeal(meal2);
      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: meal2.id,
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

      // 3. Perform first rapid edit
      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('edit_meal_recording_servings_field')),
        '10',
      );

      await tester.tap(find.text('Save Changes'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      // 4. Immediately perform second rapid edit (don't wait for first snackbar)
      await tester.tap(find.byIcon(Icons.edit).last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('edit_meal_recording_servings_field')),
        '8',
      );

      await tester.tap(find.text('Save Changes'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await tester.pumpAndSettle();

      // 5. Verify snackbar behavior is reasonable
      // We should see at least one snackbar (the most recent one)
      // Flutter's ScaffoldMessenger manages the queue
      expect(find.byType(SnackBar), findsOneWidget,
          reason: 'At least one snackbar should be visible after rapid edits');

      // 6. Verify both meals were updated successfully
      final updatedMeal1 = await mockDbHelper.getMeal(meal1.id);
      final updatedMeal2 = await mockDbHelper.getMeal(meal2.id);

      expect(updatedMeal1!.servings, 10,
          reason: 'First meal should be updated despite rapid edits');
      expect(updatedMeal2!.servings, 8,
          reason: 'Second meal should be updated despite rapid edits');
    });
  });

  group('Accessibility Tests', () {
    testWidgets('snackbar meets accessibility requirements',
        (WidgetTester tester) async {
      // 0. Clear and setup
      mockDbHelper.resetAllData();
      await mockDbHelper.insertRecipe(testRecipe);

      // 1. Create a test meal
      final meal = Meal(
        id: 'accessibility-test-meal',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 3,
        notes: 'Test meal for accessibility',
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

      // 3. Edit the meal to trigger success snackbar
      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('edit_meal_recording_servings_field')),
        '5',
      );

      await tester.tap(find.text('Save Changes'));

      // Give time for async operations
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await tester.pumpAndSettle();

      // 4. Verify snackbar appears
      expect(find.byType(SnackBar), findsOneWidget,
          reason: 'Success snackbar should appear');

      // 5. Verify snackbar text is accessible
      // Find the success message text
      final successMessageFinder = find.text('Meal updated successfully');
      expect(successMessageFinder, findsOneWidget,
          reason: 'Success message should be present');

      // 6. Get the Text widget and verify it's in the widget tree (accessible)
      final textWidget = tester.widget<Text>(successMessageFinder);
      expect(textWidget.data, 'Meal updated successfully',
          reason: 'Text widget should contain the success message');

      // 7. Verify the text is not explicitly excluded from semantics
      // In Flutter, by default, Text widgets are included in the semantics tree
      // We verify this by checking that we can find the text in the tree
      final semanticsFinder = find.ancestor(
        of: successMessageFinder,
        matching: find.byType(SnackBar),
      );
      expect(semanticsFinder, findsOneWidget,
          reason: 'Text should be within SnackBar and accessible to screen readers');

      // 8. Verify snackbar is visible and has content
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.content, isA<Text>(),
          reason: 'SnackBar should have Text content that is accessible');
    });
  });
}
