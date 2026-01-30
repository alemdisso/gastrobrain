import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/protein_type.dart';
import '../models/meal.dart';
import '../models/meal_recipe.dart';
import '../models/meal_plan.dart';
import '../models/meal_plan_item.dart';
import '../models/meal_plan_item_recipe.dart';
import '../models/recipe_recommendation.dart';
import '../models/recommendation_results.dart' as model;
import '../models/recipe.dart';
import '../models/time_context.dart';
import '../database/database_helper.dart';
import '../core/di/service_provider.dart';
import '../core/services/recommendation_service.dart';
import '../core/services/snackbar_service.dart';
import '../core/services/meal_plan_analysis_service.dart';
import '../core/services/meal_edit_service.dart';
import '../core/providers/recipe_provider.dart';
import '../core/providers/meal_provider.dart';
import '../core/providers/meal_plan_provider.dart';
import '../core/errors/gastrobrain_exceptions.dart';
import '../widgets/weekly_calendar_widget.dart';
import '../widgets/meal_recording_dialog.dart';
import '../widgets/edit_meal_recording_dialog.dart';
import '../widgets/recipe_selection_card.dart';
import '../widgets/add_side_dish_dialog.dart';
import '../widgets/recipe_selection_dialog.dart';
import '../utils/id_generator.dart';
import '../utils/sorting_utils.dart';
import '../l10n/app_localizations.dart';
import '../screens/recipe_details_screen.dart';
import '../screens/shopping_list_screen.dart';

class WeeklyPlanScreen extends StatefulWidget {
  final DatabaseHelper? databaseHelper;
  const WeeklyPlanScreen({
    super.key,
    this.databaseHelper,
  });

  @override
  State<WeeklyPlanScreen> createState() => _WeeklyPlanScreenState();
}

class _WeeklyPlanScreenState extends State<WeeklyPlanScreen>
    with SingleTickerProviderStateMixin {
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
  // Tab controller for Planning/Summary tabs
  late TabController _tabController;
  // Summary data
  Map<String, dynamic>? _summaryData;

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
    _tabController = TabController(length: 2, vsync: this);
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

        // Calculate summary data
        await _calculateSummaryData();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${AppLocalizations.of(context)!.errorLoadingData} $e')),
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

// Get recommendations with meal plan integration
    final recommendations = await _recommendationService.getRecommendations(
      count: count,
      excludeIds: context['plannedRecipeIds'] ?? [],
      // Pass meal plan for integrated protein rotation and variety scoring
      mealPlan: _currentMealPlan,
      forDate: date,
      mealType: mealType,
      weekdayMeal: isWeekday,
      maxDifficulty: isWeekday ? 4 : null,
    );

    // Cache the recommendations
    _recommendationCache[cacheKey] = recommendations;

    return recommendations;
  }

  Future<({List<RecipeRecommendation> recommendations, String historyId})>
      _getDetailedSlotRecommendations(DateTime date, String mealType,
          {int count = 5}) async {
    // Build context for recommendations
    final context = await _buildRecommendationContext(
      forDate: date,
      mealType: mealType,
    );

    // Determine if this is a weekday
    final isWeekday = date.weekday >= 1 && date.weekday <= 5;

    // Get detailed recommendations with scores and meal plan integration
    final recommendations =
        await _recommendationService.getDetailedRecommendations(
      count: count,
      excludeIds: context['plannedRecipeIds'] ?? [],
      // Pass meal plan for integrated protein rotation and variety scoring
      mealPlan: _currentMealPlan,
      forDate: date,
      mealType: mealType,
      weekdayMeal: isWeekday,
      maxDifficulty: isWeekday ? 4 : null,
    );

    // Convert service RecommendationResults to model RecommendationResults for database storage
    final modelResults = model.RecommendationResults(
      recommendations: recommendations.recommendations,
      totalEvaluated: recommendations.totalEvaluated,
      queryParameters: recommendations.queryParameters,
      generatedAt: recommendations.generatedAt,
    );

    // Save recommendation history and get the history ID
    final historyId = await _dbHelper.saveRecommendationHistory(
      modelResults,
      'meal_planning',
      targetDate: date,
      mealType: mealType,
    );

    return (
      recommendations: recommendations.recommendations,
      historyId: historyId
    );
  }

  Future<({List<RecipeRecommendation> recommendations, String historyId})>
      _refreshDetailedRecommendations(DateTime date, String mealType) async {
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
        SnackBar(
            content: Text(AppLocalizations.of(context)!.noRecipesAvailable)),
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
      mealPlan: _currentMealPlan, // Pass meal plan for protein rotation
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
      builder: (context) => RecipeSelectionDialog(
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
        title: Text(AppLocalizations.of(context)!.mealOptions),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'view'),
            child: Text(AppLocalizations.of(context)!.viewRecipeDetails),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'change'),
            child: Text(AppLocalizations.of(context)!.changeRecipe),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'manage_recipes'),
            child: Text(AppLocalizations.of(context)!.manageRecipes),
          ),
          if (!mealCooked)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'cooked'),
              child: Text(AppLocalizations.of(context)!.markAsCooked),
            ),
          if (mealCooked) ...[
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'edit_cooked'),
              child: Text(AppLocalizations.of(context)!.editCookedMeal),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'add_side_dish'),
              child: Text(AppLocalizations.of(context)!.manageSideDishes),
            ),
          ],
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'remove'),
            child: Text(AppLocalizations.of(context)!.removeFromPlan),
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
      // Navigate to recipe details screen
      try {
        final recipe = await _dbHelper.getRecipe(recipeId);
        if (recipe == null) {
          if (mounted) {
            SnackbarService.showError(
                context, AppLocalizations.of(context)!.recipeNotFound);
          }
          return;
        }

        if (mounted) {
          final hasChanges = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailsScreen(
                recipe: recipe,
                databaseHelper: _dbHelper,
              ),
            ),
          );

          // If changes were made to the recipe, refresh the meal plan
          if (hasChanges == true && mounted) {
            _loadData();
          }
        }
      } catch (e) {
        if (mounted) {
          SnackbarService.showError(
              context,
              AppLocalizations.of(context)!
                  .errorViewingRecipeDetails);
        }
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

      // Create meal object using the Meal model
      final meal = Meal(
        id: mealId,
        recipeId: null, // Use junction table approach
        cookedAt: cookedAt,
        servings: servings,
        notes: notes,
        wasSuccessful: wasSuccessful,
        actualPrepTime: actualPrepTime,
        actualCookTime: actualCookTime,
      );

      // Get providers
      final mealProvider = context.read<MealProvider>();
      final mealPlanProvider = context.read<MealPlanProvider>();

      // Record the meal using the provider
      final success = await mealProvider.recordMeal(meal);
      if (!success) {
        throw const GastrobrainException('Failed to record meal');
      }

      // Create and add primary recipe association
      final primaryMealRecipe = MealRecipe(
        mealId: mealId,
        recipeId: primaryRecipe.id,
        isPrimaryDish: true,
        notes: AppLocalizations.of(context)!.mainDish,
      );
      await mealProvider.addMealRecipe(primaryMealRecipe);

      // Add all additional recipes as side dishes
      for (final recipe in finalAdditionalRecipes) {
        final sideDishMealRecipe = MealRecipe(
          mealId: mealId,
          recipeId: recipe.id,
          isPrimaryDish: false,
          notes: AppLocalizations.of(context)!.sideDish,
        );
        await mealProvider.addMealRecipe(sideDishMealRecipe);
      }

      // Mark the meal plan item as cooked using the provider
      await mealPlanProvider.markMealAsCooked(items[0]);

      if (mounted) {
        SnackbarService.showSuccess(
            context, AppLocalizations.of(context)!.mealMarkedAsCooked);
        // Refresh recipe statistics cache to reflect the new meal data
        context.read<RecipeProvider>().refresh();
        // Refresh data to show updated meal history
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.showError(
            context,
            AppLocalizations.of(context)!
                .errorMarkingMealAsCooked(e.toString()));
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
              context, AppLocalizations.of(context)!.mealNotFoundOrNotCooked);
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
              context, AppLocalizations.of(context)!.cookedMealRecordNotFound);
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

      // Extract the updated data from the result
      final DateTime cookedAt = result['cookedAt'];
      final int servings = result['servings'];
      final String notes = result['notes'];
      final bool wasSuccessful = result['wasSuccessful'];
      final double actualPrepTime = result['actualPrepTime'];
      final double actualCookTime = result['actualCookTime'];
      final List<Recipe> updatedAdditionalRecipes = result['additionalRecipes'];

      // Update meal and recipe associations using service
      // Use the screen's database helper instance to ensure test mocks work
      final mealEditService = MealEditService(_dbHelper);
      await mealEditService.updateMealWithRecipes(
        mealId: targetMeal.id,
        cookedAt: cookedAt,
        servings: servings,
        notes: notes,
        wasSuccessful: wasSuccessful,
        actualPrepTime: actualPrepTime,
        actualCookTime: actualCookTime,
        additionalRecipes: updatedAdditionalRecipes,
      );

      if (mounted) {
        SnackbarService.showSuccess(context,
            AppLocalizations.of(context)!.sideDishesUpdatedSuccessfully);
        // Refresh data to show updated meal history
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.showError(context,
            AppLocalizations.of(context)!.errorAddingSideDish(e.toString()));
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
              context, AppLocalizations.of(context)!.mealNotFoundOrNotCooked);
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
              context, AppLocalizations.of(context)!.cookedMealRecordNotFound);
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

      // Update meal and recipe associations using service
      // Use the screen's database helper instance to ensure test mocks work
      final mealEditService = MealEditService(_dbHelper);
      await mealEditService.updateMealWithRecipes(
        mealId: mealId,
        cookedAt: cookedAt,
        servings: servings,
        notes: notes,
        wasSuccessful: wasSuccessful,
        actualPrepTime: actualPrepTime,
        actualCookTime: actualCookTime,
        additionalRecipes: updatedAdditionalRecipes,
      );

      if (mounted) {
        SnackbarService.showSuccess(
            context, AppLocalizations.of(context)!.mealUpdatedSuccessfully);
        _loadData(); // Refresh the display
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.showError(
            context, AppLocalizations.of(context)!.errorEditingMeal);
      }
    }
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
          SnackbarService.showError(
              context, AppLocalizations.of(context)!.noPrimaryRecipeFound);
        }
        return;
      }

      // Show recipe management dialog
      final mealData = !mounted
          ? null
          : await showDialog<Map<String, dynamic>>(
              context: context,
              builder: (context) => RecipeSelectionDialog(
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
        SnackbarService.showSuccess(context,
            AppLocalizations.of(context)!.mealRecipesUpdatedSuccessfully);
        _loadData(); // Refresh the display
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.showError(context,
            AppLocalizations.of(context)!.errorManagingRecipes(e.toString()));
      }
    }
  }

  Future<void> _updateMealPlanItemRecipes(
      MealPlanItem existingItem, Map<String, dynamic> mealData) async {
    final primaryRecipe = mealData['primaryRecipe'] as Recipe;
    final additionalRecipes = mealData['additionalRecipes'] as List<Recipe>;

    // Delete existing junction records for this meal plan item
    await _dbHelper.deleteMealPlanItemRecipesByItemId(existingItem.id);

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

    // Insert all new junction records using DatabaseHelper abstraction
    for (final junction in newMealPlanItemRecipes) {
      await _dbHelper.insertMealPlanItemRecipe(junction);
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

  Future<void> _handleGenerateShoppingList() async {
    try {
      // Calculate end date (6 days after start, since Friday-Thursday is 7 days)
      final endDate = _currentWeekStart.add(const Duration(days: 6));

      // Check if a shopping list already exists for this date range
      final existingList = await _dbHelper.getShoppingListForDateRange(
        _currentWeekStart,
        endDate,
      );

      if (existingList != null) {
        // Show dialog asking if user wants to view existing or regenerate
        if (!mounted) return;
        final action = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.shoppingListExists),
            content: Text(AppLocalizations.of(context)!.shoppingListExistsMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'cancel'),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'view'),
                child: Text(AppLocalizations.of(context)!.viewExistingList),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, 'regenerate'),
                child: Text(AppLocalizations.of(context)!.regenerateList),
              ),
            ],
          ),
        );

        if (action == null || action == 'cancel') {
          return; // User cancelled
        }

        if (action == 'view') {
          // Navigate to existing list
          if (mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ShoppingListScreen(
                  shoppingListId: existingList.id!,
                ),
              ),
            );
          }
          return;
        }

        // If action == 'regenerate', delete the existing list and continue
        if (action == 'regenerate') {
          await _dbHelper.deleteShoppingList(existingList.id!);
        }
      }

      // Show loading indicator
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 16),
              Text(AppLocalizations.of(context)!.generatingShoppingList),
            ],
          ),
          duration: const Duration(seconds: 30),
        ),
      );

      // Generate the shopping list
      final shoppingList = await ServiceProvider.shoppingList.generateFromDateRange(
        startDate: _currentWeekStart,
        endDate: endDate,
      );

      // Hide loading indicator
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Navigate to the shopping list screen
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShoppingListScreen(
              shoppingListId: shoppingList.id!,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.errorGeneratingShoppingList} $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _calculateSummaryData() async {
    if (_currentMealPlan == null) {
      setState(() {
        _summaryData = {
          'totalPlanned': 0,
          'percentage': 0.0,
          'proteinsByDay': <String, Set<ProteinType>>{},
          'plannedMeals': <Map<String, dynamic>>[],
          'uniqueRecipes': 0,
          'repeatedRecipes': <MapEntry<String, int>>[],
        };
      });
      return;
    }

    try {
      final items = _currentMealPlan!.items;
      final totalPlanned = items.length;
      final percentage = totalPlanned / 14.0;

      // Protein sequence by day
      final proteinsByDay = <String, Set<ProteinType>>{};

      // Planned meals list
      final plannedMeals = <Map<String, dynamic>>[];

      for (final item in items) {
        final date = DateTime.parse(item.plannedDate);
        final dayName = _getDayName(date.weekday);

        proteinsByDay[dayName] ??= <ProteinType>{};

        final mealRecipes = <String>[];
        for (final mealRecipe in item.mealPlanItemRecipes ?? []) {
          final recipe = await _dbHelper.getRecipe(mealRecipe.recipeId);
          if (recipe != null) {
            mealRecipes.add(recipe.name);

            // Get protein from primary dish
            if (mealRecipe.isPrimaryDish) {
              final ingredientMaps =
                  await _dbHelper.getRecipeIngredients(mealRecipe.recipeId);
              for (final ingredientMap in ingredientMaps) {
                final proteinTypeStr = ingredientMap['protein_type'] as String?;
                if (proteinTypeStr != null && proteinTypeStr != 'none') {
                  try {
                    final proteinType = ProteinType.values.firstWhere(
                      (type) => type.name == proteinTypeStr,
                    );
                    if (proteinType.isMainProtein) {
                      proteinsByDay[dayName]!.add(proteinType);
                      break;
                    }
                  } catch (e) {
                    continue;
                  }
                }
              }
            }
          }
        }

        if (mealRecipes.isNotEmpty) {
          plannedMeals.add({
            'day': dayName,
            'date': date,
            'mealType': item.mealType,
            'recipes': mealRecipes,
          });
        }
      }

      // Recipe variety
      final recipeIds = <String>[];
      for (final item in items) {
        for (final mealRecipe in item.mealPlanItemRecipes ?? []) {
          recipeIds.add(mealRecipe.recipeId);
        }
      }

      final uniqueCount = recipeIds.toSet().length;
      final recipeCounts = <String, int>{};
      for (final id in recipeIds) {
        recipeCounts[id] = (recipeCounts[id] ?? 0) + 1;
      }

      final repeatedRecipes = recipeCounts.entries
          .where((e) => e.value > 1)
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      if (mounted) {
        setState(() {
          _summaryData = {
            'totalPlanned': totalPlanned,
            'percentage': percentage,
            'proteinsByDay': proteinsByDay,
            'plannedMeals': plannedMeals,
            'uniqueRecipes': uniqueCount,
            'repeatedRecipes': repeatedRecipes,
          };
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _summaryData = {
            'totalPlanned': 0,
            'percentage': 0.0,
            'proteinsByDay': <String, Set<ProteinType>>{},
            'plannedMeals': <Map<String, dynamic>>[],
            'uniqueRecipes': 0,
            'repeatedRecipes': <MapEntry<String, int>>[],
            'error': e.toString(),
          };
        });
      }
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }

  Widget _buildSummaryView() {
    if (_summaryData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_summaryData!.containsKey('error')) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.summaryCalculationError,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadData,
              child: Text(AppLocalizations.of(context)!.retryButton),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewCard(),
          const SizedBox(height: 20),
          _buildProteinSequenceSection(),
          const SizedBox(height: 24),
          _buildPlannedMealsSection(),
          const SizedBox(height: 24),
          _buildVarietySection(),
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
    final totalPlanned = _summaryData!['totalPlanned'] as int;
    final percentage = _summaryData!['percentage'] as double;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_month,
            color: Color(0xFF6B8E23),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '${AppLocalizations.of(context)!.mealsPlannedCount(totalPlanned)} (${(percentage * 100).round()}%)',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C2C2C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProteinSequenceSection() {
    final proteinsByDay =
        _summaryData!['proteinsByDay'] as Map<String, Set<ProteinType>>;

    // Order days Friday through Thursday
    final orderedDays = [
      'Friday',
      'Saturday',
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday'
    ];

    final hasProteins = proteinsByDay.values.any((proteins) => proteins.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.proteinDistributionHeader,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 8),
        hasProteins
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: orderedDays.where((day) {
                  final proteins = proteinsByDay[day] ?? {};
                  return proteins.isNotEmpty;
                }).map((day) {
                  final proteins = proteinsByDay[day]!;
                  final proteinNames = proteins
                      .map((p) => p.getLocalizedDisplayName(context))
                      .join(', ');

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 50,
                          child: Text(
                            day.substring(0, 3),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6B8E23),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            proteinNames,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              )
            : Text(
                AppLocalizations.of(context)!.noProteinsPlanned,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
      ],
    );
  }

  Widget _buildPlannedMealsSection() {
    final plannedMeals =
        _summaryData!['plannedMeals'] as List<Map<String, dynamic>>;

    if (plannedMeals.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Planned Meals',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.noMealsPlannedYet,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      );
    }

    // Sort by date
    plannedMeals.sort((a, b) {
      final dateA = a['date'] as DateTime;
      final dateB = b['date'] as DateTime;
      return dateA.compareTo(dateB);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Planned Meals',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 8),
        ...plannedMeals.map((meal) {
          final day = meal['day'] as String;
          final mealType = meal['mealType'] as String;
          final recipes = meal['recipes'] as List<String>;

          // Capitalize meal type
          final formattedMealType = mealType[0].toUpperCase() + mealType.substring(1);

          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    '${day.substring(0, 3)} $formattedMealType',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B8E23),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    recipes.join(', '),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildVarietySection() {
    final uniqueRecipes = _summaryData!['uniqueRecipes'] as int;
    final repeatedRecipes =
        _summaryData!['repeatedRecipes'] as List<MapEntry<String, int>>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.recipeVarietyHeader,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C2C2C), // Charcoal
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 2,
          width: 170,
          color: const Color(0xFFD4755F), // Terracotta line
        ),
        const SizedBox(height: 12),
        Text(
          AppLocalizations.of(context)!.uniqueRecipesCount(uniqueRecipes),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (repeatedRecipes.isNotEmpty) ...[
          Text(
            AppLocalizations.of(context)!
                .repeatedRecipesCount(repeatedRecipes.length),
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          ...repeatedRecipes.map((entry) {
            return FutureBuilder<Recipe?>(
              future: _dbHelper.getRecipe(entry.key),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final recipe = snapshot.data!;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '• ${recipe.name} ${AppLocalizations.of(context)!.timesUsed(entry.value)}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                );
              },
            );
          }),
        ],
      ],
    );
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

          // TabBar for Planning/Summary
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: AppLocalizations.of(context)!.planningTabLabel),
              Tab(text: AppLocalizations.of(context)!.summaryTabLabel),
            ],
          ),

          // Main content - TabBarView
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Planning tab - existing calendar
                      WeeklyCalendarWidget(
                        weekStartDate: _currentWeekStart,
                        mealPlan: _currentMealPlan,
                        timeContext: _currentWeekContext,
                        onSlotTap: _handleSlotTap,
                        onMealTap: _handleMealTap,
                        onDaySelected: _handleDaySelected,
                        scrollController: _scrollController,
                        databaseHelper: _dbHelper,
                      ),
                      // Summary tab - new summary view
                      _buildSummaryView(),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleGenerateShoppingList,
        icon: const Icon(Icons.shopping_cart),
        label: Text(AppLocalizations.of(context)!.generateShoppingList),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    // Clear any resources used by the recommendation service if needed
    _recommendationCache.clear();
    super.dispose();
  }
}
