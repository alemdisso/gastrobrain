import 'package:flutter/material.dart';
import '../models/ingredient_category.dart';
import '../models/measurement_unit.dart';
import '../core/theme/design_tokens.dart';
import '../l10n/app_localizations.dart';
import '../utils/quantity_formatter.dart';

/// Bottom sheet that displays projected ingredients in read-only mode
///
/// This is Stage 1 (Preview Mode) - allows users to see what ingredients
/// they would need during meal planning without committing to a shopping list.
class ShoppingListPreviewBottomSheet extends StatelessWidget {
  final Map<String, List<Map<String, dynamic>>> groupedIngredients;

  const ShoppingListPreviewBottomSheet({
    super.key,
    required this.groupedIngredients,
  });

  @override
  Widget build(BuildContext context) {
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
              AppLocalizations.of(context)!.shoppingListPreviewTitle,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingMd),

          // Content
          Flexible(
            child: groupedIngredients.isEmpty
                ? _buildEmptyState(context)
                : _buildIngredientList(context),
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
              AppLocalizations.of(context)!.shoppingListPreviewEmpty,
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
    final sortedEntries = groupedIngredients.entries.toList()
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
        items.sort((a, b) =>
          (a['name'] as String).toLowerCase().compareTo(
            (b['name'] as String).toLowerCase()
          )
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
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingLg,
                vertical: DesignTokens.spacingSm,
              ),
              child: Row(
                children: [
                  // Ingredient name (flexible to take available space)
                  Expanded(
                    child: Text(
                      item['name'] as String,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacingMd),
                  // Quantity (fixed width on the right)
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

  String _formatQuantity(Map<String, dynamic> item, BuildContext context) {
    final quantity = item['quantity'] as double;
    final unitString = item['unit'] as String;

    // Convert to MeasurementUnit enum and get localized name
    final measurementUnit = MeasurementUnit.fromString(unitString);
    final localizedUnit = measurementUnit?.getLocalizedDisplayName(context) ?? unitString;

    // Format quantity (handles fractions, whole numbers, decimals)
    final formattedQuantity = QuantityFormatter.format(quantity);

    // Combine with localized unit
    return '$formattedQuantity $localizedUnit';
  }
}
