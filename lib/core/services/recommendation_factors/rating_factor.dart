// lib/core/services/recommendation_factors/rating_factor.dart

import '../../../models/recipe.dart';
import '../recommendation_service.dart';

/// A scoring factor that prioritizes recipes based on user ratings.
///
/// This factor assigns higher scores to recipes that have higher user ratings,
/// acting as a quality tiebreaker between similar options. Recipes with
/// no rating receive a neutral score.
class RatingFactor implements RecommendationFactor {
  @override
  String get id => 'rating';

  @override
  int get defaultWeight => 10; // 10% default weight (reduced from 15%)

  @override
  Set<String> get requiredData =>
      {}; // No additional data required beyond the recipe itself

  @override
  Future<double> calculateScore(
      Recipe recipe, Map<String, dynamic> context) async {
    // Get recipe rating (1-5 scale)
    final rating = recipe.rating;

    // Calculate score (0-100 scale)
    // - Recipes with no rating (0) get a neutral score of 50
    // - Recipes with ratings 1-5 get scores from 20-100

    if (rating == 0) {
      // No rating - return neutral score
      return 50.0;
    }

    // Convert 1-5 rating to 20-100 score (with 20-point intervals)
    return 20.0 * rating.toDouble();
  }

  /// Calculate a score for a recipe based on its rating.
  /// This static utility function can be used outside the factor.
  static double calculateRatingScore(Recipe recipe) {
    final rating = recipe.rating;

    if (rating == 0) {
      return 50.0;
    }

    return 20.0 * rating.toDouble();
  }
}
