import 'package:flutter/material.dart';
import '../models/ingredient_category.dart';
import '../models/measurement_unit.dart';
import '../core/di/service_provider.dart';
import '../core/services/snackbar_service.dart';
import '../core/theme/design_tokens.dart';
import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../utils/quantity_formatter.dart';
import 'shopping_list_screen.dart';

/// Full-screen refinement of shopping list ingredients.
///
/// Second screen in the unified shopping list flow.
/// Users can uncheck items they already have before generating the list.
class ShoppingListRefinementScreen extends StatefulWidget {
  final Map<String, List<Map<String, dynamic>>> groupedIngredients;
  final DateTime weekStartDate;
  final DateTime weekEndDate;
  final DatabaseHelper? databaseHelper;
  final bool hideToTaste;

  const ShoppingListRefinementScreen({
    super.key,
    required this.groupedIngredients,
    required this.weekStartDate,
    required this.weekEndDate,
    this.databaseHelper,
    this.hideToTaste = false,
  });

  @override
  State<ShoppingListRefinementScreen> createState() =>
      _ShoppingListRefinementScreenState();
}

class _ShoppingListRefinementScreenState
    extends State<ShoppingListRefinementScreen> {
  final Map<String, bool> _checkedState = {};
  bool _isGenerating = false;
  bool _hideToTaste = false;

  late final DatabaseHelper _dbHelper;

  @override
  void initState() {
    super.initState();
    _dbHelper = widget.databaseHelper ?? ServiceProvider.database.helper;
    _hideToTaste = widget.hideToTaste;
    _initializeCheckedState();
  }

  void _initializeCheckedState() {
    for (final entry in widget.groupedIngredients.entries) {
      final category = entry.key;
      for (final item in entry.value) {
        final name = item['name'] as String;
        _checkedState['$category:$name'] = true;
      }
    }
  }

  void _toggleIngredient(String category, String name) {
    setState(() {
      final key = '$category:$name';
      _checkedState[key] = !(_checkedState[key] ?? true);
    });
  }

  void _toggleAll() {
    setState(() {
      final allSelected = _checkedState.values.every((v) => v);
      for (final key in _checkedState.keys) {
        _checkedState[key] = !allSelected;
      }
    });
  }

  bool? _getCheckboxState() {
    if (_checkedState.isEmpty) return false;
    final selectedCount =
        _checkedState.values.where((checked) => checked).length;
    if (selectedCount == _checkedState.length) return true;
    if (selectedCount == 0) return false;
    return null;
  }

  bool? _getCategoryCheckboxState(String category) {
    final items = widget.groupedIngredients[category];
    if (items == null || items.isEmpty) return false;

    final keys = items.map((item) => '$category:${item['name']}').toList();
    final selectedCount =
        keys.where((key) => _checkedState[key] ?? true).length;
    if (selectedCount == keys.length) return true;
    if (selectedCount == 0) return false;
    return null;
  }

  void _toggleCategory(String category) {
    setState(() {
      final items = widget.groupedIngredients[category];
      if (items == null) return;

      final keys = items.map((item) => '$category:${item['name']}').toList();
      final allSelected =
          keys.every((key) => _checkedState[key] ?? true);
      for (final key in keys) {
        _checkedState[key] = !allSelected;
      }
    });
  }

  int _countSelected() {
    return _checkedState.values.where((v) => v).length;
  }

  Map<String, List<Map<String, dynamic>>> _getSelectedIngredients() {
    final selected = <String, List<Map<String, dynamic>>>{};

    for (final entry in widget.groupedIngredients.entries) {
      final category = entry.key;
      final selectedItems = entry.value.where((item) {
        final name = item['name'] as String;
        return _checkedState['$category:$name'] ?? true;
      }).toList();

      if (selectedItems.isNotEmpty) {
        selected[category] = selectedItems;
      }
    }

    return selected;
  }

  Future<void> _handleGenerate() async {
    final selectedCount = _countSelected();

    if (selectedCount == 0) {
      if (!mounted) return;
      SnackbarService.showError(
        context,
        AppLocalizations.of(context)!.shoppingListRefinementEmptyError,
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      // Delete existing list if any
      final existingList = await _dbHelper.getShoppingListForDateRange(
        widget.weekStartDate,
        widget.weekEndDate,
      );
      if (existingList != null) {
        await _dbHelper.deleteShoppingList(existingList.id!);
      }

      final shoppingList =
          await ServiceProvider.shoppingList.generateFromCuratedIngredients(
        startDate: widget.weekStartDate,
        endDate: widget.weekEndDate,
        curatedIngredients: _getSelectedIngredients(),
      );

      if (!mounted) return;

      // Replace both preview and refinement with saved screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => ShoppingListScreen(
            shoppingListId: shoppingList.id!,
          ),
        ),
        (route) => route.isFirst, // Keep only the weekly plan screen
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        SnackbarService.showError(
          context,
          AppLocalizations.of(context)!.errorGeneratingShoppingList,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedCount = _countSelected();
    final totalCount = _checkedState.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.shoppingListRefinementTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingLg,
              vertical: DesignTokens.spacingSm,
            ),
            child: Row(
              children: [
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
      body: Column(
        children: [
          // Select/deselect all
          CheckboxListTile(
            tristate: true,
            value: _getCheckboxState(),
            onChanged: (_) => _toggleAll(),
            title: Text(l10n.selectAll),
            subtitle: Text(l10n.shoppingListRefinementSubtitle(
                selectedCount, totalCount)),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingLg),
          ),
          const Divider(height: 1),

          // Ingredient list
          Expanded(
            child: widget.groupedIngredients.isEmpty
                ? _buildEmptyState(context)
                : _buildIngredientList(context),
          ),
        ],
      ),
      bottomNavigationBar: widget.groupedIngredients.isNotEmpty
          ? _buildActionBar(context, selectedCount)
          : null,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: DesignTokens.spacingMd),
            Text(
              AppLocalizations.of(context)!.shoppingListRefinementEmpty,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientList(BuildContext context) {
    // Apply "hide to taste" filter
    final filtered = <String, List<Map<String, dynamic>>>{};
    for (final entry in widget.groupedIngredients.entries) {
      final items = _hideToTaste
          ? entry.value.where((item) => (item['quantity'] as double) != 0).toList()
          : entry.value;
      if (items.isNotEmpty) {
        filtered[entry.key] = items;
      }
    }

    final sortedEntries = filtered.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingSm),
      itemCount: sortedEntries.length,
      itemBuilder: (context, index) {
        final entry = sortedEntries[index];
        final categoryKey = entry.key;
        final items = entry.value;

        final category = IngredientCategory.fromString(categoryKey);
        final categoryName = category.getLocalizedDisplayName(context);

        items.sort((a, b) => (a['name'] as String)
            .toLowerCase()
            .compareTo((b['name'] as String).toLowerCase()));

        return ExpansionTile(
          leading: Checkbox(
            tristate: true,
            value: _getCategoryCheckboxState(categoryKey),
            onChanged: (_) => _toggleCategory(categoryKey),
          ),
          title: Text(
            categoryName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          tilePadding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingLg,
            vertical: 0,
          ),
          childrenPadding: EdgeInsets.zero,
          dense: true,
          initiallyExpanded: true,
          children: items.map((item) {
            final itemName = item['name'] as String;
            final key = '$categoryKey:$itemName';
            final isChecked = _checkedState[key] ?? true;

            return CheckboxListTile(
              value: isChecked,
              onChanged: (value) => _toggleIngredient(categoryKey, itemName),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      itemName,
                      style: TextStyle(
                        fontSize: 16,
                        decoration:
                            isChecked ? null : TextDecoration.lineThrough,
                        color: isChecked
                            ? null
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacingMd),
                  Text(
                    _formatQuantity(item, context),
                    style: TextStyle(
                      fontSize: 14,
                      color: isChecked
                          ? Colors.grey[700]
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      decoration:
                          isChecked ? null : TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ),
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingLg,
                vertical: 0,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildActionBar(BuildContext context, int selectedCount) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingMd),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isGenerating ? null : _handleGenerate,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: DesignTokens.spacingMd,
              ),
            ),
            child: _isGenerating
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    l10n.shoppingListGenerateCount(selectedCount),
                    style: const TextStyle(fontSize: 16),
                  ),
          ),
        ),
      ),
    );
  }

  String _formatQuantity(Map<String, dynamic> item, BuildContext context) {
    final quantity = item['quantity'] as double;

    if (quantity == 0) {
      return AppLocalizations.of(context)!.toTaste;
    }

    final unitString = item['unit'] as String;
    final measurementUnit = MeasurementUnit.fromString(unitString);
    final localizedUnit =
        measurementUnit?.getLocalizedQuantityName(context, quantity) ?? unitString;

    final formattedQuantity = QuantityFormatter.format(quantity);

    return '$formattedQuantity $localizedUnit';
  }
}
