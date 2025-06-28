import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/utils/quantity_formatter.dart';

void main() {
  group('QuantityFormatter', () {
    group('formats whole numbers without decimals', () {
      test('formats 1.0 as "1"', () {
        expect(QuantityFormatter.format(1.0), equals('1'));
      });

      test('formats 2.0 as "2"', () {
        expect(QuantityFormatter.format(2.0), equals('2'));
      });

      test('formats 300.0 as "300"', () {
        expect(QuantityFormatter.format(300.0), equals('300'));
      });

      test('formats 0.0 as "0"', () {
        expect(QuantityFormatter.format(0.0), equals('0'));
      });

      test('formats 10.0 as "10"', () {
        expect(QuantityFormatter.format(10.0), equals('10'));
      });
    });

    group('preserves meaningful decimals', () {
      test('formats 2.5 as "2.5"', () {
        expect(QuantityFormatter.format(2.5), equals('2.5'));
      });

      test('formats 1.25 as "1.25"', () {
        expect(QuantityFormatter.format(1.25), equals('1.25'));
      });

      test('formats 0.5 as "0.5"', () {
        expect(QuantityFormatter.format(0.5), equals('0.5'));
      });

      test('formats 0.75 as "0.75"', () {
        expect(QuantityFormatter.format(0.75), equals('0.75'));
      });

      test('formats 3.33 as "3.33"', () {
        expect(QuantityFormatter.format(3.33), equals('3.33'));
      });
    });

    group('handles precision correctly', () {
      test('formats 1.333 as "1.33"', () {
        expect(QuantityFormatter.format(1.333), equals('1.33'));
      });

      test('formats 2.666 as "2.67"', () {
        expect(QuantityFormatter.format(2.666), equals('2.67'));
      });

      test('formats 1.999 as "2"', () {
        expect(QuantityFormatter.format(1.999), equals('2'));
      });

      test('formats 0.123 as "0.12"', () {
        expect(QuantityFormatter.format(0.123), equals('0.12'));
      });

      test('formats 0.1234567 as "0.12"', () {
        expect(QuantityFormatter.format(0.1234567), equals('0.12'));
      });
    });

    group('removes trailing zeros', () {
      test('formats 2.50 as "2.5"', () {
        expect(QuantityFormatter.format(2.50), equals('2.5'));
      });

      test('formats 1.10 as "1.1"', () {
        expect(QuantityFormatter.format(1.10), equals('1.1'));
      });

      test('formats 3.000 as "3"', () {
        expect(QuantityFormatter.format(3.000), equals('3'));
      });
    });

    group('handles edge cases', () {
      test('formats very small positive numbers', () {
        expect(QuantityFormatter.format(0.01), equals('0.01'));
        expect(QuantityFormatter.format(0.001), equals('0'));
      });

      test('formats negative numbers correctly', () {
        expect(QuantityFormatter.format(-1.0), equals('-1'));
        expect(QuantityFormatter.format(-2.5), equals('-2.5'));
        expect(QuantityFormatter.format(-0.75), equals('-0.75'));
      });

      test('formats very large numbers', () {
        expect(QuantityFormatter.format(1000.0), equals('1000'));
        expect(QuantityFormatter.format(9999.99), equals('9999.99'));
        expect(QuantityFormatter.format(1000.5), equals('1000.5'));
      });
    });

    group('common cooking scenarios', () {
      test('formats typical recipe quantities', () {
        // Common whole number quantities
        expect(QuantityFormatter.format(1.0), equals('1')); // 1 cup
        expect(QuantityFormatter.format(2.0), equals('2')); // 2 cups
        expect(QuantityFormatter.format(3.0), equals('3')); // 3 cloves

        // Common fractional quantities
        expect(QuantityFormatter.format(0.5), equals('0.5')); // 1/2 cup
        expect(QuantityFormatter.format(0.25), equals('0.25')); // 1/4 cup
        expect(QuantityFormatter.format(0.75), equals('0.75')); // 3/4 cup
        expect(QuantityFormatter.format(1.5), equals('1.5')); // 1 1/2 cups

        // Common precise quantities
        expect(QuantityFormatter.format(2.5), equals('2.5')); // 2 1/2 cups
        expect(QuantityFormatter.format(1.25), equals('1.25')); // 1 1/4 cups
      });

      test('formats weight measurements', () {
        expect(QuantityFormatter.format(300.0), equals('300')); // 300g
        expect(QuantityFormatter.format(450.0), equals('450')); // 450g
        expect(QuantityFormatter.format(1000.0), equals('1000')); // 1kg equivalent
      });

      test('formats liquid measurements', () {
        expect(QuantityFormatter.format(250.0), equals('250')); // 250ml
        expect(QuantityFormatter.format(500.0), equals('500')); // 500ml
        expect(QuantityFormatter.format(1.5), equals('1.5')); // 1.5 liters
      });
    });
  });
}