# Migration Checkpoint Template

This template shows the exact format for each checkpoint in the database migration workflow.

## Initial Context and Plan

```
Database Migration for Issue #[NUMBER]

Branch detected: feature/[NUMBER]-[description]
Roadmap: docs/planning/0.1.X/ISSUE-[NUMBER]-ROADMAP.md

Phase 2 (Database) Analysis:
[1-2 sentences summarizing database changes needed]

Current Database State:
- Latest migration: v[N] (migration_v[N].dart)
- New migration version: v[N+1]
- Impacted tables: [list of tables]
- Impacted models: [list of models]

Schema Changes Summary:
[Detailed description of schema changes]
- [Change 1: Add column X to table Y]
- [Change 2: ...]

Backward Compatibility Analysis:
- [Analysis of impact on existing data]
- Strategy: [nullable columns / defaults / data migration]

Migration Checkpoint Plan:

Checkpoint 1: Migration File Creation
├─ Create migration_v[N+1].dart
├─ Extend Migration base class
└─ Add empty up() and down() methods

Checkpoint 2: Schema Changes (up method)
├─ Implement SQL for schema changes
├─ Add IF NOT EXISTS patterns
└─ Verify schema applies correctly

Checkpoint 3: Rollback Implementation (down method) ⚠️ CRITICAL
├─ Implement SQL to revert changes
├─ Test rollback works
└─ Verify up → down → up cycle

Checkpoint 4: Model Class Updates
├─ Add/modify fields
├─ Update toMap() method
├─ Update fromMap() method
└─ Update copyWith() if exists

Checkpoint 5: Seed Data Updates (if needed)
├─ Update seed data for new fields
└─ Verify seed data loads correctly

Checkpoint 6: Migration Tests ⚠️ MANDATORY
├─ Test migration up
├─ Test migration down
├─ Test data preservation
└─ Test up → down → up cycle

Total: 6 checkpoints
Estimated skippable: [0-2] (typically Checkpoint 5 if seed data doesn't need updates)

This will follow checkpoint-based protocol:
- Implement ONE checkpoint
- Verify database state
- Wait for your confirmation
- Proceed to NEXT checkpoint
- Repeat

Ready to start CHECKPOINT 1/6? (y/n)
```

---

## Checkpoint 1: Migration File Creation

```
==================
CHECKPOINT 1/6: Migration File Creation
Goal: Create migration file skeleton with proper version and structure

Creating migration file for version [N+1] to:
[Brief description of what migration will do]

Tasks for this checkpoint:
- [ ] Create file: lib/core/database/migrations/migration_v[N+1].dart
- [ ] Import necessary packages (sqflite, Migration base class)
- [ ] Extend Migration base class
- [ ] Set version property to [N+1]
- [ ] Add empty up() method stub
- [ ] Add empty down() method stub
- [ ] Add class documentation

Migration file structure:
```dart
import 'package:sqflite/sqflite.dart';
import 'migration.dart';

/// Migration v[N+1]: [Description of changes]
///
/// Changes:
/// - [Change 1]
/// - [Change 2]
class MigrationV[N+1] extends Migration {
  @override
  int get version => [N+1];

  @override
  Future<void> up(Database db) async {
    // Schema changes will be implemented in Checkpoint 2
  }

  @override
  Future<void> down(Database db) async {
    // Rollback will be implemented in Checkpoint 3
  }
}
```

✓ Migration file created

Files created:
- lib/core/database/migrations/migration_v[N+1].dart

Verification Steps:

1. File exists in correct location:
   ```bash
   ls lib/core/database/migrations/migration_v[N+1].dart
   ```

2. File compiles without errors:
   ```bash
   flutter analyze lib/core/database/migrations/migration_v[N+1].dart
   ```

3. Version number is correct ([N+1])
4. Both up() and down() methods present (empty is OK)
5. Extends Migration base class correctly

Expected output:
- No analysis errors
- File compiles successfully
- Ready for implementation

Database State After Checkpoint 1:
- Migration file exists but not yet registered
- No schema changes applied yet
- Database remains in previous state
- Ready for schema implementation

✅ Checkpoint 1 verification complete?
Ready to proceed to CHECKPOINT 2/6? (y/n)

[STOP - WAIT for user response]
```

---

## Checkpoint 2: Schema Changes (up method)

```
==================
CHECKPOINT 2/6: Schema Changes Implementation
Goal: Implement up() method to apply schema changes

Progress from previous checkpoints:
✓ Checkpoint 1: Migration file created (v[N+1])

Implementing schema changes:
[Detailed description of what SQL will do]

Tasks for this checkpoint:
- [ ] Implement up() method with SQL statements
- [ ] Use IF NOT EXISTS for create operations
- [ ] Use proper SQLite syntax
- [ ] Add transaction handling if needed
- [ ] Ensure backward compatibility (nullable columns)
- [ ] Add comments explaining changes

Schema implementation:
```dart
@override
Future<void> up(Database db) async {
  [COMPLETE SQL IMPLEMENTATION]

  // Example for adding column:
  await db.execute('''
    ALTER TABLE table_name
    ADD COLUMN column_name TYPE NULL
  ''');

  // Example for creating table:
  await db.execute('''
    CREATE TABLE IF NOT EXISTS table_name (
      id TEXT PRIMARY KEY,
      field1 TEXT NOT NULL,
      field2 INTEGER NULL,
      created_at TEXT NOT NULL
    )
  ''');

  // Example for adding index:
  await db.execute('''
    CREATE INDEX IF NOT EXISTS idx_table_field
    ON table_name(field_name)
  ''');
}
```

✓ Schema changes implemented

Files modified:
- lib/core/database/migrations/migration_v[N+1].dart (up method)

Verification Steps:

1. Code compiles:
   ```bash
   flutter analyze lib/core/database/migrations/migration_v[N+1].dart
   ```

2. SQL syntax is valid:
   - Proper SQLite syntax ✓
   - IF NOT EXISTS used where appropriate ✓
   - Correct column types ✓

3. Backward compatibility check:
   - New columns are nullable OR have defaults ✓
   - Existing data won't be affected ✓

4. Apply migration (if MigrationRunner integrated):
   ```bash
   flutter run
   # OR
   flutter test test/core/database/migrations/migration_v[N+1]_test.dart --name "up"
   ```

5. Verify schema changes (after running):
   ```bash
   sqlite3 path/to/gastrobrain.db ".schema table_name"
   ```

   Expected:
   - [New column/table/index should appear in schema]

6. Test existing data (if applicable):
   - Query existing records: Should still work ✓
   - No data loss ✓

Database State After Checkpoint 2:
- Schema changes applied (if tested)
- [New column: table_name.column_name (TYPE, NULL)]
- [OR: New table: table_name created]
- [OR: New index: idx_name created]
- Existing data preserved
- Database version: [N+1]

⚠️ If verification finds issues, debug before proceeding!

✅ Checkpoint 2 verification complete?
Ready to proceed to CHECKPOINT 3/6? (y/n)

[STOP - WAIT for user response]
```

---

## Checkpoint 3: Rollback Implementation (CRITICAL)

```
==================
CHECKPOINT 3/6: Rollback Implementation
Goal: Implement down() method and verify complete rollback works

⚠️ CRITICAL CHECKPOINT - ROLLBACK SAFETY VERIFICATION

Progress from previous checkpoints:
✓ Checkpoint 1: Migration file created (v[N+1])
✓ Checkpoint 2: Schema changes implemented (up method works)

Implementing rollback:
[Description of how to revert the schema changes]

Tasks for this checkpoint:
- [ ] Implement down() method with SQL to revert ALL changes from up()
- [ ] Use IF EXISTS for drop operations
- [ ] Ensure complete reversion (no partial rollback)
- [ ] Test rollback doesn't break app
- [ ] Verify up → down → up cycle

Rollback implementation:
```dart
@override
Future<void> down(Database db) async {
  [COMPLETE ROLLBACK SQL]

  // Example for removing column:
  await db.execute('''
    ALTER TABLE table_name
    DROP COLUMN column_name
  ''');

  // Example for dropping table:
  await db.execute('''
    DROP TABLE IF EXISTS table_name
  ''');

  // Example for dropping index:
  await db.execute('''
    DROP INDEX IF EXISTS idx_table_field
  ''');
}
```

✓ Rollback implementation complete

Files modified:
- lib/core/database/migrations/migration_v[N+1].dart (down method)

Verification Steps - MANDATORY COMPLETE TESTING:

**Step 1: Apply migration (up)**
```bash
flutter run
# OR run test
flutter test test/core/database/migrations/migration_v[N+1]_test.dart --name "applies"
```

**Step 2: Verify schema changes exist**
```bash
sqlite3 path/to/gastrobrain.db ".schema table_name"
```
Expected: [Column/table/index should be present]
✓ Schema change present

**Step 3: Test app works with migration**
- Open app
- Navigate to features using the table
- Verify no crashes
✓ App functional after up

**Step 4: Rollback migration (down)**
```bash
# Run test that calls down()
flutter test test/core/database/migrations/migration_v[N+1]_test.dart --name "rollback"
```

**Step 5: Verify schema changes removed**
```bash
sqlite3 path/to/gastrobrain.db ".schema table_name"
```
Expected: [Column/table/index should be GONE]
✓ Schema change removed

**Step 6: Test app works after rollback**
- Open app
- Navigate to features
- Verify no crashes
✓ App functional after down

**Step 7: Re-apply migration (up again)**
```bash
flutter run
```

**Step 8: Verify schema changes exist again**
```bash
sqlite3 path/to/gastrobrain.db ".schema table_name"
```
Expected: [Column/table/index should be present again]
✓ Schema change present again

**Step 9: Final app test**
- App works correctly
✓ Full up → down → up cycle successful

Database State After Checkpoint 3:
- up() applies schema changes correctly ✓
- down() completely reverts schema changes ✓
- up → down → up cycle works flawlessly ✓
- No orphaned data or broken constraints ✓
- App remains functional at all stages ✓
- Rollback is SAFE ✓

⚠️ CRITICAL: If ANY step fails, DO NOT PROCEED to Checkpoint 4!
Debug and fix rollback issues before continuing.

Common rollback issues:
1. down() doesn't remove all changes from up()
2. Column/table/index still exists after down()
3. App crashes after down() (missing column error)
4. up() fails after down() (constraint conflict)

If you see any of these, let me know and we'll fix them.

✅ ALL rollback verification steps passed?
Ready to proceed to CHECKPOINT 4/6? (y/n)

[STOP - WAIT for user response]
```

---

## Checkpoint 4: Model Class Updates

```
==================
CHECKPOINT 4/6: Model Class Updates
Goal: Update Dart model to match new database schema exactly

Progress from previous checkpoints:
✓ Checkpoint 1: Migration file created (v[N+1])
✓ Checkpoint 2: Schema changes (up) implemented and verified
✓ Checkpoint 3: Rollback (down) implemented and verified

Updating model: [ModelName]
File: lib/core/models/[model_name].dart

Changes needed:
[Description of model changes to match schema]

Tasks for this checkpoint:
- [ ] Add/modify field in model class
- [ ] Ensure field type matches schema type exactly
- [ ] Match nullability (nullable schema = nullable field)
- [ ] Update toMap() method
- [ ] Update fromMap() method
- [ ] Update copyWith() method (if exists)
- [ ] Update constructor
- [ ] Add documentation for new field

Model updates:
```dart
class [ModelName] {
  final String id;
  final String? newField; // Match schema nullability

  [ModelName]({
    required this.id,
    this.newField, // Optional if nullable
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'new_field': newField, // Match schema column name
    };
  }

  factory [ModelName].fromMap(Map<String, dynamic> map) {
    return [ModelName](
      id: map['id'] as String,
      newField: map['new_field'] as String?, // Match nullability
    );
  }

  [ModelName] copyWith({
    String? id,
    String? newField,
  }) {
    return [ModelName](
      id: id ?? this.id,
      newField: newField ?? this.newField,
    );
  }
}
```

✓ Model updated

Files modified:
- lib/core/models/[model_name].dart

Verification Steps:

**1. Code compiles:**
```bash
flutter analyze lib/core/models/[model_name].dart
```
Expected: No errors
✓ Compiles successfully

**2. Type matching:**
- Schema column type: [SQLite type]
- Model field type: [Dart type]
- Match: [verify mapping is correct]
✓ Types match

**3. Nullability matching:**
- Schema column: [NULL or NOT NULL]
- Model field: [nullable? or not]
- Match: [verify nullability matches]
✓ Nullability matches

**4. Column name matching:**
- Schema column: [snake_case_name]
- toMap() key: [snake_case_name]
- fromMap() key: [snake_case_name]
✓ Column names match

**5. Test model operations:**
```bash
flutter test test/core/models/[model_name]_test.dart
```
Expected: All model tests pass
✓ Model tests pass

**6. Test with database:**
Create simple integration test or run app:
- Create record with new field
- Query record (verify fromMap works)
- Update record (verify toMap works)
- Verify new field value persists
✓ CRUD operations work

**7. Test backward compatibility:**
- Query existing records (created before migration)
- Verify they load without errors
- New field should be null for old records
✓ Existing data works

Database/Model State After Checkpoint 4:
- Model field matches schema column exactly
- toMap() serializes new field correctly
- fromMap() deserializes new field correctly
- copyWith() handles new field (if exists)
- CRUD operations work with new field
- Existing records load correctly
- Model is in sync with schema

✅ Checkpoint 4 verification complete?
Ready to proceed to CHECKPOINT 5/6? (y/n)

[STOP - WAIT for user response]
```

---

## Checkpoint 5: Seed Data Updates (Conditional)

### Option A: Seed Data Needs Updates

```
==================
CHECKPOINT 5/6: Seed Data Updates
Goal: Update seed data to include values for new field

Progress from previous checkpoints:
✓ Checkpoint 1: Migration file created
✓ Checkpoint 2: Schema changes (up)
✓ Checkpoint 3: Rollback verified (down)
✓ Checkpoint 4: Model updated

Analysis: Should seed data be updated?

Question: Do seed data records need values for new field?

Checking requirements:
- [Reasoning about whether seed data needs updates]
- New field: [field_name]
- Default value appropriate?: [yes/no]
- Should seed records have explicit values?: [yes/no]

Decision: UPDATE seed data

Reason: [Why seed data needs updating]

Tasks for this checkpoint:
- [ ] Open lib/core/database/seed_data.dart
- [ ] Locate seed records for [table]
- [ ] Add values for new field
- [ ] Ensure values are appropriate for seed data
- [ ] Verify seed data structure matches model

Seed data updates:
```dart
// In lib/core/database/seed_data.dart

static List<[ModelName]> get seed[ModelName]s => [
  [ModelName](
    id: '1',
    existingField: 'value',
    newField: 'appropriate_value', // Added
  ),
  [ModelName](
    id: '2',
    existingField: 'value2',
    newField: 'appropriate_value2', // Added
  ),
  // ... more seed records
];
```

✓ Seed data updated

Files modified:
- lib/core/database/seed_data.dart

Verification Steps:

**1. Code compiles:**
```bash
flutter analyze lib/core/database/seed_data.dart
```
✓ Compiles successfully

**2. Clear app data and test:**

iOS Simulator:
```bash
xcrun simctl uninstall booted com.example.gastrobrain
```

Android Emulator:
```bash
adb uninstall com.example.gastrobrain
```

**3. Run app (will seed database):**
```bash
flutter run
```

**4. Verify seed data loaded:**
- Open app
- Navigate to [feature using seeded data]
- Verify seed records appear
- Check new field values are correct
- Verify UI displays new field appropriately

✓ Seed data loads correctly
✓ New field values present
✓ UI displays correctly

Database State After Checkpoint 5:
- Seed data includes values for new field
- App initializes with seeded database successfully
- Seed records display correctly in UI
- New field values are appropriate

✅ Checkpoint 5 verification complete?
Ready to proceed to CHECKPOINT 6/6? (y/n)

[STOP - WAIT for user response]
```

### Option B: Seed Data Skip

```
==================
CHECKPOINT 5/6: Seed Data Updates
Goal: Determine if seed data needs updates

Progress from previous checkpoints:
✓ Checkpoint 1: Migration file created
✓ Checkpoint 2: Schema changes (up)
✓ Checkpoint 3: Rollback verified (down)
✓ Checkpoint 4: Model updated

Analysis: Should seed data be updated?

Checking requirements:
- New field: [field_name]
- Field is nullable: [yes/no]
- Null is appropriate for seed data: [yes/no]
- Seed records need explicit values: [yes/no]

Decision: SKIP seed data updates

Reason:
- [Why seed data doesn't need updates]
- Examples:
  * New field is nullable and null is appropriate
  * Seed data doesn't exist for this table
  * Field has default value in schema
  * Seed records intentionally left with null

✓ Seed data evaluation complete (no updates needed)

Skipping directly to Checkpoint 6 (Migration Tests).

Ready to proceed to CHECKPOINT 6/6? (y/n)

[STOP - WAIT for user response]
```

---

## Checkpoint 6: Migration Tests (MANDATORY)

```
==================
CHECKPOINT 6/6: Migration Tests
Goal: Create comprehensive tests verifying migration works correctly

⚠️ MANDATORY CHECKPOINT - Tests required for ALL migrations

Progress from previous checkpoints:
✓ Checkpoint 1: Migration file created (v[N+1])
✓ Checkpoint 2: Schema changes (up) implemented and verified
✓ Checkpoint 3: Rollback (down) implemented and verified
✓ Checkpoint 4: Model updated and verified
✓ Checkpoint 5: Seed data [updated / skipped]

Creating migration tests for v[N+1]:
[Description of what tests will verify]

Tasks for this checkpoint:
- [ ] Create test file: test/core/database/migrations/migration_v[N+1]_test.dart
- [ ] Import necessary packages (flutter_test, sqflite_ffi, migration)
- [ ] Set up test database (in-memory)
- [ ] Test: Migration applies (up)
- [ ] Test: Schema changes verified
- [ ] Test: Migration reverts (down)
- [ ] Test: Schema restored
- [ ] Test: Existing data preserved
- [ ] Test: New field usable
- [ ] Test: Full up → down → up cycle

Migration test implementation:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gastrobrain/core/database/migrations/migration_v[N+1].dart';

void main() {
  late Database db;
  late MigrationV[N+1] migration;

  setUp(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    db = await openDatabase(inMemoryDatabasePath, version: 1);
    migration = MigrationV[N+1]();
  });

  tearDown(() async {
    await db.close();
  });

  group('Migration v[N+1]', () {
    test('applies schema changes (up)', () async {
      // TODO: Create table if needed for test

      // Apply migration
      await migration.up(db);

      // Verify schema changes
      // [Specific verification for this migration]
    });

    test('reverts schema changes (down)', () async {
      // Apply migration first
      await migration.up(db);

      // Verify changes applied
      // [Verification]

      // Rollback
      await migration.down(db);

      // Verify changes reverted
      // [Verification]
    });

    test('preserves existing data', () async {
      // Create table and insert data
      // [Setup existing data]

      // Apply migration
      await migration.up(db);

      // Verify data still exists
      // [Verification]
    });

    test('supports up → down → up cycle', () async {
      // First up
      await migration.up(db);
      // [Verify]

      // Down
      await migration.down(db);
      // [Verify]

      // Second up
      await migration.up(db);
      // [Verify]
    });
  });
}
```

✓ Migration tests created

Files created:
- test/core/database/migrations/migration_v[N+1]_test.dart

Test coverage:
- ✓ Migration applies (up method)
- ✓ Schema changes verified
- ✓ Migration reverts (down method)
- ✓ Schema restored to previous state
- ✓ Existing data preserved
- ✓ New field usable in CRUD
- ✓ Full up → down → up cycle

Verification Steps:

**Run migration tests:**
```bash
flutter test test/core/database/migrations/migration_v[N+1]_test.dart
```

Expected output:
```
00:02 +4: All tests passed!
```

✓ All tests pass
✓ No errors or warnings
✓ Coverage: 4+ tests

**If tests fail:**
1. Review error messages carefully
2. Debug failing test
3. Fix issue in migration or test
4. Re-run tests
5. Repeat until all pass

⚠️ DO NOT SKIP FAILING TESTS
⚠️ DO NOT PROCEED with failing tests

Database/Migration State After Checkpoint 6:
- Migration v[N+1] fully tested ✓
- up() method verified working ✓
- down() method verified working ✓
- Backward compatibility confirmed ✓
- up → down → up cycle verified ✓
- All tests passing ✓
- Ready for commit ✓

🎉 MIGRATION IMPLEMENTATION COMPLETE!

═══════════════════════════════════════════
MIGRATION SUMMARY
═══════════════════════════════════════════

Migration: v[N+1]
Issue: #[NUMBER]
Branch: feature/[NUMBER]-[description]

Schema Changes:
- [Change 1]
- [Change 2]

Checkpoints Completed: 6/6
✓ Checkpoint 1: Migration file created
✓ Checkpoint 2: Schema changes (up)
✓ Checkpoint 3: Rollback verified (down)
✓ Checkpoint 4: Model updated
✓ Checkpoint 5: Seed data [updated/skipped]
✓ Checkpoint 6: Migration tests (all passing)

Files Created:
- lib/core/database/migrations/migration_v[N+1].dart
- test/core/database/migrations/migration_v[N+1]_test.dart

Files Modified:
- lib/core/models/[model_name].dart
- lib/core/database/seed_data.dart [if updated]

Safety Verification:
✓ Rollback works (up → down → up tested)
✓ Backward compatible (existing data preserved)
✓ Model matches schema exactly
✓ All tests passing (4+ tests)
✓ No data loss
✓ No schema inconsistencies

Next Steps:
1. Run full test suite: `flutter test`
2. Verify no regressions
3. Update issue roadmap: Mark Phase 2 (Database) complete
4. Commit migration with descriptive message
5. Proceed to next phase (Phase 3: Testing or other)

Suggested commit message:
```
feat: add migration v[N+1] for [description] (#[NUMBER])

- Add [schema change description]
- Update [ModelName] model
- Add migration tests
- Backward compatible (existing data preserved)
```

═══════════════════════════════════════════

Ready to commit migration? (y/n)
```

---

## Progress Bar Examples

```
Migration Progress: 1/6 checkpoints complete ██░░░░ 16%
Migration Progress: 2/6 checkpoints complete ████░░ 33%
Migration Progress: 3/6 checkpoints complete ████░░ 50%
Migration Progress: 4/6 checkpoints complete ██████░ 66%
Migration Progress: 5/6 checkpoints complete ████████░ 83%
Migration Progress: 6/6 checkpoints complete ██████████ 100%
```

## Checkpoint Status Indicators

```
✓ Checkpoint 1: Migration file created [COMPLETE]
✓ Checkpoint 2: Schema changes (up) [COMPLETE]
⧗ Checkpoint 3: Rollback (down) [CURRENT - IN PROGRESS]
○ Checkpoint 4: Model updates [PENDING]
○ Checkpoint 5: Seed data [PENDING]
○ Checkpoint 6: Migration tests [PENDING]
```

---

**Key Reminders:**

1. Generate code for EXACTLY ONE checkpoint per iteration
2. ALWAYS wait for user "y/n" verification
3. NEVER skip checkpoints (especially 3 and 6)
4. Provide exact verification commands
5. Check database state after each checkpoint
6. Debug immediately if verification fails
7. Complete code at each checkpoint (no TODOs)
8. Follow backward compatibility rules
9. Test rollback thoroughly (Checkpoint 3)
10. Require all tests passing (Checkpoint 6)
