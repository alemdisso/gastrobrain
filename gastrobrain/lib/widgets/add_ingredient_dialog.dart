import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/ingredient.dart';
import '../models/recipe_ingredient.dart';
//import '../models/protein_type.dart';
import '../database/database_helper.dart';
import 'add_new_ingredient_dialog.dart';
import '../utils/id_generator.dart';
import '../core/errors/gastrobrain_exceptions.dart';
import '../core/validators/entity_validator.dart';
import '../core/services/snackbar_service.dart';

class AddIngredientDialog extends StatefulWidget {
  final Recipe recipe;
  final Function(RecipeIngredient)? onSave;
  final Map<String, dynamic>? existingIngredient;
  final String? recipeIngredientId;

  const AddIngredientDialog({
    super.key,
    required this.recipe,
    this.onSave,
    this.existingIngredient,
    this.recipeIngredientId,
  }) : super();

  @override
  State<AddIngredientDialog> createState() => _AddIngredientDialogState();
}

class _AddIngredientDialogState extends State<AddIngredientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();
  List<Ingredient> _filteredIngredients = [];
  String? _selectedUnitOverride;
  bool _useCustomUnit = false;
  List<Ingredient> _availableIngredients = [];
  Ingredient? _selectedIngredient;
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _units = [
    'g',
    'kg',
    'ml',
    'l',
    'cup',
    'tbsp',
    'tsp',
    'piece',
    'slice'
  ];

  final List<String> _categories = [
    'vegetable',
    'fruit',
    'protein',
    'dairy',
    'grain',
    'pulse',
    'nuts_and_seeds',
    'seasoning',
    'sugar products',
    'other'
  ];

  // New controller for custom ingredients
  final _customNameController = TextEditingController();

  bool _isCustomIngredient = false;
  String _selectedCategory = 'vegetable';

  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    if (widget.existingIngredient != null) {
      // Pre-fill the form with existing values
      _quantityController.text =
          widget.existingIngredient!['quantity'].toString();
      _notesController.text =
          widget.existingIngredient!['preparation_notes'] ?? '';

      // Check if this is a custom ingredient
      if (widget.existingIngredient!['custom_name'] != null) {
        setState(() {
          _isCustomIngredient = true;
          _customNameController.text =
              widget.existingIngredient!['custom_name'];
          _selectedCategory = widget.existingIngredient!['custom_category'];
          _selectedUnitOverride = widget.existingIngredient!['custom_unit'];
          _isLoading = false; // Set loading to false for custom ingredients
        });
      } else {
        // Initialize unit override if it exists
        if (widget.existingIngredient!['unit_override'] != null) {
          _useCustomUnit = true;
          _selectedUnitOverride = widget.existingIngredient!['unit_override'];
        }

        // We'll need to set the selected ingredient after loading the ingredients list
        _loadIngredients().then((_) {
          if (mounted) {
            setState(() {
              _selectedIngredient = _availableIngredients.firstWhere(
                (i) => i.id == widget.existingIngredient!['id'],
                orElse: () => _availableIngredients.first,
              );
            });
          }
        });
      }
    } else {
      _loadIngredients();
    }
  }

  String _formatCategoryName(String category) {
    // Convert snake_case to Title Case
    if (category.contains('_')) {
      return category
          .split('_')
          .map((word) => word[0].toUpperCase() + word.substring(1))
          .join(' ');
    }
    // Simple capitalization for single words
    return category[0].toUpperCase() + category.substring(1);
  }

  Future<void> _addIngredientToRecipe() async {
    if (!_formKey.currentState!.validate() ||
        (!_isCustomIngredient && _selectedIngredient == null)) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      RecipeIngredient recipeIngredient;

      if (_isCustomIngredient) {
        // Create custom ingredient
        recipeIngredient = RecipeIngredient(
          id: widget.recipeIngredientId ?? IdGenerator.generateId(),
          recipeId: widget.recipe.id,
          ingredientId: null, // No reference to ingredients table
          quantity: double.parse(_quantityController.text),
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          customName: _customNameController.text,
          customCategory: _selectedCategory,
          customUnit: _selectedUnitOverride,
        );
      } else {
        // Create regular ingredient with optional unit override
        if (_selectedIngredient == null) {
          throw ValidationException('Please select an ingredient');
        }

        EntityValidator.validateRecipeIngredient(
          ingredientId: _selectedIngredient!.id,
          recipeId: widget.recipe.id,
          quantity: double.parse(_quantityController.text),
        );

        recipeIngredient = RecipeIngredient(
          id: widget.recipeIngredientId ?? IdGenerator.generateId(),
          recipeId: widget.recipe.id,
          ingredientId: _selectedIngredient!.id,
          quantity: double.parse(_quantityController.text),
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          unitOverride: _useCustomUnit ? _selectedUnitOverride : null,
        );
      }

      if (widget.onSave != null) {
        widget.onSave!(recipeIngredient);
        if (mounted) {
          // Return the RecipeIngredient object, not just true
          Navigator.pop(context, recipeIngredient);
        }
      } else {
        if (widget.recipeIngredientId != null) {
          // Update existing recipe ingredient
          await _dbHelper.updateRecipeIngredient(recipeIngredient);
        } else {
          // Add new recipe ingredient
          await _dbHelper.addIngredientToRecipe(recipeIngredient);
        }
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } on ValidationException catch (e) {
      if (mounted) {
        SnackbarService.showError(context, e.message);
      }
    } on DuplicateException catch (e) {
      if (mounted) {
        SnackbarService.showError(context, e.message);
      }
    } on GastrobrainException catch (e) {
      if (mounted) {
        SnackbarService.showError(
            context, 'Error adding ingredient: ${e.message}');
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.showError(context, 'An unexpected error occurred');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _filterIngredients(String query) {
    setState(() {
      if (query.isEmpty) {
        // If search is empty, show all ingredients (but maintain sorting)
        _filteredIngredients = List.from(_availableIngredients);
      } else {
        // Filter ingredients that contain the query (case insensitive)
        _filteredIngredients = _availableIngredients
            .where((ingredient) =>
                ingredient.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _loadIngredients() async {
    setState(() => _isLoading = true);
    try {
      final ingredients = await _dbHelper.getAllIngredients();
      if (mounted) {
        // Sort ingredients alphabetically by name
        ingredients.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        setState(() {
          _availableIngredients = ingredients;
          _isLoading = false;
        });
      }
    } on GastrobrainException catch (e) {
      _showErrorSnackBar('Error loading ingredients: ${e.message}');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _showErrorSnackBar(
          'An unexpected error occurred while loading ingredients');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createNewIngredient() async {
    final newIngredient = await showDialog<Ingredient>(
      context: context,
      builder: (context) => const AddNewIngredientDialog(),
    );

    if (newIngredient != null) {
      setState(() {
        _availableIngredients.add(newIngredient);
        _selectedIngredient = newIngredient;
      });
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    _customNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingIngredient != null
          ? 'Edit Ingredient'
          : 'Add Ingredient'),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Toggle between regular and custom ingredient
                    Row(
                      children: [
                        Expanded(
                          child: SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(
                                value: false,
                                label: Text('From Database'),
                              ),
                              ButtonSegment(
                                value: true,
                                label: Text('Custom'),
                              ),
                            ],
                            selected: {_isCustomIngredient},
                            onSelectionChanged: (Set<bool> selected) {
                              setState(() {
                                _isCustomIngredient = selected.first;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Show either custom ingredient form or regular ingredient selector
                    if (_isCustomIngredient) ...[
                      // Custom Ingredient Name
                      TextFormField(
                        controller: _customNameController,
                        decoration: const InputDecoration(
                          labelText: 'Ingredient Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an ingredient name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Custom Ingredient Category
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(_formatCategoryName(category)),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          if (value != null) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          }
                        },
                      ),
                    ] else ...[
                      Column(
                        children: [
                          // Search field
                          TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              labelText: 'Search Ingredients',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.search),
                              hintText: 'Type to search...',
                            ),
                            onChanged: _filterIngredients,
                          ),
                          const SizedBox(height: 16),
                          // Dropdown with filtered ingredients
                          DropdownButtonFormField<Ingredient>(
                            value: _filteredIngredients
                                    .contains(_selectedIngredient)
                                ? _selectedIngredient
                                : null,
                            decoration: const InputDecoration(
                              labelText: 'Select Ingredient',
                              border: OutlineInputBorder(),
                            ),
                            items: _filteredIngredients.map((ingredient) {
                              return DropdownMenuItem(
                                value: ingredient,
                                child: Text(ingredient.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedIngredient = value;
                              });
                            },
                            validator: (value) {
                              if (!_isCustomIngredient && value == null) {
                                return 'Please select an ingredient';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Create New Ingredient'),
                        onPressed: _createNewIngredient,
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Quantity and Unit Section
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quantity Field
                        Expanded(
                          child: TextFormField(
                            controller: _quantityController,
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a quantity';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Unit Section
                        Expanded(
                          child: _isCustomIngredient
                              // Custom ingredient unit selection
                              ? DropdownButtonFormField<String>(
                                  value: _selectedUnitOverride,
                                  decoration: const InputDecoration(
                                    labelText: 'Unit (Optional)',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: [
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text('No unit'),
                                    ),
                                    ..._units.map((unit) {
                                      return DropdownMenuItem(
                                        value: unit,
                                        child: Text(unit),
                                      );
                                    }),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedUnitOverride = value;
                                    });
                                  },
                                )
                              // Regular ingredient unit with override option
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_useCustomUnit)
                                      DropdownButtonFormField<String>(
                                        value: _selectedUnitOverride,
                                        decoration: const InputDecoration(
                                          labelText: 'Unit',
                                          border: OutlineInputBorder(),
                                        ),
                                        items: _units.map((unit) {
                                          return DropdownMenuItem(
                                            value: unit,
                                            child: Text(unit),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedUnitOverride = value;
                                          });
                                        },
                                      )
                                    else if (_selectedIngredient != null)
                                      SizedBox(
                                        height: 56,
                                        child: InputDecorator(
                                          decoration: const InputDecoration(
                                            labelText: 'Unit',
                                            border: OutlineInputBorder(),
                                          ),
                                          child: Text(
                                            _selectedIngredient?.unit ?? 'N/A',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                      ],
                    ),

                    // Unit Override Option (only for regular ingredients)
                    if (!_isCustomIngredient)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _useCustomUnit,
                              onChanged: (bool? value) {
                                setState(() {
                                  _useCustomUnit = value ?? false;
                                  if (!_useCustomUnit) {
                                    _selectedUnitOverride = null;
                                  }
                                });
                              },
                            ),
                            const Text('Override default unit'),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),
                    // Notes Field
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Preparation Notes (Optional)',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., finely chopped, diced, etc.',
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _addIngredientToRecipe,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  widget.existingIngredient != null ? 'Save Changes' : 'Add'),
        ),
      ],
    );
  }
}
