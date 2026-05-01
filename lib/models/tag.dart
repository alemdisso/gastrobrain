import '../l10n/app_localizations.dart';

class Tag {
  final String id;
  final String name;
  final String typeId;

  const Tag({
    required this.id,
    required this.name,
    required this.typeId,
  });

  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['id'] as String,
      name: map['name'] as String,
      typeId: map['type_id'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type_id': typeId,
    };
  }

  /// Returns a localized display name for built-in closed-type tags.
  /// Falls back to the raw [name] for open-type tags created by the user.
  String getLocalizedName(AppLocalizations l10n) {
    switch (id) {
      case 'meal-role-main-dish': return l10n.tagMealRoleMainDish;
      case 'meal-role-side-dish': return l10n.tagMealRoleSideDish;
      case 'meal-role-complete-meal': return l10n.tagMealRoleCompleteMeal;
      case 'meal-role-appetizer': return l10n.tagMealRoleAppetizer;
      case 'meal-role-accompaniment': return l10n.tagMealRoleAccompaniment;
      case 'meal-role-dessert': return l10n.tagMealRoleDessert;
      case 'meal-role-snack': return l10n.tagMealRoleSnack;
      case 'food-type-soup': return l10n.tagFoodTypeSoup;
      case 'food-type-stew': return l10n.tagFoodTypeStew;
      case 'food-type-salad': return l10n.tagFoodTypeSalad;
      case 'food-type-stock': return l10n.tagFoodTypeStock;
      case 'food-type-sandwich': return l10n.tagFoodTypeSandwich;
      case 'food-type-pasta': return l10n.tagFoodTypePasta;
      case 'food-type-rice': return l10n.tagFoodTypeRice;
      case 'food-type-grilled': return l10n.tagFoodTypeGrilled;
      case 'food-type-baked': return l10n.tagFoodTypeBaked;
      case 'food-type-raw': return l10n.tagFoodTypeRaw;
      case 'food-type-sauce': return l10n.tagFoodTypeSauce;
      default: return name;
    }
  }

  Tag copyWith({
    String? id,
    String? name,
    String? typeId,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      typeId: typeId ?? this.typeId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tag && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Tag($id, name: $name, typeId: $typeId)';
}
