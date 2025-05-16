import 'package:uuid/uuid.dart';

/// Represents a recipe that is part of a planned meal.
///
/// This model creates a junction between meal plan items and recipes,
/// allowing a single planned meal to consist of multiple recipes
/// (e.g., a main dish and several side dishes).
class MealPlanItemRecipe {
  final String id;
  final String mealPlanItemId;
  final String recipeId;
  final bool isPrimaryDish;
  final String? notes;

  MealPlanItemRecipe({
    String? id,
    required this.mealPlanItemId,
    required this.recipeId,
    this.isPrimaryDish = false,
    this.notes,
  }) : id = id ?? const Uuid().v4();

  /// Create a MealPlanItemRecipe from a map (e.g., from database)
  factory MealPlanItemRecipe.fromMap(Map<String, dynamic> map) {
    return MealPlanItemRecipe(
      id: map['id'],
      mealPlanItemId: map['meal_plan_item_id'],
      recipeId: map['recipe_id'],
      isPrimaryDish: map['is_primary_dish'] == 1,
      notes: map['notes'],
    );
  }

  /// Convert a MealPlanItemRecipe to a map (e.g., for database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'meal_plan_item_id': mealPlanItemId,
      'recipe_id': recipeId,
      'is_primary_dish': isPrimaryDish ? 1 : 0,
      'notes': notes,
    };
  }

  /// Create a copy of MealPlanItemRecipe with some fields changed
  MealPlanItemRecipe copyWith({
    String? id,
    String? mealPlanItemId,
    String? recipeId,
    bool? isPrimaryDish,
    String? notes,
  }) {
    return MealPlanItemRecipe(
      id: id ?? this.id,
      mealPlanItemId: mealPlanItemId ?? this.mealPlanItemId,
      recipeId: recipeId ?? this.recipeId,
      isPrimaryDish: isPrimaryDish ?? this.isPrimaryDish,
      notes: notes ?? this.notes,
    );
  }
}
