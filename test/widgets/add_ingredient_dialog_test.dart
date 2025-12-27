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
  });
}
