// analyze_recipe_export.dart
// Analyzes a recipe export file and produces a completeness report
// categorizing recipes as complete, ingredients-only, or stubs.
//
// Usage:
//   dart run tools/analyze_recipe_export.dart <export_file_path>
//
// Example:
//   dart run tools/analyze_recipe_export.dart assets/recipe_export_1775677070723.json

// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:convert';

Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty) {
    print('Usage: dart run tools/analyze_recipe_export.dart <export_file_path>');
    print('\nExample:');
    print('  dart run tools/analyze_recipe_export.dart assets/recipe_export_1775677070723.json');
    exit(1);
  }

  final exportPath = arguments[0];
  final exportFile = File(exportPath);

  if (!exportFile.existsSync()) {
    print('Error: Export file not found at: $exportPath');
    exit(1);
  }

  final jsonString = await exportFile.readAsString();
  final List<dynamic> raw = json.decode(jsonString) as List<dynamic>;
  final recipes = raw.cast<Map<String, dynamic>>();

  final complete = <String>[];
  final ingredientsOnly = <String>[];
  final stubs = <MapEntry<String, int>>[];

  for (final r in recipes) {
    final name = r['name'] as String;
    final instructions = ((r['instructions'] as String?) ?? '').trim();
    final ingredients = (r['current_ingredients'] as List?) ?? [];
    final count = ingredients.length;

    if (instructions.isNotEmpty && count >= 2) {
      complete.add(name);
    } else if (count >= 2) {
      ingredientsOnly.add(name);
    } else {
      stubs.add(MapEntry(name, count));
    }
  }

  complete.sort();
  ingredientsOnly.sort();
  stubs.sort((a, b) {
    final cmp = a.value.compareTo(b.value);
    return cmp != 0 ? cmp : a.key.compareTo(b.key);
  });

  final zeroIng = stubs.where((e) => e.value == 0).map((e) => e.key).toList();
  final oneIng = stubs.where((e) => e.value == 1).map((e) => e.key).toList();

  print('Export file: $exportPath');
  print('Total: ${recipes.length} recipes');
  print('');
  print('┌─────────────────────────┬───────┐');
  print('│ Category                │ Count │');
  print('├─────────────────────────┼───────┤');
  print('│ Complete                │ ${_pad(complete.length)}  │');
  print('│ Ingredients only        │ ${_pad(ingredientsOnly.length)}  │');
  print('│ Stubs (0–1 ingredient)  │ ${_pad(stubs.length)}  │');
  print('└─────────────────────────┴───────┘');
  print('');

  print('── Complete (instructions + 2+ ingredients) — ${complete.length} recipes ──');
  for (final name in complete) {
    print('  - $name');
  }
  print('');

  print('── Ingredients only (2+ ingredients, no instructions) — ${ingredientsOnly.length} recipes ──');
  for (final name in ingredientsOnly) {
    print('  - $name');
  }
  print('');

  print('── Stubs (0–1 ingredient) — ${stubs.length} recipes ──');
  print('');
  print('  0 ingredients (${zeroIng.length}):');
  for (final name in zeroIng) {
    print('    - $name');
  }
  print('');
  print('  1 ingredient (${oneIng.length}):');
  for (final name in oneIng) {
    print('    - $name');
  }
}

String _pad(int n) => n.toString().padLeft(3);
