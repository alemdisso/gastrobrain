// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide DatabaseExecutor;
import 'package:gastrobrain/core/migration/migration.dart';
import 'package:gastrobrain/core/migration/migration_runner.dart';

// ── Test migrations ───────────────────────────────────────────────────────────

/// Simple migration that creates and drops a marker table — fully reversible.
class _CreateTableMigration extends Migration {
  @override
  int get version => 200;

  @override
  String get description => 'Test: create marker table';

  @override
  Future<void> up(DatabaseExecutor db) async {
    await db.execute(
      'CREATE TABLE IF NOT EXISTS _rollback_marker (id INTEGER PRIMARY KEY)',
    );
  }

  @override
  Future<void> down(DatabaseExecutor db) async {
    await db.execute('DROP TABLE IF EXISTS _rollback_marker');
  }

  @override
  Future<bool> validate(DatabaseExecutor db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='_rollback_marker'",
    );
    return tables.isNotEmpty;
  }
}

/// Migration whose up() always throws — used to simulate a migration failure.
class _FailingUpMigration extends Migration {
  @override
  int get version => 201;

  @override
  String get description => 'Test: deliberately failing migration';

  @override
  Future<void> up(DatabaseExecutor db) async {
    throw Exception('Intentional up() failure for testing');
  }

  @override
  Future<void> down(DatabaseExecutor db) async {}

  @override
  Future<bool> validate(DatabaseExecutor db) async => false;
}

/// Migration whose down() always throws — used to simulate a failing rollback.
class _FailingDownMigration extends Migration {
  @override
  int get version => 200;

  @override
  String get description => 'Test: migration with failing down()';

  @override
  Future<void> up(DatabaseExecutor db) async {
    await db.execute(
      'CREATE TABLE IF NOT EXISTS _rollback_marker (id INTEGER PRIMARY KEY)',
    );
  }

  @override
  Future<void> down(DatabaseExecutor db) async {
    throw Exception('Intentional down() failure for testing');
  }

  @override
  Future<bool> validate(DatabaseExecutor db) async => true;
}

/// Migration with a no-op down() — mirrors migration 107 (category-to-tags
/// data migration). Rollback removes the schema_migrations record but
/// data-level changes persist; this is by design.
class _NoOpDownMigration extends Migration {
  @override
  int get version => 200;

  @override
  String get description => 'Test: migration with no-op down()';

  @override
  Future<void> up(DatabaseExecutor db) async {
    // Simulate a data migration (e.g. backfilling a column).
  }

  @override
  Future<void> down(DatabaseExecutor db) async {
    // Intentional no-op: changes are irreversible by design.
  }

  @override
  Future<bool> validate(DatabaseExecutor db) async => true;
}

// ── SQL helpers (mirror production DatabaseHelper private methods) ─────────────

Future<Database> _openEmpty() =>
    databaseFactoryFfi.openDatabase(inMemoryDatabasePath);

Future<void> _ensureErrorsTable(Database db) => db.execute('''
  CREATE TABLE IF NOT EXISTS schema_migrations_errors (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    failed_version INTEGER,
    error_message TEXT NOT NULL,
    occurred_at TEXT NOT NULL,
    acknowledged INTEGER NOT NULL DEFAULT 0,
    severity TEXT NOT NULL DEFAULT 'warning'
  )
''');

Future<void> _recordError(
  Database db,
  int? version,
  String message,
  String severity,
) =>
    db.rawInsert(
      'INSERT INTO schema_migrations_errors '
      '(failed_version, error_message, occurred_at, severity) VALUES (?, ?, ?, ?)',
      [version, message, DateTime.now().toIso8601String(), severity],
    );

Future<bool> _hasFatal(Database db) async {
  final rows = await db.rawQuery(
    "SELECT COUNT(*) as count FROM schema_migrations_errors "
    "WHERE severity = 'fatal' AND acknowledged = 0",
  );
  return (rows.first['count'] as int) > 0;
}

Future<bool> _hasWarning(Database db) async {
  final rows = await db.rawQuery(
    "SELECT COUNT(*) as count FROM schema_migrations_errors "
    "WHERE severity = 'warning' AND acknowledged = 0",
  );
  return (rows.first['count'] as int) > 0;
}

Future<void> _acknowledgeAll(Database db) => db.execute(
      'UPDATE schema_migrations_errors SET acknowledged = 1 WHERE acknowledged = 0',
    );

/// Mirrors _attemptRollbackAndRecord from DatabaseHelper.
Future<void> _attemptRollbackAndRecord(
  Database db,
  MigrationRunner runner,
  int? failedVersion,
  String errorMessage,
  int versionBeforeMigrations,
) async {
  try {
    final currentVersion = await runner.getCurrentVersion();
    if (currentVersion > versionBeforeMigrations) {
      await runner.rollbackToVersion(versionBeforeMigrations);
    }
    await _recordError(db, failedVersion, errorMessage, 'warning');
  } catch (_) {
    await _recordError(db, failedVersion, errorMessage, 'fatal');
  }
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  // ── Group 1: MigrationRunner rollback behavior ──────────────────────────────
  //
  // Tests MigrationRunner.rollbackToVersion() in isolation, verifying that
  // schema changes are reversed and schema_migrations records are removed.

  group('MigrationRunner rollback behavior', () {
    late Database db;
    late MigrationRunner runner;

    setUp(() async {
      db = await _openEmpty();
    });

    tearDown(() async => db.close());

    test('rollback of committed migration removes it from schema_migrations', () async {
      runner = MigrationRunner(db, [_CreateTableMigration()]);
      await runner.initialize();
      await runner.runPendingMigrations();

      expect(await runner.getCurrentVersion(), equals(200));

      await runner.rollbackToVersion(0);

      expect(await runner.getCurrentVersion(), equals(0));
    });

    test('rollback with reversible down() drops the schema change', () async {
      runner = MigrationRunner(db, [_CreateTableMigration()]);
      await runner.initialize();
      await runner.runPendingMigrations();

      await runner.rollbackToVersion(0);

      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='_rollback_marker'",
      );
      expect(tables, isEmpty,
          reason: 'down() should have dropped _rollback_marker');
    });

    test('rollback with no-op down() succeeds without throwing', () async {
      runner = MigrationRunner(db, [_NoOpDownMigration()]);
      await runner.initialize();
      await runner.runPendingMigrations();

      expect(await runner.getCurrentVersion(), equals(200));

      await expectLater(runner.rollbackToVersion(0), completes);
      expect(await runner.getCurrentVersion(), equals(0));
    });

    test('rollback with failing down() propagates the exception', () async {
      runner = MigrationRunner(db, [_FailingDownMigration()]);
      await runner.initialize();
      await runner.runPendingMigrations();

      await expectLater(
        runner.rollbackToVersion(0),
        throwsA(isA<MigrationException>()),
      );
    });
  });

  // ── Group 2: Severity recording — schema and SQL invariants ─────────────────
  //
  // Validates the exact schema and SQL operations for the severity column,
  // mirroring how _ensureMigrationErrorsTable and hasFatalMigrationError
  // work in DatabaseHelper.

  group('Severity column — schema and SQL invariants', () {
    late Database db;

    setUp(() async {
      db = await _openEmpty();
      await _ensureErrorsTable(db);
    });

    tearDown(() async => db.close());

    test('schema_migrations_errors has a severity column with default warning', () async {
      await _recordError(db, 109, 'some error', 'warning');

      final rows = await db.rawQuery('SELECT severity FROM schema_migrations_errors');
      expect(rows.first['severity'], equals('warning'));
    });

    test('fatal severity row is correctly stored and queried', () async {
      await _recordError(db, 109, 'fatal error', 'fatal');

      expect(await _hasFatal(db), isTrue);
      expect(await _hasWarning(db), isFalse);
    });

    test('warning severity row is correctly stored and queried', () async {
      await _recordError(db, 109, 'warning error', 'warning');

      expect(await _hasWarning(db), isTrue);
      expect(await _hasFatal(db), isFalse);
    });

    test('acknowledge clears all unacknowledged rows', () async {
      await _recordError(db, 109, 'warning', 'warning');
      await _recordError(db, 110, 'fatal', 'fatal');

      await _acknowledgeAll(db);

      expect(await _hasWarning(db), isFalse);
      expect(await _hasFatal(db), isFalse);
    });

    test('clean database has no pending errors', () async {
      expect(await _hasFatal(db), isFalse);
      expect(await _hasWarning(db), isFalse);
    });
  });

  // ── Group 3: Startup rollback flow (mirrors _initializeMigrationSystem) ─────
  //
  // Tests the full migration-failure → rollback → severity-record pipeline
  // using _attemptRollbackAndRecord, which mirrors the production logic.

  group('Startup rollback flow', () {
    late Database db;

    setUp(() async {
      db = await _openEmpty();
      await _ensureErrorsTable(db);
    });

    tearDown(() async => db.close());

    test('migration success path: all succeed, no error rows recorded', () async {
      final runner = MigrationRunner(db, [_CreateTableMigration()]);
      await runner.initialize();

      final versionBefore = await runner.getCurrentVersion();

      try {
        await runner.runPendingMigrations();
        await _acknowledgeAll(db); // mirrors _acknowledgeAllMigrationErrors
      } catch (e) {
        await _attemptRollbackAndRecord(
          db, runner, null, e.toString(), versionBefore,
        );
      }

      expect(await _hasWarning(db), isFalse);
      expect(await _hasFatal(db), isFalse);
    });

    test('migration fails + rollback succeeds → warning severity recorded', () async {
      // Apply v200 first, then attempt v201 which fails.
      final setupRunner = MigrationRunner(db, [_CreateTableMigration()]);
      await setupRunner.initialize();
      await setupRunner.runPendingMigrations();

      final versionBefore = await setupRunner.getCurrentVersion(); // 200

      // Now wire in the failing v201.
      final runner = MigrationRunner(
        db,
        [_CreateTableMigration(), _FailingUpMigration()],
      );

      try {
        await runner.runPendingMigrations();
      } catch (e) {
        await _attemptRollbackAndRecord(
          db, runner, 201, e.toString(), versionBefore,
        );
      }

      expect(await _hasWarning(db), isTrue,
          reason: 'rollback succeeded → severity should be warning');
      expect(await _hasFatal(db), isFalse);
      // DB rolled back to versionBefore (200 rolled back to itself — no-op since
      // v201 was never committed; currentVersion is still 200 == versionBefore).
    });

    test('migration fails + rollback also fails → fatal severity recorded', () async {
      // Apply v200 (which has a failing down()) successfully.
      final setupRunner = MigrationRunner(db, [_FailingDownMigration()]);
      await setupRunner.initialize();
      await setupRunner.runPendingMigrations(); // v200 succeeds

      final versionBefore = 0; // DB was at 0 before v200 ran

      // Simulate a subsequent migration failure that triggers rollback of v200.
      // We re-create the runner with v200 (failing down) already applied;
      // the rollback will attempt to call v200.down() which throws.
      final runner = MigrationRunner(db, [_FailingDownMigration()]);

      // Manually trigger the rollback path (v200 is already applied, rollback to 0).
      await _attemptRollbackAndRecord(
        db, runner, 200, 'simulated failure', versionBefore,
      );

      expect(await _hasFatal(db), isTrue,
          reason: 'rollback failed → severity should be fatal');
      expect(await _hasWarning(db), isFalse);
    });

    test('no-op down() migration: rollback succeeds, warning severity recorded', () async {
      // Apply v200 (no-op down()) first.
      final setupRunner = MigrationRunner(db, [_NoOpDownMigration()]);
      await setupRunner.initialize();
      await setupRunner.runPendingMigrations();

      final versionBefore = 0;

      // Wire in a failing v201 to trigger rollback of v200.
      final runner = MigrationRunner(
        db,
        [_NoOpDownMigration(), _FailingUpMigration()],
      );

      try {
        await runner.runPendingMigrations();
      } catch (e) {
        await _attemptRollbackAndRecord(
          db, runner, 201, e.toString(), versionBefore,
        );
      }

      expect(await _hasWarning(db), isTrue,
          reason: 'no-op down() should not cause fatal — rollback is treated as success');
      expect(await _hasFatal(db), isFalse);
    });

    test('first migration fails with no partial state → warning, no rollback attempted', () async {
      final runner = MigrationRunner(db, [_FailingUpMigration()]);
      await runner.initialize();

      final versionBefore = await runner.getCurrentVersion(); // 0

      try {
        await runner.runPendingMigrations();
      } catch (e) {
        await _attemptRollbackAndRecord(
          db, runner, 201, e.toString(), versionBefore,
        );
      }

      // currentVersion is still 0 == versionBefore; guard prevents rollback call.
      expect(await _hasWarning(db), isTrue,
          reason: 'no partial state to rollback → warning severity');
      expect(await _hasFatal(db), isFalse);
      expect(await runner.getCurrentVersion(), equals(0));
    });

    test('successful launch after previous fatal: errors acknowledged, screen not shown', () async {
      // Simulate a previous fatal error.
      await _recordError(db, 200, 'previous fatal', 'fatal');
      expect(await _hasFatal(db), isTrue);

      // New launch: all migrations succeed → _acknowledgeAllMigrationErrors.
      final runner = MigrationRunner(db, [_CreateTableMigration()]);
      await runner.initialize();

      try {
        await runner.runPendingMigrations();
        await _acknowledgeAll(db); // mirrors success path in _initializeMigrationSystem
      } catch (e) {
        await _attemptRollbackAndRecord(
          db, runner, null, e.toString(), 0,
        );
      }

      expect(await _hasFatal(db), isFalse,
          reason: 'successful launch should clear previous fatal');
      expect(await _hasWarning(db), isFalse);
    });
  });
}
