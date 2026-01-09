import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../l10n/app_localizations.dart';
import '../utils/sorting_utils.dart';

class AddSideDishDialog extends StatefulWidget {
  final List<Recipe> availableRecipes;
  final List<Recipe> excludeRecipes;
  final String? searchHint;
  final bool enableSearch;
  final Recipe? primaryRecipe;
  final List<Recipe> currentSideDishes;
  final Function(List<Recipe>)? onSideDishesChanged;

  const AddSideDishDialog({
    super.key,
    required this.availableRecipes,
    this.excludeRecipes = const [],
    this.searchHint,
    this.enableSearch = true,
    this.primaryRecipe,
    this.currentSideDishes = const [],
    this.onSideDishesChanged,
  });

  @override
  State<AddSideDishDialog> createState() => _AddSideDishDialogState();
}

class _AddSideDishDialogState extends State<AddSideDishDialog> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late List<Recipe> _currentSideDishes;

  @override
  void initState() {
    super.initState();
    _currentSideDishes = List.from(widget.currentSideDishes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Recipe> get _filteredRecipes {
    // Get recipes excluding already selected ones and current side dishes
    final excludedIds = [
      ...widget.excludeRecipes.map((r) => r.id),
      ..._currentSideDishes.map((r) => r.id),
    ];

    final availableRecipes = widget.availableRecipes.where((recipe) {
      return !excludedIds.contains(recipe.id);
    }).toList();

    // Apply search filter if enabled and query is not empty
    if (widget.enableSearch && _searchQuery.isNotEmpty) {
      return availableRecipes.where((recipe) {
        return recipe.name.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return availableRecipes;
  }

  void _handleRecipeSelection(Recipe recipe) {
    setState(() {
      _currentSideDishes.add(recipe);
      _searchQuery = '';
      _searchController.clear();
    });
    widget.onSideDishesChanged?.call(_currentSideDishes);
  }

  void _removeSideDish(Recipe recipe) {
    setState(() {
      _currentSideDishes.removeWhere((r) => r.id == recipe.id);
    });
    widget.onSideDishesChanged?.call(_currentSideDishes);
  }

  void _saveMeal() {
    Navigator.of(context).pop({
      'primaryRecipe': widget.primaryRecipe!,
      'additionalRecipes': _currentSideDishes,
    });
  }

  Widget _buildSelectedDishesCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 160),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Primary recipe section
                if (widget.primaryRecipe != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.restaurant, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.primaryRecipe!.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.mainDish,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // Divider if both primary and sides exist
                if (widget.primaryRecipe != null && _currentSideDishes.isNotEmpty)
                  const Divider(height: 20),

                // Side dishes section (scrollable)
                if (_currentSideDishes.isNotEmpty) ...[
                  Text(
                    AppLocalizations.of(context)!.sideDishesLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // All side dishes (scrollable within card)
                  ..._currentSideDishes
                      .map((recipe) => ListTile(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            leading: const Icon(
                              Icons.restaurant_menu,
                              size: 18,
                              color: Colors.grey,
                            ),
                            title: Text(recipe.name),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => _removeSideDish(recipe),
                              tooltip: AppLocalizations.of(context)!.remove,
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 8),
                          ))
                      .toList(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredRecipes = SortingUtils.sortByName(_filteredRecipes, (r) => r.name);

    // Determine if this is for multiple recipe management or single selection
    final isMultiRecipeMode = widget.primaryRecipe != null;
    final dialogTitle = isMultiRecipeMode
        ? AppLocalizations.of(context)!.manageSideDishes
        : AppLocalizations.of(context)!.addSideDish;

    return AlertDialog(
      title: Text(
        dialogTitle,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FIXED: Search field (always visible at top)
            if (widget.enableSearch) ...[
              TextField(
                key: const Key('add_side_dish_search_field'),
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: widget.searchHint ??
                      AppLocalizations.of(context)!.searchSideDishesHint,
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 12),
            ],

            // Selected dishes section (Card container)
            if (isMultiRecipeMode &&
                (_currentSideDishes.isNotEmpty || widget.primaryRecipe != null))
              Flexible(
                flex: 0,
                fit: FlexFit.loose,
                child: _buildSelectedDishesCard(),
              ),

            // DIVIDER: Visual separation
            const Divider(thickness: 1),

            // Section header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                AppLocalizations.of(context)!.addSideDish,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),

            // SCROLLABLE: Available recipes list
            Expanded(
              key: const Key('available_recipes_list'),
              child: filteredRecipes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.restaurant_menu,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? AppLocalizations.of(context)!
                                    .noRecipesFoundMatching(_searchQuery)
                                : AppLocalizations.of(context)!
                                    .noAvailableSideDishes,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                            textAlign: TextAlign.center,
                          ),
                          if (_searchQuery.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                              },
                              icon: const Icon(Icons.clear),
                              label: Text(
                                  AppLocalizations.of(context)!.clearSearch),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredRecipes.length,
                      itemBuilder: (context, index) {
                        final recipe = filteredRecipes[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.restaurant_menu,
                            color: Colors.grey,
                          ),
                          title: Text(recipe.name),
                          subtitle: Text(
                            '${recipe.prepTimeMinutes + recipe.cookTimeMinutes} min • '
                            'Difficulty: ${recipe.difficulty}/5',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          onTap: () => isMultiRecipeMode
                              ? _handleRecipeSelection(recipe)
                              : Navigator.of(context).pop(recipe),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        if (isMultiRecipeMode) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.back),
          ),
          ElevatedButton(
            onPressed: _saveMeal,
            child: Text(AppLocalizations.of(context)!.saveMeal),
          ),
        ] else ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
      ],
    );
  }
}
