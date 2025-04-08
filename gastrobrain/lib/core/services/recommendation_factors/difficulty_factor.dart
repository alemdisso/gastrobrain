import '../../../models/recipe.dart';
import '../recommendation_service.dart';

/// A scoring factor that considers recipe difficulty when making recommendations.
///
/// This factor assigns higher scores to simpler recipes, making them more likely
/// to be recommended, particularly useful for weekday cooking when time and energy
/// might be more limited.
class DifficultyFactor implements RecommendationFactor {
  @override
  String get id => 'difficulty';

  @override
  int get defaultWeight => 10; // 10% default weight

  @override
  Set<String> get requiredData => {}; // No additional data required

  @override
  Future<double> calculateScore(
      Recipe recipe, Map<String, dynamic> context) async {
    // Recipe difficulty is on a 1-5 scale
    // Lower difficulty should get a higher score (inverse relationship)

    // Handle missing or invalid difficulty
    if (recipe.difficulty <= 0 || recipe.difficulty > 5) {
      return 50.0; // Neutral score for unknown difficulty
    }

    // Convert 1-5 difficulty to 100-20 score (inverse scale)
    // Difficulty 1 -> score 100
    // Difficulty 2 -> score 80
    // Difficulty 3 -> score 60
    // Difficulty 4 -> score 40
    // Difficulty 5 -> score 20
    return 120.0 - (recipe.difficulty * 20.0);
  }

  /// Calculate a score for a recipe based on its difficulty.
  /// This static utility function can be used outside the factor.
  static double calculateDifficultyScore(Recipe recipe) {
    if (recipe.difficulty <= 0 || recipe.difficulty > 5) {
      return 50.0;
    }

    return 120.0 - (recipe.difficulty * 20.0);
  }
}
