import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/protein_type.dart';
import '../models/measurement_unit.dart';
import '../database/database_helper.dart';
import '../widgets/add_ingredient_dialog.dart';
import '../core/errors/gastrobrain_exceptions.dart';
import '../core/services/snackbar_service.dart';
import '../l10n/app_localizations.dart';
import '../utils/quantity_formatter.dart';
import '../screens/meal_history_screen.dart';
import '../screens/edit_recipe_screen.dart';

/// Unified screen for viewing complete recipe details including overview,
/// ingredients, instructions, and meal history.
///
/// This screen serves as the canonical recipe details view and can be
/// navigated to from:
/// - Recipe cards in recipes list
/// - Meal plan items
/// - Search results
/// - Anywhere else that needs to show recipe details
class RecipeDetailsScreen extends StatefulWidget {
  final Recipe recipe;
  final DatabaseHelper? databaseHelper;

  const RecipeDetailsScreen({
    super.key,
    required this.recipe,
    this.databaseHelper,
  });

  @override
  State<RecipeDetailsScreen> createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen>
    with SingleTickerProviderStateMixin {
  late DatabaseHelper _dbHelper;
  late TabController _tabController;
  late Recipe _currentRecipe;
  bool _hasChanges = false;

  // Ingredients tab state
  List<Map<String, dynamic>> _ingredients = [];
  bool _isLoadingIngredients = true;
  String? _ingredientsError;

  // Instructions tab state
  late String _instructions;

  @override
  void initState() {
    super.initState();
    _dbHelper = widget.databaseHelper ?? DatabaseHelper();
    _tabController = TabController(length: 4, vsync: this);
    _currentRecipe = widget.recipe;
    _instructions = widget.recipe.instructions;
    _loadIngredients();

    // Listen to tab changes to rebuild AppBar actions
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadIngredients() async {
    setState(() {
      _isLoadingIngredients = true;
      _ingredientsError = null;
    });

    try {
      final ingredients = await _dbHelper.getRecipeIngredients(_currentRecipe.id);
      if (mounted) {
        setState(() {
          _ingredients = ingredients;
          _isLoadingIngredients = false;
        });
      }
    } on NotFoundException catch (e) {
      if (mounted) {
        setState(() {
          _ingredientsError = e.message;
          _isLoadingIngredients = false;
        });
      }
    } on GastrobrainException catch (e) {
      if (mounted) {
        setState(() {
          _ingredientsError =
              '${AppLocalizations.of(context)!.errorLoadingIngredients} ${e.message}';
          _isLoadingIngredients = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _ingredientsError =
              AppLocalizations.of(context)!.unexpectedErrorLoadingIngredients;
          _isLoadingIngredients = false;
        });
      }
    }
  }

  Future<void> _addIngredient() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddIngredientDialog(recipe: _currentRecipe),
    );

    if (result == true) {
      _loadIngredients();
      setState(() {
        _hasChanges = true;
      });
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
          setState(() {
            _hasChanges = true;
          });
        }
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
        recipe: _currentRecipe,
        existingIngredient: ingredient,
        recipeIngredientId: ingredient['recipe_ingredient_id'],
      ),
    );

    if (result == true) {
      _loadIngredients();
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Future<void> _editInstructions() async {
    final TextEditingController controller =
        TextEditingController(text: _instructions);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.instructions),
        content: SingleChildScrollView(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.enterInstructions,
            ),
            maxLines: null,
            minLines: 10,
            keyboardType: TextInputType.multiline,
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.buttonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );

    // Dispose the controller after the dialog animation completes
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.dispose();
      });
    }

    if (result != null) {
      await _saveInstructions(result);
    }
  }

  Future<void> _saveInstructions(String newInstructions) async {
    try {
      final updatedRecipe = Recipe(
        id: _currentRecipe.id,
        name: _currentRecipe.name,
        desiredFrequency: _currentRecipe.desiredFrequency,
        notes: _currentRecipe.notes,
        instructions: newInstructions,
        createdAt: _currentRecipe.createdAt,
        difficulty: _currentRecipe.difficulty,
        prepTimeMinutes: _currentRecipe.prepTimeMinutes,
        cookTimeMinutes: _currentRecipe.cookTimeMinutes,
        rating: _currentRecipe.rating,
        category: _currentRecipe.category,
      );

      await _dbHelper.updateRecipe(updatedRecipe);

      if (mounted) {
        setState(() {
          _instructions = newInstructions;
          _currentRecipe = updatedRecipe;
          _hasChanges = true;
        });
        SnackbarService.showSuccess(
          context,
          AppLocalizations.of(context)!.instructionsUpdatedSuccessfully,
        );
      }
    } on GastrobrainException catch (e) {
      if (mounted) {
        SnackbarService.showError(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.showError(
          context,
          AppLocalizations.of(context)!.unexpectedError,
        );
      }
    }
  }

  Future<void> _editRecipe() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditRecipeScreen(recipe: _currentRecipe),
      ),
    );

    if (result == true && mounted) {
      // Recipe was edited, reload the recipe data
      try {
        final updatedRecipe = await _dbHelper.getRecipe(_currentRecipe.id);
        if (updatedRecipe != null && mounted) {
          setState(() {
            _currentRecipe = updatedRecipe;
            _instructions = updatedRecipe.instructions;
            _hasChanges = true;
          });
          // Reload ingredients in case they changed
          _loadIngredients();
        }
      } catch (e) {
        if (mounted) {
          SnackbarService.showError(
            context,
            AppLocalizations.of(context)!.errorLoadingData,
          );
        }
      }
    }
  }

  List<Widget> _buildAppBarActions() {
    final actions = <Widget>[];

    // Edit and Delete actions available via popup menu on all tabs
    actions.add(
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) {
          if (value == 'edit') {
            _editRecipe();
          } else if (value == 'delete') {
            _deleteRecipe();
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                const Icon(Icons.edit),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.editRecipe),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.deleteRecipe,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return actions;
  }

  Future<void> _deleteRecipe() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.deleteRecipe),
          content: Text(AppLocalizations.of(context)!.deleteConfirmation(_currentRecipe.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.cancel),
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
        await _dbHelper.deleteRecipe(_currentRecipe.id);
        if (mounted) {
          // Pop back with a special flag indicating deletion
          Navigator.pop(context, true);
          SnackbarService.showSuccess(
            context,
            AppLocalizations.of(context)!.recipeDeletedSuccessfully,
          );
        }
      } on GastrobrainException catch (e) {
        if (mounted) {
          SnackbarService.showError(context, e.message);
        }
      } catch (e) {
        if (mounted) {
          SnackbarService.showError(
            context,
            AppLocalizations.of(context)!.unexpectedError,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && _hasChanges) {
          // Changes were made, signal to parent to refresh
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_currentRecipe.name),
          leading: BackButton(
            onPressed: () {
              Navigator.pop(context, _hasChanges);
            },
          ),
          actions: _buildAppBarActions(),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                icon: const Icon(Icons.list_alt),
                text: AppLocalizations.of(context)!.ingredients,
              ),
              Tab(
                icon: const Icon(Icons.description),
                text: AppLocalizations.of(context)!.instructions,
              ),
              Tab(
                icon: const Icon(Icons.info_outline),
                text: AppLocalizations.of(context)!.overview,
              ),
              Tab(
                icon: const Icon(Icons.history),
                text: AppLocalizations.of(context)!.history,
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildIngredientsTab(),
            _buildInstructionsTab(),
            _buildOverviewTab(),
            _buildHistoryTab(),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category
          _buildInfoRow(
            icon: Icons.category,
            label: AppLocalizations.of(context)!.category,
            value: _currentRecipe.category.getLocalizedDisplayName(context),
          ),
          const SizedBox(height: 12),

          // Rating
          if (_currentRecipe.rating > 0)
            _buildInfoRow(
              icon: Icons.star,
              label: AppLocalizations.of(context)!.rating,
              value: '${_currentRecipe.rating}/5',
            ),
          if (_currentRecipe.rating > 0) const SizedBox(height: 12),

          // Difficulty
          _buildInfoRow(
            icon: Icons.signal_cellular_alt,
            label: AppLocalizations.of(context)!.difficulty,
            value: '${_currentRecipe.difficulty}/5',
          ),
          const SizedBox(height: 12),

          // Prep Time
          if (_currentRecipe.prepTimeMinutes > 0)
            _buildInfoRow(
              icon: Icons.kitchen,
              label: AppLocalizations.of(context)!.prepTimeLabel,
              value: '${_currentRecipe.prepTimeMinutes} ${AppLocalizations.of(context)!.minuteAbbreviation}',
            ),
          if (_currentRecipe.prepTimeMinutes > 0) const SizedBox(height: 12),

          // Cook Time
          if (_currentRecipe.cookTimeMinutes > 0)
            _buildInfoRow(
              icon: Icons.whatshot,
              label: AppLocalizations.of(context)!.cookTimeLabel,
              value: '${_currentRecipe.cookTimeMinutes} ${AppLocalizations.of(context)!.minuteAbbreviation}',
            ),
          if (_currentRecipe.cookTimeMinutes > 0) const SizedBox(height: 12),

          // Desired Frequency
          _buildInfoRow(
            icon: Icons.calendar_today,
            label: AppLocalizations.of(context)!.desiredFrequency,
            value: _currentRecipe.desiredFrequency.getLocalizedDisplayName(context),
          ),
          const SizedBox(height: 20),

          // Notes
          if (_currentRecipe.notes.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.notes,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _currentRecipe.notes,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildIngredientsTab() {
    if (_isLoadingIngredients) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_ingredientsError != null) {
      return _buildErrorView(_ingredientsError!);
    }

    if (_ingredients.isEmpty) {
      return _buildEmptyIngredientsView();
    }

    return ListView.builder(
      itemCount: _ingredients.length,
      itemBuilder: (context, index) {
        final ingredient = _ingredients[index];
        final proteinType = ingredient['protein_type'] != null
            ? ProteinType.values
                .firstWhere((e) => e.name == ingredient['protein_type'])
            : null;

        // Get the effective unit (override or default)
        final effectiveUnitString = ingredient['unit_override'] ??
            ingredient['unit'] ??
            '';

        // Convert to MeasurementUnit enum and get localized name
        final measurementUnit =
            MeasurementUnit.fromString(effectiveUnitString);
        final localizedUnit =
            measurementUnit?.getLocalizedDisplayName(context) ??
                effectiveUnitString;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: ListTile(
            leading: Icon(
              proteinType != null ? Icons.egg_alt : Icons.food_bank,
              color: proteinType?.isMainProtein == true ? Colors.red : null,
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
                                .unitOverridden(MeasurementUnit.fromString(
                                            ingredient['unit'])
                                        ?.getLocalizedDisplayName(context) ??
                                    ingredient['unit'] ??
                                    AppLocalizations.of(context)!.noUnit),
                          ),
                        ),
                    ],
                  ),
                if (ingredient['preparation_notes'] != null)
                  Text(
                    ingredient['preparation_notes'],
                    style: Theme.of(context).textTheme.bodySmall,
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
                      Text(AppLocalizations.of(context)!.delete),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInstructionsTab() {
    final bool hasInstructions = _instructions.isNotEmpty;

    if (!hasInstructions) {
      return _buildEmptyInstructionsView();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.instructions,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _instructions,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return MealHistoryScreen(recipe: _currentRecipe);
  }

  Widget _buildErrorView(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            errorMessage,
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

  Widget _buildEmptyIngredientsView() {
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

  Widget _buildEmptyInstructionsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noInstructionsAvailable,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _editInstructions,
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context)!.addInstructions),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    // Show appropriate FAB based on current tab
    switch (_tabController.index) {
      case 0: // Ingredients tab
        return FloatingActionButton(
          onPressed: _addIngredient,
          tooltip: AppLocalizations.of(context)!.addIngredient,
          child: const Icon(Icons.add),
        );
      case 1: // Instructions tab
        final bool hasInstructions = _instructions.isNotEmpty;
        return FloatingActionButton(
          onPressed: _editInstructions,
          tooltip: hasInstructions
              ? AppLocalizations.of(context)!.editInstructions
              : AppLocalizations.of(context)!.addInstructions,
          child: Icon(hasInstructions ? Icons.edit : Icons.add),
        );
      default:
        return null; // No FAB for Overview and History tabs
    }
  }
}
