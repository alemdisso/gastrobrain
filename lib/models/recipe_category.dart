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
}
