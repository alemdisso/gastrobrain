// test/models/shopping_list_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/shopping_list.dart';

void main() {
  group('ShoppingList', () {
    test('creates with required fields', () {
      final dateCreated = DateTime(2026, 1, 26, 10, 0);
      final startDate = DateTime(2026, 1, 24);
      final endDate = DateTime(2026, 1, 30);

      final shoppingList = ShoppingList(
        name: 'Jan 24-30',
        dateCreated: dateCreated,
        startDate: startDate,
        endDate: endDate,
      );

      expect(shoppingList.id, isNull);
      expect(shoppingList.name, 'Jan 24-30');
      expect(shoppingList.dateCreated, dateCreated);
      expect(shoppingList.startDate, startDate);
      expect(shoppingList.endDate, endDate);
    });

    test('creates with optional id', () {
      final dateCreated = DateTime(2026, 1, 26, 10, 0);
      final startDate = DateTime(2026, 1, 24);
      final endDate = DateTime(2026, 1, 30);

      final shoppingList = ShoppingList(
        id: 42,
        name: 'Jan 24-30',
        dateCreated: dateCreated,
        startDate: startDate,
        endDate: endDate,
      );

      expect(shoppingList.id, 42);
      expect(shoppingList.name, 'Jan 24-30');
    });

    test('converts to map correctly', () {
      final dateCreated = DateTime(2026, 1, 26, 10, 0);
      final startDate = DateTime(2026, 1, 24);
      final endDate = DateTime(2026, 1, 30);

      final shoppingList = ShoppingList(
        id: 42,
        name: 'Jan 24-30',
        dateCreated: dateCreated,
        startDate: startDate,
        endDate: endDate,
      );

      final map = shoppingList.toMap();

      expect(map['id'], 42);
      expect(map['name'], 'Jan 24-30');
      expect(map['date_created'], dateCreated.millisecondsSinceEpoch);
      expect(map['start_date'], startDate.millisecondsSinceEpoch);
      expect(map['end_date'], endDate.millisecondsSinceEpoch);
    });

    test('converts to map correctly without id', () {
      final dateCreated = DateTime(2026, 1, 26, 10, 0);
      final startDate = DateTime(2026, 1, 24);
      final endDate = DateTime(2026, 1, 30);

      final shoppingList = ShoppingList(
        name: 'Jan 24-30',
        dateCreated: dateCreated,
        startDate: startDate,
        endDate: endDate,
      );

      final map = shoppingList.toMap();

      expect(map['id'], isNull);
      expect(map['name'], 'Jan 24-30');
    });

    test('creates from map correctly', () {
      final dateCreated = DateTime(2026, 1, 26, 10, 0);
      final startDate = DateTime(2026, 1, 24);
      final endDate = DateTime(2026, 1, 30);

      final map = {
        'id': 42,
        'name': 'Jan 24-30',
        'date_created': dateCreated.millisecondsSinceEpoch,
        'start_date': startDate.millisecondsSinceEpoch,
        'end_date': endDate.millisecondsSinceEpoch,
      };

      final shoppingList = ShoppingList.fromMap(map);

      expect(shoppingList.id, 42);
      expect(shoppingList.name, 'Jan 24-30');
      expect(shoppingList.dateCreated, dateCreated);
      expect(shoppingList.startDate, startDate);
      expect(shoppingList.endDate, endDate);
    });

    test('creates from map correctly without id', () {
      final dateCreated = DateTime(2026, 1, 26, 10, 0);
      final startDate = DateTime(2026, 1, 24);
      final endDate = DateTime(2026, 1, 30);

      final map = {
        'id': null,
        'name': 'Jan 24-30',
        'date_created': dateCreated.millisecondsSinceEpoch,
        'start_date': startDate.millisecondsSinceEpoch,
        'end_date': endDate.millisecondsSinceEpoch,
      };

      final shoppingList = ShoppingList.fromMap(map);

      expect(shoppingList.id, isNull);
      expect(shoppingList.name, 'Jan 24-30');
    });

    test('copyWith creates new instance with updated fields', () {
      final dateCreated = DateTime(2026, 1, 26, 10, 0);
      final startDate = DateTime(2026, 1, 24);
      final endDate = DateTime(2026, 1, 30);

      final original = ShoppingList(
        id: 42,
        name: 'Jan 24-30',
        dateCreated: dateCreated,
        startDate: startDate,
        endDate: endDate,
      );

      final updated = original.copyWith(
        name: 'Feb 1-7',
        id: 43,
      );

      expect(updated.id, 43);
      expect(updated.name, 'Feb 1-7');
      expect(updated.dateCreated, dateCreated);
      expect(updated.startDate, startDate);
      expect(updated.endDate, endDate);

      // Original should remain unchanged
      expect(original.id, 42);
      expect(original.name, 'Jan 24-30');
    });

    test('copyWith without parameters creates identical copy', () {
      final dateCreated = DateTime(2026, 1, 26, 10, 0);
      final startDate = DateTime(2026, 1, 24);
      final endDate = DateTime(2026, 1, 30);

      final original = ShoppingList(
        id: 42,
        name: 'Jan 24-30',
        dateCreated: dateCreated,
        startDate: startDate,
        endDate: endDate,
      );

      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.name, original.name);
      expect(copy.dateCreated, original.dateCreated);
      expect(copy.startDate, original.startDate);
      expect(copy.endDate, original.endDate);
    });

    test('equality based on id', () {
      final dateCreated = DateTime(2026, 1, 26, 10, 0);
      final startDate = DateTime(2026, 1, 24);
      final endDate = DateTime(2026, 1, 30);

      final list1 = ShoppingList(
        id: 42,
        name: 'Jan 24-30',
        dateCreated: dateCreated,
        startDate: startDate,
        endDate: endDate,
      );

      final list2 = ShoppingList(
        id: 42,
        name: 'Different Name',
        dateCreated: DateTime(2025, 1, 1),
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 7),
      );

      final list3 = ShoppingList(
        id: 99,
        name: 'Jan 24-30',
        dateCreated: dateCreated,
        startDate: startDate,
        endDate: endDate,
      );

      expect(list1 == list2, isTrue); // Same id
      expect(list1 == list3, isFalse); // Different id
      expect(list1.hashCode, list2.hashCode); // Same id -> same hashCode
    });

    test('toString provides readable output', () {
      final dateCreated = DateTime(2026, 1, 26, 10, 0);
      final startDate = DateTime(2026, 1, 24);
      final endDate = DateTime(2026, 1, 30);

      final shoppingList = ShoppingList(
        id: 42,
        name: 'Jan 24-30',
        dateCreated: dateCreated,
        startDate: startDate,
        endDate: endDate,
      );

      final string = shoppingList.toString();

      expect(string, contains('ShoppingList'));
      expect(string, contains('id: 42'));
      expect(string, contains('name: Jan 24-30'));
    });

    test('roundtrip serialization preserves data', () {
      final dateCreated = DateTime(2026, 1, 26, 10, 0);
      final startDate = DateTime(2026, 1, 24);
      final endDate = DateTime(2026, 1, 30);

      final original = ShoppingList(
        id: 42,
        name: 'Jan 24-30',
        dateCreated: dateCreated,
        startDate: startDate,
        endDate: endDate,
      );

      // Serialize to map and back
      final map = original.toMap();
      final restored = ShoppingList.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.dateCreated, original.dateCreated);
      expect(restored.startDate, original.startDate);
      expect(restored.endDate, original.endDate);
    });
  });
}