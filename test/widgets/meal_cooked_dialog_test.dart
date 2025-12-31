// test/widgets/meal_cooked_dialog_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/widgets/meal_cooked_dialog.dart';
import '../helpers/dialog_test_helpers.dart';
import '../test_utils/dialog_fixtures.dart';
import '../test_utils/test_setup.dart';

void main() {
  group('MealCookedDialog', () {
    group('Initial State & Display', () {
      testWidgets('opens with correct initial state', (WidgetTester tester) async {
      final testRecipe = DialogFixtures.createTestRecipe();
      final plannedDate = DateTime(2025, 1, 15, 18, 0);

      await DialogTestHelpers.openDialog(
        tester,
        dialogBuilder: (context) => MealCookedDialog(
          recipe: testRecipe,
          plannedDate: plannedDate,
        ),
      );

      // Verify dialog title includes recipe name
      expect(find.textContaining(testRecipe.name), findsOneWidget);

      // Verify servings field exists and has default value
      final servingsField = find.byKey(const Key('meal_cooked_servings_field'));
      expect(servingsField, findsOneWidget);

      // Verify prep time field exists
      final prepTimeField = find.byKey(const Key('meal_cooked_prep_time_field'));
      expect(prepTimeField, findsOneWidget);

      // Verify cook time field exists
      final cookTimeField = find.byKey(const Key('meal_cooked_cook_time_field'));
      expect(cookTimeField, findsOneWidget);

      // Verify success switch exists and is on by default
      final successSwitch = find.byKey(const Key('meal_cooked_success_switch'));
      expect(successSwitch, findsOneWidget);
      final switchWidget = tester.widget<Switch>(successSwitch);
      expect(switchWidget.value, isTrue);

      // Verify notes field exists
      final notesField = find.byKey(const Key('meal_cooked_notes_field'));
      expect(notesField, findsOneWidget);
    });

    testWidgets('pre-fills with recipe expected prep and cook times',
        (WidgetTester tester) async {
      final testRecipe = DialogFixtures.createTestRecipe(
        prepTimeMinutes: 15,
        cookTimeMinutes: 30,
      );
      final plannedDate = DateTime(2025, 1, 15, 18, 0);

      await DialogTestHelpers.openDialog(
        tester,
        dialogBuilder: (context) => MealCookedDialog(
          recipe: testRecipe,
          plannedDate: plannedDate,
        ),
      );

      // Verify prep time is pre-filled with recipe value
      final prepTimeField = find.byKey(const Key('meal_cooked_prep_time_field'));
      final prepTimeWidget = tester.widget<TextFormField>(prepTimeField);
      expect(prepTimeWidget.controller!.text, equals('15'));

      // Verify cook time is pre-filled with recipe value
      final cookTimeField = find.byKey(const Key('meal_cooked_cook_time_field'));
      final cookTimeWidget = tester.widget<TextFormField>(cookTimeField);
      expect(cookTimeWidget.controller!.text, equals('30'));
      });
    });

    group('Return Value Testing', () {
      testWidgets('returns correct cooking details on save',
        (WidgetTester tester) async {
      final testRecipe = DialogFixtures.createTestRecipe(
        prepTimeMinutes: 15,
        cookTimeMinutes: 30,
      );
      final plannedDate = DateTime(2025, 1, 15, 18, 0);

      final result = await DialogTestHelpers.openDialogAndCapture<Map<String, dynamic>>(
        tester,
        dialogBuilder: (context) => MealCookedDialog(
          recipe: testRecipe,
          plannedDate: plannedDate,
        ),
      );

      // Fill in servings
      await tester.enterText(
        find.byKey(const Key('meal_cooked_servings_field')),
        '4',
      );
      await tester.pumpAndSettle();

      // Fill in notes
      await tester.enterText(
        find.byKey(const Key('meal_cooked_notes_field')),
        'Delicious meal!',
      );
      await tester.pumpAndSettle();

      // Modify prep time
      await tester.enterText(
        find.byKey(const Key('meal_cooked_prep_time_field')),
        '20',
      );
      await tester.pumpAndSettle();

      // Modify cook time
      await tester.enterText(
        find.byKey(const Key('meal_cooked_cook_time_field')),
        '35',
      );
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      // Verify return value
      expect(result.hasValue, isTrue);
      expect(result.value, isNotNull);
      expect(result.value!['servings'], equals(4));
      expect(result.value!['notes'], equals('Delicious meal!'));
      expect(result.value!['wasSuccessful'], isTrue);
      expect(result.value!['actualPrepTime'], equals(20.0));
      expect(result.value!['actualCookTime'], equals(35.0));
      expect(result.value!['cookedAt'], isA<DateTime>());
    });

    testWidgets('notes field preserves user input',
        (WidgetTester tester) async {
      final testRecipe = DialogFixtures.createTestRecipe();
      final plannedDate = DateTime(2025, 1, 15, 18, 0);

      final result = await DialogTestHelpers.openDialogAndCapture<Map<String, dynamic>>(
        tester,
        dialogBuilder: (context) => MealCookedDialog(
          recipe: testRecipe,
          plannedDate: plannedDate,
        ),
      );

      // Enter notes with special characters
      const testNotes = 'Very tasty! Added extra garlic & herbs. Would cook again 👍';
      await tester.enterText(
        find.byKey(const Key('meal_cooked_notes_field')),
        testNotes,
      );
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      // Verify notes are preserved
      expect(result.hasValue, isTrue);
      expect(result.value!['notes'], equals(testNotes));
    });

    testWidgets('wasSuccessful switch toggles correctly',
        (WidgetTester tester) async {
      final testRecipe = DialogFixtures.createTestRecipe();
      final plannedDate = DateTime(2025, 1, 15, 18, 0);

      final result = await DialogTestHelpers.openDialogAndCapture<Map<String, dynamic>>(
        tester,
        dialogBuilder: (context) => MealCookedDialog(
          recipe: testRecipe,
          plannedDate: plannedDate,
        ),
      );

      // Verify switch starts as true
      final successSwitch = find.byKey(const Key('meal_cooked_success_switch'));
      expect(successSwitch, findsOneWidget);
      Switch switchWidget = tester.widget<Switch>(successSwitch);
      expect(switchWidget.value, isTrue);

      // Toggle switch to false
      await tester.tap(successSwitch);
      await tester.pumpAndSettle();

      // Verify switch changed to false
      switchWidget = tester.widget<Switch>(successSwitch);
      expect(switchWidget.value, isFalse);

      // Save
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      // Verify wasSuccessful is false in return value
      expect(result.hasValue, isTrue);
      expect(result.value!['wasSuccessful'], isFalse);
      });
    });

    group('Input Validation', () {
      testWidgets('validates servings input',
        (WidgetTester tester) async {
      final testRecipe = DialogFixtures.createTestRecipe();
      final plannedDate = DateTime(2025, 1, 15, 18, 0);

      await DialogTestHelpers.openDialog(
        tester,
        dialogBuilder: (context) => MealCookedDialog(
          recipe: testRecipe,
          plannedDate: plannedDate,
        ),
      );

      final servingsField = find.byKey(const Key('meal_cooked_servings_field'));

      // Test empty servings
      await tester.enterText(servingsField, '');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Por favor, informe o número de porções'), findsOneWidget);
      expect(find.byType(MealCookedDialog), findsOneWidget); // Dialog still open

      // Test invalid number (zero)
      await tester.enterText(servingsField, '0');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Por favor, informe um número válido'), findsOneWidget);
      expect(find.byType(MealCookedDialog), findsOneWidget); // Dialog still open

      // Test invalid input (non-numeric)
      await tester.enterText(servingsField, 'abc');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Por favor, informe um número válido'), findsOneWidget);
      expect(find.byType(MealCookedDialog), findsOneWidget); // Dialog still open

      // Test valid servings
      await tester.enterText(servingsField, '4');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      // Dialog should close successfully
      expect(find.byType(MealCookedDialog), findsNothing);
    });

    testWidgets('validates prep time input',
        (WidgetTester tester) async {
      final testRecipe = DialogFixtures.createTestRecipe();
      final plannedDate = DateTime(2025, 1, 15, 18, 0);

      await DialogTestHelpers.openDialog(
        tester,
        dialogBuilder: (context) => MealCookedDialog(
          recipe: testRecipe,
          plannedDate: plannedDate,
        ),
      );

      final prepTimeField = find.byKey(const Key('meal_cooked_prep_time_field'));

      // Test negative prep time
      await tester.enterText(prepTimeField, '-5');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Informe um tempo válido'), findsOneWidget);
      expect(find.byType(MealCookedDialog), findsOneWidget); // Dialog still open

      // Test invalid input (non-numeric)
      await tester.enterText(prepTimeField, 'abc');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Informe um tempo válido'), findsOneWidget);
      expect(find.byType(MealCookedDialog), findsOneWidget); // Dialog still open

      // Test empty (should be valid - optional field)
      await tester.enterText(prepTimeField, '');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      // Dialog should close successfully
      expect(find.byType(MealCookedDialog), findsNothing);
    });

    testWidgets('validates cook time input',
        (WidgetTester tester) async {
      final testRecipe = DialogFixtures.createTestRecipe();
      final plannedDate = DateTime(2025, 1, 15, 18, 0);

      await DialogTestHelpers.openDialog(
        tester,
        dialogBuilder: (context) => MealCookedDialog(
          recipe: testRecipe,
          plannedDate: plannedDate,
        ),
      );

      final cookTimeField = find.byKey(const Key('meal_cooked_cook_time_field'));

      // Test negative cook time
      await tester.enterText(cookTimeField, '-10');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Informe um tempo válido'), findsOneWidget);
      expect(find.byType(MealCookedDialog), findsOneWidget); // Dialog still open

      // Test invalid input (non-numeric)
      await tester.enterText(cookTimeField, 'xyz');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Informe um tempo válido'), findsOneWidget);
      expect(find.byType(MealCookedDialog), findsOneWidget); // Dialog still open

      // Test empty (should be valid - optional field)
      await tester.enterText(cookTimeField, '');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      // Dialog should close successfully
      expect(find.byType(MealCookedDialog), findsNothing);
      });
    });

    group('Cancellation & Side Effects', () {
      testWidgets('returns null when cancelled',
        (WidgetTester tester) async {
      final testRecipe = DialogFixtures.createTestRecipe();
      final plannedDate = DateTime(2025, 1, 15, 18, 0);

      final result = await DialogTestHelpers.openDialogAndCapture<Map<String, dynamic>>(
        tester,
        dialogBuilder: (context) => MealCookedDialog(
          recipe: testRecipe,
          plannedDate: plannedDate,
        ),
      );

      // Cancel dialog
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // Verify cancellation
      DialogTestHelpers.verifyDialogCancelled(result);
      DialogTestHelpers.verifyDialogClosed<MealCookedDialog>();
    });

    testWidgets('no database side effects on cancel',
        (WidgetTester tester) async {
      final mockDbHelper = TestSetup.setupMockDatabase();
      final testRecipe = DialogFixtures.createTestRecipe();
      final plannedDate = DateTime(2025, 1, 15, 18, 0);

      // Add recipe to database
      mockDbHelper.recipes[testRecipe.id] = testRecipe;

      await DialogTestHelpers.openDialog(
        tester,
        dialogBuilder: (context) => MealCookedDialog(
          recipe: testRecipe,
          plannedDate: plannedDate,
        ),
      );

      // Fill in some data
      await tester.enterText(
        find.byKey(const Key('meal_cooked_servings_field')),
        '4',
      );
      await tester.enterText(
        find.byKey(const Key('meal_cooked_notes_field')),
        'Test notes',
      );
      await tester.pumpAndSettle();

      // Verify no side effects when cancelling
      await DialogTestHelpers.verifyNoSideEffects(
        mockDbHelper,
        beforeAction: () async {
          await tester.tap(find.text('Cancelar'));
          await tester.pumpAndSettle();
        },
      );

      TestSetup.cleanupMockDatabase(mockDbHelper);
      });
    });

    group('Controller Disposal (Regression)', () {
      testWidgets('safely disposes controllers on cancel',
        (WidgetTester tester) async {
      final testRecipe = DialogFixtures.createTestRecipe(
        prepTimeMinutes: 15,
        cookTimeMinutes: 30,
      );
      final plannedDate = DateTime(2025, 1, 15, 18, 0);

      await DialogTestHelpers.openDialog(
        tester,
        dialogBuilder: (context) => MealCookedDialog(
          recipe: testRecipe,
          plannedDate: plannedDate,
        ),
      );

      // Interact with fields to initialize controllers
      await tester.enterText(
        find.byKey(const Key('meal_cooked_servings_field')),
        '3',
      );
      await tester.enterText(
        find.byKey(const Key('meal_cooked_notes_field')),
        'Test notes',
      );
      await tester.pump();

      // Cancel dialog
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // If controller disposal is broken, this will throw
      // No assertion needed - test passes if no crash occurs
    });

    testWidgets('handles rapid open/close cycles',
        (WidgetTester tester) async {
      final testRecipe = DialogFixtures.createTestRecipe(
        prepTimeMinutes: 15,
        cookTimeMinutes: 30,
      );
      final plannedDate = DateTime(2025, 1, 15, 18, 0);

      // Open and close dialog 5 times rapidly
      for (int i = 0; i < 5; i++) {
        await DialogTestHelpers.openDialog(
          tester,
          dialogBuilder: (context) => MealCookedDialog(
            recipe: testRecipe,
            plannedDate: plannedDate,
          ),
        );

        // Interact with a field
        await tester.enterText(
          find.byKey(const Key('meal_cooked_servings_field')),
          '${i + 1}',
        );
        await tester.pump();

        // Cancel dialog
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
      }

      // Test passes if no crash occurs during repeated cycles
    });
    });

    group('Alternative Dismissal Methods', () {
      testWidgets('tapping outside dialog dismisses and returns null',
          (WidgetTester tester) async {
        final testRecipe = DialogFixtures.createTestRecipe();
        final plannedDate = DateTime(2025, 1, 15, 18, 0);

        final result = await DialogTestHelpers.openDialogAndCapture<Map<String, dynamic>>(
          tester,
          dialogBuilder: (context) => MealCookedDialog(
            recipe: testRecipe,
            plannedDate: plannedDate,
          ),
        );

        // Fill in some data
        await tester.enterText(
          find.byKey(const Key('meal_cooked_servings_field')),
          '3',
        );
        await tester.pumpAndSettle();

        // Tap outside dialog to dismiss
        await DialogTestHelpers.tapOutsideDialog(tester);
        await tester.pumpAndSettle();

        // Verify dialog was dismissed and returned null
        DialogTestHelpers.verifyDialogCancelled(result);
        DialogTestHelpers.verifyDialogClosed<MealCookedDialog>();
      });

      testWidgets('back button dismisses and returns null',
          (WidgetTester tester) async {
        final testRecipe = DialogFixtures.createTestRecipe();
        final plannedDate = DateTime(2025, 1, 15, 18, 0);

        final result = await DialogTestHelpers.openDialogAndCapture<Map<String, dynamic>>(
          tester,
          dialogBuilder: (context) => MealCookedDialog(
            recipe: testRecipe,
            plannedDate: plannedDate,
          ),
        );

        // Fill in some data
        await tester.enterText(
          find.byKey(const Key('meal_cooked_servings_field')),
          '2',
        );
        await tester.pumpAndSettle();

        // Press back button to dismiss
        await DialogTestHelpers.pressBackButton(tester);
        await tester.pumpAndSettle();

        // Verify dialog was dismissed and returned null
        DialogTestHelpers.verifyDialogCancelled(result);
        DialogTestHelpers.verifyDialogClosed<MealCookedDialog>();
      });
    });
  });
}
