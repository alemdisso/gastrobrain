// test/test_utils/dialog_fixtures.dart

import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/meal.dart';
import 'package:gastrobrain/models/ingredient.dart';
import 'package:gastrobrain/models/ingredient_category.dart';
import 'package:gastrobrain/models/measurement_unit.dart';
import 'package:gastrobrain/models/protein_type.dart';
import 'package:gastrobrain/models/frequency_type.dart';

/// Common test fixtures for dialog testing.
///
/// This class provides pre-configured test data that can be reused
/// across dialog tests, ensuring consistency and reducing boilerplate.
///
/// Example usage:
/// ```dart
/// testWidgets('dialog test', (tester) async {
///   final recipe = DialogFixtures.createTestRecipe();
///   final meal = DialogFixtures.createTestMeal();
///   // ... use in test
/// });
/// ```
class DialogFixtures {
  // ========== Recipe Fixtures ==========

  /// Creates a basic test recipe with default values.
  ///
  /// Use this as a starting point and override specific fields as needed.
  static Recipe createTestRecipe({
    String? id,
    String? name,
    int? difficulty,
    int? prepTimeMinutes,
    int? cookTimeMinutes,
    int? rating,
  }) {
    return Recipe(
      id: id ?? 'test-recipe-default',
      name: name ?? 'Test Recipe',
      desiredFrequency: FrequencyType.weekly,
      createdAt: DateTime.now(),
      difficulty: difficulty ?? 3,
      prepTimeMinutes: prepTimeMinutes ?? 15,
      cookTimeMinutes: cookTimeMinutes ?? 25,
      rating: rating ?? 0,
    );
  }

  /// Creates a test recipe for meal editing workflows.
  static Recipe createPrimaryRecipe() {
    return Recipe(
      id: 'primary-recipe-test',
      name: 'Grilled Chicken',
      desiredFrequency: FrequencyType.weekly,
      createdAt: DateTime.now(),
      difficulty: 3,
      prepTimeMinutes: 15,
      cookTimeMinutes: 25,
      rating: 4,
    );
  }

  /// Creates a test side dish recipe.
  static Recipe createSideRecipe() {
    return Recipe(
      id: 'side-recipe-test',
      name: 'Rice Pilaf',
      desiredFrequency: FrequencyType.weekly,
      createdAt: DateTime.now(),
      difficulty: 2,
      prepTimeMinutes: 5,
      cookTimeMinutes: 20,
      rating: 4,
    );
  }

  /// Creates a list of test recipes for testing bulk operations.
  static List<Recipe> createMultipleRecipes(int count) {
    return List.generate(
      count,
      (index) => Recipe(
        id: 'test-recipe-$index',
        name: 'Test Recipe $index',
        desiredFrequency: FrequencyType.weekly,
        createdAt: DateTime.now(),
        difficulty: (index % 5) + 1,
        prepTimeMinutes: 10 + (index * 5),
        cookTimeMinutes: 20 + (index * 5),
      ),
    );
  }

  // ========== Meal Fixtures ==========

  /// Creates a basic test meal.
  static Meal createTestMeal({
    String? id,
    int? servings,
    String? notes,
    bool? wasSuccessful,
    double? actualPrepTime,
    double? actualCookTime,
  }) {
    return Meal(
      id: id ?? 'test-meal-default',
      cookedAt: DateTime.now().subtract(const Duration(days: 1)),
      servings: servings ?? 3,
      notes: notes ?? 'Test meal notes',
      wasSuccessful: wasSuccessful ?? true,
      actualPrepTime: actualPrepTime ?? 20.0,
      actualCookTime: actualCookTime ?? 30.0,
    );
  }

  /// Creates a meal for edit dialog testing with realistic data.
  static Meal createEditableMeal() {
    return Meal(
      id: 'editable-meal-test',
      cookedAt: DateTime.now().subtract(const Duration(days: 2)),
      servings: 3,
      notes: 'Original test notes',
      wasSuccessful: true,
      actualPrepTime: 20.0,
      actualCookTime: 30.0,
    );
  }

  /// Creates a meal with minimal data (only required fields).
  static Meal createMinimalMeal() {
    return Meal(
      id: 'minimal-meal-test',
      cookedAt: DateTime.now(),
      servings: 1,
      wasSuccessful: true,
    );
  }

  /// Creates an unsuccessful meal for testing that scenario.
  static Meal createUnsuccessfulMeal() {
    return Meal(
      id: 'unsuccessful-meal-test',
      cookedAt: DateTime.now(),
      servings: 2,
      notes: 'Recipe didn\'t turn out well',
      wasSuccessful: false,
      actualPrepTime: 25.0,
      actualCookTime: 40.0,
    );
  }

  // ========== Ingredient Fixtures ==========

  /// Creates a basic vegetable ingredient.
  static Ingredient createVegetableIngredient({
    String? id,
    String? name,
  }) {
    return Ingredient(
      id: id ?? 'test-ingredient-vegetable',
      name: name ?? 'Carrots',
      category: IngredientCategory.vegetable,
      unit: MeasurementUnit.gram,
    );
  }

  /// Creates a basic protein ingredient.
  static Ingredient createProteinIngredient({
    String? id,
    String? name,
    ProteinType? proteinType,
  }) {
    return Ingredient(
      id: id ?? 'test-ingredient-protein',
      name: name ?? 'Chicken Breast',
      category: IngredientCategory.protein,
      proteinType: proteinType ?? ProteinType.chicken,
      unit: MeasurementUnit.gram,
    );
  }

  /// Creates a list of test ingredients for dropdown/selection testing.
  static List<Ingredient> createMultipleIngredients() {
    return [
      Ingredient(
        id: 'ing-1',
        name: 'Carrots',
        category: IngredientCategory.vegetable,
        unit: MeasurementUnit.gram,
      ),
      Ingredient(
        id: 'ing-2',
        name: 'Chicken Breast',
        category: IngredientCategory.protein,
        proteinType: ProteinType.chicken,
        unit: MeasurementUnit.gram,
      ),
      Ingredient(
        id: 'ing-3',
        name: 'Rice',
        category: IngredientCategory.grain,
        unit: MeasurementUnit.cup,
      ),
      Ingredient(
        id: 'ing-4',
        name: 'Olive Oil',
        category: IngredientCategory.oil,
        unit: MeasurementUnit.tablespoon,
      ),
    ];
  }

  // ========== Dialog Input Data Fixtures ==========

  /// Common dialog form data for meal recording.
  static Map<String, dynamic> mealRecordingFormData({
    int? servings,
    String? notes,
    bool? wasSuccessful,
    double? prepTime,
    double? cookTime,
  }) {
    return {
      'cookedAt': DateTime.now(),
      'servings': servings ?? 2,
      'notes': notes ?? 'Test meal recording',
      'wasSuccessful': wasSuccessful ?? true,
      'actualPrepTime': prepTime ?? 15.0,
      'actualCookTime': cookTime ?? 25.0,
    };
  }

  /// Common dialog form data for editing meals.
  static Map<String, dynamic> mealEditFormData({
    int? servings,
    String? notes,
    bool? wasSuccessful,
  }) {
    return {
      'servings': servings ?? 4,
      'notes': notes ?? 'Updated test notes',
      'wasSuccessful': wasSuccessful ?? true,
    };
  }

  // ========== Date/Time Fixtures ==========

  /// Returns a date in the past (for testing cooked meals).
  static DateTime pastDate({int daysAgo = 1}) {
    return DateTime.now().subtract(Duration(days: daysAgo));
  }

  /// Returns a date in the future (for testing planned meals).
  static DateTime futureDate({int daysAhead = 1}) {
    return DateTime.now().add(Duration(days: daysAhead));
  }

  /// Returns the current date/time.
  static DateTime now() {
    return DateTime.now();
  }

  // ========== Validation Fixtures ==========

  /// Returns invalid servings values for boundary testing.
  static List<String> invalidServingsValues() {
    return ['0', '-1', 'abc', '999999'];
  }

  /// Returns valid servings values for testing.
  static List<String> validServingsValues() {
    return ['1', '2', '4', '10'];
  }

  /// Returns very long text for boundary testing.
  static String veryLongText({int length = 1000}) {
    return 'A' * length;
  }

  /// Returns empty or whitespace strings for validation testing.
  static List<String> emptyOrWhitespaceStrings() {
    return ['', '   ', '\n', '\t'];
  }
}