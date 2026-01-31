import 'protein_type.dart';

/// Summary data for a weekly meal plan
///
/// Contains aggregated information about meals planned for a week,
/// including completion percentage, protein distribution, and recipe variety.
class MealPlanSummary {
  /// Total number of meals planned in the week
  final int totalPlanned;

  /// Percentage of the week that has meals planned (out of 14 possible slots)
  final double percentage;

  /// Protein types planned for each day of the week
  final Map<String, Set<ProteinType>> proteinsByDay;

  /// List of all planned meals with their details
  final List<PlannedMealInfo> plannedMeals;

  /// Number of unique recipes used in the week
  final int uniqueRecipes;

  /// Recipes that appear more than once, with their usage count
  final List<RecipeRepetition> repeatedRecipes;

  /// Error message if calculation failed
  final String? error;

  const MealPlanSummary({
    required this.totalPlanned,
    required this.percentage,
    required this.proteinsByDay,
    required this.plannedMeals,
    required this.uniqueRecipes,
    required this.repeatedRecipes,
    this.error,
  });

  /// Creates an empty summary (used when no meal plan exists)
  factory MealPlanSummary.empty() {
    return const MealPlanSummary(
      totalPlanned: 0,
      percentage: 0.0,
      proteinsByDay: {},
      plannedMeals: [],
      uniqueRecipes: 0,
      repeatedRecipes: [],
    );
  }

  /// Creates a summary with an error
  factory MealPlanSummary.error(String error) {
    return MealPlanSummary(
      totalPlanned: 0,
      percentage: 0.0,
      proteinsByDay: const {},
      plannedMeals: const [],
      uniqueRecipes: 0,
      repeatedRecipes: const [],
      error: error,
    );
  }

  /// Whether this summary contains an error
  bool get hasError => error != null;

  /// Whether this summary is empty (no meals planned)
  bool get isEmpty => totalPlanned == 0;
}

/// Information about a single planned meal
class PlannedMealInfo {
  /// Day of the week (e.g., "Monday")
  final String day;

  /// Date of the meal
  final DateTime date;

  /// Type of meal (e.g., "lunch", "dinner")
  final String mealType;

  /// Names of all recipes in this meal (primary + side dishes)
  final List<String> recipes;

  const PlannedMealInfo({
    required this.day,
    required this.date,
    required this.mealType,
    required this.recipes,
  });
}

/// Information about a recipe that appears multiple times
class RecipeRepetition {
  /// Recipe ID
  final String recipeId;

  /// Recipe name
  final String recipeName;

  /// Number of times this recipe appears in the week
  final int count;

  const RecipeRepetition({
    required this.recipeId,
    required this.recipeName,
    required this.count,
  });
}
