import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../models/meal_plan_summary.dart';
import '../../models/recipe.dart';
import '../../screens/dashboard_screen.dart';

/// Summary cards section on the dashboard.
///
/// Displays recent meals, weekly plan status, and recipe collection —
/// each with appropriate empty states and navigation actions.
/// Order: Recent Meals → Week Plan → Collection.
class SummaryCards extends StatelessWidget {
  final int recipeCount;
  final MealPlanSummary planSummary;
  final List<RecentMealEntry> recentMealEntries;
  final VoidCallback onBrowseRecipes;
  final VoidCallback onCreatePlan;
  final VoidCallback onAddRecipe;
  final VoidCallback onViewMealPlan;
  final void Function(Recipe recipe) onViewRecipe;

  const SummaryCards({
    super.key,
    required this.recipeCount,
    required this.planSummary,
    required this.recentMealEntries,
    required this.onBrowseRecipes,
    required this.onCreatePlan,
    required this.onAddRecipe,
    required this.onViewMealPlan,
    required this.onViewRecipe,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RecentMealsCard(
          entries: recentMealEntries,
          onViewRecipe: onViewRecipe,
        ),
        const SizedBox(height: DesignTokens.spacingSm),
        _WeeklyPlanCard(
          summary: planSummary,
          onCreatePlan: onCreatePlan,
          onViewMealPlan: onViewMealPlan,
        ),
        const SizedBox(height: DesignTokens.spacingSm),
        _RecipeCollectionCard(
          count: recipeCount,
          onBrowse: onBrowseRecipes,
          onAddRecipe: onAddRecipe,
        ),
      ],
    );
  }
}

class _RecentMealsCard extends StatelessWidget {
  final List<RecentMealEntry> entries;
  final void Function(Recipe recipe) onViewRecipe;

  const _RecentMealsCard({
    required this.entries,
    required this.onViewRecipe,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: DesignTokens.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.restaurant,
                    color: DesignTokens.warning,
                    size: DesignTokens.iconSizeMedium),
                const SizedBox(width: DesignTokens.spacingSm),
                Expanded(
                  child: Text(l10n.recentMeals,
                      style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spacingSm),
            if (entries.isNotEmpty)
              ...entries.map((entry) => InkWell(
                    onTap: entry.recipe != null
                        ? () => onViewRecipe(entry.recipe!)
                        : null,
                    borderRadius: BorderRadius.circular(
                        DesignTokens.borderRadiusSmall),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: DesignTokens.spacingXs,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: DesignTokens.iconSizeSmall,
                            color: DesignTokens.mealCookedIcon,
                          ),
                          const SizedBox(width: DesignTokens.spacingSm),
                          Expanded(
                            child: Text(
                              entry.recipeName.isNotEmpty
                                  ? entry.recipeName
                                  : l10n.cookedOnDate(
                                      _formatDate(entry.meal.cookedAt)),
                              style: theme.textTheme.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatDateShort(entry.meal.cookedAt),
                            style: theme.textTheme.bodySmall,
                          ),
                          if (entry.recipe != null) ...[
                            const SizedBox(width: DesignTokens.spacingXs),
                            const Icon(Icons.chevron_right,
                                color: DesignTokens.textTertiary,
                                size: DesignTokens.iconSizeSmall),
                          ],
                        ],
                      ),
                    ),
                  ))
            else
              Text(
                l10n.noMealsYet,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: DesignTokens.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatDateShort(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}';
  }
}

class _WeeklyPlanCard extends StatelessWidget {
  final MealPlanSummary summary;
  final VoidCallback onCreatePlan;
  final VoidCallback onViewMealPlan;

  const _WeeklyPlanCard({
    required this.summary,
    required this.onCreatePlan,
    required this.onViewMealPlan,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: !summary.isEmpty ? onViewMealPlan : null,
        borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMedium),
        child: Padding(
          padding: DesignTokens.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      color: DesignTokens.accent,
                      size: DesignTokens.iconSizeMedium),
                  const SizedBox(width: DesignTokens.spacingSm),
                  Expanded(
                    child: Text(l10n.thisWeeksPlan,
                        style: theme.textTheme.titleMedium),
                  ),
                  if (!summary.isEmpty)
                    const Icon(Icons.chevron_right,
                        color: DesignTokens.textTertiary,
                        size: DesignTokens.iconSizeMedium),
                ],
              ),
              const SizedBox(height: DesignTokens.spacingSm),
              if (!summary.isEmpty) ...[
                // Progress bar
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: summary.percentage.clamp(0.0, 1.0),
                        backgroundColor: DesignTokens.surfaceVariant,
                        color: DesignTokens.accent,
                        borderRadius: BorderRadius.circular(
                            DesignTokens.borderRadiusSmall),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacingSm),
                    Text(
                      l10n.mealsPlanned(summary.totalPlanned),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                // Show today and tomorrow planned meals
                if (summary.plannedMeals.isNotEmpty) ...[
                  const SizedBox(height: DesignTokens.spacingSm),
                  ..._buildUpcomingMeals(context, summary.plannedMeals),
                ],
              ] else ...[
                Text(
                  l10n.noPlanYet,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: DesignTokens.textSecondary,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingSm),
                OutlinedButton.icon(
                  onPressed: onCreatePlan,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.createPlan),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build a list of upcoming planned meals for today and tomorrow.
  List<Widget> _buildUpcomingMeals(
      BuildContext context, List<PlannedMealInfo> plannedMeals) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final todayMeals = plannedMeals
        .where((m) =>
            m.date.year == today.year &&
            m.date.month == today.month &&
            m.date.day == today.day)
        .toList();

    final tomorrowMeals = plannedMeals
        .where((m) =>
            m.date.year == tomorrow.year &&
            m.date.month == tomorrow.month &&
            m.date.day == tomorrow.day)
        .toList();

    final widgets = <Widget>[];

    if (todayMeals.isNotEmpty) {
      widgets.addAll(_buildDayMeals(context, todayMeals, isToday: true));
    }

    if (tomorrowMeals.isNotEmpty) {
      if (widgets.isNotEmpty) {
        widgets.add(const SizedBox(height: DesignTokens.spacingXs));
      }
      widgets.addAll(_buildDayMeals(context, tomorrowMeals, isToday: false));
    }

    return widgets;
  }

  List<Widget> _buildDayMeals(
      BuildContext context, List<PlannedMealInfo> meals,
      {required bool isToday}) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final label = isToday ? l10n.today : l10n.tomorrow;

    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: DesignTokens.weightSemibold,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: meals.map((meal) {
                final recipeSummary = meal.recipes.join(', ');
                return Padding(
                  padding:
                      const EdgeInsets.only(bottom: DesignTokens.spacingXXs),
                  child: Text(
                    recipeSummary,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    ];
  }
}

class _RecipeCollectionCard extends StatelessWidget {
  final int count;
  final VoidCallback onBrowse;
  final VoidCallback onAddRecipe;

  const _RecipeCollectionCard({
    required this.count,
    required this.onBrowse,
    required this.onAddRecipe,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: count > 0 ? onBrowse : null,
        borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMedium),
        child: Padding(
          padding: DesignTokens.cardPadding,
          child: Row(
            children: [
              Icon(Icons.menu_book,
                  color: theme.colorScheme.primary,
                  size: DesignTokens.iconSizeLarge),
              const SizedBox(width: DesignTokens.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.yourCollection,
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: DesignTokens.spacingXXs),
                    if (count > 0)
                      Text(
                        l10n.recipesInCollection(count),
                        style: theme.textTheme.bodySmall,
                      )
                    else
                      Text(
                        l10n.addFirstRecipe,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: DesignTokens.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (count > 0)
                const Icon(Icons.chevron_right,
                    color: DesignTokens.textTertiary,
                    size: DesignTokens.iconSizeMedium)
              else
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: theme.colorScheme.primary,
                  onPressed: onAddRecipe,
                  tooltip: l10n.addRecipe,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
