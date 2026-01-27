import 'package:flutter/material.dart';
import '../models/shopping_list.dart';
import '../models/shopping_list_item.dart';
import '../models/ingredient_category.dart';
import '../models/measurement_unit.dart';
import '../database/database_helper.dart';
import '../core/di/service_provider.dart';
import '../l10n/app_localizations.dart';

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

    // Group items by category
    final grouped = <String, List<ShoppingListItem>>{};
    for (final item in _items) {
      if (!grouped.containsKey(item.category)) {
        grouped[item.category] = [];
      }
      grouped[item.category]!.add(item);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
          initiallyExpanded: true,
          children: entry.value.map((item) {
            return CheckboxListTile(
              title: Text(
                item.ingredientName,
                style: TextStyle(
                  decoration: item.isPurchased
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  color: item.isPurchased
                      ? Colors.grey[600]
                      : null,
                ),
              ),
              subtitle: Text(
                _formatQuantity(item),
                style: TextStyle(
                  color: item.isPurchased
                      ? Colors.grey[500]
                      : null,
                ),
              ),
              value: item.isPurchased,
              onChanged: (value) => _togglePurchased(item),
              activeColor: Theme.of(context).colorScheme.primary,
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

    return '${item.quantity} $localizedUnit';
  }

  Future<void> _togglePurchased(ShoppingListItem item) async {
    await ServiceProvider.shoppingList.toggleItemPurchased(item.id!);
    await _loadShoppingList();
  }
}
