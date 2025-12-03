import 'package:diacritic/diacritic.dart';

/// Utility class for consistent, locale-aware sorting across the application.
///
/// Provides normalized sorting that:
/// - Treats hyphens as spaces (e.g., "pimenta-do-reino" sorts before "pimenta jalapeño")
/// - Removes accents from all characters (language-agnostic)
/// - Is case-insensitive
/// - Scales to multiple languages automatically
///
/// Example:
/// ```dart
/// final sortedIngredients = SortingUtils.sortByName(
///   ingredients,
///   (i) => i.name,
/// );
/// ```
class SortingUtils {
  /// Normalizes text for sorting by applying language-agnostic preprocessing.
  ///
  /// Preprocessing steps:
  /// - Remove diacritics/accents (ã→a, é→e, ç→c, etc.) for all languages
  /// - Convert to lowercase for case-insensitive comparison
  /// - Replace hyphens with spaces (treats "pimenta-do-reino" as "pimenta do reino")
  /// - Trim whitespace
  ///
  /// This ensures natural alphabetical ordering regardless of special characters.
  ///
  /// Examples:
  /// - "pimenta-do-reino" → "pimenta do reino"
  /// - "Feijão-Fradinho" → "feijao fradinho"
  /// - "Couve-Flor" → "couve flor"
  static String normalizeForSorting(String text) {
    return removeDiacritics(text)
        .toLowerCase()
        .replaceAll('-', ' ')
        .trim();
  }

  /// Sorts a list of items by name using normalized comparison.
  ///
  /// This method pre-computes normalized sort keys for performance (O(n) normalizations
  /// instead of O(n log n)), then uses standard string comparison.
  ///
  /// Parameters:
  /// - [items]: The list of items to sort
  /// - [getName]: Function to extract the name from each item
  ///
  /// Returns a new sorted list without modifying the original.
  ///
  /// Performance: O(n log n) with O(n) normalization overhead.
  /// For 500 items: ~500 normalizations + ~2,300 comparisons = <5ms on most devices.
  ///
  /// Example:
  /// ```dart
  /// final sortedIngredients = SortingUtils.sortByName(ingredients, (i) => i.name);
  /// ```
  static List<T> sortByName<T>(
    List<T> items,
    String Function(T) getName,
  ) {
    if (items.isEmpty) {
      return [];
    }

    // Pre-compute normalized sort keys (normalize once per item, not per comparison)
    final itemsWithKeys = items
        .map((item) => (
              item: item,
              sortKey: normalizeForSorting(getName(item)),
            ))
        .toList();

    // Sort using pre-computed keys with standard string comparison
    itemsWithKeys.sort((a, b) => a.sortKey.compareTo(b.sortKey));

    // Extract sorted items
    return itemsWithKeys.map((e) => e.item).toList();
  }

  /// Sorts a list of strings using normalized comparison.
  ///
  /// Convenience method for sorting string lists directly.
  ///
  /// Example:
  /// ```dart
  /// final sorted = SortingUtils.sortStrings(['pimenta-do-reino', 'pimenta jalapeño']);
  /// // Result: ['pimenta-do-reino', 'pimenta jalapeño']
  /// ```
  static List<String> sortStrings(List<String> strings) {
    return sortByName(strings, (s) => s);
  }
}
