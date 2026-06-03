import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../l10n/app_localizations.dart';
import '../utils/sorting_utils.dart';

/// Dialog for adding a side dish to the current meal.
///
/// Two tabs:
/// - Recipe (default): searchable list; tap a recipe to add and close
/// - Ingredient: ingredient search + qty/unit/notes form; explicit Add button
///
/// Returns one of:
///   `{'type': 'recipe',     'recipe': Recipe}`
///   `{'type': 'simple',     'ingredientId': String?, 'customName': String?,
///                            'quantity': double, 'unit': String?, 'notes': String?}`
/// Returns null on cancel or dismiss.
class UnifiedAddSideDialog extends StatefulWidget {
  final List<Recipe> availableRecipes;
  final List<Recipe> excludeRecipes;
  final List<Ingredient> availableIngredients;

  const UnifiedAddSideDialog({
    super.key,
    required this.availableRecipes,
    this.excludeRecipes = const [],
    required this.availableIngredients,
  });

  @override
  State<UnifiedAddSideDialog> createState() => _UnifiedAddSideDialogState();
}

class _UnifiedAddSideDialogState extends State<UnifiedAddSideDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // — Recipe tab state —
  final TextEditingController _recipeSearchController = TextEditingController();
  String _recipeQuery = '';

  // — Ingredient tab state —
  final TextEditingController _ingredientSearchController =
      TextEditingController();
  final TextEditingController _quantityController =
      TextEditingController(text: '1');
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _ingredientQuery = '';
  Ingredient? _selectedIngredient;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _recipeSearchController.dispose();
    _ingredientSearchController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ── Recipe tab helpers ───────────────────────────────────────────────────

  List<Recipe> get _filteredRecipes {
    final excludedIds = widget.excludeRecipes.map((r) => r.id).toSet();
    final available =
        widget.availableRecipes.where((r) => !excludedIds.contains(r.id));
    if (_recipeQuery.isEmpty) return SortingUtils.sortByName(available.toList(), (r) => r.name);
    return SortingUtils.sortByName(
      available
          .where((r) => r.name.toLowerCase().contains(_recipeQuery.toLowerCase()))
          .toList(),
      (r) => r.name,
    );
  }

  void _selectRecipe(Recipe recipe) {
    Navigator.of(context).pop({'type': 'recipe', 'recipe': recipe});
  }

  // ── Ingredient tab helpers ───────────────────────────────────────────────

  List<Ingredient> get _filteredIngredients {
    if (_ingredientQuery.isEmpty) return widget.availableIngredients;
    return widget.availableIngredients
        .where((i) =>
            i.name.toLowerCase().contains(_ingredientQuery.toLowerCase()))
        .toList();
  }

  bool get _hasFreeTextEntry =>
      _ingredientQuery.isNotEmpty && _filteredIngredients.isEmpty;

  bool get _canAddIngredient =>
      _selectedIngredient != null ||
      (_ingredientQuery.isNotEmpty && _hasFreeTextEntry);

  void _selectIngredient(Ingredient ingredient) {
    setState(() {
      _selectedIngredient = ingredient;
      _ingredientSearchController.text = ingredient.name;
      _ingredientQuery = '';
      _unitController.text =
          ingredient.unit?.getLocalizedQuantityName(context, 1.0) ?? '';
    });
  }

  void _clearIngredientSelection() {
    setState(() {
      _selectedIngredient = null;
      _ingredientSearchController.clear();
      _unitController.clear();
      _ingredientQuery = '';
    });
  }

  double get _parsedQuantity {
    final raw = _quantityController.text.trim().replaceAll(',', '.');
    return double.tryParse(raw) ?? 1.0;
  }

  void _confirmIngredient() {
    final quantity = _parsedQuantity;
    final unit = _unitController.text.trim();
    final notes = _notesController.text.trim();
    if (_selectedIngredient != null) {
      Navigator.of(context).pop({
        'type': 'simple',
        'ingredientId': _selectedIngredient!.id,
        'customName': null,
        'quantity': quantity,
        'unit': unit.isEmpty ? null : unit,
        'notes': notes.isEmpty ? null : notes,
      });
    } else if (_ingredientQuery.isNotEmpty) {
      Navigator.of(context).pop({
        'type': 'simple',
        'ingredientId': null,
        'customName': _ingredientQuery.trim(),
        'quantity': quantity,
        'unit': unit.isEmpty ? null : unit,
        'notes': notes.isEmpty ? null : notes,
      });
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40.0),
      child: SizedBox(
        height: 480,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                l10n.addSideDish,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(key: const Key('unified_side_recipe_tab'), text: l10n.sideDishAddRecipeTab),
                Tab(key: const Key('unified_side_ingredient_tab'), text: l10n.sideDishAddIngredientTab),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRecipeTab(l10n),
                  _buildIngredientTab(l10n),
                ],
              ),
            ),
            _buildActions(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          final onIngredientTab = _tabController.index == 1;
          return Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                key: const Key('unified_side_cancel_button'),
                onPressed: () => Navigator.of(context).pop(null),
                child: Text(l10n.cancel),
              ),
              if (onIngredientTab) ...[
                const SizedBox(width: 8),
                ElevatedButton(
                  key: const Key('unified_side_add_button'),
                  onPressed: _canAddIngredient ? _confirmIngredient : null,
                  child: Text(l10n.add),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  // ── Recipe tab ───────────────────────────────────────────────────────────

  Widget _buildRecipeTab(AppLocalizations l10n) {
    final recipes = _filteredRecipes;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            key: const Key('unified_side_recipe_search'),
            controller: _recipeSearchController,
            decoration: InputDecoration(
              hintText: l10n.searchSideDishesHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _recipeQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _recipeQuery = '';
                          _recipeSearchController.clear();
                        });
                      },
                    )
                  : null,
            ),
            onChanged: (v) => setState(() => _recipeQuery = v.trim()),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: recipes.isEmpty
                ? _buildRecipeEmptyState(l10n)
                : ListView.builder(
                    itemCount: recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = recipes[index];
                      final totalTime = recipe.prepTimeMinutes +
                          recipe.cookTimeMinutes +
                          recipe.marinatingTimeMinutes;
                      return ListTile(
                        key: Key('recipe_side_tile_${recipe.id}'),
                        leading: const Icon(Icons.restaurant_menu,
                            color: Colors.grey),
                        title: Text(recipe.name),
                        subtitle: Text(
                          '$totalTime min · ${l10n.difficulty}: ${recipe.difficulty}/5',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        onTap: () => _selectRecipe(recipe),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 4),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _recipeQuery.isNotEmpty
                ? l10n.noRecipesFoundMatching(_recipeQuery)
                : l10n.noAvailableSideDishes,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          if (_recipeQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => setState(() {
                _recipeQuery = '';
                _recipeSearchController.clear();
              }),
              icon: const Icon(Icons.clear),
              label: Text(l10n.clearSearch),
            ),
          ],
        ],
      ),
    );
  }

  // ── Ingredient tab ───────────────────────────────────────────────────────

  Widget _buildIngredientTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('unified_side_ingredient_search'),
            controller: _ingredientSearchController,
            decoration: InputDecoration(
              hintText: l10n.simpleSideSearchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _selectedIngredient != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearIngredientSelection,
                    )
                  : null,
            ),
            onChanged: (val) {
              if (_selectedIngredient != null) return;
              setState(() => _ingredientQuery = val.trim());
            },
          ),
          if (_selectedIngredient == null && _ingredientQuery.isNotEmpty)
            _buildIngredientSuggestions(l10n),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 90,
                child: TextField(
                  key: const Key('unified_side_quantity_field'),
                  controller: _quantityController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                  ],
                  decoration: InputDecoration(labelText: l10n.simpleSideQuantityLabel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  key: const Key('unified_side_unit_field'),
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
          TextField(
            key: const Key('unified_side_notes_field'),
            controller: _notesController,
            decoration: InputDecoration(hintText: l10n.simpleSideNotesHint),
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientSuggestions(AppLocalizations l10n) {
    final filtered = _filteredIngredients;
    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          l10n.simpleSideFreeTextHint(_ingredientQuery),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 160),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: filtered.length,
        itemBuilder: (_, index) {
          final ingredient = filtered[index];
          return ListTile(
            dense: true,
            title: Text(ingredient.name),
            subtitle: ingredient.unit != null
                ? Text(ingredient.unit!.getLocalizedQuantityName(context, 1.0))
                : null,
            onTap: () => _selectIngredient(ingredient),
          );
        },
      ),
    );
  }
}
