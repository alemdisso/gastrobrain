// test/widgets/add_ingredient_dialog_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/widgets/add_ingredient_dialog.dart';

// Simple test to verify the dialog appears
void main() {
  group('AddIngredientDialog', () {
    late Recipe testRecipe;

    setUp(() {
      testRecipe = Recipe(
        id: 'test-id',
        name: 'Test Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
      );
    });

    testWidgets('Dialog opens and displays correctly',
        (WidgetTester tester) async {
      // Build test app with proper scaffold
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AddIngredientDialog(
                        recipe: testRecipe,
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pump();

      // Verify the dialog appears with the expected title
      expect(find.text('Add Ingredient'), findsOneWidget);

      // Basic verification is complete
      // Note: Full testing would require mocking database operations
    });
  });
}
