class Ingredient {
  String id;
  String name;
  String category; // 'protein', 'vegetable', 'grain', etc.
  String? unit; // 'g', 'ml', 'piece', etc.
  String?
      proteinType; // 'fish', 'beef', 'pork', 'chicken', null for non-proteins
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
      'category': category,
      'unit': unit,
      'protein_type': proteinType,
      'notes': notes,
    };
  }

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      unit: map['unit'],
      proteinType: map['protein_type'],
      notes: map['notes'],
    );
  }
}
