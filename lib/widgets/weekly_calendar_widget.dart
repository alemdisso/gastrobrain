// lib/widgets/weekly_calendar_widget.dart

import 'package:flutter/material.dart';
import '../models/meal_plan.dart';
import '../models/meal_plan_item.dart';
import '../models/recipe.dart';
import '../models/time_context.dart';
import '../core/di/service_provider.dart';
import '../database/database_helper.dart';

class WeeklyCalendarWidget extends StatefulWidget {
  final DateTime weekStartDate;
  final MealPlan? mealPlan;
  final TimeContext timeContext;
  final Function(DateTime date, String mealType)? onSlotTap;
  final Function(DateTime date, String mealType, String recipeId)? onMealTap;
  final Function(DateTime selectedDate, int selectedDayIndex)? onDaySelected;
  final ScrollController? scrollController;
  final DatabaseHelper? databaseHelper;

  const WeeklyCalendarWidget({
    super.key,
    required this.weekStartDate,
    this.mealPlan,
    required this.timeContext,
    this.onSlotTap,
    this.onMealTap,
    this.onDaySelected,
    this.scrollController,
    this.databaseHelper,
  });

  @override
  State<WeeklyCalendarWidget> createState() => _WeeklyCalendarWidgetState();
}

class _WeeklyCalendarWidgetState extends State<WeeklyCalendarWidget>
    with SingleTickerProviderStateMixin {
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
  late DatabaseHelper _dbHelper;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Cache for recipe details
  final Map<String, Recipe> _recipes = {};

  int _selectedDayIndex = 0; // Default to first day (Friday)

  @override
  void initState() {
    super.initState();
    _dbHelper = widget.databaseHelper ?? ServiceProvider.database.dbHelper;
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _initializeWeekDates();
    _prefetchRecipes();
    
    // Start animation
    _animationController.forward();
  }

  @override
  void didUpdateWidget(WeeklyCalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weekStartDate != widget.weekStartDate ||
        oldWidget.mealPlan != widget.mealPlan ||
        oldWidget.timeContext != widget.timeContext) {
      _initializeWeekDates();
      _prefetchRecipes();
      
      // Trigger fade animation on context change
      if (oldWidget.timeContext != widget.timeContext) {
        _animationController.reset();
        _animationController.forward();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

    // Get unique recipe IDs from all mealPlanItemRecipes across all items
    final recipeIds = <String>{};

    for (final item in widget.mealPlan!.items) {
      if (item.mealPlanItemRecipes != null) {
        for (final recipe in item.mealPlanItemRecipes!) {
          recipeIds.add(recipe.recipeId);
        }
      }
    }

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

  bool _hasPrimaryRecipe(MealPlanItem? plannedMeal) {
    return plannedMeal != null &&
        plannedMeal.mealPlanItemRecipes != null &&
        plannedMeal.mealPlanItemRecipes!.isNotEmpty;
  }

  String? _getPrimaryRecipeId(MealPlanItem? plannedMeal) {
    if (_hasPrimaryRecipe(plannedMeal)) {
      return plannedMeal!.mealPlanItemRecipes!.first.recipeId;
    }
    return null;
  }

  void _handleTap(DateTime date, String mealType, MealPlanItem? plannedMeal,
      bool hasPlannedMeal) {
    final hasPrimaryRecipe = _hasPrimaryRecipe(plannedMeal);

    if (hasPlannedMeal && widget.onMealTap != null && hasPrimaryRecipe) {
      // Call onMealTap with the primary recipe ID
      final primaryRecipeId = _getPrimaryRecipeId(plannedMeal);
      widget.onMealTap!(date, mealType, primaryRecipeId!);
    } else if (widget.onSlotTap != null) {
      // No meal or no recipes, call onSlotTap to add a meal
      widget.onSlotTap!(date, mealType);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Gets the color modifier based on time context
  double _getContextOpacity() {
    switch (widget.timeContext) {
      case TimeContext.past:
        return 0.6; // Faded for past weeks
      case TimeContext.current:
        return 1.0; // Full opacity for current week
      case TimeContext.future:
        return 0.85; // Slightly reduced for future weeks
    }
  }

  /// Gets the context-specific color tint
  Color _getContextTint(BuildContext context) {
    switch (widget.timeContext) {
      case TimeContext.past:
        return Colors.grey.withAlpha(51); // Gray tint for past
      case TimeContext.current:
        return Colors.transparent; // No tint for current
      case TimeContext.future:
        return Theme.of(context).colorScheme.primary.withAlpha(25); // Blue tint for future
    }
  }

  /// Applies context-aware styling to a color
  Color _applyContextStyling(BuildContext context, Color baseColor) {
    final opacity = _getContextOpacity();
    final tint = _getContextTint(context);
    
    if (tint == Colors.transparent) {
      return baseColor.withValues(alpha: baseColor.alpha * opacity);
    } else {
      // Blend the base color with the tint
      return Color.alphaBlend(tint, baseColor.withValues(alpha: baseColor.alpha * opacity));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    // Check screen width to determine layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // If in landscape on a smaller device, use a more compact layout
    if (isLandscape && screenWidth < 960) {
      // Use a more horizontal layout with smaller meal cards
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Two columns
          childAspectRatio: 2.5, // Wider than tall
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 14, // 7 days * 2 meal types
        itemBuilder: (context, index) {
          final dayIndex = index ~/ 2; // Integer division
          final isLunch = index % 2 == 0;
          final date = _weekDates[dayIndex];

          return _buildCompactMealTile(date,
              isLunch ? MealPlanItem.lunch : MealPlanItem.dinner, dayIndex);
        },
        padding: const EdgeInsets.all(8),
      );
    }

    // For wider screens (tablets/desktop), use a side-by-side layout
    if (screenWidth > 600) {
      return Row(
        children: [
          // Left side: weekday selection
          SizedBox(
            width: 120, // Fixed width for day selector
            child: ListView.builder(
              controller: widget.scrollController, // Use it here
              itemCount: 7,
              itemBuilder: (context, index) {
                final date = _weekDates[index];
                return _buildDaySelector(date, index);
              },
            ),
          ),

          // Right side: selected day's meals
          Expanded(
            child: _buildDaySection(
                _weekDates[_selectedDayIndex], _selectedDayIndex),
          ),
        ],
      );
    }
    // For narrower screens (phones), keep the current vertical layout
    else {
      return ListView.builder(
        controller: widget.scrollController, // Use it here
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = _weekDates[index];
          return _buildDaySection(date, index);
        },
      );
    }
  }

  Widget _buildCompactMealTile(DateTime date, String mealType, int dayIndex) {
    // Find if there's a meal planned for this slot
    final MealPlanItem? plannedMeal =
        widget.mealPlan?.getItemsForDateAndMealType(date, mealType).firstOrNull;

    // Get the first recipe (primary dish) if any recipes are associated
    final primaryRecipeId = _getPrimaryRecipeId(plannedMeal);
    final Recipe? recipe =
        primaryRecipeId != null ? _recipes[primaryRecipeId] : null;

    final bool hasPlannedMeal = plannedMeal != null && recipe != null;

    return Card(
      color: _applyContextStyling(context, Theme.of(context).cardColor),
      child: InkWell(
        onTap: () => _handleTap(date, mealType, plannedMeal, hasPlannedMeal),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Day + meal
              Text(
                '${_weekdayNames[dayIndex]} ${mealType == MealPlanItem.lunch ? 'Lunch' : 'Dinner'}',
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 12,
                  color: _applyContextStyling(context, Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black),
                ),
              ),

              // Recipe or placeholder
              hasPlannedMeal
                  ? Text(
                      recipe.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: _applyContextStyling(context, Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black),
                      ),
                    )
                  : Text(
                      'Add meal',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: _applyContextStyling(context, Colors.grey),
                        fontSize: 14,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDaySelector(DateTime date, int dayIndex) {
    final today = DateTime.now();
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final isSelected = dayIndex == _selectedDayIndex;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: _applyContextStyling(context, isSelected
          ? Theme.of(context).colorScheme.primary.withAlpha(64)
          : (isToday
              ? Theme.of(context).colorScheme.primaryContainer.withAlpha(64)
              : Theme.of(context).cardColor)),
      child: InkWell(
        onTap: () {
          // Update selected day when tapped
          setState(() {
            _selectedDayIndex = dayIndex;
          });

          // Notify parent about the day selection
          if (widget.onDaySelected != null) {
            widget.onDaySelected!(_weekDates[dayIndex], dayIndex);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text(
                _weekdayNames[dayIndex],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _applyContextStyling(context, isSelected
                      ? Theme.of(context).colorScheme.primary
                      : (isToday
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black)),
                ),
              ),
              Text(
                date.day.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: _applyContextStyling(context, Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDaySection(DateTime date, int dayIndex) {
    final today = DateTime.now();
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: _applyContextStyling(context, isToday
          ? Theme.of(context).colorScheme.primaryContainer.withAlpha(64)
          : Theme.of(context).cardColor),
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
                    color: _applyContextStyling(context, isToday 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(date),
                  style: TextStyle(
                    color: _applyContextStyling(context, isToday
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey),
                  ),
                ),
                if (isToday) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _applyContextStyling(context, Theme.of(context).colorScheme.primary),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Today',
                      style: TextStyle(
                        color: _applyContextStyling(context, Theme.of(context).colorScheme.onPrimary),
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

    // Get the first recipe (primary dish) if any recipes are associated
    final primaryRecipeId = _getPrimaryRecipeId(plannedMeal);
    final Recipe? recipe =
        primaryRecipeId != null ? _recipes[primaryRecipeId] : null;

    final bool hasPlannedMeal = plannedMeal != null && recipe != null;

    // Define meal-specific colors
    // Check if this meal has been cooked using the mealPlanItem's info
    final bool hasBeenCooked =
        plannedMeal != null ? plannedMeal.hasBeenCooked : false;

    final Color backgroundColor = _applyContextStyling(context, !hasPlannedMeal
        ? Theme.of(context).colorScheme.surface
        : hasBeenCooked
            ? Colors.green.withAlpha(64) // Light green for cooked meals
            : mealType == MealPlanItem.lunch
                ? Theme.of(context).colorScheme.primaryContainer.withAlpha(128)
                : Theme.of(context)
                    .colorScheme
                    .secondaryContainer
                    .withAlpha(128));

    final Color borderColor = _applyContextStyling(context, hasPlannedMeal
        ? mealType == MealPlanItem.lunch
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.secondary
        : Theme.of(context).colorScheme.outline.withAlpha(76));

    final screenWidth = MediaQuery.of(context).size.width;
    final EdgeInsets contentPadding = screenWidth < 360
        ? const EdgeInsets.all(8) // Small screens get tighter padding
        : const EdgeInsets.all(12); // Larger screens get more space

    return InkWell(
      onTap: () => _handleTap(date, mealType, plannedMeal, hasPlannedMeal),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: contentPadding,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Meal type indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _applyContextStyling(context, mealType == MealPlanItem.lunch
                    ? Theme.of(context).colorScheme.primary.withAlpha(40)
                    : Theme.of(context).colorScheme.secondary.withAlpha(40)),
                borderRadius: BorderRadius.circular(4),
                // Optional: add a subtle shadow for more dimension
                boxShadow: [
                  BoxShadow(
                    color: _applyContextStyling(context, Colors.black.withAlpha(13)),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Add a relevant icon
                  Icon(
                    mealType == MealPlanItem.lunch
                        ? Icons.wb_sunny_outlined // Sun icon for lunch
                        : Icons.nightlight_outlined, // Moon icon for dinner
                    size: 16,
                    color: _applyContextStyling(context, mealType == MealPlanItem.lunch
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondary),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    mealType == MealPlanItem.lunch ? 'Lunch' : 'Dinner',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _applyContextStyling(context, mealType == MealPlanItem.lunch
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.secondary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Recipe info or placeholder
            Expanded(
              child: hasPlannedMeal
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                recipe.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: _applyContextStyling(context, Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black),
                                ),
                              ),
                            ),
                            // Show recipe count badge if more than one recipe
                            if (plannedMeal.mealPlanItemRecipes != null &&
                                plannedMeal.mealPlanItemRecipes!.length >
                                    1) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _applyContextStyling(context, Theme.of(context)
                                      .colorScheme
                                      .primaryContainer),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${plannedMeal.mealPlanItemRecipes!.length - 1} recipes',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _applyContextStyling(context, Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            // Add check mark icon for cooked meals
                            if (hasBeenCooked)
                              Tooltip(
                                message: 'Cooked',
                                child: Icon(
                                  Icons.check_circle,
                                  color: _applyContextStyling(context, Colors.green),
                                  size: 20,
                                ),
                              ),
                          ],
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
                                  color: _applyContextStyling(context, index < recipe.difficulty
                                      ? Colors.amber
                                      : Colors.grey),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Time
                            Row(
                              children: [
                                Icon(Icons.timer, size: 16, color: _applyContextStyling(context, Theme.of(context).iconTheme.color ?? Colors.grey)),
                                const SizedBox(width: 4),
                                Text(
                                    '${recipe.prepTimeMinutes + recipe.cookTimeMinutes} min',
                                    style: TextStyle(color: _applyContextStyling(context, Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black))),
                              ],
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Icon(Icons.add, color: _applyContextStyling(context, Theme.of(context).iconTheme.color ?? Colors.grey)),
                        const SizedBox(width: 8),
                        Text(
                          'Add meal',
                          style: TextStyle(
                            color: _applyContextStyling(context, Colors.grey),
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
