import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../screens/recipe_ingredients_screen.dart';
import '../screens/meal_history_screen.dart';
import '../l10n/app_localizations.dart';

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

  String _formatDateTime(DateTime? dateTime, BuildContext context) {
    if (dateTime == null) return AppLocalizations.of(context)!.never;
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
                // Right side - Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 20,
                      ),
                      onPressed: _toggleExpanded,
                      tooltip: isExpanded
                          ? AppLocalizations.of(context)!.showLess
                          : AppLocalizations.of(context)!.showMore,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 24, minHeight: 24),
                    ),
                  ],
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
                  // Detailed time information
                  Row(
                    children: [
                      Icon(Icons.timer_outlined,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          AppLocalizations.of(context)!
                              .detailedPrepTime(widget.recipe.prepTimeMinutes),
                          style: TextStyle(color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.restaurant_outlined,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          AppLocalizations.of(context)!
                              .detailedCookTime(widget.recipe.cookTimeMinutes),
                          style: TextStyle(color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (widget.recipe.notes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      widget.recipe.notes,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.mealCount == 0 && widget.lastCooked == null
                                  ? AppLocalizations.of(context)!.neverCooked
                                  : AppLocalizations.of(context)!
                                      .detailedTimesCooked(widget.mealCount),
                              style: const TextStyle(fontSize: 13),
                            ),
                            if (widget.lastCooked != null) ...[
                              Text(
                                AppLocalizations.of(context)!.detailedLastCooked(
                                    _formatDateTime(widget.lastCooked, context)),
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          IconButton.outlined(
                            icon: const Icon(Icons.list_alt, size: 20),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RecipeIngredientsScreen(
                                      recipe: widget.recipe),
                                ),
                              );
                            },
                            tooltip: AppLocalizations.of(context)!.ingredients,
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
                            tooltip: AppLocalizations.of(context)!.history,
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
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    const Icon(Icons.edit),
                                    const SizedBox(width: 8),
                                    Text(AppLocalizations.of(context)!.edit),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const Icon(Icons.delete),
                                    const SizedBox(width: 8),
                                    Text(AppLocalizations.of(context)!.delete),
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
