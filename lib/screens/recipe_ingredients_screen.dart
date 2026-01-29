import 'package:flutter/material.dart';
import '../models/recipe.dart';
//import '../models/ingredient.dart';
//import '../models/recipe_ingredient.dart';
import '../models/protein_type.dart';
import '../models/measurement_unit.dart';
import '../database/database_helper.dart';
import '../widgets/add_ingredient_dialog.dart';
import '../core/errors/gastrobrain_exceptions.dart';
import '../core/services/snackbar_service.dart';
import '../l10n/app_localizations.dart';
import '../utils/quantity_formatter.dart';

class RecipeIngredientsScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeIngredientsScreen({super.key, required this.recipe});

  @override
  State<RecipeIngredientsScreen> createState() =>
      _RecipeIngredientsScreenState();
}

class _RecipeIngredientsScreenState extends State<RecipeIngredientsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _ingredients = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ingredients =
          await _dbHelper.getRecipeIngredients(widget.recipe.id);
      if (mounted) {
        setState(() {
          _ingredients = ingredients;
          _isLoading = false;
        });
      }
    } on NotFoundException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } on GastrobrainException catch (e) {
      setState(() {
        _errorMessage =
            '${AppLocalizations.of(context)!.errorLoadingIngredients} ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            AppLocalizations.of(context)!.unexpectedErrorLoadingIngredients;
        _isLoading = false;
      });
    }
  }

  void _addIngredient() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddIngredientDialog(recipe: widget.recipe),
    );

    if (result == true) {
      _loadIngredients();
    }
  }

  Future<void> _deleteIngredient(Map<String, dynamic> ingredient) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.deleteIngredient),
          content: Text(AppLocalizations.of(context)!
              .deleteIngredientConfirmation(ingredient['name'])),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.buttonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(AppLocalizations.of(context)!.delete),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _dbHelper
            .deleteRecipeIngredient(ingredient['recipe_ingredient_id']);
        if (mounted) {
          SnackbarService.showSuccess(context,
              AppLocalizations.of(context)!.ingredientDeletedSuccessfully);
          _loadIngredients();
        }
        _loadIngredients(); // Reload the ingredients list
      } on GastrobrainException catch (e) {
        if (mounted) {
          SnackbarService.showError(context, e.message);
        }
      } catch (e) {
        if (mounted) {
          SnackbarService.showError(context,
              AppLocalizations.of(context)!.unexpectedErrorDeletingIngredient);
        }
      }
    }
  }

  Future<void> _editIngredient(Map<String, dynamic> ingredient) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddIngredientDialog(
        recipe: widget.recipe,
        existingIngredient: ingredient, // We'll need to add this parameter
        recipeIngredientId: ingredient['recipe_ingredient_id'], // And this one
      ),
    );

    if (result == true) {
      _loadIngredients();
    }
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'An error occurred',
            style: const TextStyle(fontSize: 18, color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadIngredients,
            icon: const Icon(Icons.refresh),
            label: Text(AppLocalizations.of(context)!.tryAgain),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.no_food, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noIngredientsAddedYet,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _addIngredient,
            icon: const Icon(Icons.add),
            label: Text(AppLocalizations.of(context)!.addIngredient),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            AppLocalizations.of(context)!.ingredientsTitle(widget.recipe.name)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadIngredients,
            tooltip: AppLocalizations.of(context)!.refresh,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _ingredients.isEmpty
                  ? _buildEmptyView()
                  : ListView.builder(
                      itemCount: _ingredients.length,
                      itemBuilder: (context, index) {
                        final ingredient = _ingredients[index];
                        final proteinType = ingredient['protein_type'] != null
                            ? ProteinType.values.firstWhere(
                                (e) => e.name == ingredient['protein_type'])
                            : null;

                        // Get the effective unit (override or default)
                        final effectiveUnitString =
                            ingredient['unit_override'] ??
                                ingredient['unit'] ??
                                '';

                        // Convert to MeasurementUnit enum and get localized name
                        final measurementUnit =
                            MeasurementUnit.fromString(effectiveUnitString);
                        final localizedUnit =
                            measurementUnit?.getLocalizedDisplayName(context) ??
                                effectiveUnitString;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: ListTile(
                            leading: Icon(
                              proteinType != null
                                  ? Icons.egg_alt
                                  : Icons.food_bank,
                              color: proteinType?.isMainProtein == true
                                  ? Colors.red
                                  : null,
                            ),
                            title: Text(ingredient['name']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Hide quantity/unit for zero quantities ("to taste" ingredients)
                                if (ingredient['quantity'] != 0)
                                  Row(
                                    children: [
                                      Text(
                                        '${QuantityFormatter.format(ingredient['quantity'])} $localizedUnit',
                                      ),
                                      if (ingredient['unit_override'] != null)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 4),
                                          child: Tooltip(
                                            message: AppLocalizations.of(context)!
                                                .unitOverridden(MeasurementUnit
                                                            .fromString(
                                                                ingredient[
                                                                    'unit'])
                                                        ?.getLocalizedDisplayName(
                                                            context) ??
                                                    ingredient['unit'] ??
                                                    AppLocalizations.of(context)!
                                                        .noUnit),
                                          ),
                                        ),
                                    ],
                                  ),
                                if (ingredient['preparation_notes'] != null)
                                  Text(
                                    ingredient['preparation_notes'],
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                switch (value) {
                                  case 'delete':
                                    _deleteIngredient(ingredient);
                                    break;
                                  case 'edit':
                                    _editIngredient(ingredient);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.edit),
                                      const SizedBox(width: 8),
                                      Text(AppLocalizations.of(context)!.edit),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.delete),
                                      const SizedBox(width: 8),
                                      Text(
                                          AppLocalizations.of(context)!.delete),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addIngredient,
        tooltip: AppLocalizations.of(context)!.addIngredient,
        child: const Icon(Icons.add),
      ),
    );
  }
}
