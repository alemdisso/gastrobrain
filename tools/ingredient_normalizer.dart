// ignore_for_file: constant_identifier_names, avoid_print

import 'dart:convert';
import 'dart:io';

/// List of common modifiers to remove during normalization
final List<String> modifiers = [
  'fresh', 'dried', 'frozen', 'cold', 'warm', 'hot',
  'chopped', 'diced', 'minced', 'sliced', 'grated', 'shredded',
  'ground', 'crushed', 'crumbled', 'whole', 'halved', 'quartered',
  'peeled', 'trimmed', 'cored', 'seeded', 'stemmed',
  'boneless', 'skinless', 'bone-in', 'skin-on',
  'cooked', 'raw', 'roasted', 'toasted', 'grilled', 'boiled', 'steamed',
  'extra', 'large', 'small', 'medium', 'thick', 'thin', 'light', 'packed',
  'good quality', 'premium', 'organic', 'free-range', 'grass-fed',
  'ripe', 'overripe', 'underripe', 'firm', 'soft',
  'finely', 'roughly' // Added as requested
];

/// Function to normalize an ingredient name
String normalizeIngredient(String ingredient) {
  // Convert to lowercase and trim spaces
  String normalized = ingredient.toLowerCase().trim();

  // Remove leading hyphens or dashes that might be from list formatting
  normalized = normalized.replaceAll(RegExp(r'^[-–—•]\s*'), '');

  // Remove modifiers
  for (final modifier in modifiers) {
    // Create a pattern to match the modifier as a whole word
    final pattern =
        RegExp(r'\b' + RegExp.escape(modifier) + r'\b', caseSensitive: false);
    normalized = normalized.replaceAll(pattern, '');
  }

  // Replace multiple spaces with a single space
  normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');

  // Trim spaces again after modifications
  normalized = normalized.trim();

  return normalized;
}

/// Extract ingredients and track their frequencies
Map<String, int> countIngredientFrequencies(List<dynamic> recipeData) {
  // Map to store ingredient frequencies
  final Map<String, int> ingredientFrequencies = {};

  // Process each recipe
  for (final recipe in recipeData) {
    if (recipe['ingredients'] != null && recipe['ingredients'] is List) {
      for (final ingredient in recipe['ingredients']) {
        if (ingredient is String) {
          final normalized = normalizeIngredient(ingredient);
          if (normalized.isNotEmpty) {
            ingredientFrequencies[normalized] =
                (ingredientFrequencies[normalized] ?? 0) + 1;
          }
        }
      }
    }
  }

  return ingredientFrequencies;
}

/// Frequency threshold for common ingredients
const int FREQUENCY_THRESHOLD = 40;

/// Main function to process data
Map<String, dynamic> analyzeIngredientFrequencies(
    String inputFile, String outputFile) {
  try {
    // Read the input file
    final file = File(inputFile);
    final data = file.readAsStringSync();
    final recipeData = jsonDecode(data) as List<dynamic>;

    // Process the ingredients and get frequencies
    final ingredientFrequencies = countIngredientFrequencies(recipeData);

    // Separate into two lists: below threshold and at/above threshold
    final List<Map<String, dynamic>> belowThreshold = [];
    final List<Map<String, dynamic>> aboveThreshold = [];

    ingredientFrequencies.forEach((ingredient, count) {
      final item = {'ingredient': ingredient, 'count': count};
      if (count < FREQUENCY_THRESHOLD) {
        belowThreshold.add(item);
      } else {
        aboveThreshold.add(item);
      }
    });

    // Sort both lists
    belowThreshold.sort(
        (a, b) => b['count'].compareTo(a['count'])); // Sort by count descending
    aboveThreshold.sort(
        (a, b) => b['count'].compareTo(a['count'])); // Sort by count descending

    // Create the output JSON object
    final output = {
      'totalIngredients': ingredientFrequencies.length,
      'frequencyThreshold': FREQUENCY_THRESHOLD,
      'commonIngredientsCount': aboveThreshold.length,
      'commonIngredients': aboveThreshold
    };

    // Write to the output file
    final outputFileObj = File(outputFile);
    outputFileObj.writeAsStringSync(jsonEncode(output), flush: true);

    print('Successfully processed ${recipeData.length} recipes.');
    print('Found ${ingredientFrequencies.length} unique ingredients:');
    print(
        '  - ${aboveThreshold.length} common ingredients (appeared $FREQUENCY_THRESHOLD or more times)');
    print(
        '  - ${belowThreshold.length} rare ingredients (appeared less than $FREQUENCY_THRESHOLD times)');
    print('Only common ingredients saved to $outputFile');

    return output;
  } catch (error) {
    print('Error processing ingredients: $error');
    rethrow;
  }
}

void main(List<String> args) {
  if (args.length < 2) {
    print(
        'Usage: dart ingredient_frequency_analyzer.dart <input-file.json> <output-file.json>');
    exit(1);
  }

  final inputFile = args[0];
  final outputFile = args[1];
  analyzeIngredientFrequencies(inputFile, outputFile);
}
