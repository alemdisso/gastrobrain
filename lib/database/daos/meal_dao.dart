// lib/database/daos/meal_dao.dart

import 'package:sqflite/sqflite.dart';
import '../../models/meal.dart';
import '../../models/meal_recipe.dart';
import '../../models/meal_ingredient.dart';
import '../../core/errors/gastrobrain_exceptions.dart';

class MealDao {
  final Future<Database> Function() _getDb;

  MealDao(this._getDb);

  // Meal CRUD

  Future<int> insertMeal(Meal meal) async {
    final db = await _getDb();
    return await db.insert('meals', meal.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Meal>> getMealsForRecipe(String recipeId) async {
    final db = await _getDb();
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT DISTINCT m.*
      FROM meals m
      LEFT JOIN meal_recipes mr ON m.id = mr.meal_id
      WHERE mr.recipe_id = ? OR m.recipe_id = ?
      ORDER BY date(m.cooked_at) DESC,
               CASE m.meal_type
                 WHEN 'dinner' THEN 0
                 WHEN 'lunch'  THEN 1
                 ELSE               2
               END ASC
    ''', [recipeId, recipeId]);

    final meals = List.generate(maps.length, (i) => Meal.fromMap(maps[i]));
    for (final meal in meals) {
      meal.mealRecipes = await getMealRecipesForMeal(meal.id);
      final sides = await getMealIngredientsForMeal(meal.id);
      if (sides.isNotEmpty) meal.mealIngredients = sides;
    }
    return meals;
  }

  Future<Meal?> getMeal(String id) async {
    final db = await _getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      'meals',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;

    final meal = Meal.fromMap(maps.first);
    meal.mealRecipes = await getMealRecipesForMeal(id);
    final sides = await getMealIngredientsForMeal(id);
    if (sides.isNotEmpty) meal.mealIngredients = sides;
    return meal;
  }

  Future<int> updateMeal(Meal meal) async {
    final db = await _getDb();
    return await db.update(
      'meals',
      meal.toMap(),
      where: 'id = ?',
      whereArgs: [meal.id],
    );
  }

  Future<int> deleteMeal(String id) async {
    final db = await _getDb();
    return await db.delete('meals', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Meal>> getAllMeals() async {
    final db = await _getDb();
    final List<Map<String, dynamic>> mealMaps = await db.query(
      'meals',
      orderBy: "date(cooked_at) DESC, CASE meal_type WHEN 'dinner' THEN 0 WHEN 'lunch' THEN 1 ELSE 2 END ASC",
    );

    final meals = <Meal>[];
    for (final mealMap in mealMaps) {
      final String mealId = mealMap['id'];
      final recipeMaps = await db.query('meal_recipes', where: 'meal_id = ?', whereArgs: [mealId]);
      final meal = Meal.fromMap(mealMap);
      meal.mealRecipes = List.generate(recipeMaps.length, (i) => MealRecipe.fromMap(recipeMaps[i]));
      final sideMaps = await db.query('meal_ingredients', where: 'meal_id = ?', whereArgs: [mealId]);
      if (sideMaps.isNotEmpty) {
        meal.mealIngredients = List.generate(sideMaps.length, (i) => MealIngredient.fromMap(sideMaps[i]));
      }
      meals.add(meal);
    }
    return meals;
  }

  Future<List<Meal>> getRecentMeals({int limit = 10}) async {
    final db = await _getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      'meals',
      orderBy: "date(cooked_at) DESC, CASE meal_type WHEN 'dinner' THEN 0 WHEN 'lunch' THEN 1 ELSE 2 END ASC",
      limit: limit,
    );
    return List.generate(maps.length, (i) => Meal.fromMap(maps[i]));
  }

  // MealRecipe (junction: meals ↔ recipes)

  Future<String> insertMealRecipe(MealRecipe mealRecipe) async {
    final db = await _getDb();
    try {
      await db.insert('meal_recipes', mealRecipe.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      return mealRecipe.id;
    } catch (e) {
      throw GastrobrainException('Failed to insert meal recipe: ${e.toString()}');
    }
  }

  Future<List<MealRecipe>> getMealRecipesForMeal(String mealId) async {
    final db = await _getDb();
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'meal_recipes',
        where: 'meal_id = ?',
        whereArgs: [mealId],
      );
      return List.generate(maps.length, (i) => MealRecipe.fromMap(maps[i]));
    } catch (e) {
      throw GastrobrainException('Failed to get meal recipes: ${e.toString()}');
    }
  }

  Future<int> updateMealRecipe(MealRecipe mealRecipe) async {
    final db = await _getDb();
    return await db.update(
      'meal_recipes',
      mealRecipe.toMap(),
      where: 'id = ?',
      whereArgs: [mealRecipe.id],
    );
  }

  Future<int> deleteMealRecipe(String id) async {
    final db = await _getDb();
    return await db.delete('meal_recipes', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteMealRecipesByMealId(String mealId, {bool excludePrimary = false}) async {
    final db = await _getDb();
    try {
      if (excludePrimary) {
        return await db.delete(
          'meal_recipes',
          where: 'meal_id = ? AND is_primary_dish = 0',
          whereArgs: [mealId],
        );
      } else {
        return await db.delete('meal_recipes', where: 'meal_id = ?', whereArgs: [mealId]);
      }
    } catch (e) {
      throw GastrobrainException('Failed to delete meal recipes: ${e.toString()}');
    }
  }

  Future<String> addRecipeToMeal(String mealId, String recipeId, {bool isPrimaryDish = false}) async {
    final db = await _getDb();
    try {
      final mealExists = await db.query('meals', where: 'id = ?', whereArgs: [mealId], limit: 1);
      if (mealExists.isEmpty) throw NotFoundException('Meal not found with id: $mealId');

      final recipeExists = await db.query('recipes', where: 'id = ?', whereArgs: [recipeId], limit: 1);
      if (recipeExists.isEmpty) throw NotFoundException('Recipe not found with id: $recipeId');

      final existing = await db.query(
        'meal_recipes',
        where: 'meal_id = ? AND recipe_id = ?',
        whereArgs: [mealId, recipeId],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        if (isPrimaryDish) {
          await db.update('meal_recipes', {'is_primary_dish': 0}, where: 'meal_id = ?', whereArgs: [mealId]);
          await db.update('meal_recipes', {'is_primary_dish': 1},
              where: 'meal_id = ? AND recipe_id = ?', whereArgs: [mealId, recipeId]);
        }
        return existing.first['id'] as String;
      }

      if (isPrimaryDish) {
        await db.update('meal_recipes', {'is_primary_dish': 0}, where: 'meal_id = ?', whereArgs: [mealId]);
      }

      final mealRecipe = MealRecipe(mealId: mealId, recipeId: recipeId, isPrimaryDish: isPrimaryDish);
      await db.insert('meal_recipes', mealRecipe.toMap());
      return mealRecipe.id;
    } catch (e) {
      if (e is NotFoundException) rethrow;
      throw GastrobrainException('Failed to add recipe to meal: ${e.toString()}');
    }
  }

  Future<bool> removeRecipeFromMeal(String mealId, String recipeId) async {
    final db = await _getDb();
    try {
      final deleted = await db.delete(
        'meal_recipes',
        where: 'meal_id = ? AND recipe_id = ?',
        whereArgs: [mealId, recipeId],
      );
      return deleted > 0;
    } catch (e) {
      throw GastrobrainException('Failed to remove recipe from meal: ${e.toString()}');
    }
  }

  Future<bool> setPrimaryRecipeForMeal(String mealId, String recipeId) async {
    final db = await _getDb();
    try {
      await db.transaction((txn) async {
        await txn.update('meal_recipes', {'is_primary_dish': 0}, where: 'meal_id = ?', whereArgs: [mealId]);
        final updated = await txn.update(
          'meal_recipes',
          {'is_primary_dish': 1},
          where: 'meal_id = ? AND recipe_id = ?',
          whereArgs: [mealId, recipeId],
        );
        if (updated == 0) {
          final mealRecipe = MealRecipe(mealId: mealId, recipeId: recipeId, isPrimaryDish: true);
          await txn.insert('meal_recipes', mealRecipe.toMap());
        }
      });
      return true;
    } catch (e) {
      throw GastrobrainException('Failed to set primary recipe: ${e.toString()}');
    }
  }

  // MealIngredient (simple sides on recorded meals)

  Future<String> insertMealIngredient(MealIngredient side) async {
    final db = await _getDb();
    try {
      await db.insert('meal_ingredients', side.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      return side.id;
    } catch (e) {
      throw GastrobrainException('Failed to insert meal ingredient: ${e.toString()}');
    }
  }

  Future<List<MealIngredient>> getMealIngredientsForMeal(String mealId) async {
    final db = await _getDb();
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'meal_ingredients',
        where: 'meal_id = ?',
        whereArgs: [mealId],
      );
      return List.generate(maps.length, (i) => MealIngredient.fromMap(maps[i]));
    } catch (e) {
      throw GastrobrainException('Failed to get meal ingredients: ${e.toString()}');
    }
  }

  Future<int> deleteMealIngredient(String id) async {
    final db = await _getDb();
    try {
      return await db.delete('meal_ingredients', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw GastrobrainException('Failed to delete meal ingredient: ${e.toString()}');
    }
  }

  Future<int> deleteMealIngredientsByMealId(String mealId) async {
    final db = await _getDb();
    try {
      return await db.delete('meal_ingredients', where: 'meal_id = ?', whereArgs: [mealId]);
    } catch (e) {
      throw GastrobrainException('Failed to delete meal ingredients: ${e.toString()}');
    }
  }

  // Meal statistics

  Future<DateTime?> getLastCookedDate(String recipeId) async {
    final db = await _getDb();
    final List<Map<String, dynamic>> result = await db.query(
      'meals',
      columns: ['cooked_at'],
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
      orderBy: 'cooked_at DESC',
      limit: 1,
    );
    if (result.isNotEmpty) {
      return DateTime.parse(result.first['cooked_at']);
    }
    return null;
  }

  Future<int> getTimesCookedCount(String recipeId) async {
    final db = await _getDb();
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM meals WHERE recipe_id = ?',
      [recipeId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Map<String, int>> getAllMealCounts() async {
    final db = await _getDb();
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT recipe_id, COUNT(*) as count
      FROM (
        SELECT recipe_id FROM meals WHERE recipe_id IS NOT NULL
        UNION ALL
        SELECT recipe_id FROM meal_recipes
      )
      GROUP BY recipe_id
    ''');
    return Map.fromEntries(
      results.map((row) => MapEntry(row['recipe_id'] as String, row['count'] as int)),
    );
  }

  Future<Map<String, DateTime>> getAllLastCooked() async {
    final db = await _getDb();
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT recipe_id, MAX(cooked_at) as last_cooked
      FROM (
        SELECT m.recipe_id, m.cooked_at
        FROM meals m
        WHERE m.recipe_id IS NOT NULL

        UNION ALL

        SELECT mr.recipe_id, m.cooked_at
        FROM meal_recipes mr
        JOIN meals m ON mr.meal_id = m.id
      )
      GROUP BY recipe_id
    ''');
    return Map.fromEntries(
      results.map((row) => MapEntry(
            row['recipe_id'] as String,
            DateTime.parse(row['last_cooked'] as String),
          )),
    );
  }
}
