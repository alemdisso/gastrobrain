class RecipeIngredient {
  String id;
  String recipeId;
  String ingredientId; // ID of the ingredient in the ingredients table
  double quantity; // Quantity of the ingredient, like 1.5 or 0.5
  String? notes; // Optional preparation notes, like "diced" or "minced"
  String? unitOverride; // Optional override for the ingredient's unit

  RecipeIngredient({
    required this.id,
    required this.recipeId,
    required this.ingredientId,
    required this.quantity,
    this.notes,
    this.unitOverride,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipe_id': recipeId,
      'ingredient_id': ingredientId,
      'quantity': quantity,
      'notes': notes,
      'unit_override': unitOverride,
    };
  }

  factory RecipeIngredient.fromMap(Map<String, dynamic> map) {
    return RecipeIngredient(
      id: map['id'],
      recipeId: map['recipe_id'],
      ingredientId: map['ingredient_id'],
      quantity: map['quantity'],
      notes: map['notes'],
      unitOverride: map['unit_override'], // Add to factory constructor
    );
  }
}
