import 'dart:convert';
import 'dart:io';
import '../../database/database_helper.dart';
import '../errors/gastrobrain_exceptions.dart';

/// Service for complete database backup and restore using JSON format
///
/// Creates a single JSON file containing ALL application data:
/// - Recipes (with ingredients, metadata, cooking history)
/// - Ingredients
/// - Meal Plans
/// - Meals (cooked meal records)
///
/// This is a COMPLETE backup/restore (no merge logic).
/// Restore operation replaces ALL existing data.
class DatabaseBackupService {
  final DatabaseHelper _databaseHelper;

  DatabaseBackupService(this._databaseHelper);

  /// Creates a complete backup of all database data to JSON
  ///
  /// Saves to Downloads folder with timestamp:
  /// gastrobrain_backup_YYYY-MM-DD_HHMMSS.json
  ///
  /// Returns the path to the created backup file.
  Future<String> backupDatabase() async {
    try {
      final backupData = <String, dynamic>{
        'version': '1.0',
        'backup_date': DateTime.now().toIso8601String(),
      };

      // Export recipes with full data
      backupData['recipes'] = await _exportRecipes();

      // Export ingredients
      backupData['ingredients'] = await _exportIngredients();

      // Export meal plans
      backupData['meal_plans'] = await _exportMealPlans();

      // Export meals (cooked meal records)
      backupData['meals'] = await _exportMeals();

      // Generate JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      // Write to file in Downloads
      final filePath = await _writeBackupToFile(jsonString);

      return filePath;
    } catch (e) {
      throw GastrobrainException('Failed to create backup: ${e.toString()}');
    }
  }

  /// Exports all recipes with their recipe_ingredients junction table data
  Future<List<Map<String, dynamic>>> _exportRecipes() async {
    final recipes = await _databaseHelper.getAllRecipes();
    final exportData = <Map<String, dynamic>>[];
    final db = await _databaseHelper.database;

    for (final recipe in recipes) {
      // Query recipe_ingredients table directly to get actual table data
      final recipeIngredients = await db.query(
        'recipe_ingredients',
        where: 'recipe_id = ?',
        whereArgs: [recipe.id],
      );

      exportData.add({
        'id': recipe.id,
        'name': recipe.name,
        'difficulty': recipe.difficulty,
        'prep_time_minutes': recipe.prepTimeMinutes,
        'cook_time_minutes': recipe.cookTimeMinutes,
        'rating': recipe.rating,
        'category': recipe.category.value,
        'desired_frequency': recipe.desiredFrequency.value,
        'notes': recipe.notes,
        'instructions': recipe.instructions,
        'created_at': recipe.createdAt.toIso8601String(),
        'recipe_ingredients': recipeIngredients
            .map((ri) => {
                  'id': ri['id'],
                  'recipe_id': ri['recipe_id'],
                  'ingredient_id': ri['ingredient_id'],
                  'quantity': ri['quantity'],
                  'notes': ri['notes'],
                  'unit_override': ri['unit_override'],
                  'custom_name': ri['custom_name'],
                  'custom_category': ri['custom_category'],
                  'custom_unit': ri['custom_unit'],
                })
            .toList(),
      });
    }

    return exportData;
  }

  /// Exports all ingredients
  Future<List<Map<String, dynamic>>> _exportIngredients() async {
    final ingredients = await _databaseHelper.getAllIngredients();

    return ingredients
        .map((ingredient) => {
              'id': ingredient.id,
              'name': ingredient.name,
              'category': ingredient.category.value,
              'unit': ingredient.unit?.value,
              'protein_type': ingredient.proteinType?.name,
              'notes': ingredient.notes,
            })
        .toList();
  }

  /// Exports all meal plans with their items and recipes
  Future<List<Map<String, dynamic>>> _exportMealPlans() async {
    final mealPlans = await _databaseHelper.getAllMealPlans();
    final exportData = <Map<String, dynamic>>[];

    for (final plan in mealPlans) {
      // Get items for this meal plan
      final items = await _databaseHelper.getMealPlanItems(plan.id);

      exportData.add({
        'id': plan.id,
        'week_start_date': plan.weekStartDate.toIso8601String(),
        'notes': plan.notes,
        'created_at': plan.createdAt.toIso8601String(),
        'modified_at': plan.modifiedAt.toIso8601String(),
        'items': items
            .map((item) => {
                  'id': item.id,
                  'meal_plan_id': item.mealPlanId,
                  'planned_date': item.plannedDate,
                  'meal_type': item.mealType,
                  'notes': item.notes,
                  'has_been_cooked': item.hasBeenCooked,
                  'recipes': (item.mealPlanItemRecipes ?? [])
                      .map((recipe) => {
                            'id': recipe.id,
                            'meal_plan_item_id': recipe.mealPlanItemId,
                            'recipe_id': recipe.recipeId,
                            'is_primary_dish': recipe.isPrimaryDish,
                            'notes': recipe.notes,
                          })
                      .toList(),
                })
            .toList(),
      });
    }

    return exportData;
  }

  /// Exports all cooked meals with their recipes
  Future<List<Map<String, dynamic>>> _exportMeals() async {
    final meals = await _databaseHelper.getAllMeals();
    final exportData = <Map<String, dynamic>>[];

    for (final meal in meals) {
      exportData.add({
        'id': meal.id,
        'recipe_id': meal.recipeId,
        'cooked_at': meal.cookedAt.toIso8601String(),
        'servings': meal.servings,
        'notes': meal.notes,
        'was_successful': meal.wasSuccessful,
        'actual_prep_time': meal.actualPrepTime,
        'actual_cook_time': meal.actualCookTime,
        'modified_at': meal.modifiedAt?.toIso8601String(),
        'meal_recipes': (meal.mealRecipes ?? [])
            .map((recipe) => {
                  'id': recipe.id,
                  'meal_id': recipe.mealId,
                  'recipe_id': recipe.recipeId,
                  'is_primary_dish': recipe.isPrimaryDish,
                  'notes': recipe.notes,
                })
            .toList(),
      });
    }

    return exportData;
  }

  /// Writes backup JSON to Downloads folder
  Future<String> _writeBackupToFile(String jsonString) async {
    try {
      // Generate filename with timestamp
      final timestamp = DateTime.now();
      final formattedDate =
          '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
      final formattedTime =
          '${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}${timestamp.second.toString().padLeft(2, '0')}';
      final fileName = 'gastrobrain_backup_${formattedDate}_$formattedTime.json';

      // Save to Downloads directory
      final file = File('/sdcard/Download/$fileName');

      // Create Downloads directory if it doesn't exist
      await file.parent.create(recursive: true);

      // Write JSON to file
      await file.writeAsString(jsonString);

      return file.path;
    } catch (e) {
      throw GastrobrainException(
          'Failed to write backup file: ${e.toString()}');
    }
  }

  /// Restores database from a backup JSON file
  ///
  /// IMPORTANT: This operation replaces ALL existing data.
  /// Make sure to show a warning dialog before calling this.
  ///
  /// [backupFilePath] Path to the JSON backup file to restore from
  Future<void> restoreDatabase(String backupFilePath) async {
    try {
      // Read and parse JSON file
      final file = File(backupFilePath);
      if (!await file.exists()) {
        throw GastrobrainException('Backup file not found: $backupFilePath');
      }

      final jsonString = await file.readAsString();
      final Map<String, dynamic> backupData = json.decode(jsonString);

      // Validate backup format
      if (backupData['version'] == null) {
        throw const GastrobrainException('Invalid backup file: missing version');
      }

      // Get database instance and perform restore in a transaction
      final db = await _databaseHelper.database;

      await db.transaction((txn) async {
        // Step 1: Delete all existing data (in reverse dependency order)
        await txn.delete('meal_recipes');
        await txn.delete('meals');
        await txn.delete('meal_plan_item_recipes');
        await txn.delete('meal_plan_items');
        await txn.delete('meal_plans');
        await txn.delete('recipe_ingredients');
        await txn.delete('recipes');
        await txn.delete('ingredients');

        // Step 2: Import ingredients
        if (backupData['ingredients'] != null) {
          final ingredients = backupData['ingredients'] as List;
          for (final ing in ingredients) {
            await txn.insert('ingredients', {
              'id': ing['id'],
              'name': ing['name'],
              'category': ing['category'],
              'unit': ing['unit'],
              'protein_type': ing['protein_type'],
              'notes': ing['notes'],
            });
          }
        }

        // Step 3: Import recipes with ingredients
        if (backupData['recipes'] != null) {
          final recipes = backupData['recipes'] as List;
          for (final recipe in recipes) {
            // Insert recipe
            await txn.insert('recipes', {
              'id': recipe['id'],
              'name': recipe['name'],
              'difficulty': recipe['difficulty'],
              'prep_time_minutes': recipe['prep_time_minutes'],
              'cook_time_minutes': recipe['cook_time_minutes'],
              'rating': recipe['rating'],
              'category': recipe['category'],
              'desired_frequency': recipe['desired_frequency'],
              'notes': recipe['notes'],
              'instructions': recipe['instructions'],
              'created_at': recipe['created_at'],
            });

            // Insert recipe ingredients
            if (recipe['recipe_ingredients'] != null) {
              final recipeIngredients = recipe['recipe_ingredients'] as List;
              for (final ri in recipeIngredients) {
                await txn.insert('recipe_ingredients', {
                  'id': ri['id'],
                  'recipe_id': ri['recipe_id'],
                  'ingredient_id': ri['ingredient_id'],
                  'quantity': ri['quantity'],
                  'notes': ri['notes'],
                  'unit_override': ri['unit_override'],
                  'custom_name': ri['custom_name'],
                  'custom_category': ri['custom_category'],
                  'custom_unit': ri['custom_unit'],
                });
              }
            }
          }
        }

        // Step 4: Import meal plans with items
        if (backupData['meal_plans'] != null) {
          final mealPlans = backupData['meal_plans'] as List;
          for (final plan in mealPlans) {
            // Insert meal plan
            await txn.insert('meal_plans', {
              'id': plan['id'],
              'week_start_date': plan['week_start_date'],
              'notes': plan['notes'],
              'created_at': plan['created_at'],
              'modified_at': plan['modified_at'],
            });

            // Insert meal plan items
            if (plan['items'] != null) {
              final items = plan['items'] as List;
              for (final item in items) {
                await txn.insert('meal_plan_items', {
                  'id': item['id'],
                  'meal_plan_id': item['meal_plan_id'],
                  'planned_date': item['planned_date'],
                  'meal_type': item['meal_type'],
                  'notes': item['notes'] ?? '',
                  'has_been_cooked': item['has_been_cooked'] ? 1 : 0,
                });

                // Insert meal plan item recipes
                if (item['recipes'] != null) {
                  final recipes = item['recipes'] as List;
                  for (final recipe in recipes) {
                    await txn.insert('meal_plan_item_recipes', {
                      'id': recipe['id'],
                      'meal_plan_item_id': recipe['meal_plan_item_id'],
                      'recipe_id': recipe['recipe_id'],
                      'is_primary_dish': recipe['is_primary_dish'] ? 1 : 0,
                      'notes': recipe['notes'],
                    });
                  }
                }
              }
            }
          }
        }

        // Step 5: Import meals with recipes
        if (backupData['meals'] != null) {
          final meals = backupData['meals'] as List;
          for (final meal in meals) {
            // Insert meal
            await txn.insert('meals', {
              'id': meal['id'],
              'recipe_id': meal['recipe_id'],
              'cooked_at': meal['cooked_at'],
              'servings': meal['servings'],
              'notes': meal['notes'],
              'was_successful': meal['was_successful'] ? 1 : 0,
              'actual_prep_time': meal['actual_prep_time'],
              'actual_cook_time': meal['actual_cook_time'],
              'modified_at': meal['modified_at'],
            });

            // Insert meal recipes
            if (meal['meal_recipes'] != null) {
              final mealRecipes = meal['meal_recipes'] as List;
              for (final recipe in mealRecipes) {
                await txn.insert('meal_recipes', {
                  'id': recipe['id'],
                  'meal_id': recipe['meal_id'],
                  'recipe_id': recipe['recipe_id'],
                  'is_primary_dish': recipe['is_primary_dish'] ? 1 : 0,
                  'notes': recipe['notes'],
                });
              }
            }
          }
        }
      });
    } catch (e) {
      throw GastrobrainException(
          'Failed to restore backup: ${e.toString()}');
    }
  }
}
