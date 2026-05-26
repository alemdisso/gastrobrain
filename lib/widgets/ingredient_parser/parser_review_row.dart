import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/ingredient_match.dart';
import '../../utils/quantity_formatter.dart';
import '../recipe_editor/parsed_ingredient.dart';

/// A single parsed ingredient row with collapsed (read-only) and expanded
/// (inline correction) states.
///
/// Rows with no match or low confidence expand automatically so the user
/// sees they need attention without having to tap first.
class ParserReviewRow extends StatefulWidget {
  final int index;
  final ParsedIngredient ingredient;
  final int parseGeneration;
  final bool initiallyExpanded;
  final void Function(double qty, double? qtyMax, String? error) onQuantityChanged;
  final void Function(String? unit) onUnitChanged;
  final void Function(String name) onNameChanged;
  final void Function(String? notes) onNotesChanged;
  final void Function(IngredientMatch? match) onMatchChanged;
  final VoidCallback onMarkAsNew;
  final VoidCallback onRemove;
  final VoidCallback onCreateNew;

  const ParserReviewRow({
    super.key,
    required this.index,
    required this.ingredient,
    required this.parseGeneration,
    required this.initiallyExpanded,
    required this.onQuantityChanged,
    required this.onUnitChanged,
    required this.onNameChanged,
    required this.onNotesChanged,
    required this.onMatchChanged,
    required this.onMarkAsNew,
    required this.onRemove,
    required this.onCreateNew,
  });

  @override
  State<ParserReviewRow> createState() => _ParserReviewRowState();
}

class _ParserReviewRowState extends State<ParserReviewRow> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  // Re-expand automatically when parse generation changes (re-parse clears state)
  @override
  void didUpdateWidget(ParserReviewRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.parseGeneration != widget.parseGeneration) {
      _expanded = widget.initiallyExpanded;
    }
  }

  Color get _dotColor {
    final ing = widget.ingredient;
    if (ing.isNewIngredient) return Colors.amber.shade700;
    if (ing.selectedMatch != null) {
      return _matchColor(ing.selectedMatch!.confidenceLevel);
    }
    if (ing.matches.isNotEmpty) {
      return _matchColor(ing.matches.first.confidenceLevel);
    }
    return Colors.red;
  }

  bool get _needsAttention {
    final ing = widget.ingredient;
    return !ing.isNewIngredient &&
        ing.selectedMatch == null &&
        ing.matches.isEmpty &&
        ing.name.trim().isNotEmpty;
  }

  String _collapsedLabel(AppLocalizations l10n) {
    final ing = widget.ingredient;
    final qty = ing.quantityMax != null
        ? QuantityFormatter.formatRange(ing.quantity, ing.quantityMax!)
        : (ing.quantity == 0 ? '' : QuantityFormatter.format(ing.quantity));
    final unit = (ing.unit != null && ing.unit!.isNotEmpty) ? ing.unit! : '';
    final name = ing.name.isNotEmpty ? ing.name : '—';

    final parts = [
      if (qty.isNotEmpty) qty,
      if (unit.isNotEmpty) unit,
      name,
    ];
    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: _needsAttention
            ? BorderSide(color: Colors.red.shade300, width: 1.5)
            : BorderSide.none,
      ),
      child: Column(
        children: [
          // ── Collapsed row ──────────────────────────────────────────────
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Confidence dot
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Parsed summary text
                  Expanded(
                    child: Text(
                      _collapsedLabel(l10n),
                      style: theme.textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Expand / collapse chevron
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),

                  // Remove button
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    color: theme.colorScheme.onSurfaceVariant,
                    tooltip: l10n.remove,
                    onPressed: widget.onRemove,
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded inline fields ──────────────────────────────────────
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 10),

                  // Qty + Unit + Name row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 72,
                        child: TextFormField(
                          key: ValueKey('qty_${widget.index}_${widget.parseGeneration}'),
                          decoration: InputDecoration(
                            labelText: l10n.simpleSideQuantityLabel,
                            hintText: 'e.g. 2 or 2–3',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            errorText: widget.ingredient.qtyError,
                            errorStyle: const TextStyle(fontSize: 10),
                          ),
                          keyboardType: TextInputType.text,
                          initialValue: widget.ingredient.quantityMax != null
                              ? QuantityFormatter.formatRange(
                                  widget.ingredient.quantity,
                                  widget.ingredient.quantityMax!)
                              : QuantityFormatter.format(widget.ingredient.quantity),
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
                                widget.onQuantityChanged(min, max, null);
                              } else {
                                widget.onQuantityChanged(
                                    min, null, 'Min must be less than max');
                              }
                            } else {
                              widget.onQuantityChanged(
                                double.tryParse(trimmed.replaceAll(',', '.')) ?? 0.0,
                                null,
                                null,
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 6),

                      SizedBox(
                        width: 64,
                        child: TextFormField(
                          key: ValueKey('unit_${widget.index}_${widget.parseGeneration}'),
                          decoration: InputDecoration(
                            labelText: l10n.unit,
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                          ),
                          initialValue: widget.ingredient.unit ?? '',
                          onChanged: (value) =>
                              widget.onUnitChanged(value.isEmpty ? null : value),
                        ),
                      ),
                      const SizedBox(width: 6),

                      Expanded(
                        child: TextFormField(
                          key: ValueKey('name_${widget.index}_${widget.parseGeneration}'),
                          decoration: InputDecoration(
                            labelText: l10n.ingredientParserNameLabel,
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                          ),
                          initialValue: widget.ingredient.name,
                          onChanged: widget.onNameChanged,
                        ),
                      ),
                    ],
                  ),

                  // Notes field (always shown in expanded state)
                  const SizedBox(height: 8),
                  TextFormField(
                    key: ValueKey('notes_${widget.index}_${widget.parseGeneration}'),
                    decoration: InputDecoration(
                      labelText: l10n.notes,
                      hintText: 'e.g. diced, room temperature',
                      border: const OutlineInputBorder(),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      isDense: true,
                    ),
                    initialValue: widget.ingredient.notes ?? '',
                    onChanged: (value) =>
                        widget.onNotesChanged(value.isEmpty ? null : value),
                  ),

                  // Match status area
                  if (widget.ingredient.name.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _buildMatchArea(l10n, context),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMatchArea(AppLocalizations l10n, BuildContext context) {
    final ing = widget.ingredient;
    final Color statusColor;
    final String statusText;

    if (ing.isNewIngredient) {
      statusColor = Colors.amber.shade700;
      statusText = l10n.ingredientParserMatchNew;
    } else if (ing.selectedMatch != null) {
      statusColor = _matchColor(ing.selectedMatch!.confidenceLevel);
      statusText = _matchLabel(ing.selectedMatch!.confidenceLevel, l10n);
    } else if (ing.matches.isNotEmpty) {
      statusColor = _matchColor(ing.matches.first.confidenceLevel);
      statusText = _matchLabel(ing.matches.first.confidenceLevel, l10n);
    } else {
      statusColor = Colors.red;
      statusText = l10n.ingredientParserMatchNone;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status label
          Row(
            children: [
              Icon(_statusIcon(ing), color: statusColor, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Selected match name
          if (ing.selectedMatch != null) ...[
            const SizedBox(height: 4),
            Text(
              '→ ${ing.selectedMatch!.ingredient.name}',
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Match dropdown (when multiple candidates)
          if (ing.matches.length > 1) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<IngredientMatch>(
              initialValue: ing.selectedMatch,
              hint: Text(
                l10n.ingredientParserSelectMatchHint,
                style: const TextStyle(fontSize: 12),
              ),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                isDense: true,
              ),
              items: ing.matches.map((match) {
                return DropdownMenuItem<IngredientMatch>(
                  value: match,
                  child: Row(
                    children: [
                      Icon(
                        _matchIcon(match.confidenceLevel),
                        size: 14,
                        color: _matchColor(match.confidenceLevel),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '${match.ingredient.name} · '
                          '${(match.confidence * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: widget.onMatchChanged,
              isExpanded: true,
            ),
          ],

          // Action buttons for unresolved rows
          if (!ing.isNewIngredient &&
              ing.selectedMatch == null &&
              ing.matches.length <= 1) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onMarkAsNew,
                    icon: const Icon(Icons.fiber_new, size: 16),
                    label: Text(
                      l10n.ingredientParserMatchNew,
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.amber.shade700,
                      side: BorderSide(color: Colors.amber.shade700),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.onCreateNew,
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(
                      l10n.createNewIngredient,
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  IconData _statusIcon(ParsedIngredient ing) {
    if (ing.isNewIngredient) return Icons.fiber_new;
    if (ing.selectedMatch != null) {
      return _matchIcon(ing.selectedMatch!.confidenceLevel);
    }
    if (ing.matches.isNotEmpty) return _matchIcon(ing.matches.first.confidenceLevel);
    return Icons.error_outline;
  }

  static Color _matchColor(MatchConfidence confidence) => switch (confidence) {
        MatchConfidence.high => Colors.green,
        MatchConfidence.medium => Colors.orange,
        MatchConfidence.low => Colors.red,
      };

  static IconData _matchIcon(MatchConfidence confidence) =>
      switch (confidence) {
        MatchConfidence.high => Icons.check_circle_outline,
        MatchConfidence.medium => Icons.warning_amber_outlined,
        MatchConfidence.low => Icons.error_outline,
      };

  static String _matchLabel(MatchConfidence confidence, AppLocalizations l10n) =>
      switch (confidence) {
        MatchConfidence.high => l10n.ingredientParserMatchHigh,
        MatchConfidence.medium => l10n.ingredientParserMatchMedium,
        MatchConfidence.low => l10n.ingredientParserMatchLow,
      };
}
