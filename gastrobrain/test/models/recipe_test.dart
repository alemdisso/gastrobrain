import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';

void main() {
  group('Recipe', () {
    test('creates with default frequency when not provided', () {
      final recipe = Recipe(
        id: 'test_id',
        name: 'Test Recipe',
        createdAt: DateTime.now(),
      );
      expect(recipe.desiredFrequency, FrequencyType.monthly);
    });

    test('creates with provided frequency', () {
      final recipe = Recipe(
        id: 'test_id',
        name: 'Test Recipe',
        createdAt: DateTime.now(),
        desiredFrequency: FrequencyType.weekly,
      );
      expect(recipe.desiredFrequency, FrequencyType.weekly);
    });

    test('converts to map correctly', () {
      final now = DateTime.now();
      final recipe = Recipe(
        id: 'test_id',
        name: 'Test Recipe',
        desiredFrequency: FrequencyType.bimonthly,
        notes: 'Test notes',
        createdAt: now,
        difficulty: 3,
        prepTimeMinutes: 30,
        cookTimeMinutes: 45,
        rating: 4,
      );

      final map = recipe.toMap();
      expect(map['id'], 'test_id');
      expect(map['name'], 'Test Recipe');
      expect(map['desired_frequency'], 'bimonthly');
      expect(map['notes'], 'Test notes');
      expect(map['created_at'], now.toIso8601String());
      expect(map['difficulty'], 3);
      expect(map['prep_time_minutes'], 30);
      expect(map['cook_time_minutes'], 45);
      expect(map['rating'], 4);
    });

    test('creates from map correctly', () {
      final now = DateTime.now();
      final map = {
        'id': 'test_id',
        'name': 'Test Recipe',
        'desired_frequency': 'bimonthly',
        'notes': 'Test notes',
        'created_at': now.toIso8601String(),
        'difficulty': 3,
        'prep_time_minutes': 30,
        'cook_time_minutes': 45,
        'rating': 4,
      };

      final recipe = Recipe.fromMap(map);
      expect(recipe.id, 'test_id');
      expect(recipe.name, 'Test Recipe');
      expect(recipe.desiredFrequency, FrequencyType.bimonthly);
      expect(recipe.notes, 'Test notes');
      expect(recipe.createdAt.toIso8601String(), now.toIso8601String());
      expect(recipe.difficulty, 3);
      expect(recipe.prepTimeMinutes, 30);
      expect(recipe.cookTimeMinutes, 45);
      expect(recipe.rating, 4);
    });

    test('handles legacy or invalid frequency in map', () {
      final map = {
        'id': 'test_id',
        'name': 'Test Recipe',
        'desired_frequency': 'invalid_frequency',
        'created_at': DateTime.now().toIso8601String(),
      };

      final recipe = Recipe.fromMap(map);
      expect(recipe.desiredFrequency, FrequencyType.monthly);
    });
  });
}
