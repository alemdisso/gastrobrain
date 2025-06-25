import '../database/database_helper.dart';
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

  static Future<RecommendationResults> fromJson(
    Map<String, dynamic> json,
    DatabaseHelper dbHelper,
  ) async {
    // Process the recommendations list
    final recommendationsJson = json['recommendations'] as List;
    final recommendations = <RecipeRecommendation>[];

    for (final recJson in recommendationsJson) {
      final recommendation = await RecipeRecommendation.fromJson(
        recJson as Map<String, dynamic>,
        dbHelper,
      );
      recommendations.add(recommendation);
    }

    return RecommendationResults(
      recommendations: recommendations,
      totalEvaluated: json['total_evaluated'] as int,
      queryParameters:
          Map<String, dynamic>.from(json['query_parameters'] as Map),
      generatedAt: DateTime.parse(json['generated_at'] as String),
    );
  }
}
