// test/mocks/mock_database_helper.dart

import 'package:gastrobrain/database/database_helper.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/meal.dart';
import 'package:gastrobrain/models/meal_recipe.dart';
import 'package:gastrobrain/models/meal_plan.dart';
import 'package:gastrobrain/models/meal_plan_item.dart';
import 'package:gastrobrain/models/meal_plan_item_recipe.dart';
import 'package:gastrobrain/models/ingredient.dart';
import 'package:gastrobrain/models/recipe_ingredient.dart';
import 'package:sqflite/sqflite.dart';

/// A partial mock implementation of DatabaseHelper for testing.
///
/// This class implements a subset of the DatabaseHelper methods needed for
/// testing the recommendation algorithm. Other methods throw UnimplementedError.
class MockDatabaseHelper implements DatabaseHelper {
  @override
  Future<int> deleteMealPlan(String id) async {
    throw UnimplementedError('Method not implemented for tests');
  }

  @override
  Future<MealPlan?> getMealPlan(String id) async {
    return _mealPlans[id];
  }

  @override
  Future<MealPlan?> getMealPlanForWeek(DateTime startDate) async {
    final normalizedStartDate =
        DateTime(startDate.year, startDate.month, startDate.day);

    // Find a plan that starts on the given date
    try {
      return _mealPlans.values.firstWhere(
        (plan) => DateTime(plan.weekStartDate.year, plan.weekStartDate.month,
                plan.weekStartDate.day)
            .isAtSameMomentAs(normalizedStartDate),
      );
    } catch (e) {
      // No matching plan found
      return null;
    }
  }

  @override
  Future<List<MealPlanItem>> getMealPlanItemsForDate(DateTime date) async {
    final dateString = MealPlanItem.formatPlannedDate(date);

    List<MealPlanItem> result = [];

    // Search through all meal plans
    for (final plan in _mealPlans.values) {
      // Find items for this date
      final items =
          plan.items.where((item) => item.plannedDate == dateString).toList();

      result.addAll(items);
    }

    return result;
  }

  @override
  Future<String> insertMealPlan(MealPlan mealPlan) async {
    _mealPlans[mealPlan.id] = mealPlan;
    return mealPlan.id;
  }

  @override
  Future<String> insertMealPlanItem(MealPlanItem item) async {
    // Find the meal plan this item belongs to
    final plan = _mealPlans[item.mealPlanId];
    if (plan != null) {
      // Add the item to the plan
      plan.items.add(item);
    }
    return item.id;
  }

  @override
  Future<int> updateMealPlan(MealPlan mealPlan) async {
    throw UnimplementedError('Method not implemented for tests');
  }

  @override
  Future<int> updateMealPlanItem(MealPlanItem item) async {
    throw UnimplementedError('Method not implemented for tests');
  }

  // In-memory storage for entities
  final Map<String, Recipe> _recipes = {};
  final Map<String, Meal> _meals = {};
  final Map<String, MealRecipe> _mealRecipes = {};
  final Map<String, MealPlan> _mealPlans = {};
  final Map<String, MealPlanItem> _mealPlanItems = {};
  final Map<String, MealPlanItemRecipe> _mealPlanItemRecipes = {};
  final Map<String, Ingredient> _ingredients = {};
  final Map<String, RecipeIngredient> _recipeIngredients = {};

  // Additional storage for recommendation-specific data
  final Map<String, DateTime?> _lastCookedDates = {};
  final Map<String, int> _mealCounts = {};

  // We'll expose these maps for direct manipulation in tests if needed
  Map<String, Recipe> get recipes => _recipes;
  Map<String, MealPlan> get mealPlans => _mealPlans;
  Map<String, Ingredient> get ingredients => _ingredients;

  // Database property implementation
  @override
  Future<Database> get database => throw UnimplementedError(
      'The database property is not implemented in MockDatabaseHelper');

  // Reset all data
  void resetAllData() {
    _recipes.clear();
    _meals.clear();
    _mealRecipes.clear();
    _mealPlans.clear();
    _mealPlanItems.clear();
    _mealPlanItemRecipes.clear();
    _ingredients.clear();
    _recipeIngredients.clear();
    _lastCookedDates.clear();
    _mealCounts.clear();
  }

  // RECIPE OPERATIONS
  @override
  Future<int> insertRecipe(Recipe recipe) async {
    _recipes[recipe.id] = recipe;
    return 1;
  }

  @override
  Future<List<Recipe>> getAllRecipes() async {
    return _recipes.values.toList();
  }

  @override
  Future<Recipe?> getRecipe(String id) async {
    return _recipes[id];
  }

  @override
  Future<int> updateRecipe(Recipe recipe) async {
    if (!_recipes.containsKey(recipe.id)) return 0;
    _recipes[recipe.id] = recipe;
    return 1;
  }

  @override
  Future<int> deleteRecipe(String id) async {
    if (!_recipes.containsKey(id)) return 0;
    _recipes.remove(id);
    return 1;
  }

  @override
  Future<List<Recipe>> getRecipesWithSortAndFilter({
    String? sortBy,
    String? sortOrder,
    Map<String, dynamic>? filters,
  }) async {
    // A simple implementation that returns all recipes
    // In a real implementation, we would apply sorting and filtering
    return _recipes.values.toList();
  }

  // MEAL OPERATIONS
  @override
  Future<int> insertMeal(Meal meal) async {
    _meals[meal.id] = meal;

    // If the meal has a recipeId, update last cooked date
    if (meal.recipeId != null) {
      _lastCookedDates[meal.recipeId!] = meal.cookedAt;
      _mealCounts[meal.recipeId!] = (_mealCounts[meal.recipeId!] ?? 0) + 1;
    }

    return 1;
  }

  @override
  Future<Meal?> getMeal(String id) async {
    return _meals[id];
  }

  @override
  Future<List<Meal>> getMealsForRecipe(String recipeId) async {
    // Return meals with direct recipeId reference OR meals linked via junction table
    final directMeals =
        _meals.values.where((meal) => meal.recipeId == recipeId).toList();

    // Get meal IDs from junction table
    final junctionMealIds = _mealRecipes.values
        .where((mr) => mr.recipeId == recipeId)
        .map((mr) => mr.mealId)
        .toSet();

    // Add meals referenced via junction table
    final junctionMeals = _meals.values
        .where((meal) => junctionMealIds.contains(meal.id))
        .toList();

    // Combine both lists
    directMeals.addAll(junctionMeals);
    return directMeals;
  }

  @override
  Future<int> deleteMeal(String id) async {
    if (!_meals.containsKey(id)) return 0;

    // Remove related junction records
    _mealRecipes.removeWhere((_, mr) => mr.mealId == id);

    _meals.remove(id);
    return 1;
  }

  @override
  Future<List<Meal>> getRecentMeals({int limit = 10}) async {
    // Sort meals by cookedAt and return the most recent ones
    final sortedMeals = _meals.values.toList()
      ..sort((a, b) => b.cookedAt.compareTo(a.cookedAt));

    return sortedMeals.take(limit).toList();
  }

  // MEAL RECIPE OPERATIONS
  @override
  Future<String> insertMealRecipe(MealRecipe mealRecipe) async {
    _mealRecipes[mealRecipe.id] = mealRecipe;

    // Update last cooked date and count
    if (_meals.containsKey(mealRecipe.mealId)) {
      final meal = _meals[mealRecipe.mealId]!;
      _lastCookedDates[mealRecipe.recipeId] = meal.cookedAt;
      _mealCounts[mealRecipe.recipeId] =
          (_mealCounts[mealRecipe.recipeId] ?? 0) + 1;
    }

    return mealRecipe.id;
  }

  @override
  Future<List<MealRecipe>> getMealRecipesForMeal(String mealId) async {
    return _mealRecipes.values.where((mr) => mr.mealId == mealId).toList();
  }

  // LAST COOKED DATE AND MEAL COUNTS
  @override
  Future<DateTime?> getLastCookedDate(String recipeId) async {
    return _lastCookedDates[recipeId];
  }

  @override
  Future<int> getTimesCookedCount(String recipeId) async {
    return _mealCounts[recipeId] ?? 0;
  }

  @override
  Future<Map<String, DateTime>> getAllLastCooked() async {
    // Filter out null dates
    return Map.fromEntries(_lastCookedDates.entries
        .where((entry) => entry.value != null)
        .map((entry) => MapEntry(entry.key, entry.value!)));
  }

  @override
  Future<Map<String, int>> getAllMealCounts() async {
    return Map.from(_mealCounts);
  }

  // Override for resetDatabaseForTests to support integration tests
  @override
  Future<void> resetDatabaseForTests() async {
    resetAllData();
  }

  // INGREDIENT OPERATIONS
  @override
  Future<String> insertIngredient(Ingredient ingredient) async {
    _ingredients[ingredient.id] = ingredient;
    return ingredient.id;
  }

  @override
  Future<List<Ingredient>> getAllIngredients() async {
    return _ingredients.values.toList();
  }

  // Not implemented methods - these would need to be added as needed
  @override
  Future<void> addIngredientToRecipe(RecipeIngredient recipeIngredient) {
    throw UnimplementedError('Method not implemented for tests');
  }

  @override
  Future<String> addRecipeToMeal(String mealId, String recipeId,
      {bool isPrimaryDish = false}) {
    throw UnimplementedError('Method not implemented for tests');
  }

  @override
  Future<void> importIngredientsFromJson(String assetPath) {
    throw UnimplementedError('Method not implemented for tests');
  }

  @override
  Future<int> deleteMealPlanItem(String id) {
    throw UnimplementedError('Method not implemented for tests');
  }

  @override
  Future<int> deleteMealRecipe(String id) {
    throw UnimplementedError('Method not implemented for tests');
  }

  @override
  Future<int> deleteRecipeIngredient(String id) {
    throw UnimplementedError('Method not implemented for tests');
  }

  @override
  Future<List<Map<String, dynamic>>> getRecipeIngredients(String recipeId) {
    throw UnimplementedError('Method not implemented for tests');
  }

  @override
  Future<int> getIngredientsCount() {
    throw UnimplementedError('Method not implemented for tests');
  }

  @override
  Future<List<Ingredient>> getProteinIngredients({String? proteinType}) {
    throw UnimplementedError('Method not implemented for tests');
  }

  @override
  Future<bool> removeRecipeFromMeal(String mealId, String recipeId) {
    throw UnimplementedError('Method not implemented for tests');
  }

  @override
  Future<bool> setPrimaryRecipeForMeal(String mealId, String recipeId) {
    throw UnimplementedError('Method not implemented for tests');
  }

  @override
  Future<int> updateMeal(Meal meal) {
    throw UnimplementedError('Method not implemented for tests');
  }

  @override
  Future<int> updateMealRecipe(MealRecipe mealRecipe) {
    throw UnimplementedError('Method not implemented for tests');
  }

  @override
  Future<int> updateRecipeIngredient(RecipeIngredient recipeIngredient) {
    throw UnimplementedError('Method not implemented for tests');
  }

  @override
  Future<List<MealPlan>> getMealPlansByDateRange(
      DateTime start, DateTime end) async {
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);

    return _mealPlans.values.where((plan) {
      final planEndDate = plan.weekEndDate;
      return !normalizedStart.isAfter(planEndDate) &&
          !normalizedEnd.isBefore(plan.weekStartDate);
    }).toList();
  }

  @override
  Future<String> insertMealPlanItemRecipe(
      MealPlanItemRecipe mealPlanItemRecipe) async {
    // Find the item this recipe belongs to
    for (final plan in _mealPlans.values) {
      for (final item in plan.items) {
        if (item.id == mealPlanItemRecipe.mealPlanItemId) {
          // Found the item, add the recipe to it
          item.mealPlanItemRecipes ??= [];
          item.mealPlanItemRecipes!.add(mealPlanItemRecipe);
          return mealPlanItemRecipe.id;
        }
      }
    }

    // Item not found
    return mealPlanItemRecipe.id;
  }
}
