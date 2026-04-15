// lib/core/services/recommendation_factors/recipe_proximity_factor.dart

import 'dart:math';

import '../../../models/recipe.dart';
import '../recommendation_service.dart';

/// A scoring factor that penalizes recipes cooked or planned near the
/// recommendation date, independent of protein type or frequency cycle.
///
/// Proximity is always measured as day distance from [forDate] — the date
/// being recommended for — in both directions (past and future).
///
/// ## Signal sources and confidence tiers
///
/// | Source                          | Confidence |
/// |---------------------------------|------------|
/// | Confirmed cooked (recentMeals)  | 1.0        |
/// | Future planned (date >= today)  | 0.7        |
/// | Unconfirmed past, current week  | 0.5        |
/// | Unconfirmed past, older         | 0.0 (ignored) |
///
/// When both confirmed and planned signals exist for the same recipe, the
/// higher-penalty signal is used — never compounded.
///
/// ## Relation to FrequencyFactor
///
/// FrequencyFactor models "is this recipe due relative to its cooking cycle?"
/// This factor models "was this exact recipe cooked or planned very recently?"
/// The crude recency guard that was in FrequencyFactor (dueRatio < 0.25) has
/// been removed in favour of this dedicated factor.
class RecipeProximityFactor implements RecommendationFactor {
  @override
  String get id => 'recipe_proximity';

  @override
  int get defaultWeight => 10;

  @override
  Set<String> get requiredData => {'recentMeals'};

  // Proximity penalty by day distance from the recommendation date.
  // Matches the decay pattern used by ProteinRotationFactor.
  static const Map<int, double> _daysPenalty = {
    1: 1.0,
    2: 0.75,
    3: 0.5,
    4: 0.25,
  };

  static const double _futurePlannedConfidence = 0.7;
  static const double _unconfirmedCurrentWeekConfidence = 0.5;

  @override
  Future<double> calculateScore(
      Recipe recipe, Map<String, dynamic> context) async {
    final forDate = context['forDate'] as DateTime? ?? DateTime.now();
    final referenceDay = DateTime(forDate.year, forDate.month, forDate.day);

    final now = DateTime.now();
    final todayNormalized = DateTime(now.year, now.month, now.day);

    // ─── Signal 1: confirmed cooked meals ───────────────────────────────────
    double confirmedPenalty = 0.0;

    final recentMeals =
        (context['recentMeals'] as List).cast<Map<String, dynamic>>();

    for (final meal in recentMeals) {
      final cookedAt = meal['cookedAt'] as DateTime;
      final cookedDay =
          DateTime(cookedAt.year, cookedAt.month, cookedAt.day);
      final dist = _dayDistance(cookedDay, referenceDay);

      if (dist > 4) continue;

      final recipes = (meal['recipes'] as List).cast<Recipe>();
      if (!recipes.any((r) => r.id == recipe.id)) continue;

      final penalty = _daysPenalty[dist] ?? 0.0;
      confirmedPenalty = max(confirmedPenalty, penalty);
    }

    // ─── Signal 2: planned meals ─────────────────────────────────────────────
    double plannedPenalty = 0.0;

    if (context.containsKey('plannedRecipesByDate')) {
      final plannedRecipesByDate =
          context['plannedRecipesByDate'] as Map<String, DateTime>;
      final plannedDate = plannedRecipesByDate[recipe.id];

      if (plannedDate != null) {
        final plannedDay =
            DateTime(plannedDate.year, plannedDate.month, plannedDate.day);
        final dist = _dayDistance(plannedDay, referenceDay);

        if (dist <= 4 && _daysPenalty.containsKey(dist)) {
          final confidence = _resolveConfidence(
            plannedDay: plannedDay,
            todayNormalized: todayNormalized,
            context: context,
          );

          if (confidence > 0.0) {
            plannedPenalty = _daysPenalty[dist]! * confidence;
          }
        }
      }
    }

    // ─── Take the stronger signal — never compound ────────────────────────
    final penalty = max(confirmedPenalty, plannedPenalty);
    return (100.0 - penalty * 100.0).clamp(0.0, 100.0);
  }

  /// Determine confidence for a planned meal entry.
  double _resolveConfidence({
    required DateTime plannedDay,
    required DateTime todayNormalized,
    required Map<String, dynamic> context,
  }) {
    if (!plannedDay.isBefore(todayNormalized)) {
      // Future planned (today or later) — high confidence
      return _futurePlannedConfidence;
    }

    // Past planned but unconfirmed — check if within the current plan week
    final planWeekStartDate = context['planWeekStartDate'] as DateTime?;
    if (planWeekStartDate != null && !plannedDay.isBefore(planWeekStartDate)) {
      return _unconfirmedCurrentWeekConfidence;
    }

    return 0.0; // Outside current plan week — too uncertain
  }

  static int _dayDistance(DateTime a, DateTime b) {
    return a.difference(b).inDays.abs();
  }
}
