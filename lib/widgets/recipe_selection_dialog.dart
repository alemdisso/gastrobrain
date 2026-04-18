import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../models/recipe_recommendation.dart';
import '../core/di/service_provider.dart';
import '../core/providers/debug_settings_provider.dart';
import '../l10n/app_localizations.dart';
import '../widgets/recipe_selection_card.dart';
import '../widgets/add_side_dish_dialog.dart';
import '../widgets/add_simple_side_dialog.dart';
import '../utils/sorting_utils.dart';
import 'servings_stepper.dart';

/// Dialog for selecting recipes for meal planning slots.
///
/// Provides two modes:
/// - Selection mode: Browse recommended or all recipes
/// - Menu mode: Manage selected recipe and side dishes
class RecipeSelectionDialog extends StatefulWidget {
  final List<Recipe> recipes;
  final List<RecipeRecommendation> detailedRecommendations;
  final List<RecipeRecommendation> allScoredRecipes;
  final Future<({List<RecipeRecommendation> recommendations, String historyId})>
      Function()? onRefreshDetailedRecommendations;
  final Recipe? initialPrimaryRecipe;
  final List<Recipe>? initialAdditionalRecipes;
  final int? initialPlannedServings;
  final List<Ingredient> availableIngredients;
  final List<Map<String, dynamic>> initialSimpleSides;

  const RecipeSelectionDialog({
    super.key,
    required this.recipes,
    this.detailedRecommendations = const [],
    this.allScoredRecipes = const [],
    this.onRefreshDetailedRecommendations,
    this.initialPrimaryRecipe,
    this.initialAdditionalRecipes,
    this.initialPlannedServings,
    this.availableIngredients = const [],
    this.initialSimpleSides = const [],
  });

  @override
  RecipeSelectionDialogState createState() => RecipeSelectionDialogState();
}

class RecipeSelectionDialogState extends State<RecipeSelectionDialog>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  late TabController _tabController;
  bool _isLoading = false;
  late List<RecipeRecommendation> _recommendations;
  late Set<String> _sessionExcludedIds; // IDs shown or dismissed in this session
  String? _recommendationHistoryId; // Store the history ID for feedback
  Recipe? _selectedRecipe;
  bool _showingMenu = false;
  List<Recipe> _additionalRecipes = [];
  int _plannedServings = 4;
  List<Map<String, dynamic>> _simpleSides = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    if (widget.initialPrimaryRecipe != null) {
      _selectedRecipe = widget.initialPrimaryRecipe;
      _additionalRecipes = List.from(widget.initialAdditionalRecipes ?? []);
      _showingMenu = true;
      _plannedServings = widget.initialPlannedServings ?? widget.initialPrimaryRecipe!.servings;
    } else {
      _tabController.index = widget.detailedRecommendations.isNotEmpty ? 0 : 1;
    }

    _simpleSides = List.from(widget.initialSimpleSides);
    _recommendations = List.from(widget.detailedRecommendations);
    _sessionExcludedIds =
        widget.detailedRecommendations.map((r) => r.recipe.id).toSet();
  }

  void _showFeedbackError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.feedbackSaveError),
        backgroundColor: Colors.red));
  }

  Future<void> _handleFeedback(
      String recipeId, UserResponse userResponse) async {
    if (userResponse == UserResponse.notToday ||
        userResponse == UserResponse.lessOften ||
        userResponse == UserResponse.moreOften ||
        userResponse == UserResponse.neverAgain) {
      _sessionExcludedIds.add(recipeId);

      final replacement = widget.allScoredRecipes
          .where((r) => !_sessionExcludedIds.contains(r.recipe.id))
          .firstOrNull;

      setState(() {
        _recommendations.removeWhere((rec) => rec.recipe.id == recipeId);
        if (replacement != null) {
          _sessionExcludedIds.add(replacement.recipe.id);
          _recommendations.add(replacement);
        }
      });
    }

    if (_recommendationHistoryId == null) return;

    try {
      final dbHelper = ServiceProvider.database.dbHelper;
      final success = await dbHelper.updateRecommendationResponse(
        _recommendationHistoryId!,
        recipeId,
        userResponse,
      );
      if (!success) _showFeedbackError();
    } catch (e) {
      _showFeedbackError();
    }
  }

  Future<void> _handleRefresh() async {
    if (widget.onRefreshDetailedRecommendations == null) return;
    setState(() => _isLoading = true);
    try {
      final result = await widget.onRefreshDetailedRecommendations!();
      if (mounted) {
        setState(() {
          _recommendations = result.recommendations;
          _recommendationHistoryId = result.historyId;
          _sessionExcludedIds =
              result.recommendations.map((r) => r.recipe.id).toSet();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                '${AppLocalizations.of(context)!.errorRefreshingRecommendations} $e')));
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
    final debugMode = context.watch<DebugSettingsProvider>().debugScoringMode;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _showingMenu
                  ? AppLocalizations.of(context)!.mealOptions
                  : AppLocalizations.of(context)!.selectRecipe,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _showingMenu ? _buildMenu() : _buildRecipeSelection(debugMode),
            ),
            TextButton(
              key: const Key('recipe_selection_cancel_button'),
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeSelection(bool debugMode) {
    final filtered = widget.recipes
        .where((recipe) =>
            recipe.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
    final filteredRecipes = SortingUtils.sortByName(filtered, (r) => r.name);

    return Column(
      children: [
        // Tab bar for switching between Recommended and All Recipes
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              key: const Key('recipe_selection_recommended_tab'),
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
            Tab(
              key: const Key('recipe_selection_all_tab'),
              text: AppLocalizations.of(context)!.allRecipes,
            ),
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
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim();
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
                              key: Key(
                                  'recipe_card_${recommendation.recipe.id}'),
                              recommendation: recommendation,
                              onTap: () =>
                                  _handleRecipeSelection(recommendation.recipe),
                              onFeedback: (userResponse) => _handleFeedback(
                                  recommendation.recipe.id, userResponse),
                              debugMode: debugMode,
                            );
                          },
                        ),
              // All Recipes tab
              ListView.builder(
                itemCount: filteredRecipes.length,
                itemBuilder: (context, index) {
                  final recipe = filteredRecipes[index];
                  return _buildRecipeListTile(recipe, debugMode);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenu() {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary recipe header
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
          const SizedBox(height: 12),

          // Acompanhamentos section — visible upfront, not buried in list
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.completeMealSection,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),

                // Existing recipe side dishes
                if (_additionalRecipes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ..._additionalRecipes.map((recipe) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.restaurant_menu,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(recipe.name,
                                  style:
                                      Theme.of(context).textTheme.bodySmall),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              tooltip: '${l10n.remove} ${recipe.name}',
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => setState(
                                  () => _additionalRecipes.remove(recipe)),
                            ),
                          ],
                        ),
                      )),
                ],

                // Existing simple sides
                if (_simpleSides.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  ..._simpleSides.map((side) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.eco_outlined,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_resolveSideName(side),
                                  style:
                                      Theme.of(context).textTheme.bodySmall),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              tooltip:
                                  '${l10n.remove} ${_resolveSideName(side)}',
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => setState(
                                  () => _simpleSides.remove(side)),
                            ),
                          ],
                        ),
                      )),
                ],

                const SizedBox(height: 8),

                // Add recipe side — OutlinedButton, full-width, immediately visible
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const Key('recipe_selection_add_side_dish_button'),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(_additionalRecipes.isNotEmpty
                        ? l10n.manageSideDishes
                        : l10n.addSideDishes),
                    onPressed: _showEnhancedSideDishDialog,
                  ),
                ),
                const SizedBox(height: 6),

                // Add simple ingredient side — secondary OutlinedButton
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const Key('recipe_selection_add_simple_side_button'),
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: Text(_simpleSides.isNotEmpty
                        ? l10n.manageSimpleSides
                        : l10n.addSimpleSide),
                    onPressed: _showAddSimpleSideDialog,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Servings stepper
          ServingsStepper(
            key: const Key('recipe_selection_planned_servings_stepper'),
            value: _plannedServings,
            onChanged: (v) => setState(() => _plannedServings = v),
          ),
          const SizedBox(height: 12),

          // Save — primary action, full-width ElevatedButton
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('recipe_selection_save_button'),
              icon: const Icon(Icons.save),
              label: Text(l10n.saveMeal),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => Navigator.pop(context, {
                'primaryRecipe': _selectedRecipe!,
                'additionalRecipes': _additionalRecipes,
                'plannedServings': _plannedServings,
                'simpleSides': _simpleSides,
              }),
            ),
          ),
          const SizedBox(height: 4),

          // Back — tertiary, text only
          TextButton.icon(
            icon: const Icon(Icons.arrow_back, size: 16),
            label: Text(l10n.back),
            onPressed: () => setState(() {
              _showingMenu = false;
              _selectedRecipe = null;
            }),
          ),
        ],
      ),
    );
  }

  // Helper method to build consistent recipe list tiles
  Widget _buildRecipeListTile(Recipe recipe, bool debugMode) {
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
      key: Key('recipe_card_${recipe.id}'),
      recommendation: recommendation,
      onTap: () => _handleRecipeSelection(recipe),
      debugMode: debugMode,
    );
  }

  Future<void> _showAddSimpleSideDialog() async {
    if (!mounted) return;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddSimpleSideDialog(
        availableIngredients: widget.availableIngredients,
      ),
    );
    if (result != null && mounted) {
      setState(() => _simpleSides.add(result));
    }
  }

  String _resolveSideName(Map<String, dynamic> side) {
    final ingredientId = side['ingredientId'] as String?;
    if (ingredientId != null) {
      final ingredient = widget.availableIngredients
          .where((i) => i.id == ingredientId)
          .firstOrNull;
      return ingredient?.name ?? side['customName'] as String? ?? '?';
    }
    return side['customName'] as String? ?? '?';
  }

  Future<void> _showEnhancedSideDishDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddSideDishDialog(
        availableRecipes: widget.recipes,
        excludeRecipes: [_selectedRecipe!],
        searchHint: 'Search side dishes...',
        enableSearch: true,
        primaryRecipe: _selectedRecipe,
        currentSideDishes: _additionalRecipes,
      ),
    );

    if (result == null || !mounted) return;

    final action = result['action'] as String?;
    if (action == 'confirm') {
      final sides = result['additionalRecipes'] as List<Recipe>? ?? [];
      setState(() => _additionalRecipes = sides);
    }
  }

  void _handleRecipeSelection(Recipe recipe) {
    setState(() {
      _selectedRecipe = recipe;
      _showingMenu = true;
      _plannedServings = recipe.servings;
    });
  }
}
