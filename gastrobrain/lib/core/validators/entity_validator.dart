// lib/core/validators/entity_validator.dart

import '../errors/gastrobrain_exceptions.dart';
import '../../models/meal_plan_item.dart';

class EntityValidator {
  static void validateRecipe({
    required String name,
    required List<Map<String, dynamic>> ingredients,
    required List<String> instructions,
  }) {
    if (name.isEmpty) {
      throw ValidationException('Recipe name cannot be empty');
    }
    // Note: temporarily disabling these checks until we implement ingredients and instructions
    // if (ingredients.isEmpty) {
    //   throw ValidationException('Recipe must include at least one ingredient');
    // }
    // if (instructions.isEmpty) {
    //   throw ValidationException('Recipe must include at least one instruction');
    // }
  }

  static void validateMeal({
    required String name,
    required DateTime date,
    required List<String> recipeIds,
  }) {
    if (name.isEmpty) {
      throw ValidationException('Meal name cannot be empty');
    }
    if (recipeIds.isEmpty) {
      throw ValidationException('Meal must include at least one recipe');
    }
    if (date.isAfter(DateTime.now())) {
      throw ValidationException('Meal date cannot be in the future');
    }
  }

  static void validateServings(int servings) {
    if (servings <= 0) {
      throw ValidationException('Number of servings must be positive');
    }
  }

  static void validateTime(double? time, String field) {
    if (time != null && time < 0) {
      throw ValidationException('$field time cannot be negative');
    }
  }

  static void validateIngredient({
    required String name,
    required String category,
    String? unit,
    String? proteinType,
  }) {
    if (name.isEmpty) {
      throw ValidationException('Ingredient name cannot be empty');
    }
    if (category.isEmpty) {
      throw ValidationException('Category must be selected');
    }
    if (category == 'protein' && proteinType == null) {
      throw ValidationException(
          'Protein type must be selected for protein ingredients');
    }
  }

  static void validateRecipeIngredient({
    required String ingredientId,
    required String recipeId,
    required double quantity,
  }) {
    if (ingredientId.isEmpty) {
      throw ValidationException('Ingredient must be selected');
    }
    if (recipeId.isEmpty) {
      throw ValidationException('Recipe ID cannot be empty');
    }
    if (quantity <= 0) {
      throw ValidationException('Quantity must be greater than zero');
    }
  }

  // Add to entity_validator.dart
  static void validateMealPlan({
    required String id,
    required DateTime weekStartDate,
  }) {
    if (id.isEmpty) {
      throw ValidationException('Meal plan ID cannot be empty');
    }

    // Validate week start date is a Friday
    if (weekStartDate.weekday != DateTime.friday) {
      throw ValidationException('Week start date must be a Friday');
    }

    // Validate week start date is not in the future
    if (weekStartDate.isAfter(DateTime.now())) {
      throw ValidationException('Week start date cannot be in the future');
    }
  }

  static void validateMealPlanItem({
    required String mealPlanId,
    required String recipeId,
    required String plannedDate,
    required String mealType,
  }) {
    if (mealPlanId.isEmpty) {
      throw ValidationException('Meal plan ID cannot be empty');
    }
    if (recipeId.isEmpty) {
      throw ValidationException('Recipe ID cannot be empty');
    }

    // Validate planned date format (YYYY-MM-DD)
    final datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!datePattern.hasMatch(plannedDate)) {
      throw ValidationException('Planned date must be in YYYY-MM-DD format');
    }

    // Validate meal type
    if (mealType != MealPlanItem.lunch && mealType != MealPlanItem.dinner) {
      throw ValidationException('Meal type must be either "lunch" or "dinner"');
    }
  }
}
