// recipe_converter.dart
// Convert CSV recipe data to JSON for Gastrobrain app

// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

/// Supported frequency types from FrequencyType enum
final List<String> validFrequencies = [
  'daily',
  'weekly',
  'biweekly',
  'monthly',
  'bimonthly',
  'rarely'
];

/// Categories for ingredients based on the project structure
final Map<String, String> categoryMap = {
  'arroz': 'Grain',
  'macarrão': 'Grain',
  'batata': 'Vegetable',
  'tomate': 'Vegetable',
  'carne': 'Protein',
  'frango': 'Protein',
  'peixe': 'Protein',
  'camarão': 'Protein',
  'lula': 'Protein',
  'atum': 'Protein',
  'salmão': 'Protein',
  'pernil': 'Protein',
  'lombo': 'Protein',
  'couve': 'Vegetable',
  'berinjela': 'Vegetable',
  'legumes': 'Vegetable',
  'abobrinha': 'Vegetable',
  'abobora': 'Vegetable',
  'feijão': 'Pulse',
  'grão': 'Pulse',
  'salada': 'Other',
  'queijo': 'Dairy',
  'ovo': 'Protein',
  'pepino': 'Vegetable',
  'repolho': 'Vegetable',
  'quiabo': 'Vegetable',
  'gorgonzola': 'Dairy',
  'manga': 'Fruit',
  'pera': 'Fruit',
  'abacate': 'Fruit',
  'couscous': 'Grain',
  'cuscuz': 'Grain',
  'milho': 'Vegetable',
  'salsicha': 'Protein',
};

/// Main function to process data
void main() async {
  // Define file paths
  const inputFile = 'recipes.csv';
  const outputFile = 'recipes.json';

  try {
    // Read the input file
    final file = File(inputFile);
    if (!await file.exists()) {
      print('Error: Input file not found at path: $inputFile');
      exit(1);
    }

    final content = await file.readAsString();

    // Process the CSV data
    final recipes = processRecipeData(content);

    // Write to the output file
    final outputFileObj = File(outputFile);
    await outputFileObj.writeAsString(jsonEncode(recipes), flush: true);

    print('Successfully converted ${recipes.length} recipes to JSON.');
    print('Output saved to: $outputFile');

    // Generate some statistics
    final proteinTypes = <String, int>{};
    final frequencies = <String, int>{};

    for (final recipe in recipes) {
      final proteinType = recipe['protein_type'] ?? 'none';
      proteinTypes[proteinType] = (proteinTypes[proteinType] ?? 0) + 1;

      final frequency = recipe['desired_frequency'];
      frequencies[frequency] = (frequencies[frequency] ?? 0) + 1;
    }

    print('\nProtein Type Distribution:');
    proteinTypes.forEach((type, count) {
      print('  - $type: $count recipes');
    });

    print('\nFrequency Distribution:');
    frequencies.forEach((freq, count) {
      print('  - $freq: $count recipes');
    });
  } catch (error) {
    print('Error processing recipes: $error');
    exit(1);
  }
}

/// Process the CSV recipe data into a list of recipe objects
List<Map<String, dynamic>> processRecipeData(String csvContent) {
  final recipes = <Map<String, dynamic>>[];
  final lines = csvContent.split('\n');

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;

    try {
      // Split by semicolon (our field separator)
      final fields = line.split(';');

      // Ensure we have enough fields
      if (fields.length < 7) {
        print('Warning: Line ${i + 1} has insufficient fields, skipping.');
        continue;
      }

      // Extract fields
      final name = fields[0].trim();
      final mainIngredient = fields[1].trim();
      final proteinType = fields[2].trim().isEmpty ? null : fields[2].trim();
      final difficulty = int.tryParse(fields[3].trim()) ?? 1;
      final rating = int.tryParse(fields[4].trim()) ?? 1;
      final prepTimeMinutes = int.tryParse(fields[5].trim()) ?? 0;
      final cookTimeMinutes = int.tryParse(fields[6].trim()) ?? 0;
      final desiredFrequency = fields.length > 7 ? fields[7].trim() : 'monthly';

      // Validate frequency
      final frequency =
          validFrequencies.contains(desiredFrequency.toLowerCase())
              ? desiredFrequency.toLowerCase()
              : 'monthly';

      // Generate a UUID for the recipe
      final id = generateUuid();

      // Create recipe object
      final recipe = {
        'id': id,
        'name': name,
        'created_at': DateTime.now().toIso8601String(),
        'difficulty': difficulty,
        'rating': rating,
        'prep_time_minutes': prepTimeMinutes,
        'cook_time_minutes': cookTimeMinutes,
        'desired_frequency': frequency,
        'notes': '',
        'main_ingredient': mainIngredient,
        'protein_type': proteinType,
      };

      recipes.add(recipe);
    } catch (e) {
      print('Warning: Error processing line ${i + 1}: $e');
      continue;
    }
  }

  return recipes;
}

/// Simple UUID generator
String generateUuid() {
  final random = <int>[];
  for (var i = 0; i < 16; i++) {
    random.add((DateTime.now().microsecondsSinceEpoch + i) % 255);
  }

  final hex = random.map((e) => e.toRadixString(16).padLeft(2, '0')).toList();

  return '${hex[0]}${hex[1]}${hex[2]}${hex[3]}-'
      '${hex[4]}${hex[5]}-'
      '${hex[6]}${hex[7]}-'
      '${hex[8]}${hex[9]}-'
      '${hex[10]}${hex[11]}${hex[12]}${hex[13]}${hex[14]}${hex[15]}';
}

/// Method to determine category based on ingredient name
String determineCategory(String ingredientName) {
  final lowerName = ingredientName.toLowerCase();

  for (final entry in categoryMap.entries) {
    if (lowerName.contains(entry.key)) {
      return entry.value;
    }
  }

  return 'Other'; // Default category
}
