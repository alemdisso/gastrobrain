# Gastrobrain Issue Roadmap Creator Skill

A specialized Claude Code skill for generating comprehensive, phase-based implementation roadmaps for GitHub issues in the Gastrobrain Flutter project.

## Overview

This skill transforms GitHub issues into actionable implementation roadmaps with detailed checkbox lists covering analysis, implementation, testing, and documentation phases. It automatically applies Gastrobrain-specific conventions for testing, localization, and database changes.

## Files

- **SKILL.md**: Main skill definition with YAML frontmatter and complete roadmap generation framework
- **templates/roadmap_template.md**: Structured output template for generated roadmaps
- **examples/**: Complete example roadmaps for different issue types
  - `ui_bug_safearea.md` - UI bug fix (SafeArea overflow issue)
  - `feature_meal_type.md` - Feature with database changes (meal type filtering)
  - `refactor_service.md` - Refactoring task (service layer consolidation)
- **README.md**: This file

## Key Features

- **Phase-Based Structure**: 4 comprehensive phases (Analysis, Implementation, Testing, Documentation)
- **Automatic Convention Application**: Testing requirements, localization rules, database migration patterns
- **Issue Type Intelligence**: Adapts roadmap based on feature/bug/refactor/testing classification
- **Smart Questions**: Only asks when genuinely needed, not about obvious requirements
- **Actionable Checkbox Lists**: Every item is a concrete, trackable task
- **File Path Specificity**: References actual project files, not generic placeholders
- **Testing Matrix**: Detailed test requirements by issue type (unit, widget, integration, E2E, edge cases)

## When to Use

### Trigger Patterns

Invoke this skill when the user says:
- "Deal with #XXX"
- "Work on #XXX"
- "Create a roadmap for #XXX"
- "I want to implement #XXX"
- "Generate a plan for issue #XXX"

### Automatic Actions

The skill will:
1. Fetch issue details from GitHub (`gh issue view XXX`)
2. Analyze issue type and requirements
3. Apply project conventions automatically
4. Generate comprehensive 4-phase roadmap
5. Ask clarifying questions only if needed

## Roadmap Structure

### Phase 1: Analysis & Understanding
- Review existing code in affected areas
- Identify similar patterns in codebase
- Check dependencies and prerequisites
- Clarify requirements and edge cases

### Phase 2: Implementation
- Database changes (model, migration, seed data)
- Service layer changes (business logic)
- UI changes (screens, widgets, dialogs)
- Localization updates (EN/PT-BR ARB files)
- Error handling and validation

### Phase 3: Testing
- Unit tests (services, models, business logic)
- Widget tests (UI components, screens)
- Integration tests (multi-component workflows)
- E2E tests (complete user journeys)
- Edge case coverage (empty states, boundaries, errors)
- Regression tests (for bugs)

### Phase 4: Documentation & Cleanup
- Code documentation (comments for complex logic)
- Project documentation (README, architecture docs)
- Final verification (analyze, test, manual checks)
- Git workflow (branch, commit, PR, issue closure)

## Testing Requirements by Issue Type

### Feature Implementation
- ✅ Unit tests (service logic, business rules)
- ✅ Widget tests (UI components, screens)
- ✅ E2E tests (primary workflow)
- ✅ Edge case tests (empty states, boundaries, errors)
- **Coverage**: >80% for new code

### UI Bug Fix
- ✅ Widget test (regression - proves bug fixed)
- ✅ Widget test (affected components still work)
- ⚠️ Unit tests (if bug involves business logic)
- **Coverage**: Regression test + affected components

### Logic/Service Bug Fix
- ✅ Unit test (reproduces bug - fails before fix)
- ✅ Unit test (verifies fix - passes after fix)
- ✅ Unit tests (related edge cases)
- ⚠️ Integration test (if spans multiple components)
- **Coverage**: Regression test + edge cases

### Refactoring
- ✅ Maintain existing test coverage (all tests still pass)
- ✅ Update tests (if internal structure changes)
- ✅ Add tests (if refactoring exposes new testable units)
- ❌ No new behavior (tests prove behavior unchanged)
- **Coverage**: No decrease, ideally increase

### Testing Task
- ✅ Follow existing patterns (TestSetup, helpers)
- ✅ Add edge case coverage (Issue #39 standards)
- ✅ Document test patterns (if new helpers)
- **Coverage**: Per task requirements

## Localization Rules

### When Required
- ✅ New UI screens or dialogs
- ✅ User-facing messages (errors, confirmations, labels)
- ✅ Modifying existing user-facing text
- ✅ Form fields or buttons

### Checklist
- [ ] Add strings to `lib/l10n/app_en.arb` (English)
- [ ] Add translations to `lib/l10n/app_pt.arb` (Portuguese)
- [ ] Run `flutter gen-l10n`
- [ ] Use `AppLocalizations.of(context)!.stringKey` in code
- [ ] Use `DateFormat.yMd(locale)` for dates
- [ ] Test both languages visually

## Database Change Rules

### When Required
- ✅ Adding new table
- ✅ Adding/removing columns
- ✅ Changing column types or constraints
- ✅ Adding/removing foreign keys or indexes
- ✅ Restructuring relationships

### Checklist
- [ ] Update model class (`lib/core/models/*.dart`)
- [ ] Create migration file (`lib/core/database/migrations/*.dart`)
- [ ] Register migration in `DatabaseHelper`
- [ ] Update seed data (if needed)
- [ ] Test migration (fresh + upgrade scenarios)
- [ ] Update dependent code (services, UI, tests)

## Question Guidelines

### Ask When
- ✅ Issue description is ambiguous
- ✅ Multiple valid implementation approaches
- ✅ Scope boundaries unclear
- ✅ Edge cases not specified
- ✅ Breaking changes required

### Don't Ask When
- ❌ Standard testing requirements (always needed)
- ❌ Obvious localization needs (clear from UI changes)
- ❌ File locations (reference project structure)
- ❌ Git workflow (use feature branches)

Questions are grouped at the end of the roadmap with context, options, and recommendations.

## Example Usage

### User Request
```
User: "I want to deal with #250. Create a comprehensive roadmap in phases."
```

### Skill Actions
1. Fetches issue #250 from GitHub
2. Analyzes: UI bug, SafeArea overflow on small screens
3. Generates roadmap:
   - Phase 1: Review dialog code, identify overflow source
   - Phase 2: Add SafeArea + SingleChildScrollView
   - Phase 3: Widget tests + regression test
   - Phase 4: Documentation, git workflow
4. Lists specific files to modify
5. Details testing strategy (widget tests, screen size variations)
6. No questions needed (issue is clear)

### Output
Complete markdown document (see `examples/ui_bug_safearea.md`) with:
- 4 detailed phases with checkbox lists
- Specific file paths to modify
- Testing strategy with concrete test names
- Acceptance criteria (from issue + implicit)
- Low risk assessment with mitigations

## How to Use

### With Claude Code

```bash
# User says one of the trigger patterns
User: "Deal with #199"
User: "Create a roadmap for issue #237"
User: "I want to work on #250"

# Skill automatically:
# 1. Fetches issue from GitHub
# 2. Generates comprehensive roadmap
# 3. Asks clarifying questions (only if needed)
```

### Manual Invocation

```bash
# Explicitly invoke the skill
User: "/skill gastrobrain-issue-roadmap #199"
```

## Output Format

The skill generates a markdown document with:

### Header
- Issue number, title, type, priority, estimate, size, dependencies
- Branch name (follows Git Flow convention)

### Overview
- Brief summary of what the issue aims to accomplish
- Context from issue description
- Expected outcome

### Prerequisites Check
- Dependencies resolved
- Environment set up
- Latest develop branch
- Tests passing

### Phases 1-4
- Detailed checkbox lists for each phase
- Concrete, actionable tasks
- Specific file paths (not placeholders)
- Code examples where helpful

### Files to Modify
- Complete list of files with descriptions
- Organized by category (core, UI, tests, docs)

### Testing Strategy
- Test types required (based on issue type matrix)
- Specific tests needed
- Test helpers to use
- Coverage targets

### Acceptance Criteria
- From issue (copied exactly)
- Implicit requirements (testing, localization, etc.)
- Definition of done

### Risk Assessment
- High/Medium/Low risk level
- Identified risks with impact, likelihood, mitigations

### Questions (if needed)
- Grouped at end
- Context, options, recommendations provided
- Only for genuine uncertainties

## Benefits

### For Implementation
- Clear, step-by-step plan from start to finish
- No missed requirements (testing, localization, etc.)
- Trackable progress with checkbox lists
- Reduced cognitive load (plan already made)

### For Testing
- Comprehensive test coverage automatically planned
- Test types matched to issue type
- Edge cases explicitly considered
- Regression prevention built in

### For Architecture
- Consistent patterns applied automatically
- Service layer usage enforced
- Database migration best practices
- Separation of concerns maintained

### For Solo Developer
- No team coordination needed (acknowledged in plans)
- Focus on execution (planning done by skill)
- Comprehensive without overwhelming
- Professional documentation for future reference

## Project-Specific Patterns

### UI Layout Bugs
- SafeArea + SingleChildScrollView pattern
- Responsive design considerations
- Small screen testing

### Features with DB Changes
- Model → Migration → Service → UI → Localization
- Fresh + upgrade migration testing
- Seed data updates

### Service Consolidation
- Service layer over direct DB access
- Mock service setup in tests
- Behavior preservation in refactors

### Parser Improvements
- Regex pattern additions
- Unit conversion logic
- Edge case test coverage

### Testing Tasks
- Follow existing patterns (TestSetup, helpers)
- Issue #39 edge case standards
- Document new patterns

## Continuous Improvement

After completing roadmaps:
1. Review what worked well (kept as-is in roadmap)
2. Note deviations from plan (adjust future roadmaps)
3. Identify missing patterns (add to skill)
4. Update examples with real completed issues

## References

- Issue Workflow: `docs/workflows/ISSUE_WORKFLOW.md`
- Testing Guides:
  - `docs/testing/DIALOG_TESTING_GUIDE.md`
  - `docs/testing/EDGE_CASE_TESTING_GUIDE.md`
  - `docs/testing/MOCK_DATABASE_ERROR_SIMULATION.md`
- Architecture: `docs/architecture/Gastrobrain-Codebase-Overview.md`
- Localization: `docs/workflows/L10N_PROTOCOL.md`

## Version

**Current Version**: 1.0.0
**Last Updated**: 2026-01-11

---

## Example Roadmaps

See `examples/` directory for complete roadmaps:

### UI Bug Example: SafeArea Overflow (#250)
**Issue**: Dialog overflows on small screens when keyboard shown
**Roadmap**: Add SafeArea + SingleChildScrollView, regression tests
**Complexity**: 2 story points, simple fix
**See**: `examples/ui_bug_safearea.md`

### Feature Example: Meal Type Filtering (#199)
**Issue**: Add meal type (breakfast/lunch/dinner) filter to recipes
**Roadmap**: Database migration, model updates, service layer, UI dropdown, full testing
**Complexity**: 5 story points, moderate feature with DB changes
**See**: `examples/feature_meal_type.md`

### Refactoring Example: Service Layer Consolidation (#237)
**Issue**: Move dialogs from direct DB access to service layer
**Roadmap**: Update dialogs to use services, maintain behavior, update tests
**Complexity**: 5 story points, architectural improvement
**See**: `examples/refactor_service.md`

Each example shows complete 4-phase roadmap with real file paths, specific tests, and actionable checkbox lists.
