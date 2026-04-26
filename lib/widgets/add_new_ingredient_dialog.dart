import 'package:flutter/material.dart';
import '../utils/sorting_utils.dart';
import '../models/ingredient.dart';
import '../models/ingredient_category.dart';
import '../models/measurement_unit.dart';
import '../models/protein_type.dart';
import '../database/database_helper.dart';
import '../utils/id_generator.dart';
import '../core/errors/gastrobrain_exceptions.dart';
import '../core/validators/entity_validator.dart';
import '../core/services/snackbar_service.dart';
import '../core/services/ingredient_duplicate_checker.dart';
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
  final _aliasesController = TextEditingController();
  IngredientCategory _selectedCategory = IngredientCategory.vegetable;
  MeasurementUnit? _selectedUnit;
  ProteinType? _selectedProteinType;
  bool _isSaving = false;

  IngredientDuplicateChecker? _duplicateChecker;
  DuplicateCheckResult _duplicateResult =
      const DuplicateCheckResult(status: DuplicateStatus.none);

  final List<IngredientCategory> _categories = IngredientCategory.values;
  final List<MeasurementUnit> _units = MeasurementUnit.values;

  @override
  void initState() {
    super.initState();
    _dbHelper = widget.databaseHelper ?? ServiceProvider.database.dbHelper;

    if (widget.ingredient != null) {
      _nameController.text = widget.ingredient!.name;
      _notesController.text = widget.ingredient!.notes ?? '';
      _aliasesController.text = widget.ingredient!.aliases.join(', ');
      _selectedCategory = widget.ingredient!.category;
      _selectedUnit = widget.ingredient!.unit;
      _selectedProteinType = widget.ingredient!.proteinType;
    }

    _nameController.addListener(_onNameChanged);
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    final ingredients = await _dbHelper.getAllIngredients();
    if (!mounted) return;
    setState(() {
      _duplicateChecker = IngredientDuplicateChecker(ingredients);
    });
    _onNameChanged();
  }

  void _onNameChanged() {
    if (_duplicateChecker == null) return;
    final result = _duplicateChecker!.check(
      _nameController.text,
      excludeId: widget.ingredient?.id,
    );
    if (mounted) {
      setState(() {
        _duplicateResult = result;
      });
    }
  }

  Future<void> _saveIngredient() async {
    if (!_formKey.currentState!.validate()) return;

    if (_duplicateResult.isExact) {
      SnackbarService.showError(
        context,
        AppLocalizations.of(context)!.ingredientExactDuplicateError(
          _duplicateResult.similarNames.first,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final normalizedName = _nameController.text.trim().toLowerCase();

      EntityValidator.validateIngredient(
        id: widget.ingredient?.id ?? IdGenerator.generateId(),
        name: normalizedName,
        category: _selectedCategory,
        unit: _selectedUnit,
        proteinType: _selectedProteinType,
      );

      final aliases = _aliasesController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final ingredient = Ingredient(
        id: widget.ingredient?.id ?? IdGenerator.generateId(),
        name: normalizedName,
        category: _selectedCategory,
        unit: _selectedUnit,
        proteinType: _selectedProteinType,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        aliases: aliases,
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
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _notesController.dispose();
    _aliasesController.dispose();
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
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!
                        .pleaseEnterIngredientName;
                  }
                  return null;
                },
              ),
              _buildDuplicateFeedback(context),
              const SizedBox(height: 16),

              DropdownButtonFormField<IngredientCategory>(
                key: const Key('add_new_ingredient_category_field'),
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.categoryLabel,
                ),
                items: (_categories.toList()
                      ..sort((a, b) {
                        if (a == IngredientCategory.other) return 1;
                        if (b == IngredientCategory.other) return -1;
                        return SortingUtils.normalizeForSorting(
                                a.getLocalizedDisplayName(context))
                            .compareTo(SortingUtils.normalizeForSorting(
                                b.getLocalizedDisplayName(context)));
                      }))
                    .map((category) {
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

              if (_selectedCategory == IngredientCategory.protein)
                DropdownButtonFormField<ProteinType>(
                  key: const Key('add_new_ingredient_protein_type_field'),
                  initialValue: _selectedProteinType,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.proteinTypeLabel,
                  ),
                  items: ProteinType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.getLocalizedDisplayName(context)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedProteinType = value);
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

              DropdownButtonFormField<MeasurementUnit?>(
                key: const Key('add_new_ingredient_unit_field'),
                initialValue: _selectedUnit,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.unitOptional,
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
                  setState(() => _selectedUnit = value);
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                key: const Key('add_new_ingredient_notes_field'),
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.notesOptional,
                  hintText:
                      AppLocalizations.of(context)!.anyAdditionalInformation,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              TextFormField(
                key: const Key('add_new_ingredient_aliases_field'),
                controller: _aliasesController,
                decoration: InputDecoration(
                  labelText:
                      AppLocalizations.of(context)!.ingredientAliasesLabel,
                  hintText:
                      AppLocalizations.of(context)!.ingredientAliasesHint,
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

  Widget _buildDuplicateFeedback(BuildContext context) {
    if (_duplicateResult.isExact) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline,
                color: Theme.of(context).colorScheme.error, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.ingredientExactDuplicateError(
                  _duplicateResult.similarNames.first,
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_duplicateResult.hasSimilar) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: Colors.amber, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.ingredientSimilarSuggestion(
                  _duplicateResult.similarNames.join(', '),
                ),
                style: const TextStyle(color: Colors.amber, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
