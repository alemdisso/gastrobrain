import 'ingredient.dart';

/// Represents a potential match between a parsed ingredient name and an existing ingredient
class IngredientMatch {
  /// The matched ingredient from the database
  final Ingredient ingredient;

  /// Confidence score from 0.0 to 1.0 (higher is better)
  final double confidence;

  /// Type of match that was found
  final MatchType matchType;

  IngredientMatch({
    required this.ingredient,
    required this.confidence,
    required this.matchType,
  });

  /// Confidence level for easy categorization
  MatchConfidence get confidenceLevel {
    if (confidence >= 0.90) return MatchConfidence.high;
    if (confidence >= 0.70) return MatchConfidence.medium;
    return MatchConfidence.low;
  }

  @override
  String toString() {
    return 'IngredientMatch(${ingredient.name}, confidence: ${(confidence * 100).toStringAsFixed(0)}%, type: ${matchType.name})';
  }
}

/// Type of matching strategy that found the match
enum MatchType {
  /// Exact string match (case-sensitive)
  exact,

  /// Case-insensitive exact match
  caseInsensitive,

  /// Match after normalizing accents and special characters
  normalized,

  /// Match via translation (e.g., "tomato" → "tomate")
  translation,

  /// Fuzzy/similarity match (Levenshtein distance, etc.)
  fuzzy,

  /// Partial/contains match
  partial,
}

/// Confidence level for easy UI decisions
enum MatchConfidence {
  /// Confidence >= 0.90 - Very likely correct, can auto-select
  high,

  /// Confidence >= 0.70 - Probably correct, show to user for confirmation
  medium,

  /// Confidence < 0.70 - Uncertain, user should verify carefully
  low,
}
