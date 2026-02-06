import '../../database/database_helper.dart';
import '../../models/meal_plan.dart';
import '../../models/meal_plan_item.dart';
import '../../models/protein_type.dart';
import '../../models/recipe.dart';
import '../../models/recipe_recommendation.dart';
import '../../models/recommendation_results.dart' as model;
import 'recommendation_service.dart';
import 'meal_plan_analysis_service.dart';

/// Service for managing recommendation caching and context building
///
/// Provides caching, context building, and retrieval of recipe recommendations
/// for meal planning slots. Handles both simple and detailed recommendations.
class RecommendationCacheService {
  final DatabaseHelper _dbHelper;
  final RecommendationService _recommendationService;
  final MealPlanAnalysisService _mealPlanAnalysis;

  // Cache for recommendations to improve performance
  final Map<String, List<Recipe>> _recommendationCache = {};

  RecommendationCacheService(
    this._dbHelper,
    this._recommendationService,
    this._mealPlanAnalysis,
  );

  /// Creates a cache key for a specific meal slot
  String _getRecommendationCacheKey(DateTime date, String mealType) {
    return '${date.toIso8601String()}-$mealType';
  }

  /// Invalidates the cached recommendations for a specific meal slot
  void invalidateSlotCache(DateTime date, String mealType) {
    final cacheKey = _getRecommendationCacheKey(date, mealType);

    // Remove this specific slot from the cache
    if (_recommendationCache.containsKey(cacheKey)) {
      _recommendationCache.remove(cacheKey);
    }
  }

  /// Clears all cached recommendations
  void clearAllCache() {
    _recommendationCache.clear();
  }

  /// Build enhanced context for recipe recommendations using dual-context analysis
  Future<Map<String, dynamic>> buildRecommendationContext({
    required MealPlan? mealPlan,
    DateTime? forDate,
    String? mealType,
  }) async {
    // Get planned context (current meal plan) - handle null case
    final plannedRecipeIds = mealPlan != null
        ? await _mealPlanAnalysis.getPlannedRecipeIds(mealPlan)
        : <String>[];
    final plannedProteins = mealPlan != null
        ? await _mealPlanAnalysis.getPlannedProteinsForWeek(mealPlan)
        : <ProteinType>[];

    // Get recently cooked context (meal history)
    final recentRecipeIds =
        await _mealPlanAnalysis.getRecentlyCookedRecipeIds(dayWindow: 5);
    final recentProteins =
        await _mealPlanAnalysis.getRecentlyCookedProteins(dayWindow: 5);

    // Calculate penalty strategy - handle null meal plan
    final penaltyStrategy = mealPlan != null
        ? await _mealPlanAnalysis.calculateProteinPenaltyStrategy(
            mealPlan,
            forDate ?? DateTime.now(),
            mealType ?? MealPlanItem.lunch,
          )
        : null;

    return {
      'forDate': forDate,
      'mealType': mealType,
      'plannedRecipeIds': plannedRecipeIds,
      'recentlyCookedRecipeIds': recentRecipeIds,
      'plannedProteins': plannedProteins,
      'recentProteins': recentProteins,
      'penaltyStrategy': penaltyStrategy,
      // Backward compatibility
      'excludeIds': plannedRecipeIds,
    };
  }

  /// Returns simple recipes without scores for caching.
  /// For recommendations with scores, use getDetailedSlotRecommendations instead.
  Future<List<Recipe>> getSlotRecommendations({
    required MealPlan? mealPlan,
    required DateTime date,
    required String mealType,
    int count = 5,
  }) async {
    final cacheKey = _getRecommendationCacheKey(date, mealType);

    // Check if we have cached recommendations
    if (_recommendationCache.containsKey(cacheKey)) {
      return _recommendationCache[cacheKey]!;
    }

    // Build context for recommendations
    final context = await buildRecommendationContext(
      mealPlan: mealPlan,
      forDate: date,
      mealType: mealType,
    );

    // Determine if this is a weekday
    final isWeekday = date.weekday >= 1 && date.weekday <= 5;

    // Get recommendations with meal plan integration
    final recommendations = await _recommendationService.getRecommendations(
      count: count,
      excludeIds: context['plannedRecipeIds'] ?? [],
      // Pass meal plan for integrated protein rotation and variety scoring
      mealPlan: mealPlan,
      forDate: date,
      mealType: mealType,
      weekdayMeal: isWeekday,
      maxDifficulty: isWeekday ? 4 : null,
    );

    // Cache the recommendations
    _recommendationCache[cacheKey] = recommendations;

    return recommendations;
  }

  /// Gets detailed recommendations with scores and saves to recommendation history
  ///
  /// Returns a record containing the recommendations and the history ID.
  Future<({List<RecipeRecommendation> recommendations, String historyId})>
      getDetailedSlotRecommendations({
    required MealPlan? mealPlan,
    required DateTime date,
    required String mealType,
    int count = 5,
  }) async {
    // Build context for recommendations
    final context = await buildRecommendationContext(
      mealPlan: mealPlan,
      forDate: date,
      mealType: mealType,
    );

    // Determine if this is a weekday
    final isWeekday = date.weekday >= 1 && date.weekday <= 5;

    // Get detailed recommendations with scores and meal plan integration
    final recommendations =
        await _recommendationService.getDetailedRecommendations(
      count: count,
      excludeIds: context['plannedRecipeIds'] ?? [],
      // Pass meal plan for integrated protein rotation and variety scoring
      mealPlan: mealPlan,
      forDate: date,
      mealType: mealType,
      weekdayMeal: isWeekday,
      maxDifficulty: isWeekday ? 4 : null,
    );

    // Convert service RecommendationResults to model RecommendationResults for database storage
    final modelResults = model.RecommendationResults(
      recommendations: recommendations.recommendations,
      totalEvaluated: recommendations.totalEvaluated,
      queryParameters: recommendations.queryParameters,
      generatedAt: recommendations.generatedAt,
    );

    // Save recommendation history and get the history ID
    final historyId = await _dbHelper.saveRecommendationHistory(
      modelResults,
      'meal_planning',
      targetDate: date,
      mealType: mealType,
    );

    return (
      recommendations: recommendations.recommendations,
      historyId: historyId
    );
  }

  /// Refreshes detailed recommendations for a slot by clearing cache and fetching new ones
  Future<({List<RecipeRecommendation> recommendations, String historyId})>
      refreshDetailedRecommendations({
    required MealPlan? mealPlan,
    required DateTime date,
    required String mealType,
  }) async {
    // Clear the cache for this slot
    invalidateSlotCache(date, mealType);

    // Get fresh detailed recommendations
    return await getDetailedSlotRecommendations(
      mealPlan: mealPlan,
      date: date,
      mealType: mealType,
      count: 8,
    );
  }
}
