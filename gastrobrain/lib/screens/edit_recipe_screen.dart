import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../database/database_helper.dart';

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
  late TextEditingController _prepTimeController;
  late TextEditingController _cookTimeController;
  late String _selectedFrequency;
  late int _difficulty;
  late int _rating;

  final List<String> _frequencies = [
    'daily',
    'weekly',
    'biweekly',
    'monthly',
    'rarely'
  ];

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing recipe data
    _nameController = TextEditingController(text: widget.recipe.name);
    _notesController = TextEditingController(text: widget.recipe.notes);
    _prepTimeController =
        TextEditingController(text: widget.recipe.prepTimeMinutes.toString());
    _cookTimeController =
        TextEditingController(text: widget.recipe.cookTimeMinutes.toString());
    _selectedFrequency = widget.recipe.desiredFrequency;
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

  void _saveRecipe() async {
    if (_formKey.currentState!.validate()) {
      final updatedRecipe = Recipe(
        id: widget.recipe.id, // Keep the same ID
        name: _nameController.text,
        desiredFrequency: _selectedFrequency,
        notes: _notesController.text,
        createdAt: widget.recipe.createdAt, // Keep original creation date
        difficulty: _difficulty,
        prepTimeMinutes: int.tryParse(_prepTimeController.text) ?? 0,
        cookTimeMinutes: int.tryParse(_cookTimeController.text) ?? 0,
        rating: _rating,
      );

      final dbHelper = DatabaseHelper();
      await dbHelper.updateRecipe(updatedRecipe);

      if (mounted) {
        Navigator.pop(context, true);
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
        title: const Text('Edit Recipe'),
      ),
      body: SingleChildScrollView(
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
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveRecipe,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Save Changes'),
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
