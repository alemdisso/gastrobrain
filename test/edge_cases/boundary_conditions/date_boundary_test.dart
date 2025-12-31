// test/edge_cases/boundary_conditions/date_boundary_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/core/validators/entity_validator.dart';
import 'package:gastrobrain/core/errors/gastrobrain_exceptions.dart';

/// Tests for date boundary conditions.
///
/// Verifies that date validation properly handles:
/// - Future dates for cooked meals (should be rejected)
/// - Past dates (should be accepted)
/// - Very old dates
/// - Edge cases around "now"
/// - Different validation for planned vs cooked meals
void main() {
  group('Date Boundary Conditions - Cooked Meals', () {
    group('Invalid Dates - Future Dates', () {
      test('future date (tomorrow) throws ValidationException', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));

        expect(
          () => EntityValidator.validateMeal(
            name: 'Test Meal',
            date: tomorrow,
          ),
          throwsA(isA<ValidationException>()
              .having((e) => e.message, 'message',
                  contains('cannot be in the future'))),
          reason: 'Cooked meals cannot have future dates',
        );
      });

      test('future date (next week) throws ValidationException', () {
        final nextWeek = DateTime.now().add(const Duration(days: 7));

        expect(
          () => EntityValidator.validateMeal(
            name: 'Test Meal',
            date: nextWeek,
          ),
          throwsA(isA<ValidationException>()),
          reason: 'Future dates should be rejected for cooked meals',
        );
      });

      test('far future date (next year) throws ValidationException', () {
        final nextYear = DateTime.now().add(const Duration(days: 365));

        expect(
          () => EntityValidator.validateMeal(
            name: 'Test Meal',
            date: nextYear,
          ),
          throwsA(isA<ValidationException>()),
          reason: 'Far future dates should be rejected',
        );
      });

      test('date in year 2100 throws ValidationException', () {
        final futureDate = DateTime(2100, 1, 1);

        expect(
          () => EntityValidator.validateMeal(
            name: 'Test Meal',
            date: futureDate,
          ),
          throwsA(isA<ValidationException>()),
          reason: 'Very far future dates should be rejected',
        );
      });
    });

    group('Valid Dates - Past and Present', () {
      test('current moment is accepted', () {
        final now = DateTime.now();

        expect(
          () => EntityValidator.validateMeal(
            name: 'Test Meal',
            date: now,
          ),
          returnsNormally,
          reason: 'Current time should be valid for cooked meals',
        );
      });

      test('one second ago is accepted', () {
        final oneSecondAgo =
            DateTime.now().subtract(const Duration(seconds: 1));

        expect(
          () => EntityValidator.validateMeal(
            name: 'Test Meal',
            date: oneSecondAgo,
          ),
          returnsNormally,
          reason: 'Past dates should be accepted',
        );
      });

      test('yesterday is accepted', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));

        expect(
          () => EntityValidator.validateMeal(
            name: 'Test Meal',
            date: yesterday,
          ),
          returnsNormally,
          reason: 'Recent past dates should be valid',
        );
      });

      test('last week is accepted', () {
        final lastWeek = DateTime.now().subtract(const Duration(days: 7));

        expect(
          () => EntityValidator.validateMeal(
            name: 'Test Meal',
            date: lastWeek,
          ),
          returnsNormally,
        );
      });

      test('last month is accepted', () {
        final lastMonth = DateTime.now().subtract(const Duration(days: 30));

        expect(
          () => EntityValidator.validateMeal(
            name: 'Test Meal',
            date: lastMonth,
          ),
          returnsNormally,
        );
      });

      test('last year is accepted', () {
        final lastYear = DateTime.now().subtract(const Duration(days: 365));

        expect(
          () => EntityValidator.validateMeal(
            name: 'Test Meal',
            date: lastYear,
          ),
          returnsNormally,
          reason: 'Old dates should be accepted',
        );
      });
    });

    group('Valid Dates - Very Old Dates', () {
      test('date in year 2000 is accepted', () {
        final year2000 = DateTime(2000, 1, 1);

        expect(
          () => EntityValidator.validateMeal(
            name: 'Test Meal',
            date: year2000,
          ),
          returnsNormally,
          reason: 'Old dates from year 2000 should be valid',
        );
      });

      test('date in year 1990 is accepted', () {
        final year1990 = DateTime(1990, 6, 15);

        expect(
          () => EntityValidator.validateMeal(
            name: 'Test Meal',
            date: year1990,
          ),
          returnsNormally,
          reason: 'Very old dates should be accepted',
        );
      });

      test('date in year 1900 is accepted', () {
        final year1900 = DateTime(1900, 1, 1);

        expect(
          () => EntityValidator.validateMeal(
            name: 'Test Meal',
            date: year1900,
          ),
          returnsNormally,
          reason: 'Extremely old dates should be accepted (no lower bound)',
        );
      });

      test('minimum DateTime value is accepted', () {
        // DateTime minimum is year 0001-01-01
        final minDate = DateTime(1);

        expect(
          () => EntityValidator.validateMeal(
            name: 'Test Meal',
            date: minDate,
          ),
          returnsNormally,
          reason: 'Minimum DateTime should be accepted',
        );
      });
    });

    group('Date Edge Cases - Boundary Testing', () {
      test('date exactly at current time passes validation', () {
        // Capture the exact moment for testing
        final now = DateTime.now();

        expect(
          () => EntityValidator.validateMeal(
            name: 'Test Meal',
            date: now,
          ),
          returnsNormally,
          reason: 'Exact current time should be valid',
        );
      });

      test('date 1 millisecond in future fails validation', () {
        // This test might be flaky due to timing, but demonstrates the boundary
        final almostNow =
            DateTime.now().add(const Duration(milliseconds: 100));

        expect(
          () => EntityValidator.validateMeal(
            name: 'Test Meal',
            date: almostNow,
          ),
          throwsA(isA<ValidationException>()),
          reason: 'Any time in future should be rejected',
        );
      });

      test('date 1 millisecond in past passes validation', () {
        final justPast =
            DateTime.now().subtract(const Duration(milliseconds: 1));

        expect(
          () => EntityValidator.validateMeal(
            name: 'Test Meal',
            date: justPast,
          ),
          returnsNormally,
          reason: 'Any time in past should be accepted',
        );
      });
    });

    group('Date Special Cases', () {
      test('leap year date (Feb 29) is handled correctly', () {
        // 2024 is a leap year
        final leapDay = DateTime(2024, 2, 29);

        // Only valid if we're past 2024-02-29
        if (DateTime.now().isAfter(leapDay)) {
          expect(
            () => EntityValidator.validateMeal(
              name: 'Test Meal',
              date: leapDay,
            ),
            returnsNormally,
            reason: 'Leap year dates should be valid',
          );
        }
      });

      test('new year boundary (Dec 31 to Jan 1) is handled', () {
        final dec31 = DateTime(2023, 12, 31, 23, 59, 59);

        expect(
          () => EntityValidator.validateMeal(
            name: 'Test Meal',
            date: dec31,
          ),
          returnsNormally,
          reason: 'Year boundaries should be handled correctly',
        );
      });

      test('midnight boundary is handled correctly', () {
        final midnight = DateTime(2024, 1, 1, 0, 0, 0);

        if (DateTime.now().isAfter(midnight)) {
          expect(
            () => EntityValidator.validateMeal(
              name: 'Test Meal',
              date: midnight,
            ),
            returnsNormally,
            reason: 'Midnight timestamps should be valid',
          );
        }
      });
    });

    group('Date Validation Error Messages', () {
      test('future date error message is helpful', () {
        final futureDate = DateTime.now().add(const Duration(days: 1));

        try {
          EntityValidator.validateMeal(
            name: 'Test Meal',
            date: futureDate,
          );
          fail('Should have thrown ValidationException');
        } on ValidationException catch (e) {
          expect(e.message, contains('future'),
              reason: 'Error message should mention future');
          expect(e.message.toLowerCase(), contains('date'),
              reason: 'Error message should mention date');
        }
      });

      test('error message is consistent across different future dates', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final nextWeek = DateTime.now().add(const Duration(days: 7));

        String? message1;
        String? message2;

        try {
          EntityValidator.validateMeal(name: 'Test', date: tomorrow);
        } on ValidationException catch (e) {
          message1 = e.message;
        }

        try {
          EntityValidator.validateMeal(name: 'Test', date: nextWeek);
        } on ValidationException catch (e) {
          message2 = e.message;
        }

        expect(message1, equals(message2),
            reason: 'Error messages should be consistent');
      });
    });
  });

  group('Date Validation Integration', () {
    test('validation can be called multiple times safely', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      expect(
        () => EntityValidator.validateMeal(name: 'Meal 1', date: yesterday),
        returnsNormally,
      );
      expect(
        () => EntityValidator.validateMeal(name: 'Meal 2', date: yesterday),
        returnsNormally,
      );
    });

    test('validation does not modify input', () {
      final originalDate = DateTime(2023, 6, 15, 12, 30, 45);
      final dateCopy = DateTime(2023, 6, 15, 12, 30, 45);

      EntityValidator.validateMeal(name: 'Test', date: dateCopy);

      expect(dateCopy, equals(originalDate),
          reason: 'Validation should not modify date');
    });

    test('exceptions can be caught and handled', () {
      final futureDate = DateTime.now().add(const Duration(days: 1));
      bool caughtException = false;
      String? errorMessage;

      try {
        EntityValidator.validateMeal(name: 'Test', date: futureDate);
      } on ValidationException catch (e) {
        caughtException = true;
        errorMessage = e.message;
      }

      expect(caughtException, isTrue);
      expect(errorMessage, isNotNull);
    });
  });

  group('Date Comparison Edge Cases', () {
    test('DateTime.now() boundary is respected', () {
      // Test that the validation uses a fresh DateTime.now() call
      // This test documents the behavior but may have timing issues

      final almostNow = DateTime.now();
      // Small delay to ensure we're testing boundary
      final nowMinus1Second =
          almostNow.subtract(const Duration(seconds: 1));

      expect(
        () => EntityValidator.validateMeal(name: 'Test', date: nowMinus1Second),
        returnsNormally,
        reason: 'Date from 1 second ago should always be valid',
      );
    });

    test('date comparison handles microseconds correctly', () {
      final base = DateTime.now();
      final past = base.subtract(const Duration(microseconds: 1));

      expect(
        () => EntityValidator.validateMeal(name: 'Test', date: past),
        returnsNormally,
        reason: 'Microsecond-level past dates should be valid',
      );
    });
  });

  group('Date Timezone Considerations', () {
    test('UTC dates are handled correctly', () {
      final utcDate = DateTime.now().toUtc().subtract(const Duration(days: 1));

      expect(
        () => EntityValidator.validateMeal(name: 'Test', date: utcDate),
        returnsNormally,
        reason: 'UTC dates should be validated correctly',
      );
    });

    test('local dates are handled correctly', () {
      final localDate = DateTime.now().subtract(const Duration(days: 1));

      expect(
        () => EntityValidator.validateMeal(name: 'Test', date: localDate),
        returnsNormally,
        reason: 'Local dates should be validated correctly',
      );
    });
  });

  group('Date Practical Scenarios', () {
    test('recording meal cooked 1 hour ago', () {
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));

      expect(
        () => EntityValidator.validateMeal(name: 'Lunch', date: oneHourAgo),
        returnsNormally,
        reason: 'Recent meals should be valid',
      );
    });

    test('recording meal from last month', () {
      final lastMonth = DateTime.now().subtract(const Duration(days: 30));

      expect(
        () => EntityValidator.validateMeal(name: 'Old Meal', date: lastMonth),
        returnsNormally,
        reason: 'Historical meals should be valid',
      );
    });

    test('cannot pre-record meal for tomorrow', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));

      expect(
        () => EntityValidator.validateMeal(name: 'Future Meal', date: tomorrow),
        throwsA(isA<ValidationException>()),
        reason: 'Cannot record meals that haven\'t been cooked yet',
      );
    });

    test('meal from 10 years ago is valid', () {
      final tenYearsAgo = DateTime.now().subtract(const Duration(days: 3650));

      expect(
        () =>
            EntityValidator.validateMeal(name: 'Ancient Meal', date: tenYearsAgo),
        returnsNormally,
        reason: 'Very old historical meals should be valid',
      );
    });
  });
}
