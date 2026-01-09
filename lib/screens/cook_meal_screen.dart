import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../models/meal.dart';
import '../models/meal_type.dart';
import '../utils/id_generator.dart';
import '../widgets/meal_recording_dialog.dart';
import '../widgets/meal_type_dialog.dart';
import '../core/errors/gastrobrain_exceptions.dart';
import '../core/services/snackbar_service.dart';
import '../core/di/service_provider.dart';
import '../core/services/meal_edit_service.dart';
import '../core/providers/recipe_provider.dart';
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

    // Show meal type selector dialog
    MealType? mealType;
    if (mounted) {
      mealType = await showDialog<MealType>(
        context: context,
        builder: (context) => const MealTypeDialog(),
      );
    }

    // Add meal type to result (can be null if skipped)
    result['mealType'] = mealType;

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
      final MealType? mealType = mealData['mealType'];

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
        mealType: mealType,
      );

      // Record meal with recipes using service
      // Create service instance to use consistent database helper
      final mealEditService = MealEditService(ServiceProvider.database.helper);
      await mealEditService.recordMealWithRecipes(
        meal: meal,
        primaryRecipe: primaryRecipe,
        additionalRecipes: additionalRecipes,
      );

      // Refresh meal statistics in the RecipeProvider to reflect the new meal
      final recipeProvider = context.read<RecipeProvider>();
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
