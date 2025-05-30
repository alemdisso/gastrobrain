// test/widgets/edit_meal_recording_dialog_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/widgets/edit_meal_recording_dialog.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/meal.dart';
import 'package:gastrobrain/models/frequency_type.dart';

void main() {
  late Recipe testRecipe;
  late Recipe sideRecipe;
  late Meal testMeal;

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

    testMeal = Meal(
      id: 'test-meal-1',
      cookedAt: DateTime.now().subtract(const Duration(days: 1)),
      servings: 3,
      notes: 'Original test notes',
      wasSuccessful: true,
      actualPrepTime: 20.0,
      actualCookTime: 30.0,
    );
  });

  group('EditMealRecordingDialog Widget Tests', () {
    testWidgets('displays dialog with pre-populated data',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => EditMealRecordingDialog(
                      meal: testMeal,
                      primaryRecipe: testRecipe,
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog title shows recipe name
      expect(find.text('Edit ${testRecipe.name}'), findsOneWidget);

      // Verify pre-populated data appears
      expect(find.text('3'), findsOneWidget); // Servings field
      expect(find.text('Original test notes'), findsOneWidget); // Notes field
      expect(find.text('20.0'), findsOneWidget); // Prep time
      expect(find.text('30.0'), findsOneWidget); // Cook time

      // Verify primary recipe is shown
      expect(find.text(testRecipe.name), findsOneWidget);
      expect(find.text('Main dish'), findsOneWidget);

      // Verify action buttons
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('displays additional recipes correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => EditMealRecordingDialog(
                      meal: testMeal,
                      primaryRecipe: testRecipe,
                      additionalRecipes: [sideRecipe],
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify both recipes are shown
      expect(find.text(testRecipe.name), findsOneWidget);
      expect(find.text(sideRecipe.name), findsOneWidget);

      // Verify recipe roles
      expect(find.text('Main dish'), findsOneWidget);
      expect(find.text('Side dish'), findsOneWidget);

      // Verify side dish has remove button
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('can cancel dialog without changes',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => EditMealRecordingDialog(
                      meal: testMeal,
                      primaryRecipe: testRecipe,
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Cancel dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog should be gone
      expect(find.text('Edit ${testRecipe.name}'), findsNothing);
      expect(find.text('Show Dialog'), findsOneWidget); // Back to main screen
    });

    testWidgets('validates servings field correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => EditMealRecordingDialog(
                      meal: testMeal,
                      primaryRecipe: testRecipe,
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Clear servings field and enter invalid value
      await tester.enterText(find.byType(TextFormField).first, '0');

      // Try to save
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Please enter a valid number'), findsOneWidget);
    });

    testWidgets('shows success switch in correct state',
        (WidgetTester tester) async {
      // Test with unsuccessful meal
      final unsuccessfulMeal = Meal(
        id: 'unsuccessful-meal',
        cookedAt: DateTime.now(),
        servings: 2,
        wasSuccessful: false, // Set to false
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => EditMealRecordingDialog(
                      meal: unsuccessfulMeal,
                      primaryRecipe: testRecipe,
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Find the switch widget
      final switchWidget = tester.widget<Switch>(find.byType(Switch));

      // Verify switch is in correct state (false for unsuccessful meal)
      expect(switchWidget.value, false);
    });
  });
}
