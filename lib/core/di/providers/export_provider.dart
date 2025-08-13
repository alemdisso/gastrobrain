import '../../services/recipe_export_service.dart';
import '../../services/ingredient_export_service.dart';
import 'database_provider.dart';

/// Provider for export-related services
class ExportProvider {
  static RecipeExportService? _recipeExportService;
  static IngredientExportService? _ingredientExportService;

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

  /// Reset services (useful for testing)
  static void reset() {
    _recipeExportService = null;
    _ingredientExportService = null;
  }
}