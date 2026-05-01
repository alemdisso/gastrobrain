import '../../models/tag.dart';

enum TagDuplicateStatus { none, exactDuplicate, similarExists }

class TagDuplicateCheckResult {
  final TagDuplicateStatus status;
  final List<String> similarNames;

  const TagDuplicateCheckResult({
    required this.status,
    this.similarNames = const [],
  });

  bool get isExact => status == TagDuplicateStatus.exactDuplicate;
  bool get hasSimilar => status == TagDuplicateStatus.similarExists;
  bool get isClean => status == TagDuplicateStatus.none;
}

/// Detects exact and prefix-match duplicates against an existing tag list
/// within a single tag type.
///
/// Exact match is case-insensitive and diacritic-normalized. Prefix suggestions
/// kick in at 2+ characters to avoid noise for single-letter input.
class TagDuplicateChecker {
  final List<Tag> _tags;

  TagDuplicateChecker(this._tags);

  /// Checks [name] against known tags, excluding [excludeId] (edit mode).
  TagDuplicateCheckResult check(String name, {String? excludeId}) {
    if (name.trim().isEmpty) {
      return const TagDuplicateCheckResult(status: TagDuplicateStatus.none);
    }

    final normalized = _normalize(name);
    final candidates = excludeId != null
        ? _tags.where((t) => t.id != excludeId).toList()
        : _tags;

    // Hard block: case-insensitive exact match.
    for (final tag in candidates) {
      if (_normalize(tag.name) == normalized) {
        return TagDuplicateCheckResult(
          status: TagDuplicateStatus.exactDuplicate,
          similarNames: [tag.name],
        );
      }
    }

    // Soft warning: prefix match (min 2 chars to avoid noise).
    if (normalized.length >= 2) {
      final similar = <String>[];
      for (final tag in candidates) {
        final normalizedTag = _normalize(tag.name);
        if (normalizedTag.startsWith(normalized) ||
            normalized.startsWith(normalizedTag)) {
          similar.add(tag.name);
        }
      }
      if (similar.isNotEmpty) {
        return TagDuplicateCheckResult(
          status: TagDuplicateStatus.similarExists,
          similarNames: similar,
        );
      }
    }

    return const TagDuplicateCheckResult(status: TagDuplicateStatus.none);
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
