// lib/models/meal_plan.dart

import 'meal_plan_item.dart';

class MealPlan {
  String id;
  DateTime weekStartDate;
  String notes;
  DateTime createdAt;
  DateTime modifiedAt;
  List<MealPlanItem> items;

  MealPlan({
    required this.id,
    required this.weekStartDate,
    this.notes = '',
    required this.createdAt,
    required this.modifiedAt,
    List<MealPlanItem> items = const [],
  }) : items = List<MealPlanItem>.from(
            items); // Create a mutable copy of the items list

  // Convert a MealPlan to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'week_start_date': weekStartDate.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'modified_at': modifiedAt.toIso8601String(),
    };
  }

  // Create a MealPlan from a Map and a list of MealPlanItems
  factory MealPlan.fromMap(Map<String, dynamic> map, List<MealPlanItem> items) {
    return MealPlan(
      id: map['id'],
      weekStartDate: DateTime.parse(map['week_start_date']),
      notes: map['notes'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      modifiedAt: DateTime.parse(map['modified_at']),
      items: items,
    );
  }

  // Calculate end date (7 days from start)
  DateTime get weekEndDate {
    return weekStartDate.add(const Duration(days: 6));
  }

  // Get only items for a specific date
  List<MealPlanItem> getItemsForDate(DateTime date) {
    // Normalize the date to remove time component
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return items.where((item) {
      final itemDate = DateTime.parse(item.plannedDate);
      final normalizedItemDate =
          DateTime(itemDate.year, itemDate.month, itemDate.day);
      return normalizedItemDate.isAtSameMomentAs(normalizedDate);
    }).toList();
  }

  // Get only items for a specific meal type (lunch or dinner)
  List<MealPlanItem> getItemsForMealType(String mealType) {
    return items.where((item) => item.mealType == mealType).toList();
  }

  // Get items for both a specific date and meal type
  List<MealPlanItem> getItemsForDateAndMealType(
      DateTime date, String mealType) {
    // Normalize the date to remove time component
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return items.where((item) {
      final itemDate = DateTime.parse(item.plannedDate);
      final normalizedItemDate =
          DateTime(itemDate.year, itemDate.month, itemDate.day);
      return normalizedItemDate.isAtSameMomentAs(normalizedDate) &&
          item.mealType == mealType;
    }).toList();
  }

  // Create a new MealPlan for the week containing the given date
  factory MealPlan.forWeek(String id, DateTime date) {
    // Calculate the previous Friday (or today if it's already Friday)
    final int weekday = date.weekday;
    // If today is Friday (weekday 5), subtract 0; otherwise calculate offset
    final daysToSubtract = weekday < 5
        ? weekday + 2 // Go back to previous Friday
        : weekday - 5; // Friday is day 5

    final DateTime weekStart = date.subtract(Duration(days: daysToSubtract));
    // Normalize to start of day
    final DateTime normalizedWeekStart =
        DateTime(weekStart.year, weekStart.month, weekStart.day);

    final now = DateTime.now();

    return MealPlan(
      id: id,
      weekStartDate: normalizedWeekStart,
      createdAt: now,
      modifiedAt: now,
    );
  }

  // Add an item to this meal plan
  void addItem(MealPlanItem item) {
    items.add(item);
    // Add a small delay to ensure timestamp difference
    modifiedAt = DateTime.now();
  }

  // Remove an item from this meal plan
  bool removeItem(String itemId) {
    final initialLength = items.length;
    items.removeWhere((item) => item.id == itemId);
    final removed = items.length < initialLength;

    if (removed) {
      modifiedAt = DateTime.now();
    }

    return removed;
  }

  // Update an existing item
  bool updateItem(MealPlanItem updatedItem) {
    final index = items.indexWhere((item) => item.id == updatedItem.id);

    if (index != -1) {
      items[index] = updatedItem;
      modifiedAt = DateTime.now();
      return true;
    }
    return false;
  }
}
