import 'package:flutter/material.dart';
import '../models/ingredient_category.dart';
import '../models/measurement_unit.dart';
import '../core/di/service_provider.dart';
import '../core/services/shopping_list_service.dart';
import '../core/services/snackbar_service.dart';
import '../core/theme/design_tokens.dart';
import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../utils/quantity_formatter.dart';
import 'shopping_list_refinement_screen.dart';
import 'shopping_list_screen.dart';

/// Full-screen preview of projected ingredients for the current week.
///
/// This is the first screen in the unified shopping list flow.
/// Shows a read-only ingredient list grouped by category.
/// Users can proceed to refinement or generate the list directly.
class ShoppingListPreviewScreen extends StatefulWidget {
  final DateTime weekStartDate;
  final DateTime weekEndDate;
  final DatabaseHelper? databaseHelper;
  final bool hideToTaste;

  const ShoppingListPreviewScreen({
    super.key,
    required this.weekStartDate,
    required this.weekEndDate,
    this.databaseHelper,
    this.hideToTaste = false,
  });

  @override
  State<ShoppingListPreviewScreen> createState() =>
      _ShoppingListPreviewScreenState();
}

class _ShoppingListPreviewScreenState extends State<ShoppingListPreviewScreen> {
  Map<String, List<Map<String, dynamic>>>? _groupedIngredients;
  bool _isLoading = true;
  bool _isGenerating = false;
  bool _hideToTaste = false;

  late final DatabaseHelper _dbHelper;
  late final ShoppingListService _shoppingListService;

  @override
  void initState() {
    super.initState();
    _dbHelper = widget.databaseHelper ?? ServiceProvider.database.helper;
    _shoppingListService = ShoppingListService(_dbHelper);
    _hideToTaste = widget.hideToTaste;
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    try {
      final ingredients =
          await _shoppingListService.calculateProjectedIngredients(
        startDate: widget.weekStartDate,
        endDate: widget.weekEndDate,
      );

      if (mounted) {
        setState(() {
          _groupedIngredients = ingredients;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarService.showError(
          context,
          AppLocalizations.of(context)!.shoppingListPreviewError,
        );
      }
    }
  }

  Future<void> _navigateToRefinement() async {
    if (_groupedIngredients == null || _groupedIngredients!.isEmpty) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShoppingListRefinementScreen(
          groupedIngredients: _groupedIngredients!,
          weekStartDate: widget.weekStartDate,
          weekEndDate: widget.weekEndDate,
          databaseHelper: _dbHelper,
          hideToTaste: _hideToTaste,
        ),
      ),
    );

    // If refinement created a list and navigated to saved screen,
    // we should pop back to weekly plan when user returns
    if (mounted && !Navigator.of(context).canPop()) return;
  }

  Future<void> _generateAll() async {
    if (_groupedIngredients == null || _groupedIngredients!.isEmpty) return;

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
        curatedIngredients: _groupedIngredients!,
      );

      if (!mounted) return;

      // Replace this screen with the saved list screen
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ShoppingListScreen(
            shoppingListId: shoppingList.id!,
          ),
        ),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.shoppingListPreviewTitle),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _groupedIngredients == null || _groupedIngredients!.isEmpty
              ? _buildEmptyState(context)
              : _buildIngredientList(context),
      bottomNavigationBar:
          (!_isLoading &&
                  _groupedIngredients != null &&
                  _groupedIngredients!.isNotEmpty)
              ? _buildActionBar(context)
              : null,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: DesignTokens.spacingMd),
            Text(
              l10n.shoppingListEmptyTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spacingSm),
            Text(
              l10n.shoppingListEmptySubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
    for (final entry in _groupedIngredients!.entries) {
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
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingLg,
                vertical: DesignTokens.spacingSm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item['name'] as String,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacingMd),
                  Text(
                    _formatQuantity(item, context),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildActionBar(BuildContext context) {
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
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isGenerating ? null : _navigateToRefinement,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: DesignTokens.spacingMd,
                  ),
                ),
                child: Text(l10n.shoppingListRefineAction),
              ),
            ),
            const SizedBox(width: DesignTokens.spacingMd),
            Expanded(
              child: ElevatedButton(
                onPressed: _isGenerating ? null : _generateAll,
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
                    : Text(l10n.shoppingListGenerateAll),
              ),
            ),
          ],
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
