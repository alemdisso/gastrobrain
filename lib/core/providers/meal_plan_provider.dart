import 'package:flutter/foundation.dart';
import '../../models/meal_plan.dart';
import '../../models/meal_plan_item.dart';
import '../repositories/meal_plan_repository.dart';
import '../errors/gastrobrain_exceptions.dart';

/// Provider for managing meal plan state throughout the application
class MealPlanProvider extends ChangeNotifier {
  final MealPlanRepository _repository = MealPlanRepository();

  // Current state
  MealPlan? _currentMealPlan;
  List<MealPlanItem> _mealPlanItems = [];
  DateTime _currentWeekStart = _getFridayOfWeek(DateTime.now());
  bool _isLoading = false;
  GastrobrainException? _error;

  // Getters for UI consumption
  MealPlan? get currentMealPlan => _currentMealPlan;
  List<MealPlanItem> get mealPlanItems => List.unmodifiable(_mealPlanItems);
  DateTime get currentWeekStart => _currentWeekStart;
  bool get isLoading => _isLoading;
  GastrobrainException? get error => _error;
  bool get hasError => _error != null;
  bool get hasData => _currentMealPlan != null || _mealPlanItems.isNotEmpty;

  /// Gets meal plan items for a specific date
  List<MealPlanItem> getMealPlanItemsForDate(DateTime date) {
    final dateString = MealPlanItem.formatPlannedDate(date);
    return _mealPlanItems.where((item) => item.plannedDate == dateString).toList();
  }

  /// Loads meal plan for current week
  Future<void> loadMealPlanForCurrentWeek({bool forceRefresh = false}) async {
    if (_isLoading) return; // Prevent multiple simultaneous loads

    _setLoading(true);
    _clearError();

    final result = await _repository.getMealPlanForWeek(_currentWeekStart, forceRefresh: forceRefresh);

    _setLoading(false);

    if (result.isSuccess) {
      _currentMealPlan = result.data;
      _clearError();
    } else if (result.isError) {
      _setError(result.error!);
    }

    notifyListeners();
  }

  /// Loads meal plan items for a specific date
  Future<void> loadMealPlanItemsForDate(DateTime date, {bool forceRefresh = false}) async {
    if (_isLoading) return; // Prevent multiple simultaneous loads

    _setLoading(true);
    _clearError();

    final result = await _repository.getMealPlanItemsForDate(date, forceRefresh: forceRefresh);

    _setLoading(false);

    if (result.isSuccess) {
      // Update the cached items for this date
      final newItems = result.data!;
      final dateString = MealPlanItem.formatPlannedDate(date);
      
      // Remove existing items for this date
      _mealPlanItems.removeWhere((item) => item.plannedDate == dateString);
      
      // Add new items
      _mealPlanItems.addAll(newItems);
      _clearError();
    } else if (result.isError) {
      _setError(result.error!);
    }

    notifyListeners();
  }

  /// Marks a meal as cooked
  Future<bool> markMealAsCooked(MealPlanItem mealPlanItem) async {
    if (_isLoading) return false;

    _setLoading(true);
    _clearError();

    final result = await _repository.markMealAsCooked(mealPlanItem);

    _setLoading(false);

    if (result.isSuccess) {
      // Update the local cache - MealPlanItem copyWith doesn't support hasBeenCooked
      final index = _mealPlanItems.indexWhere((item) => item.id == mealPlanItem.id);
      if (index != -1) {
        // Create a new MealPlanItem with hasBeenCooked set to true
        final updatedItem = MealPlanItem(
          id: mealPlanItem.id,
          mealPlanId: mealPlanItem.mealPlanId,
          plannedDate: mealPlanItem.plannedDate,
          mealType: mealPlanItem.mealType,
          notes: mealPlanItem.notes,
          hasBeenCooked: true,
          mealPlanItemRecipes: mealPlanItem.mealPlanItemRecipes,
        );
        _mealPlanItems[index] = updatedItem;
      }
      _clearError();
      notifyListeners();
      return true;
    } else if (result.isError) {
      _setError(result.error!);
      notifyListeners();
      return false;
    }

    return false;
  }

  /// Sets the current week and loads data for it
  Future<void> setCurrentWeek(DateTime weekStart, {bool forceRefresh = false}) async {
    final normalizedWeekStart = _getFridayOfWeek(weekStart);
    
    if (_currentWeekStart == normalizedWeekStart && !forceRefresh) {
      return; // Already on this week
    }

    _currentWeekStart = normalizedWeekStart;
    
    // Clear current data
    _currentMealPlan = null;
    _mealPlanItems.clear();
    
    // Load new data
    await loadMealPlanForCurrentWeek(forceRefresh: forceRefresh);
    
    notifyListeners();
  }

  /// Navigates to the next week
  Future<void> nextWeek() async {
    final nextWeekStart = _currentWeekStart.add(const Duration(days: 7));
    await setCurrentWeek(nextWeekStart);
  }

  /// Navigates to the previous week
  Future<void> previousWeek() async {
    final previousWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    await setCurrentWeek(previousWeekStart);
  }

  /// Navigates to the current week (today)
  Future<void> goToCurrentWeek() async {
    final currentWeekStart = _getFridayOfWeek(DateTime.now());
    await setCurrentWeek(currentWeekStart, forceRefresh: true);
  }

  /// Refreshes all meal plan data
  Future<void> refreshAll() async {
    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    final result = await _repository.refreshAll();

    if (result.isSuccess) {
      // Clear local cache and reload
      _currentMealPlan = null;
      _mealPlanItems.clear();
      
      // Reload current week data
      await loadMealPlanForCurrentWeek(forceRefresh: true);
      _clearError();
    } else if (result.isError) {
      _setError(result.error!);
    }

    _setLoading(false);
    notifyListeners();
  }

  /// Helper method to get Friday of a given week
  static DateTime _getFridayOfWeek(DateTime date) {
    int daysFromFriday = (date.weekday % 7 - 5) % 7;
    if (daysFromFriday < 0) daysFromFriday += 7;
    return DateTime(date.year, date.month, date.day - daysFromFriday);
  }

  /// Private helper methods

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
    }
  }

  void _setError(GastrobrainException error) {
    _error = error;
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
    }
  }

  /// Clears all cached data (useful for testing or logout)
  void clearCache() {
    _currentMealPlan = null;
    _mealPlanItems.clear();
    _currentWeekStart = _getFridayOfWeek(DateTime.now());
    _clearError();
    notifyListeners();
  }
}