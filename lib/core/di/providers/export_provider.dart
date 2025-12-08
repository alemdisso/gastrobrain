import '../../services/recipe_export_service.dart';
import '../../services/ingredient_export_service.dart';
import '../../services/recipe_import_service.dart';
import 'database_provider.dart';

/// Provider for export-related services
class ExportProvider {
  static RecipeExportService? _recipeExportService;
  static IngredientExportService? _ingredientExportService;
  static RecipeImportService? _recipeImportService;

  /// Get the recipe export service instance
  RecipeExportService get recipeExport {
    _recipeExportService ??= RecipeExportService(DatabaseProvider().dbHelper);
    return _recipeExportService!;
  }

  /// Get the ingredient export service instance
  IngredientExportService get ingredientExport {
    _ingredientExportService ??= IngredientExportService(DatabaseProvider().dbHelper);
    return _ingredientExportService!;
  }

  /// Get the recipe import service instance
  RecipeImportService get recipeImport {
    _recipeImportService ??= RecipeImportService(DatabaseProvider().dbHelper);
    return _recipeImportService!;
  }

  /// Reset services (useful for testing)
  static void reset() {
    _recipeExportService = null;
    _ingredientExportService = null;
    _recipeImportService = null;
  }
}