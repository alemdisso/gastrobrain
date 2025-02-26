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
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
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
    // Ensure we start with a Monday
    final monday = DateTime(
      widget.weekStartDate.year,
      widget.weekStartDate.month,
      widget.weekStartDate.day - (widget.weekStartDate.weekday - 1),
    );

    _weekDates = List.generate(
      7,
      (index) => monday.add(Duration(days: index)),
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
    return '${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine if we're in landscape or portrait
        final isLandscape = constraints.maxWidth > constraints.maxHeight;

        return Column(
          children: [
            // Header row with weekday names
            _buildHeaderRow(),

            // Calendar grid with meal slots
            Expanded(
              child: _buildCalendarGrid(isLandscape),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeaderRow() {
    final today = DateTime.now();

    return Row(
      children: List.generate(
        7,
        (index) {
          final date = _weekDates[index];
          final isToday = date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;

          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isToday
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                borderRadius: isToday ? BorderRadius.circular(8) : null,
              ),
              child: Column(
                children: [
                  Text(
                    _weekdayNames[index],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isToday
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : null,
                    ),
                  ),
                  Text(
                    _formatDate(_weekDates[index]),
                    style: TextStyle(
                      color: isToday
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalendarGrid(bool isLandscape) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(
        7,
        (dayIndex) {
          final date = _weekDates[dayIndex];
          return Expanded(
            child: Column(
              children: [
                // Lunch slot
                Expanded(
                  child: _buildMealSlot(date, MealPlanItem.lunch, isLandscape),
                ),

                // Small divider
                const Divider(height: 1),

                // Dinner slot
                Expanded(
                  child: _buildMealSlot(date, MealPlanItem.dinner, isLandscape),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMealSlot(DateTime date, String mealType, bool isLandscape) {
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

    final bool hasPlannedMeal = plannedMeal != null;

    // Create the slot with appropriate styling
    return InkWell(
      onTap: () {
        if (hasPlannedMeal && widget.onMealTap != null) {
          widget.onMealTap!(date, mealType, plannedMeal.recipeId);
        } else if (widget.onSlotTap != null) {
          widget.onSlotTap!(date, mealType);
        }
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.all(4),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Meal type indicator
            Text(
              mealType == MealPlanItem.lunch ? 'Lunch' : 'Dinner',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),

            if (hasPlannedMeal && recipe != null) ...[
              const SizedBox(height: 4),
              // Recipe name
              Expanded(
                child: Center(
                  child: Text(
                    recipe.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: isLandscape ? 3 : 2,
                  ),
                ),
              ),
              // Optional rating display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < recipe.difficulty ? Icons.star : Icons.star_border,
                    size: 12,
                    color:
                        index < recipe.difficulty ? Colors.amber : Colors.grey,
                  ),
                ),
              ),
            ] else ...[
              // Empty slot display
              Expanded(
                child: Center(
                  child: Icon(
                    Icons.add,
                    color: Theme.of(context).colorScheme.outline.withAlpha(128),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
