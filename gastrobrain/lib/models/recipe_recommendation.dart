import '../database/database_helper.dart';
import '../core/errors/gastrobrain_exceptions.dart';
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

  /// Convert recommendation to JSON-compatible Map
  Map<String, dynamic> toJson() {
    return {
      'recipe_id': recipe.id,
      'total_score': totalScore,
      'factor_scores': factorScores,
      'metadata': metadata,
    };
  }

  /// Create a RecipeRecommendation from JSON Map
  static Future<RecipeRecommendation> fromJson(
    Map<String, dynamic> json,
    DatabaseHelper dbHelper,
  ) async {
    // Retrieve recipe from database using the recipe_id
    final recipeId = json['recipe_id'] as String;
    final recipe = await dbHelper.getRecipe(recipeId);

    if (recipe == null) {
      throw NotFoundException('Recipe not found with id: $recipeId');
    }

    return RecipeRecommendation(
      recipe: recipe,
      totalScore: json['total_score'] as double,
      factorScores: Map<String, double>.from(json['factor_scores'] as Map),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : {},
    );
  }
}
