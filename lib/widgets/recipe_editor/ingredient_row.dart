import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/ingredient_match.dart';
import '../../utils/quantity_formatter.dart';
import 'parsed_ingredient.dart';

class IngredientRow extends StatelessWidget {
  final int index;
  final ParsedIngredient ingredient;
  final int parseGeneration;
  final void Function(double qty, double? qtyMax, String? error)
      onQuantityChanged;
  final void Function(String? unit) onUnitChanged;
  final void Function(String name) onNameChanged;
  final void Function(String? notes) onNotesChanged;
  final void Function(IngredientMatch? match) onMatchChanged;
  final VoidCallback onRemove;
  final VoidCallback onCreateNew;

  const IngredientRow({
    super.key,
    required this.index,
    required this.ingredient,
    required this.parseGeneration,
    required this.onQuantityChanged,
    required this.onUnitChanged,
    required this.onNameChanged,
    required this.onNotesChanged,
    required this.onMatchChanged,
    required this.onRemove,
    required this.onCreateNew,
  });

  @override
  Widget build(BuildContext context) {
    Color matchColor = Colors.grey;
    IconData matchIcon = Icons.help_outline;
    String matchText = 'No match';

    if (ingredient.isNewIngredient) {
      matchColor = Colors.blue;
      matchIcon = Icons.fiber_new;
      matchText = 'New ingredient - will be created';
    } else if (ingredient.selectedMatch != null) {
      matchColor = _matchColor(ingredient.selectedMatch!.confidenceLevel);
      matchIcon = _matchIcon(ingredient.selectedMatch!.confidenceLevel);
      matchText = switch (ingredient.selectedMatch!.confidenceLevel) {
        MatchConfidence.high => 'High confidence',
        MatchConfidence.medium => 'Medium confidence',
        MatchConfidence.low => 'Low confidence',
      };
    } else if (ingredient.matches.isNotEmpty) {
      final bestMatch = ingredient.matches.first;
      matchColor = _matchColor(bestMatch.confidenceLevel);
      matchIcon = _matchIcon(bestMatch.confidenceLevel);
      matchText =
          '${ingredient.matches.length} match${ingredient.matches.length > 1 ? "es" : ""} found - select one';
    } else {
      matchColor = Colors.red;
      matchIcon = Icons.error;
      matchText = 'No match - create new ingredient';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 72,
                  child: TextFormField(
                    key: ValueKey('qty_${index}_$parseGeneration'),
                    decoration: InputDecoration(
                      labelText: 'Qty',
                      hintText: 'e.g. 2 or 2–3',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      errorText: ingredient.qtyError,
                      errorStyle: const TextStyle(fontSize: 10),
                    ),
                    keyboardType: TextInputType.text,
                    initialValue: ingredient.quantityMax != null
                        ? QuantityFormatter.formatRange(
                            ingredient.quantity, ingredient.quantityMax!)
                        : QuantityFormatter.format(ingredient.quantity),
                    onChanged: (value) {
                      final trimmed = value.trim();
                      final rangeMatch = RegExp(
                        r'^(\d+(?:[.,]\d+)?)\s*[–-]\s*(\d+(?:[.,]\d+)?)$',
                      ).firstMatch(trimmed);
                      if (rangeMatch != null) {
                        final min = double.tryParse(
                                rangeMatch.group(1)!.replaceAll(',', '.')) ??
                            0.0;
                        final max = double.tryParse(
                                rangeMatch.group(2)!.replaceAll(',', '.')) ??
                            0.0;
                        if (max > min) {
                          onQuantityChanged(min, max, null);
                        } else {
                          onQuantityChanged(min, null, 'Min must be less than max');
                        }
                      } else {
                        onQuantityChanged(
                          double.tryParse(trimmed.replaceAll(',', '.')) ?? 0.0,
                          null,
                          null,
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 4),

                SizedBox(
                  width: 60,
                  child: TextFormField(
                    key: ValueKey('unit_${index}_$parseGeneration'),
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    initialValue: ingredient.unit ?? '',
                    onChanged: (value) =>
                        onUnitChanged(value.isEmpty ? null : value),
                  ),
                ),
                const SizedBox(width: 4),

                Expanded(
                  child: TextFormField(
                    key: ValueKey('name_${index}_$parseGeneration'),
                    decoration: const InputDecoration(
                      labelText: 'Ingredient Name',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    initialValue: ingredient.name,
                    onChanged: onNameChanged,
                  ),
                ),
                const SizedBox(width: 4),

                IconButton(
                  icon:
                      const Icon(Icons.delete, color: Colors.grey, size: 20),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: onRemove,
                  tooltip: 'Remove',
                ),
              ],
            ),

            if (ingredient.notes != null || ingredient.selectedMatch != null) ...[
              const SizedBox(height: 8),
              TextFormField(
                key: ValueKey('notes_${index}_$parseGeneration'),
                decoration: const InputDecoration(
                  labelText: 'Notes (descriptors)',
                  hintText: 'e.g., pequena, maduro, picado',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  isDense: true,
                ),
                initialValue: ingredient.notes ?? '',
                onChanged: (value) =>
                    onNotesChanged(value.isEmpty ? null : value),
              ),
            ],

            if (ingredient.name.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: matchColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border:
                      Border.all(color: matchColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(matchIcon, color: matchColor, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                matchText,
                                style: TextStyle(
                                  color: matchColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                        if (ingredient.selectedMatch != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '→ ${ingredient.selectedMatch!.ingredient.name}',
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(
                                  ingredient.selectedMatch!.ingredient.category
                                      .displayName,
                                  style: const TextStyle(fontSize: 10),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4),
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer
                                    .withValues(alpha: 0.5),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),

                    if (ingredient.matches.length > 1) ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<IngredientMatch>(
                        initialValue: ingredient.selectedMatch,
                        hint: Text(
                          'Select one of ${ingredient.matches.length} matches',
                          style: const TextStyle(fontSize: 12),
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Select match',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          isDense: true,
                        ),
                        items: ingredient.matches.map((match) {
                          return DropdownMenuItem<IngredientMatch>(
                            value: match,
                            child: Row(
                              children: [
                                Icon(
                                  _matchIcon(match.confidenceLevel),
                                  size: 16,
                                  color: _matchColor(match.confidenceLevel),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${match.ingredient.name} (${match.ingredient.category.displayName}) - ${(match.confidence * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: onMatchChanged,
                        isExpanded: true,
                      ),
                    ],

                    if (!ingredient.isNewIngredient &&
                        (ingredient.selectedMatch == null ||
                            (ingredient.matches.length == 1 &&
                                ingredient.selectedMatch != null &&
                                ingredient.selectedMatch!.matchType !=
                                    MatchType.exact &&
                                ingredient.selectedMatch!.matchType !=
                                    MatchType.caseInsensitive))) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ingredient.matches.isEmpty
                            ? ElevatedButton.icon(
                                onPressed: onCreateNew,
                                icon: const Icon(Icons.add, size: 18),
                                label: Text(AppLocalizations.of(context)!
                                    .createNewIngredient),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8),
                                ),
                              )
                            : OutlinedButton.icon(
                                onPressed: onCreateNew,
                                icon: const Icon(Icons.add, size: 18),
                                label: Text(AppLocalizations.of(context)!
                                    .noneOfTheseCreateNew),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                  side: const BorderSide(color: Colors.blue),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8),
                                ),
                              ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Color _matchColor(MatchConfidence confidence) => switch (confidence) {
        MatchConfidence.high => Colors.green,
        MatchConfidence.medium => Colors.orange,
        MatchConfidence.low => Colors.red,
      };

  static IconData _matchIcon(MatchConfidence confidence) =>
      switch (confidence) {
        MatchConfidence.high => Icons.check_circle,
        MatchConfidence.medium => Icons.warning_amber,
        MatchConfidence.low => Icons.error_outline,
      };
}
