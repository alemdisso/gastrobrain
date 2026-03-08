import 'package:flutter/material.dart';
import '../models/shopping_list.dart';
import '../models/shopping_list_item.dart';
import '../models/ingredient_category.dart';
import '../models/measurement_unit.dart';
import '../database/database_helper.dart';
import '../core/di/service_provider.dart';
import '../l10n/app_localizations.dart';
import '../utils/quantity_formatter.dart';
import '../widgets/add_shopping_item_dialog.dart';
import 'shopping_list_preview_screen.dart';

/// An item added manually by the user (in-memory only, not persisted to DB).
class _ManualShoppingItem {
  final String name;
  final double quantity;
  final String? unit;
  final String? notes;
  bool toBuy = true;

  _ManualShoppingItem({
    required this.name,
    required this.quantity,
    this.unit,
    this.notes,
  });
}

/// Unified wrapper used only for display/grouping logic.
class _DisplayItem {
  final ShoppingListItem? dbItem;
  final _ManualShoppingItem? manualItem;
  final int? manualIndex;

  const _DisplayItem.db(ShoppingListItem item)
      : dbItem = item,
        manualItem = null,
        manualIndex = null;

  const _DisplayItem.manual(_ManualShoppingItem item, int index)
      : dbItem = null,
        manualItem = item,
        manualIndex = index;

  bool get isManual => manualItem != null;
  String get name => dbItem?.ingredientName ?? manualItem!.name;
  String get category => isManual ? 'manual' : dbItem!.category;
  bool get toBuy => dbItem?.toBuy ?? manualItem!.toBuy;
  double get quantity => dbItem?.quantity ?? manualItem!.quantity;
  String get unit => dbItem?.unit ?? manualItem!.unit ?? '';
}

enum _StalenessType { none, planChanged, mealCooked }

class ShoppingListScreen extends StatefulWidget {
  final int shoppingListId;
  final DatabaseHelper? databaseHelper;

  const ShoppingListScreen({
    super.key,
    required this.shoppingListId,
    this.databaseHelper,
  });

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  ShoppingList? _shoppingList;
  List<ShoppingListItem> _items = [];
  final List<_ManualShoppingItem> _manualItems = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _showToBuyOnly = false;
  _StalenessType _stalenessType = _StalenessType.none;

  late final DatabaseHelper _dbHelper;

  @override
  void initState() {
    super.initState();
    _dbHelper = widget.databaseHelper ?? ServiceProvider.database.helper;
    _loadShoppingList();
  }

  Future<void> _loadShoppingList() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final shoppingList = await _dbHelper.getShoppingList(widget.shoppingListId);

      if (shoppingList == null) {
        if (mounted) {
          setState(() {
            _errorMessage = AppLocalizations.of(context)!.shoppingListNotFound;
            _isLoading = false;
          });
        }
        return;
      }

      final items = await _dbHelper.getShoppingListItems(widget.shoppingListId);

      // Check if the shopping list is stale.
      // Cooked-meal staleness takes precedence over plan-changed staleness.
      var stalenessType = _StalenessType.none;
      final mealPlan =
          await _dbHelper.getMealPlanForWeek(shoppingList.startDate);

      if (mealPlan != null) {
        // Cooked-meal staleness: a meal was cooked after the list was generated.
        if (mealPlan.lastCookedAt != null &&
            (shoppingList.mealPlanCookedAt == null ||
                mealPlan.lastCookedAt!.millisecondsSinceEpoch >
                    shoppingList.mealPlanCookedAt!.millisecondsSinceEpoch)) {
          stalenessType = _StalenessType.mealCooked;
        }
        // Plan-changed staleness: meals were added/removed/modified.
        else if (shoppingList.mealPlanModifiedAt != null &&
            mealPlan.modifiedAt.millisecondsSinceEpoch >
                shoppingList.mealPlanModifiedAt!.millisecondsSinceEpoch) {
          stalenessType = _StalenessType.planChanged;
        }
      }

      if (mounted) {
        setState(() {
          _shoppingList = shoppingList;
          _items = items;
          _stalenessType = stalenessType;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_shoppingList?.name ?? l10n.shoppingListTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.shoppingListEditIngredients,
            onPressed: _handleEditIngredients,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                FilterChip(
                  label: Text(l10n.toBuyOnly),
                  selected: _showToBuyOnly,
                  onSelected: (selected) {
                    setState(() {
                      _showToBuyOnly = selected;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _handleAddItem,
        icon: const Icon(Icons.add),
        label: Text(l10n.addShoppingItemButton),
      ),
      body: Column(
        children: [
          if (_stalenessType != _StalenessType.none) _buildStaleBanner(context),
          Expanded(
            child: SafeArea(
              top: false,
              child: _buildBody(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty && _manualItems.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                l10n.emptyShoppingList,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Build unified display items from DB items and manual items
    final allDisplayItems = <_DisplayItem>[
      ..._items.map((item) => _DisplayItem.db(item)),
      for (var i = 0; i < _manualItems.length; i++)
        _DisplayItem.manual(_manualItems[i], i),
    ];

    // Apply to-buy filter
    final filtered = allDisplayItems.where((item) {
      if (_showToBuyOnly && !item.toBuy) return false;
      return true;
    }).toList();

    // Group by category
    final grouped = <String, List<_DisplayItem>>{};
    for (final item in filtered) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    // Sort items alphabetically within each category
    for (final items in grouped.values) {
      items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }

    final l10nInner = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      children: grouped.entries.map((entry) {
        final categoryName = entry.key == 'manual'
            ? l10nInner.manualShoppingItemsCategory
            : IngredientCategory.fromString(entry.key).getLocalizedDisplayName(context);

        return ExpansionTile(
          title: Row(
            children: [
              Expanded(
                child: Text(
                  categoryName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                l10nInner.shoppingListCategoryCount(entry.value.length),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
          childrenPadding: EdgeInsets.zero,
          dense: true,
          initiallyExpanded: true,
          children: entry.value.map((item) {
            return InkWell(
              onTap: () => _toggleDisplayItem(item),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  children: [
                    Checkbox(
                      value: item.toBuy,
                      onChanged: (_) => _toggleDisplayItem(item),
                      activeColor: Theme.of(context).colorScheme.primary,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 8),
                    if (item.isManual) ...[
                      Icon(
                        Icons.edit_note,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 16,
                          color: !item.toBuy ? Colors.grey[600] : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDisplayQuantity(item),
                      style: TextStyle(
                        fontSize: 14,
                        color: !item.toBuy ? Colors.grey[500] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  Widget _buildStaleBanner(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final message = _stalenessType == _StalenessType.mealCooked
        ? l10n.shoppingListCookedMealWarning
        : l10n.shoppingListStaleWarning;

    return MaterialBanner(
      content: Text(message),
      leading: Icon(
        Icons.warning_amber_rounded,
        color: Theme.of(context).colorScheme.error,
      ),
      actions: [
        TextButton(
          onPressed: _handleUpdateList,
          child: Text(l10n.shoppingListStaleAction),
        ),
      ],
    );
  }

  Future<void> _handleUpdateList() async {
    if (_shoppingList == null) return;

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ShoppingListPreviewScreen(
          weekStartDate: _shoppingList!.startDate,
          weekEndDate: _shoppingList!.endDate,
          databaseHelper: _dbHelper,
        ),
      ),
    );
  }

  Future<void> _handleEditIngredients() async {
    if (_shoppingList == null) return;

    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.shoppingListEditIngredients),
        content: Text(l10n.shoppingListEditIngredientsConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.buttonContinue),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Delete the current list
    await _dbHelper.deleteShoppingList(_shoppingList!.id!);

    // Navigate to preview screen
    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ShoppingListPreviewScreen(
          weekStartDate: _shoppingList!.startDate,
          weekEndDate: _shoppingList!.endDate,
          databaseHelper: _dbHelper,
        ),
      ),
    );
  }

  String _formatQuantity(ShoppingListItem item) {
    if (item.quantity == 0) {
      final l10n = AppLocalizations.of(context)!;
      return l10n.toTaste;
    }

    final unit = MeasurementUnit.fromString(item.unit);
    final localizedUnit = unit?.getLocalizedQuantityName(context, item.quantity) ?? item.unit;
    final formattedQuantity = QuantityFormatter.format(item.quantity);

    return '$formattedQuantity $localizedUnit';
  }

  String _formatDisplayQuantity(_DisplayItem item) {
    if (item.isManual) {
      if (item.quantity == 0) return AppLocalizations.of(context)!.toTaste;
      final unit = MeasurementUnit.fromString(item.unit);
      final localizedUnit =
          unit?.getLocalizedQuantityName(context, item.quantity) ?? item.unit;
      final formattedQuantity = QuantityFormatter.format(item.quantity);
      return '$formattedQuantity $localizedUnit';
    }
    return _formatQuantity(item.dbItem!);
  }

  Future<void> _toggleToBuy(ShoppingListItem item) async {
    await ServiceProvider.shoppingList.toggleItemToBuy(item.id!);
    await _loadShoppingList();
  }

  Future<void> _toggleDisplayItem(_DisplayItem item) async {
    if (item.isManual) {
      setState(() {
        item.manualItem!.toBuy = !item.manualItem!.toBuy;
      });
    } else {
      await _toggleToBuy(item.dbItem!);
    }
  }

  Future<void> _handleAddItem() async {
    final ingredients = await _dbHelper.getAllIngredients();
    if (!mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddShoppingItemDialog(
        availableIngredients: ingredients,
      ),
    );

    if (result == null || !mounted) return;

    final name = (result['customName'] as String?) ??
        ingredients
            .where((i) => i.id == result['ingredientId'])
            .map((i) => i.name)
            .firstOrNull ??
        '';

    if (name.trim().isEmpty) return;

    setState(() {
      _manualItems.add(_ManualShoppingItem(
        name: name.trim(),
        quantity: (result['quantity'] as double?) ?? 1.0,
        unit: result['unit'] as String?,
        notes: result['notes'] as String?,
      ));
    });
  }
}
