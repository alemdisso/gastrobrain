// lib/core/services/meal_plan_analysis_service.dart

import '../../database/database_helper.dart';
import '../../models/meal_plan.dart';
import '../../models/protein_type.dart';
import '../errors/gastrobrain_exceptions.dart';
import 'localized_error_messages.dart';

/// Service for analyzing meal plan data to provide context for recommendations
///
/// This service extracts both planned and recently cooked meal information
/// to enable dual-context recommendation algorithms.
class MealPlanAnalysisService {
  final DatabaseHelper _dbHelper;

  MealPlanAnalysisService(this._dbHelper);

  // =============================================================================
  // PLANNED MEALS CONTEXT (from MealPlanItemRecipe junction table)
  // =============================================================================
  /// Get all recipe IDs that are planned in the current meal plan
  Future<List<String>> getPlannedRecipeIds(MealPlan? mealPlan) async {
    assert(mealPlan != null, 'MealPlan cannot be null');
    if (mealPlan!.items.isEmpty) {
      return [];
    }

    final Set<String> recipeIds = {};

    for (final item in mealPlan.items) {
      if (item.mealPlanItemRecipes != null) {
        for (final mealRecipe in item.mealPlanItemRecipes!) {
          recipeIds.add(mealRecipe.recipeId);
        }
      }
    }

    return recipeIds.toList();
  }

  /// Get all protein types that are planned for the week
  Future<List<ProteinType>> getPlannedProteinsForWeek(
      MealPlan? mealPlan) async {
    assert(mealPlan != null, 'MealPlan cannot be null');
    if (mealPlan!.items.isEmpty) {
      return [];
    }

    final plannedRecipeIds = await getPlannedRecipeIds(mealPlan);
    if (plannedRecipeIds.isEmpty) {
      return [];
    }

    return await _getProteinTypesForRecipes(plannedRecipeIds);
  }

  /// Get planned proteins organized by date
  Future<Map<DateTime, List<ProteinType>>> getPlannedProteinsByDate(
      MealPlan? mealPlan) async {
    final Map<DateTime, List<ProteinType>> result = {};

    if (mealPlan == null || mealPlan.items.isEmpty) {
      return result;
    }

    // Group items by date
    final Map<DateTime, List<String>> recipesByDate = {};

    for (final item in mealPlan.items) {
      final date = DateTime.parse(item.plannedDate);
      final normalizedDate = DateTime(date.year, date.month, date.day);

      if (item.mealPlanItemRecipes != null) {
        recipesByDate[normalizedDate] ??= [];
        for (final mealRecipe in item.mealPlanItemRecipes!) {
          recipesByDate[normalizedDate]!.add(mealRecipe.recipeId);
        }
      }
    }

    // Get protein types for each date
    for (final entry in recipesByDate.entries) {
      final proteins = await _getProteinTypesForRecipes(entry.value);
      result[entry.key] = proteins;
    }

    return result;
  }

  // =============================================================================
  // RECENTLY COOKED CONTEXT (from MealRecipe junction table)
  // =============================================================================
  /// Get recipe IDs that were cooked recently
  Future<List<String>> getRecentlyCookedRecipeIds({
    int dayWindow = 7,
    DateTime? referenceDate,
  }) async {
    try {
      final now = referenceDate ?? DateTime.now();
      final cutoffDate = now.subtract(Duration(days: dayWindow));
      final recentMeals = await _dbHelper.getRecentMeals(limit: 100);

      final Set<String> recipeIds = {};

      for (final meal in recentMeals) {
        // Only include meals within the day window (inclusive of cutoff date)
        if (meal.cookedAt.isAfter(cutoffDate) || meal.cookedAt.isAtSameMomentAs(cutoffDate)) {
          // Get recipes from junction table
          final mealRecipes = await _dbHelper.getMealRecipesForMeal(meal.id);
          for (final mealRecipe in mealRecipes) {
            recipeIds.add(mealRecipe.recipeId);
          }

          // Also include direct recipe reference (backward compatibility)
          if (meal.recipeId != null) {
            recipeIds.add(meal.recipeId!);
          }
        }
      }
      return recipeIds.toList();
    } catch (e) {
      throw GastrobrainException(
          '${LocalizedErrorMessages.getMessage('errorGettingRecentlyCookedRecipeIds')}: ${e.toString()}');
    }
  }

  /// Get protein types that were cooked recently
  Future<List<ProteinType>> getRecentlyCookedProteins({
    int dayWindow = 7,
    DateTime? referenceDate,
  }) async {
    final recentRecipeIds = await getRecentlyCookedRecipeIds(
      dayWindow: dayWindow,
      referenceDate: referenceDate,
    );
    if (recentRecipeIds.isEmpty) {
      return [];
    }

    return await _getProteinTypesForRecipes(recentRecipeIds);
  }

  /// Get recently cooked proteins organized by date
  Future<Map<DateTime, List<ProteinType>>> getRecentlyCookedProteinsByDate({
    int dayWindow = 7,
    DateTime? referenceDate,
  }) async {
    final Map<DateTime, List<ProteinType>> result = {};

    try {
      final reference = referenceDate ?? DateTime.now();
      final cutoffDate = reference.subtract(Duration(days: dayWindow));
      final recentMeals = await _dbHelper.getRecentMeals(limit: 100);

      // Group meals by date
      final Map<DateTime, List<String>> recipesByDate = {};

      for (final meal in recentMeals) {
        if (meal.cookedAt.isAfter(cutoffDate) || meal.cookedAt.isAtSameMomentAs(cutoffDate)) {
          final date = DateTime(
            meal.cookedAt.year,
            meal.cookedAt.month,
            meal.cookedAt.day,
          );

          recipesByDate[date] ??= [];

          // Get recipes from junction table
          final mealRecipes = await _dbHelper.getMealRecipesForMeal(meal.id);
          for (final mealRecipe in mealRecipes) {
            recipesByDate[date]!.add(mealRecipe.recipeId);
          }

          // Also include direct recipe reference (backward compatibility)
          if (meal.recipeId != null) {
            recipesByDate[date]!.add(meal.recipeId!);
          }
        }
      }

      // Get protein types for each date
      for (final entry in recipesByDate.entries) {
        final proteins = await _getProteinTypesForRecipes(entry.value);
        result[entry.key] = proteins;
      }

      return result;
    } catch (e) {
      throw GastrobrainException(
          '${LocalizedErrorMessages.getMessage('errorGettingRecentlyCookedProteinsByDate')}: ${e.toString()}');
    }
  }

  // =============================================================================
  // COMBINED ANALYSIS
  // =============================================================================
  /// Calculate protein penalty strategy based on both planned and cooked context
  Future<ProteinPenaltyStrategy> calculateProteinPenaltyStrategy(
    MealPlan? currentPlan,
    DateTime targetDate,
    String mealType,
  ) async {
    try {
      // Get planned proteins with dates
      final plannedProteinsByDate = await getPlannedProteinsByDate(
          currentPlan); // Get recently cooked proteins with dates
      final recentProteinsByDate = await getRecentlyCookedProteinsByDate(
          dayWindow: 7, referenceDate: targetDate);

      final penalties = <ProteinType, double>{};

      // Analyze each main protein type
      for (final protein in ProteinType.values.where((p) => p.isMainProtein)) {
        double penalty = 0.0;

        // Check if protein is planned this week
        final isPlannedThisWeek = plannedProteinsByDate.values
            .any((proteins) => proteins.contains(protein));

        if (isPlannedThisWeek) {
          penalty += 0.6; // Moderate penalty for proteins already planned
        }

        // Check recent cooking and apply graduated penalty based on recency
        final daysSinceLastCooked =
            _getDaysSinceLastCooked(protein, recentProteinsByDate, targetDate);

        if (daysSinceLastCooked != null) {
          final recencyPenalty = _calculateRecencyPenalty(daysSinceLastCooked);
          penalty += recencyPenalty;
        }

        // Clamp penalty to valid range
        penalties[protein] = penalty.clamp(0.0, 1.0);
      }

      return ProteinPenaltyStrategy(penalties: penalties);
    } catch (e) {
      throw GastrobrainException(
          '${LocalizedErrorMessages.getMessage('errorCalculatingProteinPenaltyStrategy')}: ${e.toString()}');
    }
  }

  /// Calculate penalty based on how recently a protein was cooked
  double _calculateRecencyPenalty(int daysSince) {
    if (daysSince <= 1) return 0.8; // 1 day ago: high penalty
    if (daysSince <= 2) return 0.6; // 2 days ago: high penalty
    if (daysSince <= 3) return 0.4; // 3 days ago: moderate penalty
    if (daysSince <= 4) return 0.25; // 4 days ago: light penalty
    if (daysSince <= 6) return 0.1; // 5-6 days ago: very light penalty
    return 0.0; // 7+ days ago: no penalty
  }

  /// Get days since a protein was last cooked, returns null if never cooked recently
  int? _getDaysSinceLastCooked(
      ProteinType protein,
      Map<DateTime, List<ProteinType>> recentProteinsByDate,
      DateTime referenceDate) {
    final today =
        DateTime(referenceDate.year, referenceDate.month, referenceDate.day);

    // Find most recent date this protein was cooked
    DateTime? mostRecentDate;

    for (final entry in recentProteinsByDate.entries) {
      if (entry.value.contains(protein)) {
        if (mostRecentDate == null || entry.key.isAfter(mostRecentDate)) {
          mostRecentDate = entry.key;
        }
      }
    }

    if (mostRecentDate == null) return null;

    return today.difference(mostRecentDate).inDays;
  }

  // =============================================================================
  // PRIVATE HELPER METHODS
  // =============================================================================

  /// Get protein types for a list of recipe IDs
  Future<List<ProteinType>> _getProteinTypesForRecipes(
      List<String> recipeIds) async {
    if (recipeIds.isEmpty) {
      return [];
    }

    final Set<ProteinType> proteinTypes = {};

    try {
      for (final recipeId in recipeIds) {
        final ingredientMaps = await _dbHelper.getRecipeIngredients(recipeId);

        for (final ingredientMap in ingredientMaps) {
          final proteinTypeStr = ingredientMap['protein_type'] as String?;

          if (proteinTypeStr != null) {
            try {
              final proteinType = ProteinType.values.firstWhere(
                (type) => type.name == proteinTypeStr,
              );
              proteinTypes.add(proteinType);
            } catch (e) {
              // Skip unknown protein types
              continue;
            }
          }
        }
      }

      return proteinTypes.toList();
    } catch (e) {
      throw GastrobrainException(
          '${LocalizedErrorMessages.getMessage('errorGettingProteinTypesForRecipes')}: ${e.toString()}');
    }
  }
}

/// Strategy for applying graduated penalties to protein types in recommendations
///
/// Uses penalty scores (0.0 to 1.0) instead of binary exclusion:
/// - 0.0 = no penalty (full score)
/// - 0.5 = moderate penalty (50% of original score)
/// - 1.0 = maximum penalty (0% of original score, effectively excluded)
class ProteinPenaltyStrategy {
  final Map<ProteinType, double> penalties;

  const ProteinPenaltyStrategy({required this.penalties});

  /// Get penalty for a specific protein type (0.0 if not found)
  double getPenalty(ProteinType protein) => penalties[protein] ?? 0.0;

  /// Get all protein types that have any penalty
  List<ProteinType> get penalizedProteins =>
      penalties.entries.where((e) => e.value > 0.0).map((e) => e.key).toList();

  /// Get proteins with high penalties (>= 0.7)
  List<ProteinType> get highPenaltyProteins =>
      penalties.entries.where((e) => e.value >= 0.7).map((e) => e.key).toList();

  /// Get proteins with moderate penalties (0.3 - 0.69)
  List<ProteinType> get moderatePenaltyProteins => penalties.entries
      .where((e) => e.value >= 0.3 && e.value < 0.7)
      .map((e) => e.key)
      .toList();

  /// Get proteins with light penalties (0.01 - 0.29)
  List<ProteinType> get lightPenaltyProteins => penalties.entries
      .where((e) => e.value > 0.0 && e.value < 0.3)
      .map((e) => e.key)
      .toList();

  /// Apply penalty to a base score
  double applyPenalty(ProteinType protein, double baseScore) {
    final penalty = getPenalty(protein);
    return baseScore * (1.0 - penalty);
  }

  @override
  String toString() {
    final highPenalties =
        penalties.entries.where((e) => e.value >= 0.7).toList();
    final modPenalties = penalties.entries
        .where((e) => e.value >= 0.3 && e.value < 0.7)
        .toList();
    final lightPenalties =
        penalties.entries.where((e) => e.value > 0.0 && e.value < 0.3).toList();

    return 'ProteinPenaltyStrategy('
        'high: $highPenalties, '
        'moderate: $modPenalties, '
        'light: $lightPenalties)';
  }
}
