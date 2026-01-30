import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/recipe_recommendation.dart';
import '../core/di/service_provider.dart';
import '../l10n/app_localizations.dart';
import '../widgets/recipe_selection_card.dart';
import '../widgets/add_side_dish_dialog.dart';
import '../utils/sorting_utils.dart';

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

  const RecipeSelectionDialog({
    super.key,
    required this.recipes,
    this.detailedRecommendations = const [],
    this.allScoredRecipes = const [],
    this.onRefreshDetailedRecommendations,
    this.initialPrimaryRecipe,
    this.initialAdditionalRecipes,
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
  String? _recommendationHistoryId; // Store the history ID for feedback
  Recipe? _selectedRecipe;
  bool _showingMenu = false;
  List<Recipe> _additionalRecipes = [];

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
      _showingMenu = true;
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

  Future<void> _handleFeedback(
      String recipeId, UserResponse userResponse) async {
    // Handle feedback that indicates user doesn't want this recipe now
    // Remove from current session immediately for better UX
    if (userResponse == UserResponse.notToday ||
        userResponse == UserResponse.lessOften ||
        userResponse == UserResponse.moreOften ||
        userResponse == UserResponse.neverAgain) {
      setState(() {
        _recommendations.removeWhere((rec) => rec.recipe.id == recipeId);
      });
    }

    // Only process database feedback if we have a recommendation history ID
    if (_recommendationHistoryId == null) return;

    try {
      // Update the recommendation response in the database
      final dbHelper = ServiceProvider.database.dbHelper;
      final success = await dbHelper.updateRecommendationResponse(
        _recommendationHistoryId!,
        recipeId,
        userResponse,
      );

      if (!success) {
        // Show error message if feedback couldn't be saved
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.feedbackSaveError),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Handle any errors silently for now, or show a message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.feedbackSaveError),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleRefresh() async {
    if (widget.onRefreshDetailedRecommendations == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get fresh detailed recommendations
      final result = await widget.onRefreshDetailedRecommendations!();

      if (mounted) {
        setState(() {
          _recommendations = result.recommendations;
          _recommendationHistoryId = result.historyId;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${AppLocalizations.of(context)!.errorRefreshingRecommendations} $e')),
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
              _showingMenu
                  ? AppLocalizations.of(context)!.mealOptions
                  : AppLocalizations.of(context)!.selectRecipe,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _showingMenu ? _buildMenu() : _buildRecipeSelection(),
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

  Widget _buildRecipeSelection() {
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
                              key: Key(
                                  'recipe_card_${recommendation.recipe.id}'),
                              recommendation: recommendation,
                              onTap: () =>
                                  _handleRecipeSelection(recommendation.recipe),
                              onFeedback: (userResponse) => _handleFeedback(
                                  recommendation.recipe.id, userResponse),
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
    return SingleChildScrollView(
      child: Column(
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

          // Show existing side dishes if any
          if (_additionalRecipes.isNotEmpty) ...[
            Text(
              AppLocalizations.of(context)!.sideDishesLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._additionalRecipes.map((recipe) => ListTile(
                  leading:
                      const Icon(Icons.restaurant_menu, color: Colors.grey),
                  title: Text(recipe.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => setState(() {
                      _additionalRecipes.remove(recipe);
                    }),
                  ),
                  contentPadding: EdgeInsets.zero,
                )),
            const SizedBox(height: 16),
          ],

          // Menu options
          ListTile(
            leading: const Icon(Icons.save),
            title: Text(AppLocalizations.of(context)!.save),
            subtitle:
                Text(AppLocalizations.of(context)!.addThisRecipeToMealPlan),
            onTap: () => Navigator.pop(context, {
              'primaryRecipe': _selectedRecipe!,
              'additionalRecipes': _additionalRecipes,
            }),
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: Text(_additionalRecipes.isNotEmpty
                ? AppLocalizations.of(context)!.manageSideDishes
                : AppLocalizations.of(context)!.addSideDishes),
            subtitle:
                Text(AppLocalizations.of(context)!.addMoreRecipesToThisMeal),
            onTap: () => _showEnhancedSideDishDialog(),
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
      ),
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
      key: Key('recipe_card_${recipe.id}'),
      recommendation: recommendation,
      onTap: () => _handleRecipeSelection(recipe),
    );
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

    if (result != null && mounted) {
      // The enhanced dialog returns the complete meal composition
      Navigator.pop(context, result);
    }
  }

  void _handleRecipeSelection(Recipe recipe) {
    setState(() {
      _selectedRecipe = recipe;
      _showingMenu = true;
    });
  }
}
