// lib/core/services/meal_edit_service.dart

import 'package:gastrobrain/database/database_helper.dart';
import 'package:gastrobrain/models/meal.dart';
import 'package:gastrobrain/models/meal_recipe.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/core/errors/gastrobrain_exceptions.dart';

/// Service for managing meal editing operations.
///
/// This service consolidates meal editing logic that was previously duplicated
/// across MealHistoryScreen, WeeklyPlanScreen, and CookMealScreen.
///
/// Related issue: #237
class MealEditService {
  final DatabaseHelper _dbHelper;

  MealEditService(this._dbHelper);

  /// Update a meal record with new values and recipe associations.
  ///
  /// This method handles:
  /// 1. Updating the meal record with new values
  /// 2. Removing existing side dish associations (keeping primary)
  /// 3. Adding new side dish associations
  ///
  /// Parameters:
  /// - [mealId]: ID of the meal to update
  /// - [cookedAt]: New cooked date/time
  /// - [servings]: New servings count
  /// - [notes]: New notes
  /// - [wasSuccessful]: Whether the meal was successful
  /// - [actualPrepTime]: Actual preparation time in minutes
  /// - [actualCookTime]: Actual cooking time in minutes
  /// - [additionalRecipes]: List of side dish recipes to associate
  ///
  /// Throws [NotFoundException] if meal not found.
  Future<void> updateMealWithRecipes({
    required String mealId,
    required DateTime cookedAt,
    required int servings,
    required String notes,
    required bool wasSuccessful,
    required double actualPrepTime,
    required double actualCookTime,
    required List<Recipe> additionalRecipes,
  }) async {
    // 1. Get current meal
    final currentMeal = await _dbHelper.getMeal(mealId);
    if (currentMeal == null) {
      throw NotFoundException('Meal not found: $mealId');
    }

    // 2. Update meal
    final updatedMeal = Meal(
      id: mealId,
      recipeId: currentMeal.recipeId,
      cookedAt: cookedAt,
      servings: servings,
      notes: notes,
      wasSuccessful: wasSuccessful,
      actualPrepTime: actualPrepTime,
      actualCookTime: actualCookTime,
      modifiedAt: DateTime.now(),
    );
    await _dbHelper.updateMeal(updatedMeal);

    // 3. Update recipe associations
    // Delete existing side dishes (keep primary)
    await _dbHelper.deleteMealRecipesByMealId(mealId, excludePrimary: true);

    // Add new side dishes
    for (final recipe in additionalRecipes) {
      final sideDishMealRecipe = MealRecipe(
        mealId: mealId,
        recipeId: recipe.id,
        isPrimaryDish: false,
        notes: 'Side dish',
      );
      await _dbHelper.insertMealRecipe(sideDishMealRecipe);
    }
  }

  /// Record a new meal with primary and additional recipes.
  ///
  /// This method handles:
  /// 1. Recording the meal in the database
  /// 2. Associating the primary recipe
  /// 3. Associating any side dish recipes
  ///
  /// Parameters:
  /// - [meal]: The meal to record
  /// - [primaryRecipe]: The main recipe for this meal
  /// - [additionalRecipes]: List of side dish recipes
  ///
  /// Returns the meal ID.
  Future<String> recordMealWithRecipes({
    required Meal meal,
    required Recipe primaryRecipe,
    required List<Recipe> additionalRecipes,
  }) async {
    // 1. Record meal
    await _dbHelper.insertMeal(meal);

    // 2. Add primary recipe
    final primaryMealRecipe = MealRecipe(
      mealId: meal.id,
      recipeId: primaryRecipe.id,
      isPrimaryDish: true,
      notes: 'Main dish',
    );
    await _dbHelper.insertMealRecipe(primaryMealRecipe);

    // 3. Add side dishes
    for (final recipe in additionalRecipes) {
      final sideDishMealRecipe = MealRecipe(
        mealId: meal.id,
        recipeId: recipe.id,
        isPrimaryDish: false,
        notes: 'Side dish',
      );
      await _dbHelper.insertMealRecipe(sideDishMealRecipe);
    }

    return meal.id;
  }
}
