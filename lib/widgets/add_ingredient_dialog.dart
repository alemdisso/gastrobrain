import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/ingredient.dart';
import '../models/recipe_ingredient.dart';
import '../models/measurement_unit.dart';
import '../models/ingredient_category.dart';
import '../database/database_helper.dart';
import 'add_new_ingredient_dialog.dart';
import '../utils/id_generator.dart';
import '../core/errors/gastrobrain_exceptions.dart';
import '../core/validators/entity_validator.dart';
import '../core/services/snackbar_service.dart';
import '../l10n/app_localizations.dart';
import '../core/di/service_provider.dart';

class AddIngredientDialog extends StatefulWidget {
  final Recipe recipe;
  final Function(RecipeIngredient)? onSave;
  final Map<String, dynamic>? existingIngredient;
  final String? recipeIngredientId;
  final DatabaseHelper? databaseHelper;

  const AddIngredientDialog({
    super.key,
    required this.recipe,
    this.onSave,
    this.existingIngredient,
    this.recipeIngredientId,
    this.databaseHelper,
  }) : super();

  @override
  State<AddIngredientDialog> createState() => _AddIngredientDialogState();
}

class _AddIngredientDialogState extends State<AddIngredientDialog> {
  late DatabaseHelper _dbHelper;
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();
  String? _selectedUnitOverride;
  List<Ingredient> _availableIngredients = [];
  Ingredient? _selectedIngredient;
  bool _isLoading = true;
  bool _isSaving = false;

  final List<MeasurementUnit> _units = MeasurementUnit.values;

  final List<IngredientCategory> _categories = IngredientCategory.values;

  // New controller for custom ingredients
  final _customNameController = TextEditingController();

  bool _isCustomIngredient = false;
  IngredientCategory _selectedCategory = IngredientCategory.vegetable;

  @override
  void initState() {
    super.initState();
    _dbHelper = widget.databaseHelper ?? ServiceProvider.database.dbHelper;
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
          _selectedCategory = IngredientCategory.fromString(widget.existingIngredient!['custom_category'] ?? 'other');
          _selectedUnitOverride = widget.existingIngredient!['custom_unit'];
          _isLoading = false; // Set loading to false for custom ingredients
        });
      } else {
        // Initialize unit override if it exists
        if (widget.existingIngredient!['unit_override'] != null) {
          _selectedUnitOverride = widget.existingIngredient!['unit_override'];
        }

        // We'll need to set the selected ingredient after loading the ingredients list
        _loadIngredients().then((_) {
          if (mounted) {
            setState(() {
              // Find the existing ingredient by ID
              final existingId = widget.existingIngredient!['ingredient_id'];
              final foundIngredient = _availableIngredients
                  .where((i) => i.id == existingId)
                  .firstOrNull;

              if (foundIngredient != null) {
                _selectedIngredient = foundIngredient;
                // Pre-fill search field with ingredient name for autocomplete
                _searchController.text = foundIngredient.name;
              } else {
                // If ingredient not found, leave _selectedIngredient as null
                _selectedIngredient = null;
              }
            });
          }
        });
      }
    } else {
      _loadIngredients();
    }
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
          customCategory: _selectedCategory.value,
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

        // Detect if unit was changed from ingredient's default
        final defaultUnit = _selectedIngredient!.unit?.value;
        final selectedUnit = _selectedUnitOverride;
        final unitOverride = (selectedUnit != null && selectedUnit != defaultUnit)
            ? selectedUnit
            : null;

        recipeIngredient = RecipeIngredient(
          id: widget.recipeIngredientId ?? IdGenerator.generateId(),
          recipeId: widget.recipe.id,
          ingredientId: _selectedIngredient!.id,
          quantity: double.parse(_quantityController.text),
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          unitOverride: unitOverride,
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
      builder: (context) => AddNewIngredientDialog(
        databaseHelper: _dbHelper, // Pass the database helper
      ),
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
          ? AppLocalizations.of(context)!.editIngredient
          : AppLocalizations.of(context)!.addIngredient),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Show either custom ingredient form or regular ingredient selector
                    if (_isCustomIngredient) ...[
                      // Custom Ingredient Name
                      TextFormField(
                        controller: _customNameController,
                        decoration: InputDecoration(
                          labelText:
                              AppLocalizations.of(context)!.ingredientName,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!
                                .pleaseEnterIngredientName;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Custom Ingredient Category
                      DropdownButtonFormField<IngredientCategory>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText:
                              AppLocalizations.of(context)!.categoryLabel,
                          border: const OutlineInputBorder(),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(
                              category.getLocalizedDisplayName(context),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (IngredientCategory? value) {
                          if (value != null) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          }
                        },
                      ),
                    ] else ...[
                      // Unified ingredient search with autocomplete
                      Autocomplete<Ingredient>(
                        displayStringForOption: (Ingredient ingredient) => ingredient.name,
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return _availableIngredients;
                          }
                          return _availableIngredients.where((ingredient) {
                            return ingredient.name
                                .toLowerCase()
                                .contains(textEditingValue.text.toLowerCase());
                          });
                        },
                        onSelected: (Ingredient selection) {
                          setState(() {
                            _selectedIngredient = selection;
                          });
                        },
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          // Sync with our search controller
                          if (_searchController.text != controller.text) {
                            _searchController.text = controller.text;
                          }
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.ingredientLabel,
                              hintText: AppLocalizations.of(context)!.searchOrCreateIngredient,
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.search),
                            ),
                            validator: (value) {
                              if (_selectedIngredient == null) {
                                return AppLocalizations.of(context)!.pleaseSelectAnIngredient;
                              }
                              return null;
                            },
                          );
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          final optionsList = options.toList();
                          final searchTerm = _searchController.text;
                          final hasExactMatch = optionsList.any(
                            (ing) => ing.name.toLowerCase() == searchTerm.toLowerCase()
                          );

                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4.0,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: optionsList.length + (searchTerm.isNotEmpty && !hasExactMatch ? 2 : 0),
                                  itemBuilder: (context, index) {
                                    // Show ingredients first
                                    if (index < optionsList.length) {
                                      final ingredient = optionsList[index];
                                      return ListTile(
                                        title: Text(ingredient.name),
                                        onTap: () {
                                          onSelected(ingredient);
                                        },
                                      );
                                    }
                                    // Show divider
                                    else if (index == optionsList.length) {
                                      return const Divider();
                                    }
                                    // Show "Create new" option
                                    else {
                                      return ListTile(
                                        leading: const Icon(Icons.add, size: 20),
                                        title: Text(
                                          AppLocalizations.of(context)!.createAsNew(searchTerm),
                                          style: TextStyle(
                                            color: Theme.of(context).primaryColor,
                                          ),
                                        ),
                                        onTap: () async {
                                          // Close autocomplete
                                          FocusScope.of(context).unfocus();
                                          // Open create new dialog
                                          await _createNewIngredient();
                                        },
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),
                          );
                        },
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
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.quantity,
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppLocalizations.of(context)!
                                    .pleaseEnterQuantity;
                              }
                              if (double.tryParse(value) == null) {
                                return AppLocalizations.of(context)!
                                    .pleaseEnterValidNumber;
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Unit Section
                        Expanded(
                          child: _isCustomIngredient
                              // Custom ingredient: optional unit selection
                              ? DropdownButtonFormField<String>(
                                  value: _selectedUnitOverride,
                                  decoration: InputDecoration(
                                    labelText: AppLocalizations.of(context)!
                                        .unitOptional,
                                    border: const OutlineInputBorder(),
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: null,
                                      child: Text(
                                          AppLocalizations.of(context)!.noUnit),
                                    ),
                                    ..._units.map((unit) {
                                      return DropdownMenuItem(
                                        value: unit.value,
                                        child: Text(unit.getLocalizedDisplayName(context)),
                                      );
                                    }),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedUnitOverride = value;
                                    });
                                  },
                                )
                              // Database ingredient: always show dropdown, pre-filled with default
                              : DropdownButtonFormField<String>(
                                  value: _selectedUnitOverride ?? _selectedIngredient?.unit?.value,
                                  decoration: InputDecoration(
                                    labelText: AppLocalizations.of(context)!.unit,
                                    border: const OutlineInputBorder(),
                                  ),
                                  items: _units.map((unit) {
                                    return DropdownMenuItem(
                                      value: unit.value,
                                      child: Text(unit.getLocalizedDisplayName(context)),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedUnitOverride = value;
                                    });
                                  },
                                ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    // Notes Field
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!
                            .preparationNotesOptional,
                        border: const OutlineInputBorder(),
                        hintText:
                            AppLocalizations.of(context)!.preparationNotesHint,
                      ),
                      maxLines: 2,
                    ),

                    // Progressive disclosure: Link to switch to custom ingredient mode
                    if (!_isCustomIngredient)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: TextButton.icon(
                          icon: const Icon(Icons.settings, size: 20),
                          label: Text(
                            AppLocalizations.of(context)!.useCustomIngredient,
                          ),
                          onPressed: () {
                            setState(() {
                              _isCustomIngredient = true;
                            });
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _addIngredientToRecipe,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.existingIngredient != null
                  ? AppLocalizations.of(context)!.saveChanges
                  : AppLocalizations.of(context)!.add),
        ),
      ],
    );
  }
}
