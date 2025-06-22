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
  /// **'Are you sure you want to delete {ingredientName}?'**
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

  /// Error message prefix for meal editing errors
  ///
  /// In en, this message translates to:
  /// **'Error editing meal:'**
  String get errorEditingMeal;

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

  /// Error message when meal is not found or not cooked
  ///
  /// In en, this message translates to:
  /// **'Meal not found or not yet cooked'**
  String get mealNotFoundOrNotCooked;

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

  /// Success message when meal recipes are updated
  ///
  /// In en, this message translates to:
  /// **'Meal recipes updated successfully'**
  String get mealRecipesUpdatedSuccessfully;

  /// Error message when no primary recipe is found
  ///
  /// In en, this message translates to:
  /// **'No primary recipe found'**
  String get noPrimaryRecipeFound;

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
