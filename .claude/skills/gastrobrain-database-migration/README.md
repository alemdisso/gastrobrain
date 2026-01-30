# Gastrobrain Database Migration Agent Skill

An agent skill for implementing database migrations using a **checkpoint-driven approach** that ensures safety, verifiability, and data integrity through careful step-by-step progression.

## Quick Start

```bash
# From your branch for an issue (e.g., feature/285-recipe-notes)
# In Claude Code, invoke the skill:
/gastrobrain-database-migration
```

The skill will:
1. Detect your current branch and issue number
2. Load the issue roadmap
3. Analyze Phase 2 (Database) requirements
4. Determine new migration version
5. Break work into 4-7 checkpoints
6. Implement migration **ONE CHECKPOINT AT A TIME** with verification

## Core Philosophy

**Plan → Checkpoint → Verify → Next Checkpoint**

Never implement entire migration at once. Always verify database state after each checkpoint before proceeding.

### Why Checkpoint-Based Migrations?

**The Problem with All-At-Once:**
```
❌ Write entire migration → Test → Find data loss issue → Rollback doesn't work → Disaster
Risk: HIGH | Clarity: LOW | Debugging: HARD
```

**The Checkpoint Advantage:**
```
✅ CP1 (file) → verify → CP2 (schema) → verify → CP3 (rollback) → verify → CP4 (model)...
Risk: LOW | Clarity: HIGH | Debugging: EASY
```

### Key Benefits

1. **Database Safety**: Each step verified before proceeding (no surprise data loss)
2. **Rollback Verification**: Explicit checkpoint for testing rollback (Checkpoint 3)
3. **Data Integrity**: Existing data tested at each checkpoint
4. **Model Consistency**: Schema and models updated separately, verified together
5. **User Control**: Full visibility into migration state at each checkpoint
6. **Clear Progress**: Always know which part is complete

## File Structure

```
gastrobrain-database-migration/
├── SKILL.md                              # Main skill documentation
├── README.md                             # This file
├── templates/
│   └── migration_checkpoint_template.md # Template showing 6-checkpoint structure
└── examples/
    ├── simple_column_addition.md        # 5 checkpoints (~15-20 min)
    ├── new_table_creation.md            # 6 checkpoints (~25-30 min)
    └── complex_data_migration.md        # 7 checkpoints (~40-50 min)
```

## How It Works

### Phase 1: Context Detection
- Detects current branch → extracts issue number
- Loads roadmap → finds Phase 2 (Database section)
- Scans `lib/core/database/migrations/` for latest version
- Determines new version number (latest + 1)
- Identifies impacted tables and models

### Phase 2: Checkpoint Planning
Breaks migration into 4-7 checkpoints based on complexity:

**Standard 6 Checkpoints:**
1. Migration file creation
2. Schema changes (up method)
3. **Rollback implementation (down method)** - CRITICAL
4. Model class updates
5. Seed data updates (if needed)
6. **Migration tests** - MANDATORY

**Simple migrations (4-5 checkpoints)**: Skip seed data if not needed

**Complex migrations (7+ checkpoints)**: Add data migration checkpoint between 3 and 4

### Phase 3: Checkpoint Execution
For EACH checkpoint (repeat 4-7 times):
1. Generate **ONE** checkpoint implementation (complete code)
2. Show verification steps with exact commands
3. Describe expected database state
4. Ask: "Ready to proceed? (y/n)"
5. **WAIT** for user response
6. If **yes**: Mark complete, show progress, continue to next
7. If **no**: Debug, fix, retry current checkpoint until verified
8. After success: Document what worked, apply to next checkpoint

### Phase 4: Completion
- Final verification: Run all tests together
- Summary of migration
- Safety checklist
- Next steps

## Standard Checkpoint Structure

### Checkpoint 1: Migration File Creation
- Create `migration_vX.dart`
- Extend Migration base class
- Add empty up() and down() methods
- **Verify**: File compiles

### Checkpoint 2: Schema Changes (up method)
- Implement SQL for schema changes
- Use IF NOT EXISTS patterns
- **Verify**: Schema applies correctly, existing data preserved

### Checkpoint 3: Rollback Implementation ⚠️ CRITICAL
- Implement down() to revert schema changes
- **Verify**: up → down → up cycle works perfectly
- **DO NOT SKIP**: This ensures migration can be safely reverted

### Checkpoint 4: Model Class Updates
- Add/modify fields in Dart models
- Update toMap(), fromMap(), copyWith()
- **Verify**: Model matches schema exactly

### Checkpoint 5: Seed Data Updates
- Update seed data if needed for new fields
- **Verify**: App initializes with seed data
- **Skip if**: New field is nullable and null is appropriate

### Checkpoint 6: Migration Tests ⚠️ MANDATORY
- Test up() applies changes
- Test down() reverts changes
- Test existing data preserved
- Test up → down → up cycle
- **Verify**: All tests pass

## Migration Patterns by Complexity

### Low Complexity: Add Nullable Column (5 checkpoints, ~15-20 min)
```
Example: Add 'notes' column to recipes
Checkpoints: 1, 2, 3, 4, [5 skipped], 6
See: examples/simple_column_addition.md
```

### Medium Complexity: Create New Table (6 checkpoints, ~25-30 min)
```
Example: Create shopping_lists table
Checkpoints: 1, 2, 3, 4, 5, 6
See: examples/new_table_creation.md
```

### High Complexity: Data Migration (7 checkpoints, ~40-50 min)
```
Example: Split recipe name into title/subtitle
Checkpoints: 1, 2, 3 (data migration), 4, 5, 6, 7
See: examples/complex_data_migration.md
```

## Safety Guidelines

### Backward Compatibility Rules

1. **New columns MUST be nullable** (unless using DEFAULT)
   ```sql
   -- ✅ CORRECT
   ALTER TABLE meals ADD COLUMN meal_type TEXT NULL

   -- ❌ WRONG (breaks existing data)
   ALTER TABLE meals ADD COLUMN meal_type TEXT NOT NULL
   ```

2. **Use NOT NULL only with DEFAULT**
   ```sql
   -- ✅ CORRECT
   ALTER TABLE meals ADD COLUMN is_favorite INTEGER NOT NULL DEFAULT 0
   ```

3. **Test with existing data**
   - Create test with existing records
   - Apply migration
   - Verify records still queryable
   - Verify no data loss

4. **Data transformations need dedicated checkpoint**
   - Add Checkpoint 3 for data migration
   - Verify all records transformed
   - Test edge cases
   - Proceed only after verification

### Rollback Safety (Checkpoint 3)

**MANDATORY testing sequence:**
1. Apply migration (up)
2. Verify schema changes exist
3. Rollback (down)
4. Verify schema reverted completely
5. Re-apply (up)
6. Verify schema changes exist again
7. App works at ALL stages

**DO NOT PROCEED** if rollback doesn't work perfectly!

### Testing Requirements (Checkpoint 6)

**Mandatory tests:**
- ✅ Migration applies (up)
- ✅ Schema verified
- ✅ Migration reverts (down)
- ✅ Existing data preserved
- ✅ New field usable
- ✅ Full up → down → up cycle

**Minimum**: 4-6 tests depending on complexity

## Common Migration Patterns

### Add Nullable Column
```dart
// up
await db.execute('ALTER TABLE table_name ADD COLUMN col_name TYPE NULL');

// down
await db.execute('ALTER TABLE table_name DROP COLUMN col_name');
```

### Create Table
```dart
// up
await db.execute('''
  CREATE TABLE IF NOT EXISTS table_name (
    id TEXT PRIMARY KEY,
    field TEXT NOT NULL
  )
''');

// down
await db.execute('DROP TABLE IF EXISTS table_name');
```

### Add Index
```dart
// up
await db.execute('CREATE INDEX IF NOT EXISTS idx_name ON table(col)');

// down
await db.execute('DROP INDEX IF EXISTS idx_name');
```

### Data Migration
```dart
Future<void> _migrateData(Database db) async {
  final records = await db.query('table_name');
  for (final record in records) {
    // Transform data
    final transformed = transformRecord(record);
    // Update record
    await db.update('table_name', transformed, where: 'id = ?', whereArgs: [record['id']]);
  }
}
```

## When to Use This Skill

✅ **Use when:**
- Implementing Phase 2 (Database section) from issue roadmaps
- Need to create schema changes to SQLite database
- Adding new tables, columns, or indexes
- Modifying existing database structure
- Need to ensure backward compatibility
- Want careful, verifiable progression

❌ **Don't use when:**
- Quick model-only changes (no schema changes)
- Seed data updates without schema changes
- Query optimization without schema changes
- Bug fixes in existing migrations

## Progress Tracking

Clear visual progress after each checkpoint:

```
Migration Progress: 3/6 checkpoints complete ████░░ 50%

✓ Checkpoint 1: Migration file created [COMPLETE]
✓ Checkpoint 2: Schema changes (up) [COMPLETE]
✓ Checkpoint 3: Rollback verified (down) [COMPLETE]
⧗ Checkpoint 4: Model updates [CURRENT]
○ Checkpoint 5: Seed data updates [PENDING]
○ Checkpoint 6: Migration tests [PENDING]
```

## Verification Commands

### Check Schema
```bash
sqlite3 path/to/gastrobrain.db ".schema table_name"
```

### Check Tables
```bash
sqlite3 path/to/gastrobrain.db ".tables"
```

### Check Column Info
```bash
sqlite3 path/to/gastrobrain.db "PRAGMA table_info(table_name);"
```

### Query Data
```bash
sqlite3 path/to/gastrobrain.db "SELECT * FROM table_name LIMIT 5;"
```

### Run Tests
```bash
# Specific migration test
flutter test test/core/database/migrations/migration_vX_test.dart

# All migration tests
flutter test test/core/database/migrations/

# Full test suite
flutter test
```

## Error Handling

### Common Issues by Checkpoint

**Checkpoint 1**: Compilation errors → Check syntax
**Checkpoint 2**: Migration fails → Check SQL syntax, column types
**Checkpoint 3**: Rollback fails → Verify down() reverts all changes from up()
**Checkpoint 4**: Model mismatch → Ensure field types match schema
**Checkpoint 5**: Seed fails → Check data types and values
**Checkpoint 6**: Tests fail → Debug specific test, verify migration logic

### If Checkpoint Fails

The skill will:
1. Stop and not proceed to next checkpoint
2. Ask what error you're seeing
3. Diagnose the issue
4. Provide fix (corrected code or instructions)
5. Ask to verify fix
6. Loop until checkpoint passes
7. Then proceed to next checkpoint

**Never skip a failing checkpoint!**

## Success Criteria

Migration succeeds when:
1. ✅ All checkpoints complete (4-7 depending on complexity)
2. ✅ Rollback explicitly tested and works (Checkpoint 3)
3. ✅ Backward compatible (existing data preserved)
4. ✅ Model matches schema exactly
5. ✅ All tests pass (Checkpoint 6)
6. ✅ Database state verified at each checkpoint
7. ✅ No data loss at any stage

## Templates and Examples

### Template Reference
See `templates/migration_checkpoint_template.md` for:
- Initial context and planning format
- Each checkpoint format (1-6)
- Success/failure response formats
- Progress tracking format
- Verification steps format

### Example Migrations

**Example 1: Simple Column Addition**
- File: `examples/simple_column_addition.md`
- Scenario: Add 'notes' column to recipes
- Checkpoints: 5 (skipped seed data)
- Complexity: Low
- Time: ~15-20 minutes

**Example 2: New Table Creation**
- File: `examples/new_table_creation.md`
- Scenario: Create shopping_lists table
- Checkpoints: 6 (all standard checkpoints)
- Complexity: Medium
- Time: ~25-30 minutes

**Example 3: Complex Data Migration**
- File: `examples/complex_data_migration.md`
- Scenario: Split recipe name into title/subtitle
- Checkpoints: 7 (added data migration)
- Complexity: High
- Time: ~40-50 minutes
- Special: Transforms 150+ existing records

## References

- **SKILL.md**: Complete skill documentation with all patterns
- **`lib/core/database/migrations/`**: Existing migration patterns
- **`lib/core/models/`**: Model structure reference
- **`lib/core/database/seed_data.dart`**: Seed data format
- **`test/core/database/migrations/`**: Migration test patterns
- **SQLite docs**: Column types and constraints
- **Sqflite docs**: Flutter SQLite operations

## Anti-Patterns to Avoid

### ❌ NEVER DO:
1. **Batch entire migration**: Implement all at once
2. **Skip rollback testing**: Checkpoint 3 is mandatory
3. **Skip migration tests**: Checkpoint 6 is mandatory
4. **Proceed with failures**: Fix checkpoint before next
5. **Use NOT NULL without DEFAULT**: Breaks existing data
6. **Forget to test existing data**: Always verify preservation

### ✅ ALWAYS DO:
1. **One checkpoint at a time**: Implement, verify, proceed
2. **Test rollback explicitly**: Checkpoint 3 is critical
3. **Write migration tests**: Checkpoint 6 is mandatory
4. **Use nullable columns**: For adding to existing tables
5. **Verify database state**: After each checkpoint
6. **Test with existing data**: Ensure no data loss

---

**Remember**: Database migrations are permanent. Each checkpoint verification prevents data loss and broken deployments. Never rush through checkpoints.

## Version

**v1.0.0** - Initial release with checkpoint-based migration methodology

---

## Quick Command Reference

```bash
# Invoke skill
/gastrobrain-database-migration

# Check compilation
flutter analyze lib/core/database/migrations/migration_vX.dart

# Run migration tests
flutter test test/core/database/migrations/migration_vX_test.dart

# Check schema
sqlite3 gastrobrain.db ".schema table_name"

# Run full tests
flutter test

# Clear app data (iOS)
xcrun simctl uninstall booted com.example.gastrobrain

# Clear app data (Android)
adb uninstall com.example.gastrobrain
```
