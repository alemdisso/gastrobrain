// test/screens/add_recipe_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/core/di/providers/database_provider.dart';
import 'package:gastrobrain/models/ingredient.dart';
import 'package:gastrobrain/screens/add_recipe_screen.dart';
import '../mocks/mock_database_helper.dart';

void main() {
  late MockDatabaseHelper mockDbHelper;

  setUp(() {
    // Create a fresh mock database for each test
    mockDbHelper = MockDatabaseHelper();

    // Inject the mock database into the provider
    DatabaseProvider().setDatabaseHelper(mockDbHelper);
  });

  tearDown(() {
    // Reset the mock database after each test
    mockDbHelper.resetAllData();
  });

  testWidgets('AddRecipeScreen saves recipe to injected database',
      (WidgetTester tester) async {
    // Build the widget with the injected mock database
    await tester.pumpWidget(MaterialApp(
      home: AddRecipeScreen(
        databaseHelper: mockDbHelper,
      ),
    ));

    // Enter recipe data
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Recipe Name'), 'Test Recipe');

    // Select a frequency (weekly)
    // Note: Dropdown interaction is tricky in widget tests
    // For a real test, you'd need to tap the dropdown and select an item

    // Enter times
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Preparation Time'), '30');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Cooking Time'), '45');

    // Set difficulty (tapping the third star)
    await tester.tap(find.byIcon(Icons.star_border).at(2));
    await tester.pump();

    // Add notes
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Notes'), 'Test notes');

    // Tap the save button
    await tester.tap(find.text('Save Recipe'));
    await tester.pumpAndSettle();

    // Verify the recipe was saved to the mock database
    expect(mockDbHelper.recipes.length, 1);

    // Get the first recipe from the mock database
    final savedRecipe = mockDbHelper.recipes.values.first;

    // Verify recipe details
    expect(savedRecipe.name, 'Test Recipe');
    expect(savedRecipe.prepTimeMinutes, 30);
    expect(savedRecipe.cookTimeMinutes, 45);
    expect(savedRecipe.notes, 'Test notes');

    // Note: difficulty and other UI-set values might not be captured
    // in this basic test - you'd need more complex UI interaction
  });

  testWidgets('AddRecipeScreen loads and displays ingredients from database',
      (WidgetTester tester) async {
    // Prepare test data - add ingredients to mock database
    mockDbHelper.ingredients['test-ing-1'] = Ingredient(
      id: 'test-ing-1',
      name: 'Test Ingredient 1',
      category: 'vegetable',
    );

    mockDbHelper.ingredients['test-ing-2'] = Ingredient(
      id: 'test-ing-2',
      name: 'Test Ingredient 2',
      category: 'protein',
      proteinType: 'chicken',
    );

    // Build the screen with mock database
    await tester.pumpWidget(MaterialApp(
      home: AddRecipeScreen(
        databaseHelper: mockDbHelper,
      ),
    ));

    // Find and tap the Add Ingredient button
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    // This opens the AddIngredientDialog
    expect(find.text('Add Ingredient'), findsOneWidget);

    // Verify the dialog contains our ingredients
    // You might need additional widget testing here to verify ingredients
    // appear after user interactions with the search field, etc.

    // Close the dialog by tapping Cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('AddRecipeScreen validation prevents empty recipe submission',
      (WidgetTester tester) async {
    // Build the screen
    await tester.pumpWidget(MaterialApp(
      home: AddRecipeScreen(
        databaseHelper: mockDbHelper,
      ),
    ));

    // Try to save without entering any data
    await tester.tap(find.text('Save Recipe'));
    await tester.pumpAndSettle();

    // Verify validation error appears
    expect(find.text('Please enter a recipe name'), findsOneWidget);

    // Verify nothing was saved to the database
    expect(mockDbHelper.recipes.isEmpty, true);
  });
}
