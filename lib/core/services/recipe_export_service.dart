import 'dart:convert';
import 'dart:io';
import '../../database/database_helper.dart';
import '../errors/gastrobrain_exceptions.dart';

/// Service for exporting recipe data to JSON format for external enhancement
/// 
/// Usage:
/// ```dart
/// final exportService = ServiceProvider.export.recipeExport;
/// final filePath = await exportService.exportRecipesToJson();
/// print('Recipes exported to: $filePath');
/// ```
/// 
/// The exported JSON structure includes:
/// - recipe_id: Unique identifier
/// - name: Recipe name
/// - current_main_ingredient: First ingredient (if any)
/// - enhanced_ingredients: Empty array ready for enhancement
/// - metadata: All recipe metadata (difficulty, times, rating, etc.)
class RecipeExportService {
  final DatabaseHelper _databaseHelper;

  RecipeExportService(this._databaseHelper);

  /// Export all recipes to JSON format ready for multi-ingredient enhancement
  /// 
  /// Returns the path to the exported JSON file
  Future<String> exportRecipesToJson() async {
    try {
      // Get all recipes from database
      final recipes = await _databaseHelper.getAllRecipes();
      
      // Convert recipes to export format
      final exportData = <Map<String, dynamic>>[];
      
      for (final recipe in recipes) {
        // Get current ingredient for the recipe (if any)
        final currentIngredients = await _databaseHelper.getRecipeIngredients(recipe.id);
        final currentMainIngredient = currentIngredients.isNotEmpty 
            ? currentIngredients.first['name'] as String
            : '';

        // Create export structure for each recipe
        final recipeExport = {
          'recipe_id': recipe.id,
          'name': recipe.name,
          'current_main_ingredient': currentMainIngredient,
          'enhanced_ingredients': <Map<String, dynamic>>[],
          'metadata': {
            'difficulty': recipe.difficulty,
            'prep_time_minutes': recipe.prepTimeMinutes,
            'cook_time_minutes': recipe.cookTimeMinutes,
            'rating': recipe.rating,
            'category': recipe.category.value,
            'desired_frequency': recipe.desiredFrequency.value,
            'notes': recipe.notes,
            'created_at': recipe.createdAt.toIso8601String(),
          }
        };
        
        exportData.add(recipeExport);
      }
      
      // Generate JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      
      // Write to file
      final filePath = await _writeJsonToFile(jsonString);
      
      return filePath;
    } catch (e) {
      throw GastrobrainException('Failed to export recipes: ${e.toString()}');
    }
  }

  /// Write JSON string to file in Downloads directory
  Future<String> _writeJsonToFile(String jsonString) async {
    try {
      // Export to Downloads directory for easy access on device
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'recipe_export_$timestamp.json';
      final file = File('/sdcard/Download/$fileName');
      
      // Create Downloads directory if it doesn't exist
      await file.parent.create(recursive: true);
      
      // Write JSON to file
      await file.writeAsString(jsonString);
      
      return file.path;
    } catch (e) {
      throw GastrobrainException('Failed to write export file: ${e.toString()}');
    }
  }

  /// Validate the structure of exported JSON data
  static bool validateExportStructure(List<dynamic> jsonData) {
    if (jsonData.isEmpty) return true; // Empty data is valid
    
    for (final item in jsonData) {
      if (item is! Map<String, dynamic>) return false;
      
      // Check required fields
      final requiredFields = ['recipe_id', 'name', 'current_main_ingredient', 'enhanced_ingredients', 'metadata'];
      for (final field in requiredFields) {
        if (!item.containsKey(field)) return false;
      }
      
      // Check enhanced_ingredients is a list
      if (item['enhanced_ingredients'] is! List) return false;
      
      // Check metadata structure
      final metadata = item['metadata'];
      if (metadata is! Map<String, dynamic>) return false;
      
      final metadataFields = ['difficulty', 'prep_time_minutes', 'cook_time_minutes', 'rating', 'category', 'desired_frequency'];
      for (final field in metadataFields) {
        if (!metadata.containsKey(field)) return false;
      }
    }
    
    return true;
  }
}