import 'dart:convert';
import 'dart:io';
import '../../database/database_helper.dart';
import '../errors/gastrobrain_exceptions.dart';
import '../repositories/tag_repository.dart';

/// Service for exporting recipe data to JSON format.
///
/// Export format version history:
///   v1 — original (no tags, no quantity_max, no servings)
///   v2 — adds tags array, quantity_max per ingredient, servings in metadata
class RecipeExportService {
  final DatabaseHelper _databaseHelper;
  final TagRepository _tagRepository;

  RecipeExportService(this._databaseHelper, {TagRepository? tagRepository})
      : _tagRepository = tagRepository ?? TagRepository(_databaseHelper);

  /// Export all recipes to JSON (v2 format).
  ///
  /// Returns the path to the exported file.
  Future<String> exportRecipesToJson() async {
    try {
      final recipes = await _databaseHelper.getAllRecipes();
      final exportData = <Map<String, dynamic>>[];

      for (final recipe in recipes) {
        final currentIngredients =
            await _databaseHelper.getRecipeIngredients(recipe.id);
        final tags = await _tagRepository.getTagsForRecipe(recipe.id);
        final lastCookedDate =
            await _databaseHelper.getLastCookedDate(recipe.id);
        final timesCookedCount =
            await _databaseHelper.getTimesCookedCount(recipe.id);

        final currentIngredientsData = currentIngredients.map((ing) => {
              'ingredient_id': ing['ingredient_id'],
              'name': ing['name'],
              'quantity': ing['quantity'],
              'quantity_max': ing['quantity_max'],
              'unit': ing['unit'],
              'category': ing['category'],
              'protein_type': ing['protein_type'],
              'preparation_notes': ing['preparation_notes'],
            }).toList();

        exportData.add({
          'export_version': 2,
          'recipe_id': recipe.id,
          'name': recipe.name,
          'instructions': recipe.instructions,
          'current_ingredients': currentIngredientsData,
          'enhanced_ingredients': <Map<String, dynamic>>[],
          'metadata': {
            'difficulty': recipe.difficulty,
            'prep_time_minutes': recipe.prepTimeMinutes,
            'cook_time_minutes': recipe.cookTimeMinutes,
            'marinating_time_minutes': recipe.marinatingTimeMinutes,
            'rating': recipe.rating,
            'servings': recipe.servings,
            'desired_frequency': recipe.desiredFrequency.value,
            'notes': recipe.notes,
            'created_at': recipe.createdAt.toIso8601String(),
          },
          'cooking_history': {
            'times_cooked': timesCookedCount,
            'last_cooked_date': lastCookedDate?.toIso8601String(),
          },
          'tags': tags
              .map((t) => {'type': t.typeId, 'name': t.name})
              .toList(),
        });
      }

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      return await _writeJsonToFile(jsonString);
    } catch (e) {
      throw GastrobrainException('Failed to export recipes: ${e.toString()}');
    }
  }

  Future<String> _writeJsonToFile(String jsonString) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'recipe_export_$timestamp.json';
      final file = File('/sdcard/Download/$fileName');
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonString);
      return file.path;
    } catch (e) {
      throw GastrobrainException('Failed to write export file: ${e.toString()}');
    }
  }

  /// Validate a parsed JSON list as a recipe export file.
  ///
  /// Accepts both v1 and v2 formats — tags and quantity_max are optional.
  static bool validateExportStructure(List<dynamic> jsonData) {
    if (jsonData.isEmpty) return true;

    for (final item in jsonData) {
      if (item is! Map<String, dynamic>) return false;

      for (final field in const [
        'recipe_id',
        'name',
        'current_ingredients',
        'enhanced_ingredients',
        'metadata',
        'cooking_history',
      ]) {
        if (!item.containsKey(field)) return false;
      }

      if (item['current_ingredients'] is! List) return false;
      if (item['enhanced_ingredients'] is! List) return false;

      final metadata = item['metadata'];
      if (metadata is! Map<String, dynamic>) return false;
      for (final field in const [
        'difficulty',
        'prep_time_minutes',
        'cook_time_minutes',
        'rating',
        'desired_frequency',
      ]) {
        if (!metadata.containsKey(field)) return false;
      }

      final cookingHistory = item['cooking_history'];
      if (cookingHistory is! Map<String, dynamic>) return false;
      for (final field in const ['times_cooked', 'last_cooked_date']) {
        if (!cookingHistory.containsKey(field)) return false;
      }

      // tags is optional (absent in v1 exports)
      if (item.containsKey('tags') && item['tags'] is! List) return false;
    }

    return true;
  }
}
