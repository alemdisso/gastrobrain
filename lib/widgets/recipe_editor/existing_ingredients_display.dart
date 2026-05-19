import 'package:flutter/material.dart';
import '../../models/ingredient_category.dart';
import '../../utils/quantity_formatter.dart';

class ExistingIngredientsDisplay extends StatelessWidget {
  final List<Map<String, dynamic>> existingIngredients;
  final bool isLoading;

  const ExistingIngredientsDisplay({
    super.key,
    required this.existingIngredients,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(
                'Loading existing ingredients...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (existingIngredients.isEmpty) {
      return Card(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No ingredients yet. Add ingredients below to get started.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Current Ingredients (${existingIngredients.length}) - Already in Recipe',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: existingIngredients.map((ingredientMap) {
                  final name = ingredientMap['name'] as String? ?? 'Unknown';
                  final quantity = ingredientMap['quantity'] as double? ?? 0.0;
                  final quantityMax = ingredientMap['quantity_max'] as double?;
                  final unit = ingredientMap['unit'] as String?;
                  final category =
                      ingredientMap['category'] as String? ?? 'other';

                  final quantityStr = quantity == 0
                      ? ''
                      : quantityMax != null
                          ? QuantityFormatter.formatRange(quantity, quantityMax)
                          : QuantityFormatter.format(quantity);
                  final quantityDisplay = quantityStr.isNotEmpty
                      ? '$quantityStr${unit != null ? ' $unit' : ''}'
                      : 'to taste';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 8, color: Colors.green),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '$name ($quantityDisplay)',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Chip(
                          label: Text(
                            _getCategoryDisplayName(category),
                            style: const TextStyle(fontSize: 11),
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .secondaryContainer
                              .withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryDisplayName(String categoryValue) {
    try {
      final category = IngredientCategory.values.firstWhere(
        (c) => c.value == categoryValue,
        orElse: () => IngredientCategory.other,
      );
      return category.displayName;
    } catch (e) {
      return 'Other';
    }
  }
}
