// lib/widgets/edit_meal_recording_dialog.dart

import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/meal.dart';
import '../database/database_helper.dart';
import '../core/validators/entity_validator.dart';
import '../l10n/app_localizations.dart';

class EditMealRecordingDialog extends StatefulWidget {
  final Meal meal;
  final Recipe primaryRecipe;
  final List<Recipe> additionalRecipes;

  const EditMealRecordingDialog({
    super.key,
    required this.meal,
    required this.primaryRecipe,
    this.additionalRecipes = const [],
  });

  @override
  State<EditMealRecordingDialog> createState() =>
      _EditMealRecordingDialogState();
}

class _EditMealRecordingDialogState extends State<EditMealRecordingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _servingsController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _cookTimeController = TextEditingController();
  late bool _wasSuccessful;
  late DateTime _cookedAt;

  final List<Recipe> _additionalRecipes = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Recipe> _availableRecipes = [];
  bool _isLoadingRecipes = false;

  @override
  void initState() {
    super.initState();

    // Pre-populate fields with existing meal data
    _notesController.text = widget.meal.notes;
    _servingsController.text = widget.meal.servings.toString();
    _prepTimeController.text = widget.meal.actualPrepTime.toString();
    _cookTimeController.text = widget.meal.actualCookTime.toString();
    _wasSuccessful = widget.meal.wasSuccessful;
    _cookedAt = widget.meal.cookedAt;

    // Pre-populate additional recipes
    _additionalRecipes.addAll(widget.additionalRecipes);

    // Load available recipes for modification
    _loadAvailableRecipes();
  }

  Future<void> _loadAvailableRecipes() async {
    setState(() {
      _isLoadingRecipes = true;
    });

    try {
      final recipes = await _dbHelper.getAllRecipes();
      if (mounted) {
        setState(() {
          _availableRecipes =
              recipes.where((r) => r.id != widget.primaryRecipe.id).toList();
          _isLoadingRecipes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRecipes = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.errorLoadingRecipes} $e')),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _cookedAt,
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
      );
      if (picked != null && mounted) {
        setState(() {
          _cookedAt = DateTime(
            picked.year,
            picked.month,
            picked.day,
            _cookedAt.hour,
            _cookedAt.minute,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorSelectingDate)),
        );
      }
    }
  }

  Future<void> _showAddRecipeDialog() async {
    if (_availableRecipes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.noAdditionalRecipesAvailable)),
      );
      return;
    }

    final selectedRecipe = await showDialog<Recipe>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Recipe'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select a recipe to add as a side dish:'),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                width: double.maxFinite,
                child: ListView.builder(
                  itemCount: _availableRecipes.length,
                  itemBuilder: (context, index) {
                    final recipe = _availableRecipes[index];
                    // Skip recipes already added
                    if (_additionalRecipes.any((r) => r.id == recipe.id)) {
                      return const SizedBox.shrink();
                    }
                    return ListTile(
                      title: Text(recipe.name),
                      onTap: () => Navigator.of(context).pop(recipe),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedRecipe != null && mounted) {
      setState(() {
        _additionalRecipes.add(selectedRecipe);
      });
    }
  }

  void _saveChanges() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final servings = int.parse(_servingsController.text);
      EntityValidator.validateServings(servings);

      final prepTime = double.tryParse(_prepTimeController.text);
      final cookTime = double.tryParse(_cookTimeController.text);

      EntityValidator.validateTime(prepTime, 'Preparation');
      EntityValidator.validateTime(cookTime, 'Cooking');

      // Return the updated meal data
      Navigator.of(context).pop({
        'mealId': widget.meal.id,
        'cookedAt': _cookedAt,
        'servings': servings,
        'notes': _notesController.text,
        'wasSuccessful': _wasSuccessful,
        'actualPrepTime': prepTime ?? 0.0,
        'actualCookTime': cookTime ?? 0.0,
        'primaryRecipe': widget.primaryRecipe,
        'additionalRecipes': _additionalRecipes,
        'modifiedAt': DateTime.now(),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.errorPrefix} $e')),
      );
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _servingsController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.editMealTitle(widget.primaryRecipe.name)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date section
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  'Cooked on: ${_cookedAt.toString().split('.')[0]}',
                ),
                onTap: _selectDate,
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),

              // Servings
              TextFormField(
                controller: _servingsController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.numberOfServings,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.people),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.pleaseEnterNumberOfServings;
                  }
                  if (int.tryParse(value) == null || int.parse(value) < 1) {
                    return AppLocalizations.of(context)!.pleaseEnterValidNumber;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Recipes section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recipes',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Recipe'),
                        onPressed:
                            _isLoadingRecipes ? null : _showAddRecipeDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Main recipe (always shown, cannot be changed)
                  ListTile(
                    leading: const Icon(Icons.restaurant, color: Colors.green),
                    title: Text(widget.primaryRecipe.name),
                    subtitle: const Text('Main dish'),
                    contentPadding: EdgeInsets.zero,
                  ),

                  // Additional recipes
                  if (_additionalRecipes.isNotEmpty) ...[
                    const Divider(),
                    ...List.generate(_additionalRecipes.length, (index) {
                      final recipe = _additionalRecipes[index];
                      return ListTile(
                        leading: const Icon(Icons.restaurant_menu,
                            color: Colors.grey),
                        title: Text(recipe.name),
                        subtitle: const Text('Side dish'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            setState(() {
                              _additionalRecipes.removeAt(index);
                            });
                          },
                          tooltip: 'Remove',
                        ),
                        contentPadding: EdgeInsets.zero,
                      );
                    }),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Actual times
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _prepTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Prep Time (min)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.timer),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final time = double.tryParse(value);
                          if (time == null || time < 0) {
                            return 'Enter a valid time';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _cookTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Cook Time (min)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.timer),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final time = double.tryParse(value);
                          if (time == null || time < 0) {
                            return 'Enter a valid time';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Success rating
              Row(
                children: [
                  const Text('Was it successful?'),
                  const Spacer(),
                  Switch(
                    value: _wasSuccessful,
                    onChanged: (bool value) {
                      setState(() {
                        _wasSuccessful = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveChanges,
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}
