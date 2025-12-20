<!-- markdownlint-disable -->
1# Issue #238 Implementation Roadmap

**Issue Title:** Add context menu with edit and delete options to meal cards in meal history screen

**Branch:** `ui/238-meal-card-context-menu`

**Milestone:** 0.1.3 - User Features & Critical Foundation

**Labels:** enhancement, P2-Medium, UI, ✓✓

---

## Overview

Replace the current edit IconButton in meal cards with a PopupMenuButton that provides both edit and delete options, matching the pattern used in recipe cards. This will improve consistency and enable users to delete unwanted meal entries from their history.

---

## Phase 1: Localization Preparation ✅

**Goal:** Ensure all required localized strings are available before UI implementation.

### To-Do List

- [x] **1.1: Review existing localization strings**
  - Check `lib/l10n/app_en.arb` for delete-related strings
  - Check `lib/l10n/app_pt.arb` for delete-related strings
  - Identify which strings can be reused (e.g., "delete", "edit")

- [x] **1.2: Add meal-specific deletion strings to `lib/l10n/app_en.arb`**
  - Add `deleteMeal` key for dialog title
  - Add `deleteMealConfirmation` key for confirmation message with meal date parameter
  - Add `mealDeletedSuccessfully` key for success snackbar
  - Add `errorDeletingMeal` key for error snackbar
  - Include proper `@deleteMeal`, `@deleteMealConfirmation`, etc. metadata with descriptions

- [x] **1.3: Add meal-specific deletion strings to `lib/l10n/app_pt.arb`**
  - Add Portuguese translations for all keys added in 1.2
  - Ensure parameter names match (e.g., `{mealDate}`)
  - Include proper metadata

- [x] **1.4: Generate localization files**
  - Run `flutter gen-l10n` to generate localization code
  - Verify no errors in generation
  - Verify generated files in `.dart_tool/flutter_gen/gen_l10n/`

- [x] **1.5: Validate localization**
  - Run `flutter analyze` to ensure no localization errors
  - Verify all new strings are accessible via `AppLocalizations.of(context)!.*`

**Completion Summary:**
- Added 4 localization strings in both English and Portuguese
- All strings generated successfully
- Flutter analyze passed
- Commit: `543fa30` - feat: add meal deletion localization for English and Portuguese (#238)

**Expected Strings to Add:**

```json
English (app_en.arb):
- "deleteMeal": "Delete Meal"
- "deleteMealConfirmation": "Are you sure you want to delete this meal from {mealDate}?"
- "mealDeletedSuccessfully": "Meal deleted successfully"
- "errorDeletingMeal": "Error deleting meal"

Portuguese (app_pt.arb):
- "deleteMeal": "Excluir Refeição"
- "deleteMealConfirmation": "Tem certeza que deseja excluir esta refeição de {mealDate}?"
- "mealDeletedSuccessfully": "Refeição excluída com sucesso"
- "errorDeletingMeal": "Erro ao excluir refeição"
```

**Note:** Strings like `delete`, `edit`, and `cancel` already exist and can be reused.

---

## Phase 2: UI Implementation - PopupMenuButton ✅

**Goal:** Replace the edit IconButton with PopupMenuButton in meal cards.

### To-Do List

- [x] **2.1: Locate the IconButton in meal_history_screen.dart**
  - File: `lib/screens/meal_history_screen.dart`
  - Lines: 352-362
  - Current widget: `IconButton` with `Icons.edit`

- [x] **2.2: Replace IconButton with PopupMenuButton**
  - Remove existing IconButton (lines 352-362)
  - Add PopupMenuButton widget
  - Use `Icons.more_vert` icon (vertical three dots)
  - Match visual constraints from original IconButton:
    - `constraints: BoxConstraints(minWidth: 36, minHeight: 36)`
    - `padding: EdgeInsets.all(4)`
    - Icon size: 20

- [x] **2.3: Implement PopupMenuButton items**
  - Add 'edit' menu item with `Icons.edit` and localized "Edit" text
  - Add 'delete' menu item with `Icons.delete` and localized "Delete" text
  - Use `Row` layout with icon, spacing, and text (match recipe_card.dart pattern)
  - Set proper spacing between icon and text (8px)

- [x] **2.4: Implement onSelected callback**
  - Add switch statement for handling menu selections
  - Case 'edit': Call existing `_handleEditMeal(meal)` method
  - Case 'delete': Call new `_handleDeleteMeal(meal)` method (to be implemented in Phase 3)

- [x] **2.5: Verify visual consistency**
  - Ensure PopupMenuButton fits within card layout
  - Verify alignment with existing elements (servings count, side dish badge)
  - Test on different screen sizes (responsive)

**Completion Summary:**
- Replaced IconButton with PopupMenuButton in meal_history_screen.dart
- Implemented Edit and Delete menu items with proper icons and localization
- Matched visual pattern from recipe_card.dart for consistency
- Part of commit: `659b8a3` - feat: add context menu for meal editing and deletion with confirmation dialog (#238)

**Reference Pattern (from recipe_card.dart:266-300):**

```dart
PopupMenuButton<String>(
  icon: const Icon(Icons.more_vert, size: 20),
  onSelected: (value) {
    switch (value) {
      case 'edit':
        widget.onEdit(); // In our case: _handleEditMeal(meal)
        break;
      case 'delete':
        widget.onDelete(); // In our case: _handleDeleteMeal(meal)
        break;
    }
  },
  itemBuilder: (context) => [
    PopupMenuItem(
      value: 'edit',
      child: Row(
        children: [
          const Icon(Icons.edit),
          const SizedBox(width: 8),
          Text(AppLocalizations.of(context)!.edit),
        ],
      ),
    ),
    PopupMenuItem(
      value: 'delete',
      child: Row(
        children: [
          const Icon(Icons.delete),
          const SizedBox(width: 8),
          Text(AppLocalizations.of(context)!.delete),
        ],
      ),
    ),
  ],
)
```

---

## Phase 3: Backend Implementation - Delete Meal Method ✅

**Goal:** Implement the `_handleDeleteMeal` method with confirmation dialog and database operations.

### To-Do List

- [x] **3.1: Create confirmation dialog**
  - Add `_showDeleteConfirmationDialog(Meal meal)` helper method
  - Return `Future<bool>` (true if confirmed, false if cancelled)
  - Use `AlertDialog` widget
  - Set title using `AppLocalizations.of(context)!.deleteMeal`
  - Set content using `AppLocalizations.of(context)!.deleteMealConfirmation` with formatted meal date
  - Add "Cancel" button (returns false)
  - Add "Delete" button (returns true, styled in red/destructive color)

- [x] **3.2: Implement `_handleDeleteMeal(Meal meal)` method**
  - Show confirmation dialog using `_showDeleteConfirmationDialog`
  - If not confirmed, return early
  - Wrap database operations in try-catch block
  - Add proper error handling for different exception types

- [x] **3.3: Implement database deletion logic**
  - Delete associated `MealRecipe` entries first (cascade delete)
    - Use `_dbHelper.getMealRecipesForMeal(meal.id)` to get all meal recipes
    - Loop through and delete each using `_dbHelper.deleteMealRecipe(mealRecipe.id)`
  - Delete the meal using `_dbHelper.deleteMeal(meal.id)`
  - Note: Check if DatabaseHelper has cascade delete - if yes, simplify to single call

- [x] **3.4: Update UI after deletion**
  - Call `_loadMeals()` to refresh the meal list
  - Refresh recipe statistics: `context.read<RecipeProvider>().refreshMealStats()`
  - Show success snackbar: `AppLocalizations.of(context)!.mealDeletedSuccessfully`

- [x] **3.5: Handle errors gracefully**
  - Catch `NotFoundException` - show specific error message
  - Catch `GastrobrainException` - show error with exception message
  - Catch general exceptions - show generic error message
  - Use `AppLocalizations.of(context)!.errorDeletingMeal` for error snackbar
  - Ensure snackbar only shows if widget is still mounted

- [x] **3.6: Add mounted checks**
  - Check `if (!mounted) return;` before showing dialogs
  - Check `if (!mounted) return;` before showing snackbars
  - Check `if (!mounted) return;` after async operations

**Completion Summary:**
- Implemented `_showDeleteConfirmationDialog` helper method
- Implemented `_handleDeleteMeal` with proper cascade delete logic
- Added comprehensive error handling for NotFoundException and GastrobrainException
- Added mounted checks throughout async operations
- Implemented UI refresh and success/error snackbars
- Part of commit: `659b8a3` - feat: add context menu for meal editing and deletion with confirmation dialog (#238)

**Expected Method Structure:**
```dart
Future<void> _handleDeleteMeal(Meal meal) async {
  // 1. Show confirmation dialog
  final confirmed = await _showDeleteConfirmationDialog(meal);
  if (!confirmed) return;

  try {
    // 2. Delete associated MealRecipe entries
    // 3. Delete meal from database
    // 4. Refresh meal list
    // 5. Refresh recipe statistics
    // 6. Show success snackbar
  } on NotFoundException catch (e) {
    // Handle not found
  } on GastrobrainException catch (e) {
    // Handle app exceptions
  } catch (e) {
    // Handle general errors
  }
}
```

---

## Phase 4: Testing - Unit Tests ✅

**Goal:** Add unit tests for the delete meal functionality.

### To-Do List

- [x] **4.1: Review existing test structure**
  - Check `test/screens/meal_history_edit_test.dart` for test patterns
  - Understand how MockDatabaseHelper is used
  - Review test setup and teardown patterns

- [x] **4.2: Add test for confirmation dialog display**
  - Test that tapping delete option shows confirmation dialog
  - Verify dialog title and message are correct
  - Verify dialog has Cancel and Delete buttons

- [x] **4.3: Add test for cancelling deletion**
  - Tap Cancel in confirmation dialog
  - Verify meal is NOT deleted from database
  - Verify UI is not updated
  - Verify no snackbar is shown

- [x] **4.4: Add test for confirming deletion**
  - Tap Delete in confirmation dialog
  - Verify `deleteMealRecipe` is called for each associated recipe
  - Verify `deleteMeal` is called with correct meal ID
  - Verify meal list is refreshed
  - Verify success snackbar is shown

- [x] **4.5: Add test for deletion error handling**
  - Mock database to throw `NotFoundException`
  - Verify error snackbar is shown
  - Mock database to throw `GastrobrainException`
  - Verify error snackbar is shown with exception message

- [x] **4.6: Add test for deleting meal with multiple side dishes**
  - Create meal with 3 MealRecipe entries (1 primary, 2 sides)
  - Verify all 3 MealRecipe entries are deleted
  - Verify meal is deleted
  - Verify meal list is refreshed

- [x] **4.7: Run all unit tests**
  - Execute `flutter test test/screens/meal_history_edit_test.dart`
  - Verify all tests pass
  - Execute `flutter test` to run full test suite
  - Ensure no regressions

**Completion Summary:**
- Added 6 comprehensive unit tests for meal deletion functionality
- Updated all existing tests to work with PopupMenuButton pattern (Icons.more_vert)
- Fixed Portuguese locale tests to use "Editar" instead of "Edit"
- All 50 tests passing
- Commit: `5bb22a3` - test: add meal deletion tests and update existing tests for PopupMenuButton UI (#238)

**Note:** Unit tests use `MockDatabaseHelper` and do not test actual database operations.

---

## Phase 5: Testing - E2E Tests ✅

**Goal:** Add end-to-end tests for the meal deletion workflow.

### To-Do List

- [x] **5.1: Review existing E2E test structure**
  - Check `integration_test/e2e/e2e_meal_editing_integration_test.dart`
  - Check `integration_test/e2e/helpers/e2e_test_helpers.dart` for helper methods
  - Understand test data setup and cleanup patterns

- [x] **5.2: Create test data setup**
  - Create test recipe with unique identifier
  - Create test meal with associated MealRecipe entry
  - Include side dishes in test data
  - Store IDs for cleanup

- [x] **5.3: Add E2E test for successful meal deletion**
  - Navigate to meal history screen
  - Find meal card
  - Tap PopupMenuButton (three dots icon)
  - Tap Delete option
  - Verify confirmation dialog appears
  - Tap Delete button
  - Verify success snackbar appears
  - Verify meal card is removed from UI
  - Verify meal is deleted from database

- [x] **5.4: Add E2E test for cancelled deletion**
  - Navigate to meal history screen
  - Tap PopupMenuButton
  - Tap Delete option
  - Tap Cancel in confirmation dialog
  - Verify meal card still exists in UI
  - Verify meal still exists in database

- [x] **5.5: Add E2E test for deleting meal with side dishes**
  - Create meal with 2 side dishes
  - Delete meal
  - Verify all associated MealRecipe entries are deleted
  - Verify meal is deleted
  - Verify recipe statistics are updated correctly

- [x] **5.6: Add E2E test for UI consistency**
  - Verify PopupMenuButton icon is `Icons.more_vert`
  - Verify menu has Edit and Delete options
  - Verify icons are displayed correctly
  - Verify localized text is displayed

- [x] **5.7: Run E2E tests**
  - Execute specific test file
  - Verify all tests pass
  - Run full E2E test suite to check for regressions

- [x] **5.8: Add test cleanup**
  - Ensure all test data is cleaned up in teardown
  - Delete test recipes and meals
  - Verify database is clean after tests

**Completion Summary:**
- Added 4 comprehensive E2E tests for meal deletion workflow
- Created 5 new helper methods for context menu and deletion interactions
- All tests passing (run manually on Windows outside WSL)
- Test coverage includes: successful deletion, cancelled deletion, meals with side dishes, and UI consistency
- Commits: `687d3b5`, `8a0b142`, `01aa54a`, `cded75f`, `9abfb9c`

**Expected Test Structure:**
```dart
testWidgets('Delete meal from history with confirmation', (WidgetTester tester) async {
  // Setup test data
  // Navigate to meal history
  // Tap PopupMenuButton
  // Tap Delete
  // Confirm deletion
  // Verify deletion
  // Cleanup
});
```

---

## Phase 6: Validation & Quality Assurance

**Goal:** Ensure code quality, localization correctness, and no regressions.

### To-Do List

- [ ] **6.1: Run flutter analyze**
  - Execute `flutter analyze`
  - Fix any warnings or errors
  - Ensure code follows Dart style guidelines
  - Verify no unused imports

- [ ] **6.2: Run full test suite**
  - Execute `flutter test` for all unit tests
  - Verify no test failures
  - Verify no test regressions
  - Check test coverage if available

- [ ] **6.3: Verify localization**
  - Test app with English locale
  - Verify all strings display correctly
  - Test app with Portuguese locale
  - Verify all translations display correctly
  - Check for missing strings or fallbacks

- [ ] **6.4: Manual testing - Happy path**
  - Navigate to meal history screen
  - Tap PopupMenuButton on a meal card
  - Verify menu appears with Edit and Delete options
  - Tap Edit - verify edit dialog opens
  - Tap Delete - verify confirmation dialog appears
  - Confirm deletion - verify meal is deleted and success message shows

- [ ] **6.5: Manual testing - Edge cases**
  - Test deleting meal with multiple side dishes
  - Test cancelling deletion
  - Test deleting the last meal (verify empty state appears)
  - Test deleting meal that was recently edited
  - Test rapid delete operations (stress test)

- [ ] **6.6: Manual testing - Error scenarios**
  - Simulate database error (if possible in test environment)
  - Verify error snackbar displays correctly
  - Verify app doesn't crash on error
  - Verify app recovers gracefully

- [ ] **6.7: Visual regression check**
  - Compare meal card appearance before and after changes
  - Verify PopupMenuButton fits properly in card layout
  - Verify alignment with other card elements
  - Test on different screen sizes (small, medium, large)
  - Test on different orientations (portrait, landscape)

- [ ] **6.8: Performance check**
  - Verify deletion is fast and responsive
  - Verify no UI jank or stuttering
  - Verify meal list refresh is smooth
  - Check for memory leaks (if tools available)

---

## Phase 7: Documentation & Commit

**Goal:** Update documentation, create proper commit, and prepare for merge.

### To-Do List

- [ ] **7.1: Review code changes**
  - Read through all modified files
  - Verify code follows project patterns
  - Check for consistent formatting
  - Remove any debug code or comments
  - Remove any unused code

- [ ] **7.2: Update inline documentation**
  - Add doc comments to `_handleDeleteMeal` method
  - Add doc comments to `_showDeleteConfirmationDialog` helper
  - Update existing comments if needed
  - Ensure comments are clear and concise

- [ ] **7.3: Verify all acceptance criteria**
  - [ ] Meal cards show PopupMenuButton with vertical three-dots icon
  - [ ] Context menu has "Edit" and "Delete" options with icons
  - [ ] Tapping "Edit" opens edit dialog
  - [ ] Tapping "Delete" shows confirmation dialog
  - [ ] Confirming deletion removes meal from database
  - [ ] Associated MealRecipe entries are deleted
  - [ ] Meal list refreshes after deletion
  - [ ] Success snackbar shows after deletion
  - [ ] Error snackbar shows if deletion fails
  - [ ] All strings localized in English and Portuguese
  - [ ] E2E test added for deletion workflow
  - [ ] `flutter analyze` passes
  - [ ] Manual testing confirms functionality

- [ ] **7.4: Stage and review changes**
  - Run `git status` to see all modified files
  - Run `git diff` to review all changes
  - Verify no unintended changes
  - Verify no debug code committed

- [ ] **7.5: Commit changes**
  - Stage all relevant files
  - Create commit with proper format:
    ```
    ui: add context menu with edit and delete options to meal cards (#238)

    Replaces edit IconButton with PopupMenuButton in meal history screen,
    matching the pattern used in recipe cards. Adds confirmation dialog
    for meal deletion with cascade delete of associated MealRecipe entries.

    - Add PopupMenuButton with edit/delete options to meal cards
    - Implement _handleDeleteMeal with confirmation dialog
    - Add meal deletion localization strings (en/pt)
    - Add E2E tests for meal deletion workflow
    - Update meal history screen UI for consistency

    Closes #238

    🦾 Generated with [Claude Code](https://claude.com/claude-code)

    Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
    ```

- [ ] **7.6: Final verification**
  - Run `flutter analyze` one more time
  - Run `flutter test` one more time
  - Verify branch is clean: `git status`
  - Verify commit message follows format

---

## Phase 8: Merge to Develop

**Goal:** Merge changes to develop branch and clean up.

### To-Do List

- [ ] **8.1: Ensure all changes are committed**
  - Run `git status` to verify clean working tree
  - Verify no uncommitted changes
  - Verify all test files are committed

- [ ] **8.2: Switch to develop and update**
  - Run `git checkout develop`
  - Run `git pull origin develop`
  - Check for any conflicts or updates

- [ ] **8.3: Merge feature branch**
  - Run `git merge ui/238-meal-card-context-menu`
  - Resolve any merge conflicts if they exist
  - Verify merge completed successfully

- [ ] **8.4: Run tests after merge**
  - Run `flutter analyze` on develop
  - Run `flutter test` on develop
  - Verify no issues introduced by merge

- [ ] **8.5: Push to remote**
  - Run `git push origin develop`
  - Verify push succeeded

- [ ] **8.6: Close the issue**
  - Run `gh issue close 238`
  - Verify issue is closed on GitHub
  - Add closing comment if needed

- [ ] **8.7: Clean up branches**
  - Delete local branch: `git branch -d ui/238-meal-card-context-menu`
  - Delete remote branch if pushed: `git push origin --delete ui/238-meal-card-context-menu`

- [ ] **8.8: Verify on GitHub**
  - Check that issue #238 is closed
  - Verify commit appears in develop branch
  - Check GitHub Actions CI/CD status (if applicable)

---

## Summary of Files to Modify

| File | Type | Changes |
|------|------|---------|
| `lib/l10n/app_en.arb` | Localization | Add 4 new meal deletion strings |
| `lib/l10n/app_pt.arb` | Localization | Add 4 new meal deletion strings (PT) |
| `lib/screens/meal_history_screen.dart` | UI/Logic | Replace IconButton, add PopupMenuButton, implement `_handleDeleteMeal`, add confirmation dialog |
| `test/screens/meal_history_edit_test.dart` | Tests | Add unit tests for deletion |
| `integration_test/e2e/e2e_meal_editing_integration_test.dart` | E2E Tests | Add E2E tests for deletion workflow |

---

## Estimated Effort

| Phase | Estimated Time | Complexity |
|-------|---------------|------------|
| Phase 1: Localization | 30 minutes | Low |
| Phase 2: UI Implementation | 45 minutes | Low-Medium |
| Phase 3: Backend Logic | 1 hour | Medium |
| Phase 4: Unit Tests | 1 hour | Medium |
| Phase 5: E2E Tests | 1.5 hours | Medium-High |
| Phase 6: QA & Validation | 1 hour | Low-Medium |
| Phase 7: Documentation | 30 minutes | Low |
| Phase 8: Merge & Cleanup | 30 minutes | Low |
| **Total** | **~6.5 hours** | **Medium** |

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Cascade delete not working | Low | High | Verify DatabaseHelper implementation, add explicit deletion loop if needed |
| Localization strings incorrect | Low | Medium | Thorough review of ARB files, test both locales |
| UI layout breaks on small screens | Medium | Medium | Test on multiple screen sizes, use responsive constraints |
| Test flakiness in E2E tests | Medium | Low | Use proper waits, pumpAndSettle, verify element presence |
| Regression in edit functionality | Low | High | Run full test suite, manual testing of edit flow |

---

## Success Criteria

✅ All acceptance criteria from issue #238 are met
✅ All unit tests pass
✅ All E2E tests pass
✅ `flutter analyze` reports no issues
✅ Both English and Portuguese localizations work correctly
✅ Manual testing confirms all workflows work as expected
✅ Code follows project patterns and style guidelines
✅ Issue #238 is closed and merged to develop

---

## Questions & Answers

1. **Database cascade delete:** Does `DatabaseHelper.deleteMeal()` automatically delete associated `MealRecipe` entries, or do we need to manually delete them first?
   - **Answer:** Test 4.6 will verify the behavior. Implementation will check and handle accordingly.

2. **Meal deletion impact:** Should we prevent deletion if the meal is referenced in a meal plan, or allow unrestricted deletion?
   - **Answer:** No restriction needed - allow unrestricted deletion.

3. **Undo functionality:** Should we consider adding an "undo" option after deletion (via snackbar action), or is permanent deletion acceptable?
   - **Answer:** No undo needed - keep it simple for now with permanent deletion.

4. **Test coverage:** Are there any specific edge cases or scenarios you want tested beyond what's outlined in this roadmap?
   - **Answer:** Test coverage outlined in roadmap is sufficient.

---

## Notes

- This roadmap follows the step-by-step development workflow outlined in `CLAUDE.md`
- Each phase builds on the previous phase - complete phases in order
- Use TodoWrite tool during implementation to track progress within each phase
- Follow the Issue Workflow Guide in `docs/ISSUE_WORKFLOW.md` for git operations
- Reference the L10N Protocol in `docs/L10N_PROTOCOL.md` for localization workflow
- Pattern matching with `recipe_card.dart` ensures UI consistency
- All async operations include proper mounted checks to prevent setState errors
- Error handling follows the established pattern with custom exceptions