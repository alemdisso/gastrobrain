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
    return 'Are you sure you want to remove $ingredientName from this recipe?';
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
  String get history => 'History';

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
  String errorEditingMeal(String error) {
    return 'Error editing meal: $error';
  }

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
  String get viewRecipeDetailsNotImplemented =>
      'View recipe details (not implemented)';

  @override
  String errorMarkingMealAsCooked(String error) {
    return 'Error marking meal as cooked: $error';
  }

  @override
  String get cookedMealRecordNotFound =>
      'Could not find the cooked meal record';

  @override
  String get noRecipesAvailable =>
      'No recipes available. Add some recipes first.';

  @override
  String get mealNotFoundOrNotCooked => 'Meal not found or not yet cooked';

  @override
  String errorAddingSideDish(String error) {
    return 'Error adding side dish: $error';
  }

  @override
  String get noPrimaryRecipeFound => 'No primary recipe found';

  @override
  String get mealRecipesUpdatedSuccessfully =>
      'Meal recipes updated successfully';

  @override
  String errorManagingRecipes(String error) {
    return 'Error managing recipes: $error';
  }

  @override
  String get sideDishAddedLater => 'Side dish - added later';

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
  String get couldNotFindCookedMeal => 'Could not find the cooked meal record';

  @override
  String get sideDishesUpdatedSuccessfully =>
      'Side dishes updated successfully';

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

  @override
  String get frequencyDaily => 'Daily';

  @override
  String get frequencyWeekly => 'Weekly';

  @override
  String get frequencyBiweekly => 'Biweekly';

  @override
  String get frequencyMonthly => 'Monthly';

  @override
  String get frequencyBimonthly => 'Bimonthly';

  @override
  String get frequencyRarely => 'Rarely';

  @override
  String get proteinBeef => 'Beef';

  @override
  String get proteinChicken => 'Chicken';

  @override
  String get proteinPork => 'Pork';

  @override
  String get proteinFish => 'Fish';

  @override
  String get proteinSeafood => 'Seafood';

  @override
  String get proteinLamb => 'Lamb';

  @override
  String get proteinCharcuterie => 'Charcuterie';

  @override
  String get proteinOffal => 'Offal';

  @override
  String get proteinPlantBased => 'Plant Based';

  @override
  String get proteinOther => 'Other';

  @override
  String get categoryMainDishes => 'Main dishes';

  @override
  String get categorySideDishes => 'Side dishes';

  @override
  String get categorySandwiches => 'Sandwiches';

  @override
  String get categoryCompleteMeals => 'Complete meals';

  @override
  String get categoryBreakfastItems => 'Breakfast items';

  @override
  String get categoryDesserts => 'Desserts';

  @override
  String get categorySoupsStews => 'Soups/stews';

  @override
  String get categorySalads => 'Salads';

  @override
  String get categorySauces => 'Sauces';

  @override
  String get categoryDips => 'Dips';

  @override
  String get categorySnacks => 'Snacks';

  @override
  String get categoryUncategorized => 'Uncategorized';

  @override
  String get timeContextPast => 'Past';

  @override
  String get timeContextCurrent => 'Current';

  @override
  String get timeContextFuture => 'Future';

  @override
  String get timeContextPastDescription => 'Previous week';

  @override
  String get timeContextCurrentDescription => 'This week';

  @override
  String get timeContextFutureDescription => 'Upcoming week';

  @override
  String get never => 'Never';

  @override
  String get neverCooked => 'Never cooked';

  @override
  String weekOf(String date) {
    return 'Week of $date';
  }

  @override
  String get thisWeekRelative => 'This week';

  @override
  String get nextWeekRelative => '+1 week';

  @override
  String get previousWeekRelative => '-1 week';

  @override
  String futureWeeksRelative(int count) {
    return '+$count weeks';
  }

  @override
  String pastWeeksRelative(int count) {
    return '$count weeks';
  }

  @override
  String additionalRecipesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recipes',
      one: '1 recipe',
    );
    return '$_temp0';
  }

  @override
  String get sunday => 'Sunday';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get lunch => 'Lunch';

  @override
  String get dinner => 'Dinner';

  @override
  String get today => 'Today';

  @override
  String get addMeal => 'Add meal';

  @override
  String get searchRecipesHint => 'Search recipes...';

  @override
  String get noIngredientsAddedYet => 'No ingredients added yet';

  @override
  String get ingredientCategoryVegetable => 'Vegetable';

  @override
  String get ingredientCategoryFruit => 'Fruit';

  @override
  String get ingredientCategoryProtein => 'Protein';

  @override
  String get ingredientCategoryDairy => 'Dairy';

  @override
  String get ingredientCategoryGrain => 'Grain';

  @override
  String get ingredientCategoryPulse => 'Pulse';

  @override
  String get ingredientCategoryNutsAndSeeds => 'Nuts and Seeds';

  @override
  String get ingredientCategorySeasoning => 'Seasoning';

  @override
  String get ingredientCategorySugarProducts => 'Sugar Products';

  @override
  String get ingredientCategoryOil => 'Oil';

  @override
  String get ingredientCategoryOther => 'Other';

  @override
  String get measurementUnitCup => 'Cup';

  @override
  String get measurementUnitPiece => 'Piece';

  @override
  String get measurementUnitSlice => 'Slice';

  @override
  String get measurementUnitTablespoon => 'Tbsp';

  @override
  String get measurementUnitTeaspoon => 'Tsp';

  @override
  String get measurementUnitBunch => 'Bunch';

  @override
  String get measurementUnitLeaves => 'Leaves';

  @override
  String get measurementUnitPinch => 'Pinch';

  @override
  String get unitOptional => 'Unit (Optional)';

  @override
  String get noUnit => 'No unit';

  @override
  String get editIngredient => 'Edit Ingredient';

  @override
  String get newIngredient => 'New Ingredient';

  @override
  String get ingredientName => 'Ingredient Name';

  @override
  String get pleaseEnterIngredientName => 'Please enter an ingredient name';

  @override
  String get categoryLabel => 'Category';

  @override
  String get proteinTypeLabel => 'Protein Type';

  @override
  String get pleaseSelectProteinType => 'Please select a protein type';

  @override
  String get notesOptional => 'Notes (Optional)';

  @override
  String get anyAdditionalInformation => 'Any additional information';

  @override
  String get addRecipeTitle => 'Add Recipe';

  @override
  String get remove => 'Remove';

  @override
  String get numberOfServings => 'Number of Servings';

  @override
  String get pleaseEnterNumberOfServings => 'Please enter number of servings';

  @override
  String get pleaseEnterValidNumber => 'Please enter a valid number';

  @override
  String get prepTimeMin => 'Prep Time (min)';

  @override
  String get cookTimeMin => 'Cook Time (min)';

  @override
  String get enterValidTime => 'Enter a valid time';

  @override
  String get wasItSuccessful => 'Was it successful?';

  @override
  String editMealTitle(String recipeName) {
    return 'Edit $recipeName';
  }

  @override
  String get errorLoadingRecipes => 'Error loading recipes:';

  @override
  String get errorSelectingDate => 'Error selecting date';

  @override
  String get noAdditionalRecipesAvailable => 'No additional recipes available.';

  @override
  String get errorPrefix => 'Error:';

  @override
  String get errorLoadingData => 'Error loading data:';

  @override
  String get errorRefreshingRecommendations =>
      'Error refreshing recommendations:';

  @override
  String get selectIngredient => 'Select Ingredient';

  @override
  String get quantity => 'Quantity';

  @override
  String get unit => 'Unit';

  @override
  String get preparationNotesOptional => 'Preparation Notes (Optional)';

  @override
  String get typeToSearch => 'Type to search...';

  @override
  String get preparationNotesHint => 'e.g., finely chopped, diced, etc.';

  @override
  String get actualPrepTimeMin => 'Actual Prep Time (min)';

  @override
  String get actualCookTimeMin => 'Actual Cook Time (min)';

  @override
  String get cookedOn => 'Cooked on';

  @override
  String get plannedFor => 'Planned for';

  @override
  String get pleaseSelectAnIngredient => 'Please select an ingredient';

  @override
  String get createNewIngredient => 'Create New Ingredient';

  @override
  String get pleaseEnterQuantity => 'Please enter a quantity';

  @override
  String get overrideDefaultUnit => 'Override default unit';

  @override
  String get fromDatabase => 'From Database';

  @override
  String get custom => 'Custom';

  @override
  String get addRecipeDialog => 'Add Recipe';

  @override
  String get selectRecipeToAddAsSideDish =>
      'Select a recipe to add as a side dish:';

  @override
  String get buttonAddRecipe => 'Add Recipe';

  @override
  String get buttonCancel => 'Cancel';

  @override
  String cookRecipeTitle(String recipeName) {
    return 'Cook $recipeName';
  }

  @override
  String cookedOnDate(String date) {
    return 'Cooked on: $date';
  }

  @override
  String plannedForDate(String date) {
    return 'Planned for: $date';
  }

  @override
  String ingredientsTitle(String recipeName) {
    return 'Ingredients: $recipeName';
  }

  @override
  String unitOverridden(String defaultUnit) {
    return 'Unit overridden (default: $defaultUnit)';
  }

  @override
  String get recipesLabel => 'Recipes';

  @override
  String get removeTooltip => 'Remove';

  @override
  String get prepTimeLabel => 'Prep Time (min)';

  @override
  String get cookTimeLabel => 'Cook Time (min)';

  @override
  String get minuteAbbreviation => 'min';

  @override
  String get showLess => 'Show Less';

  @override
  String get showMore => 'Show More';

  @override
  String detailedPrepTime(int prepTimeMinutes) {
    return 'Prep: ${prepTimeMinutes}min';
  }

  @override
  String detailedCookTime(int cookTimeMinutes) {
    return 'Cook: ${cookTimeMinutes}min';
  }

  @override
  String detailedTimesCooked(int mealCount) {
    return 'Times Cooked: $mealCount';
  }

  @override
  String detailedLastCooked(String formattedLastCooked) {
    return 'Last Cooked: $formattedLastCooked';
  }

  @override
  String get searchSideDishesHint => 'Search side dishes...';

  @override
  String noRecipesFoundMatching(String query) {
    return 'No recipes found matching \"$query\"';
  }

  @override
  String get noAvailableSideDishes => 'No available side dishes';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get mealRecordedSuccessfully => 'Meal recorded successfully';

  @override
  String unexpectedErrorSavingMeal(String error) {
    return 'An unexpected error occurred while saving the meal: $error';
  }

  @override
  String recordCookingDetails(String recipeName) {
    return 'Record cooking details for $recipeName';
  }

  @override
  String get recordMealDetails => 'Record Meal Details';

  @override
  String get readyToExplore => 'ready to explore';

  @override
  String get goodVariety => 'good variety';

  @override
  String get recentlyUsed => 'recently used';

  @override
  String get veryRecentlyUsed => 'very recently used';

  @override
  String timingVarietyTooltip(String score, String status) {
    return 'Timing & Variety: $score/100\nThis recipe is $status based on:\n• When you last cooked it\n• Protein type variety\n• Recipe rotation';
  }

  @override
  String get oneOfFavorites => 'one of your favorites';

  @override
  String get highlyRated => 'highly rated by you';

  @override
  String get ratedAboveAverage => 'rated above average';

  @override
  String get ratedBelowAverage => 'rated below average';

  @override
  String get notYetRated => 'not yet rated';

  @override
  String recipeQualityTooltip(String score, String status) {
    return 'Recipe Quality: $score/100\nThis recipe is $status';
  }

  @override
  String recipeEffortTooltip(String score, String minutes, String difficulty) {
    return 'Recipe Effort: $score/100\nTotal time: $minutes minutes\nDifficulty level: $difficulty/5';
  }

  @override
  String get badgeExplore => 'Explore';

  @override
  String get badgeVaried => 'Varied';

  @override
  String get badgeRecent => 'Recent';

  @override
  String get badgeRepeat => 'Repeat';

  @override
  String get badgeLoved => 'Loved';

  @override
  String get badgeHigh => 'High';

  @override
  String get badgeGreat => 'Great';

  @override
  String get badgeGood => 'Good';

  @override
  String get badgeFair => 'Fair';

  @override
  String get badgeNew => 'New';

  @override
  String get badgeQuick => 'Quick';

  @override
  String get badgeEasy => 'Easy';

  @override
  String get badgeProject => 'Project';

  @override
  String get badgeComplex => 'Complex';

  @override
  String get badgeModerate => 'Moderate';

  @override
  String get noBadges => 'No badges';

  @override
  String get sideDishesLabel => 'Side Dishes:';

  @override
  String get buttonSkip => 'Skip';

  @override
  String get buttonLessOften => 'Less Often';

  @override
  String get buttonMoreOften => 'More Often';

  @override
  String get buttonLessShort => 'Less';

  @override
  String get buttonMoreShort => 'More';

  @override
  String get buttonNeverAgain => 'Never Again';

  @override
  String get buttonSelect => 'SELECT';

  @override
  String get confirmNeverAgain =>
      'Are you sure you want to hide this recipe from future recommendations?';

  @override
  String get hide => 'Hide';

  @override
  String get feedbackSaveError => 'Could not save feedback. Please try again.';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get retry => 'Retry';

  @override
  String get noRecipesFound => 'No recipes found';

  @override
  String get addFirstRecipe => 'Add your first recipe to get started';

  @override
  String get titleDatabaseMigration => 'Database Migration';

  @override
  String get buttonRefresh => 'Refresh';

  @override
  String get labelDatabaseStatus => 'Database Status';

  @override
  String get statusMigrationNeeded => 'Migration needed';

  @override
  String get statusUpToDate => 'Up to date';

  @override
  String get labelCurrentVersion => 'Current version';

  @override
  String get labelLatestVersion => 'Latest version';

  @override
  String get labelMigrationProgress => 'Migration Progress';

  @override
  String get errorMigrationFailed => 'Migration Failed';

  @override
  String get buttonDismiss => 'Dismiss';

  @override
  String get labelMigrationResults => 'Migration Results';

  @override
  String get buttonRunMigrations => 'Run Migrations';

  @override
  String get buttonRollback => 'Rollback';

  @override
  String get labelMigrationHistory => 'Migration History';

  @override
  String get messageNoMigrationHistory => 'No migration history available';

  @override
  String get labelVersion => 'Version';

  @override
  String get titleConfirmMigration => 'Confirm Migration';

  @override
  String get messageMigrationWarning =>
      'This will update your database schema. Make sure you have a backup.';

  @override
  String get buttonContinue => 'Continue';

  @override
  String get messageMigrationSuccess => 'Migration completed successfully';

  @override
  String get titleRollbackDatabase => 'Rollback Database';

  @override
  String get messageRollbackWarning =>
      'Warning: This will revert your database to an earlier version and may cause data loss.';

  @override
  String get labelTargetVersion => 'Target Version';

  @override
  String get messageRollbackSuccess => 'Rollback completed successfully';

  @override
  String get recipeSavedSuccessfully => 'Recipe saved successfully';

  @override
  String get instructions => 'Instructions';
}
