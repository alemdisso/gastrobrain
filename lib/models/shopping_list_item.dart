// lib/models/shopping_list_item.dart

class ShoppingListItem {
  final int? id;
  final int shoppingListId;
  final String ingredientName;
  final double quantity;
  final String unit;
  final String category;
  final bool isPurchased;

  ShoppingListItem({
    this.id,
    required this.shoppingListId,
    required this.ingredientName,
    required this.quantity,
    required this.unit,
    required this.category,
    this.isPurchased = false,
  });

  /// Convert a ShoppingListItem to a Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shopping_list_id': shoppingListId,
      'ingredient_name': ingredientName,
      'quantity': quantity,
      'unit': unit,
      'category': category,
      'is_purchased': isPurchased ? 1 : 0,
    };
  }

  /// Create a ShoppingListItem from a Map retrieved from database
  factory ShoppingListItem.fromMap(Map<String, dynamic> map) {
    return ShoppingListItem(
      id: map['id'] as int?,
      shoppingListId: map['shopping_list_id'] as int,
      ingredientName: map['ingredient_name'] as String,
      quantity: map['quantity'] as double,
      unit: map['unit'] as String,
      category: map['category'] as String,
      isPurchased: map['is_purchased'] == 1,
    );
  }

  /// Create a copy of this ShoppingListItem with optional field updates
  ShoppingListItem copyWith({
    int? id,
    int? shoppingListId,
    String? ingredientName,
    double? quantity,
    String? unit,
    String? category,
    bool? isPurchased,
  }) {
    return ShoppingListItem(
      id: id ?? this.id,
      shoppingListId: shoppingListId ?? this.shoppingListId,
      ingredientName: ingredientName ?? this.ingredientName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      isPurchased: isPurchased ?? this.isPurchased,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoppingListItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
