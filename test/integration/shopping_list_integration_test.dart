// test/integration/shopping_list_integration_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/services/shopping_list_service.dart';
import 'package:gastrobrain/models/shopping_list.dart';
import 'package:gastrobrain/models/shopping_list_item.dart';

import '../mocks/mock_database_helper.dart';

void main() {
  group('Shopping List Integration Tests', () {
    late MockDatabaseHelper mockDbHelper;
    late ShoppingListService shoppingListService;

    setUp(() {
      // Create fresh mock database for each test
      mockDbHelper = MockDatabaseHelper();

      // Create shopping list service with mock database
      shoppingListService = ShoppingListService(mockDbHelper);
    });

    tearDown(() {
      // Clean up after each test
      mockDbHelper.resetAllData();
    });

    test('generates empty shopping list when no meal plan exists', () async {
      // Arrange: No meal plan data in database
      final startDate = DateTime(2024, 1, 1);  // Monday
      final endDate = DateTime(2024, 1, 7);    // Sunday

      // Act: Generate shopping list
      final shoppingList = await shoppingListService.generateFromDateRange(
        startDate: startDate,
        endDate: endDate,
      );

      // Assert: Shopping list should be created but empty
      expect(shoppingList.id, isNotNull, reason: 'Shopping list should have an ID');
      expect(shoppingList.name, contains('Jan'), reason: 'Name should contain month');
      expect(shoppingList.startDate, equals(startDate));
      expect(shoppingList.endDate, equals(endDate));

      // Verify no items were created
      final items = await mockDbHelper.getShoppingListItems(shoppingList.id!);
      expect(items, isEmpty, reason: 'No items should exist for empty meal plan');
    });

    test('toggles item purchased status correctly', () async {
      // Arrange: Create a shopping list with an item
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 7);

      final shoppingList = ShoppingList(
        name: 'Test List',
        dateCreated: DateTime.now(),
        startDate: startDate,
        endDate: endDate,
      );

      final listId = await mockDbHelper.insertShoppingList(shoppingList);

      final item = ShoppingListItem(
        shoppingListId: listId,
        ingredientName: 'Chicken Breast',
        quantity: 500,
        unit: 'g',
        category: 'Meat',
        toBuy: true,
      );

      final itemId = await mockDbHelper.insertShoppingListItem(item);

      // Act: Toggle "to buy" status
      await shoppingListService.toggleItemToBuy(itemId);

      // Assert: Item should now be marked as "not needed"
      final updatedItem = await mockDbHelper.getShoppingListItem(itemId);
      expect(updatedItem, isNotNull);
      expect(updatedItem!.toBuy, isFalse,
        reason: 'Item should be marked as not needed');

      // Act: Toggle again
      await shoppingListService.toggleItemToBuy(itemId);

      // Assert: Item should now be "to buy" again
      final reToggledItem = await mockDbHelper.getShoppingListItem(itemId);
      expect(reToggledItem!.toBuy, isTrue,
        reason: 'Item should be marked as "to buy" after second toggle');
    });

    test('retrieves shopping list by date range correctly', () async {
      // Arrange: Create two shopping lists for different date ranges
      final list1Start = DateTime(2024, 1, 1);
      final list1End = DateTime(2024, 1, 7);

      final list2Start = DateTime(2024, 1, 8);
      final list2End = DateTime(2024, 1, 14);

      final shoppingList1 = ShoppingList(
        name: 'Week 1 List',
        dateCreated: DateTime.now(),
        startDate: list1Start,
        endDate: list1End,
      );

      final shoppingList2 = ShoppingList(
        name: 'Week 2 List',
        dateCreated: DateTime.now(),
        startDate: list2Start,
        endDate: list2End,
      );

      final list1Id = await mockDbHelper.insertShoppingList(shoppingList1);
      final list2Id = await mockDbHelper.insertShoppingList(shoppingList2);

      // Act: Retrieve list by date range
      final retrievedList1 = await mockDbHelper.getShoppingListForDateRange(
        list1Start,
        list1End,
      );

      final retrievedList2 = await mockDbHelper.getShoppingListForDateRange(
        list2Start,
        list2End,
      );

      // Assert: Correct lists are retrieved
      expect(retrievedList1, isNotNull);
      expect(retrievedList1!.id, equals(list1Id));
      expect(retrievedList1.name, equals('Week 1 List'));

      expect(retrievedList2, isNotNull);
      expect(retrievedList2!.id, equals(list2Id));
      expect(retrievedList2.name, equals('Week 2 List'));
    });

    test('deletes shopping list and its items correctly', () async {
      // Arrange: Create a shopping list with multiple items
      final shoppingList = ShoppingList(
        name: 'Test List',
        dateCreated: DateTime.now(),
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 7),
      );

      final listId = await mockDbHelper.insertShoppingList(shoppingList);

      // Add multiple items
      final item1 = ShoppingListItem(
        shoppingListId: listId,
        ingredientName: 'Chicken',
        quantity: 500,
        unit: 'g',
        category: 'Meat',
        toBuy: false,
      );

      final item2 = ShoppingListItem(
        shoppingListId: listId,
        ingredientName: 'Rice',
        quantity: 200,
        unit: 'g',
        category: 'Grains',
        toBuy: false,
      );

      await mockDbHelper.insertShoppingListItem(item1);
      await mockDbHelper.insertShoppingListItem(item2);

      // Verify items exist
      final itemsBeforeDelete = await mockDbHelper.getShoppingListItems(listId);
      expect(itemsBeforeDelete.length, equals(2),
        reason: 'Should have 2 items before deletion');

      // Act: Delete the shopping list
      await mockDbHelper.deleteShoppingList(listId);

      // Assert: Shopping list is deleted
      final deletedList = await mockDbHelper.getShoppingList(listId);
      expect(deletedList, isNull,
        reason: 'Shopping list should be deleted');

      // Assert: Items are also deleted (cascade delete)
      final itemsAfterDelete = await mockDbHelper.getShoppingListItems(listId);
      expect(itemsAfterDelete, isEmpty,
        reason: 'Items should be deleted with shopping list');
    });
  });
}
