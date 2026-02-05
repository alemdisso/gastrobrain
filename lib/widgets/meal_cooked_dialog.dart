// lib/widgets/meal_cooked_dialog.dart

import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../core/validators/entity_validator.dart';
import '../l10n/app_localizations.dart';

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
          SnackBar(content: Text(AppLocalizations.of(context)!.errorSelectingDate)),
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
      title: Text('${AppLocalizations.of(context)!.cookNow} ${widget.recipe.name}'),
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
                  '${AppLocalizations.of(context)!.cookedOn}: ${_cookedAt.toString().split('.')[0]}',
                ),
                subtitle: Text(
                  '${AppLocalizations.of(context)!.plannedFor}: ${widget.plannedDate.toString().split('T')[0]}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                onTap: _selectDate,
                dense: true,
              ),
              const SizedBox(height: 12),

              // Servings
              TextFormField(
                key: const Key('meal_cooked_servings_field'),
                controller: _servingsController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.numberOfServings,
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

              // Actual times
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('meal_cooked_prep_time_field'),
                      controller: _prepTimeController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.actualPrepTimeMin,
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
                      key: const Key('meal_cooked_cook_time_field'),
                      controller: _cookTimeController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.actualCookTimeMin,
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
                    key: const Key('meal_cooked_success_switch'),
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
                key: const Key('meal_cooked_notes_field'),
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.notesOptional,
                        prefixIcon: const Icon(Icons.note),
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
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          onPressed: _saveMeal,
          child: Text(AppLocalizations.of(context)!.save),
        ),
      ],
    );
  }
}
