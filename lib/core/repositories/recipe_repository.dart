import '../../models/recipe.dart';
import '../../database/database_helper.dart';
import '../errors/gastrobrain_exceptions.dart';
import '../di/service_provider.dart';
import 'base_repository.dart';

/// Repository for managing recipe data with caching and state management
class RecipeRepository extends BaseRepository<List<Recipe>> {
  // Private constructor for singleton pattern
  RecipeRepository._();
  static final RecipeRepository _instance = RecipeRepository._();
  factory RecipeRepository() => _instance;

  // Dependencies
  final DatabaseHelper _dbHelper = ServiceProvider.database.dbHelper;

  // Cache state
  List<Recipe> _cachedRecipes = [];
  Map<String, int> _cachedMealCounts = {};
  Map<String, DateTime?> _cachedLastCookedDates = {};
  bool _isLoading = false;
  GastrobrainException? _lastError;
  DateTime? _lastCacheTime;

  // Cache configuration
  static const Duration _cacheTimeout = Duration(minutes: 5);

  @override
  bool get isLoading => _isLoading;

  @override
  bool get hasData => _cachedRecipes.isNotEmpty;

  @override
  GastrobrainException? get lastError => _lastError;

  /// Gets all cached recipes
  List<Recipe> get recipes => List.unmodifiable(_cachedRecipes);

  /// Gets meal count for a specific recipe
  int getMealCount(String recipeId) => _cachedMealCounts[recipeId] ?? 0;

  /// Gets last cooked date for a specific recipe
  DateTime? getLastCookedDate(String recipeId) => _cachedLastCookedDates[recipeId];

  /// Loads all recipes with optional sorting and filtering
  Future<RepositoryResult<List<Recipe>>> getRecipes({
    String? sortBy,
    String? sortOrder,
    Map<String, dynamic>? filters,
    bool forceRefresh = false,
  }) async {
    try {
      // Check cache validity
      if (!forceRefresh && _isCacheValid() && hasData) {
        return RepositoryResult.success(_cachedRecipes);
      }

      _isLoading = true;
      _clearError();

      // Fetch recipes with sorting and filtering
      final recipes = await _dbHelper.getRecipesWithSortAndFilter(
        sortBy: sortBy,
        sortOrder: sortOrder,
        filters: filters,
      );

      // Batch fetch related data for performance
      final mealCounts = await _dbHelper.getAllMealCounts();
      final lastCookedDates = await _dbHelper.getAllLastCooked();

      // Update cache
      _cachedRecipes = recipes;
      _cachedMealCounts = mealCounts;
      _cachedLastCookedDates = lastCookedDates;
      _lastCacheTime = DateTime.now();

      _isLoading = false;
      return RepositoryResult.success(_cachedRecipes);

    } on GastrobrainException catch (e) {
      _isLoading = false;
      _lastError = e;
      return RepositoryResult.error(e);
    } catch (e) {
      _isLoading = false;
      final error = GastrobrainException('Failed to load recipes: ${e.toString()}');
      _lastError = error;
      return RepositoryResult.error(error);
    }
  }

  /// Gets a single recipe by ID
  Future<RepositoryResult<Recipe>> getRecipe(String id) async {
    try {
      // Check cache first
      final cachedRecipe = _cachedRecipes.where((r) => r.id == id).firstOrNull;
      if (cachedRecipe != null) {
        return RepositoryResult.success(cachedRecipe);
      }

      _clearError();
      final recipe = await _dbHelper.getRecipe(id);
      
      if (recipe == null) {
        throw NotFoundException('Recipe with id $id not found');
      }

      // Add to cache if not already present
      final existingIndex = _cachedRecipes.indexWhere((r) => r.id == id);
      if (existingIndex == -1) {
        _cachedRecipes.add(recipe);
      } else {
        _cachedRecipes[existingIndex] = recipe;
      }

      return RepositoryResult.success(recipe);

    } on GastrobrainException catch (e) {
      _lastError = e;
      return RepositoryResult.error(e);
    } catch (e) {
      final error = GastrobrainException('Failed to get recipe: ${e.toString()}');
      _lastError = error;
      return RepositoryResult.error(error);
    }
  }

  /// Creates a new recipe
  Future<RepositoryResult<Recipe>> createRecipe(Recipe recipe) async {
    try {
      _clearError();
      
      final result = await _dbHelper.insertRecipe(recipe);
      if (result > 0) {
        // Add to cache
        _cachedRecipes.add(recipe);
        _cachedMealCounts[recipe.id] = 0; // New recipe has no meals yet
        _cachedLastCookedDates[recipe.id] = null;
        
        return RepositoryResult.success(recipe);
      } else {
        throw const GastrobrainException('Failed to create recipe');
      }

    } on GastrobrainException catch (e) {
      _lastError = e;
      return RepositoryResult.error(e);
    } catch (e) {
      final error = GastrobrainException('Failed to create recipe: ${e.toString()}');
      _lastError = error;
      return RepositoryResult.error(error);
    }
  }

  /// Updates an existing recipe
  Future<RepositoryResult<Recipe>> updateRecipe(Recipe recipe) async {
    try {
      _clearError();
      
      final result = await _dbHelper.updateRecipe(recipe);
      if (result > 0) {
        // Update cache
        final index = _cachedRecipes.indexWhere((r) => r.id == recipe.id);
        if (index != -1) {
          _cachedRecipes[index] = recipe;
        }
        
        return RepositoryResult.success(recipe);
      } else {
        throw NotFoundException('Recipe not found for update');
      }

    } on GastrobrainException catch (e) {
      _lastError = e;
      return RepositoryResult.error(e);
    } catch (e) {
      final error = GastrobrainException('Failed to update recipe: ${e.toString()}');
      _lastError = error;
      return RepositoryResult.error(error);
    }
  }

  /// Deletes a recipe
  Future<RepositoryResult<bool>> deleteRecipe(String id) async {
    try {
      _clearError();
      
      final result = await _dbHelper.deleteRecipe(id);
      if (result > 0) {
        // Remove from cache
        _cachedRecipes.removeWhere((r) => r.id == id);
        _cachedMealCounts.remove(id);
        _cachedLastCookedDates.remove(id);
        
        return RepositoryResult.success(true);
      } else {
        throw NotFoundException('Recipe with id $id not found');
      }

    } on GastrobrainException catch (e) {
      _lastError = e;
      return RepositoryResult.error(e);
    } catch (e) {
      final error = GastrobrainException('Failed to delete recipe: ${e.toString()}');
      _lastError = error;
      return RepositoryResult.error(error);
    }
  }

  /// Updates meal statistics for a recipe (called when meals are added/removed)
  void updateMealStats(String recipeId, int mealCount, DateTime? lastCooked) {
    _cachedMealCounts[recipeId] = mealCount;
    _cachedLastCookedDates[recipeId] = lastCooked;
  }

  @override
  void invalidateCache() {
    _cachedRecipes.clear();
    _cachedMealCounts.clear();
    _cachedLastCookedDates.clear();
    _lastCacheTime = null;
  }

  @override
  void clearError() {
    _clearError();
  }

  // Private helper methods
  bool _isCacheValid() {
    if (_lastCacheTime == null) return false;
    return DateTime.now().difference(_lastCacheTime!) < _cacheTimeout;
  }

  void _clearError() {
    _lastError = null;
  }
}