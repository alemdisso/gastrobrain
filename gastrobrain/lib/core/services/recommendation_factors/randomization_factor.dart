import 'dart:math';
import 'dart:convert';
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

  @override
  Future<double> calculateScore(
      Recipe recipe, Map<String, dynamic> context) async {
    // Check if a random seed is provided for deterministic results (useful for testing)
    final int? baseSeed = context['randomSeed'] as int?;

    // Create a recipe-specific seed by combining the base seed with the recipe ID
    // This ensures each recipe gets a different but deterministic random score
    final recipeSpecificSeed = _createRecipeSpecificSeed(recipe.id, baseSeed);

    // Create random number generator with the recipe-specific seed
    final random = Random(recipeSpecificSeed);

    // Generate a random score between 0 and 100
    // This ensures the randomization factor contributes a value in the same
    // range as other factors for consistent weighting
    return random.nextDouble() * 100;
  }

  /// Creates a deterministic seed specific to a recipe
  int _createRecipeSpecificSeed(String recipeId, int? baseSeed) {
    // Start with the base seed (or 0 if null)
    int seed = baseSeed ?? 0;

    // Combine with a hash of the recipe ID to make it unique per recipe
    // Use a simple hash function that converts the recipe ID to a number
    final recipeHash =
        recipeId.codeUnits.fold<int>(0, (hash, char) => hash * 31 + char);

    // Combine the two seeds
    return seed ^ recipeHash;
  }

  /// Calculate a random score for a recipe.
  /// This static utility function can be used outside the factor.
  static double calculateRandomScore(String recipeId, {int? seed}) {
    final recipeSpecificSeed = _createStaticRecipeSpecificSeed(recipeId, seed);
    final random = Random(recipeSpecificSeed);
    return random.nextDouble() * 100;
  }

  /// Static version of the recipe-specific seed creation for the utility method
  static int _createStaticRecipeSpecificSeed(String recipeId, int? baseSeed) {
    int seed = baseSeed ?? 0;
    final recipeHash =
        recipeId.codeUnits.fold<int>(0, (hash, char) => hash * 31 + char);
    return seed ^ recipeHash;
  }
}
