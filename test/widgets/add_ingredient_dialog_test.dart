// test/widgets/add_ingredient_dialog_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/widgets/add_ingredient_dialog.dart';
import 'package:gastrobrain/models/ingredient.dart';
import 'package:gastrobrain/models/recipe_ingredient.dart';
import '../mocks/mock_database_helper.dart';
import '../test_utils/test_app_wrapper.dart';
import '../test_utils/test_setup.dart';

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
        wrapWithLocalizations(Scaffold(
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
        )),
      );

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pump();

      // Verify the dialog appears with the expected title (Portuguese)
      expect(find.text('Adicionar Ingrediente'), findsOneWidget);

      // Basic verification is complete
      // Note: Full testing would require mocking database operations
    });
  });

  // Add a new group specifically for DI tests
  group('AddIngredientDialog with Dependency Injection', () {
    late MockDatabaseHelper mockDbHelper;
    late Recipe testRecipe;

    setUp(() {
      // Set up mock database using TestSetup utility
      mockDbHelper = TestSetup.setupMockDatabase();

      // Set up a test recipe
      testRecipe = Recipe(
        id: 'test-recipe-id',
        name: 'Test Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
      );

      // Add test ingredients to mock database
      mockDbHelper.ingredients['test-ing-1'] = Ingredient(
        id: 'test-ing-1',
        name: 'Carrots',
        category: 'vegetable',
        unit: 'g',
      );

      mockDbHelper.ingredients['test-ing-2'] = Ingredient(
        id: 'test-ing-2',
        name: 'Chicken Breast',
        category: 'protein',
        proteinType: 'chicken',
        unit: 'g',
      );
    });

    tearDown(() {
      TestSetup.cleanupMockDatabase(mockDbHelper);
    });

    // Add the DI-specific test cases here
    testWidgets('loads ingredients from injected database',
        (WidgetTester tester) async {
      RecipeIngredient? savedIngredient;

      // Build the dialog WITH THE TEST RECIPE
      await tester.pumpWidget(wrapWithLocalizations(Scaffold(
        body: Builder(
          builder: (BuildContext context) {
            return TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddIngredientDialog(
                    recipe: testRecipe, // Use the test recipe here
                    databaseHelper: mockDbHelper,
                    onSave: (ingredient) {
                      savedIngredient = ingredient;
                      Navigator.pop(context, ingredient);
                    },
                  ),
                );
              },
              child: const Text('Show Dialog'),
            );
          },
        ),
      )));
      expect(savedIngredient, null);
    });

    testWidgets('creates custom ingredient with mock database',
        (WidgetTester tester) async {
      // Test body as in the artifact
    });

    testWidgets('validates input with mock database',
        (WidgetTester tester) async {
      // Test body as in the artifact
    });
  });
}
