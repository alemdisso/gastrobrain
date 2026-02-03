# Issue #266: Add Shopping List Preview Mode (Stage 1)

**Type:** Enhancement (Feature)
**Priority:** P2-Medium
**Milestone:** 0.1.7b - Screen & Component Polish
**Labels:** enhancement, UI, UX
**Related Issues:** #258 (UX redesign), #5 (shopping list), #267 (Stage 2)
**Last Updated:** 2026-02-03

## Overview

Implement Stage 1 (Preview Mode) of the three-stage shopping list workflow designed in #258. This allows users to see "What would I need to buy if I cooked these meals?" during active meal planning, enabling better planning decisions by previewing ingredient requirements and costs before committing to recipes.

Currently, the "Preview Ingredients" button in `weekly_plan_screen.dart:1026` shows a "Coming Soon" snackbar. This issue replaces the placeholder with fully functional preview capability.

**Key characteristics:**
- Read-only preview (no checkboxes, no database writes)
- Shows aggregated ingredients grouped by category
- Ephemeral calculation (recalculates for current week)
- Bottom sheet UI pattern (consistent with #258)

## Prerequisites Check

Before starting implementation:

- [ ] Review design reference: `docs/design/ux/issue-258-ux-redesign.md` lines 192-224
- [ ] Confirm #258 (Polish Weekly Planning Screen) is complete
- [ ] Review existing `ShoppingListScreen` for ingredient grouping patterns
- [ ] Review existing bottom sheet implementations in `weekly_plan_screen.dart`
- [ ] Verify `ShoppingListService` structure and current generation logic

## Phase 1: Analysis & Understanding

### Understand Existing Code

- [ ] Read `lib/screens/weekly_plan_screen.dart` - Focus on shopping list bottom sheet (line ~990-1050)
- [ ] Read `lib/services/shopping_list_service.dart` - Understand current ingredient aggregation logic
- [ ] Read `lib/screens/shopping_list_screen.dart` - Review category grouping display patterns
- [ ] Read placeholder implementation at `_showShoppingPreview()` (line 1026)
- [ ] Review existing bottom sheet patterns in `WeeklyPlanScreen` (summary sheet, shopping options sheet)

### Identify Similar Patterns

- [ ] Check how `ShoppingListService.generateShoppingList()` aggregates ingredients from meal plans
- [ ] Check how `ShoppingListScreen` displays grouped ingredients
- [ ] Check how bottom sheets are implemented in #258 (DraggableScrollableSheet pattern)
- [ ] Identify category grouping logic (Proteins, Vegetables, Grains, etc.)

### Plan Service Layer Changes

- [ ] Determine if existing aggregation logic can be extracted/reused
- [ ] Plan signature for new `calculateProjectedIngredients(DateTime startDate, DateTime endDate)` method
- [ ] Confirm return type: `Map<String, List<Ingredient>>` (category → ingredients)
- [ ] Verify no database writes in projection logic

### Plan UI Component

- [ ] Design `ShoppingListPreviewBottomSheet` widget structure
- [ ] Plan loading state display
- [ ] Plan empty state message
- [ ] Plan error state handling
- [ ] Design category section headers and ingredient list items

## Phase 2: Implementation

### Extract Projection Logic in Service

- [ ] Open `lib/services/shopping_list_service.dart`
- [ ] Create `calculateProjectedIngredients(DateTime startDate, DateTime endDate)` method
  - Query meal plan items for date range
  - Aggregate ingredients from all recipes
  - Group by category
  - Return `Map<String, List<Ingredient>>` (no database writes)
- [ ] Extract/reuse aggregation logic from existing `generateShoppingList()` if applicable
- [ ] Handle edge cases (empty meal plan, missing recipes)
- [ ] Add error handling (database errors, null safety)

### Create Preview Bottom Sheet Widget

- [ ] Create `lib/widgets/shopping_list_preview_bottom_sheet.dart`
- [ ] Implement `ShoppingListPreviewBottomSheet` as StatelessWidget
  - Accept `Map<String, List<Ingredient>> groupedIngredients` parameter
  - Use `DraggableScrollableSheet` for bottom sheet behavior
- [ ] Add header with title (localized)
- [ ] Implement category sections with headers
- [ ] Display ingredient items (name, quantity, unit) - read-only
- [ ] Add loading state widget
- [ ] Add empty state widget with message
- [ ] Add error state widget
- [ ] Style with design tokens from #258

### Wire Up in WeeklyPlanScreen

- [ ] Open `lib/screens/weekly_plan_screen.dart`
- [ ] Replace `_showShoppingPreview()` placeholder implementation
  - Calculate date range from `_currentWeekStart`
  - Show loading indicator
  - Call `ShoppingListService.calculateProjectedIngredients()`
  - Show `ShoppingListPreviewBottomSheet` with results
  - Handle errors with user-friendly message
- [ ] Remove TODO comment
- [ ] Test preview updates when navigating weeks

### Add Localization

- [ ] Open `lib/l10n/app_en.arb`
- [ ] Add strings:
  - `shoppingListPreviewTitle`: "Projected Ingredients"
  - `shoppingListPreviewEmpty`: "No meals planned - nothing to preview"
  - `shoppingListPreviewError`: "Error loading ingredients"
  - `shoppingListPreviewLoading`: "Calculating ingredients..."
- [ ] Open `lib/l10n/app_pt.arb`
- [ ] Add Portuguese translations:
  - `shoppingListPreviewTitle`: "Ingredientes Projetados"
  - `shoppingListPreviewEmpty`: "Nenhuma refeição planejada - nada para visualizar"
  - `shoppingListPreviewError`: "Erro ao carregar ingredientes"
  - `shoppingListPreviewLoading`: "Calculando ingredientes..."
- [ ] Run `flutter gen-l10n` to generate localization code
- [ ] Update widget to use `AppLocalizations.of(context)!.shoppingListPreview*`

### Code Quality

- [ ] Run `flutter analyze` - resolve any issues
- [ ] Verify no hardcoded strings remain
- [ ] Add code comments explaining Stage 1 workflow
- [ ] Ensure proper error handling throughout

## Phase 3: Testing

### Unit Tests - Service Layer

Create `test/unit/shopping_list_service_projection_test.dart`:

- [ ] Test `calculateProjectedIngredients()` with sample meal plan
  - Verify ingredients aggregated correctly
  - Verify quantities summed for duplicate ingredients
  - Verify grouped by category
- [ ] Test empty meal plan returns empty map
- [ ] Test single meal returns correct ingredients
- [ ] Test multiple meals aggregate correctly
- [ ] Test date range filtering works
- [ ] Test handles missing recipes gracefully
- [ ] Test database error handling

### Widget Tests - Preview Bottom Sheet

Create `test/widget/shopping_list_preview_bottom_sheet_test.dart`:

- [ ] Test displays grouped ingredients correctly
  - Verify category headers render
  - Verify ingredient items render with name, quantity, unit
- [ ] Test empty state displays correct message
- [ ] Test loading state displays spinner/indicator
- [ ] Test error state displays error message
- [ ] Test scrolling works with many ingredients (20+)
- [ ] Test category sections render in correct order

### Widget Tests - Integration with WeeklyPlanScreen

Update `test/widget/weekly_plan_screen_test.dart`:

- [ ] Test "Preview Ingredients" button opens preview bottom sheet
- [ ] Test preview shows correct ingredients from current week
- [ ] Test preview is read-only (no interaction elements)
- [ ] Test preview updates when navigating to different week
- [ ] Test preview handles empty meal plan
- [ ] Test preview handles database error

### Edge Case Tests

Create `test/edge_cases/empty_states/shopping_list_preview_empty_test.dart`:

- [ ] Test empty meal plan shows appropriate message
- [ ] Test week with no recipes shows empty state

Create `test/edge_cases/boundary_conditions/shopping_list_preview_boundary_test.dart`:

- [ ] Test single ingredient displays correctly
- [ ] Test many ingredients (30+) scroll properly
- [ ] Test duplicate ingredients aggregate quantities

Create `test/edge_cases/error_scenarios/shopping_list_preview_error_test.dart`:

- [ ] Test database error shows error message
- [ ] Test null/missing recipe data handled gracefully
- [ ] Test service exception displays user-friendly error

### Localization Testing

- [ ] Manually test English localization displays correctly
- [ ] Manually test Portuguese localization displays correctly
- [ ] Verify text fits in UI for both languages
- [ ] Verify date/number formats use locale-appropriate patterns (if applicable)

### Regression Testing

- [ ] Run full test suite: `flutter test`
- [ ] Verify no regressions in existing shopping list functionality
- [ ] Verify no regressions in weekly plan screen functionality
- [ ] Test "View Shopping List" and "Generate Shopping List" still work

## Phase 4: Documentation & Cleanup

### Update Comments

- [ ] Update TODO comment in `weekly_plan_screen.dart` (remove or mark complete)
- [ ] Add docstring to `calculateProjectedIngredients()` method
- [ ] Add docstring to `ShoppingListPreviewBottomSheet` widget
- [ ] Add inline comments explaining Stage 1 workflow

### Final Verification

- [ ] Run `flutter analyze` - confirm zero issues
- [ ] Run `flutter test` - confirm all tests pass
- [ ] Manual testing on both platforms (if possible)
- [ ] Test on small screen sizes (verify no overflow)
- [ ] Test on large screen sizes (verify proper display)

### Git Workflow

- [ ] Create feature branch: `git checkout -b enhancement/266-shopping-list-preview-mode`
- [ ] Commit changes with proper message:
  ```
  enhancement: add shopping list preview mode during meal planning (#266)

  Implements Stage 1 (Preview Mode) of three-stage shopping list workflow.
  Users can now preview projected ingredients from current week's meal plan
  without committing to database. Read-only bottom sheet displays ingredients
  grouped by category.

  - Add ShoppingListService.calculateProjectedIngredients()
  - Create ShoppingListPreviewBottomSheet widget
  - Wire up preview button in WeeklyPlanScreen
  - Add localization (EN/PT)
  - Add comprehensive tests (unit, widget, edge cases)

  Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
  ```
- [ ] Push to origin: `git push -u origin enhancement/266-shopping-list-preview-mode`
- [ ] Merge to develop: `git checkout develop && git merge enhancement/266-shopping-list-preview-mode`
- [ ] Push develop: `git push origin develop`
- [ ] Close issue #266 with reference to commit
- [ ] Delete feature branch: `git branch -d enhancement/266-shopping-list-preview-mode`

## Files to Modify

**Service Layer:**
- `lib/services/shopping_list_service.dart` - Add projection method

**UI Components:**
- `lib/screens/weekly_plan_screen.dart` - Replace placeholder implementation
- `lib/widgets/shopping_list_preview_bottom_sheet.dart` - NEW widget

**Localization:**
- `lib/l10n/app_en.arb` - Add English strings
- `lib/l10n/app_pt.arb` - Add Portuguese strings

**Tests:**
- `test/unit/shopping_list_service_projection_test.dart` - NEW unit tests
- `test/widget/shopping_list_preview_bottom_sheet_test.dart` - NEW widget tests
- `test/widget/weekly_plan_screen_test.dart` - Update existing tests
- `test/edge_cases/empty_states/shopping_list_preview_empty_test.dart` - NEW edge case tests
- `test/edge_cases/boundary_conditions/shopping_list_preview_boundary_test.dart` - NEW edge case tests
- `test/edge_cases/error_scenarios/shopping_list_preview_error_test.dart` - NEW edge case tests

## Testing Strategy

### Coverage Target
- Service layer: >90% (new projection method)
- Widget layer: >80% (preview bottom sheet)
- Edge cases: 100% (all documented edge cases)

### Test Types

**Unit Tests (Service Layer):**
- Projection calculation correctness
- Ingredient aggregation logic
- Category grouping
- Edge cases (empty, errors)

**Widget Tests (UI Components):**
- Bottom sheet renders correctly
- Grouped ingredients display
- Loading/empty/error states
- Read-only behavior
- Integration with WeeklyPlanScreen

**Edge Case Tests:**
- Empty states: No meals planned
- Boundary conditions: Single ingredient, many ingredients
- Error scenarios: Database errors, missing data

### Test Execution
- Run unit tests first: `flutter test test/unit/shopping_list_service_projection_test.dart`
- Run widget tests: `flutter test test/widget/shopping_list_preview_*`
- Run edge case tests: `flutter test test/edge_cases/*/shopping_list_preview_*`
- Run full suite: `flutter test`

## Acceptance Criteria

From issue + implicit requirements:

- [ ] "Preview Ingredients" button opens bottom sheet with projected ingredients
- [ ] Preview shows ingredients grouped by category (Proteins, Vegetables, Grains, etc.)
- [ ] Preview displays quantities aggregated from all meals in current week
- [ ] Preview is read-only (no checkboxes, no "mark purchased" actions)
- [ ] No database writes occur (ephemeral calculation)
- [ ] Preview updates correctly when user navigates to different weeks
- [ ] Empty meal plan shows helpful message ("No meals planned - nothing to preview")
- [ ] Localized in both English and Portuguese
- [ ] All tests pass: `flutter analyze && flutter test`
- [ ] No regressions in existing shopping list functionality
- [ ] Loading state displays while calculating
- [ ] Error state displays user-friendly message on failure
- [ ] Bottom sheet scrolls properly with many ingredients
- [ ] Follows design patterns from #258 (bottom sheet, visual styling)

## Risk Assessment

### Low Risk
- ✅ No database schema changes
- ✅ No changes to existing shopping list generation
- ✅ Read-only feature (no data modification)
- ✅ Clear design reference from #258

### Medium Risk
- ⚠️ Service layer extraction may require refactoring existing aggregation logic
  - **Mitigation:** Reuse existing logic, don't rewrite from scratch
- ⚠️ Performance with large meal plans (many recipes, many ingredients)
  - **Mitigation:** Test with 20+ ingredients, optimize queries if needed

### Dependencies
- **Requires:** #258 complete (design patterns, visual styling)
- **Blocks:** None directly, but #267 (Stage 2) will reuse projection logic

## Notes

- Stage 1 is intentionally simple (read-only, no persistence)
- Stage 2 (#267) will add interactivity (checkboxes, quantity adjustments)
- Projection logic should be designed for reuse by Stage 2
- Bottom sheet pattern established here will be reused in Stage 2
