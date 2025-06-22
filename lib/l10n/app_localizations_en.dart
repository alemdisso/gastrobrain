// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Gastrobrain';

  @override
  String get recipes => 'Recipes';

  @override
  String get mealPlan => 'Meal Plan';

  @override
  String get ingredients => 'Ingredients';

  @override
  String get deleteRecipe => 'Delete Recipe';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get sortOptions => 'Sort Options';

  @override
  String get name => 'Name';

  @override
  String get rating => 'Rating';

  @override
  String get difficulty => 'Difficulty';

  @override
  String get filterRecipes => 'Filter Recipes';

  @override
  String deleteConfirmation(String recipeName) {
    return 'Are you sure you want to delete \"$recipeName\"?';
  }

  @override
  String get sortRecipes => 'Sort recipes';

  @override
  String get filterRecipesTooltip => 'Filter recipes';

  @override
  String get minimumRating => 'Minimum Rating';

  @override
  String get cookingFrequency => 'Cooking Frequency';

  @override
  String get category => 'Category';

  @override
  String get any => 'Any';

  @override
  String get clear => 'Clear';

  @override
  String get apply => 'Apply';

  @override
  String get addRecipe => 'Add Recipe';
}
