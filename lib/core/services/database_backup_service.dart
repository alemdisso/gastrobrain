import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../database/database_helper.dart';
import '../errors/gastrobrain_exceptions.dart';

/// Service for backing up and restoring the complete Gastrobrain database
///
/// Usage:
/// ```dart
/// final backupService = ServiceProvider.database.backup;
///
/// // Create backup
/// final backupPath = await backupService.backupDatabase();
/// print('Backup created: $backupPath');
///
/// // Restore from backup
/// await backupService.restoreDatabase('/path/to/backup.db');
/// ```
///
/// Features:
/// - Complete SQLite database backup
/// - User-selected backup location
/// - Timestamp in backup filename
/// - File validation before restore
/// - Complete database replacement (no merge logic)
/// - Automatic database connection management
class DatabaseBackupService {
  final DatabaseHelper _databaseHelper;

  DatabaseBackupService(this._databaseHelper);

  /// Creates a complete backup of the database
  ///
  /// Opens a file picker for the user to select save location.
  /// The backup file will have a timestamp in the format:
  /// gastrobrain_backup_YYYY-MM-DD_HHMMSS.db
  ///
  /// Returns the path to the created backup file.
  /// Throws [GastrobrainException] if backup fails.
  Future<String> backupDatabase() async {
    try {
      // Get current database path
      final dbPath = await _databaseHelper.getDatabasePath();

      // Generate timestamp for filename
      final timestamp = DateTime.now();
      final formattedDate =
          '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
      final formattedTime =
          '${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}${timestamp.second.toString().padLeft(2, '0')}';
      final backupFilename = 'gastrobrain_backup_${formattedDate}_$formattedTime.db';

      // Get default save directory (Downloads folder)
      Directory? downloadsDir;
      try {
        downloadsDir = await getDownloadsDirectory();
      } catch (e) {
        // If getDownloadsDirectory() fails, fallback to external storage
        downloadsDir = await getExternalStorageDirectory();
      }

      // Open file picker for user to select save location
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Database Backup',
        fileName: backupFilename,
        type: FileType.custom,
        allowedExtensions: ['db'],
        initialDirectory: downloadsDir?.path,
      );

      if (result == null) {
        // User cancelled the picker
        throw const GastrobrainException('Backup cancelled by user');
      }

      final backupPath = result;

      // Close database connection before copying
      await _databaseHelper.closeDatabase();

      // Copy database file to backup location
      final dbFile = File(dbPath);
      await dbFile.copy(backupPath);

      // Reopen database connection
      await _databaseHelper.reopenDatabase();

      return backupPath;
    } catch (e) {
      // Ensure database is reopened even if backup fails
      try {
        await _databaseHelper.reopenDatabase();
      } catch (_) {
        // Ignore errors during recovery
      }

      if (e is GastrobrainException) {
        rethrow;
      }
      throw GastrobrainException('Failed to create backup: ${e.toString()}');
    }
  }

  /// Restores the database from a backup file
  ///
  /// Opens a file picker for the user to select a backup file.
  ///
  /// IMPORTANT: This operation replaces ALL existing data.
  /// The calling code should show a warning dialog before calling this method.
  ///
  /// Returns true if restore was successful.
  /// Throws [GastrobrainException] if restore fails.
  Future<bool> restoreDatabase() async {
    try {
      // Open file picker for user to select backup file
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select Database Backup',
        type: FileType.custom,
        allowedExtensions: ['db'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        // User cancelled the picker
        throw const GastrobrainException('Restore cancelled by user');
      }

      final backupPath = result.files.single.path;
      if (backupPath == null) {
        throw const GastrobrainException('Invalid backup file path');
      }

      // Validate backup file exists
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        throw const GastrobrainException('Backup file does not exist');
      }

      // Basic validation: check if file is a valid SQLite database
      // Try to open it briefly to validate format
      try {
        final testDb = await openDatabase(
          backupPath,
          readOnly: true,
          singleInstance: false,
        );
        await testDb.close();
      } catch (e) {
        throw const GastrobrainException('Invalid database file format');
      }

      // Get current database path
      final dbPath = await _databaseHelper.getDatabasePath();

      // Close current database connection
      await _databaseHelper.closeDatabase();

      try {
        // Delete current database
        final currentDbFile = File(dbPath);
        if (await currentDbFile.exists()) {
          await currentDbFile.delete();
        }

        // Copy backup file to database location
        await backupFile.copy(dbPath);

        // Reopen database connection
        await _databaseHelper.reopenDatabase();

        return true;
      } catch (e) {
        // If restore fails, try to reopen the database
        // (it might still have the old data if delete failed)
        try {
          await _databaseHelper.reopenDatabase();
        } catch (_) {
          // Ignore errors during recovery
        }
        throw GastrobrainException('Failed to restore database: ${e.toString()}');
      }
    } catch (e) {
      // Ensure database is reopened even if restore fails
      try {
        await _databaseHelper.reopenDatabase();
      } catch (_) {
        // Ignore errors during recovery
      }

      if (e is GastrobrainException) {
        rethrow;
      }
      throw GastrobrainException('Failed to restore database: ${e.toString()}');
    }
  }

  /// Gets the current database file size in bytes
  ///
  /// Useful for displaying information to users about backup size.
  Future<int> getDatabaseSize() async {
    try {
      final db = await _databaseHelper.database;
      final dbFile = File(db.path);

      if (await dbFile.exists()) {
        final stat = await dbFile.stat();
        return stat.size;
      }

      return 0;
    } catch (e) {
      throw GastrobrainException('Failed to get database size: ${e.toString()}');
    }
  }

  /// Formats file size in human-readable format (KB, MB)
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      final kb = (bytes / 1024).toStringAsFixed(1);
      return '$kb KB';
    } else {
      final mb = (bytes / (1024 * 1024)).toStringAsFixed(2);
      return '$mb MB';
    }
  }
}
