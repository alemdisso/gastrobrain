// lib/widgets/weekly_calendar_widget.dart

import 'package:flutter/material.dart';
import '../models/meal_plan.dart';
import '../models/meal_plan_item.dart';
import '../models/recipe.dart';
import '../database/database_helper.dart';

class WeeklyCalendarWidget extends StatefulWidget {
  final DateTime weekStartDate;
  final MealPlan? mealPlan;
  final Function(DateTime date, String mealType)? onSlotTap;
  final Function(DateTime date, String mealType, String recipeId)? onMealTap;

  const WeeklyCalendarWidget({
    super.key,
    required this.weekStartDate,
    this.mealPlan,
    this.onSlotTap,
    this.onMealTap,
  });

  @override
  State<WeeklyCalendarWidget> createState() => _WeeklyCalendarWidgetState();
}

class _WeeklyCalendarWidgetState extends State<WeeklyCalendarWidget> {
  final List<String> _weekdayNames = [
    'Friday',
    'Saturday',
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday'
  ];
  late List<DateTime> _weekDates;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Cache for recipe details
  final Map<String, Recipe> _recipes = {};

  @override
  void initState() {
    super.initState();
    _initializeWeekDates();
    _prefetchRecipes();
  }

  @override
  void didUpdateWidget(WeeklyCalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weekStartDate != widget.weekStartDate ||
        oldWidget.mealPlan != widget.mealPlan) {
      _initializeWeekDates();
      _prefetchRecipes();
    }
  }

  void _initializeWeekDates() {
    // Ensure we start with a Friday
    // Calculate days to subtract to get to the previous Friday
    // If today is Friday (weekday 5), subtract 0; otherwise calculate offset
    final daysToSubtract = widget.weekStartDate.weekday < 5
        ? widget.weekStartDate.weekday + 2 // Go back to previous Friday
        : widget.weekStartDate.weekday - 5; // Friday is day 5

    final friday = DateTime(
      widget.weekStartDate.year,
      widget.weekStartDate.month,
      widget.weekStartDate.day - daysToSubtract,
    );

    _weekDates = List.generate(
      7,
      (index) => friday.add(Duration(days: index)),
    );
  }

  Future<void> _prefetchRecipes() async {
    if (widget.mealPlan == null || widget.mealPlan!.items.isEmpty) {
      return;
    }

    // Get unique recipe IDs from meal plan
    final recipeIds =
        widget.mealPlan!.items.map((item) => item.recipeId).toSet().toList();

    // Fetch recipe details for each ID
    for (final id in recipeIds) {
      if (!_recipes.containsKey(id)) {
        final recipe = await _dbHelper.getRecipe(id);
        if (recipe != null && mounted) {
          setState(() {
            _recipes[id] = recipe;
          });
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 7,
      itemBuilder: (context, index) {
        final date = _weekDates[index];
        return _buildDaySection(date, index);
      },
    );
  }

  Widget _buildDaySection(DateTime date, int dayIndex) {
    final today = DateTime.now();
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isToday
          ? Theme.of(context).colorScheme.primaryContainer.withAlpha(64)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day header
            Row(
              children: [
                Text(
                  _weekdayNames[dayIndex],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color:
                        isToday ? Theme.of(context).colorScheme.primary : null,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(date),
                  style: TextStyle(
                    color: isToday
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                ),
                if (isToday) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Today',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const Divider(),

            // Lunch section
            _buildMealSection(date, MealPlanItem.lunch),

            const SizedBox(height: 8),

            // Dinner section
            _buildMealSection(date, MealPlanItem.dinner),
          ],
        ),
      ),
    );
  }

  Widget _buildMealSection(DateTime date, String mealType) {
    // Find if there's a meal planned for this slot
    final MealPlanItem? plannedMeal = widget.mealPlan
        ?.getItemsForDateAndMealType(
          date,
          mealType,
        )
        .firstOrNull;

    // Get recipe details if available
    final Recipe? recipe =
        plannedMeal != null ? _recipes[plannedMeal.recipeId] : null;

    final bool hasPlannedMeal = plannedMeal != null && recipe != null;

    return InkWell(
      onTap: () {
        if (hasPlannedMeal && widget.onMealTap != null) {
          widget.onMealTap!(date, mealType, plannedMeal.recipeId);
        } else if (widget.onSlotTap != null) {
          widget.onSlotTap!(date, mealType);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hasPlannedMeal
              ? Theme.of(context).colorScheme.secondaryContainer.withAlpha(128)
              : Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: hasPlannedMeal
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.outline.withAlpha(76),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Meal type indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withAlpha(40),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                mealType == MealPlanItem.lunch ? 'Lunch' : 'Dinner',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Recipe info or placeholder
            Expanded(
              child: hasPlannedMeal
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            // Difficulty
                            Row(
                              children: List.generate(
                                5,
                                (index) => Icon(
                                  index < recipe.difficulty
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 16,
                                  color: index < recipe.difficulty
                                      ? Colors.amber
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Time
                            Row(
                              children: [
                                const Icon(Icons.timer, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                    '${recipe.prepTimeMinutes + recipe.cookTimeMinutes} min'),
                              ],
                            ),
                          ],
                        ),
                      ],
                    )
                  : const Row(
                      children: [
                        Icon(Icons.add),
                        SizedBox(width: 8),
                        Text(
                          'Add meal',
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
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
}
