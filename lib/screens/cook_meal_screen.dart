import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../models/meal_recipe.dart';
import '../models/meal.dart';
import '../utils/id_generator.dart';
import '../widgets/meal_recording_dialog.dart';
import '../core/errors/gastrobrain_exceptions.dart';
import '../core/services/snackbar_service.dart';
import '../core/providers/recipe_provider.dart';
import '../core/providers/meal_provider.dart';
import '../l10n/app_localizations.dart';

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

      // Create the meal object
      final meal = Meal(
        id: mealId,
        recipeId: null, // Use junction table instead
        cookedAt: cookedAt,
        servings: servings,
        notes: notes,
        wasSuccessful: wasSuccessful,
        actualPrepTime: actualPrepTime,
        actualCookTime: actualCookTime,
        modifiedAt: DateTime.now(),
      );

      // Get providers
      final mealProvider = context.read<MealProvider>();
      final recipeProvider = context.read<RecipeProvider>();

      // Record the meal using the provider
      final success = await mealProvider.recordMeal(meal);
      if (!success) {
        throw const GastrobrainException('Failed to record meal');
      }

      // Create and add primary recipe association
      final primaryMealRecipe = MealRecipe(
        mealId: mealId,
        recipeId: primaryRecipe.id,
        isPrimaryDish: true,
        notes: AppLocalizations.of(context)!.mainDish,
      );
      await mealProvider.addMealRecipe(primaryMealRecipe);

      // Add all additional recipes as side dishes
      for (final recipe in additionalRecipes) {
        final sideDishMealRecipe = MealRecipe(
          mealId: mealId,
          recipeId: recipe.id,
          isPrimaryDish: false,
          notes: AppLocalizations.of(context)!.sideDish,
        );
        await mealProvider.addMealRecipe(sideDishMealRecipe);
      }

      // Refresh meal statistics in the RecipeProvider to reflect the new meal
      await recipeProvider.refreshMealStats();

      if (mounted) {
        SnackbarService.showSuccess(context, AppLocalizations.of(context)!.mealRecordedSuccessfully);
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
            AppLocalizations.of(context)!.unexpectedErrorSavingMeal(e.toString()));
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
        title: Text(AppLocalizations.of(context)!.cookRecipeTitle(widget.recipe.name)),
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
                      AppLocalizations.of(context)!.recordCookingDetails(widget.recipe.name),
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _showMealRecordingDialog,
                      icon: const Icon(Icons.restaurant),
                      label: Text(AppLocalizations.of(context)!.recordMealDetails),
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
