// test/edge_cases/boundary_conditions/rating_difficulty_boundary_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/frequency_type.dart';

/// Tests for rating and difficulty boundary conditions.
///
/// Verifies that rating and difficulty values are properly handled at boundaries:
/// - Rating: 0 (unrated) and 1-5 scale
/// - Difficulty: 1-5 scale
/// - Model construction with boundary values
/// - Database serialization/deserialization
void main() {
  group('Rating Boundary Conditions', () {
    group('Valid Rating Values', () {
      test('rating = 0 is valid (unrated)', () {
        // Zero rating means the recipe hasn't been rated yet
        final recipe = Recipe(
          id: 'test-1',
          name: 'Test Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 3,
          rating: 0,
        );

        expect(recipe.rating, equals(0),
            reason: 'Zero rating should represent unrated state');
      });

      test('rating = 1 is valid (minimum rating)', () {
        final recipe = Recipe(
          id: 'test-1',
          name: 'Test Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 3,
          rating: 1,
        );

        expect(recipe.rating, equals(1),
            reason: 'One star rating should be valid');
      });

      test('rating = 2 is valid', () {
        final recipe = Recipe(
          id: 'test-1',
          name: 'Test Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 3,
          rating: 2,
        );

        expect(recipe.rating, equals(2));
      });

      test('rating = 3 is valid', () {
        final recipe = Recipe(
          id: 'test-1',
          name: 'Test Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 3,
          rating: 3,
        );

        expect(recipe.rating, equals(3));
      });

      test('rating = 4 is valid', () {
        final recipe = Recipe(
          id: 'test-1',
          name: 'Test Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 3,
          rating: 4,
        );

        expect(recipe.rating, equals(4));
      });

      test('rating = 5 is valid (maximum rating)', () {
        final recipe = Recipe(
          id: 'test-1',
          name: 'Test Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 3,
          rating: 5,
        );

        expect(recipe.rating, equals(5),
            reason: 'Five stars should be maximum rating');
      });
    });

    group('Rating Default Value', () {
      test('rating defaults to 0 when not specified', () {
        final recipe = Recipe(
          id: 'test-1',
          name: 'Test Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 3,
          // rating not specified
        );

        expect(recipe.rating, equals(0),
            reason: 'Rating should default to 0 (unrated)');
      });
    });

    group('Rating Out-of-Range Values (UI Constraint)', () {
      test('rating = 6 can be stored (no validation)', () {
        // Note: While the UI constrains ratings to 0-5, the model doesn't validate
        // This test documents that the model will accept out-of-range values
        final recipe = Recipe(
          id: 'test-1',
          name: 'Test Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 3,
          rating: 6,
        );

        expect(recipe.rating, equals(6),
            reason: 'Model accepts values outside UI constraints');
      });

      test('negative rating can be stored (no validation)', () {
        final recipe = Recipe(
          id: 'test-1',
          name: 'Test Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 3,
          rating: -1,
        );

        expect(recipe.rating, equals(-1),
            reason: 'Model allows negative ratings (though UI prevents this)');
      });
    });

    group('Rating Serialization', () {
      test('rating = 0 serializes and deserializes correctly', () {
        final original = Recipe(
          id: 'test-1',
          name: 'Test Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 3,
          rating: 0,
        );

        final map = original.toMap();
        final deserialized = Recipe.fromMap(map);

        expect(deserialized.rating, equals(0),
            reason: 'Zero rating should survive serialization');
      });

      test('rating = 5 serializes and deserializes correctly', () {
        final original = Recipe(
          id: 'test-1',
          name: 'Test Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 3,
          rating: 5,
        );

        final map = original.toMap();
        final deserialized = Recipe.fromMap(map);

        expect(deserialized.rating, equals(5),
            reason: 'Maximum rating should survive serialization');
      });
    });
  });

  group('Difficulty Boundary Conditions', () {
    group('Valid Difficulty Values', () {
      test('difficulty = 1 is valid (minimum/easiest)', () {
        final recipe = Recipe(
          id: 'test-1',
          name: 'Test Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 1,
        );

        expect(recipe.difficulty, equals(1),
            reason: 'Difficulty 1 should be valid (easiest)');
      });

      test('difficulty = 2 is valid', () {
        final recipe = Recipe(
          id: 'test-1',
          name: 'Test Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 2,
        );

        expect(recipe.difficulty, equals(2));
      });

      test('difficulty = 3 is valid (medium)', () {
        final recipe = Recipe(
          id: 'test-1',
          name: 'Test Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 3,
        );

        expect(recipe.difficulty, equals(3));
      });

      test('difficulty = 4 is valid', () {
        final recipe = Recipe(
          id: 'test-1',
          name: 'Test Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 4,
        );

        expect(recipe.difficulty, equals(4));
      });

      test('difficulty = 5 is valid (maximum/hardest)', () {
        final recipe = Recipe(
          id: 'test-1',
          name: 'Test Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 5,
        );

        expect(recipe.difficulty, equals(5),
            reason: 'Difficulty 5 should be valid (hardest)');
      });
    });

    group('Difficulty Default Value', () {
      test('difficulty defaults to 1 when not specified', () {
        final recipe = Recipe(
          id: 'test-1',
          name: 'Test Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          // difficulty not specified
        );

        expect(recipe.difficulty, equals(1),
            reason: 'Difficulty should default to 1 (easiest)');
      });
    });

    group('Difficulty Out-of-Range Values (UI Constraint)', () {
      test('difficulty = 0 can be stored (no validation)', () {
        // Note: UI constrains to 1-5, but model doesn't validate
        final recipe = Recipe(
          id: 'test-1',
          name: 'Test Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 0,
        );

        expect(recipe.difficulty, equals(0),
            reason: 'Model accepts zero difficulty (though UI prevents this)');
      });

      test('difficulty = 6 can be stored (no validation)', () {
        final recipe = Recipe(
          id: 'test-1',
          name: 'Test Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 6,
        );

        expect(recipe.difficulty, equals(6),
            reason: 'Model accepts values outside UI constraints');
      });

      test('negative difficulty can be stored (no validation)', () {
        final recipe = Recipe(
          id: 'test-1',
          name: 'Test Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: -1,
        );

        expect(recipe.difficulty, equals(-1));
      });
    });

    group('Difficulty Serialization', () {
      test('difficulty = 1 serializes and deserializes correctly', () {
        final original = Recipe(
          id: 'test-1',
          name: 'Test Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 1,
        );

        final map = original.toMap();
        final deserialized = Recipe.fromMap(map);

        expect(deserialized.difficulty, equals(1),
            reason: 'Minimum difficulty should survive serialization');
      });

      test('difficulty = 5 serializes and deserializes correctly', () {
        final original = Recipe(
          id: 'test-1',
          name: 'Test Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 5,
        );

        final map = original.toMap();
        final deserialized = Recipe.fromMap(map);

        expect(deserialized.difficulty, equals(5),
            reason: 'Maximum difficulty should survive serialization');
      });
    });
  });

  group('Rating and Difficulty Combined', () {
    test('recipe with both minimum values', () {
      final recipe = Recipe(
        id: 'test-1',
        name: 'Test Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
        difficulty: 1,
        rating: 0,
      );

      expect(recipe.difficulty, equals(1));
      expect(recipe.rating, equals(0));
    });

    test('recipe with both maximum values', () {
      final recipe = Recipe(
        id: 'test-1',
        name: 'Test Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
        difficulty: 5,
        rating: 5,
      );

      expect(recipe.difficulty, equals(5));
      expect(recipe.rating, equals(5));
    });

    test('recipe with mixed boundary values', () {
      final recipe = Recipe(
        id: 'test-1',
        name: 'Test Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
        difficulty: 1,
        rating: 5,
      );

      expect(recipe.difficulty, equals(1),
          reason: 'Easy recipe with high rating');
      expect(recipe.rating, equals(5));
    });

    test('recipe serialization with boundary values', () {
      final original = Recipe(
        id: 'test-1',
        name: 'Test Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
        difficulty: 5,
        rating: 0,
      );

      final map = original.toMap();
      expect(map['difficulty'], equals(5));
      expect(map['rating'], equals(0));

      final deserialized = Recipe.fromMap(map);
      expect(deserialized.difficulty, equals(5));
      expect(deserialized.rating, equals(0));
    });
  });

  group('Rating and Difficulty Edge Cases', () {
    test('all valid rating values can be stored', () {
      for (int rating = 0; rating <= 5; rating++) {
        final recipe = Recipe(
          id: 'test-$rating',
          name: 'Test Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: 3,
          rating: rating,
        );
        expect(recipe.rating, equals(rating),
            reason: 'Rating $rating should be valid');
      }
    });

    test('all valid difficulty values can be stored', () {
      for (int difficulty = 1; difficulty <= 5; difficulty++) {
        final recipe = Recipe(
          id: 'test-$difficulty',
          name: 'Test Recipe',
          desiredFrequency: FrequencyType.weekly,
          createdAt: DateTime.now(),
          difficulty: difficulty,
        );
        expect(recipe.difficulty, equals(difficulty),
            reason: 'Difficulty $difficulty should be valid');
      }
    });

    test('recipe equality with same rating and difficulty', () {
      final recipe1 = Recipe(
        id: 'test-1',
        name: 'Test Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
        difficulty: 3,
        rating: 4,
      );

      final recipe2 = Recipe(
        id: 'test-1',
        name: 'Test Recipe',
        desiredFrequency: FrequencyType.weekly,
        createdAt: recipe1.createdAt,
        difficulty: 3,
        rating: 4,
      );

      expect(recipe1.difficulty, equals(recipe2.difficulty));
      expect(recipe1.rating, equals(recipe2.rating));
    });
  });
}
