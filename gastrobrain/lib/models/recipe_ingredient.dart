class RecipeIngredient {
  String id;
  String recipeId;
  String ingredientId;
  double quantity;
  String? notes; // Optional preparation notes, like "diced" or "minced"

  RecipeIngredient({
    required this.id,
    required this.recipeId,
    required this.ingredientId,
    required this.quantity,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipe_id': recipeId,
      'ingredient_id': ingredientId,
      'quantity': quantity,
      'notes': notes,
    };
  }

  factory RecipeIngredient.fromMap(Map<String, dynamic> map) {
    return RecipeIngredient(
      id: map['id'],
      recipeId: map['recipe_id'],
      ingredientId: map['ingredient_id'],
      quantity: map['quantity'],
      notes: map['notes'],
    );
  }
}
