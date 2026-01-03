import 'dart:math';

import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../models/ingredient_category.dart';
import '../models/measurement_unit.dart';
import '../models/protein_type.dart';
import '../database/database_helper.dart';
import '../widgets/add_new_ingredient_dialog.dart';
import '../core/errors/gastrobrain_exceptions.dart';
import '../core/services/snackbar_service.dart';
import '../l10n/app_localizations.dart';

class IngredientsScreen extends StatefulWidget {
  const IngredientsScreen({super.key});

  @override
  State<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends State<IngredientsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Ingredient> _ingredients = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  /// Helper method to get localized protein type display name
  String? _getLocalizedProteinType(BuildContext context, ProteinType? proteinType) {
    return proteinType?.getLocalizedDisplayName(context);
  }

  /// Helper method to get localized category display name
  String _getLocalizedCategory(BuildContext context, IngredientCategory category) {
    return category.getLocalizedDisplayName(context);
  }

  /// Helper method to get localized unit display name
  String? _getLocalizedUnit(BuildContext context, MeasurementUnit? unit) {
    return unit?.getLocalizedDisplayName(context);
  }

  /// Helper method to build localized ingredient subtitle
  String _buildIngredientSubtitle(BuildContext context, Ingredient ingredient) {
    final List<String> parts = [];
    
    // Add localized category
    parts.add(_getLocalizedCategory(context, ingredient.category));
    
    // Add localized unit if available
    final localizedUnit = _getLocalizedUnit(context, ingredient.unit);
    if (localizedUnit != null) {
      parts.add(localizedUnit);
    }
    
    // Add localized protein type if available
    final localizedProteinType = _getLocalizedProteinType(context, ingredient.proteinType);
    if (localizedProteinType != null) {
      parts.add(localizedProteinType);
    }
    
    return parts.join(' • ');
  }

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
      final ingredients = await _dbHelper.getAllIngredients();
      if (mounted) {
        setState(() {
          // Sort ingredients alphabetically by name
          ingredients.sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          _ingredients = ingredients;
          _isLoading = false;
        });
      }
    } on GastrobrainException catch (e) {
      setState(() {
        _errorMessage = '${AppLocalizations.of(context)!.errorLoadingIngredients} ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.unexpectedErrorLoadingIngredients;
        _isLoading = false;
      });
    }
  }

  Future<void> _editIngredient(Ingredient ingredient) async {
    final result = await showDialog<Ingredient>(
      context: context,
      builder: (context) => AddNewIngredientDialog(
        ingredient: ingredient,
      ),
    );

    if (result != null) {
      _loadIngredients();
    }
  }

  void _addIngredient() async {
    final result = await showDialog<Ingredient>(
      context: context,
      builder: (context) => const AddNewIngredientDialog(),
    );

    if (result != null) {
      _loadIngredients();
    }
  }

  Future<void> _deleteIngredient(Ingredient ingredient) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.deleteIngredient),
          content: Text(AppLocalizations.of(context)!.deleteIngredientConfirmation(ingredient.name)),
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
        await _dbHelper.deleteIngredient(ingredient.id);
        if (mounted) {
          SnackbarService.showSuccess(
              context, AppLocalizations.of(context)!.ingredientDeletedSuccessfully);
          _loadIngredients();
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

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? AppLocalizations.of(context)!.anErrorOccurred,
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

  List<Ingredient> _getFilteredIngredients() {
    if (_searchQuery.isEmpty) {
      return _ingredients;
    }
    return _ingredients
        .where((ingredient) =>
            ingredient.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.ingredients),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadIngredients,
            tooltip: AppLocalizations.of(context)!.refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchIngredients,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorView()
                    : _ingredients.isEmpty
                        ? _buildEmptyView()
                        : ListView.builder(
                            padding: EdgeInsets.only(
                              bottom: max(80.0, MediaQuery.of(context).size.height * 0.3),
                            ),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _getFilteredIngredients().length,
                            itemBuilder: (context, index) {
                              final ingredient =
                                  _getFilteredIngredients()[index];
                              return ListTile(
                                title: Text(ingredient.name),
                                subtitle: Text(
                                  _buildIngredientSubtitle(context, ingredient),
                                ),
                                trailing: PopupMenuButton(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'edit':
                                        _editIngredient(ingredient);
                                        break;
                                      case 'delete':
                                        _deleteIngredient(ingredient);
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
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addIngredient,
        tooltip: AppLocalizations.of(context)!.addIngredient,
        child: const Icon(Icons.add),
      ),
    );
  }
}
