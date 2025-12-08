class QuantityFormatter {
  // Common cooking fractions with their decimal equivalents
  // Ordered by denominator (simpler fractions first) for preference in ties
  static const _fractions = {
    '½': 0.5,        // 1/2
    '⅓': 1.0 / 3.0,  // 1/3
    '⅔': 2.0 / 3.0,  // 2/3
    '¼': 0.25,       // 1/4
    '¾': 0.75,       // 3/4
    '⅕': 0.2,        // 1/5
    '⅖': 0.4,        // 2/5
    '⅗': 0.6,        // 3/5
    '⅘': 0.8,        // 4/5
    '⅙': 1.0 / 6.0,  // 1/6
    '⅛': 0.125,      // 1/8
  };

  static const double _tolerance = 0.05;

  static String format(double quantity) {
    // Handle negative numbers
    if (quantity < 0) {
      return '-${format(-quantity)}';
    }

    // Handle whole numbers
    if (quantity == quantity.toInt()) {
      return quantity.toInt().toString();
    }

    // Extract whole and fractional parts
    final wholePart = quantity.floor();
    final fractionalPart = quantity - wholePart;

    // Try to match fractional part to a common fraction
    String? matchedFraction;
    double minDifference = double.infinity;

    for (final entry in _fractions.entries) {
      final difference = (fractionalPart - entry.value).abs();
      if (difference < minDifference && difference <= _tolerance) {
        minDifference = difference;
        matchedFraction = entry.key;
      }
    }

    // If we found a matching fraction within tolerance
    if (matchedFraction != null) {
      if (wholePart > 0) {
        // Mixed number without space (e.g., "1½")
        return '$wholePart$matchedFraction';
      } else {
        // Just fraction (e.g., "½")
        return matchedFraction;
      }
    }

    // Fall back to decimal formatting (existing logic)
    return quantity.toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }
}