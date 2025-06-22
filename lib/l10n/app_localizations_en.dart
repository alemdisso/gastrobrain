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

  @override
  String get addNewRecipe => 'Add New Recipe';

  @override
  String get recipeName => 'Recipe Name';

  @override
  String get desiredFrequency => 'Desired Frequency';

  @override
  String get difficultyLevel => 'Difficulty Level';

  @override
  String get preparationTime => 'Preparation Time';

  @override
  String get cookingTime => 'Cooking Time';

  @override
  String get notes => 'Notes';

  @override
  String get minutes => 'minutes';

  @override
  String get add => 'Add';

  @override
  String get noIngredientsAdded => 'No ingredients added yet';

  @override
  String get saveRecipe => 'Save Recipe';

  @override
  String get loading => 'Loading...';

  @override
  String get unknown => 'Unknown';

  @override
  String get pleaseEnterRecipeName => 'Please enter a recipe name';

  @override
  String get pleaseEnterValidTime => 'Please enter a valid time';

  @override
  String get errorSavingRecipe => 'Error saving recipe:';

  @override
  String get unexpectedError => 'An unexpected error occurred';

  @override
  String get editRecipe => 'Edit Recipe';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get errorUpdatingRecipe => 'Error updating recipe:';
}
