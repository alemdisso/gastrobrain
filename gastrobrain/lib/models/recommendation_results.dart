import 'recipe_recommendation.dart';

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

  /// Convert recommendation results to JSON-compatible Map
  Map<String, dynamic> toJson() {
    return {
      'recommendations': recommendations.map((r) => r.toJson()).toList(),
      'total_evaluated': totalEvaluated,
      'query_parameters': queryParameters,
      'generated_at': generatedAt.toIso8601String(),
      'schema_version': 1, // Add version for forward compatibility
    };
  }
}
