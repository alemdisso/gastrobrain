import 'package:gastrobrain/database/database_helper.dart';
import 'package:gastrobrain/core/services/database_backup_service.dart';

/// Provides database access throughout the application
class DatabaseProvider {
  // Singleton instance
  static final DatabaseProvider _instance = DatabaseProvider._internal();

  factory DatabaseProvider() => _instance;

  DatabaseProvider._internal();

  // Lazy initialization of the database helper
  DatabaseHelper? _dbHelper;
  DatabaseBackupService? _backupService;

  DatabaseHelper get helper {
    _dbHelper ??= DatabaseHelper();
    return _dbHelper!;
  }

  // Backward compatibility
  DatabaseHelper get dbHelper => helper;

  DatabaseBackupService get backup {
    _backupService ??= DatabaseBackupService(helper);
    return _backupService!;
  }

  // For testing: allows injection of a mock database
  void setDatabaseHelper(DatabaseHelper helper) {
    _dbHelper = helper;
    _backupService = null; // Reset backup service when helper changes
  }
}
