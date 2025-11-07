// validate_recipe_export.dart
// Comprehensive validation script for enhanced recipe export data quality
// Validates ingredient relationships, data completeness, protein types, and multi-ingredient scenarios

// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:convert';

// Valid protein types (from ProteinType enum)
const validProteinTypes = [
  'beef',
  'chicken',
  'pork',
  'fish',
  'seafood',
  'lamb',
  'charcuterie',
  'offal',
  'plantBased',
  'other',
];

// Valid measurement units (from MeasurementUnit enum)
const validMeasurementUnits = [
  'g',
  'kg',
  'ml',
  'l',
  'cup',
  'tbsp',
  'tsp',
  'piece',
  'slice',
  'bunch',
  'leaves',
  'pinch',
  'clove',
  'head',
  'can',
  'box',
  'stem',
  'sprig',
  'seed',
  'grain',
  'cm',
];

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
class RecipeExportValidator {
  final List<Map<String, dynamic>> recipes;
  final List<ValidationIssue> issues = [];

  RecipeExportValidator(this.recipes);

  /// Run all validation checks
  void runAllValidations() {
    print('╔═══════════════════════════════════════════════════════════════╗');
    print('║      Recipe Export Data Validation Report                    ║');
    print('╚═══════════════════════════════════════════════════════════════╝\n');

    _printDataStats();

    print('\n▶ Running validation checks...\n');

    validateIngredientData();
    validateDataCompleteness();
    validateProteinTypes();
    validateMultiIngredientScenarios();
    validateQuantitiesAndUnits();

    _printSummary();
  }

  /// Print data statistics
  void _printDataStats() {
    print('📊 Export Data Statistics:');
    print('─────────────────────────────────────────────────────────');

    final totalRecipes = recipes.length;
    int totalIngredients = 0;
    int totalEnhancedIngredients = 0;

    for (final recipe in recipes) {
      final currentIngredients = recipe['current_ingredients'] as List? ?? [];
      final enhancedIngredients = recipe['enhanced_ingredients'] as List? ?? [];
      totalIngredients += currentIngredients.length;
      totalEnhancedIngredients += enhancedIngredients.length;
    }

    print('  Total Recipes: $totalRecipes');
    print('  Total Current Ingredients: $totalIngredients');
    print('  Total Enhanced Ingredients: $totalEnhancedIngredients');
    print('  Average Ingredients per Recipe: ${(totalIngredients / totalRecipes).toStringAsFixed(2)}');
  }

  /// Validate ingredient data quality
  void validateIngredientData() {
    print('\n1️⃣  Checking Ingredient Data Quality...');
    print('─────────────────────────────────────────────────────────');

    int recipesWithoutIngredients = 0;
    int ingredientsWithoutId = 0;
    int ingredientsWithoutName = 0;

    for (final recipe in recipes) {
      final recipeName = recipe['name'] as String;
      final currentIngredients = recipe['current_ingredients'] as List? ?? [];

      // Check recipes without ingredients
      if (currentIngredients.isEmpty) {
        recipesWithoutIngredients++;
        issues.add(ValidationIssue(
          category: 'Ingredient Data',
          severity: 'WARNING',
          message: 'Recipe has no ingredients',
          details: {'recipe_name': recipeName},
        ));
      }

      // Check ingredient data quality
      for (final ingredient in currentIngredients) {
        if (ingredient['ingredient_id'] == null) {
          ingredientsWithoutId++;
        }

        if (ingredient['name'] == null || (ingredient['name'] as String).isEmpty) {
          ingredientsWithoutName++;
          issues.add(ValidationIssue(
            category: 'Ingredient Data',
            severity: 'ERROR',
            message: 'Ingredient missing name',
            details: {'recipe': recipeName, 'ingredient': ingredient},
          ));
        }
      }
    }

    if (recipesWithoutIngredients > 0) {
      print('  ⚠️  WARNING: $recipesWithoutIngredients recipes have no ingredients');
    } else {
      print('  ✅ All recipes have at least one ingredient');
    }

    if (ingredientsWithoutId > 0) {
      print('  ℹ️  INFO: $ingredientsWithoutId custom ingredients (no ingredient_id)');
    }

    if (ingredientsWithoutName > 0) {
      print('  ❌ ERROR: $ingredientsWithoutName ingredients missing names');
    } else {
      print('  ✅ All ingredients have names');
    }
  }

  /// Validate data completeness
  void validateDataCompleteness() {
    print('\n2️⃣  Checking Data Completeness...');
    print('─────────────────────────────────────────────────────────');

    int missingMetadata = 0;
    int invalidQuantities = 0;
    int missingDifficulty = 0;
    int missingTimes = 0;

    for (final recipe in recipes) {
      final recipeName = recipe['name'] as String;
      final metadata = recipe['metadata'] as Map<String, dynamic>?;
      final currentIngredients = recipe['current_ingredients'] as List? ?? [];

      // Check metadata
      if (metadata == null) {
        missingMetadata++;
        continue;
      }

      if (metadata['difficulty'] == null) {
        missingDifficulty++;
      }

      if (metadata['prep_time_minutes'] == null || metadata['cook_time_minutes'] == null) {
        missingTimes++;
      }

      // Check quantities
      for (final ingredient in currentIngredients) {
        final quantity = ingredient['quantity'];
        if (quantity == null || (quantity is num && quantity < 0)) {
          invalidQuantities++;
          issues.add(ValidationIssue(
            category: 'Data Completeness',
            severity: 'ERROR',
            message: 'Invalid ingredient quantity',
            details: {
              'recipe': recipeName,
              'ingredient': ingredient['name'],
              'quantity': quantity,
            },
          ));
        }
      }
    }

    if (missingMetadata > 0) {
      print('  ❌ ERROR: $missingMetadata recipes missing metadata');
    } else {
      print('  ✅ All recipes have metadata');
    }

    if (missingDifficulty > 0) {
      print('  ⚠️  WARNING: $missingDifficulty recipes missing difficulty rating');
    } else {
      print('  ✅ All recipes have difficulty ratings');
    }

    if (missingTimes > 0) {
      print('  ⚠️  WARNING: $missingTimes recipes missing time information');
    } else {
      print('  ✅ All recipes have prep/cook times');
    }

    if (invalidQuantities > 0) {
      print('  ❌ ERROR: $invalidQuantities ingredients with invalid quantities');
    } else {
      print('  ✅ All ingredient quantities are valid');
    }
  }

  /// Validate protein types
  void validateProteinTypes() {
    print('\n3️⃣  Checking Protein Type Consistency...');
    print('─────────────────────────────────────────────────────────');

    int invalidProteinCount = 0;
    final proteinDistribution = <String, int>{};

    for (final recipe in recipes) {
      final currentIngredients = recipe['current_ingredients'] as List? ?? [];

      for (final ingredient in currentIngredients) {
        final proteinType = ingredient['protein_type'] as String?;

        if (proteinType != null) {
          // Count distribution
          proteinDistribution[proteinType] = (proteinDistribution[proteinType] ?? 0) + 1;

          // Validate against enum
          if (!validProteinTypes.contains(proteinType)) {
            invalidProteinCount++;
            issues.add(ValidationIssue(
              category: 'Protein Types',
              severity: 'ERROR',
              message: 'Invalid protein type',
              details: {
                'recipe': recipe['name'],
                'ingredient': ingredient['name'],
                'invalid_type': proteinType,
              },
            ));
          }
        }
      }
    }

    if (invalidProteinCount > 0) {
      print('  ❌ ERROR: $invalidProteinCount ingredients with invalid protein types');
    } else {
      print('  ✅ All protein types are valid');
    }

    if (proteinDistribution.isNotEmpty) {
      print('  📊 Protein type distribution:');
      final sorted = proteinDistribution.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final entry in sorted) {
        print('     ${entry.key}: ${entry.value}');
      }
    }
  }

  /// Validate multi-ingredient scenarios
  void validateMultiIngredientScenarios() {
    print('\n4️⃣  Checking Multi-Ingredient Scenarios...');
    print('─────────────────────────────────────────────────────────');

    final complexRecipes = <Map<String, dynamic>>[];
    final multiProteinRecipes = <Map<String, dynamic>>[];

    for (final recipe in recipes) {
      final recipeName = recipe['name'] as String;
      final currentIngredients = recipe['current_ingredients'] as List? ?? [];
      final ingredientCount = currentIngredients.length;

      // Find recipes with 10+ ingredients
      if (ingredientCount >= 10) {
        complexRecipes.add({
          'name': recipeName,
          'count': ingredientCount,
        });
      }

      // Find recipes with multiple protein types
      final proteins = <String>{};
      for (final ingredient in currentIngredients) {
        final proteinType = ingredient['protein_type'] as String?;
        if (proteinType != null) {
          proteins.add(proteinType);
        }
      }

      if (proteins.length > 1) {
        multiProteinRecipes.add({
          'name': recipeName,
          'proteins': proteins.toList(),
          'count': proteins.length,
        });
      }
    }

    if (complexRecipes.isNotEmpty) {
      complexRecipes.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
      print('  ℹ️  INFO: Found ${complexRecipes.length} recipes with 10+ ingredients');
      print('     Top 5 most complex recipes:');
      for (final recipe in complexRecipes.take(5)) {
        print('     - ${recipe['name']}: ${recipe['count']} ingredients');
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

    if (multiProteinRecipes.isNotEmpty) {
      multiProteinRecipes.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
      print('  ℹ️  INFO: Found ${multiProteinRecipes.length} recipes with multiple protein types');
      print('     Sample recipes:');
      for (final recipe in multiProteinRecipes.take(5)) {
        print('     - ${recipe['name']}: ${recipe['proteins']}');
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
  }

  /// Validate quantities and units
  void validateQuantitiesAndUnits() {
    print('\n5️⃣  Checking Quantities and Units...');
    print('─────────────────────────────────────────────────────────');

    int invalidUnitCount = 0;
    int unrealisticQuantities = 0;
    int zeroQuantities = 0;

    for (final recipe in recipes) {
      final recipeName = recipe['name'] as String;
      final currentIngredients = recipe['current_ingredients'] as List? ?? [];

      for (final ingredient in currentIngredients) {
        final unit = ingredient['unit'] as String?;
        final quantity = ingredient['quantity'];
        final ingredientName = ingredient['name'] as String;

        // Validate units
        if (unit != null && !validMeasurementUnits.contains(unit.toLowerCase())) {
          invalidUnitCount++;
          issues.add(ValidationIssue(
            category: 'Units',
            severity: 'WARNING',
            message: 'Unknown measurement unit',
            details: {
              'recipe': recipeName,
              'ingredient': ingredientName,
              'unit': unit,
            },
          ));
        }

        // Check quantities
        if (quantity is num) {
          if (quantity == 0) {
            zeroQuantities++;
          } else if (quantity > 10000) {
            unrealisticQuantities++;
            issues.add(ValidationIssue(
              category: 'Quantities',
              severity: 'WARNING',
              message: 'Very large quantity detected',
              details: {
                'recipe': recipeName,
                'ingredient': ingredientName,
                'quantity': quantity,
              },
            ));
          }
        }
      }
    }

    if (invalidUnitCount > 0) {
      print('  ⚠️  WARNING: $invalidUnitCount ingredients with unknown units');
    } else {
      print('  ✅ All units are valid or null');
    }

    if (zeroQuantities > 0) {
      print('  ℹ️  INFO: $zeroQuantities ingredients with zero quantity (likely "to taste")');
    }

    if (unrealisticQuantities > 0) {
      print('  ⚠️  WARNING: $unrealisticQuantities ingredients with very large quantities (>10000)');
    } else {
      print('  ✅ All quantities appear realistic');
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

      // Show errors first, then warnings, then info
      final sortedIssues = [...issues];
      sortedIssues.sort((a, b) {
        final severityOrder = {'ERROR': 0, 'WARNING': 1, 'INFO': 2};
        return severityOrder[a.severity]!.compareTo(severityOrder[b.severity]!);
      });

      // Limit detailed output to first 20 issues
      for (final issue in sortedIssues.take(20)) {
        print(issue);
        print('');
      }

      if (sortedIssues.length > 20) {
        print('... and ${sortedIssues.length - 20} more issues\n');
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
Future<void> main(List<String> arguments) async {
  print('Recipe Export Validation Tool\n');

  // Determine export file path
  String exportPath;

  if (arguments.isNotEmpty) {
    exportPath = arguments[0];
  } else {
    exportPath = 'assets/recipe_export_1762460315862.json';
  }

  final exportFile = File(exportPath);

  if (!exportFile.existsSync()) {
    print('❌ Error: Export file not found at: $exportPath\n');
    print('Usage: dart validate_recipe_export.dart [export_file_path]');
    print('\nExample:');
    print('  dart validate_recipe_export.dart assets/recipe_export_1762460315862.json');
    exit(1);
  }

  print('📂 Export file: $exportPath\n');
  print('📖 Loading export data...\n');

  // Load and parse JSON
  final jsonString = await exportFile.readAsString();
  final List<dynamic> recipesJson = json.decode(jsonString) as List<dynamic>;
  final recipes = recipesJson.cast<Map<String, dynamic>>();

  print('✅ Loaded ${recipes.length} recipes\n');

  // Run validation
  final validator = RecipeExportValidator(recipes);
  validator.runAllValidations();

  // Exit with appropriate code
  final errorCount = validator.issues.where((i) => i.severity == 'ERROR').length;
  exit(errorCount > 0 ? 1 : 0);
}
