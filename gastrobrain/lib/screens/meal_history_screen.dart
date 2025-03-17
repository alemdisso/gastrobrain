import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/meal.dart';
import '../database/database_helper.dart';
import '../core/errors/gastrobrain_exceptions.dart';
import 'cook_meal_screen.dart';

class MealHistoryScreen extends StatefulWidget {
  final Recipe recipe;

  const MealHistoryScreen({super.key, required this.recipe});

  @override
  State<MealHistoryScreen> createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends State<MealHistoryScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Meal> meals = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get meals that include this recipe (using junction table approach)
      final loadedMeals = await _dbHelper.getMealsForRecipe(widget.recipe.id);

      // For each meal, load its associated recipes
      for (final meal in loadedMeals) {
        if (meal.mealRecipes == null) {
          // Load associated recipes if not already loaded
          final mealRecipes = await _dbHelper.getMealRecipesForMeal(meal.id);
          meal.mealRecipes = mealRecipes;
        }
      }

      if (!mounted) return;

      setState(() {
        meals = loadedMeals;
        _isLoading = false;
      });
    } on NotFoundException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } on GastrobrainException catch (e) {
      setState(() {
        _errorMessage = 'Error loading meals: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred while loading meals';
        _isLoading = false;
      });
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'An error occurred',
            style: const TextStyle(fontSize: 18, color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadMeals,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No meals recorded yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('History: ${widget.recipe.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadMeals,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : meals.isEmpty
                  ? _buildEmptyView()
                  : ListView.builder(
                      itemCount: meals.length,
                      itemBuilder: (context, index) {
                        final meal = meals[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      meal.wasSuccessful
                                          ? Icons.check_circle
                                          : Icons.warning,
                                      color: meal.wasSuccessful
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatDateTime(meal.cookedAt),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    // Show recipe count if more than one
                                    if (meal.mealRecipes != null &&
                                        meal.mealRecipes!.length > 1) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primaryContainer,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${meal.mealRecipes!.length} recipes',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    const Icon(Icons.people, size: 16),
                                    const SizedBox(width: 4),
                                    Text('${meal.servings}'),
                                  ],
                                ),

                                // Display recipes using junction table information
                                if (meal.mealRecipes != null &&
                                    meal.mealRecipes!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children:
                                        meal.mealRecipes!.map((mealRecipe) {
                                      return FutureBuilder<Recipe?>(
                                        future: _dbHelper
                                            .getRecipe(mealRecipe.recipeId),
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData) {
                                            return const SizedBox.shrink();
                                          }
                                          final recipe = snapshot.data!;
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 4),
                                            child: Row(
                                              children: [
                                                if (mealRecipe.isPrimaryDish)
                                                  const Icon(Icons.restaurant,
                                                      size: 16,
                                                      color: Colors.green)
                                                else
                                                  const Icon(
                                                      Icons.restaurant_menu,
                                                      size: 16,
                                                      color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    recipe.name,
                                                    style: TextStyle(
                                                      fontWeight: mealRecipe
                                                              .isPrimaryDish
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                    ),
                                                  ),
                                                ),
                                                // Add note if this was from a plan
                                                if (mealRecipe.notes?.contains(
                                                        'From planned meal') ==
                                                    true)
                                                  Tooltip(
                                                    message: 'From meal plan',
                                                    child: Icon(
                                                        Icons.event_available,
                                                        size: 16,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary),
                                                  ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ]
                                // For backward compatibility, also show direct recipe reference if junction is empty
                                else if (meal.recipeId != null) ...[
                                  const SizedBox(height: 8),
                                  FutureBuilder<Recipe?>(
                                    future: _dbHelper.getRecipe(meal.recipeId!),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) {
                                        return const SizedBox.shrink();
                                      }
                                      return Row(
                                        children: [
                                          const Icon(Icons.restaurant,
                                              size: 16, color: Colors.green),
                                          const SizedBox(width: 4),
                                          Text(
                                            snapshot.data!.name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],

                                if (meal.actualPrepTime > 0 ||
                                    meal.actualCookTime > 0) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.timer, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Actual times - Prep: ${meal.actualPrepTime}min, Cook: ${meal.actualCookTime}min',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ],
                                if (meal.notes.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    meal.notes,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => CookMealScreen(recipe: widget.recipe),
            ),
          );
          if (result == true) {
            _loadMeals();
          }
        },
        tooltip: 'Cook Now',
        child: const Icon(Icons.add),
      ),
    );
  }
}
