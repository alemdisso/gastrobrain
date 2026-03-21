Issue #292 — Implementation Roadmap
refactor: consolidate database migrations into baseline and update seed data

Field	Value
Type	Refactor + Bug Fix
Priority	P1
Estimate	8 pts (status: In progress)
Branch	refactor/292-consolidate-migrations-baseline
What the analysis revealed
Before diving into phases, here's what the full migration read-through uncovered — this shapes every step:

_onCreate vs. migration reality gap

The current _onCreate is intentionally incomplete. It relies on the migration runner to fill the gaps after marking version 1 as applied. After consolidation, _onCreate must be self-sufficient. Missing pieces vs. current migrations:

Missing from _onCreate	Source migration
meals.meal_type TEXT	003
recipes.servings INTEGER NOT NULL DEFAULT 4	008
meal_plan_items.planned_servings INTEGER NOT NULL DEFAULT 4	009
meal_plan_item_ingredients table (+ quantity, unit)	010 + 011
meal_ingredients table (+ quantity, unit)	010 + 011
Bug: is_purchased → to_buy INTEGER NOT NULL DEFAULT 1	005
_handleLegacyDatabase after consolidation

Currently marks only version 1. After consolidation that's still correct — version 1 IS the complete schema. The migration runner checks currentVersion >= latestVersion, so:

Scenario 3 (migrated, has 1-11 in schema_migrations): 11 >= 1 → no migrations run ✓
Scenario 2 (legacy, no schema_migrations): marks version 1 → no migrations run ✓
Scenario 1 (fresh install, _onCreate ran): marks version 1 → no migrations run ✓
No logic change needed in _handleLegacyDatabase — just needs the migration version number to stay at 1.

13 tables in the consolidated baseline

recipes, meals, ingredients, recipe_ingredients, meal_plans, meal_plan_items, meal_plan_item_recipes, meal_recipes, recommendation_history, shopping_lists, shopping_list_items, meal_plan_item_ingredients, meal_ingredients

Prerequisites Check
 Verify recipe_export_*.json exists locally on dev machine
 Verify ingredient_export_*.json exists locally on dev machine
 Create feature branch before touching any code:
Phase 1 — Analysis ✅
Already completed during pre-implementation discussion. Key decisions recorded:

Option B: full 001-011 consolidation
Seed data: as-is (incomplete recipes acceptable — curation is #317)
Scenario 2 test: manual on emulator using personal DB with schema_migrations dropped
Phase 2 — Implementation
Step 1: Build conversion tool
 Create tools/convert_export_to_seed.dart
Read recipe_export_*.json → strip cooking history, cooking stats, flatten structure
Read ingredient_export_*.json → strip any app-internal fields
Output assets/recipes.json and assets/ingredients.json in seed format
Handle missing fields gracefully (incomplete recipes are OK — null instructions, empty ingredients)
Print summary: X recipes written, Y ingredients written
 Run: dart run tools/convert_export_to_seed.dart
 Review generated assets/recipes.json and assets/ingredients.json output
 Commit seed files
Step 2: Update 001_initial_schema.dart — consolidated baseline
 Replace up() method with complete 13-table schema:
recipes — add instructions TEXT, servings INTEGER NOT NULL DEFAULT 4
meals — add meal_type TEXT (nullable)
meal_plan_items — add planned_servings INTEGER NOT NULL DEFAULT 4
shopping_list_items — use to_buy INTEGER NOT NULL DEFAULT 1 (NOT is_purchased)
meal_plan_item_ingredients — include quantity REAL NOT NULL DEFAULT 1.0, unit TEXT
meal_ingredients — include quantity REAL NOT NULL DEFAULT 1.0, unit TEXT
All other tables: copy from current _onCreate (already complete)
 Update down() — add DROP for meal_plan_item_ingredients, meal_ingredients
 Update validate() — add all 13 tables to the check list, verify to_buy exists on shopping_list_items
 Update description and class doc comment to reflect "consolidated baseline (001-011)"
Step 3: Fix _onCreate in database_helper.dart
 Add meal_type TEXT to meals table definition
 Add servings INTEGER NOT NULL DEFAULT 4 to recipes table definition
 Add planned_servings INTEGER NOT NULL DEFAULT 4 to meal_plan_items
 Fix line 323: is_purchased INTEGER NOT NULL DEFAULT 0 → to_buy INTEGER NOT NULL DEFAULT 1
 Add meal_plan_item_ingredients CREATE TABLE (with quantity and unit)
 Add meal_ingredients CREATE TABLE (with quantity and unit)
 Keep _onCreate and the new 001_initial_schema.dart in sync — both must produce identical schemas
Step 4: Archive migrations 002-011
 Create directory lib/core/migration/migrations/_archived/
 Move 002_ingredient_enum_conversion.dart → _archived/
 Move 003_add_meal_type.dart → _archived/
 Move 004_add_shopping_list_tables.dart → _archived/
 Move 005_rename_is_purchased_to_to_buy.dart → _archived/
 Move 006_add_meal_plan_modified_at.dart → _archived/
 Move 007_add_cooked_at_columns.dart → _archived/
 Move 008_add_recipe_servings.dart → _archived/
 Move 009_add_planned_servings.dart → _archived/
 Move 010_add_simple_sides_tables.dart → _archived/
 Move 011_add_simple_sides_quantity.dart → _archived/
 Add _archived/README.md — one-liner: "Historical migrations archived after consolidation into 001 (issue #292)"
Step 5: Update migration registry in database_helper.dart
 Remove imports for 002-011 (lines 33-42)
 Update _migrations list — keep only InitialSchemaMigration()
 Run flutter analyze — fix any dead import warnings
Phase 3 — Testing
Scenario 1: Fresh install (must pass)
 Write integration test: test/integration/database/migration_consolidation_test.dart
Set up an empty in-memory database
Call _onCreate directly (or open a new DB)
Assert all 13 tables exist
Assert shopping_list_items has to_buy column, NOT is_purchased
Assert recipes has servings column
Assert meals has meal_type column
Assert meal_plan_items has planned_servings column
Assert meal_plan_item_ingredients and meal_ingredients exist with quantity and unit
Assert seed data imported (recipe count > 0)
Scenario 3: Migrated DB (must pass)
 Write integration test in same file:
Create a DB with schema_migrations table pre-populated with versions 1-11
Open via _initializeMigrationSystem
Assert no new migrations run
Assert all existing data preserved
Run full test suite
 flutter analyze — no issues
 flutter test — all passing
 Confirm no regressions in shopping list, recipe, meal plan tests
Scenario 2: Legacy DB (best effort — manual, on emulator)
 Export personal DB backup
 Open in DB Browser for SQLite → drop schema_migrations table → save as legacy_test.db
 Push to emulator app data directory
 Launch app, check logcat for: "Detected legacy database, marking initial schema as applied..."
 Query schema_migrations — expect exactly 1 row (version 1)
 Navigate through app — no crash, no missing data
Phase 4 — Documentation & Cleanup
 Update docs/planning/sprints/sprint-planning-0.1.14.md sprint log with Day 1 notes
 Final flutter analyze && flutter test
 Commit: refactor: consolidate database migrations into baseline (#292)
 Merge to develop
 Close issue #292
Files to Modify / Create
Modify:

lib/core/migration/migrations/001_initial_schema.dart — consolidated 13-table schema
lib/database/database_helper.dart — fix _onCreate, remove 002-011 from registry
Create:

tools/convert_export_to_seed.dart — local conversion script
lib/core/migration/migrations/_archived/README.md
test/integration/database/migration_consolidation_test.dart
Move (002-011 → _archived/):

10 migration files
Regenerated:

assets/recipes.json
assets/ingredients.json
Risk Notes
_onCreate and 001_initial_schema.dart must be kept in sync — both serve fresh installs through different code paths. After this change, they should produce identical schemas. A mismatch is the most likely source of bugs.
Migration 002 (enum conversion) was a data transform, not a schema change — it updated ingredient category strings. The seed data from the conversion tool will already have normalized enum values (they come from your live DB which already had migration 002 applied), so this is a non-issue.
DB version stays at 18 — no reason to change it.