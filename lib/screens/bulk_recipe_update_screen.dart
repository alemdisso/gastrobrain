import 'package:flutter/material.dart';
import '../core/di/service_provider.dart';
import '../models/recipe.dart';
import '../l10n/app_localizations.dart';

/// Bulk recipe update screen for efficiently adding ingredients and instructions
/// to existing recipes that have basic metadata but are missing detailed content.
///
/// This is a temporary development tool for issue #161 (Recipe Selection & Loading).
/// Subsequent issues will add ingredient parsing (#162) and instructions/workflow (#163).
class BulkRecipeUpdateScreen extends StatefulWidget {
  const BulkRecipeUpdateScreen({super.key});

  @override
  State<BulkRecipeUpdateScreen> createState() => _BulkRecipeUpdateScreenState();
}

class _BulkRecipeUpdateScreenState extends State<BulkRecipeUpdateScreen> {
  // State management
  List<Recipe> _recipesNeedingIngredients = [];
  Recipe? _selectedRecipe;
  int? _selectedRecipeIndex;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRecipesNeedingIngredients();
  }

  /// Load recipes that need ingredient data (have 0 ingredients)
  Future<void> _loadRecipesNeedingIngredients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dbHelper = ServiceProvider.database.dbHelper;
      final allRecipes = await dbHelper.getAllRecipes();

      // Filter recipes that have no ingredients
      final recipesNeedingUpdate = <Recipe>[];
      for (final recipe in allRecipes) {
        final ingredients = await dbHelper.getRecipeIngredients(recipe.id);
        if (ingredients.isEmpty) {
          recipesNeedingUpdate.add(recipe);
        }
      }

      setState(() {
        _recipesNeedingIngredients = recipesNeedingUpdate;
        _isLoading = false;

        // Auto-select first recipe if available
        if (_recipesNeedingIngredients.isNotEmpty) {
          _selectedRecipe = _recipesNeedingIngredients[0];
          _selectedRecipeIndex = 0;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading recipes: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  /// Handle recipe selection from dropdown
  void _onRecipeSelected(Recipe? recipe) {
    if (recipe == null) return;

    setState(() {
      _selectedRecipe = recipe;
      _selectedRecipeIndex = _recipesNeedingIngredients.indexOf(recipe);
    });
  }

  /// Navigate to previous recipe
  void _navigateToPrevious() {
    if (_selectedRecipeIndex == null || _selectedRecipeIndex! <= 0) return;

    setState(() {
      _selectedRecipeIndex = _selectedRecipeIndex! - 1;
      _selectedRecipe = _recipesNeedingIngredients[_selectedRecipeIndex!];
    });
  }

  /// Navigate to next recipe
  void _navigateToNext() {
    if (_selectedRecipeIndex == null ||
        _selectedRecipeIndex! >= _recipesNeedingIngredients.length - 1) {
      return;
    }

    setState(() {
      _selectedRecipeIndex = _selectedRecipeIndex! + 1;
      _selectedRecipe = _recipesNeedingIngredients[_selectedRecipeIndex!];
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Recipe Update'),
        actions: [
          // Progress indicator in app bar
          if (_recipesNeedingIngredients.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Recipe ${(_selectedRecipeIndex ?? 0) + 1} of ${_recipesNeedingIngredients.length}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(context, localizations),
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
                'All recipes have ingredients!',
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recipe Selector Section
          _buildRecipeSelector(context, localizations),
          const SizedBox(height: 24),

          // Recipe Metadata Display (Read-only)
          if (_selectedRecipe != null)
            _buildRecipeMetadataDisplay(context, localizations),
          const SizedBox(height: 24),

          // Placeholder for Ingredients (Issue #162)
          _buildIngredientsPlaceholder(context),
          const SizedBox(height: 24),

          // Placeholder for Instructions (Issue #163)
          _buildInstructionsPlaceholder(context),
          const SizedBox(height: 24),

          // Navigation Controls
          _buildNavigationControls(context, localizations),
        ],
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
              value: _selectedRecipe,
              decoration: InputDecoration(
                labelText: localizations.recipeName,
                border: const OutlineInputBorder(),
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
                      '${_recipesNeedingIngredients.length} recipes need ingredients',
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

  /// Read-only recipe metadata display
  Widget _buildRecipeMetadataDisplay(
      BuildContext context, AppLocalizations localizations) {
    if (_selectedRecipe == null) return const SizedBox.shrink();

    final recipe = _selectedRecipe!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Name Header
            Text(
              recipe.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Metadata Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Category
                Chip(
                  avatar: const Icon(Icons.category, size: 18),
                  label: Text(recipe.category.getLocalizedDisplayName(context)),
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.5),
                ),

                // Difficulty
                Chip(
                  avatar: const Icon(Icons.signal_cellular_alt, size: 18),
                  label: Text(
                      '${localizations.difficulty}: ${recipe.difficulty}/5'),
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .secondaryContainer
                      .withValues(alpha: 0.5),
                ),

                // Rating
                if (recipe.rating > 0)
                  Chip(
                    avatar: const Icon(Icons.star, size: 18),
                    label: Text('${localizations.rating}: ${recipe.rating}/5'),
                    backgroundColor: Colors.amber.withValues(alpha: 0.3),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Times
            Row(
              children: [
                Icon(Icons.schedule,
                    size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '${localizations.prepTimeLabel}: ${recipe.prepTimeMinutes} min  •  '
                  '${localizations.cookTimeLabel}: ${recipe.cookTimeMinutes} min',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Current Status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .errorContainer
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .error
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Theme.of(context).colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Status: No ingredients',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Placeholder for ingredients section (to be implemented in #162)
  Widget _buildIngredientsPlaceholder(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list_alt,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'Ingredients',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(
                    Icons.construction,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ingredient parsing and editing',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Will be implemented in issue #162',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Placeholder for instructions section (to be implemented in #163)
  Widget _buildInstructionsPlaceholder(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'Instructions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(
                    Icons.construction,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Instructions field and workflow',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Will be implemented in issue #163',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
              'Progress: ${(_selectedRecipeIndex ?? 0) + 1} of ${_recipesNeedingIngredients.length} recipes',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Placeholder for save/workflow buttons (Issue #163)
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
                      'Save & Next Recipe workflow will be added in issue #163',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
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
}
