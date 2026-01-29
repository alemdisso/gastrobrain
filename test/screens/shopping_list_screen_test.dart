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
        toBuy: true,
      );

      final item2 = ShoppingListItem(
        shoppingListId: listId,
        ingredientName: 'Tomatoes',
        quantity: 3,
        unit: 'piece',
        category: 'vegetable',
        toBuy: true,
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

      // Should display quantities with localized units (formatted without trailing zeros)
      expect(find.text('500 g'), findsOneWidget);
      expect(find.text('3 Piece'), findsOneWidget);
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
        toBuy: true,
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

    testWidgets('filters items when "To Buy Only" is selected', (tester) async {
      // Create shopping list
      final shoppingList = ShoppingList(
        name: 'Test List',
        dateCreated: DateTime.now(),
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
      );

      final listId = await mockDbHelper.insertShoppingList(shoppingList);

      // Add items: one to buy, one not needed
      final item1 = ShoppingListItem(
        shoppingListId: listId,
        ingredientName: 'Chicken Breast',
        quantity: 500,
        unit: 'g',
        category: 'protein',
        toBuy: true,
      );

      final item2 = ShoppingListItem(
        shoppingListId: listId,
        ingredientName: 'Salt',
        quantity: 10,
        unit: 'g',
        category: 'seasoning',
        toBuy: false,
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

      await tester.pumpAndSettle();

      // Both items should be visible initially
      expect(find.text('Chicken Breast'), findsOneWidget);
      expect(find.text('Salt'), findsOneWidget);

      // Tap the "Show All" filter chip (it toggles to "To Buy Only")
      await tester.tap(find.text('Show All'));
      await tester.pumpAndSettle();

      // Now it should show "To Buy Only" text
      expect(find.text('To Buy Only'), findsOneWidget);

      // Only "to buy" item should be visible
      expect(find.text('Chicken Breast'), findsOneWidget);
      expect(find.text('Salt'), findsNothing);
    });

    testWidgets('filters out "to taste" items when "Hide To Taste" is selected', (tester) async {
      // Create shopping list
      final shoppingList = ShoppingList(
        name: 'Test List',
        dateCreated: DateTime.now(),
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
      );

      final listId = await mockDbHelper.insertShoppingList(shoppingList);

      // Add items: one normal, one "to taste"
      final item1 = ShoppingListItem(
        shoppingListId: listId,
        ingredientName: 'Tomato',
        quantity: 500,
        unit: 'g',
        category: 'vegetable',
        toBuy: true,
      );

      final item2 = ShoppingListItem(
        shoppingListId: listId,
        ingredientName: 'Salt',
        quantity: 0,
        unit: 'g',
        category: 'seasoning',
        toBuy: true,
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

      await tester.pumpAndSettle();

      // Both items should be visible initially
      expect(find.text('Tomato'), findsOneWidget);
      expect(find.text('Salt'), findsOneWidget);

      // Tap the "Hide To Taste" filter chip
      await tester.tap(find.text('Hide \'To Taste\''));
      await tester.pumpAndSettle();

      // Only normal item should be visible
      expect(find.text('Tomato'), findsOneWidget);
      expect(find.text('Salt'), findsNothing);
    });

    testWidgets('displays formatted quantities (fractions and clean decimals)', (tester) async {
      // Create shopping list
      final shoppingList = ShoppingList(
        name: 'Test List',
        dateCreated: DateTime.now(),
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
      );

      final listId = await mockDbHelper.insertShoppingList(shoppingList);

      // Add items with various quantities
      await mockDbHelper.insertShoppingListItem(ShoppingListItem(
        shoppingListId: listId,
        ingredientName: 'Sugar',
        quantity: 2.5,
        unit: 'cup',
        category: 'baking',
        toBuy: true,
      ));

      await mockDbHelper.insertShoppingListItem(ShoppingListItem(
        shoppingListId: listId,
        ingredientName: 'Flour',
        quantity: 0.5,
        unit: 'cup',
        category: 'baking',
        toBuy: true,
      ));

      await mockDbHelper.insertShoppingListItem(ShoppingListItem(
        shoppingListId: listId,
        ingredientName: 'Butter',
        quantity: 100.0,
        unit: 'g',
        category: 'dairy',
        toBuy: true,
      ));

      await tester.pumpWidget(
        createTestableWidget(
          ShoppingListScreen(
            shoppingListId: listId,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display formatted quantities:
      // 2.5 → "2½ Cup"
      // 0.5 → "½ Cup"
      // 100.0 → "100 g"
      expect(find.text('2½ Cup'), findsOneWidget);
      expect(find.text('½ Cup'), findsOneWidget);
      expect(find.text('100 g'), findsOneWidget);
    });

    testWidgets('applies both filters together', (tester) async {
      // Create shopping list
      final shoppingList = ShoppingList(
        name: 'Test List',
        dateCreated: DateTime.now(),
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
      );

      final listId = await mockDbHelper.insertShoppingList(shoppingList);

      // Add items with different combinations
      await mockDbHelper.insertShoppingListItem(ShoppingListItem(
        shoppingListId: listId,
        ingredientName: 'Chicken',
        quantity: 500,
        unit: 'g',
        category: 'protein',
        toBuy: true,
      ));

      await mockDbHelper.insertShoppingListItem(ShoppingListItem(
        shoppingListId: listId,
        ingredientName: 'Salt',
        quantity: 0,
        unit: 'g',
        category: 'seasoning',
        toBuy: true,
      ));

      await mockDbHelper.insertShoppingListItem(ShoppingListItem(
        shoppingListId: listId,
        ingredientName: 'Pepper',
        quantity: 10,
        unit: 'g',
        category: 'seasoning',
        toBuy: false,
      ));

      await tester.pumpWidget(
        createTestableWidget(
          ShoppingListScreen(
            shoppingListId: listId,
            databaseHelper: mockDbHelper,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // All items visible initially
      expect(find.text('Chicken'), findsOneWidget);
      expect(find.text('Salt'), findsOneWidget);
      expect(find.text('Pepper'), findsOneWidget);

      // Apply "To Buy Only" filter (tap "Show All" to toggle it)
      await tester.tap(find.text('Show All'));
      await tester.pumpAndSettle();

      // Only "to buy" items visible (Chicken and Salt)
      expect(find.text('Chicken'), findsOneWidget);
      expect(find.text('Salt'), findsOneWidget);
      expect(find.text('Pepper'), findsNothing);

      // Also apply "Hide To Taste" filter
      await tester.tap(find.text('Hide \'To Taste\''));
      await tester.pumpAndSettle();

      // Only Chicken should be visible (to buy = true, quantity > 0)
      expect(find.text('Chicken'), findsOneWidget);
      expect(find.text('Salt'), findsNothing);
      expect(find.text('Pepper'), findsNothing);
    });
  });
}
