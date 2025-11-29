// test/models/meal_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/meal.dart';
import 'package:gastrobrain/models/meal_recipe.dart';

void main() {
  group('Meal', () {
    test('creates with required fields and nullable recipeId', () {
      final now = DateTime.now();

      // Create a meal with null recipeId
      final meal = Meal(
        id: 'test_id',
        recipeId: null, // Explicitly set to null
        cookedAt: now,
      );

      expect(meal.id, 'test_id');
      expect(meal.recipeId, isNull);
      expect(meal.cookedAt, now);
      expect(meal.servings, 1); // Default value
      expect(meal.notes, ''); // Default value
      expect(meal.wasSuccessful, true); // Default value
      expect(meal.actualPrepTime, 0); // Default value
      expect(meal.actualCookTime, 0); // Default value
      expect(meal.mealRecipes, isNull);
    });

    test('creates with non-null recipeId for backward compatibility', () {
      final now = DateTime.now();

      // Create a meal with a recipeId (legacy approach)
      final meal = Meal(
        id: 'test_id',
        recipeId: 'recipe_id', // Non-null recipe ID
        cookedAt: now,
      );

      expect(meal.id, 'test_id');
      expect(meal.recipeId, 'recipe_id');
      expect(meal.cookedAt, now);
    });

    test('converts to map correctly with null recipeId', () {
      final now = DateTime.now();

      final meal = Meal(
        id: 'test_id',
        recipeId: null,
        cookedAt: now,
        servings: 2,
        notes: 'Test notes',
        wasSuccessful: false,
        actualPrepTime: 15.5,
        actualCookTime: 30.0,
      );

      final map = meal.toMap();

      expect(map['id'], 'test_id');
      expect(map['recipe_id'], isNull);
      expect(map['cooked_at'], now.toIso8601String());
      expect(map['servings'], 2);
      expect(map['notes'], 'Test notes');
      expect(map['was_successful'], 0);
      expect(map['actual_prep_time'], 15.5);
      expect(map['actual_cook_time'], 30.0);
    });

    test('converts from map correctly with null recipeId', () {
      final now = DateTime.now();

      final map = {
        'id': 'test_id',
        'recipe_id': null,
        'cooked_at': now.toIso8601String(),
        'servings': 2,
        'notes': 'Test notes',
        'was_successful': 0,
        'actual_prep_time': 15.5,
        'actual_cook_time': 30.0,
      };

      final meal = Meal.fromMap(map);

      expect(meal.id, 'test_id');
      expect(meal.recipeId, isNull);
      expect(meal.cookedAt.toIso8601String(), now.toIso8601String());
      expect(meal.servings, 2);
      expect(meal.notes, 'Test notes');
      expect(meal.wasSuccessful, false);
      expect(meal.actualPrepTime, 15.5);
      expect(meal.actualCookTime, 30.0);
    });

    test('can have associated recipes through mealRecipes property', () {
      final now = DateTime.now();

      final meal = Meal(
        id: 'test_id',
        recipeId: null, // No direct recipe association
        cookedAt: now,
      );

      // Add associated recipes through the junction model
      meal.mealRecipes = [
        MealRecipe(
          mealId: 'test_id',
          recipeId: 'recipe_id_1',
          isPrimaryDish: true,
        ),
        MealRecipe(
          mealId: 'test_id',
          recipeId: 'recipe_id_2',
          isPrimaryDish: false,
        ),
      ];

      expect(meal.mealRecipes, isNotNull);
      expect(meal.mealRecipes!.length, 2);
      expect(meal.mealRecipes![0].recipeId, 'recipe_id_1');
      expect(meal.mealRecipes![0].isPrimaryDish, isTrue);
      expect(meal.mealRecipes![1].recipeId, 'recipe_id_2');
      expect(meal.mealRecipes![1].isPrimaryDish, isFalse);

      // Verify the meal can have associated recipes even with a null recipeId
      expect(meal.recipeId, isNull);
    });
  });

  test('handles missing values in fromMap with defaults', () {
    final now = DateTime.now();
    final map = {
      'id': 'test_id',
      'recipe_id': 'recipe_id',
      'cooked_at': now.toIso8601String(),
      'servings': 2,
      'notes': 'Test notes',
      'was_successful': 1,
      // Missing actual_prep_time and actual_cook_time
    };

    final meal = Meal.fromMap(map);

    expect(meal.id, 'test_id');
    expect(meal.actualPrepTime, 0); // Should default to 0
    expect(meal.actualCookTime, 0); // Should default to 0
  });

  test('creates with all fields specified', () {
    final now = DateTime.now();
    final mealRecipes = [
      MealRecipe(
        mealId: 'test_id',
        recipeId: 'recipe_1',
        isPrimaryDish: true,
      )
    ];

    final meal = Meal(
      id: 'test_id',
      recipeId: 'recipe_main',
      cookedAt: now,
      servings: 4,
      notes: 'Special meal',
      wasSuccessful: false,
      actualPrepTime: 30.5,
      actualCookTime: 45.0,
      mealRecipes: mealRecipes,
    );

    expect(meal.id, 'test_id');
    expect(meal.recipeId, 'recipe_main');
    expect(meal.cookedAt, now);
    expect(meal.servings, 4);
    expect(meal.notes, 'Special meal');
    expect(meal.wasSuccessful, false);
    expect(meal.actualPrepTime, 30.5);
    expect(meal.actualCookTime, 45.0);
    expect(meal.mealRecipes, mealRecipes);
    expect(meal.mealRecipes!.length, 1);
  });

  test('correctly handles boolean to integer conversion', () {
    final now = DateTime.now();

    // Test true → 1
    final successfulMeal = Meal(
      id: 'test_success',
      cookedAt: now,
      wasSuccessful: true,
    );
    expect(successfulMeal.toMap()['was_successful'], 1);

    // Test false → 0
    final failedMeal = Meal(
      id: 'test_fail',
      cookedAt: now,
      wasSuccessful: false,
    );
    expect(failedMeal.toMap()['was_successful'], 0);

    // Test 1 → true
    final map1 = {
      'id': 'test_1',
      'cooked_at': now.toIso8601String(),
      'was_successful': 1,
      'servings': 2,
      'notes': '',
    };
    expect(Meal.fromMap(map1).wasSuccessful, true);

    // Test 0 → false
    final map0 = {
      'id': 'test_0',
      'cooked_at': now.toIso8601String(),
      'was_successful': 0,
      'servings': 2,
      'notes': '',
    };
    expect(Meal.fromMap(map0).wasSuccessful, false);
  });

  test('handles edge cases in data', () {
    final now = DateTime.now();

    // Test with very large values
    final largeMeal = Meal(
      id: 'large_test',
      cookedAt: now,
      servings: 1000,
      actualPrepTime: 9999.99,
      actualCookTime: 9999.99,
    );

    final largeMap = largeMeal.toMap();
    final recoveredLargeMeal = Meal.fromMap(largeMap);

    expect(recoveredLargeMeal.servings, 1000);
    expect(recoveredLargeMeal.actualPrepTime, 9999.99);
    expect(recoveredLargeMeal.actualCookTime, 9999.99);

    // Test with empty notes
    final emptyNotesMeal = Meal(
      id: 'empty_notes',
      cookedAt: now,
      notes: '',
    );

    final emptyMap = emptyNotesMeal.toMap();
    final recoveredEmptyMeal = Meal.fromMap(emptyMap);

    expect(recoveredEmptyMeal.notes, '');
  });

  test('round-trip serialization preserves all data', () {
    final now = DateTime.now();
    final modifiedDate = now.subtract(const Duration(hours: 2));

    final original = Meal(
      id: 'round_trip_test',
      recipeId: 'recipe_123',
      cookedAt: now,
      servings: 3,
      notes: 'Round trip test notes',
      wasSuccessful: false,
      actualPrepTime: 12.5,
      actualCookTime: 25.75,
      modifiedAt: modifiedDate,
    );

    // Convert to map and back
    final map = original.toMap();
    final recovered = Meal.fromMap(map);

    // Convert recovered back to map
    final secondMap = recovered.toMap();

    // Both maps should be identical
    expect(secondMap['id'], map['id']);
    expect(secondMap['recipe_id'], map['recipe_id']);
    expect(secondMap['cooked_at'], map['cooked_at']);
    expect(secondMap['servings'], map['servings']);
    expect(secondMap['notes'], map['notes']);
    expect(secondMap['was_successful'], map['was_successful']);
    expect(secondMap['actual_prep_time'], map['actual_prep_time']);
    expect(secondMap['actual_cook_time'], map['actual_cook_time']);
    expect(secondMap['modified_at'], map['modified_at']);
  });

  test('handles zero values correctly', () {
    final now = DateTime.now();

    final meal = Meal(
      id: 'zero_test',
      cookedAt: now,
      servings: 1, // Minimum servings
      actualPrepTime: 0,
      actualCookTime: 0,
    );

    expect(meal.actualPrepTime, 0);
    expect(meal.actualCookTime, 0);

    final map = meal.toMap();
    expect(map['actual_prep_time'], 0);
    expect(map['actual_cook_time'], 0);

    final recovered = Meal.fromMap(map);
    expect(recovered.actualPrepTime, 0);
    expect(recovered.actualCookTime, 0);
  });

  test('handles special characters in notes', () {
    final now = DateTime.now();

    final specialNotes = 'Test with special chars: !@#\$%^&*()_+-=[]{}|;:\'",.<>?/\\~`\n\tNew line and tab';
    final meal = Meal(
      id: 'special_chars_test',
      cookedAt: now,
      notes: specialNotes,
    );

    final map = meal.toMap();
    final recovered = Meal.fromMap(map);

    expect(recovered.notes, specialNotes);
  });

  test('handles very long notes strings', () {
    final now = DateTime.now();
    final longNotes = 'A' * 10000; // 10,000 character string

    final meal = Meal(
      id: 'long_notes_test',
      cookedAt: now,
      notes: longNotes,
    );

    final map = meal.toMap();
    final recovered = Meal.fromMap(map);

    expect(recovered.notes, longNotes);
    expect(recovered.notes.length, 10000);
  });

  test('preserves date precision through serialization', () {
    // Create a date with milliseconds
    final preciseDate = DateTime(2024, 1, 15, 14, 30, 45, 123);

    final meal = Meal(
      id: 'precision_test',
      cookedAt: preciseDate,
    );

    final map = meal.toMap();
    final recovered = Meal.fromMap(map);

    // ISO 8601 string should preserve milliseconds
    expect(recovered.cookedAt.toIso8601String(), preciseDate.toIso8601String());
  });

  test('handles different time zones correctly', () {
    // Create dates in UTC and local time
    final utcDate = DateTime.utc(2024, 1, 15, 12, 0, 0);
    final localDate = DateTime(2024, 1, 15, 12, 0, 0);

    final utcMeal = Meal(
      id: 'utc_test',
      cookedAt: utcDate,
    );

    final localMeal = Meal(
      id: 'local_test',
      cookedAt: localDate,
    );

    // Verify both can be serialized and deserialized
    final utcMap = utcMeal.toMap();
    final localMap = localMeal.toMap();

    final recoveredUtc = Meal.fromMap(utcMap);
    final recoveredLocal = Meal.fromMap(localMap);

    expect(recoveredUtc.cookedAt.toIso8601String(), utcDate.toIso8601String());
    expect(recoveredLocal.cookedAt.toIso8601String(), localDate.toIso8601String());
  });
}
