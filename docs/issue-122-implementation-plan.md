# Issue #122: Refine Add Ingredient Dialog UI - Implementation Plan

## Problem Summary
Current dialog (619 lines) is cluttered and overwhelming:
1. Database/Custom toggle occupies space for 1% use case
2. Search field + dropdown not clearly connected
3. Unit override checkbox confusing (should be direct selection)
4. "Create New" button placement clumsy
5. Focus wrong: should be "existing (common) vs create new (rare)"

## Solution Architecture

### Core Changes

**1. Unified Search/Autocomplete** (Replaces lines 308-444)
```
Current: SegmentedButton + Search TextField + Dropdown + "Create New" button
New: Single autocomplete field with inline results
```
- Search shows filtered ingredients from DB
- Bottom of results: "➕ Criar '[term]' como novo"
- Selecting item closes dropdown, populates selection
- Create option opens `AddNewIngredientDialog`

**2. Simplified Unit Selection** (Replaces lines 449-579)
```
Current: Display unit OR (checkbox + dropdown if override)
New: Always show dropdown pre-filled with default unit
```
- No checkbox needed
- Direct selection changes unit at model level (unitOverride)
- Q1: ✅ Confirmed behavior

**3. Progressive Disclosure for Custom Ingredients** (Moves lines 337-379)
```
Current: Toggle at top (takes prime real estate)
New: Link/button at bottom "⚙️ Usar ingrediente personalizado"
```
- Clicking expands inline OR replaces current view
- Shows: Name + Category + Unit (optional) fields
- Creates recipe-specific ingredient (NOT added to DB)
- Q2: ✅ Confirmed - Option A (recipe-specific only)

**4. Notes Field Position** (Keep lines 582-593, possibly reorder)
- Stays visible but marked optional
- Position after quantity/unit section

## Implementation Phases

### Phase 1: Preparation & Branch Setup
- [ ] Create branch: `enhancement/122-refine-add-ingredient-dialog`
- [ ] Read all 23 identified files for context
- [ ] Document current state transitions and data flow
- [ ] Identify all affected localization strings

### Phase 2: Localization Updates
**New/Modified strings needed:**
- `searchOrCreateIngredient` - "Buscar ou criar ingrediente..."
- `createNewWithTerm` - "Criar '{term}' como novo" (parameterized)
- `useCustomIngredient` - "Usar ingrediente personalizado"
- Remove: `fromDatabase`, `custom`, `overrideDefaultUnit`
- Modify: `searchIngredients`, `selectIngredient` (may consolidate)

**Files to update:**
- `lib/l10n/app_en.arb`
- `lib/l10n/app_pt.arb`
- Run `flutter gen-l10n` after changes

### Phase 3: Build Unified Search Component
**Approach (Q3: Flexible - mockup shows option 3, not strict):**
- Start with Flutter's `Autocomplete<Ingredient>` widget
- Custom builder for results presentation
- If Autocomplete insufficient → custom TextField + overlay
- Show search icon prefix
- Results: scrollable list + separator + create option

**State management:**
```dart
- _searchController (existing, line 41)
- _filteredIngredients (existing, line 42)
- _selectedIngredient (existing, line 46)
- Remove: _isCustomIngredient (line 57)
```

**Key methods to refactor:**
- `_filterIngredients()` (lines 220-233) - keep logic
- `_createNewIngredient()` (lines 268-282) - keep, call from results
- Remove SegmentedButton logic (lines 311-333)

### Phase 4: Simplify Unit Selection
**Changes:**
```dart
// REMOVE (lines 559-579):
- bool _useCustomUnit
- Checkbox widget
- Conditional display logic

// MODIFY (lines 449-556):
- Always show DropdownButtonFormField<String>
- Pre-fill with _selectedIngredient?.unit?.value
- onChange sets _selectedUnitOverride directly
- No checkbox, no conditional rendering
```

**Unit field logic:**
- Regular ingredient: pre-fill with `ingredient.unit`, allow change
- Custom ingredient: optional dropdown (current behavior OK per Q4)
- Model handles change detection (if different from default → unitOverride)

### Phase 5: Progressive Disclosure - Custom Ingredient
**Bottom link/button:**
```dart
TextButton.icon(
  icon: Icon(Icons.settings),
  label: Text(AppLocalizations.of(context)!.useCustomIngredient),
  onPressed: _toggleCustomIngredientMode,
)
```

**Behavior options (decide during implementation):**
- **Option A:** Expand inline - replace search section with name/category/unit
- **Option B:** Show fields below (less preferred - adds length)
- **Option C:** Modal bottom sheet (mobile-friendly)

**Keep existing custom ingredient logic (lines 132-143, 337-379):**
- `_customNameController`
- `_selectedCategory`
- Custom ingredient creation in `_addIngredientToRecipe()`

### Phase 6: Layout Reorganization
**New structure (lines 294-617 refactored):**
```dart
Form(
  child: SingleChildScrollView(
    child: Column([
      // 1. Unified Search/Autocomplete (NEW)
      if (!_isCustomIngredient) UnifiedIngredientSearch(...),

      // 2. Custom ingredient fields (MOVED, CONDITIONAL)
      if (_isCustomIngredient) ...[
        CustomIngredientNameField(),
        CategoryDropdown(),
      ],

      // 3. Quantity + Unit Row (SIMPLIFIED)
      Row([
        QuantityField(),  // Keep as-is
        UnitDropdown(),   // Always visible, no checkbox
      ]),

      // 4. Preparation Notes (KEEP)
      NotesField(),

      // 5. Custom Ingredient Link (NEW)
      if (!_isCustomIngredient) CustomIngredientToggleButton(),
    ]),
  ),
)
```

### Phase 7: Testing Updates
**Files to update:**
- `test/widgets/add_ingredient_dialog_test.dart`

**Test scenarios to add/modify:**
1. Unified search filters ingredients correctly
2. "Create new" option appears when no matches
3. Selecting ingredient pre-fills unit
4. Changing unit sets unitOverride
5. Custom ingredient toggle shows/hides appropriate fields
6. All existing functionality preserved
7. Validation still works

**Keep existing tests:**
- DI tests (lines 66-144)
- Database interaction tests
- Validation tests

### Phase 8: Validation & Polish
- [ ] Run `flutter analyze` - must pass
- [ ] Run `flutter test` - all tests green
- [ ] Manual testing: add ingredients in various scenarios
- [ ] Test responsive design (different screen sizes)
- [ ] Verify accessibility (screen reader support)
- [ ] Check both English and Portuguese localizations

## Technical Considerations

**Maintain existing architecture:**
- Dependency injection via `databaseHelper` parameter
- `onSave` callback pattern
- `existingIngredient` editing mode
- All exception handling (ValidationException, DuplicateException, etc.)

**Performance:**
- Ingredient filtering should remain efficient (< 1000 ingredients)
- Autocomplete debouncing if needed (not currently implemented)

**Backwards compatibility:**
- Database schema unchanged
- RecipeIngredient model unchanged (lines 1-63)
- All database operations unchanged

**Edge cases to handle:**
- Empty search (show all ingredients? or empty?)
- No ingredients in database
- Editing existing ingredient (pre-select in autocomplete)
- Custom ingredient editing (switch to custom mode)

## Files Requiring Changes

**Primary:**
1. `lib/widgets/add_ingredient_dialog.dart` - Major refactoring (lines 294-617)
2. `lib/l10n/app_en.arb` - Add/modify strings
3. `lib/l10n/app_pt.arb` - Add/modify strings
4. `test/widgets/add_ingredient_dialog_test.dart` - Update tests

**No changes needed:**
- Data models (all remain unchanged)
- Database helper
- Validation logic
- Service providers
- Screens using the dialog (API unchanged)

## Risk Assessment

**Low risk:**
- Localization changes (isolated, easily testable)
- Unit field simplification (removes code, less complex)
- Custom ingredient toggle (moves existing code)

**Medium risk:**
- Unified search/autocomplete (new component, user-facing)
- State management changes (removing _isCustomIngredient early)
- Layout reorganization (visual regression possible)

**Mitigation:**
- Incremental implementation (one phase at a time)
- Test after each phase
- Keep git commits atomic for easy rollback
- Manual testing on real device/emulator

## Success Criteria

✅ All features from current dialog work identically
✅ UI is simpler and less cluttered
✅ Search + create flow is unified and intuitive
✅ Unit selection is direct (no checkbox)
✅ Custom ingredient option hidden until needed
✅ All tests pass (flutter analyze + flutter test)
✅ Both English and Portuguese strings correct
✅ Responsive design maintained

## Key Decisions

1. **Q1:** Unit field always visible, no checkbox - change tracked at model level ✅
2. **Q2:** Custom ingredient = recipe-specific only (not added to DB) ✅
3. **Q3:** Flexible on autocomplete implementation (start with Flutter's Autocomplete) ✅
4. **Q4:** Custom ingredient unit handling - keep current simple approach ✅

## UI Mockup Reference

```
┌─────────────────────────────────────────┐
│  Adicionar Ingrediente                  │
├─────────────────────────────────────────┤
│                                         │
│  Ingrediente                            │
│  ┌───────────────────────────────────┐ │
│  │ 🔍 Buscar ou criar ingrediente... │ │
│  └───────────────────────────────────┘ │
│  ┌───────────────────────────────────┐ │
│  │ Tomate                            │ │
│  │ Tomate cereja                     │ │
│  │ Tomate seco                       │ │
│  │ ─────────────────────────────────  │ │
│  │ ➕ Criar "tomat" como novo       │ │
│  └───────────────────────────────────┘ │
│                                         │
│  ┌──────────────┐  ┌─────────────────┐│
│  │ Quantidade   │  │ Unidade         ││
│  │ 2            │  │ kg ▼            ││
│  └──────────────┘  └─────────────────┘│
│                                         │
│  Notas de Preparo (Opcional)            │
│  ┌───────────────────────────────────┐ │
│  │ picado, em cubos, etc.            │ │
│  └───────────────────────────────────┘ │
│                                         │
│  ┌─────────────────────────────────┐  │
│  │ ⚙️ Usar ingrediente personalizado│  │
│  └─────────────────────────────────┘  │
│                                         │
│              [Cancelar]  [Adicionar]    │
└─────────────────────────────────────────┘
```
