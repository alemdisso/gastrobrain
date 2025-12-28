// test/widgets/add_ingredient_dialog_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/widgets/add_ingredient_dialog.dart';
import 'package:gastrobrain/models/ingredient.dart';
import 'package:gastrobrain/models/recipe_ingredient.dart';
import '../mocks/mock_database_helper.dart';
import '../helpers/dialog_test_helpers.dart';
import '../test_utils/dialog_fixtures.dart';
import '../test_utils/test_setup.dart';

// Test to verify the dialog appears and basic functionality
void main() {
  group('AddIngredientDialog', () {
    testWidgets('Dialog opens and displays correctly',
        (WidgetTester tester) async {
      // Using DialogTestHelpers and DialogFixtures for cleaner test setup
      final testRecipe = DialogFixtures.createTestRecipe();

      await DialogTestHelpers.openDialog(
        tester,
        dialogBuilder: (context) => AddIngredientDialog(
          recipe: testRecipe,
        ),
      );

      // Verify the dialog appears with the expected title (Portuguese)
      expect(find.text('Adicionar Ingrediente'), findsOneWidget);
    });
  });

  // Tests with Dependency Injection using DialogFixtures and DialogTestHelpers
  group('AddIngredientDialog with Dependency Injection', () {
    late MockDatabaseHelper mockDbHelper;

    setUp(() {
      // Set up mock database using TestSetup utility
      mockDbHelper = TestSetup.setupMockDatabase();

      // Add test ingredients using DialogFixtures
      final ingredients = DialogFixtures.createMultipleIngredients();
      for (final ingredient in ingredients) {
        mockDbHelper.ingredients[ingredient.id] = ingredient;
      }
    });

    tearDown(() {
      TestSetup.cleanupMockDatabase(mockDbHelper);
    });

    testWidgets('loads ingredients from injected database',
        (WidgetTester tester) async {
      final testRecipe = DialogFixtures.createTestRecipe();

      await DialogTestHelpers.openDialog(
        tester,
        dialogBuilder: (context) => AddIngredientDialog(
          recipe: testRecipe,
          databaseHelper: mockDbHelper,
        ),
      );

      // Verify autocomplete field is present with ingredients loaded
      expect(find.byType(Autocomplete<Ingredient>), findsOneWidget);
    });

    testWidgets('shows autocomplete search field for database ingredients',
        (WidgetTester tester) async {
      final testRecipe = DialogFixtures.createTestRecipe();

      await DialogTestHelpers.openDialog(
        tester,
        dialogBuilder: (context) => AddIngredientDialog(
          recipe: testRecipe,
          databaseHelper: mockDbHelper,
        ),
      );

      // Verify autocomplete search field is shown
      expect(find.byType(Autocomplete<Ingredient>), findsOneWidget);

      // Verify search icon is present
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('shows progressive disclosure link for custom ingredient',
        (WidgetTester tester) async {
      final testRecipe = DialogFixtures.createTestRecipe();

      await DialogTestHelpers.openDialog(
        tester,
        dialogBuilder: (context) => AddIngredientDialog(
          recipe: testRecipe,
          databaseHelper: mockDbHelper,
        ),
      );

      // Verify progressive disclosure link is shown (Portuguese)
      expect(find.text('Usar ingrediente personalizado'), findsOneWidget);

      // Verify settings icon is present
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('unit dropdown is always visible for database ingredients',
        (WidgetTester tester) async {
      final testRecipe = DialogFixtures.createTestRecipe();

      await DialogTestHelpers.openDialog(
        tester,
        dialogBuilder: (context) => AddIngredientDialog(
          recipe: testRecipe,
          databaseHelper: mockDbHelper,
        ),
      );

      // Unit dropdown should be visible (finds at least one)
      expect(find.byType(DropdownButtonFormField<String>), findsWidgets);

      // Old checkbox should NOT be present
      expect(find.text('Substituir unidade padrão'), findsNothing);
      expect(find.byType(Checkbox), findsNothing);
    });

    testWidgets('no segmented button for database/custom toggle',
        (WidgetTester tester) async {
      final testRecipe = DialogFixtures.createTestRecipe();

      await DialogTestHelpers.openDialog(
        tester,
        dialogBuilder: (context) => AddIngredientDialog(
          recipe: testRecipe,
          databaseHelper: mockDbHelper,
        ),
      );

      // Verify SegmentedButton is NOT present
      expect(find.byType(SegmentedButton<bool>), findsNothing);

      // Old labels should not be present
      expect(find.text('Do Banco de Dados'), findsNothing);
      expect(find.text('Personalizado'), findsNothing);
    });
  });

  group('AddIngredientDialog - Return Value Testing', () {
    late MockDatabaseHelper mockDbHelper;
    late Ingredient testIngredient;

    setUp(() {
      mockDbHelper = TestSetup.setupMockDatabase();
      testIngredient = DialogFixtures.createProteinIngredient(
        id: 'test-ing-1',
        name: 'Chicken Breast',
      );
      mockDbHelper.insertIngredient(testIngredient);
    });

    tearDown(() {
      TestSetup.cleanupMockDatabase(mockDbHelper);
    });

    testWidgets('auto-selects ingredient on exact match with Enter key',
        (WidgetTester tester) async {
      final testRecipe = DialogFixtures.createTestRecipe();

      RecipeIngredient? savedIngredient;
      await DialogTestHelpers.openDialog(
        tester,
        dialogBuilder: (context) => AddIngredientDialog(
          recipe: testRecipe,
          databaseHelper: mockDbHelper,
          onSave: (ingredient) {
            savedIngredient = ingredient;
          },
        ),
      );

      // Wait for ingredients to load
      await tester.pumpAndSettle();

      // Enter quantity - use key to find the specific field
      final quantityField = find.byKey(const Key('add_ingredient_quantity_field'));
      await tester.enterText(quantityField, '500');
      await tester.pumpAndSettle();

      // Find the autocomplete search field
      final searchField = find.byKey(const Key('add_ingredient_search_field'));
      expect(searchField, findsOneWidget);

      // Type exact ingredient name
      await tester.enterText(searchField, 'Chicken Breast');
      await tester.pumpAndSettle();

      // Simulate pressing Enter/Done on keyboard
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Extra pumps to ensure setState completes
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Try to save
      await tester.tap(find.text('Adicionar'));
      await tester.pumpAndSettle();

      // Verify return value
      expect(savedIngredient, isNotNull);
      expect(savedIngredient!.recipeId, equals(testRecipe.id));
      expect(savedIngredient!.ingredientId, equals(testIngredient.id));
      expect(savedIngredient!.quantity, equals(500.0));
    });

    testWidgets('database ingredient selection with default unit returns correct RecipeIngredient',
        (WidgetTester tester) async {
      final testRecipe = DialogFixtures.createTestRecipe();

      RecipeIngredient? savedIngredient;
      await DialogTestHelpers.openDialog(
        tester,
        dialogBuilder: (context) => AddIngredientDialog(
          recipe: testRecipe,
          databaseHelper: mockDbHelper,
          onSave: (ingredient) {
            savedIngredient = ingredient;
          },
        ),
      );

      // Wait for ingredients to load
      await tester.pumpAndSettle();

      // Enter quantity
      final quantityField = find.byKey(const Key('add_ingredient_quantity_field'));
      await tester.enterText(quantityField, '250');
      await tester.pumpAndSettle();

      // Type exact ingredient name in search field
      final searchField = find.byKey(const Key('add_ingredient_search_field'));
      await tester.enterText(searchField, 'Chicken Breast');
      await tester.pumpAndSettle();

      // Simulate pressing Enter/Done to auto-select on exact match
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Extra pumps to ensure setState completes
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Save
      await tester.tap(find.text('Adicionar'));
      await tester.pumpAndSettle();

      // Verify return value
      expect(savedIngredient, isNotNull);
      expect(savedIngredient!.recipeId, equals(testRecipe.id));
      expect(savedIngredient!.ingredientId, equals(testIngredient.id));
      expect(savedIngredient!.quantity, equals(250.0));
      expect(savedIngredient!.unitOverride, isNull); // Using default unit
      expect(savedIngredient!.customName, isNull);
      expect(savedIngredient!.customCategory, isNull);
      expect(savedIngredient!.customUnit, isNull);
    });

    testWidgets('database ingredient selection with unit override returns correct RecipeIngredient',
        (WidgetTester tester) async {
      final testRecipe = DialogFixtures.createTestRecipe();

      RecipeIngredient? savedIngredient;
      await DialogTestHelpers.openDialog(
        tester,
        dialogBuilder: (context) => AddIngredientDialog(
          recipe: testRecipe,
          databaseHelper: mockDbHelper,
          onSave: (ingredient) {
            savedIngredient = ingredient;
          },
        ),
      );

      // Wait for ingredients to load
      await tester.pumpAndSettle();

      // Enter quantity
      final quantityField = find.byKey(const Key('add_ingredient_quantity_field'));
      await tester.enterText(quantityField, '3');
      await tester.pumpAndSettle();

      // Type exact ingredient name in search field
      final searchField = find.byKey(const Key('add_ingredient_search_field'));
      await tester.enterText(searchField, 'Chicken Breast');
      await tester.pumpAndSettle();

      // Simulate pressing Enter/Done to auto-select on exact match
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Extra pumps to ensure setState completes
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Change unit from default
      final unitField = find.byKey(const Key('add_ingredient_unit_field'));
      await tester.tap(unitField);
      await tester.pumpAndSettle();

      // Select a different unit (cup)
      await tester.tap(find.text('Xícara').last);
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Adicionar'));
      await tester.pumpAndSettle();

      // Verify return value
      expect(savedIngredient, isNotNull);
      expect(savedIngredient!.recipeId, equals(testRecipe.id));
      expect(savedIngredient!.ingredientId, equals(testIngredient.id));
      expect(savedIngredient!.quantity, equals(3.0));
      expect(savedIngredient!.unitOverride, equals('cup')); // Changed from default
    });

    testWidgets('database ingredient with notes returns RecipeIngredient with notes field',
        (WidgetTester tester) async {
      final testRecipe = DialogFixtures.createTestRecipe();

      RecipeIngredient? savedIngredient;
      await DialogTestHelpers.openDialog(
        tester,
        dialogBuilder: (context) => AddIngredientDialog(
          recipe: testRecipe,
          databaseHelper: mockDbHelper,
          onSave: (ingredient) {
            savedIngredient = ingredient;
          },
        ),
      );

      // Wait for ingredients to load
      await tester.pumpAndSettle();

      // Enter quantity
      final quantityField = find.byKey(const Key('add_ingredient_quantity_field'));
      await tester.enterText(quantityField, '200');
      await tester.pumpAndSettle();

      // Type exact ingredient name in search field
      final searchField = find.byKey(const Key('add_ingredient_search_field'));
      await tester.enterText(searchField, 'Chicken Breast');
      await tester.pumpAndSettle();

      // Simulate pressing Enter/Done to auto-select on exact match
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Extra pumps to ensure setState completes
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Add notes
      final notesField = find.byKey(const Key('add_ingredient_notes_field'));
      await tester.enterText(notesField, 'Cut into cubes');
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Adicionar'));
      await tester.pumpAndSettle();

      // Verify return value includes notes
      expect(savedIngredient, isNotNull);
      expect(savedIngredient!.notes, equals('Cut into cubes'));
    });

    testWidgets('custom ingredient creation returns correct RecipeIngredient object',
        (WidgetTester tester) async {
      final testRecipe = DialogFixtures.createTestRecipe();

      RecipeIngredient? savedIngredient;
      await DialogTestHelpers.openDialog(
        tester,
        dialogBuilder: (context) => AddIngredientDialog(
          recipe: testRecipe,
          databaseHelper: mockDbHelper,
          onSave: (ingredient) {
            savedIngredient = ingredient;
          },
        ),
      );

      // Wait for ingredients to load
      await tester.pumpAndSettle();

      // Switch to custom ingredient mode
      await tester.tap(find.text('Usar ingrediente personalizado'));
      await tester.pumpAndSettle();

      // Fill custom ingredient name
      final customNameField = find.byKey(const Key('add_ingredient_custom_name_field'));
      await tester.enterText(customNameField, 'Special Spice Mix');
      await tester.pumpAndSettle();

      // Select category
      final categoryField = find.byKey(const Key('add_ingredient_custom_category_field'));
      await tester.tap(categoryField);
      await tester.pumpAndSettle();

      // Select "Tempero" (seasoning)
      await tester.tap(find.text('Tempero').last);
      await tester.pumpAndSettle();

      // Enter quantity
      final quantityField = find.byKey(const Key('add_ingredient_quantity_field'));
      await tester.enterText(quantityField, '2');
      await tester.pumpAndSettle();

      // Select unit
      final unitField = find.byKey(const Key('add_ingredient_custom_unit_field'));
      await tester.tap(unitField);
      await tester.pumpAndSettle();

      // Select "Colher de sopa" (tablespoon)
      await tester.tap(find.text('Colher de sopa').last);
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Adicionar'));
      await tester.pumpAndSettle();

      // Verify return value
      expect(savedIngredient, isNotNull);
      expect(savedIngredient!.recipeId, equals(testRecipe.id));
      expect(savedIngredient!.ingredientId, isNull); // Custom ingredient has no DB reference
      expect(savedIngredient!.quantity, equals(2.0));
      expect(savedIngredient!.customName, equals('Special Spice Mix'));
      expect(savedIngredient!.customCategory, equals('seasoning'));
      expect(savedIngredient!.customUnit, equals('tbsp')); // Stored value, not display name
      expect(savedIngredient!.unitOverride, isNull); // Not used for custom ingredients
    });

    testWidgets('returns null when cancelled',
        (WidgetTester tester) async {
      final testRecipe = DialogFixtures.createTestRecipe();

      final result = await DialogTestHelpers.openDialogAndCapture<RecipeIngredient>(
        tester,
        dialogBuilder: (context) => AddIngredientDialog(
          recipe: testRecipe,
          databaseHelper: mockDbHelper,
        ),
      );

      // Wait for ingredients to load
      await tester.pumpAndSettle();

      // Cancel dialog
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // Verify cancellation
      DialogTestHelpers.verifyDialogCancelled(result);
      DialogTestHelpers.verifyDialogClosed<AddIngredientDialog>();
    });

    testWidgets('no database side effects on cancel',
        (WidgetTester tester) async {
      final testRecipe = DialogFixtures.createTestRecipe();

      await DialogTestHelpers.openDialog(
        tester,
        dialogBuilder: (context) => AddIngredientDialog(
          recipe: testRecipe,
          databaseHelper: mockDbHelper,
        ),
      );

      // Wait for ingredients to load
      await tester.pumpAndSettle();

      // Verify no side effects
      await DialogTestHelpers.verifyNoSideEffects(
        mockDbHelper,
        beforeAction: () async {
          await tester.tap(find.text('Cancelar'));
          await tester.pumpAndSettle();
        },
      );
    });

    testWidgets('safely disposes controllers on cancel',
        (WidgetTester tester) async {
      final testRecipe = DialogFixtures.createTestRecipe();

      await DialogTestHelpers.openDialog(
        tester,
        dialogBuilder: (context) => AddIngredientDialog(
          recipe: testRecipe,
          databaseHelper: mockDbHelper,
        ),
      );

      // Wait for ingredients to load
      await tester.pumpAndSettle();

      // Interact with fields to initialize controllers
      final quantityField = find.byKey(const Key('add_ingredient_quantity_field'));
      await tester.enterText(quantityField, '100');
      await tester.pump();

      final notesField = find.byKey(const Key('add_ingredient_notes_field'));
      await tester.enterText(notesField, 'Test notes');
      await tester.pump();

      // Cancel dialog
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // If controller disposal is broken, this would throw
      // Test passes if no crash occurs
      DialogTestHelpers.verifyDialogClosed<AddIngredientDialog>();
    });

    testWidgets('safely disposes controllers on save',
        (WidgetTester tester) async {
      final testRecipe = DialogFixtures.createTestRecipe();

      await DialogTestHelpers.openDialog(
        tester,
        dialogBuilder: (context) => AddIngredientDialog(
          recipe: testRecipe,
          databaseHelper: mockDbHelper,
        ),
      );

      // Wait for ingredients to load
      await tester.pumpAndSettle();

      // Select ingredient and fill form
      final searchField = find.byKey(const Key('add_ingredient_search_field'));
      await tester.enterText(searchField, 'Chicken Breast');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Chicken Breast').last);
      await tester.pumpAndSettle();

      final quantityField = find.byKey(const Key('add_ingredient_quantity_field'));
      await tester.enterText(quantityField, '300');
      await tester.pumpAndSettle();

      // Save dialog
      await tester.tap(find.text('Adicionar'));
      await tester.pumpAndSettle();

      // If controller disposal is broken, this would throw
      // Test passes if no crash occurs
      DialogTestHelpers.verifyDialogClosed<AddIngredientDialog>();
    });
  });
}
