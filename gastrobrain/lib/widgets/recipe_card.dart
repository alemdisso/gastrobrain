import 'package:flutter/material.dart';
import '../models/recipe.dart';
//import '../screens/cook_meal_screen.dart';
//import '../screens/edit_recipe_screen.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final Function() onEdit;
  final Function() onDelete;
  final Function() onCooked;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onEdit,
    required this.onDelete,
    required this.onCooked,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(
          recipe.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                // Difficulty stars
                const Text('D: '),
                ...List.generate(
                    5,
                    (index) => Icon(
                          index < recipe.difficulty
                              ? Icons.star
                              : Icons.star_border,
                          size: 16,
                          color: index < recipe.difficulty
                              ? Colors.amber
                              : Colors.grey,
                        )),
                const SizedBox(width: 16),
                // Rating stars
                const Text('R: '),
                ...List.generate(
                    5,
                    (index) => Icon(
                          index < recipe.rating
                              ? Icons.star
                              : Icons.star_border,
                          size: 16,
                          color: index < recipe.rating
                              ? Colors.amber
                              : Colors.grey,
                        )),
              ],
            ),
            Row(
              children: [
                Icon(Icons.timer, size: 16),
                const SizedBox(width: 4),
                Text('${recipe.prepTimeMinutes}/${recipe.cookTimeMinutes}min'),
                const SizedBox(width: 16),
                Icon(Icons.repeat, size: 16),
                const SizedBox(width: 4),
                Text(recipe.desiredFrequency),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.restaurant),
              onPressed: onCooked,
              tooltip: 'Cook Now',
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit();
                    break;
                  case 'delete':
                    onDelete();
                    break;
                }
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
          ],
        ),
      ),
    );
  }
}
