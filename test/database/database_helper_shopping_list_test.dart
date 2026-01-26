import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/shopping_list.dart';
import 'package:gastrobrain/models/shopping_list_item.dart';
import '../mocks/mock_database_helper.dart';

void main() {
  late MockDatabaseHelper dbHelper;

  setUp(() {
    dbHelper = MockDatabaseHelper();
  });

  tearDown(() {
    dbHelper.resetAllData();
  });

  group('Shopping List CRUD Operations', () {
    test('can insert shopping list', () async {
      final shoppingList = ShoppingList(
        name: 'Jan 24-30',
        dateCreated: DateTime(2026, 1, 26),
        startDate: DateTime(2026, 1, 24),
        endDate: DateTime(2026, 1, 30),
      );

      final id = await dbHelper.insertShoppingList(shoppingList);

      expect(id, isA<int>());
      expect(id, greaterThan(0));
    });

    test('can retrieve shopping list by id', () async {
      final shoppingList = ShoppingList(
        name: 'Jan 24-30',
        dateCreated: DateTime(2026, 1, 26),
        startDate: DateTime(2026, 1, 24),
        endDate: DateTime(2026, 1, 30),
      );

      final id = await dbHelper.insertShoppingList(shoppingList);
      final retrieved = await dbHelper.getShoppingList(id);

      expect(retrieved, isNotNull);
      expect(retrieved!.id, id);
      expect(retrieved.name, 'Jan 24-30');
      expect(retrieved.startDate, DateTime(2026, 1, 24));
      expect(retrieved.endDate, DateTime(2026, 1, 30));
    });

    test('can get shopping list for date range', () async {
      final list1 = ShoppingList(
        name: 'Jan 24-30',
        dateCreated: DateTime(2026, 1, 26),
        startDate: DateTime(2026, 1, 24),
        endDate: DateTime(2026, 1, 30),
      );

      final list2 = ShoppingList(
        name: 'Feb 1-7',
        dateCreated: DateTime(2026, 2, 1),
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 2, 7),
      );

      await dbHelper.insertShoppingList(list1);
      await dbHelper.insertShoppingList(list2);

      final retrieved = await dbHelper.getShoppingListForDateRange(
        DateTime(2026, 1, 24),
        DateTime(2026, 1, 30),
      );

      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Jan 24-30');
    });

    test('can delete shopping list', () async {
      final shoppingList = ShoppingList(
        name: 'Jan 24-30',
        dateCreated: DateTime(2026, 1, 26),
        startDate: DateTime(2026, 1, 24),
        endDate: DateTime(2026, 1, 30),
      );

      final id = await dbHelper.insertShoppingList(shoppingList);

      // Verify it exists
      expect(await dbHelper.getShoppingList(id), isNotNull);

      // Delete it
      await dbHelper.deleteShoppingList(id);

      // Verify it's gone
      expect(await dbHelper.getShoppingList(id), isNull);
    });
  });

  group('Shopping List Item CRUD Operations', () {
    test('can insert shopping list item', () async {
      // First create a shopping list
      final shoppingList = ShoppingList(
        name: 'Jan 24-30',
        dateCreated: DateTime(2026, 1, 26),
        startDate: DateTime(2026, 1, 24),
        endDate: DateTime(2026, 1, 30),
      );
      final listId = await dbHelper.insertShoppingList(shoppingList);

      // Now add an item
      final item = ShoppingListItem(
        shoppingListId: listId,
        ingredientName: 'Tomato',
        quantity: 500,
        unit: 'g',
        category: 'Vegetables',
      );

      final itemId = await dbHelper.insertShoppingListItem(item);

      expect(itemId, isA<int>());
      expect(itemId, greaterThan(0));
    });

    test('can retrieve shopping list item by id', () async {
      final shoppingList = ShoppingList(
        name: 'Jan 24-30',
        dateCreated: DateTime(2026, 1, 26),
        startDate: DateTime(2026, 1, 24),
        endDate: DateTime(2026, 1, 30),
      );
      final listId = await dbHelper.insertShoppingList(shoppingList);

      final item = ShoppingListItem(
        shoppingListId: listId,
        ingredientName: 'Tomato',
        quantity: 500,
        unit: 'g',
        category: 'Vegetables',
        isPurchased: false,
      );

      final itemId = await dbHelper.insertShoppingListItem(item);
      final retrieved = await dbHelper.getShoppingListItem(itemId);

      expect(retrieved, isNotNull);
      expect(retrieved!.id, itemId);
      expect(retrieved.ingredientName, 'Tomato');
      expect(retrieved.quantity, 500);
      expect(retrieved.unit, 'g');
      expect(retrieved.category, 'Vegetables');
      expect(retrieved.isPurchased, false);
    });

    test('can get all items for a shopping list', () async {
      final shoppingList = ShoppingList(
        name: 'Jan 24-30',
        dateCreated: DateTime(2026, 1, 26),
        startDate: DateTime(2026, 1, 24),
        endDate: DateTime(2026, 1, 30),
      );
      final listId = await dbHelper.insertShoppingList(shoppingList);

      final item1 = ShoppingListItem(
        shoppingListId: listId,
        ingredientName: 'Tomato',
        quantity: 500,
        unit: 'g',
        category: 'Vegetables',
      );

      final item2 = ShoppingListItem(
        shoppingListId: listId,
        ingredientName: 'Chicken',
        quantity: 600,
        unit: 'g',
        category: 'Proteins',
      );

      await dbHelper.insertShoppingListItem(item1);
      await dbHelper.insertShoppingListItem(item2);

      final items = await dbHelper.getShoppingListItems(listId);

      expect(items.length, 2);
      expect(items[0].ingredientName, 'Tomato');
      expect(items[1].ingredientName, 'Chicken');
    });

    test('can update shopping list item', () async {
      final shoppingList = ShoppingList(
        name: 'Jan 24-30',
        dateCreated: DateTime(2026, 1, 26),
        startDate: DateTime(2026, 1, 24),
        endDate: DateTime(2026, 1, 30),
      );
      final listId = await dbHelper.insertShoppingList(shoppingList);

      final item = ShoppingListItem(
        shoppingListId: listId,
        ingredientName: 'Tomato',
        quantity: 500,
        unit: 'g',
        category: 'Vegetables',
        isPurchased: false,
      );

      final itemId = await dbHelper.insertShoppingListItem(item);

      // Update the item (mark as purchased)
      final updatedItem = item.copyWith(id: itemId, isPurchased: true);
      await dbHelper.updateShoppingListItem(updatedItem);

      // Retrieve and verify
      final retrieved = await dbHelper.getShoppingListItem(itemId);
      expect(retrieved, isNotNull);
      expect(retrieved!.isPurchased, true);
    });

    test('can delete shopping list item', () async {
      final shoppingList = ShoppingList(
        name: 'Jan 24-30',
        dateCreated: DateTime(2026, 1, 26),
        startDate: DateTime(2026, 1, 24),
        endDate: DateTime(2026, 1, 30),
      );
      final listId = await dbHelper.insertShoppingList(shoppingList);

      final item = ShoppingListItem(
        shoppingListId: listId,
        ingredientName: 'Tomato',
        quantity: 500,
        unit: 'g',
        category: 'Vegetables',
      );

      final itemId = await dbHelper.insertShoppingListItem(item);

      // Verify it exists
      expect(await dbHelper.getShoppingListItem(itemId), isNotNull);

      // Delete it
      await dbHelper.deleteShoppingListItem(itemId);

      // Verify it's gone
      expect(await dbHelper.getShoppingListItem(itemId), isNull);
    });
  });
}
