import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../l10n/app_localizations.dart';

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

  Widget _buildPrimaryRecipeSection() {
    if (widget.primaryRecipe == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.restaurant, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${widget.primaryRecipe!.name} (${AppLocalizations.of(context)!.mainDish})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSideDishesSection() {
    if (_currentSideDishes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.sideDishesLabel,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        ..._currentSideDishes.map((recipe) => ListTile(
              leading: const Icon(Icons.restaurant_menu, color: Colors.grey),
              title: Text(recipe.name),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => _removeSideDish(recipe),
              ),
              contentPadding: EdgeInsets.zero,
            )),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredRecipes = _filteredRecipes
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

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
            // Upper sections (scrollable when needed)
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Primary recipe section (only in multi-recipe mode)
                    if (isMultiRecipeMode) _buildPrimaryRecipeSection(),

                    // Current side dishes section (only in multi-recipe mode)
                    if (isMultiRecipeMode) _buildCurrentSideDishesSection(),

                    // Add side dish section
                    Text(
                      AppLocalizations.of(context)!.addSideDish,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    if (widget.enableSearch) ...[
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: widget.searchHint ??
                              AppLocalizations.of(context)!
                                  .searchSideDishesHint,
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
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),

            // Recipe list (always visible, takes remaining space)
            Expanded(
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
