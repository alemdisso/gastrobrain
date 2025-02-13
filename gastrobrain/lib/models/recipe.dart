class Recipe {
  String id;
  String name;
  String desiredFrequency;
  String notes;
  DateTime createdAt;

  Recipe({
    required this.id,
    required this.name,
    this.desiredFrequency = 'monthly',
    this.notes = '',
    required this.createdAt,
  });

  // Convert a Recipe into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'desired_frequency': desiredFrequency,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Create a Recipe from a Map
  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'],
      name: map['name'],
      desiredFrequency: map['desired_frequency'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
