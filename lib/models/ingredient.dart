import 'ingredient_category.dart';
import 'measurement_unit.dart';
import 'protein_type.dart';

class Ingredient {
  String id;
  String name;
  IngredientCategory category;
  MeasurementUnit? unit;
  ProteinType? proteinType; // null for non-proteins
  String? notes;

  Ingredient({
    required this.id,
    required this.name,
    required this.category,
    this.unit,
    this.proteinType,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category.value,
      'unit': unit?.value,
      'protein_type': proteinType?.name,
      'notes': notes,
    };
  }

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      id: map['id'],
      name: map['name'],
      category: IngredientCategory.fromString(map['category']),
      unit: MeasurementUnit.fromString(map['unit']),
      proteinType: map['protein_type'] != null 
          ? ProteinType.values.firstWhere(
              (type) => type.name == map['protein_type'],
              orElse: () => ProteinType.other,
            )
          : null,
      notes: map['notes'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Ingredient && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
