# Issue #199: Add meal type selection to recipe filtering

**Type**: Feature
**Priority**: P1-High
**Estimate**: 5 story points / ~1 day
**Size**: M
**Dependencies**: None
**Branch**: `feature/199-meal-type-filter`

---

## Overview

Add the ability to filter recipes by meal type (breakfast, lunch, dinner, snack, any) in the recipe list screen, improving recipe discoverability for users planning specific meals.

**Context**:
- Currently recipes can only be filtered by rating and difficulty
- Users want to see breakfast-appropriate recipes when planning morning meals
- Meal type should be stored in database and filterable in UI
- Default value "any" for existing recipes

**Expected Outcome**:
Recipe list screen has meal type dropdown filter, database stores meal type per recipe, filtering works correctly, all in both languages (EN/PT-BR).

---

## Prerequisites Check

Before starting implementation, verify:

- [x] All dependent issues resolved (None)
- [x] Development environment set up (`flutter doctor`)
- [x] On latest develop branch (`git checkout develop && git pull`)
- [x] All existing tests passing (`flutter test`)
- [x] No analysis warnings (`flutter analyze`)

**Prerequisite Knowledge**:
- [x] Familiar with Recipe model and database schema
- [x] Reviewed RecipeListScreen filtering implementation
- [x] Understand database migration process

---

## Phase 1: Analysis & Understanding

**Goal**: Understand existing filtering system and plan meal type integration

### Code Review
- [ ] Read issue #199 description and acceptance criteria
- [ ] Review existing code in affected areas:
  - [ ] `lib/core/models/recipe.dart` - Current recipe model
  - [ ] `lib/core/database/database_helper.dart` - Recipe table schema
  - [ ] `lib/screens/recipe_list_screen.dart` - Existing filter dropdowns
  - [ ] `lib/core/services/recipe_service.dart` - Recipe filtering logic
- [ ] Identify similar patterns in codebase:
  - [ ] Review how difficulty filter works (dropdown → service → database)
  - [ ] Check how rating filter is implemented
  - [ ] Review enum handling for difficulty (can use similar pattern)

### Architectural Analysis
- [ ] Identify affected layers:
  - [ ] Models: Recipe model (add mealType field)
  - [ ] Services: RecipeService (add meal type filtering)
  - [ ] UI: RecipeListScreen (add meal type dropdown)
  - [ ] Database: recipes table (add meal_type column)
- [ ] Check for ripple effects:
  - [ ] RecipeFormDialog needs meal type selector (separate issue?)
  - [ ] Recommendation service might want to use meal type
  - [ ] Seed data needs meal type values
  - [ ] All existing tests using Recipe need updating

### Dependency Check
- [ ] Verify no blocking issues open (None)
- [ ] Check if new dependencies needed (No, use existing dropdown pattern)
- [ ] Identify potential conflicts with ongoing work (None)

### Requirements Clarification
- [ ] Review acceptance criteria from issue
- [ ] Identify implicit requirements (testing, localization, migration)
- [ ] Clarify edge cases (what happens with "any"? filter combination?)
- [ ] See Questions section for clarifications needed

---

## Phase 2: Implementation

**Goal**: Add meal type field to database, model, service, and UI

### Database Changes

- [ ] Update model class: `lib/core/models/recipe.dart`
  - [ ] Add `final String mealType;` field
  - [ ] Update constructor with `this.mealType = 'any'` default
  - [ ] Update `toMap()` method:
    ```dart
    'meal_type': mealType,
    ```
  - [ ] Update `fromMap()` factory:
    ```dart
    mealType: map['meal_type'] as String? ?? 'any',
    ```
  - [ ] Update `copyWith()` method to include mealType parameter
- [ ] Create migration: `lib/core/database/migrations/add_meal_type_migration.dart`
  - [ ] Implement `up()` method:
    ```dart
    await db.execute('''
      ALTER TABLE recipes
      ADD COLUMN meal_type TEXT DEFAULT 'any'
    ''');
    ```
  - [ ] Implement `down()` method (document SQLite limitation)
  - [ ] Set version to next number (check latest migration)
- [ ] Register migration in `lib/core/database/database_helper.dart`
  - [ ] Add to migrations list
  - [ ] Increment database version
- [ ] Update seed data: `lib/core/database/seed_data.dart`
  - [ ] Add meal_type values to sample recipes:
    - Pancakes → 'breakfast'
    - Pasta → 'lunch' or 'dinner'
    - Salad → 'lunch'
    - Etc.
- [ ] Test migration manually:
  - [ ] Delete app data and reinstall (fresh database)
  - [ ] Upgrade from previous version (migration applied)
  - [ ] Verify existing recipes have meal_type = 'any'

### Service Layer Changes

- [ ] Update service: `lib/core/services/recipe_service.dart`
  - [ ] Add `mealType` parameter to `getFilteredRecipes()` method:
    ```dart
    Future<List<Recipe>> getFilteredRecipes({
      String? difficulty,
      int? minRating,
      String? mealType, // New parameter
    }) async {
      // ...
    }
    ```
  - [ ] Update SQL WHERE clause to filter by meal type:
    ```dart
    if (mealType != null && mealType != 'any') {
      whereClauses.add('meal_type = ?');
      whereArgs.add(mealType);
    }
    ```
  - [ ] Update method documentation
- [ ] No service provider changes needed (RecipeService already registered)

### UI Changes

- [ ] Update screen: `lib/screens/recipe_list_screen.dart`
  - [ ] Add state variable:
    ```dart
    String _selectedMealType = 'any';
    ```
  - [ ] Add meal type dropdown widget (similar to difficulty dropdown):
    ```dart
    DropdownButton<String>(
      value: _selectedMealType,
      items: [
        DropdownMenuItem(value: 'any', child: Text(AppLocalizations.of(context)!.mealTypeAny)),
        DropdownMenuItem(value: 'breakfast', child: Text(AppLocalizations.of(context)!.mealTypeBreakfast)),
        DropdownMenuItem(value: 'lunch', child: Text(AppLocalizations.of(context)!.mealTypeLunch)),
        DropdownMenuItem(value: 'dinner', child: Text(AppLocalizations.of(context)!.mealTypeDinner)),
        DropdownMenuItem(value: 'snack', child: Text(AppLocalizations.of(context)!.mealTypeSnack)),
      ],
      onChanged: (value) {
        setState(() {
          _selectedMealType = value!;
          _loadRecipes(); // Reload with new filter
        });
      },
    )
    ```
  - [ ] Update `_loadRecipes()` to pass meal type to service:
    ```dart
    final recipes = await recipeService.getFilteredRecipes(
      difficulty: _selectedDifficulty,
      minRating: _selectedMinRating,
      mealType: _selectedMealType, // Add parameter
    );
    ```
  - [ ] Add dropdown to filter row in UI
  - [ ] Ensure responsive layout still works
- [ ] Add responsive design considerations:
  - [ ] Filter row might be too crowded with 3 dropdowns
  - [ ] Consider wrapping filter row in Wrap widget
  - [ ] Test on small screens (< 360dp width)

### Localization Updates

- [ ] Add strings to `lib/l10n/app_en.arb`:
  ```json
  "mealTypeFilterLabel": "Meal Type",
  "@mealTypeFilterLabel": {
    "description": "Label for meal type filter dropdown"
  },
  "mealTypeAny": "Any",
  "@mealTypeAny": {
    "description": "Option to show recipes of any meal type"
  },
  "mealTypeBreakfast": "Breakfast",
  "@mealTypeBreakfast": {
    "description": "Breakfast meal type"
  },
  "mealTypeLunch": "Lunch",
  "@mealTypeLunch": {
    "description": "Lunch meal type"
  },
  "mealTypeDinner": "Dinner",
  "@mealTypeDinner": {
    "description": "Dinner meal type"
  },
  "mealTypeSnack": "Snack",
  "@mealTypeSnack": {
    "description": "Snack meal type"
  }
  ```
- [ ] Add translations to `lib/l10n/app_pt.arb`:
  ```json
  "mealTypeFilterLabel": "Tipo de Refeição",
  "mealTypeAny": "Qualquer",
  "mealTypeBreakfast": "Café da Manhã",
  "mealTypeLunch": "Almoço",
  "mealTypeDinner": "Jantar",
  "mealTypeSnack": "Lanche"
  ```
- [ ] Run `flutter gen-l10n` to generate localization classes
- [ ] Update UI code to use `AppLocalizations.of(context)!.mealType*`

### Error Handling & Validation

- [ ] Validate meal type values in service (optional, UI dropdown prevents invalid values)
- [ ] Handle null/empty meal type gracefully (treat as 'any')
- [ ] No additional error handling needed (filtering can't fail for this feature)

### Code Quality

- [ ] Run `flutter analyze` and fix any warnings
- [ ] Add comment explaining meal type filter logic
- [ ] Remove debug print statements
- [ ] Clean up unused imports

---

## Phase 3: Testing

**Goal**: Ensure meal type filtering works correctly across all components

### Unit Tests

- [ ] Update test file: `test/unit/recipe_service_test.dart`
- [ ] Test service layer filtering:
  - [ ] `test('getFilteredRecipes filters by meal type correctly')`
  - [ ] `test('getFilteredRecipes returns all recipes when meal type is "any"')`
  - [ ] `test('getFilteredRecipes handles null meal type')`
  - [ ] `test('getFilteredRecipes combines meal type with difficulty filter')`
  - [ ] `test('getFilteredRecipes combines meal type with rating filter')`
- [ ] Update test file: `test/unit/recipe_model_test.dart`
- [ ] Test model serialization:
  - [ ] `test('Recipe.toMap includes meal_type field')`
  - [ ] `test('Recipe.fromMap parses meal_type correctly')`
  - [ ] `test('Recipe.fromMap defaults to "any" if meal_type missing')`
  - [ ] `test('Recipe.copyWith includes mealType parameter')`

### Widget Tests

- [ ] Update test file: `test/widget/recipe_list_screen_test.dart`
- [ ] Set up test:
  - [ ] Add recipes with different meal types to mock database
- [ ] Test widget rendering:
  - [ ] `testWidgets('displays meal type dropdown', (tester) async { ... })`
  - [ ] `testWidgets('shows all meal type options', (tester) async { ... })`
- [ ] Test filtering behavior:
  - [ ] `testWidgets('filters recipes by breakfast on selection', (tester) async { ... })`
  - [ ] `testWidgets('shows all recipes when "any" selected', (tester) async { ... })`
  - [ ] `testWidgets('combines meal type filter with difficulty filter', (tester) async { ... })`
- [ ] Test localization:
  - [ ] Verify both EN and PT-BR meal type labels display
  - [ ] Test layout with Portuguese text (longer strings)

### Integration Tests

- [ ] Create test file: `test/integration/meal_type_filtering_integration_test.dart`
- [ ] Test multi-component workflow:
  - [ ] User opens recipe list → selects meal type → sees filtered recipes
  - [ ] User combines multiple filters → sees correctly filtered results
  - [ ] User resets filters → sees all recipes again

### E2E Tests

- [ ] Create test file: `test/e2e/recipe_filtering_e2e_test.dart`
- [ ] Test complete user workflow:
  - [ ] Happy path: Open app → navigate to recipes → select breakfast → see breakfast recipes → select one
  - [ ] Error path: No recipes match filter → show empty state

### Edge Case Tests

- [ ] Empty states: `test/edge_cases/empty_states/recipe_list_empty_test.dart`
  - [ ] `testWidgets('shows empty state when no recipes match meal type filter', (tester) async { ... })`
  - [ ] Verify helpful empty state message
- [ ] Boundary conditions: `test/edge_cases/boundary_conditions/meal_type_boundary_test.dart`
  - [ ] `test('handles empty string meal type (treats as "any")')`
  - [ ] `test('handles null meal type (treats as "any")')`
  - [ ] `test('handles invalid meal type (treats as "any" or filters out)')`
- [ ] Database migration: `test/integration/meal_type_migration_test.dart`
  - [ ] `test('migration adds meal_type column with default value')`
  - [ ] `test('existing recipes have meal_type = "any" after migration')`
  - [ ] `test('new recipes can set any meal type')`

### Test Execution & Verification

- [ ] Run all tests: `flutter test`
- [ ] Verify all tests pass
- [ ] Check test coverage for new code (>80%)
- [ ] Run specific tests during development:
  - `flutter test test/unit/recipe_service_test.dart`
  - `flutter test test/widget/recipe_list_screen_test.dart`

---

## Phase 4: Documentation & Cleanup

**Goal**: Finalize changes and prepare for merge

### Code Documentation

- [ ] Add/update code comments:
  - [ ] Document meal type values in Recipe model
  - [ ] Explain filter combination logic in service
  - [ ] Note migration approach for existing recipes

### Project Documentation
*No major documentation updates needed*

### Final Verification

- [ ] Run `flutter analyze` - no warnings
- [ ] Run `flutter test` - all tests pass
- [ ] Test both languages visually (EN and PT-BR)
- [ ] Test on small screen (filter layout)
- [ ] Test migration on fresh + existing database
- [ ] Verify no debug code or console logs left
- [ ] Verify no commented-out code
- [ ] Verify no unused imports

### Git Workflow

- [ ] Create feature branch:
  ```bash
  git checkout develop
  git pull origin develop
  git checkout -b feature/199-meal-type-filter
  ```
- [ ] Commit changes with proper message:
  ```bash
  git add .
  git commit -m "feat: add meal type filtering for recipes (#199)

  - Add meal_type column to recipes table (migration)
  - Update Recipe model with mealType field
  - Add meal type filter dropdown to RecipeListScreen
  - Implement filtering in RecipeService
  - Add localization for meal types (EN/PT-BR)
  - Comprehensive tests (unit, widget, integration, E2E)
  - Default existing recipes to 'any' meal type

  Closes #199

  Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
  ```
- [ ] Push to origin:
  ```bash
  git push -u origin feature/199-meal-type-filter
  ```
- [ ] Create pull request:
  ```bash
  gh pr create --title "feat: add meal type filtering for recipes" \
    --body "Implements #199 - meal type selection and filtering"
  ```

### Issue Closure

- [ ] Verify all acceptance criteria met
- [ ] Close issue #199 with reference to PR
- [ ] Note: Migration tested on both fresh and existing databases
- [ ] Delete feature branch after merge:
  ```bash
  git branch -d feature/199-meal-type-filter
  git push origin --delete feature/199-meal-type-filter
  ```

---

## Files to Modify

### Core Files
- `lib/core/models/recipe.dart` - Add mealType field, update serialization
- `lib/core/services/recipe_service.dart` - Add meal type filtering logic
- `lib/core/database/database_helper.dart` - Register new migration
- `lib/core/database/migrations/add_meal_type_migration.dart` - New migration file
- `lib/core/database/seed_data.dart` - Add meal_type to sample recipes

### UI Files
- `lib/screens/recipe_list_screen.dart` - Add meal type dropdown filter

### Localization Files
- `lib/l10n/app_en.arb` - Add meal type strings (6 new strings)
- `lib/l10n/app_pt.arb` - Add meal type translations (6 strings)

### Test Files
- `test/unit/recipe_service_test.dart` - Add filtering tests
- `test/unit/recipe_model_test.dart` - Add serialization tests
- `test/widget/recipe_list_screen_test.dart` - Add UI filtering tests
- `test/integration/meal_type_filtering_integration_test.dart` - New integration tests
- `test/integration/meal_type_migration_test.dart` - New migration tests
- `test/e2e/recipe_filtering_e2e_test.dart` - New E2E tests
- `test/edge_cases/empty_states/recipe_list_empty_test.dart` - Update empty state tests
- `test/edge_cases/boundary_conditions/meal_type_boundary_test.dart` - New boundary tests

---

## Testing Strategy

### Test Types Required

Based on issue type **Feature**, the following tests are required:

**Unit Tests**:
- [x] RecipeService filtering logic (5+ tests)
- [x] Recipe model serialization (4+ tests)
- **Coverage target**: >80% of new service code

**Widget Tests**:
- [x] Meal type dropdown rendering
- [x] Filtering behavior on selection
- [x] Filter combination (meal type + difficulty + rating)
- [x] Localization (EN/PT-BR)
- **Coverage target**: >70% of new UI code

**Integration Tests**:
- [x] Multi-component filtering workflow
- [x] Database migration (fresh + upgrade scenarios)

**E2E Tests**:
- [x] Complete user journey (select filter → see results → select recipe)
- [x] Happy path and empty state path

**Edge Case Tests**:
- [x] Empty states (no recipes match filter)
- [x] Boundary conditions (null, empty, invalid meal type)
- [x] Data integrity (migration doesn't corrupt data)

### Test Helpers to Use

- `TestSetup.setupMockDatabase()` - Mock database with test recipes
- `EdgeCaseTestHelpers.verifyEmptyState()` - Empty state verification
- Real database for migration tests

### Localization Testing

- [ ] Test RecipeListScreen in English (EN)
- [ ] Test RecipeListScreen in Portuguese (PT-BR)
- [ ] Verify dropdown layout with longer Portuguese strings
- [ ] Verify all 6 meal type options display correctly

---

## Acceptance Criteria

### From Issue #199
- [x] Recipes have meal_type field stored in database
- [x] Recipe list screen has meal type dropdown filter
- [x] Filtering by meal type works correctly
- [x] "Any" option shows all recipes
- [x] Meal type filter combines with existing filters (difficulty, rating)
- [x] All text localized in EN and PT-BR
- [x] Existing recipes default to "any" after migration

### Implicit Requirements
- [x] **Testing**: Unit + Widget + Integration + E2E + Edge cases
- [x] **Localization**: All meal type strings in both languages
- [x] **Code Quality**: `flutter analyze` shows no warnings
- [x] **Test Passing**: `flutter test` shows all tests passing
- [x] **Database Migration**: Tested on fresh + existing databases
- [x] **Git Workflow**: Proper branch, commit message, PR

### Definition of Done

This issue is complete when:
- [x] All acceptance criteria met
- [x] All 4 phases completed
- [x] Migration tested and verified
- [x] All tests passing (unit, widget, integration, E2E, edge cases)
- [x] Code merged to develop branch
- [x] Issue closed with reference to PR
- [x] No regression in existing functionality

---

## Risk Assessment

### Medium Risk Level

**Identified Risks**:

1. **Database Migration Failure** - Medium Risk
   - **Description**: Migration could fail on existing user databases
   - **Impact**: Users unable to upgrade app, potential data loss
   - **Likelihood**: Low (simple ALTER TABLE, default value provided)
   - **Mitigation**: Test migration thoroughly (fresh + upgrade), add default value, test rollback

2. **Filter UI Crowding** - Low Risk
   - **Description**: Three filters (difficulty, rating, meal type) might crowd UI on small screens
   - **Impact**: Poor UX, hard to use filters
   - **Likelihood**: Medium (small Android devices common)
   - **Mitigation**: Use Wrap widget for filter row, test on small screens (360dp width)

3. **RecipeFormDialog Needs Update** - Low Risk
   - **Description**: Users can't set meal type when creating/editing recipes
   - **Impact**: All recipes remain "any", filter not useful
   - **Likelihood**: High (form doesn't have meal type selector yet)
   - **Mitigation**: Note in follow-up work, or add to this issue scope (see Questions)

---

## Questions

Before implementation, please clarify:

### 1. RecipeFormDialog Scope
**Question**: Should this issue include adding meal type selector to RecipeFormDialog (for creating/editing recipes)?

**Context**: Issue #199 mentions filtering but doesn't explicitly mention recipe creation/editing. Currently, new recipes would default to "any" meal type with no way to change it.

**Options**:
- **Option A**: Include in this issue - Add meal type dropdown to RecipeFormDialog
  - Pros: Complete feature, users can set meal type immediately
  - Cons: Increases scope from 5 to ~8 story points
- **Option B**: Separate issue - Filter-only for now, creation/editing in follow-up
  - Pros: Smaller scope, faster delivery of filtering
  - Cons: Incomplete feature until follow-up

**Recommendation**: **Option B** (separate issue) - Keeps this issue focused on filtering, allows testing migration separately.

**Impact**: If Option A, need to update RecipeFormDialog, add more tests, add more localization strings.

---

### 2. Meal Type Persistence
**Question**: Should the selected meal type filter persist across app sessions?

**Context**: Other filters (difficulty, rating) currently reset on app restart.

**Options**:
- **Option A**: Persist filter - Use SharedPreferences to save last selection
  - Pros: Better UX, users don't re-select frequently
  - Cons: Slightly more complex implementation
- **Option B**: Reset on restart - Consistent with other filters
  - Pros: Simpler, consistent behavior
  - Cons: Users must re-select each time

**Recommendation**: **Option B** (reset on restart) - Consistent with existing filter behavior.

**Impact**: If Option A, need to add SharedPreferences logic, test persistence.

---

## Notes

**Assumptions**:
- Meal type values are hardcoded (breakfast, lunch, dinner, snack, any) - not user-configurable
- Default "any" is appropriate for existing recipes (not breakfast/lunch/dinner specific)
- RecipeFormDialog update will be separate issue (if not clarified otherwise)
- Filter reset on app restart (consistent with other filters)

**Follow-Up Work**:
- Add meal type selector to RecipeFormDialog (create/edit recipes)
- Consider adding meal type to MealPlanItem (meal planning context)
- Consider using meal type in recommendation algorithm (breakfast recipes for breakfast meal plans)

**References**:
- Issue: #199
- Related: RecipeFormDialog (no current issue for meal type selector)
- Architecture Docs: `docs/architecture/Gastrobrain-Codebase-Overview.md`
- Testing Guide: `docs/testing/EDGE_CASE_TESTING_GUIDE.md`
- Migration Pattern: See existing migrations in `lib/core/database/migrations/`

---

**Roadmap Created**: 2026-01-11
**Last Updated**: 2026-01-11
**Status**: Planning
