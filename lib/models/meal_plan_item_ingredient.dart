import 'package:uuid/uuid.dart';

/// Represents an ingredient added as a simple side to a planned meal.
///
/// This is a junction model between [MealPlanItem] and [Ingredient],
/// supporting two modes:
/// - DB-linked: [ingredientId] is set, [customName] may be null
/// - Free-text: [ingredientId] is null, [customName] is required
///
/// DB-linked sides contribute to shopping list generation.
/// Free-text sides are stored for display only.
class MealPlanItemIngredient {
  final String id;
  final String mealPlanItemId;
  final String? ingredientId;  // null for free-text entries
  final String? customName;    // non-null when ingredientId is null
  final String? notes;
  final double quantity;       // How much to buy (default 1.0)
  final String? unit;          // Unit string (e.g. 'kg', 'g') — null if unspecified

  /// Whether this is a free-text entry (not linked to a DB ingredient)
  bool get isCustom => ingredientId == null;

  MealPlanItemIngredient({
    String? id,
    required this.mealPlanItemId,
    this.ingredientId,
    this.customName,
    this.notes,
    this.quantity = 1.0,
    this.unit,
  }) : id = id ?? const Uuid().v4();

  factory MealPlanItemIngredient.fromMap(Map<String, dynamic> map) {
    return MealPlanItemIngredient(
      id: map['id'] as String,
      mealPlanItemId: map['meal_plan_item_id'] as String,
      ingredientId: map['ingredient_id'] as String?,
      customName: map['custom_name'] as String?,
      notes: map['notes'] as String?,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: map['unit'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'meal_plan_item_id': mealPlanItemId,
      'ingredient_id': ingredientId,
      'custom_name': customName,
      'notes': notes,
      'quantity': quantity,
      'unit': unit,
    };
  }

  MealPlanItemIngredient copyWith({
    String? id,
    String? mealPlanItemId,
    String? ingredientId,
    String? customName,
    String? notes,
    double? quantity,
    String? unit,
  }) {
    return MealPlanItemIngredient(
      id: id ?? this.id,
      mealPlanItemId: mealPlanItemId ?? this.mealPlanItemId,
      ingredientId: ingredientId ?? this.ingredientId,
      customName: customName ?? this.customName,
      notes: notes ?? this.notes,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealPlanItemIngredient &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
