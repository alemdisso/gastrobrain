import 'package:flutter/material.dart';
import '../models/protein_type.dart';
import '../models/meal.dart';
import '../models/meal_recipe.dart';
import '../models/meal_plan.dart';
import '../models/meal_plan_item.dart';
import '../models/meal_plan_item_recipe.dart';
import '../models/recipe_recommendation.dart';
import '../models/recipe.dart';
import '../models/time_context.dart';
import '../database/database_helper.dart';
import '../core/di/service_provider.dart';
import '../core/services/recommendation_service.dart';
import '../core/services/snackbar_service.dart';
import '../core/services/meal_plan_analysis_service.dart';
import '../widgets/weekly_calendar_widget.dart';
import '../widgets/meal_recording_dialog.dart';
import '../widgets/edit_meal_recording_dialog.dart';
import '../widgets/recipe_selection_card.dart';
import '../widgets/add_side_dish_dialog.dart';
import '../utils/id_generator.dart';
import '../l10n/app_localizations.dart';

class WeeklyPlanScreen extends StatefulWidget {
  final DatabaseHelper? databaseHelper;
  const WeeklyPlanScreen({
    super.key,
    this.databaseHelper,
  });

  @override
  State<WeeklyPlanScreen> createState() => _WeeklyPlanScreenState();
}

class _WeeklyPlanScreenState extends State<WeeklyPlanScreen> {
  late DatabaseHelper _dbHelper;
  late RecommendationService _recommendationService;
  late MealPlanAnalysisService _mealPlanAnalysis;
  DateTime _currentWeekStart = _getFriday(DateTime.now());
  MealPlan? _currentMealPlan;
  bool _isLoading = true;
  List<Recipe> _availableRecipes = [];
  final ScrollController _scrollController = ScrollController();
  // Cache for recommendations to improve performance
  final Map<String, List<Recipe>> _recommendationCache = {};

  // Helper method to create cache key
  String _getRecommendationCacheKey(DateTime date, String mealType) {
    return '${date.toIso8601String()}-$mealType';
  }

  /// Invalidates the cached recommendations for a specific meal slot
  void _invalidateRecommendationCache(DateTime date, String mealType) {
    final cacheKey = _getRecommendationCacheKey(date, mealType);

    // Remove this specific slot from the cache
    if (_recommendationCache.containsKey(cacheKey)) {
      _recommendationCache.remove(cacheKey);
    }
  }

  /// Clears all cached recommendations
  void _clearAllRecommendationCache() {
    _recommendationCache.clear();
  }

  @override
  void initState() {
    super.initState();
    _dbHelper = widget.databaseHelper ?? ServiceProvider.database.dbHelper;
    _recommendationService =
        ServiceProvider.recommendations.recommendationService;
    _mealPlanAnalysis = MealPlanAnalysisService(_dbHelper);
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

  /// Determines the temporal context of the current week relative to today
  TimeContext get _currentWeekContext {
    final now = DateTime.now();
    final currentWeekFriday = _getFriday(now);

    // Compare dates only (ignore time)
    final currentWeekStartNormalized = DateTime(
      _currentWeekStart.year,
      _currentWeekStart.month,
      _currentWeekStart.day,
    );

    final currentFridayNormalized = DateTime(
      currentWeekFriday.year,
      currentWeekFriday.month,
      currentWeekFriday.day,
    );

    if (currentWeekStartNormalized.isAtSameMomentAs(currentFridayNormalized)) {
      return TimeContext.current;
    } else if (currentWeekStartNormalized.isBefore(currentFridayNormalized)) {
      return TimeContext.past;
    } else {
      return TimeContext.future;
    }
  }

  /// Calculates the relative week distance from the current week
  /// Returns positive number for future weeks, negative for past weeks
  int get _weekDistanceFromCurrent {
    final now = DateTime.now();
    final currentWeekFriday = _getFriday(now);
    final differenceInDays =
        _currentWeekStart.difference(currentWeekFriday).inDays;
    return (differenceInDays / 7).round();
  }

  /// Returns a formatted string showing relative time distance
  String get _relativeTimeDistance {
    final distance = _weekDistanceFromCurrent;
    if (distance == 0) {
      return AppLocalizations.of(context)!.thisWeekRelative;
    } else if (distance == 1) {
      return AppLocalizations.of(context)!.nextWeekRelative;
    } else if (distance == -1) {
      return AppLocalizations.of(context)!.previousWeekRelative;
    } else if (distance > 0) {
      return AppLocalizations.of(context)!.futureWeeksRelative(distance);
    } else {
      return AppLocalizations.of(context)!.pastWeeksRelative(distance);
    }
  }

  /// Jumps to the current week
  void _jumpToCurrentWeek() {
    final now = DateTime.now();
    final currentWeekFriday = _getFriday(now);

    // Use normalized dates for comparison
    final currentWeekStartNormalized = DateTime(
      _currentWeekStart.year,
      _currentWeekStart.month,
      _currentWeekStart.day,
    );

    final currentFridayNormalized = DateTime(
      currentWeekFriday.year,
      currentWeekFriday.month,
      currentWeekFriday.day,
    );

    if (!currentWeekStartNormalized.isAtSameMomentAs(currentFridayNormalized)) {
      setState(() {
        _currentWeekStart = currentWeekFriday;
        _currentMealPlan = null;
      });
      _loadData();
    }
  }

  /// Gets the context indicator color
  Color _getContextColor() {
    switch (_currentWeekContext) {
      case TimeContext.past:
        return Colors.grey.withAlpha(51);
      case TimeContext.current:
        return Theme.of(context).colorScheme.primaryContainer.withAlpha(128);
      case TimeContext.future:
        return Theme.of(context).colorScheme.primary.withAlpha(76);
    }
  }

  /// Gets the context border color
  Color _getContextBorderColor() {
    switch (_currentWeekContext) {
      case TimeContext.past:
        return Colors.grey.withAlpha(128);
      case TimeContext.current:
        return Theme.of(context).colorScheme.primary.withAlpha(128);
      case TimeContext.future:
        return Theme.of(context).colorScheme.primary.withAlpha(128);
    }
  }

  /// Gets the context text color
  Color _getContextTextColor() {
    switch (_currentWeekContext) {
      case TimeContext.past:
        return Colors.grey[700] ?? Colors.grey;
      case TimeContext.current:
        return Theme.of(context).colorScheme.onPrimaryContainer;
      case TimeContext.future:
        return Theme.of(context).colorScheme.primary;
    }
  }

  /// Gets the context icon
  IconData _getContextIcon() {
    switch (_currentWeekContext) {
      case TimeContext.past:
        return Icons.history;
      case TimeContext.current:
        return Icons.today;
      case TimeContext.future:
        return Icons.schedule;
    }
  }

  Future<void> _loadData() async {
    _clearAllRecommendationCache();
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
          SnackBar(content: Text('${AppLocalizations.of(context)!.errorLoadingData} $e')),
        );
      }
    }
  }

  void _changeWeek(int weekOffset) {
    _clearAllRecommendationCache();
    setState(() {
      _currentWeekStart = _currentWeekStart.add(Duration(days: weekOffset * 7));
      _currentMealPlan = null;
    });
    _loadData();
  }

  /// Build enhanced context for recipe recommendations using dual-context analysis
  Future<Map<String, dynamic>> _buildRecommendationContext({
    DateTime? forDate,
    String? mealType,
  }) async {
    // Get planned context (current meal plan) - handle null case
    final plannedRecipeIds = _currentMealPlan != null
        ? await _mealPlanAnalysis.getPlannedRecipeIds(_currentMealPlan)
        : <String>[];
    final plannedProteins = _currentMealPlan != null
        ? await _mealPlanAnalysis.getPlannedProteinsForWeek(_currentMealPlan)
        : <ProteinType>[];

    // Get recently cooked context (meal history)
    final recentRecipeIds =
        await _mealPlanAnalysis.getRecentlyCookedRecipeIds(dayWindow: 5);
    final recentProteins =
        await _mealPlanAnalysis.getRecentlyCookedProteins(dayWindow: 5);

    // Calculate penalty strategy - handle null meal plan
    final penaltyStrategy = _currentMealPlan != null
        ? await _mealPlanAnalysis.calculateProteinPenaltyStrategy(
            _currentMealPlan!,
            forDate ?? DateTime.now(),
            mealType ?? MealPlanItem.lunch,
          )
        : null;

    return {
      'forDate': forDate,
      'mealType': mealType,
      'plannedRecipeIds': plannedRecipeIds,
      'recentlyCookedRecipeIds': recentRecipeIds,
      'plannedProteins': plannedProteins,
      'recentProteins': recentProteins,
      'penaltyStrategy': penaltyStrategy,
      // Backward compatibility
      'excludeIds': plannedRecipeIds,
    };
  }

  /// Returns simple recipes without scores for caching.
  /// For recommendations with scores, use _getDetailedSlotRecommendations instead.
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

    // Determine if this is a weekday
    final isWeekday = date.weekday >= 1 && date.weekday <= 5;

// Get recommendations with enhanced dual-context filtering
    final recommendations = await _recommendationService.getRecommendations(
      count: count,
      excludeIds: context['plannedRecipeIds'] ?? [],
      // Note: We'll need to update RecommendationService to use penalty strategy
      // For now, use high penalty proteins as avoidProteinTypes
      avoidProteinTypes: (context['penaltyStrategy'] as ProteinPenaltyStrategy?)
          ?.highPenaltyProteins,
      forDate: date,
      mealType: mealType,
      weekdayMeal: isWeekday,
      maxDifficulty: isWeekday ? 4 : null,
    );

    // Cache the recommendations
    _recommendationCache[cacheKey] = recommendations;

    return recommendations;
  }

  Future<List<RecipeRecommendation>> _getDetailedSlotRecommendations(
      DateTime date, String mealType,
      {int count = 5}) async {
    // Build context for recommendations
    final context = await _buildRecommendationContext(
      forDate: date,
      mealType: mealType,
    );

    // Determine if this is a weekday
    final isWeekday = date.weekday >= 1 && date.weekday <= 5;

    // Get detailed recommendations with scores
    final recommendations =
        await _recommendationService.getDetailedRecommendations(
      count: count,
      excludeIds: context['plannedRecipeIds'] ?? [],
      avoidProteinTypes: (context['penaltyStrategy'] as ProteinPenaltyStrategy?)
          ?.highPenaltyProteins,
      forDate: date,
      mealType: mealType,
      weekdayMeal: isWeekday,
      maxDifficulty: isWeekday ? 4 : null,
    );

    return recommendations.recommendations;
  }

  Future<List<RecipeRecommendation>> _refreshDetailedRecommendations(
      DateTime date, String mealType) async {
    // Clear the cache for this slot
    _invalidateRecommendationCache(date, mealType);

    // Get fresh detailed recommendations
    return await _getDetailedSlotRecommendations(date, mealType, count: 8);
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

    // Get detailed recommendations with scores for this slot
    final recommendationContext = await _buildRecommendationContext(
      forDate: date,
      mealType: mealType,
    );

    final isWeekday = date.weekday >= 1 && date.weekday <= 5;

    final allRecommendations =
        await _recommendationService.getDetailedRecommendations(
      count: 999, // Get all recommendations for selection
      excludeIds: recommendationContext['excludeIds'] ?? [],
      avoidProteinTypes: recommendationContext['avoidProteinTypes'],
      forDate: date,
      mealType: mealType,
      weekdayMeal: isWeekday,
      maxDifficulty: isWeekday ? 4 : null,
    );
    // Keep top 8 for "Try This" tab
    final topRecommendations =
        allRecommendations.recommendations.take(8).toList();

    // Check if widget is still mounted before showing dialog
    if (!mounted) return;

    // Show recipe selection dialog with detailed recommendations
    final mealData = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _RecipeSelectionDialog(
        recipes: recipes,
        detailedRecommendations: topRecommendations,
        allScoredRecipes: allRecommendations.recommendations,
        onRefreshDetailedRecommendations: () =>
            _refreshDetailedRecommendations(date, mealType),
      ),
    );

    if (mealData != null) {
      final primaryRecipe = mealData['primaryRecipe'] as Recipe;
      final additionalRecipes = mealData['additionalRecipes'] as List<Recipe>;

      // Create or update meal plan
      if (_currentMealPlan == null) {
        // Create new meal plan for this week
        final newPlanId = IdGenerator.generateId();
        final newPlan = MealPlan.forWeek(
          newPlanId,
          _currentWeekStart,
        );

        // Add the meal to the plan
        final planItemId = IdGenerator.generateId();
        final planItem = MealPlanItem(
          id: planItemId,
          mealPlanId: newPlan.id,
          plannedDate: MealPlanItem.formatPlannedDate(date),
          mealType: mealType,
        );

        // Create junction records for all recipes
        final List<MealPlanItemRecipe> mealPlanItemRecipes = [];

        // Add primary recipe
        mealPlanItemRecipes.add(MealPlanItemRecipe(
          mealPlanItemId: planItemId,
          recipeId: primaryRecipe.id,
          isPrimaryDish: true,
        ));

        // Add additional recipes as side dishes
        for (final additionalRecipe in additionalRecipes) {
          mealPlanItemRecipes.add(MealPlanItemRecipe(
            mealPlanItemId: planItemId,
            recipeId: additionalRecipe.id,
            isPrimaryDish: false,
          ));
        }

        // Set the recipes list for the item
        planItem.mealPlanItemRecipes = mealPlanItemRecipes;

        newPlan.addItem(planItem);

        // Save to database
        await _dbHelper.insertMealPlan(newPlan);
        await _dbHelper.insertMealPlanItem(planItem);

        // Save all junction records
        for (final junction in mealPlanItemRecipes) {
          await _dbHelper.insertMealPlanItemRecipe(junction);
        }

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

        // Create junction records for all recipes
        final List<MealPlanItemRecipe> mealPlanItemRecipes = [];

        // Add primary recipe
        mealPlanItemRecipes.add(MealPlanItemRecipe(
          mealPlanItemId: planItemId,
          recipeId: primaryRecipe.id,
          isPrimaryDish: true,
        ));

        // Add additional recipes as side dishes
        for (final additionalRecipe in additionalRecipes) {
          mealPlanItemRecipes.add(MealPlanItemRecipe(
            mealPlanItemId: planItemId,
            recipeId: additionalRecipe.id,
            isPrimaryDish: false,
          ));
        }

        // Set the recipes list for the item
        planItem.mealPlanItemRecipes = mealPlanItemRecipes;

        _currentMealPlan!.addItem(planItem);

        // Save to database
        await _dbHelper.insertMealPlanItem(planItem);

        // Save all junction records
        for (final junction in mealPlanItemRecipes) {
          await _dbHelper.insertMealPlanItemRecipe(junction);
        }

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
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'manage_recipes'),
            child: const Text('Manage Recipes'),
          ),
          if (!mealCooked)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'cooked'),
              child: const Text('Mark as Cooked'),
            ),
          if (mealCooked) ...[
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'edit_cooked'),
              child: const Text('Edit Cooked Meal'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'add_side_dish'),
              child: const Text('Manage Side Dishes'),
            ),
          ],
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'remove'),
            child: const Text('Remove from Plan'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
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
    } else if (action == 'manage_recipes') {
      // Open multi-recipe management for existing meal
      await _handleManageRecipes(date, mealType, recipeId);
    } else if (action == 'cooked') {
      // Mark the meal as cooked
      await _handleMarkAsCooked(date, mealType, recipeId);
    } else if (action == 'edit_cooked') {
      // Edit the cooked meal
      await _handleEditCookedMeal(date, mealType, recipeId);
    } else if (action == 'add_side_dish') {
      // Add side dish to existing cooked meal
      await _handleAddSideDish(date, mealType, recipeId);
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
          SnackbarService.showError(
              context, AppLocalizations.of(context)!.plannedMealNotFound);
        }
        return;
      }

      // Get the primary recipe
      final recipe = await _dbHelper.getRecipe(recipeId);
      if (recipe == null) {
        if (mounted) {
          SnackbarService.showError(
              context, AppLocalizations.of(context)!.recipeNotFound);
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
            notes: AppLocalizations.of(context)!.mainDish,
          );

          // Insert the primary junction record
          await txn.insert('meal_recipes', primaryMealRecipe.toMap());

          // Insert all additional recipes as side dishes
          for (final recipe in finalAdditionalRecipes) {
            final sideDishMealRecipe = MealRecipe(
              mealId: mealId,
              recipeId: recipe.id,
              isPrimaryDish: false,
              notes: AppLocalizations.of(context)!.sideDish,
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
        SnackbarService.showSuccess(
            context, AppLocalizations.of(context)!.mealMarkedAsCooked);
        // Refresh data to show updated meal history
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.showError(context, 'Error marking meal as cooked: $e');
      }
    }
  }

  Future<void> _handleAddSideDish(
      DateTime date, String mealType, String recipeId) async {
    try {
      // First, find the existing cooked meal
      // We need to look in the meals table for a meal that was created from this planned meal
      final items =
          _currentMealPlan?.getItemsForDateAndMealType(date, mealType) ?? [];
      if (items.isEmpty || !items[0].hasBeenCooked) {
        if (mounted) {
          SnackbarService.showError(
              context, 'Meal not found or not yet cooked');
        }
        return;
      }

      // Find the actual meal record
      // We'll search for meals cooked on the same date as the planned date
      final plannedDateOnly = MealPlanItem.formatPlannedDate(date);
      final searchDate = DateTime.parse(plannedDateOnly);

      // Get all meals for the primary recipe from that day
      final allMealsForRecipe = await _dbHelper.getMealsForRecipe(recipeId);

      // Find the meal that was cooked on the planned date (or close to it)
      Meal? targetMeal;
      for (final meal in allMealsForRecipe) {
        final mealDate = DateTime(
          meal.cookedAt.year,
          meal.cookedAt.month,
          meal.cookedAt.day,
        );
        final plannedDateNormalized = DateTime(
          searchDate.year,
          searchDate.month,
          searchDate.day,
        );

        if (mealDate.isAtSameMomentAs(plannedDateNormalized)) {
          targetMeal = meal;
          break;
        }
      }

      if (targetMeal == null) {
        if (mounted) {
          SnackbarService.showError(
              context, 'Could not find the cooked meal record');
        }
        return;
      }

      // Get the primary recipe
      final recipe = await _dbHelper.getRecipe(recipeId);
      if (recipe == null) {
        if (mounted) {
          SnackbarService.showError(
              context, AppLocalizations.of(context)!.recipeNotFound);
        }
        return;
      }

      // Get current additional recipes from the meal
      List<Recipe> currentAdditionalRecipes = [];
      if (targetMeal.mealRecipes != null) {
        for (final mealRecipe in targetMeal.mealRecipes!) {
          if (!mealRecipe.isPrimaryDish) {
            final additionalRecipe =
                await _dbHelper.getRecipe(mealRecipe.recipeId);
            if (additionalRecipe != null) {
              currentAdditionalRecipes.add(additionalRecipe);
            }
          }
        }
      }

      // Show the meal recording dialog in "edit mode"
      Map<String, dynamic>? result;
      if (mounted) {
        result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => MealRecordingDialog(
            primaryRecipe: recipe,
            additionalRecipes: currentAdditionalRecipes,
            plannedDate: date,
            notes: targetMeal?.notes ?? '',
          ),
        );
      }

      if (result == null) return; // User cancelled

      // Extract the updated additional recipes
      final List<Recipe> updatedAdditionalRecipes = result['additionalRecipes'];

      // Update the meal's additional recipes
      await _updateMealRecipes(
          targetMeal.id, recipe.id, updatedAdditionalRecipes);

      if (mounted) {
        SnackbarService.showSuccess(
            context, 'Side dishes updated successfully');
        // Refresh data to show updated meal history
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.showError(context, 'Error adding side dish: $e');
      }
    }
  }

  Future<void> _handleEditCookedMeal(
      DateTime date, String mealType, String recipeId) async {
    try {
      // Find the cooked meal plan item
      final items =
          _currentMealPlan?.getItemsForDateAndMealType(date, mealType) ?? [];
      if (items.isEmpty || !items[0].hasBeenCooked) {
        if (mounted) {
          SnackbarService.showError(
              context, 'Meal not found or not yet cooked');
        }
        return;
      }

      // Find the actual meal record by searching for meals cooked on the planned date
      final plannedDateOnly = MealPlanItem.formatPlannedDate(date);
      final searchDate = DateTime.parse(plannedDateOnly);

      final allMealsForRecipe = await _dbHelper.getMealsForRecipe(recipeId);

      Meal? targetMeal;
      for (final meal in allMealsForRecipe) {
        final mealDate = DateTime(
          meal.cookedAt.year,
          meal.cookedAt.month,
          meal.cookedAt.day,
        );
        final plannedDateNormalized = DateTime(
          searchDate.year,
          searchDate.month,
          searchDate.day,
        );

        if (mealDate.isAtSameMomentAs(plannedDateNormalized)) {
          targetMeal = meal;
          break;
        }
      }

      if (targetMeal == null) {
        if (mounted) {
          SnackbarService.showError(
              context, 'Could not find the cooked meal record');
        }
        return;
      }

      // Get the primary recipe
      final recipe = await _dbHelper.getRecipe(recipeId);
      if (recipe == null) {
        if (mounted) {
          SnackbarService.showError(
              context, AppLocalizations.of(context)!.recipeNotFound);
        }
        return;
      }

      // Get current additional recipes from the meal
      List<Recipe> currentAdditionalRecipes = [];
      if (targetMeal.mealRecipes != null) {
        for (final mealRecipe in targetMeal.mealRecipes!) {
          if (!mealRecipe.isPrimaryDish) {
            final additionalRecipe =
                await _dbHelper.getRecipe(mealRecipe.recipeId);
            if (additionalRecipe != null) {
              currentAdditionalRecipes.add(additionalRecipe);
            }
          }
        }
      }

      // Show the edit dialog
      Map<String, dynamic>? result;
      if (mounted) {
        result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => EditMealRecordingDialog(
            meal: targetMeal!,
            primaryRecipe: recipe,
            additionalRecipes: currentAdditionalRecipes,
          ),
        );
      }

      if (result == null) return; // User cancelled

      // Extract the updated data
      final String mealId = result['mealId'];
      final DateTime cookedAt = result['cookedAt'];
      final int servings = result['servings'];
      final String notes = result['notes'];
      final bool wasSuccessful = result['wasSuccessful'];
      final double actualPrepTime = result['actualPrepTime'];
      final double actualCookTime = result['actualCookTime'];
      final List<Recipe> updatedAdditionalRecipes = result['additionalRecipes'];
      final DateTime modifiedAt = result['modifiedAt'];

      // Update the meal record
      await _updateMealRecord(mealId, cookedAt, servings, notes, wasSuccessful,
          actualPrepTime, actualCookTime, modifiedAt);

      // Update the meal's recipe associations
      await _updateMealRecipes(mealId, recipe.id, updatedAdditionalRecipes);

      if (mounted) {
        SnackbarService.showSuccess(context, 'Meal updated successfully');
        _loadData(); // Refresh the display
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.showError(context, 'Error editing meal: $e');
      }
    }
  }

  Future<void> _updateMealRecord(
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

  Future<void> _handleManageRecipes(
      DateTime date, String mealType, String recipeId) async {
    try {
      // Get the existing meal plan item
      final items =
          _currentMealPlan?.getItemsForDateAndMealType(date, mealType) ?? [];
      if (items.isEmpty) {
        if (mounted) {
          SnackbarService.showError(
              context, AppLocalizations.of(context)!.plannedMealNotFound);
        }
        return;
      }

      final existingItem = items[0];

      // Get current recipes
      final currentRecipes = <Recipe>[];
      Recipe? primaryRecipe;
      final additionalRecipes = <Recipe>[];

      if (existingItem.mealPlanItemRecipes != null) {
        for (final mealRecipe in existingItem.mealPlanItemRecipes!) {
          final recipe = await _dbHelper.getRecipe(mealRecipe.recipeId);
          if (recipe != null) {
            currentRecipes.add(recipe);
            if (mealRecipe.isPrimaryDish) {
              primaryRecipe = recipe;
            } else {
              additionalRecipes.add(recipe);
            }
          }
        }
      }

      if (primaryRecipe == null) {
        if (mounted) {
          SnackbarService.showError(context, 'No primary recipe found');
        }
        return;
      }

      // Show recipe management dialog
      final mealData = !mounted
          ? null
          : await showDialog<Map<String, dynamic>>(
              context: context,
              builder: (context) => _RecipeSelectionDialog(
                recipes: _availableRecipes,
                detailedRecommendations: const [], // No recommendations needed for editing
                initialPrimaryRecipe: primaryRecipe,
                initialAdditionalRecipes: additionalRecipes,
              ),
            );

      if (mealData == null) return; // User cancelled

      // Update the meal plan item with new recipes
      await _updateMealPlanItemRecipes(existingItem, mealData);

      if (mounted) {
        SnackbarService.showSuccess(
            context, 'Meal recipes updated successfully');
        _loadData(); // Refresh the display
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.showError(context, 'Error managing recipes: $e');
      }
    }
  }

  Future<void> _updateMealRecipes(String mealId, String primaryRecipeId,
      List<Recipe> additionalRecipes) async {
    await _dbHelper.database.then((db) async {
      return await db.transaction((txn) async {
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
            notes: 'Side dish - added later',
          );

          await txn.insert('meal_recipes', sideDishMealRecipe.toMap());
        }
      });
    });
  }

  Future<void> _updateMealPlanItemRecipes(
      MealPlanItem existingItem, Map<String, dynamic> mealData) async {
    final primaryRecipe = mealData['primaryRecipe'] as Recipe;
    final additionalRecipes = mealData['additionalRecipes'] as List<Recipe>;

    await _dbHelper.database.then((db) async {
      return await db.transaction((txn) async {
        // Delete existing junction records for this meal plan item
        await txn.delete(
          'meal_plan_item_recipes',
          where: 'meal_plan_item_id = ?',
          whereArgs: [existingItem.id],
        );

        // Create new junction records
        final List<MealPlanItemRecipe> newMealPlanItemRecipes = [];

        // Add primary recipe
        newMealPlanItemRecipes.add(MealPlanItemRecipe(
          mealPlanItemId: existingItem.id,
          recipeId: primaryRecipe.id,
          isPrimaryDish: true,
        ));

        // Add additional recipes as side dishes
        for (final additionalRecipe in additionalRecipes) {
          newMealPlanItemRecipes.add(MealPlanItemRecipe(
            mealPlanItemId: existingItem.id,
            recipeId: additionalRecipe.id,
            isPrimaryDish: false,
          ));
        }

        // Insert all new junction records
        for (final junction in newMealPlanItemRecipes) {
          await txn.insert('meal_plan_item_recipes', junction.toMap());
        }
      });
    });
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
        title: Text(AppLocalizations.of(context)!.weeklyMealPlan),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: AppLocalizations.of(context)!.refresh,
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
                  tooltip: AppLocalizations.of(context)!.previousWeek,
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _currentWeekContext != TimeContext.current
                        ? _jumpToCurrentWeek
                        : null,
                    child: Column(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.weekOf(formattedDate),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Time context indicator
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getContextColor(),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getContextBorderColor(),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getContextIcon(),
                                    size: 14,
                                    color: _getContextTextColor(),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _currentWeekContext
                                        .getLocalizedDisplayName(context),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: _getContextTextColor(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Relative time distance with tap hint
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _relativeTimeDistance,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                                // Show subtle jump hint for non-current weeks
                                if (_currentWeekContext !=
                                    TimeContext.current) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.my_location,
                                    size: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withAlpha(128),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        // Add subtle hint text for non-current weeks
                        if (_currentWeekContext != TimeContext.current)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              AppLocalizations.of(context)!
                                  .tapToJumpToCurrentWeek,
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withAlpha(153),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.navigate_next),
                  onPressed: () => _changeWeek(1),
                  tooltip: AppLocalizations.of(context)!.nextWeek,
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
                    timeContext: _currentWeekContext,
                    onSlotTap: _handleSlotTap,
                    onMealTap: _handleMealTap,
                    onDaySelected: _handleDaySelected,
                    scrollController: _scrollController,
                    databaseHelper: _dbHelper,
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
  final List<RecipeRecommendation> detailedRecommendations;
  final List<RecipeRecommendation> allScoredRecipes;
  final Future<List<RecipeRecommendation>> Function()?
      onRefreshDetailedRecommendations;
  final Recipe? initialPrimaryRecipe;
  final List<Recipe>? initialAdditionalRecipes;

  const _RecipeSelectionDialog({
    required this.recipes,
    this.detailedRecommendations = const [],
    this.allScoredRecipes = const [],
    this.onRefreshDetailedRecommendations,
    this.initialPrimaryRecipe,
    this.initialAdditionalRecipes,
  });
  @override
  _RecipeSelectionDialogState createState() => _RecipeSelectionDialogState();
}

class _RecipeSelectionDialogState extends State<_RecipeSelectionDialog>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  late TabController _tabController;
  bool _isLoading = false;
  late List<RecipeRecommendation> _recommendations;
  Recipe? _selectedRecipe;
  bool _showingMenu = false;
  List<Recipe> _additionalRecipes = [];
  bool _showingMultiRecipeMode = false;

  @override
  void initState() {
    super.initState();
    // Initialize tab controller for the two tabs
    _tabController = TabController(length: 2, vsync: this);

    // Check if we're editing an existing meal
    if (widget.initialPrimaryRecipe != null) {
      // Pre-populate with existing meal data
      _selectedRecipe = widget.initialPrimaryRecipe;
      _additionalRecipes = List.from(widget.initialAdditionalRecipes ?? []);
      _showingMultiRecipeMode = _additionalRecipes.isNotEmpty;
      _showingMenu = !_showingMultiRecipeMode;
    } else {
      // Start on the Recommended tab if we have recommendations
      if (widget.detailedRecommendations.isNotEmpty) {
        _tabController.index = 0;
      } else {
        _tabController.index =
            1; // Default to All Recipes if no recommendations
      }
    }

    // Initialize recommendations from widget prop
    _recommendations = List.from(widget.detailedRecommendations);
  }

  Future<void> _handleRefresh() async {
    if (widget.onRefreshDetailedRecommendations == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get fresh detailed recommendations
      final freshRecommendations =
          await widget.onRefreshDetailedRecommendations!();

      if (mounted) {
        setState(() {
          _recommendations = freshRecommendations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.errorRefreshingRecommendations} $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      // Make dialog use more screen space on small devices
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _showingMultiRecipeMode
                  ? AppLocalizations.of(context)!.addSideDishes
                  : (_showingMenu
                      ? AppLocalizations.of(context)!.mealOptions
                      : AppLocalizations.of(context)!.selectRecipe),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _showingMultiRecipeMode
                ? _buildMultiRecipeMode()
                : (_showingMenu
                    ? _buildMenu()
                    : Expanded(child: _buildRecipeSelection())),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeSelection() {
    final filteredRecipes = widget.recipes
        .where((recipe) =>
            recipe.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Column(
      children: [
        // Tab bar for switching between Recommended and All Recipes
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppLocalizations.of(context)!.tryThis),
                  if (widget.onRefreshDetailedRecommendations != null)
                    GestureDetector(
                      onTap: _isLoading ? null : _handleRefresh,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Icon(
                          Icons.refresh,
                          size: 18,
                          color: _isLoading
                              ? Colors.grey.withValues(alpha: 128)
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Tab(text: AppLocalizations.of(context)!.allRecipes),
          ],
        ),
        const SizedBox(height: 16),

        // Only show search on All Recipes tab
        AnimatedBuilder(
          animation: _tabController,
          builder: (context, child) {
            return _tabController.index == 1
                ? TextField(
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.searchRecipesHint,
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
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
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _recommendations.isEmpty
                      ? Center(
                          child: Text(AppLocalizations.of(context)!
                              .noRecommendationsAvailable))
                      : ListView.builder(
                          itemCount: _recommendations.length,
                          itemBuilder: (context, index) {
                            final recommendation = _recommendations[index];
                            return RecipeSelectionCard(
                              recommendation: recommendation,
                              onTap: () =>
                                  _handleRecipeSelection(recommendation.recipe),
                            );
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
      ],
    );
  }

  Widget _buildMenu() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Show selected recipe
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.restaurant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedRecipe!.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Menu options
        ListTile(
          leading: const Icon(Icons.save),
          title: Text(AppLocalizations.of(context)!.save),
          subtitle: Text(AppLocalizations.of(context)!.addThisRecipeToMealPlan),
          onTap: () => Navigator.pop(context, {
            'primaryRecipe': _selectedRecipe!,
            'additionalRecipes': <Recipe>[],
          }),
        ),
        ListTile(
          leading: const Icon(Icons.add),
          title: Text(AppLocalizations.of(context)!.addSideDishes),
          subtitle:
              Text(AppLocalizations.of(context)!.addMoreRecipesToThisMeal),
          onTap: () => setState(() {
            _showingMultiRecipeMode = true;
          }),
        ),
        ListTile(
          leading: const Icon(Icons.arrow_back),
          title: Text(AppLocalizations.of(context)!.back),
          subtitle: Text(AppLocalizations.of(context)!.chooseDifferentRecipe),
          onTap: () => setState(() {
            _showingMenu = false;
            _selectedRecipe = null;
          }),
        ),
      ],
    );
  }

  // Helper method to build consistent recipe list tiles
  Widget _buildRecipeListTile(Recipe recipe) {
    // Find the real recommendation for this recipe
    final realRecommendation = widget.allScoredRecipes
        .where((rec) => rec.recipe.id == recipe.id)
        .firstOrNull;

    final recommendation = realRecommendation ??
        RecipeRecommendation(
          recipe: recipe,
          totalScore: 50.0,
          factorScores: {
            'frequency': 50.0,
            'protein_rotation': 50.0,
            'variety_encouragement': 50.0,
            'rating': 50.0,
          },
        );

    return RecipeSelectionCard(
      recommendation: recommendation,
      onTap: () => _handleRecipeSelection(recipe),
    );
  }

  Widget _buildMultiRecipeMode() {
    return Column(
      children: [
        // Show selected primary recipe (locked)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.restaurant, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_selectedRecipe!.name} (Main Dish)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Show selected additional recipes
        if (_additionalRecipes.isNotEmpty) ...[
          const Text('Side Dishes:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._additionalRecipes.map((recipe) => ListTile(
                leading: const Icon(Icons.restaurant_menu, color: Colors.grey),
                title: Text(recipe.name),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => setState(() {
                    _additionalRecipes.remove(recipe);
                  }),
                ),
              )),
          const SizedBox(height: 16),
        ],

        // Add recipe button
        ElevatedButton.icon(
          onPressed: () => _showAddSideDishDialog(),
          icon: const Icon(Icons.add),
          label: Text(AppLocalizations.of(context)!.addSideDish),
        ),
        const SizedBox(height: 16),

        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              onPressed: () => setState(() {
                _showingMultiRecipeMode = false;
              }),
              child: Text(AppLocalizations.of(context)!.back),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, {
                'primaryRecipe': _selectedRecipe!,
                'additionalRecipes': _additionalRecipes,
              }),
              child: Text(AppLocalizations.of(context)!.saveMeal),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showAddSideDishDialog() async {
    // Create list of recipes to exclude (primary + already added)
    final excludeRecipes = [
      _selectedRecipe!,
      ..._additionalRecipes,
    ];

    final selectedRecipe = await showDialog<Recipe>(
      context: context,
      builder: (context) => AddSideDishDialog(
        availableRecipes: widget.recipes,
        excludeRecipes: excludeRecipes,
        searchHint: 'Search side dishes...',
        enableSearch: true,
      ),
    );

    if (selectedRecipe != null && mounted) {
      setState(() {
        _additionalRecipes.add(selectedRecipe);
      });
    }
  }

  void _handleRecipeSelection(Recipe recipe) {
    setState(() {
      _selectedRecipe = recipe;
      _showingMenu = true;
    });
  }
}
