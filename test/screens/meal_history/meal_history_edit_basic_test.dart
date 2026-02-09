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

      // TODO(#286): Add comprehensive tests for actual editing workflow
      // This test currently just verifies the multi-recipe meal displays correctly
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
}
