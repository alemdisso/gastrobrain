# Issue #324: Recipe Tagging System

**Milestone**: 0.2.5 - Tagging & Filtering  
**Labels**: enhancement, P2-Medium  
**Size**: L (8 pts)  
**Branch**: `feature/324-recipe-tagging-system`

---

## Phase 1: Analysis & Understanding ✅ COMPLETE

### Requirements Summary

Add a typed tagging system to recipes. Tags belong to `TagType` categories (e.g. Cuisine, Occasion, Dietary); each type controls whether it uses hard-filter AND logic (`is_hard`) and whether users can invent new tags (`is_open`). The recipe editor gains a tag section (add + edit screens). Recipe detail view shows tags. The recipes list gains a filter dialog that filters by tag. No changes to the `Recipe` model class itself — tags are fetched separately via `TagRepository`.

### Technical Design Decisions

**Decision 1 — Data access: TagRepository (not DatabaseHelper extension)**  
`DatabaseHelper` is already 2375 lines (🔴 Critical). A dedicated `TagRepository` follows the existing `RecipeRepository` pattern and keeps the data layer clean.

**Decision 2 — Filter query: EXISTS subquery**  
`getRecipesWithSortAndFilter()` in `DatabaseHelper` is extended with one EXISTS clause per active tag filter:
```sql
EXISTS (
  SELECT 1 FROM recipe_tags rt
  JOIN tags t ON t.id = rt.tag_id
  WHERE rt.recipe_id = recipes.id
    AND t.type_id = ?
    AND t.name = ?
)
```
Hard-filter types use AND semantics (each clause added); soft types use OR (any match).

**Decision 3 — TagPickerWidget: mode-switching widget**  
Closed mode: read-only chip grid. Open mode: search field + chip grid + "Create 'X'" option (for `is_open` types only). Mirrors the `IngredientDuplicateChecker` pattern for duplicate detection.

**Alternatives Considered**:
- Adding tags to DatabaseHelper: Rejected — already Critical size, SRP violation
- OR semantics for all tag types: Rejected — hard tags (Dietary) must be AND (vegan AND gluten-free means both required)
- `FROM pragma_table_info()` table-valued function: Rejected — requires SQLite 3.16+; use `PRAGMA table_info()` rawQuery instead

### Data Model

**Tables added by Migration 005:**

```sql
CREATE TABLE tag_types (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  is_hard INTEGER NOT NULL DEFAULT 0,   -- 1 = AND filter logic
  is_open INTEGER NOT NULL DEFAULT 1    -- 1 = user can create new tags
);

CREATE TABLE tags (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  type_id TEXT NOT NULL REFERENCES tag_types(id)
);

CREATE TABLE recipe_tags (
  recipe_id TEXT NOT NULL REFERENCES recipes(id),
  tag_id TEXT NOT NULL REFERENCES tags(id),
  PRIMARY KEY (recipe_id, tag_id)
);
```

**Seed data:**
- TagType `cuisine` — is_hard=0, is_open=1 (user-created vocabulary)
- TagType `occasion` — is_hard=0, is_open=1
- TagType `dietary` — is_hard=1, is_open=0 (closed vocabulary; fixed tags below)
  - Tags: `vegetarian`, `vegan`, `gluten-free`, `dairy-free`

### Patterns to Follow

| Pattern | Location | Usage |
|---------|----------|-------|
| Repository | `lib/core/repositories/recipe_repository.dart` | TagRepository structure |
| DuplicateChecker | `lib/core/services/ingredient_duplicate_checker.dart` | TagDuplicateChecker exact+prefix matching |
| ADD COLUMN migration | `migrations/003_add_marinating_time.dart` | Idempotent up(), PRAGMA table_info |
| Enum model | `lib/models/frequency_type.dart` | fromString(), getDisplayName() |
| Widget DI | `lib/screens/weekly_plan_screen.dart` | Constructor injection + initState |
| Filter query | `lib/database/database_helper.dart:1884` | getRecipesWithSortAndFilter() extension |

### Edge Cases Identified

| Edge Case | Handling Strategy |
|-----------|-------------------|
| Recipe with no tags | Empty chip grid, "No tags yet" placeholder |
| Search returns nothing (open type) | Show "Create 'X'" option |
| Exact duplicate tag name | `TagDuplicateChecker` shows warning, prevent creation |
| Similar tag name (prefix match) | Show suggestion with existing tag |
| Delete tag type that has tags | Block — validate no child tags before delete |
| Closed type vocabulary (dietary) | Hide "Create" option; search within fixed set only |
| AND filter with no matching recipes | Empty state, normal empty-list UX |
| Tag name with diacritics | Normalize same as `IngredientDuplicateChecker` |
| Migration 005 on existing DB | Idempotent: check table existence before CREATE |

### Risk Assessment

| Risk | Level | Mitigation |
|------|-------|------------|
| DatabaseHelper size growth | 🟡 Medium | Add only the EXISTS WHERE clause; no new methods in DatabaseHelper |
| TagPickerWidget complexity | 🟡 Medium | Keep mode-switching simple; no animation required |
| AND/OR filter semantics bug | 🟡 Medium | Write explicit tests for multi-tag hard+soft scenarios |
| Migration 005 version gap | 🟢 Low | Verify latest migration is 004 before numbering |
| Seed data duplication on re-run | 🟢 Low | Use INSERT OR IGNORE; idempotent up() checks table existence |

### Testing Requirements

**Unit Tests:**
- [ ] `TagType.fromMap()` / `toMap()` round-trip
- [ ] `Tag.fromMap()` / `toMap()` round-trip
- [ ] `TagDuplicateChecker.check()` — exact match, prefix match, no match, diacritics
- [ ] `TagRepository.getOrCreateTag()` — existing tag returned, new tag created for open type
- [ ] `TagRepository.addTagToRecipe()` / `removeTagFromRecipe()` — idempotent

**Widget Tests:**
- [ ] `TagPickerWidget` closed mode shows existing chips
- [ ] `TagPickerWidget` open mode shows search + create option
- [ ] `TagPickerWidget` closed type hides "Create" option

**Integration Tests:**
- [ ] `getRecipesWithSortAndFilter()` with tag filter returns only matching recipes
- [ ] AND logic: dietary=vegan + dietary=gluten-free returns recipes with both tags

**Migration Tests:**
- [ ] Migration 005 up() creates all three tables + seed data
- [ ] Migration 005 up() is idempotent (safe to run twice)
- [ ] Migration 005 validate() returns true after up()
- [ ] Migration 005 down() drops tables cleanly

### Localization Inventory (~10 strings)

```
tags / "Tags" / "Etiquetas"
addTag / "Add tag" / "Adicionar etiqueta"
createTagNamed / "Create '{name}'" / "Criar '{name}'"
filterByTags / "Filter by tags" / "Filtrar por etiquetas"
noTagsAdded / "No tags added yet" / "Sem etiquetas"
filterOptions / "Filter Options" / "Opções de Filtro"
clearFilters / "Clear Filters" / "Limpar Filtros"
tagTypeCuisine / "Cuisine" / "Culinária"
tagTypeOccasion / "Occasion" / "Ocasião"
tagTypeDietary / "Dietary" / "Dietético"
```

---

## Phase 2: Implementation ✅ COMPLETE

### Files to Create

- `lib/core/migration/migrations/005_add_tags.dart`
- `lib/models/tag_type.dart`
- `lib/models/tag.dart`
- `lib/core/repositories/tag_repository.dart`
- `lib/core/services/tag_duplicate_checker.dart`
- `lib/widgets/tag_picker_widget.dart`
- `lib/widgets/recipe_filter_dialog.dart`

### Files to Modify

- `lib/database/database_helper.dart` — register migration 005; add tag EXISTS clause to `getRecipesWithSortAndFilter()`
- `lib/core/providers/recipe_provider.dart` — extend `setFilters()` / `clearFilters()` with `tagFilters`
- `lib/screens/add_recipe_screen.dart` — add tag section
- `lib/screens/edit_recipe_screen.dart` — add tag section
- `lib/screens/recipe_details_overview_tab.dart` — tag chip display
- `lib/screens/recipes_screen.dart` — wire up `RecipeFilterDialog`
- `lib/l10n/app_en.arb` — 10 strings
- `lib/l10n/app_pt.arb` — 10 strings

### Implementation Checklist

- [x] Step 1: Create feature branch `feature/324-recipe-tagging-system`
- [x] Step 2: Migration 005 — create tag_types, tags, recipe_tags tables + seed data
- [x] Step 3: Register migration 005 in DatabaseHelper
- [x] Step 4: `TagType` model (toMap/fromMap)
- [x] Step 5: `Tag` model (toMap/fromMap)
- [x] Step 6: `TagRepository` (getAllTagTypes, getTagsByType, getTagsForRecipe, addTagToRecipe, removeTagFromRecipe, getOrCreateTag, setTagsForRecipe)
- [x] Step 7: `TagDuplicateChecker` (mirrors IngredientDuplicateChecker pattern)
- [x] Step 8: `TagPickerWidget` (closed + open modes, duplicate check)
- [x] Step 9: Extend `getRecipesWithSortAndFilter()` with EXISTS tag filter
- [x] Step 10: Extend `RecipeProvider` with `tagFilters` support
- [x] Step 11: `RecipeFilterDialog` widget (extracted from recipes_screen + tag filter UI)
- [x] Step 12: Wire `RecipeFilterDialog` into `recipes_screen.dart`
- [x] Step 13: Add tag section to `add_recipe_screen.dart`
- [x] Step 14: Add tag section to `edit_recipe_screen.dart`
- [x] Step 15: Add tag chip row to `recipe_details_overview_tab.dart`
- [x] Step 16: Localization — 4 strings in both ARB files; run `flutter gen-l10n`
- [x] Step 17: `flutter analyze` — clean pass

---

## Phase 3: Testing ✅ COMPLETE

### Testing Checklist

- [x] Unit: TagType model round-trip
- [x] Unit: Tag model round-trip
- [x] Unit: TagDuplicateChecker — exact, prefix, diacritics
- [x] Unit: TagRepository CRUD operations
- [x] Widget: TagPickerWidget closed/open modes
- [x] Integration: tag filter query AND semantics
- [x] Migration: 005 up/validate/down (12 tests in migration_consolidation_test.dart)

---

## Phase 4: Completion

- [x] Run full test suite: `flutter test` — 1869 tests passed
- [ ] Merge to develop
- [ ] Close issue #324
- [ ] Clean up branch

---

*Phase 1 analysis completed on 2026-04-27*  
*Phase 2 implementation completed on 2026-04-27*  
*Phase 3 testing completed on 2026-04-27*
