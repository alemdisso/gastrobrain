import 'package:flutter/material.dart';
import '../models/protein_type.dart';
import '../models/measurement_unit.dart';
import '../l10n/app_localizations.dart';
import '../utils/quantity_formatter.dart';

/// Ingredients tab for RecipeDetailsScreen.
///
/// Handles loading, error, empty, and populated states for the ingredient list.
/// Shows an "Ingredients for X servings" header when ingredients are present.
class RecipeDetailsIngredientsTab extends StatelessWidget {
  const RecipeDetailsIngredientsTab({
    super.key,
    required this.ingredients,
    required this.servings,
    required this.isLoading,
    required this.error,
    required this.onDeleteIngredient,
    required this.onEditIngredient,
    required this.onRetry,
    required this.onAdd,
  });

  final List<Map<String, dynamic>> ingredients;
  final int servings;
  final bool isLoading;
  final String? error;
  final void Function(Map<String, dynamic>) onDeleteIngredient;
  final void Function(Map<String, dynamic>) onEditIngredient;
  final VoidCallback onRetry;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return _buildErrorView(context, error!);
    }

    if (ingredients.isEmpty) {
      return _buildEmptyView(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            AppLocalizations.of(context)!.ingredientsForServings(servings),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: ingredients.length,
            itemBuilder: (context, index) =>
                _buildIngredientTile(context, ingredients[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientTile(
      BuildContext context, Map<String, dynamic> ingredient) {
    final proteinType = ingredient['protein_type'] != null
        ? ProteinType.values
            .firstWhere((e) => e.name == ingredient['protein_type'])
        : null;

    final effectiveUnitString =
        ingredient['unit_override'] ?? ingredient['unit'] ?? '';
    final measurementUnit = MeasurementUnit.fromString(effectiveUnitString);
    final quantity = ingredient['quantity'] as double;
    final localizedUnit =
        measurementUnit?.getLocalizedQuantityName(context, quantity) ??
            effectiveUnitString;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              proteinType != null ? Icons.egg_alt : Icons.food_bank,
              size: 20,
              color: proteinType?.isMainProtein == true ? Colors.red : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ingredient['name'],
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  if (quantity != 0)
                    Row(
                      children: [
                        Text(
                          '${QuantityFormatter.format(quantity)} $localizedUnit',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (ingredient['unit_override'] != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Tooltip(
                              message: AppLocalizations.of(context)!
                                  .unitOverridden(
                                MeasurementUnit.fromString(ingredient['unit'])
                                        ?.getLocalizedDisplayName(context) ??
                                    ingredient['unit'] ??
                                    AppLocalizations.of(context)!.noUnit,
                              ),
                            ),
                          ),
                      ],
                    ),
                  if (ingredient['preparation_notes'] != null)
                    Text(
                      ingredient['preparation_notes'],
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  onDeleteIngredient(ingredient);
                } else if (value == 'edit') {
                  onEditIngredient(ingredient);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.edit),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.delete),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            errorMessage,
            style: const TextStyle(fontSize: 18, color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(AppLocalizations.of(context)!.tryAgain),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.no_food, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noIngredientsAddedYet,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(AppLocalizations.of(context)!.addIngredient),
          ),
        ],
      ),
    );
  }
}
