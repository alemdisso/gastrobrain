// ignore_for_file: avoid_print
// convert_export_to_seed.dart
//
// LOCAL-ONLY tool — runs on the dev machine, not bundled with the app.
//
// Reads the latest recipe_export_*.json file from the assets/ directory and
// produces two seed files consumed by the app on fresh install:
//
//   assets/recipes.json     — flat recipe list (no cooking history, no IDs)
//   assets/ingredients.json — de-duplicated ingredient list extracted from
//                             all recipes' current_ingredients
//
// Only recipes whose recipe_id appears in tools/seed_recipe_list.txt are
// included. To add or remove a recipe from seed, edit that file and rerun.
//
// Usage:
//   dart run tools/convert_export_to_seed.dart [export_file_path]
//
// If no path is given, the most-recently-modified recipe_export_*.json is used.
// Run from the project root.

import 'dart:convert';
import 'dart:io';

void main(List<String> arguments) async {
  // ── 1. Load include list ─────────────────────────────────────────────────
  const includeListPath = 'tools/seed_recipe_list.txt';
  final includeListFile = File(includeListPath);

  if (!includeListFile.existsSync()) {
    print('ERROR: Include list not found at $includeListPath.');
    print('Run: dart run tools/analyze_recipe_export.dart <export> --generate-list > $includeListPath');
    exit(1);
  }

  final includedUuids = includeListFile
      .readAsLinesSync()
      .where((l) => l.isNotEmpty && !l.trimLeft().startsWith('#'))
      .map((l) => l.split(' ').first.trim())
      .toSet();

  print('Include list: $includeListPath (${includedUuids.length} recipes)');

  // ── 2. Locate the recipe export file ────────────────────────────────────
  final assetsDir = Directory('assets');
  if (!assetsDir.existsSync()) {
    print('ERROR: assets/ directory not found. Run from the project root.');
    exit(1);
  }

  File exportFile;
  if (arguments.isNotEmpty) {
    exportFile = File(arguments[0]);
    if (!exportFile.existsSync()) {
      print('ERROR: Export file not found: ${arguments[0]}');
      exit(1);
    }
  } else {
    final exportFiles = assetsDir
        .listSync()
        .whereType<File>()
        .where((f) => f.uri.pathSegments.last.startsWith('recipe_export_') &&
            f.uri.pathSegments.last.endsWith('.json'))
        .toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    if (exportFiles.isEmpty) {
      print('ERROR: No recipe_export_*.json found in assets/.');
      exit(1);
    }
    exportFile = exportFiles.first;
  }

  print('Reading export: ${exportFile.path}');

  // ── 3. Parse and filter the export ──────────────────────────────────────
  final List<dynamic> exportData =
      json.decode(exportFile.readAsStringSync()) as List<dynamic>;

  print('Found ${exportData.length} recipes in export.');

  final filteredData = exportData
      .where((r) => includedUuids.contains(r['recipe_id'] as String?))
      .toList();

  print('Filtered to ${filteredData.length} recipes from include list.');

  if (filteredData.length != includedUuids.length) {
    final foundUuids = filteredData.map((r) => r['recipe_id'] as String).toSet();
    final missing = includedUuids.difference(foundUuids);
    print('WARNING: ${missing.length} UUID(s) in include list not found in export:');
    for (final uuid in missing) {
      print('  $uuid');
    }
  }

  // ── 4. Build seed recipes ────────────────────────────────────────────────
  final seedRecipes = <Map<String, dynamic>>[];

  for (final raw in filteredData) {
    final meta = raw['metadata'] as Map<String, dynamic>? ?? {};

    seedRecipes.add({
      'name': (raw['name'] as String).toLowerCase(),
      'desired_frequency': meta['desired_frequency'] as String? ?? 'monthly',
      'notes': meta['notes'] as String? ?? '',
      'created_at': meta['created_at'] as String? ??
          DateTime.now().toIso8601String(),
      'difficulty': (meta['difficulty'] as num?)?.toInt() ?? 1,
      'prep_time_minutes': (meta['prep_time_minutes'] as num?)?.toInt() ?? 0,
      'cook_time_minutes': (meta['cook_time_minutes'] as num?)?.toInt() ?? 0,
      'rating': (meta['rating'] as num?)?.toInt() ?? 0,
      'instructions': raw['instructions'] as String? ?? '',
    });
  }

  // ── 4. Build seed ingredients (de-duped by name, case-insensitive) ───────
  final seen = <String>{};
  final seedIngredients = <Map<String, dynamic>>[];

  for (final raw in filteredData) {
    final ingredients =
        raw['current_ingredients'] as List<dynamic>? ?? [];

    for (final ing in ingredients) {
      final name = (ing['name'] as String? ?? '').trim().toLowerCase();
      if (name.isEmpty || seen.contains(name)) continue;
      seen.add(name);

      seedIngredients.add({
        'name': name,
        'category': ing['category'] as String? ?? 'other',
        'unit': ing['unit'] as String?,
        'protein_type': ing['protein_type'] as String?,
      });
    }
  }

  // Sort alphabetically for stable output
  seedRecipes.sort(
      (a, b) => (a['name'] as String).compareTo(b['name'] as String));
  seedIngredients.sort(
      (a, b) => (a['name'] as String).compareTo(b['name'] as String));

  // ── 5. Write output files ────────────────────────────────────────────────
  const encoder = JsonEncoder.withIndent('  ');

  final recipesOut = File('assets/recipes.json');
  recipesOut.writeAsStringSync(encoder.convert(seedRecipes));

  final ingredientsOut = File('assets/ingredients.json');
  ingredientsOut.writeAsStringSync(encoder.convert(seedIngredients));

  // ── 6. Summary ───────────────────────────────────────────────────────────
  print('');
  print('✓ assets/recipes.json     — ${seedRecipes.length} recipes');
  print('✓ assets/ingredients.json — ${seedIngredients.length} ingredients');
  print('');
  print('Done. Review the output files before committing.');
}
