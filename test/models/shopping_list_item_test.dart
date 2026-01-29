// test/models/shopping_list_item_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/shopping_list_item.dart';

void main() {
  group('ShoppingListItem', () {
    test('creates with required fields', () {
      final item = ShoppingListItem(
        shoppingListId: 1,
        ingredientName: 'Tomato',
        quantity: 500,
        unit: 'g',
        category: 'Vegetables',
      );

      expect(item.id, isNull);
      expect(item.shoppingListId, 1);
      expect(item.ingredientName, 'Tomato');
      expect(item.quantity, 500);
      expect(item.unit, 'g');
      expect(item.category, 'Vegetables');
      expect(item.toBuy, true); // Default value
    });

    test('converts to map correctly', () {
      final item = ShoppingListItem(
        id: 42,
        shoppingListId: 1,
        ingredientName: 'Tomato',
        quantity: 500,
        unit: 'g',
        category: 'Vegetables',
        toBuy: true,
      );

      final map = item.toMap();

      expect(map['id'], 42);
      expect(map['shopping_list_id'], 1);
      expect(map['ingredient_name'], 'Tomato');
      expect(map['quantity'], 500.0);
      expect(map['unit'], 'g');
      expect(map['category'], 'Vegetables');
      expect(map['to_buy'], 1); // SQLite uses 1 for true
    });

    test('creates from map correctly', () {
      final map = {
        'id': 42,
        'shopping_list_id': 1,
        'ingredient_name': 'Tomato',
        'quantity': 500.0,
        'unit': 'g',
        'category': 'Vegetables',
        'to_buy': 1,
      };

      final item = ShoppingListItem.fromMap(map);

      expect(item.id, 42);
      expect(item.shoppingListId, 1);
      expect(item.ingredientName, 'Tomato');
      expect(item.quantity, 500.0);
      expect(item.unit, 'g');
      expect(item.category, 'Vegetables');
      expect(item.toBuy, true);
    });

    test('copyWith creates new instance with updated fields', () {
      final original = ShoppingListItem(
        id: 42,
        shoppingListId: 1,
        ingredientName: 'Tomato',
        quantity: 500,
        unit: 'g',
        category: 'Vegetables',
        toBuy: true,
      );

      final updated = original.copyWith(toBuy: false);

      expect(updated.toBuy, false);
      expect(updated.id, 42);
      expect(updated.ingredientName, 'Tomato');

      // Original should remain unchanged
      expect(original.toBuy, true);
    });

    test('equality based on id', () {
      final item1 = ShoppingListItem(
        id: 42,
        shoppingListId: 1,
        ingredientName: 'Tomato',
        quantity: 500,
        unit: 'g',
        category: 'Vegetables',
      );

      final item2 = ShoppingListItem(
        id: 42,
        shoppingListId: 2,
        ingredientName: 'Different',
        quantity: 100,
        unit: 'kg',
        category: 'Other',
      );

      final item3 = ShoppingListItem(
        id: 99,
        shoppingListId: 1,
        ingredientName: 'Tomato',
        quantity: 500,
        unit: 'g',
        category: 'Vegetables',
      );

      expect(item1 == item2, isTrue); // Same id
      expect(item1 == item3, isFalse); // Different id
      expect(item1.hashCode, item2.hashCode); // Same id -> same hashCode
    });

    test('roundtrip serialization preserves data', () {
      final original = ShoppingListItem(
        id: 42,
        shoppingListId: 1,
        ingredientName: 'Tomato',
        quantity: 500,
        unit: 'g',
        category: 'Vegetables',
        toBuy: true,
      );

      // Serialize to map and back
      final map = original.toMap();
      final restored = ShoppingListItem.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.shoppingListId, original.shoppingListId);
      expect(restored.ingredientName, original.ingredientName);
      expect(restored.quantity, original.quantity);
      expect(restored.unit, original.unit);
      expect(restored.category, original.category);
      expect(restored.toBuy, original.toBuy);
    });
  });
}
