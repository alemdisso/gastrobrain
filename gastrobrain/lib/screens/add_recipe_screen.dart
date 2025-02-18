import 'package:flutter/material.dart';
import '../widgets/add_ingredient_dialog.dart';
import '../models/recipe.dart';
import '../models/ingredient.dart';
import '../models/recipe_ingredient.dart';
import '../database/database_helper.dart';
import '../core/errors/gastrobrain_exceptions.dart';
import '../core/validators/entity_validator.dart';
import '../utils/id_generator.dart';
import '../widgets/add_ingredient_dialog.dart';

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _cookTimeController = TextEditingController();
  String _selectedFrequency = 'monthly';
  int _difficulty = 1;
  int _rating = 0;
  bool _isSaving = false;
  final String _tempRecipeId = IdGenerator.generateId();
  final List<RecipeIngredient> _pendingIngredients = [];
  final Map<String, Ingredient> _ingredientDetails =
      {}; // Cache for ingredient details

  final List<String> _frequencies = [
    'daily',
    'weekly',
    'biweekly',
    'monthly',
    'rarely'
  ];

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
        suffixText: 'minutes',
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final minutes = int.tryParse(value);
          if (minutes == null || minutes < 0) {
            return 'Please enter a valid time';
          }
        }
        return null;
      },
    );
  }

  Future<Ingredient?> _getIngredientDetails(String ingredientId) async {
    // Check if we already have the ingredient details cached
    if (_ingredientDetails.containsKey(ingredientId)) {
      return _ingredientDetails[ingredientId];
    }

    final dbHelper = DatabaseHelper();
    try {
      // Load all ingredients at once and cache them
      final ingredients = await dbHelper.getAllIngredients();
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
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
    );

    final result = await showDialog<RecipeIngredient>(
      // Change return type
      context: context,
      builder: (context) => AddIngredientDialog(
        recipe: tempRecipe,
        onSave: (ingredient) {
          // Instead of saving to DB, return the ingredient
          Navigator.pop(context, ingredient);
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

      final dbHelper = DatabaseHelper();
      await dbHelper.insertRecipe(recipe);

      // Then save all pending ingredients
      for (final ingredient in _pendingIngredients) {
        await dbHelper.addIngredientToRecipe(ingredient);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } on ValidationException catch (e) {
      _showErrorSnackBar(e.message);
    } on DuplicateException catch (e) {
      _showErrorSnackBar(e.message);
    } on GastrobrainException catch (e) {
      _showErrorSnackBar('Error saving recipe: ${e.message}');
    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _addIngredient() async {
    // Create a temporary recipe for the dialog
    final tempRecipe = Recipe(
      id: DateTime.now().toString(),
      name: _nameController.text,
      createdAt: DateTime.now(),
      desiredFrequency: _selectedFrequency,
      notes: _notesController.text,
      difficulty: _difficulty,
      prepTimeMinutes: int.tryParse(_prepTimeController.text) ?? 0,
      cookTimeMinutes: int.tryParse(_cookTimeController.text) ?? 0,
      rating: _rating,
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddIngredientDialog(recipe: tempRecipe),
    );

    if (result == true) {
      // Reload ingredients list
      final dbHelper = DatabaseHelper();
      final ingredients = await dbHelper.getRecipeIngredients(tempRecipe.id);
      setState(() {
        _ingredients.clear();
        _ingredients.addAll(ingredients);
      });
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
        title: const Text('Add New Recipe'),
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
                  decoration: const InputDecoration(
                    labelText: 'Recipe Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a recipe name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedFrequency,
                  decoration: const InputDecoration(
                    labelText: 'Desired Frequency',
                    border: OutlineInputBorder(),
                  ),
                  items: _frequencies.map((String frequency) {
                    return DropdownMenuItem<String>(
                      value: frequency,
                      child: Text(
                          frequency[0].toUpperCase() + frequency.substring(1)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedFrequency = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildRatingField('Difficulty Level', _difficulty, (value) {
                  setState(() => _difficulty = value);
                }),
                const SizedBox(height: 16),
                _buildTimeField('Preparation Time', _prepTimeController),
                const SizedBox(height: 16),
                _buildTimeField('Cooking Time', _cookTimeController),
                const SizedBox(height: 16),
                _buildRatingField('Rating', _rating, (value) {
                  setState(() => _rating = value);
                }),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
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
                            const Text(
                              'Ingredients',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Add'),
                              onPressed: _addIngredient,
                            ),
                          ],
                        ),
                        if (_pendingIngredients.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'No ingredients added yet',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _pendingIngredients.length,
                            itemBuilder: (context, index) {
                              final ingredient = _pendingIngredients[index];
                              return ListTile(
                                title: FutureBuilder<Ingredient?>(
                                  future: _getIngredientDetails(
                                      ingredient.ingredientId),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      final ingredientName =
                                          snapshot.data?.name ?? 'Unknown';
                                      final unit = snapshot.data?.unit ?? '';
                                      return Text(
                                          '$ingredientName: ${ingredient.quantity} $unit');
                                    }
                                    return const Text('Loading...');
                                  },
                                ),
                                subtitle: ingredient.notes != null
                                    ? Text(ingredient.notes!)
                                    : null,
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
                          ),
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
                          : const Text('Save Recipe'),
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
