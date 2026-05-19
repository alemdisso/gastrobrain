// lib/database/daos/ingredient_dao.dart

import 'package:sqflite/sqflite.dart';
import '../../models/ingredient.dart';
import '../../models/recipe_ingredient.dart';

class IngredientDao {
  final Future<Database> Function() _getDb;

  IngredientDao(this._getDb);

  // Ingredient CRUD

  Future<String> insertIngredient(Ingredient ingredient) async {
    final db = await _getDb();
    await db.insert('ingredients', ingredient.toMap());
    return ingredient.id;
  }

  Future<List<Ingredient>> getAllIngredients() async {
    final db = await _getDb();
    final List<Map<String, dynamic>> maps = await db.query('ingredients');
    return List.generate(maps.length, (i) => Ingredient.fromMap(maps[i]));
  }

  Future<Ingredient?> getIngredient(String id) async {
    final db = await _getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      'ingredients',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Ingredient.fromMap(maps.first);
  }

  Future<Ingredient?> findIngredientByName(String name) async {
    final db = await _getDb();
    final results = await db.query(
      'ingredients',
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Ingredient.fromMap(results.first);
  }

  Future<List<Ingredient>> getProteinIngredients({String? proteinType}) async {
    final db = await _getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      'ingredients',
      where: proteinType != null ? 'protein_type = ?' : 'protein_type IS NOT NULL',
      whereArgs: proteinType != null ? [proteinType] : null,
    );
    return List.generate(maps.length, (i) => Ingredient.fromMap(maps[i]));
  }

  Future<int> updateIngredient(Ingredient ingredient) async {
    final db = await _getDb();
    return await db.update(
      'ingredients',
      ingredient.toMap(),
      where: 'id = ?',
      whereArgs: [ingredient.id],
    );
  }

  Future<int> deleteIngredient(String id) async {
    final db = await _getDb();
    return await db.delete(
      'ingredients',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getIngredientsCount() async {
    final db = await _getDb();
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM ingredients');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Recipe ingredients (join table)

  Future<void> addIngredientToRecipe(RecipeIngredient recipeIngredient) async {
    final db = await _getDb();
    await db.insert('recipe_ingredients', recipeIngredient.toMap());
  }

  Future<List<Map<String, dynamic>>> getRecipeIngredients(String recipeId) async {
    final db = await _getDb();
    return await db.rawQuery('''
      SELECT
      ri.id as recipe_ingredient_id,
      ri.quantity,
      ri.quantity_max,
      ri.notes as preparation_notes,
      ri.unit_override,
      ri.custom_name,
      ri.custom_category,
      ri.custom_unit,
      ri.ingredient_id,
      COALESCE(ri.custom_name, i.name) as name,
      COALESCE(ri.custom_category, i.category) as category,
      COALESCE(ri.custom_unit, COALESCE(ri.unit_override, i.unit)) as unit,
      i.protein_type,
      i.notes as ingredient_notes
    FROM recipe_ingredients ri
    LEFT JOIN ingredients i ON ri.ingredient_id = i.id
    WHERE ri.recipe_id = ?
    ''', [recipeId]);
  }

  Future<List<Map<String, dynamic>>> getRecipesByIngredientId(String ingredientId) async {
    final db = await _getDb();
    return await db.rawQuery('''
      SELECT r.*,
        ri.quantity AS usage_quantity,
        COALESCE(ri.custom_unit, COALESCE(ri.unit_override, i.unit)) AS usage_unit,
        (SELECT COUNT(*) FROM recipe_ingredients WHERE recipe_id = r.id) AS ingredient_count
      FROM recipes r
      JOIN recipe_ingredients ri ON r.id = ri.recipe_id
      LEFT JOIN ingredients i ON i.id = ri.ingredient_id
      WHERE ri.ingredient_id = ?
      ORDER BY r.name ASC
    ''', [ingredientId]);
  }

  /// Returns meals where this ingredient appeared (via recipes or direct sides).
  /// [sinceDate] optional ISO-8601 cutoff (inclusive).
  Future<List<Map<String, dynamic>>> getMealHistoryByIngredientId(
    String ingredientId, {
    String? sinceDate,
  }) async {
    final db = await _getDb();
    final args = <dynamic>[ingredientId];
    final dateFilter = sinceDate != null ? 'AND m.cooked_at >= ?' : '';
    if (sinceDate != null) args.add(sinceDate);

    final viaRecipes = await db.rawQuery('''
      SELECT m.id AS meal_id, m.cooked_at, m.meal_type,
             r.name AS recipe_name, 'recipe' AS source
      FROM meals m
      JOIN meal_recipes mr ON mr.meal_id = m.id
      JOIN recipe_ingredients ri ON ri.recipe_id = mr.recipe_id
      JOIN recipes r ON r.id = mr.recipe_id
      WHERE ri.ingredient_id = ?
      $dateFilter
    ''', args);

    final directArgs = <dynamic>[ingredientId];
    if (sinceDate != null) directArgs.add(sinceDate);
    final viaDirectSides = await db.rawQuery('''
      SELECT m.id AS meal_id, m.cooked_at, m.meal_type,
             NULL AS recipe_name, 'side' AS source
      FROM meals m
      JOIN meal_ingredients mi ON mi.meal_id = m.id
      WHERE mi.ingredient_id = ?
      $dateFilter
    ''', directArgs);

    // Merge and deduplicate by meal_id
    final seen = <String>{};
    final merged = <Map<String, dynamic>>[];
    for (final row in [...viaRecipes, ...viaDirectSides]) {
      final mealId = row['meal_id'] as String;
      if (seen.add(mealId)) merged.add(row);
    }
    merged.sort((a, b) =>
        (b['cooked_at'] as String).compareTo(a['cooked_at'] as String));
    return merged;
  }

  Future<int> updateRecipeIngredient(RecipeIngredient recipeIngredient) async {
    final db = await _getDb();
    return await db.update(
      'recipe_ingredients',
      recipeIngredient.toMap(),
      where: 'id = ?',
      whereArgs: [recipeIngredient.id],
    );
  }

  Future<int> deleteRecipeIngredient(String id) async {
    final db = await _getDb();
    return await db.delete(
      'recipe_ingredients',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
