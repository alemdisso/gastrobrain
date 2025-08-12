import 'package:flutter/material.dart';
import '../widgets/add_ingredient_dialog.dart';
import '../models/recipe.dart';
import '../models/ingredient.dart';
import '../models/recipe_ingredient.dart';
import '../models/frequency_type.dart';
import '../models/recipe_category.dart';
import '../models/measurement_unit.dart';
import '../database/database_helper.dart';
import '../core/errors/gastrobrain_exceptions.dart';
import '../core/validators/entity_validator.dart';
import '../core/di/service_provider.dart';
import '../utils/id_generator.dart';
import '../core/services/snackbar_service.dart';
import '../l10n/app_localizations.dart';
import '../utils/quantity_formatter.dart';

class AddRecipeScreen extends StatefulWidget {
  final DatabaseHelper? databaseHelper;

  const AddRecipeScreen({
    super.key,
    this.databaseHelper,
  });

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
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
  final String _tempRecipeId = IdGenerator.generateId();
  final List<RecipeIngredient> _pendingIngredients = [];
  final Map<String, Ingredient> _ingredientDetails =
      {}; // Cache for ingredient details

  final frequencies = FrequencyType.values;

  @override
  void initState() {
    super.initState();
    // Use the injected database helper or get one from ServiceProvider
    _dbHelper = widget.databaseHelper ?? ServiceProvider.database.dbHelper;
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

  Widget _buildIngredientList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _pendingIngredients.length,
      itemBuilder: (context, index) {
        final ingredient = _pendingIngredients[index];
        return ListTile(
          title: ingredient.ingredientId != null
              ? FutureBuilder<Ingredient?>(
                  future: _getIngredientDetails(ingredient.ingredientId!),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final ingredientName = snapshot.data?.name ??
                          AppLocalizations.of(context)!.unknown;
                      final unitString =
                          ingredient.unitOverride ?? snapshot.data?.unit?.value ?? '';
                      final measurementUnit = MeasurementUnit.fromString(unitString);
                      final localizedUnit = measurementUnit?.getLocalizedDisplayName(context) ?? unitString;
                      return Text(
                          '$ingredientName: ${QuantityFormatter.format(ingredient.quantity)} $localizedUnit');
                    }
                    return Text(AppLocalizations.of(context)!.loading);
                  },
                )
              : Text(() {
                  final customUnitString = ingredient.customUnit ?? '';
                  final measurementUnit = MeasurementUnit.fromString(customUnitString);
                  final localizedUnit = measurementUnit?.getLocalizedDisplayName(context) ?? customUnitString;
                  return '${ingredient.customName}: ${QuantityFormatter.format(ingredient.quantity)} $localizedUnit';
                }()),
          subtitle: ingredient.notes != null ? Text(ingredient.notes!) : null,
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              setState(() {
                _pendingIngredients.removeAt(index);
              });
            },
          ),
        );
      },
    );
  }

  Future<Ingredient?> _getIngredientDetails(String ingredientId) async {
    // Check if we already have the ingredient details cached
    if (_ingredientDetails.containsKey(ingredientId)) {
      return _ingredientDetails[ingredientId];
    }

    try {
      // Load all ingredients at once and cache them
      final ingredients = await _dbHelper.getAllIngredients();
      for (final ingredient in ingredients) {
        _ingredientDetails[ingredient.id] = ingredient;
      }

      final ingredient = _ingredientDetails[ingredientId];
      if (ingredient == null) {
        throw NotFoundException('Ingredient not found');
      }

      return ingredient;
    } on GastrobrainException {
      rethrow; // Re-throw GastrobrainException types as they are
    } catch (e) {
      throw GastrobrainException('Error loading ingredient details: $e');
    }
  }

  Future<void> _addIngredient() async {
    // Create a temporary recipe for the dialog
    final tempRecipe = Recipe(
      id: _tempRecipeId, // Use consistent temporary ID
      name: _nameController.text,
      desiredFrequency: _selectedFrequency,
      notes: _notesController.text,
      createdAt: DateTime.now(),
      difficulty: _difficulty,
      prepTimeMinutes: int.tryParse(_prepTimeController.text) ?? 0,
      cookTimeMinutes: int.tryParse(_cookTimeController.text) ?? 0,
      rating: _rating,
      category: _selectedCategory,
    );

    // The AddIngredientDialog will now properly return a RecipeIngredient object
    final result = await showDialog<RecipeIngredient>(
      context: context,
      builder: (context) => AddIngredientDialog(
        recipe: tempRecipe,
        databaseHelper: _dbHelper,
        onSave: (ingredient) {
          // We don't need to explicitly call Navigator.pop here anymore
          // as the dialog will handle it and return the ingredient
        },
      ),
    );

    if (result != null) {
      setState(() {
        _pendingIngredients.add(result);
      });
    }
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
        ingredients: _pendingIngredients.map((i) => i.toMap()).toList(),
        instructions: [],
      );

      final prepTime = int.tryParse(_prepTimeController.text);
      final cookTime = int.tryParse(_cookTimeController.text);

      EntityValidator.validateTime(prepTime?.toDouble(), 'Preparation');
      EntityValidator.validateTime(cookTime?.toDouble(), 'Cooking');

      final recipe = Recipe(
        id: _tempRecipeId, // Use the same ID we've been using
        name: _nameController.text,
        desiredFrequency: _selectedFrequency,
        notes: _notesController.text,
        createdAt: DateTime.now(),
        difficulty: _difficulty,
        prepTimeMinutes: prepTime ?? 0,
        cookTimeMinutes: cookTime ?? 0,
        rating: _rating,
      );

      await _dbHelper.insertRecipe(recipe);

      // Then save all pending ingredients
      for (final ingredient in _pendingIngredients) {
        await _dbHelper.addIngredientToRecipe(ingredient);
      }

      if (mounted) {
        Navigator.pop(context, true);
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
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.addNewRecipe),
      ),
      body: SingleChildScrollView(
        // Added ScrollView
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
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
                _buildDifficultyField(
                    AppLocalizations.of(context)!.difficultyLevel, _difficulty,
                    (value) {
                  setState(() => _difficulty = value);
                }),
                const SizedBox(height: 16),
                _buildTimeField(AppLocalizations.of(context)!.preparationTime,
                    _prepTimeController),
                const SizedBox(height: 16),
                _buildTimeField(AppLocalizations.of(context)!.cookingTime,
                    _cookTimeController),
                const SizedBox(height: 16),
                _buildRatingField(AppLocalizations.of(context)!.rating, _rating,
                    (value) {
                  setState(() => _rating = value);
                }),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.notes,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
// Ingredients Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.ingredients,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.add),
                              label: Text(AppLocalizations.of(context)!.add),
                              onPressed: _addIngredient,
                            ),
                          ],
                        ),
                        if (_pendingIngredients.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                AppLocalizations.of(context)!
                                    .noIngredientsAdded,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          )
                        else
                          _buildIngredientList(),
                      ],
                    ),
                  ),
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
