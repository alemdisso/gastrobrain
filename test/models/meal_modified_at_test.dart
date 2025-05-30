// test/models/meal_modified_at_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/meal.dart';

void main() {
  group('Meal modifiedAt Field Tests', () {
    test('Meal can be created with modifiedAt field', () {
      final now = DateTime.now();
      final meal = Meal(
        id: 'test-meal-1',
        cookedAt: now,
        servings: 2,
        notes: 'Test meal',
        modifiedAt: now,
      );

      expect(meal.modifiedAt, equals(now));
      expect(meal.id, equals('test-meal-1'));
      expect(meal.servings, equals(2));
    });

    test('Meal can be created without modifiedAt field (null)', () {
      final now = DateTime.now();
      final meal = Meal(
        id: 'test-meal-2',
        cookedAt: now,
        servings: 3,
      );

      expect(meal.modifiedAt, isNull);
      expect(meal.id, equals('test-meal-2'));
      expect(meal.servings, equals(3));
    });

    test('Meal toMap includes modifiedAt field', () {
      final now = DateTime.now();
      final meal = Meal(
        id: 'test-meal-3',
        cookedAt: now,
        servings: 4,
        notes: 'Test with modified date',
        modifiedAt: now,
      );

      final map = meal.toMap();

      expect(map['id'], equals('test-meal-3'));
      expect(map['servings'], equals(4));
      expect(map['modified_at'], equals(now.toIso8601String()));
    });

    test('Meal toMap handles null modifiedAt', () {
      final now = DateTime.now();
      final meal = Meal(
        id: 'test-meal-4',
        cookedAt: now,
        servings: 1,
      );

      final map = meal.toMap();

      expect(map['id'], equals('test-meal-4'));
      expect(map['modified_at'], isNull);
    });

    test('Meal fromMap recreates modifiedAt correctly', () {
      final now = DateTime.now();
      final originalMeal = Meal(
        id: 'test-meal-5',
        cookedAt: now,
        servings: 2,
        modifiedAt: now,
      );

      final map = originalMeal.toMap();
      final recreatedMeal = Meal.fromMap(map);

      expect(recreatedMeal.id, equals(originalMeal.id));
      expect(recreatedMeal.servings, equals(originalMeal.servings));
      expect(recreatedMeal.modifiedAt, equals(originalMeal.modifiedAt));
    });

    test('Meal fromMap handles null modifiedAt in map', () {
      final now = DateTime.now();
      final map = {
        'id': 'test-meal-6',
        'recipe_id': null,
        'cooked_at': now.toIso8601String(),
        'servings': 3,
        'notes': 'Test notes',
        'was_successful': 1,
        'actual_prep_time': 10.0,
        'actual_cook_time': 20.0,
        'modified_at': null, // Explicitly null
      };

      final meal = Meal.fromMap(map);

      expect(meal.id, equals('test-meal-6'));
      expect(meal.servings, equals(3));
      expect(meal.modifiedAt, isNull);
    });
  });
}
