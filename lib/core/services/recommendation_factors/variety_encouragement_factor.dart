// lib/core/services/recommendation_factors/variety_encouragement_factor.dart

import 'dart:math';
import '../../../models/recipe.dart';
import '../recommendation_service.dart';

/// A scoring factor that gives small boosts to recipes that have been cooked less frequently
/// or never cooked, encouraging variety in meal suggestions.
///
/// This factor assigns higher scores to recipes with fewer cooking instances,
/// helping to prevent the same subset of recipes from dominating recommendations.
class VarietyEncouragementFactor implements RecommendationFactor {
  @override
  String get id => 'variety_encouragement';

  @override
  int get defaultWeight => 10; // 10% weight in the total recommendation score

  @override
  Set<String> get requiredData => {'mealCounts'};

  @override
  Future<double> calculateScore(
      Recipe recipe, Map<String, dynamic> context) async {
    // Get meal counts for all recipes
    final Map<String, int> mealCounts =
        context['mealCounts'] as Map<String, int>;

    // Get the number of times this recipe has been cooked
    final cookCount = mealCounts[recipe.id] ?? 0;

    // Never cooked recipes get a perfect score
    if (cookCount == 0) {
      return 100.0;
    }

    // Use a logarithmic scale to reduce the score as cook count increases
    // This creates a curve where:
    // 0 cooks = 100 points
    // 1 cook = 85 points
    // 2 cooks = 77 points
    // 5 cooks = 63 points
    // 10 cooks = 50 points
    // 20 cooks = 37 points
    // 50 cooks = 19 points

    // This formula creates a smooth curve from 100 down to 0
    // with diminishing penalties as cook count increases
    final double baseScore = 100.0 * exp(-0.07 * cookCount);

    // Ensure score is between 0 and 100
    return max(0.0, min(100.0, baseScore));
  }

  /// Calculate a score for the recipe based on how frequently it has been cooked.
  /// This static method can be used outside of the recommendation system.
  static double calculateVarietyScore(Recipe recipe, int cookCount) {
    if (cookCount == 0) {
      return 100.0;
    }

    final double baseScore = 100.0 * exp(-0.07 * cookCount);
    return max(0.0, min(100.0, baseScore));
  }
}
