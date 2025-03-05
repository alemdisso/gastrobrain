import 'package:uuid/uuid.dart';

/// Represents a recipe that is part of a meal.
///
/// This model creates a junction between meals and recipes,
/// allowing a single meal to consist of multiple recipes
/// (e.g., a main dish and several side dishes).
class MealRecipe {
  final String id;
  final String mealId;
  final String recipeId;
  final bool isPrimaryDish;
  final String? notes;

  MealRecipe({
    String? id,
    required this.mealId,
    required this.recipeId,
    this.isPrimaryDish = false,
    this.notes,
  }) : id = id ?? const Uuid().v4();

  /// Create a MealRecipe from a map (e.g., from database)
  factory MealRecipe.fromMap(Map<String, dynamic> map) {
    return MealRecipe(
      id: map['id'],
      mealId: map['meal_id'],
      recipeId: map['recipe_id'],
      isPrimaryDish: map['is_primary_dish'] == 1,
      notes: map['notes'],
    );
  }

  /// Convert a MealRecipe to a map (e.g., for database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'meal_id': mealId,
      'recipe_id': recipeId,
      'is_primary_dish': isPrimaryDish ? 1 : 0,
      'notes': notes,
    };
  }

  /// Create a copy of MealRecipe with some fields changed
  MealRecipe copyWith({
    String? id,
    String? mealId,
    String? recipeId,
    bool? isPrimaryDish,
    String? notes,
  }) {
    return MealRecipe(
      id: id ?? this.id,
      mealId: mealId ?? this.mealId,
      recipeId: recipeId ?? this.recipeId,
      isPrimaryDish: isPrimaryDish ?? this.isPrimaryDish,
      notes: notes ?? this.notes,
    );
  }
}
