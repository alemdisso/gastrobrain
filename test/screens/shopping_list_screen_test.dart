// test/screens/shopping_list_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gastrobrain/models/ingredient.dart';
import 'package:gastrobrain/models/ingredient_category.dart';
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

      // Should display localized categories with item counts
      expect(find.text('Protein'), findsOneWidget);
      expect(find.text('Vegetable'), findsOneWidget);

      // Categories are expanded by default — items should be visible
      expect(find.text('Chicken Breast'), findsOneWidget);
      expect(find.text('Tomatoes'), findsOneWidget);

      // Should display quantities with localized units (formatted without trailing zeros)
      expect(find.text('500 g'), findsOneWidget);
      expect(find.text('3 Pieces'), findsOneWidget);
    });

    testWidgets('displays "to taste" items without warning icon', (tester) async {
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

      // Categories are expanded by default — items should be visible
      // Should display "to taste" without a warning icon (#297)
      expect(find.textContaining('to taste'), findsOneWidget);
      expect(find.textContaining('⚠️'), findsNothing);
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

    testWidgets('displays "Add item" FAB', (tester) async {
      final shoppingList = ShoppingList(
        name: 'Test List',
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
      await tester.pumpAndSettle();

      expect(find.text('Add item'), findsOneWidget);
    });

    testWidgets('filters items when "To Buy Only" chip is selected', (tester) async {
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

      // Both items should be visible initially (categories expanded by default)
      expect(find.text('Chicken Breast'), findsOneWidget);
      expect(find.text('Salt'), findsOneWidget);

      // Tap the "To Buy Only" filter chip (static label)
      await tester.tap(find.text('To Buy Only'));
      await tester.pumpAndSettle();

      // Only "to buy" item should be visible
      expect(find.text('Chicken Breast'), findsOneWidget);
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

      // Categories are expanded by default — items should be visible
      // 'baking' maps to IngredientCategory.other → "Other"
      // 'dairy' maps to IngredientCategory.dairy → "Dairy"
      // Should display formatted quantities:
      // 2.5 → "2½ Cups"
      // 0.5 → "½ Cups" (plural for non-1 quantities)
      // 100.0 → "100 g"
      expect(find.text('2½ Cups'), findsOneWidget);
      expect(find.text('½ Cups'), findsOneWidget);
      expect(find.text('100 g'), findsOneWidget);
    });

  });

  group('Manual shopping items (#312)', () {
    late int listId;

    setUp(() async {
      mockDbHelper = MockDatabaseHelper();
      final shoppingList = ShoppingList(
        name: 'Test List',
        dateCreated: DateTime.now(),
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
      );
      listId = await mockDbHelper.insertShoppingList(shoppingList);
    });

    Future<void> pumpScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          ShoppingListScreen(
            shoppingListId: listId,
            databaseHelper: mockDbHelper,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Add button in dialog is disabled when search field is empty',
        (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Add item'));
      await tester.pumpAndSettle();

      // Dialog should be open
      expect(find.text('Add Item'), findsOneWidget);

      // Add button should be disabled (nothing typed yet)
      final addButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Add'));
      expect(addButton.onPressed, isNull);
    });

    testWidgets('adds free-text item — appears in list with edit_note icon',
        (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Add item'));
      await tester.pumpAndSettle();

      // Type a name that won't match any DB ingredient
      await tester.enterText(find.byType(TextField).first, 'Olive oil');
      await tester.pumpAndSettle();

      // Confirm
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pumpAndSettle();

      expect(find.text('Olive oil'), findsOneWidget);
      expect(find.byIcon(Icons.edit_note), findsOneWidget);
    });

    testWidgets('adds DB-linked item — appears in its ingredient category',
        (tester) async {
      // Pre-load an ingredient into the mock DB
      await mockDbHelper.insertIngredient(Ingredient(
        id: 'ing-1',
        name: 'Spinach',
        category: IngredientCategory.vegetable,
      ));

      await pumpScreen(tester);

      await tester.tap(find.text('Add item'));
      await tester.pumpAndSettle();

      // Type the ingredient name
      await tester.enterText(find.byType(TextField).first, 'Spinach');
      await tester.pumpAndSettle();

      // Select from suggestion list
      await tester.tap(find.text('Spinach').last);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pumpAndSettle();

      // Item appears under its real category
      expect(find.text('Spinach'), findsOneWidget);
      expect(find.byIcon(Icons.edit_note), findsOneWidget);
      expect(find.text('Vegetable'), findsOneWidget);
    });

    testWidgets('manual items survive To Buy Only filter toggle',
        (tester) async {
      await pumpScreen(tester);

      // Add a manual item
      await tester.tap(find.text('Add item'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Paper towels');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pumpAndSettle();

      expect(find.text('Paper towels'), findsOneWidget);

      // Toggle "To Buy Only" filter — item is still toBuy=true so should remain
      await tester.tap(find.text('To Buy Only'));
      await tester.pumpAndSettle();

      expect(find.text('Paper towels'), findsOneWidget);

      // Toggle filter off again
      await tester.tap(find.text('To Buy Only'));
      await tester.pumpAndSettle();

      expect(find.text('Paper towels'), findsOneWidget);
    });

    testWidgets('manual items are cleared when screen is recreated',
        (tester) async {
      // First screen instance — add a manual item
      await pumpScreen(tester);
      await tester.tap(find.text('Add item'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Foil wrap');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pumpAndSettle();
      expect(find.text('Foil wrap'), findsOneWidget);

      // Replace with a fresh screen instance using a different key to force
      // state recreation — simulates pushReplacement after list regeneration
      await tester.pumpWidget(
        createTestableWidget(
          ShoppingListScreen(
            key: const ValueKey('recreated'),
            shoppingListId: listId,
            databaseHelper: mockDbHelper,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Foil wrap'), findsNothing);
    });
  });

}
