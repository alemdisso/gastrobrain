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

    group('formats common fractions', () {
      test('formats 0.5 as "½"', () {
        expect(QuantityFormatter.format(0.5), equals('½'));
      });

      test('formats 0.25 as "¼"', () {
        expect(QuantityFormatter.format(0.25), equals('¼'));
      });

      test('formats 0.75 as "¾"', () {
        expect(QuantityFormatter.format(0.75), equals('¾'));
      });

      test('formats 0.333... as "⅓"', () {
        expect(QuantityFormatter.format(1.0 / 3.0), equals('⅓'));
      });

      test('formats 0.666... as "⅔"', () {
        expect(QuantityFormatter.format(2.0 / 3.0), equals('⅔'));
      });
    });

    group('formats less common fractions', () {
      test('formats 0.2 as "⅕"', () {
        expect(QuantityFormatter.format(0.2), equals('⅕'));
      });

      test('formats 0.4 as "⅖"', () {
        expect(QuantityFormatter.format(0.4), equals('⅖'));
      });

      test('formats 0.6 as "⅗"', () {
        expect(QuantityFormatter.format(0.6), equals('⅗'));
      });

      test('formats 0.8 as "⅘"', () {
        expect(QuantityFormatter.format(0.8), equals('⅘'));
      });

      test('formats 0.166... as "⅙"', () {
        expect(QuantityFormatter.format(1.0 / 6.0), equals('⅙'));
      });

      test('formats 0.125 as "⅛"', () {
        expect(QuantityFormatter.format(0.125), equals('⅛'));
      });
    });

    group('formats mixed numbers', () {
      test('formats 1.5 as "1½"', () {
        expect(QuantityFormatter.format(1.5), equals('1½'));
      });

      test('formats 2.5 as "2½"', () {
        expect(QuantityFormatter.format(2.5), equals('2½'));
      });

      test('formats 1.25 as "1¼"', () {
        expect(QuantityFormatter.format(1.25), equals('1¼'));
      });

      test('formats 2.75 as "2¾"', () {
        expect(QuantityFormatter.format(2.75), equals('2¾'));
      });

      test('formats 1.333... as "1⅓"', () {
        expect(QuantityFormatter.format(1.0 + 1.0 / 3.0), equals('1⅓'));
      });

      test('formats 3.666... as "3⅔"', () {
        expect(QuantityFormatter.format(3.0 + 2.0 / 3.0), equals('3⅔'));
      });
    });

    group('handles tolerance matching', () {
      test('formats 0.32 as "⅓" (within tolerance)', () {
        expect(QuantityFormatter.format(0.32), equals('⅓'));
      });

      test('formats 0.33 as "⅓" (within tolerance)', () {
        expect(QuantityFormatter.format(0.33), equals('⅓'));
      });

      test('formats 0.34 as "⅓" (within tolerance)', () {
        expect(QuantityFormatter.format(0.34), equals('⅓'));
      });

      test('formats 0.7 as "⅔" (closest match within tolerance)', () {
        expect(QuantityFormatter.format(0.7), equals('⅔'));
      });

      test('formats 0.77 as "¾" (within tolerance)', () {
        expect(QuantityFormatter.format(0.77), equals('¾'));
      });

      test('formats 0.83 as "⅘" (within tolerance)', () {
        expect(QuantityFormatter.format(0.83), equals('⅘'));
      });

      test('formats 0.55 as "⅗" (within tolerance, prefers simpler)', () {
        expect(QuantityFormatter.format(0.55), equals('⅗'));
      });
    });

    group('preserves uncommon decimals', () {
      test('formats 3.33 as "3⅓" (within tolerance)', () {
        expect(QuantityFormatter.format(3.33), equals('3⅓'));
      });

      test('formats 0.9 as "0.9" (outside tolerance, no close fraction)', () {
        expect(QuantityFormatter.format(0.9), equals('0.9'));
      });

      test('formats 0.15 as "⅙" (within tolerance)', () {
        expect(QuantityFormatter.format(0.15), equals('⅙'));
      });

      test('formats 0.35 as "⅓" (within tolerance)', () {
        expect(QuantityFormatter.format(0.35), equals('⅓'));
      });

      test('formats 0.27 as "¼" (within tolerance)', () {
        expect(QuantityFormatter.format(0.27), equals('¼'));
      });

      test('formats 0.42 as "⅖" (within tolerance)', () {
        expect(QuantityFormatter.format(0.42), equals('⅖'));
      });
    });

    group('handles precision correctly', () {
      test('formats 1.333 as "1⅓" (within tolerance)', () {
        expect(QuantityFormatter.format(1.333), equals('1⅓'));
      });

      test('formats 2.666 as "2⅔" (within tolerance)', () {
        expect(QuantityFormatter.format(2.666), equals('2⅔'));
      });

      test('formats 1.999 as "2"', () {
        expect(QuantityFormatter.format(1.999), equals('2'));
      });

      test('formats 0.123 as "⅛" (within tolerance)', () {
        expect(QuantityFormatter.format(0.123), equals('⅛'));
      });

      test('formats 0.1234567 as "⅛" (within tolerance)', () {
        expect(QuantityFormatter.format(0.1234567), equals('⅛'));
      });
    });

    group('removes trailing zeros', () {
      test('formats 2.50 as "2½"', () {
        expect(QuantityFormatter.format(2.50), equals('2½'));
      });

      test('formats 1.10 as "1⅛" (within tolerance)', () {
        expect(QuantityFormatter.format(1.10), equals('1⅛'));
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
        expect(QuantityFormatter.format(-2.5), equals('-2½'));
        expect(QuantityFormatter.format(-0.75), equals('-¾'));
      });

      test('formats very large numbers', () {
        expect(QuantityFormatter.format(1000.0), equals('1000'));
        expect(QuantityFormatter.format(9999.99), equals('9999.99'));
        expect(QuantityFormatter.format(1000.5), equals('1000½'));
      });
    });

    group('common cooking scenarios', () {
      test('formats typical recipe quantities', () {
        // Common whole number quantities
        expect(QuantityFormatter.format(1.0), equals('1')); // 1 cup
        expect(QuantityFormatter.format(2.0), equals('2')); // 2 cups
        expect(QuantityFormatter.format(3.0), equals('3')); // 3 cloves

        // Common fractional quantities now display as fractions
        expect(QuantityFormatter.format(0.5), equals('½')); // 1/2 cup
        expect(QuantityFormatter.format(0.25), equals('¼')); // 1/4 cup
        expect(QuantityFormatter.format(0.75), equals('¾')); // 3/4 cup
        expect(QuantityFormatter.format(1.5), equals('1½')); // 1 1/2 cups

        // Common precise quantities now display as fractions
        expect(QuantityFormatter.format(2.5), equals('2½')); // 2 1/2 cups
        expect(QuantityFormatter.format(1.25), equals('1¼')); // 1 1/4 cups
      });

      test('formats weight measurements', () {
        expect(QuantityFormatter.format(300.0), equals('300')); // 300g
        expect(QuantityFormatter.format(450.0), equals('450')); // 450g
        expect(QuantityFormatter.format(1000.0), equals('1000')); // 1kg equivalent
      });

      test('formats liquid measurements', () {
        expect(QuantityFormatter.format(250.0), equals('250')); // 250ml
        expect(QuantityFormatter.format(500.0), equals('500')); // 500ml
        expect(QuantityFormatter.format(1.5), equals('1½')); // 1.5 liters
      });
    });
  });
}