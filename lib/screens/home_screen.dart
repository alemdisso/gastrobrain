import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/recipe.dart';
import '../models/recipe_category.dart';
import '../widgets/recipe_card.dart';
import 'add_recipe_screen.dart';
import 'edit_recipe_screen.dart';
import 'cook_meal_screen.dart';
import 'weekly_plan_screen.dart';

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

  String? _currentSortBy;
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
        title: const Text('Delete Recipe'),
        content: Text('Are you sure you want to delete "${recipe.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
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
            const ListTile(
              title: Text('Sort Options'),
              dense: true,
            ),
            ListTile(
              leading: Icon(_currentSortBy == 'name'
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked),
              title: const Text('Name'),
              onTap: () {
                setState(() {
                  _currentSortBy = 'name';
                  _loadRecipes();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(_currentSortBy == 'rating'
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked),
              title: const Text('Rating'),
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
              title: const Text('Difficulty'),
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
              title: const Text('Filter Recipes'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Difficulty'),
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
                    const Text('Minimum Rating'),
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
                      decoration: const InputDecoration(
                        labelText: 'Cooking Frequency',
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Any')),
                        ...[
                          'daily',
                          'weekly',
                          'biweekly',
                          'monthly',
                          'rarely'
                        ].map(
                            (f) => DropdownMenuItem(value: f, child: Text(f))),
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
                      decoration: const InputDecoration(
                        labelText: 'Category',
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Any')),
                        ...RecipeCategory.values.map(
                          (category) => DropdownMenuItem(
                            value: category.value,
                            child: Text(category.displayName),
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
                  child: const Text('Clear'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
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
                  child: const Text('Apply'),
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
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastrobrain'),
        actions: _selectedIndex == 0
            ? [
                IconButton(
                  icon: const Icon(Icons.sort),
                  onPressed: _showSortingMenu,
                  tooltip: 'Sort recipes',
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilterDialog,
                  tooltip: 'Filter recipes',
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Recipes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Meal Plan',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: _addRecipe,
              tooltip: 'Add Recipe',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
