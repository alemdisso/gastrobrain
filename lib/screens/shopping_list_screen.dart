import 'package:flutter/material.dart';
import '../models/shopping_list.dart';
import '../models/shopping_list_item.dart';
import '../models/ingredient_category.dart';
import '../models/measurement_unit.dart';
import '../database/database_helper.dart';
import '../core/di/service_provider.dart';
import '../l10n/app_localizations.dart';
import '../utils/quantity_formatter.dart';

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
  bool _isLoading = true;
  String? _errorMessage;
  bool _showToBuyOnly = false;
  bool _hideToTaste = false;

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

      if (mounted) {
        setState(() {
          _shoppingList = shoppingList;
          _items = items;
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                FilterChip(
                  label: Text(_showToBuyOnly ? l10n.showToBuyOnly : l10n.showAll),
                  selected: _showToBuyOnly,
                  onSelected: (selected) {
                    setState(() {
                      _showToBuyOnly = selected;
                    });
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(l10n.hideToTaste),
                  selected: _hideToTaste,
                  onSelected: (selected) {
                    setState(() {
                      _hideToTaste = selected;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(context),
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

    if (_items.isEmpty) {
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

    // Apply filters
    var filteredItems = _items.where((item) {
      // Filter by "to buy" status
      if (_showToBuyOnly && !item.toBuy) {
        return false;
      }

      // Filter out "to taste" items
      if (_hideToTaste && item.quantity == 0) {
        return false;
      }

      return true;
    }).toList();

    // Group items by category
    final grouped = <String, List<ShoppingListItem>>{};
    for (final item in filteredItems) {
      if (!grouped.containsKey(item.category)) {
        grouped[item.category] = [];
      }
      grouped[item.category]!.add(item);
    }

    // Sort items alphabetically within each category
    for (final items in grouped.values) {
      items.sort((a, b) => a.ingredientName.toLowerCase().compareTo(b.ingredientName.toLowerCase()));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      children: grouped.entries.map((entry) {
        // Translate category name using IngredientCategory enum
        final category = IngredientCategory.fromString(entry.key);
        final categoryName = category.getLocalizedDisplayName(context);

        return ExpansionTile(
          title: Text(
            categoryName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
          childrenPadding: EdgeInsets.zero,
          dense: true,
          initiallyExpanded: true,
          children: entry.value.map((item) {
            return InkWell(
              onTap: () => _toggleToBuy(item),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  children: [
                    // Checkbox
                    Checkbox(
                      value: item.toBuy,
                      onChanged: (value) => _toggleToBuy(item),
                      activeColor: Theme.of(context).colorScheme.primary,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 8),
                    // Ingredient name (flexible to take available space)
                    Expanded(
                      child: Text(
                        item.ingredientName,
                        style: TextStyle(
                          fontSize: 16,
                          color: !item.toBuy
                              ? Colors.grey[600]
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Quantity (fixed width on the right)
                    Text(
                      _formatQuantity(item),
                      style: TextStyle(
                        fontSize: 14,
                        color: !item.toBuy
                            ? Colors.grey[500]
                            : Colors.grey[700],
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

  String _formatQuantity(ShoppingListItem item) {
    if (item.quantity == 0) {
      final l10n = AppLocalizations.of(context)!;
      return '${l10n.toTaste} ⚠️';
    }

    // Localize unit using MeasurementUnit enum
    final unit = MeasurementUnit.fromString(item.unit);
    final localizedUnit = unit?.getLocalizedDisplayName(context) ?? item.unit;

    // Format quantity using QuantityFormatter (shows fractions, removes trailing zeros)
    final formattedQuantity = QuantityFormatter.format(item.quantity);

    return '$formattedQuantity $localizedUnit';
  }

  Future<void> _toggleToBuy(ShoppingListItem item) async {
    await ServiceProvider.shoppingList.toggleItemToBuy(item.id!);
    await _loadShoppingList();
  }
}
