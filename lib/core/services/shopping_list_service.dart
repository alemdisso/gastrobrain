import '../../database/database_helper.dart';
import '../../models/shopping_list.dart';
import '../../models/shopping_list_item.dart';
import 'ingredient_aggregator.dart';
import 'package:intl/intl.dart';

export 'unit_converter.dart' show UnitConversionException;

class ShoppingListService {
  final DatabaseHelper dbHelper;
  final IngredientAggregator _aggregator;

  ShoppingListService(this.dbHelper, {IngredientAggregator? aggregator})
      : _aggregator = aggregator ?? IngredientAggregator();

  /// Calculate projected ingredients for a date range without database writes.
  ///
  /// Used for preview mode (Stage 1). Returns a map of category names to
  /// lists of ingredient data. Does NOT write to database.
  Future<Map<String, List<Map<String, dynamic>>>>
      calculateProjectedIngredients({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final ingredients = await _extractIngredientsInRange(startDate, endDate);
    final filtered = _aggregator.applyExclusionRule(ingredients);
    final aggregated = _aggregator.aggregateIngredients(filtered);
    return _aggregator.groupByCategory(aggregated);
  }

  /// Generate a shopping list from a date range.
  ///
  /// Extracts ingredients from all meal plan items within the date range,
  /// applies exclusion rules, aggregates quantities, groups by category,
  /// and saves to the database.
  Future<ShoppingList> generateFromDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final listName = _generateListName(startDate, endDate);

    final ingredients = await _extractIngredientsInRange(startDate, endDate);
    final filtered = _aggregator.applyExclusionRule(ingredients);
    final aggregated = _aggregator.aggregateIngredients(filtered);
    final grouped = _aggregator.groupByCategory(aggregated);

    final mealPlan = await dbHelper.getMealPlanForWeek(startDate);
    final mealPlanModifiedAt = mealPlan?.modifiedAt;
    final mealPlanCookedAt = mealPlan?.lastCookedAt;

    final shoppingList = ShoppingList(
      name: listName,
      dateCreated: DateTime.now(),
      startDate: startDate,
      endDate: endDate,
      mealPlanModifiedAt: mealPlanModifiedAt,
      mealPlanCookedAt: mealPlanCookedAt,
    );

    final listId = await dbHelper.insertShoppingList(shoppingList);

    for (final entry in grouped.entries) {
      final category = entry.key;
      for (final ingredientData in entry.value) {
        final item = ShoppingListItem(
          shoppingListId: listId,
          ingredientName: ingredientData['name'] as String,
          quantity: ingredientData['quantity'] as double,
          unit: ingredientData['unit'] as String,
          category: category,
          toBuy: true,
        );
        await dbHelper.insertShoppingListItem(item);
      }
    }

    return shoppingList.copyWith(id: listId);
  }

  /// Generate a shopping list from curated (user-selected) ingredients.
  ///
  /// Used in Stage 2 (Refinement Mode). The curatedIngredients are already
  /// filtered, aggregated, and grouped — passed directly from user selection.
  Future<ShoppingList> generateFromCuratedIngredients({
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, List<Map<String, dynamic>>> curatedIngredients,
  }) async {
    final listName = _generateListName(startDate, endDate);

    final mealPlan = await dbHelper.getMealPlanForWeek(startDate);
    final mealPlanModifiedAt = mealPlan?.modifiedAt;
    final mealPlanCookedAt = mealPlan?.lastCookedAt;

    final shoppingList = ShoppingList(
      name: listName,
      dateCreated: DateTime.now(),
      startDate: startDate,
      endDate: endDate,
      mealPlanModifiedAt: mealPlanModifiedAt,
      mealPlanCookedAt: mealPlanCookedAt,
    );

    final listId = await dbHelper.insertShoppingList(shoppingList);

    for (final entry in curatedIngredients.entries) {
      final category = entry.key;
      for (final ingredientData in entry.value) {
        final item = ShoppingListItem(
          shoppingListId: listId,
          ingredientName: ingredientData['name'] as String,
          quantity: ingredientData['quantity'] as double,
          unit: ingredientData['unit'] as String,
          category: category,
          toBuy: true,
        );
        await dbHelper.insertShoppingListItem(item);
      }
    }

    return shoppingList.copyWith(id: listId);
  }

  /// Toggle the "to buy" state of a shopping list item.
  Future<void> toggleItemToBuy(int itemId) async {
    final item = await dbHelper.getShoppingListItem(itemId);
    if (item == null) return;

    final updated = item.copyWith(toBuy: !item.toBuy);
    await dbHelper.updateShoppingListItem(updated);
  }

  /// Generate a display name for the shopping list.
  String _generateListName(DateTime start, DateTime end) {
    final formatter = DateFormat('MMM d');
    return '${formatter.format(start)}-${end.day}';
  }

  /// Extract ingredients from meal plan items in date range.
  Future<List<Map<String, dynamic>>> _extractIngredientsInRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final List<Map<String, dynamic>> allIngredients = [];

    final startDateStr = startDate.toIso8601String().split('T')[0];
    final endDateStr = endDate.toIso8601String().split('T')[0];

    final mealPlans =
        await dbHelper.getMealPlansByDateRange(startDate, endDate);

    for (final mealPlan in mealPlans) {
      final itemsWithRecipes = await dbHelper.getMealPlanItems(mealPlan.id);

      for (final item in itemsWithRecipes) {
        if (item.plannedDate.compareTo(startDateStr) < 0 ||
            item.plannedDate.compareTo(endDateStr) > 0) {
          continue;
        }

        // Skip meals that have already been cooked.
        if (item.hasBeenCooked) continue;

        if (item.mealPlanItemRecipes == null ||
            item.mealPlanItemRecipes!.isEmpty) {
          continue;
        }

        // Add DB-linked simple sides using stored quantity/unit.
        final sides = item.mealPlanItemIngredients ?? [];
        for (final side in sides) {
          if (side.ingredientId == null) continue; // free-text: skip
          final ingredient = await dbHelper.getIngredient(side.ingredientId!);
          if (ingredient == null) continue;
          allIngredients.add({
            'name': ingredient.name,
            'quantity': side.quantity,
            'unit': side.unit ?? ingredient.unit?.value ?? '',
            'category': ingredient.category.value,
          });
        }

        // For each recipe, get its ingredients and scale by servings.
        for (final mealPlanItemRecipe in item.mealPlanItemRecipes!) {
          final ingredients =
              await dbHelper.getRecipeIngredients(mealPlanItemRecipe.recipeId);

          final recipe =
              await dbHelper.getRecipe(mealPlanItemRecipe.recipeId);
          final recipeServings = recipe?.servings ?? 0;
          // Guard against recipe.servings = 0 to avoid Infinity quantities.
          final scalingFactor = recipeServings > 0
              ? item.plannedServings / recipeServings
              : 1.0;

          final scaledIngredients = ingredients.map((ingredient) {
            return {
              ...ingredient,
              'quantity': (ingredient['quantity'] as double) * scalingFactor,
            };
          }).toList();

          allIngredients.addAll(scaledIngredients);
        }
      }
    }

    return allIngredients;
  }
}
