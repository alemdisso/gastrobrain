class RecipeIngredient {
  String id;
  String recipeId;
  String? ingredientId;
  double quantity;
  double? quantityMax;
  String? notes;
  String? unitOverride;
  String? customName;
  String? customCategory;
  String? customUnit;

  RecipeIngredient({
    required this.id,
    required this.recipeId,
    required this.ingredientId,
    required this.quantity,
    this.quantityMax,
    this.notes,
    this.unitOverride,
    this.customName,
    this.customCategory,
    this.customUnit,
  });

  bool get isCustom => ingredientId == null;

  /// True when this ingredient has a range quantity (e.g. "2–3 cloves").
  bool get isRange => quantityMax != null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipe_id': recipeId,
      'ingredient_id': ingredientId,
      'quantity': quantity,
      'quantity_max': quantityMax,
      'notes': notes,
      'unit_override': unitOverride,
      'custom_name': customName,
      'custom_category': customCategory,
      'custom_unit': customUnit,
    };
  }

  factory RecipeIngredient.custom({
    required String id,
    required String recipeId,
    required String name,
    required String category,
    required double quantity,
    double? quantityMax,
    String? unit,
    String? notes,
  }) {
    return RecipeIngredient(
      id: id,
      recipeId: recipeId,
      ingredientId: null,
      quantity: quantity,
      quantityMax: quantityMax,
      notes: notes,
      customName: name,
      customCategory: category,
      customUnit: unit,
    );
  }
}
