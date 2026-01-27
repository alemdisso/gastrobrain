import 'package:flutter/material.dart';
import '../models/shopping_list.dart';
import '../models/shopping_list_item.dart';
import '../core/di/service_provider.dart';
import '../l10n/app_localizations.dart';

class ShoppingListScreen extends StatefulWidget {
  final int shoppingListId;

  const ShoppingListScreen({
    super.key,
    required this.shoppingListId,
  });

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  ShoppingList? _shoppingList;
  List<ShoppingListItem> _items = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadShoppingList();
  }

  Future<void> _loadShoppingList() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final shoppingList = await ServiceProvider.database.helper
          .getShoppingList(widget.shoppingListId);

      if (shoppingList == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Shopping list not found';
            _isLoading = false;
          });
        }
        return;
      }

      final items = await ServiceProvider.database.helper
          .getShoppingListItems(widget.shoppingListId);

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
        child: Text(_errorMessage!),
      );
    }

    if (_items.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return Center(
        child: Text(l10n.emptyShoppingList),
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
      children: grouped.entries.map((entry) {
        return ExpansionTile(
          title: Text(entry.key),
          initiallyExpanded: true,
          children: entry.value.map((item) {
            return CheckboxListTile(
              title: Text(item.ingredientName),
              subtitle: Text(_formatQuantity(item)),
              value: item.isPurchased,
              onChanged: (value) => _togglePurchased(item),
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
    return '${item.quantity} ${item.unit}';
  }

  Future<void> _togglePurchased(ShoppingListItem item) async {
    await ServiceProvider.shoppingList.toggleItemPurchased(item.id!);
    await _loadShoppingList();
  }
}
