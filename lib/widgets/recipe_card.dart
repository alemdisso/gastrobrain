import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../screens/recipe_details_screen.dart';
import '../core/providers/recipe_provider.dart';

class RecipeCard extends StatefulWidget {
  final Recipe recipe;
  final Function() onEdit;
  final Function() onDelete;
  final Function() onCooked;
  final int mealCount; // New parameter
  final DateTime? lastCooked; // New parameter

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onEdit,
    required this.onDelete,
    required this.onCooked,
    required this.mealCount,
    required this.lastCooked,
  });

  @override
  State<RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends State<RecipeCard> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: _handleCardTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              widget.recipe.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          // Info and Actions Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 12),
            child: Row(
              children: [
                // Left side - Information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category row
                      Row(
                        children: [
                          const Icon(Icons.category,
                              size: 16, color: Colors.blue),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              widget.recipe.category
                                  .getLocalizedDisplayName(context),
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Time and rating row
                      Row(
                        children: [
                          Icon(
                            widget.recipe.difficulty >= 4
                                ? Icons.warning
                                : Icons.timer,
                            size: 16,
                            color: widget.recipe.difficulty >= 4
                                ? Colors.orange
                                : null,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.recipe.prepTimeMinutes + widget.recipe.cookTimeMinutes} min',
                            style: TextStyle(
                              color: widget.recipe.difficulty >= 4
                                  ? Colors.orange
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Rating stars (5-star scale)
                          ...List.generate(5, (index) {
                            return Icon(
                              index < widget.recipe.rating ? Icons.star : Icons.star_border,
                              size: 16,
                              color: index < widget.recipe.rating ? Colors.amber : Colors.grey,
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Future<void> _handleCardTap() async {
    final hasChanges = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailsScreen(recipe: widget.recipe),
      ),
    );

    // If changes were made to the recipe, refresh the recipe list
    if (hasChanges == true && mounted) {
      context.read<RecipeProvider>().loadRecipes(forceRefresh: true);
    }
  }
}
