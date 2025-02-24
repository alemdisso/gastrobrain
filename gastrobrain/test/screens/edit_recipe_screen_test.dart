import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/screens/edit_recipe_screen.dart';

void main() {
  group('EditRecipeScreen', () {
    late Recipe testRecipe;

    setUp(() {
      testRecipe = Recipe(
        id: 'test_id',
        name: 'Test Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
        difficulty: 3,
        prepTimeMinutes: 30,
        cookTimeMinutes: 45,
        rating: 4,
      );
    });

    testWidgets('loads recipe frequency correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EditRecipeScreen(recipe: testRecipe),
        ),
      );

      // Find dropdown
      final dropdownFinder =
          find.byType(DropdownButtonFormField<FrequencyType>);
      expect(dropdownFinder, findsOneWidget);

      // Find the dropdown button's text
      final dropdownButton =
          find.byType(DropdownButtonFormField<FrequencyType>);
      expect(dropdownButton, findsOneWidget);

      // Verify the selected value text is visible within the button
      final buttonText = find.descendant(
        of: dropdownButton,
        matching: find.text('Weekly'),
      );
      expect(buttonText, findsOneWidget);
    });

    testWidgets('shows all frequency options', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EditRecipeScreen(recipe: testRecipe),
        ),
      );

      // Find and tap the dropdown button to open the menu
      await tester.tap(find.byType(DropdownButtonFormField<FrequencyType>));
      await tester.pumpAndSettle();

      // Verify each frequency appears in the menu
      for (final frequency in FrequencyType.values) {
        final menuItemFinder = find
            .ancestor(
              of: find.text(frequency.displayName),
              matching: find.byType(DropdownMenuItem<FrequencyType>),
            )
            .last; // Use last to get the one in the overlay

        expect(menuItemFinder, findsOneWidget,
            reason: 'Should find menu item for ${frequency.displayName}');
      }
    });

    testWidgets('can change frequency', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EditRecipeScreen(recipe: testRecipe),
        ),
      );

      // Open dropdown and select monthly
      await tester.tap(find.byType(DropdownButtonFormField<FrequencyType>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Monthly').last);
      await tester.pumpAndSettle();

      // Find the dropdown button
      final dropdownButton =
          find.byType(DropdownButtonFormField<FrequencyType>);

      // Verify the selected value text is visible within the button
      final monthlyText = find.descendant(
        of: dropdownButton,
        matching: find.text('Monthly'),
      );
      final weeklyText = find.descendant(
        of: dropdownButton,
        matching: find.text('Weekly'),
      );

      expect(monthlyText, findsOneWidget);
      expect(weeklyText, findsNothing);
    });

    testWidgets('preserves frequency when other fields change',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EditRecipeScreen(recipe: testRecipe),
        ),
      );

      // Change recipe name
      await tester.enterText(
          find.byType(TextFormField).first, 'Updated Recipe');
      await tester.pump();

      // Verify frequency is still weekly
      expect(find.text('Weekly'), findsOneWidget);
    });
  });
}
