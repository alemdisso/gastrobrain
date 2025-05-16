import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/meal_recipe.dart';
import '../database/database_helper.dart';
import '../utils/id_generator.dart';
import '../widgets/meal_recording_dialog.dart';
import '../core/errors/gastrobrain_exceptions.dart';
import '../core/services/snackbar_service.dart';

class CookMealScreen extends StatefulWidget {
  final Recipe recipe;
  final List<Recipe>? additionalRecipes;

  const CookMealScreen({
    super.key,
    required this.recipe,
    this.additionalRecipes,
  });

  @override
  State<CookMealScreen> createState() => _CookMealScreenState();
}

class _CookMealScreenState extends State<CookMealScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isSaving = false;

  Future<void> _showMealRecordingDialog() async {
    Map<String, dynamic>? result;

    if (mounted) {
      result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => MealRecordingDialog(
          primaryRecipe: widget.recipe,
          additionalRecipes: widget.additionalRecipes,
        ),
      );
    }

    // If dialog was cancelled or widget unmounted
    if (result == null || !mounted) return;

    // Process and save the meal
    await _saveMeal(result);
  }

  Future<void> _saveMeal(Map<String, dynamic> mealData) async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Extract data from result
      final DateTime cookedAt = mealData['cookedAt'];
      final int servings = mealData['servings'];
      final String notes = mealData['notes'];
      final bool wasSuccessful = mealData['wasSuccessful'];
      final double actualPrepTime = mealData['actualPrepTime'];
      final double actualCookTime = mealData['actualCookTime'];
      final Recipe primaryRecipe = mealData['primaryRecipe'];
      final List<Recipe> additionalRecipes = mealData['additionalRecipes'];

      // Create the meal with a new ID
      final mealId = IdGenerator.generateId();

      // Begin a transaction to ensure all operations succeed or fail together
      await _dbHelper.database.then((db) async {
        return await db.transaction((txn) async {
          // Create meal object WITHOUT direct recipe_id (using null)
          final mealMap = {
            'id': mealId,
            'recipe_id': null, // Use junction table instead
            'cooked_at': cookedAt.toIso8601String(),
            'servings': servings,
            'notes': notes,
            'was_successful': wasSuccessful ? 1 : 0,
            'actual_prep_time': actualPrepTime,
            'actual_cook_time': actualCookTime,
          };

          // Insert the meal map
          await txn.insert('meals', mealMap);

          // Create and insert primary recipe association
          final primaryMealRecipe = MealRecipe(
            mealId: mealId,
            recipeId: primaryRecipe.id,
            isPrimaryDish: true,
            notes: 'Main dish',
          );

          // Insert the primary junction record
          await txn.insert('meal_recipes', primaryMealRecipe.toMap());

          // Insert all additional recipes as side dishes
          for (final recipe in additionalRecipes) {
            final sideDishMealRecipe = MealRecipe(
              mealId: mealId,
              recipeId: recipe.id,
              isPrimaryDish: false,
              notes: 'Side dish',
            );

            await txn.insert('meal_recipes', sideDishMealRecipe.toMap());
          }
        });
      });

      if (mounted) {
        SnackbarService.showSuccess(context, 'Meal recorded successfully');
        Navigator.pop(context, true);
      }
    } on ValidationException catch (e) {
      if (mounted) {
        SnackbarService.showError(context, e.message);
      }
    } on GastrobrainException catch (e) {
      if (mounted) {
        SnackbarService.showError(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.showError(context,
            'An unexpected error occurred while saving the meal: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cook ${widget.recipe.name}'),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Record cooking details for ${widget.recipe.name}',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _showMealRecordingDialog,
                      icon: const Icon(Icons.restaurant),
                      label: const Text('Record Meal Details'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
