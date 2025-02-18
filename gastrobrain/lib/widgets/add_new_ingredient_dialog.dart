import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../models/protein_type.dart';
import '../database/database_helper.dart';
import '../utils/id_generator.dart';
import '../core/errors/gastrobrain_exceptions.dart';
import '../core/validators/entity_validator.dart';

class AddNewIngredientDialog extends StatefulWidget {
  const AddNewIngredientDialog({super.key});

  @override
  State<AddNewIngredientDialog> createState() => _AddNewIngredientDialogState();
}

class _AddNewIngredientDialogState extends State<AddNewIngredientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedCategory = 'vegetable';
  String? _selectedUnit;
  ProteinType? _selectedProteinType;
  bool _isSaving = false;

  final List<String> _categories = [
    'vegetable',
    'fruit',
    'protein', // for meat, fish, eggs
    'dairy',
    'grain', // for cereals like wheat, rice
    'pulse', // for legumes like lentils, beans
    'nuts_and_seeds',
    'seasoning',
    'sugar products', // for sugar, honey, syrups, etc.
    'other'
  ];

  final List<String> _units = [
    'g',
    'kg',
    'ml',
    'l',
    'cup',
    'tbsp',
    'tsp',
    'piece',
    'slice'
  ];

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _saveIngredient() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Validate ingredient data
      EntityValidator.validateIngredient(
        name: _nameController.text,
        category: _selectedCategory,
        unit: _selectedUnit,
        proteinType: _selectedProteinType?.name,
      );

      final ingredient = Ingredient(
        id: IdGenerator.generateId(),
        name: _nameController.text,
        category: _selectedCategory,
        unit: _selectedUnit,
        proteinType: _selectedProteinType?.name,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      final dbHelper = DatabaseHelper();
      await dbHelper.insertIngredient(ingredient);

      if (mounted) {
        Navigator.pop(context, ingredient);
      }
    } on ValidationException catch (e) {
      _showErrorSnackBar(e.message);
    } on DuplicateException catch (e) {
      _showErrorSnackBar(e.message);
    } on GastrobrainException catch (e) {
      _showErrorSnackBar('Error saving ingredient: ${e.message}');
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

  String formatCategoryName(String category) {
    // Convert snake_case to Title Case
    if (category.contains('_')) {
      return category
          .split('_')
          .map((word) => word[0].toUpperCase() + word.substring(1))
          .join(' ');
    }
    // Simple capitalization for single words
    return category[0].toUpperCase() + category.substring(1);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Ingredient'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ingredient Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an ingredient name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(formatCategoryName(category)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
<<<<<<< HEAD
=======
                    _selectedCategory = value!;
>>>>>>> fix/ingredients-temporary-recipe
                    if (value != 'protein') {
                      _selectedProteinType = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // Unit Dropdown
              DropdownButtonFormField<String>(
                value: _selectedUnit,
                decoration: const InputDecoration(
                  labelText: 'Unit (Optional)',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('No unit'),
                  ),
                  ..._units.map((unit) {
                    return DropdownMenuItem(
                      value: unit,
                      child: Text(unit),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedUnit = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Protein Type (only shown for protein category)
              if (_selectedCategory == 'protein')
                DropdownButtonFormField<ProteinType>(
                  value: _selectedProteinType,
                  decoration: const InputDecoration(
                    labelText: 'Protein Type',
                    border: OutlineInputBorder(),
                  ),
                  items: ProteinType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProteinType = value;
                    });
                  },
                  validator: (value) {
                    if (_selectedCategory == 'protein' && value == null) {
                      return 'Please select a protein type';
                    }
                    return null;
                  },
                ),

              if (_selectedCategory == 'protein') const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Any additional information',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveIngredient,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
