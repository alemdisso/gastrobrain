import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/screens/cook_meal_screen.dart';

void main() {
  late Recipe testRecipe;

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
  });
}
