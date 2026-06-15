import 'dart:convert';

import 'package:gastrobrain/database/database_helper.dart';
import 'package:gastrobrain/core/repositories/tag_repository.dart';
import 'package:gastrobrain/models/frequency_type.dart';
import 'package:gastrobrain/models/ingredient.dart';
import 'package:gastrobrain/models/ingredient_category.dart';
import 'package:gastrobrain/models/measurement_unit.dart';
import 'package:gastrobrain/models/meal.dart';
import 'package:gastrobrain/models/meal_ingredient.dart';
import 'package:gastrobrain/models/meal_plan.dart';
import 'package:gastrobrain/models/meal_plan_item.dart';
import 'package:gastrobrain/models/meal_plan_item_ingredient.dart';
import 'package:gastrobrain/models/meal_plan_item_recipe.dart';
import 'package:gastrobrain/models/meal_recipe.dart';
import 'package:gastrobrain/models/protein_type.dart';
import 'package:gastrobrain/models/recipe.dart';
import 'package:gastrobrain/models/recipe_ingredient.dart';
import 'package:gastrobrain/utils/id_generator.dart';

/// Seeds [dbHelper]'s database with one row of relational data in every
/// table currently covered by `DatabaseBackupService`, for use by the
/// backup round-trip test (#402).
///
/// Covers: ingredients (one with aliases, one with a protein type), recipes
/// (with recipe_ingredients, recipe_tags — a custom tag and a built-in tag,
/// story, marinating time, and non-default servings), a meal plan with one
/// item that has both a planned recipe and a simple-side ingredient, a
/// cooked meal with a recipe and a simple-side ingredient, and two
/// recommendation_history rows.
Future<void> seedBackupTestData(DatabaseHelper dbHelper) async {
  final db = await dbHelper.database;

  final ingredient1 = Ingredient(
    id: IdGenerator.generateId(),
    name: 'Tomato',
    category: IngredientCategory.vegetable,
    unit: MeasurementUnit.piece,
    notes: 'Fresh',
    aliases: const ['tomatoes', 'jitomate'],
  );
  final ingredient2 = Ingredient(
    id: IdGenerator.generateId(),
    name: 'Chicken Breast',
    category: IngredientCategory.protein,
    unit: MeasurementUnit.gram,
    proteinType: ProteinType.chicken,
  );
  await dbHelper.insertIngredient(ingredient1);
  await dbHelper.insertIngredient(ingredient2);

  final recipe1 = Recipe(
    id: IdGenerator.generateId(),
    name: 'Tomato Salad',
    createdAt: DateTime(2026, 1, 1),
    story: 'A family favorite passed down for generations.',
    marinatingTimeMinutes: 15,
    servings: 2,
    notes: 'Serve chilled',
    instructions: 'Slice tomatoes and toss with dressing.',
  );
  final recipe2 = Recipe(
    id: IdGenerator.generateId(),
    name: 'Grilled Chicken',
    createdAt: DateTime(2026, 1, 2),
    desiredFrequency: FrequencyType.weekly,
    difficulty: 3,
    prepTimeMinutes: 10,
    cookTimeMinutes: 25,
    rating: 4,
    instructions: 'Grill until cooked through.',
  );
  await dbHelper.insertRecipe(recipe1);
  await dbHelper.insertRecipe(recipe2);

  await dbHelper.addIngredientToRecipe(RecipeIngredient(
    id: IdGenerator.generateId(),
    recipeId: recipe1.id,
    ingredientId: ingredient1.id,
    quantity: 3,
    unitOverride: 'piece',
  ));
  await dbHelper.addIngredientToRecipe(RecipeIngredient(
    id: IdGenerator.generateId(),
    recipeId: recipe2.id,
    ingredientId: ingredient2.id,
    quantity: 500,
  ));

  final tagRepo = TagRepository(dbHelper);
  final customTag = await tagRepo.createTag('fusion', 'cuisine');
  await tagRepo.setTagsForRecipe(
      recipe1.id, ['dietary-vegetarian', customTag.id]);
  await tagRepo.setTagsForRecipe(recipe2.id, ['meal-role-main-dish']);

  final planCreatedAt = DateTime(2026, 6, 1, 12, 0, 0);
  final mealPlan = MealPlan(
    id: IdGenerator.generateId(),
    weekStartDate: DateTime(2026, 5, 29), // Friday
    createdAt: planCreatedAt,
    modifiedAt: planCreatedAt,
    notes: 'Test week',
  );
  await dbHelper.insertMealPlan(mealPlan);

  final mealPlanItem = MealPlanItem(
    id: IdGenerator.generateId(),
    mealPlanId: mealPlan.id,
    plannedDate: '2026-06-02',
    mealType: MealPlanItem.dinner,
    notes: 'Family dinner',
    plannedServings: 6,
  );
  await dbHelper.insertMealPlanItem(mealPlanItem);

  await dbHelper.insertMealPlanItemRecipe(MealPlanItemRecipe(
    mealPlanItemId: mealPlanItem.id,
    recipeId: recipe2.id,
    isPrimaryDish: true,
  ));

  await dbHelper.insertMealPlanItemIngredient(MealPlanItemIngredient(
    mealPlanItemId: mealPlanItem.id,
    customName: 'Steamed broccoli',
    quantity: 200,
    unit: 'g',
    notes: 'side dish',
  ));

  final meal = Meal(
    id: IdGenerator.generateId(),
    cookedAt: DateTime(2026, 6, 2, 19, 0),
    servings: 2,
    notes: 'Turned out great',
    actualPrepTime: 12,
    actualCookTime: 28,
  );
  await dbHelper.insertMeal(meal);

  await dbHelper.insertMealRecipe(MealRecipe(
    mealId: meal.id,
    recipeId: recipe2.id,
    isPrimaryDish: true,
  ));

  await dbHelper.insertMealIngredient(MealIngredient(
    mealId: meal.id,
    ingredientId: ingredient1.id,
    quantity: 2,
    unit: 'piece',
    notes: 'sliced',
  ));

  await db.insert('recommendation_history', {
    'id': IdGenerator.generateId(),
    'result_data': jsonEncode({'recipeIds': [recipe1.id, recipe2.id]}),
    'created_at': DateTime(2026, 5, 25).toIso8601String(),
    'context_type': 'weekly_plan',
    'target_date': '2026-06-01',
    'meal_type': 'dinner',
    'user_id': null,
  });
  await db.insert('recommendation_history', {
    'id': IdGenerator.generateId(),
    'result_data': jsonEncode({'recipeIds': [recipe2.id]}),
    'created_at': DateTime(2026, 5, 26).toIso8601String(),
    'context_type': 'single_meal',
    'target_date': null,
    'meal_type': 'dinner',
    'user_id': null,
  });
}
