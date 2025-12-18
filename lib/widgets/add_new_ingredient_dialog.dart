import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../models/ingredient_category.dart';
import '../models/measurement_unit.dart';
import '../models/protein_type.dart';
import '../database/database_helper.dart';
import '../utils/id_generator.dart';
import '../core/errors/gastrobrain_exceptions.dart';
import '../core/validators/entity_validator.dart';
import '../core/services/snackbar_service.dart';
import '../core/di/service_provider.dart';
import '../l10n/app_localizations.dart';

class AddNewIngredientDialog extends StatefulWidget {
  final DatabaseHelper? databaseHelper;
  final Ingredient? ingredient;

  const AddNewIngredientDialog({
    super.key,
    this.databaseHelper,
    this.ingredient,
  });

  @override
  State<AddNewIngredientDialog> createState() => _AddNewIngredientDialogState();
}

class _AddNewIngredientDialogState extends State<AddNewIngredientDialog> {
  late DatabaseHelper _dbHelper;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  IngredientCategory _selectedCategory = IngredientCategory.vegetable;
  MeasurementUnit? _selectedUnit;
  ProteinType? _selectedProteinType;
  bool _isSaving = false;

  final List<IngredientCategory> _categories = IngredientCategory.values;

  final List<MeasurementUnit> _units = MeasurementUnit.values;

  @override
  void initState() {
    super.initState();
    // Use the injected database helper or get one from ServiceProvider
    _dbHelper = widget.databaseHelper ?? ServiceProvider.database.dbHelper;

    // Pre-fill form if editing an existing ingredient
    if (widget.ingredient != null) {
      _nameController.text = widget.ingredient!.name;
      _notesController.text = widget.ingredient!.notes ?? '';
      _selectedCategory = widget.ingredient!.category;
      _selectedUnit = widget.ingredient!.unit;
      _selectedProteinType = widget.ingredient!.proteinType;
    }
  }

  Future<void> _saveIngredient() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Validate ingredient data
      EntityValidator.validateIngredient(
        id: widget.ingredient?.id ?? IdGenerator.generateId(),
        name: _nameController.text,
        category: _selectedCategory,
        unit: _selectedUnit,
        proteinType: _selectedProteinType,
      );

      final ingredient = Ingredient(
        id: widget.ingredient?.id ?? IdGenerator.generateId(),
        name: _nameController.text,
        category: _selectedCategory,
        unit: _selectedUnit,
        proteinType: _selectedProteinType,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (widget.ingredient != null) {
        await _dbHelper.updateIngredient(ingredient);
      } else {
        await _dbHelper.insertIngredient(ingredient);
      }

      if (mounted) {
        Navigator.pop(context, ingredient);
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
        SnackbarService.showError(context,
            '${AppLocalizations.of(context)!.errorSavingRecipe} ${e.message}');
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.showError(
            context, AppLocalizations.of(context)!.unexpectedError);
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
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.ingredient != null
          ? AppLocalizations.of(context)!.editIngredient
          : AppLocalizations.of(context)!.newIngredient),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('add_new_ingredient_name_field'),
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.ingredientName,
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

              // Category Dropdown
              DropdownButtonFormField<IngredientCategory>(
                key: const Key('add_new_ingredient_category_field'),
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.categoryLabel,
                  border: const OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.getLocalizedDisplayName(context)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                    if (value != IngredientCategory.protein) {
                      _selectedProteinType = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // Unit Dropdown
              DropdownButtonFormField<MeasurementUnit?>(
                key: const Key('add_new_ingredient_unit_field'),
                initialValue: _selectedUnit,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.unitOptional,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem<MeasurementUnit?>(
                    value: null,
                    child: Text(AppLocalizations.of(context)!.noUnit),
                  ),
                  ..._units.map((unit) {
                    return DropdownMenuItem(
                      value: unit,
                      child: Text(unit.getLocalizedDisplayName(context)),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedUnit = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Protein Type (only shown for protein category)
              if (_selectedCategory == IngredientCategory.protein)
                DropdownButtonFormField<ProteinType>(
                  key: const Key('add_new_ingredient_protein_type_field'),
                  initialValue: _selectedProteinType,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.proteinTypeLabel,
                    border: const OutlineInputBorder(),
                  ),
                  items: ProteinType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.getLocalizedDisplayName(context)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProteinType = value;
                    });
                  },
                  validator: (value) {
                    if (_selectedCategory == IngredientCategory.protein &&
                        value == null) {
                      return AppLocalizations.of(context)!
                          .pleaseSelectProteinType;
                    }
                    return null;
                  },
                ),

              if (_selectedCategory == IngredientCategory.protein)
                const SizedBox(height: 16),

              // Notes
              TextFormField(
                key: const Key('add_new_ingredient_notes_field'),
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.notesOptional,
                  border: const OutlineInputBorder(),
                  hintText:
                      AppLocalizations.of(context)!.anyAdditionalInformation,
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
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveIngredient,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.ingredient != null
                  ? AppLocalizations.of(context)!.saveChanges
                  : AppLocalizations.of(context)!.save),
        ),
      ],
    );
  }
}
