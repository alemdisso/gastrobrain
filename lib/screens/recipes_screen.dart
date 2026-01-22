import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../models/recipe_category.dart';
import '../models/frequency_type.dart';
import '../widgets/recipe_card.dart';
import '../l10n/app_localizations.dart';
import '../core/providers/recipe_provider.dart';
import 'add_recipe_screen.dart';
import 'edit_recipe_screen.dart';
import 'cook_meal_screen.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load recipes when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecipeProvider>().loadRecipes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addRecipe() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddRecipeScreen()),
    );

    if (result == true) {
      if (mounted) {
        context.read<RecipeProvider>().loadRecipes(forceRefresh: true);
      }
    }
  }

  Future<void> _editRecipe(Recipe recipe) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditRecipeScreen(recipe: recipe),
      ),
    );

    if (result == true) {
      if (mounted) {
        context.read<RecipeProvider>().loadRecipes(forceRefresh: true);
      }
    }
  }

  Future<void> _deleteRecipe(Recipe recipe) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteRecipe),
        content:
            Text(AppLocalizations.of(context)!.deleteConfirmation(recipe.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final provider = context.read<RecipeProvider>();
      final success = await provider.deleteRecipe(recipe.id);

      if (!success && mounted) {
        // Show error message if deletion failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorOccurred),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSortingDialog() {
    final currentSortBy = context.read<RecipeProvider>().currentSortBy;
    String? tempSortBy = currentSortBy;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.sortOptions),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioGroup<String>(
                    groupValue: tempSortBy,
                    onChanged: (value) => setState(() => tempSortBy = value),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RadioListTile<String>(
                          title: Text(AppLocalizations.of(context)!.name),
                          value: 'name',
                        ),
                        RadioListTile<String>(
                          title: Text(AppLocalizations.of(context)!.rating),
                          value: 'rating',
                        ),
                        RadioListTile<String>(
                          title: Text(AppLocalizations.of(context)!.difficulty),
                          value: 'difficulty',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                TextButton(
                  onPressed: () {
                    if (tempSortBy != null) {
                      String sortOrder = 'ASC';
                      if (tempSortBy == 'rating') {
                        sortOrder = 'DESC'; // Higher ratings first
                      }
                      context.read<RecipeProvider>().setSorting(
                            sortBy: tempSortBy!,
                            sortOrder: sortOrder,
                          );
                    }
                    Navigator.pop(context);
                  },
                  child: Text(AppLocalizations.of(context)!.apply),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Checks if any filter is currently active (provider filters or search query)
  bool _hasAnyActiveFilter(RecipeProvider provider) {
    return provider.hasActiveFilters || _searchQuery.isNotEmpty;
  }

  /// Clears all active filters (both provider filters and search query)
  Future<void> _clearAllFilters() async {
    setState(() {
      _searchQuery = '';
      _searchController.clear(); // Clear the TextField as well
    });
    await context.read<RecipeProvider>().clearFilters();
  }

  /// Gets a human-readable description of active filters
  String _getFilterDescription(BuildContext context, RecipeProvider provider) {
    final List<String> filterParts = [];

    // Add search query if present
    if (_searchQuery.isNotEmpty) {
      filterParts.add(
          '${AppLocalizations.of(context)!.filterByName}: "$_searchQuery"');
    }

    // Add provider filters
    final filters = provider.filters;
    if (filters.containsKey('difficulty')) {
      filterParts.add(
          '${AppLocalizations.of(context)!.filterByDifficulty}: ${filters['difficulty']}');
    }
    if (filters.containsKey('rating')) {
      filterParts.add(
          '${AppLocalizations.of(context)!.filterByRating}: ${filters['rating']}+');
    }
    if (filters.containsKey('desired_frequency')) {
      filterParts.add('${AppLocalizations.of(context)!.filterByFrequency}');
    }
    if (filters.containsKey('category')) {
      filterParts.add('${AppLocalizations.of(context)!.filterByCategory}');
    }

    return filterParts.join(', ');
  }

  void _showFilterDialog() {
    final currentFilters = context.read<RecipeProvider>().filters;
    int? selectedDifficulty = currentFilters['difficulty'];
    int? selectedRating = currentFilters['rating'];
    String? selectedFrequency = currentFilters['desired_frequency'];
    String? selectedCategory = currentFilters['category'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.filterRecipes),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.6,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)!.difficulty),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(5, (index) {
                          return IconButton(
                            icon: Icon(
                              index < (selectedDifficulty ?? -1)
                                  ? Icons.battery_full
                                  : Icons.battery_0_bar,
                              color: index < (selectedDifficulty ?? -1)
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                selectedDifficulty = index + 1;
                              });
                            },
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      Text(AppLocalizations.of(context)!.minimumRating),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(5, (index) {
                          return IconButton(
                            icon: Icon(
                              index < (selectedRating ?? -1)
                                  ? Icons.star
                                  : Icons.star_border,
                              color: index < (selectedRating ?? -1)
                                  ? Colors.amber
                                  : Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                selectedRating = index + 1;
                              });
                            },
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: selectedFrequency,
                        decoration: InputDecoration(
                          labelText:
                              AppLocalizations.of(context)!.cookingFrequency,
                        ),
                        items: [
                          DropdownMenuItem(
                              value: null,
                              child: Text(AppLocalizations.of(context)!.any)),
                          ...FrequencyType.values.map((frequency) =>
                              DropdownMenuItem(
                                  value: frequency.value,
                                  child: Text(frequency
                                      .getLocalizedDisplayName(context)))),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedFrequency = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.category,
                        ),
                        items: [
                          DropdownMenuItem(
                              value: null,
                              child: Text(AppLocalizations.of(context)!.any)),
                          ...RecipeCategory.values.map(
                            (category) => DropdownMenuItem(
                              value: category.value,
                              child: Text(
                                  category.getLocalizedDisplayName(context)),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedCategory = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedDifficulty = null;
                      selectedRating = null;
                      selectedFrequency = null;
                      selectedCategory = null;
                    });
                  },
                  child: Text(AppLocalizations.of(context)!.clear),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                TextButton(
                  onPressed: () {
                    final newFilters = <String, dynamic>{
                      if (selectedDifficulty != null)
                        'difficulty': selectedDifficulty,
                      if (selectedRating != null) 'rating': selectedRating,
                      if (selectedFrequency != null)
                        'desired_frequency': selectedFrequency,
                      if (selectedCategory != null)
                        'category': selectedCategory,
                    };
                    context.read<RecipeProvider>().setFilters(newFilters);
                    Navigator.pop(context);
                  },
                  child: Text(AppLocalizations.of(context)!.apply),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<Recipe> _getFilteredRecipes(List<Recipe> recipes) {
    if (_searchQuery.isEmpty) {
      return recipes;
    }
    return recipes
        .where((recipe) =>
            recipe.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.recipes),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortingDialog,
            tooltip: AppLocalizations.of(context)!.sortRecipes,
          ),
          Consumer<RecipeProvider>(
            builder: (context, provider, child) {
              final hasActiveFilters = _hasAnyActiveFilter(provider);
              return IconButton(
                icon: Badge(
                  isLabelVisible: hasActiveFilters,
                  child: const Icon(Icons.filter_list),
                ),
                onPressed: _showFilterDialog,
                tooltip: AppLocalizations.of(context)!.filterRecipesTooltip,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchRecipes,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // Filter indicator banner
          Consumer<RecipeProvider>(
            builder: (context, provider, child) {
              if (!_hasAnyActiveFilter(provider)) {
                return const SizedBox.shrink();
              }

              final filteredCount = _getFilteredRecipes(provider.recipes).length;
              final totalCount = provider.totalRecipeCount;

              return Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.filter_list,
                          size: 20,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${AppLocalizations.of(context)!.filtersActive}: ${_getFilterDescription(context, provider)}',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.clear, size: 16),
                          label: Text(AppLocalizations.of(context)!.clearFilters),
                          onPressed: _clearAllFilters,
                          style: TextButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimaryContainer,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppLocalizations.of(context)!.showingXOfYRecipes(
                          filteredCount,
                          totalCount,
                        ),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: Consumer<RecipeProvider>(
              builder: (context, recipeProvider, child) {
                // Handle loading state
                if (recipeProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // Handle error state
                if (recipeProvider.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.errorOccurred,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          recipeProvider.error?.message ?? '',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            recipeProvider.clearError();
                            recipeProvider.loadRecipes(forceRefresh: true);
                          },
                          child: Text(AppLocalizations.of(context)!.retry),
                        ),
                      ],
                    ),
                  );
                }

                // Handle empty state
                if (!recipeProvider.hasData) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.noRecipesFound,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.addFirstRecipe,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                // Get filtered recipes
                final filteredRecipes =
                    _getFilteredRecipes(recipeProvider.recipes);

                // Build recipes list
                return RefreshIndicator(
                  onRefresh: () => recipeProvider.loadRecipes(forceRefresh: true),
                  child: ListView.builder(
                    padding: EdgeInsets.only(
                      bottom: max(80.0, MediaQuery.of(context).size.height * 0.3),
                    ),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filteredRecipes.length,
                    itemBuilder: (context, index) {
                      final recipe = filteredRecipes[index];
                      return RecipeCard(
                        recipe: recipe,
                        onEdit: () => _editRecipe(recipe),
                        onDelete: () => _deleteRecipe(recipe),
                        onCooked: () {
                          Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CookMealScreen(recipe: recipe),
                            ),
                          ).then((value) {
                            if (value == true) {
                              recipeProvider.loadRecipes(forceRefresh: true);
                            }
                          });
                        },
                        mealCount: recipeProvider.getMealCount(recipe.id),
                        lastCooked: recipeProvider.getLastCookedDate(recipe.id),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRecipe,
        tooltip: AppLocalizations.of(context)!.addRecipe,
        child: const Icon(Icons.add),
      ),
    );
  }
}