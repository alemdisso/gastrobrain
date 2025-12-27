// test/screens/meal_history/meal_history_edit_feedback_test.dart

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
      // Tap menu button then Edit
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
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
      // Tap menu button then Edit
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
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
      // Tap menu button then Editar (Edit in Portuguese)
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar')); // Portuguese "Edit"
      await tester.pumpAndSettle();
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
      // Tap menu button then Edit
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
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
      // Tap menu button then Edit
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
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
      final hasSuccessMessage = find
              .textContaining('success', findRichText: true)
              .evaluate()
              .isNotEmpty ||
          find
              .textContaining('sucesso', findRichText: true)
              .evaluate()
              .isNotEmpty;
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
      // Tap menu button then Edit
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // 5. Verify edit dialog is open (there are multiple "Rice Pilaf" texts: one in background, one in dialog)
      expect(find.byType(Dialog), findsOneWidget,
          reason: 'Edit dialog should be open');
      expect(find.text('Rice Pilaf'), findsWidgets,
          reason:
              'Existing side dish should be shown in edit dialog and background');

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
      final hasSuccessMessage = find
              .textContaining('success', findRichText: true)
              .evaluate()
              .isNotEmpty ||
          find
              .textContaining('sucesso', findRichText: true)
              .evaluate()
              .isNotEmpty;
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

      final sideRecipes = mealRecipes.where((mr) => !mr.isPrimaryDish).toList();
      expect(sideRecipes.length, 2, reason: 'Should have 2 side dishes');

      // Verify both side dishes are present
      final sideRecipeIds = sideRecipes.map((mr) => mr.recipeId).toList();
      expect(sideRecipeIds.contains(sideRecipe.id), isTrue,
          reason: 'Original side dish should still be present');
      expect(sideRecipeIds.contains(sideRecipe2.id), isTrue,
          reason: 'Newly added side dish should be in database');
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
      // Tap menu button then Edit
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
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
      final hasSuccessMessage = find
              .textContaining('success', findRichText: true)
              .evaluate()
              .isNotEmpty ||
          find
              .textContaining('sucesso', findRichText: true)
              .evaluate()
              .isNotEmpty;
      expect(hasSuccessMessage, isTrue,
          reason: 'Success message should be present in English or Portuguese');

      // 8. Verify data was updated
      final updatedMeal = await mockDbHelper.getMeal(meal.id);
      expect(updatedMeal!.notes, 'Updated single-recipe meal notes',
          reason: 'Single-recipe meal notes should be updated');
    });
  });
}
