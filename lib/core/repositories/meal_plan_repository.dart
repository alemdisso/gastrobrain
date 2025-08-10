import '../../models/meal_plan.dart';
import '../../models/meal_plan_item.dart';
import '../../database/database_helper.dart';
import '../errors/gastrobrain_exceptions.dart';
import '../di/service_provider.dart';
import 'base_repository.dart';

/// Repository for managing meal plan data with caching and state management
class MealPlanRepository extends BaseRepository<List<MealPlan>> {
  // Private constructor for singleton pattern
  MealPlanRepository._() {
    // Register for migration notifications
    RepositoryRegistry.register(this);
  }
  static final MealPlanRepository _instance = MealPlanRepository._();
  factory MealPlanRepository() => _instance;

  // Dependencies
  final DatabaseHelper _dbHelper = ServiceProvider.database.dbHelper;

  // Cache state
  List<MealPlan> _cachedMealPlans = [];
  Map<String, MealPlan?> _cachedMealPlansByWeek = {};
  Map<String, List<MealPlanItem>> _cachedMealPlanItems = {};
  bool _isLoading = false;
  GastrobrainException? _lastError;
  DateTime? _lastCacheTime;

  // Cache configuration
  static const Duration _cacheTimeout = Duration(minutes: 5);

  @override
  bool get isLoading => _isLoading;

  @override
  bool get hasData => _cachedMealPlans.isNotEmpty;

  @override
  GastrobrainException? get lastError => _lastError;

  /// Gets all cached meal plans
  List<MealPlan> get mealPlans => List.unmodifiable(_cachedMealPlans);

  /// Gets meal plan for a specific week
  Future<RepositoryResult<MealPlan?>> getMealPlanForWeek(DateTime weekStart, {bool forceRefresh = false}) async {
    try {
      final weekKey = _getWeekKey(weekStart);
      
      // Check cache validity
      if (!forceRefresh && _isCacheValid() && _cachedMealPlansByWeek.containsKey(weekKey)) {
        return RepositoryResult.success(_cachedMealPlansByWeek[weekKey]);
      }

      _isLoading = true;
      _lastError = null;

      // Load from database
      final mealPlan = await _dbHelper.getMealPlanForWeek(weekStart);
      
      // Update cache
      _cachedMealPlansByWeek[weekKey] = mealPlan;
      _updateCacheTime();

      return RepositoryResult.success(mealPlan);

    } catch (e) {
      final error = GastrobrainException('Failed to load meal plan for week: ${e.toString()}');
      _lastError = error;
      return RepositoryResult.error(error);
    } finally {
      _isLoading = false;
    }
  }

  /// Gets meal plan items for a specific date
  Future<RepositoryResult<List<MealPlanItem>>> getMealPlanItemsForDate(DateTime date, {bool forceRefresh = false}) async {
    try {
      final dateKey = _getDateKey(date);
      
      // Check cache validity
      if (!forceRefresh && _isCacheValid() && _cachedMealPlanItems.containsKey(dateKey)) {
        return RepositoryResult.success(_cachedMealPlanItems[dateKey]!);
      }

      _isLoading = true;
      _lastError = null;

      // Load from database
      final items = await _dbHelper.getMealPlanItemsForDate(date);
      
      // Update cache
      _cachedMealPlanItems[dateKey] = items;
      _updateCacheTime();

      return RepositoryResult.success(items);

    } catch (e) {
      final error = GastrobrainException('Failed to load meal plan items for date: ${e.toString()}');
      _lastError = error;
      return RepositoryResult.error(error);
    } finally {
      _isLoading = false;
    }
  }

  /// Records a meal as cooked by updating meal plan item status
  /// Note: This method will need the MealPlanItem object since DatabaseHelper doesn't have getMealPlanItem by ID
  Future<RepositoryResult<void>> markMealAsCooked(MealPlanItem mealPlanItem) async {
    try {
      _isLoading = true;
      _lastError = null;

      // Update in database - create new MealPlanItem since copyWith doesn't support hasBeenCooked
      final updatedItem = MealPlanItem(
        id: mealPlanItem.id,
        mealPlanId: mealPlanItem.mealPlanId,
        plannedDate: mealPlanItem.plannedDate,
        mealType: mealPlanItem.mealType,
        notes: mealPlanItem.notes,
        hasBeenCooked: true,
        mealPlanItemRecipes: mealPlanItem.mealPlanItemRecipes,
      );
      await _dbHelper.updateMealPlanItem(updatedItem);

      // Invalidate relevant caches
      _invalidateRelatedCaches(mealPlanItem.plannedDate);

      return const RepositoryResult.success(null);

    } catch (e) {
      final error = GastrobrainException('Failed to mark meal as cooked: ${e.toString()}');
      _lastError = error;
      return RepositoryResult.error(error);
    } finally {
      _isLoading = false;
    }
  }

  /// Refresh all cached data
  Future<RepositoryResult<void>> refreshAll() async {
    try {
      _isLoading = true;
      _lastError = null;

      // Clear all caches
      _cachedMealPlans.clear();
      _cachedMealPlansByWeek.clear();
      _cachedMealPlanItems.clear();
      _lastCacheTime = null;

      return const RepositoryResult.success(null);

    } catch (e) {
      final error = GastrobrainException('Failed to refresh meal plan data: ${e.toString()}');
      _lastError = error;
      return RepositoryResult.error(error);
    } finally {
      _isLoading = false;
    }
  }

  @override
  void invalidateCache() {
    _cachedMealPlans.clear();
    _cachedMealPlansByWeek.clear();
    _cachedMealPlanItems.clear();
    _lastCacheTime = null;
    _lastError = null;
  }

  @override
  void clearError() {
    _lastError = null;
  }

  /// Private helper methods

  bool _isCacheValid() {
    if (_lastCacheTime == null) return false;
    return DateTime.now().difference(_lastCacheTime!) < _cacheTimeout;
  }

  void _updateCacheTime() {
    _lastCacheTime = DateTime.now();
  }

  String _getWeekKey(DateTime weekStart) {
    return 'week_${weekStart.toIso8601String().substring(0, 10)}';
  }

  String _getDateKey(DateTime date) {
    return 'date_${date.toIso8601String().substring(0, 10)}';
  }

  void _invalidateRelatedCaches(String plannedDateString) {
    // Convert string date to DateTime for cache invalidation
    final dateParts = plannedDateString.split('-');
    final date = DateTime(int.parse(dateParts[0]), int.parse(dateParts[1]), int.parse(dateParts[2]));
    
    // Invalidate caches for the specific date and week
    final dateKey = _getDateKey(date);
    final weekKey = _getWeekKey(_getFridayOfWeek(date));
    
    _cachedMealPlanItems.remove(dateKey);
    _cachedMealPlansByWeek.remove(weekKey);
  }

  DateTime _getFridayOfWeek(DateTime date) {
    int daysFromFriday = (date.weekday % 7 - 5) % 7;
    if (daysFromFriday < 0) daysFromFriday += 7;
    return DateTime(date.year, date.month, date.day - daysFromFriday);
  }

}