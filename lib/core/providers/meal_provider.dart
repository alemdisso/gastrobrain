import 'package:flutter/foundation.dart';
import '../../models/meal.dart';
import '../../models/meal_recipe.dart';
import '../repositories/meal_repository.dart';
import '../errors/gastrobrain_exceptions.dart';

/// Provider for managing meal state throughout the application
class MealProvider extends ChangeNotifier {
  final MealRepository _repository = MealRepository();

  // Current state
  List<Meal> _meals = [];
  Map<String, List<Meal>> _mealsByRecipe = {};
  bool _isLoading = false;
  GastrobrainException? _error;

  // Getters for UI consumption
  List<Meal> get meals => List.unmodifiable(_meals);
  bool get isLoading => _isLoading;
  GastrobrainException? get error => _error;
  bool get hasError => _error != null;
  bool get hasData => _meals.isNotEmpty;

  /// Gets meals for a specific recipe
  List<Meal> getMealsForRecipe(String recipeId) {
    return List.unmodifiable(_mealsByRecipe[recipeId] ?? []);
  }

  /// Loads meals for a specific recipe
  Future<void> loadMealsForRecipe(String recipeId, {bool forceRefresh = false}) async {
    if (_isLoading) return; // Prevent multiple simultaneous loads

    _setLoading(true);
    _clearError();

    final result = await _repository.getMealsForRecipe(recipeId, forceRefresh: forceRefresh);

    _setLoading(false);

    if (result.isSuccess) {
      _mealsByRecipe[recipeId] = result.data!;
      _clearError();
    } else if (result.isError) {
      _setError(result.error!);
    }

    notifyListeners();
  }

  /// Gets a single meal by ID
  Future<Meal?> getMeal(String id) async {
    // Check if already in our list
    final existingMeal = _meals.where((m) => m.id == id).firstOrNull;
    if (existingMeal != null) {
      return existingMeal;
    }

    // Fetch from repository
    final result = await _repository.getMeal(id);
    if (result.isSuccess) {
      final meal = result.data!;
      // Update our list if meal was fetched
      final existingIndex = _meals.indexWhere((m) => m.id == id);
      if (existingIndex == -1) {
        _meals.add(meal);
      } else {
        _meals[existingIndex] = meal;
      }
      notifyListeners();
      return meal;
    } else if (result.isError) {
      _setError(result.error!);
      notifyListeners();
    }

    return null;
  }

  /// Records a new meal
  Future<bool> recordMeal(Meal meal) async {
    _clearError();
    
    final result = await _repository.recordMeal(meal);
    
    if (result.isSuccess) {
      _meals.add(meal);
      
      // Update recipe-specific cache
      if (_mealsByRecipe.containsKey(meal.recipeId)) {
        _mealsByRecipe[meal.recipeId]!.add(meal);
      }
      
      notifyListeners();
      return true;
    } else if (result.isError) {
      _setError(result.error!);
      notifyListeners();
    }
    
    return false;
  }

  /// Updates an existing meal
  Future<bool> updateMeal(Meal meal) async {
    _clearError();
    
    final result = await _repository.updateMeal(meal);
    
    if (result.isSuccess) {
      // Update main meals list
      final index = _meals.indexWhere((m) => m.id == meal.id);
      if (index != -1) {
        _meals[index] = meal;
      }
      
      // Update recipe-specific cache
      if (_mealsByRecipe.containsKey(meal.recipeId)) {
        final recipeIndex = _mealsByRecipe[meal.recipeId]!.indexWhere((m) => m.id == meal.id);
        if (recipeIndex != -1) {
          _mealsByRecipe[meal.recipeId]![recipeIndex] = meal;
        }
      }
      
      notifyListeners();
      return true;
    } else if (result.isError) {
      _setError(result.error!);
      notifyListeners();
    }
    
    return false;
  }

  /// Deletes a meal
  Future<bool> deleteMeal(String id) async {
    _clearError();
    
    // Find the meal to get recipeId before deletion
    final meal = _meals.where((m) => m.id == id).firstOrNull;
    
    final result = await _repository.deleteMeal(id);
    
    if (result.isSuccess) {
      _meals.removeWhere((m) => m.id == id);
      
      // Update recipe-specific cache
      if (meal != null && _mealsByRecipe.containsKey(meal.recipeId)) {
        _mealsByRecipe[meal.recipeId]!.removeWhere((m) => m.id == id);
      }
      
      notifyListeners();
      return true;
    } else if (result.isError) {
      _setError(result.error!);
      notifyListeners();
    }
    
    return false;
  }

  /// Gets meal recipes for a specific meal
  Future<List<MealRecipe>?> getMealRecipes(String mealId) async {
    _clearError();
    
    final result = await _repository.getMealRecipes(mealId);
    
    if (result.isSuccess) {
      return result.data!;
    } else if (result.isError) {
      _setError(result.error!);
      notifyListeners();
    }
    
    return null;
  }

  /// Adds a meal recipe
  Future<bool> addMealRecipe(MealRecipe mealRecipe) async {
    _clearError();
    
    final result = await _repository.addMealRecipe(mealRecipe);
    
    if (result.isSuccess) {
      notifyListeners();
      return true;
    } else if (result.isError) {
      _setError(result.error!);
      notifyListeners();
    }
    
    return false;
  }

  /// Updates a meal recipe
  Future<bool> updateMealRecipe(MealRecipe mealRecipe) async {
    _clearError();
    
    final result = await _repository.updateMealRecipe(mealRecipe);
    
    if (result.isSuccess) {
      notifyListeners();
      return true;
    } else if (result.isError) {
      _setError(result.error!);
      notifyListeners();
    }
    
    return false;
  }

  /// Deletes a meal recipe
  Future<bool> deleteMealRecipe(String id) async {
    _clearError();
    
    final result = await _repository.deleteMealRecipe(id);
    
    if (result.isSuccess) {
      notifyListeners();
      return true;
    } else if (result.isError) {
      _setError(result.error!);
      notifyListeners();
    }
    
    return false;
  }

  /// Refreshes the cache and reloads all data
  Future<void> refresh() async {
    _repository.invalidateCache();
    // Clear local cache
    _meals.clear();
    _mealsByRecipe.clear();
    notifyListeners();
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