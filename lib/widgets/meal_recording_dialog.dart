// lib/widgets/meal_recording_dialog.dart

import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../database/database_helper.dart';
import '../core/validators/entity_validator.dart';
import '../l10n/app_localizations.dart';
import '../utils/sorting_utils.dart';
import 'package:intl/intl.dart';
import 'servings_stepper.dart';

class MealRecordingDialog extends StatefulWidget {
  final Recipe primaryRecipe;
  final List<Recipe>? additionalRecipes;
  final DateTime? plannedDate;
  final String? notes;
  final bool allowRecipeChange;
  final DatabaseHelper? databaseHelper;
  final int? plannedServings;

  const MealRecordingDialog({
    super.key,
    required this.primaryRecipe,
    this.additionalRecipes,
    this.plannedDate,
    this.notes,
    this.allowRecipeChange = true,
    this.databaseHelper,
    this.plannedServings,
  });

  @override
  State<MealRecordingDialog> createState() => _MealRecordingDialogState();
}

class _MealRecordingDialogState extends State<MealRecordingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _cookTimeController = TextEditingController();
  int _servings = 4;
  bool _wasSuccessful = true;
  DateTime _cookedAt = DateTime.now();

  // For managing additional recipes
  final List<Recipe> _additionalRecipes = [];
  final Map<String, TextEditingController> _recipeNoteControllers = {};
  late final DatabaseHelper _dbHelper;
  List<Recipe> _availableRecipes = [];
  bool _isLoadingRecipes = false;

  @override
  void initState() {
    super.initState();

    // Initialize database helper using dependency injection
    _dbHelper = widget.databaseHelper ?? DatabaseHelper();

    // Set initial servings: plannedServings → recipe.servings → 4
    final initial = widget.plannedServings ?? widget.primaryRecipe.servings;
    _servings = initial > 0 ? initial : 4;

    // Pre-fill with recipe's expected times
    _prepTimeController.text = widget.primaryRecipe.prepTimeMinutes.toString();
    _cookTimeController.text = widget.primaryRecipe.cookTimeMinutes.toString();

    // Pre-fill notes if provided
    if (widget.notes != null && widget.notes!.isNotEmpty) {
      _notesController.text = widget.notes!;
    }

    // Initialise per-recipe note controller for primary recipe
    _recipeNoteControllers[widget.primaryRecipe.id] = TextEditingController();

    // Pre-fill with any additional recipes
    if (widget.additionalRecipes != null) {
      _additionalRecipes.addAll(widget.additionalRecipes!);
      for (final r in widget.additionalRecipes!) {
        _recipeNoteControllers[r.id] = TextEditingController();
      }
    }

    // If planned date is provided, use it as default
    if (widget.plannedDate != null) {
      _cookedAt = widget.plannedDate!;
    }

    // Load available recipes for selection
    _loadAvailableRecipes();
  }

  String _formatDate(DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMd(locale).format(date);
  }

  Future<void> _loadAvailableRecipes() async {
    setState(() {
      _isLoadingRecipes = true;
    });

    try {
      // Load all recipes except the main one
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
          // Preserve the current time but use the selected date
          final now = DateTime.now();
          _cookedAt = DateTime(
            picked.year,
            picked.month,
            picked.day,
            now.hour,
            now.minute,
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
        title: Text(AppLocalizations.of(context)!.buttonAddRecipe),
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
                    // Skip recipes that are already added
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
            child: Text(AppLocalizations.of(context)!.buttonCancel),
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

  void _saveMeal() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      // Collect all recipe IDs for validation
      final List<String> allRecipeIds = [
        widget.primaryRecipe.id,
        ..._additionalRecipes.map((r) => r.id),
      ];

      // Validate the data
      EntityValidator.validateMeal(
        name: widget.primaryRecipe.name,
        date: _cookedAt,
        recipeIds: allRecipeIds,
      );

      final prepTime = double.tryParse(_prepTimeController.text);
      final cookTime = double.tryParse(_cookTimeController.text);

      EntityValidator.validateTime(prepTime, 'Preparation');
      EntityValidator.validateTime(cookTime, 'Cooking');

      // Collect non-empty per-recipe notes
      final recipeNotes = <String, String?>{};
      for (final entry in _recipeNoteControllers.entries) {
        final text = entry.value.text.trim();
        if (text.isNotEmpty) recipeNotes[entry.key] = text;
      }

      // Return the meal data to the caller
      Navigator.of(context).pop({
        'cookedAt': _cookedAt,
        'servings': _servings,
        'notes': _notesController.text,
        'wasSuccessful': _wasSuccessful,
        'actualPrepTime': prepTime ?? 0.0,
        'actualCookTime': cookTime ?? 0.0,
        'primaryRecipe': widget.primaryRecipe,
        'additionalRecipes': _additionalRecipes,
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
          .cookRecipeTitle(widget.primaryRecipe.name)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date and Time section
              ListTile(
                key: const Key('meal_recording_date_selector'),
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  AppLocalizations.of(context)!
                      .cookedOnDate(_formatDate(_cookedAt)),
                ),
                subtitle: widget.plannedDate != null
                    ? Text(
                        AppLocalizations.of(context)!
                            .plannedForDate(_formatDate(widget.plannedDate!)),
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    : null,
                onTap: _selectDate,
                dense: true,
              ),
              const SizedBox(height: 12),

              // Servings
              ServingsStepper(
                key: const Key('meal_recording_servings_stepper'),
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
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.recipesLabel,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      if (widget.allowRecipeChange)
                        TextButton.icon(
                          icon: const Icon(Icons.add),
                          label: Text(
                              AppLocalizations.of(context)!.buttonAddRecipe),
                          onPressed:
                              _isLoadingRecipes ? null : _showAddRecipeDialog,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Main recipe (always shown)
                  ListTile(
                    leading: const Icon(Icons.restaurant, color: Colors.green),
                    title: Text(widget.primaryRecipe.name),
                    subtitle: Text(AppLocalizations.of(context)!.mainDish),
                    contentPadding: EdgeInsets.zero,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextFormField(
                      controller: _recipeNoteControllers[widget.primaryRecipe.id],
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.recipeNoteHint,
                        prefixIcon: const Icon(Icons.note_outlined, size: 18),
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
                            trailing: widget.allowRecipeChange
                                ? IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () =>
                                        _removeAdditionalRecipe(index),
                                    tooltip: AppLocalizations.of(context)!
                                        .removeTooltip,
                                  )
                                : null,
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
                      key: const Key('meal_recording_prep_time_field'),
                      controller: _prepTimeController,
                      decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(context)!.actualPrepTimeMin,
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
                      key: const Key('meal_recording_cook_time_field'),
                      controller: _cookTimeController,
                      decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(context)!.actualCookTimeMin,
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
                    key: const Key('meal_recording_success_switch'),
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
                key: const Key('meal_recording_notes_field'),
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
          key: const Key('meal_recording_cancel_button'),
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.buttonCancel),
        ),
        ElevatedButton(
          key: const Key('meal_recording_save_button'),
          onPressed: _saveMeal,
          child: Text(AppLocalizations.of(context)!.save),
        ),
      ],
    );
  }
}
