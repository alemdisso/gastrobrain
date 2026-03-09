import 'meal_ingredient.dart';
import 'meal_recipe.dart';
import 'meal_type.dart';

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
  List<MealIngredient>? mealIngredients; // List of simple sides in this meal
  MealType? mealType; // Type of meal (lunch, dinner, prep)

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
    this.mealIngredients,
    this.mealType,
  });

  Meal copyWith({
    String? id,
    String? recipeId,
    DateTime? cookedAt,
    int? servings,
    String? notes,
    bool? wasSuccessful,
    double? actualPrepTime,
    double? actualCookTime,
    DateTime? modifiedAt,
    List<MealRecipe>? mealRecipes,
    List<MealIngredient>? mealIngredients,
    MealType? mealType,
  }) {
    return Meal(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      cookedAt: cookedAt ?? this.cookedAt,
      servings: servings ?? this.servings,
      notes: notes ?? this.notes,
      wasSuccessful: wasSuccessful ?? this.wasSuccessful,
      actualPrepTime: actualPrepTime ?? this.actualPrepTime,
      actualCookTime: actualCookTime ?? this.actualCookTime,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      mealRecipes: mealRecipes ?? this.mealRecipes,
      mealIngredients: mealIngredients ?? this.mealIngredients,
      mealType: mealType ?? this.mealType,
    );
  }

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
      'meal_type': mealType?.value,
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
      mealType: MealType.fromString(map['meal_type']),
      // Note: mealRecipes must be loaded separately
    );
  }
}
