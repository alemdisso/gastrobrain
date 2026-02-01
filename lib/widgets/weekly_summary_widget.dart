import 'package:flutter/material.dart';
import '../models/meal_plan_summary.dart';
import '../l10n/app_localizations.dart';

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

  const WeeklySummaryWidget({
    super.key,
    required this.summaryData,
    required this.onRetry,
    this.scrollController,
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
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.summaryCalculationError,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewCard(context),
          const SizedBox(height: 20),
          _buildProteinSequenceSection(context),
          const SizedBox(height: 24),
          _buildPlannedMealsSection(context),
          const SizedBox(height: 24),
          _buildVarietySection(context),
        ],
      ),
    );
  }

  /// Builds the overview card showing total meals and completion percentage
  Widget _buildOverviewCard(BuildContext context) {
    final totalPlanned = summaryData!.totalPlanned;
    final percentage = summaryData!.percentage;

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

  /// Builds the planned meals section showing all scheduled meals
  Widget _buildPlannedMealsSection(BuildContext context) {
    final plannedMeals = summaryData!.plannedMeals;

    if (plannedMeals.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.plannedMeals,
            style: const TextStyle(
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
    final sortedMeals = List<PlannedMealInfo>.from(plannedMeals)
      ..sort((a, b) => a.date.compareTo(b.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.plannedMeals,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 8),
        ...sortedMeals.map((meal) {
          final day = meal.day;
          final mealType = meal.mealType;
          final recipes = meal.recipes;

          // Capitalize meal type
          final formattedMealType =
              mealType[0].toUpperCase() + mealType.substring(1);

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

  /// Builds the variety section showing unique and repeated recipes
  Widget _buildVarietySection(BuildContext context) {
    final uniqueRecipes = summaryData!.uniqueRecipes;
    final repeatedRecipes = summaryData!.repeatedRecipes;

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
          ...repeatedRecipes.map((repetition) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '• ${repetition.recipeName} ${AppLocalizations.of(context)!.timesUsed(repetition.count)}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            );
          }),
        ],
      ],
    );
  }
}
