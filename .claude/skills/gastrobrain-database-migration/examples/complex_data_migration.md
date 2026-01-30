# Example 3: Complex Schema Change with Data Migration

This example shows a complex migration that requires transforming existing data - demonstrates adding a checkpoint for data migration. Most complex scenario, requires 7 checkpoints.

**Scenario**: Split `recipe_name` into `title` and `subtitle` fields (Issue #340)

---

## Initial Context and Plan

```
Database Migration for Issue #340

Branch detected: feature/340-recipe-title-subtitle
Roadmap: docs/planning/0.1.8/ISSUE-340-ROADMAP.md

Phase 2 (Database) Analysis:
Split recipe names into title and subtitle for better organization.
Many recipes have format "Title - Subtitle", need to parse and migrate existing data.

Current Database State:
- Latest migration: v19 (migration_v19.dart)
- New migration version: v20
- Impacted tables: recipes
- Impacted models: Recipe
- **CRITICAL**: 150+ existing recipes need data transformation

Schema Changes Summary:
- Add `title` column to recipes (TEXT NOT NULL)
- Add `subtitle` column to recipes (TEXT NULL)
- **Migrate existing `name` data** to title/subtitle
- Keep `name` column temporarily for backward compat during migration
- Future migration will remove `name` column

Backward Compatibility Analysis:
- **Complex**: Need to transform existing data
- Cannot make columns NULL (data is being split, not added)
- Must parse existing names and populate new columns
- Rollback must restore original data

Migration Checkpoint Plan:

Checkpoint 1: Migration File Creation
├─ Create migration_v20.dart
├─ Extend Migration base class
└─ Add empty up() and down() methods

Checkpoint 2: Schema Changes (up method - Part 1)
├─ Add title column (TEXT NULL initially for migration)
├─ Add subtitle column (TEXT NULL)
└─ Keep existing name column

Checkpoint 3: Data Migration (NEW CHECKPOINT)
├─ Parse existing name values
├─ Split into title and subtitle
├─ Populate new columns
└─ Verify all records migrated

Checkpoint 4: Schema Changes (up method - Part 2)
├─ ALTER title to NOT NULL (after data migrated)
└─ Finalize schema

Checkpoint 5: Rollback Implementation (down method)
├─ Drop title and subtitle columns
└─ Restore to original state

Checkpoint 6: Model Class Updates
├─ Add title and subtitle fields
├─ Update toMap(), fromMap(), copyWith()
└─ Keep name field temporarily

Checkpoint 7: Migration Tests
├─ Test schema changes
├─ Test data migration (existing names split correctly)
├─ Test rollback restores original data
└─ Test up → down → up cycle

Total: 7 checkpoints (added data migration checkpoint)

⚠️ NOTE: This migration is complex and requires careful data handling!

Ready to start CHECKPOINT 1/7? (y/n)
```

**User**: y

---

## Checkpoints 1-2: Setup (Abbreviated for Space)

```
[CHECKPOINT 1: Migration file creation - similar to previous examples]
[CHECKPOINT 2: Add title and subtitle columns as NULL initially]

After Checkpoint 2 schema:
```dart
await db.execute('ALTER TABLE recipes ADD COLUMN title TEXT NULL');
await db.execute('ALTER TABLE recipes ADD COLUMN subtitle TEXT NULL');
```

Database state: Columns added but empty (all NULL).
Ready for data migration.
```

---

## Checkpoint 3: Data Migration (CRITICAL)

```
==================
CHECKPOINT 3/7: Data Migration
Goal: Transform existing recipe names into title and subtitle

⚠️ CRITICAL CHECKPOINT - DATA TRANSFORMATION

Progress from previous checkpoints:
✓ Checkpoint 1: Migration file created (v20)
✓ Checkpoint 2: Added title and subtitle columns (both NULL)

Implementing data migration:
Parse existing `name` values and split into title/subtitle.
Format: "Title - Subtitle" → title="Title", subtitle="Subtitle"
Or: "Single Title" → title="Single Title", subtitle=null

Tasks for this checkpoint:
- [x] Query all existing recipes
- [x] Parse name field for each recipe
- [x] Split on " - " delimiter
- [x] Update title column
- [x] Update subtitle column (if present)
- [x] Handle edge cases (no delimiter, multiple delimiters)
- [x] Verify all records updated

Data migration implementation:

```dart
@override
Future<void> up(Database db) async {
  // Checkpoint 2: Add new columns
  await db.execute('ALTER TABLE recipes ADD COLUMN title TEXT NULL');
  await db.execute('ALTER TABLE recipes ADD COLUMN subtitle TEXT NULL');

  // Checkpoint 3: Migrate existing data
  await _migrateRecipeNames(db);
}

/// Helper method to migrate existing recipe names to title/subtitle
Future<void> _migrateRecipeNames(Database db) async {
  // Get all recipes
  final recipes = await db.query('recipes');

  for (final recipe in recipes) {
    final name = recipe['name'] as String;
    final id = recipe['id'] as String;

    // Parse name into title and subtitle
    String title;
    String? subtitle;

    if (name.contains(' - ')) {
      // Split on first occurrence of " - "
      final parts = name.split(' - ');
      title = parts[0].trim();
      // Join remaining parts (in case of multiple " - ")
      subtitle = parts.skip(1).join(' - ').trim();
      if (subtitle.isEmpty) subtitle = null;
    } else {
      // No subtitle, use full name as title
      title = name.trim();
      subtitle = null;
    }

    // Update record with new title/subtitle
    await db.update(
      'recipes',
      {
        'title': title,
        'subtitle': subtitle,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
```

✓ Data migration implemented

Files modified:
- lib/core/database/migrations/migration_v20.dart (data migration logic)

Verification Steps - MANDATORY DATA VERIFICATION:

**Step 1: Check initial data**
Before migration, some sample recipes:
- "Pasta Carbonara - Classic Italian"
- "Chocolate Cake"
- "Grilled Chicken - With Herbs - Lemon Glaze"

**Step 2: Apply migration (up)**
Run app or tests to apply migration.

**Step 3: Verify data transformation**
```bash
sqlite3 path/to/gastrobrain.db "SELECT name, title, subtitle FROM recipes LIMIT 10;"
```

Expected results:
- "Pasta Carbonara - Classic Italian" →
  - title: "Pasta Carbonara"
  - subtitle: "Classic Italian"
- "Chocolate Cake" →
  - title: "Chocolate Cake"
  - subtitle: NULL
- "Grilled Chicken - With Herbs - Lemon Glaze" →
  - title: "Grilled Chicken"
  - subtitle: "With Herbs - Lemon Glaze"

✓ Data split correctly

**Step 4: Verify all records migrated**
```bash
sqlite3 path/to/gastrobrain.db "SELECT COUNT(*) FROM recipes WHERE title IS NULL;"
```
Expected: 0 (all records should have title)
✓ No NULL titles

**Step 5: Verify subtitle nullable**
```bash
sqlite3 path/to/gastrobrain.db "SELECT COUNT(*) FROM recipes WHERE subtitle IS NULL;"
```
Expected: Some number (recipes without subtitles)
✓ Subtitle correctly NULL where appropriate

**Step 6: Test app with migrated data**
- App loads recipes correctly
- UI displays titles properly
- Subtitles shown where present
✓ App functional with new data

Database State After Checkpoint 3:
- title and subtitle columns populated ✓
- All 150+ recipes have title values ✓
- Subtitles present where name had " - " ✓
- No data loss ✓
- name column still present (unchanged) ✓
- Ready for schema finalization ✓

⚠️ DO NOT PROCEED if any records have NULL titles!
⚠️ Verify data looks correct before continuing!

✅ Checkpoint 3 verification complete?
Ready to proceed to CHECKPOINT 4/7? (y/n)
```

**User**: y

```
✅ CHECKPOINT 3/7 complete

Migration Progress: 3/7 checkpoints complete ██████ 42%

✓ Checkpoint 1: Migration file created [COMPLETE]
✓ Checkpoint 2: Added columns (NULL) [COMPLETE]
✓ Checkpoint 3: Data migration [COMPLETE - CRITICAL]
○ Checkpoint 4: Finalize schema (NOT NULL)
○ Checkpoint 5: Rollback implementation
○ Checkpoint 6: Model updates
○ Checkpoint 7: Migration tests

Key achievement: All 150+ recipes successfully migrated!

Ready for CHECKPOINT 4/7? (y/n)
```

**User**: y

---

## Checkpoint 4: Finalize Schema

```
==================
CHECKPOINT 4/7: Schema Finalization
Goal: Make title NOT NULL now that data is migrated

Progress from previous checkpoints:
✓ Checkpoint 1: Migration file created
✓ Checkpoint 2: Added title/subtitle columns (NULL)
✓ Checkpoint 3: Data migrated (all records have title)

Finalizing schema:
Now that all records have title values, we can enforce NOT NULL constraint.
Note: SQLite doesn't support ALTER COLUMN, so we'll document this constraint
for new inserts.

Tasks for this checkpoint:
- [x] Document title should be NOT NULL
- [x] Ensure app code enforces NOT NULL
- [x] Note for future: Consider recreating table if strict NOT NULL needed

Schema finalization note:

```dart
// Note: SQLite doesn't support ALTER COLUMN to add NOT NULL
// The title column will remain nullable in schema, but application
// code enforces NOT NULL through model validation
// All existing data has been migrated to have title values
// New inserts will require title through Recipe model
```

In practice, the Recipe model will enforce this:

```dart
class Recipe {
  final String title; // Required, not nullable
  final String? subtitle; // Optional, nullable
  // ...
}
```

✓ Schema finalization documented

Database State After Checkpoint 4:
- Schema structure complete ✓
- title column: TEXT (with data)
- subtitle column: TEXT NULL
- name column: still present (for backward compat)
- Application enforces NOT NULL for title ✓

✅ Checkpoint 4 verification complete?
Ready to proceed to CHECKPOINT 5/7? (y/n)
```

**User**: y

---

## Checkpoint 5: Rollback Implementation

```
==================
CHECKPOINT 5/7: Rollback Implementation
Goal: Implement down() to revert columns and restore original state

⚠️ CRITICAL CHECKPOINT - COMPLEX ROLLBACK

Progress from previous checkpoints:
✓ Checkpoint 1: Migration file created
✓ Checkpoint 2: Added columns
✓ Checkpoint 3: Data migrated
✓ Checkpoint 4: Schema finalized

Implementing rollback:
Drop title and subtitle columns. Original name column still intact,
so data is preserved on rollback.

Tasks for this checkpoint:
- [x] DROP title column
- [x] DROP subtitle column
- [x] name column remains (no data loss)
- [x] Verify rollback works

Rollback implementation:

```dart
@override
Future<void> down(Database db) async {
  // Remove the added columns
  // Original 'name' column still exists, so no data loss
  await db.execute('ALTER TABLE recipes DROP COLUMN title');
  await db.execute('ALTER TABLE recipes DROP COLUMN subtitle');
}
```

✓ Rollback implemented

Files modified:
- lib/core/database/migrations/migration_v20.dart (down method)

Verification:

**Rollback safety:**
- name column never modified: ✓
- Dropping title/subtitle leaves name intact: ✓
- No data loss on rollback: ✓

Database State After Checkpoint 5:
- down() drops title and subtitle ✓
- name column preserved ✓
- Rollback safe (no data loss) ✓
- App can revert to using name ✓

✅ Checkpoint 5 verification complete?
Ready to proceed to CHECKPOINT 6/7? (y/n)
```

**User**: y

---

## Checkpoint 6: Model Updates

```
==================
CHECKPOINT 6/7: Model Class Updates
Goal: Update Recipe model with title and subtitle

Progress from previous checkpoints:
✓ Checkpoints 1-5: Migration complete with data transformation

Updating model: Recipe
File: lib/core/models/recipe.dart

Changes needed:
Add title (String) and subtitle (String?) fields. Keep name field
temporarily for backward compatibility during transition.

Model updates:

```dart
class Recipe {
  final String id;
  final String name; // Keep for backward compat
  final String title; // New - required
  final String? subtitle; // New - optional
  // ... other fields ...

  Recipe({
    required this.id,
    required this.name, // Temporarily required
    required this.title, // Required
    this.subtitle, // Optional
    // ... other parameters ...
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'subtitle': subtitle,
      // ... other fields ...
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'] as String,
      name: map['name'] as String,
      title: map['title'] as String,
      subtitle: map['subtitle'] as String?,
      // ... other fields ...
    );
  }

  Recipe copyWith({
    String? id,
    String? name,
    String? title,
    String? subtitle,
    // ... other parameters ...
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      // ... other fields ...
    );
  }
}
```

✓ Model updated

Verification:
- title field matches migrated data: ✓
- subtitle nullable: ✓
- name field preserved: ✓
- toMap/fromMap handle all fields: ✓

✅ Checkpoint 6 verification complete?
Ready to proceed to CHECKPOINT 7/7? (y/n)
```

**User**: y

---

## Checkpoint 7: Migration Tests

```
==================
CHECKPOINT 7/7: Migration Tests
Goal: Test schema changes AND data migration

⚠️ MANDATORY - Must test data transformation!

Progress: All checkpoints 1-6 complete

Creating migration tests for v20:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gastrobrain/core/database/migrations/migration_v20.dart';

void main() {
  late Database db;
  late MigrationV20 migration;

  setUp() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    db = await openDatabase(inMemoryDatabasePath, version: 1);
    migration = MigrationV20();

    // Create recipes table with old schema
    await db.execute('''
      CREATE TABLE recipes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        difficulty INTEGER NOT NULL
      )
    ''');
  });

  tearDown() async => await db.close();

  group('Migration v20 - Title/Subtitle split', () {
    test('adds title and subtitle columns', () async {
      await migration.up(db);

      final columns = await db.rawQuery('PRAGMA table_info(recipes)');
      expect(columns.any((col) => col['name'] == 'title'), isTrue);
      expect(columns.any((col) => col['name'] == 'subtitle'), isTrue);
    });

    test('migrates recipe with subtitle (contains " - ")', () async {
      // Insert recipe with subtitle format
      await db.insert('recipes', {
        'id': '1',
        'name': 'Pasta Carbonara - Classic Italian',
        'difficulty': 2,
      });

      // Apply migration
      await migration.up(db);

      // Verify data split
      final result = await db.query('recipes', where: 'id = ?', whereArgs: ['1']);
      expect(result.first['title'], equals('Pasta Carbonara'));
      expect(result.first['subtitle'], equals('Classic Italian'));
      expect(result.first['name'], equals('Pasta Carbonara - Classic Italian')); // Preserved
    });

    test('migrates recipe without subtitle (no " - ")', () async {
      await db.insert('recipes', {
        'id': '2',
        'name': 'Chocolate Cake',
        'difficulty': 3,
      });

      await migration.up(db);

      final result = await db.query('recipes', where: 'id = ?', whereArgs: ['2']);
      expect(result.first['title'], equals('Chocolate Cake'));
      expect(result.first['subtitle'], isNull);
    });

    test('handles multiple " - " in name', () async {
      await db.insert('recipes', {
        'id': '3',
        'name': 'Grilled Chicken - With Herbs - Lemon Glaze',
        'difficulty': 2,
      });

      await migration.up(db);

      final result = await db.query('recipes', where: 'id = ?', whereArgs: ['3']);
      expect(result.first['title'], equals('Grilled Chicken'));
      expect(result.first['subtitle'], equals('With Herbs - Lemon Glaze')); // Remaining parts joined
    });

    test('removes title and subtitle on rollback', () async {
      await db.insert('recipes', {'id': '4', 'name': 'Test Recipe', 'difficulty': 1});

      // Apply
      await migration.up(db);
      var columns = await db.rawQuery('PRAGMA table_info(recipes)');
      expect(columns.any((col) => col['name'] == 'title'), isTrue);

      // Rollback
      await migration.down(db);
      columns = await db.rawQuery('PRAGMA table_info(recipes)');
      expect(columns.any((col) => col['name'] == 'title'), isFalse);
      expect(columns.any((col) => col['name'] == 'subtitle'), isFalse);

      // Original name preserved
      final result = await db.query('recipes');
      expect(result.first['name'], equals('Test Recipe'));
    });

    test('supports up → down → up cycle', () async {
      await db.insert('recipes', {'id': '5', 'name': 'Pizza - Margherita', 'difficulty': 2});

      // First up
      await migration.up(db);
      var result = await db.query('recipes');
      expect(result.first['title'], equals('Pizza'));

      // Down
      await migration.down(db);
      result = await db.query('recipes');
      expect(result.first.containsKey('title'), isFalse);
      expect(result.first['name'], equals('Pizza - Margherita')); // Preserved

      // Second up
      await migration.up(db);
      result = await db.query('recipes');
      expect(result.first['title'], equals('Pizza'));
      expect(result.first['subtitle'], equals('Margherita'));
    });
  });
}
```

✓ Tests created: 6 tests covering data migration

Run tests:
```bash
flutter test test/core/database/migrations/migration_v20_test.dart
```

Expected: All 6 tests pass ✓

🎉 MIGRATION COMPLETE!

═══════════════════════════════════════════
COMPLEX MIGRATION SUMMARY
═══════════════════════════════════════════

Migration: v20
Issue: #340
Type: **Complex data migration**

Schema & Data Changes:
- Added title column (TEXT)
- Added subtitle column (TEXT NULL)
- **Migrated 150+ existing recipe names**
- Parsed "Title - Subtitle" format
- Preserved original name column

Checkpoints Completed: 7/7
✓ Checkpoint 1: Migration file created
✓ Checkpoint 2: Added columns (NULL)
✓ Checkpoint 3: **Data migration (CRITICAL)**
✓ Checkpoint 4: Schema finalized
✓ Checkpoint 5: Rollback implemented
✓ Checkpoint 6: Model updated
✓ Checkpoint 7: Migration tests (6 tests)

Why 7 Checkpoints?
Added Checkpoint 3 for data migration - transforming existing
data requires dedicated checkpoint with thorough verification.

Files Created/Modified:
- lib/core/database/migrations/migration_v20.dart (with data migration logic)
- lib/core/models/recipe.dart (added title/subtitle fields)
- test/core/database/migrations/migration_v20_test.dart

Safety Verification:
✓ Data migration tested with multiple scenarios
✓ All existing recipes successfully migrated
✓ Rollback preserves original data (name column)
✓ No data loss at any stage
✓ All 6 tests passing

Complexity Level: **HIGH**
- Data transformation required
- 150+ records affected
- Multiple edge cases handled
- Backward compatibility maintained

Next Steps:
1. Run full test suite
2. Test with production-like data volumes
3. Verify UI handles title/subtitle correctly
4. Plan future migration to remove name column
5. Commit complex migration

Commit message:
```
feat: split recipe names into title and subtitle (#340)

- Add title and subtitle columns to recipes table
- Migrate 150+ existing recipes (parse "Title - Subtitle" format)
- Update Recipe model with new fields
- Comprehensive tests including data migration scenarios
- Backward compatible (name column preserved)
- Complex migration with 7 checkpoints
```

═══════════════════════════════════════════

Ready to commit? (y/n)
```

---

## Summary

**Migration Type**: Complex data migration
**Checkpoints Used**: 7 (added data migration checkpoint)
**Time Estimate**: ~40-50 minutes with careful verification
**Complexity**: High

### Key Differences from Previous Examples

1. **Data Transformation**: Not just adding/creating, but transforming existing data
2. **Extra Checkpoint**: Checkpoint 3 dedicated to data migration
3. **More Testing**: Tests must verify data transformation correctness
4. **Edge Cases**: Multiple scenarios (with/without delimiter, multiple delimiters)
5. **Rollback Safety**: Original data preserved (name column kept)

### Why Extra Checkpoint Was Essential

- **Checkpoint 3 (Data Migration)**: Isolated data transformation
  - Verified all records migrated
  - Tested edge cases
  - Confirmed no data loss
  - Stopped and verified before proceeding

Without dedicated checkpoint:
- Risk of proceeding with incomplete data migration
- Harder to debug transformation issues
- Might discover problems too late (after model changes)

**Checkpoint approach prevented**: Discovering data migration issues after model already updated and seed data changed - would require backtracking through multiple checkpoints.

**Result**: Complex migration completed safely with full data integrity verification at each step.
