// lib/widgets/edit_meal_recording_dialog.dart

import 'dart:math';

import 'package:flutter/material.dart';
import '../models/meal_recipe.dart';
import '../models/recipe.dart';
import '../models/meal.dart';
import '../database/database_helper.dart';
import '../core/validators/entity_validator.dart';
import '../core/di/service_provider.dart';
import '../utils/sorting_utils.dart';
import '../l10n/app_localizations.dart';
import 'servings_stepper.dart';

class EditMealRecordingDialog extends StatefulWidget {
  final Meal meal;
  final Recipe primaryRecipe;
  final List<Recipe> additionalRecipes;
  final List<MealRecipe> mealRecipes;
  final DatabaseHelper? databaseHelper;

  const EditMealRecordingDialog({
    super.key,
    required this.meal,
    required this.primaryRecipe,
    this.additionalRecipes = const [],
    this.mealRecipes = const [],
    this.databaseHelper,
  });

  @override
  State<EditMealRecordingDialog> createState() =>
      _EditMealRecordingDialogState();
}

class _EditMealRecordingDialogState extends State<EditMealRecordingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _cookTimeController = TextEditingController();
  late int _servings;
  late bool _wasSuccessful;
  late DateTime _cookedAt;

  final List<Recipe> _additionalRecipes = [];
  final Map<String, TextEditingController> _recipeNoteControllers = {};
  late final DatabaseHelper _dbHelper;
  List<Recipe> _availableRecipes = [];
  bool _isLoadingRecipes = false;

  @override
  void initState() {
    super.initState();

    // Initialize database helper using dependency injection
    _dbHelper = widget.databaseHelper ?? ServiceProvider.database.dbHelper;

    // Pre-populate fields with existing meal data
    _notesController.text = widget.meal.notes;
    _servings = max(1, widget.meal.servings);
    _prepTimeController.text = widget.meal.actualPrepTime.toString();
    _cookTimeController.text = widget.meal.actualCookTime.toString();
    _wasSuccessful = widget.meal.wasSuccessful;
    _cookedAt = widget.meal.cookedAt;

    // Initialise per-recipe note controllers, pre-filled from existing MealRecipe.notes
    final notesByRecipeId = {
      for (final mr in widget.mealRecipes) mr.recipeId: mr.notes ?? '',
    };
    _recipeNoteControllers[widget.primaryRecipe.id] =
        TextEditingController(text: notesByRecipeId[widget.primaryRecipe.id] ?? '');

    // Pre-populate additional recipes
    _additionalRecipes.addAll(widget.additionalRecipes);
    for (final r in widget.additionalRecipes) {
      _recipeNoteControllers[r.id] =
          TextEditingController(text: notesByRecipeId[r.id] ?? '');
    }

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
          final filtered =
              recipes.where((r) => r.id != widget.primaryRecipe.id).toList();
          _availableRecipes = SortingUtils.sortByName(filtered, (r) => r.name);
          _isLoadingRecipes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRecipes = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${AppLocalizations.of(context)!.errorLoadingRecipes} $e')),
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
          SnackBar(
              content: Text(AppLocalizations.of(context)!.errorSelectingDate)),
        );
      }
    }
  }

  Future<void> _showAddRecipeDialog() async {
    if (_availableRecipes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context)!.noAdditionalRecipesAvailable)),
      );
      return;
    }

    final selectedRecipe = await showDialog<Recipe>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.addRecipeDialog),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.selectRecipeToAddAsSideDish),
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
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
      ),
    );

    if (selectedRecipe != null && mounted) {
      setState(() {
        _additionalRecipes.add(selectedRecipe);
        _recipeNoteControllers[selectedRecipe.id] = TextEditingController();
      });
    }
  }

  void _removeAdditionalRecipe(int index) {
    setState(() {
      final recipe = _additionalRecipes[index];
      _recipeNoteControllers.remove(recipe.id)?.dispose();
      _additionalRecipes.removeAt(index);
    });
  }

  void _saveChanges() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final prepTime = double.tryParse(_prepTimeController.text);
      final cookTime = double.tryParse(_cookTimeController.text);

      EntityValidator.validateTime(
          prepTime, AppLocalizations.of(context)!.preparationTime);
      EntityValidator.validateTime(
          cookTime, AppLocalizations.of(context)!.cookingTime);

      // Collect non-empty per-recipe notes
      final recipeNotes = <String, String?>{};
      for (final entry in _recipeNoteControllers.entries) {
        final text = entry.value.text.trim();
        if (text.isNotEmpty) recipeNotes[entry.key] = text;
      }

      // Return the updated meal data
      Navigator.of(context).pop({
        'mealId': widget.meal.id,
        'cookedAt': _cookedAt,
        'servings': _servings,
        'notes': _notesController.text,
        'wasSuccessful': _wasSuccessful,
        'actualPrepTime': prepTime ?? 0.0,
        'actualCookTime': cookTime ?? 0.0,
        'primaryRecipe': widget.primaryRecipe,
        'additionalRecipes': _additionalRecipes,
        'modifiedAt': DateTime.now(),
        'recipeNotes': recipeNotes,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${AppLocalizations.of(context)!.errorPrefix} $e')),
      );
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    for (final c in _recipeNoteControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!
          .editMealTitle(widget.primaryRecipe.name)),
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
                  '${AppLocalizations.of(context)!.cookedOn}: ${_cookedAt.toString().split('.')[0]}',
                ),
                onTap: _selectDate,
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),

              // Servings
              ServingsStepper(
                key: const Key('edit_meal_recording_servings_stepper'),
                value: _servings,
                onChanged: (v) => setState(() => _servings = v),
              ),
              const SizedBox(height: 12),

              // Recipes section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.recipesLabel,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: Text(AppLocalizations.of(context)!.addRecipe),
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
                    subtitle: Text(AppLocalizations.of(context)!.mainDish),
                    contentPadding: EdgeInsets.zero,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextFormField(
                      controller:
                          _recipeNoteControllers[widget.primaryRecipe.id],
                      decoration: InputDecoration(
                        hintText:
                            AppLocalizations.of(context)!.recipeNoteHint,
                        prefixIcon:
                            const Icon(Icons.note_outlined, size: 18),
                        isDense: true,
                      ),
                      maxLines: 2,
                    ),
                  ),

                  // Additional recipes
                  if (_additionalRecipes.isNotEmpty) ...[
                    const Divider(),
                    ...List.generate(_additionalRecipes.length, (index) {
                      final recipe = _additionalRecipes[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.restaurant_menu,
                                color: Colors.grey),
                            title: Text(recipe.name),
                            subtitle:
                                Text(AppLocalizations.of(context)!.sideDish),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _removeAdditionalRecipe(index),
                              tooltip:
                                  AppLocalizations.of(context)!.removeTooltip,
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: TextFormField(
                              controller: _recipeNoteControllers[recipe.id],
                              decoration: InputDecoration(
                                hintText: AppLocalizations.of(context)!
                                    .recipeNoteHint,
                                prefixIcon: const Icon(Icons.note_outlined,
                                    size: 18),
                                isDense: true,
                              ),
                              maxLines: 2,
                            ),
                          ),
                        ],
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
                      key: const Key('edit_meal_recording_prep_time_field'),
                      controller: _prepTimeController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.prepTimeLabel,
                                    prefixIcon: const Icon(Icons.timer),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final time = double.tryParse(value);
                          if (time == null || time < 0) {
                            return AppLocalizations.of(context)!.enterValidTime;
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      key: const Key('edit_meal_recording_cook_time_field'),
                      controller: _cookTimeController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.cookTimeLabel,
                                    prefixIcon: const Icon(Icons.timer),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final time = double.tryParse(value);
                          if (time == null || time < 0) {
                            return AppLocalizations.of(context)!.enterValidTime;
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
                  Text(AppLocalizations.of(context)!.wasItSuccessful),
                  const Spacer(),
                  Switch(
                    key: const Key('edit_meal_recording_success_switch'),
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
                key: const Key('edit_meal_recording_notes_field'),
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.notesOptional,
                        prefixIcon: const Icon(Icons.note),
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
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          onPressed: _saveChanges,
          child: Text(AppLocalizations.of(context)!.saveChanges),
        ),
      ],
    );
  }
}
