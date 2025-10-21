import 'package:string_similarity/string_similarity.dart';
import '../../models/ingredient.dart';
import '../../models/ingredient_match.dart';

/// Service for matching parsed ingredient names against existing database ingredients
///
/// Provides multi-stage matching with graduated confidence levels:
/// 1. Exact match (100%)
/// 2. Case-insensitive match (95%)
/// 3. Normalized match - removes accents/diacritics (90%)
/// 4. Fuzzy match - similarity algorithms (60-85%)
/// 5. Translation match - bilingual EN/PT (80%) - Future
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

    // If we have high-confidence normalized matches, return early
    if (matches.isNotEmpty && matches.first.confidence >= 0.90) {
      matches.sort((a, b) => b.confidence.compareTo(a.confidence));
      return matches;
    }

    // Stage 4: Fuzzy matches (similarity-based)
    final fuzzyMatches = _findFuzzyMatches(parsedName);
    matches.addAll(fuzzyMatches);

    // Future stages:
    // Stage 5: Translation matches
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

  /// Stage 4: Fuzzy match using string similarity
  List<IngredientMatch> _findFuzzyMatches(String parsedName) {
    final matches = <IngredientMatch>[];
    final normalizedParsed = _normalize(parsedName);

    // Skip very short strings (less than 3 chars) as fuzzy matching is unreliable
    if (normalizedParsed.length < 3) {
      return matches;
    }

    // Check all ingredients for similarity
    for (final ingredient in _allIngredients) {
      final normalizedIngredient = _getCachedNormalized(ingredient.name);

      // Skip if already matched exactly or normalized
      if (normalizedIngredient == normalizedParsed) {
        continue; // Already found in normalized stage
      }

      // Calculate similarity using Jaro-Winkler distance (0.0 to 1.0)
      final similarity = normalizedParsed.similarityTo(normalizedIngredient);

      // Only include matches above threshold (60%)
      // Confidence scaling:
      // - 0.85+ similarity = 85% confidence (high)
      // - 0.75-0.84 similarity = 75-84% confidence (medium)
      // - 0.60-0.74 similarity = 60-74% confidence (low)
      if (similarity >= 0.60) {
        // Scale confidence: similarity of 0.60 -> 60%, 0.85+ -> 85%
        final confidence = similarity.clamp(0.60, 0.85);

        matches.add(IngredientMatch(
          ingredient: ingredient,
          confidence: confidence,
          matchType: MatchType.fuzzy,
        ));
      }
    }

    // Sort by similarity (highest first) and limit to top 5 fuzzy matches
    matches.sort((a, b) => b.confidence.compareTo(a.confidence));
    return matches.take(5).toList();
  }

  /// Normalize a string: lowercase, remove accents, normalize separators, trim
  String _normalize(String text) {
    if (text.isEmpty) return '';

    // Convert to lowercase and trim
    String normalized = text.toLowerCase().trim();

    // Remove common accents/diacritics
    // This is a basic implementation - can be enhanced with a package later
    const accents = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const replacements = 'aaaaaeeeeiiiiooooouuuucn';

    for (int i = 0; i < accents.length; i++) {
      normalized = normalized.replaceAll(accents[i], replacements[i]);
    }

    // Normalize word separators: convert hyphens, underscores to spaces
    normalized = normalized.replaceAll('-', ' ');
    normalized = normalized.replaceAll('_', ' ');

    // Collapse multiple spaces into single space
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');

    // Final trim after normalization
    normalized = normalized.trim();

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
