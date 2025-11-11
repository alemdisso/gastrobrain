// lib/core/services/recommendation_factors/frequency_factor.dart

import 'dart:math';

import '../../../models/recipe.dart';
import '../../../models/frequency_type.dart';
import '../recommendation_service.dart';

/// A scoring factor that prioritizes recipes based on their desired cooking frequency
/// and when they were last cooked.
///
/// This factor assigns higher scores to recipes that are "due" to be cooked
/// based on their frequency preference and last cooked date.
class FrequencyFactor implements RecommendationFactor {
  @override
  String get id => 'frequency';

  @override
  int get defaultWeight => 35; // 35% default weight (reduced from 40%)

  @override
  Set<String> get requiredData => {'lastCooked'};

  // Approximate days between cooking for each frequency type
  static const Map<FrequencyType, int> _frequencyDays = {
    FrequencyType.daily: 1,
    FrequencyType.weekly: 7,
    FrequencyType.biweekly: 14,
    FrequencyType.monthly: 30,
    FrequencyType.bimonthly: 60,
    FrequencyType.rarely: 90,
  };

  @override
  Future<double> calculateScore(
      Recipe recipe, Map<String, dynamic> context) async {
    // NEW: Check if recipe is already planned
    if (context.containsKey('plannedRecipeIds')) {
      final plannedRecipeIds = context['plannedRecipeIds'] as List<String>;
      if (plannedRecipeIds.contains(recipe.id)) {
        // Recipe is already in meal plan - treat as recently cooked
        return 0.0;
      }
    }

    // EXISTING: Get the last cooked date for this recipe
    final Map<String, DateTime?> lastCooked =
        context['lastCooked'] as Map<String, DateTime?>;
    final lastCookedDate = lastCooked[recipe.id];

    // If the recipe has never been cooked, give it a high baseline score
    if (lastCookedDate == null) {
      // New recipes get a high but not perfect score to encourage exploration
      // while still leaving room for recipes that are "due" to be cooked
      return 85.0;
    }

    // Calculate days since the recipe was last cooked
    final now = DateTime.now();
    final daysSinceLastCooked = now.difference(lastCookedDate).inDays;

    // Get the preferred interval for this recipe based on its frequency
    final preferredInterval = _frequencyDays[recipe.desiredFrequency] ?? 30;

    // Calculate how "due" the recipe is as a ratio
    final dueRatio = daysSinceLastCooked / preferredInterval;

    // Calculate the score based on the due ratio, with more granularity for overdue recipes:
    // - For recipes that aren't yet due (dueRatio < 1), scale from 0 to 85
    // - For overdue recipes (dueRatio >= 1), scale from 85 to 100 based on how overdue
    double score;

    if (dueRatio < 1.0) {
      // Not yet due - scale from 0 to 85
      score = dueRatio * 85.0;
    } else {
      // Recipe is overdue - scale from 85 to 100 based on how overdue
      // Use a logarithmic scale to differentiate between slightly and very overdue
      // Cap the effective overdueness at 8x for score calculation
      final overdueness = (dueRatio - 1.0).clamp(0.0, 7.0);

      // Calculate a score between 85-100 based on overdueness
      // Log base 2 of (1 + overdueness) gives a nice curve:
      // 1x overdue → 85 points
      // 2x overdue → ~93 points
      // 4x overdue → ~98 points
      // 8x overdue → 100 points
      final overdueScore = 85.0 + (15.0 * (log(1.0 + overdueness) / log(8.0)));
      score = overdueScore;
    }

    // Apply penalty for recipes cooked very recently relative to their frequency
    // This helps prevent the same recipe from being recommended multiple times in a row
    if (dueRatio < 0.25) {
      // Apply stronger penalty when a recipe was cooked very recently
      // This creates more separation between just-cooked and almost-due recipes
      score = score *
          (0.5 + dueRatio * 2); // Smooth ramp-up from 50% to 100% of score
    }

    return score;
  }

  /// Calculate a score for the recipe based on when it was last cooked
  /// compared to its desired frequency.
  static double calculateDueScore(Recipe recipe, DateTime? lastCookedDate) {
    // If the recipe has never been cooked, give it a high baseline score
    if (lastCookedDate == null) {
      return 85.0;
    }

    // Calculate days since the recipe was last cooked
    final now = DateTime.now();
    final daysSinceLastCooked = now.difference(lastCookedDate).inDays;

    // Get the preferred interval for this recipe based on its frequency
    final preferredInterval = _frequencyDays[recipe.desiredFrequency] ?? 30;

    // Calculate how "due" the recipe is as a ratio
    final dueRatio = daysSinceLastCooked / preferredInterval;

    // Calculate the score based on the due ratio
    double score;

    if (dueRatio < 1.0) {
      // Not yet due - scale from 0 to 85
      score = dueRatio * 85.0;
    } else {
      // Recipe is overdue - scale from 85 to 100 based on how overdue
      final overdueness = (dueRatio - 1.0).clamp(0.0, 7.0);

      // Calculate a score between 85-100 based on overdueness
      final overdueScore = 85.0 + (15.0 * (log(1.0 + overdueness) / log(8.0)));
      score = overdueScore;
    }

    // Apply penalty for recipes cooked very recently
    if (dueRatio < 0.25) {
      score = score * (0.5 + dueRatio * 2);
    }

    return score;
  }
}
