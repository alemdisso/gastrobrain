import 'dart:convert';

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
  List<String> aliases;

  Ingredient({
    required this.id,
    required this.name,
    required this.category,
    this.unit,
    this.proteinType,
    this.notes,
    this.aliases = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category.value,
      'unit': unit?.value,
      'protein_type': proteinType?.name,
      'notes': notes,
      'aliases': aliases.isEmpty ? null : jsonEncode(aliases),
    };
  }

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    List<String> aliases = [];
    if (map['aliases'] != null) {
      try {
        aliases = List<String>.from(
          jsonDecode(map['aliases'] as String) as List,
        );
      } catch (_) {
        // Malformed JSON — treat as no aliases
      }
    }
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
      aliases: aliases,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Ingredient && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
