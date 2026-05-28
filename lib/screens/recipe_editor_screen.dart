import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:uuid/uuid.dart';
import '../core/di/service_provider.dart';
import '../core/services/ingredient_matching_service.dart';
import '../models/recipe.dart';
import '../models/recipe_ingredient.dart';
import '../models/ingredient.dart';
import '../widgets/add_new_ingredient_dialog.dart';
import '../widgets/ingredient_parser/ingredient_parser_section.dart';
import '../widgets/recipe_editor/existing_ingredients_display.dart';
import '../widgets/recipe_editor/parsed_ingredient.dart';
import '../widgets/recipe_editor/recipe_enrichment_progress_card.dart';
import '../widgets/recipe_editor/recipe_metadata_display.dart';
import '../l10n/app_localizations.dart';
import '../utils/id_generator.dart';
import '../utils/sorting_utils.dart';

/// Recipe editor screen for efficiently adding ingredients and instructions
/// to existing recipes that have basic metadata but are missing detailed content.
///
/// This is a temporary development tool for issue #161 (Recipe Selection & Loading).
/// Subsequent issues will add ingredient parsing (#162) and instructions/workflow (#163).
class RecipeEditorScreen extends StatefulWidget {
  const RecipeEditorScreen({super.key});

  @override
  State<RecipeEditorScreen> createState() => _RecipeEditorScreenState();
}

class _RecipeEditorScreenState extends State<RecipeEditorScreen> {
  // State management
  List<Recipe> _recipesNeedingIngredients = [];
  Recipe? _selectedRecipe;
  int? _selectedRecipeIndex;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isMetadataExpanded = false;
  int _servings = 4;

  // Ingredient parsing state — list is populated by IngredientParserSection
  // via onIngredientsConfirmed before _saveIngredients is called.
  List<ParsedIngredient> _parsedIngredients = [];
  bool _isSaving = false;

  // Instructions state
  final TextEditingController _instructionsController = TextEditingController();
  bool _hasUnsavedChanges = false;
  bool _isInstructionsPreviewMode = false;

  // Session tracking (Phase 5)
  int _recipesUpdatedInSession = 0;

  // Recipe enrichment stats
  Map<String, int>? _enrichmentStats;
  bool _isLoadingStats = false;

  // Existing ingredients state (raw maps from database query)
  List<Map<String, dynamic>> _existingIngredients = [];
  bool _isLoadingIngredients = false;

  // Ingredient matching service
  final IngredientMatchingService _matchingService =
      IngredientMatchingService();
  bool _isMatchingServiceReady = false;

  bool _isParserServiceReady = false;

  @override
  void initState() {
    super.initState();
    _loadRecipesNeedingIngredients();
    _loadAllIngredients();
    _loadEnrichmentStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize parser service with localized strings (requires context)
    // This may run before matching service is ready, so we also try in _loadAllIngredients
    if (!_isParserServiceReady && _isMatchingServiceReady && mounted) {
      final localizations = AppLocalizations.of(context);
      if (localizations != null) {
        ServiceProvider.ingredientParser.initialize(
          localizations,
          matchingService: _matchingService,
        );
        setState(() {
          _isParserServiceReady = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  /// Load recipes that need ingredient data (have less than 3 ingredients)
  /// If [preserveCurrentRecipe] is true, tries to keep the current recipe selected
  Future<void> _loadRecipesNeedingIngredients(
      {bool preserveCurrentRecipe = false}) async {
    // Remember current recipe ID if we want to preserve selection
    final currentRecipeId = preserveCurrentRecipe ? _selectedRecipe?.id : null;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dbHelper = ServiceProvider.database.dbHelper;
      final allRecipes = await dbHelper.getAllRecipes();

      // Filter recipes with less than 3 ingredients (incomplete data)
      final unsortedRecipes = <Recipe>[];
      for (final recipe in allRecipes) {
        final ingredients = await dbHelper.getRecipeIngredients(recipe.id);
        if (ingredients.length < 3) {
          unsortedRecipes.add(recipe);
        }
      }

      // Sort recipes alphabetically by name for easier selection
      final recipesNeedingUpdate =
          SortingUtils.sortByName(unsortedRecipes, (r) => r.name);

      // Try to find the previously selected recipe in the updated list
      Recipe? recipeToSelect;
      int? indexToSelect;

      if (currentRecipeId != null) {
        // Try to find the current recipe in the new list
        final index =
            recipesNeedingUpdate.indexWhere((r) => r.id == currentRecipeId);
        if (index >= 0) {
          recipeToSelect = recipesNeedingUpdate[index];
          indexToSelect = index;
        }
      }

      // If no recipe to preserve, or it's no longer in the list, select first
      if (recipeToSelect == null && recipesNeedingUpdate.isNotEmpty) {
        recipeToSelect = recipesNeedingUpdate[0];
        indexToSelect = 0;
      }

      setState(() {
        _recipesNeedingIngredients = recipesNeedingUpdate;
        _isLoading = false;
        _selectedRecipe = recipeToSelect;
        _selectedRecipeIndex = indexToSelect;
      });

      // Load existing ingredients and instructions for selected recipe
      final selectedRecipe = recipeToSelect;
      if (selectedRecipe != null) {
        try {
          final existingIngredients =
              await dbHelper.getRecipeIngredients(selectedRecipe.id);
          setState(() {
            _existingIngredients = existingIngredients;
            _instructionsController.text = selectedRecipe.instructions;
            _servings = selectedRecipe.servings > 0 ? selectedRecipe.servings : 4;
            _hasUnsavedChanges =
                false; // Reset unsaved changes when loading recipe (will be used in Phase 4)
          });
        } catch (e) {
          setState(() {
            _existingIngredients = [];
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading recipes: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  /// Load all ingredients from database for matching
  Future<void> _loadAllIngredients() async {
    try {
      final dbHelper = ServiceProvider.database.dbHelper;
      final allIngredients = await dbHelper.getAllIngredients();

      // Initialize matching service with loaded ingredients
      _matchingService.initialize(allIngredients);

      setState(() {
        _isMatchingServiceReady = true;
      });

      // Initialize parser service now that matching service is ready
      // (only if we have localizations context available)
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        if (localizations != null && !_isParserServiceReady) {
          ServiceProvider.ingredientParser.initialize(
            localizations,
            matchingService: _matchingService,
          );
          setState(() {
            _isParserServiceReady = true;
          });
        }
      }
    } catch (e) {
      // Silently fail - matching will just not work if ingredients can't be loaded
      setState(() {
        _isMatchingServiceReady = false;
      });
    }
  }

  /// Load recipe enrichment statistics
  Future<void> _loadEnrichmentStats() async {
    setState(() {
      _isLoadingStats = true;
    });

    try {
      final dbHelper = ServiceProvider.database.dbHelper;
      final stats = await dbHelper.getRecipeEnrichmentStats();

      if (mounted) {
        setState(() {
          _enrichmentStats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _enrichmentStats = null;
          _isLoadingStats = false;
        });
      }
    }
  }

  /// Handle recipe selection from dropdown
  void _onRecipeSelected(Recipe? recipe) async {
    if (recipe == null) return;

    setState(() {
      _selectedRecipe = recipe;
      _selectedRecipeIndex = _recipesNeedingIngredients.indexOf(recipe);
      _isLoadingIngredients = true;
    });

    // Load existing recipe ingredients and instructions
    try {
      final dbHelper = ServiceProvider.database.dbHelper;
      final existingIngredients =
          await dbHelper.getRecipeIngredients(recipe.id);

      setState(() {
        _existingIngredients = existingIngredients;
        _instructionsController.text = recipe.instructions;
        _servings = recipe.servings > 0 ? recipe.servings : 4;
        _hasUnsavedChanges = false; // Reset when loading new recipe
        _isLoadingIngredients = false;
      });
    } catch (e) {
      setState(() {
        _existingIngredients = [];
        _isLoadingIngredients = false;
      });
    }
  }

  /// Navigate to previous recipe
  void _navigateToPrevious() async {
    if (_selectedRecipeIndex == null || _selectedRecipeIndex! <= 0) return;

    final newIndex = _selectedRecipeIndex! - 1;
    final newRecipe = _recipesNeedingIngredients[newIndex];

    setState(() {
      _selectedRecipeIndex = newIndex;
      _selectedRecipe = newRecipe;
      _isLoadingIngredients = true;
    });

    // Load existing recipe ingredients and instructions
    try {
      final dbHelper = ServiceProvider.database.dbHelper;
      final existingIngredients =
          await dbHelper.getRecipeIngredients(newRecipe.id);

      setState(() {
        _existingIngredients = existingIngredients;
        _instructionsController.text = newRecipe.instructions;
        _servings = newRecipe.servings > 0 ? newRecipe.servings : 4;
        _hasUnsavedChanges = false; // Reset when navigating
        _isLoadingIngredients = false;
      });
    } catch (e) {
      setState(() {
        _existingIngredients = [];
        _isLoadingIngredients = false;
      });
    }
  }

  /// Navigate to next recipe
  void _navigateToNext() async {
    if (_selectedRecipeIndex == null ||
        _selectedRecipeIndex! >= _recipesNeedingIngredients.length - 1) {
      return;
    }

    final newIndex = _selectedRecipeIndex! + 1;
    final newRecipe = _recipesNeedingIngredients[newIndex];

    setState(() {
      _selectedRecipeIndex = newIndex;
      _selectedRecipe = newRecipe;
      _isLoadingIngredients = true;
    });

    // Load existing recipe ingredients and instructions
    try {
      final dbHelper = ServiceProvider.database.dbHelper;
      final existingIngredients =
          await dbHelper.getRecipeIngredients(newRecipe.id);

      setState(() {
        _existingIngredients = existingIngredients;
        _instructionsController.text = newRecipe.instructions;
        _servings = newRecipe.servings > 0 ? newRecipe.servings : 4;
        _hasUnsavedChanges = false; // Reset when navigating
        _isLoadingIngredients = false;
      });
    } catch (e) {
      setState(() {
        _existingIngredients = [];
        _isLoadingIngredients = false;
      });
    }
  }

  /// Show dialog to create a new ingredient from parsed data.
  /// Returns the persisted [Ingredient] on confirm, or null on cancel.
  Future<Ingredient?> _showCreateIngredientDialog(
      ParsedIngredient parsed) async {
    final prefilledIngredient = Ingredient(
      id: IdGenerator.generateId(),
      name: parsed.originalName.isNotEmpty ? parsed.originalName : parsed.name,
      category: parsed.category,
      unit: null,
      notes: parsed.notes,
    );

    return showDialog<Ingredient>(
      context: context,
      builder: (context) => AddNewIngredientDialog(
        ingredient: prefilledIngredient,
      ),
    );
  }

  /// Save ingredients and instructions to database. Returns true on success.
  Future<bool> _saveIngredients() async {
    if (_selectedRecipe == null || _parsedIngredients.isEmpty) return false;

    // Separate new and unresolved ingredients
    final newIngredients = _parsedIngredients
        .where((p) => p.name.trim().isNotEmpty && p.isNewIngredient)
        .toList();
    final unresolvedIngredients = _parsedIngredients
        .where((p) =>
            p.name.trim().isNotEmpty &&
            !p.isNewIngredient &&
            p.selectedMatch == null)
        .toList();

    // Validate: all ingredients must be either matched or marked as new
    if (unresolvedIngredients.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot save: ${unresolvedIngredients.length} ingredient(s) not matched to database. '
              'Please select a match or create new ingredients first.',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return false;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final dbHelper = ServiceProvider.database.dbHelper;
      const uuid = Uuid();

      int addedCount = 0;
      int updatedCount = 0;
      int createdCount = 0;

      // Step 1: Create new ingredients in the main ingredients table
      for (final parsed in newIngredients) {
        await dbHelper.insertIngredient(parsed.newIngredientToCreate!);
        createdCount++;
      }

      // Step 2: Load current recipe ingredients to check for duplicates
      final existingIngredients =
          await dbHelper.getRecipeIngredients(_selectedRecipe!.id);

      // Build map of existing ingredient_id -> recipe_ingredient data
      final existingByIngredientId = <String, Map<String, dynamic>>{};
      for (final existing in existingIngredients) {
        final ingredientId = existing['ingredient_id'] as String?;
        if (ingredientId != null) {
          existingByIngredientId[ingredientId] = existing;
        }
      }

      // Step 3: Process all parsed ingredients (matched + newly created)
      for (final parsed in _parsedIngredients) {
        if (parsed.name.trim().isEmpty) continue;

        // Get ingredient ID (from match or from newly created ingredient)
        String? ingredientId;
        if (parsed.selectedMatch != null) {
          ingredientId = parsed.selectedMatch!.ingredient.id;
        } else if (parsed.isNewIngredient) {
          ingredientId = parsed.newIngredientToCreate!.id;
        } else {
          continue; // Skip unresolved (shouldn't happen due to validation)
        }

        // Check if this ingredient already exists in the recipe
        if (existingByIngredientId.containsKey(ingredientId)) {
          // Update existing recipe ingredient
          final existing = existingByIngredientId[ingredientId]!;
          final recipeIngredientId = existing['recipe_ingredient_id'] as String;

          final updatedRecipeIngredient = RecipeIngredient(
            id: recipeIngredientId,
            recipeId: _selectedRecipe!.id,
            ingredientId: ingredientId,
            quantity: parsed.quantity,
            quantityMax: parsed.quantityMax,
            notes: parsed.notes,
            unitOverride: parsed.unit,
          );

          await dbHelper.updateRecipeIngredient(updatedRecipeIngredient);
          updatedCount++;
        } else {
          // Add new recipe ingredient link
          final recipeIngredient = RecipeIngredient(
            id: uuid.v4(),
            recipeId: _selectedRecipe!.id,
            ingredientId: ingredientId,
            quantity: parsed.quantity,
            quantityMax: parsed.quantityMax,
            notes: parsed.notes,
            unitOverride: parsed.unit,
          );

          await dbHelper.addIngredientToRecipe(recipeIngredient);
          addedCount++;
        }
      }

      // Step 4: Save instructions
      final updatedRecipe = _selectedRecipe!.copyWith(
        instructions: _instructionsController.text,
        servings: _servings,
      );
      await dbHelper.updateRecipe(updatedRecipe);

      // Show success message
      if (mounted) {
        final message = StringBuffer();
        if (createdCount > 0) {
          message.write('Created $createdCount new ingredient(s)');
        }
        if (addedCount > 0) {
          if (message.isNotEmpty) message.write(', ');
          message.write('Added $addedCount to recipe');
        }
        if (updatedCount > 0) {
          if (message.isNotEmpty) message.write(', ');
          message.write('Updated $updatedCount');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.toString()),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _parsedIngredients = [];
          _hasUnsavedChanges = false;
        });

        // Reload existing ingredients to show updated state
        final refreshedIngredients =
            await dbHelper.getRecipeIngredients(_selectedRecipe!.id);
        setState(() {
          _existingIngredients = refreshedIngredients;
        });

        // Reload recipes list (this recipe should now have more ingredients)
        // Preserve current recipe selection unless it's been removed from the list
        await _loadRecipesNeedingIngredients(preserveCurrentRecipe: true);

        // Refresh enrichment stats to reflect the update
        await _loadEnrichmentStats();

        // Increment session counter for completed recipe update
        setState(() {
          _recipesUpdatedInSession++;
        });
        return true;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving ingredients: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
    return false;
  }

  /// Save current recipe (ingredients + instructions) and load next recipe
  Future<void> _saveAndNext() async {
    if (_selectedRecipe == null) return;

    // Remember current index before save (list will be reloaded during save)
    final indexBeforeSave = _selectedRecipeIndex ?? 0;

    // Save ingredients and instructions
    await _saveIngredients();

    // After save, check if there are more recipes
    if (_recipesNeedingIngredients.isEmpty) {
      // No more recipes to update
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All recipes updated!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      return;
    }

    // Load next recipe: use saved index (which now points to next recipe after current one was removed)
    // If index is out of bounds, wrap to first recipe
    final nextIndex = indexBeforeSave < _recipesNeedingIngredients.length
        ? indexBeforeSave
        : 0;

    final newRecipe = _recipesNeedingIngredients[nextIndex];

    setState(() {
      _selectedRecipe = newRecipe;
      _selectedRecipeIndex = nextIndex;
      _isLoadingIngredients = true;
    });

    // Load the next recipe's data
    try {
      final dbHelper = ServiceProvider.database.dbHelper;
      final existingIngredients =
          await dbHelper.getRecipeIngredients(newRecipe.id);

      setState(() {
        _existingIngredients = existingIngredients;
        _instructionsController.text = newRecipe.instructions;
        _hasUnsavedChanges = false;
        _isLoadingIngredients = false;
      });
    } catch (e) {
      setState(() {
        _existingIngredients = [];
        _isLoadingIngredients = false;
      });
    }
  }

  /// Save current recipe and close screen
  Future<void> _saveAndClose() async {
    if (_selectedRecipe == null) {
      Navigator.pop(context);
      return;
    }

    // Save ingredients and instructions
    await _saveIngredients();

    // Show session summary and return to previous screen
    if (mounted) {
      // Show session summary SnackBar
      if (_recipesUpdatedInSession > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Session complete: $_recipesUpdatedInSession recipe${_recipesUpdatedInSession != 1 ? "s" : ""} updated!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        // If already popped (no unsaved changes), nothing to do
        if (didPop) return;

        // Show confirmation dialog for unsaved changes
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Unsaved Changes'),
            content: const Text(
              'You have unsaved changes to the instructions. Do you want to discard them?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Stay'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Discard'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          ),
        );

        // If user confirmed, manually pop the screen
        if (shouldPop == true && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.recipeEditor),
          actions: [
            // Progress indicator in app bar
            if (_recipesNeedingIngredients.isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Recipe ${(_selectedRecipeIndex ?? 0) + 1} of ${_recipesNeedingIngredients.length}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (_recipesUpdatedInSession > 0)
                        Text(
                          '$_recipesUpdatedInSession updated',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        body: _buildBody(context, localizations),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations localizations) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadRecipesNeedingIngredients,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_recipesNeedingIngredients.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline,
                  size: 64, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                'All recipes are complete!',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'No recipes need updating at this time.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      top: false, // AppBar handles top
      bottom: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Recipe Enrichment Progress Card
          RecipeEnrichmentProgressCard(
            enrichmentStats: _enrichmentStats,
            isLoading: _isLoadingStats,
          ),
          const SizedBox(height: 16),

          // Recipe Selector Section
          _buildRecipeSelector(context, localizations),
          const SizedBox(height: 24),

          // Recipe Metadata Display (Read-only)
          if (_selectedRecipe != null)
            RecipeMetadataDisplay(
              recipe: _selectedRecipe!,
              isExpanded: _isMetadataExpanded,
              servings: _servings,
              onToggleExpanded: () =>
                  setState(() => _isMetadataExpanded = !_isMetadataExpanded),
              onServingsChanged: (v) => setState(() => _servings = v),
            ),
          const SizedBox(height: 24),

          // Existing Ingredients Display (Read-only)
          if (_selectedRecipe != null)
            ExistingIngredientsDisplay(
              existingIngredients: _existingIngredients,
              isLoading: _isLoadingIngredients,
            ),
          if (_selectedRecipe != null) const SizedBox(height: 24),

          // Placeholder for Ingredients (Issue #162)
          _buildIngredientsPlaceholder(context),
          const SizedBox(height: 24),

          // Navigation Controls
          _buildNavigationControls(context, localizations),
        ],
      ),
      ),
    );
  }


  /// Recipe selector dropdown widget
  Widget _buildRecipeSelector(
      BuildContext context, AppLocalizations localizations) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Select Recipe to Update',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Recipe>(
              initialValue: _selectedRecipe,
              decoration: InputDecoration(
                labelText: localizations.recipeName,
                      contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _recipesNeedingIngredients.map((recipe) {
                return DropdownMenuItem<Recipe>(
                  value: recipe,
                  child: Text(
                    recipe.name,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: _onRecipeSelected,
              isExpanded: true,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_recipesNeedingIngredients.length} recipes need updates',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }




  /// Ingredients section with parsing and editing
  Widget _buildIngredientsPlaceholder(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.list_alt,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Ingredients',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Redesigned ingredient parser (Issue #371)
            IngredientParserSection(
              matchingService: _matchingService,
              isServicesReady: _isParserServiceReady,
              onIngredientsConfirmed: (list) async {
                setState(() => _parsedIngredients = list);
                return _saveIngredients();
              },
              onCreateNew: (parsed) => _showCreateIngredientDialog(parsed),
            ),

            if (_parsedIngredients.isNotEmpty || _existingIngredients.isNotEmpty) ...[
              const SizedBox(height: 24),

              // Instructions section
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.description,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Instructions',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  if (!_isInstructionsPreviewMode)
                    Flexible(
                      child: Text(
                        '${_instructionsController.text.length} characters',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(width: 8),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.edit_outlined),
                      ),
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.visibility_outlined),
                      ),
                    ],
                    selected: {_isInstructionsPreviewMode},
                    onSelectionChanged: (v) => setState(
                      () => _isInstructionsPreviewMode = v.first,
                    ),
                    style: const ButtonStyle(
                      visualDensity: VisualDensity(
                        horizontal: VisualDensity.minimumDensity,
                        vertical: VisualDensity.minimumDensity,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_isInstructionsPreviewMode)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _instructionsController.text.isEmpty
                      ? Text(
                          'Enter cooking instructions here...',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                        )
                      : MarkdownBody(
                          data: _instructionsController.text,
                          shrinkWrap: true,
                          styleSheet: MarkdownStyleSheet.fromTheme(
                            Theme.of(context),
                          ).copyWith(
                            p: const TextStyle(fontSize: 16, height: 1.5),
                          ),
                        ),
                )
              else
                TextField(
                  controller: _instructionsController,
                  maxLines: 12,
                  decoration: const InputDecoration(
                    hintText:
                        'Enter cooking instructions here...\n\nExample:\n1. Preheat oven to 180°C\n2. Mix ingredients...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _hasUnsavedChanges = true;
                    });
                  },
                ),
              const SizedBox(height: 24),

              // Workflow control buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveAndNext,
                      icon: const Icon(Icons.save_alt),
                      label: const Text('Save & Next'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveAndClose,
                      icon: const Icon(Icons.check),
                      label: const Text('Update & Close'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }


  /// Instructions section for entering cooking instructions
  /// Navigation controls (Previous/Next buttons and progress)
  Widget _buildNavigationControls(
      BuildContext context, AppLocalizations localizations) {
    final bool hasPrevious =
        _selectedRecipeIndex != null && _selectedRecipeIndex! > 0;
    final bool hasNext = _selectedRecipeIndex != null &&
        _selectedRecipeIndex! < _recipesNeedingIngredients.length - 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Navigation',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Previous/Next buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: hasPrevious ? _navigateToPrevious : null,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Previous'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: hasNext ? _navigateToNext : null,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress indicator
            LinearProgressIndicator(
              value: _recipesNeedingIngredients.isEmpty
                  ? 0
                  : (_selectedRecipeIndex! + 1) /
                      _recipesNeedingIngredients.length,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            const SizedBox(height: 8),
            Text(
              'Progress: ${(_selectedRecipeIndex ?? 0) + 1} of ${_recipesNeedingIngredients.length} incomplete recipes',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

