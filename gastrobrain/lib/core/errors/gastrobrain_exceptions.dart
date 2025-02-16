// lib/core/errors/gastrobrain_exceptions.dart

/// Base exception class for all Gastrobrain-specific exceptions
class GastrobrainException implements Exception {
  final String message;

  GastrobrainException(this.message);

  @override
  String toString() => 'GastrobrainException: $message';
}

/// Thrown when input validation fails
class ValidationException extends GastrobrainException {
  ValidationException(String message) : super(message);

  @override
  String toString() => 'ValidationException: $message';
}

/// Thrown when attempting to create a duplicate entry
class DuplicateException extends GastrobrainException {
  DuplicateException(String message) : super(message);

  @override
  String toString() => 'DuplicateException: $message';
}

/// Thrown when a requested resource is not found
class NotFoundException extends GastrobrainException {
  NotFoundException(String message) : super(message);

  @override
  String toString() => 'NotFoundException: $message';
}

/// Validation functions for different entities
class EntityValidator {
  static void validateIngredient({
    required String name,
    required String unit,
    required double quantity,
  }) {
    if (name.isEmpty) {
      throw ValidationException('Ingredient name cannot be empty');
    }
    if (unit.isEmpty) {
      throw ValidationException('Ingredient unit cannot be empty');
    }
    if (quantity <= 0) {
      throw ValidationException('Ingredient quantity must be positive');
    }
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
  }

  static void validateRecipe({
    required String name,
    required List<Map<String, dynamic>> ingredients,
    required List<String> instructions,
  }) {
    if (name.isEmpty) {
      throw ValidationException('Recipe name cannot be empty');
    }
    if (ingredients.isEmpty) {
      throw ValidationException('Recipe must include at least one ingredient');
    }
    if (instructions.isEmpty) {
      throw ValidationException('Recipe must include at least one instruction');
    }

    // Validate each ingredient in the recipe
    for (final ingredient in ingredients) {
      validateIngredient(
        name: ingredient['name'] as String,
        unit: ingredient['unit'] as String,
        quantity: ingredient['quantity'] as double,
      );
    }
  }
}

/// Example usage in a service class
class GastrobrainService {
  Future<void> addIngredient({
    required String name,
    required String unit,
    required double quantity,
  }) async {
    try {
      // Validate input
      EntityValidator.validateIngredient(
        name: name,
        unit: unit,
        quantity: quantity,
      );

      // Check for duplicates
      if (await _ingredientExists(name)) {
        throw DuplicateException('Ingredient $name already exists');
      }

      // Save ingredient
      await _saveIngredient({
        'name': name,
        'unit': unit,
        'quantity': quantity,
      });
    } catch (e) {
      if (e is GastrobrainException) {
        rethrow;
      }
      throw GastrobrainException('Failed to add ingredient: $e');
    }
  }

  Future<void> addRecipe({
    required String name,
    required List<Map<String, dynamic>> ingredients,
    required List<String> instructions,
  }) async {
    try {
      // Validate input
      EntityValidator.validateRecipe(
        name: name,
        ingredients: ingredients,
        instructions: instructions,
      );

      // Check for duplicates
      if (await _recipeExists(name)) {
        throw DuplicateException('Recipe $name already exists');
      }

      // Verify all ingredients exist
      for (final ingredient in ingredients) {
        if (!await _ingredientExists(ingredient['name'] as String)) {
          throw NotFoundException(
            'Ingredient ${ingredient['name']} not found',
          );
        }
      }

      // Save recipe
      await _saveRecipe({
        'name': name,
        'ingredients': ingredients,
        'instructions': instructions,
      });
    } catch (e) {
      if (e is GastrobrainException) {
        rethrow;
      }
      throw GastrobrainException('Failed to add recipe: $e');
    }
  }

  // Database operation stubs (to be implemented)
  Future<bool> _ingredientExists(String name) async {
    // Implementation details
    return false;
  }

  Future<bool> _recipeExists(String name) async {
    // Implementation details
    return false;
  }

  Future<void> _saveIngredient(Map<String, dynamic> ingredient) async {
    // Implementation details
  }

  Future<void> _saveRecipe(Map<String, dynamic> recipe) async {
    // Implementation details
  }
}
