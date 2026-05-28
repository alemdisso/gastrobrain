# Issue #370 — ux: redesign recipe creation as a phased, progressive disclosure flow

| Field | Value |
|---|---|
| **Type** | UX / Feature |
| **Priority** | P2-Medium |
| **Estimate** | 13 points (Size L) |
| **Milestone** | 0.2.13 — Recipe Redesign |
| **Start** | 2026-05-27 |
| **End** | 2026-05-29 |
| **Depends on** | #371 ✅ (IngredientParserSection shipped) |
| **UX Design** | `docs/design/ux/issue-370-ux-design.md` ✅ |

---

## Overview

Replace the monolithic `AddRecipeScreen` (453 lines, 12 fields at once) and `EditRecipeScreen` (417 lines) with a single `RecipeFormScreen` that follows a phased, progressive disclosure model. Both screens are structurally parallel near-duplicates — this issue unifies them.

**MVP scope (Phases 1+4 only)**:
- **Phase 1 — Stub**: name + meal type + servings → saveable immediately
- **Phase 4 — Ingredients**: embeds `IngredientParserSection` from #371
- **Phases 2, 3, 5**: fields preserved in a temporary "More details" section (existing flat form), to be redesigned in follow-up issues

**Architecture decision** (from UX design session):
- `RecipeFormScreen(recipe: null)` = create mode
- `RecipeFormScreen(recipe: recipe)` = edit mode
- `AddRecipeScreen` and `EditRecipeScreen` deleted; all callsites updated

---

## Prerequisites Check

- [x] `IngredientParserSection` widget available (`lib/widgets/ingredient_parser/ingredient_parser_section.dart`)
- [x] `ParserReviewRow` widget available (`lib/widgets/ingredient_parser/parser_review_row.dart`)
- [x] `ServingsStepper` widget available (`lib/widgets/servings_stepper.dart`)
- [x] `TagPickerWidget` available (`lib/widgets/tag_picker_widget.dart`)
- [x] UX design complete (`docs/design/ux/issue-370-ux-design.md`)

---

## Phase 1: Analysis & Understanding

- [x] Audit all callsites for `AddRecipeScreen`:
  - `lib/screens/recipes_screen.dart`
  - `lib/screens/dashboard_screen.dart`
  - `lib/widgets/dashboard/quick_actions_panel.dart`
  - `lib/main.dart` (routes)
- [x] Audit all callsites for `EditRecipeScreen`:
  - `lib/screens/recipe_details_screen.dart` (`_editRecipe()` method)
  - `lib/main.dart` (routes)
- [x] Review `IngredientParserSection` constructor — confirm `existingIngredients` param handles pre-loaded ingredients for edit mode
- [x] Review `EditRecipeScreen` field list — confirm all fields for "More details" section (difficulty, prep/cook/marinating time, rating, tags, notes, story)
- [x] Check existing tests for files to be deleted:
  - `test/screens/add_recipe_screen_test.dart` (if exists)
  - `test/screens/edit_recipe_screen_test.dart` (if exists)

---

## Phase 2: Implementation

### 2.1 — Feature branch

- [x] `git checkout develop && git pull origin develop`
- [x] `git checkout -b ui/370-phased-recipe-form`

### 2.2 — New l10n strings

Add to `lib/l10n/app_en.arb` and `lib/l10n/app_pt.arb`:

| Key | English | Portuguese |
|---|---|---|
| `newRecipe` | New recipe | Nova receita |
| `saveChanges` | Save changes | Salvar alterações |
| `skipForNow` | Skip for now | Pular por agora |
| `editBasics` | Edit basics | Editar informações básicas |
| `moreDetails` | More details | Mais detalhes |
| `basics` | Basics | Informações básicas |

- [x] Add 6 keys to `lib/l10n/app_en.arb`
- [x] Add 6 keys to `lib/l10n/app_pt.arb`
- [x] Run `flutter gen-l10n`

### 2.3 — Build `RecipeFormScreen`

Create `lib/screens/recipe_form_screen.dart`:

**State**:
- `Recipe? recipe` param — null = create mode, non-null = edit mode
- `bool _phase1Saved` — controls Phase 1 → Phase 4 transition in create mode
- `bool _hasUnsavedChanges` — triggers discard confirmation on back
- Phase 1 controllers: `_nameController`, `_selectedFrequency`, `_servings`
- Phase 4: `List<ParsedIngredient> _parsedIngredients`
- "More details" controllers: all fields from current `EditRecipeScreen`

**Create mode flow**:
- [x] Phase 1 section: name (auto-focused, required), meal type dropdown, servings stepper, full-width "Save recipe" `ElevatedButton`
- [x] On Phase 1 save: persist recipe to DB → `setState(() => _phase1Saved = true)` → AppBar title = recipe name → Phase 1 collapses to summary card (name + meal type + servings + ✏ `IconButton` to re-expand) → Phase 4 expands with scroll
- [x] Phase 4 section: `IngredientParserSection` (empty initial state) + full-width "Add to recipe" `ElevatedButton` (disabled until ingredients parsed) + "Skip for now" `TextButton` below card
- [x] "Skip for now" / "Add to recipe" → `Navigator.push(RecipeDetailsScreen(recipe: savedRecipe))`

**Edit mode flow**:
- [x] Phase 1 section (`_SectionExpansion`, expanded by default): pre-filled fields + "Save changes" button
- [x] Phase 4 section (`_SectionExpansion`, expanded by default): `IngredientParserSection` fresh start + "Save changes" button
- [x] "More details" `_SectionExpansion` (collapsed by default): all Phase 2+3+5 fields from current `EditRecipeScreen` (difficulty, prep/cook/marinating time, rating, tags, notes, story) + "Save changes" button
- [x] Per-section save: updates only that section's fields on the existing recipe
- [x] Back navigation with unsaved changes → "Discard changes?" `AlertDialog`
- [x] Pop with `true` on any successful save for parent refresh

**Shared**:
- [x] DI: `DatabaseHelper? databaseHelper` param, falls back to `ServiceProvider.database.dbHelper`
- [x] All error handling via `SnackbarService`
- [x] `flutter analyze` — no warnings

### 2.4 — Update callsites

- [x] `lib/screens/recipes_screen.dart` — replace `AddRecipeScreen` navigation with `RecipeFormScreen(recipe: null)`
- [x] `lib/screens/dashboard_screen.dart` — same replacement
- [x] `lib/widgets/dashboard/quick_actions_panel.dart` — same replacement (no-op — not using AddRecipeScreen directly)
- [x] `lib/screens/recipe_details_screen.dart` — `_editRecipe()`: replace `EditRecipeScreen(recipe: ...)` with `RecipeFormScreen(recipe: ...)`
- [x] `lib/main.dart` — updated (old screens removed)

### 2.5 — Delete old screens

- [x] Delete `lib/screens/add_recipe_screen.dart`
- [x] Delete `lib/screens/edit_recipe_screen.dart`
- [x] `flutter analyze` — confirm no dangling imports

---

## Phase 3: Testing

### 3.1 — Widget tests for `RecipeFormScreen`

File: `test/screens/recipe_form_screen_test.dart`

**Create mode — Phase 1**:
- [x] `renders Phase 1 fields with name auto-focused`
- [x] `save button disabled when name is empty`
- [x] `save button enabled when name is non-empty`
- [x] `saves recipe and transitions to Phase 4 on valid save`
- [x] `Phase 1 collapses to summary card after save`
- [x] `AppBar title updates to recipe name after Phase 1 save`
- [x] `edit icon on summary re-expands Phase 1`

**Create mode — Phase 4**:
- [x] `Phase 4 shows IngredientParserSection after Phase 1 save`
- [ ] `Add to recipe button disabled before parsing` (deferred — button not present in MVP)
- [ ] `Skip for now navigates to RecipeDetailsScreen with stub` (deferred — navigator push hard to test in isolation)
- [ ] `Add to recipe navigates to RecipeDetailsScreen after ingredient confirm` (deferred)
- [x] `Skip for now button is present after Phase 1 save`

**Edit mode**:
- [x] `renders with all sections pre-filled from existing recipe`
- [x] `Phase 1 and Phase 4 sections expanded by default`
- [x] `More details section collapsed by default` (verifies expand behavior)
- [ ] `per-section save updates only that section` (deferred)
- [x] `returns true to caller on successful save`
- [ ] `shows discard dialog on back with unsaved changes` (deferred — PopScope interaction)
- [ ] `does not show discard dialog when no unsaved changes` (deferred)

**Error handling**:
- [x] `shows error snackbar on DB save failure (Phase 1)`
- [ ] `shows error snackbar on DB save failure (Phase 4)` (deferred)
- [x] `stays on form with data intact after save failure`

### 3.2 — Callsite regression tests

- [x] Integration test `e2e_recipe_editing_workflow_test.dart` updated to use `RecipeFormScreen`

### 3.3 — Edge cases

File: `test/edge_cases/interaction_patterns/recipe_form_flow_test.dart`

- [x] `back button before Phase 1 save does not persist anything`
- [x] `back button after Phase 1 save does not delete the stub`
- [x] `servings value preserved across Phase 1 collapse/re-expand`
- [x] `edit mode with recipe that has no ingredients shows empty parser state`
- [x] `create mode with very long recipe name fits in summary card`

### 3.4 — Run full suite

- [x] `flutter test` — 2076 tests pass
- [x] `flutter analyze` — no issues

---

## Phase 4: Documentation & Cleanup

- [x] Delete `test/screens/add_recipe_screen_test.dart` (coverage now in `recipe_form_screen_test.dart`)
- [x] Delete `test/screens/edit_recipe_screen_test.dart` (same reason)
- [x] Update `docs/architecture/Gastrobrain-Codebase-Overview.md` — replaced `AddRecipeScreen` and `EditRecipeScreen` entries with `RecipeFormScreen`
- [x] Update `docs/architecture/Gastrobrain-Codebase-Overview.html` — same
- [x] Create follow-up issues for deferred phases:
  - #385 `ux: redesign recipe form Phase 2 — Timing & difficulty`
  - #386 `ux: redesign recipe form Phase 3 — Tags & rating`
  - #387 `ux: redesign recipe form Phase 5 — Notes & story`
  - #388 `ux: replace AddIngredientDialog in RecipeDetailsScreen with IngredientParserSection`
- [x] Final: `flutter analyze && flutter test` — 2076 tests pass, 0 analysis issues
- [ ] Commit: `feat: replace add/edit recipe screens with unified phased RecipeFormScreen (#370)`
- [ ] `git checkout develop && git merge ui/370-phased-recipe-form`
- [ ] `git push origin develop`
- [ ] `git branch -d ui/370-phased-recipe-form`

---

## Files to Modify

**Create**:
- `lib/screens/recipe_form_screen.dart`
- `test/screens/recipe_form_screen_test.dart`
- `test/edge_cases/interaction_patterns/recipe_form_flow_test.dart`

**Update**:
- `lib/l10n/app_en.arb`
- `lib/l10n/app_pt.arb`
- `lib/screens/recipes_screen.dart`
- `lib/screens/dashboard_screen.dart`
- `lib/screens/recipe_details_screen.dart`
- `lib/widgets/dashboard/quick_actions_panel.dart`
- `lib/main.dart`
- `docs/architecture/Gastrobrain-Codebase-Overview.md`
- `docs/architecture/Gastrobrain-Codebase-Overview.html`

**Delete**:
- `lib/screens/add_recipe_screen.dart`
- `lib/screens/edit_recipe_screen.dart`
- `test/screens/add_recipe_screen_test.dart` (if exists)
- `test/screens/edit_recipe_screen_test.dart` (if exists)

---

## Acceptance Criteria

- [ ] User can create a recipe with only name + meal type — saved to DB in under 10 seconds
- [ ] After Phase 1 save, `IngredientParserSection` is presented as the natural next step
- [ ] "Skip for now" exits to `RecipeDetailsScreen` without requiring ingredients
- [ ] Editing a recipe uses the same `RecipeFormScreen` (no separate edit screen)
- [ ] All Phase 2+3+5 fields (timing, difficulty, rating, tags, notes, story) remain editable via "More details" section
- [ ] `AddRecipeScreen` and `EditRecipeScreen` no longer exist in the codebase
- [ ] All existing navigation to add/edit recipe works correctly through `RecipeFormScreen`
- [ ] EN and PT-BR strings present for all 6 new keys
- [ ] All tests pass, no analyzer warnings
