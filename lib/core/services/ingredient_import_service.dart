import 'dart:convert';
import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import '../../database/database_helper.dart';
import '../errors/gastrobrain_exceptions.dart';
import 'ingredient_export_service.dart';
import 'recipe_import_service.dart' show DuplicateStrategy;

export 'recipe_import_service.dart' show DuplicateStrategy;

/// Service for importing ingredient data from a Gastrobrain JSON export file.
///
/// Usage (two-phase):
/// ```dart
/// final preview = await service.previewImport(bytes);
/// // show strategy dialog if preview.duplicateNames.isNotEmpty
/// final result = await service.executeImport(preview, strategy);
/// ```
class IngredientImportService {
  final DatabaseHelper _databaseHelper;

  IngredientImportService(this._databaseHelper);

  /// Parse and validate [bytes] without writing to the database.
  ///
  /// Returns an [IngredientImportPreview] containing the parsed records and the
  /// set of ingredient names that already exist locally.
  /// Throws [GastrobrainException] if the file is malformed.
  Future<IngredientImportPreview> previewImport(Uint8List bytes) async {
    final List<dynamic> jsonData;
    try {
      jsonData = json.decode(utf8.decode(bytes)) as List<dynamic>;
    } catch (e) {
      throw const GastrobrainException('Invalid JSON: could not parse file.');
    }

    if (!IngredientExportService.validateExportStructure(jsonData)) {
      throw const GastrobrainException(
          'Invalid format: file does not match the ingredient export structure.');
    }

    if (jsonData.isEmpty) {
      return const IngredientImportPreview(records: [], duplicateNames: {});
    }

    final records = jsonData.cast<Map<String, dynamic>>();

    // Detect duplicates by name (case-insensitive) against local DB.
    final existingIngredients = await _databaseHelper.getAllIngredients();
    final existingNamesLower =
        existingIngredients.map((i) => i.name.toLowerCase().trim()).toSet();

    final duplicateNames = <String>{};
    for (final record in records) {
      final name = (record['name'] as String).toLowerCase().trim();
      if (existingNamesLower.contains(name)) {
        duplicateNames.add(name);
      }
    }

    return IngredientImportPreview(
        records: records, duplicateNames: duplicateNames);
  }

  /// Execute the import using [strategy] for any duplicates found in [preview].
  ///
  /// All writes occur in a single transaction — any unhandled error rolls back
  /// the entire import.
  Future<IngredientImportResult> executeImport(
    IngredientImportPreview preview,
    DuplicateStrategy strategy,
  ) async {
    if (preview.records.isEmpty) {
      return const IngredientImportResult(
        added: 0,
        updated: 0,
        skipped: 0,
        errors: [],
        warnings: [],
      );
    }

    final errors = <String>[];
    final warnings = <String>[];
    int added = 0;
    int updated = 0;
    int skipped = 0;

    final db = await _databaseHelper.database;

    await db.transaction((txn) async {
      for (final record in preview.records) {
        final importedName = (record['name'] as String).trim();
        final isDuplicate =
            preview.duplicateNames.contains(importedName.toLowerCase());

        if (isDuplicate) {
          switch (strategy) {
            case DuplicateStrategy.skip:
              skipped++;
              continue;
            case DuplicateStrategy.replace:
              await _replaceIngredient(record, txn);
              updated++;
            case DuplicateStrategy.addAsNew:
              final modified = Map<String, dynamic>.from(record);
              modified['name'] = '$importedName (imported)';
              await _insertIngredient(modified, txn);
              added++;
          }
        } else {
          try {
            await _insertIngredient(record, txn);
            added++;
          } catch (e) {
            errors.add('Failed to import ingredient "$importedName": $e');
          }
        }
      }
    });

    return IngredientImportResult(
      added: added,
      updated: updated,
      skipped: skipped,
      errors: errors,
      warnings: warnings,
    );
  }

  // ── private helpers ───────────────────────────────────────────────────────

  Future<void> _insertIngredient(
      Map<String, dynamic> record, Transaction txn) async {
    await txn.insert(
      'ingredients',
      {
        'id': record['ingredient_id'] as String,
        'name': (record['name'] as String).trim(),
        'category': record['category'],
        'unit': record['unit'],
        'protein_type': record['protein_type'],
        'notes': record['notes'],
      },
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
  }

  Future<void> _replaceIngredient(
      Map<String, dynamic> record, Transaction txn) async {
    final importedName = (record['name'] as String).trim();

    final existing = await txn.rawQuery(
      'SELECT id FROM ingredients WHERE LOWER(name) = LOWER(?)',
      [importedName],
    );
    if (existing.isNotEmpty) {
      final existingId = existing.first['id'] as String;
      await txn.update(
        'ingredients',
        {
          'name': importedName,
          'category': record['category'],
          'unit': record['unit'],
          'protein_type': record['protein_type'],
          'notes': record['notes'],
        },
        where: 'id = ?',
        whereArgs: [existingId],
      );
    }
  }
}

// ── Data classes ─────────────────────────────────────────────────────────────

/// Parsed import file ready for user review, before any DB writes.
class IngredientImportPreview {
  final List<Map<String, dynamic>> records;

  /// Lower-cased names of records that already exist locally.
  final Set<String> duplicateNames;

  const IngredientImportPreview({
    required this.records,
    required this.duplicateNames,
  });

  bool get hasDuplicates => duplicateNames.isNotEmpty;
}

/// Result of a completed ingredient import operation.
class IngredientImportResult {
  final int added;
  final int updated;
  final int skipped;
  final List<String> errors;
  final List<String> warnings;

  const IngredientImportResult({
    required this.added,
    required this.updated,
    required this.skipped,
    required this.errors,
    required this.warnings,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;

  int get total => added + updated + skipped;
}
