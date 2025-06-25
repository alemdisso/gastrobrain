import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/recipe.dart';
import '../models/recipe_category.dart';
import '../models/frequency_type.dart';
import '../widgets/recipe_card.dart';
import '../l10n/app_localizations.dart';
import 'add_recipe_screen.dart';
import 'edit_recipe_screen.dart';
import 'cook_meal_screen.dart';
import 'weekly_plan_screen.dart';
import 'ingredients_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Recipe> recipes = [];
  Map<String, int> recipeMealCounts = {}; // New map to store meal counts
  Map<String, DateTime?> lastCookedDates =
      {}; // New map to store last cooked dates

  String? _currentSortBy = 'name';
  String? _currentSortOrder = 'ASC';
  Map<String, dynamic> _filters = {};

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    final loadedRecipes = await _dbHelper.getRecipesWithSortAndFilter(
      sortBy: _currentSortBy,
      sortOrder: _currentSortOrder,
      filters: _filters.isEmpty ? null : _filters,
    );

    // Load all meal statistics at once
    final allMealCounts = await _dbHelper.getAllMealCounts();
    final allLastCooked = await _dbHelper.getAllLastCooked();

    setState(() {
      recipes = loadedRecipes;
      recipeMealCounts = allMealCounts;
      lastCookedDates = allLastCooked;
    });
  }

  Future<void> _addRecipe() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddRecipeScreen()),
    );

    if (result == true) {
      _loadRecipes();
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
      _loadRecipes();
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
      await _dbHelper.deleteRecipe(recipe.id);
      _loadRecipes();
    }
  }

  void _showSortingMenu() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(AppLocalizations.of(context)!.sortOptions),
              dense: true,
            ),
            ListTile(
              leading: Icon(_currentSortBy == 'name'
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked),
              title: Text(AppLocalizations.of(context)!.name),
              onTap: () {
                setState(() {
                  _currentSortBy = 'name';
                  _currentSortOrder = 'ASC';
                  _loadRecipes();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(_currentSortBy == 'rating'
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked),
              title: Text(AppLocalizations.of(context)!.rating),
              onTap: () {
                setState(() {
                  _currentSortBy = 'rating';
                  _currentSortOrder = 'DESC'; // Higher ratings first
                  _loadRecipes();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(_currentSortBy == 'difficulty'
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked),
              title: Text(AppLocalizations.of(context)!.difficulty),
              onTap: () {
                setState(() {
                  _currentSortBy = 'difficulty';
                  _loadRecipes();
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showFilterDialog() {
    int? selectedDifficulty = _filters['difficulty'];
    int? selectedRating = _filters['rating'];
    String? selectedFrequency = _filters['desired_frequency'];
    String? selectedCategory = _filters['category'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.filterRecipes),
              content: SingleChildScrollView(
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
                    _filters = {
                      if (selectedDifficulty != null)
                        'difficulty': selectedDifficulty,
                      if (selectedRating != null) 'rating': selectedRating,
                      if (selectedFrequency != null)
                        'desired_frequency': selectedFrequency,
                      if (selectedCategory != null)
                        'category': selectedCategory,
                    };
                    _loadRecipes();
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
    return ListView.builder(
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
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
                _loadRecipes();
              }
            });
          },
          mealCount: recipeMealCounts[recipe.id] ?? 0,
          lastCooked: lastCookedDates[recipe.id],
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
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appTitle),
        actions: _selectedIndex == 0
            ? [
                IconButton(
                  icon: const Icon(Icons.sort),
                  onPressed: _showSortingMenu,
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
