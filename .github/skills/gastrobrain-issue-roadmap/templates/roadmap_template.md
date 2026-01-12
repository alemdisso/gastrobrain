# Issue #[NUMBER]: [ISSUE_TITLE]

**Type**: [Feature/Bug/Refactor/Testing/Documentation]
**Priority**: [P0-Critical / P1-High / P2-Medium / P3-Low]
**Estimate**: [X story points / Y hours]
**Size**: [XS/S/M/L/XL]
**Dependencies**: [List issue numbers or "None"]
**Branch**: `[type]/[issue-number]-[short-description]`

---

## Overview

[Brief 2-3 sentence summary of what this issue aims to accomplish, extracted from issue description]

**Context**:
- [Key context point 1]
- [Key context point 2]

**Expected Outcome**:
[What success looks like when this issue is resolved]

---

## Prerequisites Check

Before starting implementation, verify:

- [ ] All dependent issues resolved (if any)
- [ ] Development environment set up (`flutter doctor`)
- [ ] On latest develop branch (`git checkout develop && git pull`)
- [ ] All existing tests passing (`flutter test`)
- [ ] No analysis warnings (`flutter analyze`)

**Prerequisite Knowledge**:
- [ ] Familiar with [relevant architectural pattern]
- [ ] Reviewed [similar feature/fix] in codebase
- [ ] Understand [key concept needed for this work]

---

## Phase 1: Analysis & Understanding

**Goal**: Understand the problem/feature and identify implementation approach

### Code Review
- [ ] Read issue description and all comments thoroughly
- [ ] Review existing code in affected areas:
  - [ ] `[file/path/1.dart]` - [what to look for]
  - [ ] `[file/path/2.dart]` - [what to look for]
- [ ] Identify similar patterns in codebase:
  - [ ] Review `[reference/file.dart]` for similar implementation
  - [ ] Check how `[similar feature]` was implemented

### Architectural Analysis
- [ ] Identify affected layers:
  - [ ] Models: [which models affected]
  - [ ] Services: [which services affected]
  - [ ] UI: [which screens/widgets affected]
  - [ ] Database: [schema changes needed?]
- [ ] Check for ripple effects:
  - [ ] Services depending on changed models
  - [ ] UI components using changed services
  - [ ] Tests covering affected code

### Dependency Check
- [ ] Verify no blocking issues open
- [ ] Check if new dependencies needed (pubspec.yaml)
- [ ] Identify potential conflicts with ongoing work

### Requirements Clarification
- [ ] Review acceptance criteria from issue
- [ ] Identify implicit requirements (testing, localization, etc.)
- [ ] Clarify edge cases and error handling
- [ ] [Additional clarification needed - see Questions section]

---

## Phase 2: Implementation

**Goal**: Make the core changes to fix/implement the issue

### Database Changes
[Remove this section if no database changes needed]

- [ ] Update model class: `lib/core/models/[model].dart`
  - [ ] Add/modify fields
  - [ ] Update `toMap()` method
  - [ ] Update `fromMap()` factory
  - [ ] Update `copyWith()` (if exists)
  - [ ] Add default values for new fields
- [ ] Create migration: `lib/core/database/migrations/[migration_name].dart`
  - [ ] Implement `up()` method (apply changes)
  - [ ] Implement `down()` method (rollback)
  - [ ] Set appropriate version number
- [ ] Register migration in `lib/core/database/database_helper.dart`
- [ ] Update seed data: `lib/core/database/seed_data.dart` (if needed)
- [ ] Test migration manually:
  - [ ] Fresh install (empty database)
  - [ ] Upgrade (existing data)

### Service Layer Changes
[Remove this section if no service changes needed]

- [ ] Update/create service: `lib/core/services/[service].dart`
  - [ ] Add/modify methods
  - [ ] Implement business logic
  - [ ] Add error handling (ValidationException, NotFoundException, etc.)
  - [ ] Update method documentation
- [ ] Update service provider: `lib/core/di/service_provider.dart` (if new service)
- [ ] Update dependent services (if any)

### UI Changes
[Remove this section if no UI changes needed]

- [ ] Update/create screen: `lib/screens/[screen].dart`
  - [ ] Add/modify widgets
  - [ ] Handle loading/error states
  - [ ] Connect to services via ServiceProvider
  - [ ] Add navigation (if needed)
- [ ] Update/create widget: `lib/widgets/[widget].dart` (if applicable)
  - [ ] Implement widget structure
  - [ ] Handle user interactions
  - [ ] Manage local state
- [ ] Add responsive design considerations:
  - [ ] Wrap with SafeArea (for screens)
  - [ ] Add SingleChildScrollView (if content can overflow)
  - [ ] Test on small screens
  - [ ] Handle keyboard overlap

### Localization Updates
[Remove this section if no user-facing text changes]

- [ ] Add strings to `lib/l10n/app_en.arb`:
  - [ ] `[stringKey1]`: "[English text]"
  - [ ] `[stringKey2]`: "[English text with {placeholder}]"
- [ ] Add translations to `lib/l10n/app_pt.arb`:
  - [ ] `[stringKey1]`: "[Texto em português]"
  - [ ] `[stringKey2]`: "[Texto em português com {placeholder}]"
- [ ] Run `flutter gen-l10n` to generate localization classes
- [ ] Update UI code to use `AppLocalizations.of(context)!.[stringKey]`
- [ ] Use `DateFormat.yMd(locale).format(date)` for dates (if applicable)
- [ ] Use `NumberFormat` for numbers (if applicable)

### Error Handling & Validation

- [ ] Add input validation (if applicable):
  - [ ] Form field validators
  - [ ] Business rule validation
  - [ ] Data type validation
- [ ] Add error handling:
  - [ ] Catch service exceptions
  - [ ] Display user-friendly error messages (localized)
  - [ ] Handle network/database errors gracefully
  - [ ] Add error recovery paths

### Code Quality

- [ ] Run `flutter analyze` and fix any warnings
- [ ] Add code comments for complex logic
- [ ] Follow Dart style guide
- [ ] Remove debug print statements
- [ ] Clean up unused imports

---

## Phase 3: Testing

**Goal**: Ensure changes work correctly and don't break existing functionality

### Unit Tests
[Adapt based on issue type - see Testing Requirements matrix in SKILL.md]

- [ ] Create/update test file: `test/unit/[name]_test.dart`
- [ ] Test service layer logic:
  - [ ] `test('[method] [expected behavior]')` - [description]
  - [ ] `test('[method] handles [edge case]')` - [description]
  - [ ] `test('[method] throws [exception] when [condition]')` - [description]
- [ ] Test model serialization:
  - [ ] `test('toMap converts model to map correctly')`
  - [ ] `test('fromMap creates model from map correctly')`
  - [ ] `test('handles null/missing fields gracefully')`
- [ ] Test business logic:
  - [ ] Happy path scenarios
  - [ ] Edge cases (empty, null, boundary values)
  - [ ] Error scenarios

### Widget Tests
[Required for all UI changes]

- [ ] Create/update test file: `test/widget/[name]_test.dart`
- [ ] Set up test:
  - [ ] Use `TestSetup.setupMockDatabase()` for mock data
  - [ ] Initialize required dependencies
- [ ] Test widget rendering:
  - [ ] `testWidgets('renders correctly', (tester) async { ... })`
  - [ ] `testWidgets('displays [element]', (tester) async { ... })`
- [ ] Test user interactions:
  - [ ] `testWidgets('handles [action]', (tester) async { ... })`
  - [ ] `testWidgets('updates state on [interaction]', (tester) async { ... })`
- [ ] Test error states:
  - [ ] `testWidgets('shows error message on failure', (tester) async { ... })`
  - [ ] `testWidgets('handles empty state', (tester) async { ... })`
- [ ] Test localization:
  - [ ] Verify both EN and PT-BR strings display
  - [ ] Test layout with different text lengths

### Integration Tests
[If feature spans multiple components]

- [ ] Create test file: `test/integration/[name]_integration_test.dart`
- [ ] Test multi-component workflows:
  - [ ] User journey from [start] to [end]
  - [ ] Data flow between components
  - [ ] State synchronization
- [ ] Use real database (not mocks) for integration tests

### E2E Tests
[Required for major features]

- [ ] Create test file: `test/e2e/[name]_e2e_test.dart`
- [ ] Test complete user workflows:
  - [ ] Happy path: [describe workflow]
  - [ ] Error path: [describe error scenario]
  - [ ] Recovery path: [describe recovery from error]

### Edge Case Tests
[Required per Issue #39 standards]

- [ ] Empty states: `test/edge_cases/empty_states/[name]_empty_test.dart`
  - [ ] `testWidgets('shows empty state when no data', (tester) async { ... })`
  - [ ] Verify helpful empty state message
  - [ ] Verify call-to-action available
- [ ] Boundary conditions: `test/edge_cases/boundary_conditions/[name]_boundary_test.dart`
  - [ ] Test with zero values
  - [ ] Test with maximum values
  - [ ] Test with negative values (if applicable)
  - [ ] Test with very long strings
- [ ] Error scenarios: `test/edge_cases/error_scenarios/[name]_error_test.dart`
  - [ ] Database error handling
  - [ ] Network error handling (if applicable)
  - [ ] Validation error display
  - [ ] Recovery from errors
- [ ] Data integrity: `test/edge_cases/data_integrity/[name]_integrity_test.dart`
  - [ ] No orphaned records after operations
  - [ ] Cascade deletes work correctly
  - [ ] Transaction rollback on error

### Regression Tests
[Required for bug fixes]

- [ ] Create regression test: `test/regression/[issue_number]_regression_test.dart`
- [ ] Test that reproduces original bug (would fail before fix)
- [ ] Verify fix resolves the issue (passes after fix)
- [ ] Test related scenarios that could cause similar bugs

### Test Execution & Verification

- [ ] Run all tests: `flutter test`
- [ ] Verify all tests pass
- [ ] Check test coverage (aim for >80% of new code)
- [ ] Run specific test file during development:
  - `flutter test test/unit/[name]_test.dart`
  - `flutter test test/widget/[name]_test.dart`

---

## Phase 4: Documentation & Cleanup

**Goal**: Finalize changes and prepare for merge

### Code Documentation

- [ ] Add/update code comments:
  - [ ] Complex business logic
  - [ ] Non-obvious implementation decisions
  - [ ] Workarounds or gotchas
- [ ] Update method documentation (if public API changes):
  - [ ] Parameter descriptions
  - [ ] Return value descriptions
  - [ ] Exception documentation

### Project Documentation
[Remove if no documentation updates needed]

- [ ] Update README.md (if feature affects usage)
- [ ] Update architecture docs (if structural changes)
- [ ] Update `docs/workflows/` (if workflow changes)
- [ ] Update `docs/testing/` (if new test patterns)

### Final Verification

- [ ] Run `flutter analyze` - no warnings
- [ ] Run `flutter test` - all tests pass
- [ ] Test both languages visually (EN and PT-BR)
- [ ] Test on small screen sizes (edge cases)
- [ ] Verify no debug code or console logs left
- [ ] Verify no commented-out code
- [ ] Verify no unused imports

### Git Workflow

- [ ] Create feature branch:
  ```bash
  git checkout develop
  git pull origin develop
  git checkout -b [type]/[issue-number]-[short-description]
  ```
- [ ] Commit changes with proper message:
  ```bash
  git add .
  git commit -m "[type]: [description] (#[issue-number])

  [Optional detailed description]

  Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
  ```
- [ ] Push to origin:
  ```bash
  git push -u origin [branch-name]
  ```
- [ ] Create pull request (if applicable):
  ```bash
  gh pr create --title "[type]: [description]" --body "[description]"
  ```

### Issue Closure

- [ ] Verify all acceptance criteria met
- [ ] Verify all implicit requirements met (testing, localization, etc.)
- [ ] Close issue with reference:
  - Reference commit hash or PR number
  - Note any deviations from original plan
  - Document any follow-up work needed
- [ ] Update related issues (if any)
- [ ] Delete feature branch (after merge):
  ```bash
  git branch -d [branch-name]
  git push origin --delete [branch-name]
  ```

---

## Files to Modify

### Core Files
- `lib/core/models/[model].dart` - [Description of changes]
- `lib/core/services/[service].dart` - [Description of changes]
- `lib/core/database/database_helper.dart` - [Description of changes]
- `lib/core/database/migrations/[migration].dart` - [New migration file]

### UI Files
- `lib/screens/[screen].dart` - [Description of changes]
- `lib/widgets/[widget].dart` - [Description of changes]

### Localization Files
- `lib/l10n/app_en.arb` - [New strings to add]
- `lib/l10n/app_pt.arb` - [New translations to add]

### Test Files
- `test/unit/[service]_test.dart` - [New unit tests]
- `test/widget/[widget]_test.dart` - [New widget tests]
- `test/integration/[feature]_integration_test.dart` - [New integration tests]
- `test/e2e/[feature]_e2e_test.dart` - [New E2E tests]
- `test/edge_cases/[category]/[name]_test.dart` - [New edge case tests]

### Documentation Files
- `README.md` - [If applicable]
- `docs/[relevant].md` - [If applicable]

---

## Testing Strategy

### Test Types Required

Based on issue type **[Feature/Bug/Refactor/Testing]**, the following tests are required:

**Unit Tests**:
- [ ] [Specific service method tests]
- [ ] [Specific model tests]
- [ ] [Specific business logic tests]
- **Coverage target**: >80% of new code

**Widget Tests**:
- [ ] [Specific widget rendering tests]
- [ ] [Specific interaction tests]
- [ ] [Specific state management tests]
- **Coverage target**: >70% of new widgets

**Integration Tests**:
- [ ] [Specific workflow tests]
- [ ] [Specific multi-component tests]

**E2E Tests**:
- [ ] [Specific user journey tests]
- [ ] Happy path and error path

**Edge Case Tests**:
- [ ] Empty states
- [ ] Boundary conditions
- [ ] Error scenarios
- [ ] Data integrity

### Test Helpers to Use

- `TestSetup.setupMockDatabase()` - Mock database setup
- `DialogTestHelpers` - Dialog testing utilities
- `EdgeCaseTestHelpers` - Edge case testing patterns
- `ErrorInjectionHelpers` - Error simulation for tests

### Localization Testing

- [ ] Test all new screens/dialogs in English (EN)
- [ ] Test all new screens/dialogs in Portuguese (PT-BR)
- [ ] Verify text fits in UI for both languages
- [ ] Verify date formatting uses locale-aware DateFormat
- [ ] Verify number formatting uses locale-aware NumberFormat (if applicable)

---

## Acceptance Criteria

### From Issue
[Copy acceptance criteria exactly from GitHub issue]

- [ ] [Criterion 1 from issue]
- [ ] [Criterion 2 from issue]
- [ ] [Criterion 3 from issue]

### Implicit Requirements
[Requirements not stated in issue but required by project standards]

- [ ] **Testing**: All test types completed (unit, widget, integration, E2E, edge cases)
- [ ] **Localization**: All user-facing text in both EN and PT-BR
- [ ] **Code Quality**: `flutter analyze` shows no warnings
- [ ] **Test Passing**: `flutter test` shows all tests passing
- [ ] **Database Migration**: Tested on both fresh and existing databases (if applicable)
- [ ] **Documentation**: Code comments added for complex logic
- [ ] **Git Workflow**: Proper branch, commit message, and PR (if applicable)

### Definition of Done

This issue is complete when:
- [ ] All acceptance criteria met (from issue and implicit)
- [ ] All 4 phases completed
- [ ] Code merged to develop branch (if applicable)
- [ ] Issue closed with reference to commit/PR
- [ ] No regression in existing functionality
- [ ] Test suite still at 600+ tests (or increased)

---

## Risk Assessment

### [High/Medium/Low] Risk Level

**Identified Risks**:

1. **[Risk Name]** - [Risk Level: High/Medium/Low]
   - **Description**: [What could go wrong]
   - **Impact**: [What would happen if risk occurs]
   - **Likelihood**: [How likely is this risk]
   - **Mitigation**: [How to prevent/minimize risk]

2. **[Risk Name]** - [Risk Level: High/Medium/Low]
   - **Description**: [What could go wrong]
   - **Impact**: [What would happen if risk occurs]
   - **Likelihood**: [How likely is this risk]
   - **Mitigation**: [How to prevent/minimize risk]

**Common Risks by Type**:

- **Database Migration**: Data loss, failed migration, rollback issues
  - *Mitigation*: Test thoroughly, backup data, implement down() migration
- **UI Changes**: Layout issues, overflow, localization problems
  - *Mitigation*: Test on small screens, test both languages, use SafeArea
- **Refactoring**: Breaking existing functionality, test failures
  - *Mitigation*: Run full test suite frequently, careful incremental changes
- **Service Changes**: Ripple effects, breaking dependent code
  - *Mitigation*: Search for all usages, update all callers, update tests

---

## Questions

[Only include this section if there are genuine uncertainties]

Before implementation, please clarify:

### 1. [Question Category]
**Question**: [Specific question about requirements/approach]?

**Context**: [Why this is unclear from the issue]

**Options**:
- **Option A**: [Approach 1] - [Pros/Cons]
- **Option B**: [Approach 2] - [Pros/Cons]

**Recommendation**: [Suggested approach based on project patterns]

**Impact**: [What depends on this decision]

---

### 2. [Question Category]
**Question**: [Specific question]?

**Context**: [Why this needs clarification]

**Options**:
- **Option A**: [Approach 1]
- **Option B**: [Approach 2]

**Recommendation**: [Suggested approach]

**Impact**: [Dependencies]

---

## Notes

[Any additional notes, assumptions, or important context]

**Assumptions**:
- [Assumption 1]
- [Assumption 2]

**Follow-Up Work**:
- [Related work that should be done in future issues]
- [Tech debt identified but out of scope]

**References**:
- Issue: #[issue-number]
- Related Issues: #[related-issue-1], #[related-issue-2]
- Architecture Docs: `docs/architecture/[relevant-doc].md`
- Testing Guides: `docs/testing/[relevant-guide].md`
- Workflow Docs: `docs/workflows/[relevant-workflow].md`

---

**Roadmap Created**: [Date]
**Last Updated**: [Date]
**Status**: [Planning/In Progress/Complete]
