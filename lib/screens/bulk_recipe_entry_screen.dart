import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/frequency_type.dart';
import '../models/recipe_category.dart';
import '../database/database_helper.dart';
import '../core/errors/gastrobrain_exceptions.dart';
import '../core/validators/entity_validator.dart';
import '../core/di/service_provider.dart';
import '../utils/id_generator.dart';
import '../core/services/snackbar_service.dart';
import '../l10n/app_localizations.dart';

/// Temporary development tool for bulk recipe entry
/// This screen provides a streamlined interface for quickly adding recipes
/// to populate the database for testing and development purposes.
class BulkRecipeEntryScreen extends StatefulWidget {
  final DatabaseHelper? databaseHelper;

  const BulkRecipeEntryScreen({
    super.key,
    this.databaseHelper,
  });

  @override
  State<BulkRecipeEntryScreen> createState() => _BulkRecipeEntryScreenState();
}

class _BulkRecipeEntryScreenState extends State<BulkRecipeEntryScreen> {
  late DatabaseHelper _dbHelper;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _cookTimeController = TextEditingController();
  FrequencyType _selectedFrequency = FrequencyType.monthly;
  RecipeCategory _selectedCategory = RecipeCategory.uncategorized;
  int _difficulty = 1;
  int _rating = 0;
  bool _isSaving = false;

  final frequencies = FrequencyType.values;

  @override
  void initState() {
    super.initState();
    _dbHelper = widget.databaseHelper ?? ServiceProvider.database.dbHelper;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    super.dispose();
  }

  Widget _buildDifficultyField(String label, int value, Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                index < value ? Icons.battery_full : Icons.battery_0_bar,
                color: index < value ? Colors.green : Colors.grey,
              ),
              onPressed: () => onChanged(index + 1),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildRatingField(String label, int value, Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                index < value ? Icons.star : Icons.star_border,
                color: index < value ? Colors.amber : Colors.grey,
              ),
              onPressed: () => onChanged(index + 1),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTimeField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixText: AppLocalizations.of(context)!.minutes,
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final minutes = int.tryParse(value);
          if (minutes == null || minutes < 0) {
            return AppLocalizations.of(context)!.pleaseEnterValidTime;
          }
        }
        return null;
      },
    );
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Validate recipe data
      EntityValidator.validateRecipe(
        name: _nameController.text,
        ingredients: [], // Empty for now, will be added in issue #162
        instructions: [], // Empty for now, will be added in issue #163
      );

      final prepTime = int.tryParse(_prepTimeController.text);
      final cookTime = int.tryParse(_cookTimeController.text);

      EntityValidator.validateTime(prepTime?.toDouble(), 'Preparation');
      EntityValidator.validateTime(cookTime?.toDouble(), 'Cooking');

      final recipe = Recipe(
        id: IdGenerator.generateId(),
        name: _nameController.text,
        desiredFrequency: _selectedFrequency,
        notes: _notesController.text,
        createdAt: DateTime.now(),
        difficulty: _difficulty,
        prepTimeMinutes: prepTime ?? 0,
        cookTimeMinutes: cookTime ?? 0,
        rating: _rating,
        category: _selectedCategory,
      );

      await _dbHelper.insertRecipe(recipe);

      if (mounted) {
        SnackbarService.showSuccess(
          context,
          AppLocalizations.of(context)!.recipeSavedSuccessfully,
        );

        // Clear form for next recipe entry
        _clearForm();
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
          context,
          '${AppLocalizations.of(context)!.errorSavingRecipe} ${e.message}',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.showError(
          context,
          AppLocalizations.of(context)!.unexpectedError,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _notesController.clear();
    _prepTimeController.clear();
    _cookTimeController.clear();
    setState(() {
      _selectedFrequency = FrequencyType.monthly;
      _selectedCategory = RecipeCategory.uncategorized;
      _difficulty = 1;
      _rating = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Recipe Entry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Bulk Recipe Entry Tool'),
                  content: const Text(
                    'This is a temporary development tool for quickly adding recipes to the database.\n\n'
                    'Features coming in subsequent issues:\n'
                    '• Ingredient parsing and editing (#162)\n'
                    '• Instructions field (#163)\n\n'
                    'Current: Basic recipe metadata entry',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recipe Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.recipeName,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.pleaseEnterRecipeName;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Desired Frequency
                DropdownButtonFormField<FrequencyType>(
                  value: _selectedFrequency,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.desiredFrequency,
                    border: const OutlineInputBorder(),
                  ),
                  items: frequencies.map((frequency) {
                    return DropdownMenuItem<FrequencyType>(
                      value: frequency,
                      child: Text(frequency.getLocalizedDisplayName(context)),
                    );
                  }).toList(),
                  onChanged: (FrequencyType? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedFrequency = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Category
                DropdownButtonFormField<RecipeCategory>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.category,
                    border: const OutlineInputBorder(),
                  ),
                  items: RecipeCategory.values.map((category) {
                    return DropdownMenuItem<RecipeCategory>(
                      value: category,
                      child: Text(category.getLocalizedDisplayName(context)),
                    );
                  }).toList(),
                  onChanged: (RecipeCategory? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Difficulty
                _buildDifficultyField(
                  AppLocalizations.of(context)!.difficultyLevel,
                  _difficulty,
                  (value) {
                    setState(() => _difficulty = value);
                  },
                ),
                const SizedBox(height: 16),

                // Prep Time
                _buildTimeField(
                  AppLocalizations.of(context)!.preparationTime,
                  _prepTimeController,
                ),
                const SizedBox(height: 16),

                // Cook Time
                _buildTimeField(
                  AppLocalizations.of(context)!.cookingTime,
                  _cookTimeController,
                ),
                const SizedBox(height: 16),

                // Rating
                _buildRatingField(
                  AppLocalizations.of(context)!.rating,
                  _rating,
                  (value) {
                    setState(() => _rating = value);
                  },
                ),
                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.notes,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Ingredients Placeholder
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.ingredients,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ingredient parsing will be added in issue #162',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Instructions Placeholder
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.instructions,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Instructions field will be added in issue #163',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveRecipe,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: _isSaving
                          ? const CircularProgressIndicator()
                          : Text(AppLocalizations.of(context)!.saveRecipe),
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
