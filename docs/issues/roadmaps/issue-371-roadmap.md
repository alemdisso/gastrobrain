# Issue #371: Redesign Ingredient Parser UX/UI as a First-Class Entry Method

**Type**: Feature / UX Redesign
**Priority**: P2-Medium
**Estimate**: 13 story points
**Size**: L
**Dependencies**: #283 ✓ (IngredientParserService extracted — `lib/core/services/ingredient_parser_service.dart`)
**Branch**: `ui/371-ingredient-parser-ux`
**Milestone**: 0.2.13 — Recipe Redesign

---

## Overview

The ingredient parser is a powerful feature buried as an afterthought in the recipe editor. This issue promotes it to a first-class, trustworthy entry method: the user pastes (or types) a list of ingredients, sees a clean parse preview, corrects any uncertain rows inline, and commits in one action. The result ships as a self-contained widget that #370 Phase 4 embeds directly.

**Context**:
- Engine is ready: `IngredientParserService` (from #283) handles EN + PT-BR, fractions, ranges, "a gosto", parenthetical notes
- Current implementation is deeply embedded in `recipe_editor_screen.dart`; each parsed row renders as a dense mini-form (qty field + unit field + name field + notes field + match dropdown + create button) — 6 interactive elements per ingredient by default
- The re-designed UX flips the default: rows are compact and read-only; editing is an exception triggered by tap

**Expected Outcome**:
A standalone `IngredientParserSection` widget that accepts a bulk ingredient list as input, shows a compact review phase with inline correction, and emits a confirmed ingredient list. Both EN and PT-BR fully localized. No hardcoded strings remain in the parser UI path.

---

## Prerequisites Check

- [x] #283 closed — `IngredientParserService` in `ServiceProvider`
- [ ] On latest develop: `git checkout develop && git pull origin develop`
- [ ] All existing tests passing: `flutter test`
- [ ] No analysis warnings: `flutter analyze`

---

## Phase 1: Analysis & Understanding

**Goal**: Map the current implementation thoroughly before touching anything.

### Existing Parser UI Code

- [ ] Read `lib/screens/recipe_editor_screen.dart` — locate `_buildIngredientsPlaceholder()`, `_parseIngredients()`, `_parseIngredientLine()`, `_updateIngredient()`, `_removeIngredientAt()`, `_showCreateIngredientDialog()` — understand the full state surface
- [ ] Read `lib/widgets/recipe_editor/ingredient_row.dart` — understand what the redesigned row replaces (the verbose form layout with match dropdown)
- [ ] Read `lib/widgets/recipe_editor/parsed_ingredient.dart` — note which fields the data model carries (`quantity`, `quantityMax`, `unit`, `name`, `notes`, `matches`, `selectedMatch`, `isNewIngredient`, `qtyError`)
- [ ] Read `lib/core/services/ingredient_parser_service.dart` — confirm `parseIngredientLine()` return shape (`ParsedIngredientResult`: `quantity`, `quantityMax`, `unit`, `ingredientName`, `notes`, `matches`)
- [ ] Check `lib/core/services/ingredient_matching_service.dart` — understand `IngredientMatch` shape (`ingredient`, `confidence`, `confidenceLevel`, `matchType`)

### Reusable L10n Keys

- [ ] Confirm reusable ARB keys: `unit`, `simpleSideQuantityLabel`, `notes`, `remove`, `newIngredient`, `createNewIngredient`, `noneOfTheseCreateNew`
- [ ] Confirm all other parser strings are new (no existing `ingredientParser*` keys)

### Architecture Decision

- [ ] Confirm new widget tree:
  - `IngredientParserSection` (stateful, self-contained) — owns the multiline input + parse state + review list
    - `ParserReviewRow` (stateful) — owns single-row expand/collapse state
  - `recipe_editor_screen.dart` mounts `IngredientParserSection` in place of `_buildIngredientsPlaceholder()`
  - `ingredient_row.dart` is **retired** after replacement (delete or leave orphaned until confirmed safe)

---

## Phase 2: Implementation

**Goal**: Build the redesigned widget, wire it into the existing editor, localize everything.

### Step 1 — New Widget: `ParserReviewRow`

- [ ] Create `lib/widgets/ingredient_parser/parser_review_row.dart`
- [ ] **Collapsed state** (default): single `ListTile`-style row
  - Left: confidence dot (green = high match, amber = new ingredient / medium, red = no match / needs review)
  - Center: `"{quantity} {unit} · {name}"` — plain text, no input fields
  - Right: delete `IconButton`
- [ ] **Expanded state** (tap to toggle): inline fields appear below the collapsed row
  - Qty field (reuse `simpleSideQuantityLabel`)
  - Unit field (reuse `unit`)
  - Name field (new key `ingredientParserNameLabel`)
  - Notes field (reuse `notes`) — only if notes present or user opens
  - Match section: confidence badge + optional dropdown (when `matches.length > 1`)
  - "Will be created" amber badge (when `isNewIngredient`)
  - `createNewIngredient` button (when `matches` is empty and not `isNewIngredient`)
- [ ] Rows with `confidenceLevel == MatchConfidence.low` or no matches **open expanded by default** (need attention)
- [ ] Expose callbacks: `onQuantityChanged`, `onUnitChanged`, `onNameChanged`, `onNotesChanged`, `onMatchChanged`, `onMarkAsNew`, `onRemove`
- [ ] Use `AnimatedCrossFade` or `AnimatedSize` for the expand/collapse transition

### Step 2 — New Widget: `IngredientParserSection`

- [ ] Create `lib/widgets/ingredient_parser/ingredient_parser_section.dart`
- [ ] **Input area**:
  - `TextField` with `maxLines: 6`, label = `ingredientParserInputLabel`, hint = `ingredientParserHintText`
  - Helper text = `ingredientParserHelperText` (supports EN + PT-BR formats)
  - Row of two buttons: `ElevatedButton` "Parse" (`ingredientParserParseButton`) + `TextButton` "Add manually" (`ingredientParserAddManuallyButton`)
- [ ] **Parse action** (`_parseIngredients`):
  - Split input by newline, filter empty lines
  - Call `ServiceProvider.ingredientParser.parseIngredientLine()` per line
  - Build `List<ParsedIngredient>` — same model as today
  - Rows with no matches or low confidence → `isExpanded = true` by default
- [ ] **Review area** (visible when `_parsedIngredients.isNotEmpty`):
  - Section header: `ingredientParserReviewTitle(count)` — e.g. "Parsed (5)"
  - `ListView` of `ParserReviewRow` widgets, one per parsed ingredient
  - Sticky bottom bar: `ElevatedButton` "Add {n} ingredients" (`ingredientParserAddAllButton(count)`)
    - Disabled + warning text when any row has `matchState == needsAttention` (red dot, no match, no `isNewIngredient` flag set)
    - `ingredientParserBlockedHint(count)` shows count of unresolved rows
- [ ] **"Add manually" path**: appends a blank `ParsedIngredient` row (expanded by default, empty fields)
- [ ] **Callback**: `onIngredientsConfirmed(List<ParsedIngredient> confirmed)` — called when user taps "Add N ingredients"
- [ ] Wire `IngredientParserSection` as `StatefulWidget`; keep `_rawIngredientsController` and parse state internal

### Step 3 — Update `recipe_editor_screen.dart`

- [ ] Replace `_buildIngredientsPlaceholder()` body with a mounted `IngredientParserSection`
- [ ] Pass `onIngredientsConfirmed` callback that calls the existing `_saveIngredients()` / DB insertion logic
- [ ] Remove the now-inlined methods: `_parseIngredients`, `_parseIngredientLine`, `_updateIngredient`, `_removeIngredientAt` (these move inside the widgets)
- [ ] Keep `_showCreateIngredientDialog()` — delegate to `IngredientParserSection` via callback or keep in screen and pass down

### Step 4 — Retire `ingredient_row.dart`

- [ ] Confirm nothing else imports `lib/widgets/recipe_editor/ingredient_row.dart`
- [ ] Delete or keep with a `// retired — replaced by ParserReviewRow` comment until #370 confirms no reuse

### Step 5 — Localization

- [ ] Add to `lib/l10n/app_en.arb`:

  | Key | English |
  |-----|---------|
  | `ingredientParserInputLabel` | `"Ingredients"` |
  | `ingredientParserHintText` | `"200g flour\n2 cups milk\n3 eggs\nSalt to taste"` |
  | `ingredientParserHelperText` | `"Paste a list or type one at a time. Supports EN and PT-BR formats."` |
  | `ingredientParserParseButton` | `"Parse"` |
  | `ingredientParserAddManuallyButton` | `"Add manually"` |
  | `ingredientParserReviewTitle` | `"Parsed ({count})"` — `count: int` |
  | `ingredientParserAddAllButton` | `"Add {count} ingredient(s)"` — `count: int` |
  | `ingredientParserBlockedHint` | `"{count} needs attention"` — `count: int` |
  | `ingredientParserMatchHigh` | `"Matched"` |
  | `ingredientParserMatchMedium` | `"Close match — verify"` |
  | `ingredientParserMatchLow` | `"Low confidence — review"` |
  | `ingredientParserMatchNew` | `"Will be created"` |
  | `ingredientParserMatchNone` | `"No match — tap to review"` |
  | `ingredientParserNameLabel` | `"Ingredient"` |
  | `ingredientParserSelectMatchHint` | `"Choose from suggestions"` |

- [ ] Add all 15 keys with PT-BR translations to `lib/l10n/app_pt.arb`

  | Key | Português |
  |-----|-----------|
  | `ingredientParserInputLabel` | `"Ingredientes"` |
  | `ingredientParserHintText` | `"200g de farinha\n2 xícaras de leite\n3 ovos\nSal a gosto"` |
  | `ingredientParserHelperText` | `"Cole uma lista ou adicione um por vez. Suporta formatos PT-BR e EN."` |
  | `ingredientParserParseButton` | `"Analisar"` |
  | `ingredientParserAddManuallyButton` | `"Adicionar manualmente"` |
  | `ingredientParserReviewTitle` | `"Analisados ({count})"` |
  | `ingredientParserAddAllButton` | `"Adicionar {count} ingrediente(s)"` |
  | `ingredientParserBlockedHint` | `"{count} precisam de atenção"` |
  | `ingredientParserMatchHigh` | `"Encontrado"` |
  | `ingredientParserMatchMedium` | `"Correspondência aproximada — verifique"` |
  | `ingredientParserMatchLow` | `"Baixa confiança — revise"` |
  | `ingredientParserMatchNew` | `"Será criado"` |
  | `ingredientParserMatchNone` | `"Sem correspondência — toque para revisar"` |
  | `ingredientParserNameLabel` | `"Ingrediente"` |
  | `ingredientParserSelectMatchHint` | `"Escolha entre as sugestões"` |

- [ ] Run `flutter gen-l10n`
- [ ] Replace all hardcoded strings in `ingredient_row.dart` and `recipe_editor_screen.dart` parser section with `AppLocalizations` calls — use new keys above + reuse `unit`, `simpleSideQuantityLabel`, `notes`, `remove`, `createNewIngredient`, `noneOfTheseCreateNew`

### Step 6 — Code Quality

- [ ] Run `flutter analyze` — no warnings
- [ ] Verify new files are under widget size threshold (< 250 lines each)
- [ ] No hardcoded strings remain in parser widget path

---

## Phase 3: Testing

**Goal**: Full widget test coverage for both new widgets + edge case coverage.

### Widget Tests — `ParserReviewRow`

File: `test/widget/ingredient_parser/parser_review_row_test.dart`

- [ ] `testWidgets('renders collapsed with correct quantity, unit, name')`
- [ ] `testWidgets('confidence dot is green for high-confidence match')`
- [ ] `testWidgets('confidence dot is amber for new ingredient')`
- [ ] `testWidgets('confidence dot is red for no-match row')`
- [ ] `testWidgets('tapping row expands inline fields')`
- [ ] `testWidgets('tapping expanded row collapses it')`
- [ ] `testWidgets('no-match rows are expanded by default')`
- [ ] `testWidgets('qty field change fires onQuantityChanged')`
- [ ] `testWidgets('unit field change fires onUnitChanged')`
- [ ] `testWidgets('name field change fires onNameChanged')`
- [ ] `testWidgets('match dropdown visible when matches.length > 1')`
- [ ] `testWidgets('will-be-created badge visible when isNewIngredient')`
- [ ] `testWidgets('delete button fires onRemove')`

### Widget Tests — `IngredientParserSection`

File: `test/widget/ingredient_parser/ingredient_parser_section_test.dart`

- [ ] `testWidgets('renders input area with label and parse button')`
- [ ] `testWidgets('parse button is enabled when input is non-empty')`
- [ ] `testWidgets('parse button is disabled when input is empty')`
- [ ] `testWidgets('tapping parse shows review rows for each input line')`
- [ ] `testWidgets('review section hidden before first parse')`
- [ ] `testWidgets('add-all button shows correct ingredient count')`
- [ ] `testWidgets('add-all button disabled when unresolved red rows exist')`
- [ ] `testWidgets('add-all button fires onIngredientsConfirmed with parsed list')`
- [ ] `testWidgets('add-manually appends blank expanded row')`
- [ ] `testWidgets('removing a row updates the count in add-all button')`
- [ ] `testWidgets('parse success: renders EN labels correctly')`
- [ ] `testWidgets('parse success: renders PT-BR labels correctly')`

### Edge Case Tests

**Empty / minimal input** — `test/edge_cases/empty_states/ingredient_parser_empty_test.dart`
- [ ] `testWidgets('parse with all-empty lines shows no review rows')`
- [ ] `testWidgets('parse with single valid line shows one row')`
- [ ] `testWidgets('empty input: add-all button absent')`

**Boundary conditions** — `test/edge_cases/boundary_conditions/ingredient_parser_boundary_test.dart`
- [ ] `testWidgets('very long ingredient name truncates cleanly in collapsed row')`
- [ ] `testWidgets('quantity = 0 (a gosto) renders without qty/unit in collapsed row')`
- [ ] `testWidgets('range quantity (2-3 cups) displays correctly')`
- [ ] `testWidgets('20 ingredients pasted: all rows render, scroll works')`
- [ ] `testWidgets('special characters in ingredient name handled gracefully')`

**Interaction patterns** — `test/edge_cases/interaction_patterns/ingredient_parser_interaction_test.dart`
- [ ] `testWidgets('re-parsing clears previous review and shows fresh results')`
- [ ] `testWidgets('expanding multiple rows simultaneously is supported')`
- [ ] `testWidgets('marking unmatched row as new ingredient clears the blocked state')`
- [ ] `testWidgets('creating new ingredient via dialog resolves the red row')`

### Regression — Existing Recipe Editor

- [ ] `testWidgets('existing recipe editor still loads with ingredient parser section mounted')`
- [ ] Verify `flutter test test/widget/` — all pre-existing widget tests still pass after `ingredient_row.dart` retirement

### Full Suite Verification

- [ ] `flutter test` — all tests pass
- [ ] `flutter analyze` — clean

---

## Phase 4: Documentation & Cleanup

- [ ] Add brief doc comment to `IngredientParserSection` explaining the callback contract (`onIngredientsConfirmed`)
- [ ] Add doc comment to `ParserReviewRow` explaining the expand-by-default rule for low-confidence rows
- [ ] Confirm `ingredient_row.dart` is removed or clearly marked retired
- [ ] Verify no orphaned imports to `ingredient_row.dart` anywhere
- [ ] Run final `flutter analyze && flutter test`
- [ ] Test PT-BR visually — check that "Analisar", "Adicionar manualmente" and review labels fit the layout
- [ ] Create branch and commit:
  ```
  git checkout develop
  git pull origin develop
  git checkout -b ui/371-ingredient-parser-ux
  ```
  ```
  git commit -m "ui: redesign ingredient parser as first-class entry widget (#371)

  Extracts parser UX into IngredientParserSection + ParserReviewRow widgets.
  Compact read-mode rows with inline expansion on tap. Bulk paste primary
  input. All strings localized EN + PT-BR. Retires ingredient_row.dart.

  Closes #371

  Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
  ```
- [ ] `git push -u origin ui/371-ingredient-parser-ux`
- [ ] `git checkout develop && git merge ui/371-ingredient-parser-ux`
- [ ] `git push origin develop`
- [ ] `git branch -d ui/371-ingredient-parser-ux && git push origin --delete ui/371-ingredient-parser-ux`

---

## Files to Modify

### New Files
- `lib/widgets/ingredient_parser/ingredient_parser_section.dart` — main stateful widget
- `lib/widgets/ingredient_parser/parser_review_row.dart` — single-row widget with inline expansion
- `test/widget/ingredient_parser/ingredient_parser_section_test.dart`
- `test/widget/ingredient_parser/parser_review_row_test.dart`
- `test/edge_cases/empty_states/ingredient_parser_empty_test.dart`
- `test/edge_cases/boundary_conditions/ingredient_parser_boundary_test.dart`
- `test/edge_cases/interaction_patterns/ingredient_parser_interaction_test.dart`

### Modified Files
- `lib/screens/recipe_editor_screen.dart` — mount `IngredientParserSection`, remove inlined parse logic
- `lib/widgets/recipe_editor/parsed_ingredient.dart` — add `isExpanded` field for inline expansion state (or manage in `ParserReviewRow` local state — decide in Phase 1)
- `lib/l10n/app_en.arb` — 15 new keys
- `lib/l10n/app_pt.arb` — 15 new PT-BR translations

### Retired Files
- `lib/widgets/recipe_editor/ingredient_row.dart` — replaced by `ParserReviewRow`; delete after confirming no other callers

---

## Acceptance Criteria

### From Issue
- [ ] Natural language ingredient input feels intuitive and trustworthy
- [ ] Parse results clearly shown; user can confirm or correct them
- [ ] Ambiguous or failed parses handled gracefully
- [ ] Integrates cleanly as a widget for #370 Phase 4 to embed

### From Design Session
- [ ] Multiline paste (bulk) is the primary input mode
- [ ] Review rows are compact and read-only by default
- [ ] Tapping a row expands inline correction fields (qty, unit, name, notes, match)
- [ ] Low-confidence and no-match rows expand automatically
- [ ] Unknown ingredients shown with amber "Will be created" badge — does not block commit
- [ ] Rows with no match resolution show red indicator and block "Add N ingredients"
- [ ] Single "Add N ingredients" commit action at bottom
- [ ] `IngredientParserSection` is a self-contained widget exposing `onIngredientsConfirmed` callback

### Implicit Requirements
- [ ] All user-facing strings in both EN and PT-BR (no hardcoded text)
- [ ] `flutter analyze` clean
- [ ] `flutter test` all pass
- [ ] New widget files under 250-line threshold

---

## Risk Assessment

**Medium Risk Overall**

1. **`recipe_editor_screen.dart` state entanglement** — Medium
   - The current parser state (`_parsedIngredients`, `_parseGeneration`, `_isParserServiceReady`) is tightly coupled to the screen's `setState`. Moving it into `IngredientParserSection` requires careful boundary drawing.
   - Mitigation: Move all parse state into `IngredientParserSection`; screen only receives the final confirmed list via callback.

2. **`_showCreateIngredientDialog()` ownership** — Low/Medium
   - This dialog currently lives on the screen and needs `BuildContext`. Passing it into the widget as a callback is clean but adds boilerplate.
   - Mitigation: Pass `onCreateNew(ParsedIngredient) → Future<void>` callback from the screen into `IngredientParserSection` and down to each `ParserReviewRow`.

3. **`isExpanded` state location** — Low
   - Could live on `ParsedIngredient` (model) or in `ParserReviewRow` (local). If state lives in the model, re-parsing would reset all expansions cleanly; if local, scrolling may reset state unexpectedly.
   - Mitigation: Track `isExpanded` in the `IngredientParserSection`'s state map `Map<int, bool>`, keyed by list index — not in the model, not in the row widget.

---

**Roadmap Created**: 2026-05-26
**Status**: Planning
