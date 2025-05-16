// Create a new file: lib/widgets/meal_recording_dialog.dart

import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../database/database_helper.dart';
import '../core/validators/entity_validator.dart';

class MealRecordingDialog extends StatefulWidget {
  final Recipe primaryRecipe;
  final List<Recipe>? additionalRecipes;
  final DateTime? plannedDate;
  final String? notes;
  final bool allowRecipeChange;

  const MealRecordingDialog({
    super.key,
    required this.primaryRecipe,
    this.additionalRecipes,
    this.plannedDate,
    this.notes,
    this.allowRecipeChange = true,
  });

  @override
  State<MealRecordingDialog> createState() => _MealRecordingDialogState();
}

class _MealRecordingDialogState extends State<MealRecordingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _servingsController = TextEditingController(text: '1');
  final _prepTimeController = TextEditingController();
  final _cookTimeController = TextEditingController();
  bool _wasSuccessful = true;
  DateTime _cookedAt = DateTime.now();

  // For managing additional recipes
  final List<Recipe> _additionalRecipes = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Recipe> _availableRecipes = [];
  bool _isLoadingRecipes = false;

  @override
  void initState() {
    super.initState();

    // Pre-fill with recipe's expected times
    _prepTimeController.text = widget.primaryRecipe.prepTimeMinutes.toString();
    _cookTimeController.text = widget.primaryRecipe.cookTimeMinutes.toString();

    // Pre-fill notes if provided
    if (widget.notes != null && widget.notes!.isNotEmpty) {
      _notesController.text = widget.notes!;
    }

    // Pre-fill with any additional recipes
    if (widget.additionalRecipes != null) {
      _additionalRecipes.addAll(widget.additionalRecipes!);
    }

    // If planned date is provided, use it as default
    if (widget.plannedDate != null) {
      _cookedAt = widget.plannedDate!;
    }

    // Load available recipes for selection
    _loadAvailableRecipes();
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
          SnackBar(content: Text('Error loading recipes: $e')),
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
          const SnackBar(content: Text('Error selecting date')),
        );
      }
    }
  }

  Future<void> _showAddRecipeDialog() async {
    if (_availableRecipes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No additional recipes available.')),
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

      final servings = int.parse(_servingsController.text);
      EntityValidator.validateServings(servings);

      final prepTime = double.tryParse(_prepTimeController.text);
      final cookTime = double.tryParse(_cookTimeController.text);

      EntityValidator.validateTime(prepTime, 'Preparation');
      EntityValidator.validateTime(cookTime, 'Cooking');

      // Return the meal data to the caller
      Navigator.of(context).pop({
        'cookedAt': _cookedAt,
        'servings': servings,
        'notes': _notesController.text,
        'wasSuccessful': _wasSuccessful,
        'actualPrepTime': prepTime ?? 0.0,
        'actualCookTime': cookTime ?? 0.0,
        'primaryRecipe': widget.primaryRecipe,
        'additionalRecipes': _additionalRecipes,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
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
      title: Text('Cook ${widget.primaryRecipe.name}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date and Time section
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  'Cooked on: ${_cookedAt.toString().split('.')[0]}',
                ),
                subtitle: widget.plannedDate != null
                    ? Text(
                        'Planned for: ${widget.plannedDate.toString().split('T')[0]}',
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    : null,
                onTap: _selectDate,
                dense: true,
              ),
              const SizedBox(height: 12),

              // Servings
              TextFormField(
                controller: _servingsController,
                decoration: const InputDecoration(
                  labelText: 'Number of Servings',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.people),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter number of servings';
                  }
                  if (int.tryParse(value) == null || int.parse(value) < 1) {
                    return 'Please enter a valid number';
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
                      if (widget.allowRecipeChange)
                        TextButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add Recipe'),
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
                        trailing: widget.allowRecipeChange
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () {
                                  setState(() {
                                    _additionalRecipes.removeAt(index);
                                  });
                                },
                                tooltip: 'Remove',
                              )
                            : null,
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
                        labelText: 'Actual Prep Time (min)',
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
                        labelText: 'Actual Cook Time (min)',
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
          onPressed: _saveMeal,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
