import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gastrobrain/widgets/shopping_list_preview_bottom_sheet.dart';
import 'package:gastrobrain/l10n/app_localizations.dart';

void main() {
  group('ShoppingListPreviewBottomSheet - Localization', () {
    Widget createTestWidget(Widget child, {Locale? locale}) {
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
        locale: locale ?? const Locale('en', ''),
        home: Scaffold(
          body: child,
        ),
      );
    }

    testWidgets('displays localized units in Portuguese',
        (WidgetTester tester) async {
      final testIngredients = {
        'vegetable': [
          {
            'name': 'Tomato',
            'quantity': 2.0,
            'unit': 'cup', // Should be localized to "Xícara"
            'category': 'vegetable'
          },
          {
            'name': 'Onion',
            'quantity': 1.0,
            'unit': 'tbsp', // Should be localized to "Colher de sopa"
            'category': 'vegetable'
          },
        ],
        'spice': [
          {
            'name': 'Salt',
            'quantity': 1.0,
            'unit': 'tsp', // Should be localized to "Colher de chá"
            'category': 'spice'
          },
        ],
      };

      await tester.pumpWidget(
        createTestWidget(
          ShoppingListPreviewBottomSheet(
            groupedIngredients: testIngredients,
          ),
          locale: const Locale('pt', ''),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Portuguese localization
      expect(find.textContaining('Xícara'), findsOneWidget); // cup
      expect(find.textContaining('Colher de sopa'), findsOneWidget); // tbsp
      expect(find.textContaining('Colher de chá'), findsOneWidget); // tsp
    });

    testWidgets('displays localized units in English',
        (WidgetTester tester) async {
      final testIngredients = {
        'vegetable': [
          {
            'name': 'Tomato',
            'quantity': 2.0,
            'unit': 'cup',
            'category': 'vegetable'
          },
          {
            'name': 'Onion',
            'quantity': 1.0,
            'unit': 'tbsp',
            'category': 'vegetable'
          },
        ],
        'spice': [
          {
            'name': 'Salt',
            'quantity': 1.0,
            'unit': 'tsp',
            'category': 'spice'
          },
        ],
      };

      await tester.pumpWidget(
        createTestWidget(
          ShoppingListPreviewBottomSheet(
            groupedIngredients: testIngredients,
          ),
          locale: const Locale('en', ''),
        ),
      );
      await tester.pumpAndSettle();

      // Verify English localization
      expect(find.textContaining('Cup'), findsOneWidget);
      expect(find.textContaining('Tbsp'), findsOneWidget);
      expect(find.textContaining('Tsp'), findsOneWidget);
    });

    testWidgets('falls back to raw string for unknown units',
        (WidgetTester tester) async {
      final testIngredients = {
        'other': [
          {
            'name': 'Custom Item',
            'quantity': 5.0,
            'unit': 'custom_unit', // Unknown unit, should display as-is
            'category': 'other'
          },
        ],
      };

      await tester.pumpWidget(
        createTestWidget(
          ShoppingListPreviewBottomSheet(
            groupedIngredients: testIngredients,
          ),
          locale: const Locale('pt', ''),
        ),
      );
      await tester.pumpAndSettle();

      // Should display raw unit string for unknown units
      expect(find.textContaining('custom_unit'), findsOneWidget);
    });

    testWidgets('preserves quantity formatting with localized units',
        (WidgetTester tester) async {
      final testIngredients = {
        'vegetable': [
          {
            'name': 'Flour',
            'quantity': 0.5,
            'unit': 'cup',
            'category': 'vegetable'
          },
          {
            'name': 'Sugar',
            'quantity': 1.25,
            'unit': 'cup',
            'category': 'vegetable'
          },
          {
            'name': 'Butter',
            'quantity': 2.0,
            'unit': 'tbsp',
            'category': 'vegetable'
          },
        ],
      };

      await tester.pumpWidget(
        createTestWidget(
          ShoppingListPreviewBottomSheet(
            groupedIngredients: testIngredients,
          ),
          locale: const Locale('pt', ''),
        ),
      );
      await tester.pumpAndSettle();

      // Check that fractions and decimals are preserved
      expect(find.textContaining('½ Xícara'), findsOneWidget); // 0.5 cup
      expect(find.textContaining('1¼ Xícara'), findsOneWidget); // 1.25 cup
      expect(find.textContaining('2 Colher de sopa'), findsOneWidget); // 2 tbsp
    });

    testWidgets('displays various common units correctly in Portuguese',
        (WidgetTester tester) async {
      final testIngredients = {
        'various': [
          {
            'name': 'Item 1',
            'quantity': 1.0,
            'unit': 'piece',
            'category': 'various'
          },
          {
            'name': 'Item 2',
            'quantity': 1.0,
            'unit': 'slice',
            'category': 'various'
          },
          {
            'name': 'Item 3',
            'quantity': 1.0,
            'unit': 'bunch',
            'category': 'various'
          },
          {
            'name': 'Item 4',
            'quantity': 1.0,
            'unit': 'pinch',
            'category': 'various'
          },
        ],
      };

      await tester.pumpWidget(
        createTestWidget(
          ShoppingListPreviewBottomSheet(
            groupedIngredients: testIngredients,
          ),
          locale: const Locale('pt', ''),
        ),
      );
      await tester.pumpAndSettle();

      // Verify various units are localized
      expect(find.textContaining('Unidade'), findsOneWidget); // piece
      expect(find.textContaining('Fatia'), findsOneWidget); // slice
      expect(find.textContaining('Maço'), findsOneWidget); // bunch
      expect(find.textContaining('Pitada'), findsOneWidget); // pinch
    });

    testWidgets('metric abbreviations remain unchanged',
        (WidgetTester tester) async {
      final testIngredients = {
        'various': [
          {
            'name': 'Flour',
            'quantity': 500.0,
            'unit': 'g',
            'category': 'various'
          },
          {
            'name': 'Sugar',
            'quantity': 1.0,
            'unit': 'kg',
            'category': 'various'
          },
          {
            'name': 'Milk',
            'quantity': 250.0,
            'unit': 'ml',
            'category': 'various'
          },
          {
            'name': 'Water',
            'quantity': 1.0,
            'unit': 'l',
            'category': 'various'
          },
        ],
      };

      await tester.pumpWidget(
        createTestWidget(
          ShoppingListPreviewBottomSheet(
            groupedIngredients: testIngredients,
          ),
          locale: const Locale('pt', ''),
        ),
      );
      await tester.pumpAndSettle();

      // Metric abbreviations should remain the same
      expect(find.textContaining('500 g'), findsOneWidget);
      expect(find.textContaining('1 kg'), findsOneWidget);
      expect(find.textContaining('250 ml'), findsOneWidget);
      expect(find.textContaining('1 l'), findsOneWidget);
    });
  });
}
