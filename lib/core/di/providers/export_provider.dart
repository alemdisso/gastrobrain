import '../../services/recipe_export_service.dart';
import 'database_provider.dart';

/// Provider for export-related services
class ExportProvider {
  static RecipeExportService? _recipeExportService;

  /// Get the recipe export service instance
  RecipeExportService get recipeExport {
    _recipeExportService ??= RecipeExportService(DatabaseProvider().dbHelper);
    return _recipeExportService!;
  }

  /// Reset services (useful for testing)
  static void reset() {
    _recipeExportService = null;
  }
}