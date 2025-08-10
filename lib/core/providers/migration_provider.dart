import 'package:flutter/foundation.dart';
import '../migration/migration.dart';
import '../errors/gastrobrain_exceptions.dart';
import '../di/service_provider.dart';

/// Provider for managing database migration state and UI feedback
/// 
/// This provider handles:
/// - Migration progress tracking
/// - User feedback during migrations
/// - Error handling and recovery
/// - UI state management for migration screens
class MigrationProvider extends ChangeNotifier {
  // Dependencies
  final _dbHelper = ServiceProvider.database.dbHelper;

  // Migration state
  bool _isMigrating = false;
  bool _needsMigration = false;
  String _currentStatus = '';
  double _progress = 0.0;
  List<MigrationResult> _migrationResults = [];
  GastrobrainException? _error;
  
  // Migration history
  List<Map<String, dynamic>> _migrationHistory = [];

  /// Whether a migration is currently in progress
  bool get isMigrating => _isMigrating;

  /// Whether the database needs migration
  bool get needsMigration => _needsMigration;

  /// Current migration status message
  String get currentStatus => _currentStatus;

  /// Migration progress (0.0 to 1.0)
  double get progress => _progress;

  /// Results from the last migration run
  List<MigrationResult> get migrationResults => List.unmodifiable(_migrationResults);

  /// Any error that occurred during migration
  GastrobrainException? get error => _error;

  /// Migration history from database
  List<Map<String, dynamic>> get migrationHistory => List.unmodifiable(_migrationHistory);

  /// Current database version
  int get currentVersion => _dbHelper.getCurrentVersion() as int? ?? 0;

  /// Latest available migration version
  int get latestVersion => _dbHelper.getLatestVersion();

  /// Whether the last migration had any failures
  bool get hasFailures => _migrationResults.any((r) => !r.success);

  /// Whether the last migration was completely successful
  bool get wasSuccessful => _migrationResults.isNotEmpty && _migrationResults.every((r) => r.success);

  /// Initialize the provider by checking migration status
  Future<void> initialize() async {
    try {
      _error = null;
      await _checkMigrationStatus();
      await _loadMigrationHistory();
      notifyListeners();
    } catch (e) {
      _error = e is GastrobrainException 
          ? e 
          : GastrobrainException('Failed to initialize migration provider: ${e.toString()}');
      notifyListeners();
    }
  }

  /// Check if database needs migration
  Future<void> _checkMigrationStatus() async {
    _needsMigration = await _dbHelper.needsMigration();
  }

  /// Load migration history from database
  Future<void> _loadMigrationHistory() async {
    _migrationHistory = await _dbHelper.getMigrationHistory();
  }

  /// Run pending migrations with UI feedback
  Future<bool> runMigrations() async {
    if (_isMigrating) {
      throw const GastrobrainException('Migration already in progress');
    }

    _isMigrating = true;
    _error = null;
    _migrationResults.clear();
    _currentStatus = 'Preparing migration...';
    _progress = 0.0;
    notifyListeners();

    try {
      final results = await _dbHelper.runPendingMigrations(
        onProgress: _onMigrationProgress,
        onMigrationComplete: _onMigrationComplete,
      );

      _migrationResults = results;
      
      if (results.isEmpty) {
        _currentStatus = 'No migrations needed';
        _progress = 1.0;
      } else if (results.every((r) => r.success)) {
        _currentStatus = 'All migrations completed successfully';
        _progress = 1.0;
        await _checkMigrationStatus(); // Update needsMigration flag
        await _loadMigrationHistory(); // Refresh history
      } else {
        final failedCount = results.where((r) => !r.success).length;
        _currentStatus = 'Migration failed: $failedCount migration(s) failed';
        _error = GastrobrainException('$failedCount migration(s) failed');
      }

      return results.isEmpty || results.every((r) => r.success);

    } catch (e) {
      _error = e is GastrobrainException 
          ? e 
          : GastrobrainException('Migration failed: ${e.toString()}');
      _currentStatus = 'Migration failed: ${_error!.message}';
      return false;
    } finally {
      _isMigrating = false;
      notifyListeners();
    }
  }

  /// Rollback to a specific version (USE WITH CAUTION)
  Future<bool> rollbackToVersion(int targetVersion) async {
    if (_isMigrating) {
      throw const GastrobrainException('Migration already in progress');
    }

    if (targetVersion >= currentVersion) {
      throw GastrobrainException('Target version must be less than current version ($currentVersion)');
    }

    _isMigrating = true;
    _error = null;
    _migrationResults.clear();
    _currentStatus = 'Preparing rollback to version $targetVersion...';
    _progress = 0.0;
    notifyListeners();

    try {
      final results = await _dbHelper.rollbackToVersion(
        targetVersion,
        onProgress: _onMigrationProgress,
        onMigrationComplete: _onMigrationComplete,
      );

      _migrationResults = results;
      
      if (results.every((r) => r.success)) {
        _currentStatus = 'Rollback to version $targetVersion completed successfully';
        _progress = 1.0;
        await _checkMigrationStatus();
        await _loadMigrationHistory();
      } else {
        final failedCount = results.where((r) => !r.success).length;
        _currentStatus = 'Rollback failed: $failedCount rollback(s) failed';
        _error = GastrobrainException('$failedCount rollback(s) failed');
      }

      return results.every((r) => r.success);

    } catch (e) {
      _error = e is GastrobrainException 
          ? e 
          : GastrobrainException('Rollback failed: ${e.toString()}');
      _currentStatus = 'Rollback failed: ${_error!.message}';
      return false;
    } finally {
      _isMigrating = false;
      notifyListeners();
    }
  }

  /// Handle migration progress updates
  void _onMigrationProgress(String status, double progress) {
    _currentStatus = status;
    _progress = progress;
    notifyListeners();
  }

  /// Handle individual migration completion
  void _onMigrationComplete(MigrationResult result) {
    // Update the results list if we want to show real-time updates
    if (!_migrationResults.any((r) => r.version == result.version)) {
      _migrationResults.add(result);
    }
    notifyListeners();
  }

  /// Clear any error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Reset migration state (for testing or after errors)
  void reset() {
    _isMigrating = false;
    _needsMigration = false;
    _currentStatus = '';
    _progress = 0.0;
    _migrationResults.clear();
    _error = null;
    _migrationHistory.clear();
    notifyListeners();
  }

  /// Refresh migration status and history
  Future<void> refresh() async {
    if (_isMigrating) return; // Don't refresh during migration
    
    try {
      _error = null;
      await _checkMigrationStatus();
      await _loadMigrationHistory();
      notifyListeners();
    } catch (e) {
      _error = e is GastrobrainException 
          ? e 
          : GastrobrainException('Failed to refresh migration status: ${e.toString()}');
      notifyListeners();
    }
  }

  /// Get human-readable status for migration results
  String getResultSummary() {
    if (_migrationResults.isEmpty) return 'No migrations run';
    
    final successful = _migrationResults.where((r) => r.success).length;
    final failed = _migrationResults.length - successful;
    
    if (failed == 0) {
      return '$successful migration(s) completed successfully';
    } else {
      return '$successful successful, $failed failed';
    }
  }

  /// Get detailed migration results for debugging
  List<String> getDetailedResults() {
    return _migrationResults.map((result) {
      if (result.success) {
        return '✓ Migration ${result.version} completed in ${result.duration.inMilliseconds}ms';
      } else {
        return '✗ Migration ${result.version} failed: ${result.error}';
      }
    }).toList();
  }

  /// Check if there are any pending migrations without running them
  Future<List<Map<String, dynamic>>> getPendingMigrations() async {
    try {
      final currentVersion = await _dbHelper.getCurrentVersion();
      final latestVersion = _dbHelper.getLatestVersion();
      
      // This is a simplified version - in practice, you'd want to get the actual
      // migration objects and return their metadata
      final pending = <Map<String, dynamic>>[];
      
      for (int version = currentVersion + 1; version <= latestVersion; version++) {
        pending.add({
          'version': version,
          'description': 'Migration version $version',
          'estimated_duration': '~1-2 seconds',
        });
      }
      
      return pending;
    } catch (e) {
      return [];
    }
  }
}