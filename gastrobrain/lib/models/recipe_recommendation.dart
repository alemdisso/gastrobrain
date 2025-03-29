import '../../models/recipe.dart';

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
