import 'dart:convert';
import 'package:flutter/services.dart';
import '../di/service_provider.dart';
import '../../models/ingredient.dart';
import '../../models/ingredient_category.dart';
import '../../models/measurement_unit.dart';
import '../../models/protein_type.dart';
import '../errors/gastrobrain_exceptions.dart';

class IngredientTranslationService {
  static const String _translationDataAsset = 'assets/reviewed_ingredients_pt.csv';

  /// Load translation data from CSV asset
  Future<List<Map<String, String>>> _loadTranslationData() async {
    try {
      final csvContent = await rootBundle.loadString(_translationDataAsset);
      final lines = csvContent.split('\n');
      
      if (lines.isEmpty) {
        throw const GastrobrainException('Translation file is empty');
      }
      
      // Skip header line
      final dataLines = lines.skip(1).where((line) => line.trim().isNotEmpty);
      
      final translations = <Map<String, String>>[];
      
      for (final line in dataLines) {
        final parts = line.split(';');
        if (parts.length >= 6) {
          translations.add({
            'id': parts[0].trim(),
            'name': parts[1].trim(),
            'category': parts[2].trim(),
            'unit': parts[3].trim(),
            'protein_type': parts[4].trim(),
            'notes': parts[5].trim(),
          });
        }
      }
      
      return translations;
    } catch (e) {
      throw GastrobrainException('Failed to load translation data: ${e.toString()}');
    }
  }

  /// Translate ingredients from English to Portuguese
  Future<TranslationResult> translateIngredients() async {
    final dbHelper = ServiceProvider.database.dbHelper;
    
    try {
      // Load translation data
      final translations = await _loadTranslationData();
      
      if (translations.isEmpty) {
        throw const GastrobrainException('No translation data found');
      }
      
      int successCount = 0;
      int errorCount = 0;
      final List<String> errors = [];
      
      // Process each translation
      for (final translation in translations) {
        try {
          final id = translation['id']!;
          final name = translation['name']!;
          final categoryStr = translation['category']!;
          final unitStr = translation['unit']!;
          final proteinTypeStr = translation['protein_type']!;
          final notes = translation['notes']!;
          
          // Parse category
          final category = categoryStr.isNotEmpty 
              ? IngredientCategory.fromString(categoryStr)
              : IngredientCategory.other;
          
          // Parse unit
          final unit = unitStr.isNotEmpty 
              ? MeasurementUnit.fromString(unitStr)
              : null;
          
          // Parse protein type
          final proteinType = proteinTypeStr.isNotEmpty
              ? ProteinType.values.firstWhere(
                  (type) => type.name == proteinTypeStr,
                  orElse: () => ProteinType.other,
                )
              : null;
          
          // Create updated ingredient
          final ingredient = Ingredient(
            id: id,
            name: name,
            category: category,
            unit: unit,
            proteinType: proteinType,
            notes: notes.isNotEmpty ? notes : null,
          );
          
          // Update in database
          await dbHelper.updateIngredient(ingredient);
          successCount++;
          
        } catch (e) {
          errorCount++;
          errors.add('Failed to update ${translation['name']}: ${e.toString()}');
        }
      }
      
      return TranslationResult(
        totalProcessed: translations.length,
        successCount: successCount,
        errorCount: errorCount,
        errors: errors,
      );
      
    } catch (e) {
      throw GastrobrainException('Translation failed: ${e.toString()}');
    }
  }

  /// Verify translations by checking sample ingredients
  Future<List<Ingredient>> verifyTranslations() async {
    final dbHelper = ServiceProvider.database.dbHelper;
    
    try {
      // Get all ingredients to verify the translation worked
      final ingredients = await dbHelper.getAllIngredients();
      
      // Return a sample of translated ingredients
      return ingredients.take(10).toList();
      
    } catch (e) {
      throw GastrobrainException('Verification failed: ${e.toString()}');
    }
  }
}

class TranslationResult {
  final int totalProcessed;
  final int successCount;
  final int errorCount;
  final List<String> errors;

  TranslationResult({
    required this.totalProcessed,
    required this.successCount,
    required this.errorCount,
    required this.errors,
  });

  bool get isSuccess => errorCount == 0;
  
  String get summary => 
      'Processed: $totalProcessed, Success: $successCount, Errors: $errorCount';
}