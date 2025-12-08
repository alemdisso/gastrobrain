import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import '../../database/database_helper.dart';
import '../errors/gastrobrain_exceptions.dart';
import 'recipe_export_service.dart';

/// Service for importing recipe data from JSON format
///
/// This service imports recipes exported by RecipeExportService.
/// It REPLACES all existing recipes and ingredients with the imported data.
///
/// Usage:
/// ```dart
/// final importService = RecipeImportService(databaseHelper);
/// final result = await importService.importRecipesFromJson(filePath);
/// print('Imported ${result.recipesImported} recipes, ${result.ingredientsImported} ingredients');
/// ```
class RecipeImportService {
  final DatabaseHelper _databaseHelper;

  RecipeImportService(this._databaseHelper);

  /// Import recipes from a JSON file, replacing all existing recipes and ingredients
  ///
  /// [filePath] Path to the JSON file to import from.
  ///            Can be a file path or an asset path (starting with 'assets/')
  ///
  /// Returns [RecipeImportResult] with statistics about the import
  Future<RecipeImportResult> importRecipesFromJson(String filePath) async {
    try {
      // Read and parse JSON file
      final jsonString = await _readJsonFile(filePath);
      final List<dynamic> jsonData = json.decode(jsonString);

      // Validate structure
      if (!RecipeExportService.validateExportStructure(jsonData)) {
        throw const GastrobrainException(
            'Invalid JSON format: does not match expected recipe export structure');
      }

      // Get database instance and perform import in a transaction
      final db = await _databaseHelper.database;

      int recipesImported = 0;
      int ingredientsImported = 0;
      final errors = <String>[];

      await db.transaction((txn) async {
        // Step 1: Delete all existing recipes and ingredients
        await txn.delete('recipe_ingredients');
        await txn.delete('recipes');
        await txn.delete('ingredients');

        // Step 2: Collect all unique ingredients from all recipes
        final uniqueIngredients = <String, Map<String, dynamic>>{};

        for (final recipeData in jsonData) {
          final currentIngredients =
              recipeData['current_ingredients'] as List? ?? [];

          for (final ing in currentIngredients) {
            final ingredientId = ing['ingredient_id'] as String?;
            if (ingredientId != null &&
                !uniqueIngredients.containsKey(ingredientId)) {
              uniqueIngredients[ingredientId] = ing as Map<String, dynamic>;
            }
          }
        }

        // Step 3: Import all unique ingredients
        for (final ing in uniqueIngredients.values) {
          try {
            await txn.insert('ingredients', {
              'id': ing['ingredient_id'],
              'name': ing['name'],
              'category': ing['category'],
              'unit': ing['unit'],
              'protein_type': ing['protein_type'],
              'notes': ing['preparation_notes'],
            });
            ingredientsImported++;
          } catch (e) {
            errors.add('Failed to import ingredient ${ing['name']}: $e');
          }
        }

        // Step 4: Import all recipes with their recipe_ingredients
        for (final recipeData in jsonData) {
          try {
            final metadata = recipeData['metadata'] as Map<String, dynamic>;
            final recipeId = recipeData['recipe_id'] as String;

            // Insert recipe
            await txn.insert('recipes', {
              'id': recipeId,
              'name': recipeData['name'],
              'difficulty': metadata['difficulty'],
              'prep_time_minutes': metadata['prep_time_minutes'],
              'cook_time_minutes': metadata['cook_time_minutes'],
              'rating': metadata['rating'],
              'category': metadata['category'],
              'desired_frequency': metadata['desired_frequency'],
              'notes': metadata['notes'] ?? '',
              'instructions': metadata['instructions'] ?? '',
              'created_at': metadata['created_at'],
            });

            // Insert recipe ingredients relationships
            final currentIngredients =
                recipeData['current_ingredients'] as List? ?? [];
            int ingredientCount = 0;
            for (final ing in currentIngredients) {
              try {
                // Generate a unique ID for the recipe_ingredient junction entry
                final riId = _generateUniqueId();
                await txn.insert('recipe_ingredients', {
                  'id': riId,
                  'recipe_id': recipeId,
                  'ingredient_id': ing['ingredient_id'],
                  'quantity': ing['quantity'],
                  'notes': ing['preparation_notes'],
                  'unit_override': ing['unit'],
                  'custom_name': null,
                  'custom_category': null,
                  'custom_unit': null,
                });
                ingredientCount++;
              } catch (e) {
                errors.add(
                    'Failed to import ingredient ${ing['name']} for recipe ${recipeData['name']}: $e');
              }
            }

            if (ingredientCount > 0) {
              recipesImported++;
            }
          } catch (e) {
            errors.add(
                'Failed to import recipe ${recipeData['name']}: $e');
          }
        }
      });

      return RecipeImportResult(
        recipesImported: recipesImported,
        ingredientsImported: ingredientsImported,
        errors: errors,
      );
    } catch (e) {
      throw GastrobrainException('Failed to import recipes: ${e.toString()}');
    }
  }

  /// Read JSON file from either file system or assets
  Future<String> _readJsonFile(String filePath) async {
    if (filePath.startsWith('assets/')) {
      // Read from assets
      return await rootBundle.loadString(filePath);
    } else {
      // Read from file system
      final file = File(filePath);
      if (!await file.exists()) {
        throw GastrobrainException('File not found: $filePath');
      }
      return await file.readAsString();
    }
  }

  /// Generate a unique ID for recipe_ingredient entries
  String _generateUniqueId() {
    // Use timestamp + random component to ensure uniqueness
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final random = (timestamp % 100000).toString().padLeft(5, '0');
    return '${timestamp}_$random';
  }
}

/// Result of a recipe import operation
class RecipeImportResult {
  final int recipesImported;
  final int ingredientsImported;
  final List<String> errors;

  RecipeImportResult({
    required this.recipesImported,
    required this.ingredientsImported,
    required this.errors,
  });

  bool get hasErrors => errors.isNotEmpty;

  String get summary {
    final buffer = StringBuffer();
    buffer.writeln('Recipes imported: $recipesImported');
    buffer.writeln('Ingredients imported: $ingredientsImported');
    if (hasErrors) {
      buffer.writeln('Errors: ${errors.length}');
    }
    return buffer.toString();
  }
}
