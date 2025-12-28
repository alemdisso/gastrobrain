// test/widgets/add_new_ingredient_dialog_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/widgets/add_new_ingredient_dialog.dart';
import 'package:gastrobrain/models/ingredient.dart';
import 'package:gastrobrain/models/ingredient_category.dart';
import 'package:gastrobrain/models/measurement_unit.dart';
import 'package:gastrobrain/models/protein_type.dart';
import '../helpers/dialog_test_helpers.dart';
import '../test_utils/test_setup.dart';

void main() {
  group('AddNewIngredientDialog', () {
    group('Initial State & Display', () {
      testWidgets('opens with empty form', (WidgetTester tester) async {
        final mockDbHelper = TestSetup.setupMockDatabase();

        await DialogTestHelpers.openDialog(
          tester,
          dialogBuilder: (context) => AddNewIngredientDialog(
            databaseHelper: mockDbHelper,
          ),
        );

        // Verify dialog title shows "new ingredient" (not "edit ingredient")
        expect(find.text('Novo Ingrediente'), findsOneWidget);

        // Verify name field exists and is empty
        final nameField =
            find.byKey(const Key('add_new_ingredient_name_field'));
        expect(nameField, findsOneWidget);
        final nameWidget = tester.widget<TextFormField>(nameField);
        expect(nameWidget.controller!.text, isEmpty);

        // Verify category dropdown exists (should have default value)
        final categoryField =
            find.byKey(const Key('add_new_ingredient_category_field'));
        expect(categoryField, findsOneWidget);

        // Verify unit dropdown exists
        final unitField =
            find.byKey(const Key('add_new_ingredient_unit_field'));
        expect(unitField, findsOneWidget);

        // Verify notes field exists and is empty
        final notesField =
            find.byKey(const Key('add_new_ingredient_notes_field'));
        expect(notesField, findsOneWidget);
        final notesWidget = tester.widget<TextFormField>(notesField);
        expect(notesWidget.controller!.text, isEmpty);

        // Verify protein type field is NOT shown (default category is vegetable, not protein)
        final proteinTypeField =
            find.byKey(const Key('add_new_ingredient_protein_type_field'));
        expect(proteinTypeField, findsNothing);

        // Verify save button exists
        expect(find.text('Salvar'), findsOneWidget);

        // Verify cancel button exists
        expect(find.text('Cancelar'), findsOneWidget);

        TestSetup.cleanupMockDatabase(mockDbHelper);
      });
    });

    group('Return Value Testing', () {
      testWidgets('returns created Ingredient on save',
          (WidgetTester tester) async {
        final mockDbHelper = TestSetup.setupMockDatabase();

        final result = await DialogTestHelpers.openDialogAndCapture<Ingredient>(
          tester,
          dialogBuilder: (context) => AddNewIngredientDialog(
            databaseHelper: mockDbHelper,
          ),
        );

        // Fill in ingredient name
        final nameField =
            find.byKey(const Key('add_new_ingredient_name_field'));
        await tester.enterText(nameField, 'Tomato');
        await tester.pumpAndSettle();

        // Select a unit (optional, but let's test it)
        final unitField =
            find.byKey(const Key('add_new_ingredient_unit_field'));
        await tester.tap(unitField);
        await tester.pumpAndSettle();

        // Select "g" unit
        await tester.tap(find.text('g').last);
        await tester.pumpAndSettle();

        // Add some notes
        final notesField =
            find.byKey(const Key('add_new_ingredient_notes_field'));
        await tester.enterText(notesField, 'Fresh and ripe');
        await tester.pumpAndSettle();

        // Save
        await tester.tap(find.text('Salvar'));
        await tester.pumpAndSettle();

        // Verify return value
        expect(result.hasValue, isTrue);
        expect(result.value, isNotNull);
        expect(result.value, isA<Ingredient>());
        expect(result.value!.name, equals('Tomato'));
        expect(result.value!.category,
            equals(IngredientCategory.vegetable)); // Default category
        expect(result.value!.unit, equals(MeasurementUnit.gram));
        expect(result.value!.notes, equals('Fresh and ripe'));
        expect(result.value!.proteinType, isNull); // Not a protein category

        TestSetup.cleanupMockDatabase(mockDbHelper);
      });
    });

    group('Input Validation', () {
      testWidgets('validates ingredient name is required',
          (WidgetTester tester) async {
        final mockDbHelper = TestSetup.setupMockDatabase();

        await DialogTestHelpers.openDialog(
          tester,
          dialogBuilder: (context) => AddNewIngredientDialog(
            databaseHelper: mockDbHelper,
          ),
        );

        // Try to save without entering a name
        await tester.tap(find.text('Salvar'));
        await tester.pumpAndSettle();

        // Should show validation error
        expect(find.text('Por favor, informe o nome do ingrediente'),
            findsOneWidget);

        // Dialog should still be open
        expect(find.byType(AddNewIngredientDialog), findsOneWidget);

        // Now enter a name and save should work
        final nameField =
            find.byKey(const Key('add_new_ingredient_name_field'));
        await tester.enterText(nameField, 'Onion');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Salvar'));
        await tester.pumpAndSettle();

        // Dialog should close successfully
        expect(find.byType(AddNewIngredientDialog), findsNothing);

        TestSetup.cleanupMockDatabase(mockDbHelper);
      });
    });

    group('Dropdown Functionality', () {
      testWidgets('category dropdown works correctly',
          (WidgetTester tester) async {
        final mockDbHelper = TestSetup.setupMockDatabase();

        final result = await DialogTestHelpers.openDialogAndCapture<Ingredient>(
          tester,
          dialogBuilder: (context) => AddNewIngredientDialog(
            databaseHelper: mockDbHelper,
          ),
        );

        // Fill in ingredient name
        final nameField =
            find.byKey(const Key('add_new_ingredient_name_field'));
        await tester.enterText(nameField, 'Rice');
        await tester.pumpAndSettle();

        // Tap category dropdown
        final categoryField =
            find.byKey(const Key('add_new_ingredient_category_field'));
        await tester.tap(categoryField);
        await tester.pumpAndSettle();

        // Select "Grão" (grain) category
        await tester.tap(find.text('Grão').last);
        await tester.pumpAndSettle();

        // Save
        await tester.tap(find.text('Salvar'));
        await tester.pumpAndSettle();

        // Verify the category was changed from default (vegetable) to grain
        expect(result.hasValue, isTrue);
        expect(result.value, isNotNull);
        expect(result.value!.category, equals(IngredientCategory.grain));
        expect(result.value!.name, equals('Rice'));

        TestSetup.cleanupMockDatabase(mockDbHelper);
      });

      testWidgets('unit dropdown works correctly', (WidgetTester tester) async {
        final mockDbHelper = TestSetup.setupMockDatabase();

        final result = await DialogTestHelpers.openDialogAndCapture<Ingredient>(
          tester,
          dialogBuilder: (context) => AddNewIngredientDialog(
            databaseHelper: mockDbHelper,
          ),
        );

        // Fill in ingredient name
        final nameField =
            find.byKey(const Key('add_new_ingredient_name_field'));
        await tester.enterText(nameField, 'Olive Oil');
        await tester.pumpAndSettle();

        // Tap unit dropdown
        final unitField =
            find.byKey(const Key('add_new_ingredient_unit_field'));
        await tester.tap(unitField);
        await tester.pumpAndSettle();

        // Select "ml" (milliliter) unit
        await tester.tap(find.text('ml').last);
        await tester.pumpAndSettle();

        // Save
        await tester.tap(find.text('Salvar'));
        await tester.pumpAndSettle();

        // Verify the unit was selected
        expect(result.hasValue, isTrue);
        expect(result.value, isNotNull);
        expect(result.value!.unit, equals(MeasurementUnit.milliliter));
        expect(result.value!.name, equals('Olive Oil'));

        TestSetup.cleanupMockDatabase(mockDbHelper);
      });

      testWidgets('protein type field shown only for protein category',
          (WidgetTester tester) async {
        final mockDbHelper = TestSetup.setupMockDatabase();

        final result = await DialogTestHelpers.openDialogAndCapture<Ingredient>(
          tester,
          dialogBuilder: (context) => AddNewIngredientDialog(
            databaseHelper: mockDbHelper,
          ),
        );

        // Initially, protein type field should NOT be shown (default category is vegetable)
        final proteinTypeField =
            find.byKey(const Key('add_new_ingredient_protein_type_field'));
        expect(proteinTypeField, findsNothing);

        // Fill in ingredient name
        final nameField =
            find.byKey(const Key('add_new_ingredient_name_field'));
        await tester.enterText(nameField, 'Chicken Breast');
        await tester.pumpAndSettle();

        // Change category to protein
        final categoryField =
            find.byKey(const Key('add_new_ingredient_category_field'));
        await tester.tap(categoryField);
        await tester.pumpAndSettle();

        // Select "Proteína" (protein) category
        await tester.tap(find.text('Proteína').last);
        await tester.pumpAndSettle();

        // Now protein type field SHOULD be shown
        expect(proteinTypeField, findsOneWidget);

        // Select a protein type
        await tester.tap(proteinTypeField);
        await tester.pumpAndSettle();

        // Select "Frango" (chicken)
        await tester.tap(find.text('Frango').last);
        await tester.pumpAndSettle();

        // Save
        await tester.tap(find.text('Salvar'));
        await tester.pumpAndSettle();

        // Verify the protein type was saved
        expect(result.hasValue, isTrue);
        expect(result.value, isNotNull);
        expect(result.value!.category, equals(IngredientCategory.protein));
        expect(result.value!.proteinType, equals(ProteinType.chicken));
        expect(result.value!.name, equals('Chicken Breast'));

        TestSetup.cleanupMockDatabase(mockDbHelper);
      });
    });

    group('Cancellation & Side Effects', () {
      testWidgets('returns null when cancelled',
          (WidgetTester tester) async {
        final mockDbHelper = TestSetup.setupMockDatabase();

        final result = await DialogTestHelpers.openDialogAndCapture<Ingredient>(
          tester,
          dialogBuilder: (context) => AddNewIngredientDialog(
            databaseHelper: mockDbHelper,
          ),
        );

        // Fill in some data
        final nameField =
            find.byKey(const Key('add_new_ingredient_name_field'));
        await tester.enterText(nameField, 'Garlic');
        await tester.pumpAndSettle();

        // Cancel dialog
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();

        // Verify cancellation
        DialogTestHelpers.verifyDialogCancelled(result);
        DialogTestHelpers.verifyDialogClosed<AddNewIngredientDialog>();

        TestSetup.cleanupMockDatabase(mockDbHelper);
      });

      testWidgets('saves ingredient to database',
          (WidgetTester tester) async {
        final mockDbHelper = TestSetup.setupMockDatabase();

        await DialogTestHelpers.openDialog(
          tester,
          dialogBuilder: (context) => AddNewIngredientDialog(
            databaseHelper: mockDbHelper,
          ),
        );

        // Fill in ingredient data
        final nameField =
            find.byKey(const Key('add_new_ingredient_name_field'));
        await tester.enterText(nameField, 'Bell Pepper');
        await tester.pumpAndSettle();

        // Select category
        final categoryField =
            find.byKey(const Key('add_new_ingredient_category_field'));
        await tester.tap(categoryField);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Vegetal').last);
        await tester.pumpAndSettle();

        // Select unit
        final unitField =
            find.byKey(const Key('add_new_ingredient_unit_field'));
        await tester.tap(unitField);
        await tester.pumpAndSettle();

        await tester.tap(find.text('g').last);
        await tester.pumpAndSettle();

        // Add notes
        final notesField =
            find.byKey(const Key('add_new_ingredient_notes_field'));
        await tester.enterText(notesField, 'Red or green');
        await tester.pumpAndSettle();

        // Save
        await tester.tap(find.text('Salvar'));
        await tester.pumpAndSettle();

        // Verify ingredient was saved to database
        expect(mockDbHelper.ingredients.length, equals(1));
        final savedIngredient = mockDbHelper.ingredients.values.first;
        expect(savedIngredient.name, equals('Bell Pepper'));
        expect(savedIngredient.category, equals(IngredientCategory.vegetable));
        expect(savedIngredient.unit, equals(MeasurementUnit.gram));
        expect(savedIngredient.notes, equals('Red or green'));
        expect(savedIngredient.proteinType, isNull);

        TestSetup.cleanupMockDatabase(mockDbHelper);
      });
    });

    group('Error Handling', () {
      testWidgets('shows error when save fails',
          (WidgetTester tester) async {
        final mockDbHelper = TestSetup.setupMockDatabase();

        // Configure mock to fail on insertIngredient
        mockDbHelper.failOnOperation('insertIngredient');

        await DialogTestHelpers.openDialog(
          tester,
          dialogBuilder: (context) => AddNewIngredientDialog(
            databaseHelper: mockDbHelper,
          ),
        );

        // Fill in ingredient data
        final nameField =
            find.byKey(const Key('add_new_ingredient_name_field'));
        await tester.enterText(nameField, 'Test Ingredient');
        await tester.pumpAndSettle();

        // Try to save
        await tester.tap(find.text('Salvar'));
        await tester.pumpAndSettle();

        // Should show error message in snackbar
        expect(find.textContaining('erro'), findsOneWidget);

        // Dialog should still be open (not closed on error)
        expect(find.byType(AddNewIngredientDialog), findsOneWidget);

        // Ingredient should NOT be saved to database
        expect(mockDbHelper.ingredients.length, equals(0));

        TestSetup.cleanupMockDatabase(mockDbHelper);
      });
    });
  });
}
