import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/recipe.dart';
import '../models/tag.dart';
import '../database/database_helper.dart';
import '../widgets/add_ingredient_dialog.dart';
import '../core/errors/gastrobrain_exceptions.dart';
import '../core/repositories/tag_repository.dart';
import '../core/services/snackbar_service.dart';
import '../l10n/app_localizations.dart';
import '../screens/meal_history_screen.dart';
import '../screens/edit_recipe_screen.dart';
import '../screens/recipe_details_overview_tab.dart';
import '../screens/recipe_details_ingredients_tab.dart';

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
  final int initialTabIndex;

  const RecipeDetailsScreen({
    super.key,
    required this.recipe,
    this.databaseHelper,
    this.initialTabIndex = 0,
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

  // Tags state
  List<Tag> _recipeTags = [];
  late TagRepository _tagRepo;

  // Instructions tab state
  late String _instructions;

  @override
  void initState() {
    super.initState();
    _dbHelper = widget.databaseHelper ?? DatabaseHelper();
    _tagRepo = TagRepository(_dbHelper);
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _currentRecipe = widget.recipe;
    _instructions = widget.recipe.instructions;
    _loadIngredients();
    _loadTags();

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

  Future<void> _loadTags() async {
    try {
      final tags = await _tagRepo.getTagsForRecipe(_currentRecipe.id);
      if (mounted) setState(() => _recipeTags = tags);
    } catch (_) {}
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
    bool isPreviewMode = false;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final l10n = AppLocalizations.of(dialogContext)!;
          return AlertDialog(
            title: Text(l10n.instructions),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(
                          value: false,
                          label: Text(l10n.instructionsEditLabel),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text(l10n.instructionsPreviewLabel),
                          icon: const Icon(Icons.visibility_outlined),
                        ),
                      ],
                      selected: {isPreviewMode},
                      onSelectionChanged: (v) =>
                          setDialogState(() => isPreviewMode = v.first),
                    ),
                    const SizedBox(height: 12),
                    if (isPreviewMode)
                      MarkdownBody(
                        data: controller.text.isEmpty
                            ? '_${l10n.enterInstructions}_'
                            : controller.text,
                        shrinkWrap: true,
                        styleSheet: MarkdownStyleSheet.fromTheme(
                          Theme.of(dialogContext),
                        ).copyWith(
                          p: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                      )
                    else
                      TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          hintText: l10n.enterInstructions,
                        ),
                        maxLines: null,
                        minLines: 8,
                        keyboardType: TextInputType.multiline,
                        autofocus: true,
                        onChanged: (_) => setDialogState(() {}),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(l10n.buttonCancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, controller.text),
                child: Text(l10n.save),
              ),
            ],
          );
        },
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
      final updatedRecipe = _currentRecipe.copyWith(
        instructions: newInstructions,
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

  Future<void> _editStory() async {
    final TextEditingController controller =
        TextEditingController(text: _currentRecipe.story);
    bool isPreviewMode = false;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final l10n = AppLocalizations.of(dialogContext)!;
          return AlertDialog(
            title: Text(l10n.recipeStory),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(
                          value: false,
                          label: Text(l10n.instructionsEditLabel),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text(l10n.instructionsPreviewLabel),
                          icon: const Icon(Icons.visibility_outlined),
                        ),
                      ],
                      selected: {isPreviewMode},
                      onSelectionChanged: (v) =>
                          setDialogState(() => isPreviewMode = v.first),
                    ),
                    const SizedBox(height: 12),
                    if (isPreviewMode)
                      MarkdownBody(
                        data: controller.text.isEmpty
                            ? '_${l10n.enterStory}_'
                            : controller.text,
                        shrinkWrap: true,
                        styleSheet: MarkdownStyleSheet.fromTheme(
                          Theme.of(dialogContext),
                        ).copyWith(
                          p: const TextStyle(fontSize: 16, height: 1.6),
                        ),
                      )
                    else
                      TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          hintText: l10n.enterStory,
                        ),
                        maxLines: null,
                        minLines: 8,
                        keyboardType: TextInputType.multiline,
                        autofocus: true,
                        onChanged: (_) => setDialogState(() {}),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(l10n.buttonCancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, controller.text),
                child: Text(l10n.save),
              ),
            ],
          );
        },
      ),
    );

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.dispose();
      });
    }

    if (result != null) {
      await _saveStory(result);
    }
  }

  Future<void> _saveStory(String newStory) async {
    try {
      final updatedRecipe = _currentRecipe.copyWith(story: newStory);
      await _dbHelper.updateRecipe(updatedRecipe);

      if (mounted) {
        setState(() {
          _currentRecipe = updatedRecipe;
          _hasChanges = true;
        });
        SnackbarService.showSuccess(
          context,
          AppLocalizations.of(context)!.storyUpdatedSuccessfully,
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
    return RecipeDetailsOverviewTab(recipe: _currentRecipe, tags: _recipeTags);
  }

  Widget _buildIngredientsTab() {
    return RecipeDetailsIngredientsTab(
      ingredients: _ingredients,
      servings: _currentRecipe.servings,
      isLoading: _isLoadingIngredients,
      error: _ingredientsError,
      onDeleteIngredient: _deleteIngredient,
      onEditIngredient: _editIngredient,
      onRetry: _loadIngredients,
      onAdd: _addIngredient,
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
          MarkdownBody(
            data: _instructions,
            shrinkWrap: true,
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
              p: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return MealHistoryScreen(recipe: _currentRecipe);
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
      case 2: // Overview tab — edit story
        final bool hasStory = _currentRecipe.story.isNotEmpty;
        return FloatingActionButton(
          onPressed: _editStory,
          tooltip: hasStory
              ? AppLocalizations.of(context)!.editStory
              : AppLocalizations.of(context)!.addStory,
          child: Icon(hasStory ? Icons.edit : Icons.add),
        );
      default:
        return null; // No FAB for History tab
    }
  }
}
