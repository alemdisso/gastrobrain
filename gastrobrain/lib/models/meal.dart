class Meal {
  String id;
  String recipeId;
  DateTime cookedAt;
  int servings;
  String notes;
  bool wasSuccessful; // Track if the recipe worked well this time
  double actualPrepTime; // Track real prep time for future reference
  double actualCookTime; // Track real cook time for future reference

  Meal({
    required this.id,
    required this.recipeId,
    required this.cookedAt,
    this.servings = 1,
    this.notes = '',
    this.wasSuccessful = true,
    this.actualPrepTime = 0,
    this.actualCookTime = 0,
  });

  // Convert a Meal into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipe_id': recipeId,
      'cooked_at': cookedAt.toIso8601String(),
      'servings': servings,
      'notes': notes,
      'was_successful': wasSuccessful ? 1 : 0,
      'actual_prep_time': actualPrepTime,
      'actual_cook_time': actualCookTime,
    };
  }

  // Create a Meal from a Map
  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      id: map['id'],
      recipeId: map['recipe_id'],
      cookedAt: DateTime.parse(map['cooked_at']),
      servings: map['servings'],
      notes: map['notes'],
      wasSuccessful: map['was_successful'] == 1,
      actualPrepTime: map['actual_prep_time'] ?? 0,
      actualCookTime: map['actual_cook_time'] ?? 0,
    );
  }
}
