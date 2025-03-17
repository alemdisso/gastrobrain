// lib/screens/weekly_plan_screen.dart

import 'package:flutter/material.dart';
import '../models/meal_recipe.dart';
import '../models/meal_plan.dart';
import '../models/meal_plan_item.dart';
import '../models/meal_plan_item_recipe.dart';
import '../models/recipe.dart';
import '../database/database_helper.dart';
import '../core/services/recommendation_service.dart';
import '../core/services/recommendation_service_extension.dart';
import '../core/services/snackbar_service.dart';
import '../widgets/weekly_calendar_widget.dart';
import '../widgets/meal_recording_dialog.dart';
import '../utils/id_generator.dart';

class WeeklyPlanScreen extends StatefulWidget {
  const WeeklyPlanScreen({super.key});

  @override
  State<WeeklyPlanScreen> createState() => _WeeklyPlanScreenState();
}

class _WeeklyPlanScreenState extends State<WeeklyPlanScreen> {
  DateTime _currentWeekStart = _getFriday(DateTime.now());
  MealPlan? _currentMealPlan;
  bool _isLoading = true;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Recipe> _availableRecipes = [];
  final ScrollController _scrollController = ScrollController();
  late RecommendationService _recommendationService;
  // Cache for recommendations to improve performance
  final Map<String, List<Recipe>> _recommendationCache = {};

  // Helper method to create cache key
  String _getRecommendationCacheKey(DateTime date, String mealType) {
    return '${date.toIso8601String()}-$mealType';
  }

  @override
  void initState() {
    super.initState();
    // Initialize the recommendation service
    _recommendationService = _dbHelper.createRecommendationService();
    _loadData();
  }

  static DateTime _getFriday(DateTime date) {
    final int weekday = date.weekday;
    // If today is Friday (weekday 5), subtract 0; otherwise calculate offset
    final daysToSubtract = weekday < 5
        ? weekday + 2 // Go back to previous Friday
        : weekday - 5; // Friday is day 5

    return date.subtract(Duration(days: daysToSubtract));
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load meal plan for current week
      final mealPlan = await _dbHelper.getMealPlanForWeek(_currentWeekStart);

      // Load available recipes for selection
      final recipes = await _dbHelper.getAllRecipes();

      if (mounted) {
        setState(() {
          _currentMealPlan = mealPlan;
          _availableRecipes = recipes;
          _isLoading = false;
        });

        // Clear the recommendation cache when meal plan changes
        _recommendationCache.clear();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _changeWeek(int weekOffset) {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(Duration(days: weekOffset * 7));
      _currentMealPlan = null;
    });
    _loadData();
  }

  /// Build context for recipe recommendations based on the current meal plan
  Future<Map<String, dynamic>> _buildRecommendationContext({
    DateTime? forDate,
    String? mealType,
  }) async {
    final context = <String, dynamic>{
      'forDate': forDate,
      'mealType': mealType,
    };

    // If we have a meal plan, analyze it for context
    if (_currentMealPlan != null) {
      // Get recipes already used in the current plan
      final List<String> usedRecipeIds = [];

      // Get protein types already used in this week's plan
      // ignore: unused_local_variable
      final List<String> usedProteinIds = [];

      // Collect recipes from meal plan
      for (final item in _currentMealPlan!.items) {
        if (item.mealPlanItemRecipes != null) {
          for (final mealRecipe in item.mealPlanItemRecipes!) {
            usedRecipeIds.add(mealRecipe.recipeId);

            // Get recipe details to check protein types
            final recipe = await _dbHelper.getRecipe(mealRecipe.recipeId);
            if (recipe != null) {
              // This is a simple approach - for a more comprehensive solution,
              // we would analyze the recipe's ingredients for protein types
              // For now, we'll just collect the recipe IDs
            }
          }
        }
      }

      context['excludeIds'] = usedRecipeIds;
    }

    return context;
  }

  /// Get recommendations for a specific meal slot (with caching)
  Future<List<Recipe>> getSlotRecommendations(DateTime date, String mealType,
      {int count = 5}) async {
    final cacheKey = _getRecommendationCacheKey(date, mealType);

    // Check if we have cached recommendations
    if (_recommendationCache.containsKey(cacheKey)) {
      return _recommendationCache[cacheKey]!;
    }

    // Build context for recommendations
    final context = await _buildRecommendationContext(
      forDate: date,
      mealType: mealType,
    );

    // Get recommendations
    final recommendations = await _recommendationService.getRecommendations(
      count: count,
      excludeIds: context['excludeIds'] ?? [],
      forDate: date,
      mealType: mealType,
    );

    // Cache the recommendations
    _recommendationCache[cacheKey] = recommendations;

    return recommendations;
  }

  Future<void> _handleSlotTap(DateTime date, String mealType) async {
    final recipes = _availableRecipes;
    if (recipes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No recipes available. Add some recipes first.')),
      );
      return;
    }

    // Get recommendations for this slot
    final recommendations = await getSlotRecommendations(date, mealType);

    // Check if widget is still mounted before showing dialog
    if (!mounted) return;

    // Show recipe selection dialog with recommendations
    final selectedRecipe = await showDialog<Recipe>(
      context: context,
      builder: (context) => _RecipeSelectionDialog(
        recipes: recipes,
        recommendations: recommendations,
      ),
    );

    if (selectedRecipe != null) {
      // Create or update meal plan
      if (_currentMealPlan == null) {
        // Create new meal plan for this week
        final newPlanId = IdGenerator.generateId();
        final newPlan = MealPlan.forWeek(
          newPlanId,
          _currentWeekStart,
        );

        // Add the selected recipe to the plan
        final planItemId = IdGenerator.generateId();
        final planItem = MealPlanItem(
          id: planItemId,
          mealPlanId: newPlan.id,
          plannedDate: MealPlanItem.formatPlannedDate(date),
          mealType: mealType,
        );

        // Create junction record for the recipe
        final junction = MealPlanItemRecipe(
          mealPlanItemId: planItemId,
          recipeId: selectedRecipe.id,
          isPrimaryDish: true,
        );

        // Set the recipes list for the item
        planItem.mealPlanItemRecipes = [junction];

        newPlan.addItem(planItem);

        // Save to database
        await _dbHelper.insertMealPlan(newPlan);
        await _dbHelper.insertMealPlanItem(planItem);

        // Save the junction record
        await _dbHelper.insertMealPlanItemRecipe(junction);

        setState(() {
          _currentMealPlan = newPlan;
        });
      } else {
        // Check if there's already a meal in this slot
        final existingItems =
            _currentMealPlan!.getItemsForDateAndMealType(date, mealType);

        if (existingItems.isNotEmpty) {
          // Remove existing items for this slot
          for (final item in existingItems) {
            await _dbHelper.deleteMealPlanItem(item.id);
            _currentMealPlan!.removeItem(item.id);
          }
        }

        // Add the new meal to the plan
        final planItemId = IdGenerator.generateId();
        final planItem = MealPlanItem(
          id: planItemId,
          mealPlanId: _currentMealPlan!.id,
          plannedDate: MealPlanItem.formatPlannedDate(date),
          mealType: mealType,
        );

        // Create junction record for the recipe
        final junction = MealPlanItemRecipe(
          mealPlanItemId: planItemId,
          recipeId: selectedRecipe.id,
          isPrimaryDish: true,
        );

        // Set the recipes list for the item
        planItem.mealPlanItemRecipes = [junction];

        _currentMealPlan!.addItem(planItem);

        // Save to database
        await _dbHelper.insertMealPlanItem(planItem);

        // Save the junction record
        await _dbHelper.insertMealPlanItemRecipe(junction);

        await _dbHelper.updateMealPlan(_currentMealPlan!);

        setState(() {
          // Force a reload to ensure the calendar widget refreshes
          _loadData();
        });
      }
    }
  }

  Future<void> _handleMealTap(
      DateTime date, String mealType, String recipeId) async {
    // First check if the meal has been cooked
    bool mealCooked = false;
    if (_currentMealPlan != null) {
      final items =
          _currentMealPlan!.getItemsForDateAndMealType(date, mealType);
      mealCooked = items.isNotEmpty && items[0].hasBeenCooked;
    }

    // Show options for the existing meal
    final action = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Meal Options'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'view'),
            child: const Text('View Recipe Details'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'change'),
            child: const Text('Change Recipe'),
          ),
          if (!mealCooked)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'cooked'),
              child: const Text('Mark as Cooked'),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'remove'),
            child: const Text('Remove from Plan'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (action == null) return;

    if (action == 'view') {
      // Implement viewing recipe details
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('View recipe details (not implemented)')),
        );
      }
    } else if (action == 'change') {
      // Reuse the slot tap handler to change the recipe
      await _handleSlotTap(date, mealType);
    } else if (action == 'cooked') {
      // Mark the meal as cooked
      await _handleMarkAsCooked(date, mealType, recipeId);
    } else if (action == 'remove') {
      // Remove the meal from the plan
      if (_currentMealPlan != null) {
        final items =
            _currentMealPlan!.getItemsForDateAndMealType(date, mealType);

        for (final item in items) {
          await _dbHelper.deleteMealPlanItem(item.id);
          _currentMealPlan!.removeItem(item.id);
        }

        await _dbHelper.updateMealPlan(_currentMealPlan!);
        setState(() {
          // Force a reload to ensure the calendar widget refreshes
          _loadData();
        });
      }
    }
  }

  Future<void> _handleMarkAsCooked(
      DateTime date, String mealType, String recipeId) async {
    try {
      // First, get details of the meal plan item
      final items =
          _currentMealPlan?.getItemsForDateAndMealType(date, mealType) ?? [];
      if (items.isEmpty) {
        if (mounted) {
          SnackbarService.showError(context, 'Planned meal not found');
        }
        return;
      }

      // Get the primary recipe
      final recipe = await _dbHelper.getRecipe(recipeId);
      if (recipe == null) {
        if (mounted) {
          SnackbarService.showError(context, 'Recipe not found');
        }
        return;
      }

      // Get any additional recipes already in the plan
      List<Recipe> additionalRecipes = [];
      if (items[0].mealPlanItemRecipes != null) {
        for (final mealRecipe in items[0].mealPlanItemRecipes!) {
          if (mealRecipe.recipeId != recipeId) {
            // Skip the primary recipe
            final additionalRecipe =
                await _dbHelper.getRecipe(mealRecipe.recipeId);
            if (additionalRecipe != null) {
              additionalRecipes.add(additionalRecipe);
            }
          }
        }
      }

      // Show the meal recording dialog
      Map<String, dynamic>? result;
      if (mounted) {
        result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => MealRecordingDialog(
            primaryRecipe: recipe,
            additionalRecipes: additionalRecipes,
            plannedDate: date,
            notes: items[0].notes,
          ),
        );
      }

      if (result == null) return; // User cancelled or widget unmounted

      // Extract the data from the result
      final DateTime cookedAt = result['cookedAt'];
      final int servings = result['servings'];
      final String notes = result['notes'];
      final bool wasSuccessful = result['wasSuccessful'];
      final double actualPrepTime = result['actualPrepTime'];
      final double actualCookTime = result['actualCookTime'];
      final Recipe primaryRecipe = result['primaryRecipe'];
      final List<Recipe> finalAdditionalRecipes = result['additionalRecipes'];

      // Create the meal with a new ID
      final mealId = IdGenerator.generateId();

      // Begin a transaction
      await _dbHelper.database.then((db) async {
        return await db.transaction((txn) async {
          // Create meal object WITHOUT direct recipe_id (using null)
          final mealMap = {
            'id': mealId,
            'recipe_id': null, // Use junction table approach
            'cooked_at': cookedAt.toIso8601String(),
            'servings': servings,
            'notes': notes,
            'was_successful': wasSuccessful ? 1 : 0,
            'actual_prep_time': actualPrepTime,
            'actual_cook_time': actualCookTime,
          };

          // Insert the meal
          await txn.insert('meals', mealMap);

          // Create and insert primary recipe association
          final primaryMealRecipe = MealRecipe(
            mealId: mealId,
            recipeId: primaryRecipe.id,
            isPrimaryDish: true,
            notes: 'Main dish',
          );

          // Insert the primary junction record
          await txn.insert('meal_recipes', primaryMealRecipe.toMap());

          // Insert all additional recipes as side dishes
          for (final recipe in finalAdditionalRecipes) {
            final sideDishMealRecipe = MealRecipe(
              mealId: mealId,
              recipeId: recipe.id,
              isPrimaryDish: false,
              notes: 'Side dish',
            );

            await txn.insert('meal_recipes', sideDishMealRecipe.toMap());
          }

          // Update the meal plan item to mark it as cooked
          await txn.update(
            'meal_plan_items',
            {'has_been_cooked': 1},
            where: 'id = ?',
            whereArgs: [items[0].id],
          );
        });
      });

      if (mounted) {
        SnackbarService.showSuccess(context, 'Meal marked as cooked');
        // Refresh data to show updated meal history
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.showError(context, 'Error marking meal as cooked: $e');
      }
    }
  }

  void _handleDaySelected(DateTime selectedDate, int selectedDayIndex) {
    // You can use this to update UI elements, scroll to specific sections,
    // or perform any other actions needed when a day is selected

    // For example, you might want to show a summary of meals for this day
    // or highlight it in another part of your UI

    // You can also store the selected date in state if needed
    setState(() {
      // _selectedDate = selectedDate;
    });
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        '${_currentWeekStart.day}/${_currentWeekStart.month}/${_currentWeekStart.year}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Meal Plan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Week navigation controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.navigate_before),
                  onPressed: () => _changeWeek(-1),
                  tooltip: 'Previous Week',
                ),
                Text(
                  'Week of $formattedDate',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.navigate_next),
                  onPressed: () => _changeWeek(1),
                  tooltip: 'Next Week',
                ),
              ],
            ),
          ),

          // Main calendar widget
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : WeeklyCalendarWidget(
                    weekStartDate: _currentWeekStart,
                    mealPlan: _currentMealPlan,
                    onSlotTap: _handleSlotTap,
                    onMealTap: _handleMealTap,
                    onDaySelected: _handleDaySelected,
                    scrollController: _scrollController, // Pass the controller
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // Clear any resources used by the recommendation service if needed
    _recommendationCache.clear();
    super.dispose();
  }
}

// Helper dialog for recipe selection
class _RecipeSelectionDialog extends StatefulWidget {
  final List<Recipe> recipes;
  final List<Recipe> recommendations;

  const _RecipeSelectionDialog({
    required this.recipes,
    this.recommendations = const [],
  });

  @override
  _RecipeSelectionDialogState createState() => _RecipeSelectionDialogState();
}

class _RecipeSelectionDialogState extends State<_RecipeSelectionDialog>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Initialize tab controller for the two tabs
    _tabController = TabController(length: 2, vsync: this);
    // Start on the Recommended tab if we have recommendations
    if (widget.recommendations.isNotEmpty) {
      _tabController.index = 0;
    } else {
      _tabController.index = 1; // Default to All Recipes if no recommendations
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredRecipes = widget.recipes
        .where((recipe) =>
            recipe.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Recipe',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Tab bar for switching between Recommended and All Recipes
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Recommended'),
                Tab(text: 'All Recipes'),
              ],
            ),

            const SizedBox(height: 16),

            // Only show search on All Recipes tab - with AnimatedBuilder to respond to tab changes
            AnimatedBuilder(
              animation: _tabController,
              builder: (context, child) {
                return _tabController.index == 1
                    ? TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search recipes...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      )
                    : const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Recommended tab
                  widget.recommendations.isEmpty
                      ? const Center(
                          child: Text('No recommendations available'),
                        )
                      : ListView.builder(
                          itemCount: widget.recommendations.length,
                          itemBuilder: (context, index) {
                            final recipe = widget.recommendations[index];
                            return _buildRecipeListTile(recipe);
                          },
                        ),

                  // All Recipes tab
                  ListView.builder(
                    itemCount: filteredRecipes.length,
                    itemBuilder: (context, index) {
                      final recipe = filteredRecipes[index];
                      return _buildRecipeListTile(recipe);
                    },
                  ),
                ],
              ),
            ),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build consistent recipe list tiles
  Widget _buildRecipeListTile(Recipe recipe) {
    return ListTile(
      title: Text(recipe.name),
      subtitle: Row(
        children: [
          // Display difficulty rating
          ...List.generate(
            5,
            (i) => Icon(
              i < recipe.difficulty ? Icons.star : Icons.star_border,
              size: 14,
              color: i < recipe.difficulty ? Colors.amber : Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          Text('${recipe.prepTimeMinutes + recipe.cookTimeMinutes} min'),
        ],
      ),
      onTap: () => Navigator.pop(context, recipe),
    );
  }
}
