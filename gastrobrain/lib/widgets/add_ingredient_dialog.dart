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
  String? _selectedUnitOverride;
  bool _useCustomUnit = false;

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

  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Ingredient> _availableIngredients = [];
  Ingredient? _selectedIngredient;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingIngredient != null) {
      // Pre-fill the form with existing values
      _quantityController.text =
          widget.existingIngredient!['quantity'].toString();
      _notesController.text =
          widget.existingIngredient!['preparation_notes'] ?? '';

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
    } else {
      _loadIngredients();
    }
  }

  Future<void> _addIngredientToRecipe() async {
    if (!_formKey.currentState!.validate() || _selectedIngredient == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      EntityValidator.validateRecipeIngredient(
        ingredientId: _selectedIngredient!.id,
        recipeId: widget.recipe.id,
        quantity: double.parse(_quantityController.text),
      );

      if (widget.recipeIngredientId != null) {
        // Update existing recipe ingredient
        final updatedRecipeIngredient = RecipeIngredient(
          id: widget.recipeIngredientId!,
          recipeId: widget.recipe.id,
          ingredientId: _selectedIngredient!.id,
          quantity: double.parse(_quantityController.text),
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          unitOverride: _useCustomUnit
              ? _selectedUnitOverride
              : null, // Include unit override
        );

        await _dbHelper.updateRecipeIngredient(updatedRecipeIngredient);
      } else {
        // Create new recipe ingredient
        final recipeIngredient = RecipeIngredient(
          id: IdGenerator.generateId(),
          recipeId: widget.recipe.id,
          ingredientId: _selectedIngredient!.id,
          quantity: double.parse(_quantityController.text),
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );

        if (widget.onSave != null) {
          widget.onSave!(recipeIngredient);
        } else {
          await _dbHelper.addIngredientToRecipe(recipeIngredient);
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
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

  Future<void> _loadIngredients() async {
    setState(() => _isLoading = true);
    try {
      final ingredients = await _dbHelper.getAllIngredients();
      if (mounted) {
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
                    // Ingredient Selection
                    DropdownButtonFormField<Ingredient>(
                      value: _selectedIngredient,
                      decoration: const InputDecoration(
                        labelText: 'Select Ingredient',
                        border: OutlineInputBorder(),
                      ),
                      items: _availableIngredients.map((ingredient) {
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
                        if (value == null) {
                          return 'Please select an ingredient';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Create New Ingredient'),
                      onPressed: _createNewIngredient,
                    ),
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
                          child: Column(
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
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Select a unit';
                                    }
                                    return null;
                                  },
                                )
                              else if (_selectedIngredient != null)
                                SizedBox(
                                  height: 56, // Match TextFormField height
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Unit',
                                      border: OutlineInputBorder(),
                                    ),
                                    child: Text(
                                      _selectedIngredient?.unit ?? 'N/A',
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Unit Override Checkbox
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
                                } else if (_selectedIngredient?.unit != null) {
                                  // Initialize with current unit if available
                                  _selectedUnitOverride =
                                      _selectedIngredient?.unit;
                                }
                              });
                            },
                          ),
                          const Text('Override default unit'),
                          if (!_useCustomUnit &&
                              _selectedIngredient?.unit != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                '(current: ${_selectedIngredient!.unit})',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Preparation Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Preparation Notes (Optional)',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., finely chopped, diced, etc.',
                      ),
                      maxLines: 2,
                    ),

                    if (_selectedIngredient != null) ...[
                      const SizedBox(height: 16),
                      // Ingredient Info Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Category: ${_selectedIngredient!.category}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              if (_selectedIngredient!.proteinType != null)
                                Text(
                                  'Protein Type: ${_selectedIngredient!.proteinType}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              if (_selectedIngredient!.notes?.isNotEmpty ==
                                  true)
                                Text(
                                  'Notes: ${_selectedIngredient!.notes}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
