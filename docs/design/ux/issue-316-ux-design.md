# UX Design — Issue #316: Unified Meal Options Dialog

**Issue**: [#316 — Redesign Meal Options menu into a rich, unified experience](https://github.com/alemdisso/gastrobrain/issues/316)
**Milestone**: 0.2.11 — DB Safety Foundation + UX Polish
**Designed**: 2026-05-18
**Status**: Ready for implementation

---

## Checkpoint 1 — Goal & Context

**User Goal**: When a user taps a meal they've already planned, they want to immediately see what that meal looks like — recipe, side dishes, servings — and be able to act on it (cook it, change it, remove it) without navigating through an action menu that hides the meal's content.

**Pain Point**: The current bottom sheet is a list of verbs ("Manage Recipes", "Manage Simple Sides", "View Details") — the user must hold the meal's content in their head. They never see their actual meal in the UI during this interaction. Meanwhile, the dialog shown right after *selecting* a recipe during new meal planning already displays the recipe and sides inline — creating a jarring inconsistency for the same slot.

**Success Criteria**:
- [ ] Tapping an existing planned meal immediately shows the recipe name, side dishes, and servings — no extra tap required to see what's planned
- [ ] All current actions are preserved and reachable within one screen (no disappearing functionality)
- [ ] The "Mark as Cooked" action is prominent and context-aware (shows "Edit Cooked Meal" if already cooked)
- [ ] The destructive "Remove" action is visually separated and not accidentally triggered
- [ ] The experience is identical in shape to what the user already saw when first planning the meal (consistent mental model)

**Scope**: Redesign of the `_handleMealTap` flow — replaces the existing bottom sheet with the `RecipeSelectionDialog` in menu mode, extended with the missing actions (View Details, Mark as Cooked, Remove).

---

## Checkpoint 2 — Current State Assessment

**What exists — two surfaces handling the same problem differently:**

**Surface A — `_handleMealTap` bottom sheet** (when user taps an *existing* planned meal):
A modal bottom sheet with three sections. The meal's content (recipe, sides, servings) is **invisible** — the user sees only action labels. Manages side dishes via separate full-screen dialogs launched from OutlinedButtons.

**Surface B — `RecipeSelectionDialog._buildMenu()`** (after *newly* selecting a recipe during planning):
A centered `Dialog` that shows the recipe name prominently, inline side dishes with inline remove buttons, a servings stepper, and a Save button. Rich, content-first. But: no View Details, no Mark as Cooked, no Remove.

**Factual note**: `_showingMenu` is already auto-set to `true` in `initState` when `initialPrimaryRecipe != null` (line 68–71). That gap described in the issue is closed. The real missing pieces are the three actions and the data-loading step in `_handleMealTap`.

**What works** ✅:
- `_buildMenu()` recipe header is clear and visually distinct (`primaryContainer` background)
- Inline side dishes list with per-item remove — much better than "Manage Recipes" button
- Servings stepper is already in place and functional
- "Back" button is already context-aware
- All needed L10N keys already exist (`mealOptions`, `viewRecipeDetails`, `changeRecipe`, `markAsCooked`, `editCookedMeal`, `removeFromPlan`, `saveChanges`)
- `Dialog` inset padding (16px h, 24px v) gives reasonable breathing room on mobile

**What doesn't work** ❌:
- `_handleMealTap` opens a different surface (bottom sheet) instead of reusing `_buildMenu()`
- Meal content (recipe, sides, servings) is invisible in the current bottom sheet
- `_buildMenu()` has no "View Details", "Mark as Cooked", or "Remove"
- Return value has no action discriminator — `_handleMealTap` can't route from a dialog result
- Save button says "Save Meal" in both flows — in edit mode it should say "Save Changes"

**Design patterns to maintain**:
- `Dialog` container (not a bottom sheet)
- `primaryContainer` recipe header
- Inline side dish list with ✕ remove buttons
- Cancel button in Dialog frame footer
- Destructive action visually separated with error color

**Approach**: Evolutionary extension — keep `_buildMenu()` as-is, add three new actions below the Save button with a visual separator, pass an action discriminator in the return value, swap `_handleMealTap` to open `RecipeSelectionDialog` instead of the bottom sheet.

---

## Checkpoint 3 — User Flow Map

### Flow A — Edit Existing Meal (Primary Flow)

1. **Entry** — User taps an existing planned meal slot on the weekly calendar
2. **Tap** — `_handleMealTap(date, mealType, recipeId)` called
3. **Data loading** — Screen fetches `MealPlanItem`: primary recipe, additional recipes, simple sides, planned servings, `hasBeenCooked`
4. **Dialog opens** — `RecipeSelectionDialog` in menu mode, pre-populated. User immediately sees the meal's content.
5. **Decision → one of five branches:**
   - **Save Changes** → `{action: 'save', ...}` → update meal plan item → SnackBar → refresh
   - **Mark as Cooked** → `{action: 'cooked'}` → existing mark-as-cooked logic → SnackBar
   - **View Details** (info icon on header) → `{action: 'view'}` → navigate to `RecipeDetailsScreen`
   - **Change Recipe** → `{action: 'change'}` → `_handleSlotTap(date, mealType)` (fresh selection)
   - **Remove from Plan** → `{action: 'remove'}` → confirm if cooked → remove → SnackBar → slot clears
6. **Exit** — Back on calendar, slot updated

### Flow B — New Meal Planning (Unchanged)

Empty slot → `_handleSlotTap` → `RecipeSelectionDialog` (selection mode) → pick recipe → `_buildMenu()` (new-meal) → Save Meal → slot filled. No changes.

### Decision Points

| At | Condition | Branch |
|---|---|---|
| Step 3 | DB fetch fails | SnackBar error, abort — no dialog |
| Step 4 | `mealCooked == true` | "Mark as Cooked" → "Edit Cooked Meal" |
| Step 5e | `mealCooked == true` | Warn: removing also deletes cooking record. Confirm/Cancel |
| Step 5e | `mealCooked == false` | Silent remove, no confirm |

### Error Paths

| Error | Response |
|---|---|
| DB fetch fails | SnackBar, dialog never opens |
| Save changes fails | Dialog stays open, SnackBar error |
| Mark as Cooked fails | SnackBar error, meal plan unchanged |
| Remove fails | SnackBar error, meal plan unchanged |
| Recipe not found (View Details) | SnackBar `recipeNotFound`, no navigation |

### Edge Cases

| Case | Behaviour |
|---|---|
| Meal has no side dishes | Only Add buttons shown in sides section |
| Meal already cooked | "Edit Cooked Meal" replaces "Mark as Cooked" |
| Recipe was deleted | DB fetch returns null → SnackBar error, no dialog |
| Save without changes | Allowed — DB write is idempotent |
| Cancel / tap-outside | No changes, calendar unchanged |

---

## Checkpoint 4 — Information Architecture

### Hierarchy

**Primary** — Recipe name (seen first, largest visual weight)

**Secondary** — Meal composition + adjustments:
- Side dishes (inline list + add buttons)
- Servings stepper

**Tertiary actions** — Operations on the meal:
- Save Changes (primary button)
- Mark as Cooked / Edit Cooked Meal
- Change Recipe
- View Details (via header info icon — not a separate row)

**Destructive zone** (visually separated):
- Remove from Plan

**Persistent escape**:
- Cancel (Dialog frame footer)

### Groups

| # | Name | Contents |
|---|---|---|
| 1 | Identity | Recipe name in `primaryContainer` container; trailing info icon (edit mode only) |
| 2 | Complete the Meal | Inline side dishes + Add Side Dish + Add Simple Side |
| 3 | Servings | ServingsStepper widget |
| 4 | Actions | Save Changes (primary); Mark as Cooked + Change Recipe (secondary pair) |
| 5 | Destructive zone | Divider + Remove from Plan |

### Progressive Disclosure

| Element | Visibility rule |
|---|---|
| Side dish list items | Only when sides exist |
| "Edit Cooked Meal" | Only when `mealCooked == true` |
| Groups 4 (secondary pair) and 5 | Only when `isEditMode == true` |
| Info icon on header | Only when `isEditMode == true` |
| Back TextButton | Hidden when `isEditMode == true` |
| Recipe tags / metadata | Not in this dialog — belongs in `RecipeDetailsScreen` |

### Label Decisions

| Context | Label | Key |
|---|---|---|
| Save button — edit mode | "Save Changes" | `saveChanges` |
| Save button — new-meal mode | "Save Meal" | `saveMeal` (unchanged) |
| Info icon tooltip | "View Recipe Details" | `viewRecipeDetails` |

**Zero new ARB strings needed.** All labels exist in both EN and PT.

---

## Checkpoint 5 — Wireframe & Interaction Design

### Edit Mode Layout

```
┌──────────────────────────────────────────┐
│              Meal Options                │  titleLarge, Dialog frame
├──────────────────────────────────────────┤
│ ┌────────────────────────────────────┐   │  GROUP 1: Identity
│ │ 🍽  Pasta Bolognese          [ⓘ]  │   │  primaryContainer bg, 12px radius
│ │     (bodyMedium bold)              │   │  InkWell wrapper (edit mode only)
│ └────────────────────────────────────┘   │  trailing: Icons.info_outline 20px
│  12px gap                                │
│ ┌────────────────────────────────────┐   │  GROUP 2: Complete the Meal
│ │  COMPLETE THE MEAL          label  │   │  outlined border, 8px radius
│ │  🍽  Garlic Bread             [✕]  │   │  each item: bodySmall + 16px icon
│ │  🥬  Side Salad               [✕]  │   │  remove: IconButton compact
│ │  [+ Add Side Dish    ] full-width  │   │  OutlinedButton h:40px
│ │  [+ Add Simple Side  ] full-width  │   │  6px between buttons
│ └────────────────────────────────────┘   │
│  12px gap                                │
│  ┌─────────────────────────────────┐     │  GROUP 3: Servings
│  │  [−]      4 servings      [+]  │     │  ServingsStepper (existing)
│  └─────────────────────────────────┘     │
│  12px gap                                │
│ ┌────────────────────────────────────┐   │  GROUP 4: Actions
│ │  [💾  Save Changes          ]      │   │  ElevatedButton full-width h:48px
│ └────────────────────────────────────┘   │
│  8px gap                                 │
│  [✓ Mark as Cooked] [↔ Change Recipe]   │  Row(Expanded + 8px gap + Expanded)
│  OutlinedButton     OutlinedButton       │  h:40px each
│  ─────────────────────────────────────  │  Divider(height: 20)
│  [  🗑  Remove from Plan  ]              │  GROUP 5: TextButton, errorColor
├──────────────────────────────────────────┤
│              [   Cancel   ]              │  Dialog frame, TextButton
└──────────────────────────────────────────┘
```

### New-Meal Mode Layout (unchanged)

```
┌──────────────────────────────────────────┐
│              Meal Options                │
├──────────────────────────────────────────┤
│  [recipe header — no info icon]          │
│  [complete meal section]                 │
│  [servings stepper]                      │
│  [💾  Save Meal            ] full-width  │
│  [← Back                  ] TextButton  │
├──────────────────────────────────────────┤
│              [   Cancel   ]              │
└──────────────────────────────────────────┘
```

### New Constructor Parameters

```dart
final bool isEditMode;          // default: false
final bool initialMealCooked;   // default: false
```

### Return Value Contracts

```dart
// Edit — Save Changes
{'action': 'save', 'primaryRecipe': Recipe, 'additionalRecipes': List<Recipe>,
 'plannedServings': int, 'simpleSides': List<Map<String, dynamic>>}

// Edit — Mark as Cooked
{'action': 'cooked'}

// Edit — Edit Cooked Meal
{'action': 'edit_cooked'}

// Edit — Change Recipe
{'action': 'change'}

// Edit — View Details (info icon)
{'action': 'view'}

// Edit — Remove from Plan
{'action': 'remove'}

// Cancel / dismiss
null

// New-meal — Save Meal (unchanged)
{'primaryRecipe': Recipe, 'additionalRecipes': List<Recipe>,
 'plannedServings': int, 'simpleSides': List<Map<String, dynamic>>}
```

### Key Interactions

| Interaction | Behaviour |
|---|---|
| Info icon tap | `Navigator.pop(context, {action: 'view'})` — edit mode only |
| Remove (cooked meal) | `showDialog` confirm → Remove or Cancel |
| Remove (uncooked meal) | Immediate `Navigator.pop(context, {action: 'remove'})` |
| Save without changes | Allowed — idempotent DB write |
| Cancel / tap-outside | `null` return — no changes |
| Change Recipe | Returns `{action: 'change'}` → `_handleSlotTap` called by screen |

---

## Checkpoint 6 — Accessibility Review

### Touch Targets

| Element | Size | Status |
|---|---|---|
| Info icon button | 48×48px (IconButton default) | ✅ |
| Save Changes | Full-width, h:48px | ✅ |
| Mark as Cooked / Change Recipe | Expanded, h:40px | ✅ |
| Remove from Plan | Full-width TextButton | ✅ |
| Side dish remove buttons | ~24×24px effective area | ⚠️ Pre-existing — out of scope |

### Screen Reader

- Info `IconButton`: `tooltip: l10n.viewRecipeDetails` → auto-used as a11y label
- All action buttons: text labels → read correctly
- Remove from Plan: error colour supplemented by explicit text label

### Color Contrast

All colours from Material theme — theme-guaranteed contrast for `primaryContainer`, `primary`, `error` combinations.

### Focus Order

Top → bottom: info icon → side item removes → add buttons → stepper → Save → Mark as Cooked → Change Recipe → Remove → Cancel

Natural DOM order — no `FocusTraversalOrder` needed.

### Localization

Zero new ARB strings. All labels exist in EN and PT. Longest PT button pair ("Marcar como Cozinhada" + "Trocar Receita") fits in `Expanded` columns at 16px.

---

## Follow-up Issue (post-#316)

Side dish remove buttons have a ~24×24px effective tap area (zeroed `padding` + `constraints`). Should be ≥44×44px. File as a separate accessibility issue after #316 ships — fixing it is out of scope here.

---

## Implementation Checklist

- [ ] Add `isEditMode` and `initialMealCooked` parameters to `RecipeSelectionDialog`
- [ ] Add info `IconButton` to recipe header row (edit mode only)
- [ ] Change Save button label to `saveChanges` when `isEditMode == true`
- [ ] Change Save button return value to include `action: 'save'` when `isEditMode == true`
- [ ] Add secondary action row (Mark as Cooked + Change Recipe) below Save — edit mode only
- [ ] Add Divider + Remove from Plan below action row — edit mode only
- [ ] Hide Back TextButton when `isEditMode == true`
- [ ] Add Remove confirmation dialog (cooked meals only)
- [ ] Replace `showModalBottomSheet` in `_handleMealTap` with data-load + `RecipeSelectionDialog` call
- [ ] Update `_handleMealTap` routing to read `result['action']`
- [ ] Widget tests: dialog opens in edit mode, each action returns correct value, cancel returns null, cooked/uncooked state renders correctly
