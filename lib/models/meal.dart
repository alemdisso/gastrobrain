import 'meal_recipe.dart';

class Meal {
  String id;
  String? recipeId; // Make recipeId nullable
  DateTime cookedAt;
  int servings;
  String notes;
  bool wasSuccessful; // Track if the meal worked well this time
  double actualPrepTime; // Track real prep time for future reference
  double actualCookTime; // Track real cook time for future reference
  DateTime? modifiedAt; // Track when the meal was last modified
  List<MealRecipe>? mealRecipes; // List of recipes in this meal

  Meal({
    required this.id,
    this.recipeId,
    required this.cookedAt,
    this.servings = 1,
    this.notes = '',
    this.wasSuccessful = true,
    this.actualPrepTime = 0,
    this.actualCookTime = 0,
    this.modifiedAt,
    this.mealRecipes,
  });

  // Convert a Meal into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipe_id':
          recipeId, // This will be null when not using direct association
      'cooked_at': cookedAt.toIso8601String(),
      'servings': servings,
      'notes': notes,
      'was_successful': wasSuccessful ? 1 : 0,
      'actual_prep_time': actualPrepTime,
      'actual_cook_time': actualCookTime,
      'modified_at': modifiedAt?.toIso8601String(),
      // Note: mealRecipes must be saved separately
    };
  }

  // Create a Meal from a Map
  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      id: map['id'],
      recipeId: map['recipe_id'], // This can now be null
      cookedAt: DateTime.parse(map['cooked_at']),
      servings: map['servings'],
      notes: map['notes'],
      wasSuccessful: map['was_successful'] == 1,
      actualPrepTime: map['actual_prep_time'] ?? 0,
      actualCookTime: map['actual_cook_time'] ?? 0,
      modifiedAt: map['modified_at'] != null
          ? DateTime.parse(map['modified_at'])
          : null,
      // Note: mealRecipes must be loaded separately
    );
  }
}
