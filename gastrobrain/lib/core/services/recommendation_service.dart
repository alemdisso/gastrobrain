// lib/core/services/recommendation_service.dart

import 'dart:math';

import '../../database/database_helper.dart';
import '../../models/recipe.dart';
import '../../models/protein_type.dart';
import '../errors/gastrobrain_exceptions.dart';
import 'recommendation_database_queries.dart';

/// A class representing a scored recipe recommendation.
class RecipeRecommendation {
  /// The Recipe being recommended
  final Recipe recipe;

  /// The total score (0-100) calculated for this recipe
  final double totalScore;

  /// Individual factor scores, mapped by factor ID
  final Map<String, double> factorScores;

  /// Additional context data that might be useful for UI or debugging
  final Map<String, dynamic> metadata;

  RecipeRecommendation({
    required this.recipe,
    required this.totalScore,
    required this.factorScores,
    this.metadata = const {},
  });
}

/// Results container for recommendation queries
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

  /// Weight of this factor in the recommendation (0-100)
  int get weight;

  /// Calculate a score (0-100) for this recipe based on the factor's criteria
  Future<double> calculateScore(Recipe recipe, Map<String, dynamic> context);

  /// Describe what data this factor needs from the database
  Set<String> get requiredData;
}

/// Service for generating recipe recommendations based on various factors
class RecommendationService {
  final RecommendationDatabaseQueries _dbQueries;
  final Random _random = Random();

  /// Map of registered recommendation factors
  final Map<String, RecommendationFactor> _factors = {};

  /// Default constructor with DatabaseHelper injection
  RecommendationService({required DatabaseHelper dbHelper})
      : _dbQueries = RecommendationDatabaseQueries(dbHelper: dbHelper);

  /// Register a scoring factor
  void registerFactor(RecommendationFactor factor) {
    _factors[factor.id] = factor;
  }

  /// Unregister a scoring factor
  void unregisterFactor(String factorId) {
    _factors.remove(factorId);
  }

  /// Get all registered factors
  List<RecommendationFactor> get factors => _factors.values.toList();

  /// Get the total weight of all registered factors
  int get totalWeight =>
      _factors.values.fold(0, (sum, factor) => sum + factor.weight);

  /// Main method to get recipe recommendations
  ///
  /// Parameters:
  /// - [count]: Number of recipes to recommend
  /// - [excludeIds]: Recipe IDs to exclude from recommendations
  /// - [avoidProteinTypes]: Protein types to avoid or downrank
  /// - [forDate]: Target date for the recommendation (for context)
  /// - [mealType]: Meal type ('lunch' or 'dinner')
  ///
  /// Returns a list of recommended recipes sorted by score
  Future<List<Recipe>> getRecommendations({
    int count = 5,
    List<String> excludeIds = const [],
    List<ProteinType>? avoidProteinTypes,
    DateTime? forDate,
    String? mealType,
  }) async {
    try {
      // Validate inputs
      if (count <= 0) {
        throw ValidationException('Recommendation count must be positive');
      }

      if (_factors.isEmpty) {
        throw GastrobrainException('No recommendation factors registered');
      }

      // Build context data needed by factors
      final context = await _buildContext(
        excludeIds: excludeIds,
        avoidProteinTypes: avoidProteinTypes,
        forDate: forDate,
        mealType: mealType,
      );

      // Get candidate recipes
      final recipes = await _getCandidateRecipes(excludeIds);

      if (recipes.isEmpty) {
        return [];
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
    } on ValidationException {
      rethrow;
    } on NotFoundException {
      rethrow;
    } catch (e) {
      throw GastrobrainException(
          'Error generating recommendations: ${e.toString()}');
    }
  }

  /// Get detailed recommendation results including scores and metadata
  Future<RecommendationResults> getDetailedRecommendations({
    int count = 5,
    List<String> excludeIds = const [],
    List<ProteinType>? avoidProteinTypes,
    DateTime? forDate,
    String? mealType,
  }) async {
    try {
      // Validate inputs
      if (count <= 0) {
        throw ValidationException('Recommendation count must be positive');
      }

      if (_factors.isEmpty) {
        throw GastrobrainException('No recommendation factors registered');
      }

      // Build context data needed by factors
      final context = await _buildContext(
        excludeIds: excludeIds,
        avoidProteinTypes: avoidProteinTypes,
        forDate: forDate,
        mealType: mealType,
      );

      // Get candidate recipes
      final recipes = await _getCandidateRecipes(excludeIds);

      if (recipes.isEmpty) {
        return RecommendationResults(
          recommendations: [],
          totalEvaluated: 0,
          queryParameters: {
            'count': count,
            'excludeIds': excludeIds,
            'avoidProteinTypes': avoidProteinTypes?.map((p) => p.name).toList(),
            'forDate': forDate?.toIso8601String(),
            'mealType': mealType,
          },
        );
      }

      // Calculate scores for each recipe using all factors
      final scoredRecipes = await _scoreRecipes(recipes, context);

      // Sort by total score (descending)
      scoredRecipes.sort((a, b) => b.totalScore.compareTo(a.totalScore));

      return RecommendationResults(
        recommendations: scoredRecipes.take(count).toList(),
        totalEvaluated: recipes.length,
        queryParameters: {
          'count': count,
          'excludeIds': excludeIds,
          'avoidProteinTypes': avoidProteinTypes?.map((p) => p.name).toList(),
          'forDate': forDate?.toIso8601String(),
          'mealType': mealType,
        },
      );
    } on ValidationException {
      rethrow;
    } on NotFoundException {
      rethrow;
    } catch (e) {
      throw GastrobrainException(
          'Error generating detailed recommendations: ${e.toString()}');
    }
  }

  /// Build context data needed by scoring factors
  Future<Map<String, dynamic>> _buildContext({
    required List<String> excludeIds,
    List<ProteinType>? avoidProteinTypes,
    DateTime? forDate,
    String? mealType,
  }) async {
    // Collect required data from all registered factors
    final requiredData =
        _factors.values.expand((factor) => factor.requiredData).toSet();

    final context = <String, dynamic>{
      'excludeIds': excludeIds,
      'avoidProteinTypes': avoidProteinTypes,
      'forDate': forDate,
      'mealType': mealType,
      'randomSeed': _random.nextInt(1000), // For reproducible randomness
    };

    // Load meal history data if required
    if (requiredData.contains('mealCounts')) {
      context['mealCounts'] = await _dbQueries.getMealCounts();
    }

    // Load last cooked dates if required
    if (requiredData.contains('lastCooked')) {
      context['lastCooked'] = await _dbQueries.getLastCookedDates();
    }

    // Load protein types if required
    final needsProteinInfo =
        requiredData.contains('proteinTypes') || avoidProteinTypes != null;

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

    return context;
  }

  /// Get candidate recipes that meet basic filtering criteria
  Future<List<Recipe>> _getCandidateRecipes(List<String> excludeIds) async {
    return await _dbQueries.getCandidateRecipes(excludeIds: excludeIds);
  }

  /// Score recipes using all registered factors
  Future<List<RecipeRecommendation>> _scoreRecipes(
    List<Recipe> recipes,
    Map<String, dynamic> context,
  ) async {
    final recommendations = <RecipeRecommendation>[];
    final factorTotal = totalWeight > 0 ? totalWeight : 100;

    for (final recipe in recipes) {
      final factorScores = <String, double>{};
      double weightedTotal = 0;

      // Calculate score for each factor
      for (final factor in _factors.values) {
        final score = await factor.calculateScore(recipe, context);
        factorScores[factor.id] = score;

        // Apply factor weight
        weightedTotal += (score * factor.weight / factorTotal);
      }

      // Create recommendation with total score and factor breakdown
      recommendations.add(RecipeRecommendation(
        recipe: recipe,
        totalScore: weightedTotal,
        factorScores: factorScores,
      ));
    }

    return recommendations;
  }
}
