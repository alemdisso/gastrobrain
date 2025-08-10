import 'package:sqflite/sqflite.dart';

/// Interface for database operations that works with both Database and Transaction
abstract class DatabaseExecutor {
  Future<void> execute(String sql, [List<Object?>? arguments]);
  Future<List<Map<String, Object?>>> query(String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  });
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]);
  Future<int> insert(String table, Map<String, Object?> values);
  Future<int> update(String table, Map<String, Object?> values, {String? where, List<Object?>? whereArgs});
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs});
}

/// Wrapper to make Database implement our DatabaseExecutor interface
class DatabaseWrapper implements DatabaseExecutor {
  final Database _db;
  DatabaseWrapper(this._db);

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) => _db.execute(sql, arguments);

  @override
  Future<List<Map<String, Object?>>> query(String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) => _db.query(table, distinct: distinct, columns: columns, where: where, 
      whereArgs: whereArgs, groupBy: groupBy, having: having, orderBy: orderBy, 
      limit: limit, offset: offset);

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]) => 
      _db.rawQuery(sql, arguments);

  @override
  Future<int> insert(String table, Map<String, Object?> values) => _db.insert(table, values);

  @override
  Future<int> update(String table, Map<String, Object?> values, {String? where, List<Object?>? whereArgs}) => 
      _db.update(table, values, where: where, whereArgs: whereArgs);

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) => 
      _db.delete(table, where: where, whereArgs: whereArgs);
}

/// Wrapper to make Transaction implement our DatabaseExecutor interface  
class TransactionWrapper implements DatabaseExecutor {
  final Transaction _txn;
  TransactionWrapper(this._txn);

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) => _txn.execute(sql, arguments);

  @override
  Future<List<Map<String, Object?>>> query(String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) => _txn.query(table, distinct: distinct, columns: columns, where: where, 
      whereArgs: whereArgs, groupBy: groupBy, having: having, orderBy: orderBy, 
      limit: limit, offset: offset);

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]) => 
      _txn.rawQuery(sql, arguments);

  @override
  Future<int> insert(String table, Map<String, Object?> values) => _txn.insert(table, values);

  @override
  Future<int> update(String table, Map<String, Object?> values, {String? where, List<Object?>? whereArgs}) => 
      _txn.update(table, values, where: where, whereArgs: whereArgs);

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) => 
      _txn.delete(table, where: where, whereArgs: whereArgs);
}

/// Abstract base class for database migrations
/// 
/// Each migration represents a single schema change that can be applied
/// (up) or rolled back (down). Migrations are identified by a unique version
/// number and should be applied in sequential order.
abstract class Migration {
  /// Unique version number for this migration
  /// Must be sequential and never reused
  int get version;

  /// Human-readable description of what this migration does
  /// Used for logging and user feedback during migration process
  String get description;

  /// Apply the migration (schema upgrade)
  /// 
  /// This method contains the forward migration logic, such as:
  /// - Creating new tables
  /// - Adding columns
  /// - Creating indexes
  /// - Data transformation
  /// 
  /// Should be idempotent - safe to run multiple times
  Future<void> up(DatabaseExecutor db);

  /// Rollback the migration (schema downgrade)
  /// 
  /// This method contains the reverse migration logic to undo
  /// the changes made by the up() method:
  /// - Dropping tables
  /// - Removing columns (where possible)
  /// - Dropping indexes
  /// - Reversing data transformation
  /// 
  /// Should be idempotent - safe to run multiple times
  Future<void> down(DatabaseExecutor db);

  /// Validate that the migration was applied correctly
  /// 
  /// Optional method that can be overridden to add custom validation
  /// after the migration is applied. Useful for verifying data integrity
  /// or ensuring expected schema changes were made.
  Future<bool> validate(DatabaseExecutor db) async {
    return true; // Default: assume migration is valid
  }

  /// Get the estimated time this migration might take
  /// 
  /// Used for user feedback and progress estimation.
  /// Override for migrations that might take significant time.
  Duration get estimatedDuration => const Duration(seconds: 1);

  /// Whether this migration requires user data backup before running
  /// 
  /// Set to true for migrations that modify existing data or could
  /// potentially cause data loss if they fail.
  bool get requiresBackup => true;

  @override
  String toString() => 'Migration $version: $description';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Migration && runtimeType == other.runtimeType && version == other.version;

  @override
  int get hashCode => version.hashCode;
}

/// Result of a migration operation
class MigrationResult {
  final bool success;
  final String? error;
  final Duration duration;
  final int version;

  const MigrationResult.success(this.version, this.duration)
      : success = true,
        error = null;

  const MigrationResult.failure(this.version, this.error, this.duration)
      : success = false;

  @override
  String toString() {
    if (success) {
      return 'Migration $version completed successfully in ${duration.inMilliseconds}ms';
    } else {
      return 'Migration $version failed: $error (after ${duration.inMilliseconds}ms)';
    }
  }
}

/// Exception thrown when migration operations fail
class MigrationException implements Exception {
  final String message;
  final int? version;
  final String? operation; // 'up', 'down', 'validate'

  const MigrationException(this.message, {this.version, this.operation});

  @override
  String toString() {
    if (version != null && operation != null) {
      return 'MigrationException: $message (Migration $version, operation: $operation)';
    } else if (version != null) {
      return 'MigrationException: $message (Migration $version)';
    }
    return 'MigrationException: $message';
  }
}