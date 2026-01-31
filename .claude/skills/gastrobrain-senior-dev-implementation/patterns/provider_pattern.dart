// =============================================================================
// Provider Pattern Template
// =============================================================================
// Reference: lib/core/providers/recipe_provider.dart
//
// This file demonstrates the standard patterns for:
// 1. ChangeNotifier extension
// 2. Private fields with public getters
// 3. notifyListeners() after state changes
// 4. Error handling and loading states
// =============================================================================

import 'package:flutter/foundation.dart';
import '../repositories/my_repository.dart';
import '../errors/gastrobrain_exceptions.dart';
import '../../models/my_model.dart';

// -----------------------------------------------------------------------------
// PROVIDER PATTERN
// -----------------------------------------------------------------------------
// Use when: Managing state that multiple widgets need to access
// Reference: lib/core/providers/recipe_provider.dart
// -----------------------------------------------------------------------------

/// Provider for managing [feature] state throughout the application
class MyProvider extends ChangeNotifier {
  /// Repository for data access
  final MyRepository _repository;

  // ---------------------------------------------------------------------------
  // STATE VARIABLES (private)
  // ---------------------------------------------------------------------------

  /// Current list of items
  List<MyModel> _items = [];

  /// Loading state
  bool _isLoading = false;

  /// Current error (null if none)
  GastrobrainException? _error;

  /// Currently selected item
  MyModel? _selectedItem;

  /// Filter state
  Map<String, dynamic> _filters = {};

  /// Sort configuration
  String? _sortBy = 'name';
  String? _sortOrder = 'ASC';

  // ---------------------------------------------------------------------------
  // GETTERS (public, immutable where appropriate)
  // ---------------------------------------------------------------------------

  /// Immutable list of items
  List<MyModel> get items => List.unmodifiable(_items);

  /// Loading state
  bool get isLoading => _isLoading;

  /// Current error
  GastrobrainException? get error => _error;

  /// Whether there is an error
  bool get hasError => _error != null;

  /// Whether data has been loaded
  bool get hasData => _items.isNotEmpty;

  /// Currently selected item
  MyModel? get selectedItem => _selectedItem;

  /// Current filters (immutable copy)
  Map<String, dynamic> get filters => Map.unmodifiable(_filters);

  /// Whether filters are active
  bool get hasActiveFilters => _filters.isNotEmpty;

  /// Current sort field
  String? get sortBy => _sortBy;

  /// Current sort order
  String? get sortOrder => _sortOrder;

  /// Item count
  int get itemCount => _items.length;

  // ---------------------------------------------------------------------------
  // CONSTRUCTOR
  // ---------------------------------------------------------------------------

  MyProvider(this._repository);

  // ---------------------------------------------------------------------------
  // CRUD OPERATIONS
  // ---------------------------------------------------------------------------

  /// Loads all items with current filters and sorting
  Future<void> loadItems({bool forceRefresh = false}) async {
    // Prevent multiple simultaneous loads
    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      final result = await _repository.getAll(
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        filters: _filters.isEmpty ? null : _filters,
        forceRefresh: forceRefresh,
      );

      if (result.isSuccess) {
        _items = result.data!;
        _clearError();
      } else if (result.isError) {
        _setError(result.error!);
      }
    } catch (e) {
      _setError(GastrobrainException('Failed to load items: $e'));
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Gets a single item by ID
  Future<MyModel?> getItem(String id) async {
    // Check cache first
    final existingItem = _items.where((i) => i.id == id).firstOrNull;
    if (existingItem != null) {
      return existingItem;
    }

    // Fetch from repository
    try {
      final result = await _repository.getById(id);
      if (result.isSuccess) {
        final item = result.data!;
        // Add to cache if not already present
        if (!_items.any((i) => i.id == id)) {
          _items.add(item);
          notifyListeners();
        }
        return item;
      } else if (result.isError) {
        _setError(result.error!);
        notifyListeners();
      }
    } catch (e) {
      _setError(GastrobrainException('Failed to get item: $e'));
      notifyListeners();
    }

    return null;
  }

  /// Creates a new item
  Future<bool> createItem(MyModel item) async {
    _clearError();

    try {
      final result = await _repository.create(item);

      if (result.isSuccess) {
        _items.add(item);
        notifyListeners();
        return true;
      } else if (result.isError) {
        _setError(result.error!);
        notifyListeners();
      }
    } catch (e) {
      _setError(GastrobrainException('Failed to create item: $e'));
      notifyListeners();
    }

    return false;
  }

  /// Updates an existing item
  Future<bool> updateItem(MyModel item) async {
    _clearError();

    try {
      final result = await _repository.update(item);

      if (result.isSuccess) {
        final index = _items.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          _items[index] = item;
        }
        notifyListeners();
        return true;
      } else if (result.isError) {
        _setError(result.error!);
        notifyListeners();
      }
    } catch (e) {
      _setError(GastrobrainException('Failed to update item: $e'));
      notifyListeners();
    }

    return false;
  }

  /// Deletes an item
  Future<bool> deleteItem(String id) async {
    _clearError();

    try {
      final result = await _repository.delete(id);

      if (result.isSuccess) {
        _items.removeWhere((i) => i.id == id);
        // Clear selection if deleted item was selected
        if (_selectedItem?.id == id) {
          _selectedItem = null;
        }
        notifyListeners();
        return true;
      } else if (result.isError) {
        _setError(result.error!);
        notifyListeners();
      }
    } catch (e) {
      _setError(GastrobrainException('Failed to delete item: $e'));
      notifyListeners();
    }

    return false;
  }

  // ---------------------------------------------------------------------------
  // SELECTION
  // ---------------------------------------------------------------------------

  /// Selects an item
  void selectItem(MyModel? item) {
    if (_selectedItem != item) {
      _selectedItem = item;
      notifyListeners();
    }
  }

  /// Clears selection
  void clearSelection() {
    if (_selectedItem != null) {
      _selectedItem = null;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // FILTERING AND SORTING
  // ---------------------------------------------------------------------------

  /// Updates sorting parameters and reloads
  Future<void> setSorting({String? sortBy, String? sortOrder}) async {
    if (sortBy != null) _sortBy = sortBy;
    if (sortOrder != null) _sortOrder = sortOrder;
    await loadItems(forceRefresh: true);
  }

  /// Updates filter parameters and reloads
  Future<void> setFilters(Map<String, dynamic> filters) async {
    _filters = Map.from(filters);
    await loadItems(forceRefresh: true);
  }

  /// Clears all filters and reloads
  Future<void> clearFilters() async {
    _filters.clear();
    await loadItems(forceRefresh: true);
  }

  // ---------------------------------------------------------------------------
  // REFRESH
  // ---------------------------------------------------------------------------

  /// Force refreshes all data
  Future<void> refresh() async {
    _repository.invalidateCache();
    await loadItems(forceRefresh: true);
  }

  // ---------------------------------------------------------------------------
  // ERROR HANDLING
  // ---------------------------------------------------------------------------

  /// Clears the current error
  void clearError() {
    _clearError();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // PRIVATE HELPERS
  // ---------------------------------------------------------------------------

  void _setLoading(bool loading) {
    _isLoading = loading;
  }

  void _setError(GastrobrainException error) {
    _error = error;
  }

  void _clearError() {
    _error = null;
  }

  // ---------------------------------------------------------------------------
  // LIFECYCLE
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    // Clean up any resources
    super.dispose();
  }
}
