import 'dart:convert';
import 'dart:io';
import '../../database/database_helper.dart';
import '../errors/gastrobrain_exceptions.dart';

/// Service for exporting ingredient data to JSON format
/// 
/// Usage:
/// ```dart
/// final exportService = ServiceProvider.export.ingredientExport;
/// final filePath = await exportService.exportIngredientsToJson();
/// print('Ingredients exported to: $filePath');
/// ```
/// 
/// The exported JSON structure includes:
/// - ingredient_id: Unique identifier
/// - name: Ingredient name
/// - category: Ingredient category
/// - unit: Default measurement unit (if any)
/// - protein_type: Protein classification (if applicable)
/// - notes: Additional notes
class IngredientExportService {
  final DatabaseHelper _databaseHelper;

  IngredientExportService(this._databaseHelper);

  /// Export all ingredients to JSON format
  /// 
  /// Returns the path to the exported JSON file
  Future<String> exportIngredientsToJson() async {
    try {
      // Get all ingredients from database
      final ingredients = await _databaseHelper.getAllIngredients();
      
      // Convert ingredients to export format
      final exportData = ingredients.map((ingredient) => {
        'ingredient_id': ingredient.id,
        'name': ingredient.name,
        'category': ingredient.category.value,
        'unit': ingredient.unit?.value,
        'protein_type': ingredient.proteinType?.name,
        'notes': ingredient.notes,
      }).toList();
      
      // Generate JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      
      // Write to file
      final filePath = await _writeJsonToFile(jsonString);
      
      return filePath;
    } catch (e) {
      throw GastrobrainException('Failed to export ingredients: ${e.toString()}');
    }
  }

  /// Write JSON string to file in Downloads directory
  Future<String> _writeJsonToFile(String jsonString) async {
    try {
      // Export to Downloads directory for easy access on device
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'ingredient_export_$timestamp.json';
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
      final requiredFields = ['ingredient_id', 'name', 'category'];
      for (final field in requiredFields) {
        if (!item.containsKey(field)) return false;
      }
      
      // Check that category is not null/empty
      if (item['category'] == null || item['category'].toString().isEmpty) {
        return false;
      }
    }
    
    return true;
  }
}