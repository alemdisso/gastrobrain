# Issue #216 Roadmap: Import Tools (Recipes & Ingredients with Merge Logic)

**Milestone**: 0.2.8 — Range Quantities + Import  
**Estimate**: 8 pts | **Size**: L | **Priority**: P2  
**Issue**: [#216 — Add import tools and reorganize data management in Tools tab](https://github.com/alemdisso/gastrobrain/issues/216)

---

## Phase 1: Analysis & Understanding ✅ COMPLETE

### Requirements Summary

Add granular import for recipes and ingredients from JSON files, using a global duplicate-handling strategy (skip / replace / add-as-new). Before import can be built, the export format must be updated to include tags (added by #324–#335) and `quantity_max` (added by #358), both of which post-date the original issue. The existing `RecipeImportService` exists but implements a destructive "replace all" strategy and must be fully rewritten. `IngredientImportService` is net new.

### Technical Design Decision

**Selected Approach**: Global duplicate strategy — one choice per import run applied uniformly to all collisions.

**Rationale**:
- Bulk import tools work with global strategies (CSV import, app stores, etc.)
- Per-item resolution doesn't scale for 50+ recipe collections
- "Add as new" covers the edge case of wanting selective preservation
- Simpler implementation, less state management, more predictable UX

**Alternatives Considered**:
- Per-item conflict resolution: rejected — unusable at scale, doubles complexity

### Tag Handling Decision

Tags are exported as `[{"type": "cuisine", "name": "Italian"}]` (name+type, not ID). On import, use `TagRepository.getOrCreateTag()` (case-insensitive lookup, creates if missing). No UUID changes to the tag schema — name+type is the correct natural key for cross-device identity. UUID consideration deferred to v0.3.0 recipe sharing.

### Export Format Gap (fixed in this issue)

The existing export (`recipe_export_service.dart`) is missing:
- `tags` array entirely (post-dates the export service)
- `quantity_max` in ingredient entries (added in #358)
- `servings` in metadata
- `export_version` field (needed for backward compat)

All four are added as part of Step 1.

### Patterns to Follow

| Pattern | Location | Usage |
|---------|----------|-------|
| File picker + SAF bytes fallback | `tools_screen._restoreDatabase()` lines 234–311 | File picking with Android 10+ compat |
| Transaction pattern | existing `RecipeImportService` | `db.transaction((txn) async {...})` |
| TagRepository.getOrCreateTag | `tag_repository.dart:95` | Idempotent tag lookup/create |
| Result object | `RecipeImportResult` (end of recipe_import_service.dart) | Extend with added/updated/skipped/warnings |
| DI singleton pattern | `export_provider.dart` | Register new `ingredientImport` slot |

### Edge Cases Identified

| Edge Case | Handling Strategy |
|-----------|-------------------|
| v1 export (no tags, no quantity_max) | `export_version` absent → treat tags as `[]`, `quantity_max` as null |
| Unknown tag type in import | Skip that tag, add warning to result — don't block import |
| "Add as new" on already-suffixed name | Append " (imported)" once; acceptable duplication if re-imported |
| Empty JSON / empty array | Show "No records found in this file" before strategy dialog |
| Wrong-schema file (ingredient file used for recipe import) | `validateExportStructure` fails → clear error message |
| Ingredient ID mismatch across devices | Ingredients embedded in `current_ingredients` are created fresh |
| Replace strategy: old tags must be cleared | `setTagsForRecipeTxn()` does DELETE then INSERT atomically |

### Risk Assessment

| Risk | Level | Mitigation |
|------|-------|------------|
| TagRepository not txn-aware | High | Add `getOrCreateTagTxn()` + `setTagsForRecipeTxn()` in Step 2 |
| tools_screen.dart already 1000 lines | High | Logged in refactoring backlog; extract to widgets post-#216 |
| SAF scoped storage (Android 10+) | Medium | Use bytes fallback — pattern already in `_restoreDatabase()` |
| "Add as new" ID collision | Low | Generate fresh UUID via `IdGenerator` |

### Testing Requirements

**Unit Tests (RecipeImportService)**:
- [ ] Skip strategy: existing recipe unchanged
- [ ] Replace strategy: fields + tags updated
- [ ] Add-as-new strategy: second copy with " (imported)" suffix
- [ ] Tags restored on import
- [ ] `quantity_max` preserved through round-trip
- [ ] v1 export (no tags) imports without error
- [ ] Transaction rolled back on DB error
- [ ] Result counts (added / updated / skipped) correct

**Unit Tests (IngredientImportService)**:
- [ ] All 3 strategies produce correct state
- [ ] Result counts correct

**Unit Tests (RecipeExportService)**:
- [ ] Tags array present and correct in exported JSON
- [ ] `quantity_max` exported when present, null when absent
- [ ] `servings` included in metadata

**Edge Case Tests**:
- [ ] Empty file → "No records found", no crash
- [ ] Wrong-schema file → validation error
- [ ] v1 export → imports cleanly, recipe has no tags
- [ ] Unknown tag type → warning in summary, import proceeds

---

## Phase 2: Implementation

### Implementation Checklist

- [x] **Step 1**: Fix export — add tags, `quantity_max`, `servings`, `export_version` to `recipe_export_service.dart`
- [x] **Step 2**: Add txn-aware helpers to `tag_repository.dart` (`getOrCreateTagTxn`, `setTagsForRecipeTxn`)
- [x] **Step 3**: Rewrite `recipe_import_service.dart` — merge mode, `DuplicateStrategy` enum, tag restoration, two-phase API (`previewImport` + `executeImport`)
- [x] **Step 4**: Create `ingredient_import_service.dart` — same pattern, simpler (no tags)
- [x] **Step 5**: Update `export_provider.dart` — add `ingredientImport` slot, update `recipeImport` to pass `TagRepository`
- [x] **Step 6**: Update `tools_screen.dart` — file picker flow, strategy dialog, ingredient import entry point, updated summary dialog
- [x] **Step 7**: Localization — ~14 strings in `app_en.arb` + `app_pt.arb`, run `flutter gen-l10n`

### Files to Create
- `lib/core/services/ingredient_import_service.dart`
- `test/core/services/recipe_import_service_merge_test.dart`
- `test/core/services/ingredient_import_service_test.dart`
- `test/core/services/recipe_export_service_tags_test.dart`

### Files to Modify
- `lib/core/services/recipe_export_service.dart`
- `lib/core/services/recipe_import_service.dart` (full rewrite)
- `lib/core/repositories/tag_repository.dart`
- `lib/core/di/providers/export_provider.dart`
- `lib/screens/tools_screen.dart`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_pt.arb`

### New Export JSON Format (v2)

```json
{
  "export_version": 2,
  "recipe_id": "...",
  "name": "Frango Assado",
  "instructions": "...",
  "current_ingredients": [
    {
      "ingredient_id": "...",
      "name": "Garlic",
      "quantity": 2.0,
      "quantity_max": 3.0,
      "unit": "clove",
      "category": "vegetable",
      "protein_type": null,
      "preparation_notes": "minced"
    }
  ],
  "enhanced_ingredients": [],
  "metadata": {
    "difficulty": 2,
    "prep_time_minutes": 20,
    "cook_time_minutes": 60,
    "marinating_time_minutes": 0,
    "rating": 4,
    "servings": 4,
    "desired_frequency": "weekly",
    "notes": "",
    "created_at": "2025-01-01T00:00:00.000"
  },
  "cooking_history": {
    "times_cooked": 3,
    "last_cooked_date": "2025-03-15T00:00:00.000"
  },
  "tags": [
    {"type": "cuisine", "name": "Portuguese"},
    {"type": "meal_role", "name": "main dish"}
  ]
}
```

### New Localization Strings

```json
"importDuplicatesTitle": "Duplicates Found",
"importDuplicatesMessage": "{count} {count, plural, =1{item already exists} other{items already exist}} in your library.",
"importStrategySkip": "Keep Existing",
"importStrategyReplace": "Use Imported",
"importStrategyAddAsNew": "Add as New",
"importEmptyFile": "No records found in this file.",
"importRecipesTitle": "Import Recipes",
"importIngredientsTitle": "Import Ingredients",
"importResultAdded": "Added",
"importResultUpdated": "Updated",
"importResultSkipped": "Skipped",
"importResultWarnings": "Warnings",
"importIngredients": "Import Ingredients",
"importIngredientsDescription": "Import ingredients from a JSON file exported by Gastrobrain."
```

---

## Phase 3: Testing

- [ ] Run `flutter test test/core/services/recipe_import_service_merge_test.dart`
- [ ] Run `flutter test test/core/services/ingredient_import_service_test.dart`
- [ ] Run `flutter test test/core/services/recipe_export_service_tags_test.dart`
- [ ] Run full suite: `flutter test`
- [ ] Manual round-trip: export recipes → import with each strategy → verify

---

## Phase 4: Documentation & Completion

- [ ] `flutter analyze` passes
- [ ] Merge to `develop`
- [ ] Commit message includes `Closes #216`

---

*Phase 1 analysis completed on 2026-05-13*  
*Ready for Phase 2 implementation*
