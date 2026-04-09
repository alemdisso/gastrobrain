// analyze_recipe_export.dart
// Analyzes a recipe export file and produces a completeness report
// categorizing recipes as complete, ingredients-only, or stubs.
//
// Usage:
//   dart run tools/analyze_recipe_export.dart <export_file_path> [--generate-list] [--delta <include_list_path>]
//
// Flags:
//   --generate-list            Output UUID include list for all complete recipes
//   --delta <list_path>        Show complete recipes not yet in the include list
//
// Examples:
//   dart run tools/analyze_recipe_export.dart assets/recipe_export_1775743662475.json
//   dart run tools/analyze_recipe_export.dart assets/recipe_export_1775743662475.json --generate-list
//   dart run tools/analyze_recipe_export.dart assets/recipe_export_1775743662475.json --delta tools/seed_recipe_list.txt

// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:convert';

Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty) {
    print('Usage: dart run tools/analyze_recipe_export.dart <export_file_path> [--generate-list] [--delta <list_path>]');
    exit(1);
  }

  final exportPath = arguments[0];
  final generateList = arguments.contains('--generate-list');
  final deltaIndex = arguments.indexOf('--delta');
  final deltaListPath = deltaIndex != -1 && deltaIndex + 1 < arguments.length
      ? arguments[deltaIndex + 1]
      : null;

  final exportFile = File(exportPath);

  if (!exportFile.existsSync()) {
    print('Error: Export file not found at: $exportPath');
    exit(1);
  }

  final jsonString = await exportFile.readAsString();
  final List<dynamic> raw = json.decode(jsonString) as List<dynamic>;
  final recipes = raw.cast<Map<String, dynamic>>();

  // name → uuid for complete recipes
  final complete = <String, String>{};
  final ingredientsOnly = <String>[];
  final stubs = <MapEntry<String, int>>[];

  for (final r in recipes) {
    final name = (r['name'] as String).trim();
    final uuid = r['recipe_id'] as String? ?? '';
    final instructions = ((r['instructions'] as String?) ?? '').trim();
    final ingredients = (r['current_ingredients'] as List?) ?? [];
    final count = ingredients.length;

    if (instructions.isNotEmpty && count >= 2) {
      complete[name] = uuid;
    } else if (count >= 2) {
      ingredientsOnly.add(name);
    } else {
      stubs.add(MapEntry(name, count));
    }
  }

  final sortedComplete = complete.keys.toList()..sort();
  ingredientsOnly.sort();
  stubs.sort((a, b) {
    final cmp = a.value.compareTo(b.value);
    return cmp != 0 ? cmp : a.key.compareTo(b.key);
  });

  final zeroIng = stubs.where((e) => e.value == 0).map((e) => e.key).toList();
  final oneIng = stubs.where((e) => e.value == 1).map((e) => e.key).toList();

  // ── --generate-list mode ─────────────────────────────────────────────────
  if (generateList) {
    print('# Seed recipe include list');
    print('# Generated from: $exportPath');
    print('# Format: <uuid>  # <recipe name>');
    print('# Lines starting with # are ignored by the converter.');
    print('');
    print('## added in 0.2.1');
    for (final name in sortedComplete) {
      print('${complete[name]}  # $name');
    }
    return;
  }

  // ── --delta mode ─────────────────────────────────────────────────────────
  if (deltaListPath != null) {
    final listFile = File(deltaListPath);
    if (!listFile.existsSync()) {
      print('Error: include list not found at $deltaListPath');
      exit(1);
    }
    final listedUuids = listFile
        .readAsLinesSync()
        .where((l) => l.isNotEmpty && !l.trimLeft().startsWith('#'))
        .map((l) => l.split(' ').first.trim())
        .toSet();

    final notInList = sortedComplete
        .where((name) => !listedUuids.contains(complete[name]))
        .toList();

    print('Complete recipes not yet in include list: ${notInList.length}');
    print('');
    for (final name in notInList) {
      print('${complete[name]}  # $name');
    }
    return;
  }

  // ── default analysis mode ─────────────────────────────────────────────────
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
  for (final name in sortedComplete) {
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
