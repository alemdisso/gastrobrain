import '../l10n/app_localizations.dart';

enum IngredientCategory {
  vegetable('vegetable'),
  fruit('fruit'),
  protein('protein'),
  dairy('dairy'),
  grain('grain'),
  pulse('pulse'),
  nutsAndSeeds('nuts_and_seeds'),
  seasoning('seasoning'),
  sugarProducts('sugar_products'),
  oil('oil'),
  other('other');

  final String value;
  const IngredientCategory(this.value);

  static IngredientCategory fromString(String value) {
    return IngredientCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => IngredientCategory.other,
    );
  }

  String get displayName {
    switch (this) {
      case IngredientCategory.vegetable:
        return 'Vegetable';
      case IngredientCategory.fruit:
        return 'Fruit';
      case IngredientCategory.protein:
        return 'Protein';
      case IngredientCategory.dairy:
        return 'Dairy';
      case IngredientCategory.grain:
        return 'Grain';
      case IngredientCategory.pulse:
        return 'Pulse';
      case IngredientCategory.nutsAndSeeds:
        return 'Nuts and Seeds';
      case IngredientCategory.seasoning:
        return 'Seasoning';
      case IngredientCategory.sugarProducts:
        return 'Sugar Products';
      case IngredientCategory.oil:
        return 'Oil';
      case IngredientCategory.other:
        return 'Other';
    }
  }

  String getLocalizedDisplayName(context) {
    final localizations = context != null ? AppLocalizations.of(context)! : null;
    
    if (localizations == null) {
      return displayName; // Fallback to English
    }
    
    switch (this) {
      case IngredientCategory.vegetable:
        return localizations.ingredientCategoryVegetable;
      case IngredientCategory.fruit:
        return localizations.ingredientCategoryFruit;
      case IngredientCategory.protein:
        return localizations.ingredientCategoryProtein;
      case IngredientCategory.dairy:
        return localizations.ingredientCategoryDairy;
      case IngredientCategory.grain:
        return localizations.ingredientCategoryGrain;
      case IngredientCategory.pulse:
        return localizations.ingredientCategoryPulse;
      case IngredientCategory.nutsAndSeeds:
        return localizations.ingredientCategoryNutsAndSeeds;
      case IngredientCategory.seasoning:
        return localizations.ingredientCategorySeasoning;
      case IngredientCategory.sugarProducts:
        return localizations.ingredientCategorySugarProducts;
      case IngredientCategory.oil:
        return localizations.ingredientCategoryOil;
      case IngredientCategory.other:
        return localizations.ingredientCategoryOther;
    }
  }
}