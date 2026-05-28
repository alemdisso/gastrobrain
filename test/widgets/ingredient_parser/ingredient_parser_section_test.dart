import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/core/services/ingredient_matching_service.dart';
import 'package:gastrobrain/models/ingredient.dart';
import 'package:gastrobrain/widgets/ingredient_parser/ingredient_parser_section.dart';
import 'package:gastrobrain/widgets/recipe_editor/parsed_ingredient.dart';
import '../../test_utils/test_app_wrapper.dart';

Widget buildSection({
  IngredientMatchingService? matchingService,
  bool isServicesReady = false,
  Future<bool> Function(List<ParsedIngredient>)? onIngredientsConfirmed,
  Future<Ingredient?> Function(ParsedIngredient)? onCreateNew,
}) {
  return wrapWithLocalizations(
    Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: IngredientParserSection(
            matchingService: matchingService ?? IngredientMatchingService(),
            isServicesReady: isServicesReady,
            onIngredientsConfirmed: onIngredientsConfirmed ?? (_) async => true,
            onCreateNew: onCreateNew ?? (_) async => null,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('IngredientParserSection', () {
    group('initial state', () {
      testWidgets('parse button is disabled when services not ready',
          (tester) async {
        await tester.pumpWidget(buildSection(isServicesReady: false));
        await tester.pumpAndSettle();

        final parseButton = tester.widget<ElevatedButton>(
          find.byKey(const Key('ingredient_parser_parse_button')),
        );
        expect(parseButton.onPressed, isNull);
      });

      testWidgets('parse button is enabled when services ready',
          (tester) async {
        await tester.pumpWidget(buildSection(isServicesReady: true));
        await tester.pumpAndSettle();

        final parseButton = tester.widget<ElevatedButton>(
          find.byKey(const Key('ingredient_parser_parse_button')),
        );
        expect(parseButton.onPressed, isNotNull);
      });

      testWidgets('starts with no ingredient rows', (tester) async {
        await tester.pumpWidget(buildSection());
        await tester.pumpAndSettle();

        // Confirm button only appears when there are rows
        expect(find.byKey(const Key('ingredient_parser_confirm_button')), findsNothing);
        expect(find.byKey(const Key('ingredient_parser_parse_button')), findsOneWidget);
      });
    });

    group('add manually', () {
      testWidgets('tapping Add Manually adds an expanded row', (tester) async {
        await tester.pumpWidget(buildSection());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        // expand_less icon means the new row is expanded
        expect(find.byIcon(Icons.expand_less), findsOneWidget);
      });

      testWidgets('two taps on Add Manually creates two rows', (tester) async {
        await tester.pumpWidget(buildSection());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.close), findsNWidgets(2));
      });

      testWidgets('removing the only row hides confirm button', (tester) async {
        await tester.pumpWidget(buildSection());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('ingredient_parser_confirm_button')), findsNothing);
      });
    });

    group('confirm button gate', () {
      testWidgets(
          'confirm button is disabled when row name is set with no match',
          (tester) async {
        await tester.pumpWidget(buildSection());
        await tester.pumpAndSettle();

        // Add a manual row and type a name so it needs attention
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        await tester.enterText(
            find
                .byType(TextFormField)
                .at(2), // name field (3rd field in expanded row)
            'UnknownIngredient');
        await tester.pumpAndSettle();

        final confirmButton = tester.widget<ElevatedButton>(
          find.byKey(const Key('ingredient_parser_confirm_button')),
        );
        expect(confirmButton.onPressed, isNull);
      });

      testWidgets('confirm button is enabled for blank-name manual row',
          (tester) async {
        await tester.pumpWidget(buildSection());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        // The new row has an empty name → not "needs attention" → confirm enabled
        final confirmButton = tester.widget<ElevatedButton>(
          find.byKey(const Key('ingredient_parser_confirm_button')),
        );
        expect(confirmButton.onPressed, isNotNull);
      });
    });

    group('confirm flow', () {
      testWidgets('tapping confirm calls onIngredientsConfirmed',
          (tester) async {
        bool called = false;

        await tester.pumpWidget(buildSection(
          onIngredientsConfirmed: (list) async {
            called = true;
            return true;
          },
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('ingredient_parser_confirm_button')));
        await tester.pumpAndSettle();

        expect(called, isTrue);
      });

      testWidgets('section clears when onIngredientsConfirmed returns true',
          (tester) async {
        await tester.pumpWidget(buildSection(
          onIngredientsConfirmed: (_) async => true,
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('ingredient_parser_confirm_button')));
        await tester.pumpAndSettle();

        // Rows cleared — confirm button gone
        expect(find.byKey(const Key('ingredient_parser_confirm_button')), findsNothing);
        expect(find.byIcon(Icons.close), findsNothing);
      });

      testWidgets(
          'section preserves rows when onIngredientsConfirmed returns false',
          (tester) async {
        await tester.pumpWidget(buildSection(
          onIngredientsConfirmed: (_) async => false,
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('ingredient_parser_confirm_button')));
        await tester.pumpAndSettle();

        // Row still present
        expect(find.byIcon(Icons.close), findsOneWidget);
      });
    });

    group('parse with services not ready (fallback)', () {
      testWidgets(
          'parsing with services not ready is blocked by disabled button',
          (tester) async {
        await tester.pumpWidget(buildSection(isServicesReady: false));
        await tester.pumpAndSettle();

        await tester.enterText(
            find.byType(TextField), '2 tbsp azeite\n1 cup farinha');
        await tester.pumpAndSettle();

        // Parse button is disabled — no rows produced
        expect(find.byIcon(Icons.close), findsNothing);
      });
    });
  });
}
