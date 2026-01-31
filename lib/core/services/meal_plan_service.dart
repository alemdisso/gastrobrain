import '../../database/database_helper.dart';
import '../../models/meal_plan.dart';
import '../../models/meal_plan_item.dart';
import '../../models/meal_plan_item_recipe.dart';
import '../../models/recipe.dart';
import '../../utils/id_generator.dart';

/// Service for managing meal plan operations
///
/// Handles creation, modification, and deletion of meal plans and their items.
/// Encapsulates the business logic for meal planning operations.
class MealPlanService {
  final DatabaseHelper _dbHelper;

  const MealPlanService(this._dbHelper);

  /// Gets the meal plan for a specific week, or null if none exists
  Future<MealPlan?> getMealPlanForWeek(DateTime weekStart) async {
    return await _dbHelper.getMealPlanForWeek(weekStart);
  }

  /// Gets or creates a meal plan for the specified week
  ///
  /// If a meal plan already exists for the week, returns it.
  /// Otherwise, creates a new meal plan and saves it to the database.
  Future<MealPlan> getOrCreateMealPlan(DateTime weekStart) async {
    final existing = await _dbHelper.getMealPlanForWeek(weekStart);
    if (existing != null) {
      return existing;
    }

    // Create new meal plan for this week
    final newPlanId = IdGenerator.generateId();
    final newPlan = MealPlan.forWeek(newPlanId, weekStart);
    await _dbHelper.insertMealPlan(newPlan);

    return newPlan;
  }

  /// Adds or updates a meal in a specific slot (date + meal type)
  ///
  /// If the slot already has a meal, it will be replaced.
  /// Returns the updated meal plan.
  Future<MealPlan> addOrUpdateMealToSlot({
    required MealPlan mealPlan,
    required DateTime date,
    required String mealType,
    required Recipe primaryRecipe,
    List<Recipe> additionalRecipes = const [],
  }) async {
    // Check if there's already a meal in this slot
    final existingItems =
        mealPlan.getItemsForDateAndMealType(date, mealType);

    if (existingItems.isNotEmpty) {
      // Remove existing items for this slot
      for (final item in existingItems) {
        await _dbHelper.deleteMealPlanItem(item.id);
        mealPlan.removeItem(item.id);
      }
    }

    // Create the new meal plan item
    final planItemId = IdGenerator.generateId();
    final planItem = MealPlanItem(
      id: planItemId,
      mealPlanId: mealPlan.id,
      plannedDate: MealPlanItem.formatPlannedDate(date),
      mealType: mealType,
    );

    // Create junction records for all recipes
    final mealPlanItemRecipes = _createRecipeJunctions(
      planItemId,
      primaryRecipe,
      additionalRecipes,
    );

    // Set the recipes list for the item
    planItem.mealPlanItemRecipes = mealPlanItemRecipes;

    // Add to meal plan
    mealPlan.addItem(planItem);

    // Save to database
    await _dbHelper.insertMealPlanItem(planItem);

    // Save all junction records
    for (final junction in mealPlanItemRecipes) {
      await _dbHelper.insertMealPlanItemRecipe(junction);
    }

    await _dbHelper.updateMealPlan(mealPlan);

    return mealPlan;
  }

  /// Removes a meal from a specific slot
  ///
  /// Returns the updated meal plan.
  Future<MealPlan> removeMealFromSlot({
    required MealPlan mealPlan,
    required DateTime date,
    required String mealType,
  }) async {
    final items = mealPlan.getItemsForDateAndMealType(date, mealType);

    for (final item in items) {
      await _dbHelper.deleteMealPlanItem(item.id);
      mealPlan.removeItem(item.id);
    }

    await _dbHelper.updateMealPlan(mealPlan);

    return mealPlan;
  }

  /// Updates the recipes for an existing meal plan item
  ///
  /// Replaces all current recipes with the new primary and additional recipes.
  Future<void> updateMealItemRecipes({
    required MealPlanItem mealPlanItem,
    required Recipe primaryRecipe,
    List<Recipe> additionalRecipes = const [],
  }) async {
    // Delete existing junction records for this meal plan item
    await _dbHelper.deleteMealPlanItemRecipesByItemId(mealPlanItem.id);

    // Create new junction records
    final newMealPlanItemRecipes = _createRecipeJunctions(
      mealPlanItem.id,
      primaryRecipe,
      additionalRecipes,
    );

    // Insert all new junction records
    for (final junction in newMealPlanItemRecipes) {
      await _dbHelper.insertMealPlanItemRecipe(junction);
    }
  }

  /// Creates junction table records linking a meal plan item to its recipes
  ///
  /// The [primaryRecipe] is marked as the primary dish.
  /// [additionalRecipes] are marked as side dishes.
  List<MealPlanItemRecipe> _createRecipeJunctions(
    String mealPlanItemId,
    Recipe primaryRecipe,
    List<Recipe> additionalRecipes,
  ) {
    final junctions = <MealPlanItemRecipe>[];

    // Add primary recipe
    junctions.add(MealPlanItemRecipe(
      mealPlanItemId: mealPlanItemId,
      recipeId: primaryRecipe.id,
      isPrimaryDish: true,
    ));

    // Add additional recipes as side dishes
    for (final additionalRecipe in additionalRecipes) {
      junctions.add(MealPlanItemRecipe(
        mealPlanItemId: mealPlanItemId,
        recipeId: additionalRecipe.id,
        isPrimaryDish: false,
      ));
    }

    return junctions;
  }
}
