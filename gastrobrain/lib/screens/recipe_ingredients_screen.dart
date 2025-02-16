import 'package:flutter/material.dart';
import '../models/recipe.dart';
//import '../models/ingredient.dart';
//import '../models/recipe_ingredient.dart';
import '../models/protein_type.dart';
import '../database/database_helper.dart';
import '../widgets/add_ingredient_dialog.dart';
import '../core/errors/gastrobrain_exceptions.dart';

class RecipeIngredientsScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeIngredientsScreen({super.key, required this.recipe});

  @override
  State<RecipeIngredientsScreen> createState() =>
      _RecipeIngredientsScreenState();
}

class _RecipeIngredientsScreenState extends State<RecipeIngredientsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _ingredients = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ingredients =
          await _dbHelper.getRecipeIngredients(widget.recipe.id);
      if (mounted) {
        setState(() {
          _ingredients = ingredients;
          _isLoading = false;
        });
      }
    } on NotFoundException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } on GastrobrainException catch (e) {
      setState(() {
        _errorMessage = 'Error loading ingredients: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'An unexpected error occurred while loading ingredients';
        _isLoading = false;
      });
    }
  }

  void _addIngredient() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddIngredientDialog(recipe: widget.recipe),
    );

    if (result == true) {
      _loadIngredients();
    }
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'An error occurred',
            style: const TextStyle(fontSize: 18, color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadIngredients,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.no_food, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No ingredients added yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _addIngredient,
            icon: const Icon(Icons.add),
            label: const Text('Add Ingredient'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ingredients: ${widget.recipe.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadIngredients,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _ingredients.isEmpty
                  ? _buildEmptyView()
                  : ListView.builder(
                      itemCount: _ingredients.length,
                      itemBuilder: (context, index) {
                        final ingredient = _ingredients[index];
                        final proteinType = ingredient['protein_type'] != null
                            ? ProteinType.values.firstWhere(
                                (e) => e.name == ingredient['protein_type'])
                            : null;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: ListTile(
                            leading: Icon(
                              proteinType != null
                                  ? Icons.egg_alt
                                  : Icons.food_bank,
                              color: proteinType?.isMainProtein == true
                                  ? Colors.red
                                  : null,
                            ),
                            title: Text(ingredient['name']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${ingredient['quantity']} ${ingredient['unit'] ?? ''}',
                                ),
                                if (ingredient['preparation_notes'] != null)
                                  Text(
                                    ingredient['preparation_notes'],
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                // We'll implement edit/delete next
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete),
                                      SizedBox(width: 8),
                                      Text('Delete'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addIngredient,
        tooltip: 'Add Ingredient',
        child: const Icon(Icons.add),
      ),
    );
  }
}
