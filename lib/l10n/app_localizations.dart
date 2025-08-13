import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Gastrobrain'**
  String get appTitle;

  /// Tab label for recipes section
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get recipes;

  /// Tab label for meal planning section
  ///
  /// In en, this message translates to:
  /// **'Meal Plan'**
  String get mealPlan;

  /// Tab label for ingredients section
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get ingredients;

  /// Title for delete recipe confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Recipe'**
  String get deleteRecipe;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Title for sorting options menu
  ///
  /// In en, this message translates to:
  /// **'Sort Options'**
  String get sortOptions;

  /// Sort by name option
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Sort by rating option
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// Sort by difficulty option
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get difficulty;

  /// Title for recipe filter dialog
  ///
  /// In en, this message translates to:
  /// **'Filter Recipes'**
  String get filterRecipes;

  /// Confirmation message for recipe deletion
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{recipeName}\"?'**
  String deleteConfirmation(String recipeName);

  /// Tooltip for sort button
  ///
  /// In en, this message translates to:
  /// **'Sort recipes'**
  String get sortRecipes;

  /// Tooltip for filter button
  ///
  /// In en, this message translates to:
  /// **'Filter recipes'**
  String get filterRecipesTooltip;

  /// Label for minimum rating filter
  ///
  /// In en, this message translates to:
  /// **'Minimum Rating'**
  String get minimumRating;

  /// Label for cooking frequency filter
  ///
  /// In en, this message translates to:
  /// **'Cooking Frequency'**
  String get cookingFrequency;

  /// Label for category filter
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// Option for any/no filter
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get any;

  /// Button to clear filters
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Button to apply filters
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// Tooltip for add recipe button
  ///
  /// In en, this message translates to:
  /// **'Add Recipe'**
  String get addRecipe;

  /// Title for add recipe screen
  ///
  /// In en, this message translates to:
  /// **'Add New Recipe'**
  String get addNewRecipe;

  /// Label for recipe name field
  ///
  /// In en, this message translates to:
  /// **'Recipe Name'**
  String get recipeName;

  /// Label for desired cooking frequency field
  ///
  /// In en, this message translates to:
  /// **'Desired Frequency'**
  String get desiredFrequency;

  /// Label for difficulty level field
  ///
  /// In en, this message translates to:
  /// **'Difficulty Level'**
  String get difficultyLevel;

  /// Label for preparation time field
  ///
  /// In en, this message translates to:
  /// **'Preparation Time'**
  String get preparationTime;

  /// Label for cooking time field
  ///
  /// In en, this message translates to:
  /// **'Cooking Time'**
  String get cookingTime;

  /// Label for notes field
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// Time unit for minutes
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// Add button text
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Message when no ingredients are added
  ///
  /// In en, this message translates to:
  /// **'No ingredients added yet'**
  String get noIngredientsAdded;

  /// Save recipe button text
  ///
  /// In en, this message translates to:
  /// **'Save Recipe'**
  String get saveRecipe;

  /// Loading indicator text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Unknown value placeholder
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// Validation message for empty recipe name
  ///
  /// In en, this message translates to:
  /// **'Please enter a recipe name'**
  String get pleaseEnterRecipeName;

  /// Validation message for invalid time
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid time'**
  String get pleaseEnterValidTime;

  /// Error message prefix for recipe saving errors
  ///
  /// In en, this message translates to:
  /// **'Error saving recipe:'**
  String get errorSavingRecipe;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get unexpectedError;

  /// Title for edit recipe screen
  ///
  /// In en, this message translates to:
  /// **'Edit Recipe'**
  String get editRecipe;

  /// Save changes button text
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// Error message prefix for recipe updating errors
  ///
  /// In en, this message translates to:
  /// **'Error updating recipe:'**
  String get errorUpdatingRecipe;

  /// Error message prefix for ingredient loading errors
  ///
  /// In en, this message translates to:
  /// **'Error loading ingredients:'**
  String get errorLoadingIngredients;

  /// Generic error message for ingredient loading
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred while loading ingredients'**
  String get unexpectedErrorLoadingIngredients;

  /// Generic error message for ingredient deletion
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred while deleting the ingredient'**
  String get unexpectedErrorDeletingIngredient;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get anErrorOccurred;

  /// Title for delete ingredient dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Ingredient'**
  String get deleteIngredient;

  /// Confirmation message for ingredient deletion
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove {ingredientName} from this recipe?'**
  String deleteIngredientConfirmation(String ingredientName);

  /// Success message for ingredient deletion
  ///
  /// In en, this message translates to:
  /// **'Ingredient deleted successfully'**
  String get ingredientDeletedSuccessfully;

  /// Try again button text
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// Add ingredient button text
  ///
  /// In en, this message translates to:
  /// **'Add Ingredient'**
  String get addIngredient;

  /// Search field hint text for ingredients
  ///
  /// In en, this message translates to:
  /// **'Search ingredients...'**
  String get searchIngredients;

  /// Refresh button tooltip
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Edit menu item text
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// History tooltip text
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// Title for meal history screen
  ///
  /// In en, this message translates to:
  /// **'History: {recipeName}'**
  String historyTitle(String recipeName);

  /// Error message prefix for meal loading errors
  ///
  /// In en, this message translates to:
  /// **'Error loading meals:'**
  String get errorLoadingMeals;

  /// Generic error message for meal loading
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred while loading meals'**
  String get unexpectedErrorLoadingMeals;

  /// Empty state message for meal history
  ///
  /// In en, this message translates to:
  /// **'No meals recorded yet'**
  String get noMealsRecorded;

  /// Success message for meal update
  ///
  /// In en, this message translates to:
  /// **'Meal updated successfully'**
  String get mealUpdatedSuccessfully;

  /// Error message when editing meal fails
  ///
  /// In en, this message translates to:
  /// **'Error editing meal: {error}'**
  String errorEditingMeal(String error);

  /// Recipe count display
  ///
  /// In en, this message translates to:
  /// **'{count} recipes'**
  String recipesCount(int count);

  /// Tooltip for edit meal button
  ///
  /// In en, this message translates to:
  /// **'Edit meal'**
  String get editMeal;

  /// Tooltip for cook now button
  ///
  /// In en, this message translates to:
  /// **'Cook Now'**
  String get cookNow;

  /// Tooltip for meal plan indicator
  ///
  /// In en, this message translates to:
  /// **'From meal plan'**
  String get fromMealPlan;

  /// Display for actual cooking times
  ///
  /// In en, this message translates to:
  /// **'Actual times - Prep: {prepTime}min, Cook: {cookTime}min'**
  String actualTimes(String prepTime, String cookTime);

  /// Title for weekly meal plan screen
  ///
  /// In en, this message translates to:
  /// **'Weekly Meal Plan'**
  String get weeklyMealPlan;

  /// Tooltip for previous week button
  ///
  /// In en, this message translates to:
  /// **'Previous Week'**
  String get previousWeek;

  /// Tooltip for next week button
  ///
  /// In en, this message translates to:
  /// **'Next Week'**
  String get nextWeek;

  /// Tooltip for current week navigation
  ///
  /// In en, this message translates to:
  /// **'Tap to jump to current week'**
  String get tapToJumpToCurrentWeek;

  /// Label for current week
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// Title for meal options dialog
  ///
  /// In en, this message translates to:
  /// **'Meal Options'**
  String get mealOptions;

  /// Button text to view recipe details
  ///
  /// In en, this message translates to:
  /// **'View Recipe Details'**
  String get viewRecipeDetails;

  /// Button text to change recipe
  ///
  /// In en, this message translates to:
  /// **'Change Recipe'**
  String get changeRecipe;

  /// Button text to manage recipes
  ///
  /// In en, this message translates to:
  /// **'Manage Recipes'**
  String get manageRecipes;

  /// Button text to mark meal as cooked
  ///
  /// In en, this message translates to:
  /// **'Mark as Cooked'**
  String get markAsCooked;

  /// Button text to edit cooked meal
  ///
  /// In en, this message translates to:
  /// **'Edit Cooked Meal'**
  String get editCookedMeal;

  /// Button text to manage side dishes
  ///
  /// In en, this message translates to:
  /// **'Manage Side Dishes'**
  String get manageSideDishes;

  /// Button text to remove meal from plan
  ///
  /// In en, this message translates to:
  /// **'Remove from Plan'**
  String get removeFromPlan;

  /// Snackbar message for not implemented view recipe details feature
  ///
  /// In en, this message translates to:
  /// **'View recipe details (not implemented)'**
  String get viewRecipeDetailsNotImplemented;

  /// Error message when marking meal as cooked fails
  ///
  /// In en, this message translates to:
  /// **'Error marking meal as cooked: {error}'**
  String errorMarkingMealAsCooked(String error);

  /// Error message when cooked meal record is not found
  ///
  /// In en, this message translates to:
  /// **'Could not find the cooked meal record'**
  String get cookedMealRecordNotFound;

  /// Message when no recipes are available
  ///
  /// In en, this message translates to:
  /// **'No recipes available. Add some recipes first.'**
  String get noRecipesAvailable;

  /// Error message when meal is not found or not cooked
  ///
  /// In en, this message translates to:
  /// **'Meal not found or not yet cooked'**
  String get mealNotFoundOrNotCooked;

  /// Error message when adding side dish fails
  ///
  /// In en, this message translates to:
  /// **'Error adding side dish: {error}'**
  String errorAddingSideDish(String error);

  /// Error message when no primary recipe is found
  ///
  /// In en, this message translates to:
  /// **'No primary recipe found'**
  String get noPrimaryRecipeFound;

  /// Success message when meal recipes are updated
  ///
  /// In en, this message translates to:
  /// **'Meal recipes updated successfully'**
  String get mealRecipesUpdatedSuccessfully;

  /// Error message when managing recipes fails
  ///
  /// In en, this message translates to:
  /// **'Error managing recipes: {error}'**
  String errorManagingRecipes(String error);

  /// Notes text for side dishes added later
  ///
  /// In en, this message translates to:
  /// **'Side dish - added later'**
  String get sideDishAddedLater;

  /// Error message when planned meal is not found
  ///
  /// In en, this message translates to:
  /// **'Planned meal not found'**
  String get plannedMealNotFound;

  /// Error message when recipe is not found
  ///
  /// In en, this message translates to:
  /// **'Recipe not found'**
  String get recipeNotFound;

  /// Label for main dish
  ///
  /// In en, this message translates to:
  /// **'Main dish'**
  String get mainDish;

  /// Label for side dish
  ///
  /// In en, this message translates to:
  /// **'Side dish'**
  String get sideDish;

  /// Success message when meal is marked as cooked
  ///
  /// In en, this message translates to:
  /// **'Meal marked as cooked'**
  String get mealMarkedAsCooked;

  /// Error message when cooked meal record is not found
  ///
  /// In en, this message translates to:
  /// **'Could not find the cooked meal record'**
  String get couldNotFindCookedMeal;

  /// Success message when side dishes are updated
  ///
  /// In en, this message translates to:
  /// **'Side dishes updated successfully'**
  String get sideDishesUpdatedSuccessfully;

  /// Button text to add side dishes
  ///
  /// In en, this message translates to:
  /// **'Add Side Dishes'**
  String get addSideDishes;

  /// Button text to select recipe
  ///
  /// In en, this message translates to:
  /// **'Select Recipe'**
  String get selectRecipe;

  /// Button text to try a recommendation
  ///
  /// In en, this message translates to:
  /// **'Try this'**
  String get tryThis;

  /// Tab label for all recipes
  ///
  /// In en, this message translates to:
  /// **'All Recipes'**
  String get allRecipes;

  /// Message when no recommendations are available
  ///
  /// In en, this message translates to:
  /// **'No recommendations available'**
  String get noRecommendationsAvailable;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Subtitle for save action
  ///
  /// In en, this message translates to:
  /// **'Add this recipe to meal plan'**
  String get addThisRecipeToMealPlan;

  /// Subtitle for add side dishes action
  ///
  /// In en, this message translates to:
  /// **'Add more recipes to this meal'**
  String get addMoreRecipesToThisMeal;

  /// Subtitle for back action
  ///
  /// In en, this message translates to:
  /// **'Choose a different recipe'**
  String get chooseDifferentRecipe;

  /// Back button text
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Button text to add side dish
  ///
  /// In en, this message translates to:
  /// **'Add Side Dish'**
  String get addSideDish;

  /// Button text to save meal
  ///
  /// In en, this message translates to:
  /// **'Save Meal'**
  String get saveMeal;

  /// Error message for invalid recommendation count
  ///
  /// In en, this message translates to:
  /// **'Recommendation count must be positive'**
  String get recommendationCountMustBePositive;

  /// Error message when no recommendation factors are available
  ///
  /// In en, this message translates to:
  /// **'No recommendation factors registered'**
  String get noRecommendationFactorsRegistered;

  /// Error message for unknown weight profile
  ///
  /// In en, this message translates to:
  /// **'Unknown weight profile: {profileName}'**
  String unknownWeightProfile(String profileName);

  /// Error message prefix for recommendation generation errors
  ///
  /// In en, this message translates to:
  /// **'Error generating recommendations'**
  String get errorGeneratingRecommendations;

  /// Error message for candidate recipe retrieval
  ///
  /// In en, this message translates to:
  /// **'Error getting candidate recipes'**
  String get errorGettingCandidateRecipes;

  /// Error message for protein type retrieval
  ///
  /// In en, this message translates to:
  /// **'Error getting recipe protein types'**
  String get errorGettingRecipeProteinTypes;

  /// Error message for last cooked date retrieval
  ///
  /// In en, this message translates to:
  /// **'Error getting last cooked dates'**
  String get errorGettingLastCookedDates;

  /// Error message for meal count retrieval
  ///
  /// In en, this message translates to:
  /// **'Error getting meal counts'**
  String get errorGettingMealCounts;

  /// Error message for recent meal retrieval
  ///
  /// In en, this message translates to:
  /// **'Error getting recent meals'**
  String get errorGettingRecentMeals;

  /// Error message when recommendation factor is not found
  ///
  /// In en, this message translates to:
  /// **'Factor not found: {factorId}'**
  String factorNotFound(String factorId);

  /// Name for balanced weight profile
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get weightProfileBalanced;

  /// Name for frequency-focused weight profile
  ///
  /// In en, this message translates to:
  /// **'Frequency-focused'**
  String get weightProfileFrequencyFocused;

  /// Name for variety-focused weight profile
  ///
  /// In en, this message translates to:
  /// **'Variety-focused'**
  String get weightProfileVarietyFocused;

  /// Name for weekday weight profile
  ///
  /// In en, this message translates to:
  /// **'Weekday'**
  String get weightProfileWeekday;

  /// Name for weekend weight profile
  ///
  /// In en, this message translates to:
  /// **'Weekend'**
  String get weightProfileWeekend;

  /// Error message for recipe statistics retrieval
  ///
  /// In en, this message translates to:
  /// **'Error getting recipes with statistics'**
  String get errorGettingRecipesWithStats;

  /// Error message for recently cooked recipe ID retrieval
  ///
  /// In en, this message translates to:
  /// **'Error getting recently cooked recipe IDs'**
  String get errorGettingRecentlyCookedRecipeIds;

  /// Error message for recently cooked proteins retrieval
  ///
  /// In en, this message translates to:
  /// **'Error getting recently cooked proteins by date'**
  String get errorGettingRecentlyCookedProteinsByDate;

  /// Error message for protein penalty calculation
  ///
  /// In en, this message translates to:
  /// **'Error calculating protein penalty strategy'**
  String get errorCalculatingProteinPenaltyStrategy;

  /// Error message for recipe protein type retrieval
  ///
  /// In en, this message translates to:
  /// **'Error getting protein types for recipes'**
  String get errorGettingProteinTypesForRecipes;

  /// Display name for daily frequency
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get frequencyDaily;

  /// Display name for weekly frequency
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get frequencyWeekly;

  /// Display name for biweekly frequency
  ///
  /// In en, this message translates to:
  /// **'Biweekly'**
  String get frequencyBiweekly;

  /// Display name for monthly frequency
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get frequencyMonthly;

  /// Display name for bimonthly frequency
  ///
  /// In en, this message translates to:
  /// **'Bimonthly'**
  String get frequencyBimonthly;

  /// Display name for rarely frequency
  ///
  /// In en, this message translates to:
  /// **'Rarely'**
  String get frequencyRarely;

  /// Display name for beef protein type
  ///
  /// In en, this message translates to:
  /// **'Beef'**
  String get proteinBeef;

  /// Display name for chicken protein type
  ///
  /// In en, this message translates to:
  /// **'Chicken'**
  String get proteinChicken;

  /// Display name for pork protein type
  ///
  /// In en, this message translates to:
  /// **'Pork'**
  String get proteinPork;

  /// Display name for fish protein type
  ///
  /// In en, this message translates to:
  /// **'Fish'**
  String get proteinFish;

  /// Display name for seafood protein type
  ///
  /// In en, this message translates to:
  /// **'Seafood'**
  String get proteinSeafood;

  /// Display name for lamb protein type
  ///
  /// In en, this message translates to:
  /// **'Lamb'**
  String get proteinLamb;

  /// Display name for charcuterie protein type
  ///
  /// In en, this message translates to:
  /// **'Charcuterie'**
  String get proteinCharcuterie;

  /// Display name for offal protein type
  ///
  /// In en, this message translates to:
  /// **'Offal'**
  String get proteinOffal;

  /// Display name for plant-based protein type
  ///
  /// In en, this message translates to:
  /// **'Plant Based'**
  String get proteinPlantBased;

  /// Display name for other protein type
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get proteinOther;

  /// Display name for main dishes category
  ///
  /// In en, this message translates to:
  /// **'Main dishes'**
  String get categoryMainDishes;

  /// Display name for side dishes category
  ///
  /// In en, this message translates to:
  /// **'Side dishes'**
  String get categorySideDishes;

  /// Display name for sandwiches category
  ///
  /// In en, this message translates to:
  /// **'Sandwiches'**
  String get categorySandwiches;

  /// Display name for complete meals category
  ///
  /// In en, this message translates to:
  /// **'Complete meals'**
  String get categoryCompleteMeals;

  /// Display name for breakfast items category
  ///
  /// In en, this message translates to:
  /// **'Breakfast items'**
  String get categoryBreakfastItems;

  /// Display name for desserts category
  ///
  /// In en, this message translates to:
  /// **'Desserts'**
  String get categoryDesserts;

  /// Display name for soups/stews category
  ///
  /// In en, this message translates to:
  /// **'Soups/stews'**
  String get categorySoupsStews;

  /// Display name for salads category
  ///
  /// In en, this message translates to:
  /// **'Salads'**
  String get categorySalads;

  /// Display name for sauces category
  ///
  /// In en, this message translates to:
  /// **'Sauces'**
  String get categorySauces;

  /// Display name for dips category
  ///
  /// In en, this message translates to:
  /// **'Dips'**
  String get categoryDips;

  /// Display name for snacks category
  ///
  /// In en, this message translates to:
  /// **'Snacks'**
  String get categorySnacks;

  /// Display name for uncategorized category
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get categoryUncategorized;

  /// Display name for past time context
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get timeContextPast;

  /// Display name for current time context
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get timeContextCurrent;

  /// Display name for future time context
  ///
  /// In en, this message translates to:
  /// **'Future'**
  String get timeContextFuture;

  /// Description for past time context
  ///
  /// In en, this message translates to:
  /// **'Previous week'**
  String get timeContextPastDescription;

  /// Description for current time context
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get timeContextCurrentDescription;

  /// Description for future time context
  ///
  /// In en, this message translates to:
  /// **'Upcoming week'**
  String get timeContextFutureDescription;

  /// Text shown when a recipe has never been cooked
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// Text shown in recipe cards for recipes that have never been cooked
  ///
  /// In en, this message translates to:
  /// **'Never cooked'**
  String get neverCooked;

  /// Format string for week header with date
  ///
  /// In en, this message translates to:
  /// **'Week of {date}'**
  String weekOf(String date);

  /// Relative time distance for current week
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeekRelative;

  /// Relative time distance for next week
  ///
  /// In en, this message translates to:
  /// **'+1 week'**
  String get nextWeekRelative;

  /// Relative time distance for previous week
  ///
  /// In en, this message translates to:
  /// **'-1 week'**
  String get previousWeekRelative;

  /// Relative time distance for future weeks
  ///
  /// In en, this message translates to:
  /// **'+{count} weeks'**
  String futureWeeksRelative(int count);

  /// Relative time distance for past weeks
  ///
  /// In en, this message translates to:
  /// **'{count} weeks'**
  String pastWeeksRelative(int count);

  /// Count of additional recipes with proper pluralization
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{1 recipe} other{{count} recipes}}'**
  String additionalRecipesCount(int count);

  /// Day names for the weekly calendar
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// Day names for the weekly calendar
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// Day names for the weekly calendar
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// Day names for the weekly calendar
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// Day names for the weekly calendar
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// Day names for the weekly calendar
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// Day names for the weekly calendar
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// Meal type names
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get lunch;

  /// Meal type names
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get dinner;

  /// Label for today indicator
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Label for add meal button
  ///
  /// In en, this message translates to:
  /// **'Add meal'**
  String get addMeal;

  /// Hint text for recipe search field
  ///
  /// In en, this message translates to:
  /// **'Search recipes...'**
  String get searchRecipesHint;

  /// Message when no ingredients have been added yet
  ///
  /// In en, this message translates to:
  /// **'No ingredients added yet'**
  String get noIngredientsAddedYet;

  /// Ingredient category names
  ///
  /// In en, this message translates to:
  /// **'Vegetable'**
  String get ingredientCategoryVegetable;

  /// Ingredient category names
  ///
  /// In en, this message translates to:
  /// **'Fruit'**
  String get ingredientCategoryFruit;

  /// Ingredient category names
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get ingredientCategoryProtein;

  /// Ingredient category names
  ///
  /// In en, this message translates to:
  /// **'Dairy'**
  String get ingredientCategoryDairy;

  /// Ingredient category names
  ///
  /// In en, this message translates to:
  /// **'Grain'**
  String get ingredientCategoryGrain;

  /// Ingredient category names
  ///
  /// In en, this message translates to:
  /// **'Pulse'**
  String get ingredientCategoryPulse;

  /// Ingredient category names
  ///
  /// In en, this message translates to:
  /// **'Nuts and Seeds'**
  String get ingredientCategoryNutsAndSeeds;

  /// Ingredient category names
  ///
  /// In en, this message translates to:
  /// **'Seasoning'**
  String get ingredientCategorySeasoning;

  /// Ingredient category names
  ///
  /// In en, this message translates to:
  /// **'Sugar Products'**
  String get ingredientCategorySugarProducts;

  /// Ingredient category names
  ///
  /// In en, this message translates to:
  /// **'Oil'**
  String get ingredientCategoryOil;

  /// Ingredient category names
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get ingredientCategoryOther;

  /// Measurement unit names
  ///
  /// In en, this message translates to:
  /// **'Cup'**
  String get measurementUnitCup;

  /// Measurement unit names
  ///
  /// In en, this message translates to:
  /// **'Piece'**
  String get measurementUnitPiece;

  /// Measurement unit names
  ///
  /// In en, this message translates to:
  /// **'Slice'**
  String get measurementUnitSlice;

  /// Measurement unit names
  ///
  /// In en, this message translates to:
  /// **'Tbsp'**
  String get measurementUnitTablespoon;

  /// Measurement unit names
  ///
  /// In en, this message translates to:
  /// **'Tsp'**
  String get measurementUnitTeaspoon;

  /// Measurement unit names
  ///
  /// In en, this message translates to:
  /// **'Bunch'**
  String get measurementUnitBunch;

  /// Measurement unit names
  ///
  /// In en, this message translates to:
  /// **'Leaves'**
  String get measurementUnitLeaves;

  /// Measurement unit names
  ///
  /// In en, this message translates to:
  /// **'Pinch'**
  String get measurementUnitPinch;

  /// Label for unit field in ingredient forms
  ///
  /// In en, this message translates to:
  /// **'Unit (Optional)'**
  String get unitOptional;

  /// Option for no unit in dropdowns
  ///
  /// In en, this message translates to:
  /// **'No unit'**
  String get noUnit;

  /// Dialog title for editing ingredient
  ///
  /// In en, this message translates to:
  /// **'Edit Ingredient'**
  String get editIngredient;

  /// Dialog title for adding new ingredient
  ///
  /// In en, this message translates to:
  /// **'New Ingredient'**
  String get newIngredient;

  /// Label for ingredient name field
  ///
  /// In en, this message translates to:
  /// **'Ingredient Name'**
  String get ingredientName;

  /// Validation message for empty ingredient name
  ///
  /// In en, this message translates to:
  /// **'Please enter an ingredient name'**
  String get pleaseEnterIngredientName;

  /// Label for category field
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// Label for protein type field
  ///
  /// In en, this message translates to:
  /// **'Protein Type'**
  String get proteinTypeLabel;

  /// Validation message for protein type selection
  ///
  /// In en, this message translates to:
  /// **'Please select a protein type'**
  String get pleaseSelectProteinType;

  /// Label for notes field
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get notesOptional;

  /// Hint text for notes field
  ///
  /// In en, this message translates to:
  /// **'Any additional information'**
  String get anyAdditionalInformation;

  /// Text for add recipe button/dialog
  ///
  /// In en, this message translates to:
  /// **'Add Recipe'**
  String get addRecipeTitle;

  /// Text for removing items
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// Label for servings field
  ///
  /// In en, this message translates to:
  /// **'Number of Servings'**
  String get numberOfServings;

  /// Validation message for servings
  ///
  /// In en, this message translates to:
  /// **'Please enter number of servings'**
  String get pleaseEnterNumberOfServings;

  /// Validation message for valid number
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get pleaseEnterValidNumber;

  /// Label for prep time field
  ///
  /// In en, this message translates to:
  /// **'Prep Time (min)'**
  String get prepTimeMin;

  /// Label for cook time field
  ///
  /// In en, this message translates to:
  /// **'Cook Time (min)'**
  String get cookTimeMin;

  /// Validation message for valid time
  ///
  /// In en, this message translates to:
  /// **'Enter a valid time'**
  String get enterValidTime;

  /// Question about meal success
  ///
  /// In en, this message translates to:
  /// **'Was it successful?'**
  String get wasItSuccessful;

  /// Edit meal dialog title format
  ///
  /// In en, this message translates to:
  /// **'Edit {recipeName}'**
  String editMealTitle(String recipeName);

  /// Error message for loading recipes
  ///
  /// In en, this message translates to:
  /// **'Error loading recipes:'**
  String get errorLoadingRecipes;

  /// Error message for selecting date
  ///
  /// In en, this message translates to:
  /// **'Error selecting date'**
  String get errorSelectingDate;

  /// Message when no additional recipes available
  ///
  /// In en, this message translates to:
  /// **'No additional recipes available.'**
  String get noAdditionalRecipesAvailable;

  /// General error prefix
  ///
  /// In en, this message translates to:
  /// **'Error:'**
  String get errorPrefix;

  /// Error message for loading data
  ///
  /// In en, this message translates to:
  /// **'Error loading data:'**
  String get errorLoadingData;

  /// Error message for refreshing recommendations
  ///
  /// In en, this message translates to:
  /// **'Error refreshing recommendations:'**
  String get errorRefreshingRecommendations;

  /// Label for select ingredient dropdown
  ///
  /// In en, this message translates to:
  /// **'Select Ingredient'**
  String get selectIngredient;

  /// Label for quantity field
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// Label for unit field
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// Label for preparation notes field
  ///
  /// In en, this message translates to:
  /// **'Preparation Notes (Optional)'**
  String get preparationNotesOptional;

  /// Hint text for search field
  ///
  /// In en, this message translates to:
  /// **'Type to search...'**
  String get typeToSearch;

  /// Hint text for preparation notes
  ///
  /// In en, this message translates to:
  /// **'e.g., finely chopped, diced, etc.'**
  String get preparationNotesHint;

  /// Label for actual prep time
  ///
  /// In en, this message translates to:
  /// **'Actual Prep Time (min)'**
  String get actualPrepTimeMin;

  /// Label for actual cook time
  ///
  /// In en, this message translates to:
  /// **'Actual Cook Time (min)'**
  String get actualCookTimeMin;

  /// Label for cooked on date
  ///
  /// In en, this message translates to:
  /// **'Cooked on'**
  String get cookedOn;

  /// Label for planned for date
  ///
  /// In en, this message translates to:
  /// **'Planned for'**
  String get plannedFor;

  /// Validation message for selecting an ingredient
  ///
  /// In en, this message translates to:
  /// **'Please select an ingredient'**
  String get pleaseSelectAnIngredient;

  /// Button text for creating new ingredient
  ///
  /// In en, this message translates to:
  /// **'Create New Ingredient'**
  String get createNewIngredient;

  /// Validation message for entering quantity
  ///
  /// In en, this message translates to:
  /// **'Please enter a quantity'**
  String get pleaseEnterQuantity;

  /// Label for override default unit checkbox
  ///
  /// In en, this message translates to:
  /// **'Override default unit'**
  String get overrideDefaultUnit;

  /// Label for from database option
  ///
  /// In en, this message translates to:
  /// **'From Database'**
  String get fromDatabase;

  /// Label for custom option
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// Dialog title for adding recipe
  ///
  /// In en, this message translates to:
  /// **'Add Recipe'**
  String get addRecipeDialog;

  /// Instruction text for selecting side dish
  ///
  /// In en, this message translates to:
  /// **'Select a recipe to add as a side dish:'**
  String get selectRecipeToAddAsSideDish;

  /// Button text for adding a recipe
  ///
  /// In en, this message translates to:
  /// **'Add Recipe'**
  String get buttonAddRecipe;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get buttonCancel;

  /// Title for cooking recipe dialog
  ///
  /// In en, this message translates to:
  /// **'Cook {recipeName}'**
  String cookRecipeTitle(String recipeName);

  /// Label for cooked on date
  ///
  /// In en, this message translates to:
  /// **'Cooked on: {date}'**
  String cookedOnDate(String date);

  /// Label for planned for date
  ///
  /// In en, this message translates to:
  /// **'Planned for: {date}'**
  String plannedForDate(String date);

  /// Title for ingredients screen with recipe name
  ///
  /// In en, this message translates to:
  /// **'Ingredients: {recipeName}'**
  String ingredientsTitle(String recipeName);

  /// Tooltip for unit override indicator
  ///
  /// In en, this message translates to:
  /// **'Unit overridden (default: {defaultUnit})'**
  String unitOverridden(String defaultUnit);

  /// Label for recipes section
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get recipesLabel;

  /// Tooltip for remove button
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeTooltip;

  /// Label for prep time field
  ///
  /// In en, this message translates to:
  /// **'Prep Time (min)'**
  String get prepTimeLabel;

  /// Label for cook time field
  ///
  /// In en, this message translates to:
  /// **'Cook Time (min)'**
  String get cookTimeLabel;

  /// Compact way to express minutes
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minuteAbbreviation;

  /// Show less
  ///
  /// In en, this message translates to:
  /// **'Show Less'**
  String get showLess;

  /// Show more
  ///
  /// In en, this message translates to:
  /// **'Show More'**
  String get showMore;

  /// Display for detailed preparating times
  ///
  /// In en, this message translates to:
  /// **'Prep: {prepTimeMinutes}min'**
  String detailedPrepTime(int prepTimeMinutes);

  /// Display for detailed cooking times
  ///
  /// In en, this message translates to:
  /// **'Cook: {cookTimeMinutes}min'**
  String detailedCookTime(int cookTimeMinutes);

  /// Display for detailed meal count
  ///
  /// In en, this message translates to:
  /// **'Times Cooked: {mealCount}'**
  String detailedTimesCooked(int mealCount);

  /// Display for detailed last cooked time
  ///
  /// In en, this message translates to:
  /// **'Last Cooked: {formattedLastCooked}'**
  String detailedLastCooked(String formattedLastCooked);

  /// Hint text for side dish search field
  ///
  /// In en, this message translates to:
  /// **'Search side dishes...'**
  String get searchSideDishesHint;

  /// Message when no recipes match search query
  ///
  /// In en, this message translates to:
  /// **'No recipes found matching \"{query}\"'**
  String noRecipesFoundMatching(String query);

  /// Message when no side dishes are available
  ///
  /// In en, this message translates to:
  /// **'No available side dishes'**
  String get noAvailableSideDishes;

  /// Button text to clear search
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// Success message when meal is recorded
  ///
  /// In en, this message translates to:
  /// **'Meal recorded successfully'**
  String get mealRecordedSuccessfully;

  /// Error message when saving meal fails unexpectedly
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred while saving the meal: {error}'**
  String unexpectedErrorSavingMeal(String error);

  /// Instruction text for recording cooking details
  ///
  /// In en, this message translates to:
  /// **'Record cooking details for {recipeName}'**
  String recordCookingDetails(String recipeName);

  /// Button text to record meal details
  ///
  /// In en, this message translates to:
  /// **'Record Meal Details'**
  String get recordMealDetails;

  /// Recipe timing status - ready to explore
  ///
  /// In en, this message translates to:
  /// **'ready to explore'**
  String get readyToExplore;

  /// Recipe timing status - good variety
  ///
  /// In en, this message translates to:
  /// **'good variety'**
  String get goodVariety;

  /// Recipe timing status - recently used
  ///
  /// In en, this message translates to:
  /// **'recently used'**
  String get recentlyUsed;

  /// Recipe timing status - very recently used
  ///
  /// In en, this message translates to:
  /// **'very recently used'**
  String get veryRecentlyUsed;

  /// Tooltip for timing and variety badge
  ///
  /// In en, this message translates to:
  /// **'Timing & Variety: {score}/100\nThis recipe is {status} based on:\n• When you last cooked it\n• Protein type variety\n• Recipe rotation'**
  String timingVarietyTooltip(String score, String status);

  /// Recipe quality status - one of favorites
  ///
  /// In en, this message translates to:
  /// **'one of your favorites'**
  String get oneOfFavorites;

  /// Recipe quality status - highly rated
  ///
  /// In en, this message translates to:
  /// **'highly rated by you'**
  String get highlyRated;

  /// Recipe quality status - above average
  ///
  /// In en, this message translates to:
  /// **'rated above average'**
  String get ratedAboveAverage;

  /// Recipe quality status - below average
  ///
  /// In en, this message translates to:
  /// **'rated below average'**
  String get ratedBelowAverage;

  /// Recipe quality status - not rated
  ///
  /// In en, this message translates to:
  /// **'not yet rated'**
  String get notYetRated;

  /// Tooltip for recipe quality badge
  ///
  /// In en, this message translates to:
  /// **'Recipe Quality: {score}/100\nThis recipe is {status}'**
  String recipeQualityTooltip(String score, String status);

  /// Tooltip for recipe effort badge
  ///
  /// In en, this message translates to:
  /// **'Recipe Effort: {score}/100\nTotal time: {minutes} minutes\nDifficulty level: {difficulty}/5'**
  String recipeEffortTooltip(String score, String minutes, String difficulty);

  /// Badge label - explore (high variety, good timing)
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get badgeExplore;

  /// Badge label - varied (good variety, decent timing)
  ///
  /// In en, this message translates to:
  /// **'Varied'**
  String get badgeVaried;

  /// Badge label - recent (recently used)
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get badgeRecent;

  /// Badge label - repeat (very recently used)
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get badgeRepeat;

  /// Badge label - loved (consistently high rated)
  ///
  /// In en, this message translates to:
  /// **'Loved'**
  String get badgeLoved;

  /// Badge label - high (high quality)
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get badgeHigh;

  /// Badge label - great (good quality)
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get badgeGreat;

  /// Badge label - good (average rating)
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get badgeGood;

  /// Badge label - fair (below average)
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get badgeFair;

  /// Badge label - new (no rating yet)
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get badgeNew;

  /// Badge label - quick (easy and fast)
  ///
  /// In en, this message translates to:
  /// **'Quick'**
  String get badgeQuick;

  /// Badge label - easy (low difficulty)
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get badgeEasy;

  /// Badge label - project (high difficulty, long time)
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get badgeProject;

  /// Badge label - complex (high difficulty)
  ///
  /// In en, this message translates to:
  /// **'Complex'**
  String get badgeComplex;

  /// Badge label - moderate (default effort level)
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get badgeModerate;

  /// Fallback text when no badges are available
  ///
  /// In en, this message translates to:
  /// **'No badges'**
  String get noBadges;

  /// Label for side dishes section
  ///
  /// In en, this message translates to:
  /// **'Side Dishes:'**
  String get sideDishesLabel;

  /// Button to skip/dismiss recipe for current session only
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get buttonSkip;

  /// Button to reduce recommendation frequency for this recipe
  ///
  /// In en, this message translates to:
  /// **'Less Often'**
  String get buttonLessOften;

  /// Button to increase recommendation frequency for this recipe
  ///
  /// In en, this message translates to:
  /// **'More Often'**
  String get buttonMoreOften;

  /// Short button text to reduce recommendation frequency for this recipe
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get buttonLessShort;

  /// Short button text to increase recommendation frequency for this recipe
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get buttonMoreShort;

  /// Button to strongly penalize this recipe in future recommendations
  ///
  /// In en, this message translates to:
  /// **'Never Again'**
  String get buttonNeverAgain;

  /// Button to select recipe for meal plan
  ///
  /// In en, this message translates to:
  /// **'SELECT'**
  String get buttonSelect;

  /// Confirmation dialog text for never again action
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to hide this recipe from future recommendations?'**
  String get confirmNeverAgain;

  /// Confirm button text for hiding recipe
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// Error message when feedback cannot be saved to database
  ///
  /// In en, this message translates to:
  /// **'Could not save feedback. Please try again.'**
  String get feedbackSaveError;

  /// Generic error message for when an error occurs
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// Button text to retry an operation
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Message when no recipes are found
  ///
  /// In en, this message translates to:
  /// **'No recipes found'**
  String get noRecipesFound;

  /// Instruction text for adding first recipe
  ///
  /// In en, this message translates to:
  /// **'Add your first recipe to get started'**
  String get addFirstRecipe;

  /// Title for database migration screen
  ///
  /// In en, this message translates to:
  /// **'Database Migration'**
  String get titleDatabaseMigration;

  /// Button to refresh data
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get buttonRefresh;

  /// Label for database status section
  ///
  /// In en, this message translates to:
  /// **'Database Status'**
  String get labelDatabaseStatus;

  /// Status when database migration is needed
  ///
  /// In en, this message translates to:
  /// **'Migration needed'**
  String get statusMigrationNeeded;

  /// Status when database is up to date
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get statusUpToDate;

  /// Label for current database version
  ///
  /// In en, this message translates to:
  /// **'Current version'**
  String get labelCurrentVersion;

  /// Label for latest available database version
  ///
  /// In en, this message translates to:
  /// **'Latest version'**
  String get labelLatestVersion;

  /// Label for migration progress section
  ///
  /// In en, this message translates to:
  /// **'Migration Progress'**
  String get labelMigrationProgress;

  /// Error title when migration fails
  ///
  /// In en, this message translates to:
  /// **'Migration Failed'**
  String get errorMigrationFailed;

  /// Button to dismiss an error or message
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get buttonDismiss;

  /// Label for migration results section
  ///
  /// In en, this message translates to:
  /// **'Migration Results'**
  String get labelMigrationResults;

  /// Button to start database migrations
  ///
  /// In en, this message translates to:
  /// **'Run Migrations'**
  String get buttonRunMigrations;

  /// Button to rollback database changes
  ///
  /// In en, this message translates to:
  /// **'Rollback'**
  String get buttonRollback;

  /// Label for migration history section
  ///
  /// In en, this message translates to:
  /// **'Migration History'**
  String get labelMigrationHistory;

  /// Message when no migration history exists
  ///
  /// In en, this message translates to:
  /// **'No migration history available'**
  String get messageNoMigrationHistory;

  /// Label for version number
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get labelVersion;

  /// Title for migration confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Confirm Migration'**
  String get titleConfirmMigration;

  /// Warning message before running migrations
  ///
  /// In en, this message translates to:
  /// **'This will update your database schema. Make sure you have a backup.'**
  String get messageMigrationWarning;

  /// Button to continue with an action
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get buttonContinue;

  /// Success message after migration completes
  ///
  /// In en, this message translates to:
  /// **'Migration completed successfully'**
  String get messageMigrationSuccess;

  /// Title for database rollback dialog
  ///
  /// In en, this message translates to:
  /// **'Rollback Database'**
  String get titleRollbackDatabase;

  /// Warning message before database rollback
  ///
  /// In en, this message translates to:
  /// **'Warning: This will revert your database to an earlier version and may cause data loss.'**
  String get messageRollbackWarning;

  /// Label for target version in rollback dialog
  ///
  /// In en, this message translates to:
  /// **'Target Version'**
  String get labelTargetVersion;

  /// Success message after rollback completes
  ///
  /// In en, this message translates to:
  /// **'Rollback completed successfully'**
  String get messageRollbackSuccess;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
