import 'package:flutter/material.dart';
import '../models/ingredient.dart';
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
  String _selectedCategory = 'vegetable';
  String? _selectedUnit;
  ProteinType? _selectedProteinType;
  bool _isSaving = false;

  final List<String> _categories = [
    'vegetable',
    'fruit',
    'protein', // for meat, fish, eggs
    'dairy',
    'grain', // for cereals like wheat, rice
    'pulse', // for legumes like lentils, beans
    'nuts_and_seeds',
    'seasoning',
    'sugar products', // for sugar, honey, syrups, etc.
    'other'
  ];

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
      if (widget.ingredient!.proteinType != null) {
        _selectedProteinType = ProteinType.values.firstWhere(
          (type) => type.name == widget.ingredient!.proteinType,
          orElse: () => ProteinType.other,
        );
      }
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
        name: _nameController.text,
        category: _selectedCategory,
        unit: _selectedUnit,
        proteinType: _selectedProteinType?.name,
      );

      final ingredient = Ingredient(
        id: widget.ingredient?.id ?? IdGenerator.generateId(),
        name: _nameController.text,
        category: _selectedCategory,
        unit: _selectedUnit,
        proteinType: _selectedProteinType?.name,
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
        SnackbarService.showError(
            context, '${AppLocalizations.of(context)!.errorSavingRecipe} ${e.message}');
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.showError(context, AppLocalizations.of(context)!.unexpectedError);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String formatCategoryName(String category) {
    final l10n = AppLocalizations.of(context)!;
    
    // Map string categories to localized names
    switch (category.toLowerCase()) {
      case 'vegetable':
        return l10n.ingredientCategoryVegetable;
      case 'fruit':
        return l10n.ingredientCategoryFruit;
      case 'protein':
        return l10n.ingredientCategoryProtein;
      case 'dairy':
        return l10n.ingredientCategoryDairy;
      case 'grain':
        return l10n.ingredientCategoryGrain;
      case 'pulse':
        return l10n.ingredientCategoryPulse;
      case 'nuts_and_seeds':
        return l10n.ingredientCategoryNutsAndSeeds;
      case 'seasoning':
        return l10n.ingredientCategorySeasoning;
      case 'sugar products':
        return l10n.ingredientCategorySugarProducts;
      case 'oil':
        return l10n.ingredientCategoryOil;
      case 'other':
        return l10n.ingredientCategoryOther;
      default:
        // Fallback to simple capitalization for unknown categories
        if (category.contains('_')) {
          return category
              .split('_')
              .map((word) => word[0].toUpperCase() + word.substring(1))
              .join(' ');
        }
        return category[0].toUpperCase() + category.substring(1);
    }
  }

  /// Helper method to get localized unit display name
  String getLocalizedUnitName(String unit) {
    final l10n = AppLocalizations.of(context)!;
    
    // Localize descriptive units, keep abbreviations as-is
    switch (unit.toLowerCase()) {
      case 'cup':
        return l10n.measurementUnitCup;
      case 'piece':
        return l10n.measurementUnitPiece;
      case 'slice':
        return l10n.measurementUnitSlice;
      case 'tbsp':
        return l10n.measurementUnitTablespoon;
      case 'tsp':
        return l10n.measurementUnitTeaspoon;
      default:
        return unit; // Keep abbreviations like 'g', 'ml', 'kg', etc.
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
      title: Text(
          widget.ingredient != null 
              ? AppLocalizations.of(context)!.editIngredient 
              : AppLocalizations.of(context)!.newIngredient),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.ingredientName,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.pleaseEnterIngredientName;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.categoryLabel,
                  border: const OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(formatCategoryName(category)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                    if (value != 'protein') {
                      _selectedProteinType = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // Unit Dropdown
              DropdownButtonFormField<String>(
                value: _selectedUnit,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.unitOptional,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text(AppLocalizations.of(context)!.noUnit),
                  ),
                  ..._units.map((unit) {
                    return DropdownMenuItem(
                      value: unit,
                      child: Text(getLocalizedUnitName(unit)),
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
              if (_selectedCategory == 'protein')
                DropdownButtonFormField<ProteinType>(
                  value: _selectedProteinType,
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
                    if (_selectedCategory == 'protein' && value == null) {
                      return AppLocalizations.of(context)!.pleaseSelectProteinType;
                    }
                    return null;
                  },
                ),

              if (_selectedCategory == 'protein') const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.notesOptional,
                  border: const OutlineInputBorder(),
                  hintText: AppLocalizations.of(context)!.anyAdditionalInformation,
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
