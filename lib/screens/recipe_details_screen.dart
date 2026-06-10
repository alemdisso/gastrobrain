import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:uuid/uuid.dart';
import '../core/di/service_provider.dart';
import '../core/errors/gastrobrain_exceptions.dart';
import '../core/repositories/tag_repository.dart';
import '../core/services/ingredient_matching_service.dart';
import '../core/services/snackbar_service.dart';
import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../models/recipe_ingredient.dart';
import '../models/tag.dart';
import '../screens/meal_history_screen.dart';
import '../screens/recipe_details_ingredients_tab.dart';
import '../screens/recipe_details_overview_tab.dart';
import '../utils/dialog_utils.dart';
import '../utils/id_generator.dart';
import '../widgets/add_ingredient_dialog.dart';
import '../widgets/add_new_ingredient_dialog.dart';
import '../widgets/ingredient_parser/ingredient_parser_section.dart';
import '../widgets/recipe_editor/instructions_edit_sheet.dart';
import '../widgets/recipe_editor/parsed_ingredient.dart';
import '../widgets/recipe_editor/recipe_info_edit_sheet.dart';
import '../widgets/recipe_editor/tags_edit_sheet.dart';

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

  // Ingredient parser state
  final IngredientMatchingService _matchingService = IngredientMatchingService();
  bool _isMatchingServiceReady = false;
  bool _isParserServiceReady = false;

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
    _loadAllIngredients();
    _loadTags();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isParserServiceReady && _isMatchingServiceReady && mounted) {
      final l10n = AppLocalizations.of(context);
      if (l10n != null) {
        ServiceProvider.ingredientParser
            .initialize(l10n, matchingService: _matchingService);
        setState(() => _isParserServiceReady = true);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllIngredients() async {
    try {
      final ingredients = await _dbHelper.getAllIngredients();
      _matchingService.initialize(ingredients);
      if (mounted) {
        setState(() => _isMatchingServiceReady = true);
        final l10n = AppLocalizations.of(context);
        if (l10n != null && !_isParserServiceReady) {
          ServiceProvider.ingredientParser
              .initialize(l10n, matchingService: _matchingService);
          setState(() => _isParserServiceReady = true);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isMatchingServiceReady = false);
    }
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

  void _addIngredients() {
    final l10n = AppLocalizations.of(context)!;
    showGastrobrainBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom +
              MediaQuery.of(sheetContext).padding.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(sheetContext).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.addIngredients,
                style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              IngredientParserSection(
                matchingService: _matchingService,
                isServicesReady: _isParserServiceReady,
                onIngredientsConfirmed: (list) async {
                  final ok = await _saveIngredientsFromParser(list);
                  if (ok) {
                    Navigator.pop(sheetContext);
                    if (mounted) {
                      _loadIngredients();
                      setState(() => _hasChanges = true);
                    }
                  }
                  return ok;
                },
                onCreateNew: _showCreateIngredientDialogForParser,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _saveIngredientsFromParser(
      List<ParsedIngredient> confirmed) async {
    try {
      const uuid = Uuid();
      final existing =
          await _dbHelper.getRecipeIngredients(_currentRecipe.id);
      final existingById = <String, Map<String, dynamic>>{
        for (final e in existing)
          if (e['ingredient_id'] != null) e['ingredient_id'] as String: e,
      };

      for (final parsed in confirmed) {
        if (parsed.name.trim().isEmpty) continue;
        if (parsed.isNewIngredient) {
          await _dbHelper.insertIngredient(parsed.newIngredientToCreate!);
        }
        final ingredientId = parsed.selectedMatch?.ingredient.id ??
            parsed.newIngredientToCreate?.id;
        if (ingredientId == null) continue;

        if (existingById.containsKey(ingredientId)) {
          final ri = RecipeIngredient(
            id: existingById[ingredientId]!['recipe_ingredient_id'] as String,
            recipeId: _currentRecipe.id,
            ingredientId: ingredientId,
            quantity: parsed.quantity,
            quantityMax: parsed.quantityMax,
            notes: parsed.notes,
            unitOverride: parsed.unit,
          );
          await _dbHelper.updateRecipeIngredient(ri);
        } else {
          await _dbHelper.addIngredientToRecipe(RecipeIngredient(
            id: uuid.v4(),
            recipeId: _currentRecipe.id,
            ingredientId: ingredientId,
            quantity: parsed.quantity,
            quantityMax: parsed.quantityMax,
            notes: parsed.notes,
            unitOverride: parsed.unit,
          ));
        }
      }
      return true;
    } catch (e) {
      if (mounted) {
        SnackbarService.showError(
            context, AppLocalizations.of(context)!.unexpectedError);
      }
      return false;
    }
  }

  Future<Ingredient?> _showCreateIngredientDialogForParser(
      ParsedIngredient parsed) async {
    final prefilled = Ingredient(
      id: IdGenerator.generateId(),
      name: parsed.originalName.isNotEmpty ? parsed.originalName : parsed.name,
      category: parsed.category,
      unit: null,
      notes: parsed.notes,
    );
    return showDialog<Ingredient>(
      context: context,
      builder: (_) => AddNewIngredientDialog(ingredient: prefilled),
    );
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
    final result = await showGastrobrainBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => InstructionsEditSheet(
        initialInstructions: _instructions,
      ),
    );
    if (result != null) await _saveInstructions(result);
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

  Future<void> _editRecipeInfo() async {
    final updated = await showGastrobrainBottomSheet<Recipe>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => RecipeInfoEditSheet(recipe: _currentRecipe),
    );
    if (updated == null || !mounted) return;

    try {
      await _dbHelper.updateRecipe(updated);
      if (mounted) {
        setState(() {
          _currentRecipe = updated;
          _hasChanges = true;
        });
        SnackbarService.showSuccess(
          context,
          AppLocalizations.of(context)!.recipeSavedSuccessfully,
        );
      }
    } on GastrobrainException catch (e) {
      if (mounted) SnackbarService.showError(context, e.message);
    } catch (_) {
      if (mounted) {
        SnackbarService.showError(
            context, AppLocalizations.of(context)!.unexpectedError);
      }
    }
  }

  Future<void> _editTags() async {
    final selectedIds = await showGastrobrainBottomSheet<List<String>>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => TagsEditSheet(
        recipeId: _currentRecipe.id,
        tagRepository: _tagRepo,
      ),
    );
    if (selectedIds == null || !mounted) return;

    try {
      await _tagRepo.setTagsForRecipe(_currentRecipe.id, selectedIds);
      if (mounted) {
        await _loadTags();
        setState(() => _hasChanges = true);
        SnackbarService.showSuccess(
          context,
          AppLocalizations.of(context)!.tagsUpdatedSuccessfully,
        );
      }
    } on GastrobrainException catch (e) {
      if (mounted) SnackbarService.showError(context, e.message);
    } catch (_) {
      if (mounted) {
        SnackbarService.showError(
            context, AppLocalizations.of(context)!.unexpectedError);
      }
    }
  }

  List<Widget> _buildAppBarActions() {
    return [
      IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: AppLocalizations.of(context)!.deleteRecipe,
        onPressed: _deleteRecipe,
      ),
    ];
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
          SnackbarService.showSuccess(
            context,
            AppLocalizations.of(context)!.recipeDeletedSuccessfully,
          );
          Navigator.pop(context, true);
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
      ),
    );
  }

  Widget _buildOverviewTab() {
    return RecipeDetailsOverviewTab(
      recipe: _currentRecipe,
      tags: _recipeTags,
      onEdit: _editRecipeInfo,
      onEditTags: _editTags,
    );
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
      onAdd: _addIngredients,
    );
  }

  Widget _buildInstructionsTab() {
    final bool hasInstructions = _instructions.isNotEmpty;

    if (!hasInstructions) {
      return _buildEmptyInstructionsView();
    }

    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.instructions,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: l10n.editInstructions,
                onPressed: _editInstructions,
              ),
            ],
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

}
