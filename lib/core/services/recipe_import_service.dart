import 'dart:convert';
import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import '../../database/database_helper.dart';
import '../errors/gastrobrain_exceptions.dart';
import '../repositories/tag_repository.dart';
import '../../utils/id_generator.dart';
import 'recipe_export_service.dart';

export 'recipe_import_service.dart' show DuplicateStrategy;

/// How to handle a record whose name already exists in the local database.
enum DuplicateStrategy {
  /// Keep the local record unchanged; skip the imported one.
  skip,

  /// Overwrite the local record with the imported data.
  replace,

  /// Import the record as a new entry (appends " (imported)" to the name).
  addAsNew,
}

/// Service for importing recipe data from a Gastrobrain JSON export file.
///
/// Usage (two-phase):
/// ```dart
/// final preview = await service.previewImport(bytes);
/// // show strategy dialog if preview.duplicateNames.isNotEmpty
/// final result = await service.executeImport(preview, strategy);
/// ```
class RecipeImportService {
  final DatabaseHelper _databaseHelper;
  final TagRepository _tagRepository;

  RecipeImportService(this._databaseHelper, {TagRepository? tagRepository})
      : _tagRepository = tagRepository ?? TagRepository(_databaseHelper);

  /// Parse and validate [bytes] without writing to the database.
  ///
  /// Returns a [RecipeImportPreview] containing the parsed records and the
  /// set of recipe names that already exist locally.
  /// Throws [GastrobrainException] if the file is malformed.
  Future<RecipeImportPreview> previewImport(Uint8List bytes) async {
    final List<dynamic> jsonData;
    try {
      jsonData = json.decode(utf8.decode(bytes)) as List<dynamic>;
    } catch (e) {
      throw const GastrobrainException('Invalid JSON: could not parse file.');
    }

    if (!RecipeExportService.validateExportStructure(jsonData)) {
      throw const GastrobrainException(
          'Invalid format: file does not match the recipe export structure.');
    }

    if (jsonData.isEmpty) {
      return const RecipeImportPreview(records: [], duplicateNames: {});
    }

    final records = jsonData.cast<Map<String, dynamic>>();

    // Detect duplicates by name (case-insensitive) against local DB.
    final existingRecipes = await _databaseHelper.getAllRecipes();
    final existingNamesLower =
        existingRecipes.map((r) => r.name.toLowerCase().trim()).toSet();

    final duplicateNames = <String>{};
    for (final record in records) {
      final name = (record['name'] as String).toLowerCase().trim();
      if (existingNamesLower.contains(name)) {
        duplicateNames.add(name);
      }
    }

    return RecipeImportPreview(
        records: records, duplicateNames: duplicateNames);
  }

  /// Execute the import using [strategy] for any duplicates found in [preview].
  ///
  /// All writes occur in a single transaction — any unhandled error rolls back
  /// the entire import.
  Future<RecipeImportResult> executeImport(
    RecipeImportPreview preview,
    DuplicateStrategy strategy,
  ) async {
    if (preview.records.isEmpty) {
      return const RecipeImportResult(
        recipesAdded: 0,
        recipesUpdated: 0,
        recipesSkipped: 0,
        ingredientsAdded: 0,
        ingredientsUpdated: 0,
        ingredientsSkipped: 0,
        errors: [],
        warnings: [],
      );
    }

    final errors = <String>[];
    final warnings = <String>[];
    int recipesAdded = 0;
    int recipesUpdated = 0;
    int recipesSkipped = 0;
    int ingredientsAdded = 0;
    int ingredientsUpdated = 0;
    int ingredientsSkipped = 0;

    final db = await _databaseHelper.database;

    await db.transaction((txn) async {
      // Snapshot junction tables so meal history survives any recipe replacement.
      final mealRecipesSnap =
          List<Map<String, dynamic>>.from(await txn.query('meal_recipes'));
      final mpiRecipesSnap = List<Map<String, dynamic>>.from(
          await txn.query('meal_plan_item_recipes'));

      for (final record in preview.records) {
        final importedName = (record['name'] as String).trim();
        final isDuplicate =
            preview.duplicateNames.contains(importedName.toLowerCase());

        if (isDuplicate) {
          switch (strategy) {
            case DuplicateStrategy.skip:
              recipesSkipped++;
              continue;
            case DuplicateStrategy.replace:
              final counts = await _replaceRecipe(
                  record, txn, warnings);
              recipesUpdated++;
              ingredientsAdded += counts['added']!;
              ingredientsUpdated += counts['updated']!;
              ingredientsSkipped += counts['skipped']!;
            case DuplicateStrategy.addAsNew:
              final modified = Map<String, dynamic>.from(record);
              modified['name'] = '$importedName (imported)';
              modified['recipe_id'] = IdGenerator.generateId();
              final counts = await _insertRecipe(modified, txn, warnings);
              recipesAdded++;
              ingredientsAdded += counts['added']!;
              ingredientsSkipped += counts['skipped']!;
          }
        } else {
          try {
            final counts = await _insertRecipe(record, txn, warnings);
            recipesAdded++;
            ingredientsAdded += counts['added']!;
            ingredientsSkipped += counts['skipped']!;
          } catch (e) {
            errors.add('Failed to import recipe "$importedName": $e');
          }
        }
      }

      // Restore junction rows for recipes that survived.
      final allRecipeIds =
          (await txn.query('recipes', columns: ['id']))
              .map((r) => r['id'] as String)
              .toSet();

      for (final row in mealRecipesSnap) {
        if (allRecipeIds.contains(row['recipe_id'])) {
          await txn.insert('meal_recipes', Map<String, dynamic>.from(row),
              conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }
      for (final row in mpiRecipesSnap) {
        if (allRecipeIds.contains(row['recipe_id'])) {
          await txn.insert(
              'meal_plan_item_recipes', Map<String, dynamic>.from(row),
              conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }
    });

    return RecipeImportResult(
      recipesAdded: recipesAdded,
      recipesUpdated: recipesUpdated,
      recipesSkipped: recipesSkipped,
      ingredientsAdded: ingredientsAdded,
      ingredientsUpdated: ingredientsUpdated,
      ingredientsSkipped: ingredientsSkipped,
      errors: errors,
      warnings: warnings,
    );
  }

  // ── private helpers ───────────────────────────────────────────────────────

  /// Insert a recipe and its ingredients/tags. Returns ingredient counts.
  Future<Map<String, int>> _insertRecipe(
    Map<String, dynamic> record,
    Transaction txn,
    List<String> warnings,
  ) async {
    final metadata = record['metadata'] as Map<String, dynamic>;
    final recipeId = record['recipe_id'] as String;

    await txn.insert('recipes', {
      'id': recipeId,
      'name': (record['name'] as String).trim(),
      'difficulty': metadata['difficulty'],
      'prep_time_minutes': metadata['prep_time_minutes'],
      'cook_time_minutes': metadata['cook_time_minutes'],
      'marinating_time_minutes': metadata['marinating_time_minutes'] ?? 0,
      'rating': metadata['rating'],
      'servings': metadata['servings'] ?? 0,
      'desired_frequency': metadata['desired_frequency'],
      'notes': metadata['notes'] ?? '',
      'instructions': record['instructions'] ?? '',
      'created_at': metadata['created_at'],
    });

    final ingCounts = await _upsertIngredients(record, recipeId, txn, warnings);
    await _restoreTags(record, recipeId, txn, warnings);

    return ingCounts;
  }

  /// Delete an existing recipe by name and re-insert from [record].
  Future<Map<String, int>> _replaceRecipe(
    Map<String, dynamic> record,
    Transaction txn,
    List<String> warnings,
  ) async {
    final importedName = (record['name'] as String).trim();

    // Find existing recipe ID by name (case-insensitive).
    final existing = await txn.rawQuery(
      'SELECT id FROM recipes WHERE LOWER(name) = LOWER(?)',
      [importedName],
    );
    if (existing.isNotEmpty) {
      final existingId = existing.first['id'] as String;
      await txn.delete('recipe_ingredients',
          where: 'recipe_id = ?', whereArgs: [existingId]);
      await txn.delete('recipe_tags',
          where: 'recipe_id = ?', whereArgs: [existingId]);
      await txn.delete('recipes',
          where: 'id = ?', whereArgs: [existingId]);
    }

    return _insertRecipe(record, txn, warnings);
  }

  /// Insert/update ingredients referenced by [record] and link them to [recipeId].
  Future<Map<String, int>> _upsertIngredients(
    Map<String, dynamic> record,
    String recipeId,
    Transaction txn,
    List<String> warnings,
  ) async {
    int added = 0;
    int skipped = 0;

    final ingredients =
        (record['current_ingredients'] as List? ?? [])
            .cast<Map<String, dynamic>>();

    for (final ing in ingredients) {
      final ingredientId = ing['ingredient_id'] as String?;
      if (ingredientId == null) {
        skipped++;
        continue;
      }

      try {
        // Upsert ingredient (insert or ignore if already present).
        await txn.insert(
          'ingredients',
          {
            'id': ingredientId,
            'name': ing['name'],
            'category': ing['category'],
            'unit': ing['unit'],
            'protein_type': ing['protein_type'],
            'notes': ing['preparation_notes'],
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );

        await txn.insert('recipe_ingredients', {
          'id': IdGenerator.generateId(),
          'recipe_id': recipeId,
          'ingredient_id': ingredientId,
          'quantity': ing['quantity'],
          'quantity_max': ing['quantity_max'],
          'notes': ing['preparation_notes'],
          'unit_override': ing['unit'],
          'custom_name': null,
          'custom_category': null,
          'custom_unit': null,
        });
        added++;
      } catch (e) {
        warnings.add('Skipped ingredient "${ing['name']}": $e');
        skipped++;
      }
    }

    return {'added': added, 'updated': 0, 'skipped': skipped};
  }

  /// Restore tags from [record] onto [recipeId] inside [txn].
  Future<void> _restoreTags(
    Map<String, dynamic> record,
    String recipeId,
    Transaction txn,
    List<String> warnings,
  ) async {
    final rawTags =
        (record['tags'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final tagIds = <String>[];

    for (final t in rawTags) {
      try {
        final tag = await _tagRepository.getOrCreateTagTxn(
            t['name'] as String, t['type'] as String, txn);
        tagIds.add(tag.id);
      } catch (e) {
        warnings.add('Skipped tag "${t['name']}": $e');
      }
    }

    await _tagRepository.setTagsForRecipeTxn(recipeId, tagIds, txn);
  }
}

// ── Data classes ─────────────────────────────────────────────────────────────

/// Parsed import file ready for user review, before any DB writes.
class RecipeImportPreview {
  final List<Map<String, dynamic>> records;

  /// Lower-cased names of records that already exist locally.
  final Set<String> duplicateNames;

  const RecipeImportPreview({
    required this.records,
    required this.duplicateNames,
  });

  bool get hasDuplicates => duplicateNames.isNotEmpty;
}

/// Result of a completed import operation.
class RecipeImportResult {
  final int recipesAdded;
  final int recipesUpdated;
  final int recipesSkipped;
  final int ingredientsAdded;
  final int ingredientsUpdated;
  final int ingredientsSkipped;
  final List<String> errors;
  final List<String> warnings;

  const RecipeImportResult({
    required this.recipesAdded,
    required this.recipesUpdated,
    required this.recipesSkipped,
    required this.ingredientsAdded,
    required this.ingredientsUpdated,
    required this.ingredientsSkipped,
    required this.errors,
    required this.warnings,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;

  int get totalRecipes => recipesAdded + recipesUpdated + recipesSkipped;
}
