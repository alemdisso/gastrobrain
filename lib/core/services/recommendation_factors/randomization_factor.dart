import 'dart:math';
import '../../../models/recipe.dart';
import '../recommendation_service.dart';

/// A scoring factor that adds a small randomization element to recipe recommendations.
///
/// This factor adds a small random adjustment to the final score to prevent identical
/// recommendations and keep suggestions fresh even with similar scoring.
class RandomizationFactor implements RecommendationFactor {
  @override
  String get id => 'randomization';

  @override
  int get defaultWeight => 5; // 5% weight in the total recommendation score

  @override
  Set<String> get requiredData => {}; // No additional data required

  /// Creates a deterministic seed specific to a recipe
  @override
  Future<double> calculateScore(
      Recipe recipe, Map<String, dynamic> context) async {
    // Check if a random seed is provided for deterministic results (useful for testing)
    final int? baseSeed = context['randomSeed'] as int?;

    // Handle the case where we explicitly want randomness (baseSeed is null)
    // and the case where we want deterministic results (baseSeed is not null)
    Random random;

    if (baseSeed == null) {
      // For truly random behavior when no seed is provided, use a new Random instance
      // This will use system entropy and produce different results each time
      random = Random();
    } else {
      // When a seed is provided, create a deterministic random generator
      // based on the recipe ID and provided seed
      final recipeSpecificSeed = _createRecipeSpecificSeed(recipe.id, baseSeed);
      random = Random(recipeSpecificSeed);
    }

    // Generate a random score between 0 and 100
    return random.nextDouble() * 100;
  }

// Simplify the seed generation to focus only on the deterministic case
  int _createRecipeSpecificSeed(String recipeId, int baseSeed) {
    // Generate a deterministic hash for the recipe ID
    final recipeHash = recipeId.codeUnits
        .fold<int>(0, (hash, char) => (hash * 31 + char) & 0x7FFFFFFF);

    // Combine the seed with the recipe hash using XOR for deterministic results
    return baseSeed ^ recipeHash;
  }

  /// Calculate a random score for a recipe.
  /// This static utility function can be used outside the factor.
  static double calculateRandomScore(String recipeId, {int? seed}) {
    if (seed == null) {
      // Use system entropy for true randomness
      return Random().nextDouble() * 100;
    } else {
      // Use deterministic random for testing
      final recipeSpecificSeed =
          _createStaticRecipeSpecificSeed(recipeId, seed);
      return Random(recipeSpecificSeed).nextDouble() * 100;
    }
  }

  /// Static version of the recipe-specific seed creation for the utility method
  static int _createStaticRecipeSpecificSeed(String recipeId, int baseSeed) {
    final recipeHash = recipeId.codeUnits
        .fold<int>(0, (hash, char) => (hash * 31 + char) & 0x7FFFFFFF);

    return baseSeed ^ recipeHash;
  }
}
