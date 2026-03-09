/// Unit conversion utilities for ingredient quantities.
class UnitConverter {
  /// Convert quantity from one unit to another.
  ///
  /// Supports conversions:
  /// - Weight: g ↔ kg
  /// - Volume: ml ↔ L, tsp ↔ tbsp (3:1), tbsp ↔ cup (16:1), tsp ↔ cup (48:1)
  /// - Count: clove ↔ head (10:1)
  ///
  /// Returns the converted quantity, or throws [UnitConversionException]
  /// if units are incompatible.
  double convertToCommonUnit(double quantity, String fromUnit, String toUnit) {
    final from = fromUnit.toLowerCase();
    final to = toUnit.toLowerCase();

    if (from == to) return quantity;

    // Weight
    if (from == 'g' && to == 'kg') return quantity / 1000;
    if (from == 'kg' && to == 'g') return quantity * 1000;

    // Volume: metric
    if (from == 'ml' && to == 'l') return quantity / 1000;
    if (from == 'l' && to == 'ml') return quantity * 1000;

    // Volume: cooking units — 3 tsp = 1 tbsp, 16 tbsp = 1 cup, 48 tsp = 1 cup
    if (from == 'tsp' && to == 'tbsp') return quantity / 3;
    if (from == 'tbsp' && to == 'tsp') return quantity * 3;
    if (from == 'tbsp' && to == 'cup') return quantity / 16;
    if (from == 'cup' && to == 'tbsp') return quantity * 16;
    if (from == 'tsp' && to == 'cup') return quantity / 48;
    if (from == 'cup' && to == 'tsp') return quantity * 48;

    // Count: garlic — 1 head ≈ 10 cloves
    if (from == 'clove' && to == 'head') return quantity / 10;
    if (from == 'head' && to == 'clove') return quantity * 10;

    throw UnitConversionException('Cannot convert $fromUnit to $toUnit');
  }
}

/// Exception thrown when units cannot be converted.
class UnitConversionException implements Exception {
  final String message;
  UnitConversionException(this.message);

  @override
  String toString() => 'UnitConversionException: $message';
}
