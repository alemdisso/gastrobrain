class RecipeIngredient {
  String id;
  String recipeId;
  String?
      ingredientId; // ID of the ingredient in the ingredients table or null for custom ingredients
  double quantity; // Quantity of the ingredient, like 1.5 or 0.5
  String? notes; // Optional preparation notes, like "diced" or "minced"
  String? unitOverride; // Optional override for the ingredient's unit
  String? customName;
  String? customCategory;
  String? customUnit;

  RecipeIngredient({
    required this.id,
    required this.recipeId,
    required this.ingredientId,
    required this.quantity,
    this.notes,
    this.unitOverride,
    this.customName,
    this.customCategory,
    this.customUnit,
  });

  // Convenience getter to check if this is a custom ingredient
  bool get isCustom => ingredientId == null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipe_id': recipeId,
      'ingredient_id': ingredientId,
      'quantity': quantity,
      'notes': notes,
      'unit_override': unitOverride,
      'custom_name': customName,
      'custom_category': customCategory,
      'custom_unit': customUnit,
    };
  }

  // Factory constructor for creating a custom ingredient
  factory RecipeIngredient.custom({
    required String id,
    required String recipeId,
    required String name,
    required String category,
    required double quantity,
    String? unit,
    String? notes,
  }) {
    return RecipeIngredient(
      id: id,
      recipeId: recipeId,
      ingredientId: null,
      quantity: quantity,
      notes: notes,
      customName: name,
      customCategory: category,
      customUnit: unit,
    );
  }
}
