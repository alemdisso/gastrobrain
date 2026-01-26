import '../database/database_helper.dart';

class ShoppingListService {
  final DatabaseHelper dbHelper;

  /// Ingredients to exclude when quantity is zero ("to taste")
  static const List<String> _excludedStaples = [
    'Salt',
    'Water',
    'Oil',
    'Black Pepper',
    'Sugar',
  ];

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

  /// Apply exclusion rule (salt rule) to filter ingredients
  ///
  /// Excludes ingredients that are:
  /// - "To taste" (quantity == 0)
  /// - AND in the excluded staples list
  ///
  /// Returns filtered list of ingredients.
  List<Map<String, dynamic>> applyExclusionRule(List<Map<String, dynamic>> ingredients) {
    return ingredients.where((ingredient) {
      final quantity = ingredient['quantity'] as double;
      final name = ingredient['name'] as String;

      // Exclude if quantity is 0 AND name is in exclusion list
      if (quantity == 0 && _excludedStaples.contains(name)) {
        return false;
      }

      return true;
    }).toList();
  }
}

/// Exception thrown when units cannot be converted
class UnitConversionException implements Exception {
  final String message;
  UnitConversionException(this.message);

  @override
  String toString() => 'UnitConversionException: $message';
}
