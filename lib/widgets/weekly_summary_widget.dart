import 'package:flutter/material.dart';
import '../models/meal_plan_summary.dart';
import '../l10n/app_localizations.dart';
import '../core/theme/design_tokens.dart';

/// Widget that displays a weekly meal plan summary
///
/// Shows overview statistics, protein distribution, planned meals,
/// and recipe variety metrics for a weekly meal plan.
class WeeklySummaryWidget extends StatelessWidget {
  /// The summary data to display
  final MealPlanSummary? summaryData;

  /// Callback when user wants to retry loading data (on error)
  final VoidCallback onRetry;

  /// Optional scroll controller (used when embedded in bottom sheet)
  final ScrollController? scrollController;

  /// Reference date for temporal grouping; defaults to today if null
  final DateTime? referenceDate;

  const WeeklySummaryWidget({
    super.key,
    required this.summaryData,
    required this.onRetry,
    this.scrollController,
    this.referenceDate,
  });

  @override
  Widget build(BuildContext context) {
    if (summaryData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (summaryData!.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: DesignTokens.spacingMd),
            Text(
              AppLocalizations.of(context)!.summaryCalculationError,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: DesignTokens.spacingSm),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context)!.retryButton),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(DesignTokens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewCard(context),
          const SizedBox(height: DesignTokens.spacingLg),
          _buildProteinSequenceSection(context),
          const SizedBox(height: DesignTokens.spacingLg),
          _buildPlannedMealsSection(context),
          if (summaryData!.uniqueRecipes > 0) ...[
            const SizedBox(height: DesignTokens.spacingLg),
            _buildVarietySection(context),
          ],
        ],
      ),
    );
  }

  /// Builds the overview card showing total meals and completion percentage
  Widget _buildOverviewCard(BuildContext context) {
    final totalPlanned = summaryData!.totalPlanned;
    final percentage = summaryData!.percentage;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingSm),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_month,
            color: DesignTokens.accent,
            size: 20,
          ),
          const SizedBox(width: DesignTokens.spacingSm),
          Text(
            '${AppLocalizations.of(context)!.mealsPlannedCount(totalPlanned)} (${(percentage * 100).round()}%)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: DesignTokens.textPrimary,
                ),
          ),
        ],
      ),
    );
  }

  /// Builds the protein distribution section showing proteins by day
  Widget _buildProteinSequenceSection(BuildContext context) {
    final proteinsByDay = summaryData!.proteinsByDay;

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

    final hasProteins =
        proteinsByDay.values.any((proteins) => proteins.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.proteinDistributionHeader,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: DesignTokens.textPrimary,
              ),
        ),
        const SizedBox(height: DesignTokens.spacingSm),
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
                    padding:
                        const EdgeInsets.only(bottom: DesignTokens.spacingXs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 50,
                          child: Text(
                            day.substring(0, 3),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: DesignTokens.weightMedium,
                                  color: DesignTokens.accent,
                                ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            proteinNames,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              )
            : Text(
                AppLocalizations.of(context)!.noProteinsPlanned,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: DesignTokens.textSecondary),
              ),
      ],
    );
  }

  /// Builds the planned meals section with temporal grouping.
  ///
  /// Groups meals into Cooked (past + marked cooked), Unconfirmed (past + not
  /// cooked), and Upcoming (today or future), each with a distinct visual header.
  Widget _buildPlannedMealsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final plannedMeals = summaryData!.plannedMeals;

    if (plannedMeals.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.plannedMeals,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: DesignTokens.textPrimary,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingSm),
          Text(
            l10n.noMealsPlannedYet,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: DesignTokens.textSecondary),
          ),
        ],
      );
    }

    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final cooked = <PlannedMealInfo>[];
    final unconfirmed = <PlannedMealInfo>[];
    final upcoming = <PlannedMealInfo>[];

    for (final meal in plannedMeals) {
      final mealDay =
          DateTime(meal.date.year, meal.date.month, meal.date.day);
      if (mealDay.isBefore(today)) {
        if (meal.isCooked) {
          cooked.add(meal);
        } else {
          unconfirmed.add(meal);
        }
      } else {
        upcoming.add(meal);
      }
    }

    cooked.sort((a, b) => a.date.compareTo(b.date));
    unconfirmed.sort((a, b) => a.date.compareTo(b.date));
    upcoming.sort((a, b) => a.date.compareTo(b.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.plannedMeals,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: DesignTokens.textPrimary,
              ),
        ),
        const SizedBox(height: DesignTokens.spacingSm),
        if (cooked.isNotEmpty) ...[
          _buildStatusHeader(
            context,
            label: l10n.mealSectionCooked,
            icon: Icons.check_circle,
            color: DesignTokens.mealCookedIcon,
          ),
          ..._buildMealRows(context, cooked),
        ],
        if (unconfirmed.isNotEmpty) ...[
          if (cooked.isNotEmpty)
            const SizedBox(height: DesignTokens.spacingXs),
          _buildStatusHeader(
            context,
            label: l10n.mealSectionUnconfirmed,
            icon: Icons.help_outline,
            color: DesignTokens.warning,
          ),
          ..._buildMealRows(context, unconfirmed),
        ],
        if (upcoming.isNotEmpty) ...[
          if (cooked.isNotEmpty || unconfirmed.isNotEmpty)
            const SizedBox(height: DesignTokens.spacingXs),
          _buildStatusHeader(
            context,
            label: l10n.mealSectionUpcoming,
            icon: Icons.calendar_today,
            color: DesignTokens.accent,
          ),
          ..._buildMealRows(context, upcoming),
        ],
      ],
    );
  }

  Widget _buildStatusHeader(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spacingXs),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: DesignTokens.spacingXs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: DesignTokens.weightSemibold,
                ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMealRows(
      BuildContext context, List<PlannedMealInfo> meals) {
    return meals.map((meal) {
      final formattedMealType =
          meal.mealType[0].toUpperCase() + meal.mealType.substring(1);
      return Padding(
        padding: const EdgeInsets.only(
          bottom: DesignTokens.spacingSm,
          left: DesignTokens.spacingMd,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text(
                '${meal.day.substring(0, 3)} $formattedMealType',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: DesignTokens.accent,
                ),
              ),
            ),
            Expanded(
              child: Text(
                meal.recipes.join(', '),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  /// Builds the variety section showing unique and repeated recipes
  Widget _buildVarietySection(BuildContext context) {
    final uniqueRecipes = summaryData!.uniqueRecipes;
    final repeatedRecipes = summaryData!.repeatedRecipes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.recipeVarietyHeader,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: DesignTokens.textPrimary,
              ),
        ),
        const SizedBox(height: DesignTokens.spacingXs),
        Container(
          height: 2,
          width: 170,
          color: DesignTokens.primary,
        ),
        const SizedBox(height: DesignTokens.spacingMd),
        Text(
          AppLocalizations.of(context)!.uniqueRecipesCount(uniqueRecipes),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: DesignTokens.weightBold,
              ),
        ),
        const SizedBox(height: DesignTokens.spacingSm),
        if (repeatedRecipes.isNotEmpty) ...[
          Text(
            AppLocalizations.of(context)!
                .repeatedRecipesCount(repeatedRecipes.length),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: DesignTokens.spacingSm),
          ...repeatedRecipes.map((repetition) {
            return Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: DesignTokens.spacingXXs),
              child: Text(
                '• ${repetition.recipeName} ${AppLocalizations.of(context)!.timesUsed(repetition.count)}',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: DesignTokens.textSecondary),
              ),
            );
          }),
        ],
      ],
    );
  }
}
