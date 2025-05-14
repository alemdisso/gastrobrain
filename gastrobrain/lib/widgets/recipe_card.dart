import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../screens/recipe_ingredients_screen.dart';
//import '../screens/cook_meal_screen.dart';
import '../screens/meal_history_screen.dart';
//import '../database/database_helper.dart';

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
  DateTime? lastCooked;
  int totalMeals = 0;
  static final Set<String> _expandedIds = {};

  bool get isExpanded => _expandedIds.contains(widget.recipe.id);

  @override
  void initState() {
    super.initState();
    //_loadMealStats();
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Never';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  void _toggleExpanded() {
    setState(() {
      if (isExpanded) {
        _expandedIds.remove(widget.recipe.id);
      } else {
        _expandedIds.add(widget.recipe.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          ListTile(
            title: Text(
              widget.recipe.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Difficulty stars
                    ...List.generate(
                        5,
                        (index) => Icon(
                              index < widget.recipe.difficulty
                                  ? Icons.battery_full
                                  : Icons.battery_0_bar,
                              size: 16,
                              color: index < widget.recipe.difficulty
                                  ? Colors.green
                                  : Colors.grey,
                            )),
                    const SizedBox(width: 16),
                    // Rating stars
                    ...List.generate(
                        5,
                        (index) => Icon(
                              index < widget.recipe.rating
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 16,
                              color: index < widget.recipe.rating
                                  ? Colors.amber
                                  : Colors.grey,
                            )),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.timer, size: 16),
                    const SizedBox(width: 4),
                    Text(
                        '${widget.recipe.prepTimeMinutes}/${widget.recipe.cookTimeMinutes}min'),
                    const SizedBox(width: 16),
                    const Icon(Icons.repeat, size: 16),
                    const SizedBox(width: 4),
                    Text(widget.recipe.desiredFrequency.displayName),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.restaurant),
                  onPressed: widget.onCooked,
                  tooltip: 'Cook Now',
                ),
                IconButton(
                  icon:
                      Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: _toggleExpanded, // Use the new toggle method
                  tooltip: isExpanded ? 'Show Less' : 'Show More',
                ),
              ],
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.recipe.notes.isNotEmpty) ...[
                    const Text(
                      'Notes:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(widget.recipe.notes),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Times cooked: ${widget.mealCount}'),
                          Text(
                              'Last cooked: ${_formatDateTime(widget.lastCooked)}'),
                        ],
                      ),
                      Wrap(
                        spacing: 4, // horizontal space between buttons
                        children: [
                          IconButton.outlined(
                            icon: const Icon(Icons.food_bank, size: 20),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RecipeIngredientsScreen(
                                      recipe: widget.recipe),
                                ),
                              );
                            },
                            tooltip: 'Ingredients',
                          ),
                          IconButton.outlined(
                            icon: const Icon(Icons.history, size: 20),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      MealHistoryScreen(recipe: widget.recipe),
                                ),
                              );
                            },
                            tooltip: 'History',
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 20),
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  widget.onEdit();
                                  break;
                                case 'delete':
                                  widget.onDelete();
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
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
