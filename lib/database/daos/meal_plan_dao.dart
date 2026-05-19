// lib/database/daos/meal_plan_dao.dart

import 'package:sqflite/sqflite.dart';
import '../../models/meal_plan.dart';
import '../../models/meal_plan_item.dart';
import '../../models/meal_plan_item_recipe.dart';
import '../../models/meal_plan_item_ingredient.dart';
import '../../core/errors/gastrobrain_exceptions.dart';
import '../../core/validators/entity_validator.dart';

class MealPlanDao {
  final Future<Database> Function() _getDb;

  MealPlanDao(this._getDb);

  // Meal Plan CRUD

  Future<String> insertMealPlan(MealPlan mealPlan) async {
    final db = await _getDb();
    try {
      EntityValidator.validateMealPlan(
        id: mealPlan.id,
        weekStartDate: mealPlan.weekStartDate,
      );
      await db.insert('meal_plans', mealPlan.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      return mealPlan.id;
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw GastrobrainException('Failed to insert meal plan: ${e.toString()}');
    }
  }

  Future<MealPlan?> getMealPlan(String id) async {
    final db = await _getDb();
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'meal_plans',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isEmpty) return null;

      final items = await _loadItemsForPlan(db, id);
      return MealPlan.fromMap(maps.first, items);
    } catch (e) {
      throw GastrobrainException('Failed to get meal plan: ${e.toString()}');
    }
  }

  Future<List<MealPlan>> getMealPlansByDateRange(DateTime start, DateTime end) async {
    final db = await _getDb();
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();

    final List<Map<String, dynamic>> planMaps = await db.rawQuery('''
      SELECT * FROM meal_plans
      WHERE week_start_date <= ? AND
            date(week_start_date, '+7 days') >= ?
      ORDER BY week_start_date ASC
    ''', [endStr, startStr]);

    final mealPlans = <MealPlan>[];
    for (final planMap in planMaps) {
      final planId = planMap['id'] as String;
      final itemMaps = await db.query('meal_plan_items', where: 'meal_plan_id = ?', whereArgs: [planId]);
      final items = List.generate(itemMaps.length, (i) => MealPlanItem.fromMap(itemMaps[i]));
      mealPlans.add(MealPlan.fromMap(planMap, items));
    }
    return mealPlans;
  }

  Future<MealPlan?> getMealPlanForWeek(DateTime date) async {
    final db = await _getDb();
    final int weekday = date.weekday;
    final daysToSubtract = weekday < 5 ? weekday + 2 : weekday - 5;
    final normalizedStart = DateTime(
      date.subtract(Duration(days: daysToSubtract)).year,
      date.subtract(Duration(days: daysToSubtract)).month,
      date.subtract(Duration(days: daysToSubtract)).day,
    );
    final startStr = normalizedStart.toIso8601String();

    final List<Map<String, dynamic>> maps = await db.query(
      'meal_plans',
      where: 'week_start_date = ?',
      whereArgs: [startStr],
    );
    if (maps.isEmpty) return null;

    final planId = maps.first['id'] as String;
    final items = await _loadItemsForPlan(db, planId);
    return MealPlan.fromMap(maps.first, items);
  }

  Future<void> updateMealPlanCookedAt(String mealPlanId, DateTime cookedAt) async {
    final db = await _getDb();
    await db.update(
      'meal_plans',
      {'last_cooked_at': cookedAt.toIso8601String()},
      where: 'id = ?',
      whereArgs: [mealPlanId],
    );
  }

  Future<int> updateMealPlan(MealPlan mealPlan) async {
    final db = await _getDb();
    try {
      EntityValidator.validateMealPlan(
        id: mealPlan.id,
        weekStartDate: mealPlan.weekStartDate,
      );
      return await db.transaction((txn) async {
        final updateCount = await txn.update(
          'meal_plans',
          mealPlan.toMap(),
          where: 'id = ?',
          whereArgs: [mealPlan.id],
        );
        if (updateCount == 0) {
          throw NotFoundException('Meal plan not found with id: ${mealPlan.id}');
        }

        await txn.delete('meal_plan_items', where: 'meal_plan_id = ?', whereArgs: [mealPlan.id]);

        for (final item in mealPlan.items) {
          EntityValidator.validateMealPlanItem(
            id: item.id,
            mealPlanId: item.mealPlanId,
            plannedDate: item.plannedDate,
            mealType: item.mealType,
          );
          await txn.insert('meal_plan_items', item.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace);

          if (item.mealPlanItemRecipes != null && item.mealPlanItemRecipes!.isNotEmpty) {
            for (final recipe in item.mealPlanItemRecipes!) {
              await txn.insert('meal_plan_item_recipes', recipe.toMap(),
                  conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
        }
        return 1;
      });
    } on ValidationException {
      rethrow;
    } on NotFoundException {
      rethrow;
    } catch (e) {
      throw GastrobrainException('Failed to update meal plan: ${e.toString()}');
    }
  }

  Future<int> deleteMealPlan(String id) async {
    final db = await _getDb();
    return await db.delete('meal_plans', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<MealPlan>> getAllMealPlans() async {
    final db = await _getDb();
    final List<Map<String, dynamic>> planMaps = await db.query(
      'meal_plans',
      orderBy: 'week_start_date DESC',
    );
    final mealPlans = <MealPlan>[];
    for (final planMap in planMaps) {
      final planId = planMap['id'] as String;
      final itemMaps = await db.query('meal_plan_items', where: 'meal_plan_id = ?', whereArgs: [planId]);
      final items = List.generate(itemMaps.length, (i) => MealPlanItem.fromMap(itemMaps[i]));
      mealPlans.add(MealPlan.fromMap(planMap, items));
    }
    return mealPlans;
  }

  // Meal Plan Items

  Future<String> insertMealPlanItem(MealPlanItem item) async {
    final db = await _getDb();
    try {
      EntityValidator.validateMealPlanItem(
        id: item.id,
        mealPlanId: item.mealPlanId,
        plannedDate: item.plannedDate,
        mealType: item.mealType,
      );
      await db.insert('meal_plan_items', item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      return item.id;
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw GastrobrainException('Failed to insert meal plan item: ${e.toString()}');
    }
  }

  Future<int> updateMealPlanItem(MealPlanItem item) async {
    final db = await _getDb();
    return await db.update('meal_plan_items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<int> deleteMealPlanItem(String id) async {
    final db = await _getDb();
    return await db.delete('meal_plan_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<MealPlanItem>> getMealPlanItemsForDate(DateTime date) async {
    final db = await _getDb();
    final dateStr = date.toIso8601String().split('T')[0];
    final List<Map<String, dynamic>> maps = await db.query(
      'meal_plan_items',
      where: 'planned_date = ?',
      whereArgs: [dateStr],
    );
    return List.generate(maps.length, (i) => MealPlanItem.fromMap(maps[i]));
  }

  Future<List<MealPlanItem>> getMealPlanItems(String mealPlanId) async {
    final db = await _getDb();
    final itemMaps = await db.query('meal_plan_items', where: 'meal_plan_id = ?', whereArgs: [mealPlanId]);
    final items = <MealPlanItem>[];
    for (final itemMap in itemMaps) {
      final item = MealPlanItem.fromMap(itemMap);
      item.mealPlanItemRecipes = await _loadRecipesForItem(db, item.id);
      item.mealPlanItemIngredients = await _loadIngredientsForItem(db, item.id);
      items.add(item);
    }
    return items;
  }

  // MealPlanItemRecipe junction

  Future<String> insertMealPlanItemRecipe(MealPlanItemRecipe mealPlanItemRecipe) async {
    final db = await _getDb();
    try {
      final mealPlanItem = await db.query(
        'meal_plan_items',
        where: 'id = ?',
        whereArgs: [mealPlanItemRecipe.mealPlanItemId],
      );
      if (mealPlanItem.isEmpty) {
        throw NotFoundException('Meal plan item not found with id: ${mealPlanItemRecipe.mealPlanItemId}');
      }
      await db.insert('meal_plan_item_recipes', mealPlanItemRecipe.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      return mealPlanItemRecipe.id;
    } catch (e) {
      throw GastrobrainException('Failed to insert meal plan item recipe: ${e.toString()}');
    }
  }

  Future<int> deleteMealPlanItemRecipesByItemId(String mealPlanItemId) async {
    final db = await _getDb();
    try {
      return await db.delete(
        'meal_plan_item_recipes',
        where: 'meal_plan_item_id = ?',
        whereArgs: [mealPlanItemId],
      );
    } catch (e) {
      throw GastrobrainException('Failed to delete meal plan item recipes: ${e.toString()}');
    }
  }

  // MealPlanItemIngredient (simple sides)

  Future<String> insertMealPlanItemIngredient(MealPlanItemIngredient side) async {
    final db = await _getDb();
    try {
      await db.insert('meal_plan_item_ingredients', side.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      return side.id;
    } catch (e) {
      throw GastrobrainException('Failed to insert meal plan item ingredient: ${e.toString()}');
    }
  }

  Future<List<MealPlanItemIngredient>> getMealPlanItemIngredientsForItem(String mealPlanItemId) async {
    final db = await _getDb();
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'meal_plan_item_ingredients',
        where: 'meal_plan_item_id = ?',
        whereArgs: [mealPlanItemId],
      );
      return List.generate(maps.length, (i) => MealPlanItemIngredient.fromMap(maps[i]));
    } catch (e) {
      throw GastrobrainException('Failed to get meal plan item ingredients: ${e.toString()}');
    }
  }

  Future<int> deleteMealPlanItemIngredient(String id) async {
    final db = await _getDb();
    try {
      return await db.delete('meal_plan_item_ingredients', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw GastrobrainException('Failed to delete meal plan item ingredient: ${e.toString()}');
    }
  }

  Future<int> deleteMealPlanItemIngredientsByItemId(String mealPlanItemId) async {
    final db = await _getDb();
    try {
      return await db.delete(
        'meal_plan_item_ingredients',
        where: 'meal_plan_item_id = ?',
        whereArgs: [mealPlanItemId],
      );
    } catch (e) {
      throw GastrobrainException('Failed to delete meal plan item ingredients: ${e.toString()}');
    }
  }

  // Private helpers

  Future<List<MealPlanItem>> _loadItemsForPlan(Database db, String planId) async {
    final itemMaps = await db.query('meal_plan_items', where: 'meal_plan_id = ?', whereArgs: [planId]);
    final items = <MealPlanItem>[];
    for (final itemMap in itemMaps) {
      final item = MealPlanItem.fromMap(itemMap);
      item.mealPlanItemRecipes = await _loadRecipesForItem(db, item.id);
      item.mealPlanItemIngredients = await _loadIngredientsForItem(db, item.id);
      items.add(item);
    }
    return items;
  }

  Future<List<MealPlanItemRecipe>?> _loadRecipesForItem(Database db, String itemId) async {
    final maps = await db.query('meal_plan_item_recipes', where: 'meal_plan_item_id = ?', whereArgs: [itemId]);
    if (maps.isEmpty) return null;
    return List.generate(maps.length, (i) => MealPlanItemRecipe.fromMap(maps[i]));
  }

  Future<List<MealPlanItemIngredient>?> _loadIngredientsForItem(Database db, String itemId) async {
    final maps = await db.query('meal_plan_item_ingredients', where: 'meal_plan_item_id = ?', whereArgs: [itemId]);
    if (maps.isEmpty) return null;
    return List.generate(maps.length, (i) => MealPlanItemIngredient.fromMap(maps[i]));
  }
}
