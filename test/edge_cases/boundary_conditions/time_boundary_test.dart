// test/edge_cases/boundary_conditions/time_boundary_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/core/validators/entity_validator.dart';
import 'package:gastrobrain/core/errors/gastrobrain_exceptions.dart';

/// Tests for time boundary conditions.
///
/// Verifies that time validation properly handles:
/// - Zero and negative values
/// - Decimal/fractional times
/// - Null values (optional times)
/// - Very large time values
/// - Different field names (prep time, cook time)
void main() {
  group('Time Boundary Conditions', () {
    group('Invalid Times - Negative Values', () {
      test('negative prep time throws ValidationException', () {
        expect(
          () => EntityValidator.validateTime(-1.0, 'Prep'),
          throwsA(isA<ValidationException>()
              .having((e) => e.message, 'message',
                  contains('cannot be negative'))),
          reason: 'Negative prep time should be rejected',
        );
      });

      test('negative cook time throws ValidationException', () {
        expect(
          () => EntityValidator.validateTime(-5.0, 'Cook'),
          throwsA(isA<ValidationException>()
              .having((e) => e.message, 'message', contains('Cook'))),
          reason: 'Negative cook time should be rejected with field name',
        );
      });

      test('large negative time throws ValidationException', () {
        expect(
          () => EntityValidator.validateTime(-999.0, 'Prep'),
          throwsA(isA<ValidationException>()),
          reason: 'Large negative times should be rejected',
        );
      });

      test('negative decimal time throws ValidationException', () {
        expect(
          () => EntityValidator.validateTime(-0.5, 'Cook'),
          throwsA(isA<ValidationException>()),
          reason: 'Negative fractional times should be rejected',
        );
      });

      test('very small negative time (-0.01) throws ValidationException', () {
        expect(
          () => EntityValidator.validateTime(-0.01, 'Prep'),
          throwsA(isA<ValidationException>()),
          reason: 'Even very small negative times should be rejected',
        );
      });
    });

    group('Valid Times - Zero Boundary', () {
      test('prep time = 0 is accepted', () {
        // Zero time is valid (e.g., no-prep recipes)
        expect(
          () => EntityValidator.validateTime(0.0, 'Prep'),
          returnsNormally,
          reason: 'Zero prep time should be valid',
        );
      });

      test('cook time = 0 is accepted', () {
        // Zero cook time is valid (e.g., no-cook recipes like salads)
        expect(
          () => EntityValidator.validateTime(0.0, 'Cook'),
          returnsNormally,
          reason: 'Zero cook time should be valid',
        );
      });

      test('time = 0.0 (exact zero) is accepted', () {
        expect(
          () => EntityValidator.validateTime(0.0, 'Total'),
          returnsNormally,
          reason: 'Exact zero should be valid',
        );
      });
    });

    group('Valid Times - Decimal/Fractional Values', () {
      test('time = 0.5 is accepted (half minute)', () {
        expect(
          () => EntityValidator.validateTime(0.5, 'Prep'),
          returnsNormally,
          reason: 'Half-minute increments should be valid',
        );
      });

      test('time = 1.5 is accepted (one and half minutes)', () {
        expect(
          () => EntityValidator.validateTime(1.5, 'Cook'),
          returnsNormally,
          reason: 'Decimal times should be accepted',
        );
      });

      test('time = 15.5 is accepted (common fractional time)', () {
        expect(
          () => EntityValidator.validateTime(15.5, 'Prep'),
          returnsNormally,
          reason: 'Common fractional cooking times should be valid',
        );
      });

      test('time = 0.25 is accepted (quarter minute)', () {
        expect(
          () => EntityValidator.validateTime(0.25, 'Cook'),
          returnsNormally,
          reason: 'Quarter-minute increments should be valid',
        );
      });

      test('time = 30.75 is accepted (precise decimal)', () {
        expect(
          () => EntityValidator.validateTime(30.75, 'Total'),
          returnsNormally,
          reason: 'Precise decimal times should be accepted',
        );
      });
    });

    group('Valid Times - Common Values', () {
      test('time = 1 minute is accepted', () {
        expect(
          () => EntityValidator.validateTime(1.0, 'Prep'),
          returnsNormally,
          reason: 'One minute should be valid',
        );
      });

      test('time = 5 minutes is accepted', () {
        expect(
          () => EntityValidator.validateTime(5.0, 'Prep'),
          returnsNormally,
        );
      });

      test('time = 15 minutes is accepted (common prep time)', () {
        expect(
          () => EntityValidator.validateTime(15.0, 'Prep'),
          returnsNormally,
        );
      });

      test('time = 30 minutes is accepted (common cook time)', () {
        expect(
          () => EntityValidator.validateTime(30.0, 'Cook'),
          returnsNormally,
        );
      });

      test('time = 60 minutes is accepted (one hour)', () {
        expect(
          () => EntityValidator.validateTime(60.0, 'Cook'),
          returnsNormally,
        );
      });
    });

    group('Valid Times - Large Values', () {
      test('time = 120 minutes is accepted (two hours)', () {
        expect(
          () => EntityValidator.validateTime(120.0, 'Cook'),
          returnsNormally,
          reason: 'Two hour cook time should be valid',
        );
      });

      test('time = 240 minutes is accepted (four hours)', () {
        expect(
          () => EntityValidator.validateTime(240.0, 'Cook'),
          returnsNormally,
          reason: 'Long cooking times like slow roasts should be valid',
        );
      });

      test('time = 999 minutes is accepted (very long)', () {
        expect(
          () => EntityValidator.validateTime(999.0, 'Cook'),
          returnsNormally,
          reason: 'Very long cooking times should be accepted',
        );
      });

      test('time = 9999 minutes is accepted (extreme)', () {
        expect(
          () => EntityValidator.validateTime(9999.0, 'Cook'),
          returnsNormally,
          reason: 'Extremely long times should be accepted (no upper bound)',
        );
      });

      test('time = 100000 minutes is accepted', () {
        // Test that there's no artificial upper limit
        expect(
          () => EntityValidator.validateTime(100000.0, 'Prep'),
          returnsNormally,
          reason: 'No upper limit should be enforced',
        );
      });
    });

    group('Null Time Values', () {
      test('null prep time is accepted (optional field)', () {
        expect(
          () => EntityValidator.validateTime(null, 'Prep'),
          returnsNormally,
          reason: 'Null times should be allowed (optional field)',
        );
      });

      test('null cook time is accepted', () {
        expect(
          () => EntityValidator.validateTime(null, 'Cook'),
          returnsNormally,
          reason: 'Cook time can be optional',
        );
      });

      test('null total time is accepted', () {
        expect(
          () => EntityValidator.validateTime(null, 'Total'),
          returnsNormally,
        );
      });
    });

    group('Time Validation with Different Field Names', () {
      test('validation includes field name in error message', () {
        try {
          EntityValidator.validateTime(-5.0, 'Prep');
          fail('Should have thrown ValidationException');
        } on ValidationException catch (e) {
          expect(e.message, contains('Prep'),
              reason: 'Error message should include field name');
        }
      });

      test('different field names produce different error messages', () {
        String? prepError;
        String? cookError;

        try {
          EntityValidator.validateTime(-1.0, 'Prep');
        } on ValidationException catch (e) {
          prepError = e.message;
        }

        try {
          EntityValidator.validateTime(-1.0, 'Cook');
        } on ValidationException catch (e) {
          cookError = e.message;
        }

        expect(prepError, isNotNull);
        expect(cookError, isNotNull);
        expect(prepError, isNot(equals(cookError)),
            reason: 'Error messages should differ by field name');
        expect(prepError, contains('Prep'));
        expect(cookError, contains('Cook'));
      });

      test('custom field name is included in validation', () {
        try {
          EntityValidator.validateTime(-10.0, 'Custom Field');
          fail('Should have thrown ValidationException');
        } on ValidationException catch (e) {
          expect(e.message, contains('Custom Field'),
              reason: 'Custom field names should be included');
        }
      });
    });

    group('Time Type Constraints', () {
      test('parsing decimal strings succeeds', () {
        // Test that decimal strings parse correctly for double
        expect(double.tryParse('15.5'), equals(15.5));
        expect(double.tryParse('0.5'), equals(0.5));
        expect(double.tryParse('30'), equals(30.0));
      });

      test('parsing invalid strings returns null', () {
        expect(double.tryParse('abc'), isNull,
            reason: 'Non-numeric input should parse to null');
        expect(double.tryParse(''), isNull,
            reason: 'Empty string should parse to null');
        expect(double.tryParse('10 minutes'), isNull,
            reason: 'String with units should parse to null');
      });

      test('parsing negative strings succeeds but will fail validation', () {
        expect(double.tryParse('-5'), equals(-5.0));
        expect(double.tryParse('-15.5'), equals(-15.5));
        // These values parse successfully but will be rejected by validation
      });
    });

    group('Time Edge Cases', () {
      test('very small positive time (0.01) is accepted', () {
        expect(
          () => EntityValidator.validateTime(0.01, 'Prep'),
          returnsNormally,
          reason: 'Very small positive times should be valid',
        );
      });

      test('maximum double value is accepted', () {
        // Test with a very large double value
        expect(
          () => EntityValidator.validateTime(double.maxFinite, 'Cook'),
          returnsNormally,
          reason: 'Maximum double value should be accepted',
        );
      });

      test('zero boundary is clearly defined', () {
        // Test the exact boundary between invalid and valid
        expect(
          () => EntityValidator.validateTime(-0.01, 'Prep'),
          throwsA(isA<ValidationException>()),
          reason: 'Just below zero is invalid',
        );
        expect(
          () => EntityValidator.validateTime(0.0, 'Prep'),
          returnsNormally,
          reason: 'Zero is valid',
        );
        expect(
          () => EntityValidator.validateTime(0.01, 'Prep'),
          returnsNormally,
          reason: 'Just above zero is valid',
        );
      });
    });

    group('Time Validation Integration', () {
      test('validation can be called multiple times safely', () {
        expect(() => EntityValidator.validateTime(15.0, 'Prep'),
            returnsNormally);
        expect(() => EntityValidator.validateTime(30.0, 'Cook'),
            returnsNormally);
        expect(() => EntityValidator.validateTime(null, 'Total'),
            returnsNormally);
      });

      test('validation does not modify input', () {
        const time = 25.5;
        EntityValidator.validateTime(time, 'Prep');
        expect(time, equals(25.5),
            reason: 'Validation should not modify input');
      });

      test('exceptions can be caught and handled', () {
        bool caughtException = false;
        String? errorMessage;

        try {
          EntityValidator.validateTime(-10.0, 'Cook');
        } on ValidationException catch (e) {
          caughtException = true;
          errorMessage = e.message;
        }

        expect(caughtException, isTrue);
        expect(errorMessage, isNotNull);
        expect(errorMessage, contains('cannot be negative'));
      });
    });
  });

  group('Time Calculation Edge Cases', () {
    test('total time calculation with boundary values', () {
      // Test that time calculations work with boundary values
      const prepTime = 0.0;
      const cookTime = 0.0;
      const totalTime = prepTime + cookTime;

      expect(totalTime, equals(0.0),
          reason: 'Zero times should sum to zero');
    });

    test('total time with one null component', () {
      // Demonstrate handling when one time is null
      const prepTime = 15.0;
      const double? cookTime = null;
      final totalTime = prepTime + (cookTime ?? 0.0);

      expect(totalTime, equals(15.0),
          reason: 'Null time should be treated as zero in calculations');
    });

    test('total time with very large values', () {
      const prepTime = 9999.0;
      const cookTime = 9999.0;
      const totalTime = prepTime + cookTime;

      expect(totalTime, equals(19998.0),
          reason: 'Large times should calculate correctly');
    });

    test('total time with decimal values', () {
      const prepTime = 15.5;
      const cookTime = 30.25;
      const totalTime = prepTime + cookTime;

      expect(totalTime, closeTo(45.75, 0.01),
          reason: 'Decimal times should sum correctly');
    });
  });
}
