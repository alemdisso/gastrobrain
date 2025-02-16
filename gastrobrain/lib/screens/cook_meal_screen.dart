import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/meal.dart';
import '../database/database_helper.dart';
import '../utils/id_generator.dart';
import '../core/errors/gastrobrain_exceptions.dart';

class CookMealScreen extends StatefulWidget {
  final Recipe recipe;

  const CookMealScreen({super.key, required this.recipe});

  @override
  State<CookMealScreen> createState() => _CookMealScreenState();
}

class _CookMealScreenState extends State<CookMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _servingsController = TextEditingController(text: '1');
  final _prepTimeController = TextEditingController();
  final _cookTimeController = TextEditingController();
  bool _wasSuccessful = true;
  DateTime _cookedAt = DateTime.now();
  bool _isSaving = false;

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _saveMeal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Validate meal data
      EntityValidator.validateMeal(
        name: widget.recipe.name,
        date: _cookedAt,
        recipeIds: [widget.recipe.id],
      );

      final meal = Meal(
        id: IdGenerator.generateId(),
        recipeId: widget.recipe.id,
        cookedAt: _cookedAt,
        servings: int.parse(_servingsController.text),
        notes: _notesController.text,
        wasSuccessful: _wasSuccessful,
        actualPrepTime: double.tryParse(_prepTimeController.text) ?? 0,
        actualCookTime: double.tryParse(_cookTimeController.text) ?? 0,
      );

      final dbHelper = DatabaseHelper();
      await dbHelper.insertMeal(meal);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } on ValidationException catch (e) {
      _showErrorSnackBar(e.message);
    } on GastrobrainException catch (e) {
      _showErrorSnackBar('Error saving meal: ${e.message}');
    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred while saving the meal');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _cookedAt,
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
      );
      if (picked != null && picked != _cookedAt) {
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
      _showErrorSnackBar('Error selecting date');
    }
  }

  @override
  void initState() {
    super.initState();
    // Pre-fill with recipe's expected times
    _prepTimeController.text = widget.recipe.prepTimeMinutes.toString();
    _cookTimeController.text = widget.recipe.cookTimeMinutes.toString();
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Cook ${widget.recipe.name}'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date and Time section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(
                        'Cooked on: ${_cookedAt.toString().split('.')[0]}',
                      ),
                      onTap: () => _selectDate(context),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

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
                const SizedBox(height: 16),

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
                const SizedBox(height: 16),

                // Success rating
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
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
                  ),
                ),
                const SizedBox(height: 16),

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
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveMeal,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(),
                          )
                        : const Icon(Icons.save),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(_isSaving ? 'Saving...' : 'Save Meal'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
