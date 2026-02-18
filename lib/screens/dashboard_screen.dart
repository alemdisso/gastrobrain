import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/meal.dart';
import '../models/meal_plan.dart';
import '../models/recipe.dart';
import '../core/di/service_provider.dart';
import '../core/services/meal_plan_summary_service.dart';
import '../models/meal_plan_summary.dart';
import '../core/theme/design_tokens.dart';
import '../l10n/app_localizations.dart';
import '../widgets/dashboard/hero_section.dart';
import '../widgets/dashboard/quick_actions_panel.dart';
import '../widgets/dashboard/summary_cards.dart';
import 'add_recipe_screen.dart';
import 'recipe_details_screen.dart';
import 'tools_screen.dart';

/// A recent meal entry enriched with recipe data for dashboard display.
class RecentMealEntry {
  final Meal meal;
  final String recipeName;
  final Recipe? recipe;

  const RecentMealEntry({
    required this.meal,
    required this.recipeName,
    this.recipe,
  });
}

/// Main dashboard/landing screen for Gastrobrain.
///
/// Shows a hero section, quick actions, and summary cards
/// providing an overview of the user's meal planning activity.
class DashboardScreen extends StatefulWidget {
  final DatabaseHelper? databaseHelper;
  final void Function(int tabIndex)? onNavigateToTab;

  const DashboardScreen({
    super.key,
    this.databaseHelper,
    this.onNavigateToTab,
  });

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  late DatabaseHelper _dbHelper;
  late MealPlanSummaryService _summaryService;

  bool _isLoading = true;
  int _recipeCount = 0;
  MealPlanSummary _planSummary = MealPlanSummary.empty();
  List<RecentMealEntry> _recentMealEntries = [];

  @override
  void initState() {
    super.initState();
    _dbHelper = widget.databaseHelper ?? ServiceProvider.database.dbHelper;
    _summaryService = MealPlanSummaryService(_dbHelper);
    _loadData();
  }

  /// Public method to refresh dashboard data (called from HomePage on tab re-select).
  Future<void> refreshData() => _loadData();

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _dbHelper.getRecipesCount(),
        _dbHelper.getMealPlanForWeek(DateTime.now()),
        _dbHelper.getRecentMeals(limit: 3),
      ]);

      final recipeCount = results[0] as int;
      final currentPlan = results[1] as MealPlan?;
      final recentMeals = results[2] as List<Meal>;
      final summary = await _summaryService.calculateSummary(currentPlan);

      // Enrich recent meals with recipe data
      final entries = <RecentMealEntry>[];
      for (final meal in recentMeals) {
        String recipeName = '';
        Recipe? recipe;
        // Try junction table first
        final mealRecipes = await _dbHelper.getMealRecipesForMeal(meal.id);
        if (mealRecipes.isNotEmpty) {
          final primaryRecipe = mealRecipes.firstWhere(
            (mr) => mr.isPrimaryDish,
            orElse: () => mealRecipes.first,
          );
          recipe = await _dbHelper.getRecipe(primaryRecipe.recipeId);
          recipeName = recipe?.name ?? '';
        } else if (meal.recipeId != null) {
          // Fallback to legacy direct reference
          recipe = await _dbHelper.getRecipe(meal.recipeId!);
          recipeName = recipe?.name ?? '';
        }
        entries.add(RecentMealEntry(
          meal: meal,
          recipeName: recipeName,
          recipe: recipe,
        ));
      }

      if (mounted) {
        setState(() {
          _recipeCount = recipeCount;
          _planSummary = summary;
          _recentMealEntries = entries;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToMealPlan() {
    widget.onNavigateToTab?.call(1);
  }

  void _navigateToContent() {
    widget.onNavigateToTab?.call(2);
  }

  Future<void> _navigateToAddRecipe() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddRecipeScreen()),
    );
    if (result == true) {
      refreshData();
    }
  }

  void _navigateToRecipe(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailsScreen(
          recipe: recipe,
          initialTabIndex: 3, // History tab
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            key: const Key('dashboard_tools_button'),
            icon: const Icon(Icons.settings),
            tooltip: l10n.tools,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ToolsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HeroSection(onPlanThisWeek: _navigateToMealPlan),
                  const SizedBox(height: DesignTokens.spacingLg),
                  QuickActionsPanel(
                    onViewThisWeek: _navigateToMealPlan,
                    onAddRecipe: _navigateToAddRecipe,
                    onBrowseRecipes: _navigateToContent,
                  ),
                  const SizedBox(height: DesignTokens.spacingLg),
                  SummaryCards(
                    recipeCount: _recipeCount,
                    planSummary: _planSummary,
                    recentMealEntries: _recentMealEntries,
                    onBrowseRecipes: _navigateToContent,
                    onCreatePlan: _navigateToMealPlan,
                    onAddRecipe: _navigateToAddRecipe,
                    onViewMealPlan: _navigateToMealPlan,
                    onViewRecipe: _navigateToRecipe,
                  ),
                ],
              ),
            ),
    );
  }
}
