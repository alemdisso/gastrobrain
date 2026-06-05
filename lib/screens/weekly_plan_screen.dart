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
import '../core/theme/design_tokens.dart';
import '../core/providers/recipe_provider.dart';
import '../core/providers/meal_provider.dart';
import '../core/providers/meal_plan_provider.dart';
import '../core/errors/gastrobrain_exceptions.dart';
import '../models/ingredient.dart';
import '../models/meal_plan_item_ingredient.dart';
import '../widgets/weekly_calendar_widget.dart';
import '../widgets/meal_recording_dialog.dart';
import '../widgets/edit_meal_recording_dialog.dart';
import '../widgets/recipe_selection_dialog.dart';
import '../widgets/week_navigation_widget.dart';
import '../widgets/weekly_summary_widget.dart';
import '../screens/shopping_list_preview_screen.dart';
import '../utils/dialog_utils.dart';
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
  State<WeeklyPlanScreen> createState() => WeeklyPlanScreenState();
}

class WeeklyPlanScreenState extends State<WeeklyPlanScreen> {
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
  List<Ingredient> _availableIngredients = [];
  final ScrollController _scrollController = ScrollController();

  /// Exposed for widget tests only — do not use in production code.
  ScrollController get scrollControllerForTest => _scrollController;
  // Summary data (will be used in Summary bottom sheet - Checkpoint 3)
  MealPlanSummary? _summaryData;
  // Bottom sheet state
  bool _isSummarySheetOpen = false;
  // Pending scroll-to-today (set by scrollToToday(), consumed after _loadData)
  bool _pendingScrollToToday = false;
  DateTime? _pendingScrollDate;

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

  /// Called by HomeScreen when the user taps "Plan Today" on the Dashboard.
  /// Ensures the current week is displayed, then scrolls to today's row.
  /// Called by HomeScreen when the user taps "Plan Today" on the Dashboard.
  /// [today] is injectable for testing; defaults to DateTime.now().
  void scrollToToday({DateTime? today}) {
    if (_currentWeekContext != TimeContext.current) {
      _jumpToCurrentWeek(); // triggers _loadData()
    }
    _pendingScrollToToday = true;
    _pendingScrollDate = today ?? DateTime.now();
    if (_currentWeekContext == TimeContext.current && !_isLoading) {
      _scheduleScrollToToday(_pendingScrollDate!);
    }
  }

  void _scheduleScrollToToday(DateTime today) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final dayIndex = (today.weekday + 2) % 7;
      if (dayIndex == 0) return; // Friday — already at top
      final maxExtent = _scrollController.position.maxScrollExtent;
      if (maxExtent == 0) return; // Failsafe: layout not ready
      _scrollController.animateTo(
        (dayIndex / 6.0) * maxExtent,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _loadData() async {
    _recommendationCache.clearAllCache();
    setState(() {
      _isLoading = true;
    });

    try {
      // Load meal plan for current week
      final mealPlan = await _dbHelper.getMealPlanForWeek(_currentWeekStart);

      // Load available recipes and ingredients for selection
      final recipes = await _dbHelper.getAllRecipes();
      final ingredients = await _dbHelper.getAllIngredients();

      if (mounted) {
        setState(() {
          _currentMealPlan = mealPlan;
          _availableRecipes = recipes;
          _availableIngredients = ingredients;
          _isLoading = false;
        });

        // Clear the recommendation cache when meal plan changes
        _recommendationCache.clearAllCache();

        // Calculate summary data
        await _calculateSummaryData();

        // Consume pending scroll-to-today now that the ListView is rendered
        if (_pendingScrollToToday) {
          _pendingScrollToToday = false;
          _scheduleScrollToToday(_pendingScrollDate ?? DateTime.now());
          _pendingScrollDate = null;
        }
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
        onRefreshDetailedRecommendations: () =>
            _recommendationCache.refreshDetailedRecommendations(
                mealPlan: _currentMealPlan, date: date, mealType: mealType),
        availableIngredients: _availableIngredients,
      ),
    );

    if (mealData != null) {
      final primaryRecipe = mealData['primaryRecipe'] as Recipe;
      final additionalRecipes = mealData['additionalRecipes'] as List<Recipe>;
      final plannedServings = mealData['plannedServings'] as int? ?? primaryRecipe.servings;
      final simpleSides =
          mealData['simpleSides'] as List<Map<String, dynamic>>? ?? [];

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
        plannedServings: plannedServings,
      );

      // Persist simple sides for the newly created/updated item
      if (simpleSides.isNotEmpty) {
        final items = updatedPlan.getItemsForDateAndMealType(date, mealType);
        if (items.isNotEmpty) {
          final itemId = items[0].id;
          for (final side in simpleSides) {
            await _dbHelper.insertMealPlanItemIngredient(
              MealPlanItemIngredient(
                mealPlanItemId: itemId,
                ingredientId: side['ingredientId'] as String?,
                customName: side['customName'] as String?,
                quantity: (side['quantity'] as num?)?.toDouble() ?? 1.0,
                unit: side['unit'] as String?,
                notes: side['notes'] as String?,
              ),
            );
          }
        }
      }

      setState(() {
        _currentMealPlan = updatedPlan;
        // Force a reload to ensure the calendar widget refreshes
        _loadData();
      });
    }
  }

  Future<
      ({
        MealPlanItem item,
        Recipe primary,
        List<Recipe> additional,
        List<Map<String, dynamic>> simpleSides
      })?> _loadMealItemForEdit(DateTime date, String mealType) async {
    final items =
        _currentMealPlan?.getItemsForDateAndMealType(date, mealType) ?? [];
    if (items.isEmpty) {
      if (mounted) {
        SnackbarService.showError(
            context, AppLocalizations.of(context)!.plannedMealNotFound);
      }
      return null;
    }

    final existingItem = items[0];
    Recipe? primaryRecipe;
    final additionalRecipes = <Recipe>[];

    try {
      if (existingItem.mealPlanItemRecipes != null) {
        for (final mealRecipe in existingItem.mealPlanItemRecipes!) {
          final recipe = await _dbHelper.getRecipe(mealRecipe.recipeId);
          if (recipe != null) {
            if (mealRecipe.isPrimaryDish) {
              primaryRecipe = recipe;
            } else {
              additionalRecipes.add(recipe);
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.showError(
            context, AppLocalizations.of(context)!.errorManagingRecipes(e.toString()));
      }
      return null;
    }

    if (primaryRecipe == null) {
      if (mounted) {
        SnackbarService.showError(
            context, AppLocalizations.of(context)!.noPrimaryRecipeFound);
      }
      return null;
    }

    final simpleSides = (existingItem.mealPlanItemIngredients ?? [])
        .map((s) => <String, dynamic>{
              'ingredientId': s.ingredientId,
              'customName': s.customName,
              'quantity': s.quantity,
              'unit': s.unit,
              'notes': s.notes,
            })
        .toList();

    return (
      item: existingItem,
      primary: primaryRecipe,
      additional: additionalRecipes,
      simpleSides: simpleSides,
    );
  }

  Future<void> _handleMealTap(
      DateTime date, String mealType, String recipeId) async {
    bool mealCooked = false;
    if (_currentMealPlan != null) {
      final items =
          _currentMealPlan!.getItemsForDateAndMealType(date, mealType);
      mealCooked = items.isNotEmpty && items[0].hasBeenCooked;
    }

    final mealItemData = await _loadMealItemForEdit(date, mealType);
    if (mealItemData == null) return;

    final result = !mounted
        ? null
        : await showDialog<Map<String, dynamic>>(
            context: context,
            builder: (context) => RecipeSelectionDialog(
              recipes: _availableRecipes,
              detailedRecommendations: const [],
              initialPrimaryRecipe: mealItemData.primary,
              initialAdditionalRecipes: mealItemData.additional,
              initialPlannedServings: mealItemData.item.plannedServings,
              availableIngredients: _availableIngredients,
              initialSimpleSides: mealItemData.simpleSides,
              isEditMode: true,
              initialMealCooked: mealCooked,
            ),
          );

    if (result == null) return;

    final action = result['action'] as String?;

    if (action == 'save') {
      try {
        final existingItem = mealItemData.item;
        final updatedServings = result['plannedServings'] as int?;
        if (updatedServings != null &&
            updatedServings != existingItem.plannedServings) {
          existingItem.plannedServings = updatedServings;
          await _dbHelper.updateMealPlanItem(existingItem);
        }

        await _updateMealPlanItemRecipes(existingItem, result);

        final newSimpleSides =
            result['simpleSides'] as List<Map<String, dynamic>>? ?? [];
        await _dbHelper.deleteMealPlanItemIngredientsByItemId(existingItem.id);
        for (final side in newSimpleSides) {
          await _dbHelper.insertMealPlanItemIngredient(
            MealPlanItemIngredient(
              mealPlanItemId: existingItem.id,
              ingredientId: side['ingredientId'] as String?,
              customName: side['customName'] as String?,
              quantity: (side['quantity'] as num?)?.toDouble() ?? 1.0,
              unit: side['unit'] as String?,
              notes: side['notes'] as String?,
            ),
          );
        }

        if (mounted) {
          SnackbarService.showSuccess(context,
              AppLocalizations.of(context)!.mealRecipesUpdatedSuccessfully);
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          SnackbarService.showError(context,
              AppLocalizations.of(context)!.errorManagingRecipes(e.toString()));
        }
      }
    } else if (action == 'cooked') {
      await _handleMarkAsCooked(date, mealType, recipeId);
    } else if (action == 'edit_cooked') {
      await _handleEditCookedMeal(date, mealType, recipeId);
    } else if (action == 'view') {
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
          if (hasChanges == true && mounted) {
            _loadData();
          }
        }
      } catch (e) {
        if (mounted) {
          SnackbarService.showError(context,
              AppLocalizations.of(context)!.errorViewingRecipeDetails);
        }
      }
    } else if (action == 'change') {
      await _handleSlotTap(date, mealType);
    } else if (action == 'remove') {
      if (_currentMealPlan != null) {
        final updatedPlan = await _mealPlanService.removeMealFromSlot(
          mealPlan: _currentMealPlan!,
          date: date,
          mealType: mealType,
        );
        setState(() {
          _currentMealPlan = updatedPlan;
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
            plannedServings: mealPlanItem.plannedServings,
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
      final Map<String, String?>? recipeNotes =
          result['recipeNotes'] as Map<String, String?>?;

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
        notes: recipeNotes?[primaryRecipe.id],
      );
      await mealProvider.addMealRecipe(primaryMealRecipe);

      // Add all additional recipes as side dishes
      for (final recipe in finalAdditionalRecipes) {
        final sideDishMealRecipe = MealRecipe(
          mealId: mealId,
          recipeId: recipe.id,
          isPrimaryDish: false,
          notes: recipeNotes?[recipe.id],
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

      // Load existing MealRecipe records for pre-populating per-recipe notes
      final existingMealRecipes =
          await _dbHelper.getMealRecipesForMeal(targetMeal.id);

      // Show the edit dialog
      Map<String, dynamic>? result;
      if (mounted) {
        result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => EditMealRecordingDialog(
            meal: targetMeal,
            primaryRecipe: recipes.primary,
            additionalRecipes: recipes.additional,
            mealRecipes: existingMealRecipes,
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
      final Map<String, String?>? recipeNotes =
          result['recipeNotes'] as Map<String, String?>?;

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
        recipeNotes: recipeNotes,
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

    showGastrobrainBottomSheet(
      context: context,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(DesignTokens.borderRadiusLarge),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(
                    vertical: DesignTokens.spacingSm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  borderRadius: BorderRadius.circular(DesignTokens.spacingXXs),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingMd,
                  vertical: DesignTokens.spacingSm,
                ),
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

  /// Opens the unified shopping list flow.
  /// If a saved list exists for the current week, navigates directly to it.
  /// Otherwise, opens the preview screen.
  Future<void> _openShoppingListFlow() async {
    try {
      final endDate = _currentWeekStart.add(const Duration(days: 6));
      final existingList = await _dbHelper.getShoppingListForDateRange(
        _currentWeekStart,
        endDate,
      );

      if (!mounted) return;

      if (existingList != null) {
        // Has saved list → go directly to saved screen
        await Navigator.push(
          context,
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => ShoppingListScreen(
              shoppingListId: existingList.id!,
            ),
          ),
        );
      } else {
        // No saved list → go to preview screen
        await Navigator.push(
          context,
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => ShoppingListPreviewScreen(
              weekStartDate: _currentWeekStart,
              weekEndDate: endDate,
              databaseHelper: _dbHelper,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.weeklyMealPlan),
        actions: [
          IconButton(
            icon: Icon(
              Icons.analytics_outlined,
              color: _isSummarySheetOpen
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onPressed: _openSummarySheet,
            tooltip: AppLocalizations.of(context)!.summaryTabLabel,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: AppLocalizations.of(context)!.refresh,
          ),
        ],
      ),
      floatingActionButton: _currentWeekContext == TimeContext.past
          ? null
          : FloatingActionButton(
              onPressed: _openShoppingListFlow,
              tooltip: AppLocalizations.of(context)!.generateShoppingList,
              child: const Icon(Icons.shopping_cart_outlined),
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
                    ingredientNames: Map.fromEntries(
                      _availableIngredients
                          .map((i) => MapEntry(i.id, i.name)),
                    ),
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
    _recommendationCache.clearAllCache();
    super.dispose();
  }
}
