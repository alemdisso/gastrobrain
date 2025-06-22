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
