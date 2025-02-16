import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/ingredient.dart';
import '../models/recipe_ingredient.dart';
//import '../models/protein_type.dart';
import '../database/database_helper.dart';
import 'add_new_ingredient_dialog.dart';

class AddIngredientDialog extends StatefulWidget {
  final Recipe recipe;

  const AddIngredientDialog({super.key, required this.recipe});

  @override
  State<AddIngredientDialog> createState() => _AddIngredientDialogState();
}

class _AddIngredientDialogState extends State<AddIngredientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();

  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Ingredient> _availableIngredients = [];
  Ingredient? _selectedIngredient;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    setState(() => _isLoading = true);
    final ingredients = await _dbHelper.getAllIngredients();
    setState(() {
      _availableIngredients = ingredients;
      _isLoading = false;
    });
  }

  Future<void> _addIngredientToRecipe() async {
    if (!_formKey.currentState!.validate() || _selectedIngredient == null) {
      return;
    }

    final recipeIngredient = RecipeIngredient(
      id: DateTime.now().toString(), // We'll improve ID generation later
      recipeId: widget.recipe.id,
      ingredientId: _selectedIngredient!.id,
      quantity: double.parse(_quantityController.text),
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    await _dbHelper.addIngredientToRecipe(recipeIngredient);
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _createNewIngredient() async {
    final newIngredient = await showDialog<Ingredient>(
      context: context,
      builder: (context) => const AddNewIngredientDialog(),
    );

    if (newIngredient != null) {
      setState(() {
        _availableIngredients.add(newIngredient);
        _selectedIngredient = newIngredient;
      });
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Ingredient'),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ingredient Selection
                    DropdownButtonFormField<Ingredient>(
                      value: _selectedIngredient,
                      decoration: const InputDecoration(
                        labelText: 'Select Ingredient',
                        border: OutlineInputBorder(),
                      ),
                      items: _availableIngredients.map((ingredient) {
                        return DropdownMenuItem(
                          value: ingredient,
                          child: Text(ingredient.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedIngredient = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select an ingredient';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Create New Ingredient'),
                      onPressed: _createNewIngredient,
                    ),
                    const SizedBox(height: 16),

                    // Quantity
                    TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        border: const OutlineInputBorder(),
                        suffixText: _selectedIngredient?.unit,
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a quantity';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Preparation Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Preparation Notes (Optional)',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., finely chopped, diced, etc.',
                      ),
                      maxLines: 2,
                    ),

                    if (_selectedIngredient != null) ...[
                      const SizedBox(height: 16),
                      // Ingredient Info Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Category: ${_selectedIngredient!.category}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              if (_selectedIngredient!.proteinType != null)
                                Text(
                                  'Protein Type: ${_selectedIngredient!.proteinType}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              if (_selectedIngredient!.notes?.isNotEmpty ==
                                  true)
                                Text(
                                  'Notes: ${_selectedIngredient!.notes}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
          onPressed: _addIngredientToRecipe,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
