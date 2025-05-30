// test/screens/cook_meal_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/screens/cook_meal_screen.dart';

void main() {
  late Recipe testRecipe;
  late Recipe sideRecipe;

  setUp(() {
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
  });

  group('CookMealScreen Widget Tests', () {
    testWidgets('renders with correct recipe name in title',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CookMealScreen(recipe: testRecipe),
        ),
      );

      await tester.pumpAndSettle();

      // Verify app bar title shows recipe name
      expect(find.text('Cook ${testRecipe.name}'), findsOneWidget);

      // Verify main content text
      expect(find.text('Record cooking details for ${testRecipe.name}'),
          findsOneWidget);

      // Verify the "Record Meal Details" button exists
      expect(find.text('Record Meal Details'), findsOneWidget);
      expect(find.byIcon(Icons.restaurant), findsOneWidget);
    });

    testWidgets('tapping button shows meal recording dialog',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CookMealScreen(recipe: testRecipe),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the "Record Meal Details" button
      await tester.tap(find.text('Record Meal Details'));
      await tester.pumpAndSettle();

      // Verify that the MealRecordingDialog appeared
      // We can check for the dialog title which should show the recipe name
      expect(find.text('Cook ${testRecipe.name}'),
          findsNWidgets(2)); // One in app bar, one in dialog

      // Or check for dialog-specific elements
      expect(find.text('Number of Servings'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('handles dialog cancellation correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CookMealScreen(recipe: testRecipe),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the button to open dialog
      await tester.tap(find.text('Record Meal Details'));
      await tester.pumpAndSettle();

      // Cancel the dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Should return to the main screen (dialog closed)
      expect(find.text('Record cooking details for ${testRecipe.name}'),
          findsOneWidget);
      expect(find.text('Record Meal Details'), findsOneWidget);

      // Dialog should be gone
      expect(find.text('Number of Servings'), findsNothing);
    });

    testWidgets('renders with additional recipes when provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CookMealScreen(
            recipe: testRecipe,
            additionalRecipes: [sideRecipe],
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should still show the primary recipe name in title
      expect(find.text('Cook ${testRecipe.name}'), findsOneWidget);

      // Should show the same UI regardless of additional recipes
      expect(find.text('Record cooking details for ${testRecipe.name}'),
          findsOneWidget);
      expect(find.text('Record Meal Details'), findsOneWidget);
    });

    testWidgets('passes additional recipes to dialog when provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CookMealScreen(
            recipe: testRecipe,
            additionalRecipes: [sideRecipe],
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open the dialog
      await tester.tap(find.text('Record Meal Details'));
      await tester.pumpAndSettle();

      // Should show both primary and additional recipes in the dialog
      expect(find.text(testRecipe.name), findsOneWidget);
      expect(find.text(sideRecipe.name), findsOneWidget);

      // Should show proper indicators for main vs side dish
      expect(find.text('Main dish'), findsOneWidget);
      expect(find.text('Side dish'), findsOneWidget);
    });
    testWidgets('handles empty additional recipes list',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CookMealScreen(
            recipe: testRecipe,
            additionalRecipes: const [],
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open the dialog
      await tester.tap(find.text('Record Meal Details'));
      await tester.pumpAndSettle();

      // Should only show primary recipe
      expect(find.text(testRecipe.name), findsOneWidget);
      expect(find.text('Main dish'), findsOneWidget);

      // Should not show any side dishes
      expect(find.text('Side dish'), findsNothing);

      // Should still show "Add Recipe" button for adding sides
      expect(find.text('Add Recipe'), findsOneWidget);
    });

    testWidgets('shows correct app bar title with long recipe names',
        (WidgetTester tester) async {
      final longNameRecipe = Recipe(
        id: 'long-name-recipe',
        name: 'Super Long Recipe Name That Might Cause Layout Issues',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CookMealScreen(recipe: longNameRecipe),
        ),
      );

      await tester.pumpAndSettle();

      // Should handle long names gracefully in app bar
      expect(find.text('Cook ${longNameRecipe.name}'), findsOneWidget);

      // Should also show in main content
      expect(find.text('Record cooking details for ${longNameRecipe.name}'),
          findsOneWidget);
    });
  });
}
