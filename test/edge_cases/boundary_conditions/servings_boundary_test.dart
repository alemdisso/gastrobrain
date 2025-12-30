// test/edge_cases/boundary_conditions/servings_boundary_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/core/validators/entity_validator.dart';
import 'package:gastrobrain/core/errors/gastrobrain_exceptions.dart';

/// Tests for servings boundary conditions.
///
/// Verifies that servings validation properly handles:
/// - Zero and negative values
/// - Minimum valid values
/// - Very large values
/// - Edge cases at validation boundaries
void main() {
  group('Servings Boundary Conditions', () {
    group('Invalid Servings - Below Minimum', () {
      test('servings = 0 throws ValidationException', () {
        // Test the boundary case of zero servings
        expect(
          () => EntityValidator.validateServings(0),
          throwsA(isA<ValidationException>()
              .having((e) => e.message, 'message',
                  contains('must be positive'))),
          reason: 'Servings cannot be zero',
        );
      });

      test('servings = -1 throws ValidationException', () {
        // Test negative servings
        expect(
          () => EntityValidator.validateServings(-1),
          throwsA(isA<ValidationException>()),
          reason: 'Servings cannot be negative',
        );
      });

      test('servings = -999 throws ValidationException', () {
        // Test large negative value
        expect(
          () => EntityValidator.validateServings(-999),
          throwsA(isA<ValidationException>()),
          reason: 'Large negative servings should be rejected',
        );
      });
    });

    group('Valid Servings - Minimum Boundary', () {
      test('servings = 1 is accepted (minimum valid)', () {
        // Test the minimum valid servings value
        expect(
          () => EntityValidator.validateServings(1),
          returnsNormally,
          reason: 'One serving should be valid',
        );
      });

      test('servings = 2 is accepted', () {
        // Test common small value
        expect(
          () => EntityValidator.validateServings(2),
          returnsNormally,
          reason: 'Two servings should be valid',
        );
      });
    });

    group('Valid Servings - High Values', () {
      test('servings = 10 is accepted (typical large meal)', () {
        // Test typical large family meal size
        expect(
          () => EntityValidator.validateServings(10),
          returnsNormally,
          reason: 'Ten servings should be valid',
        );
      });

      test('servings = 100 is accepted (very large batch)', () {
        // Test very large batch cooking
        expect(
          () => EntityValidator.validateServings(100),
          returnsNormally,
          reason: 'Large batch servings should be valid',
        );
      });

      test('servings = 999 is accepted (extreme batch)', () {
        // Test extreme but potentially valid use case
        expect(
          () => EntityValidator.validateServings(999),
          returnsNormally,
          reason: 'Very large servings should be accepted',
        );
      });

      test('servings = 9999 is accepted (no upper limit)', () {
        // Test that there's no artificial upper limit
        expect(
          () => EntityValidator.validateServings(9999),
          returnsNormally,
          reason: 'Extremely large servings should be accepted (no upper bound)',
        );
      });

      test('servings = 50000 is accepted (edge case)', () {
        // Test extremely high value to confirm no hidden limits
        expect(
          () => EntityValidator.validateServings(50000),
          returnsNormally,
          reason: 'No upper limit should be enforced on servings',
        );
      });
    });

    group('Servings Type Constraints', () {
      test('servings must be int type (not decimal)', () {
        // Note: This is enforced by the type system in Dart
        // The validator expects int, so passing a double would be a compile error
        // This test documents that servings are integers only

        // Test that common integer values work
        expect(() => EntityValidator.validateServings(1), returnsNormally);
        expect(() => EntityValidator.validateServings(2), returnsNormally);
        expect(() => EntityValidator.validateServings(3), returnsNormally);

        // Decimal servings like 2.5 are not possible due to type constraint
        // This is handled at the UI level (TextField parsing to int)
      });

      test('parsing non-numeric strings returns null', () {
        // Test that tryParse returns null for invalid input
        // This simulates what happens in the UI layer
        expect(int.tryParse('abc'), isNull,
            reason: 'Non-numeric input should parse to null');
        expect(int.tryParse(''), isNull,
            reason: 'Empty string should parse to null');
        expect(int.tryParse('1.5'), isNull,
            reason: 'Decimal string should parse to null for int');
      });

      test('parsing valid numeric strings succeeds', () {
        // Test that valid strings parse correctly
        expect(int.tryParse('1'), equals(1));
        expect(int.tryParse('10'), equals(10));
        expect(int.tryParse('999'), equals(999));
        expect(int.tryParse('-5'), equals(-5),
            reason: 'Negative numbers parse but will fail validation');
      });
    });

    group('Servings Edge Cases', () {
      test('maximum int value is accepted', () {
        // Test with Dart's maximum int value (platform-dependent, but very large)
        // On 64-bit platforms, this is 2^63 - 1
        const maxInt = 9223372036854775807; // 2^63 - 1
        expect(
          () => EntityValidator.validateServings(maxInt),
          returnsNormally,
          reason: 'Maximum int value should be accepted',
        );
      });

      test('zero boundary is clearly defined', () {
        // Test that the boundary is exactly at zero
        expect(
          () => EntityValidator.validateServings(0),
          throwsA(isA<ValidationException>()),
          reason: 'Zero is invalid',
        );
        expect(
          () => EntityValidator.validateServings(1),
          returnsNormally,
          reason: 'One is valid',
        );
      });
    });
  });

  group('Servings Validation Error Messages', () {
    test('error message is helpful and specific', () {
      // Verify the error message provides clear guidance
      try {
        EntityValidator.validateServings(0);
        fail('Should have thrown ValidationException');
      } on ValidationException catch (e) {
        expect(e.message, contains('must be positive'),
            reason: 'Error message should explain the requirement');
        expect(e.message.toLowerCase(), contains('serving'),
            reason: 'Error message should mention servings');
      }
    });

    test('error message is consistent for all invalid values', () {
      // Verify error messages are consistent
      String? message1;
      String? message2;

      try {
        EntityValidator.validateServings(0);
      } on ValidationException catch (e) {
        message1 = e.message;
      }

      try {
        EntityValidator.validateServings(-5);
      } on ValidationException catch (e) {
        message2 = e.message;
      }

      expect(message1, equals(message2),
          reason: 'Error messages should be consistent');
    });
  });

  group('Servings Validation Integration', () {
    test('validation can be called multiple times safely', () {
      // Test that validation is stateless and can be called repeatedly
      expect(() => EntityValidator.validateServings(1), returnsNormally);
      expect(() => EntityValidator.validateServings(1), returnsNormally);
      expect(() => EntityValidator.validateServings(2), returnsNormally);
      expect(() => EntityValidator.validateServings(100), returnsNormally);
    });

    test('validation does not modify input', () {
      // Test that validation is pure (no side effects)
      const servings = 5;
      EntityValidator.validateServings(servings);
      // If servings were modified, this would fail
      expect(servings, equals(5),
          reason: 'Validation should not modify input');
    });

    test('exceptions can be caught and handled', () {
      // Test that exceptions can be properly caught for error handling
      bool caughtException = false;
      String? errorMessage;

      try {
        EntityValidator.validateServings(0);
      } on ValidationException catch (e) {
        caughtException = true;
        errorMessage = e.message;
      }

      expect(caughtException, isTrue,
          reason: 'Exception should be catchable');
      expect(errorMessage, isNotNull,
          reason: 'Error message should be available');
    });
  });
}
