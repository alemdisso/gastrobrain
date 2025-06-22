import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/meal.dart';
import '../models/meal_recipe.dart';
import '../database/database_helper.dart';
import '../core/errors/gastrobrain_exceptions.dart';
import '../widgets/edit_meal_recording_dialog.dart';
import 'cook_meal_screen.dart';
import '../l10n/app_localizations.dart';

class MealHistoryScreen extends StatefulWidget {
  final Recipe recipe;
  final DatabaseHelper? databaseHelper;

  const MealHistoryScreen({
    super.key,
    required this.recipe,
    this.databaseHelper,
  });

  @override
  State<MealHistoryScreen> createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends State<MealHistoryScreen> {
  late DatabaseHelper _dbHelper = DatabaseHelper();
  List<Meal> meals = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _dbHelper = widget.databaseHelper ?? DatabaseHelper();
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
        _errorMessage = '${AppLocalizations.of(context)!.errorLoadingMeals} ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.unexpectedErrorLoadingMeals;
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
            _errorMessage ?? AppLocalizations.of(context)!.anErrorOccurred,
            style: const TextStyle(fontSize: 18, color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadMeals,
            icon: const Icon(Icons.refresh),
            label: Text(AppLocalizations.of(context)!.tryAgain),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noMealsRecorded,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<void> _handleEditMeal(Meal meal) async {
    try {
      // Get the primary recipe (the one this screen is showing history for)
      final primaryRecipe = widget.recipe;

      // Get additional recipes from the meal
      List<Recipe> additionalRecipes = [];
      if (meal.mealRecipes != null) {
        for (final mealRecipe in meal.mealRecipes!) {
          if (!mealRecipe.isPrimaryDish) {
            final additionalRecipe =
                await _dbHelper.getRecipe(mealRecipe.recipeId);
            if (additionalRecipe != null) {
              additionalRecipes.add(additionalRecipe);
            }
          }
        }
      }

      // Show edit dialog
      Map<String, dynamic>? result;
      if (mounted) {
        result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => EditMealRecordingDialog(
            meal: meal,
            primaryRecipe: primaryRecipe,
            additionalRecipes: additionalRecipes,
          ),
        );
      }

      if (result != null) {
        // Extract updated data and update the meal
        final String mealId = result['mealId'];
        final DateTime cookedAt = result['cookedAt'];
        final int servings = result['servings'];
        final String notes = result['notes'];
        final bool wasSuccessful = result['wasSuccessful'];
        final double actualPrepTime = result['actualPrepTime'];
        final double actualCookTime = result['actualCookTime'];
        final List<Recipe> updatedAdditionalRecipes =
            result['additionalRecipes'];
        final DateTime modifiedAt = result['modifiedAt'];

        // Update meal in database
        await _updateMealInDatabase(mealId, cookedAt, servings, notes,
            wasSuccessful, actualPrepTime, actualCookTime, modifiedAt);

        // Update recipe associations
        await _updateMealRecipeAssociations(
            mealId, primaryRecipe.id, updatedAdditionalRecipes);

        // Refresh the meal list
        _loadMeals();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.mealUpdatedSuccessfully)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.errorEditingMeal} $e')),
        );
      }
    }
  }

  Future<void> _updateMealInDatabase(
    String mealId,
    DateTime cookedAt,
    int servings,
    String notes,
    bool wasSuccessful,
    double actualPrepTime,
    double actualCookTime,
    DateTime modifiedAt,
  ) async {
    final db = await _dbHelper.database;

    await db.update(
      'meals',
      {
        'cooked_at': cookedAt.toIso8601String(),
        'servings': servings,
        'notes': notes,
        'was_successful': wasSuccessful ? 1 : 0,
        'actual_prep_time': actualPrepTime,
        'actual_cook_time': actualCookTime,
        'modified_at': modifiedAt.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [mealId],
    );
  }

  Future<void> _updateMealRecipeAssociations(String mealId,
      String primaryRecipeId, List<Recipe> additionalRecipes) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      // Remove all existing side dishes (keep only primary)
      await txn.delete(
        'meal_recipes',
        where: 'meal_id = ? AND is_primary_dish = 0',
        whereArgs: [mealId],
      );

      // Add all new additional recipes as side dishes
      for (final recipe in additionalRecipes) {
        final sideDishMealRecipe = MealRecipe(
          mealId: mealId,
          recipeId: recipe.id,
          isPrimaryDish: false,
          notes: 'Side dish - edited',
        );

        await txn.insert('meal_recipes', sideDishMealRecipe.toMap());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.historyTitle(widget.recipe.name)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadMeals,
            tooltip: AppLocalizations.of(context)!.refresh,
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
                                          AppLocalizations.of(context)!.recipesCount(meal.mealRecipes!.length),
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
                                    const SizedBox(width: 8),
                                    // Add edit button
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      onPressed: () => _handleEditMeal(meal),
                                      tooltip: AppLocalizations.of(context)!.editMeal,
                                      constraints: const BoxConstraints(
                                        minWidth: 36,
                                        minHeight: 36,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                    ),
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
                                                    message: AppLocalizations.of(context)!.fromMealPlan,
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
                                        AppLocalizations.of(context)!.actualTimes(
                                          meal.actualPrepTime.toString(),
                                          meal.actualCookTime.toString(),
                                        ),
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
        tooltip: AppLocalizations.of(context)!.cookNow,
        child: const Icon(Icons.add),
      ),
    );
  }
}
