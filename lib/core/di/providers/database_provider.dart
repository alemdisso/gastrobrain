import 'package:gastrobrain/database/database_helper.dart';

/// Provides database access throughout the application
class DatabaseProvider {
  // Singleton instance
  static final DatabaseProvider _instance = DatabaseProvider._internal();

  factory DatabaseProvider() => _instance;

  DatabaseProvider._internal();

  // Lazy initialization of the database helper
  DatabaseHelper? _dbHelper;

  DatabaseHelper get dbHelper {
    _dbHelper ??= DatabaseHelper();
    return _dbHelper!;
  }

  // For testing: allows injection of a mock database
  void setDatabaseHelper(DatabaseHelper helper) {
    _dbHelper = helper;
  }
}
