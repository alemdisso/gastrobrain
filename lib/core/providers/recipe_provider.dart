import 'package:flutter/foundation.dart';
import '../../models/recipe.dart';
import '../repositories/recipe_repository.dart';
import '../errors/gastrobrain_exceptions.dart';

/// Provider for managing recipe state throughout the application
class RecipeProvider extends ChangeNotifier {
  final RecipeRepository _repository = RecipeRepository();

  // Current state
  List<Recipe> _recipes = [];
  bool _isLoading = false;
  GastrobrainException? _error;
  int _totalRecipeCount = 0;

  // Filter and sort state
  String? _currentSortBy = 'name';
  String? _currentSortOrder = 'ASC';
  Map<String, dynamic> _filters = {};

  // Getters for UI consumption
  List<Recipe> get recipes => List.unmodifiable(_recipes);
  bool get isLoading => _isLoading;
  GastrobrainException? get error => _error;
  bool get hasError => _error != null;
  bool get hasData => _recipes.isNotEmpty;

  // Filter and sort getters
  String? get currentSortBy => _currentSortBy;
  String? get currentSortOrder => _currentSortOrder;
  Map<String, dynamic> get filters => Map.unmodifiable(_filters);

  // Filter state helpers
  bool get hasActiveFilters => _filters.isNotEmpty;
  int get totalRecipeCount => _totalRecipeCount;
  int get filteredRecipeCount => _recipes.length;

  /// Loads all recipes with current filters and sorting
  Future<void> loadRecipes({bool forceRefresh = false}) async {
    if (_isLoading) return; // Prevent multiple simultaneous loads

    _setLoading(true);
    _clearError();

    final result = await _repository.getRecipes(
      sortBy: _currentSortBy,
      sortOrder: _currentSortOrder,
      filters: _filters.isEmpty ? null : _filters,
      forceRefresh: forceRefresh,
    );

    // Also fetch total recipe count (for "X of Y" display)
    _totalRecipeCount = await _repository.getTotalRecipeCount();

    _setLoading(false);

    if (result.isSuccess) {
      _recipes = result.data!;
      _clearError();
    } else if (result.isError) {
      _setError(result.error!);
    }

    notifyListeners();
  }

  /// Gets a single recipe by ID
  Future<Recipe?> getRecipe(String id) async {
    // Check if already in our list
    final existingRecipe = _recipes.where((r) => r.id == id).firstOrNull;
    if (existingRecipe != null) {
      return existingRecipe;
    }

    // Fetch from repository
    final result = await _repository.getRecipe(id);
    if (result.isSuccess) {
      // Update our list if recipe was fetched
      final recipe = result.data!;
      final existingIndex = _recipes.indexWhere((r) => r.id == id);
      if (existingIndex == -1) {
        _recipes.add(recipe);
      } else {
        _recipes[existingIndex] = recipe;
      }
      notifyListeners();
      return recipe;
    } else if (result.isError) {
      _setError(result.error!);
      notifyListeners();
    }

    return null;
  }

  /// Creates a new recipe
  Future<bool> createRecipe(Recipe recipe) async {
    _clearError();
    
    final result = await _repository.createRecipe(recipe);
    
    if (result.isSuccess) {
      _recipes.add(recipe);
      notifyListeners();
      return true;
    } else if (result.isError) {
      _setError(result.error!);
      notifyListeners();
    }
    
    return false;
  }

  /// Updates an existing recipe
  Future<bool> updateRecipe(Recipe recipe) async {
    _clearError();
    
    final result = await _repository.updateRecipe(recipe);
    
    if (result.isSuccess) {
      final index = _recipes.indexWhere((r) => r.id == recipe.id);
      if (index != -1) {
        _recipes[index] = recipe;
        notifyListeners();
      }
      return true;
    } else if (result.isError) {
      _setError(result.error!);
      notifyListeners();
    }
    
    return false;
  }

  /// Deletes a recipe
  Future<bool> deleteRecipe(String id) async {
    _clearError();
    
    final result = await _repository.deleteRecipe(id);
    
    if (result.isSuccess) {
      _recipes.removeWhere((r) => r.id == id);
      notifyListeners();
      return true;
    } else if (result.isError) {
      _setError(result.error!);
      notifyListeners();
    }
    
    return false;
  }

  /// Updates sorting parameters and reloads recipes
  Future<void> setSorting({String? sortBy, String? sortOrder}) async {
    if (sortBy != null) _currentSortBy = sortBy;
    if (sortOrder != null) _currentSortOrder = sortOrder;
    
    await loadRecipes(forceRefresh: true);
  }

  /// Updates filter parameters and reloads recipes
  Future<void> setFilters(Map<String, dynamic> filters) async {
    _filters = Map.from(filters);
    await loadRecipes(forceRefresh: true);
  }

  /// Clears all filters and reloads recipes
  Future<void> clearFilters() async {
    _filters.clear();
    await loadRecipes(forceRefresh: true);
  }

  /// Gets meal count for a specific recipe
  int getMealCount(String recipeId) {
    return _repository.getMealCount(recipeId);
  }

  /// Gets last cooked date for a specific recipe
  DateTime? getLastCookedDate(String recipeId) {
    return _repository.getLastCookedDate(recipeId);
  }

  /// Updates meal statistics for a recipe (called from MealProvider)
  void updateMealStats(String recipeId, int mealCount, DateTime? lastCooked) {
    _repository.updateMealStats(recipeId, mealCount, lastCooked);
    // Notify listeners so UI updates when meal statistics change
    notifyListeners();
  }

  /// Refreshes meal statistics for all recipes from database
  Future<void> refreshMealStats() async {
    await loadRecipes(forceRefresh: true);
  }

  /// Refreshes the cache and reloads all data
  Future<void> refresh() async {
    _repository.invalidateCache();
    await loadRecipes(forceRefresh: true);
  }

  /// Clears error state
  void clearError() {
    _clearError();
    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
    }
  }

  void _setError(GastrobrainException error) {
    _error = error;
  }

  void _clearError() {
    _error = null;
  }

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }
}