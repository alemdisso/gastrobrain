# UX Design: #280 — Shopping List Generation Flow

Reference document for the unified shopping list redesign. Generated during UX exploration (Checkpoints 1-6).

---

## Goal & Context

**User Goal**: Smooth, unified flow from "what ingredients do I need?" to "shopping list ready" — without navigating disconnected menus and losing context between modes.

**Pain Points**:
- Menu friction: 3-option menu before seeing any content
- Disconnected modes: preview, refinement, saved are separate dead-end paths
- No invalidation: stale lists after meal plan changes go undetected
- Bottom sheets are cramped for long ingredient lists (#277)

**Success Criteria**:
- One-tap access to shopping list (no menu)
- Fluid movement between preview → refinement → saved
- Stale lists show warning with regenerate option
- Summary moves to app bar, bottom bar removed entirely

---

## Current vs New Navigation

**Current** (fragmented):
```
Bottom Bar → Menu Bottom Sheet
├── Preview Ingredients → Bottom Sheet (read-only, dead end)
├── Generate Shopping List → Refinement Bottom Sheet → Saved List Screen
└── View Existing List → Saved List Screen
```

**New** (unified):
```
FAB 🛒 → Navigator Stack
├── No saved list → Preview Screen → Refinement Screen → Saved Screen
├── Has saved list → Saved Screen (with stale detection)
└── Stale → Update → Preview Screen → Refinement → Saved Screen
```

---

## Architecture Decision: Navigator Stack

Each mode is a **separate route** pushed onto the navigator (Option B):
- Natural back button behavior
- Proper route transitions
- Each mode is a focused widget
- Weekly plan pushes first route (Preview or Saved depending on existing list)

---

## Screen Wireframes

### Weekly Plan Screen (updated)

```
┌─────────────────────────────────────┐
│ [←]  Refeições da Semana    [📊][🔄] │  ← App bar: summary + refresh
├─────────────────────────────────────┤
│                                     │
│  Week navigation (< Esta semana >) │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  Segunda 16/02               │  │
│  │  ┌─────────────────────────┐ │  │
│  │  │ ☀ Almoço                │ │  │
│  │  │ curry de lombo suíno    │ │  │
│  │  └─────────────────────────┘ │  │
│  │  ┌─────────────────────────┐ │  │
│  │  │ 🌙 Jantar               │ │  │
│  │  │ + Adicionar refeição    │ │  │
│  │  └─────────────────────────┘ │  │
│  └───────────────────────────────┘  │
│                                     │
│  ... more days ...                  │
│                                     │
│                          ┌────┐     │
│                          │ 🛒 │     │  ← FAB (bottom-right)
│                          └────┘     │
└─────────────────────────────────────┘
```

- Bottom bar removed entirely
- Summary: icon button in app bar (📊 analytics/bar_chart icon)
- Shopping list: FAB with cart icon (single entry point)

### Preview Screen

```
┌─────────────────────────────────────┐
│ [←]  Ingredientes                   │  ← App bar, back to weekly plan
├─────────────────────────────────────┤
│                                     │
│  ▼ Carnes e Aves                    │  ← ExpansionTile (expanded)
│    frango ..................  800g   │
│    lombo suíno .............  500g   │
│                                     │
│  ▼ Vegetais                         │
│    cebola ..................  3 un   │
│    pimentão ................  2 un   │
│    tomate ..................  4 un   │
│                                     │
│  ▼ Temperos                         │
│    curry em pó .............  2 cs   │
│    alho ....................  6 dentes│
│                                     │
│  ... more categories ...            │
│                                     │
├─────────────────────────────────────┤
│  [ Refinar ]      [ Gerar Lista ▶ ]│  ← Bottom action bar
└─────────────────────────────────────┘
```

- Read-only ingredient list grouped by category
- Categories expanded by default (reviewing everything)
- Two actions: "Refinar" (→ refinement) or "Gerar Lista" (skip refinement, save all)

### Refinement Screen

```
┌─────────────────────────────────────┐
│ [←]  Refinar Lista                  │  ← Back goes to Preview
├─────────────────────────────────────┤
│  ☑ Selecionar todos    18 de 22     │  ← Tri-state select all + count
├─────────────────────────────────────┤
│                                     │
│  ▼ Carnes e Aves                    │  ← ExpansionTile (expanded)
│    ☑ frango ................  800g   │
│    ☑ lombo suíno ...........  500g   │
│                                     │
│  ▼ Vegetais                         │
│    ☑ cebola ................  3 un   │
│    ☐ p̶i̶m̶e̶n̶t̶ã̶o̶ ̶.̶.̶.̶.̶.̶.̶.̶  ̶2̶ ̶u̶n̶   │  ← Unchecked = strikethrough
│    ☑ tomate ................  4 un   │
│                                     │
│  ... more categories ...            │
│                                     │
├─────────────────────────────────────┤
│  [ Gerar Lista de Compras (18) ▶ ] │  ← Primary action with count
└─────────────────────────────────────┘
```

- Same ingredient list, now with checkboxes
- All checked by default (opt-out model)
- Selections persist if toggling back to Preview and returning
- Generate button shows selected count

### Saved Screen

```
┌─────────────────────────────────────┐
│ [←]  Lista de Compras               │  ← Back to weekly plan
├─────────────────────────────────────┤
│ ⚠️ Seu plano mudou. Lista pode     │  ← Stale warning (conditional)
│    estar desatualizada. [Atualizar] │     MaterialBanner, amber
├─────────────────────────────────────┤
│  [A comprar ▾]  [Esconder a gosto] │  ← Filter chips
├─────────────────────────────────────┤
│                                     │
│  ▶ Carnes e Aves (2)               │  ← Collapsed by default
│                                     │
│  ▼ Vegetais (3)                     │  ← Expanded on tap
│    ☑ cebola ................  3 un   │
│    ☑ tomate ................  4 un   │
│    ☐ p̶i̶m̶e̶n̶t̶ã̶o̶ ̶.̶.̶.̶.̶.̶.̶.̶  ̶2̶ ̶u̶n̶   │  ← Bought = checked off
│                                     │
│  ▶ Temperos (2)                     │
│                                     │
└─────────────────────────────────────┘
```

- No bottom action bar — interactions are inline (check/uncheck while shopping)
- Categories collapsed by default (focus on one section at a time in-store)
- Category headers show item count
- Stale warning only when `mealPlan.modifiedAt` differs from saved timestamp

### Empty State

```
┌─────────────────────────────────────┐
│ [←]  Ingredientes                   │
├─────────────────────────────────────┤
│                                     │
│                                     │
│              🛒                      │
│                                     │
│    Nenhuma refeição planejada       │
│    para esta semana.                │
│                                     │
│    Adicione refeições ao seu        │
│    plano para ver os ingredientes.  │
│                                     │
│                                     │
└─────────────────────────────────────┘
```

---

## Mode-Specific Content Map

| Element | Preview | Refinement | Saved |
|---------|---------|------------|-------|
| App bar title | "Ingredientes" | "Refinar Lista" | "Lista de Compras" |
| Back goes to | Weekly plan | Preview | Weekly plan |
| Stale warning banner | — | — | conditional |
| Select/deselect all | — | ✓ (tri-state + count) | — |
| Filter chips | — | — | ✓ |
| Checkboxes | — | ✓ | ✓ |
| Strikethrough on uncheck | — | ✓ | ✓ |
| Categories expanded | yes | yes | no |
| Category item count | — | — | ✓ |
| Bottom action bar | "Refinar" + "Gerar Lista" | "Gerar Lista (N)" | — |
| Loading state | ✓ (calculating) | — | ✓ (loading list) |

---

## Interaction Transitions

| From | To | Transition | Trigger |
|------|----|-----------|---------|
| Weekly Plan | Preview | Slide-up (fullscreenDialog) | Tap FAB (no saved list) |
| Weekly Plan | Saved | Slide-up (fullscreenDialog) | Tap FAB (has saved list) |
| Preview | Refinement | Slide-left (forward) | Tap "Refinar" |
| Refinement | Preview | Slide-right (back) | Back button |
| Refinement | Saved | pushReplacement (clears stack) | Tap "Generate" |
| Preview | Saved | pushReplacement (clears stack) | Tap "Generate All" |
| Saved (stale) | Preview | Slide-left (regenerate) | Tap "Atualizar" |
| Any screen | Weekly Plan | Slide-down / back | Back from first route |

---

## Component Specifications

| Component | Flutter Widget | Notes |
|-----------|---------------|-------|
| FAB | `FloatingActionButton` | Shopping cart icon, standard 56px |
| App bar summary | `IconButton` | bar_chart or analytics icon |
| Stale warning | `MaterialBanner` | Amber background, "Atualizar" action |
| Filter chips | `FilterChip` in `Wrap` | Same pattern as current saved list |
| Select all | `CheckboxListTile` | Tri-state, count text right-aligned |
| Category group | `ExpansionTile` | Item count in title for Saved mode |
| Ingredient (read-only) | `ListTile` | Name (expanded) + quantity (trailing) |
| Ingredient (checkbox) | `CheckboxListTile` | Strikethrough on unchecked |
| Bottom action bar | `Container` + `SafeArea` | Elevated, with shadow, 1-2 buttons |
| Empty state | `Column` (centered) | Icon + title + subtitle |
| Loading state | `CircularProgressIndicator` | Centered |

---

## Stale Detection Logic

**On save**:
- Store `mealPlan.modifiedAt` in `ShoppingList.mealPlanModifiedAt` field
- Requires DB migration: add `meal_plan_modified_at` column to `shopping_lists` table

**On open saved list**:
- Load current meal plan's `modifiedAt`
- Compare with `shoppingList.mealPlanModifiedAt`
- If different → show `MaterialBanner` warning

**On "Update" action**:
- Navigate to Preview screen with current week dates
- User goes through Preview → Refinement → Generate
- New list replaces old one (or old one deleted + new created)

---

## Localization Strings

| Key | EN | PT |
|-----|----|----|
| `shoppingListIngredients` | "Ingredients" | "Ingredientes" |
| `shoppingListRefine` | "Refine List" | "Refinar Lista" |
| `shoppingListRefineAction` | "Refine" | "Refinar" |
| `shoppingListGenerateAll` | "Generate List" | "Gerar Lista" |
| `shoppingListGenerateCount` | "Generate List ({count})" | "Gerar Lista ({count})" |
| `shoppingListStaleWarning` | "Your meal plan changed. This list may be outdated." | "Seu plano mudou. Esta lista pode estar desatualizada." |
| `shoppingListStaleAction` | "Update" | "Atualizar" |
| `shoppingListEmptyTitle` | "No meals planned" | "Nenhuma refeição planejada" |
| `shoppingListEmptySubtitle` | "Add meals to your plan to see ingredients." | "Adicione refeições ao plano para ver ingredientes." |

---

## Future Extensibility (not in scope, but design-aware)

1. **Category exclusion filters**: User hides entire categories. Fits in Refinement mode — category-level toggles on `ExpansionTile` headers. Current design leaves room for action icons on category headers.

2. **Multi-list / per-store routing**: User splits ingredients by store. Category grouping is the natural pivot. The state model could evolve: Preview → Refinement → **Assign to Stores** → Saved Lists.

3. **Custom ingredient addition**: User adds items not in recipes. Fits in Refinement mode — "Add item" action at bottom of category or as a FAB within refinement.

These don't affect current implementation, but the architecture (separate screens, category-based grouping) supports them.
