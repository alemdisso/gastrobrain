class Recipe {
  String id;
  String name;
  String desiredFrequency;
  String notes;
  DateTime createdAt;
  // New fields
  int difficulty; // 1-5 scale
  int prepTimeMinutes; // Preparation time in minutes
  int cookTimeMinutes; // Cooking time in minutes
  int rating; // 1-5 scale

  Recipe({
    required this.id,
    required this.name,
    this.desiredFrequency = 'monthly',
    this.notes = '',
    required this.createdAt,
    this.difficulty = 1,
    this.prepTimeMinutes = 0,
    this.cookTimeMinutes = 0,
    this.rating = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'desired_frequency': desiredFrequency,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'difficulty': difficulty,
      'prep_time_minutes': prepTimeMinutes,
      'cook_time_minutes': cookTimeMinutes,
      'rating': rating,
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'],
      name: map['name'],
      desiredFrequency: map['desired_frequency'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      difficulty: map['difficulty'] ?? 1,
      prepTimeMinutes: map['prep_time_minutes'] ?? 0,
      cookTimeMinutes: map['cook_time_minutes'] ?? 0,
      rating: map['rating'] ?? 0,
    );
  }
}
