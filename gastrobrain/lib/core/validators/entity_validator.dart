// lib/core/validators/entity_validator.dart

import '../errors/gastrobrain_exceptions.dart';

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
}
