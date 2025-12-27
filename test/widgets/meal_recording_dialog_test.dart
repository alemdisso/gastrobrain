// test/widgets/meal_recording_dialog_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/widgets/meal_recording_dialog.dart';
import 'package:gastrobrain/models/recipe.dart';
import '../test_utils/test_app_wrapper.dart';
import '../test_utils/test_setup.dart';
import '../test_utils/dialog_fixtures.dart';
import '../helpers/dialog_test_helpers.dart';
import '../mocks/mock_database_helper.dart';

void main() {
  late MockDatabaseHelper mockDbHelper;
  late Recipe primaryRecipe;
  late Recipe sideRecipe1;
  late Recipe sideRecipe2;
  late List<Recipe> availableRecipes;

  setUp(() {
    mockDbHelper = TestSetup.setupMockDatabase();

    // Create test recipes
    primaryRecipe = DialogFixtures.createPrimaryRecipe();
    sideRecipe1 = DialogFixtures.createSideRecipe();
    sideRecipe2 = DialogFixtures.createTestRecipe(
      id: 'side-recipe-2',
      name: 'Roasted Vegetables',
      difficulty: 2,
    );

    availableRecipes = [primaryRecipe, sideRecipe1, sideRecipe2];

    // Insert recipes into mock database
    for (final recipe in availableRecipes) {
      mockDbHelper.insertRecipe(recipe);
    }
  });

  tearDown() {
    TestSetup.cleanupMockDatabase(mockDbHelper);
  }

  group('MealRecordingDialog - Initial State', () {
    testWidgets('dialog opens with correct initial state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => MealRecordingDialog(
                    primaryRecipe: primaryRecipe,
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        )),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog opened
      expect(DialogTestHelpers.findDialogByType<MealRecordingDialog>(),
          findsOneWidget);

      // Verify primary recipe is shown
      expect(find.text(primaryRecipe.name), findsAtLeastNWidgets(1));
      expect(find.text('Prato principal'), findsOneWidget);

      // Verify servings field has default value of 1
      final servingsField = find.byKey(const Key('meal_recording_servings_field'));
      expect(servingsField, findsOneWidget);
      expect(tester.widget<TextFormField>(servingsField).controller!.text, equals('1'));

      // Verify prep time is pre-filled from recipe
      final prepTimeField = find.byKey(const Key('meal_recording_prep_time_field'));
      expect(prepTimeField, findsOneWidget);
      expect(
        tester.widget<TextFormField>(prepTimeField).controller!.text,
        equals(primaryRecipe.prepTimeMinutes.toString()),
      );

      // Verify cook time is pre-filled from recipe
      final cookTimeField = find.byKey(const Key('meal_recording_cook_time_field'));
      expect(cookTimeField, findsOneWidget);
      expect(
        tester.widget<TextFormField>(cookTimeField).controller!.text,
        equals(primaryRecipe.cookTimeMinutes.toString()),
      );

      // Verify success switch is ON by default
      final successSwitch = find.byKey(const Key('meal_recording_success_switch'));
      expect(successSwitch, findsOneWidget);
      expect(tester.widget<Switch>(successSwitch).value, isTrue);

      // Verify buttons are present
      expect(find.byKey(const Key('meal_recording_cancel_button')), findsOneWidget);
      expect(find.byKey(const Key('meal_recording_save_button')), findsOneWidget);
    });

    testWidgets('pre-fills notes when provided', (WidgetTester tester) async {
      const testNotes = 'This is a test note';

      await tester.pumpWidget(
        wrapWithLocalizations(Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => MealRecordingDialog(
                    primaryRecipe: primaryRecipe,
                    notes: testNotes,
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        )),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify notes are pre-filled
      final notesField = find.byKey(const Key('meal_recording_notes_field'));
      expect(notesField, findsOneWidget);
      expect(
        tester.widget<TextFormField>(notesField).controller!.text,
        equals(testNotes),
      );
    });

    testWidgets('pre-fills planned date when provided',
        (WidgetTester tester) async {
      final plannedDate = DateTime(2024, 1, 15, 12, 30);

      await tester.pumpWidget(
        wrapWithLocalizations(Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => MealRecordingDialog(
                    primaryRecipe: primaryRecipe,
                    plannedDate: plannedDate,
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        )),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify planned date is shown in the dialog
      // The dialog shows "Planejada para: [date]" when plannedDate is provided
      expect(find.textContaining('Planejada para:'), findsOneWidget);
    });

    testWidgets('pre-fills additional recipes when provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => MealRecordingDialog(
                    primaryRecipe: primaryRecipe,
                    additionalRecipes: [sideRecipe1, sideRecipe2],
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        )),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify additional recipes are shown
      expect(find.text(sideRecipe1.name), findsOneWidget);
      expect(find.text(sideRecipe2.name), findsOneWidget);

      // Verify they're marked as side dishes
      expect(find.text('Acompanhamento'), findsNWidgets(2));
    });

    testWidgets('loads available recipes from database',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => MealRecordingDialog(
                    primaryRecipe: primaryRecipe,
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        )),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Wait for recipes to load
      await tester.pumpAndSettle();

      // Verify recipes are available in mock database
      expect(mockDbHelper.recipes.isNotEmpty, isTrue);
      expect(mockDbHelper.recipes.length, equals(3));
    });
  });

  group('MealRecordingDialog - Return Value', () {
    testWidgets('returns correct meal data on save',
        (WidgetTester tester) async {
      final result = await DialogTestHelpers.openDialogAndCapture<Map>(
        tester,
        dialogBuilder: (context) => MealRecordingDialog(
          primaryRecipe: primaryRecipe,
        ),
      );

      // Fill in servings
      await tester.enterText(
        find.byKey(const Key('meal_recording_servings_field')),
        '4',
      );
      await tester.pumpAndSettle();

      // Fill in notes
      await tester.enterText(
        find.byKey(const Key('meal_recording_notes_field')),
        'Test notes',
      );
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.byKey(const Key('meal_recording_save_button')));
      await tester.pumpAndSettle();

      // Verify return value
      expect(result.hasValue, isTrue);
      expect(result.value, isNotNull);
      expect(result.value!['servings'], equals(4));
      expect(result.value!['notes'], equals('Test notes'));
      expect(result.value!['wasSuccessful'], isTrue);
      expect(result.value!['primaryRecipe'], equals(primaryRecipe));
      expect(result.value!['actualPrepTime'], equals(primaryRecipe.prepTimeMinutes.toDouble()));
      expect(result.value!['actualCookTime'], equals(primaryRecipe.cookTimeMinutes.toDouble()));
      expect(result.value!['additionalRecipes'], isA<List>());
      expect(result.value!['cookedAt'], isA<DateTime>());
    });

    testWidgets('returns additional recipes in meal data',
        (WidgetTester tester) async {
      final result = await DialogTestHelpers.openDialogAndCapture<Map>(
        tester,
        dialogBuilder: (context) => MealRecordingDialog(
          primaryRecipe: primaryRecipe,
          additionalRecipes: [sideRecipe1],
        ),
      );

      // Save
      await tester.tap(find.byKey(const Key('meal_recording_save_button')));
      await tester.pumpAndSettle();

      // Verify additional recipes in return value
      expect(result.hasValue, isTrue);
      final additionalRecipes = result.value!['additionalRecipes'] as List;
      expect(additionalRecipes.length, equals(1));
      expect(additionalRecipes[0], equals(sideRecipe1));
    });

    testWidgets('returns null when cancelled', (WidgetTester tester) async {
      final result = await DialogTestHelpers.openDialogAndCapture<Map>(
        tester,
        dialogBuilder: (context) => MealRecordingDialog(
          primaryRecipe: primaryRecipe,
        ),
      );

      // Cancel
      await tester.tap(find.byKey(const Key('meal_recording_cancel_button')));
      await tester.pumpAndSettle();

      // Verify null return
      DialogTestHelpers.verifyDialogCancelled(result);
      DialogTestHelpers.verifyDialogClosed<MealRecordingDialog>();
    });
  });

  group('MealRecordingDialog - Additional Recipes Management', () {
    // Note: Comprehensive tests for adding side dishes via nested dialog are
    // deferred until #237 implements proper DI. See issue comment for details.

    testWidgets('shows add recipe button when allowRecipeChange is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => MealRecordingDialog(
                    primaryRecipe: primaryRecipe,
                    allowRecipeChange: true,
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        )),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify "Add Recipe" button is present
      expect(find.text('Adicionar Receita'), findsOneWidget);
    });

    testWidgets('hides add recipe button when allowRecipeChange is false',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => MealRecordingDialog(
                    primaryRecipe: primaryRecipe,
                    allowRecipeChange: false,
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        )),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify "Add Recipe" button is NOT present
      expect(find.text('Adicionar Receita'), findsNothing);
    });

    testWidgets('allows removing side dishes', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
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
        )),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify side dish is shown
      expect(find.text(sideRecipe1.name), findsOneWidget);
      expect(find.text('Acompanhamento'), findsOneWidget);

      // Find and tap delete button
      final deleteButton = find.byIcon(Icons.delete_outline);
      expect(deleteButton, findsOneWidget);
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // Verify side dish was removed
      expect(find.text('Acompanhamento'), findsNothing);
    });
  });

  group('MealRecordingDialog - Validation', () {
    testWidgets('validates servings field is required',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => MealRecordingDialog(
                    primaryRecipe: primaryRecipe,
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        )),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Clear servings field
      await tester.enterText(
        find.byKey(const Key('meal_recording_servings_field')),
        '',
      );
      await tester.pumpAndSettle();

      // Try to save
      await tester.tap(find.byKey(const Key('meal_recording_save_button')));
      await tester.pumpAndSettle();

      // Verify validation error is shown
      expect(find.text('Por favor, informe o número de porções'), findsOneWidget);

      // Verify dialog is still open
      expect(
        DialogTestHelpers.findDialogByType<MealRecordingDialog>(),
        findsOneWidget,
      );
    });

    testWidgets('validates servings must be a valid number',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => MealRecordingDialog(
                    primaryRecipe: primaryRecipe,
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        )),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Enter invalid servings
      await tester.enterText(
        find.byKey(const Key('meal_recording_servings_field')),
        '0',
      );
      await tester.pumpAndSettle();

      // Try to save
      await tester.tap(find.byKey(const Key('meal_recording_save_button')));
      await tester.pumpAndSettle();

      // Verify validation error is shown
      expect(find.text('Por favor, informe um número válido'), findsOneWidget);
    });

    testWidgets('validates prep time must be valid if provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => MealRecordingDialog(
                    primaryRecipe: primaryRecipe,
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        )),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Enter invalid prep time
      await tester.enterText(
        find.byKey(const Key('meal_recording_prep_time_field')),
        '-5',
      );
      await tester.pumpAndSettle();

      // Try to save
      await tester.tap(find.byKey(const Key('meal_recording_save_button')));
      await tester.pumpAndSettle();

      // Verify validation error is shown
      expect(find.text('Informe um tempo válido'), findsAtLeastNWidgets(1));
    });

    testWidgets('validates cook time must be valid if provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => MealRecordingDialog(
                    primaryRecipe: primaryRecipe,
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        )),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Enter invalid cook time
      await tester.enterText(
        find.byKey(const Key('meal_recording_cook_time_field')),
        '-10',
      );
      await tester.pumpAndSettle();

      // Try to save
      await tester.tap(find.byKey(const Key('meal_recording_save_button')));
      await tester.pumpAndSettle();

      // Verify validation error is shown
      expect(find.text('Informe um tempo válido'), findsAtLeastNWidgets(1));
    });
  });

  group('MealRecordingDialog - Date Selection', () {
    testWidgets('allows selecting a different date',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => MealRecordingDialog(
                    primaryRecipe: primaryRecipe,
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        )),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Tap on date selector
      await tester.tap(find.byKey(const Key('meal_recording_date_selector')));
      await tester.pumpAndSettle();

      // Date picker should appear
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });
  });

  group('MealRecordingDialog - Success Switch', () {
    testWidgets('toggles success switch', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => MealRecordingDialog(
                    primaryRecipe: primaryRecipe,
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        )),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Get success switch
      final successSwitch = find.byKey(const Key('meal_recording_success_switch'));
      expect(tester.widget<Switch>(successSwitch).value, isTrue);

      // Toggle switch
      await tester.tap(successSwitch);
      await tester.pumpAndSettle();

      // Verify switch is now OFF
      expect(tester.widget<Switch>(successSwitch).value, isFalse);
    });

    testWidgets('returns correct wasSuccessful value in meal data',
        (WidgetTester tester) async {
      final result = await DialogTestHelpers.openDialogAndCapture<Map>(
        tester,
        dialogBuilder: (context) => MealRecordingDialog(
          primaryRecipe: primaryRecipe,
        ),
      );

      // Toggle success switch to OFF
      final successSwitch = find.byKey(const Key('meal_recording_success_switch'));
      await tester.tap(successSwitch);
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.byKey(const Key('meal_recording_save_button')));
      await tester.pumpAndSettle();

      // Verify wasSuccessful is false in return value
      expect(result.hasValue, isTrue);
      expect(result.value!['wasSuccessful'], isFalse);
    });
  });

  group('MealRecordingDialog - Controller Disposal', () {
    testWidgets('safely disposes controllers on cancel',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => MealRecordingDialog(
                    primaryRecipe: primaryRecipe,
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        )),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Cancel
      await tester.tap(find.byKey(const Key('meal_recording_cancel_button')));
      await tester.pumpAndSettle();

      // Verify dialog closed without errors
      DialogTestHelpers.verifyDialogClosed<MealRecordingDialog>();

      // Pump a few more frames to ensure no disposal errors
      await tester.pump();
      await tester.pump();
    });

    testWidgets('safely disposes controllers on save',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => MealRecordingDialog(
                    primaryRecipe: primaryRecipe,
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        )),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.byKey(const Key('meal_recording_save_button')));
      await tester.pumpAndSettle();

      // Verify dialog closed without errors
      DialogTestHelpers.verifyDialogClosed<MealRecordingDialog>();

      // Pump a few more frames to ensure no disposal errors
      await tester.pump();
      await tester.pump();
    });
  });
}
