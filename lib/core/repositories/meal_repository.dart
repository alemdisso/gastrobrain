import '../../models/meal.dart';
import '../../models/meal_recipe.dart';
import '../../database/database_helper.dart';
import '../errors/gastrobrain_exceptions.dart';
import '../di/service_provider.dart';
import 'base_repository.dart';

/// Repository for managing meal data with caching and state management
class MealRepository extends BaseRepository<List<Meal>> {
  // Private constructor for singleton pattern
  MealRepository._();
  static final MealRepository _instance = MealRepository._();
  factory MealRepository() => _instance;

  // Dependencies
  final DatabaseHelper _dbHelper = ServiceProvider.database.dbHelper;

  // Cache state
  List<Meal> _cachedMeals = [];
  Map<String, List<Meal>> _cachedMealsByRecipe = {};
  bool _isLoading = false;
  GastrobrainException? _lastError;
  DateTime? _lastCacheTime;

  // Cache configuration
  static const Duration _cacheTimeout = Duration(minutes: 5);

  @override
  bool get isLoading => _isLoading;

  @override
  bool get hasData => _cachedMeals.isNotEmpty;

  @override
  GastrobrainException? get lastError => _lastError;

  /// Gets all cached meals
  List<Meal> get meals => List.unmodifiable(_cachedMeals);

  /// Gets meals for a specific recipe
  Future<RepositoryResult<List<Meal>>> getMealsForRecipe(String recipeId, {bool forceRefresh = false}) async {
    try {
      // Check cache validity
      if (!forceRefresh && _isCacheValid() && _cachedMealsByRecipe.containsKey(recipeId)) {
        return RepositoryResult.success(_cachedMealsByRecipe[recipeId]!);
      }

      _isLoading = true;
      _clearError();

      final meals = await _dbHelper.getMealsForRecipe(recipeId);
      
      // Update cache
      _cachedMealsByRecipe[recipeId] = meals;
      _lastCacheTime = DateTime.now();

      _isLoading = false;
      return RepositoryResult.success(meals);

    } on GastrobrainException catch (e) {
      _isLoading = false;
      _lastError = e;
      return RepositoryResult.error(e);
    } catch (e) {
      _isLoading = false;
      final error = GastrobrainException('Failed to load meals for recipe: ${e.toString()}');
      _lastError = error;
      return RepositoryResult.error(error);
    }
  }

  /// Gets a single meal by ID
  Future<RepositoryResult<Meal>> getMeal(String id) async {
    try {
      // Check cache first
      final cachedMeal = _cachedMeals.where((m) => m.id == id).firstOrNull;
      if (cachedMeal != null) {
        return RepositoryResult.success(cachedMeal);
      }

      _clearError();
      final meal = await _dbHelper.getMeal(id);
      
      if (meal == null) {
        throw NotFoundException('Meal with id $id not found');
      }

      // Add to cache if not already present
      final existingIndex = _cachedMeals.indexWhere((m) => m.id == id);
      if (existingIndex == -1) {
        _cachedMeals.add(meal);
      } else {
        _cachedMeals[existingIndex] = meal;
      }

      return RepositoryResult.success(meal);

    } on GastrobrainException catch (e) {
      _lastError = e;
      return RepositoryResult.error(e);
    } catch (e) {
      final error = GastrobrainException('Failed to get meal: ${e.toString()}');
      _lastError = error;
      return RepositoryResult.error(error);
    }
  }

  /// Records a new meal
  Future<RepositoryResult<Meal>> recordMeal(Meal meal) async {
    try {
      _clearError();
      
      final result = await _dbHelper.insertMeal(meal);
      if (result > 0) {
        // Add to cache
        _cachedMeals.add(meal);
        
        // Update recipe-specific cache if it exists
        if (_cachedMealsByRecipe.containsKey(meal.recipeId)) {
          _cachedMealsByRecipe[meal.recipeId]!.add(meal);
        }
        
        return RepositoryResult.success(meal);
      } else {
        throw const GastrobrainException('Failed to record meal');
      }

    } on GastrobrainException catch (e) {
      _lastError = e;
      return RepositoryResult.error(e);
    } catch (e) {
      final error = GastrobrainException('Failed to record meal: ${e.toString()}');
      _lastError = error;
      return RepositoryResult.error(error);
    }
  }

  /// Updates an existing meal
  Future<RepositoryResult<Meal>> updateMeal(Meal meal) async {
    try {
      _clearError();
      
      final result = await _dbHelper.updateMeal(meal);
      if (result > 0) {
        // Update cache
        final index = _cachedMeals.indexWhere((m) => m.id == meal.id);
        if (index != -1) {
          _cachedMeals[index] = meal;
        }
        
        // Update recipe-specific cache if it exists
        if (_cachedMealsByRecipe.containsKey(meal.recipeId)) {
          final recipeIndex = _cachedMealsByRecipe[meal.recipeId]!.indexWhere((m) => m.id == meal.id);
          if (recipeIndex != -1) {
            _cachedMealsByRecipe[meal.recipeId]![recipeIndex] = meal;
          }
        }
        
        return RepositoryResult.success(meal);
      } else {
        throw NotFoundException('Meal not found for update');
      }

    } on GastrobrainException catch (e) {
      _lastError = e;
      return RepositoryResult.error(e);
    } catch (e) {
      final error = GastrobrainException('Failed to update meal: ${e.toString()}');
      _lastError = error;
      return RepositoryResult.error(error);
    }
  }

  /// Deletes a meal
  Future<RepositoryResult<bool>> deleteMeal(String id) async {
    try {
      _clearError();
      
      final result = await _dbHelper.deleteMeal(id);
      if (result > 0) {
        // Remove from cache
        final meal = _cachedMeals.where((m) => m.id == id).firstOrNull;
        _cachedMeals.removeWhere((m) => m.id == id);
        
        // Update recipe-specific cache if it exists
        if (meal != null && _cachedMealsByRecipe.containsKey(meal.recipeId)) {
          _cachedMealsByRecipe[meal.recipeId]!.removeWhere((m) => m.id == id);
        }
        
        return RepositoryResult.success(true);
      } else {
        throw NotFoundException('Meal with id $id not found');
      }

    } on GastrobrainException catch (e) {
      _lastError = e;
      return RepositoryResult.error(e);
    } catch (e) {
      final error = GastrobrainException('Failed to delete meal: ${e.toString()}');
      _lastError = error;
      return RepositoryResult.error(error);
    }
  }

  /// Gets meal recipes for a specific meal
  Future<RepositoryResult<List<MealRecipe>>> getMealRecipes(String mealId) async {
    try {
      _clearError();
      
      final mealRecipes = await _dbHelper.getMealRecipesForMeal(mealId);
      return RepositoryResult.success(mealRecipes);

    } on GastrobrainException catch (e) {
      _lastError = e;
      return RepositoryResult.error(e);
    } catch (e) {
      final error = GastrobrainException('Failed to get meal recipes: ${e.toString()}');
      _lastError = error;
      return RepositoryResult.error(error);
    }
  }

  /// Adds a meal recipe to an existing meal
  Future<RepositoryResult<bool>> addMealRecipe(MealRecipe mealRecipe) async {
    try {
      _clearError();
      
      await _dbHelper.insertMealRecipe(mealRecipe);
      return RepositoryResult.success(true);

    } on GastrobrainException catch (e) {
      _lastError = e;
      return RepositoryResult.error(e);
    } catch (e) {
      final error = const GastrobrainException('Failed to add meal recipe');
      _lastError = error;
      return RepositoryResult.error(error);
    }
  }

  /// Updates a meal recipe
  Future<RepositoryResult<bool>> updateMealRecipe(MealRecipe mealRecipe) async {
    try {
      _clearError();
      
      final result = await _dbHelper.updateMealRecipe(mealRecipe);
      if (result > 0) {
        return RepositoryResult.success(true);
      } else {
        throw const GastrobrainException('Failed to update meal recipe');
      }

    } on GastrobrainException catch (e) {
      _lastError = e;
      return RepositoryResult.error(e);
    } catch (e) {
      final error = const GastrobrainException('Failed to update meal recipe');
      _lastError = error;
      return RepositoryResult.error(error);
    }
  }

  /// Deletes a meal recipe
  Future<RepositoryResult<bool>> deleteMealRecipe(String id) async {
    try {
      _clearError();
      
      final result = await _dbHelper.deleteMealRecipe(id);
      if (result > 0) {
        return RepositoryResult.success(true);
      } else {
        throw const GastrobrainException('Failed to delete meal recipe');
      }

    } on GastrobrainException catch (e) {
      _lastError = e;
      return RepositoryResult.error(e);
    } catch (e) {
      final error = const GastrobrainException('Failed to delete meal recipe');
      _lastError = error;
      return RepositoryResult.error(error);
    }
  }

  @override
  void invalidateCache() {
    _cachedMeals.clear();
    _cachedMealsByRecipe.clear();
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