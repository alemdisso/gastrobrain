import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meal.dart';
import '../models/meal_recipe.dart';
import '../models/meal_plan.dart';
import '../models/meal_plan_item.dart';
import '../models/meal_plan_summary.dart';
import '../models/recipe.dart';
import '../models/time_context.dart';
import '../database/database_helper.dart';
import '../core/di/service_provider.dart';
import '../core/services/recommendation_service.dart';
import '../core/services/snackbar_service.dart';
import '../core/services/meal_plan_analysis_service.dart';
import '../core/services/meal_plan_summary_service.dart';
import '../core/services/meal_plan_service.dart';
import '../core/services/meal_action_service.dart';
import '../core/services/meal_edit_service.dart';
import '../core/services/recommendation_cache_service.dart';
import '../core/providers/recipe_provider.dart';
import '../core/providers/meal_provider.dart';
import '../core/providers/meal_plan_provider.dart';
import '../core/errors/gastrobrain_exceptions.dart';
import '../widgets/weekly_calendar_widget.dart';
import '../widgets/meal_recording_dialog.dart';
import '../widgets/edit_meal_recording_dialog.dart';
import '../widgets/recipe_selection_dialog.dart';
import '../widgets/week_navigation_widget.dart';
import '../widgets/weekly_summary_widget.dart';
import '../utils/id_generator.dart';
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

class _WeeklyPlanScreenState extends State<WeeklyPlanScreen> {
  late DatabaseHelper _dbHelper;
  late RecommendationService _recommendationService;
  late MealPlanAnalysisService _mealPlanAnalysis;
  late MealPlanSummaryService _mealPlanSummary;
  late MealPlanService _mealPlanService;
  late MealActionService _mealActionService;
  late RecommendationCacheService _recommendationCache;
  DateTime _currentWeekStart = _getFriday(DateTime.now());
  MealPlan? _currentMealPlan;
  bool _isLoading = true;
  List<Recipe> _availableRecipes = [];
  final ScrollController _scrollController = ScrollController();
  // Summary data (will be used in Summary bottom sheet - Checkpoint 3)
  MealPlanSummary? _summaryData;
  // Bottom sheet state
  bool _isSummarySheetOpen = false;
  bool _isShoppingSheetOpen = false;

  @override
  void initState() {
    super.initState();
    _dbHelper = widget.databaseHelper ?? ServiceProvider.database.dbHelper;
    _recommendationService =
        ServiceProvider.recommendations.recommendationService;
    _mealPlanAnalysis = MealPlanAnalysisService(_dbHelper);
    _mealPlanSummary = MealPlanSummaryService(_dbHelper);
    _mealPlanService = MealPlanService(_dbHelper);
    _mealActionService = MealActionService(_dbHelper);
    _recommendationCache = RecommendationCacheService(
      _dbHelper,
      _recommendationService,
      _mealPlanAnalysis,
    );
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

  Future<void> _loadData() async {
    _recommendationCache.clearAllCache();
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
        _recommendationCache.clearAllCache();

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
    _recommendationCache.clearAllCache();
    setState(() {
      _currentWeekStart = _currentWeekStart.add(Duration(days: weekOffset * 7));
      _currentMealPlan = null;
    });
    _loadData();
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
    final recommendationContext =
        await _recommendationCache.buildRecommendationContext(
      mealPlan: _currentMealPlan,
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
        onRefreshDetailedRecommendations: () => _recommendationCache
            .refreshDetailedRecommendations(
                mealPlan: _currentMealPlan, date: date, mealType: mealType),
      ),
    );

    if (mealData != null) {
      final primaryRecipe = mealData['primaryRecipe'] as Recipe;
      final additionalRecipes = mealData['additionalRecipes'] as List<Recipe>;

      // Get or create meal plan for this week
      final mealPlan = _currentMealPlan ??
          await _mealPlanService.getOrCreateMealPlan(_currentWeekStart);

      // Add or update the meal in the slot
      final updatedPlan = await _mealPlanService.addOrUpdateMealToSlot(
        mealPlan: mealPlan,
        date: date,
        mealType: mealType,
        primaryRecipe: primaryRecipe,
        additionalRecipes: additionalRecipes,
      );

      setState(() {
        _currentMealPlan = updatedPlan;
        // Force a reload to ensure the calendar widget refreshes
        _loadData();
      });
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
              context, AppLocalizations.of(context)!.errorViewingRecipeDetails);
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
        final updatedPlan = await _mealPlanService.removeMealFromSlot(
          mealPlan: _currentMealPlan!,
          date: date,
          mealType: mealType,
        );

        setState(() {
          _currentMealPlan = updatedPlan;
          // Force a reload to ensure the calendar widget refreshes
          _loadData();
        });
      }
    }
  }

  Future<void> _handleMarkAsCooked(
      DateTime date, String mealType, String recipeId) async {
    try {
      // Find the planned meal for this slot
      final mealPlanItem = _mealActionService.findPlannedMealForSlot(
        _currentMealPlan,
        date,
        mealType,
      );
      if (mealPlanItem == null) {
        if (mounted) {
          SnackbarService.showError(
              context, AppLocalizations.of(context)!.plannedMealNotFound);
        }
        return;
      }

      // Get recipes from the meal plan item
      final recipes = await _mealActionService.getRecipesFromMealPlanItem(
        mealPlanItem,
        recipeId,
      );
      if (recipes == null) {
        if (mounted) {
          SnackbarService.showError(
              context, AppLocalizations.of(context)!.recipeNotFound);
        }
        return;
      }

      // Show the meal recording dialog
      Map<String, dynamic>? result;
      if (mounted) {
        result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => MealRecordingDialog(
            primaryRecipe: recipes.primary,
            additionalRecipes: recipes.additional,
            plannedDate: date,
            notes: mealPlanItem.notes,
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
      await mealPlanProvider.markMealAsCooked(mealPlanItem);

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
      // Find the planned meal for this slot
      final mealPlanItem = _mealActionService.findPlannedMealForSlot(
        _currentMealPlan,
        date,
        mealType,
      );
      if (mealPlanItem == null || !mealPlanItem.hasBeenCooked) {
        if (mounted) {
          SnackbarService.showError(
              context, AppLocalizations.of(context)!.mealNotFoundOrNotCooked);
        }
        return;
      }

      // Find the cooked meal record
      final targetMeal = await _mealActionService.findCookedMealForSlot(
        date,
        recipeId,
      );
      if (targetMeal == null) {
        if (mounted) {
          SnackbarService.showError(
              context, AppLocalizations.of(context)!.cookedMealRecordNotFound);
        }
        return;
      }

      // Get recipes from the cooked meal
      final recipes = await _mealActionService.getRecipesFromCookedMeal(
        targetMeal,
        recipeId,
      );
      if (recipes == null) {
        if (mounted) {
          SnackbarService.showError(
              context, AppLocalizations.of(context)!.recipeNotFound);
        }
        return;
      }

      // Show the meal recording dialog in "edit mode"
      Map<String, dynamic>? result;
      if (mounted) {
        result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => MealRecordingDialog(
            primaryRecipe: recipes.primary,
            additionalRecipes: recipes.additional,
            plannedDate: date,
            notes: targetMeal.notes,
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
      // Find the planned meal for this slot
      final mealPlanItem = _mealActionService.findPlannedMealForSlot(
        _currentMealPlan,
        date,
        mealType,
      );
      if (mealPlanItem == null || !mealPlanItem.hasBeenCooked) {
        if (mounted) {
          SnackbarService.showError(
              context, AppLocalizations.of(context)!.mealNotFoundOrNotCooked);
        }
        return;
      }

      // Find the cooked meal record
      final targetMeal = await _mealActionService.findCookedMealForSlot(
        date,
        recipeId,
      );
      if (targetMeal == null) {
        if (mounted) {
          SnackbarService.showError(
              context, AppLocalizations.of(context)!.cookedMealRecordNotFound);
        }
        return;
      }

      // Get recipes from the cooked meal
      final recipes = await _mealActionService.getRecipesFromCookedMeal(
        targetMeal,
        recipeId,
      );
      if (recipes == null) {
        if (mounted) {
          SnackbarService.showError(
              context, AppLocalizations.of(context)!.recipeNotFound);
        }
        return;
      }

      // Show the edit dialog
      Map<String, dynamic>? result;
      if (mounted) {
        result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => EditMealRecordingDialog(
            meal: targetMeal,
            primaryRecipe: recipes.primary,
            additionalRecipes: recipes.additional,
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

    await _mealPlanService.updateMealItemRecipes(
      mealPlanItem: existingItem,
      primaryRecipe: primaryRecipe,
      additionalRecipes: additionalRecipes,
    );
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
            content:
                Text(AppLocalizations.of(context)!.shoppingListExistsMessage),
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
      final shoppingList =
          await ServiceProvider.shoppingList.generateFromDateRange(
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
            content: Text(
                '${AppLocalizations.of(context)!.errorGeneratingShoppingList} $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _calculateSummaryData() async {
    final summary = await _mealPlanSummary.calculateSummary(_currentMealPlan);
    if (mounted) {
      setState(() {
        _summaryData = summary;
      });
    }
  }

  // Bottom sheet methods
  void _openSummarySheet() {
    setState(() => _isSummarySheetOpen = true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.summaryTabLabel,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Summary content
              Expanded(
                child: WeeklySummaryWidget(
                  summaryData: _summaryData,
                  onRetry: _loadData,
                  scrollController: scrollController,
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      setState(() => _isSummarySheetOpen = false);
    });
  }

  void _openShoppingSheet() {
    setState(() => _isShoppingSheetOpen = true);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: _buildShoppingListOptions(context),
      ),
    ).whenComplete(() {
      setState(() => _isShoppingSheetOpen = false);
    });
  }

  Future<void> _showShoppingPreview() async {
    // TODO: Implement preview mode (Stage 1 from UX doc - future enhancement)
    // For now, show a SnackBar
    if (mounted) {
      SnackbarService.showSuccess(
        context,
        AppLocalizations.of(context)!.previewModeComingSoon,
      );
    }
  }

  Future<bool> _hasExistingShoppingList() async {
    // Check if there's an active shopping list for current week
    try {
      final endDate = _currentWeekStart.add(const Duration(days: 6));
      final existingList = await _dbHelper.getShoppingListForDateRange(
        _currentWeekStart,
        endDate,
      );
      return existingList != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> _navigateToShoppingList() async {
    try {
      final endDate = _currentWeekStart.add(const Duration(days: 6));
      final existingList = await _dbHelper.getShoppingListForDateRange(
        _currentWeekStart,
        endDate,
      );

      if (existingList != null && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShoppingListScreen(
              shoppingListId: existingList.id!,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.showError(
          context,
          AppLocalizations.of(context)!.failedToLoadShoppingList,
        );
      }
    }
  }

  Widget _buildShoppingListOptions(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasExistingShoppingList(),
      builder: (context, snapshot) {
        final hasExisting = snapshot.data ?? false;

        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Text(
                AppLocalizations.of(context)!.generateShoppingList,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Preview option
              Card(
                child: ListTile(
                  leading: const Icon(Icons.preview),
                  title: Text(AppLocalizations.of(context)!.previewIngredients),
                  subtitle: Text(AppLocalizations.of(context)!.previewIngredientsSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    _showShoppingPreview();
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Generate option
              Card(
                child: ListTile(
                  leading: const Icon(Icons.add_shopping_cart),
                  title: Text(AppLocalizations.of(context)!.generateShoppingList),
                  subtitle: Text(AppLocalizations.of(context)!.createListForShopping),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    _handleGenerateShoppingList();
                  },
                ),
              ),
              const SizedBox(height: 12),

              // View existing option (conditional)
              if (hasExisting)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.list),
                    title: Text(AppLocalizations.of(context)!.viewExistingList),
                    subtitle: Text(AppLocalizations.of(context)!.viewExistingListSubtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToShoppingList();
                    },
                  ),
                ),

              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: _openSummarySheet,
              icon: const Icon(Icons.analytics_outlined),
              label: Text(AppLocalizations.of(context)!.summaryTabLabel),
              style: TextButton.styleFrom(
                foregroundColor: _isSummarySheetOpen
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: TextButton.icon(
              onPressed: _openShoppingSheet,
              icon: const Icon(Icons.shopping_cart_outlined),
              label: Text(AppLocalizations.of(context)!.generateShoppingList),
              style: TextButton.styleFrom(
                foregroundColor: _isShoppingSheetOpen
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          WeekNavigationWidget(
            weekStartDate: _currentWeekStart,
            timeContext: _currentWeekContext,
            onPreviousWeek: () => _changeWeek(-1),
            onNextWeek: () => _changeWeek(1),
            onJumpToCurrentWeek: _currentWeekContext != TimeContext.current
                ? _jumpToCurrentWeek
                : null,
          ),

          // Main content - Planning calendar (always visible)
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
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // Clear any resources used by the recommendation service if needed
    _recommendationCache.clearAllCache();
    super.dispose();
  }
}
