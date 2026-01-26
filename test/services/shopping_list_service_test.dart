import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/services/shopping_list_service.dart';
import '../mocks/mock_database_helper.dart';

void main() {
  late ShoppingListService service;
  late MockDatabaseHelper dbHelper;

  setUp(() {
    dbHelper = MockDatabaseHelper();
    service = ShoppingListService(dbHelper);
  });

  tearDown(() {
    dbHelper.resetAllData();
  });

  group('Unit Conversion', () {
    test('converts grams to kilograms', () {
      // 1500g = 1.5kg
      final result = service.convertToCommonUnit(1500, 'g', 'kg');
      expect(result, 1.5);
    });

    test('converts kilograms to grams', () {
      // 2kg = 2000g
      final result = service.convertToCommonUnit(2, 'kg', 'g');
      expect(result, 2000);
    });

    test('converts milliliters to liters', () {
      // 2500ml = 2.5L
      final result = service.convertToCommonUnit(2500, 'ml', 'L');
      expect(result, 2.5);
    });

    test('converts liters to milliliters', () {
      // 1.5L = 1500ml
      final result = service.convertToCommonUnit(1.5, 'L', 'ml');
      expect(result, 1500);
    });

    test('returns same value when units are identical', () {
      final result = service.convertToCommonUnit(500, 'g', 'g');
      expect(result, 500);
    });

    test('throws exception for incompatible units', () {
      // Trying to convert g to ml (weight to volume)
      expect(
        () => service.convertToCommonUnit(100, 'g', 'ml'),
        throwsA(isA<UnitConversionException>()),
      );
    });

    test('handles case-insensitive unit names', () {
      // Should work with uppercase, lowercase, mixed case
      expect(service.convertToCommonUnit(1000, 'G', 'KG'), 1);
      expect(service.convertToCommonUnit(1, 'KG', 'g'), 1000);
      expect(service.convertToCommonUnit(1000, 'ML', 'l'), 1);
    });
  });
}
