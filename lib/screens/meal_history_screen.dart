import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../models/meal.dart';
import '../models/meal_recipe.dart';
import '../database/database_helper.dart';
import '../core/errors/gastrobrain_exceptions.dart';
import '../core/providers/recipe_provider.dart';
import '../widgets/edit_meal_recording_dialog.dart';
import 'cook_meal_screen.dart';
import '../l10n/app_localizations.dart';
import '../core/theme/button_styles.dart';

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
        _errorMessage =
            '${AppLocalizations.of(context)!.errorLoadingMeals} ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            AppLocalizations.of(context)!.unexpectedErrorLoadingMeals;
        _isLoading = false;
      });
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMd(locale).format(dateTime);
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
            databaseHelper: _dbHelper,
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
        await _loadMeals();

        // Refresh recipe statistics to reflect any changes in meal data
        final recipeProvider = context.read<RecipeProvider>();
        await recipeProvider.refreshMealStats();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    AppLocalizations.of(context)!.mealUpdatedSuccessfully)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${AppLocalizations.of(context)!.errorEditingMeal}')),
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
    // Get the current meal to preserve fields we're not updating
    final currentMeal = await _dbHelper.getMeal(mealId);
    if (currentMeal == null) {
      throw Exception('Meal not found: $mealId');
    }

    // Create updated meal with new values
    final updatedMeal = Meal(
      id: mealId,
      recipeId: currentMeal.recipeId,
      cookedAt: cookedAt,
      servings: servings,
      notes: notes,
      wasSuccessful: wasSuccessful,
      actualPrepTime: actualPrepTime,
      actualCookTime: actualCookTime,
      modifiedAt: modifiedAt,
      mealRecipes: currentMeal.mealRecipes,
    );

    // Use DatabaseHelper's updateMeal method
    await _dbHelper.updateMeal(updatedMeal);
  }

  Future<void> _updateMealRecipeAssociations(String mealId,
      String primaryRecipeId, List<Recipe> additionalRecipes) async {
    // Get all current meal recipes for this meal
    final currentMealRecipes = await _dbHelper.getMealRecipesForMeal(mealId);

    // Delete all existing side dishes (keep only primary)
    for (final mealRecipe in currentMealRecipes) {
      if (!mealRecipe.isPrimaryDish) {
        await _dbHelper.deleteMealRecipe(mealRecipe.id);
      }
    }

    // Add all new additional recipes as side dishes
    for (final recipe in additionalRecipes) {
      final sideDishMealRecipe = MealRecipe(
        mealId: mealId,
        recipeId: recipe.id,
        isPrimaryDish: false,
        notes: 'Side dish - edited',
      );

      await _dbHelper.insertMealRecipe(sideDishMealRecipe);
    }
  }

  /// Shows confirmation dialog before deleting a meal
  Future<bool> _showDeleteConfirmationDialog(Meal meal) async {
    final formattedDate = _formatDateTime(meal.cookedAt);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteMeal),
        content: Text(
          AppLocalizations.of(context)!.deleteMealConfirmation(formattedDate),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ButtonStyles.destructive,
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Handles meal deletion with confirmation dialog
  Future<void> _handleDeleteMeal(Meal meal) async {
    // Show confirmation dialog
    final confirmed = await _showDeleteConfirmationDialog(meal);
    if (!confirmed) return;

    try {
      // Delete associated MealRecipe entries first
      final mealRecipes = await _dbHelper.getMealRecipesForMeal(meal.id);
      for (final mealRecipe in mealRecipes) {
        await _dbHelper.deleteMealRecipe(mealRecipe.id);
      }

      // Delete the meal
      await _dbHelper.deleteMeal(meal.id);

      // Refresh the meal list
      await _loadMeals();

      // Refresh recipe statistics
      if (mounted) {
        final recipeProvider = context.read<RecipeProvider>();
        await recipeProvider.refreshMealStats();
      }

      // Show success snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.mealDeletedSuccessfully,
            ),
          ),
        );
      }
    } on NotFoundException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
          ),
        );
      }
    } on GastrobrainException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.errorDeletingMeal}: ${e.message}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorDeletingMeal),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe.name),
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
                                    // Show meal type if available
                                    if (meal.mealType != null) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondaryContainer,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          meal.mealType!.getDisplayName(
                                              AppLocalizations.of(context)!),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSecondaryContainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                    const Spacer(),
                                    // Show side dish count if there are any
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
                                          AppLocalizations.of(context)!
                                              .sideDishCount(
                                                  meal.mealRecipes!.length - 1),
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
                                    // Add context menu with edit and delete options
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, size: 20),
                                      padding: const EdgeInsets.all(4),
                                      constraints: const BoxConstraints(
                                        minWidth: 36,
                                        minHeight: 36,
                                      ),
                                      onSelected: (value) {
                                        switch (value) {
                                          case 'edit':
                                            _handleEditMeal(meal);
                                            break;
                                          case 'delete':
                                            _handleDeleteMeal(meal);
                                            break;
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              const Icon(Icons.edit),
                                              const SizedBox(width: 8),
                                              Text(AppLocalizations.of(context)!.edit),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              const Icon(Icons.delete),
                                              const SizedBox(width: 8),
                                              Text(AppLocalizations.of(context)!.delete),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                // Display side dishes (exclude only when this recipe is the primary dish)
                                if (meal.mealRecipes != null &&
                                    meal.mealRecipes!.length > 1) ...[
                                  const SizedBox(height: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: meal.mealRecipes!
                                        .where((mealRecipe) =>
                                            // Only exclude if this recipe was the PRIMARY dish
                                            // If it was a side dish, show it (important context)
                                            !(mealRecipe.recipeId ==
                                                    widget.recipe.id &&
                                                mealRecipe.isPrimaryDish))
                                        .map((mealRecipe) {
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
                                                const Icon(
                                                    Icons.restaurant_menu,
                                                    size: 16,
                                                    color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(recipe.name),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    }).toList(),
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
                                        AppLocalizations.of(context)!
                                            .actualTimes(
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
            // Refresh recipe statistics when returning from cooking
            final recipeProvider = context.read<RecipeProvider>();
            await recipeProvider.refreshMealStats();
          }
        },
        tooltip: AppLocalizations.of(context)!.cookNow,
        child: const Icon(Icons.add),
      ),
    );
  }
}
