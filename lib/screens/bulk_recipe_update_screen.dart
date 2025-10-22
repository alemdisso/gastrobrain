import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../core/di/service_provider.dart';
import '../core/services/ingredient_matching_service.dart';
import '../models/recipe.dart';
import '../models/recipe_ingredient.dart';
import '../models/ingredient_category.dart';
import '../models/ingredient_match.dart';
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
  bool _isMetadataExpanded = false;

  // Ingredient parsing state
  final TextEditingController _rawIngredientsController = TextEditingController();
  List<_ParsedIngredient> _parsedIngredients = [];
  bool _isSaving = false;

  // Existing ingredients state (raw maps from database query)
  List<Map<String, dynamic>> _existingIngredients = [];
  bool _isLoadingIngredients = false;

  // Ingredient matching service
  final IngredientMatchingService _matchingService = IngredientMatchingService();
  bool _isMatchingServiceReady = false;

  @override
  void initState() {
    super.initState();
    _loadRecipesNeedingIngredients();
    _loadAllIngredients();
  }

  @override
  void dispose() {
    _rawIngredientsController.dispose();
    super.dispose();
  }

  /// Load recipes that need ingredient data (have less than 3 ingredients)
  /// If [preserveCurrentRecipe] is true, tries to keep the current recipe selected
  Future<void> _loadRecipesNeedingIngredients({bool preserveCurrentRecipe = false}) async {
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
      final recipesNeedingUpdate = <Recipe>[];
      for (final recipe in allRecipes) {
        final ingredients = await dbHelper.getRecipeIngredients(recipe.id);
        if (ingredients.length < 3) {
          recipesNeedingUpdate.add(recipe);
        }
      }

      // Try to find the previously selected recipe in the updated list
      Recipe? recipeToSelect;
      int? indexToSelect;

      if (currentRecipeId != null) {
        // Try to find the current recipe in the new list
        final index = recipesNeedingUpdate.indexWhere((r) => r.id == currentRecipeId);
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

      // Load existing ingredients for selected recipe
      if (recipeToSelect != null) {
        try {
          final existingIngredients = await dbHelper.getRecipeIngredients(recipeToSelect.id);
          setState(() {
            _existingIngredients = existingIngredients;
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
    } catch (e) {
      // Silently fail - matching will just not work if ingredients can't be loaded
      setState(() {
        _isMatchingServiceReady = false;
      });
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

    // Load existing recipe ingredients
    try {
      final dbHelper = ServiceProvider.database.dbHelper;
      final existingIngredients = await dbHelper.getRecipeIngredients(recipe.id);

      setState(() {
        _existingIngredients = existingIngredients;
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

    // Load existing recipe ingredients
    try {
      final dbHelper = ServiceProvider.database.dbHelper;
      final existingIngredients = await dbHelper.getRecipeIngredients(newRecipe.id);

      setState(() {
        _existingIngredients = existingIngredients;
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

    // Load existing recipe ingredients
    try {
      final dbHelper = ServiceProvider.database.dbHelper;
      final existingIngredients = await dbHelper.getRecipeIngredients(newRecipe.id);

      setState(() {
        _existingIngredients = existingIngredients;
        _isLoadingIngredients = false;
      });
    } catch (e) {
      setState(() {
        _existingIngredients = [];
        _isLoadingIngredients = false;
      });
    }
  }

  /// Parse raw ingredient text into structured ingredient list
  void _parseIngredients() {
    final rawText = _rawIngredientsController.text.trim();
    if (rawText.isEmpty) {
      setState(() {
        _parsedIngredients = [];
      });
      return;
    }

    final lines = rawText.split('\n');
    final parsedList = <_ParsedIngredient>[];

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      final parsed = _parseIngredientLine(trimmedLine);
      if (parsed != null) {
        parsedList.add(parsed);
      }
    }

    setState(() {
      _parsedIngredients = parsedList;
    });
  }

  /// Common descriptors that modify ingredients (size, state, preparation)
  /// These are extracted and stored in the notes field, not the ingredient name
  static const _descriptors = {
    // Size (PT)
    'pequena', 'pequeno', 'pequenas', 'pequenos',
    'grande', 'grandes',
    'média', 'medio', 'médias', 'medios',
    // Size (EN)
    'small', 'large', 'medium',
    // State/ripeness (PT)
    'maduro', 'madura', 'maduros', 'maduras',
    'verde', 'verdes',
    'fresco', 'fresca', 'frescos', 'frescas',
    'seco', 'seca', 'secos', 'secas',
    // State/ripeness (EN)
    'ripe', 'green', 'fresh', 'dried',
    // Preparation (PT)
    'picado', 'picada', 'picados', 'picadas',
    'ralado', 'ralada', 'ralados', 'raladas',
    'fatiado', 'fatiada', 'fatiados', 'fatiadas',
    'cortado', 'cortada', 'cortados', 'cortadas',
    // Preparation (EN)
    'chopped', 'diced', 'minced', 'grated', 'sliced', 'cut',
    // Modifiers (PT)
    'sem', 'com',
    // Common combinations (PT)
    'sem sementes', 'com casca', 'sem casca',
  };

  /// Parse a single ingredient line
  ///
  /// Handles three refinements (Issue #166):
  /// 1. Default unit: Quantities without units default to "piece"
  /// 2. Descriptors: Extracted and stored in notes, not ingredient name
  /// 3. "de" handling: Strips "de" after valid units (e.g., "2 fatias de pão" → "pão")
  ///
  /// Examples:
  /// - "3 ovos" → 3 piece ovos, notes: null
  /// - "1 cebola pequena" → 1 piece cebola, notes: "pequena"
  /// - "2 tomates maduros" → 2 piece tomates, notes: "maduros"
  /// - "2 fatias de pão" → 2 slice pão, notes: null
  /// - "200g farinha" → 200 g farinha, notes: null
  _ParsedIngredient? _parseIngredientLine(String line) {
    // Regex patterns for parsing ingredients
    // Supports formats like:
    // - "200g farinha" / "200g flour"
    // - "2 xícaras leite" / "2 cups milk"
    // - "1 csp sal" / "1 tsp salt"
    // - "3 ovos" / "3 eggs"
    // - "1 cebola pequena" / "1 small onion"
    // - "2 fatias de pão" / "2 slices of bread"
    // - "Sal a gosto" / "Salt to taste"

    // Pattern: [quantity] [unit] ingredient_name
    // Note: Using [a-zA-ZÀ-ÿ] to support accented characters (e.g., xícara, colher)
    final quantityUnitPattern = RegExp(
      r'^(\d+(?:[.,]\d+)?)\s*([a-zA-ZÀ-ÿ]+)?\s+(.+)$',
      caseSensitive: false,
    );

    // Pattern: just ingredient name (no quantity)
    // Note: Using [a-zA-ZÀ-ÿ] to support accented characters
    final nameOnlyPattern = RegExp(r'^([a-zA-ZÀ-ÿ\s]+)(?:\s+(?:a\s+)?gosto)?$', caseSensitive: false);

    final match = quantityUnitPattern.firstMatch(line);
    if (match != null) {
      final quantityStr = match.group(1)!.replaceAll(',', '.');
      final quantity = double.tryParse(quantityStr) ?? 1.0;
      final unitStr = match.group(2)?.toLowerCase().trim();
      var name = match.group(3)!.trim();

      // Try to parse the captured unit word
      var unit = _parseUnit(unitStr);

      // Track descriptors for notes field
      final descriptorParts = <String>[];

      // If the captured word is not a valid unit, it's probably part of the ingredient name
      if (unitStr != null && unit == null) {
        // Check if it's a descriptor
        if (_descriptors.contains(unitStr.toLowerCase())) {
          descriptorParts.add(unitStr);
          // Don't add descriptor to name, just default to "piece"
        } else {
          // Not a unit, not a descriptor - it's part of the ingredient name
          name = '$unitStr $name';
        }
        unit = 'piece';
      }

      // If no unit word was captured at all, default to "piece"
      if (unitStr == null) {
        unit = 'piece';
      }

      // Handle "de" after unit words (e.g., "2 fatias de pão" → "pão")
      if (unit != null && name.startsWith('de ')) {
        name = name.substring(3); // Strip "de "
      }

      // Smart matching: Try to find the longest ingredient name match first,
      // then extract descriptors from what remains.
      // This handles compound names like "pimentão verde" correctly.
      String matchedName = name;
      List<IngredientMatch> matches = [];
      IngredientMatch? selectedMatch;

      // Try progressively shorter prefixes (from right to left)
      // to find the longest matching ingredient name
      final nameParts = name.split(' ');
      bool foundMatch = false;

      for (int i = nameParts.length; i >= 1 && !foundMatch; i--) {
        final prefixParts = nameParts.sublist(0, i);
        final testName = prefixParts.join(' ');

        matches = _findMatchesForName(testName);
        selectedMatch = _getAutoSelectedMatch(matches);

        // If we found a high-confidence match, use it
        if (selectedMatch != null && selectedMatch.confidence >= 0.90) {
          matchedName = testName;
          foundMatch = true;

          // Extract remaining words as potential descriptors
          if (i < nameParts.length) {
            final remainingParts = nameParts.sublist(i);
            // Only keep remaining parts if they're actual descriptors
            final validDescriptors = remainingParts.where(
              (part) => _descriptors.contains(part.toLowerCase())
            ).toList();

            if (validDescriptors.isNotEmpty) {
              descriptorParts.addAll(validDescriptors);
            }
          }
        }
      }

      // If no high-confidence match found, fall back to original descriptor extraction
      if (!foundMatch) {
        final cleanNameParts = <String>[];

        for (final part in nameParts) {
          if (_descriptors.contains(part.toLowerCase())) {
            descriptorParts.add(part);
          } else {
            cleanNameParts.add(part);
          }
        }

        matchedName = cleanNameParts.join(' ');
        matches = _findMatchesForName(matchedName);
        selectedMatch = _getAutoSelectedMatch(matches);
      }

      final notes = descriptorParts.isNotEmpty ? descriptorParts.join(' ') : null;

      return _ParsedIngredient(
        quantity: quantity,
        unit: unit,
        name: selectedMatch?.ingredient.name ?? matchedName, // Use matched name if available
        category: selectedMatch?.ingredient.category ?? IngredientCategory.other,
        matches: matches,
        selectedMatch: selectedMatch,
        notes: notes,
      );
    }

    // Try name-only pattern
    final nameMatch = nameOnlyPattern.firstMatch(line);
    if (nameMatch != null) {
      final name = line.trim();
      final matches = _findMatchesForName(name);
      final selectedMatch = _getAutoSelectedMatch(matches);

      return _ParsedIngredient(
        quantity: 0.0, // "to taste"
        unit: null,
        name: selectedMatch?.ingredient.name ?? name, // Use matched name if available
        category: selectedMatch?.ingredient.category ?? IngredientCategory.other,
        matches: matches,
        selectedMatch: selectedMatch,
      );
    }

    // Fallback: treat whole line as ingredient name
    final name = line.trim();
    final matches = _findMatchesForName(name);
    final selectedMatch = _getAutoSelectedMatch(matches);

    return _ParsedIngredient(
      quantity: 1.0,
      unit: null,
      name: selectedMatch?.ingredient.name ?? name, // Use matched name if available
      category: selectedMatch?.ingredient.category ?? IngredientCategory.other,
      matches: matches,
      selectedMatch: selectedMatch,
    );
  }

  /// Find ingredient matches for a given name
  List<IngredientMatch> _findMatchesForName(String name) {
    if (!_isMatchingServiceReady || name.trim().isEmpty) {
      return [];
    }
    return _matchingService.findMatches(name);
  }

  /// Get auto-selected match if applicable
  IngredientMatch? _getAutoSelectedMatch(List<IngredientMatch> matches) {
    if (!_isMatchingServiceReady || matches.isEmpty) {
      return null;
    }

    // Auto-select if high confidence (>= 90%) OR if it's the only match
    if (matches.length == 1 || _matchingService.shouldAutoSelect(matches)) {
      return matches.first;
    }

    return null;
  }

  /// Parse unit string to custom unit string
  /// Returns null if no valid unit found
  String? _parseUnit(String? unitStr) {
    if (unitStr == null || unitStr.isEmpty) return null;

    // Map of common unit abbreviations (PT/EN) to standard units
    final unitMap = {
      // Weight
      'g': 'g',
      'kg': 'kg',
      'gram': 'g',
      'grama': 'g',
      'gramas': 'g',
      'quilograma': 'kg',
      'kilogram': 'kg',

      // Volume
      'ml': 'ml',
      'l': 'l',
      'litro': 'l',
      'liter': 'l',
      'litros': 'l',
      'liters': 'l',

      // Culinary measures
      'xícara': 'cup',
      'xicara': 'cup',
      'xícaras': 'cup',
      'xicaras': 'cup',
      'cup': 'cup',
      'cups': 'cup',
      'c': 'cup',

      'colher': 'tbsp',
      'col': 'tbsp',
      'cs': 'tbsp',
      'csp': 'tbsp',
      'tbsp': 'tbsp',
      'tablespoon': 'tbsp',
      'colheres': 'tbsp',

      'tsp': 'tsp',
      'teaspoon': 'tsp',
      'chá': 'tsp',
      'cha': 'tsp',
      'cc': 'tsp',

      // Count
      'unidade': 'piece',
      'unidades': 'piece',
      'piece': 'piece',
      'pieces': 'piece',
      'pç': 'piece',
      'pc': 'piece',
      'un': 'piece',

      'fatia': 'slice',
      'fatias': 'slice',
      'slice': 'slice',
      'slices': 'slice',

      'maço': 'bunch',
      'bunch': 'bunch',
      'maco': 'bunch',

      'folha': 'leaves',
      'folhas': 'leaves',
      'leaves': 'leaves',
      'leaf': 'leaves',

      'pitada': 'pinch',
      'pinch': 'pinch',
      'pitadas': 'pinch',

      'dente': 'clove',
      'dentes': 'clove',
      'clove': 'clove',
      'cloves': 'clove',

      'cabeça': 'head',
      'cabeca': 'head',
      'cabeças': 'head',
      'cabecas': 'head',
      'head': 'head',
      'heads': 'head',
    };

    return unitMap[unitStr.toLowerCase()];
  }

  /// Add a new empty ingredient row
  void _addIngredientRow() {
    setState(() {
      _parsedIngredients.add(_ParsedIngredient(
        quantity: 1.0,
        unit: null,
        name: '',
        category: IngredientCategory.other,
        matches: [],
        selectedMatch: null,
      ));
    });
  }

  /// Remove ingredient at index
  void _removeIngredientAt(int index) {
    setState(() {
      _parsedIngredients.removeAt(index);
    });
  }

  /// Update ingredient at index
  void _updateIngredient(int index, {
    double? quantity,
    String? unit,
    String? name,
    String? notes,
    IngredientCategory? category,
    IngredientMatch? selectedMatch,
  }) {
    if (index < 0 || index >= _parsedIngredients.length) return;

    setState(() {
      final ingredient = _parsedIngredients[index];

      // If name changed, re-run matching
      List<IngredientMatch> matches = ingredient.matches;
      IngredientMatch? newSelectedMatch = selectedMatch ?? ingredient.selectedMatch;

      if (name != null && name != ingredient.name) {
        matches = _findMatchesForName(name);
        newSelectedMatch = _getAutoSelectedMatch(matches);
      }

      // If selectedMatch is explicitly provided (user picked from dropdown), use it
      if (selectedMatch != null) {
        newSelectedMatch = selectedMatch;
      }

      // If we have a selected match, use the matched ingredient's name
      // This ensures the field shows "alho-poró" instead of "alho porro"
      final finalName = newSelectedMatch?.ingredient.name ?? (name ?? ingredient.name);

      _parsedIngredients[index] = _ParsedIngredient(
        quantity: quantity ?? ingredient.quantity,
        unit: unit ?? ingredient.unit,
        name: finalName,
        notes: notes ?? ingredient.notes,
        category: category ?? newSelectedMatch?.ingredient.category ?? ingredient.category,
        matches: matches,
        selectedMatch: newSelectedMatch,
      );
    });
  }

  /// Save ingredients to database
  Future<void> _saveIngredients() async {
    if (_selectedRecipe == null || _parsedIngredients.isEmpty) return;

    // Validate: all ingredients must have matched ingredient IDs
    final unmatchedIngredients = _parsedIngredients
        .where((p) => p.name.trim().isNotEmpty && p.selectedMatch == null)
        .toList();

    if (unmatchedIngredients.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot save: ${unmatchedIngredients.length} ingredient(s) not matched to database. '
              'Please select a match or create new ingredients first.',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final dbHelper = ServiceProvider.database.dbHelper;
      const uuid = Uuid();

      int addedCount = 0;
      int updatedCount = 0;

      // Load current recipe ingredients to check for duplicates
      final existingIngredients = await dbHelper.getRecipeIngredients(_selectedRecipe!.id);

      // Build map of existing ingredient_id -> recipe_ingredient data
      final existingByIngredientId = <String, Map<String, dynamic>>{};
      for (final existing in existingIngredients) {
        final ingredientId = existing['ingredient_id'] as String?;
        if (ingredientId != null) {
          existingByIngredientId[ingredientId] = existing;
        }
      }

      // Process each parsed ingredient
      for (final parsed in _parsedIngredients) {
        if (parsed.name.trim().isEmpty || parsed.selectedMatch == null) continue;

        final ingredientId = parsed.selectedMatch!.ingredient.id;

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
            notes: parsed.notes,
            unitOverride: parsed.unit,
          );

          await dbHelper.updateRecipeIngredient(updatedRecipeIngredient);
          updatedCount++;
        } else {
          // Add new recipe ingredient
          final recipeIngredient = RecipeIngredient(
            id: uuid.v4(),
            recipeId: _selectedRecipe!.id,
            ingredientId: ingredientId,
            quantity: parsed.quantity,
            notes: parsed.notes,
            unitOverride: parsed.unit,
          );

          await dbHelper.addIngredientToRecipe(recipeIngredient);
          addedCount++;
        }
      }

      // Show success message
      if (mounted) {
        final message = StringBuffer();
        if (addedCount > 0) {
          message.write('Added $addedCount');
        }
        if (updatedCount > 0) {
          if (message.isNotEmpty) message.write(', ');
          message.write('Updated $updatedCount');
        }
        message.write(' ingredient(s)');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.toString()),
            backgroundColor: Colors.green,
          ),
        );

        // Clear the form
        setState(() {
          _rawIngredientsController.clear();
          _parsedIngredients = [];
        });

        // Reload existing ingredients to show updated state
        final refreshedIngredients = await dbHelper.getRecipeIngredients(_selectedRecipe!.id);
        setState(() {
          _existingIngredients = refreshedIngredients;
        });

        // Reload recipes list (this recipe should now have more ingredients)
        // Preserve current recipe selection unless it's been removed from the list
        await _loadRecipesNeedingIngredients(preserveCurrentRecipe: true);
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

          // Existing Ingredients Display (Read-only)
          if (_selectedRecipe != null)
            _buildExistingIngredientsDisplay(context),
          if (_selectedRecipe != null)
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

  /// Read-only recipe metadata display (collapsible)
  Widget _buildRecipeMetadataDisplay(
      BuildContext context, AppLocalizations localizations) {
    if (_selectedRecipe == null) return const SizedBox.shrink();

    final recipe = _selectedRecipe!;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact header (always visible)
          InkWell(
            onTap: () {
              setState(() {
                _isMetadataExpanded = !_isMetadataExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Recipe name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        // Category badge (compact)
                        Chip(
                          avatar: const Icon(Icons.category, size: 16),
                          label: Text(
                            recipe.category.getLocalizedDisplayName(context),
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withValues(alpha: 0.5),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      ],
                    ),
                  ),
                  // Expand/collapse button
                  IconButton(
                    icon: Icon(
                      _isMetadataExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                    ),
                    tooltip: _isMetadataExpanded
                        ? 'Hide details'
                        : 'Show details',
                    onPressed: () {
                      setState(() {
                        _isMetadataExpanded = !_isMetadataExpanded;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // Expanded metadata (conditionally visible)
          if (_isMetadataExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 12),

                  // Metadata Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
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
                          label:
                              Text('${localizations.rating}: ${recipe.rating}/5'),
                          backgroundColor: Colors.amber.withValues(alpha: 0.3),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Times (compact format)
                  Row(
                    children: [
                      Icon(Icons.schedule,
                          size: 18, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Prep: ${recipe.prepTimeMinutes}m  •  Cook: ${recipe.cookTimeMinutes}m',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

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
                          'Status: Incomplete recipe',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Display existing recipe ingredients (read-only)
  Widget _buildExistingIngredientsDisplay(BuildContext context) {
    if (_selectedRecipe == null) return const SizedBox.shrink();

    // Show loading state
    if (_isLoadingIngredients) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(
                'Loading existing ingredients...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    // If no existing ingredients, show a message
    if (_existingIngredients.isEmpty) {
      return Card(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No ingredients yet. Add ingredients below to get started.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Display existing ingredients
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Current Ingredients (${_existingIngredients.length}) - Already in Recipe',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Ingredient list
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _existingIngredients.map((ingredientMap) {
                  final name = ingredientMap['name'] as String? ?? 'Unknown';
                  final quantity = ingredientMap['quantity'] as double? ?? 0.0;
                  final unit = ingredientMap['unit'] as String?;
                  final category = ingredientMap['category'] as String? ?? 'other';

                  // Format quantity display
                  final quantityStr = formatQuantity(quantity);
                  final quantityDisplay = quantityStr.isNotEmpty
                      ? '$quantityStr${unit != null ? ' $unit' : ''}'
                      : 'to taste';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 8, color: Colors.green),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '$name ($quantityDisplay)',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        // Category badge
                        Chip(
                          label: Text(
                            _getCategoryDisplayName(category),
                            style: const TextStyle(fontSize: 11),
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .secondaryContainer
                              .withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper to get category display name from string value
  String _getCategoryDisplayName(String categoryValue) {
    try {
      final category = IngredientCategory.values.firstWhere(
        (c) => c.value == categoryValue,
        orElse: () => IngredientCategory.other,
      );
      return category.displayName;
    } catch (e) {
      return 'Other';
    }
  }

  /// Format quantity for display
  /// Whole numbers show without decimal (1 not 1.0)
  /// Decimal numbers keep their decimals (1.5 stays 1.5)
  String formatQuantity(double quantity) {
    if (quantity == 0) {
      return ''; // Empty for "to taste" ingredients
    }

    // Check if it's a whole number
    if (quantity == quantity.toInt()) {
      return quantity.toInt().toString(); // "1" not "1.0"
    }

    // Keep decimals for fractional quantities
    return quantity.toString(); // "1.5" stays "1.5"
  }

  /// Build summary text showing existing and new ingredient counts
  String _buildIngredientSummary() {
    final existingCount = _existingIngredients.length;
    final newCount = _parsedIngredients.where((p) => p.selectedMatch != null).length;
    final unmatchedCount = _parsedIngredients.where((p) => p.name.trim().isNotEmpty && p.selectedMatch == null).length;

    final parts = <String>[];

    if (existingCount > 0) {
      parts.add('$existingCount existing ingredient${existingCount != 1 ? "s" : ""}');
    }

    if (newCount > 0) {
      parts.add('adding $newCount new');
    }

    if (unmatchedCount > 0) {
      parts.add('$unmatchedCount unmatched (need selection)');
    }

    if (parts.isEmpty) {
      return 'No ingredients to save';
    }

    return parts.join(', ');
  }

  /// Ingredients section with parsing and editing (Issue #162)
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
                Icon(Icons.list_alt, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Ingredients',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Raw ingredient input
            TextField(
              controller: _rawIngredientsController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Paste ingredient list (one per line)',
                hintText: '200g flour\n2 cups milk\n3 eggs\nSalt to taste',
                border: OutlineInputBorder(),
                helperText: 'Supports PT/EN formats: "200g farinha", "2 xícaras leite", etc.',
                helperMaxLines: 2,
              ),
              onChanged: (_) => _parseIngredients(),
            ),
            const SizedBox(height: 16),

            // Parse button
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _parseIngredients,
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('Parse Ingredients'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _addIngredientRow,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Row'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Parsed ingredients table
            if (_parsedIngredients.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Parsed Ingredients (${_parsedIngredients.length})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),

              // Ingredient rows
              ..._parsedIngredients.asMap().entries.map((entry) {
                final index = entry.key;
                final ingredient = entry.value;
                return _buildIngredientRow(context, index, ingredient);
              }),
              const SizedBox(height: 16),

              // Summary: existing and new ingredient counts
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _buildIngredientSummary(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveIngredients,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save Ingredients'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build a single ingredient row for editing
  Widget _buildIngredientRow(BuildContext context, int index, _ParsedIngredient ingredient) {
    // Determine match status colors
    Color matchColor = Colors.grey;
    IconData matchIcon = Icons.help_outline;
    String matchText = 'No match';

    if (ingredient.selectedMatch != null) {
      switch (ingredient.selectedMatch!.confidenceLevel) {
        case MatchConfidence.high:
          matchColor = Colors.green;
          matchIcon = Icons.check_circle;
          matchText = 'High confidence';
          break;
        case MatchConfidence.medium:
          matchColor = Colors.orange;
          matchIcon = Icons.warning_amber;
          matchText = 'Medium confidence';
          break;
        case MatchConfidence.low:
          matchColor = Colors.red;
          matchIcon = Icons.error_outline;
          matchText = 'Low confidence';
          break;
      }
    } else if (ingredient.matches.isNotEmpty) {
      // Has matches but none auto-selected - show based on best match
      final bestMatch = ingredient.matches.first;
      matchColor = _getMatchColor(bestMatch.confidenceLevel);
      matchIcon = _getMatchIcon(bestMatch.confidenceLevel);
      matchText = '${ingredient.matches.length} match${ingredient.matches.length > 1 ? "es" : ""} found - select one';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Quantity, Unit, Name, Delete
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quantity field
                SizedBox(
                  width: 80,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Qty',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    controller: TextEditingController(
                      text: formatQuantity(ingredient.quantity),
                    ),
                    onChanged: (value) {
                      final qty = double.tryParse(value) ?? 0.0;
                      _updateIngredient(index, quantity: qty);
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // Unit field
                SizedBox(
                  width: 80,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    controller: TextEditingController(text: ingredient.unit ?? ''),
                    onChanged: (value) {
                      _updateIngredient(index, unit: value.isEmpty ? null : value);
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // Name field
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Ingredient Name',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    controller: TextEditingController(text: ingredient.name),
                    onChanged: (value) {
                      _updateIngredient(index, name: value);
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // Remove button
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeIngredientAt(index),
                  tooltip: 'Remove',
                ),
              ],
            ),

            // Notes field (descriptors like "pequena", "maduro", etc.)
            if (ingredient.notes != null || ingredient.selectedMatch != null) ...[
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Notes (descriptors)',
                  hintText: 'e.g., pequena, maduro, picado',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  isDense: true,
                ),
                controller: TextEditingController(text: ingredient.notes ?? ''),
                onChanged: (value) {
                  _updateIngredient(index, notes: value.isEmpty ? null : value);
                },
              ),
            ],

            // Match indicator row
            if (ingredient.name.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: matchColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: matchColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Match status indicator
                    Row(
                      children: [
                        Icon(matchIcon, color: matchColor, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          matchText,
                          style: TextStyle(
                            color: matchColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        if (ingredient.selectedMatch != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '→ ${ingredient.selectedMatch!.ingredient.name}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(
                              ingredient.selectedMatch!.ingredient.category.displayName,
                              style: const TextStyle(fontSize: 10),
                            ),
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .secondaryContainer
                                .withValues(alpha: 0.5),
                          ),
                        ],
                      ],
                    ),

                    // Dropdown for match selection if multiple matches
                    // (single matches are auto-selected and shown in the name field)
                    if (ingredient.matches.length > 1) ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<IngredientMatch>(
                        value: ingredient.selectedMatch,
                        hint: Text(
                          'Select one of ${ingredient.matches.length} matches',
                          style: const TextStyle(fontSize: 12),
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Select match',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          isDense: true,
                        ),
                        items: ingredient.matches.map((match) {
                          return DropdownMenuItem<IngredientMatch>(
                            value: match,
                            child: Row(
                              children: [
                                Icon(
                                  _getMatchIcon(match.confidenceLevel),
                                  size: 16,
                                  color: _getMatchColor(match.confidenceLevel),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${match.ingredient.name} (${match.ingredient.category.displayName}) - ${(match.confidence * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (match) {
                          _updateIngredient(index, selectedMatch: match);
                        },
                        isExpanded: true,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Helper to get match indicator color
  Color _getMatchColor(MatchConfidence confidence) {
    switch (confidence) {
      case MatchConfidence.high:
        return Colors.green;
      case MatchConfidence.medium:
        return Colors.orange;
      case MatchConfidence.low:
        return Colors.red;
    }
  }

  /// Helper to get match indicator icon
  IconData _getMatchIcon(MatchConfidence confidence) {
    switch (confidence) {
      case MatchConfidence.high:
        return Icons.check_circle;
      case MatchConfidence.medium:
        return Icons.warning_amber;
      case MatchConfidence.low:
        return Icons.error_outline;
    }
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
              'Progress: ${(_selectedRecipeIndex ?? 0) + 1} of ${_recipesNeedingIngredients.length} incomplete recipes',
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

/// Helper class to represent a parsed ingredient before saving to database
class _ParsedIngredient {
  double quantity;
  String? unit;
  String name;
  IngredientCategory category;
  String? notes; // Descriptors like "pequena", "maduro", "picado"

  // Matching information
  List<IngredientMatch> matches;
  IngredientMatch? selectedMatch; // User-selected or auto-selected match

  _ParsedIngredient({
    required this.quantity,
    this.unit,
    required this.name,
    required this.category,
    this.notes,
    this.matches = const [],
    this.selectedMatch,
  });
}
