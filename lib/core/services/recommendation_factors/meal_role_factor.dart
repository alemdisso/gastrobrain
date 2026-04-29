import '../../../models/recipe.dart';
import '../recommendation_service.dart';

/// Score tables for meal_role and food_type tags keyed by meal type.
///
/// Designed for Brazilian eating patterns (lunch is the main meal).
/// Scores represent suitability (0-100) for each combination.
class MealTypeProfileConfig {
  final Map<String, Map<String, int>> mealRoleScores;
  final Map<String, Map<String, int>> foodTypeScores;

  const MealTypeProfileConfig({
    required this.mealRoleScores,
    required this.foodTypeScores,
  });

  static const MealTypeProfileConfig defaultConfig = MealTypeProfileConfig(
    mealRoleScores: {
      'lunch': {
        'meal-role-complete-meal': 90,
        'meal-role-main-dish': 80,
        'meal-role-side-dish': 50,
        'meal-role-accompaniment': 50,
        'meal-role-appetizer': 30,
        'meal-role-dessert': 10,
        'meal-role-snack': 10,
      },
      'dinner': {
        'meal-role-complete-meal': 90,
        'meal-role-main-dish': 80,
        'meal-role-side-dish': 50,
        'meal-role-accompaniment': 50,
        'meal-role-appetizer': 30,
        'meal-role-dessert': 10,
        'meal-role-snack': 10,
      },
    },
    foodTypeScores: {
      'lunch': {
        'food-type-soup': 35,
        'food-type-stew': 75,
        'food-type-salad': 70,
        'food-type-sandwich': 55,
        'food-type-pasta': 75,
        'food-type-rice': 80,
        'food-type-grilled': 80,
        'food-type-baked': 75,
        'food-type-raw': 60,
        'food-type-stock': 15,
        'food-type-sauce': 15,
      },
      'dinner': {
        'food-type-soup': 80,
        'food-type-stew': 85,
        'food-type-salad': 80,
        'food-type-sandwich': 85,
        'food-type-pasta': 80,
        'food-type-rice': 60,
        'food-type-grilled': 80,
        'food-type-baked': 80,
        'food-type-raw': 65,
        'food-type-stock': 15,
        'food-type-sauce': 15,
      },
    },
  );
}

/// Scores recipes based on how well their meal_role and food_type tags
/// match the requested meal type (lunch or dinner).
///
/// Context keys consumed:
/// - `mealType` (String?): 'lunch' or 'dinner'. Returns 50 if absent.
/// - `recipeTags` (Map<String, List<String>>): recipe ID → tag IDs for
///   meal_role and food_type types. Returns 50 when recipe has no tags.
///
/// Scoring:
/// - meal_role match: highest score among the recipe's meal_role tags (weight 60%).
/// - food_type match: highest score among the recipe's food_type tags (weight 40%).
/// - Missing tag type: neutral 50.
/// - Unknown mealType or null mealType: returns 50 (neutral, no differentiation).
class MealRoleFactor implements RecommendationFactor {
  final MealTypeProfileConfig config;

  const MealRoleFactor({
    this.config = MealTypeProfileConfig.defaultConfig,
  });

  @override
  String get id => 'meal_role';

  @override
  int get defaultWeight => 0;

  @override
  Set<String> get requiredData => {'recipeTags'};

  @override
  Future<double> calculateScore(
      Recipe recipe, Map<String, dynamic> context) async {
    final mealType = context['mealType'] as String?;
    if (mealType == null) return 50.0;

    final mealRoleTable = config.mealRoleScores[mealType];
    final foodTypeTable = config.foodTypeScores[mealType];
    if (mealRoleTable == null || foodTypeTable == null) return 50.0;

    final allTags = context['recipeTags'] as Map<String, List<String>>?;
    final tagIds = allTags?[recipe.id] ?? [];

    final mealRoleScore = _bestScore(
      tagIds.where((id) => id.startsWith('meal-role-')).toList(),
      mealRoleTable,
    );
    final foodTypeScore = _bestScore(
      tagIds.where((id) => id.startsWith('food-type-')).toList(),
      foodTypeTable,
    );

    return mealRoleScore * 0.6 + foodTypeScore * 0.4;
  }

  double _bestScore(List<String> tagIds, Map<String, int> table) {
    if (tagIds.isEmpty) return 50.0;
    var best = 0;
    for (final id in tagIds) {
      final score = table[id];
      if (score != null && score > best) best = score;
    }
    return best > 0 ? best.toDouble() : 50.0;
  }
}
