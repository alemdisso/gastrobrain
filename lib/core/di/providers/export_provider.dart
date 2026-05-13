import '../../repositories/tag_repository.dart';
import '../../services/ingredient_export_service.dart';
import '../../services/ingredient_import_service.dart';
import '../../services/recipe_export_service.dart';
import '../../services/recipe_import_service.dart';
import 'database_provider.dart';

/// Provider for export/import services.
class ExportProvider {
  static RecipeExportService? _recipeExportService;
  static IngredientExportService? _ingredientExportService;
  static RecipeImportService? _recipeImportService;
  static IngredientImportService? _ingredientImportService;

  RecipeExportService get recipeExport {
    _recipeExportService ??= RecipeExportService(DatabaseProvider().dbHelper);
    return _recipeExportService!;
  }

  IngredientExportService get ingredientExport {
    _ingredientExportService ??=
        IngredientExportService(DatabaseProvider().dbHelper);
    return _ingredientExportService!;
  }

  RecipeImportService get recipeImport {
    _recipeImportService ??= RecipeImportService(
      DatabaseProvider().dbHelper,
      tagRepository: TagRepository(DatabaseProvider().dbHelper),
    );
    return _recipeImportService!;
  }

  IngredientImportService get ingredientImport {
    _ingredientImportService ??=
        IngredientImportService(DatabaseProvider().dbHelper);
    return _ingredientImportService!;
  }

  /// Reset services (useful for testing).
  static void reset() {
    _recipeExportService = null;
    _ingredientExportService = null;
    _recipeImportService = null;
    _ingredientImportService = null;
  }
}