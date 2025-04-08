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

  @override
  Future<double> calculateScore(
      Recipe recipe, Map<String, dynamic> context) async {
    // Check if a random seed is provided for deterministic results (useful for testing)
    final int? seed = context['randomSeed'] as int?;

    // Create random number generator, optionally with seed
    final random = seed != null ? Random(seed) : Random();

    // Generate a random score between 0 and 100
    // This ensures the randomization factor contributes a value in the same
    // range as other factors for consistent weighting
    return random.nextDouble() * 100;
  }

  /// Calculate a random score for a recipe.
  /// This static utility function can be used outside the factor.
  static double calculateRandomScore({int? seed}) {
    final random = seed != null ? Random(seed) : Random();
    return random.nextDouble() * 100;
  }
}
