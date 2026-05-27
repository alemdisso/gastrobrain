# UX Design: Unified Recipe Creation & Editing Flow
**Issue**: #370 — ux: redesign recipe creation as a phased, progressive disclosure flow  
**Sprint**: 0.2.13 — Recipe Redesign  
**Date**: 2026-05-27  
**MVP Scope**: Phases 1 (Stub) + 4 (Ingredients)

---

## Goal & Context

**User Goal**: Users want to create and enrich recipes progressively — starting with just a name and meal type (enough to save a "stub"), then coming back to add ingredients, timing, tags, and notes at their own pace. Editing an existing recipe should feel like continuing the same journey, not opening a completely different form.

**Pain Points**:
- Current creation form dumps 12 fields at once — cognitively overwhelming for a quick stub
- Creation and editing are two separate screens with duplicated logic and inconsistent structure
- Ingredient editing lives in a separate enrichment tool, disconnected from the metadata editing flow
- No sense of recipe "completeness" — users can't tell what's missing or what's worth adding next

**Success Criteria**:
- [ ] A recipe can be saved with only name + meal type — in under 10 seconds
- [ ] Adding ingredients to an existing recipe feels like a natural continuation, not a mode switch
- [ ] Creating a recipe and editing a recipe use the same screens/components (no duplication)
- [ ] Users have a clear sense of what each phase adds and can skip phases freely
- [ ] The flow feels intentional and cultured — not a generic multi-step wizard

**Scope**: Unified redesign of `add_recipe_screen.dart` + `edit_recipe_screen.dart` into a single phased `RecipeFormScreen`, with `recipe_editor_screen.dart` (enrichment tool) remaining separate.

---

## Current State Assessment

**What exists**:
- `add_recipe_screen.dart` (453 lines) — 12 fields in a single scrollable form
- `edit_recipe_screen.dart` (417 lines) — same fields minus ingredients
- `recipe_editor_screen.dart` (1141 lines) — bulk enrichment tool with `IngredientParserSection`
- `recipe_details_screen.dart` — read-only tabbed view (Ingredients / Instructions / Overview / History)

**What works** ✅:
- Card-based grouping already creates visual sections (good bones)
- `ServingsStepper`, `TagPickerWidget`, `IngredientParserSection` are well-extracted reusable widgets
- `SnackbarService` for consistent error/success feedback
- DI pattern (`databaseHelper` injected) supports testability

**What doesn't work** ❌:
- 12 fields at once — users creating a quick stub must scroll past everything before saving
- `add_recipe_screen.dart` uses old `AddIngredientDialog`, not `IngredientParserSection`
- `edit_recipe_screen.dart` has no ingredients — editing ingredients requires a separate tool
- Creation and editing are near-duplicate files with no shared structure
- No progress signal — users can't tell what's missing from a stub recipe

**Approach**: Hybrid — structural change (flat form → phased sections) reusing all existing leaf widgets.

**Instructions note**: Instructions are free-form markdown, edited via a dedicated tab + dialog in `RecipeDetailsScreen`. They stay there — not part of the form flow.

---

## Field Assignment

| Field | Phase | Status |
|---|---|---|
| Name | Phase 1 — Stub | MVP |
| Meal type / frequency | Phase 1 — Stub | MVP |
| Servings | Phase 1 — Stub | MVP (needed before ingredients) |
| Prep / cook / marinating time | Phase 2 — Timing | Deferred |
| Difficulty | Phase 2 — Timing | Deferred |
| Rating | Phase 3 — Quality | Deferred |
| Tags | Phase 3 — Quality | Deferred |
| Ingredients | Phase 4 — Ingredients | MVP |
| Notes | Phase 5 — Context | Deferred |
| Story / history | Phase 5 — Context | Deferred |
| Instructions | RecipeDetailsScreen (stays) | Not in form |

---

## User Flow Map

### Mode A — Creation (new recipe)

**Primary Flow**:
1. User taps "Add Recipe" FAB on recipes list screen
2. `RecipeFormScreen(recipe: null)` opens — only Phase 1 shown
3. User types name, selects meal type, optionally adjusts servings
4. Taps **"Save recipe"** → recipe persisted to DB with real ID
5. Phase 1 collapses to summary card; Phase 4 (Ingredients) expands
6. User pastes/types ingredients → reviews parsed list → taps "Add to recipe"
7. User taps **"Skip for now"** or completes Phase 4 → navigates to `RecipeDetailsScreen`

**Decision Points**:
- Name empty at step 4 → inline validation error, cannot save
- User taps "Skip for now" at step 6 → navigates to details with stub only
- Back button before step 4 → nothing persisted, standard back navigation

**Error Paths**:
- DB save fails at step 4: SnackBar error, stays on Phase 1 with data intact
- Ingredient parse fails: handled inline by `IngredientParserSection`

### Mode B — Editing (existing recipe)

**Primary Flow**:
1. User taps "Edit" from `RecipeDetailsScreen`
2. `RecipeFormScreen(recipe: recipe)` opens — all sections visible
3. Phase 1 and Phase 4 sections expanded; "More details" collapsed
4. User edits any section, taps per-section "Save changes"
5. Back navigation → `RecipeDetailsScreen` refreshes

**Decision Points**:
- Unsaved edits on back → "Discard changes?" confirm dialog

### Shared
- `RecipeFormScreen(recipe: null)` = create mode
- `RecipeFormScreen(recipe: recipe)` = edit mode
- Both use `Navigator.push`, return `true` on any save for parent refresh

---

## Information Architecture

**Phase 1 — Stub**:
- Primary: Recipe name (large field, auto-focused, required)
- Secondary: Meal type (dropdown, default: dinner)
- Tertiary: Servings (compact stepper, default: 4)
- Save: full-width "Save recipe" button

**Phase 4 — Ingredients**:
- Primary: `IngredientParserSection` bulk textarea
- Secondary: Parsed review rows (confidence dots, match dropdowns)
- Tertiary: "Add to recipe" confirm button (active only when items parsed)
- Exit: "Skip for now" text button below card

**"More details" section (MVP temporary)**:
- Contains phases 2+3+5 fields as existing flat form
- Collapsed by default in edit mode
- To be replaced phase-by-phase in follow-up issues

**Progressive Disclosure**:
- Create: Phase 1 only → save → Phase 4 expands, Phase 1 collapses to summary
- Edit: Phases 1+4 expanded, "More details" collapsed

---

## Wireframes

### Screen A — Create Mode, Phase 1
```
┌─────────────────────────────────────┐
│  ←  New recipe                      │  AppBar
├─────────────────────────────────────┤
│                                     │  32px top padding
│  ┌───────────────────────────────┐  │
│  │  Recipe name           *      │  │  TextFormField, auto-focused
│  │  [________________________]   │  │
│  └───────────────────────────────┘  │
│                                     │  24px gap
│  ┌───────────────────────────────┐  │
│  │  Meal type                    │  │  DropdownButtonFormField
│  │  [ Dinner                  ▼] │  │
│  └───────────────────────────────┘  │
│                                     │  24px gap
│  ┌───────────────────────────────┐  │
│  │  Servings                     │  │  ServingsStepper
│  │  [  −  ]   4   [  +  ]        │  │
│  └───────────────────────────────┘  │
│                                     │  32px gap
│  ┌───────────────────────────────┐  │
│  │        Save recipe            │  │  ElevatedButton, full-width, 48px
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

### Screen B — Create Mode, Phase 4
```
┌─────────────────────────────────────┐
│  ←  Spaghetti Carbonara             │  AppBar = recipe name
├─────────────────────────────────────┤
│                                     │
│  ┌───────────────────────────────┐  │  Phase 1 collapsed summary
│  │  ✓  Spaghetti Carbonara       │  │
│  │     Dinner  ·  4 servings  ✏  │  │  ✏ = re-expand Phase 1
│  └───────────────────────────────┘  │
│                                     │  24px gap
│  ┌───────────────────────────────┐  │
│  │  Ingredients                  │  │  Phase 4 card
│  │  ─────────────────────────── │  │
│  │  ┌─────────────────────────┐  │  │
│  │  │ 2 eggs                  │  │  │  Bulk textarea (minLines: 4)
│  │  │ 200g spaghetti          │  │  │
│  │  └─────────────────────────┘  │  │
│  │  [ Parse ingredients ]        │  │
│  │  ── Review ────────────────── │  │
│  │  ● 2 eggs               ✓  ▼  │  │  ParserReviewRows
│  │  ● 200g spaghetti       ✓  ▼  │  │
│  │  ● 100g guanciale       ~  ▼  │  │  ~ = uncertain
│  │  [    Add to recipe         ] │  │  ElevatedButton
│  └───────────────────────────────┘  │
│  [  Skip for now  ]                 │  TextButton, subtle
└─────────────────────────────────────┘
```

### Screen C — Edit Mode
```
┌─────────────────────────────────────┐
│  ←  Edit recipe                     │  AppBar — no global save
├─────────────────────────────────────┤
│                                     │
│  ┌───────────────────────────────┐  │
│  │  ▼  Basics                    │  │  Phase 1 — expanded
│  │  Name: [Spaghetti Carbonara ] │  │
│  │  Meal type: [ Dinner       ▼] │  │
│  │  Servings:  [  −  ]  4  [  +] │  │
│  │  [  Save changes  ]           │  │
│  └───────────────────────────────┘  │
│                                     │  16px gap
│  ┌───────────────────────────────┐  │
│  │  ▼  Ingredients               │  │  Phase 4 — expanded
│  │  [IngredientParserSection   ] │  │
│  │  [  Save changes  ]           │  │
│  └───────────────────────────────┘  │
│                                     │  16px gap
│  ┌───────────────────────────────┐  │
│  │  ▷  More details              │  │  Phases 2+3+5 — collapsed
│  └───────────────────────────────┘  │  (temporary flat fields)
└─────────────────────────────────────┘
```

---

## Accessibility Review

- All form fields have `labelText` — announced by screen readers
- Phase 1 ✏ button: `tooltip: 'Edit basics'` required
- Phase 1 summary ✓ checkmark: accompanied by text, not color alone
- `ServingsStepper`: verify `Semantics` wrapper announces value (e.g. "4 servings")
- Section `ExpansionTile` headers: built-in semantics, logical focus order
- Save buttons: full-width ElevatedButton, 48px — above 44px minimum
- Error states: inline validator text + snackbar with icon+text (not color alone)

---

## New Localization Strings

| Key | English | Portuguese |
|---|---|---|
| `newRecipe` | New recipe | Nova receita |
| `saveChanges` | Save changes | Salvar alterações |
| `skipForNow` | Skip for now | Pular por agora |
| `editBasics` | Edit basics | Editar informações básicas |
| `moreDetails` | More details | Mais detalhes |
| `basics` | Basics | Informações básicas |

> Note: `editRecipe`, `saveRecipe` already exist in ARB files.

---

## Implementation Handoff

**Build**:
- [ ] `lib/screens/recipe_form_screen.dart` — new unified screen
- [ ] Phase 1 section widget (or inline in screen)
- [ ] Phase 4 section widget embedding `IngredientParserSection`
- [ ] "More details" `ExpansionTile` with existing Phase 2+3+5 fields
- [ ] 6 new l10n keys in `app_en.arb` + `app_pt.arb`
- [ ] Delete `add_recipe_screen.dart`, update all callsites
- [ ] Delete `edit_recipe_screen.dart`, update all callsites

**Leave unchanged**:
- `RecipeDetailsScreen` — instructions tab, overview tab, history tab
- `RecipeEditorScreen` — enrichment tool
- `IngredientParserSection` — used as-is

**Follow-up issues to create**:
- Phase 2 (Timing & difficulty) as a proper section
- Phase 3 (Tags & rating) as a proper section
- Phase 5 (Notes & story) as a proper section
- Replace `AddIngredientDialog` in `RecipeDetailsScreen` ingredients tab with `IngredientParserSection`
