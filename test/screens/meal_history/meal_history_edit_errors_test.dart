// test/screens/meal_history/meal_history_edit_errors_test.dart

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
      // Tap menu button then Edit
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
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
      // Tap menu button then Edit
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
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
      // Tap menu button then Editar (Edit in Portuguese)
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar')); // Portuguese "Edit"
      await tester.pumpAndSettle();
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
      // Tap menu button then Edit
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
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
      final hasErrorMessage = find
              .textContaining('Error', findRichText: true)
              .evaluate()
              .isNotEmpty ||
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
      // Tap menu button then Edit
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
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
      final hasErrorMessage = find
              .textContaining('Error', findRichText: true)
              .evaluate()
              .isNotEmpty ||
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
      // Tap menu button then Edit
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
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
      final hasErrorMessage = find
              .textContaining('Error', findRichText: true)
              .evaluate()
              .isNotEmpty ||
          find.textContaining('Erro', findRichText: true).evaluate().isNotEmpty;
      expect(hasErrorMessage, isTrue,
          reason: 'Error message should be present in English or Portuguese');
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
      // Tap menu button then Edit
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
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
      final hasErrorMessage = errorMessage.contains('Error editing meal') ||
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
      // Note: Service deletes all side dishes first, then tries to insert new ones.
      // Since insert failed, we have:
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

      final sideRecipes = mealRecipes.where((mr) => !mr.isPrimaryDish).toList();
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
  });
}
