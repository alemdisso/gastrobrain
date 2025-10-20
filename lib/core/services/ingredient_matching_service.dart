import '../../models/ingredient.dart';
import '../../models/ingredient_match.dart';

/// Service for matching parsed ingredient names against existing database ingredients
///
/// Provides multi-stage matching with graduated confidence levels:
/// 1. Exact match (100%)
/// 2. Case-insensitive match (95%)
/// 3. Normalized match - removes accents/diacritics (90%)
/// 4. Translation match - bilingual EN/PT (80%) - Future
/// 5. Fuzzy match - similarity algorithms (60-75%) - Future
/// 6. Partial match - contains/substring (50-60%) - Future
class IngredientMatchingService {
  /// Cache of normalized ingredient names for performance
  final Map<String, String> _normalizedCache = {};

  /// Index of ingredients by first letter for faster lookup
  final Map<String, List<Ingredient>> _firstLetterIndex = {};

  /// All available ingredients from the database
  List<Ingredient> _allIngredients = [];

  /// Initialize the service with ingredients and build indexes
  void initialize(List<Ingredient> ingredients) {
    _allIngredients = ingredients;
    _buildFirstLetterIndex();
    _buildNormalizedCache();
  }

  /// Find all potential matches for a parsed ingredient name
  /// Returns list sorted by confidence (highest first)
  List<IngredientMatch> findMatches(String parsedName) {
    if (parsedName.trim().isEmpty) return [];

    final matches = <IngredientMatch>[];

    // Stage 1: Exact match
    final exactMatch = _findExactMatch(parsedName);
    if (exactMatch != null) {
      matches.add(exactMatch);
      return matches; // Exact match found, no need to continue
    }

    // Stage 2: Case-insensitive match
    final caseInsensitiveMatch = _findCaseInsensitiveMatch(parsedName);
    if (caseInsensitiveMatch != null) {
      matches.add(caseInsensitiveMatch);
      return matches; // High confidence match, no need to continue
    }

    // Stage 3: Normalized match (removes accents, special chars)
    final normalizedMatches = _findNormalizedMatches(parsedName);
    matches.addAll(normalizedMatches);

    // Future stages will be added here:
    // Stage 4: Translation matches
    // Stage 5: Fuzzy matches
    // Stage 6: Partial matches

    // Sort by confidence (highest first)
    matches.sort((a, b) => b.confidence.compareTo(a.confidence));

    return matches;
  }

  /// Stage 1: Exact string match (case-sensitive)
  IngredientMatch? _findExactMatch(String parsedName) {
    // Use first-letter index for faster lookup
    final firstLetter = parsedName[0].toLowerCase();
    final candidates = _firstLetterIndex[firstLetter] ?? [];

    for (final ingredient in candidates) {
      if (ingredient.name == parsedName) {
        return IngredientMatch(
          ingredient: ingredient,
          confidence: 1.0,
          matchType: MatchType.exact,
        );
      }
    }
    return null;
  }

  /// Stage 2: Case-insensitive exact match
  IngredientMatch? _findCaseInsensitiveMatch(String parsedName) {
    final lowerParsedName = parsedName.toLowerCase();
    final firstLetter = lowerParsedName[0];
    final candidates = _firstLetterIndex[firstLetter] ?? [];

    for (final ingredient in candidates) {
      if (ingredient.name.toLowerCase() == lowerParsedName) {
        return IngredientMatch(
          ingredient: ingredient,
          confidence: 0.95,
          matchType: MatchType.caseInsensitive,
        );
      }
    }
    return null;
  }

  /// Stage 3: Normalized match (removes accents, special characters)
  List<IngredientMatch> _findNormalizedMatches(String parsedName) {
    final normalizedParsed = _normalize(parsedName);
    final matches = <IngredientMatch>[];

    // Search through all ingredients (already indexed)
    final firstLetter = normalizedParsed.isNotEmpty ? normalizedParsed[0] : '';
    final candidates = _firstLetterIndex[firstLetter] ?? [];

    for (final ingredient in candidates) {
      final normalizedIngredient = _getCachedNormalized(ingredient.name);

      if (normalizedIngredient == normalizedParsed) {
        matches.add(IngredientMatch(
          ingredient: ingredient,
          confidence: 0.90,
          matchType: MatchType.normalized,
        ));
      }
    }

    return matches;
  }

  /// Normalize a string: lowercase, remove accents, trim
  String _normalize(String text) {
    if (text.isEmpty) return '';

    // Convert to lowercase
    String normalized = text.toLowerCase().trim();

    // Remove common accents/diacritics
    // This is a basic implementation - can be enhanced with a package later
    const accents = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const replacements = 'aaaaaeeeeiiiiooooouuuucn';

    for (int i = 0; i < accents.length; i++) {
      normalized = normalized.replaceAll(accents[i], replacements[i]);
    }

    return normalized;
  }

  /// Get cached normalized version of a name
  String _getCachedNormalized(String name) {
    return _normalizedCache[name] ?? _normalize(name);
  }

  /// Build first-letter index for faster lookups
  void _buildFirstLetterIndex() {
    _firstLetterIndex.clear();

    for (final ingredient in _allIngredients) {
      if (ingredient.name.isEmpty) continue;

      final firstLetter = ingredient.name[0].toLowerCase();
      _firstLetterIndex.putIfAbsent(firstLetter, () => []).add(ingredient);
    }
  }

  /// Build cache of normalized ingredient names
  void _buildNormalizedCache() {
    _normalizedCache.clear();

    for (final ingredient in _allIngredients) {
      _normalizedCache[ingredient.name] = _normalize(ingredient.name);
    }
  }

  /// Get the best match (highest confidence) if available
  IngredientMatch? getBestMatch(String parsedName) {
    final matches = findMatches(parsedName);
    return matches.isNotEmpty ? matches.first : null;
  }

  /// Check if a match should be auto-selected
  /// Returns true if there's a single high-confidence match
  bool shouldAutoSelect(List<IngredientMatch> matches) {
    if (matches.isEmpty) return false;
    if (matches.length > 1 && matches[0].confidence == matches[1].confidence) {
      return false; // Multiple equally confident matches - user should choose
    }
    return matches.first.confidenceLevel == MatchConfidence.high;
  }

  /// Get the auto-selected match if applicable
  IngredientMatch? getAutoSelectedMatch(String parsedName) {
    final matches = findMatches(parsedName);
    return shouldAutoSelect(matches) ? matches.first : null;
  }
}
