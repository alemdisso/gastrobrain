import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../models/measurement_unit.dart';
import '../models/recipe.dart';
import '../database/database_helper.dart';
import '../core/di/service_provider.dart';
import '../l10n/app_localizations.dart';
import '../screens/recipe_details_screen.dart';
import '../core/theme/design_tokens.dart';

class IngredientDetailScreen extends StatefulWidget {
  final Ingredient ingredient;
  final DatabaseHelper? databaseHelper;

  const IngredientDetailScreen({
    super.key,
    required this.ingredient,
    this.databaseHelper,
  });

  @override
  State<IngredientDetailScreen> createState() => _IngredientDetailScreenState();
}

enum _MealHistoryFilter { last30Days, last3Months, allTime }

class _IngredientDetailScreenState extends State<IngredientDetailScreen>
    with SingleTickerProviderStateMixin {
  late DatabaseHelper _dbHelper;
  late TabController _tabController;

  List<Map<String, dynamic>> _usedInRecipes = [];
  List<Map<String, dynamic>> _mealHistory = [];
  List<Map<String, dynamic>> _filteredMealHistory = [];
  _MealHistoryFilter _historyFilter = _MealHistoryFilter.allTime;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _dbHelper = widget.databaseHelper ?? ServiceProvider.database.dbHelper;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final recipes =
        await _dbHelper.getRecipesByIngredientId(widget.ingredient.id);
    final history =
        await _dbHelper.getMealHistoryByIngredientId(widget.ingredient.id);
    if (mounted) {
      setState(() {
        _usedInRecipes = recipes;
        _mealHistory = history;
        _filteredMealHistory = history;
        _isLoading = false;
      });
    }
  }

  void _applyFilter(_MealHistoryFilter filter) {
    final now = DateTime.now();
    List<Map<String, dynamic>> filtered;
    if (filter == _MealHistoryFilter.last30Days) {
      final cutoff = now.subtract(const Duration(days: 30));
      filtered = _mealHistory
          .where((r) =>
              DateTime.parse(r['cooked_at'] as String).isAfter(cutoff))
          .toList();
    } else if (filter == _MealHistoryFilter.last3Months) {
      final cutoff = now.subtract(const Duration(days: 90));
      filtered = _mealHistory
          .where((r) =>
              DateTime.parse(r['cooked_at'] as String).isAfter(cutoff))
          .toList();
    } else {
      filtered = _mealHistory;
    }
    setState(() {
      _historyFilter = filter;
      _filteredMealHistory = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ingredient.name),
        leading: const BackButton(),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: const Icon(Icons.menu_book), text: l10n.usedIn),
            Tab(icon: const Icon(Icons.history), text: l10n.mealHistory),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.ingredient.aliases.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.spacingMd,
                DesignTokens.spacingMd,
                DesignTokens.spacingMd,
                0,
              ),
              child: Wrap(
                spacing: DesignTokens.spacingXs,
                children: widget.ingredient.aliases
                    .map((alias) => Chip(label: Text(alias)))
                    .toList(),
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _UsedInTab(
                  isLoading: _isLoading,
                  recipes: _usedInRecipes,
                  l10n: l10n,
                ),
                _MealHistoryTab(
                  isLoading: _isLoading,
                  meals: _filteredMealHistory,
                  totalCount: _mealHistory.length,
                  activeFilter: _historyFilter,
                  onFilterChanged: _applyFilter,
                  l10n: l10n,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UsedInTab extends StatelessWidget {
  final bool isLoading;
  final List<Map<String, dynamic>> recipes;
  final AppLocalizations l10n;

  const _UsedInTab({
    required this.isLoading,
    required this.recipes,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (recipes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spacingLg),
          child: Text(
            l10n.noRecipesUsingIngredient,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.spacingMd,
            DesignTokens.spacingMd,
            DesignTokens.spacingMd,
            DesignTokens.spacingSm,
          ),
          child: Chip(
            label: Text(l10n.usedInNRecipes(recipes.length)),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              return _RecipeCard(row: recipes[index], l10n: l10n);
            },
          ),
        ),
      ],
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Map<String, dynamic> row;
  final AppLocalizations l10n;

  const _RecipeCard({required this.row, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final recipe = Recipe.fromMap(row);
    final usageQuantity = row['usage_quantity'];
    final usageUnit = row['usage_unit'] as String?;
    final ingredientCount = (row['ingredient_count'] as int?) ?? 0;
    final isIncomplete = ingredientCount < 3;
    final localizedUnit = usageUnit != null && usageUnit.isNotEmpty
        ? MeasurementUnit.fromString(usageUnit)
                ?.getLocalizedQuantityName(
                    context, (usageQuantity as num).toDouble()) ??
            usageUnit
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingMd,
        vertical: DesignTokens.spacingXs,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMedium),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecipeDetailsScreen(recipe: recipe),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      recipe.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (isIncomplete)
                    Chip(
                      label: Text(
                        l10n.incompleteRecipe,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
              const SizedBox(height: DesignTokens.spacingXs),
              Row(
                children: [
                  ...List.generate(
                    5,
                    (i) => Icon(
                      i < recipe.difficulty
                          ? Icons.battery_full
                          : Icons.battery_0_bar,
                      size: 14,
                      color: i < recipe.difficulty
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ),
                  if (recipe.rating > 0) ...[
                    const SizedBox(width: DesignTokens.spacingSm),
                    ...List.generate(
                      5,
                      (i) => Icon(
                        i < recipe.rating
                            ? Icons.star
                            : Icons.star_border,
                        size: 14,
                        color: i < recipe.rating
                            ? Colors.amber
                            : Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
              if (usageQuantity != null)
                Padding(
                  padding:
                      const EdgeInsets.only(top: DesignTokens.spacingXs),
                  child: Text(
                    (usageQuantity as num) == 0
                        ? l10n.toTaste
                        : l10n.ingredientUsageQuantityLabel(
                            localizedUnit != null
                                ? '$usageQuantity $localizedUnit'
                                : '$usageQuantity',
                          ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MealHistoryTab extends StatelessWidget {
  final bool isLoading;
  final List<Map<String, dynamic>> meals;
  final int totalCount;
  final _MealHistoryFilter activeFilter;
  final ValueChanged<_MealHistoryFilter> onFilterChanged;
  final AppLocalizations l10n;

  const _MealHistoryTab({
    required this.isLoading,
    required this.meals,
    required this.totalCount,
    required this.activeFilter,
    required this.onFilterChanged,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.spacingMd,
            DesignTokens.spacingMd,
            DesignTokens.spacingMd,
            DesignTokens.spacingXs,
          ),
          child: Wrap(
            spacing: DesignTokens.spacingXs,
            children: [
              FilterChip(
                label: Text(l10n.filterLast30Days),
                selected: activeFilter == _MealHistoryFilter.last30Days,
                onSelected: (_) =>
                    onFilterChanged(_MealHistoryFilter.last30Days),
              ),
              FilterChip(
                label: Text(l10n.filterLast3Months),
                selected: activeFilter == _MealHistoryFilter.last3Months,
                onSelected: (_) =>
                    onFilterChanged(_MealHistoryFilter.last3Months),
              ),
              FilterChip(
                label: Text(l10n.filterAllTime),
                selected: activeFilter == _MealHistoryFilter.allTime,
                onSelected: (_) =>
                    onFilterChanged(_MealHistoryFilter.allTime),
              ),
            ],
          ),
        ),
        if (meals.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingMd,
              vertical: DesignTokens.spacingXs,
            ),
            child: Chip(
              label: Text(l10n.usedInNCookedMeals(meals.length)),
            ),
          ),
        if (meals.isEmpty)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.spacingLg),
                child: Text(
                  l10n.noMealsWithIngredient,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: meals.length,
              itemBuilder: (context, index) {
                return _MealHistoryTile(row: meals[index], l10n: l10n);
              },
            ),
          ),
      ],
    );
  }
}

class _MealHistoryTile extends StatelessWidget {
  final Map<String, dynamic> row;
  final AppLocalizations l10n;

  const _MealHistoryTile({required this.row, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final cookedAt = DateTime.parse(row['cooked_at'] as String);
    final recipeName = row['recipe_name'] as String?;
    final mealType = row['meal_type'] as String?;

    return ListTile(
      leading: const Icon(Icons.restaurant),
      title: Text(
        recipeName ?? l10n.directSideIngredient,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      subtitle: Text(
        _formatDate(cookedAt),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: mealType != null
          ? Chip(
              label: Text(
                mealType,
                style: const TextStyle(fontSize: 11),
              ),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )
          : null,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
