import 'package:flutter/material.dart';
import '../models/recipe.dart';

class AddSideDishDialog extends StatefulWidget {
  final List<Recipe> availableRecipes;
  final List<Recipe> excludeRecipes;
  final String? searchHint;
  final bool enableSearch;

  const AddSideDishDialog({
    super.key,
    required this.availableRecipes,
    this.excludeRecipes = const [],
    this.searchHint = 'Search side dishes...',
    this.enableSearch = true,
  });

  @override
  State<AddSideDishDialog> createState() => _AddSideDishDialogState();
}

class _AddSideDishDialogState extends State<AddSideDishDialog> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Recipe> get _filteredRecipes {
    // Get recipes excluding already selected ones
    final availableRecipes = widget.availableRecipes.where((recipe) {
      return !widget.excludeRecipes.any((excludedRecipe) => 
          excludedRecipe.id == recipe.id);
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
    Navigator.of(context).pop(recipe);
  }

  @override
  Widget build(BuildContext context) {
    final filteredRecipes = _filteredRecipes
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return AlertDialog(
      title: const Text('Add Side Dish'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.enableSearch) ...[
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: widget.searchHint,
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
                                ? 'No recipes found matching "$_searchQuery"'
                                : 'No available side dishes',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                              label: const Text('Clear search'),
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
                          onTap: () => _handleRecipeSelection(recipe),
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
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}