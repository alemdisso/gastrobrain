---
name: gastrobrain-database-migration
description: Implements database migrations using checkpoint-driven approach with verification at each step to ensure safe schema changes and data integrity
version: 1.0.0
---

# Gastrobrain Database Migration Agent

## Purpose

Implements database migrations from issue roadmaps using a **checkpoint-based approach** that ensures safety, verifiability, and data integrity through careful step-by-step progression.

**Core Philosophy**: Plan → Checkpoint → Verify → Next Checkpoint

## When to Use This Skill

Use this skill when:
- Implementing Phase 2 (Database section) from issue roadmaps
- Need to create schema changes to SQLite database
- Adding new tables, columns, or indexes
- Modifying existing database structure
- Need to ensure backward compatibility with existing data
- Want careful, verifiable progression through migration work

**DO NOT use this skill for:**
- Quick model-only changes (no schema changes)
- Seed data updates without schema changes
- Database query optimization without schema changes
- Bug fixes in existing migration code

## Checkpoint Philosophy

### Why Checkpoint-Based Migrations?

**The Problem with All-At-Once:**
```
❌ BAD: Write entire migration + model + tests → Test → Find issues → Debug everything
Risk: High (data loss, broken rollback, model mismatch)
Clarity: Low (too many moving parts)
Debugging: Hard (which part failed?)
```

**The Checkpoint Advantage:**
```
✅ GOOD: CP1 (file) → verify → CP2 (schema) → verify → CP3 (rollback) → verify...
Risk: Low (each step verified before next)
Clarity: High (one concern at a time)
Debugging: Easy (issue isolated to current checkpoint)
```

### Key Benefits

1. **Database Safety**: Each step verified before proceeding
2. **Rollback Verification**: Explicit checkpoint for testing rollback
3. **Data Integrity**: Existing data tested at each step
4. **Model Consistency**: Schema and models updated separately, verified together
5. **User Control**: Full visibility into migration state at each checkpoint
6. **Clear Progress**: Always know which part of migration is complete

### Migration Risks This Prevents

1. **Data Loss**: Backward incompatible changes caught early
2. **Broken Rollback**: Rollback tested in dedicated checkpoint
3. **Model Mismatch**: Schema and model verified separately before combining
4. **Failed Migration**: Schema tested before model changes committed
5. **Incomplete Cleanup**: Down method verified to fully revert changes

## Context Detection

### Automatic Analysis

```
1. Detect current branch: feature/XXX-description
2. Extract issue number: XXX
3. Load roadmap: docs/planning/0.1.X/ISSUE-XXX-ROADMAP.md
4. Locate Phase 2 (Implementation - Database section)
5. Scan lib/core/database/migrations/ for latest version
6. Determine new version: latest + 1
7. Identify impacted models from roadmap
```

### Initial Output

```
Database Migration for Issue #XXX

Branch detected: feature/XXX-description
Roadmap: docs/planning/0.1.X/ISSUE-XXX-ROADMAP.md

Phase 2 (Database) Requirements:
[Summary of database changes needed]

Current State:
- Latest migration: v15 (migration_v15.dart)
- New migration: v16
- Impacted tables: [list]
- Impacted models: [list]
- Backward compatibility: [analysis]

Migration Checkpoint Plan:
1. Migration file creation
2. Schema changes (up method)
3. Rollback implementation (down method)
4. Model class updates
5. Seed data updates (if needed)
6. Migration tests

Total: 6 checkpoints

Ready to start Checkpoint 1/6? (y/n)
```

## Migration Checkpoint Breakdown

### Standard 6-Checkpoint Structure

**Checkpoint 1: Migration File Creation**
- Create migration file with version number
- Extend Migration base class
- Add empty up() and down() stubs
- Verify file compiles

**Checkpoint 2: Schema Changes (up method)**
- Implement SQL for schema changes
- Add proper error handling
- Use IF NOT EXISTS patterns
- Verify schema change works

**Checkpoint 3: Rollback Implementation (down method)** ⚠️ CRITICAL
- Implement SQL to revert schema changes
- Test rollback actually works
- Verify up → down → up cycle
- Ensure no orphaned data

**Checkpoint 4: Model Class Updates**
- Add/modify fields in Dart models
- Update toMap() method
- Update fromMap() method
- Update copyWith() if exists
- Verify model matches schema

**Checkpoint 5: Seed Data Updates**
- Update seed data if needed
- Verify seed data works with new schema
- Test app with seed data

**Checkpoint 6: Migration Tests** ⚠️ MANDATORY
- Test migration up applies cleanly
- Test migration down reverts cleanly
- Test existing data compatibility
- Test up → down → up sequence
- Verify all tests pass

### Flexible Checkpoint Count

Not all migrations need all 6 checkpoints:

**Simple column addition: 4-5 checkpoints**
- Skip Checkpoint 5 if seed data doesn't need updates
- Still require 1, 2, 3, 4, 6 (file, up, down, model, tests)

**New table creation: 5-6 checkpoints**
- Usually need seed data for new table
- All 6 checkpoints typically needed

**Complex data migration: 6+ checkpoints**
- May add "Data Migration" checkpoint between 3 and 4
- Data transformation needs dedicated verification

## Checkpoint Protocol

### For Each Checkpoint:

```
==================
CHECKPOINT X/Y: [Clear checkpoint name]
Goal: [One sentence describing what this accomplishes]

[If X > 1, show context:]
Progress from previous checkpoints:
✓ Checkpoint 1: [what was accomplished]
✓ Checkpoint 2: [what was accomplished]
[... previous checkpoints ...]

Tasks for this checkpoint:
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3

[Generate complete code for this checkpoint]

✓ Changes complete

Files modified:
- [file path]: [what changed]

Verification Steps:
1. [Specific verification step 1]
2. [Specific verification step 2]
3. [Specific verification step 3]

Commands to verify:
```bash
[Exact commands to run]
```

Database State After Checkpoint X:
[Description of expected database state]
- [Table/column that should exist or not exist]
- [Data that should be preserved]
- [Any constraints or indexes]

Ready to proceed to Checkpoint [X+1]/Y? (y/n)

[STOP - WAIT for user response]
```

### Response Handling

**If user responds "y" (checkpoint verified):**

```
✅ CHECKPOINT X/Y complete

Progress: X/Y checkpoints complete [progress bar]

Checkpoints Status:
✓ Checkpoint 1: [name]
✓ Checkpoint 2: [name]
✓ Checkpoint X: [name] [JUST COMPLETED]
○ Checkpoint X+1: [name]
[... remaining checkpoints ...]

Ready for CHECKPOINT [X+1]/Y? (y/n)
```

**If user responds "n" (checkpoint failed verification):**

```
❌ CHECKPOINT X/Y verification failed

Let's debug before proceeding. It's critical to fix this checkpoint
before continuing to ensure database integrity.

Common issues for [checkpoint type]:
1. [Common issue 1]
2. [Common issue 2]
3. [Common issue 3]

What issue are you seeing?
[Options: "doesn't compile", "migration fails", "rollback fails", "other"]

[WAIT for user input]

---

[After receiving issue:]

Analysis:
[Diagnosis of the issue]

Fix:
[Corrected code or specific fix instructions]

Try the fix:
[Commands to verify]

Does it work now? (y/n)

[Continue debugging loop until checkpoint passes]
```

## Safety and Rollback Verification

### Checkpoint 3: Rollback Testing (CRITICAL)

This checkpoint is **mandatory** and **cannot be skipped**.

```
==================
CHECKPOINT 3/6: Rollback Implementation
Goal: Implement and verify down() method completely reverts schema changes

⚠️ CRITICAL CHECKPOINT - ROLLBACK SAFETY

Progress from previous checkpoints:
✓ Checkpoint 1: Migration file created (v16)
✓ Checkpoint 2: Schema changes implemented (up method works)

Tasks for this checkpoint:
- [ ] Implement down() method with SQL to revert changes
- [ ] Test rollback removes all schema changes
- [ ] Verify up → down → up cycle works
- [ ] Ensure no orphaned data or broken constraints

[Generates complete down() method]

✓ Rollback implementation complete

Files modified:
- lib/core/database/migrations/migration_vX.dart: Added down() method

Verification Steps - MANDATORY TESTING:

1. Apply migration (up):
   ```bash
   # Run app to apply migration
   flutter run
   # Or run test that applies migration
   ```

2. Verify column/table exists:
   ```bash
   sqlite3 path/to/gastrobrain.db ".schema table_name"
   # Should show new column/table
   ```

3. Rollback (down):
   ```bash
   # Run test that rolls back migration
   flutter test test/core/database/migrations/migration_vX_test.dart --name "rollback"
   ```

4. Verify column/table removed:
   ```bash
   sqlite3 path/to/gastrobrain.db ".schema table_name"
   # Should NOT show new column/table
   ```

5. Re-apply migration (up):
   ```bash
   flutter run
   # Should work without errors
   ```

6. Verify column/table exists again:
   ```bash
   sqlite3 path/to/gastrobrain.db ".schema table_name"
   # Should show new column/table again
   ```

7. App still functional at each step:
   - After up: App works ✓
   - After down: App works ✓
   - After re-up: App works ✓

Database State After Checkpoint 3:
- up() method adds schema changes correctly
- down() method completely reverts schema changes
- up → down → up cycle works flawlessly
- No data loss or corruption at any step
- App remains functional throughout

⚠️ DO NOT PROCEED if rollback doesn't work perfectly!

Ready to proceed to Checkpoint 4/6? (y/n)
```

### Rollback Patterns by Change Type

**Adding Column:**
```dart
// up
await db.execute('ALTER TABLE table_name ADD COLUMN col_name TYPE NULL');

// down
await db.execute('ALTER TABLE table_name DROP COLUMN col_name');
```

**Creating Table:**
```dart
// up
await db.execute('CREATE TABLE IF NOT EXISTS table_name (...)');

// down
await db.execute('DROP TABLE IF EXISTS table_name');
```

**Adding Index:**
```dart
// up
await db.execute('CREATE INDEX IF NOT EXISTS idx_name ON table(col)');

// down
await db.execute('DROP INDEX IF EXISTS idx_name');
```

## Backward Compatibility Rules

### Critical Safety Guidelines

1. **New columns MUST be nullable**
   ```dart
   // ✅ CORRECT - nullable column
   ALTER TABLE meals ADD COLUMN meal_type TEXT NULL

   // ❌ WRONG - not null without default breaks existing data
   ALTER TABLE meals ADD COLUMN meal_type TEXT NOT NULL
   ```

2. **Use NOT NULL only with DEFAULT**
   ```dart
   // ✅ CORRECT - not null with default value
   ALTER TABLE meals ADD COLUMN is_favorite INTEGER NOT NULL DEFAULT 0
   ```

3. **Test with existing data**
   - Create test with existing records
   - Apply migration
   - Verify existing records still queryable
   - Verify no data loss

4. **Consider data migration**
   - If transforming existing data, add checkpoint between 3 and 4
   - Use SQL UPDATE statements carefully
   - Test with production-like data volumes

### Checkpoint 2 Safety Checks

```
CHECKPOINT 2/6: Schema Changes

[... implementation ...]

Backward Compatibility Verification:

Before applying migration:
1. App has existing data in [table]
2. Existing records: [count]

After applying migration:
1. Existing records still present: [verify count]
2. Existing records still queryable: [test query]
3. New column is nullable: ✓
4. No data loss: ✓

If adding NOT NULL column:
- Must have DEFAULT value
- Verify: sqlite3 db ".schema table" shows DEFAULT

Ready to proceed to Checkpoint 3/6? (y/n)
```

## Model Update Patterns

### Checkpoint 4: Model Updates

```
==================
CHECKPOINT 4/6: Model Class Updates
Goal: Update Dart model to match new schema exactly

Progress from previous checkpoints:
✓ Checkpoint 1: Migration file created
✓ Checkpoint 2: Schema changes (up)
✓ Checkpoint 3: Rollback verified (down)

Tasks for this checkpoint:
- [ ] Add/modify field in model class
- [ ] Update toMap() method to include new field
- [ ] Update fromMap() method to parse new field
- [ ] Update copyWith() method if exists
- [ ] Ensure field type matches schema
- [ ] Make field nullable if column is nullable

[For adding a field:]

Model: lib/core/models/[model_name].dart

Changes needed:
1. Add field to class
2. Update toMap()
3. Update fromMap()
4. Update copyWith()

[Generates complete model updates]

✓ Model updated

Files modified:
- lib/core/models/[model_name].dart

Verification Steps:

1. Code compiles:
   ```bash
   flutter analyze lib/core/models/[model_name].dart
   ```

2. Field type matches schema:
   - Schema: [column type]
   - Model: [dart type]
   - Match: ✓

3. Field nullability matches schema:
   - Schema: [NULL or NOT NULL]
   - Model: [nullable or not]
   - Match: ✓

4. Test CRUD operations:
   ```bash
   flutter test test/core/models/[model_name]_test.dart
   ```

5. Test with database:
   - Create record with new field
   - Query record
   - Update record
   - Delete record
   - All operations work: ✓

Model State After Checkpoint 4:
- Model field matches schema exactly
- toMap() includes new field
- fromMap() parses new field correctly
- copyWith() handles new field
- All CRUD operations work

Ready to proceed to Checkpoint 5/6? (y/n)
```

### Standard Model Pattern

**Adding nullable field:**
```dart
class MyModel {
  final String id;
  final String? newField; // Nullable if column is NULL

  MyModel({
    required this.id,
    this.newField, // Optional parameter
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'new_field': newField, // Can be null
    };
  }

  factory MyModel.fromMap(Map<String, dynamic> map) {
    return MyModel(
      id: map['id'] as String,
      newField: map['new_field'] as String?, // Nullable
    );
  }

  MyModel copyWith({
    String? id,
    String? newField, // Nullable
  }) {
    return MyModel(
      id: id ?? this.id,
      newField: newField ?? this.newField,
    );
  }
}
```

**Adding non-null field with default:**
```dart
class MyModel {
  final String id;
  final bool isFavorite; // Non-null with default

  MyModel({
    required this.id,
    this.isFavorite = false, // Default value
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  factory MyModel.fromMap(Map<String, dynamic> map) {
    return MyModel(
      id: map['id'] as String,
      isFavorite: (map['is_favorite'] as int?) == 1,
    );
  }
}
```

## Seed Data Updates

### Checkpoint 5: Seed Data (Conditional)

```
==================
CHECKPOINT 5/6: Seed Data Updates
Goal: Update seed data if needed for new schema

Progress from previous checkpoints:
✓ Checkpoint 1: Migration file created
✓ Checkpoint 2: Schema changes (up)
✓ Checkpoint 3: Rollback verified (down)
✓ Checkpoint 4: Model updated

Analysis: Should seed data be updated?

Question: Do seed data records need values for new field?
- If YES → Update seed data
- If NO → Leave as null (skip to Checkpoint 6)

[Based on issue requirements, provide guidance]

Decision: [UPDATE / SKIP]

[If UPDATE:]

Tasks for this checkpoint:
- [ ] Update lib/core/database/seed_data.dart
- [ ] Add values for new field in seed records
- [ ] Verify seed data works with new schema
- [ ] Test app initialization with seed data

[Generates seed data updates]

✓ Seed data updated

Files modified:
- lib/core/database/seed_data.dart

Verification Steps:

1. Clear app data:
   ```bash
   # iOS Simulator
   xcrun simctl uninstall booted com.example.gastrobrain

   # Android Emulator
   adb uninstall com.example.gastrobrain
   ```

2. Run app (will seed database):
   ```bash
   flutter run
   ```

3. Verify seed data loaded:
   - Check UI shows seed records
   - Verify new field values are correct
   - Test app functionality with seed data

Seed Data State After Checkpoint 5:
- Seed data includes values for new field
- App initializes successfully with seed data
- Seed records display correctly in UI

Ready to proceed to Checkpoint 6/6? (y/n)

[If SKIP:]

Seed data doesn't require updates because:
- New field is nullable
- Null is appropriate for seed data
- [Other reason]

Skipping to Checkpoint 6/6 (Migration Tests).

Ready to proceed to Checkpoint 6/6? (y/n)
```

## Migration Testing Requirements

### Checkpoint 6: Migration Tests (MANDATORY)

```
==================
CHECKPOINT 6/6: Migration Tests
Goal: Create comprehensive tests verifying migration works correctly

⚠️ MANDATORY CHECKPOINT - Tests are required for all migrations

Progress from previous checkpoints:
✓ Checkpoint 1: Migration file created (vX)
✓ Checkpoint 2: Schema changes implemented (up)
✓ Checkpoint 3: Rollback verified (down)
✓ Checkpoint 4: Model updated
✓ Checkpoint 5: Seed data updated [or skipped]

Tasks for this checkpoint:
- [ ] Create test file for migration vX
- [ ] Test up() applies schema changes correctly
- [ ] Test down() reverts schema changes completely
- [ ] Test existing data compatibility
- [ ] Test new field is usable in CRUD operations
- [ ] Test up → down → up cycle
- [ ] Verify all tests pass

[Generates complete migration test file]

Test file: test/core/database/migrations/migration_vX_test.dart

Test coverage:
1. ✓ Migration applies (up)
2. ✓ Schema changes verified
3. ✓ Migration reverts (down)
4. ✓ Schema restored to previous state
5. ✓ Existing data preserved
6. ✓ New field usable
7. ✓ Full up → down → up cycle

✓ Migration tests created

Files created:
- test/core/database/migrations/migration_vX_test.dart

Verification Steps:

Run migration tests:
```bash
flutter test test/core/database/migrations/migration_vX_test.dart
```

Expected output:
- All tests pass ✓
- No errors or warnings
- Coverage: [X] tests

If tests fail:
- Review error messages
- Fix issues in migration or tests
- Re-run until all pass
- DO NOT SKIP FAILING TESTS

Database State After Checkpoint 6:
- Migration vX fully tested
- up() verified working
- down() verified working
- Backward compatibility confirmed
- Ready for commit

🎉 MIGRATION COMPLETE!

═══════════════════════════════════════════
MIGRATION IMPLEMENTATION SUMMARY
═══════════════════════════════════════════

Migration: v[X]
Issue: #[XXX]
Changes: [Summary of schema changes]

Checkpoints Completed:
✓ Checkpoint 1: Migration file created
✓ Checkpoint 2: Schema changes (up)
✓ Checkpoint 3: Rollback verified (down)
✓ Checkpoint 4: Model updated
✓ Checkpoint 5: Seed data [updated/skipped]
✓ Checkpoint 6: Migration tests (all passing)

Files Modified:
- lib/core/database/migrations/migration_vX.dart [NEW]
- lib/core/models/[model].dart [MODIFIED]
- lib/core/database/seed_data.dart [MODIFIED/UNCHANGED]
- test/core/database/migrations/migration_vX_test.dart [NEW]

Safety Verification:
✓ Rollback works (up → down → up tested)
✓ Backward compatible (existing data preserved)
✓ Model matches schema exactly
✓ All tests passing

Next Steps:
1. ✓ Run full test suite: flutter test
2. ✓ Verify no regressions
3. ○ Update issue roadmap: Mark Phase 2 (Database) complete
4. ○ Commit migration
5. ○ Proceed to Phase 3 (Testing) or next phase

═══════════════════════════════════════════

Ready to commit migration? (y/n)
```

### Standard Test Structure

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gastrobrain/core/database/migrations/migration_vX.dart';

void main() {
  late Database db;
  late MigrationVX migration;

  setUp(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    db = await openDatabase(inMemoryDatabasePath, version: 1);
    migration = MigrationVX();
  });

  tearDown(() async {
    await db.close();
  });

  group('Migration vX', () {
    test('applies schema changes (up)', () async {
      // Apply migration
      await migration.up(db);

      // Verify schema changes
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='table_name'"
      );
      expect(result, isNotEmpty);

      // Verify column exists
      final columns = await db.rawQuery('PRAGMA table_info(table_name)');
      expect(columns.any((col) => col['name'] == 'new_column'), isTrue);
    });

    test('reverts schema changes (down)', () async {
      // Apply migration
      await migration.up(db);

      // Verify it was applied
      var columns = await db.rawQuery('PRAGMA table_info(table_name)');
      expect(columns.any((col) => col['name'] == 'new_column'), isTrue);

      // Rollback
      await migration.down(db);

      // Verify it was reverted
      columns = await db.rawQuery('PRAGMA table_info(table_name)');
      expect(columns.any((col) => col['name'] == 'new_column'), isFalse);
    });

    test('preserves existing data', () async {
      // Create table with old schema
      await db.execute('''
        CREATE TABLE table_name (
          id TEXT PRIMARY KEY,
          existing_field TEXT
        )
      ''');

      // Insert test data
      await db.insert('table_name', {'id': '1', 'existing_field': 'test'});

      // Apply migration
      await migration.up(db);

      // Verify data still exists
      final result = await db.query('table_name');
      expect(result.length, equals(1));
      expect(result.first['id'], equals('1'));
      expect(result.first['existing_field'], equals('test'));
    });

    test('supports up → down → up cycle', () async {
      // First up
      await migration.up(db);
      var columns = await db.rawQuery('PRAGMA table_info(table_name)');
      expect(columns.any((col) => col['name'] == 'new_column'), isTrue);

      // Down
      await migration.down(db);
      columns = await db.rawQuery('PRAGMA table_info(table_name)');
      expect(columns.any((col) => col['name'] == 'new_column'), isFalse);

      // Second up
      await migration.up(db);
      columns = await db.rawQuery('PRAGMA table_info(table_name)');
      expect(columns.any((col) => col['name'] == 'new_column'), isTrue);
    });
  });
}
```

## Progress Tracking

Show clear progress after each checkpoint:

```
Migration Progress: 3/6 checkpoints complete ████░░ 50%

✓ Checkpoint 1: Migration file created [COMPLETE]
✓ Checkpoint 2: Schema changes (up) [COMPLETE]
✓ Checkpoint 3: Rollback verified (down) [COMPLETE]
⧗ Checkpoint 4: Model updates [CURRENT]
○ Checkpoint 5: Seed data updates
○ Checkpoint 6: Migration tests
```

## Common Migration Patterns

### Pattern 1: Add Nullable Column

**Checkpoints: 5 (skip seed data)**

```
CP1: Create migration file
CP2: ALTER TABLE table ADD COLUMN col TYPE NULL
CP3: ALTER TABLE table DROP COLUMN col
CP4: Add field to model (nullable)
CP5: Skip (nullable field, no seed update needed)
CP6: Tests
```

### Pattern 2: Add Column with Default

**Checkpoints: 6**

```
CP1: Create migration file
CP2: ALTER TABLE table ADD COLUMN col TYPE NOT NULL DEFAULT value
CP3: ALTER TABLE table DROP COLUMN col
CP4: Add field to model (with default)
CP5: Update seed data with default values
CP6: Tests
```

### Pattern 3: Create New Table

**Checkpoints: 6**

```
CP1: Create migration file
CP2: CREATE TABLE IF NOT EXISTS table (...)
CP3: DROP TABLE IF EXISTS table
CP4: Create new model class
CP5: Add seed data for new table
CP6: Tests
```

### Pattern 4: Add Index

**Checkpoints: 4 (no model/seed changes)**

```
CP1: Create migration file
CP2: CREATE INDEX IF NOT EXISTS idx ON table(col)
CP3: DROP INDEX IF EXISTS idx
CP4: No model changes (skip)
CP5: No seed changes (skip)
CP6: Tests
```

### Pattern 5: Complex Data Migration

**Checkpoints: 7 (add data migration)**

```
CP1: Create migration file
CP2: ALTER TABLE (add new column)
CP3: Data migration (transform existing data)
CP4: Rollback (revert both schema and data)
CP5: Update model
CP6: Update seed data
CP7: Tests (including data migration)
```

## Error Handling and Debugging

### Common Issues by Checkpoint

**Checkpoint 1 (File Creation):**
- Compilation errors → Check syntax
- Version conflict → Verify version number is latest + 1
- Import errors → Check Migration base class import

**Checkpoint 2 (Schema up):**
- Migration fails → Check SQL syntax
- Column already exists → Use IF NOT EXISTS or check existing schema
- Type mismatch → Verify SQLite type is correct

**Checkpoint 3 (Rollback down):**
- Down doesn't revert → Check SQL matches up() changes
- Column/table still exists → Verify DROP statement
- App crashes after rollback → Check app handles missing column

**Checkpoint 4 (Model):**
- Compilation error → Check field type matches schema
- fromMap() fails → Verify column name matches exactly
- Null error → Ensure nullable types for nullable columns

**Checkpoint 5 (Seed Data):**
- Seed fails to load → Check new field values are valid
- Type error → Verify seed data types match model

**Checkpoint 6 (Tests):**
- Test fails → Debug specific test, verify migration logic
- Flaky test → Check test cleanup (tearDown)
- Coverage incomplete → Add missing test cases

## Success Criteria

This skill succeeds when:

1. **Checkpoint-Based**: Migration broken into clear, verifiable checkpoints
2. **Safety First**: Rollback explicitly tested (Checkpoint 3)
3. **Backward Compatible**: Existing data preserved and tested
4. **Model Consistency**: Schema and model match exactly
5. **User Control**: User confirms each checkpoint before next
6. **Complete Tests**: Migration tests comprehensive and passing
7. **Clear Progress**: Status visible at each checkpoint
8. **Verified State**: Database state checked after each checkpoint

## References

- `lib/core/database/migrations/`: Existing migration patterns
- `lib/core/models/`: Model structure and patterns
- `lib/core/database/seed_data.dart`: Seed data format
- `test/core/database/migrations/`: Migration test patterns
- SQLite documentation: Column types and constraints
- Sqflite documentation: Flutter SQLite operations

---

**Remember**: Database migrations are permanent. Each checkpoint verification prevents data loss and broken deployments. Never skip checkpoints, especially rollback testing.
