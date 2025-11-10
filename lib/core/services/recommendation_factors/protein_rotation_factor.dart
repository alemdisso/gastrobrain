// lib/core/services/recommendation_factors/protein_rotation_factor.dart

import 'dart:math';
import '../../../models/recipe.dart';
import '../../../models/protein_type.dart';
import '../recommendation_service.dart';

/// A scoring factor that encourages protein variety in meal recommendations.
///
/// This factor assigns lower scores to recipes containing protein types that have
/// been used recently, helping to create more diverse meal plans.
class ProteinRotationFactor implements RecommendationFactor {
  @override
  String get id => 'protein_rotation';

  @override
  int get defaultWeight => 30; // 30% weight in the total recommendation score

  @override
  Set<String> get requiredData => {'proteinTypes', 'recentMeals'};

  // Penalty percentages for proteins used recently (decaying with time)
  static const Map<int, double> _daysPenalty = {
    1: 1.0, // 100% penalty for proteins used 1 day ago
    2: 0.75, // 75% penalty for proteins used 2 days ago
    3: 0.5, // 50% penalty for proteins used 3 days ago
    4: 0.25, // 25% penalty for proteins used 4 days ago
  };

  @override
  Future<double> calculateScore(
      Recipe recipe, Map<String, dynamic> context) async {
    // Get the protein types for this recipe
    final Map<String, Set<ProteinType>> proteinTypesMap =
        context['proteinTypes'] as Map<String, Set<ProteinType>>;

    final recipeProteinTypes = proteinTypesMap[recipe.id] ?? {};

    // If this recipe has no proteins, give it a neutral score
    if (recipeProteinTypes.isEmpty) {
      return 70.0; // Neutral score for non-protein recipes
    }

    // Check if we have any main proteins in this recipe
    final mainProteins =
        recipeProteinTypes.where((p) => p.isMainProtein).toList();

    // If no main proteins, give a high score (non-main proteins don't need rotation)
    if (mainProteins.isEmpty) {
      return 90.0; // Good score for recipes with no main proteins
    }

    // Get recent meals
    final recentMeals = context['recentMeals'] as List<Map<String, dynamic>>;
    if (recentMeals.isEmpty) {
      return 100.0; // No recent meals, so no penalties
    }

    // Map of protein type to days ago it was used
    final Map<ProteinType, int> recentProteinUsage = {};

    // Get today's date for calculating "days ago"
    final today = DateTime.now();

    // Process recent meals to find protein types and their most recent usage
    for (final meal in recentMeals) {
      final cookedAt = meal['cookedAt'] as DateTime;
      final daysAgo = today.difference(cookedAt).inDays;

      // We only care about proteins used in the last 4 days
      if (daysAgo > 4) continue;

      // Get ALL recipes for this meal (primary + secondary)
      final recipes = (meal['recipes'] as List).cast<Recipe>();

      // Process each recipe in the meal
      for (final recipe in recipes) {
        // Look up protein types for this recipe
        final mealProteinTypes = proteinTypesMap[recipe.id] ?? {};

        // Update the most recent usage for each protein type
        for (var proteinType in mealProteinTypes) {
          // Only consider main proteins for rotation
          if (!proteinType.isMainProtein) continue;

          // If this is the most recent usage of this protein, update the map
          if (!recentProteinUsage.containsKey(proteinType) ||
              recentProteinUsage[proteinType]! > daysAgo) {
            recentProteinUsage[proteinType] = daysAgo;
          }
        }
      }
    }

    // Calculate penalty for each main protein in the recipe
    double totalPenalty = 0.0;
    int penaltyCount = 0;

    for (var proteinType in mainProteins) {
      if (recentProteinUsage.containsKey(proteinType)) {
        final daysAgo = recentProteinUsage[proteinType]!;
        if (_daysPenalty.containsKey(daysAgo)) {
          totalPenalty += _daysPenalty[daysAgo]!;
          penaltyCount++;
        }
      }
    }

    // Calculate average penalty (if any penalties were applied)
    final averagePenalty = penaltyCount > 0 ? totalPenalty / penaltyCount : 0.0;

    // Calculate final score:
    // - Start with 100 (perfect score)
    // - Apply penalty by reducing score
    final score = 100.0 - (averagePenalty * 100.0);

    // Ensure score doesn't go below 0
    return max(0.0, score);
  }
}
