// lib/screens/weekly_plan_screen.dart

import 'package:flutter/material.dart';
import '../widgets/weekly_calendar_widget.dart';
import '../models/meal_plan.dart';
import '../models/meal_plan_item.dart';
import '../database/database_helper.dart';
import '../models/recipe.dart';
import '../utils/id_generator.dart';

class WeeklyPlanScreen extends StatefulWidget {
  const WeeklyPlanScreen({super.key});

  @override
  State<WeeklyPlanScreen> createState() => _WeeklyPlanScreenState();
}

class _WeeklyPlanScreenState extends State<WeeklyPlanScreen> {
  DateTime _currentWeekStart = _getMonday(DateTime.now());
  MealPlan? _currentMealPlan;
  bool _isLoading = true;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Recipe> _availableRecipes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  static DateTime _getMonday(DateTime date) {
    final int weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
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

  Future<void> _handleSlotTap(DateTime date, String mealType) async {
    final recipes = _availableRecipes;
    if (recipes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No recipes available. Add some recipes first.')),
      );
      return;
    }

    // Show recipe selection dialog
    final selectedRecipe = await showDialog<Recipe>(
      context: context,
      builder: (context) => _RecipeSelectionDialog(recipes: recipes),
    );

    if (selectedRecipe != null) {
      // Create or update meal plan
      if (_currentMealPlan == null) {
        // Create new meal plan for this week
        final newPlan = MealPlan.forWeek(
          IdGenerator.generateId(),
          _currentWeekStart,
        );

        // Add the selected recipe to the plan
        final planItem = MealPlanItem(
          id: IdGenerator.generateId(),
          mealPlanId: newPlan.id,
          recipeId: selectedRecipe.id,
          plannedDate: MealPlanItem.formatPlannedDate(date),
          mealType: mealType,
        );

        newPlan.addItem(planItem);

        // Save to database
        await _dbHelper.insertMealPlan(newPlan);
        await _dbHelper.insertMealPlanItem(planItem);

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
        final planItem = MealPlanItem(
          id: IdGenerator.generateId(),
          mealPlanId: _currentMealPlan!.id,
          recipeId: selectedRecipe.id,
          plannedDate: MealPlanItem.formatPlannedDate(date),
          mealType: mealType,
        );

        _currentMealPlan!.addItem(planItem);

        // Save to database
        await _dbHelper.insertMealPlanItem(planItem);
        await _dbHelper.updateMealPlan(_currentMealPlan!);

        setState(() {});
      }
    }
  }

  Future<void> _handleMealTap(
      DateTime date, String mealType, String recipeId) async {
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
        setState(() {});
      }
    }
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
                  ),
          ),
        ],
      ),
    );
  }
}

// Helper dialog for recipe selection
class _RecipeSelectionDialog extends StatefulWidget {
  final List<Recipe> recipes;

  const _RecipeSelectionDialog({required this.recipes});

  @override
  _RecipeSelectionDialogState createState() => _RecipeSelectionDialogState();
}

class _RecipeSelectionDialogState extends State<_RecipeSelectionDialog> {
  String _searchQuery = '';

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
            TextField(
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
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: filteredRecipes.length,
                itemBuilder: (context, index) {
                  final recipe = filteredRecipes[index];
                  return ListTile(
                    title: Text(recipe.name),
                    subtitle: Row(
                      children: [
                        // Display difficulty rating
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < recipe.difficulty
                                ? Icons.star
                                : Icons.star_border,
                            size: 14,
                            color: i < recipe.difficulty
                                ? Colors.amber
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                            '${recipe.prepTimeMinutes + recipe.cookTimeMinutes} min'),
                      ],
                    ),
                    onTap: () => Navigator.pop(context, recipe),
                  );
                },
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
}
