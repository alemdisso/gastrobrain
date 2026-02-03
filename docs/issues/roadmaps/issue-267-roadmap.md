# Issue #267: Add Shopping List Refinement Mode (Stage 2)

**Type:** Enhancement (Feature)
**Priority:** P2-Medium
**Milestone:** 0.1.7b - Screen & Component Polish
**Labels:** enhancement, UI, UX
**Related Issues:** #258 (UX redesign), #5 (shopping list), #266 (Stage 1)
**Last Updated:** 2026-02-03

## Overview

Implement Stage 2 (Refinement Mode) of the three-stage shopping list workflow designed in #258. This solves the "duplicate ingredients" problem where users often have pantry staples (oil, salt, onions, etc.) at home but currently ALL ingredients get added to shopping lists.

Refinement mode adds an interactive curation step between planning and shopping, allowing users to:
- Review all projected ingredients before finalizing
- Uncheck items they already own
- Optionally adjust quantities
- Generate the final shopping list from only selected items

**Key characteristics:**
- Interactive curation (checkboxes, select all/none)
- All items checked by default (opt-out model)
- Validation (prevents empty list generation)
- No database writes until user confirms
- Replaces immediate list generation

## Prerequisites Check

Before starting implementation:

- [ ] Review design reference: `docs/design/ux/issue-258-ux-redesign.md` lines 192-224
- [ ] Confirm #266 (Stage 1 Preview) is complete (can reuse projection logic)
- [ ] Review existing `ShoppingListService.generateShoppingList()` flow
- [ ] Review bottom sheet patterns from #258 and #266
- [ ] Understand current "Generate Shopping List" flow in `weekly_plan_screen.dart`

## Phase 1: Analysis & Understanding

### Understand Existing Code

- [ ] Read `lib/screens/weekly_plan_screen.dart` - Focus on `_handleGenerateShoppingList()` method
- [ ] Read `lib/services/shopping_list_service.dart` - Understand current generation flow
- [ ] Read `lib/widgets/shopping_list_preview_bottom_sheet.dart` - Review Stage 1 UI patterns (from #266)
- [ ] Review how "Regenerate" dialog works for existing lists
- [ ] Identify where shopping list navigation happens after generation

### Identify Similar Patterns

- [ ] Check checkbox list patterns in existing codebase
- [ ] Check how Stage 1 (#266) displays grouped ingredients
- [ ] Check validation patterns for form submissions
- [ ] Check "Select All"/"Deselect All" patterns if they exist elsewhere
- [ ] Review how other bottom sheets handle user confirmation

### Plan Data Flow

- [ ] Design refinement state management (StatefulWidget in bottom sheet)
- [ ] Plan how to track checked/unchecked items
- [ ] Plan how to pass curated list back to caller
- [ ] Design cancellation handling (no database writes)
- [ ] Plan quantity adjustment state (if implementing)

### Plan UI Component

- [ ] Design `ShoppingListRefinementBottomSheet` widget structure
- [ ] Plan checkbox list item widget
- [ ] Plan category section headers with checkboxes
- [ ] Plan "Select All" / "Deselect All" controls
- [ ] Plan validation UI (show error if no items selected)
- [ ] Plan "Generate Shopping List" confirmation button state

## Phase 2: Implementation

### Create Refinement Bottom Sheet Widget

- [ ] Create `lib/widgets/shopping_list_refinement_bottom_sheet.dart`
- [ ] Implement `ShoppingListRefinementBottomSheet` as StatefulWidget
  - Accept `Map<String, List<Ingredient>> projectedIngredients` parameter
  - Return `List<Ingredient>?` (null if cancelled)
  - Use `DraggableScrollableSheet` for bottom sheet behavior
- [ ] Add header with title and "Select All" / "Deselect All" buttons
- [ ] Implement category sections with headers
- [ ] Implement checkbox list items for ingredients
  - Checkbox widget
  - Ingredient name, quantity, unit display
  - Optional: Quantity adjustment stepper
- [ ] Implement state tracking for checked items
- [ ] Add validation logic (at least one item must be selected)
- [ ] Add "Generate Shopping List" button with validation feedback
- [ ] Handle cancellation (return null)
- [ ] Style with design tokens from #258

### Update Generation Flow in WeeklyPlanScreen

- [ ] Open `lib/screens/weekly_plan_screen.dart`
- [ ] Modify `_handleGenerateShoppingList()` method:
  - Calculate date range from current week
  - Call projection logic (reuse from #266 if available)
  - Show `ShoppingListRefinementBottomSheet` with projected ingredients
  - Wait for user curation (selected items)
  - If cancelled (null), return early (no database write)
  - If confirmed, generate shopping list with only selected items
  - Navigate to `ShoppingListScreen` with generated list
- [ ] Handle errors gracefully (show snackbar or dialog)

### Update ShoppingListService

- [ ] Open `lib/services/shopping_list_service.dart`
- [ ] Update `generateShoppingList()` method or create new method:
  - Accept optional `List<Ingredient> selectedIngredients` parameter
  - If provided, use only these ingredients (not all from meal plan)
  - Maintain existing aggregation logic
  - Return generated shopping list ID
- [ ] Ensure quantities from refinement are preserved

### Update Regeneration Flow

- [ ] Locate "Regenerate" dialog logic in `weekly_plan_screen.dart`
- [ ] Update regeneration flow to also show refinement sheet
- [ ] Flow: Confirm regenerate → Delete old list → Show refinement → Generate new curated list

### Add Localization

- [ ] Open `lib/l10n/app_en.arb`
- [ ] Add strings:
  - `shoppingListRefinementTitle`: "Refine Shopping List"
  - `shoppingListRefinementSelectAll`: "Select All"
  - `shoppingListRefinementDeselectAll`: "Deselect All"
  - `shoppingListRefinementGenerate`: "Generate Shopping List"
  - `shoppingListRefinementValidation`: "Please select at least one item"
  - `shoppingListRefinementEmpty`: "No ingredients to refine"
- [ ] Open `lib/l10n/app_pt.arb`
- [ ] Add Portuguese translations:
  - `shoppingListRefinementTitle`: "Refinar Lista de Compras"
  - `shoppingListRefinementSelectAll`: "Selecionar Tudo"
  - `shoppingListRefinementDeselectAll`: "Desselecionar Tudo"
  - `shoppingListRefinementGenerate`: "Gerar Lista de Compras"
  - `shoppingListRefinementValidation`: "Por favor, selecione pelo menos um item"
  - `shoppingListRefinementEmpty`: "Nenhum ingrediente para refinar"
- [ ] Run `flutter gen-l10n` to generate localization code
- [ ] Update widget to use `AppLocalizations.of(context)!.shoppingListRefinement*`

### Code Quality

- [ ] Run `flutter analyze` - resolve any issues
- [ ] Verify no hardcoded strings remain
- [ ] Add code comments explaining Stage 2 workflow
- [ ] Ensure proper error handling throughout
- [ ] Verify no database writes on cancellation

## Phase 3: Testing

### Unit Tests - Service Layer

Update `test/unit/shopping_list_service_test.dart`:

- [ ] Test `generateShoppingList()` with curated ingredient list
  - Verify only selected ingredients included
  - Verify quantities preserved from refinement
- [ ] Test generation with empty list returns error/validation failure
- [ ] Test generation maintains category grouping
- [ ] Test existing generation still works (no selected ingredients parameter)

### Widget Tests - Refinement Bottom Sheet

Create `test/widget/shopping_list_refinement_bottom_sheet_test.dart`:

- [ ] Test displays projected ingredients with checkboxes
  - Verify all items checked by default
  - Verify category headers render
- [ ] Test checkbox interaction
  - Tap to uncheck item
  - Tap to check item
  - Verify state updates correctly
- [ ] Test "Select All" button
  - Unchecks some items → Tap "Select All" → All items checked
- [ ] Test "Deselect All" button
  - Tap "Deselect All" → All items unchecked
- [ ] Test validation
  - Uncheck all items → Tap "Generate" → Shows validation error
  - At least one item checked → "Generate" button enabled
- [ ] Test cancellation
  - Close bottom sheet → Returns null
  - Press back button → Returns null
- [ ] Test generates with selected items
  - Uncheck 2 items → Tap "Generate" → Returns list with only checked items
- [ ] Test optional quantity adjustment (if implemented)
  - Increase quantity → State updates
  - Decrease quantity → State updates

### Widget Tests - Integration with WeeklyPlanScreen

Update `test/widget/weekly_plan_screen_test.dart`:

- [ ] Test "Generate Shopping List" button opens refinement sheet
- [ ] Test cancelling refinement does not create shopping list
  - Verify database unchanged
- [ ] Test confirming refinement creates shopping list
  - Verify navigation to ShoppingListScreen
  - Verify only selected items in list
- [ ] Test regeneration flow includes refinement
- [ ] Test error handling displays user-friendly message

### Edge Case Tests

Create `test/edge_cases/empty_states/shopping_list_refinement_empty_test.dart`:

- [ ] Test empty meal plan shows appropriate message
- [ ] Test all items unchecked shows validation message

Create `test/edge_cases/boundary_conditions/shopping_list_refinement_boundary_test.dart`:

- [ ] Test single ingredient selection works
- [ ] Test many ingredients (30+) scroll and interact properly
- [ ] Test selecting/deselecting many items at once

Create `test/edge_cases/interaction_patterns/shopping_list_refinement_interaction_test.dart`:

- [ ] Test rapid checkbox toggling
- [ ] Test alternating select all/deselect all
- [ ] Test quantity adjustment edge cases (if implemented)

Create `test/edge_cases/error_scenarios/shopping_list_refinement_error_test.dart`:

- [ ] Test database error during generation shows error message
- [ ] Test projection error handled gracefully
- [ ] Test partial generation failure (verify no partial list created)

Create `test/edge_cases/data_integrity/shopping_list_refinement_integrity_test.dart`:

- [ ] Test cancellation leaves database unchanged
- [ ] Test no orphaned records created on error
- [ ] Test quantities preserved correctly from refinement to final list

### Localization Testing

- [ ] Manually test English localization displays correctly
- [ ] Manually test Portuguese localization displays correctly
- [ ] Verify text fits in UI for both languages (especially buttons)
- [ ] Verify validation messages display correctly in both languages

### Regression Testing

- [ ] Run full test suite: `flutter test`
- [ ] Verify Stage 1 (Preview) still works
- [ ] Verify "View Shopping List" still works
- [ ] Verify existing shopping lists display correctly
- [ ] Test weekly plan screen functionality unchanged

## Phase 4: Documentation & Cleanup

### Update Comments

- [ ] Add docstring to `ShoppingListRefinementBottomSheet` widget
- [ ] Add inline comments explaining Stage 2 workflow
- [ ] Document opt-out model (all checked by default)
- [ ] Document validation logic

### Update UX Documentation

- [ ] Update `docs/design/ux/issue-258-ux-redesign.md` with implementation notes
- [ ] Mark Stage 2 as complete in design doc

### Final Verification

- [ ] Run `flutter analyze` - confirm zero issues
- [ ] Run `flutter test` - confirm all tests pass
- [ ] Manual testing on both platforms (if possible)
- [ ] Test on small screen sizes (verify no overflow, scrolling works)
- [ ] Test on large screen sizes (verify proper display)
- [ ] Test complete workflow: Plan meals → Refine → Shop

### Git Workflow

- [ ] Create feature branch: `git checkout -b enhancement/267-shopping-list-refinement-mode`
- [ ] Commit changes with proper message:
  ```
  enhancement: add shopping list refinement mode before shopping (#267)

  Implements Stage 2 (Refinement Mode) of three-stage shopping list workflow.
  Users can now curate projected ingredients before generating final shopping
  list, unchecking items they already own. Prevents duplicate purchases and
  wasted money.

  - Add ShoppingListRefinementBottomSheet widget with checkboxes
  - Update generation flow in WeeklyPlanScreen
  - Add "Select All" / "Deselect All" convenience controls
  - Add validation to prevent empty list generation
  - Add localization (EN/PT)
  - Add comprehensive tests (unit, widget, edge cases, data integrity)

  Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
  ```
- [ ] Push to origin: `git push -u origin enhancement/267-shopping-list-refinement-mode`
- [ ] Merge to develop: `git checkout develop && git merge enhancement/267-shopping-list-refinement-mode`
- [ ] Push develop: `git push origin develop`
- [ ] Close issue #267 with reference to commit
- [ ] Delete feature branch: `git branch -d enhancement/267-shopping-list-refinement-mode`

## Files to Modify

**Service Layer:**
- `lib/services/shopping_list_service.dart` - Update generation to accept curated list

**UI Components:**
- `lib/screens/weekly_plan_screen.dart` - Update generation and regeneration flows
- `lib/widgets/shopping_list_refinement_bottom_sheet.dart` - NEW widget

**Localization:**
- `lib/l10n/app_en.arb` - Add English strings
- `lib/l10n/app_pt.arb` - Add Portuguese strings

**Tests:**
- `test/unit/shopping_list_service_test.dart` - Update existing tests
- `test/widget/shopping_list_refinement_bottom_sheet_test.dart` - NEW widget tests
- `test/widget/weekly_plan_screen_test.dart` - Update existing tests
- `test/edge_cases/empty_states/shopping_list_refinement_empty_test.dart` - NEW edge case tests
- `test/edge_cases/boundary_conditions/shopping_list_refinement_boundary_test.dart` - NEW edge case tests
- `test/edge_cases/interaction_patterns/shopping_list_refinement_interaction_test.dart` - NEW edge case tests
- `test/edge_cases/error_scenarios/shopping_list_refinement_error_test.dart` - NEW edge case tests
- `test/edge_cases/data_integrity/shopping_list_refinement_integrity_test.dart` - NEW edge case tests

## Testing Strategy

### Coverage Target
- Service layer: >85% (updated generation logic)
- Widget layer: >85% (refinement bottom sheet)
- Edge cases: 100% (all documented edge cases)
- Data integrity: 100% (cancellation, errors)

### Test Types

**Unit Tests (Service Layer):**
- Generation with curated ingredient list
- Quantity preservation
- Edge cases (empty list validation)

**Widget Tests (UI Components):**
- Checkbox interaction
- Select All / Deselect All
- Validation feedback
- Confirmation and cancellation
- Integration with WeeklyPlanScreen

**Edge Case Tests:**
- Empty states: No ingredients, all unchecked
- Boundary conditions: Single item, many items
- Interaction patterns: Rapid toggling, alternating select/deselect
- Error scenarios: Database errors, projection errors
- Data integrity: Cancellation, no orphaned records

### Test Execution
- Run unit tests first: `flutter test test/unit/shopping_list_service_test.dart`
- Run widget tests: `flutter test test/widget/shopping_list_refinement_*`
- Run edge case tests: `flutter test test/edge_cases/*/shopping_list_refinement_*`
- Run regression tests: `flutter test test/widget/weekly_plan_screen_test.dart`
- Run full suite: `flutter test`

## Acceptance Criteria

From issue + implicit requirements:

- [ ] "Generate Shopping List" button opens refinement bottom sheet (not direct generation)
- [ ] Refinement sheet shows all projected ingredients with checkboxes
- [ ] All items are checked by default (opt-out model)
- [ ] Ingredients grouped by category with clear section headers
- [ ] User can check/uncheck individual items
- [ ] "Select All" and "Deselect All" convenience buttons work correctly
- [ ] Optional: Quantity adjustment controls work (if implemented)
- [ ] "Generate Shopping List" button creates list with only checked items
- [ ] Validation: Cannot generate empty list (at least one item must be selected)
- [ ] Canceling refinement (close/back) does NOT create shopping list
- [ ] Regeneration flow also shows refinement sheet
- [ ] Final shopping list in `ShoppingListScreen` contains only selected items
- [ ] Localized in both English and Portuguese
- [ ] All tests pass: `flutter analyze && flutter test`
- [ ] No regressions in existing shopping list functionality (Stage 1, Stage 3)
- [ ] No database writes on cancellation
- [ ] Error states display user-friendly messages

## Risk Assessment

### Low Risk
- ✅ UI-only state until confirmation
- ✅ Clear design reference from #258
- ✅ Can reuse projection logic from #266

### Medium Risk
- ⚠️ Complex state management (many checkboxes, potential quantity adjustments)
  - **Mitigation:** Keep state simple, use StatefulWidget pattern
- ⚠️ Validation logic complexity (must prevent empty list)
  - **Mitigation:** Simple count check, clear error messaging
- ⚠️ Cancellation must not modify database
  - **Mitigation:** Extensive data integrity tests

### High Risk
- ❌ Performance with many ingredients (50+ checkboxes)
  - **Mitigation:** Test with large meal plans, optimize if needed
  - **Mitigation:** Consider lazy loading or virtualized list if performance issues

### Dependencies
- **Requires:** #266 complete (can reuse projection logic)
- **Blocks:** None
- **Related:** Completes three-stage workflow with #5 (Stage 3)

## Notes

- Stage 2 adds significant value: prevents duplicate ingredient purchases
- Opt-out model (all checked by default) is intentional - users remove what they have
- Validation is critical - empty shopping list generation would be confusing
- Quantity adjustment is optional feature - defer if complex
- Stage 3 (shopping mode) already exists from #5
- Three-stage workflow now complete: Preview → Refine → Shop
