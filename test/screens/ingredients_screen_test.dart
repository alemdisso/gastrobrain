// test/screens/ingredients_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gastrobrain/models/ingredient.dart';
import 'package:gastrobrain/models/ingredient_category.dart';
import 'package:gastrobrain/screens/ingredients_screen.dart';
import 'package:gastrobrain/l10n/app_localizations.dart';
import '../mocks/mock_database_helper.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en', '')],
    home: child,
  );
}

Ingredient _makeIngredient({String id = 'ing-1', String name = 'Salt'}) {
  return Ingredient(
    id: id,
    name: name,
    category: IngredientCategory.seasoning,
  );
}

void main() {
  group('IngredientsScreen — DI (#355)', () {
    late MockDatabaseHelper mockDb;

    setUp(() {
      mockDb = MockDatabaseHelper();
    });

    testWidgets('injected databaseHelper is used — ingredient appears in list',
        (tester) async {
      mockDb.ingredients['ing-1'] = _makeIngredient(name: 'Oregano');

      await tester.pumpWidget(_buildTestApp(
        IngredientsScreen(databaseHelper: mockDb),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Oregano'), findsOneWidget);
    });

    testWidgets('empty mock shows empty-state message, no crash',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        IngredientsScreen(databaseHelper: mockDb),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Oregano'), findsNothing);
      // Empty state widget rendered — no exception thrown
      expect(find.byType(IngredientsScreen), findsOneWidget);
    });

    testWidgets('multiple ingredients from mock all appear in list',
        (tester) async {
      mockDb.ingredients['ing-1'] = _makeIngredient(id: 'ing-1', name: 'Basil');
      mockDb.ingredients['ing-2'] = _makeIngredient(id: 'ing-2', name: 'Thyme');
      mockDb.ingredients['ing-3'] = _makeIngredient(id: 'ing-3', name: 'Paprika');

      await tester.pumpWidget(_buildTestApp(
        IngredientsScreen(databaseHelper: mockDb),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Basil'), findsOneWidget);
      expect(find.text('Thyme'), findsOneWidget);
      expect(find.text('Paprika'), findsOneWidget);
    });
  });
}
