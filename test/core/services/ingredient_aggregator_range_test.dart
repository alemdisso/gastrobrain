import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/core/services/ingredient_aggregator.dart';

void main() {
  late IngredientAggregator aggregator;

  setUp(() {
    aggregator = IngredientAggregator();
  });

  group('IngredientAggregator — range quantity aggregation', () {
    Map<String, dynamic> ingredient(
      String name, {
      required double quantity,
      double? quantityMax,
      String unit = 'g',
      String category = 'vegetable',
    }) {
      return {
        'name': name,
        'quantity': quantity,
        if (quantityMax != null) 'quantity_max': quantityMax,
        'unit': unit,
        'category': category,
      };
    }

    group('range + range → summed range', () {
      test('adds both min and max bounds independently', () {
        final result = aggregator.aggregateIngredients([
          ingredient('carrot', quantity: 100, quantityMax: 150),
          ingredient('carrot', quantity: 200, quantityMax: 300),
        ]);

        expect(result.length, equals(1));
        expect(result.first['quantity'], equals(300.0));
        expect(result.first['quantity_max'], equals(450.0));
      });
    });

    group('range + single → range (single treated as point)', () {
      test('single contributor expands both bounds equally', () {
        final result = aggregator.aggregateIngredients([
          ingredient('onion', quantity: 100, quantityMax: 200),
          ingredient('onion', quantity: 50),
        ]);

        expect(result.length, equals(1));
        expect(result.first['quantity'], equals(150.0));
        expect(result.first['quantity_max'], equals(250.0));
      });

      test('single + range produces same result regardless of order', () {
        final a = aggregator.aggregateIngredients([
          ingredient('onion', quantity: 50),
          ingredient('onion', quantity: 100, quantityMax: 200),
        ]);
        final b = aggregator.aggregateIngredients([
          ingredient('onion', quantity: 100, quantityMax: 200),
          ingredient('onion', quantity: 50),
        ]);

        expect(a.first['quantity'], equals(b.first['quantity']));
        expect(a.first['quantity_max'], equals(b.first['quantity_max']));
      });
    });

    group('single + single → no range produced', () {
      test('quantity_max absent when both contributors are point quantities', () {
        final result = aggregator.aggregateIngredients([
          ingredient('salt', quantity: 5),
          ingredient('salt', quantity: 3),
        ]);

        expect(result.length, equals(1));
        expect(result.first['quantity'], equals(8.0));
        expect(result.first['quantity_max'], isNull);
      });
    });

    group('unit promotion on both bounds', () {
      test('g → kg promotes quantity and quantity_max', () {
        final result = aggregator.aggregateIngredients([
          ingredient('flour', quantity: 600, quantityMax: 700),
          ingredient('flour', quantity: 500, quantityMax: 600),
        ]);

        expect(result.length, equals(1));
        expect(result.first['unit'], equals('kg'));
        expect(result.first['quantity'], closeTo(1.1, 0.001));
        expect(result.first['quantity_max'], closeTo(1.3, 0.001));
      });

      test('ml → L promotes quantity and quantity_max', () {
        final result = aggregator.aggregateIngredients([
          ingredient('water', quantity: 600, quantityMax: 700, unit: 'ml', category: 'other'),
          ingredient('water', quantity: 500, quantityMax: 600, unit: 'ml', category: 'other'),
        ]);

        expect(result.first['unit'], equals('L'));
        expect(result.first['quantity'], closeTo(1.1, 0.001));
        expect(result.first['quantity_max'], closeTo(1.3, 0.001));
      });

      test('tsp → tbsp promotes quantity and quantity_max', () {
        final result = aggregator.aggregateIngredients([
          ingredient('paprika', quantity: 2, quantityMax: 2, unit: 'tsp', category: 'spice'),
          ingredient('paprika', quantity: 2, quantityMax: 4, unit: 'tsp', category: 'spice'),
        ]);

        expect(result.first['unit'], equals('tbsp'));
        expect(result.first['quantity'], closeTo(4.0 / 3, 0.001));
        expect(result.first['quantity_max'], closeTo(6.0 / 3, 0.001));
      });

      test('clove → head promotes quantity and quantity_max', () {
        final result = aggregator.aggregateIngredients([
          ingredient('garlic', quantity: 6, quantityMax: 7, unit: 'clove', category: 'vegetable'),
          ingredient('garlic', quantity: 5, quantityMax: 6, unit: 'clove', category: 'vegetable'),
        ]);

        expect(result.first['unit'], equals('head'));
        expect(result.first['quantity'], closeTo(1.1, 0.001));
        expect(result.first['quantity_max'], closeTo(1.3, 0.001));
      });

      test('range above threshold: both bounds promoted together', () {
        final result = aggregator.aggregateIngredients([
          ingredient('butter', quantity: 1100, quantityMax: 1500),
        ]);

        expect(result.first['unit'], equals('kg'));
        expect(result.first['quantity'], closeTo(1.1, 0.001));
        expect(result.first['quantity_max'], closeTo(1.5, 0.001));
      });
    });

    group('null quantity_max passthrough', () {
      test('single ingredient with no range has null quantity_max', () {
        final result = aggregator.aggregateIngredients([
          ingredient('pepper', quantity: 5, unit: 'g'),
        ]);

        expect(result.first['quantity_max'], isNull);
      });
    });
  });
}
