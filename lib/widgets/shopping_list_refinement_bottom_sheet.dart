import 'package:flutter/material.dart';
import '../models/ingredient_category.dart';
import '../core/theme/design_tokens.dart';
import '../l10n/app_localizations.dart';
import '../utils/quantity_formatter.dart';

/// Bottom sheet that allows users to refine their shopping list before generation
///
/// This is Stage 2 (Refinement Mode) - bridges the gap between meal planning
/// and shopping by allowing users to uncheck items they already have at home.
class ShoppingListRefinementBottomSheet extends StatefulWidget {
  final Map<String, List<Map<String, dynamic>>> groupedIngredients;
  final VoidCallback? onGenerateList;

  const ShoppingListRefinementBottomSheet({
    super.key,
    required this.groupedIngredients,
    this.onGenerateList,
  });

  @override
  State<ShoppingListRefinementBottomSheet> createState() =>
      _ShoppingListRefinementBottomSheetState();
}

class _ShoppingListRefinementBottomSheetState
    extends State<ShoppingListRefinementBottomSheet> {
  // Track checked state for each ingredient
  // Key format: "categoryName:ingredientName"
  final Map<String, bool> _checkedState = {};
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _initializeCheckedState();
  }

  /// Initialize all ingredients as checked by default (opt-out model)
  void _initializeCheckedState() {
    for (final entry in widget.groupedIngredients.entries) {
      final category = entry.key;
      final items = entry.value;

      for (final item in items) {
        final name = item['name'] as String;
        final key = _makeKey(category, name);
        _checkedState[key] = true; // All checked by default
      }
    }
  }

  /// Create a unique key for ingredient tracking
  String _makeKey(String category, String name) {
    return '$category:$name';
  }

  /// Toggle individual ingredient checked state
  void _toggleIngredient(String category, String name) {
    setState(() {
      final key = _makeKey(category, name);
      _checkedState[key] = !(_checkedState[key] ?? true);
    });
  }

  /// Select all ingredients
  void _selectAll() {
    setState(() {
      for (final key in _checkedState.keys) {
        _checkedState[key] = true;
      }
    });
  }

  /// Deselect all ingredients
  void _deselectAll() {
    setState(() {
      for (final key in _checkedState.keys) {
        _checkedState[key] = false;
      }
    });
  }

  /// Get selected ingredients (only those checked)
  Map<String, List<Map<String, dynamic>>> _getSelectedIngredients() {
    final selected = <String, List<Map<String, dynamic>>>{};

    for (final entry in widget.groupedIngredients.entries) {
      final category = entry.key;
      final items = entry.value;

      final selectedItems = items.where((item) {
        final name = item['name'] as String;
        final key = _makeKey(category, name);
        return _checkedState[key] ?? true;
      }).toList();

      if (selectedItems.isNotEmpty) {
        selected[category] = selectedItems;
      }
    }

    return selected;
  }

  /// Count total selected items
  int _countSelectedItems() {
    return _checkedState.values.where((isChecked) => isChecked).length;
  }

  /// Handle generate shopping list action
  Future<void> _handleGenerate() async {
    final selectedCount = _countSelectedItems();

    // Validation: At least one item must be selected
    if (selectedCount == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.shoppingListRefinementEmptyError),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Return selected ingredients to caller
    if (mounted) {
      Navigator.pop(context, _getSelectedIngredients());
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _countSelectedItems();
    final totalCount = _checkedState.length;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(DesignTokens.borderRadiusLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle/grip
          Padding(
            padding: const EdgeInsets.only(top: DesignTokens.spacingMd),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(DesignTokens.spacingXXs),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.spacingMd),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingLg),
            child: Text(
              AppLocalizations.of(context)!.shoppingListRefinementTitle,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingSm),

          // Subtitle with count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingLg),
            child: Text(
              AppLocalizations.of(context)!.shoppingListRefinementSubtitle(selectedCount, totalCount),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingMd),

          // Select All / Deselect All buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingLg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: _selectAll,
                  icon: const Icon(Icons.check_box),
                  label: Text(AppLocalizations.of(context)!.selectAll),
                ),
                TextButton.icon(
                  onPressed: _deselectAll,
                  icon: const Icon(Icons.check_box_outline_blank),
                  label: Text(AppLocalizations.of(context)!.deselectAll),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content
          Flexible(
            child: widget.groupedIngredients.isEmpty
                ? _buildEmptyState(context)
                : _buildIngredientList(context),
          ),

          // Bottom action bar
          Container(
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
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : Text(
                          AppLocalizations.of(context)!.generateShoppingList,
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spacingXl),
      child: Center(
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
    // Sort categories for consistent display
    final sortedEntries = widget.groupedIngredients.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return ListView.builder(
      shrinkWrap: true,
      itemCount: sortedEntries.length,
      itemBuilder: (context, index) {
        final entry = sortedEntries[index];
        final categoryKey = entry.key;
        final items = entry.value;

        // Get localized category name
        final category = IngredientCategory.fromString(categoryKey);
        final categoryName = category.getLocalizedDisplayName(context);

        // Sort items alphabetically within category
        items.sort(
          (a, b) => (a['name'] as String)
              .toLowerCase()
              .compareTo((b['name'] as String).toLowerCase()),
        );

        return ExpansionTile(
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
            final key = _makeKey(categoryKey, itemName);
            final isChecked = _checkedState[key] ?? true;

            return CheckboxListTile(
              value: isChecked,
              onChanged: (value) => _toggleIngredient(categoryKey, itemName),
              title: Row(
                children: [
                  // Ingredient name (flexible to take available space)
                  Expanded(
                    child: Text(
                      itemName,
                      style: TextStyle(
                        fontSize: 16,
                        decoration: isChecked ? null : TextDecoration.lineThrough,
                        color: isChecked
                            ? null
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacingMd),
                  // Quantity (fixed width on the right)
                  Text(
                    _formatQuantity(item),
                    style: TextStyle(
                      fontSize: 14,
                      color: isChecked
                          ? Colors.grey[700]
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      decoration: isChecked ? null : TextDecoration.lineThrough,
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

  String _formatQuantity(Map<String, dynamic> item) {
    final quantity = item['quantity'] as double;
    final unit = item['unit'] as String;

    // Format quantity (handles fractions, whole numbers, decimals)
    final formattedQuantity = QuantityFormatter.format(quantity);

    // Combine with unit
    return '$formattedQuantity $unit';
  }
}
