import '../migration.dart';

/// Convert ingredient categories and units from strings to enum values
/// 
/// This migration standardizes ingredient data by converting string-based
/// categories and units to use consistent enum values, ensuring better
/// type safety and localization support.
class IngredientEnumConversionMigration extends Migration {
  @override
  int get version => 2;

  @override
  String get description => 'Convert ingredient categories and units to standardized enum values';

  @override
  Duration get estimatedDuration => const Duration(seconds: 5);

  @override
  bool get requiresBackup => true; // Modifying existing data

  @override
  Future<void> up(DatabaseExecutor db) async {
    print('Converting ingredient categories to standardized enum values...');
    
    // Map of old string categories to new enum values
    final categoryMappings = {
      'vegetable': 'vegetable',
      'vegetables': 'vegetable', // Handle plurals
      'fruit': 'fruit',
      'fruits': 'fruit',
      'protein': 'protein',
      'proteins': 'protein',
      'dairy': 'dairy',
      'grain': 'grain',
      'grains': 'grain',
      'pulse': 'pulse',
      'pulses': 'pulse',
      'nuts_and_seeds': 'nuts_and_seeds',
      'nuts and seeds': 'nuts_and_seeds', // Handle space variants
      'seasoning': 'seasoning',
      'seasonings': 'seasoning',
      'sugar products': 'sugar_products',
      'sugar_products': 'sugar_products',
      'oil': 'oil',
      'oils': 'oil',
      'other': 'other',
      // Fallback for any unmapped categories
    };

    // Update categories
    for (final entry in categoryMappings.entries) {
      final oldValue = entry.key;
      final newValue = entry.value;
      
      await db.execute(
        'UPDATE ingredients SET category = ? WHERE LOWER(category) = ?',
        [newValue, oldValue.toLowerCase()],
      );
    }

    // Handle any remaining unmapped categories by setting them to 'other'
    final unmappedCategories = await db.rawQuery('''
      SELECT DISTINCT category 
      FROM ingredients 
      WHERE category NOT IN (${categoryMappings.values.map((_) => '?').join(',')})
    ''', categoryMappings.values.toList());

    if (unmappedCategories.isNotEmpty) {
      print('Found unmapped categories, setting to "other": ${unmappedCategories.map((row) => row['category']).join(', ')}');
      
      await db.execute(
        'UPDATE ingredients SET category = ? WHERE category NOT IN (${categoryMappings.values.map((_) => '?').join(',')})',
        ['other', ...categoryMappings.values.toList()],
      );
    }

    print('Converting ingredient units to standardized enum values...');
    
    // Map of old string units to new enum values
    final unitMappings = {
      'g': 'g',
      'gram': 'g',
      'grams': 'g',
      'kg': 'kg',
      'kilogram': 'kg',
      'kilograms': 'kg',
      'ml': 'ml',
      'milliliter': 'ml',
      'milliliters': 'ml',
      'l': 'l',
      'liter': 'l',
      'liters': 'l',
      'cup': 'cup',
      'cups': 'cup',
      'tbsp': 'tbsp',
      'tablespoon': 'tbsp',
      'tablespoons': 'tbsp',
      'tsp': 'tsp',
      'teaspoon': 'tsp',
      'teaspoons': 'tsp',
      'piece': 'piece',
      'pieces': 'piece',
      'slice': 'slice',
      'slices': 'slice',
    };

    // Update units
    for (final entry in unitMappings.entries) {
      final oldValue = entry.key;
      final newValue = entry.value;
      
      await db.execute(
        'UPDATE ingredients SET unit = ? WHERE LOWER(unit) = ?',
        [newValue, oldValue.toLowerCase()],
      );
    }

    // Handle unmapped units by setting them to null (will be handled as custom units)
    final unmappedUnits = await db.rawQuery('''
      SELECT DISTINCT unit 
      FROM ingredients 
      WHERE unit IS NOT NULL 
      AND unit NOT IN (${unitMappings.values.map((_) => '?').join(',')})
    ''', unitMappings.values.toList());

    if (unmappedUnits.isNotEmpty) {
      print('Found unmapped units, setting to NULL: ${unmappedUnits.map((row) => row['unit']).join(', ')}');
      
      await db.execute(
        'UPDATE ingredients SET unit = NULL WHERE unit IS NOT NULL AND unit NOT IN (${unitMappings.values.map((_) => '?').join(',')})',
        unitMappings.values.toList(),
      );
    }

    print('Ingredient enum conversion completed successfully');
  }

  @override
  Future<void> down(DatabaseExecutor db) async {
    // This migration standardizes data, so rollback would just revert to the same values
    // Since we're mapping to consistent values, there's no need to do anything specific
    // The enum model classes will handle backward compatibility
    print('Ingredient enum conversion rollback completed (no-op - data remains standardized)');
  }

  @override
  Future<bool> validate(DatabaseExecutor db) async {
    // Validate that all categories are now using enum values
    final validCategories = [
      'vegetable', 'fruit', 'protein', 'dairy', 'grain', 'pulse',
      'nuts_and_seeds', 'seasoning', 'sugar_products', 'oil', 'other'
    ];

    final invalidCategories = await db.rawQuery('''
      SELECT DISTINCT category 
      FROM ingredients 
      WHERE category NOT IN (${validCategories.map((_) => '?').join(',')})
    ''', validCategories);

    if (invalidCategories.isNotEmpty) {
      print('Validation failed: Found invalid categories: ${invalidCategories.map((row) => row['category']).join(', ')}');
      return false;
    }

    // Validate that all units are either null or using enum values
    final validUnits = [
      'g', 'kg', 'ml', 'l', 'cup', 'tbsp', 'tsp', 'piece', 'slice'
    ];

    final invalidUnits = await db.rawQuery('''
      SELECT DISTINCT unit 
      FROM ingredients 
      WHERE unit IS NOT NULL 
      AND unit NOT IN (${validUnits.map((_) => '?').join(',')})
    ''', validUnits);

    if (invalidUnits.isNotEmpty) {
      print('Validation failed: Found invalid units: ${invalidUnits.map((row) => row['unit']).join(', ')}');
      return false;
    }

    // Count converted records
    final totalIngredients = await db.rawQuery('SELECT COUNT(*) as count FROM ingredients');
    final count = totalIngredients.first['count'] as int;
    
    print('Validation passed: $count ingredients successfully converted to enum values');
    return true;
  }
}