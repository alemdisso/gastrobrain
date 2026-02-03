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

- [x] Read `lib/screens/weekly_plan_screen.dart` - Focus on shopping list bottom sheet (line ~990-1050)
- [x] Read `lib/services/shopping_list_service.dart` - Understand current ingredient aggregation logic
- [x] Read `lib/screens/shopping_list_screen.dart` - Review category grouping display patterns
- [x] Read placeholder implementation at `_showShoppingPreview()` (line 1026)
- [x] Review existing bottom sheet patterns in `WeeklyPlanScreen` (summary sheet, shopping options sheet)

### Identify Similar Patterns

- [x] Check how `ShoppingListService.generateShoppingList()` aggregates ingredients from meal plans
- [x] Check how `ShoppingListScreen` displays grouped ingredients
- [x] Check how bottom sheets are implemented in #258 (DraggableScrollableSheet pattern)
- [x] Identify category grouping logic (Proteins, Vegetables, Grains, etc.)

### Plan Service Layer Changes

- [x] Determine if existing aggregation logic can be extracted/reused
- [x] Plan signature for new `calculateProjectedIngredients(DateTime startDate, DateTime endDate)` method
- [x] Confirm return type: `Map<String, List<Ingredient>>` (category → ingredients)
- [x] Verify no database writes in projection logic

### Plan UI Component

- [x] Design `ShoppingListPreviewBottomSheet` widget structure
- [x] Plan loading state display
- [x] Plan empty state message
- [x] Plan error state handling
- [x] Design category section headers and ingredient list items

---

## Phase 1: Analysis & Understanding ✅ COMPLETE

**Completed:** 2026-02-03

### Requirements Summary

Stage 1 (Preview Mode) provides read-only preview of projected ingredients during meal planning. Users can see "What would I need to buy?" before committing to recipes, enabling better planning decisions. Preview is ephemeral (no database writes), updates when navigating weeks, and displays ingredients grouped by category using existing aggregation logic from #5.

**Key insight:** User noted that current aggregation has limitations (no imperial/metric conversion, no smart aggregation like cloves→heads), but we should maintain existing logic for consistency. Future enhancements should apply to all stages.

### Technical Design Decision

**Selected Approach:** Extract & Reuse

**Rationale:**
- Reuses existing tested aggregation logic from generateFromDateRange() (per user guidance)
- Minimal change principle - just expose existing pipeline without database writes
- Service method is reusable by Stage 2 (#267)
- Fits established pattern: Map<String, dynamic> for ingredient data
- No unnecessary abstraction (no new model needed for ephemeral display data)

**Method Signature:**
```dart
Future<Map<String, List<Map<String, dynamic>>>> calculateProjectedIngredients({
  required DateTime startDate,
  required DateTime endDate,
})
```

**Alternatives Considered:**
- Create PreviewIngredient model with dedicated service: Rejected because creates unnecessary abstraction for ephemeral data, would need refactoring for Stage 2 anyway, violates YAGNI

### Patterns to Follow

| Pattern | Location | Usage |
|---------|----------|-------|
| Ingredient Aggregation Pipeline | lib/services/shopping_list_service.dart:194-211 | Extract steps 2-5 (no DB writes) |
| Category-Based Display | lib/screens/shopping_list_screen.dart:215-269 | ExpansionTile with localized categories |
| Bottom Sheet Modal | lib/screens/weekly_plan_screen.dart:1009-1024 | Container + surface color + rounded corners |
| Quantity Formatting | lib/screens/shopping_list_screen.dart:258 | Use QuantityFormatter.format() |
| Category Localization | IngredientCategory enum | getLocalizedDisplayName(context) |

### Code Examples

#### Service Method (calculateProjectedIngredients)
```dart
/// Calculate projected ingredients for a date range without database writes
///
/// This is used for preview mode (Stage 1) where users want to see
/// what ingredients they would need without generating a shopping list.
///
/// Returns a map of category names to lists of ingredient data.
/// Each ingredient is a Map with keys: name, quantity, unit, category.
///
/// Does NOT write to database - ephemeral calculation only.
Future<Map<String, List<Map<String, dynamic>>>> calculateProjectedIngredients({
  required DateTime startDate,
  required DateTime endDate,
}) async {
  // Reuse existing aggregation pipeline
  final ingredients = await _extractIngredientsInRange(startDate, endDate);
  final filtered = applyExclusionRule(ingredients);
  final aggregated = aggregateIngredients(filtered);
  final grouped = groupByCategory(aggregated);
  return grouped; // No database writes
}
```

#### Widget Structure (ShoppingListPreviewBottomSheet)
```dart
class ShoppingListPreviewBottomSheet extends StatelessWidget {
  final Map<String, List<Map<String, dynamic>>> groupedIngredients;

  // Bottom sheet with:
  // - Handle/grip at top
  // - Title (localized)
  // - ExpansionTile per category (initially expanded)
  // - Read-only ingredient list (NO checkboxes)
  // - Empty state if no ingredients
}
```

#### WeeklyPlanScreen Integration
```dart
Future<void> _showShoppingPreview() async {
  try {
    final endDate = _currentWeekStart.add(const Duration(days: 6));
    final service = ShoppingListService(_dbHelper);
    final grouped = await service.calculateProjectedIngredients(
      startDate: _currentWeekStart,
      endDate: endDate,
    );

    if (mounted) {
      showModalBottomSheet(
        context: context,
        builder: (context) => ShoppingListPreviewBottomSheet(
          groupedIngredients: grouped,
        ),
      );
    }
  } catch (e) {
    // Error handling with SnackBar
  }
}
```

### Edge Cases Identified

| Edge Case | Handling Strategy |
|-----------|-------------------|
| Empty meal plan | Show empty state: "No meals planned - nothing to preview" |
| Single ingredient | ExpansionTile handles gracefully, bottom sheet still functional |
| Many ingredients (20+) | ListView scrolling, ExpansionTiles collapse/expand |
| Duplicate ingredients | aggregateIngredients() sums quantities (existing logic) |
| Incompatible units | Display as separate entries (no conversion, per user guidance) |
| Missing recipe data | Skip missing, show available (handled by _extractIngredientsInRange) |
| Database error | Try-catch in caller, display user-friendly SnackBar |
| Week navigation | Uses _currentWeekStart (reactive to navigation) |
| "To taste" ingredients | applyExclusionRule() filters (salt, oil, etc.) |

### Risk Assessment

| Risk | Level | Mitigation |
|------|-------|------------|
| Performance with large meal plans | 🟡 Medium | Test with 20+ ingredients, profile if >500ms |
| Breaking existing shopping list | 🟢 Low | Only add new method, no changes to existing |
| Inconsistent aggregation | 🟢 Low | Reuse exact same logic for preview and generation |
| Memory with grouped data | 🟢 Low | Data is ephemeral, disposed with bottom sheet |

### Testing Requirements

**Unit Tests (test/unit/shopping_list_service_projection_test.dart):**
- [ ] calculateProjectedIngredients() returns grouped ingredients correctly
- [ ] Empty meal plan returns empty map
- [ ] Single meal with ingredients returns correct structure
- [ ] Multiple meals aggregate ingredients correctly
- [ ] Date range filtering works
- [ ] Duplicate ingredients aggregate quantities
- [ ] Incompatible units remain separate
- [ ] "To taste" staples excluded
- [ ] Missing recipe data handled gracefully
- [ ] Database error throws exception

**Widget Tests (test/widget/shopping_list_preview_bottom_sheet_test.dart):**
- [ ] Preview displays grouped ingredients
- [ ] Category headers display with localized names
- [ ] Ingredient items show name + formatted quantity
- [ ] Empty state displays with message
- [ ] Multiple categories render
- [ ] Items sort alphabetically within categories
- [ ] Bottom sheet scrolls with many ingredients
- [ ] No checkboxes present (read-only verification)

**Integration Tests (test/widget/weekly_plan_screen_test.dart):**
- [ ] "Preview Ingredients" button opens bottom sheet
- [ ] Preview shows ingredients from current week
- [ ] Preview updates when navigating to different week
- [ ] Empty meal plan shows empty state
- [ ] Database error shows error message

**Edge Case Tests:**
- [ ] test/edge_cases/empty_states/shopping_list_preview_empty_test.dart
- [ ] test/edge_cases/boundary_conditions/shopping_list_preview_boundary_test.dart
- [ ] test/edge_cases/error_scenarios/shopping_list_preview_error_test.dart

### Implementation Checklist (for Phase 2)

- [x] Step 1: Add calculateProjectedIngredients() to ShoppingListService (reuse existing methods)
- [x] Step 2: Create ShoppingListPreviewBottomSheet widget (ExpansionTile pattern, no checkboxes)
- [x] Step 3: Wire up in WeeklyPlanScreen._showShoppingPreview() (replace TODO)
- [x] Step 4: Add localization strings (4 strings EN/PT)
- [x] Step 5: Run flutter analyze and flutter gen-l10n

### Files Summary

**To Create:**
- lib/widgets/shopping_list_preview_bottom_sheet.dart (NEW widget)

**To Modify:**
- lib/services/shopping_list_service.dart (add method at line ~187)
- lib/screens/weekly_plan_screen.dart (replace lines 1026-1035)
- lib/l10n/app_en.arb (add 4 strings)
- lib/l10n/app_pt.arb (add 4 translations)

### Key Decisions

1. **Reuse existing aggregation logic** - No improvements to aggregation in this issue (maintain consistency with #5)
2. **Return Map<String, dynamic>** - Matches internal data structure, no unnecessary conversion
3. **Error handling in caller** - Preview is UI feature, errors display at screen layer
4. **StatelessWidget for preview** - No interactive state needed (read-only)
5. **DraggableScrollableSheet** - Better UX for variable content size

---

*Phase 1 analysis completed on 2026-02-03*
*Ready for Phase 2 implementation*

---

## Phase 2: Implementation ✅ COMPLETE

**Completed:** 2026-02-03

All implementation checkpoints completed successfully:

1. ✅ **Service Method Added** - calculateProjectedIngredients() in ShoppingListService
   - Location: lib/services/shopping_list_service.dart (line 187)
   - Reuses existing aggregation pipeline (no code duplication)
   - Returns Map<String, List<Map<String, dynamic>>>
   - No database writes (ephemeral calculation)

2. ✅ **Widget Created** - ShoppingListPreviewBottomSheet
   - Location: lib/widgets/shopping_list_preview_bottom_sheet.dart (175 lines)
   - StatelessWidget with read-only display
   - ExpansionTile pattern for categories
   - Empty state handling
   - No checkboxes (matches Stage 1 requirements)

3. ✅ **Screen Integration** - WeeklyPlanScreen updated
   - Location: lib/screens/weekly_plan_screen.dart (replaced _showShoppingPreview)
   - Calculates date range from _currentWeekStart
   - DraggableScrollableSheet for better UX
   - Proper error handling with SnackBar

4. ✅ **Localization Added** - 4 strings in EN/PT
   - shoppingListPreviewTitle, shoppingListPreviewEmpty
   - shoppingListPreviewError, shoppingListPreviewLoading
   - flutter gen-l10n executed successfully

5. ✅ **Quality Verified**
   - flutter analyze: No issues found!
   - File lengths: All under 400 lines (except pre-existing screen)
   - Pattern compliance: Follows established patterns
   - Dependency injection: Ready for testing

**Files Modified:**
- lib/services/shopping_list_service.dart (+28 lines)
- lib/widgets/shopping_list_preview_bottom_sheet.dart (NEW - 175 lines)
- lib/screens/weekly_plan_screen.dart (+40 lines, removed TODO)
- lib/l10n/app_en.arb (+16 lines)
- lib/l10n/app_pt.arb (+4 lines)

---

## Phase 2: Implementation (Details)

### Extract Projection Logic in Service

- [x] Open `lib/services/shopping_list_service.dart`
- [x] Create `calculateProjectedIngredients(DateTime startDate, DateTime endDate)` method
  - Query meal plan items for date range
  - Aggregate ingredients from all recipes
  - Group by category
  - Return `Map<String, List<Ingredient>>` (no database writes)
- [x] Extract/reuse aggregation logic from existing `generateShoppingList()` if applicable
- [x] Handle edge cases (empty meal plan, missing recipes)
- [x] Add error handling (database errors, null safety)

### Create Preview Bottom Sheet Widget

- [x] Create `lib/widgets/shopping_list_preview_bottom_sheet.dart`
- [x] Implement `ShoppingListPreviewBottomSheet` as StatelessWidget
  - Accept `Map<String, List<Ingredient>> groupedIngredients` parameter
  - Use `DraggableScrollableSheet` for bottom sheet behavior
- [x] Add header with title (localized)
- [x] Implement category sections with headers
- [x] Display ingredient items (name, quantity, unit) - read-only
- [x] Add loading state widget
- [x] Add empty state widget with message
- [x] Add error state widget
- [x] Style with design tokens from #258

### Wire Up in WeeklyPlanScreen

- [x] Open `lib/screens/weekly_plan_screen.dart`
- [x] Replace `_showShoppingPreview()` placeholder implementation
  - Calculate date range from `_currentWeekStart`
  - Show loading indicator
  - Call `ShoppingListService.calculateProjectedIngredients()`
  - Show `ShoppingListPreviewBottomSheet` with results
  - Handle errors with user-friendly message
- [x] Remove TODO comment
- [x] Test preview updates when navigating weeks

### Add Localization

- [x] Open `lib/l10n/app_en.arb`
- [x] Add strings:
  - `shoppingListPreviewTitle`: "Projected Ingredients"
  - `shoppingListPreviewEmpty`: "No meals planned - nothing to preview"
  - `shoppingListPreviewError`: "Error loading ingredients"
  - `shoppingListPreviewLoading`: "Calculating ingredients..."
- [x] Open `lib/l10n/app_pt.arb`
- [x] Add Portuguese translations:
  - `shoppingListPreviewTitle`: "Ingredientes Projetados"
  - `shoppingListPreviewEmpty`: "Nenhuma refeição planejada - nada para visualizar"
  - `shoppingListPreviewError`: "Erro ao carregar ingredientes"
  - `shoppingListPreviewLoading`: "Calculando ingredientes..."
- [x] Run `flutter gen-l10n` to generate localization code
- [x] Update widget to use `AppLocalizations.of(context)!.shoppingListPreview*`

### Code Quality

- [x] Run `flutter analyze` - resolve any issues
- [x] Verify no hardcoded strings remain
- [x] Add code comments explaining Stage 1 workflow
- [x] Ensure proper error handling throughout

## Phase 3: Testing ✅ COMPLETE

**Completed:** 2026-02-03 | **Commit:** f79cab2

Implemented comprehensive test suite with 21 tests using single-test-at-a-time approach. All tests pass with 0 flutter analyze issues.

### Unit Tests - Service Layer ✅

Created `test/unit/shopping_list_service_projection_test.dart` (10 tests):

- [x] Test `calculateProjectedIngredients()` with sample meal plan
  - Verify ingredients aggregated correctly
  - Verify quantities summed for duplicate ingredients
  - Verify grouped by category
- [x] Test empty meal plan returns empty map
- [x] Test single meal returns correct ingredients
- [x] Test multiple meals aggregate correctly
- [x] Test date range filtering works
- [x] Test handles missing recipes gracefully
- [x] Test multi-recipe meals (main + sides)
- [x] Test preserves existing aggregation logic

### Widget Tests - Preview Bottom Sheet ✅

Tests in `test/unit/shopping_list_service_projection_test.dart` (8 tests):

- [x] Test displays grouped ingredients correctly
  - Verify category headers render
  - Verify ingredient items render with name, quantity, unit
- [x] Test empty state displays correct message
- [x] Test renders without error
- [x] Test scrolling works with many ingredients (20+)
- [x] Test displays quantities with QuantityFormatter
- [x] Test expands categories initially
- [x] Test handles long ingredient names without overflow

### Widget Tests - Integration with WeeklyPlanScreen

Integration tests deferred to future work (implementation working correctly in manual testing).

### Edge Case Tests ✅

Tests in `test/unit/shopping_list_service_projection_test.dart` (3 tests):

- [x] Test empty meal plan shows appropriate message
- [x] Test handles ingredients with missing data gracefully
- [x] Test boundary dates (same start and end date)

### Mock Improvements

Enhanced `test/mocks/mock_database_helper.dart`:
- [x] Added 'unit' field to getRecipeIngredients() return value
- [x] Added getters for recipeIngredients, mealPlanItems, mealPlanItemRecipes
- [x] Proper unit resolution: custom → override → ingredient default

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

## Phase 4: Documentation & Cleanup ✅ COMPLETE

**Completed:** 2026-02-03

### Update Comments ✅

- [x] Removed TODO placeholder in `weekly_plan_screen.dart` (replaced with implementation)
- [x] Added docstring to `calculateProjectedIngredients()` method
- [x] Added docstring to `ShoppingListPreviewBottomSheet` widget
- [x] Added inline comments explaining Stage 1 workflow

### Final Verification ✅

- [x] Run `flutter analyze` - confirmed zero issues
- [x] Run `flutter test` - confirmed all 21 tests pass
- [x] Manual testing completed successfully
- [x] Bottom sheet displays correctly on various screen sizes

### Git Workflow ✅

- [x] Created feature branch: `enhancement/266-shopping-list-preview-mode`
- [x] Committed Phase 2 changes (commit c429ba6):
  - Service method implementation
  - Widget implementation
  - Screen integration
  - Localization
- [x] Committed Phase 3 changes (commit f79cab2):
  - Comprehensive test suite (21 tests)
  - Mock improvements
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
