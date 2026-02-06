import '../../database/database_helper.dart';
import '../../models/meal.dart';
import '../../models/meal_plan.dart';
import '../../models/meal_plan_item.dart';
import '../../models/recipe.dart';

/// Service for meal action operations
///
/// Provides helper methods for finding and fetching data related to meal operations
/// such as marking meals as cooked, editing cooked meals, and managing side dishes.
class MealActionService {
  final DatabaseHelper _dbHelper;

  const MealActionService(this._dbHelper);

  /// Finds the meal plan item for a specific date and meal type
  ///
  /// Returns null if no meal plan exists or no meal is found for the slot.
  /// Throws an exception if multiple items exist for the same slot (data integrity issue).
  MealPlanItem? findPlannedMealForSlot(
    MealPlan? mealPlan,
    DateTime date,
    String mealType,
  ) {
    if (mealPlan == null) return null;

    final items = mealPlan.getItemsForDateAndMealType(date, mealType);
    if (items.isEmpty) return null;

    // There should only be one meal per slot
    return items.first;
  }

  /// Finds the cooked meal record for a specific date and recipe
  ///
  /// Searches for a meal that was cooked on the specified date (date only, time ignored).
  /// Returns null if no matching cooked meal is found.
  Future<Meal?> findCookedMealForSlot(
    DateTime plannedDate,
    String recipeId,
  ) async {
    final plannedDateOnly = MealPlanItem.formatPlannedDate(plannedDate);
    final searchDate = DateTime.parse(plannedDateOnly);

    // Get all meals for the recipe
    final allMealsForRecipe = await _dbHelper.getMealsForRecipe(recipeId);

    // Find the meal cooked on the planned date
    for (final meal in allMealsForRecipe) {
      final mealDate = DateTime(
        meal.cookedAt.year,
        meal.cookedAt.month,
        meal.cookedAt.day,
      );
      final plannedDateNormalized = DateTime(
        searchDate.year,
        searchDate.month,
        searchDate.day,
      );

      if (mealDate.isAtSameMomentAs(plannedDateNormalized)) {
        return meal;
      }
    }

    return null;
  }

  /// Gets the primary recipe and additional recipes from a meal plan item
  ///
  /// Returns a record with the primary recipe and a list of additional recipes.
  /// Returns null if the primary recipe cannot be found.
  Future<({Recipe primary, List<Recipe> additional})?> getRecipesFromMealPlanItem(
    MealPlanItem mealPlanItem,
    String primaryRecipeId,
  ) async {
    // Get the primary recipe
    final primaryRecipe = await _dbHelper.getRecipe(primaryRecipeId);
    if (primaryRecipe == null) return null;

    // Get any additional recipes from the plan
    final additionalRecipes = <Recipe>[];
    if (mealPlanItem.mealPlanItemRecipes != null) {
      for (final mealRecipe in mealPlanItem.mealPlanItemRecipes!) {
        if (mealRecipe.recipeId != primaryRecipeId) {
          final additionalRecipe =
              await _dbHelper.getRecipe(mealRecipe.recipeId);
          if (additionalRecipe != null) {
            additionalRecipes.add(additionalRecipe);
          }
        }
      }
    }

    return (primary: primaryRecipe, additional: additionalRecipes);
  }

  /// Gets the primary recipe and additional recipes from a cooked meal
  ///
  /// Returns a record with the primary recipe and a list of additional recipes.
  /// Returns null if the primary recipe cannot be found.
  Future<({Recipe primary, List<Recipe> additional})?> getRecipesFromCookedMeal(
    Meal cookedMeal,
    String primaryRecipeId,
  ) async {
    // Get the primary recipe
    final primaryRecipe = await _dbHelper.getRecipe(primaryRecipeId);
    if (primaryRecipe == null) return null;

    // Get current additional recipes from the meal
    final additionalRecipes = <Recipe>[];
    if (cookedMeal.mealRecipes != null) {
      for (final mealRecipe in cookedMeal.mealRecipes!) {
        if (!mealRecipe.isPrimaryDish) {
          final additionalRecipe =
              await _dbHelper.getRecipe(mealRecipe.recipeId);
          if (additionalRecipe != null) {
            additionalRecipes.add(additionalRecipe);
          }
        }
      }
    }

    return (primary: primaryRecipe, additional: additionalRecipes);
  }
}
