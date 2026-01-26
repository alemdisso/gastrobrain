import '../database/database_helper.dart';

class ShoppingListService {
  final DatabaseHelper dbHelper;

  ShoppingListService(this.dbHelper);

  /// Convert quantity from one unit to another
  ///
  /// Supports basic metric conversions:
  /// - Weight: g ↔ kg
  /// - Volume: ml ↔ L
  ///
  /// Returns the converted quantity, or throws an exception if units are incompatible.
  double convertToCommonUnit(double quantity, String fromUnit, String toUnit) {
    // Normalize to lowercase
    final from = fromUnit.toLowerCase();
    final to = toUnit.toLowerCase();

    // If units are the same, no conversion needed
    if (from == to) return quantity;

    // Weight conversions
    if (from == 'g' && to == 'kg') {
      return quantity / 1000;
    }
    if (from == 'kg' && to == 'g') {
      return quantity * 1000;
    }

    // Volume conversions
    if (from == 'ml' && to == 'l') {
      return quantity / 1000;
    }
    if (from == 'l' && to == 'ml') {
      return quantity * 1000;
    }

    // Units are incompatible
    throw UnitConversionException('Cannot convert $fromUnit to $toUnit');
  }
}

/// Exception thrown when units cannot be converted
class UnitConversionException implements Exception {
  final String message;
  UnitConversionException(this.message);

  @override
  String toString() => 'UnitConversionException: $message';
}
