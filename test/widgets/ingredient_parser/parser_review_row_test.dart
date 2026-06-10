import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/ingredient.dart';
import 'package:gastrobrain/models/ingredient_category.dart';
import 'package:gastrobrain/models/ingredient_match.dart';
import 'package:gastrobrain/widgets/ingredient_parser/parser_review_row.dart';
import 'package:gastrobrain/widgets/recipe_editor/parsed_ingredient.dart';
import '../../test_utils/test_app_wrapper.dart';

Ingredient _ingredient({String name = 'Azeite', IngredientCategory category = IngredientCategory.oil}) {
  return Ingredient(
    id: 'test-id',
    name: name,
    category: category,
  );
}

IngredientMatch _match({double confidence = 0.95}) {
  return IngredientMatch(
    ingredient: _ingredient(),
    confidence: confidence,
    matchType: MatchType.exact,
  );
}

Widget buildRow({
  required ParsedIngredient ingredient,
  bool initiallyExpanded = false,
  void Function(double, double?, String?)? onQuantityChanged,
  void Function(String?)? onUnitChanged,
  void Function(String)? onNameChanged,
  void Function(String?)? onNotesChanged,
  void Function(IngredientMatch?)? onMatchChanged,
  VoidCallback? onMarkAsNew,
  VoidCallback? onRemove,
  VoidCallback? onCreateNew,
  int parseGeneration = 0,
}) {
  return wrapWithLocalizations(
    Scaffold(
      body: SingleChildScrollView(
        child: ParserReviewRow(
          index: 0,
          ingredient: ingredient,
          parseGeneration: parseGeneration,
          initiallyExpanded: initiallyExpanded,
          onQuantityChanged: onQuantityChanged ?? (_, __, ___) {},
          onUnitChanged: onUnitChanged ?? (_) {},
          onNameChanged: onNameChanged ?? (_) {},
          onNotesChanged: onNotesChanged ?? (_) {},
          onMatchChanged: onMatchChanged ?? (_) {},
          onMarkAsNew: onMarkAsNew ?? () {},
          onRemove: onRemove ?? () {},
          onCreateNew: onCreateNew ?? () {},
        ),
      ),
    ),
  );
}

void main() {
  group('ParserReviewRow', () {
    group('collapsed state', () {
      testWidgets('shows qty, unit and name in label', (tester) async {
        final ing = ParsedIngredient(
          quantity: 2.0,
          unit: 'tbsp',
          name: 'Azeite',
          category: IngredientCategory.oil,
          matches: [],
        );

        await tester.pumpWidget(buildRow(ingredient: ing));
        await tester.pumpAndSettle();

        expect(find.textContaining('2'), findsWidgets);
        expect(find.textContaining('Colheres de sopa'), findsOneWidget);
        expect(find.textContaining('Azeite'), findsWidgets);
      });

      testWidgets('shows remove button', (tester) async {
        final ing = ParsedIngredient(
          quantity: 1.0,
          unit: null,
          name: 'Sal',
          category: IngredientCategory.other,
          matches: [],
        );

        await tester.pumpWidget(buildRow(ingredient: ing));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.close), findsOneWidget);
      });

      testWidgets('calls onRemove when delete button tapped', (tester) async {
        bool removed = false;
        final ing = ParsedIngredient(
          quantity: 1.0,
          unit: null,
          name: 'Sal',
          category: IngredientCategory.other,
          matches: [],
        );

        await tester.pumpWidget(buildRow(
          ingredient: ing,
          onRemove: () => removed = true,
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        expect(removed, isTrue);
      });
    });

    group('expansion', () {
      testWidgets('starts collapsed by default', (tester) async {
        final ing = ParsedIngredient(
          quantity: 1.0,
          unit: null,
          name: 'Sal',
          category: IngredientCategory.other,
          matches: [],
        );

        await tester.pumpWidget(buildRow(ingredient: ing));
        await tester.pumpAndSettle();

        // Qty field only visible when expanded
        expect(find.byIcon(Icons.expand_more), findsOneWidget);
        expect(find.byIcon(Icons.expand_less), findsNothing);
      });

      testWidgets('expands when header is tapped', (tester) async {
        final ing = ParsedIngredient(
          quantity: 1.0,
          unit: null,
          name: 'Sal',
          category: IngredientCategory.other,
          matches: [],
        );

        await tester.pumpWidget(buildRow(ingredient: ing));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.expand_more));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.expand_less), findsOneWidget);
      });

      testWidgets('starts expanded when initiallyExpanded is true', (tester) async {
        final ing = ParsedIngredient(
          quantity: 1.0,
          unit: null,
          name: 'Sal',
          category: IngredientCategory.other,
          matches: [],
        );

        await tester.pumpWidget(buildRow(ingredient: ing, initiallyExpanded: true));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.expand_less), findsOneWidget);
      });
    });

    group('needs-attention styling', () {
      testWidgets('shows red border when name is set with no match', (tester) async {
        final ing = ParsedIngredient(
          quantity: 1.0,
          unit: null,
          name: 'UnknownIngredient',
          category: IngredientCategory.other,
          matches: [],
        );

        await tester.pumpWidget(buildRow(ingredient: ing));
        await tester.pumpAndSettle();

        final card = tester.widget<Card>(find.byType(Card));
        final shape = card.shape as RoundedRectangleBorder;
        expect(shape.side.color, equals(Colors.red.shade300));
      });

      testWidgets('no red border when match is selected', (tester) async {
        final ing = ParsedIngredient(
          quantity: 1.0,
          unit: null,
          name: 'Azeite',
          category: IngredientCategory.oil,
          matches: [_match()],
          selectedMatch: _match(),
        );

        await tester.pumpWidget(buildRow(ingredient: ing));
        await tester.pumpAndSettle();

        final card = tester.widget<Card>(find.byType(Card));
        final shape = card.shape as RoundedRectangleBorder;
        expect(shape.side, equals(BorderSide.none));
      });
    });

    group('match area (expanded)', () {
      testWidgets('shows action buttons when name is set and no match', (tester) async {
        final ing = ParsedIngredient(
          quantity: 1.0,
          unit: null,
          name: 'UnknownIngredient',
          category: IngredientCategory.other,
          matches: [],
        );

        await tester.pumpWidget(buildRow(ingredient: ing, initiallyExpanded: true));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.fiber_new), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);
      });

      testWidgets('does not show action buttons when match is selected', (tester) async {
        final ing = ParsedIngredient(
          quantity: 1.0,
          unit: null,
          name: 'Azeite',
          category: IngredientCategory.oil,
          matches: [_match()],
          selectedMatch: _match(),
        );

        await tester.pumpWidget(buildRow(ingredient: ing, initiallyExpanded: true));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.fiber_new), findsNothing);
      });

      testWidgets('shows dropdown when multiple matches exist', (tester) async {
        final match1 = _match(confidence: 0.95);
        final match2 = IngredientMatch(
          ingredient: _ingredient(name: 'Azeite de Oliva'),
          confidence: 0.75,
          matchType: MatchType.partial,
        );

        final ing = ParsedIngredient(
          quantity: 1.0,
          unit: null,
          name: 'Azeite',
          category: IngredientCategory.oil,
          matches: [match1, match2],
          selectedMatch: match1,
        );

        await tester.pumpWidget(buildRow(ingredient: ing, initiallyExpanded: true));
        await tester.pumpAndSettle();

        expect(find.byType(DropdownButtonFormField<IngredientMatch>), findsOneWidget);
      });

      testWidgets('calls onCreateNew when Create New button tapped', (tester) async {
        bool called = false;
        final ing = ParsedIngredient(
          quantity: 1.0,
          unit: null,
          name: 'UnknownIngredient',
          category: IngredientCategory.other,
          matches: [],
        );

        await tester.pumpWidget(buildRow(
          ingredient: ing,
          initiallyExpanded: true,
          onCreateNew: () => called = true,
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        expect(called, isTrue);
      });
    });
  });
}
