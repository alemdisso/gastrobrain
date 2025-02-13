import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../database/database_helper.dart';

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedFrequency = 'monthly';

  final List<String> _frequencies = [
    'daily',
    'weekly',
    'biweekly',
    'monthly',
    'rarely'
  ];

  void _saveRecipe() async {
    if (_formKey.currentState!.validate()) {
      final recipe = Recipe(
        id: DateTime.now().toString(), // We'll improve ID generation later
        name: _nameController.text,
        desiredFrequency: _selectedFrequency,
        notes: _notesController.text,
        createdAt: DateTime.now(),
      );

      final dbHelper = DatabaseHelper();
      await dbHelper.insertRecipe(recipe);

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Recipe'),
      ),
      body: Padding(
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
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveRecipe,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Save Recipe'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
