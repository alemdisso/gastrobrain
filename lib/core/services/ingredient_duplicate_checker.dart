import '../../models/ingredient.dart';

enum DuplicateStatus { none, exactDuplicate, similarExists }

class DuplicateCheckResult {
  final DuplicateStatus status;
  final List<String> similarNames;

  const DuplicateCheckResult({
    required this.status,
    this.similarNames = const [],
  });

  bool get isExact => status == DuplicateStatus.exactDuplicate;
  bool get hasSimilar => status == DuplicateStatus.similarExists;
  bool get isClean => status == DuplicateStatus.none;
}

/// Detects exact and prefix-match duplicates against an existing ingredient list.
///
/// Exact match is case-insensitive and diacritic-normalized. Aliases are
/// included in the exact-match check (#198). Prefix suggestions kick in at
/// 2+ characters to avoid noise for single-letter input.
class IngredientDuplicateChecker {
  final List<Ingredient> _ingredients;

  IngredientDuplicateChecker(this._ingredients);

  /// Checks [name] against known ingredients, excluding [excludeId] (edit mode).
  DuplicateCheckResult check(String name, {String? excludeId}) {
    if (name.trim().isEmpty) {
      return const DuplicateCheckResult(status: DuplicateStatus.none);
    }

    final normalized = _normalize(name);
    final candidates = excludeId != null
        ? _ingredients.where((i) => i.id != excludeId).toList()
        : _ingredients;

    // Hard block: name or alias exact match (normalized, case-insensitive)
    for (final ingredient in candidates) {
      if (_normalize(ingredient.name) == normalized) {
        return DuplicateCheckResult(
          status: DuplicateStatus.exactDuplicate,
          similarNames: [ingredient.name],
        );
      }
      for (final alias in ingredient.aliases) {
        if (_normalize(alias) == normalized) {
          return DuplicateCheckResult(
            status: DuplicateStatus.exactDuplicate,
            similarNames: [ingredient.name],
          );
        }
      }
    }

    // Soft warning: prefix match (min 2 chars to avoid noise)
    if (normalized.length >= 2) {
      final similar = <String>[];
      for (final ingredient in candidates) {
        final normalizedIng = _normalize(ingredient.name);
        if (normalizedIng.startsWith(normalized) ||
            normalized.startsWith(normalizedIng)) {
          similar.add(ingredient.name);
        }
      }
      if (similar.isNotEmpty) {
        return DuplicateCheckResult(
          status: DuplicateStatus.similarExists,
          similarNames: similar,
        );
      }
    }

    return const DuplicateCheckResult(status: DuplicateStatus.none);
  }

  String _normalize(String text) {
    if (text.isEmpty) return '';
    String n = text.toLowerCase().trim();
    const accents = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const replacements = 'aaaaaeeeeiiiiooooouuuucn';
    for (int i = 0; i < accents.length; i++) {
      n = n.replaceAll(accents[i], replacements[i]);
    }
    return n.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
