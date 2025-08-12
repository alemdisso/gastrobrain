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
import 'weekly_plan_screen.dart';
import 'ingredients_screen.dart';
import 'tools_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load recipes when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecipeProvider>().loadRecipes();
    });
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
                  RadioListTile<String>(
                    title: Text(AppLocalizations.of(context)!.name),
                    value: 'name',
                    groupValue: tempSortBy,
                    onChanged: (value) => setState(() => tempSortBy = value),
                  ),
                  RadioListTile<String>(
                    title: Text(AppLocalizations.of(context)!.rating),
                    value: 'rating',
                    groupValue: tempSortBy,
                    onChanged: (value) => setState(() => tempSortBy = value),
                  ),
                  RadioListTile<String>(
                    title: Text(AppLocalizations.of(context)!.difficulty),
                    value: 'difficulty',
                    groupValue: tempSortBy,
                    onChanged: (value) => setState(() => tempSortBy = value),
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
                      value: selectedFrequency,
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
                              child: Text(frequency.getLocalizedDisplayName(context))
                            )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedFrequency = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
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
                            child:
                                Text(category.getLocalizedDisplayName(context)),
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

  Widget _buildRecipesScreen() {
    return Consumer<RecipeProvider>(
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

        // Build recipes list
        return RefreshIndicator(
          onRefresh: () => recipeProvider.loadRecipes(forceRefresh: true),
          child: ListView.builder(
            itemCount: recipeProvider.recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipeProvider.recipes[index];
              return RecipeCard(
                recipe: recipe,
                onEdit: () => _editRecipe(recipe),
                onDelete: () => _deleteRecipe(recipe),
                onCooked: () {
                  Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CookMealScreen(recipe: recipe),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildRecipesScreen(),
      const WeeklyPlanScreen(),
      const IngredientsScreen(),
      const ToolsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appTitle),
        actions: _selectedIndex == 0
            ? [
                IconButton(
                  icon: const Icon(Icons.sort),
                  onPressed: _showSortingDialog,
                  tooltip: AppLocalizations.of(context)!.sortRecipes,
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilterDialog,
                  tooltip: AppLocalizations.of(context)!.filterRecipesTooltip,
                ),
              ]
            : null,
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.menu_book),
            label: AppLocalizations.of(context)!.recipes,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_today),
            label: AppLocalizations.of(context)!.mealPlan,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.restaurant_menu),
            label: AppLocalizations.of(context)!.ingredients,
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Tools',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: _addRecipe,
              tooltip: AppLocalizations.of(context)!.addRecipe,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
