// test/widgets/add_simple_side_dialog_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/widgets/add_simple_side_dialog.dart';
import 'package:gastrobrain/models/ingredient.dart';
import 'package:gastrobrain/models/ingredient_category.dart';
import 'package:gastrobrain/models/measurement_unit.dart';
import '../test_utils/test_app_wrapper.dart';
import '../helpers/dialog_test_helpers.dart';

List<Ingredient> _makeIngredients() => [
      Ingredient(
        id: 'i1',
        name: 'Banana',
        category: IngredientCategory.fruit,
        unit: MeasurementUnit.piece,
      ),
      Ingredient(
        id: 'i2',
        name: 'Batata',
        category: IngredientCategory.vegetable,
        unit: MeasurementUnit.gram,
      ),
    ];

Future<void> _openDialog(WidgetTester tester, List<Ingredient> ingredients) async {
  await tester.pumpWidget(
    wrapWithLocalizations(
      Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AddSimpleSideDialog(availableIngredients: ingredients),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  group('AddSimpleSideDialog', () {
    testWidgets('renders without overflow when no search term entered', (tester) async {
      await _openDialog(tester, _makeIngredients());

      expect(find.byType(AddSimpleSideDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows suggestions list without layout errors when search matches', (tester) async {
      await _openDialog(tester, _makeIngredients());

      await tester.enterText(find.byType(TextField).first, 'Ban');
      await tester.pumpAndSettle();

      expect(find.text('Banana'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('add button is disabled and label is visible in initial state', (tester) async {
      await _openDialog(tester, _makeIngredients());

      final addButton = find.byType(ElevatedButton).last;
      final ElevatedButton button = tester.widget<ElevatedButton>(addButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('add button enables after ingredient selected from suggestions', (tester) async {
      await _openDialog(tester, _makeIngredients());

      await tester.enterText(find.byType(TextField).first, 'Ban');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Banana').last);
      await tester.pumpAndSettle();

      final addButton = find.byType(ElevatedButton).last;
      final ElevatedButton button = tester.widget<ElevatedButton>(addButton);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('returns null when cancelled', (tester) async {
      final result = await DialogTestHelpers.openDialogAndCapture<Map<String, dynamic>>(
        tester,
        dialogBuilder: (context) => AddSimpleSideDialog(availableIngredients: _makeIngredients()),
      );

      await DialogTestHelpers.tapDialogButton(tester, 'Cancelar');
      await tester.pumpAndSettle();

      expect(result.value, isNull);
    });

    testWidgets('returns ingredient data when DB ingredient selected and confirmed', (tester) async {
      final result = await DialogTestHelpers.openDialogAndCapture<Map<String, dynamic>>(
        tester,
        dialogBuilder: (context) => AddSimpleSideDialog(availableIngredients: _makeIngredients()),
      );

      await tester.enterText(find.byType(TextField).first, 'Ban');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Banana').last);
      await tester.pumpAndSettle();

      await DialogTestHelpers.tapDialogButton(tester, 'Adicionar');
      await tester.pumpAndSettle();

      expect(result.hasValue, isTrue);
      expect(result.value!['ingredientId'], equals('i1'));
      expect(result.value!['customName'], isNull);
      expect(result.value!['quantity'], equals(1.0));
    });

    testWidgets('layout holds with suggestions visible — actions area not displaced', (tester) async {
      await _openDialog(tester, _makeIngredients());

      await tester.enterText(find.byType(TextField).first, 'Ban');
      await tester.pumpAndSettle();

      // Both action buttons must be visible (not clipped or displaced)
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Adicionar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
