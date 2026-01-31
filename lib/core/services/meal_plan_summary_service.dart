import '../../database/database_helper.dart';
import '../../models/meal_plan.dart';
import '../../models/meal_plan_summary.dart';
import '../../models/protein_type.dart';

/// Service for calculating summary statistics for meal plans
///
/// Provides aggregated information about a weekly meal plan including
/// completion percentage, protein distribution, and recipe variety.
class MealPlanSummaryService {
  final DatabaseHelper _dbHelper;

  const MealPlanSummaryService(this._dbHelper);

  /// Calculates summary data for a meal plan
  ///
  /// Returns [MealPlanSummary.empty] if [mealPlan] is null.
  /// Returns [MealPlanSummary.error] if calculation fails.
  Future<MealPlanSummary> calculateSummary(MealPlan? mealPlan) async {
    if (mealPlan == null) {
      return MealPlanSummary.empty();
    }

    try {
      final items = mealPlan.items;
      final totalPlanned = items.length;
      final percentage = totalPlanned / 14.0; // 14 = 7 days × 2 meals per day

      // Calculate protein distribution by day
      final proteinsByDay = <String, Set<ProteinType>>{};

      // Build list of planned meals
      final plannedMeals = <PlannedMealInfo>[];

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
          plannedMeals.add(PlannedMealInfo(
            day: dayName,
            date: date,
            mealType: item.mealType,
            recipes: mealRecipes,
          ));
        }
      }

      // Calculate recipe variety
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

      // Build list of repeated recipes with their names
      final repeatedRecipesList = <RecipeRepetition>[];
      for (final entry in recipeCounts.entries.where((e) => e.value > 1)) {
        final recipe = await _dbHelper.getRecipe(entry.key);
        if (recipe != null) {
          repeatedRecipesList.add(RecipeRepetition(
            recipeId: entry.key,
            recipeName: recipe.name,
            count: entry.value,
          ));
        }
      }

      // Sort by count descending
      repeatedRecipesList.sort((a, b) => b.count.compareTo(a.count));

      return MealPlanSummary(
        totalPlanned: totalPlanned,
        percentage: percentage,
        proteinsByDay: proteinsByDay,
        plannedMeals: plannedMeals,
        uniqueRecipes: uniqueCount,
        repeatedRecipes: repeatedRecipesList,
      );
    } catch (e) {
      return MealPlanSummary.error(e.toString());
    }
  }

  /// Converts a weekday number to its name
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
}
