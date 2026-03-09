import 'package:uuid/uuid.dart';

/// Represents an ingredient added as a simple side to a recorded meal.
///
/// This is a junction model between [Meal] and [Ingredient],
/// supporting two modes:
/// - DB-linked: [ingredientId] is set, [customName] may be null
/// - Free-text: [ingredientId] is null, [customName] is required
///
/// DB-linked sides support future ingredient frequency tracking.
/// Free-text sides are stored for display only.
class MealIngredient {
  final String id;
  final String mealId;
  final String? ingredientId;  // null for free-text entries
  final String? customName;    // non-null when ingredientId is null
  final String? notes;
  final double quantity;       // How much was used (default 1.0)
  final String? unit;          // Unit string — null if unspecified

  /// Whether this is a free-text entry (not linked to a DB ingredient)
  bool get isCustom => ingredientId == null;

  MealIngredient({
    String? id,
    required this.mealId,
    this.ingredientId,
    this.customName,
    this.notes,
    this.quantity = 1.0,
    this.unit,
  }) : id = id ?? const Uuid().v4();

  factory MealIngredient.fromMap(Map<String, dynamic> map) {
    return MealIngredient(
      id: map['id'] as String,
      mealId: map['meal_id'] as String,
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
      'meal_id': mealId,
      'ingredient_id': ingredientId,
      'custom_name': customName,
      'notes': notes,
      'quantity': quantity,
      'unit': unit,
    };
  }

  MealIngredient copyWith({
    String? id,
    String? mealId,
    String? ingredientId,
    String? customName,
    String? notes,
    double? quantity,
    String? unit,
  }) {
    return MealIngredient(
      id: id ?? this.id,
      mealId: mealId ?? this.mealId,
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
      other is MealIngredient &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
