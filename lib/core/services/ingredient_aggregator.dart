import 'unit_converter.dart';

/// Aggregates ingredient lists: filtering, quantity combining, and grouping.
class IngredientAggregator {
  final UnitConverter _converter;

  /// Ingredients to exclude when quantity is zero ("to taste").
  static const List<String> excludedStaples = [
    'Salt',
    'Water',
    'Oil',
    'Black Pepper',
    'Sugar',
  ];

  IngredientAggregator({UnitConverter? converter})
      : _converter = converter ?? UnitConverter();

  /// Apply exclusion rule (salt rule) to filter ingredients.
  ///
  /// Excludes ingredients that are:
  /// - "To taste" (quantity == 0) AND in the excluded staples list
  /// - OR have null/invalid required fields
  List<Map<String, dynamic>> applyExclusionRule(
      List<Map<String, dynamic>> ingredients) {
    return ingredients.where((ingredient) {
      if (ingredient['name'] == null ||
          ingredient['quantity'] == null ||
          ingredient['unit'] == null ||
          ingredient['category'] == null) {
        return false;
      }

      final quantity = ingredient['quantity'] as double;
      final name = ingredient['name'] as String;

      if (quantity == 0 && excludedStaples.contains(name)) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Aggregate ingredients with the same name.
  ///
  /// Groups ingredients by name (case-insensitive) and combines quantities.
  /// Attempts to convert units within each group.
  /// Converts to larger unit if quantity >= 1000 (g→kg, ml→L).
  List<Map<String, dynamic>> aggregateIngredients(
      List<Map<String, dynamic>> ingredients) {
    final Map<String, List<Map<String, dynamic>>> nameGroups = {};

    for (final ingredient in ingredients) {
      final name = ingredient['name'] as String;
      final key = name.toLowerCase();
      nameGroups.putIfAbsent(key, () => []).add(ingredient);
    }

    final List<Map<String, dynamic>> result = [];

    for (final group in nameGroups.values) {
      if (group.isEmpty) continue;

      final Map<String, Map<String, dynamic>> unitGroups = {};

      for (final item in group) {
        final unit = (item['unit'] as String).toLowerCase();

        String? compatibleKey;
        for (final key in unitGroups.keys) {
          try {
            _converter.convertToCommonUnit(1.0, unit, key);
            compatibleKey = key;
            break;
          } catch (e) {
            // Not compatible, continue searching
          }
        }

        if (compatibleKey != null) {
          final existing = unitGroups[compatibleKey]!;
          final existingQuantity = existing['quantity'] as double;
          final existingUnit = existing['unit'] as String;
          final itemQuantity = item['quantity'] as double;
          final converted = _converter.convertToCommonUnit(
              itemQuantity, unit, existingUnit.toLowerCase());
          existing['quantity'] = existingQuantity + converted;
        } else {
          unitGroups[unit] = Map<String, dynamic>.from(item);
        }
      }

      for (final item in unitGroups.values) {
        final quantity = item['quantity'] as double;
        final unit = (item['unit'] as String).toLowerCase();

        if (unit == 'g' && quantity >= 1000) {
          item['quantity'] = quantity / 1000;
          item['unit'] = 'kg';
        } else if (unit == 'ml' && quantity >= 1000) {
          item['quantity'] = quantity / 1000;
          item['unit'] = 'L';
        } else if (unit == 'tsp' && quantity >= 3) {
          item['quantity'] = quantity / 3;
          item['unit'] = 'tbsp';
        } else if (unit == 'tbsp' && quantity >= 16) {
          item['quantity'] = quantity / 16;
          item['unit'] = 'cup';
        } else if (unit == 'clove' && quantity >= 10) {
          item['quantity'] = quantity / 10;
          item['unit'] = 'head';
        }

        result.add(item);
      }
    }

    return result;
  }

  /// Group ingredients by category.
  ///
  /// Returns a map where keys are category names and values are ingredient lists.
  /// Ingredients with no category default to 'Other'.
  Map<String, List<Map<String, dynamic>>> groupByCategory(
      List<Map<String, dynamic>> ingredients) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final ingredient in ingredients) {
      final category = ingredient['category'] as String? ?? 'Other';
      grouped.putIfAbsent(category, () => []).add(ingredient);
    }

    return grouped;
  }
}
