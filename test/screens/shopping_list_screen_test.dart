// test/screens/shopping_list_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gastrobrain/models/shopping_list.dart';
import 'package:gastrobrain/models/shopping_list_item.dart';
import 'package:gastrobrain/screens/shopping_list_screen.dart';
import 'package:gastrobrain/l10n/app_localizations.dart';
import '../mocks/mock_database_helper.dart';

void main() {
  late MockDatabaseHelper mockDbHelper;

  Widget createTestableWidget(Widget child,
      {Locale locale = const Locale('en', '')}) {
    return MaterialApp(
      locale: locale,
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
      home: child,
    );
  }

  setUp(() {
    mockDbHelper = MockDatabaseHelper();
  });

  group('ShoppingListScreen Widget Tests', () {
    testWidgets('displays loading indicator while loading', (tester) async {
      // Create a shopping list with ID
      final shoppingList = ShoppingList(
        name: 'Test List',
        dateCreated: DateTime.now(),
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
      );

      await mockDbHelper.insertShoppingList(shoppingList);

      await tester.pumpWidget(
        createTestableWidget(
          ShoppingListScreen(
            shoppingListId: 1,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      // Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays error message when shopping list not found', (tester) async {
      // Don't add any shopping list to the mock database

      await tester.pumpWidget(
        createTestableWidget(
          ShoppingListScreen(
            shoppingListId: 999,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Should display error message
      expect(find.textContaining('Shopping list not found'), findsOneWidget);
    });

    testWidgets('displays shopping list items grouped by category', (tester) async {
      // Create shopping list
      final shoppingList = ShoppingList(
        name: 'Weekly List',
        dateCreated: DateTime.now(),
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
      );

      final listId = await mockDbHelper.insertShoppingList(shoppingList);

      // Add items in different categories (using enum values)
      final item1 = ShoppingListItem(
        shoppingListId: listId,
        ingredientName: 'Chicken Breast',
        quantity: 500,
        unit: 'g',
        category: 'protein',
        isPurchased: false,
      );

      final item2 = ShoppingListItem(
        shoppingListId: listId,
        ingredientName: 'Tomatoes',
        quantity: 3,
        unit: 'piece',
        category: 'vegetable',
        isPurchased: false,
      );

      await mockDbHelper.insertShoppingListItem(item1);
      await mockDbHelper.insertShoppingListItem(item2);

      await tester.pumpWidget(
        createTestableWidget(
          ShoppingListScreen(
            shoppingListId: listId,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      // Wait for loading
      await tester.pumpAndSettle();

      // Should display localized categories (in English since test uses English locale)
      expect(find.text('Protein'), findsOneWidget);
      expect(find.text('Vegetable'), findsOneWidget);

      // Should display items
      expect(find.text('Chicken Breast'), findsOneWidget);
      expect(find.text('Tomatoes'), findsOneWidget);

      // Should display quantities with localized units
      expect(find.text('500.0 g'), findsOneWidget);
      expect(find.text('3.0 Piece'), findsOneWidget);
    });

    testWidgets('displays "to taste" items with warning indicator', (tester) async {
      // Create shopping list
      final shoppingList = ShoppingList(
        name: 'Weekly List',
        dateCreated: DateTime.now(),
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
      );

      final listId = await mockDbHelper.insertShoppingList(shoppingList);

      // Add item with quantity 0 (to taste)
      final item = ShoppingListItem(
        shoppingListId: listId,
        ingredientName: 'Salt',
        quantity: 0,
        unit: 'g',
        category: 'seasoning',
        isPurchased: false,
      );

      await mockDbHelper.insertShoppingListItem(item);

      await tester.pumpWidget(
        createTestableWidget(
          ShoppingListScreen(
            shoppingListId: listId,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      // Wait for loading
      await tester.pumpAndSettle();

      // Should display "to taste" with warning indicator
      expect(find.textContaining('to taste'), findsOneWidget);
      expect(find.textContaining('⚠️'), findsOneWidget);
    });

    testWidgets('displays empty shopping list message when no items', (tester) async {
      // Create shopping list without items
      final shoppingList = ShoppingList(
        name: 'Empty List',
        dateCreated: DateTime.now(),
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
      );

      final listId = await mockDbHelper.insertShoppingList(shoppingList);

      await tester.pumpWidget(
        createTestableWidget(
          ShoppingListScreen(
            shoppingListId: listId,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      // Wait for loading
      await tester.pumpAndSettle();

      // Should display empty message
      expect(find.textContaining('No items'), findsOneWidget);
    });
  });
}
