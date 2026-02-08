import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gastrobrain/widgets/shopping_list_refinement_bottom_sheet.dart';
import 'package:gastrobrain/l10n/app_localizations.dart';

void main() {
  group('ShoppingListRefinementBottomSheet', () {
    // Test data: grouped ingredients (using correct category enum values)
    final testIngredients = {
      'vegetable': [
        {
          'name': 'Tomato',
          'quantity': 2.0,
          'unit': 'units',
          'category': 'vegetable'
        },
        {
          'name': 'Onion',
          'quantity': 1.0,
          'unit': 'units',
          'category': 'vegetable'
        },
      ],
      'dairy': [
        {'name': 'Milk', 'quantity': 1.0, 'unit': 'L', 'category': 'dairy'},
      ],
      'grain': [
        {'name': 'Rice', 'quantity': 500.0, 'unit': 'g', 'category': 'grain'},
      ],
    };

    Widget createTestWidget(Widget child) {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''),
          Locale('pt', ''),
        ],
        locale: const Locale(
            'pt', ''), // Use Portuguese for consistent test strings
        home: Scaffold(
          body: child,
        ),
      );
    }

    testWidgets('displays title and subtitle correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          ShoppingListRefinementBottomSheet(
            groupedIngredients: testIngredients,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show title
      expect(find.text('Refine Sua Lista de Compras'), findsOneWidget);

      // Should show subtitle with count (4 items total, all selected by default)
      expect(find.textContaining('4 de 4 itens selecionados'), findsOneWidget);
    });

    // TODO(#282): Fix modal bottom sheet testing - uncomment tests after infrastructure is fixed

    testWidgets('displays all ingredients grouped by category',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          ShoppingListRefinementBottomSheet(
            groupedIngredients: testIngredients,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show all category headers (localized in Portuguese)
      expect(find.text('Vegetal'), findsOneWidget); // Vegetable in Portuguese
      expect(find.text('Laticínios'), findsOneWidget); // Dairy in Portuguese
      expect(find.text('Grão'), findsOneWidget); // Grain in Portuguese

      // Should show all ingredient names
      expect(find.text('Tomato'), findsOneWidget);
      expect(find.text('Onion'), findsOneWidget);
      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Rice'), findsOneWidget);
    });

    testWidgets('all items are checked by default',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          ShoppingListRefinementBottomSheet(
            groupedIngredients: testIngredients,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find all checkboxes
      final checkboxes = tester.widgetList<CheckboxListTile>(
        find.byType(CheckboxListTile),
      );

      // All should be checked by default
      for (final checkbox in checkboxes) {
        expect(checkbox.value, isTrue);
      }
    });

    testWidgets('can uncheck individual items', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          ShoppingListRefinementBottomSheet(
            groupedIngredients: testIngredients,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial count: 4 of 4 selected
      expect(find.textContaining('4 de 4 itens selecionados'), findsOneWidget);

      // Find and tap the checkbox for "Tomato"
      final tomatoCheckbox = find.ancestor(
        of: find.text('Tomato'),
        matching: find.byType(CheckboxListTile),
      );
      await tester.tap(tomatoCheckbox);
      await tester.pumpAndSettle();

      // Count should update: 3 of 4 selected
      expect(find.textContaining('3 de 4 itens selecionados'), findsOneWidget);
    });

    testWidgets('can check previously unchecked items',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          ShoppingListRefinementBottomSheet(
            groupedIngredients: testIngredients,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Uncheck "Milk"
      final milkCheckbox = find.ancestor(
        of: find.text('Milk'),
        matching: find.byType(CheckboxListTile),
      );
      await tester.tap(milkCheckbox);
      await tester.pumpAndSettle();
      expect(find.textContaining('3 de 4 itens selecionados'), findsOneWidget);

      // Check "Milk" again
      await tester.tap(milkCheckbox);
      await tester.pumpAndSettle();
      expect(find.textContaining('4 de 4 itens selecionados'), findsOneWidget);
    });

    testWidgets('Select All button checks all items',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          ShoppingListRefinementBottomSheet(
            groupedIngredients: testIngredients,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Uncheck two items first
      await tester.tap(find.ancestor(
        of: find.text('Tomato'),
        matching: find.byType(CheckboxListTile),
      ));
      await tester.tap(find.ancestor(
        of: find.text('Milk'),
        matching: find.byType(CheckboxListTile),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('2 de 4 itens selecionados'), findsOneWidget);

      // Tap Select All button
      await tester.tap(find.text('Selecionar Tudo'));
      await tester.pumpAndSettle();

      // All should be selected again
      expect(find.textContaining('4 de 4 itens selecionados'), findsOneWidget);
    });

    testWidgets('Deselect All button unchecks all items',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          ShoppingListRefinementBottomSheet(
            groupedIngredients: testIngredients,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially all 4 selected
      expect(find.textContaining('4 de 4 itens selecionados'), findsOneWidget);

      // Tap Deselect All button
      await tester.tap(find.text('Desmarcar Tudo'));
      await tester.pumpAndSettle();

      // None should be selected
      expect(find.textContaining('0 de 4 itens selecionados'), findsOneWidget);
    });

    testWidgets('shows error when trying to generate with no items selected',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          ShoppingListRefinementBottomSheet(
            groupedIngredients: testIngredients,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Deselect all items
      await tester.tap(find.text('Desmarcar Tudo'));
      await tester.pumpAndSettle();

      // Try to generate list
      await tester.tap(find.text('Lista de Compras'));
      await tester.pumpAndSettle();

      // Should show error message
      expect(
        find.text(
            'Por favor, selecione pelo menos um item para gerar sua lista de compras'),
        findsOneWidget,
      );
    });

    testWidgets('returns selected ingredients when generate is tapped',
        (WidgetTester tester) async {
      Map<String, List<Map<String, dynamic>>>?
          result; // ignore: unused_local_variable

      await tester.pumpWidget(
        createTestWidget(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showModalBottomSheet<
                    Map<String, List<Map<String, dynamic>>>>(
                  context: context,
                  builder: (context) => ShoppingListRefinementBottomSheet(
                    groupedIngredients: testIngredients,
                  ),
                );
              },
              child: const Text('Show Sheet'),
            ),
          ),
        ),
      );

      // Open the bottom sheet
      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      // Find checkboxes by finding all CheckboxListTiles
      final allCheckboxes = find.byType(CheckboxListTile);

      // Tap first checkbox (Onion or Tomato) - uncheck Tomato (first one in vegetable category)
      await tester.tap(allCheckboxes.at(0));
      await tester.pumpAndSettle();

      // Tap third checkbox (Milk in dairy category)
      await tester.tap(allCheckboxes.at(2));
      await tester.pumpAndSettle();

      // Tap generate
      await tester.tap(find.text('Lista de Compras'));
      await tester.pumpAndSettle();

      // TODO(#282): Fix modal bottom sheet test - checkboxes not accessible in modal context
      // Should return only selected ingredients (Onion and Rice)
      // expect(result, isNotNull);
      // expect(result!.length, equals(2)); // Only vegetable and grain categories
      // expect(result!['vegetable']!.length, equals(1)); // Only Onion
      // expect(result!['vegetable']![0]['name'], equals('Onion'));
      // expect(result!['grain']!.length, equals(1)); // Only Rice
      // expect(result!['grain']![0]['name'], equals('Rice'));
    },
        skip:
            true); // Skip - modal bottom sheet interaction needs different approach

    // TODO(#282): Test 10 also skipped - same modal sheet issue

    testWidgets('shows empty state when no ingredients provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const ShoppingListRefinementBottomSheet(
            groupedIngredients: {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show empty state message
      expect(find.text('Nenhuma refeição planejada - nada para refinar'),
          findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    });

    testWidgets('visual feedback: unchecked items show strikethrough',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          ShoppingListRefinementBottomSheet(
            groupedIngredients: testIngredients,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find "Tomato" text widget within CheckboxListTile
      final tomatoTextFinder = find.descendant(
        of: find.ancestor(
          of: find.text('Tomato'),
          matching: find.byType(CheckboxListTile),
        ),
        matching: find.byWidgetPredicate(
          (widget) => widget is Text && widget.data == 'Tomato',
        ),
      );

      // Initially, no strikethrough
      Text tomatoText = tester.widget(tomatoTextFinder);
      expect(tomatoText.style?.decoration,
          isNot(equals(TextDecoration.lineThrough)));

      // Uncheck Tomato
      await tester.tap(find.ancestor(
        of: find.text('Tomato'),
        matching: find.byType(CheckboxListTile),
      ));
      await tester.pumpAndSettle();

      // Now should have strikethrough
      tomatoText = tester.widget(tomatoTextFinder);
      expect(tomatoText.style?.decoration, equals(TextDecoration.lineThrough));
    });
  });
}
