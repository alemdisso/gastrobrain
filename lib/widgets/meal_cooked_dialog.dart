// lib/widgets/meal_cooked_dialog.dart

import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../core/validators/entity_validator.dart';

class MealCookedDialog extends StatefulWidget {
  final Recipe recipe;
  final DateTime plannedDate;

  const MealCookedDialog({
    super.key,
    required this.recipe,
    required this.plannedDate,
  });

  @override
  State<MealCookedDialog> createState() => _MealCookedDialogState();
}

class _MealCookedDialogState extends State<MealCookedDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _servingsController = TextEditingController(text: '1');
  final _prepTimeController = TextEditingController();
  final _cookTimeController = TextEditingController();
  bool _wasSuccessful = true;
  DateTime _cookedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Pre-fill with recipe's expected times
    _prepTimeController.text = widget.recipe.prepTimeMinutes.toString();
    _cookTimeController.text = widget.recipe.cookTimeMinutes.toString();
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

  void _saveMeal() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      // Validate meal data
      EntityValidator.validateMeal(
        name: widget.recipe.name,
        date: _cookedAt,
        recipeIds: [widget.recipe.id],
      );

      final servings = int.parse(_servingsController.text);
      EntityValidator.validateServings(servings);

      final prepTime = double.tryParse(_prepTimeController.text);
      final cookTime = double.tryParse(_cookTimeController.text);

      EntityValidator.validateTime(prepTime, 'Preparation');
      EntityValidator.validateTime(cookTime, 'Cooking');

      // Return cooking details to the caller
      Navigator.pop(context, {
        'cookedAt': _cookedAt,
        'servings': servings,
        'notes': _notesController.text,
        'wasSuccessful': _wasSuccessful,
        'actualPrepTime': prepTime ?? 0.0,
        'actualCookTime': cookTime ?? 0.0,
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
      title: Text('Cook ${widget.recipe.name}'),
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
                subtitle: Text(
                  'Planned for: ${widget.plannedDate.toString().split('T')[0]}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
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
                maxLines: 2,
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
