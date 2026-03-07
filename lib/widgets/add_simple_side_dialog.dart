import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ingredient.dart';
import '../l10n/app_localizations.dart';

/// Dialog for adding a simple ingredient side to a planned or recorded meal.
///
/// Supports two modes:
/// - DB-linked: user selects from [availableIngredients] list
/// - Free-text: user types a custom name when no match is found
///
/// Always shows quantity + unit fields. When a DB ingredient is selected,
/// unit is pre-filled from the ingredient's default unit.
///
/// Returns `Map<String, dynamic>` with keys:
///   - `ingredientId` (String?) — null for free-text entries
///   - `customName`   (String?) — non-null for free-text entries
///   - `quantity`     (double)  — amount (default 1.0)
///   - `unit`         (String?) — unit string, null if left blank
///   - `notes`        (String?) — optional notes
class AddSimpleSideDialog extends StatefulWidget {
  final List<Ingredient> availableIngredients;

  const AddSimpleSideDialog({
    super.key,
    required this.availableIngredients,
  });

  @override
  State<AddSimpleSideDialog> createState() => _AddSimpleSideDialogState();
}

class _AddSimpleSideDialogState extends State<AddSimpleSideDialog> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quantityController =
      TextEditingController(text: '1');
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _searchQuery = '';
  Ingredient? _selectedIngredient;

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<Ingredient> get _filtered {
    if (_searchQuery.isEmpty) return widget.availableIngredients;
    return widget.availableIngredients
        .where((i) => i.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  bool get _hasFreeTextEntry =>
      _searchQuery.isNotEmpty && _filtered.isEmpty;

  void _selectIngredient(Ingredient ingredient) {
    setState(() {
      _selectedIngredient = ingredient;
      _searchController.text = ingredient.name;
      _searchQuery = '';
      // Pre-fill unit from ingredient default
      _unitController.text = ingredient.unit?.value ?? '';
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIngredient = null;
      _searchController.clear();
      _unitController.clear();
      _searchQuery = '';
    });
  }

  double get _parsedQuantity {
    final raw = _quantityController.text.trim().replaceAll(',', '.');
    return double.tryParse(raw) ?? 1.0;
  }

  void _confirm() {
    final quantity = _parsedQuantity;
    final unit = _unitController.text.trim();
    final notes = _notesController.text.trim();
    if (_selectedIngredient != null) {
      Navigator.of(context).pop({
        'ingredientId': _selectedIngredient!.id,
        'customName': null,
        'quantity': quantity,
        'unit': unit.isEmpty ? null : unit,
        'notes': notes.isEmpty ? null : notes,
      });
    } else if (_searchQuery.isNotEmpty) {
      Navigator.of(context).pop({
        'ingredientId': null,
        'customName': _searchQuery.trim(),
        'quantity': quantity,
        'unit': unit.isEmpty ? null : unit,
        'notes': notes.isEmpty ? null : notes,
      });
    }
  }

  bool get _canConfirm =>
      _selectedIngredient != null ||
      (_searchQuery.isNotEmpty && _hasFreeTextEntry);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.addSimpleSideTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ingredient search / free-text
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: l10n.simpleSideSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _selectedIngredient != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSelection,
                      )
                    : null,
              ),
              onChanged: (val) {
                if (_selectedIngredient != null) return;
                setState(() => _searchQuery = val.trim());
              },
            ),
            if (_selectedIngredient == null && _searchQuery.isNotEmpty)
              _buildSuggestions(l10n),
            const SizedBox(height: 12),
            // Quantity + unit row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quantity
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[\d.,]')),
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.simpleSideQuantityLabel,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Unit
                Expanded(
                  child: TextField(
                    controller: _unitController,
                    decoration: InputDecoration(
                      labelText: l10n.simpleSideUnitLabel,
                      hintText: l10n.simpleSideUnitHint,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Notes
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: l10n.simpleSideNotesHint,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _canConfirm ? _confirm : null,
          child: Text(l10n.add),
        ),
      ],
    );
  }

  Widget _buildSuggestions(AppLocalizations l10n) {
    final filtered = _filtered;
    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          l10n.simpleSideFreeTextHint(_searchQuery),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 180),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: filtered.length,
        itemBuilder: (_, index) {
          final ingredient = filtered[index];
          return ListTile(
            dense: true,
            title: Text(ingredient.name),
            subtitle: ingredient.unit != null
                ? Text(ingredient.unit!.value)
                : null,
            onTap: () => _selectIngredient(ingredient),
          );
        },
      ),
    );
  }
}
