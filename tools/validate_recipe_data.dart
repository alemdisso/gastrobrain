// validate_recipe_data.dart
// Comprehensive validation script for enhanced recipe data quality
// Validates ingredient relationships, data completeness, protein types, and multi-ingredient scenarios

// ignore_for_file: avoid_print

import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart' show Sqflite;
import 'package:path/path.dart' as path;
import '../lib/models/protein_type.dart';
import '../lib/models/measurement_unit.dart';

/// Validation result for tracking issues
class ValidationIssue {
  final String category;
  final String severity; // 'ERROR', 'WARNING', 'INFO'
  final String message;
  final Map<String, dynamic>? details;

  ValidationIssue({
    required this.category,
    required this.severity,
    required this.message,
    this.details,
  });

  @override
  String toString() {
    String result = '[$severity] $category: $message';
    if (details != null) {
      result += '\n  Details: $details';
    }
    return result;
  }
}

/// Main validation class
class RecipeDataValidator {
  final Database db;
  final List<ValidationIssue> issues = [];

  RecipeDataValidator(this.db);

  /// Run all validation checks
  Future<void> runAllValidations() async {
    print('╔═══════════════════════════════════════════════════════════════╗');
    print('║        Recipe Data Validation Report                         ║');
    print('╚═══════════════════════════════════════════════════════════════╝\n');

    await _printDatabaseStats();

    print('\n▶ Running validation checks...\n');

    await validateIngredientReferences();
    await validateDataCompleteness();
    await validateProteinTypes();
    await validateMultiIngredientScenarios();
    await validateQuantitiesAndUnits();

    _printSummary();
  }

  /// Print database statistics
  Future<void> _printDatabaseStats() async {
    print('📊 Database Statistics:');
    print('─────────────────────────────────────────────────────────');

    final recipesCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM recipes')
    ) ?? 0;

    final ingredientsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ingredients')
    ) ?? 0;

    final recipeIngredientsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM recipe_ingredients')
    ) ?? 0;

    final customIngredientsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM recipe_ingredients WHERE ingredient_id IS NULL')
    ) ?? 0;

    print('  Total Recipes: $recipesCount');
    print('  Total Ingredients: $ingredientsCount');
    print('  Total Recipe-Ingredient Links: $recipeIngredientsCount');
    print('  Custom Ingredients: $customIngredientsCount');
  }

  /// Validate ingredient references
  Future<void> validateIngredientReferences() async {
    print('\n1️⃣  Checking Ingredient Relationships...');
    print('─────────────────────────────────────────────────────────');

    // Check for orphaned ingredient references
    final orphanedRefs = await db.rawQuery('''
      SELECT ri.id, ri.recipe_id, ri.ingredient_id
      FROM recipe_ingredients ri
      WHERE ri.ingredient_id IS NOT NULL
        AND NOT EXISTS (
          SELECT 1 FROM ingredients i WHERE i.id = ri.ingredient_id
        )
    ''');

    if (orphanedRefs.isNotEmpty) {
      issues.add(ValidationIssue(
        category: 'Ingredient References',
        severity: 'ERROR',
        message: 'Found ${orphanedRefs.length} orphaned ingredient references',
        details: {'count': orphanedRefs.length, 'sample': orphanedRefs.take(5).toList()},
      ));
      print('  ❌ ERROR: ${orphanedRefs.length} orphaned ingredient references found');
    } else {
      print('  ✅ All ingredient references are valid');
    }

    // Check for recipes with no ingredients
    final recipesWithoutIngredients = await db.rawQuery('''
      SELECT r.id, r.name
      FROM recipes r
      WHERE NOT EXISTS (
        SELECT 1 FROM recipe_ingredients ri WHERE ri.recipe_id = r.id
      )
    ''');

    if (recipesWithoutIngredients.isNotEmpty) {
      issues.add(ValidationIssue(
        category: 'Ingredient References',
        severity: 'WARNING',
        message: 'Found ${recipesWithoutIngredients.length} recipes without ingredients',
        details: {'recipes': recipesWithoutIngredients.map((r) => r['name']).take(5).toList()},
      ));
      print('  ⚠️  WARNING: ${recipesWithoutIngredients.length} recipes have no ingredients');
    } else {
      print('  ✅ All recipes have at least one ingredient');
    }

    // Validate custom ingredients have required fields
    final invalidCustomIngredients = await db.rawQuery('''
      SELECT ri.id, ri.recipe_id
      FROM recipe_ingredients ri
      WHERE ri.ingredient_id IS NULL
        AND (ri.custom_name IS NULL OR ri.custom_name = ''
             OR ri.custom_category IS NULL OR ri.custom_category = '')
    ''');

    if (invalidCustomIngredients.isNotEmpty) {
      issues.add(ValidationIssue(
        category: 'Ingredient References',
        severity: 'ERROR',
        message: 'Found ${invalidCustomIngredients.length} custom ingredients with missing data',
        details: {'count': invalidCustomIngredients.length},
      ));
      print('  ❌ ERROR: ${invalidCustomIngredients.length} custom ingredients missing required fields');
    } else {
      print('  ✅ All custom ingredients have required fields');
    }
  }

  /// Validate data completeness
  Future<void> validateDataCompleteness() async {
    print('\n2️⃣  Checking Data Completeness...');
    print('─────────────────────────────────────────────────────────');

    // Check for recipes with missing required fields
    final recipesWithMissingData = await db.rawQuery('''
      SELECT id, name, difficulty, prep_time, cook_time
      FROM recipes
      WHERE name IS NULL OR name = ''
         OR difficulty IS NULL OR difficulty = ''
         OR prep_time IS NULL OR prep_time <= 0
         OR cook_time IS NULL or cook_time <= 0
    ''');

    if (recipesWithMissingData.isNotEmpty) {
      issues.add(ValidationIssue(
        category: 'Data Completeness',
        severity: 'ERROR',
        message: 'Found ${recipesWithMissingData.length} recipes with missing required fields',
        details: {'count': recipesWithMissingData.length},
      ));
      print('  ❌ ERROR: ${recipesWithMissingData.length} recipes have missing required fields');
    } else {
      print('  ✅ All recipes have required fields');
    }

    // Check for invalid quantities
    final invalidQuantities = await db.rawQuery('''
      SELECT ri.id, ri.recipe_id, ri.quantity
      FROM recipe_ingredients ri
      WHERE ri.quantity IS NULL OR ri.quantity <= 0
    ''');

    if (invalidQuantities.isNotEmpty) {
      issues.add(ValidationIssue(
        category: 'Data Completeness',
        severity: 'ERROR',
        message: 'Found ${invalidQuantities.length} ingredients with invalid quantities',
        details: {'count': invalidQuantities.length},
      ));
      print('  ❌ ERROR: ${invalidQuantities.length} ingredients have invalid quantities');
    } else {
      print('  ✅ All ingredient quantities are valid');
    }

    // Check for recipes without difficulty ratings
    final recipesWithoutDifficulty = await db.rawQuery('''
      SELECT id, name
      FROM recipes
      WHERE difficulty IS NULL OR difficulty = ''
    ''');

    if (recipesWithoutDifficulty.isNotEmpty) {
      issues.add(ValidationIssue(
        category: 'Data Completeness',
        severity: 'WARNING',
        message: 'Found ${recipesWithoutDifficulty.length} recipes without difficulty rating',
        details: {'count': recipesWithoutDifficulty.length},
      ));
      print('  ⚠️  WARNING: ${recipesWithoutDifficulty.length} recipes lack difficulty rating');
    } else {
      print('  ✅ All recipes have difficulty ratings');
    }
  }

  /// Validate protein types
  Future<void> validateProteinTypes() async {
    print('\n3️⃣  Checking Protein Type Consistency...');
    print('─────────────────────────────────────────────────────────');

    // Get all valid protein type names
    final validProteinTypes = ProteinType.values.map((pt) => pt.name).toList();

    // Check for invalid protein types in ingredients
    final invalidProteinTypes = await db.rawQuery('''
      SELECT id, name, protein_type
      FROM ingredients
      WHERE protein_type IS NOT NULL
    ''');

    int invalidCount = 0;
    for (final ingredient in invalidProteinTypes) {
      final proteinType = ingredient['protein_type'] as String?;
      if (proteinType != null && !validProteinTypes.contains(proteinType)) {
        invalidCount++;
        issues.add(ValidationIssue(
          category: 'Protein Types',
          severity: 'ERROR',
          message: 'Invalid protein type found',
          details: {
            'ingredient_id': ingredient['id'],
            'ingredient_name': ingredient['name'],
            'invalid_type': proteinType,
          },
        ));
      }
    }

    if (invalidCount > 0) {
      print('  ❌ ERROR: $invalidCount ingredients with invalid protein types');
    } else {
      print('  ✅ All protein types are valid');
    }

    // Check protein distribution
    final proteinDistribution = await db.rawQuery('''
      SELECT protein_type, COUNT(*) as count
      FROM ingredients
      WHERE protein_type IS NOT NULL
      GROUP BY protein_type
      ORDER BY count DESC
    ''');

    print('  📊 Protein type distribution:');
    for (final row in proteinDistribution) {
      print('     ${row['protein_type']}: ${row['count']}');
    }
  }

  /// Validate multi-ingredient scenarios
  Future<void> validateMultiIngredientScenarios() async {
    print('\n4️⃣  Checking Multi-Ingredient Scenarios...');
    print('─────────────────────────────────────────────────────────');

    // Find recipes with 10+ ingredients
    final complexRecipes = await db.rawQuery('''
      SELECT r.id, r.name, COUNT(ri.id) as ingredient_count
      FROM recipes r
      JOIN recipe_ingredients ri ON r.id = ri.recipe_id
      GROUP BY r.id, r.name
      HAVING COUNT(ri.id) >= 10
      ORDER BY ingredient_count DESC
    ''');

    if (complexRecipes.isNotEmpty) {
      print('  ℹ️  INFO: Found ${complexRecipes.length} recipes with 10+ ingredients');
      print('     Top 5 most complex recipes:');
      for (final recipe in complexRecipes.take(5)) {
        print('     - ${recipe['name']}: ${recipe['ingredient_count']} ingredients');
      }

      issues.add(ValidationIssue(
        category: 'Multi-Ingredient',
        severity: 'INFO',
        message: 'Found ${complexRecipes.length} recipes with 10+ ingredients',
        details: {'top_recipes': complexRecipes.take(5).toList()},
      ));
    } else {
      print('  ℹ️  INFO: No recipes with 10+ ingredients found');
    }

    // Find recipes with multiple protein types
    final multiProteinRecipes = await db.rawQuery('''
      SELECT
        r.id,
        r.name,
        GROUP_CONCAT(DISTINCT i.protein_type) as protein_types,
        COUNT(DISTINCT i.protein_type) as protein_count
      FROM recipes r
      JOIN recipe_ingredients ri ON r.id = ri.recipe_id
      JOIN ingredients i ON ri.ingredient_id = i.id
      WHERE i.protein_type IS NOT NULL
      GROUP BY r.id, r.name
      HAVING COUNT(DISTINCT i.protein_type) > 1
      ORDER BY protein_count DESC
    ''');

    if (multiProteinRecipes.isNotEmpty) {
      print('  ℹ️  INFO: Found ${multiProteinRecipes.length} recipes with multiple protein types');
      print('     Sample recipes:');
      for (final recipe in multiProteinRecipes.take(5)) {
        print('     - ${recipe['name']}: ${recipe['protein_types']}');
      }

      issues.add(ValidationIssue(
        category: 'Multi-Ingredient',
        severity: 'INFO',
        message: 'Found ${multiProteinRecipes.length} recipes with multiple protein types',
        details: {'sample_recipes': multiProteinRecipes.take(5).toList()},
      ));
    } else {
      print('  ℹ️  INFO: All recipes have single or no protein types');
    }

    // Check average ingredients per recipe
    final avgIngredients = await db.rawQuery('''
      SELECT AVG(ingredient_count) as avg_count
      FROM (
        SELECT COUNT(ri.id) as ingredient_count
        FROM recipes r
        LEFT JOIN recipe_ingredients ri ON r.id = ri.recipe_id
        GROUP BY r.id
      )
    ''');

    final avgCount = (avgIngredients.first['avg_count'] as num?)?.toDouble() ?? 0.0;
    print('  📊 Average ingredients per recipe: ${avgCount.toStringAsFixed(2)}');
  }

  /// Validate quantities and units
  Future<void> validateQuantitiesAndUnits() async {
    print('\n5️⃣  Checking Quantities and Units...');
    print('─────────────────────────────────────────────────────────');

    // Get all valid measurement units
    final validUnits = MeasurementUnit.values.map((mu) => mu.value).toList();

    // Check for ingredients with units that don't match enum
    final ingredientsWithUnits = await db.rawQuery('''
      SELECT i.id, i.name, i.unit,
             ri.unit_override, ri.custom_unit
      FROM ingredients i
      LEFT JOIN recipe_ingredients ri ON i.id = ri.ingredient_id
      WHERE i.unit IS NOT NULL OR ri.unit_override IS NOT NULL OR ri.custom_unit IS NOT NULL
    ''');

    int invalidUnitCount = 0;
    for (final row in ingredientsWithUnits) {
      final unit = row['unit'] as String?;
      final unitOverride = row['unit_override'] as String?;
      final customUnit = row['custom_unit'] as String?;

      final unitToCheck = customUnit ?? unitOverride ?? unit;

      if (unitToCheck != null && !validUnits.contains(unitToCheck.toLowerCase())) {
        invalidUnitCount++;
        issues.add(ValidationIssue(
          category: 'Units',
          severity: 'WARNING',
          message: 'Unknown unit found',
          details: {
            'ingredient_name': row['name'],
            'unit': unitToCheck,
          },
        ));
      }
    }

    if (invalidUnitCount > 0) {
      print('  ⚠️  WARNING: $invalidUnitCount ingredients with unknown units');
    } else {
      print('  ✅ All units are valid or null');
    }

    // Check for unrealistic quantities (>10000)
    final unrealisticQuantities = await db.rawQuery('''
      SELECT ri.id, r.name as recipe_name, ri.quantity,
             COALESCE(ri.custom_name, i.name) as ingredient_name
      FROM recipe_ingredients ri
      JOIN recipes r ON ri.recipe_id = r.id
      LEFT JOIN ingredients i ON ri.ingredient_id = i.id
      WHERE ri.quantity > 10000
    ''');

    if (unrealisticQuantities.isNotEmpty) {
      issues.add(ValidationIssue(
        category: 'Quantities',
        severity: 'WARNING',
        message: 'Found ${unrealisticQuantities.length} ingredients with very large quantities (>10000)',
        details: {'sample': unrealisticQuantities.take(5).toList()},
      ));
      print('  ⚠️  WARNING: ${unrealisticQuantities.length} ingredients have very large quantities');
    } else {
      print('  ✅ All quantities appear realistic');
    }

    // Check for very small quantities (<0.01)
    final tinyQuantities = await db.rawQuery('''
      SELECT ri.id, r.name as recipe_name, ri.quantity,
             COALESCE(ri.custom_name, i.name) as ingredient_name
      FROM recipe_ingredients ri
      JOIN recipes r ON ri.recipe_id = r.id
      LEFT JOIN ingredients i ON ri.ingredient_id = i.id
      WHERE ri.quantity < 0.01 AND ri.quantity > 0
    ''');

    if (tinyQuantities.isNotEmpty) {
      print('  ℹ️  INFO: ${tinyQuantities.length} ingredients have very small quantities (<0.01)');
    }
  }

  /// Print validation summary
  void _printSummary() {
    print('\n╔═══════════════════════════════════════════════════════════════╗');
    print('║                    Validation Summary                         ║');
    print('╚═══════════════════════════════════════════════════════════════╝');

    final errorCount = issues.where((i) => i.severity == 'ERROR').length;
    final warningCount = issues.where((i) => i.severity == 'WARNING').length;
    final infoCount = issues.where((i) => i.severity == 'INFO').length;

    print('\n📋 Issue Summary:');
    print('  ❌ Errors: $errorCount');
    print('  ⚠️  Warnings: $warningCount');
    print('  ℹ️  Info: $infoCount');

    if (issues.isNotEmpty) {
      print('\n📝 Detailed Issues:');
      print('─────────────────────────────────────────────────────────');
      for (final issue in issues) {
        print(issue);
        print('');
      }
    }

    print('\n' + '═' * 63);
    if (errorCount == 0 && warningCount == 0) {
      print('✅ VALIDATION PASSED: Data quality is excellent!');
    } else if (errorCount == 0) {
      print('⚠️  VALIDATION PASSED WITH WARNINGS: Minor issues found');
    } else {
      print('❌ VALIDATION FAILED: Critical issues need attention');
    }
    print('═' * 63 + '\n');
  }
}

/// Main function to run validation
Future<void> main() async {
  print('Initializing SQLite for validation...\n');

  // Initialize sqflite_common_ffi for desktop/CLI usage
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Find the database file
  final homeDir = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
  final dbPath = path.join(homeDir, '.local', 'share', 'gastrobrain', 'gastrobrain.db');

  if (!File(dbPath).existsSync()) {
    print('❌ Error: Database not found at: $dbPath');
    print('Please ensure the app has been run at least once to create the database.');
    exit(1);
  }

  print('📂 Database path: $dbPath\n');

  // Open database
  final db = await openDatabase(dbPath, readOnly: true);

  try {
    // Run validation
    final validator = RecipeDataValidator(db);
    await validator.runAllValidations();

    // Exit with appropriate code
    final errorCount = validator.issues.where((i) => i.severity == 'ERROR').length;
    exit(errorCount > 0 ? 1 : 0);
  } finally {
    await db.close();
  }
}
