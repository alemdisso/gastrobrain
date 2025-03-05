import 'meal_plan_item_recipe.dart';

class MealPlanItem {
  String id;
  String mealPlanId;
  String plannedDate; // ISO 8601 date string (YYYY-MM-DD)
  String mealType; // 'lunch' or 'dinner'
  String notes;
  List<MealPlanItemRecipe>?
      mealPlanItemRecipes; // List of recipes in this planned meal

  // For backward compatibility
  String? recipeId;

  static const String lunch = 'lunch';
  static const String dinner = 'dinner';

  MealPlanItem({
    required this.id,
    required this.mealPlanId,
    required this.recipeId,
    required this.plannedDate,
    required this.mealType,
    this.notes = '',
    this.mealPlanItemRecipes,
  }) {
    // Validate meal type
    if (mealType != lunch && mealType != dinner) {
      throw ArgumentError('mealType must be either "lunch" or "dinner"');
    }
  }

  // Convert a MealPlanItem to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'meal_plan_id': mealPlanId,
      'recipe_id': recipeId, // Keep for backward compatibility
      'planned_date': plannedDate,
      'meal_type': mealType,
      'notes': notes,
      // Note: mealPlanItemRecipes must be saved separately
    };
  }

  // Create a MealPlanItem from a Map
  factory MealPlanItem.fromMap(Map<String, dynamic> map) {
    return MealPlanItem(
      id: map['id'],
      mealPlanId: map['meal_plan_id'],
      recipeId: map['recipe_id'],
      plannedDate: map['planned_date'],
      mealType: map['meal_type'],
      notes: map['notes'] ?? '',
      // Note: mealPlanItemRecipes must be loaded separately
    );
  }

  // Create a copy of this item with some fields potentially changed
  MealPlanItem copyWith({
    String? id,
    String? mealPlanId,
    String? recipeId,
    String? plannedDate,
    String? mealType,
    String? notes,
    List<MealPlanItemRecipe>? mealPlanItemRecipes,
  }) {
    return MealPlanItem(
      id: id ?? this.id,
      mealPlanId: mealPlanId ?? this.mealPlanId,
      recipeId: recipeId ?? this.recipeId,
      plannedDate: plannedDate ?? this.plannedDate,
      mealType: mealType ?? this.mealType,
      notes: notes ?? this.notes,
      mealPlanItemRecipes: mealPlanItemRecipes ?? this.mealPlanItemRecipes,
    );
  }

  // Helper method to create plannedDate string
  static String formatPlannedDate(DateTime date) {
    // Format as YYYY-MM-DD
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}
