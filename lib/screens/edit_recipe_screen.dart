import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/frequency_type.dart';
import '../models/recipe_category.dart';
import '../database/database_helper.dart';
import '../core/errors/gastrobrain_exceptions.dart';
import '../core/validators/entity_validator.dart';
import '../l10n/app_localizations.dart';

class EditRecipeScreen extends StatefulWidget {
  final Recipe recipe;

  const EditRecipeScreen({super.key, required this.recipe});

  @override
  State<EditRecipeScreen> createState() => _EditRecipeScreenState();
}

class _EditRecipeScreenState extends State<EditRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late TextEditingController _instructionsController;
  late TextEditingController _prepTimeController;
  late TextEditingController _cookTimeController;
  late FrequencyType _selectedFrequency;
  late RecipeCategory _selectedCategory;
  late int _difficulty;
  late int _rating;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing recipe data
    _nameController = TextEditingController(text: widget.recipe.name);
    _notesController = TextEditingController(text: widget.recipe.notes);
    _instructionsController =
        TextEditingController(text: widget.recipe.instructions);
    _prepTimeController =
        TextEditingController(text: widget.recipe.prepTimeMinutes.toString());
    _cookTimeController =
        TextEditingController(text: widget.recipe.cookTimeMinutes.toString());
    _selectedFrequency = widget.recipe.desiredFrequency;
    _selectedCategory = widget.recipe.category;
    _difficulty = widget.recipe.difficulty;
    _rating = widget.recipe.rating;
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

  Widget _buildDifficultyField(
      String label, int value, Function(int) onChanged) {
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

  Widget _buildTimeField(String label, TextEditingController controller,
      {Key? key}) {
    return TextFormField(
      key: key,
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
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
        id: widget.recipe.id,
        name: _nameController.text,
        ingredients: [],
        instructions: [],
      );

      final prepTime = int.tryParse(_prepTimeController.text);
      final cookTime = int.tryParse(_cookTimeController.text);

      EntityValidator.validateTime(prepTime?.toDouble(), 'Preparation');
      EntityValidator.validateTime(cookTime?.toDouble(), 'Cooking');

      final updatedRecipe = Recipe(
        id: widget.recipe.id,
        name: _nameController.text,
        desiredFrequency: _selectedFrequency,
        notes: _notesController.text,
        instructions: _instructionsController.text,
        createdAt: widget.recipe.createdAt,
        difficulty: _difficulty,
        prepTimeMinutes: prepTime ?? 0,
        cookTimeMinutes: cookTime ?? 0,
        rating: _rating,
        category: _selectedCategory,
      );

      final dbHelper = DatabaseHelper();
      await dbHelper.updateRecipe(updatedRecipe);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } on ValidationException catch (e) {
      _showErrorSnackBar(e.message);
    } on DuplicateException catch (e) {
      _showErrorSnackBar(e.message);
    } on NotFoundException catch (e) {
      _showErrorSnackBar(e.message);
    } on GastrobrainException catch (e) {
      _showErrorSnackBar(
          '${AppLocalizations.of(context)!.errorUpdatingRecipe} ${e.message}');
    } catch (e) {
      _showErrorSnackBar(AppLocalizations.of(context)!.unexpectedError);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _instructionsController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.editRecipe),
      ),
      body: SafeArea(
        top: false, // AppBar handles top
        bottom: true,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  key: const Key('edit_recipe_name_field'),
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.recipeName,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!
                          .pleaseEnterRecipeName;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<FrequencyType>(
                  key: const Key('edit_recipe_frequency_field'),
                  initialValue: _selectedFrequency,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.desiredFrequency,
                    border: const OutlineInputBorder(),
                  ),
                  items: FrequencyType.values.map((frequency) {
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
                DropdownButtonFormField<RecipeCategory>(
                  key: const Key('edit_recipe_category_field'),
                  initialValue: _selectedCategory,
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
                _buildDifficultyField(
                    AppLocalizations.of(context)!.difficultyLevel, _difficulty,
                    (value) {
                  setState(() => _difficulty = value);
                }),
                const SizedBox(height: 16),
                _buildTimeField(AppLocalizations.of(context)!.preparationTime,
                    _prepTimeController,
                    key: const Key('edit_recipe_prep_time_field')),
                const SizedBox(height: 16),
                _buildTimeField(AppLocalizations.of(context)!.cookingTime,
                    _cookTimeController,
                    key: const Key('edit_recipe_cook_time_field')),
                const SizedBox(height: 16),
                _buildRatingField(AppLocalizations.of(context)!.rating, _rating,
                    (value) {
                  setState(() => _rating = value);
                }),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('edit_recipe_notes_field'),
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.notes,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('edit_recipe_instructions_field'),
                  controller: _instructionsController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.instructionsLabel,
                    hintText: AppLocalizations.of(context)!.enterInstructions,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: null,
                  minLines: 5,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveRecipe,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: _isSaving
                          ? const CircularProgressIndicator()
                          : Text(AppLocalizations.of(context)!.saveChanges),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
