// test/screens/meal_history/meal_history_delete_test.dart

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
  group('Meal Deletion Tests', () {
    testWidgets('displays PopupMenuButton with delete option',
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

      // Should show PopupMenuButton with three dots icon
      expect(find.byIcon(Icons.more_vert), findsOneWidget);

      // Tap the menu button
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Should show Edit and Delete options
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('delete option shows confirmation dialog',
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

      // Tap the menu button
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap Delete option
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Should show confirmation dialog
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Delete Meal'), findsOneWidget);
      expect(find.textContaining('Are you sure you want to delete'),
          findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsAtLeastNWidgets(1));
    });

    testWidgets('cancelling deletion keeps meal in database',
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

      // Verify meal exists before deletion attempt
      final mealBefore = await mockDbHelper.getMeal(testMeal.id);
      expect(mealBefore, isNotNull);

      // Tap the menu button
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap Delete option
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Tap Cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify meal still exists
      final mealAfter = await mockDbHelper.getMeal(testMeal.id);
      expect(mealAfter, isNotNull);
      expect(mealAfter!.id, testMeal.id);

      // Verify no snackbar is shown
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('confirming deletion removes meal from database',
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

      // Verify meal exists before deletion
      final mealBefore = await mockDbHelper.getMeal(testMeal.id);
      expect(mealBefore, isNotNull);

      // Verify MealRecipe association exists
      final mealRecipesBefore =
          await mockDbHelper.getMealRecipesForMeal(testMeal.id);
      expect(mealRecipesBefore, isNotEmpty);

      // Tap the menu button
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap Delete option
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Tap Delete button in confirmation dialog
      final deleteButtons = find.text('Delete');
      await tester.tap(deleteButtons.last);
      await tester.pumpAndSettle();

      // Verify meal is deleted
      final mealAfter = await mockDbHelper.getMeal(testMeal.id);
      expect(mealAfter, isNull);

      // Verify MealRecipe associations are deleted
      final mealRecipesAfter =
          await mockDbHelper.getMealRecipesForMeal(testMeal.id);
      expect(mealRecipesAfter, isEmpty);

      // Verify success snackbar is shown
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Meal deleted successfully'), findsOneWidget);
    });

    testWidgets(
        'deleting meal with multiple side dishes removes all associations',
        (WidgetTester tester) async {
      // Remove the test meal from setUp to avoid confusion
      await mockDbHelper.deleteMeal(testMeal.id);

      // Create a meal with multiple side dishes
      final mealWithSides = Meal(
        id: 'meal-with-sides',
        recipeId: null,
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
        servings: 4,
        notes: 'Multi-recipe meal',
        wasSuccessful: true,
        actualPrepTime: 25.0,
        actualCookTime: 35.0,
      );

      await mockDbHelper.insertMeal(mealWithSides);

      // Add primary dish
      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: mealWithSides.id,
        recipeId: testRecipe.id,
        isPrimaryDish: true,
      ));

      // Add two side dishes
      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: mealWithSides.id,
        recipeId: sideRecipe.id,
        isPrimaryDish: false,
      ));

      final anotherSide = Recipe(
        id: 'another-side',
        name: 'Green Salad',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
        difficulty: 1,
        prepTimeMinutes: 10,
        cookTimeMinutes: 0,
      );
      await mockDbHelper.insertRecipe(anotherSide);

      await mockDbHelper.insertMealRecipe(MealRecipe(
        mealId: mealWithSides.id,
        recipeId: anotherSide.id,
        isPrimaryDish: false,
      ));

      // Verify all 3 MealRecipe entries exist
      final mealRecipesBefore =
          await mockDbHelper.getMealRecipesForMeal(mealWithSides.id);
      expect(mealRecipesBefore.length, 3);

      await tester.pumpWidget(
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the meal card (should be the first one since it's more recent)
      final moreVertButtons = find.byIcon(Icons.more_vert);
      expect(moreVertButtons, findsAtLeastNWidgets(1));

      // Tap the first menu button
      await tester.tap(moreVertButtons.first);
      await tester.pumpAndSettle();

      // Tap Delete option
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Confirm deletion - find and tap the Delete button in the AlertDialog
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete').last);
      await tester.pumpAndSettle();

      // Wait for async operations to complete
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Verify meal is deleted
      final mealAfter = await mockDbHelper.getMeal(mealWithSides.id);
      expect(mealAfter, isNull);

      // Verify ALL MealRecipe associations are deleted
      final mealRecipesAfter =
          await mockDbHelper.getMealRecipesForMeal(mealWithSides.id);
      expect(mealRecipesAfter, isEmpty);

      // Verify success snackbar
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('deletion error shows error snackbar',
        (WidgetTester tester) async {
      // Configure mock to throw exception on delete
      mockDbHelper.shouldThrowOnDelete = true;

      await tester.pumpWidget(
        createTestableWidget(
          MealHistoryScreen(
            recipe: testRecipe,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the menu button
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap Delete option
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Confirm deletion
      final deleteButtons = find.text('Delete');
      await tester.tap(deleteButtons.last);
      await tester.pumpAndSettle();

      // Verify error snackbar is shown
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Error deleting meal'), findsOneWidget);

      // Reset mock state
      mockDbHelper.shouldThrowOnDelete = false;
    });
  });
}
