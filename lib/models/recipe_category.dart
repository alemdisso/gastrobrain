import '../l10n/app_localizations.dart';

enum RecipeCategory {
  mainDishes('main_dishes'),
  sideDishes('side_dishes'),
  sandwiches('sandwiches'),
  completeMeals('complete_meals'),
  breakfastItems('breakfast_items'),
  desserts('desserts'),
  soupsStews('soups_stews'),
  salads('salads'),
  sauces('sauces'),
  dips('dips'),
  snacks('snacks'),
  uncategorized('uncategorized');

  final String value;
  const RecipeCategory(this.value);

  static RecipeCategory fromString(String value) {
    return RecipeCategory.values.firstWhere(
      (type) => type.value == value,
      orElse: () => RecipeCategory.uncategorized,
    );
  }

  String get displayName {
    switch (this) {
      case RecipeCategory.mainDishes:
        return 'Main dishes';
      case RecipeCategory.sideDishes:
        return 'Side dishes';
      case RecipeCategory.sandwiches:
        return 'Sandwiches';
      case RecipeCategory.completeMeals:
        return 'Complete meals';
      case RecipeCategory.breakfastItems:
        return 'Breakfast items';
      case RecipeCategory.desserts:
        return 'Desserts';
      case RecipeCategory.soupsStews:
        return 'Soups/stews';
      case RecipeCategory.salads:
        return 'Salads';
      case RecipeCategory.sauces:
        return 'Sauces';
      case RecipeCategory.dips:
        return 'Dips';
      case RecipeCategory.snacks:
        return 'Snacks';
      case RecipeCategory.uncategorized:
        return 'Uncategorized';
    }
  }

  String getLocalizedDisplayName(context) {
    final localizations = context != null ? AppLocalizations.of(context)! : null;
    
    if (localizations == null) {
      return displayName; // Fallback to English
    }
    
    switch (this) {
      case RecipeCategory.mainDishes:
        return localizations.categoryMainDishes;
      case RecipeCategory.sideDishes:
        return localizations.categorySideDishes;
      case RecipeCategory.sandwiches:
        return localizations.categorySandwiches;
      case RecipeCategory.completeMeals:
        return localizations.categoryCompleteMeals;
      case RecipeCategory.breakfastItems:
        return localizations.categoryBreakfastItems;
      case RecipeCategory.desserts:
        return localizations.categoryDesserts;
      case RecipeCategory.soupsStews:
        return localizations.categorySoupsStews;
      case RecipeCategory.salads:
        return localizations.categorySalads;
      case RecipeCategory.sauces:
        return localizations.categorySauces;
      case RecipeCategory.dips:
        return localizations.categoryDips;
      case RecipeCategory.snacks:
        return localizations.categorySnacks;
      case RecipeCategory.uncategorized:
        return localizations.categoryUncategorized;
    }
  }
}
