import 'package:sqflite/sqflite.dart';
import 'migration.dart';

/// Manages and executes database migrations
/// 
/// The MigrationRunner handles:
/// - Tracking which migrations have been applied
/// - Running pending migrations in order
/// - Rolling back failed migrations
/// - Providing progress feedback during migration process
class MigrationRunner {
  final Database _db;
  final List<Migration> _migrations;
  
  /// Callback for migration progress updates
  final void Function(String status, double progress)? onProgress;
  
  /// Callback for individual migration completion
  final void Function(MigrationResult result)? onMigrationComplete;

  MigrationRunner(
    this._db, 
    this._migrations, {
    this.onProgress,
    this.onMigrationComplete,
  }) {
    // Ensure migrations are sorted by version
    _migrations.sort((a, b) => a.version.compareTo(b.version));
    
    // Validate migration versions are sequential and unique
    _validateMigrationSequence();
  }

  /// Initialize the migration system by creating the schema_migrations table
  Future<void> initialize() async {
    await _createMigrationTable();
  }

  /// Check if any migrations need to be run
  Future<bool> needsMigration() async {
    if (_migrations.isEmpty) return false;
    
    final currentVersion = await _getCurrentVersion();
    final latestVersion = _migrations.last.version;
    
    return currentVersion < latestVersion;
  }

  /// Get the current database schema version
  Future<int> getCurrentVersion() async {
    return await _getCurrentVersion();
  }

  /// Get the latest available migration version
  int getLatestVersion() {
    return _migrations.isEmpty ? 0 : _migrations.last.version;
  }

  /// Get list of pending migrations
  Future<List<Migration>> getPendingMigrations() async {
    final currentVersion = await _getCurrentVersion();
    return _migrations.where((m) => m.version > currentVersion).toList();
  }

  /// Get list of applied migrations
  Future<List<Migration>> getAppliedMigrations() async {
    final currentVersion = await _getCurrentVersion();
    return _migrations.where((m) => m.version <= currentVersion).toList();
  }

  /// Run all pending migrations
  Future<List<MigrationResult>> runPendingMigrations() async {
    final pendingMigrations = await getPendingMigrations();
    
    if (pendingMigrations.isEmpty) {
      onProgress?.call('No migrations needed', 1.0);
      return [];
    }

    final results = <MigrationResult>[];
    final totalMigrations = pendingMigrations.length;

    onProgress?.call('Starting migrations...', 0.0);

    for (int i = 0; i < pendingMigrations.length; i++) {
      final migration = pendingMigrations[i];
      final progress = i / totalMigrations;
      
      onProgress?.call('Running migration ${migration.version}: ${migration.description}', progress);
      
      try {
        final result = await _runMigration(migration);
        results.add(result);
        onMigrationComplete?.call(result);
        
        if (!result.success) {
          // Stop on first failure
          throw MigrationException(
            'Migration ${migration.version} failed: ${result.error}',
            version: migration.version,
            operation: 'up',
          );
        }
      } catch (e) {
        final errorResult = MigrationResult.failure(
          migration.version,
          e.toString(),
          Duration.zero,
        );
        results.add(errorResult);
        onMigrationComplete?.call(errorResult);
        rethrow;
      }
    }

    onProgress?.call('All migrations completed successfully', 1.0);
    return results;
  }

  /// Run a specific migration
  Future<MigrationResult> _runMigration(Migration migration) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Run the migration within a transaction for atomicity
      await _db.transaction((txn) async {
        final executor = TransactionWrapper(txn);
        
        // Execute the migration
        await migration.up(executor);
        
        // Validate the migration if validation is provided
        final isValid = await migration.validate(executor);
        if (!isValid) {
          throw MigrationException(
            'Migration validation failed',
            version: migration.version,
            operation: 'validate',
          );
        }
        
        // Record the migration as applied
        await _recordMigration(txn, migration);
      });
      
      stopwatch.stop();
      return MigrationResult.success(migration.version, stopwatch.elapsed);
      
    } catch (e) {
      stopwatch.stop();
      return MigrationResult.failure(
        migration.version,
        e.toString(),
        stopwatch.elapsed,
      );
    }
  }

  /// Rollback to a specific version
  /// 
  /// This will roll back all migrations that are newer than the target version.
  /// Use with caution as this can cause data loss.
  Future<List<MigrationResult>> rollbackToVersion(int targetVersion) async {
    final currentVersion = await _getCurrentVersion();
    
    if (targetVersion >= currentVersion) {
      throw ArgumentError('Target version must be less than current version');
    }

    final migrationsToRollback = _migrations
        .where((m) => m.version > targetVersion && m.version <= currentVersion)
        .toList()
        ..sort((a, b) => b.version.compareTo(a.version)); // Reverse order for rollback

    final results = <MigrationResult>[];
    final totalRollbacks = migrationsToRollback.length;

    onProgress?.call('Starting rollback...', 0.0);

    for (int i = 0; i < migrationsToRollback.length; i++) {
      final migration = migrationsToRollback[i];
      final progress = i / totalRollbacks;
      
      onProgress?.call('Rolling back migration ${migration.version}: ${migration.description}', progress);
      
      try {
        final result = await _rollbackMigration(migration);
        results.add(result);
        onMigrationComplete?.call(result);
        
        if (!result.success) {
          throw MigrationException(
            'Rollback of migration ${migration.version} failed: ${result.error}',
            version: migration.version,
            operation: 'down',
          );
        }
      } catch (e) {
        final errorResult = MigrationResult.failure(
          migration.version,
          e.toString(),
          Duration.zero,
        );
        results.add(errorResult);
        onMigrationComplete?.call(errorResult);
        rethrow;
      }
    }

    onProgress?.call('Rollback completed', 1.0);
    return results;
  }

  /// Rollback a specific migration
  Future<MigrationResult> _rollbackMigration(Migration migration) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      await _db.transaction((txn) async {
        final executor = TransactionWrapper(txn);
        
        // Execute the rollback
        await migration.down(executor);
        
        // Remove the migration record
        await _removeMigrationRecord(txn, migration);
      });
      
      stopwatch.stop();
      return MigrationResult.success(migration.version, stopwatch.elapsed);
      
    } catch (e) {
      stopwatch.stop();
      return MigrationResult.failure(
        migration.version,
        e.toString(),
        stopwatch.elapsed,
      );
    }
  }

  /// Create the schema_migrations table if it doesn't exist
  Future<void> _createMigrationTable() async {
    await _db.execute('''
      CREATE TABLE IF NOT EXISTS schema_migrations (
        version INTEGER PRIMARY KEY,
        applied_at TEXT NOT NULL,
        description TEXT NOT NULL,
        duration_ms INTEGER NOT NULL
      )
    ''');
  }

  /// Get the current schema version from the database
  Future<int> _getCurrentVersion() async {
    try {
      final result = await _db.rawQuery(
        'SELECT MAX(version) as version FROM schema_migrations'
      );
      
      final version = result.first['version'] as int?;
      return version ?? 0;
    } catch (e) {
      // If schema_migrations table doesn't exist, we're at version 0
      return 0;
    }
  }

  /// Record a migration as applied
  Future<void> _recordMigration(Transaction txn, Migration migration) async {
    await txn.insert('schema_migrations', {
      'version': migration.version,
      'applied_at': DateTime.now().toIso8601String(),
      'description': migration.description,
      'duration_ms': migration.estimatedDuration.inMilliseconds,
    });
  }

  /// Remove a migration record (for rollbacks)
  Future<void> _removeMigrationRecord(Transaction txn, Migration migration) async {
    await txn.delete(
      'schema_migrations',
      where: 'version = ?',
      whereArgs: [migration.version],
    );
  }

  /// Validate that migrations have sequential, unique version numbers
  void _validateMigrationSequence() {
    final versions = <int>{};
    
    for (final migration in _migrations) {
      if (migration.version <= 0) {
        throw ArgumentError('Migration version must be positive: ${migration.version}');
      }
      
      if (!versions.add(migration.version)) {
        throw ArgumentError('Duplicate migration version: ${migration.version}');
      }
    }
    
    // Check for gaps in sequence (optional - might be too strict)
    // final sortedVersions = versions.toList()..sort();
    // for (int i = 1; i < sortedVersions.length; i++) {
    //   if (sortedVersions[i] - sortedVersions[i-1] > 1) {
    //     throw ArgumentError('Gap in migration versions between ${sortedVersions[i-1]} and ${sortedVersions[i]}');
    //   }
    // }
  }

  /// Get migration history from the database
  Future<List<Map<String, dynamic>>> getMigrationHistory() async {
    try {
      return await _db.query(
        'schema_migrations',
        orderBy: 'version ASC',
      );
    } catch (e) {
      return [];
    }
  }
}