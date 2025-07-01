// lib/core/services/recommendation_service.dart

import 'dart:math';

import '../../database/database_helper.dart';
import '../../models/recipe.dart';
import '../../models/protein_type.dart';
import '../../models/frequency_type.dart';
import '../../models/recipe_recommendation.dart';
import '../errors/gastrobrain_exceptions.dart';
import 'localized_error_messages.dart';
import 'recommendation_database_queries.dart';
import 'recommendation_factors/frequency_factor.dart';
import 'recommendation_factors/protein_rotation_factor.dart';
import 'recommendation_factors/rating_factor.dart';
import 'recommendation_factors/difficulty_factor.dart';
import 'recommendation_factors/variety_encouragement_factor.dart';
import 'recommendation_factors/randomization_factor.dart';
import 'recommendation_factors/user_feedback_factor.dart';

/// Results container for recommendation queries
/// ## Performance Notes
///
/// **Temporal Context Impact:**
/// - Date calculations: O(1) operations using DateTime.weekday
/// - Weight profile switching: Creates temporary map copy (~100 bytes)
/// - No additional database queries required
/// - Recommendation caching remains effective per day type
///
/// **Memory Usage:**
/// - Temporary weight map: ~6 integers (48 bytes)
/// - Context map additions: ~3 entries (negligible)
/// - Total overhead: <100 bytes per recommendation request
///
/// **Caching Compatibility:**
/// Temporal recommendations can be safely cached using cache keys that include
/// the day type (weekday/weekend) to avoid serving weekend recommendations
/// on weekdays and vice versa.
class RecommendationResults {
  /// The list of recipe recommendations, sorted by score
  final List<RecipeRecommendation> recommendations;

  /// The total number of recipes that were evaluated
  final int totalEvaluated;

  /// The query parameters that were used to generate these recommendations
  final Map<String, dynamic> queryParameters;

  /// Timestamp of when the recommendations were generated
  final DateTime generatedAt;

  RecommendationResults({
    required this.recommendations,
    required this.totalEvaluated,
    required this.queryParameters,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();
}

/// Abstract class for scoring factors
abstract class RecommendationFactor {
  /// Unique identifier for this factor
  String get id;

  /// Default weight of this factor (for backward compatibility)
  int get defaultWeight => 0;

  /// Calculate a score (0-100) for this recipe based on the factor's criteria
  Future<double> calculateScore(Recipe recipe, Map<String, dynamic> context);

  /// Describe what data this factor needs from the database
  Set<String> get requiredData;
}

/// Service for generating recipe recommendations based on various factors
///
/// ## Temporal Behavior
/// The service automatically adapts recommendations based on day of week:
///
/// **Weekdays (Monday-Friday):**
/// - Emphasize simplicity and reliability (difficulty weight: 20%)
/// - Reduce experimentation (rating weight: 10%, variety: 10%)
/// - Favor tested, quick recipes for busy schedules
///
/// **Weekends (Saturday-Sunday):**
/// - Allow complexity (difficulty weight: 5%)
/// - Encourage favorites and experimentation (rating: 20%, variety: 15%)
/// - Support longer cooking projects and social meals
///
/// This behavior is controlled by the `weekdayMeal` parameter and implemented
/// through dynamic weight profile switching, not individual factor modifications.
/// The temporal context is also added to the recommendation context map for
/// future factor extensions.
///
/// ## Weight Profile System
/// Temporal behavior uses temporary weight profiles that:
/// 1. Save current weights before recommendation generation
/// 2. Apply temporal profile (weekday/weekend)
/// 3. Generate recommendations with adjusted weights
/// 4. Restore original weights afterward
///
/// This ensures no permanent state changes while enabling temporal adaptation.
class RecommendationService {
  final RecommendationDatabaseQueries _dbQueries;
  final Random _random = Random();
  Map<String, dynamic>? overrideTestContext;

  /// Map of registered recommendation factors
  final Map<String, RecommendationFactor> _factors = {};

  /// Map of weights for registered factors
  final Map<String, int> _factorWeights = {};

  /// Default constructor with DatabaseHelper injection
  RecommendationService({
    required DatabaseHelper dbHelper,
    bool registerDefaultFactors = false,
    Map<String, List<ProteinType>>? proteinTypesOverride,
  }) : _dbQueries = RecommendationDatabaseQueries(
          dbHelper: dbHelper,
          proteinTypesOverride: proteinTypesOverride,
        ) {
    if (registerDefaultFactors) {
      registerStandardFactors();
    }
  }

  /// Register all standard recommendation factors with their default weights
  void registerStandardFactors() {
    // Register factors with their default weights
    registerFactor(FrequencyFactor());
    registerFactor(ProteinRotationFactor());
    registerFactor(RatingFactor());
    registerFactor(VarietyEncouragementFactor());
    registerFactor(DifficultyFactor());
    registerFactor(RandomizationFactor());
    registerFactor(UserFeedbackFactor());

    // Ensure weights are normalized to sum to 100
    _normalizeWeights();
  }

  /// Register a scoring factor
  void registerFactor(RecommendationFactor factor, {int? weight}) {
    _factors[factor.id] = factor;
    _factorWeights[factor.id] = weight ?? factor.defaultWeight;
    _normalizeWeights(); // Ensure weights sum to 100
  }

  /// Unregister a scoring factor
  void unregisterFactor(String factorId) {
    _factors.remove(factorId);
  }

  /// Get all registered factors
  List<RecommendationFactor> get factors => _factors.values.toList();

  /// Set weight for an already registered factor
  void setFactorWeight(String factorId, int weight) {
    if (!_factors.containsKey(factorId)) {
      throw NotFoundException(LocalizedErrorMessages.factorNotFound(factorId));
    }
    _factorWeights[factorId] = weight;
    _normalizeWeights();
  }

  /// Get current weight for a factor
  int getFactorWeight(String factorId) {
    return _factorWeights[factorId] ?? 0;
  }

  /// Normalize weights to ensure they sum to 100
  void _normalizeWeights() {
    final totalWeight =
        _factorWeights.values.fold(0, (sum, weight) => sum + weight);

    // If sum is 0, set equal weights
    if (totalWeight == 0 && _factorWeights.isNotEmpty) {
      final equalWeight = 100 ~/ _factorWeights.length;
      _factorWeights.updateAll((key, value) => equalWeight);

      // Distribute any remaining weight to avoid rounding errors
      int remaining = 100 - _factorWeights.values.fold(0, (sum, w) => sum + w);
      if (remaining > 0 && _factorWeights.isNotEmpty) {
        final firstKey = _factorWeights.keys.first;
        _factorWeights[firstKey] = _factorWeights[firstKey]! + remaining;
      }
      return;
    }

    // If sum is not 100 and not 0, normalize
    if (totalWeight != 100 && totalWeight > 0) {
      // First pass: Calculate normalized weights
      final Map<String, int> normalizedWeights = {};
      _factorWeights.forEach((key, value) {
        normalizedWeights[key] = (value * 100 ~/ totalWeight);
      });

      // Calculate the total after normalization
      final normalizedTotal =
          normalizedWeights.values.fold(0, (sum, w) => sum + w);

      // Distribute any remaining weight to avoid rounding errors
      int remaining = 100 - normalizedTotal;

      // Update the weights
      _factorWeights.clear();
      _factorWeights.addAll(normalizedWeights);

      // Distribute the remaining weight to the factors proportionally
      if (remaining > 0 && _factorWeights.isNotEmpty) {
        // Sort factors by their original weight (descending) to distribute remaining weight
        final sortedKeys = _factorWeights.keys.toList()
          ..sort((a, b) => _factorWeights[b]!.compareTo(_factorWeights[a]!));

        // Distribute remaining weight to the highest weighted factors
        for (int i = 0; i < remaining && i < sortedKeys.length; i++) {
          _factorWeights[sortedKeys[i]] = _factorWeights[sortedKeys[i]]! + 1;
        }
      }
    }
  }

  /// Get the total weight of all registered factors
  int get totalWeight =>
      _factorWeights.values.fold(0, (sum, weight) => sum + weight);

  /// Main method to get recipe recommendations
  ///
  ////// The recommendation system automatically applies temporal context
  /// when [forDate] is provided:
  /// - **Weekdays (Mon-Fri)**: Favor simpler, quicker recipes through increased
  ///   difficulty factor weight (20% vs 5%), reduced experimentation emphasis
  /// - **Weekends (Sat-Sun)**: Allow complex recipes, emphasize favorites through
  ///   increased rating factor weight (20% vs 10%), encourage variety
  ///
  /// Temporal adaptation is achieved through different factor weight profiles that
  /// adjust the relative importance of difficulty, rating, and variety factors.
  /// The [weekdayMeal] parameter controls this behavior.
  /// Parameters:
  /// - [count]: Number of recipes to recommend
  /// - [excludeIds]: Recipe IDs to exclude from recommendations
  /// - [avoidProteinTypes]: Protein types to avoid or downrank
  /// - [weekdayMeal]: When true, applies weekday profile favoring simplicity.
  ///   When false, applies weekend profile allowing complexity. When null, uses
  ///   default weights without temporal adjustment.
  /// - [forDate]: Used for temporal context and passed to factors that may need
  ///   day-specific logic in future versions.
  /// - [mealType]: Meal type ('lunch' or 'dinner')
  ///
  /// Returns a list of recommended recipes sorted by score
  Future<List<Recipe>> getRecommendations({
    int count = 5,
    List<String> excludeIds = const [],
    List<ProteinType>? avoidProteinTypes,
    List<ProteinType>? requiredProteinTypes,
    DateTime? forDate,
    String? mealType,
    int? maxDifficulty,
    FrequencyType? preferredFrequency,
    bool? weekdayMeal,
  }) async {
    try {
      // Validate inputs
      if (count <= 0) {
        throw ValidationException(LocalizedErrorMessages.getMessage('recommendationCountMustBePositive'));
      }

      if (_factors.isEmpty) {
        throw GastrobrainException(
            LocalizedErrorMessages.getMessage('noRecommendationFactorsRegistered'));
      }

      // Build context data needed by factors
      final context = await _buildContext(
        excludeIds: excludeIds,
        avoidProteinTypes: avoidProteinTypes,
        requiredProteinTypes: requiredProteinTypes,
        forDate: forDate,
        mealType: mealType,
        maxDifficulty: maxDifficulty,
        preferredFrequency: preferredFrequency,
        weekdayMeal: weekdayMeal,
      );

      // Get candidate recipes with filtering applied
      final recipes = await _getCandidateRecipes(
        excludeIds,
        requiredProteinTypes: requiredProteinTypes,
        avoidProteinTypes: avoidProteinTypes,
        maxDifficulty: maxDifficulty,
        preferredFrequency: preferredFrequency,
      );

      if (recipes.isEmpty) {
        return [];
      }

      // Apply weekday/weekend profile if specified
      if (weekdayMeal != null) {
        // Don't modify original weights, just apply a temporary profile
        final originalWeights = Map<String, int>.from(_factorWeights);
        try {
          if (weekdayMeal) {
            _setWeekdayProfile();
          } else {
            _setWeekendProfile();
          }

          // Calculate scores for each recipe using all factors
          final scoredRecipes = await _scoreRecipes(recipes, context);

          // Sort by total score (descending) and return top [count]
          scoredRecipes.sort((a, b) => b.totalScore.compareTo(a.totalScore));

          // Return just the recipes (not the full recommendation objects)
          return scoredRecipes
              .take(count)
              .map((recommendation) => recommendation.recipe)
              .toList();
        } finally {
          // Restore original weights
          _factorWeights.clear();
          _factorWeights.addAll(originalWeights);
        }
      } else {
        // Calculate scores for each recipe using all factors with current weights
        final scoredRecipes = await _scoreRecipes(recipes, context);

        // Sort by total score (descending) and return top [count]
        scoredRecipes.sort((a, b) => b.totalScore.compareTo(a.totalScore));

        // Return just the recipes (not the full recommendation objects)
        return scoredRecipes
            .take(count)
            .map((recommendation) => recommendation.recipe)
            .toList();
      }
    } on ValidationException {
      rethrow;
    } on NotFoundException {
      rethrow;
    } catch (e) {
      throw GastrobrainException(
          '${LocalizedErrorMessages.getMessage('errorGeneratingRecommendations')}: ${e.toString()}');
    }
  }

  bool _isWeekday(DateTime date) {
    return date.weekday >= DateTime.monday && date.weekday <= DateTime.friday;
  }

  /// Get detailed recommendation results including scores and metadata
  Future<RecommendationResults> getDetailedRecommendations({
    int count = 5,
    List<String> excludeIds = const [],
    List<ProteinType>? avoidProteinTypes,
    List<ProteinType>? requiredProteinTypes,
    DateTime? forDate,
    String? mealType,
    int? maxDifficulty,
    FrequencyType? preferredFrequency,
    bool? weekdayMeal,
  }) async {
    try {
      // Validate inputs
      if (count <= 0) {
        throw ValidationException(LocalizedErrorMessages.getMessage('recommendationCountMustBePositive'));
      }

      if (_factors.isEmpty) {
        throw GastrobrainException(
            LocalizedErrorMessages.getMessage('noRecommendationFactorsRegistered'));
      }

      // Build context data needed by factors
      final context = await _buildContext(
        excludeIds: excludeIds,
        avoidProteinTypes: avoidProteinTypes,
        requiredProteinTypes: requiredProteinTypes,
        forDate: forDate,
        mealType: mealType,
        maxDifficulty: maxDifficulty,
        preferredFrequency: preferredFrequency,
        weekdayMeal: weekdayMeal,
      );

      // Get candidate recipes with filtering applied
      final recipes = await _getCandidateRecipes(
        excludeIds,
        requiredProteinTypes: requiredProteinTypes,
        avoidProteinTypes: avoidProteinTypes,
        maxDifficulty: maxDifficulty,
        preferredFrequency: preferredFrequency,
      );

      // Create query parameters for result metadata
      final queryParameters = {
        'count': count,
        'excludeIds': excludeIds,
        'avoidProteinTypes': avoidProteinTypes?.map((p) => p.name).toList(),
        'requiredProteinTypes':
            requiredProteinTypes?.map((p) => p.name).toList(),
        'forDate': forDate?.toIso8601String(),
        'mealType': mealType,
        'maxDifficulty': maxDifficulty,
        'preferredFrequency': preferredFrequency?.value,
        'weekdayMeal': weekdayMeal,
      };

      if (recipes.isEmpty) {
        return RecommendationResults(
          recommendations: [],
          totalEvaluated: 0,
          queryParameters: queryParameters,
        );
      }

      // Apply weekday/weekend profile if specified
      if (weekdayMeal != null) {
        // Don't modify original weights, just apply a temporary profile
        final originalWeights = Map<String, int>.from(_factorWeights);
        try {
          if (weekdayMeal) {
            _setWeekdayProfile();
          } else {
            _setWeekendProfile();
          }

          // Calculate scores for each recipe using all factors
          final scoredRecipes = await _scoreRecipes(recipes, context);

          // Sort by total score (descending)
          scoredRecipes.sort((a, b) => b.totalScore.compareTo(a.totalScore));

          return RecommendationResults(
            recommendations: scoredRecipes.take(count).toList(),
            totalEvaluated: recipes.length,
            queryParameters: queryParameters,
          );
        } finally {
          // Restore original weights
          _factorWeights.clear();
          _factorWeights.addAll(originalWeights);
        }
      } else {
        // Calculate scores for each recipe using all factors with current weights
        final scoredRecipes = await _scoreRecipes(recipes, context);

        // Sort by total score (descending)
        scoredRecipes.sort((a, b) => b.totalScore.compareTo(a.totalScore));

        return RecommendationResults(
          recommendations: scoredRecipes.take(count).toList(),
          totalEvaluated: recipes.length,
          queryParameters: queryParameters,
        );
      }
    } on ValidationException {
      rethrow;
    } on NotFoundException {
      rethrow;
    } catch (e) {
      throw GastrobrainException(
          '${LocalizedErrorMessages.getMessage('errorGeneratingDetailedRecommendations')}: ${e.toString()}');
    }
  }

  /// Build context data needed by scoring factors
  Future<Map<String, dynamic>> _buildContext({
    required List<String> excludeIds,
    List<ProteinType>? avoidProteinTypes,
    List<ProteinType>? requiredProteinTypes,
    DateTime? forDate,
    String? mealType,
    int? maxDifficulty,
    FrequencyType? preferredFrequency,
    bool? weekdayMeal,
  }) async {
    // For testing, override the context if provided
    if (overrideTestContext != null) {
      final testContext = Map<String, dynamic>.from(overrideTestContext!);
      // Add standard context values that tests might not provide
      testContext['excludeIds'] = excludeIds;
      testContext['avoidProteinTypes'] = avoidProteinTypes;
      testContext['requiredProteinTypes'] = requiredProteinTypes;
      testContext['forDate'] = forDate;
      testContext['mealType'] = mealType;
      testContext['maxDifficulty'] = maxDifficulty;
      testContext['preferredFrequency'] = preferredFrequency;
      testContext['weekdayMeal'] = weekdayMeal;
      if (!testContext.containsKey('randomSeed')) {
        testContext['randomSeed'] = _random.nextInt(1000);
      }
      return testContext;
    }

    // Collect required data from all registered factors
    final requiredData =
        _factors.values.expand((factor) => factor.requiredData).toSet();

    final context = <String, dynamic>{
      'excludeIds': excludeIds,
      'avoidProteinTypes': avoidProteinTypes,
      'requiredProteinTypes': requiredProteinTypes,
      'forDate': forDate,
      'mealType': mealType,
      'maxDifficulty': maxDifficulty,
      'preferredFrequency': preferredFrequency,
      'weekdayMeal': weekdayMeal,
      'randomSeed': _random.nextInt(1000), // For reproducible randomness
    };

    // Add temporal context when date is provided
    if (forDate != null) {
      final isWeekday = _isWeekday(forDate);
      context['dayType'] = isWeekday ? 'weekday' : 'weekend';
      context['isWeekday'] = isWeekday;
    }

    // Load meal history data if required
    if (requiredData.contains('mealCounts')) {
      context['mealCounts'] = await _dbQueries.getMealCounts();
    }

    // Load last cooked dates if required
    if (requiredData.contains('lastCooked')) {
      context['lastCooked'] = await _dbQueries.getLastCookedDates();
    }

    // Load protein types if required
    final needsProteinInfo = requiredData.contains('proteinTypes') ||
        avoidProteinTypes != null ||
        requiredProteinTypes != null;

    if (needsProteinInfo) {
      // Get recipes first to get their IDs
      final recipes =
          await _dbQueries.getCandidateRecipes(excludeIds: excludeIds);
      final recipeIds = recipes.map((r) => r.id).toList();

      context['proteinTypes'] =
          await _dbQueries.getRecipeProteinTypes(recipeIds: recipeIds);
    }

    // If needed, get detailed recipe stats in a single optimized query
    final needsDetailedStats = requiredData.contains('lastCooked') &&
        requiredData.contains('mealCounts') &&
        requiredData.contains('proteinTypes');

    if (needsDetailedStats) {
      final recipeStats = await _dbQueries.getRecipesWithStats(
          excludeIds: excludeIds, includeProteinInfo: true);

      context['recipeStats'] = recipeStats;
    }

    // For more advanced recommendations, load recent meals for context
    if (requiredData.contains('recentMeals')) {
      final recentMeals = await _dbQueries.getRecentMeals(
          startDate: DateTime.now().subtract(const Duration(days: 14)),
          limit: 20);

      context['recentMeals'] = recentMeals;
    }

    // Load feedback history if required
    if (requiredData.contains('feedbackHistory')) {
      // Get candidate recipes to determine which ones need feedback history
      final recipes = await _getCandidateRecipes(
        excludeIds,
        requiredProteinTypes: requiredProteinTypes,
        avoidProteinTypes: avoidProteinTypes,
        maxDifficulty: maxDifficulty,
        preferredFrequency: preferredFrequency,
      );
      final recipeIds = recipes.map((r) => r.id).toList();

      context['feedbackHistory'] = await UserFeedbackFactor.getFeedbackHistory(
        _dbQueries.dbHelper,
        recipeIds: recipeIds,
        lookbackDays: 365,
      );
    }

    return context;
  }

  /// Get candidate recipes that meet basic filtering criteria
  Future<List<Recipe>> _getCandidateRecipes(
    List<String> excludeIds, {
    List<ProteinType>? requiredProteinTypes,
    List<ProteinType>? avoidProteinTypes,
    int? maxDifficulty,
    FrequencyType? preferredFrequency,
  }) async {
    // Get candidate recipes with basic exclusions
    List<Recipe> candidates = await _dbQueries.getCandidateRecipes(
      excludeIds: excludeIds,
      requiredProteinTypes: requiredProteinTypes,
      excludedProteinTypes: avoidProteinTypes,
    );

    // Apply additional filtering
    if (maxDifficulty != null || preferredFrequency != null) {
      candidates = candidates.where((recipe) {
        // Apply difficulty filter if specified
        if (maxDifficulty != null && recipe.difficulty > maxDifficulty) {
          return false;
        }

        // Apply frequency filter if specified
        if (preferredFrequency != null &&
            recipe.desiredFrequency != preferredFrequency) {
          return false;
        }

        return true;
      }).toList();
    }

    return candidates;
  }

  /// Score recipes using all registered factors
  Future<List<RecipeRecommendation>> _scoreRecipes(
    List<Recipe> recipes,
    Map<String, dynamic> context,
  ) async {
    final recommendations = <RecipeRecommendation>[];

    // Calculate total weight from the weight map
    final factorTotal = totalWeight;
    final effectiveTotal = factorTotal > 0 ? factorTotal : 100;

    for (final recipe in recipes) {
      final factorScores = <String, double>{};
      double weightedTotal = 0;

      // Calculate score for each factor
      for (final factor in _factors.values) {
        final score = await factor.calculateScore(recipe, context);
        factorScores[factor.id] = score;

        // Apply factor weight from the weight map
        final weight = _factorWeights[factor.id] ?? 0;
        weightedTotal += (score * weight / effectiveTotal);
      }

      // Create recommendation with total score and factor breakdown
      recommendations.add(RecipeRecommendation(
        recipe: recipe,
        totalScore: weightedTotal,
        factorScores: factorScores,
        // Include weight information in metadata for transparency
        metadata: {'factorWeights': Map<String, int>.from(_factorWeights)},
      ));
    }

    return recommendations;
  }

  /// Apply a predefined weight profile
  void applyWeightProfile(String profileName) {
    switch (profileName.toLowerCase()) {
      case 'balanced':
        _setBalancedProfile();
        break;
      case 'frequency-focused':
        _setFrequencyFocusedProfile();
        break;
      case 'variety-focused':
        _setVarietyFocusedProfile();
        break;
      case 'weekday':
        _setWeekdayProfile();
        break;
      case 'weekend':
        _setWeekendProfile();
        break;
      default:
        throw ValidationException(LocalizedErrorMessages.unknownWeightProfile(profileName));
    }
  }

  /// Set a balanced recommendation profile
  void _setBalancedProfile() {
    _factorWeights['frequency'] = 30;
    _factorWeights['protein_rotation'] = 20;
    _factorWeights['rating'] = 10;
    _factorWeights['variety_encouragement'] = 15;
    _factorWeights['difficulty'] = 10;
    _factorWeights['randomization'] = 5;
    _factorWeights['user_feedback'] = 10;
    _normalizeWeights();
  }

  /// Set a frequency-focused profile (emphasizes cooking recipes at their desired interval)
  void _setFrequencyFocusedProfile() {
    _factorWeights['frequency'] = 45;
    _factorWeights['protein_rotation'] = 20;
    _factorWeights['rating'] = 10;
    _factorWeights['variety_encouragement'] = 10;
    _factorWeights['difficulty'] = 5;
    _factorWeights['randomization'] = 5;
    _factorWeights['user_feedback'] = 5;
    _normalizeWeights();
  }

  /// Set a variety-focused profile (emphasizes trying different recipes)
  void _setVarietyFocusedProfile() {
    _factorWeights['frequency'] = 20;
    _factorWeights['protein_rotation'] = 25;
    _factorWeights['rating'] = 10;
    _factorWeights['variety_encouragement'] = 25;
    _factorWeights['difficulty'] = 5;
    _factorWeights['randomization'] = 5;
    _factorWeights['user_feedback'] = 10;
    _normalizeWeights();
  }

  /// Set a weekday profile (emphasizes simpler, quicker recipes)
  ///
  /// Weekday cooking typically involves:
  /// - Time constraints from work/school schedules
  /// - Need for reliable, tested recipes
  /// - Preference for simpler preparation
  /// - Limited time for experimentation
  ///
  /// Weight adjustments create this behavior:
  /// - **Difficulty: 20%** (high) - Strongly favor simpler recipes
  /// - **Rating: 10%** (low) - Less emphasis on experimentation
  /// - **Variety: 10%** (low) - Stick to familiar patterns
  /// - **Frequency: 30%** (moderate) - Maintain cooking rhythm
  /// - **Protein Rotation: 25%** (moderate) - Basic variety
  /// - **Randomization: 5%** (minimal) - Consistent suggestions
  ///
  /// Mathematical effect: Simple recipes (difficulty 1-2) receive significantly
  /// higher scores due to the 20% difficulty weight, making them 4x more likely
  /// to appear in top recommendations compared to complex recipes.

  void _setWeekdayProfile() {
    _factorWeights['frequency'] = 25;
    _factorWeights['protein_rotation'] = 20;
    _factorWeights['rating'] = 10;
    _factorWeights['variety_encouragement'] = 10;
    _factorWeights['difficulty'] = 20; // Higher weight for weekdays
    _factorWeights['randomization'] = 5;
    _factorWeights['user_feedback'] = 10;
    _normalizeWeights();
  }

  /// Set a weekend profile (more complex, special recipes)
  ///
  /// Weekend cooking typically involves:
  /// - More available time for preparation
  /// - Opportunity to try favorites and new recipes
  /// - Social cooking (family meals, entertaining)
  /// - Willingness to experiment
  ///
  /// Weight adjustments create this behavior:
  /// - **Difficulty: 5%** (low) - Don't penalize complex recipes
  /// - **Rating: 20%** (high) - Emphasize proven favorites
  /// - **Variety: 15%** (higher) - Encourage experimentation
  /// - **Frequency: 30%** (moderate) - Maintain cooking rhythm
  /// - **Protein Rotation: 25%** (moderate) - Basic variety
  /// - **Randomization: 5%** (minimal) - Consistent suggestions
  ///
  /// Mathematical effect: Complex recipes aren't penalized (5% vs 20% weight),
  /// while highly-rated recipes get 2x the influence, making weekend
  /// recommendations favor quality and complexity over simplicity.
  void _setWeekendProfile() {
    _factorWeights['frequency'] = 25;
    _factorWeights['protein_rotation'] = 20;
    _factorWeights['rating'] = 20; // Higher weight on weekends
    _factorWeights['variety_encouragement'] = 15;
    _factorWeights['difficulty'] = 5; // Lower weight on weekends
    _factorWeights['randomization'] = 5;
    _factorWeights['user_feedback'] = 10;
    _normalizeWeights();
  }
}
