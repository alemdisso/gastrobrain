import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../screens/recipe_ingredients_screen.dart';
//import '../screens/cook_meal_screen.dart';
import '../screens/meal_history_screen.dart';
import '../database/database_helper.dart';

class RecipeCard extends StatefulWidget {
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
  State<RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends State<RecipeCard> {
  bool isExpanded = false;
  DateTime? lastCooked;
  int totalMeals = 0;

  @override
  void initState() {
    super.initState();
    _loadMealStats();
  }

  Future<void> _loadMealStats() async {
    final dbHelper = DatabaseHelper();
    final lastCookedDate = await dbHelper.getLastCookedDate(widget.recipe.id);
    final mealsCount = await dbHelper.getTimesCookedCount(widget.recipe.id);

    if (mounted) {
      setState(() {
        lastCooked = lastCookedDate;
        totalMeals = mealsCount;
      });
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Never';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
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
                    const Text('D: '),
                    ...List.generate(
                        5,
                        (index) => Icon(
                              index < widget.recipe.difficulty
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 16,
                              color: index < widget.recipe.difficulty
                                  ? Colors.amber
                                  : Colors.grey,
                            )),
                    const SizedBox(width: 16),
                    // Rating stars
                    const Text('R: '),
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
                    Icon(Icons.timer, size: 16),
                    const SizedBox(width: 4),
                    Text(
                        '${widget.recipe.prepTimeMinutes}/${widget.recipe.cookTimeMinutes}min'),
                    const SizedBox(width: 16),
                    Icon(Icons.repeat, size: 16),
                    const SizedBox(width: 4),
                    Text(widget.recipe.desiredFrequency),
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
                  onPressed: () {
                    setState(() {
                      isExpanded = !isExpanded;
                    });
                  },
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
                          Text('Last cooked: ${_formatDateTime(lastCooked)}'),
                          Text('Times cooked: $totalMeals'),
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
