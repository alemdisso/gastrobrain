class Meal {
  String id;
  String recipeId;
  DateTime cookedAt;
  int servings;
  String notes;

  Meal({
    required this.id,
    required this.recipeId,
    required this.cookedAt,
    this.servings = 1,
    this.notes = '',
  });

  // Convert a Meal into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipe_id': recipeId,
      'cooked_at': cookedAt.toIso8601String(),
      'servings': servings,
      'notes': notes,
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
    );
  }
}
