# Issue #198 Roadmap — Add Aliases Field to Ingredients

**Branch:** `feature/198-ingredient-aliases`
**Milestone:** 0.2.4 - Recipe Enhancement
**Labels:** enhancement, model, P1-High

---

## Phase 1: Analysis & Understanding ✅ COMPLETE

### Requirements Summary

Add an `aliases: List<String>` field to `Ingredient` so recipe parsers can find
ingredients by alternative names (e.g. "aipo" → "salsão"). Aliases are stored
as a JSON array in SQLite, matched with 0.95 confidence (alias stage), and
managed via the existing `AddNewIngredientDialog` form.

### Technical Design Decision

**Selected Approach:** JSON column + migration runner stage 2

**Rationale:**
- Single new `TEXT` column, zero new tables — minimal blast radius
- `ALTER TABLE ADD COLUMN` in SQLite is O(1) — safe on large databases
- Migration runner v2 handles both fresh installs and upgrades consistently
- `fromMap` null-guard ensures backward compat with existing rows

**Alternatives Considered:**
- Separate `ingredient_aliases` table: rejected — adds join complexity for a simple list

### Dual-Versioning Note

The database has two versioning layers:
- SQLite `user_version` (currently 18) — controlled by `openDatabase`
- Migration runner (currently v1) — controlled by `schema_migrations` table

The new migration must go into the **migration runner only** (version 2).
No changes needed to `_onCreate` or `001_initial_schema.dart`.

### Patterns to Follow

| Pattern | Location |
|---|---|
| Migration structure (up/down/validate) | `lib/core/migration/migrations/001_initial_schema.dart` |
| JSON field in model (toMap/fromMap) | `lib/models/ingredient.dart` — `notes` field as reference |
| Multi-stage matching pipeline | `ingredient_matching_service.dart` lines 36–97 |
| Dialog text controller + dispose | `lib/widgets/add_new_ingredient_dialog.dart` |

### Edge Cases Identified

| Edge Case | Handling Strategy |
|---|---|
| `aliases` column NULL (existing rows) | `fromMap` null-check → fallback `[]` |
| Malformed JSON in column | try-catch in `fromMap` → fallback `[]` |
| Same alias on two ingredients | Return both as alias matches; `shouldAutoSelect` handles ambiguity |
| Alias matches another ingredient's primary name | Exact match (1.0) wins; alias stage (0.95) never reached |
| Whitespace in user input | `split(',').map(trim).where(isNotEmpty)` |
| Empty aliases list | Skip alias stage entirely in matching service |

### Risk Assessment

| Risk | Level | Mitigation |
|---|---|---|
| `ALTER TABLE` on large DB | 🟢 LOW | SQLite ADD COLUMN is O(1) |
| Migration v2 on fresh install | 🟢 LOW | ALTER TABLE succeeds even after `_onCreate` |
| JSON decode on null | 🟡 MED | Null-guard + try-catch in `fromMap` |
| Service file grows past 550 lines | 🟡 MED | Accept for now; tracked in refactoring-backlog.md |

---

## Phase 2: Implementation

### Checklist

- [ ] **Step 1 — Migration file**
  - Create `lib/core/migration/migrations/002_add_ingredient_aliases.dart`
  - `up()`: `ALTER TABLE ingredients ADD COLUMN aliases TEXT`
  - `down()`: recreate table without column (SQLite DROP COLUMN compat)
  - `validate()`: check `pragma_table_info` for 'aliases' column
  - `requiresBackup = false`

- [ ] **Step 2 — Register migration**
  - `lib/database/database_helper.dart` → add `AddIngredientAliasesMigration()` to `_migrations`

- [ ] **Step 3 — Ingredient model**
  - `lib/models/ingredient.dart`
  - Add `import 'dart:convert'`
  - Add `List<String> aliases` field (default `const []`)
  - `toMap()`: encode as `jsonEncode(aliases)` (null when empty)
  - `fromMap()`: null-guard + try-catch decode

- [ ] **Step 4 — MatchType enum**
  - `lib/models/ingredient_match.dart`
  - Add `alias` to `MatchType` enum

- [ ] **Step 5 — Alias matching stage**
  - `lib/core/services/ingredient_matching_service.dart`
  - Add `_findAliasMatches(String parsedName)` private method (Stage 1.5)
  - Insert between Stage 1 (exact) and Stage 2 (caseInsensitive)
  - Confidence: 0.95, MatchType.alias
  - Normalizes both alias and parsed name before comparing
  - Returns all matching ingredients (handles ambiguous aliases)

- [ ] **Step 6 — Localization**
  - `lib/l10n/app_en.arb`: add `ingredientAliasesLabel`, `ingredientAliasesHint`
  - `lib/l10n/app_pt.arb`: add same keys in Portuguese
  - Run `flutter gen-l10n`

- [ ] **Step 7 — Dialog UI**
  - `lib/widgets/add_new_ingredient_dialog.dart`
  - Add `_aliasesController` TextEditingController
  - Pre-populate from `widget.ingredient?.aliases.join(', ')`
  - Parse on save: `split(',').map(trim).where(isNotEmpty).toList()`
  - Pass `aliases` to `Ingredient(...)` constructor
  - Dispose controller in `dispose()`
  - Add `TextFormField` with `ingredientAliasesLabel` + `ingredientAliasesHint`

- [ ] **Step 8 — Detail screen display**
  - `lib/screens/ingredient_detail_screen.dart`
  - Display aliases as a `Wrap` of `Chip` widgets in body header
  - Only show if `widget.ingredient.aliases.isNotEmpty`

---

## Phase 3: Testing

### Checklist

**Model tests** (`test/models/ingredient_test.dart`):
- [ ] `aliases` defaults to `[]` when not provided
- [ ] `toMap()` encodes non-empty aliases as JSON string
- [ ] `toMap()` stores `null` when aliases is empty
- [ ] `fromMap()` decodes JSON string back to `List<String>`
- [ ] `fromMap()` handles `null` aliases column (existing DB rows)
- [ ] `fromMap()` handles malformed JSON gracefully (returns `[]`)
- [ ] Round-trip `toMap` → `fromMap` preserves aliases

**Matching service tests** (`test/core/services/ingredient_matching_service_test.dart`):
- [ ] Alias match found, MatchType == alias
- [ ] Alias match confidence is 0.95
- [ ] Exact name match (1.0) wins over alias match (0.95)
- [ ] Two ingredients with same alias both returned as matches
- [ ] Case-insensitive alias match ("AIPO" finds alias "aipo")
- [ ] Ingredient with no aliases: alias stage does not produce matches

**Widget tests** (`test/widgets/add_new_ingredient_dialog_test.dart`):
- [ ] Aliases field visible in dialog
- [ ] Existing aliases pre-populated in edit mode (joined with ", ")
- [ ] Comma-separated input correctly parsed and saved
- [ ] Whitespace trimmed from aliases

**DB integration tests** (`test/database/database_helper_ingredient_test.dart`):
- [ ] Stores and retrieves ingredient with aliases
- [ ] Handles empty aliases list
- [ ] Handles NULL aliases column (legacy rows)

---

## Phase 4: Review & Documentation

- [ ] Run `flutter test && flutter analyze`
- [ ] Verify migration runs cleanly on fresh DB
- [ ] Verify matching service unit tests pass
- [ ] Merge to develop

---

*Phase 1 analysis completed: 2026-04-22*
*Ready for Phase 2 implementation*
