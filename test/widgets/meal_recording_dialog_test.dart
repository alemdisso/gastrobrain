import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/widgets/meal_recording_dialog.dart';
import '../mocks/mock_database_helper.dart';

void main() {
  late MockDatabaseHelper mockDbHelper;
  late Recipe primaryRecipe;
  late Recipe sideRecipe1;
  late Recipe sideRecipe2;

  setUpAll(() {
    // Initialize FFI for tests
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Create fresh mock database for each test
    mockDbHelper = MockDatabaseHelper();

    // Create test recipes
    primaryRecipe = Recipe(
      id: 'primary-recipe-1',
      name: 'Grilled Chicken',
      desiredFrequency: FrequencyType.weekly,
      createdAt: DateTime.now(),
      difficulty: 3,
      prepTimeMinutes: 15,
      cookTimeMinutes: 25,
    );

    sideRecipe1 = Recipe(
      id: 'side-recipe-1',
      name: 'Rice Pilaf',
      desiredFrequency: FrequencyType.weekly,
      createdAt: DateTime.now(),
      difficulty: 2,
      prepTimeMinutes: 5,
      cookTimeMinutes: 20,
    );

    sideRecipe2 = Recipe(
      id: 'side-recipe-2',
      name: 'Green Salad',
      desiredFrequency: FrequencyType.weekly,
      createdAt: DateTime.now(),
      difficulty: 1,
      prepTimeMinutes: 10,
      cookTimeMinutes: 0,
    );

    // Add recipes to mock database
    await mockDbHelper.insertRecipe(primaryRecipe);
    await mockDbHelper.insertRecipe(sideRecipe1);
    await mockDbHelper.insertRecipe(sideRecipe2);
  });

  tearDown(() {
    mockDbHelper.resetAllData();
  });

  group('MealRecordingDialog Widget Tests', () {
    testWidgets('renders with primary recipe', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MealRecordingDialog(
              primaryRecipe: primaryRecipe,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify dialog title shows primary recipe name
      expect(find.text('Cook ${primaryRecipe.name}'), findsOneWidget);

      // Verify primary recipe is shown in recipes section
      expect(find.text(primaryRecipe.name), findsOneWidget);
      expect(find.text('Main dish'), findsOneWidget);

      // Verify main dish icon is present
      expect(find.byIcon(Icons.restaurant), findsOneWidget);

      // Verify basic form fields are present
      expect(find.text('Number of Servings'), findsOneWidget);
      expect(find.text('Actual Prep Time (min)'), findsOneWidget);
      expect(find.text('Actual Cook Time (min)'), findsOneWidget);
      expect(find.text('Was it successful?'), findsOneWidget);
    });

    testWidgets('renders with primary recipe and additional recipes',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MealRecordingDialog(
              primaryRecipe: primaryRecipe,
              additionalRecipes: [sideRecipe1, sideRecipe2],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify primary recipe
      expect(find.text(primaryRecipe.name), findsOneWidget);
      expect(find.text('Main dish'), findsOneWidget);

      // Verify additional recipes are shown
      expect(find.text(sideRecipe1.name), findsOneWidget);
      expect(find.text(sideRecipe2.name), findsOneWidget);

      // Should have two "Side dish" labels
      expect(find.text('Side dish'), findsNWidgets(2));

      // Should have side dish icons for additional recipes
      expect(find.byIcon(Icons.restaurant_menu), findsNWidgets(2));

      // Should have delete buttons for side dishes
      expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
    });

    testWidgets('can add additional recipes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MealRecordingDialog(
              primaryRecipe: primaryRecipe,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially should only show primary recipe
      expect(find.text('Side dish'), findsNothing);

      // Tap "Add Recipe" button
      await tester.tap(find.text('Add Recipe'));
      await tester.pumpAndSettle();

      // Should show recipe selection dialog
      expect(find.text('Add Recipe'), findsWidgets);
      expect(
          find.text('Select a recipe to add as a side dish:'), findsOneWidget);

      // Should show available recipes (excluding primary)
      expect(find.text(sideRecipe1.name), findsOneWidget);
      expect(find.text(sideRecipe2.name), findsOneWidget);

      // Primary recipe should not be shown in selection
      // (We expect only one instance - the one already selected as primary)
      expect(find.text(primaryRecipe.name), findsOneWidget);

      // Tap on a side recipe to select it
      await tester.tap(find.text(sideRecipe1.name));
      await tester.pumpAndSettle();

      // Should return to main dialog with added recipe
      expect(find.text(sideRecipe1.name), findsOneWidget);
      expect(find.text('Side dish'), findsOneWidget);
      expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('can remove additional recipes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MealRecordingDialog(
              primaryRecipe: primaryRecipe,
              additionalRecipes: [sideRecipe1, sideRecipe2],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially should show both side recipes
      expect(find.text(sideRecipe1.name), findsOneWidget);
      expect(find.text(sideRecipe2.name), findsOneWidget);
      expect(find.text('Side dish'), findsNWidgets(2));

      // Find and tap the first delete button
      final deleteButtons = find.byIcon(Icons.delete_outline);
      expect(deleteButtons, findsNWidgets(2));

      await tester.tap(deleteButtons.first);
      await tester.pumpAndSettle();

      // Should now have only one side recipe remaining
      expect(find.text('Side dish'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);

      // One of the recipes should be gone (exact which one depends on order)
      final remainingRecipes = [
        find.text(sideRecipe1.name).evaluate().isNotEmpty,
        find.text(sideRecipe2.name).evaluate().isNotEmpty,
      ];
      expect(remainingRecipes.where((exists) => exists).length, 1);
    });

    testWidgets('validates required fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MealRecordingDialog(
              primaryRecipe: primaryRecipe,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Clear the servings field to trigger validation
      final servingsField = find.widgetWithText(TextFormField, '1');
      await tester.enterText(servingsField, '');

      // Try to save without valid servings
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Please enter number of servings'), findsOneWidget);
    });

    testWidgets('validates servings as positive number',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MealRecordingDialog(
              primaryRecipe: primaryRecipe,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter invalid servings
      final servingsField = find.widgetWithText(TextFormField, '1');
      await tester.enterText(servingsField, '-1');

      // Try to save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Please enter a valid number'), findsOneWidget);
    });

    testWidgets('saves meal data correctly', (WidgetTester tester) async {
      Map<String, dynamic>? savedData;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  savedData = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (context) => MealRecordingDialog(
                      primaryRecipe: primaryRecipe,
                      additionalRecipes: [sideRecipe1],
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open the dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Modify servings
      final servingsField = find.widgetWithText(TextFormField, '1');
      await tester.enterText(servingsField, '4');

      // Add notes
      final notesField = find.widgetWithText(TextFormField, '');
      await tester.enterText(notesField.last, 'Test meal notes');

      // Save the meal
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify saved data
      expect(savedData, isNotNull);
      expect(savedData!['servings'], 4);
      expect(savedData!['notes'], 'Test meal notes');
      expect(savedData!['wasSuccessful'], true); // Default value
      expect(savedData!['primaryRecipe'], primaryRecipe);

      final additionalRecipes = savedData!['additionalRecipes'] as List<Recipe>;
      expect(additionalRecipes.length, 1);
      expect(additionalRecipes[0].id, sideRecipe1.id);
    });

    testWidgets('handles empty additional recipes list',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MealRecordingDialog(
              primaryRecipe: primaryRecipe,
              additionalRecipes: const [],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show only primary recipe
      expect(find.text(primaryRecipe.name), findsOneWidget);
      expect(find.text('Main dish'), findsOneWidget);
      expect(find.text('Side dish'), findsNothing);

      // Should still show "Add Recipe" button
      expect(find.text('Add Recipe'), findsOneWidget);
    });

    testWidgets('preserves actual time values from primary recipe',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MealRecordingDialog(
              primaryRecipe: primaryRecipe,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that prep and cook time fields are pre-filled
      expect(find.widgetWithText(TextFormField, '15'),
          findsOneWidget); // prep time
      expect(find.widgetWithText(TextFormField, '25'),
          findsOneWidget); // cook time
    });

    testWidgets('allows cancellation', (WidgetTester tester) async {
      Map<String, dynamic>? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (context) => MealRecordingDialog(
                      primaryRecipe: primaryRecipe,
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open the dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Cancel the dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Should return null when cancelled
      expect(result, isNull);
    });
  });
}
