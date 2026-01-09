import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/meal_type.dart';

void main() {
  group('MealType', () {
    test('should have correct enum values', () {
      expect(MealType.values.length, equals(3));
      expect(MealType.values, contains(MealType.lunch));
      expect(MealType.values, contains(MealType.dinner));
      expect(MealType.values, contains(MealType.prep));
    });

    test('should have correct string values', () {
      expect(MealType.lunch.value, equals('lunch'));
      expect(MealType.dinner.value, equals('dinner'));
      expect(MealType.prep.value, equals('prep'));
    });

    group('fromString', () {
      test('should return correct MealType for valid strings', () {
        expect(MealType.fromString('lunch'), equals(MealType.lunch));
        expect(MealType.fromString('dinner'), equals(MealType.dinner));
        expect(MealType.fromString('prep'), equals(MealType.prep));
      });

      test('should return null for null input', () {
        expect(MealType.fromString(null), isNull);
      });

      test('should return prep for invalid strings', () {
        expect(MealType.fromString('invalid'), equals(MealType.prep));
        expect(MealType.fromString('breakfast'), equals(MealType.prep));
        expect(MealType.fromString(''), equals(MealType.prep));
      });
    });
  });
}
