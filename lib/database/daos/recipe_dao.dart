// lib/database/daos/recipe_dao.dart

import 'package:sqflite/sqflite.dart';
import '../../models/recipe.dart';

class RecipeDao {
  final Future<Database> Function() _getDb;

  RecipeDao(this._getDb);

  static const _frequencyOrder = [
    'daily', 'weekly', 'biweekly', 'monthly', 'bimonthly', 'rarely'
  ];

  Future<int> insertRecipe(Recipe recipe) async {
    final db = await _getDb();
    return await db.insert('recipes', recipe.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Recipe>> getAllRecipes() async {
    final db = await _getDb();
    final List<Map<String, dynamic>> maps = await db.query('recipes');
    return List.generate(maps.length, (i) => Recipe.fromMap(maps[i]));
  }

  Future<Recipe?> getRecipe(String id) async {
    final db = await _getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Recipe.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateRecipe(Recipe recipe) async {
    final db = await _getDb();
    return await db.update(
      'recipes',
      recipe.toMap(),
      where: 'id = ?',
      whereArgs: [recipe.id],
    );
  }

  Future<int> deleteRecipe(String id) async {
    final db = await _getDb();
    return await db.delete(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getRecipesCount() async {
    final db = await _getDb();
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM recipes');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getEnrichedRecipeCount() async {
    final db = await _getDb();
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM (
        SELECT r.id
        FROM recipes r
        INNER JOIN recipe_ingredients ri ON r.id = ri.recipe_id
        GROUP BY r.id
        HAVING COUNT(ri.ingredient_id) >= 3
      )
    ''');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Map<String, int>> getRecipeEnrichmentStats() async {
    final totalRecipes = await getRecipesCount();
    final enrichedRecipes = await getEnrichedRecipeCount();
    final incompleteRecipes = totalRecipes - enrichedRecipes;
    return {
      'total': totalRecipes,
      'enriched': enrichedRecipes,
      'incomplete': incompleteRecipes,
    };
  }

  Future<List<Recipe>> getRecipesWithSortAndFilter({
    String? sortBy,
    String? sortOrder,
    Map<String, dynamic>? filters,
  }) async {
    final db = await _getDb();

    String query = 'SELECT * FROM recipes';
    List<dynamic> arguments = [];

    if (filters != null && filters.isNotEmpty) {
      List<String> whereConditions = [];

      if (filters.containsKey('difficulty')) {
        whereConditions.add('difficulty <= ?');
        arguments.add(filters['difficulty']);
      }

      if (filters.containsKey('rating')) {
        whereConditions.add('rating >= ?');
        arguments.add(filters['rating']);
      }

      if (filters.containsKey('desired_frequency')) {
        final freq = filters['desired_frequency'] as String;
        final idx = _frequencyOrder.indexOf(freq);
        final validFreqs = idx == -1 ? [freq] : _frequencyOrder.sublist(0, idx + 1);
        final placeholders = List.filled(validFreqs.length, '?').join(', ');
        whereConditions.add('desired_frequency IN ($placeholders)');
        arguments.addAll(validFreqs);
      }

      if (filters.containsKey('tag_filters')) {
        final tagFilters = filters['tag_filters'] as List<Map<String, String>>;

        final Map<String, List<String>> namesByType = {};
        final Map<String, bool> isHardByType = {};
        for (final tf in tagFilters) {
          final typeId = tf['type_id']!;
          namesByType.putIfAbsent(typeId, () => []).add(tf['name']!);
          isHardByType[typeId] = tf['is_hard'] == 'true';
        }

        for (final entry in namesByType.entries) {
          final typeId = entry.key;
          final names = entry.value;
          final isHard = isHardByType[typeId] ?? false;

          if (isHard) {
            for (final name in names) {
              whereConditions.add(
                'EXISTS (SELECT 1 FROM recipe_tags rt '
                'JOIN tags t ON t.id = rt.tag_id '
                'WHERE rt.recipe_id = recipes.id '
                'AND t.type_id = ? AND t.name = ?)',
              );
              arguments.addAll([typeId, name]);
            }
          } else {
            final placeholders = List.filled(names.length, '?').join(', ');
            whereConditions.add(
              'EXISTS (SELECT 1 FROM recipe_tags rt '
              'JOIN tags t ON t.id = rt.tag_id '
              'WHERE rt.recipe_id = recipes.id '
              'AND t.type_id = ? AND t.name IN ($placeholders))',
            );
            arguments.add(typeId);
            arguments.addAll(names);
          }
        }
      }

      if (whereConditions.isNotEmpty) {
        query += ' WHERE ${whereConditions.join(' AND ')}';
      }
    }

    if (sortBy != null) {
      if (sortBy == 'name') {
        query += ' ORDER BY name COLLATE NOCASE';
      } else {
        query += ' ORDER BY $sortBy';
      }
      if (sortOrder != null) {
        query += ' $sortOrder';
      }
    } else {
      query += ' ORDER BY created_at DESC';
    }

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, arguments);
    return List.generate(maps.length, (i) => Recipe.fromMap(maps[i]));
  }
}
