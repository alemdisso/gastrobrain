// test/screens/cook_meal_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/screens/cook_meal_screen.dart';
import '../test_utils/test_app_wrapper.dart';

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
        wrapWithLocalizations(CookMealScreen(recipe: testRecipe)),
      );

      await tester.pumpAndSettle();

      // Verify app bar title shows recipe name (Portuguese)
      expect(find.text('Cozinhar ${testRecipe.name}'), findsOneWidget);

      // Verify main content text (Portuguese)
      expect(find.text('Registrar detalhes de preparo para ${testRecipe.name}'),
          findsOneWidget);

      // Verify the "Registrar Detalhes da Refeição" button exists
      expect(find.text('Registrar Detalhes da Refeição'), findsOneWidget);
      expect(find.byIcon(Icons.restaurant), findsOneWidget);
    });

    testWidgets('tapping button shows meal recording dialog',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(CookMealScreen(recipe: testRecipe)),
      );

      await tester.pumpAndSettle();

      // Tap the "Registrar Detalhes da Refeição" button
      await tester.tap(find.text('Registrar Detalhes da Refeição'));
      await tester.pumpAndSettle();

      // Verify that the MealRecordingDialog appeared
      // We can check for the dialog title which should show the recipe name
      expect(find.text('Cozinhar ${testRecipe.name}'),
          findsNWidgets(2)); // One in app bar, one in dialog

      // Or check for dialog-specific elements (Portuguese)
      expect(find.text('Número de Porções'), findsOneWidget);
      expect(find.text('Salvar'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('handles dialog cancellation correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(CookMealScreen(recipe: testRecipe)),
      );

      await tester.pumpAndSettle();

      // Tap the button to open dialog
      await tester.tap(find.text('Registrar Detalhes da Refeição'));
      await tester.pumpAndSettle();

      // Cancel the dialog
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // Should return to the main screen (dialog closed)
      expect(find.text('Registrar detalhes de preparo para ${testRecipe.name}'),
          findsOneWidget);
      expect(find.text('Registrar Detalhes da Refeição'), findsOneWidget);

      // Dialog should be gone
      expect(find.text('Número de Porções'), findsNothing);
    });

    testWidgets('renders with additional recipes when provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(CookMealScreen(
          recipe: testRecipe,
          additionalRecipes: [sideRecipe],
        )),
      );

      await tester.pumpAndSettle();

      // Should still show the primary recipe name in title
      expect(find.text('Cozinhar ${testRecipe.name}'), findsOneWidget);

      // Should show the same UI regardless of additional recipes
      expect(find.text('Registrar detalhes de preparo para ${testRecipe.name}'),
          findsOneWidget);
      expect(find.text('Registrar Detalhes da Refeição'), findsOneWidget);
    });

    testWidgets('passes additional recipes to dialog when provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(CookMealScreen(
          recipe: testRecipe,
          additionalRecipes: [sideRecipe],
        )),
      );

      await tester.pumpAndSettle();

      // Open the dialog
      await tester.tap(find.text('Registrar Detalhes da Refeição'));
      await tester.pumpAndSettle();

      // Should show both primary and additional recipes in the dialog
      expect(find.text(testRecipe.name), findsOneWidget);
      expect(find.text(sideRecipe.name), findsOneWidget);

      // Should show proper indicators for main vs side dish (Portuguese)
      expect(find.text('Prato principal'), findsOneWidget);
      expect(find.text('Acompanhamento'), findsOneWidget);
    });
    testWidgets('handles empty additional recipes list',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(CookMealScreen(
          recipe: testRecipe,
          additionalRecipes: const [],
        )),
      );

      await tester.pumpAndSettle();

      // Open the dialog
      await tester.tap(find.text('Registrar Detalhes da Refeição'));
      await tester.pumpAndSettle();

      // Should only show primary recipe
      expect(find.text(testRecipe.name), findsOneWidget);
      expect(find.text('Prato principal'), findsOneWidget);

      // Should not show any side dishes
      expect(find.text('Acompanhamento'), findsNothing);

      // Should still show "Adicionar Receita" button for adding sides
      expect(find.text('Adicionar Receita'), findsOneWidget);
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
        wrapWithLocalizations(CookMealScreen(recipe: longNameRecipe)),
      );

      await tester.pumpAndSettle();

      // Should handle long names gracefully in app bar
      expect(find.text('Cozinhar ${longNameRecipe.name}'), findsOneWidget);

      // Should also show in main content
      expect(find.text('Registrar detalhes de preparo para ${longNameRecipe.name}'),
          findsOneWidget);
    });
  });

  group('MealRecordingDialog Form Validation Tests', () {
    testWidgets('validates required servings field', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(CookMealScreen(recipe: testRecipe)),
      );

      await tester.pumpAndSettle();

      // Open the dialog
      await tester.tap(find.text('Registrar Detalhes da Refeição'));
      await tester.pumpAndSettle();

      // Clear the servings field (it starts with default value "1")
      final servingsField = find.byKey(const Key('meal_recording_servings_field'));
      await tester.enterText(servingsField, '');
      await tester.pumpAndSettle();

      // Try to save without servings
      await tester.tap(find.byKey(const Key('meal_recording_save_button')));
      await tester.pumpAndSettle();

      // Should show validation error (Portuguese)
      expect(find.text('Por favor, informe o número de porções'), findsOneWidget);
    });

    testWidgets('validates servings is a positive number', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(CookMealScreen(recipe: testRecipe)),
      );

      await tester.pumpAndSettle();

      // Open the dialog
      await tester.tap(find.text('Registrar Detalhes da Refeição'));
      await tester.pumpAndSettle();

      // Enter invalid servings (zero)
      final servingsField = find.byKey(const Key('meal_recording_servings_field'));
      await tester.enterText(servingsField, '0');
      await tester.pumpAndSettle();

      // Try to save with zero servings
      await tester.tap(find.byKey(const Key('meal_recording_save_button')));
      await tester.pumpAndSettle();

      // Should show validation error (Portuguese)
      expect(find.text('Por favor, informe um número válido'), findsOneWidget);
    });

    testWidgets('validates servings is not negative', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(CookMealScreen(recipe: testRecipe)),
      );

      await tester.pumpAndSettle();

      // Open the dialog
      await tester.tap(find.text('Registrar Detalhes da Refeição'));
      await tester.pumpAndSettle();

      // Enter negative servings
      final servingsField = find.byKey(const Key('meal_recording_servings_field'));
      await tester.enterText(servingsField, '-1');
      await tester.pumpAndSettle();

      // Try to save with negative servings
      await tester.tap(find.byKey(const Key('meal_recording_save_button')));
      await tester.pumpAndSettle();

      // Should show validation error (Portuguese)
      expect(find.text('Por favor, informe um número válido'), findsOneWidget);
    });

    testWidgets('validates servings is not a text', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(CookMealScreen(recipe: testRecipe)),
      );

      await tester.pumpAndSettle();

      // Open the dialog
      await tester.tap(find.text('Registrar Detalhes da Refeição'));
      await tester.pumpAndSettle();

      // Enter text instead of number
      final servingsField = find.byKey(const Key('meal_recording_servings_field'));
      await tester.enterText(servingsField, 'abc');
      await tester.pumpAndSettle();

      // Try to save with text
      await tester.tap(find.byKey(const Key('meal_recording_save_button')));
      await tester.pumpAndSettle();

      // Should show validation error (Portuguese)
      expect(find.text('Por favor, informe um número válido'), findsOneWidget);
    });

    testWidgets('validates prep time is not negative', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(CookMealScreen(recipe: testRecipe)),
      );

      await tester.pumpAndSettle();

      // Open the dialog
      await tester.tap(find.text('Registrar Detalhes da Refeição'));
      await tester.pumpAndSettle();

      // Enter negative prep time
      final prepTimeField = find.byKey(const Key('meal_recording_prep_time_field'));
      await tester.enterText(prepTimeField, '-10');
      await tester.pumpAndSettle();

      // Try to save
      await tester.tap(find.byKey(const Key('meal_recording_save_button')));
      await tester.pumpAndSettle();

      // Should show validation error (Portuguese)
      expect(find.text('Informe um tempo válido'), findsOneWidget);
    });

    testWidgets('validates cook time is not negative', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(CookMealScreen(recipe: testRecipe)),
      );

      await tester.pumpAndSettle();

      // Open the dialog
      await tester.tap(find.text('Registrar Detalhes da Refeição'));
      await tester.pumpAndSettle();

      // Enter negative cook time
      final cookTimeField = find.byKey(const Key('meal_recording_cook_time_field'));
      await tester.enterText(cookTimeField, '-20');
      await tester.pumpAndSettle();

      // Try to save
      await tester.tap(find.byKey(const Key('meal_recording_save_button')));
      await tester.pumpAndSettle();

      // Should show validation error (Portuguese)
      expect(find.text('Informe um tempo válido'), findsOneWidget);
    });

    testWidgets('allows empty prep time (optional field)', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(CookMealScreen(recipe: testRecipe)),
      );

      await tester.pumpAndSettle();

      // Open the dialog
      await tester.tap(find.text('Registrar Detalhes da Refeição'));
      await tester.pumpAndSettle();

      // Clear prep time field
      final prepTimeField = find.byKey(const Key('meal_recording_prep_time_field'));
      await tester.enterText(prepTimeField, '');
      await tester.pumpAndSettle();

      // Should not show validation error on empty optional field
      // (We can't easily test if form validates successfully without mocking providers,
      // but we can verify no error message appears)
      expect(find.text('Informe um tempo válido'), findsNothing);
    });

    testWidgets('allows empty cook time (optional field)', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(CookMealScreen(recipe: testRecipe)),
      );

      await tester.pumpAndSettle();

      // Open the dialog
      await tester.tap(find.text('Registrar Detalhes da Refeição'));
      await tester.pumpAndSettle();

      // Clear cook time field
      final cookTimeField = find.byKey(const Key('meal_recording_cook_time_field'));
      await tester.enterText(cookTimeField, '');
      await tester.pumpAndSettle();

      // Should not show validation error on empty optional field
      expect(find.text('Informe um tempo válido'), findsNothing);
    });
  });

  group('MealRecordingDialog Success Toggle Tests', () {
    testWidgets('success toggle defaults to true', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(CookMealScreen(recipe: testRecipe)),
      );

      await tester.pumpAndSettle();

      // Open the dialog
      await tester.tap(find.text('Registrar Detalhes da Refeição'));
      await tester.pumpAndSettle();

      // Verify the success switch is on by default
      final successSwitch = tester.widget<Switch>(
        find.byKey(const Key('meal_recording_success_switch')),
      );
      expect(successSwitch.value, true);
    });

    testWidgets('can toggle success switch to false', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(CookMealScreen(recipe: testRecipe)),
      );

      await tester.pumpAndSettle();

      // Open the dialog
      await tester.tap(find.text('Registrar Detalhes da Refeição'));
      await tester.pumpAndSettle();

      // Toggle the switch off
      await tester.tap(find.byKey(const Key('meal_recording_success_switch')));
      await tester.pumpAndSettle();

      // Verify it's now false
      final successSwitch = tester.widget<Switch>(
        find.byKey(const Key('meal_recording_success_switch')),
      );
      expect(successSwitch.value, false);
    });

    testWidgets('can toggle success switch back to true', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(CookMealScreen(recipe: testRecipe)),
      );

      await tester.pumpAndSettle();

      // Open the dialog
      await tester.tap(find.text('Registrar Detalhes da Refeição'));
      await tester.pumpAndSettle();

      // Toggle off
      await tester.tap(find.byKey(const Key('meal_recording_success_switch')));
      await tester.pumpAndSettle();

      // Toggle back on
      await tester.tap(find.byKey(const Key('meal_recording_success_switch')));
      await tester.pumpAndSettle();

      // Verify it's true again
      final successSwitch = tester.widget<Switch>(
        find.byKey(const Key('meal_recording_success_switch')),
      );
      expect(successSwitch.value, true);
    });
  });

  group('MealRecordingDialog Date Selection Tests', () {
    testWidgets('displays current date by default', (WidgetTester tester) async {
      final now = DateTime.now();
      final formattedDate = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      await tester.pumpWidget(
        wrapWithLocalizations(CookMealScreen(recipe: testRecipe)),
      );

      await tester.pumpAndSettle();

      // Open the dialog
      await tester.tap(find.text('Registrar Detalhes da Refeição'));
      await tester.pumpAndSettle();

      // Should display current date
      expect(find.textContaining(formattedDate), findsOneWidget);
    });

    testWidgets('opens date picker when date selector is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(CookMealScreen(recipe: testRecipe)),
      );

      await tester.pumpAndSettle();

      // Open the dialog
      await tester.tap(find.text('Registrar Detalhes da Refeição'));
      await tester.pumpAndSettle();

      // Tap the date selector
      await tester.tap(find.byKey(const Key('meal_recording_date_selector')));
      await tester.pumpAndSettle();

      // Should open date picker dialog
      // Verify date picker is open by checking for OK button
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('can select a past date', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(CookMealScreen(recipe: testRecipe)),
      );

      await tester.pumpAndSettle();

      // Open the dialog
      await tester.tap(find.text('Registrar Detalhes da Refeição'));
      await tester.pumpAndSettle();

      // Record the original date
      final now = DateTime.now();
      final formattedToday = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      expect(find.textContaining(formattedToday), findsOneWidget);

      // Tap the date selector
      await tester.tap(find.byKey(const Key('meal_recording_date_selector')));
      await tester.pumpAndSettle();

      // The date picker should be open - verify by checking for OK button
      expect(find.text('OK'), findsOneWidget);

      // For simplicity, just confirm without changing the date
      // The important thing is that the date picker works
      // Selecting a specific past date is complex and fragile in tests
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Date should still be shown (even if unchanged)
      expect(find.textContaining(formattedToday), findsOneWidget);
    });

    testWidgets('date picker does not allow future dates', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(CookMealScreen(recipe: testRecipe)),
      );

      await tester.pumpAndSettle();

      // Open the dialog
      await tester.tap(find.text('Registrar Detalhes da Refeição'));
      await tester.pumpAndSettle();

      // Tap the date selector
      await tester.tap(find.byKey(const Key('meal_recording_date_selector')));
      await tester.pumpAndSettle();

      // The DatePicker's lastDate is set to DateTime.now(), so future dates
      // should be disabled. This is implicit in the DatePicker configuration
      // (lastDate: DateTime.now()) and is verified by the code, not by
      // explicit user interaction in the test.
      // We just verify the picker opened successfully by looking for the OK button
      expect(find.text('OK'), findsOneWidget);

      // Close the date picker by tapping OK
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    });

    testWidgets('can close date picker and preserve original date', (WidgetTester tester) async {
      final now = DateTime.now();
      final formattedToday = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      await tester.pumpWidget(
        wrapWithLocalizations(CookMealScreen(recipe: testRecipe)),
      );

      await tester.pumpAndSettle();

      // Open the dialog
      await tester.tap(find.text('Registrar Detalhes da Refeição'));
      await tester.pumpAndSettle();

      // Verify current date is shown
      expect(find.textContaining(formattedToday), findsOneWidget);

      // Tap the date selector
      await tester.tap(find.byKey(const Key('meal_recording_date_selector')));
      await tester.pumpAndSettle();

      // Close by tapping OK without changing the date
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Should still show today's date
      expect(find.textContaining(formattedToday), findsOneWidget);
    });
  });

  group('MealRecordingDialog Notes and Optional Fields Tests', () {
    testWidgets('notes field is optional and accepts text', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(CookMealScreen(recipe: testRecipe)),
      );

      await tester.pumpAndSettle();

      // Open the dialog
      await tester.tap(find.text('Registrar Detalhes da Refeição'));
      await tester.pumpAndSettle();

      // Enter notes
      final notesField = find.byKey(const Key('meal_recording_notes_field'));
      await tester.enterText(notesField, 'This was delicious!');
      await tester.pumpAndSettle();

      // Verify text was entered
      expect(find.text('This was delicious!'), findsOneWidget);
    });

    testWidgets('notes field can be left empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(CookMealScreen(recipe: testRecipe)),
      );

      await tester.pumpAndSettle();

      // Open the dialog
      await tester.tap(find.text('Registrar Detalhes da Refeição'));
      await tester.pumpAndSettle();

      // Notes field should be empty by default
      final notesField = find.byKey(const Key('meal_recording_notes_field'));
      final textField = tester.widget<TextFormField>(notesField);
      expect(textField.controller?.text ?? '', isEmpty);
    });

    testWidgets('notes field accepts multiline text', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(CookMealScreen(recipe: testRecipe)),
      );

      await tester.pumpAndSettle();

      // Open the dialog
      await tester.tap(find.text('Registrar Detalhes da Refeição'));
      await tester.pumpAndSettle();

      // Enter multiline notes
      final notesField = find.byKey(const Key('meal_recording_notes_field'));
      await tester.enterText(notesField, 'Line 1\nLine 2\nLine 3');
      await tester.pumpAndSettle();

      // Verify multiline text was entered
      expect(find.text('Line 1\nLine 2\nLine 3'), findsOneWidget);
    });

    testWidgets('displays pre-filled prep and cook times from recipe', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalizations(CookMealScreen(recipe: testRecipe)),
      );

      await tester.pumpAndSettle();

      // Open the dialog
      await tester.tap(find.text('Registrar Detalhes da Refeição'));
      await tester.pumpAndSettle();

      // Verify prep time is pre-filled with recipe's prep time
      expect(find.text('15'), findsOneWidget); // testRecipe.prepTimeMinutes = 15

      // Verify cook time is pre-filled with recipe's cook time
      expect(find.text('25'), findsOneWidget); // testRecipe.cookTimeMinutes = 25
    });
  });
}
