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
}
