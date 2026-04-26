import 'frequency_type.dart';
import 'recipe_category.dart';

class Recipe {
  String id;
  String name;
  FrequencyType desiredFrequency;
  String notes;
  String instructions; // Cooking instructions
  String story; // Personal and cultural narrative context
  DateTime createdAt;
  int difficulty; // 1-5 scale
  int prepTimeMinutes; // Preparation time in minutes
  int cookTimeMinutes; // Cooking time in minutes
  int marinatingTimeMinutes; // Marinating time in minutes (0 = not applicable)
  int rating; // 1-5 scale
  RecipeCategory category; // Category of the recipe
  int servings; // Baseline yield (how many people this recipe serves)

  Recipe({
    required this.id,
    required this.name,
    FrequencyType? desiredFrequency,
    this.notes = '',
    this.instructions = '',
    this.story = '',
    required this.createdAt,
    this.difficulty = 1,
    this.prepTimeMinutes = 0,
    this.cookTimeMinutes = 0,
    this.marinatingTimeMinutes = 0,
    this.rating = 0,
    RecipeCategory? category,
    this.servings = 4,
  })  : desiredFrequency = desiredFrequency ?? FrequencyType.monthly,
        category = category ?? RecipeCategory.uncategorized;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'desired_frequency': desiredFrequency.value,
      'notes': notes,
      'instructions': instructions,
      'story': story,
      'created_at': createdAt.toIso8601String(),
      'difficulty': difficulty,
      'prep_time_minutes': prepTimeMinutes,
      'cook_time_minutes': cookTimeMinutes,
      'marinating_time_minutes': marinatingTimeMinutes,
      'rating': rating,
      'category': category.value,
      'servings': servings,
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'],
      name: map['name'],
      desiredFrequency:
          FrequencyType.fromString(map['desired_frequency'] ?? 'monthly'),
      notes: map['notes'] ?? '',
      instructions: map['instructions'] ?? '',
      story: map['story'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      difficulty: map['difficulty'] ?? 1,
      prepTimeMinutes: map['prep_time_minutes'] ?? 0,
      cookTimeMinutes: map['cook_time_minutes'] ?? 0,
      marinatingTimeMinutes: map['marinating_time_minutes'] ?? 0,
      rating: map['rating'] ?? 0,
      category: RecipeCategory.fromString(map['category'] ?? 'uncategorized'),
      servings: map['servings'] ?? 4,
    );
  }

  Recipe copyWith({
    String? id,
    String? name,
    FrequencyType? desiredFrequency,
    String? notes,
    String? instructions,
    String? story,
    DateTime? createdAt,
    int? difficulty,
    int? prepTimeMinutes,
    int? cookTimeMinutes,
    int? marinatingTimeMinutes,
    int? rating,
    RecipeCategory? category,
    int? servings,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      desiredFrequency: desiredFrequency ?? this.desiredFrequency,
      notes: notes ?? this.notes,
      instructions: instructions ?? this.instructions,
      story: story ?? this.story,
      createdAt: createdAt ?? this.createdAt,
      difficulty: difficulty ?? this.difficulty,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
      marinatingTimeMinutes: marinatingTimeMinutes ?? this.marinatingTimeMinutes,
      rating: rating ?? this.rating,
      category: category ?? this.category,
      servings: servings ?? this.servings,
    );
  }
}
