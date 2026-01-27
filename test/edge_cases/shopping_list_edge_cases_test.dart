// test/edge_cases/shopping_list_edge_cases_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/services/shopping_list_service.dart';
import 'package:gastrobrain/models/shopping_list.dart';
import 'package:gastrobrain/models/shopping_list_item.dart';

import '../mocks/mock_database_helper.dart';

/// Edge case tests for shopping list feature
///
/// Covers boundary conditions, error scenarios, and edge cases that
/// might occur during normal usage of the shopping list feature.
void main() {
  group('Shopping List Edge Cases', () {
    late MockDatabaseHelper mockDbHelper;
    late ShoppingListService shoppingListService;

    setUp(() {
      mockDbHelper = MockDatabaseHelper();
      shoppingListService = ShoppingListService(mockDbHelper);
    });

    tearDown(() {
      mockDbHelper.resetAllData();
    });

    group('Empty States', () {
      test('handles empty shopping list (no items)', () async {
        // Arrange: Create shopping list with no items
        final shoppingList = ShoppingList(
          name: 'Empty List',
          dateCreated: DateTime.now(),
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 7),
        );

        final listId = await mockDbHelper.insertShoppingList(shoppingList);

        // Act: Retrieve items
        final items = await mockDbHelper.getShoppingListItems(listId);

        // Assert: No items returned
        expect(items, isEmpty, reason: 'Empty shopping list should have no items');

        // Verify list still exists
        final retrievedList = await mockDbHelper.getShoppingList(listId);
        expect(retrievedList, isNotNull, reason: 'Empty list should still exist');
      });
    });

    group('Boundary Conditions', () {
      test('handles very large quantities correctly', () async {
        // Arrange: Create shopping list with very large quantity
        final shoppingList = ShoppingList(
          name: 'Large Quantity List',
          dateCreated: DateTime.now(),
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 7),
        );

        final listId = await mockDbHelper.insertShoppingList(shoppingList);

        final item = ShoppingListItem(
          shoppingListId: listId,
          ingredientName: 'Rice',
          quantity: 9999.9,
          unit: 'kg',
          category: 'Grains',
          isPurchased: false,
        );

        // Act: Insert item with large quantity
        final itemId = await mockDbHelper.insertShoppingListItem(item);

        // Assert: Item stored correctly
        final retrievedItem = await mockDbHelper.getShoppingListItem(itemId);
        expect(retrievedItem, isNotNull);
        expect(retrievedItem!.quantity, equals(9999.9),
            reason: 'Large quantity should be stored accurately');
        expect(retrievedItem.unit, equals('kg'));
      });

      test('handles zero quantity items (to taste)', () async {
        // Arrange: Create shopping list with zero quantity item
        final shoppingList = ShoppingList(
          name: 'To Taste List',
          dateCreated: DateTime.now(),
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 7),
        );

        final listId = await mockDbHelper.insertShoppingList(shoppingList);

        final item = ShoppingListItem(
          shoppingListId: listId,
          ingredientName: 'Oregano',
          quantity: 0,
          unit: 'g',
          category: 'Seasonings',
          isPurchased: false,
        );

        // Act: Insert zero quantity item
        final itemId = await mockDbHelper.insertShoppingListItem(item);

        // Assert: Zero quantity stored correctly
        final retrievedItem = await mockDbHelper.getShoppingListItem(itemId);
        expect(retrievedItem, isNotNull);
        expect(retrievedItem!.quantity, equals(0),
            reason: 'Zero quantity (to taste) should be stored');
        expect(retrievedItem.ingredientName, equals('Oregano'));
      });

      test('handles very long ingredient names', () async {
        // Arrange: Create shopping list with very long ingredient name
        final longName = 'A' * 200; // 200 character ingredient name

        final shoppingList = ShoppingList(
          name: 'Long Name List',
          dateCreated: DateTime.now(),
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 7),
        );

        final listId = await mockDbHelper.insertShoppingList(shoppingList);

        final item = ShoppingListItem(
          shoppingListId: listId,
          ingredientName: longName,
          quantity: 100,
          unit: 'g',
          category: 'Other',
          isPurchased: false,
        );

        // Act: Insert item with long name
        final itemId = await mockDbHelper.insertShoppingListItem(item);

        // Assert: Long name stored correctly
        final retrievedItem = await mockDbHelper.getShoppingListItem(itemId);
        expect(retrievedItem, isNotNull);
        expect(retrievedItem!.ingredientName, equals(longName),
            reason: 'Long ingredient name should be stored fully');
        expect(retrievedItem.ingredientName.length, equals(200));
      });
    });

    group('Error Scenarios', () {
      test('handles non-existent shopping list ID gracefully', () async {
        // Act: Try to retrieve non-existent shopping list
        final nonExistentList = await mockDbHelper.getShoppingList(99999);

        // Assert: Returns null without error
        expect(nonExistentList, isNull,
            reason: 'Non-existent shopping list should return null');
      });

      test('handles toggle on non-existent item gracefully', () async {
        // Act: Try to toggle non-existent item
        // Should not throw error
        await shoppingListService.toggleItemPurchased(99999);

        // Assert: No exception thrown (test completes successfully)
        expect(true, isTrue, reason: 'Toggle on non-existent item should not crash');
      });
    });
  });
}
