// lib/models/meal_plan_item.dart

class MealPlanItem {
  String id;
  String mealPlanId;
  String recipeId;
  String plannedDate; // ISO 8601 date string (YYYY-MM-DD)
  String mealType; // 'lunch' or 'dinner'
  String notes;

  static const String LUNCH = 'lunch';
  static const String DINNER = 'dinner';

  MealPlanItem({
    required this.id,
    required this.mealPlanId,
    required this.recipeId,
    required this.plannedDate,
    required this.mealType,
    this.notes = '',
  }) {
    // Validate meal type
    if (mealType != LUNCH && mealType != DINNER) {
      throw ArgumentError('mealType must be either "lunch" or "dinner"');
    }
  }

  // Convert a MealPlanItem to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'meal_plan_id': mealPlanId,
      'recipe_id': recipeId,
      'planned_date': plannedDate,
      'meal_type': mealType,
      'notes': notes,
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
  }) {
    return MealPlanItem(
      id: id ?? this.id,
      mealPlanId: mealPlanId ?? this.mealPlanId,
      recipeId: recipeId ?? this.recipeId,
      plannedDate: plannedDate ?? this.plannedDate,
      mealType: mealType ?? this.mealType,
      notes: notes ?? this.notes,
    );
  }

  // Helper method to create plannedDate string
  static String formatPlannedDate(DateTime date) {
    // Format as YYYY-MM-DD
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}
