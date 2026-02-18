import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/core/services/shopping_list_service.dart';
import 'package:gastrobrain/models/shopping_list.dart';
import 'package:gastrobrain/models/shopping_list_item.dart';
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

    test('converts teaspoons to tablespoons', () {
      // 3 tsp = 1 tbsp
      expect(service.convertToCommonUnit(3, 'tsp', 'tbsp'), 1.0);
      expect(service.convertToCommonUnit(6, 'tsp', 'tbsp'), 2.0);
    });

    test('converts tablespoons to teaspoons', () {
      expect(service.convertToCommonUnit(1, 'tbsp', 'tsp'), 3.0);
      expect(service.convertToCommonUnit(2, 'tbsp', 'tsp'), 6.0);
    });

    test('converts tablespoons to cups', () {
      // 16 tbsp = 1 cup
      expect(service.convertToCommonUnit(16, 'tbsp', 'cup'), 1.0);
      expect(service.convertToCommonUnit(8, 'tbsp', 'cup'), 0.5);
    });

    test('converts cups to tablespoons', () {
      expect(service.convertToCommonUnit(1, 'cup', 'tbsp'), 16.0);
    });

    test('converts teaspoons to cups', () {
      // 48 tsp = 1 cup
      expect(service.convertToCommonUnit(48, 'tsp', 'cup'), 1.0);
    });

    test('converts cloves to heads', () {
      // 10 cloves = 1 head
      expect(service.convertToCommonUnit(10, 'clove', 'head'), 1.0);
      expect(service.convertToCommonUnit(5, 'clove', 'head'), 0.5);
    });

    test('converts heads to cloves', () {
      expect(service.convertToCommonUnit(1, 'head', 'clove'), 10.0);
    });
  });

  group('Exclusion Rule (Salt Rule)', () {
    test('excludes salt with quantity zero', () {
      final ingredients = [
        {
          'name': 'Salt',
          'quantity': 0.0,
          'unit': 'g',
          'category': 'Seasonings'
        },
        {
          'name': 'Tomato',
          'quantity': 500.0,
          'unit': 'g',
          'category': 'Vegetables'
        },
      ];

      final filtered = service.applyExclusionRule(ingredients);

      expect(filtered.length, 1);
      expect(filtered[0]['name'], 'Tomato');
    });

    test('includes salt with quantity greater than zero', () {
      final ingredients = [
        {
          'name': 'Salt',
          'quantity': 5.0,
          'unit': 'g',
          'category': 'Seasonings'
        },
        {
          'name': 'Tomato',
          'quantity': 500.0,
          'unit': 'g',
          'category': 'Vegetables'
        },
      ];

      final filtered = service.applyExclusionRule(ingredients);

      expect(filtered.length, 2);
      expect(filtered[0]['name'], 'Salt');
      expect(filtered[1]['name'], 'Tomato');
    });

    test('includes non-excluded ingredients with quantity zero', () {
      final ingredients = [
        {'name': 'Oregano', 'quantity': 0.0, 'unit': 'g', 'category': 'Spices'},
        {
          'name': 'Tomato',
          'quantity': 500.0,
          'unit': 'g',
          'category': 'Vegetables'
        },
      ];

      final filtered = service.applyExclusionRule(ingredients);

      expect(filtered.length, 2);
      expect(filtered[0]['name'], 'Oregano');
      expect(filtered[1]['name'], 'Tomato');
    });

    test('excludes all items in exclusion list when quantity is zero', () {
      final ingredients = [
        {
          'name': 'Salt',
          'quantity': 0.0,
          'unit': 'g',
          'category': 'Seasonings'
        },
        {'name': 'Water', 'quantity': 0.0, 'unit': 'ml', 'category': 'Liquids'},
        {'name': 'Oil', 'quantity': 0.0, 'unit': 'ml', 'category': 'Fats'},
        {
          'name': 'Black Pepper',
          'quantity': 0.0,
          'unit': 'g',
          'category': 'Seasonings'
        },
        {
          'name': 'Sugar',
          'quantity': 0.0,
          'unit': 'g',
          'category': 'Seasonings'
        },
        {
          'name': 'Tomato',
          'quantity': 500.0,
          'unit': 'g',
          'category': 'Vegetables'
        },
      ];

      final filtered = service.applyExclusionRule(ingredients);

      expect(filtered.length, 1);
      expect(filtered[0]['name'], 'Tomato');
    });
  });

  group('Ingredient Aggregation', () {
    test('aggregates same ingredient with same unit', () {
      final ingredients = [
        {
          'name': 'Tomato',
          'quantity': 200.0,
          'unit': 'g',
          'category': 'Vegetables'
        },
        {
          'name': 'Tomato',
          'quantity': 300.0,
          'unit': 'g',
          'category': 'Vegetables'
        },
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
        {
          'name': 'Tomato',
          'quantity': 200.0,
          'unit': 'g',
          'category': 'Vegetables'
        },
        {
          'name': 'tomato',
          'quantity': 300.0,
          'unit': 'g',
          'category': 'Vegetables'
        },
        {
          'name': 'TOMATO',
          'quantity': 100.0,
          'unit': 'g',
          'category': 'Vegetables'
        },
      ];

      final aggregated = service.aggregateIngredients(ingredients);

      expect(aggregated.length, 1);
      expect(aggregated[0]['name'], 'Tomato'); // Uses first occurrence's casing
      expect(aggregated[0]['quantity'], 600.0);
    });

    test('keeps incompatible units as separate items', () {
      final ingredients = [
        {'name': 'Flour', 'quantity': 500.0, 'unit': 'g', 'category': 'Grains'},
        {
          'name': 'Flour',
          'quantity': 2.0,
          'unit': 'cups',
          'category': 'Grains'
        },
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

    test('aggregates tsp and converts to tbsp at threshold', () {
      final ingredients = [
        {'name': 'Cumin', 'quantity': 2.0, 'unit': 'tsp', 'category': 'Spices'},
        {'name': 'Cumin', 'quantity': 1.0, 'unit': 'tsp', 'category': 'Spices'},
      ];

      final aggregated = service.aggregateIngredients(ingredients);

      expect(aggregated.length, 1);
      expect(aggregated[0]['name'], 'Cumin');
      expect(aggregated[0]['quantity'], 1.0); // 3 tsp = 1 tbsp
      expect(aggregated[0]['unit'], 'tbsp');
    });

    test('keeps tsp as-is when below threshold', () {
      final ingredients = [
        {'name': 'Cumin', 'quantity': 1.0, 'unit': 'tsp', 'category': 'Spices'},
        {'name': 'Cumin', 'quantity': 1.0, 'unit': 'tsp', 'category': 'Spices'},
      ];

      final aggregated = service.aggregateIngredients(ingredients);

      expect(aggregated.length, 1);
      expect(aggregated[0]['quantity'], 2.0); // 2 tsp stays as tsp
      expect(aggregated[0]['unit'], 'tsp');
    });

    test('aggregates tbsp and converts to cup at threshold', () {
      final ingredients = [
        {'name': 'Olive Oil', 'quantity': 8.0, 'unit': 'tbsp', 'category': 'Fats'},
        {'name': 'Olive Oil', 'quantity': 8.0, 'unit': 'tbsp', 'category': 'Fats'},
      ];

      final aggregated = service.aggregateIngredients(ingredients);

      expect(aggregated.length, 1);
      expect(aggregated[0]['quantity'], 1.0); // 16 tbsp = 1 cup
      expect(aggregated[0]['unit'], 'cup');
    });

    test('aggregates tsp and tbsp together via conversion', () {
      final ingredients = [
        {'name': 'Soy Sauce', 'quantity': 1.0, 'unit': 'tbsp', 'category': 'Condiments'},
        {'name': 'Soy Sauce', 'quantity': 3.0, 'unit': 'tsp', 'category': 'Condiments'},
      ];

      final aggregated = service.aggregateIngredients(ingredients);

      // 1 tbsp + 3 tsp = 1 tbsp + 1 tbsp = 2 tbsp (tsp converted to tbsp)
      expect(aggregated.length, 1);
      expect(aggregated[0]['quantity'], 2.0);
      expect(aggregated[0]['unit'], 'tbsp');
    });

    test('aggregates cloves and converts to head at threshold', () {
      final ingredients = [
        {'name': 'Garlic', 'quantity': 4.0, 'unit': 'clove', 'category': 'Vegetables'},
        {'name': 'Garlic', 'quantity': 6.0, 'unit': 'clove', 'category': 'Vegetables'},
      ];

      final aggregated = service.aggregateIngredients(ingredients);

      expect(aggregated.length, 1);
      expect(aggregated[0]['name'], 'Garlic');
      expect(aggregated[0]['quantity'], 1.0); // 10 cloves = 1 head
      expect(aggregated[0]['unit'], 'head');
    });

    test('keeps cloves as-is when below threshold', () {
      final ingredients = [
        {'name': 'Garlic', 'quantity': 3.0, 'unit': 'clove', 'category': 'Vegetables'},
        {'name': 'Garlic', 'quantity': 4.0, 'unit': 'clove', 'category': 'Vegetables'},
      ];

      final aggregated = service.aggregateIngredients(ingredients);

      expect(aggregated.length, 1);
      expect(aggregated[0]['quantity'], 7.0); // 7 cloves stays as cloves
      expect(aggregated[0]['unit'], 'clove');
    });

    test('aggregates cloves and heads together via conversion', () {
      final ingredients = [
        {'name': 'Garlic', 'quantity': 1.0, 'unit': 'head', 'category': 'Vegetables'},
        {'name': 'Garlic', 'quantity': 5.0, 'unit': 'clove', 'category': 'Vegetables'},
      ];

      final aggregated = service.aggregateIngredients(ingredients);

      // 1 head + 5 cloves = 10 cloves + 5 cloves = 15 cloves → 1.5 heads
      expect(aggregated.length, 1);
      expect(aggregated[0]['quantity'], 1.5);
      expect(aggregated[0]['unit'], 'head');
    });
  });

  group('Category Grouping', () {
    test('groups ingredients by category', () {
      final ingredients = [
        {
          'name': 'Tomato',
          'quantity': 500.0,
          'unit': 'g',
          'category': 'Vegetables'
        },
        {
          'name': 'Chicken',
          'quantity': 600.0,
          'unit': 'g',
          'category': 'Proteins'
        },
        {
          'name': 'Onion',
          'quantity': 200.0,
          'unit': 'g',
          'category': 'Vegetables'
        },
      ];

      final grouped = service.groupByCategory(ingredients);

      expect(grouped.keys.length, 2);
      expect(grouped['Vegetables']?.length, 2);
      expect(grouped['Proteins']?.length, 1);
    });

    test('handles missing category by defaulting to Other', () {
      final ingredients = [
        {
          'name': 'Tomato',
          'quantity': 500.0,
          'unit': 'g',
          'category': 'Vegetables'
        },
        {
          'name': 'Mystery Item',
          'quantity': 100.0,
          'unit': 'g',
          'category': null
        },
      ];

      final grouped = service.groupByCategory(ingredients);

      expect(grouped.keys.contains('Other'), isTrue);
      expect(grouped['Other']?.length, 1);
      expect(grouped['Other']?[0]['name'], 'Mystery Item');
    });

    test('preserves to taste items in grouping', () {
      final ingredients = [
        {
          'name': 'Tomato',
          'quantity': 500.0,
          'unit': 'g',
          'category': 'Vegetables'
        },
        {'name': 'Oregano', 'quantity': 0.0, 'unit': 'g', 'category': 'Spices'},
      ];

      final grouped = service.groupByCategory(ingredients);

      expect(grouped['Spices']?.length, 1);
      expect(grouped['Spices']?[0]['name'], 'Oregano');
      expect(grouped['Spices']?[0]['quantity'], 0.0);
    });
  });

  group('Main Generation Method', () {
    test('generates shopping list from empty date range', () async {
      final startDate = DateTime(2026, 1, 24);
      final endDate = DateTime(2026, 1, 30);

      // Generate shopping list (should work even with no meal plan items)
      final shoppingList = await service.generateFromDateRange(
        startDate: startDate,
        endDate: endDate,
      );

      expect(shoppingList, isNotNull);
      expect(shoppingList, isA<ShoppingList>());
      expect(shoppingList.id, isNotNull);
      expect(shoppingList.startDate, startDate);
      expect(shoppingList.endDate, endDate);
      expect(shoppingList.name, 'Jan 24-30');
    });
  });

  group('Toggle To Buy', () {
    test('toggles item from "to buy" to "not needed"', () async {
      // Create a shopping list
      final shoppingList = await service.generateFromDateRange(
        startDate: DateTime(2026, 1, 24),
        endDate: DateTime(2026, 1, 30),
      );

      // Manually add an item marked as "to buy"
      final itemId = await dbHelper.insertShoppingListItem(
        ShoppingListItem(
          shoppingListId: shoppingList.id!,
          ingredientName: 'Tomato',
          quantity: 500,
          unit: 'g',
          category: 'Vegetables',
          toBuy: true,
        ),
      );

      // Toggle it
      await service.toggleItemToBuy(itemId);

      // Verify it's not needed
      final item = await dbHelper.getShoppingListItem(itemId);
      expect(item, isNotNull);
      expect(item!.toBuy, false);
    });

    test('toggles item from "not needed" to "to buy"', () async {
      // Create a shopping list
      final shoppingList = await service.generateFromDateRange(
        startDate: DateTime(2026, 1, 24),
        endDate: DateTime(2026, 1, 30),
      );

      // Manually add an item that's not needed
      final itemId = await dbHelper.insertShoppingListItem(
        ShoppingListItem(
          shoppingListId: shoppingList.id!,
          ingredientName: 'Chicken',
          quantity: 600,
          unit: 'g',
          category: 'Proteins',
          toBuy: false,
        ),
      );

      // Toggle it
      await service.toggleItemToBuy(itemId);

      // Verify it's marked as "to buy"
      final item = await dbHelper.getShoppingListItem(itemId);
      expect(item, isNotNull);
      expect(item!.toBuy, true);
    });

    test('handles non-existent item gracefully', () async {
      // Try to toggle an item that doesn't exist
      // Should not throw an error
      await service.toggleItemToBuy(9999);
      // Test passes if no exception is thrown
    });
  });
}
