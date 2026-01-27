import '../database/database_helper.dart';
import '../models/shopping_list.dart';
import '../models/shopping_list_item.dart';
import 'package:intl/intl.dart';

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

  /// Aggregate ingredients with the same name
  ///
  /// Groups ingredients by name (case-insensitive) and combines quantities.
  /// Attempts to convert units within each group.
  /// Converts to larger unit if quantity >= 1000 (g→kg, ml→L).
  ///
  /// Returns list of aggregated ingredients.
  List<Map<String, dynamic>> aggregateIngredients(List<Map<String, dynamic>> ingredients) {
    // Group by ingredient name (case-insensitive)
    final Map<String, List<Map<String, dynamic>>> nameGroups = {};

    for (final ingredient in ingredients) {
      final name = ingredient['name'] as String;
      final key = name.toLowerCase();

      if (!nameGroups.containsKey(key)) {
        nameGroups[key] = [];
      }
      nameGroups[key]!.add(ingredient);
    }

    // Aggregate each group
    final List<Map<String, dynamic>> result = [];

    for (final group in nameGroups.values) {
      if (group.isEmpty) continue;

      // Within each name group, further group by compatible units
      final Map<String, Map<String, dynamic>> unitGroups = {};

      for (final item in group) {
        final unit = (item['unit'] as String).toLowerCase();

        // Try to find a compatible unit group
        String? compatibleKey;
        for (final key in unitGroups.keys) {
          try {
            // Test if units are compatible
            convertToCommonUnit(1.0, unit, key);
            compatibleKey = key;
            break;
          } catch (e) {
            // Not compatible, continue searching
          }
        }

        if (compatibleKey != null) {
          // Add to existing compatible group
          final existing = unitGroups[compatibleKey]!;
          final existingQuantity = existing['quantity'] as double;
          final existingUnit = existing['unit'] as String;
          final itemQuantity = item['quantity'] as double;

          // Convert and add
          final converted = convertToCommonUnit(itemQuantity, unit, existingUnit.toLowerCase());
          existing['quantity'] = existingQuantity + converted;
        } else {
          // Create new unit group
          unitGroups[unit] = Map<String, dynamic>.from(item);
        }
      }

      // Convert to larger units if needed and add to result
      for (final item in unitGroups.values) {
        final quantity = item['quantity'] as double;
        final unit = (item['unit'] as String).toLowerCase();

        // Convert to larger unit if >= 1000
        if (unit == 'g' && quantity >= 1000) {
          item['quantity'] = quantity / 1000;
          item['unit'] = 'kg';
        } else if (unit == 'ml' && quantity >= 1000) {
          item['quantity'] = quantity / 1000;
          item['unit'] = 'L';
        }

        result.add(item);
      }
    }

    return result;
  }

  /// Group ingredients by category
  ///
  /// Takes aggregated ingredients and groups them by category.
  /// Returns a map where keys are category names and values are lists of ingredients.
  Map<String, List<Map<String, dynamic>>> groupByCategory(List<Map<String, dynamic>> ingredients) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final ingredient in ingredients) {
      final category = ingredient['category'] as String? ?? 'Other';

      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(ingredient);
    }

    return grouped;
  }

  /// Generate a shopping list from a date range
  ///
  /// Extracts ingredients from all meal plan items within the date range,
  /// applies exclusion rules, aggregates quantities, groups by category,
  /// and saves to the database.
  ///
  /// Returns the created ShoppingList.
  Future<ShoppingList> generateFromDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // 1. Generate list name
    final listName = _generateListName(startDate, endDate);

    // 2. Extract ingredients from meal plan items in date range
    final ingredients = await _extractIngredientsInRange(startDate, endDate);

    // 3. Apply exclusion rule (salt rule)
    final filtered = applyExclusionRule(ingredients);

    // 4. Aggregate ingredients
    final aggregated = aggregateIngredients(filtered);

    // 5. Group by category
    final grouped = groupByCategory(aggregated);

    // 6. Create shopping list
    final shoppingList = ShoppingList(
      name: listName,
      dateCreated: DateTime.now(),
      startDate: startDate,
      endDate: endDate,
    );

    // 7. Save shopping list to database
    final listId = await dbHelper.insertShoppingList(shoppingList);

    // 8. Create and save shopping list items
    for (final entry in grouped.entries) {
      final category = entry.key;
      final items = entry.value;

      for (final ingredientData in items) {
        final item = ShoppingListItem(
          shoppingListId: listId,
          ingredientName: ingredientData['name'] as String,
          quantity: ingredientData['quantity'] as double,
          unit: ingredientData['unit'] as String,
          category: category,
          isPurchased: false,
        );

        await dbHelper.insertShoppingListItem(item);
      }
    }

    // 9. Return the created shopping list with ID
    return shoppingList.copyWith(id: listId);
  }

  /// Generate a display name for the shopping list
  String _generateListName(DateTime start, DateTime end) {
    final formatter = DateFormat('MMM d');
    return '${formatter.format(start)}-${end.day}';
  }

  /// Extract ingredients from meal plan items in date range
  Future<List<Map<String, dynamic>>> _extractIngredientsInRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    // TODO: Implement ingredient extraction
    // For now, return empty list
    return [];
  }

  /// Toggle the purchased state of a shopping list item
  ///
  /// Retrieves the item, flips its isPurchased state, and updates the database.
  Future<void> toggleItemPurchased(int itemId) async {
    final item = await dbHelper.getShoppingListItem(itemId);
    if (item == null) return;

    final updated = item.copyWith(isPurchased: !item.isPurchased);
    await dbHelper.updateShoppingListItem(updated);
  }
}

/// Exception thrown when units cannot be converted
class UnitConversionException implements Exception {
  final String message;
  UnitConversionException(this.message);

  @override
  String toString() => 'UnitConversionException: $message';
}
