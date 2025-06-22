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

  @override
  String get errorLoadingIngredients => 'Error loading ingredients:';

  @override
  String get unexpectedErrorLoadingIngredients =>
      'An unexpected error occurred while loading ingredients';

  @override
  String get unexpectedErrorDeletingIngredient =>
      'An unexpected error occurred while deleting the ingredient';

  @override
  String get anErrorOccurred => 'An error occurred';

  @override
  String get deleteIngredient => 'Delete Ingredient';

  @override
  String deleteIngredientConfirmation(String ingredientName) {
    return 'Are you sure you want to delete $ingredientName?';
  }

  @override
  String get ingredientDeletedSuccessfully => 'Ingredient deleted successfully';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get addIngredient => 'Add Ingredient';

  @override
  String get searchIngredients => 'Search ingredients...';

  @override
  String get refresh => 'Refresh';

  @override
  String get edit => 'Edit';

  @override
  String historyTitle(String recipeName) {
    return 'History: $recipeName';
  }

  @override
  String get errorLoadingMeals => 'Error loading meals:';

  @override
  String get unexpectedErrorLoadingMeals =>
      'An unexpected error occurred while loading meals';

  @override
  String get noMealsRecorded => 'No meals recorded yet';

  @override
  String get mealUpdatedSuccessfully => 'Meal updated successfully';

  @override
  String get errorEditingMeal => 'Error editing meal:';

  @override
  String recipesCount(int count) {
    return '$count recipes';
  }

  @override
  String get editMeal => 'Edit meal';

  @override
  String get cookNow => 'Cook Now';

  @override
  String get fromMealPlan => 'From meal plan';

  @override
  String actualTimes(String prepTime, String cookTime) {
    return 'Actual times - Prep: ${prepTime}min, Cook: ${cookTime}min';
  }

  @override
  String get weeklyMealPlan => 'Weekly Meal Plan';

  @override
  String get previousWeek => 'Previous Week';

  @override
  String get nextWeek => 'Next Week';

  @override
  String get tapToJumpToCurrentWeek => 'Tap to jump to current week';

  @override
  String get thisWeek => 'This week';

  @override
  String get mealOptions => 'Meal Options';

  @override
  String get viewRecipeDetails => 'View Recipe Details';

  @override
  String get changeRecipe => 'Change Recipe';

  @override
  String get manageRecipes => 'Manage Recipes';

  @override
  String get markAsCooked => 'Mark as Cooked';

  @override
  String get editCookedMeal => 'Edit Cooked Meal';

  @override
  String get manageSideDishes => 'Manage Side Dishes';

  @override
  String get removeFromPlan => 'Remove from Plan';

  @override
  String get plannedMealNotFound => 'Planned meal not found';

  @override
  String get recipeNotFound => 'Recipe not found';

  @override
  String get mainDish => 'Main dish';

  @override
  String get sideDish => 'Side dish';

  @override
  String get mealMarkedAsCooked => 'Meal marked as cooked';

  @override
  String get mealNotFoundOrNotCooked => 'Meal not found or not yet cooked';

  @override
  String get couldNotFindCookedMeal => 'Could not find the cooked meal record';

  @override
  String get sideDishesUpdatedSuccessfully =>
      'Side dishes updated successfully';

  @override
  String get mealRecipesUpdatedSuccessfully =>
      'Meal recipes updated successfully';

  @override
  String get noPrimaryRecipeFound => 'No primary recipe found';

  @override
  String get addSideDishes => 'Add Side Dishes';

  @override
  String get selectRecipe => 'Select Recipe';

  @override
  String get tryThis => 'Try this';

  @override
  String get allRecipes => 'All Recipes';

  @override
  String get noRecommendationsAvailable => 'No recommendations available';

  @override
  String get save => 'Save';

  @override
  String get addThisRecipeToMealPlan => 'Add this recipe to meal plan';

  @override
  String get addMoreRecipesToThisMeal => 'Add more recipes to this meal';

  @override
  String get chooseDifferentRecipe => 'Choose a different recipe';

  @override
  String get back => 'Back';

  @override
  String get addSideDish => 'Add Side Dish';

  @override
  String get saveMeal => 'Save Meal';

  @override
  String get recommendationCountMustBePositive =>
      'Recommendation count must be positive';

  @override
  String get noRecommendationFactorsRegistered =>
      'No recommendation factors registered';

  @override
  String unknownWeightProfile(String profileName) {
    return 'Unknown weight profile: $profileName';
  }

  @override
  String get errorGeneratingRecommendations =>
      'Error generating recommendations';

  @override
  String get errorGettingCandidateRecipes => 'Error getting candidate recipes';

  @override
  String get errorGettingRecipeProteinTypes =>
      'Error getting recipe protein types';

  @override
  String get errorGettingLastCookedDates => 'Error getting last cooked dates';

  @override
  String get errorGettingMealCounts => 'Error getting meal counts';

  @override
  String get errorGettingRecentMeals => 'Error getting recent meals';

  @override
  String factorNotFound(String factorId) {
    return 'Factor not found: $factorId';
  }

  @override
  String get weightProfileBalanced => 'Balanced';

  @override
  String get weightProfileFrequencyFocused => 'Frequency-focused';

  @override
  String get weightProfileVarietyFocused => 'Variety-focused';

  @override
  String get weightProfileWeekday => 'Weekday';

  @override
  String get weightProfileWeekend => 'Weekend';

  @override
  String get errorGettingRecipesWithStats =>
      'Error getting recipes with statistics';

  @override
  String get errorGettingRecentlyCookedRecipeIds =>
      'Error getting recently cooked recipe IDs';

  @override
  String get errorGettingRecentlyCookedProteinsByDate =>
      'Error getting recently cooked proteins by date';

  @override
  String get errorCalculatingProteinPenaltyStrategy =>
      'Error calculating protein penalty strategy';

  @override
  String get errorGettingProteinTypesForRecipes =>
      'Error getting protein types for recipes';
}
