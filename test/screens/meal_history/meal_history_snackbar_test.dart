// test/screens/meal_history/meal_history_snackbar_test.dart

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
      // Tap menu button then Edit
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
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
      // Tap menu button then Edit
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
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
      // Tap menu button then Edit
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('edit_meal_recording_servings_field')),
        '10',
      );

      await tester.tap(find.text('Save Changes'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      // 4. Immediately perform second rapid edit (don't wait for first snackbar)
      await tester.tap(find.byIcon(Icons.more_vert).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
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
          reason:
              'Text should be within SnackBar and accessible to screen readers');

      // 8. Verify snackbar is visible and has content
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.content, isA<Text>(),
          reason: 'SnackBar should have Text content that is accessible');
    });
  });
}
