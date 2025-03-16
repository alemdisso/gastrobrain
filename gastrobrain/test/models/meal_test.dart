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
}
