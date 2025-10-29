import 'package:string_similarity/string_similarity.dart';
import '../../models/ingredient.dart';
import '../../models/ingredient_match.dart';

/// Service for matching parsed ingredient names against existing database ingredients
///
/// Provides multi-stage matching with graduated confidence levels:
/// 1. Exact match (100%)
/// 2. Case-insensitive match (95%)
/// 3. Normalized match - removes accents/diacritics, handles plural forms (90%)
/// 4. Prefix/Partial match - substring/prefix matching (65-85%)
/// 5. Fuzzy match - similarity algorithms (60-85%)
/// 6. Translation match - bilingual EN/PT (80%) - Future
///
/// The normalized matching stage includes automatic plural-to-singular conversion
/// for both Portuguese and English, allowing "cebolas" to match "cebola" with 90% confidence.
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

    // Stage 4: Prefix/Partial matches (substring matching)
    final prefixMatches = _findPrefixMatches(parsedName);
    matches.addAll(prefixMatches);

    // If we have prefix matches, include them before fuzzy
    if (matches.isNotEmpty && matches.first.confidence >= 0.80) {
      matches.sort((a, b) => b.confidence.compareTo(a.confidence));
      return matches;
    }

    // Stage 5: Fuzzy matches (similarity-based)
    final fuzzyMatches = _findFuzzyMatches(parsedName);
    matches.addAll(fuzzyMatches);

    // Future stages:
    // Stage 6: Translation matches

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

  /// Stage 3: Normalized match (removes accents, special characters, handles plurals)
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

    // If no direct normalized match found, try singularization
    if (matches.isEmpty) {
      final singularizedParsed = _singularize(normalizedParsed);
      
      // Only search if singularization produced a different form
      if (singularizedParsed != normalizedParsed) {
        final singularFirstLetter = singularizedParsed.isNotEmpty ? singularizedParsed[0] : '';
        final singularCandidates = _firstLetterIndex[singularFirstLetter] ?? [];
        
        for (final ingredient in singularCandidates) {
          final normalizedIngredient = _getCachedNormalized(ingredient.name);
          
          if (normalizedIngredient == singularizedParsed) {
            matches.add(IngredientMatch(
              ingredient: ingredient,
              confidence: 0.90, // High confidence for plural-to-singular matches
              matchType: MatchType.normalized,
            ));
          }
        }
      }
    }

    return matches;
  }

  /// Stage 4: Prefix/Partial match (substring matching)
  /// Handles cases like "azeite" matching "azeite de oliva"
  List<IngredientMatch> _findPrefixMatches(String parsedName) {
    final matches = <IngredientMatch>[];
    final normalizedParsed = _normalize(parsedName);

    // Skip very short strings (less than 3 chars) as prefix matching is unreliable
    if (normalizedParsed.length < 3) {
      return matches;
    }

    // Search through all ingredients
    for (final ingredient in _allIngredients) {
      final normalizedIngredient = _getCachedNormalized(ingredient.name);

      // Skip if already matched exactly or normalized
      if (normalizedIngredient == normalizedParsed) {
        continue; // Already found in earlier stages
      }

      // Check if parsed name is a prefix of the ingredient name
      // Example: "azeite" matches "azeite de oliva"
      if (normalizedIngredient.startsWith(normalizedParsed)) {
        // Check if it's a word boundary (followed by space or end of string)
        // This prevents "tom" from matching "tomate" but allows "tomate" to match "tomate cereja"
        final nextCharIndex = normalizedParsed.length;
        if (nextCharIndex >= normalizedIngredient.length ||
            normalizedIngredient[nextCharIndex] == ' ') {

          // Calculate confidence based on how much of the ingredient name was matched
          // Higher match ratio = higher confidence
          final matchRatio = normalizedParsed.length / normalizedIngredient.length;

          // Scale confidence:
          // - 100% match ratio = 0.85 confidence (very high but not exact)
          // - 50% match ratio = 0.75 confidence (medium-high)
          // - 33% match ratio = 0.65 confidence (medium)
          final confidence = 0.65 + (matchRatio * 0.20);

          matches.add(IngredientMatch(
            ingredient: ingredient,
            confidence: confidence.clamp(0.65, 0.85),
            matchType: MatchType.partial,
          ));
        }
      }

      // Also check reverse: if ingredient name is a prefix of parsed name
      // Less common but useful for cases like parsing "azeite de oliva extra virgem"
      // when only "azeite de oliva" exists in database
      else if (normalizedParsed.startsWith(normalizedIngredient)) {
        final nextCharIndex = normalizedIngredient.length;
        if (nextCharIndex >= normalizedParsed.length ||
            normalizedParsed[nextCharIndex] == ' ') {

          // Lower confidence for reverse matches
          final matchRatio = normalizedIngredient.length / normalizedParsed.length;
          final confidence = 0.60 + (matchRatio * 0.15);

          matches.add(IngredientMatch(
            ingredient: ingredient,
            confidence: confidence.clamp(0.60, 0.75),
            matchType: MatchType.partial,
          ));
        }
      }
    }

    // Sort by confidence (highest first) and limit to top 5 prefix matches
    matches.sort((a, b) => b.confidence.compareTo(a.confidence));
    return matches.take(5).toList();
  }

  /// Stage 5: Fuzzy match using string similarity
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

  /// Irregular plural forms for common cooking ingredients
  /// Maps plural forms to their singular equivalents
  static const Map<String, String> _irregularPlurals = {
    // Portuguese irregular plurals
    'ovos': 'ovo',
    'alhos': 'alho',
    'paes': 'pao',
    'limoes': 'limao',
    'mamoes': 'mamao',
    'pimentoes': 'pimentao',
    'alemaes': 'alemao',
    'capitaes': 'capitao',
    'atuns': 'atum',
    'arrozes': 'arroz',
    'nozes': 'noz',
    'acucares': 'acucar',
    'animais': 'animal',
    // English irregular plurals
    'geese': 'goose',
    'leaves': 'leaf',
    'knives': 'knife',
    'halves': 'half',
    // English -oes plurals (to avoid Portuguese pattern confusion)
    'tomatoes': 'tomato',
    'potatoes': 'potato',
    'mangoes': 'mango',
    'avocados': 'avocado',
    // English -ions plurals (to avoid Portuguese -ns pattern confusion)
    'onions': 'onion',
  };

  /// Singularize a word by removing plural suffixes
  /// Handles both Portuguese and English plural patterns
  /// Returns the singular form if a plural pattern is detected, otherwise returns the original word
  String _singularize(String word) {
    if (word.isEmpty || word.length <= 3) {
      return word; // Too short to safely singularize
    }

    // Check irregular plurals first (most reliable)
    if (_irregularPlurals.containsKey(word)) {
      return _irregularPlurals[word]!;
    }

    // Handle compound words (e.g., "couve flores" -> "couve flor")
    if (word.contains(' ')) {
      final parts = word.split(' ');
      final singularParts = <String>[];
      
      for (final part in parts) {
        singularParts.add(_singularize(part));
      }
      
      return singularParts.join(' ');
    }

    // Portuguese patterns (in order of specificity)
    
    // Pattern: -ões -> -ão (limões -> limão, pimentões -> pimentão)
    // Must check length to avoid matching English -oes
    if (word.endsWith('oes') && word.length > 4) {
      // Check if this looks like Portuguese (has -ões pattern in normalized form)
      // For Portuguese words, this is common: limões, pimentões, mamões
      final beforeOes = word[word.length - 4];
      // Portuguese -ões usually has consonant before 'o'
      // English -oes (tomatoes) has vowel before 'o'
      if (!'aeiou'.contains(beforeOes)) {
        return '${word.substring(0, word.length - 3)}ao';
      }
    }
    
    // Pattern: -ães -> -ão (pães -> pão, alemães -> alemão, capitães -> capitão)
    if (word.endsWith('aes') && word.length > 4) {
      return '${word.substring(0, word.length - 3)}ao';
    }
    
    // Pattern: -ãos -> -ão (mãos -> mão, irmãos -> irmão) - less common
    if (word.endsWith('aos') && word.length > 4) {
      return '${word.substring(0, word.length - 3)}ao';
    }
    
    // Pattern: -res -> -r (açúcares -> açúcar)
    if (word.endsWith('res') && word.length > 4) {
      return word.substring(0, word.length - 2);
    }
    
    // Pattern: -zes -> -z (arrozes -> arroz, nozes -> noz)
    if (word.endsWith('zes') && word.length > 4) {
      return word.substring(0, word.length - 2);
    }
    
    // Pattern: -ns -> -m (atuns -> atum, jardins -> jardim)
    if (word.endsWith('ns') && word.length > 3) {
      return '${word.substring(0, word.length - 2)}m';
    }
    
    // Pattern: -is -> -l (animais -> animal)
    if (word.endsWith('is') && word.length > 3) {
      return '${word.substring(0, word.length - 2)}l';
    }

    // English patterns
    
    // Pattern: -ves -> -f or -fe (knives -> knife, leaves -> leaf, halves -> half)
    if (word.endsWith('ves') && word.length > 4) {
      final stem = word.substring(0, word.length - 3);
      // Try -fe first (common pattern: knife, wife, life)
      return '${stem}fe';
    }
    
    // Pattern: -ies -> -y (berries -> berry, cherries -> cherry, strawberries -> strawberry)
    if (word.endsWith('ies') && word.length > 4) {
      return '${word.substring(0, word.length - 3)}y';
    }
    
    // Pattern: -oes -> -o for English (tomatoes -> tomato, potatoes -> potato)
    // This is checked AFTER Portuguese -ões pattern
    if (word.endsWith('oes') && word.length > 4) {
      return word.substring(0, word.length - 2);
    }
    
    // Pattern: -es after s/ss/sh/ch/x/z (dishes -> dish, boxes -> box)
    if (word.endsWith('es') && word.length > 3) {
      final stem = word.substring(0, word.length - 2);
      // Check if stem ends with s, sh, ch, x, or z
      if (stem.endsWith('s') || stem.endsWith('sh') || 
          stem.endsWith('ch') || stem.endsWith('x') || stem.endsWith('z')) {
        return stem;
      }
    }

    // Pattern: Regular -s plurals (Portuguese and English)
    // Only remove if preceded by a vowel to avoid words like "aspargos"
    if (word.endsWith('s') && word.length > 3) {
      final beforeS = word[word.length - 2];
      // Check if character before 's' is a vowel
      if ('aeiou'.contains(beforeS)) {
        return word.substring(0, word.length - 1);
      }
    }

    // No plural pattern detected, return original
    return word;
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
