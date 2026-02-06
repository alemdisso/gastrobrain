// =============================================================================
// Service Pattern Template
// =============================================================================
// Reference: lib/core/services/recommendation_cache_service.dart
//
// This file demonstrates the standard patterns for:
// 1. Constructor dependency injection
// 2. Private helper methods
// 3. Error handling with GastrobrainException hierarchy
// 4. Async operations with proper return types
// =============================================================================

import '../../database/database_helper.dart';
import '../../models/my_model.dart';
import '../errors/gastrobrain_exceptions.dart';

// -----------------------------------------------------------------------------
// SERVICE PATTERN
// -----------------------------------------------------------------------------
// Use when: Creating business logic that operates on data
// Reference: lib/core/services/recommendation_cache_service.dart
// -----------------------------------------------------------------------------

/// Service for managing [feature] operations
///
/// Provides [brief description of what this service does].
/// Uses constructor dependency injection for testability.
class MyService {
  /// Database helper injected via constructor
  final DatabaseHelper _dbHelper;

  /// Optional: inject other services as needed
  final OtherService? _otherService;

  /// Constructor with required dependencies
  /// Use named parameters for optional dependencies
  MyService(
    this._dbHelper, {
    OtherService? otherService,
  }) : _otherService = otherService;

  // ---------------------------------------------------------------------------
  // PUBLIC METHODS
  // ---------------------------------------------------------------------------

  /// Gets all items with optional filtering
  ///
  /// Returns empty list if no items found (not null).
  /// Throws [GastrobrainException] on database errors.
  Future<List<MyModel>> getAll({
    String? filterBy,
    bool includeInactive = false,
  }) async {
    try {
      final items = await _dbHelper.getAllMyModels();

      // Apply filters
      var filtered = items.where((item) {
        if (!includeInactive && !item.isActive) return false;
        if (filterBy != null && !item.name.contains(filterBy)) return false;
        return true;
      }).toList();

      return filtered;
    } catch (e) {
      throw GastrobrainException('Failed to get items: $e');
    }
  }

  /// Gets a single item by ID
  ///
  /// Throws [NotFoundException] if item doesn't exist.
  Future<MyModel> getById(String id) async {
    try {
      final item = await _dbHelper.getMyModel(id);
      if (item == null) {
        throw NotFoundException('Item with ID $id not found');
      }
      return item;
    } on NotFoundException {
      rethrow; // Preserve specific exceptions
    } catch (e) {
      throw GastrobrainException('Failed to get item: $e');
    }
  }

  /// Creates a new item
  ///
  /// Validates input before saving.
  /// Throws [ValidationException] for invalid input.
  /// Returns the created item.
  Future<MyModel> create(MyModel item) async {
    // Validate
    _validateItem(item);

    try {
      await _dbHelper.insertMyModel(item);
      return item;
    } catch (e) {
      throw GastrobrainException('Failed to create item: $e');
    }
  }

  /// Updates an existing item
  ///
  /// Throws [NotFoundException] if item doesn't exist.
  /// Throws [ValidationException] for invalid input.
  Future<MyModel> update(MyModel item) async {
    // Verify exists
    await getById(item.id);

    // Validate
    _validateItem(item);

    try {
      await _dbHelper.updateMyModel(item);
      return item;
    } catch (e) {
      throw GastrobrainException('Failed to update item: $e');
    }
  }

  /// Deletes an item by ID
  ///
  /// Throws [NotFoundException] if item doesn't exist.
  /// Returns true if deletion successful.
  Future<bool> delete(String id) async {
    // Verify exists
    await getById(id);

    try {
      await _dbHelper.deleteMyModel(id);
      return true;
    } catch (e) {
      throw GastrobrainException('Failed to delete item: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // PRIVATE HELPER METHODS
  // ---------------------------------------------------------------------------
  // Use _ prefix for all private methods
  // Keep business logic in these methods for testability

  /// Validates item before save
  void _validateItem(MyModel item) {
    if (item.name.isEmpty) {
      throw ValidationException('Name cannot be empty');
    }
    if (item.name.length > 100) {
      throw ValidationException('Name cannot exceed 100 characters');
    }
    // Add more validation as needed
  }

  /// Internal helper for complex logic
  Future<List<MyModel>> _filterByComplexCriteria(
    List<MyModel> items,
    Map<String, dynamic> criteria,
  ) async {
    // Complex filtering logic here
    return items.where((item) {
      // Apply criteria
      return true;
    }).toList();
  }
}

// -----------------------------------------------------------------------------
// SERVICE WITH CACHING PATTERN
// -----------------------------------------------------------------------------
// Use when: Service needs to cache results for performance
// Reference: lib/core/services/recommendation_cache_service.dart
// -----------------------------------------------------------------------------

/// Service with internal caching
class MyCachingService {
  final DatabaseHelper _dbHelper;

  /// Cache storage
  final Map<String, List<MyModel>> _cache = {};

  MyCachingService(this._dbHelper);

  /// Creates a cache key from parameters
  String _getCacheKey(DateTime date, String type) {
    return '${date.toIso8601String()}-$type';
  }

  /// Invalidates cache for specific key
  void invalidateCache(DateTime date, String type) {
    final cacheKey = _getCacheKey(date, type);
    _cache.remove(cacheKey);
  }

  /// Clears all cached data
  void clearAllCache() {
    _cache.clear();
  }

  /// Gets items with caching
  Future<List<MyModel>> getCached({
    required DateTime date,
    required String type,
  }) async {
    final cacheKey = _getCacheKey(date, type);

    // Return cached if available
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    // Fetch from database
    final items = await _dbHelper.getMyModelsByDateAndType(date, type);

    // Cache and return
    _cache[cacheKey] = items;
    return items;
  }
}
