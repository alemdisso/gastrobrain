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

  group('Exclusion Rule (Salt Rule)', () {
    test('excludes salt with quantity zero', () {
      final ingredients = [
        {'name': 'Salt', 'quantity': 0.0, 'unit': 'g'},
        {'name': 'Tomato', 'quantity': 500.0, 'unit': 'g'},
      ];

      final filtered = service.applyExclusionRule(ingredients);

      expect(filtered.length, 1);
      expect(filtered[0]['name'], 'Tomato');
    });

    test('includes salt with quantity greater than zero', () {
      final ingredients = [
        {'name': 'Salt', 'quantity': 5.0, 'unit': 'g'},
        {'name': 'Tomato', 'quantity': 500.0, 'unit': 'g'},
      ];

      final filtered = service.applyExclusionRule(ingredients);

      expect(filtered.length, 2);
      expect(filtered[0]['name'], 'Salt');
      expect(filtered[1]['name'], 'Tomato');
    });

    test('includes non-excluded ingredients with quantity zero', () {
      final ingredients = [
        {'name': 'Oregano', 'quantity': 0.0, 'unit': 'g'},
        {'name': 'Tomato', 'quantity': 500.0, 'unit': 'g'},
      ];

      final filtered = service.applyExclusionRule(ingredients);

      expect(filtered.length, 2);
      expect(filtered[0]['name'], 'Oregano');
      expect(filtered[1]['name'], 'Tomato');
    });

    test('excludes all items in exclusion list when quantity is zero', () {
      final ingredients = [
        {'name': 'Salt', 'quantity': 0.0, 'unit': 'g'},
        {'name': 'Water', 'quantity': 0.0, 'unit': 'ml'},
        {'name': 'Oil', 'quantity': 0.0, 'unit': 'ml'},
        {'name': 'Black Pepper', 'quantity': 0.0, 'unit': 'g'},
        {'name': 'Sugar', 'quantity': 0.0, 'unit': 'g'},
        {'name': 'Tomato', 'quantity': 500.0, 'unit': 'g'},
      ];

      final filtered = service.applyExclusionRule(ingredients);

      expect(filtered.length, 1);
      expect(filtered[0]['name'], 'Tomato');
    });
  });

  group('Ingredient Aggregation', () {
    test('aggregates same ingredient with same unit', () {
      final ingredients = [
        {'name': 'Tomato', 'quantity': 200.0, 'unit': 'g', 'category': 'Vegetables'},
        {'name': 'Tomato', 'quantity': 300.0, 'unit': 'g', 'category': 'Vegetables'},
      ];

      final aggregated = service.aggregateIngredients(ingredients);

      expect(aggregated.length, 1);
      expect(aggregated[0]['name'], 'Tomato');
      expect(aggregated[0]['quantity'], 500.0);
      expect(aggregated[0]['unit'], 'g');
      expect(aggregated[0]['category'], 'Vegetables');
    });

    test('aggregates and converts compatible units', () {
      final ingredients = [
        {'name': 'Flour', 'quantity': 200.0, 'unit': 'g', 'category': 'Grains'},
        {'name': 'Flour', 'quantity': 1.0, 'unit': 'kg', 'category': 'Grains'},
      ];

      final aggregated = service.aggregateIngredients(ingredients);

      expect(aggregated.length, 1);
      expect(aggregated[0]['name'], 'Flour');
      // 200g + 1kg = 1200g = 1.2kg (auto-converted because >= 1000)
      expect(aggregated[0]['quantity'], 1.2);
      expect(aggregated[0]['unit'], 'kg');
    });

    test('aggregates with case-insensitive name matching', () {
      final ingredients = [
        {'name': 'Tomato', 'quantity': 200.0, 'unit': 'g', 'category': 'Vegetables'},
        {'name': 'tomato', 'quantity': 300.0, 'unit': 'g', 'category': 'Vegetables'},
        {'name': 'TOMATO', 'quantity': 100.0, 'unit': 'g', 'category': 'Vegetables'},
      ];

      final aggregated = service.aggregateIngredients(ingredients);

      expect(aggregated.length, 1);
      expect(aggregated[0]['name'], 'Tomato'); // Uses first occurrence's casing
      expect(aggregated[0]['quantity'], 600.0);
    });

    test('keeps incompatible units as separate items', () {
      final ingredients = [
        {'name': 'Flour', 'quantity': 500.0, 'unit': 'g', 'category': 'Grains'},
        {'name': 'Flour', 'quantity': 2.0, 'unit': 'cups', 'category': 'Grains'},
      ];

      final aggregated = service.aggregateIngredients(ingredients);

      // Should remain as 2 separate items since g and cups are incompatible
      expect(aggregated.length, 2);
    });

    test('converts to larger unit when quantity reaches 1000', () {
      final ingredients = [
        {'name': 'Rice', 'quantity': 600.0, 'unit': 'g', 'category': 'Grains'},
        {'name': 'Rice', 'quantity': 400.0, 'unit': 'g', 'category': 'Grains'},
      ];

      final aggregated = service.aggregateIngredients(ingredients);

      expect(aggregated.length, 1);
      expect(aggregated[0]['name'], 'Rice');
      expect(aggregated[0]['quantity'], 1.0); // 1000g = 1kg
      expect(aggregated[0]['unit'], 'kg');
    });
  });
}
