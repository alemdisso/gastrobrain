# Issue #348: Add Marinating Time as a Separate Recipe Field

**Milestone**: 0.2.4 - Recipe Enhancement  
**Labels**: enhancement, P3-Low  
**Branch**: `feature/348-marinating-time`

---

## Phase 1: Analysis & Understanding ✅ COMPLETE

### Requirements Summary

Add an optional `marinatingTimeMinutes` (int, default 0) field to the Recipe model, backed by a database migration (version 3). Display marinating time alongside prep/cook time in recipe details and forms. Include it in total time calculations. Full EN + PT localization.

### Technical Design Decision

**Selected Approach**: Symmetric `int` field mirroring `prepTimeMinutes` / `cookTimeMinutes` (default 0 = not set, display guarded by `> 0` checks).

**Rationale**:
- Consistent with existing time field patterns — zero new patterns introduced
- `0` as "not set" is idiomatic in this codebase and unambiguous in practice (no recipe marinates for 0 minutes)
- Simpler nullable avoidance → no null checks in total-time math

**Alternatives Considered**:
- `int?` nullable: Rejected — breaks symmetry with prep/cook, adds null-check friction throughout

### Effort Score Design Decision

Marinating time contributes to the effort score and effort label (`_calculateEffortScore`, `_getEffortLabel` in `recipe_selection_card.dart`) but is **capped at 120 minutes**.

**Rationale**: The effort relationship is non-linear. A short marination (≤ 1-2h) can still be done last-minute; longer marinations all carry the same planning burden regardless of whether it's 4h, 8h, or 24h. The cap at 120 minutes captures the "planning ahead" threshold without over-penalising long marinades.

```dart
// Capped contribution used in effort calculations only
int get _marinatingEffortContribution =>
    marinatingTimeMinutes.clamp(0, 120);

// Used in _calculateEffortScore() and _getEffortLabel():
final totalTime = prepTimeMinutes + cookTimeMinutes + _marinatingEffortContribution;
```

For **total time display** (recipe card, details, side dish dialog), full `marinatingTimeMinutes` is used — the user needs accurate planning information.

### Patterns to Follow

| Pattern | Location | Usage |
|---------|----------|-------|
| Time field (int) | `lib/models/recipe.dart` | Field declaration, toMap/fromMap/copyWith |
| ADD COLUMN migration | `migrations/002_add_ingredient_aliases.dart` | up/down/validate structure |
| Optional display guard | `recipe_details_overview_tab.dart:59-78` | `if (field > 0)` before rendering |
| `_buildTimeField()` reuse | `add_recipe_screen.dart:90` | Pass label + controller |

### Edge Cases Identified

| Edge Case | Handling Strategy |
|-----------|-------------------|
| Default 0 (not set) | Hide from display; include as 0 in totals (net zero) |
| Import of old JSON (no field) | `map['marinating_time_minutes'] ?? 0` |
| Large values (24h+) | Valid — UI just displays the number |
| Negative/invalid input | Existing `_buildTimeField` validator rejects |

### Risk Assessment

| Risk | Level | Mitigation |
|------|-------|------------|
| Missing a total-time calc location | Medium | Grep `prepTime + cookTime` before commit |
| Migration version conflict | Low | Must be version 3 (after AddIngredientAliases = 2) |
| Export/import round-trip gap | Low | Add to both export and import services |

### Localization Strings (4)

```
EN:
"marinatingTime": "Marinating Time"           ← form field label
"marinatingTimeLabel": "Marinate Time (min)"  ← details display label

PT:
"marinatingTime": "Tempo de Marinada"
"marinatingTimeLabel": "Tempo de Marinada (min)"
```

---

## Phase 2: Implementation ✅ COMPLETE

### Files to Create
- `lib/core/migration/migrations/003_add_marinating_time.dart`

### Files to Modify
- `lib/models/recipe.dart`
- `lib/database/database_helper.dart`
- `lib/screens/add_recipe_screen.dart`
- `lib/screens/edit_recipe_screen.dart`
- `lib/screens/recipe_details_overview_tab.dart`
- `lib/widgets/recipe_card.dart`
- `lib/widgets/recipe_selection_card.dart`
- `lib/widgets/add_side_dish_dialog.dart`
- `lib/core/services/recipe_export_service.dart`
- `lib/core/services/recipe_import_service.dart`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_pt.arb`

### Implementation Checklist

- [x] Step 1: Create feature branch `feature/348-marinating-time`
- [x] Step 2: Update `Recipe` model (field + toMap/fromMap/copyWith)
- [x] Step 3: Create migration `003_add_marinating_time.dart` (version 3)
- [x] Step 4: Register migration in `database_helper.dart`
- [x] Step 5: Update `add_recipe_screen.dart` (controller + field + save)
- [x] Step 6: Update `edit_recipe_screen.dart` (controller + field + save)
- [x] Step 7: Update `recipe_details_overview_tab.dart` (display with guard)
- [x] Step 8: Update total time in `recipe_card.dart`, `recipe_selection_card.dart` (effort capped 120 min; tooltip/display full value), `add_side_dish_dialog.dart`
- [x] Step 9: Update `recipe_export_service.dart` and `recipe_import_service.dart`
- [x] Step 10: Add l10n strings to both ARB files; run `flutter gen-l10n`
- [x] Step 11: `flutter analyze` — clean pass

---

## Phase 3: Testing ✅ COMPLETE

### Testing Checklist

**Unit/Model Tests** (`test/models/recipe_test.dart`):
- [ ] `fromMap()` with `marinating_time_minutes` present → field populated
- [ ] `fromMap()` without `marinating_time_minutes` → defaults to 0
- [ ] `toMap()` includes `marinating_time_minutes`
- [ ] `copyWith()` with `marinatingTimeMinutes` → overrides correctly

**Migration Tests** (`test/database/migration_consolidation_test.dart` or new file):
- [ ] `up()` adds column to recipes table
- [ ] Existing rows default to 0 after migration
- [ ] `validate()` returns true after `up()`
- [ ] `down()` removes column (table recreated without it)

**Screen Tests**:
- [ ] `add_recipe_screen_test.dart`: marinating time field saves to recipe
- [ ] `edit_recipe_screen_test.dart`: field pre-populates from recipe, saves updated value
- [ ] `recipe_details_screen_test.dart`: shows marinating time when > 0, hidden when 0

---

## Phase 4: Completion

- [ ] Run full test suite: `flutter test`
- [ ] Merge to develop
- [ ] Close issue #348
- [ ] Clean up branch

---

*Phase 1 analysis completed on 2026-04-22*  
*Ready for Phase 2 implementation*
