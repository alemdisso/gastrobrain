// test/fixtures/boundary_fixtures.dart

/// Boundary value fixtures for edge case testing.
///
/// Provides standardized extreme and boundary values for testing how the
/// application handles edge cases across different data types.
///
/// Example usage:
/// ```dart
/// testWidgets('handles very long recipe name', (tester) async {
///   await tester.enterText(
///     find.byKey(Key('recipeName')),
///     BoundaryValues.veryLongText,
///   );
///   // Test how UI handles rendering...
/// });
/// ```
class BoundaryValues {
  // ==================== TEXT VALUES ====================

  /// Empty string
  static const String emptyString = '';

  /// Single character
  static const String singleChar = 'A';

  /// Whitespace-only string (spaces, tabs)
  static const String whitespaceOnly = '   \t  ';

  /// Very long text (1000 characters)
  static const String veryLongText = 'Lorem ipsum dolor sit amet, consectetur '
      'adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna '
      'aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris '
      'nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit '
      'in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint '
      'occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim '
      'id est laborum. Sed ut perspiciatis unde omnis iste natus error sit voluptatem '
      'accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo '
      'inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo '
      'enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia '
      'consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro '
      'quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, '
      'sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam '
      'quaerat voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem ullam '
      'corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur.';

  /// Extremely long text (10000 characters)
  static final String extremelyLongText = 'A' * 10000;

  /// Text with special HTML/XML characters
  static const String specialChars = '<script>"alert"\'&</script>';

  /// Text with emoji
  static const String withEmoji = 'Recipe with emojis 😀🎉🍕🍰';

  /// Text with unicode characters (accents, etc.)
  static const String withUnicode = 'Crème brûlée, Jalapeño, Naïve café';

  /// Text with newlines
  static const String withNewlines = 'Line 1\nLine 2\nLine 3';

  /// Text with multiple consecutive spaces
  static const String multipleSpaces = 'Word    with    many    spaces';

  /// SQL injection attempt (should be escaped)
  static const String sqlInjection = "'; DROP TABLE recipes; --";

  /// XSS attempt (should be escaped)
  static const String xssAttempt = '<img src=x onerror=alert(1)>';

  // ==================== NUMERIC VALUES ====================

  /// Zero
  static const int zero = 0;

  /// Minimum valid positive integer
  static const int minPositiveInt = 1;

  /// Small integer
  static const int small = 5;

  /// Medium integer
  static const int medium = 100;

  /// Large integer
  static const int large = 999;

  /// Very large integer
  static const int veryLarge = 9999;

  /// Maximum reasonable integer for app
  static const int maxReasonable = 999999;

  /// Negative integer
  static const int negative = -1;

  /// Large negative integer
  static const int largeNegative = -999;

  /// Decimal value
  static const double decimal = 2.5;

  /// Very small decimal
  static const double verySmallDecimal = 0.1;

  /// Large decimal
  static const double largeDecimal = 999.99;

  // ==================== RATING VALUES ====================

  /// Minimum rating (0 = unrated)
  static const int ratingUnrated = 0;

  /// Minimum valid rating
  static const int ratingMin = 1;

  /// Maximum valid rating
  static const int ratingMax = 5;

  /// Invalid rating (too high)
  static const int ratingTooHigh = 6;

  /// Invalid rating (negative)
  static const int ratingNegative = -1;

  // ==================== DIFFICULTY VALUES ====================

  /// Minimum difficulty
  static const int difficultyMin = 1;

  /// Maximum difficulty
  static const int difficultyMax = 5;

  /// Invalid difficulty (too low)
  static const int difficultyTooLow = 0;

  /// Invalid difficulty (too high)
  static const int difficultyTooHigh = 6;

  // ==================== SERVINGS VALUES ====================

  /// Minimum valid servings
  static const int servingsMin = 1;

  /// Typical servings
  static const int servingsTypical = 4;

  /// Large servings
  static const int servingsLarge = 50;

  /// Very large servings
  static const int servingsVeryLarge = 999;

  /// Invalid servings (zero)
  static const int servingsZero = 0;

  /// Invalid servings (negative)
  static const int servingsNegative = -1;

  // ==================== TIME VALUES (minutes) ====================

  /// Zero time
  static const int timeZero = 0;

  /// Minimum time
  static const int timeMin = 1;

  /// Short time
  static const int timeShort = 15;

  /// Medium time
  static const int timeMedium = 60;

  /// Long time
  static const int timeLong = 240;

  /// Very long time
  static const int timeVeryLong = 9999;

  /// Decimal time (half hour)
  static const double timeDecimal = 30.5;

  /// Negative time
  static const int timeNegative = -1;

  // ==================== DATE VALUES ====================

  /// Very old date (year 2000)
  static final DateTime dateVeryOld = DateTime(2000, 1, 1);

  /// Old date (10 years ago)
  static final DateTime dateOld = DateTime.now().subtract(const Duration(days: 3650));

  /// Recent date (yesterday)
  static final DateTime dateYesterday = DateTime.now().subtract(const Duration(days: 1));

  /// Today
  static final DateTime dateToday = DateTime.now();

  /// Tomorrow
  static final DateTime dateTomorrow = DateTime.now().add(const Duration(days: 1));

  /// Future date (next year)
  static final DateTime dateFuture = DateTime.now().add(const Duration(days: 365));

  /// Far future date (year 2100)
  static final DateTime dateFarFuture = DateTime(2100, 12, 31);

  // ==================== LIST SIZE VALUES ====================

  /// Empty list size
  static const int listEmpty = 0;

  /// Single item list
  static const int listSingle = 1;

  /// Small list (< 10)
  static const int listSmall = 5;

  /// Medium list (10-50)
  static const int listMedium = 25;

  /// Large list (50-100)
  static const int listLarge = 75;

  /// Very large list (100+)
  static const int listVeryLarge = 150;

  /// Extremely large list (1000+)
  static const int listExtreme = 1500;

  // ==================== INGREDIENT QUANTITIES ====================

  /// Very small quantity
  static const String quantityVerySmall = '0.25';

  /// Small quantity
  static const String quantitySmall = '1';

  /// Medium quantity
  static const String quantityMedium = '5';

  /// Large quantity
  static const String quantityLarge = '50';

  /// Very large quantity
  static const String quantityVeryLarge = '999';

  /// Decimal quantity
  static const String quantityDecimal = '2.5';

  /// Zero quantity
  static const String quantityZero = '0';

  /// Negative quantity
  static const String quantityNegative = '-1';

  // ==================== NOTES/INSTRUCTIONS ====================

  /// Empty notes
  static const String notesEmpty = '';

  /// Short notes
  static const String notesShort = 'Quick note.';

  /// Medium notes
  static const String notesMedium = 'This is a medium-length note with some '
      'details about the recipe or meal. It contains a few sentences.';

  /// Long notes (close to 1000 chars)
  static const String notesLong = 'This is a very long note that contains '
      'extensive details about the recipe, cooking process, and various tips. '
      'It includes multiple paragraphs of information. The first paragraph discusses '
      'ingredient selection and preparation. The second paragraph covers cooking '
      'techniques and timing. The third paragraph provides serving suggestions and '
      'potential variations. The fourth paragraph includes storage recommendations '
      'and reheating instructions. The fifth paragraph shares the recipe\'s history '
      'and cultural significance. Additional notes include dietary considerations, '
      'common mistakes to avoid, and equipment recommendations. This comprehensive '
      'guide ensures successful recipe execution. More text to reach the length goal. '
      'Additional information about flavor profiles, texture considerations, and '
      'presentation ideas. Tips for meal planning and ingredient substitutions. '
      'Nutritional information and health benefits. Recipe scaling guidance for '
      'different serving sizes.';

  /// Extremely long notes (10000+ chars)
  static final String notesExtreme = extremelyLongText;

  // ==================== RECIPE NAMES ====================

  /// Single character name
  static const String recipeSingleChar = 'A';

  /// Short name
  static const String recipeShort = 'Pasta';

  /// Medium name
  static const String recipeMedium = 'Spaghetti Carbonara';

  /// Long name
  static const String recipeLong = 'Grandma\'s Special Homemade Italian '
      'Spaghetti Carbonara with Crispy Pancetta and Fresh Parmesan';

  /// Very long name (100+ chars)
  static const String recipeVeryLong = 'The Ultimate Traditional Authentic '
      'Italian Spaghetti alla Carbonara Recipe with Crispy Pancetta, Fresh '
      'Farm Eggs, Aged Parmigiano-Reggiano, and Black Pepper from Tellicherry';

  /// Name with special characters
  static const String recipeSpecialChars = 'Mom\'s "Famous" <Pasta> & Sauce';

  /// Name with emoji
  static const String recipeEmoji = 'Delicious Pasta 🍝😋';

  /// Name with unicode
  static const String recipeUnicode = 'Crème Brûlée au Café';

  // ==================== INGREDIENT NAMES ====================

  /// Single character ingredient
  static const String ingredientSingleChar = 'X';

  /// Short ingredient name
  static const String ingredientShort = 'Salt';

  /// Medium ingredient name
  static const String ingredientMedium = 'Extra Virgin Olive Oil';

  /// Long ingredient name
  static const String ingredientLong = 'Organic Free-Range Chicken Breast '
      'Tenderloins with Skin Removed';

  /// Ingredient with special chars
  static const String ingredientSpecialChars = 'Red Wine (Cabernet)';

  /// Ingredient with unicode
  static const String ingredientUnicode = 'Jalapeño Peppers';

  // ==================== SEARCH QUERIES ====================

  /// Empty search
  static const String searchEmpty = '';

  /// Single char search
  static const String searchSingleChar = 'a';

  /// Short search
  static const String searchShort = 'pasta';

  /// Long search query
  static const String searchLong = 'traditional authentic italian recipe '
      'with fresh ingredients';

  /// Search with special characters
  static const String searchSpecialChars = 'recipe & "special" ingredients';

  /// Search with no expected results
  static const String searchNoResults = 'xyzabc123impossiblerecipe';
}

/// Common boundary value combinations for specific use cases.
///
/// Provides pre-configured sets of boundary values for common testing scenarios.
class BoundaryValueSets {
  /// Recipe boundary test values
  static final recipeBoundaries = {
    'empty_name': '',
    'single_char': 'A',
    'long_name': BoundaryValues.recipeVeryLong,
    'special_chars': BoundaryValues.recipeSpecialChars,
    'zero_servings': 0,
    'max_servings': 999,
    'zero_time': 0,
    'max_time': 9999,
    'invalid_rating': 6,
    'invalid_difficulty': 0,
  };

  /// Meal boundary test values
  static final mealBoundaries = {
    'empty_notes': '',
    'long_notes': BoundaryValues.notesLong,
    'extreme_notes': BoundaryValues.notesExtreme,
    'zero_servings': 0,
    'max_servings': 999,
    'past_date': BoundaryValues.dateVeryOld,
    'future_date': BoundaryValues.dateFarFuture,
  };

  /// Ingredient boundary test values
  static final ingredientBoundaries = {
    'empty_name': '',
    'single_char': 'X',
    'long_name': BoundaryValues.ingredientLong,
    'zero_quantity': '0',
    'negative_quantity': '-1',
    'max_quantity': '999',
    'decimal_quantity': '2.5',
  };

  /// List size boundaries for testing collection handling
  static final listSizeBoundaries = [
    0, // Empty
    1, // Single item
    10, // Small
    50, // Medium
    100, // Large
    500, // Very large
    1000, // Extreme
  ];

  /// Text length boundaries for testing text inputs
  static final textLengthBoundaries = [
    0, // Empty
    1, // Single char
    50, // Short
    200, // Medium
    1000, // Long
    10000, // Extreme
  ];
}
