---
name: "Gastrobrain Issue Roadmap Creator"
description: "Generates actionable, phase-based implementation roadmaps for GitHub issues. Creates comprehensive markdown documents with checkbox lists for analysis, implementation, testing, and documentation phases. Applies Gastrobrain-specific testing, localization, and database conventions automatically."
version: "1.0.0"
author: "Gastrobrain Development Team"
---

# Gastrobrain Issue Roadmap Creator

A specialized skill for generating comprehensive, phase-based implementation roadmaps for GitHub issues in the Gastrobrain Flutter project. Produces actionable markdown documents with checkbox lists that guide the entire implementation process.

## When to Use This Skill

### Trigger Patterns

Use this skill when the user says:
- "Deal with #XXX"
- "Work on #XXX"
- "Create a roadmap for #XXX"
- "I want to implement #XXX"
- "Generate a plan for issue #XXX"
- "Help me with #XXX" (when referring to a GitHub issue)

### Automatic Actions

When triggered:
1. **Immediately fetch issue details** from GitHub using `gh issue view XXX`
2. **Fetch story points** from GitHub Project #3: `gh project item-list 3 --owner alemdisso --format json --limit 100` — use the `estimate` field (source of truth for story points, not issue body)
3. **Analyze issue type** (feature, bug, refactor, testing)
4. **Apply project conventions** (testing, localization, database)
5. **Generate complete roadmap** using the template
6. **Ask clarifying questions** only if genuinely needed

### Do NOT Use This Skill

- For sprint planning (use `gastrobrain-sprint-planner` instead)
- For exploratory codebase analysis (use Task tool with Explore agent)
- For general questions about the project
- For immediate implementation without roadmap

## Project Context

### Development Environment
- **Project**: Gastrobrain - Flutter meal planning & recipe management app
- **Database**: SQLite with migrations and seed data
- **Localization**: Bilingual (English, Portuguese-BR) - mandatory for all UI changes
- **Testing**: 600+ tests - non-negotiable requirement for all changes
- **Workflow**: Git Flow (feature branches → develop → release → master)
- **Issue Tracking**: GitHub Projects #3 with story point estimates
- **Team**: Solo developer (no team coordination needed in roadmaps)

### Key Architectural Patterns
- **Dependency Injection**: `ServiceProvider` for accessing services
- **Database Operations**: `DatabaseHelper` with custom exceptions
- **Error Handling**: `NotFoundException`, `ValidationException`, `GastrobrainException`
- **Multi-Recipe Meals**: `MealPlanItemRecipe` (planning) and `MealRecipe` (cooking)
- **Testing**: `MockDatabaseHelper` for unit tests, real DB for integration tests

### Project Structure
```
lib/
├── core/
│   ├── database/           # DatabaseHelper, migrations
│   ├── di/                 # ServiceProvider (dependency injection)
│   ├── models/             # Data models
│   └── services/           # Business logic services
├── l10n/                   # app_en.arb, app_pt.arb
├── screens/                # Top-level screen widgets
├── widgets/                # Reusable UI components
└── utils/                  # Helpers, parsers, formatters

test/
├── unit/                   # Business logic, models, services
├── widget/                 # UI components, screens
├── integration/            # Multi-component workflows
├── e2e/                    # End-to-end user journeys
├── edge_cases/             # Issue #39 coverage
│   ├── empty_states/
│   ├── boundary_conditions/
│   ├── error_scenarios/
│   ├── interaction_patterns/
│   └── data_integrity/
└── regression/             # Bug regression tests
```

## Roadmap Structure

All roadmaps follow a **4-phase approach**:

### Phase 1: Analysis & Understanding
**Purpose**: Understand existing code and identify implementation approach

**Typical tasks**:
- [ ] Read issue description and acceptance criteria
- [ ] Review existing code in related files
- [ ] Identify similar patterns in codebase
- [ ] Check for dependencies or prerequisites
- [ ] Clarify unknowns (ask questions if needed)

**When to expand**:
- New features: Review architecture, design patterns
- Refactoring: Analyze current implementation, identify code smells
- Bugs: Reproduce issue, identify root cause
- Testing: Review test coverage gaps, analyze edge cases

### Phase 2: Implementation
**Purpose**: Make the core changes to fix/implement the issue

**Typical tasks**:
- [ ] Update/create model classes (if database changes)
- [ ] Create database migration (if schema changes)
- [ ] Implement service layer logic (business rules)
- [ ] Create/update UI components (screens, widgets, dialogs)
- [ ] Add localization strings (app_en.arb, app_pt.arb)
- [ ] Handle error cases and validation
- [ ] Run `flutter analyze` to check for issues

**Checklist by change type**:
- **Model changes**: Update class, migration, seed data
- **Service changes**: Update interface, implementation, error handling
- **UI changes**: Update widget, add localization, handle states
- **Database schema**: Migration file, update models, test migration

### Phase 3: Testing
**Purpose**: Ensure changes work correctly and don't break existing functionality

**Mandatory for ALL issues** - never skip this phase.

**Typical tasks**:
- [ ] Write/update unit tests (services, models, business logic)
- [ ] Write/update widget tests (UI components, screens)
- [ ] Write integration tests (multi-component workflows)
- [ ] Write E2E tests (full user journeys)
- [ ] Add edge case coverage (empty states, boundaries, errors)
- [ ] Add regression test (for bugs)
- [ ] Run `flutter test` to verify all tests pass
- [ ] Verify localization in both languages

**See "Testing Requirements by Issue Type" section** for specific test types needed.

### Phase 4: Documentation & Cleanup
**Purpose**: Finalize changes and prepare for merge

**Typical tasks**:
- [ ] Update code comments (if complex logic)
- [ ] Update README or docs (if public API changes)
- [ ] Run final `flutter analyze && flutter test`
- [ ] Commit with proper message format: `type: description (#issue)`
- [ ] Push to feature branch
- [ ] Create pull request (if needed)
- [ ] Close issue with reference to commit/PR

## Testing Requirements by Issue Type

### Feature Implementation

**Required Tests**:
- ✅ **Unit tests**: All service layer logic, business rules, data transformations
- ✅ **Widget tests**: All new UI components, screens, forms, dialogs
- ✅ **E2E tests**: Primary user workflow (happy path + error path)
- ✅ **Edge case tests**: Empty states, boundary conditions, error scenarios

**Coverage Target**: >80% for new code

**Example** (Add meal type filter):
```dart
// Unit tests
- test('filters recipes by meal type correctly')
- test('handles empty meal type gracefully')
- test('combines meal type with other filters')

// Widget tests
- testWidgets('shows meal type dropdown')
- testWidgets('applies filter on selection')
- testWidgets('displays filtered results')

// E2E tests
- testWidgets('user can filter and select recipe')

// Edge cases
- testWidgets('shows empty state when no matches')
- testWidgets('handles invalid meal type')
```

### UI Bug Fix

**Required Tests**:
- ✅ **Widget test**: Demonstrates bug is fixed (regression test)
- ✅ **Widget test**: Verifies fix doesn't break related UI
- ⚠️ **Unit tests**: If bug involves business logic

**Coverage Target**: Regression test + affected components

**Example** (Fix SafeArea issue):
```dart
// Widget regression test
- testWidgets('content respects safe area on small screens')
- testWidgets('no overflow on various screen sizes')
- testWidgets('dialog displays correctly with keyboard')
```

### Logic/Service Bug Fix

**Required Tests**:
- ✅ **Unit test**: Reproduces the bug (fails before fix)
- ✅ **Unit test**: Verifies fix works (passes after fix)
- ✅ **Unit tests**: Related edge cases that could cause similar bugs
- ⚠️ **Integration test**: If bug spans multiple components

**Coverage Target**: Regression test + edge cases

**Example** (Fix recipe deletion not updating UI):
```dart
// Unit regression test
- test('deleting recipe removes from list')
- test('deleting last recipe shows empty state')
- test('deleting recipe updates recommendation cache')

// Edge cases
- test('handles deletion of non-existent recipe')
- test('handles concurrent deletions')
```

### Refactoring

**Required Tests**:
- ✅ **Maintain existing test coverage**: All existing tests still pass
- ✅ **Update tests**: Reflect new structure (if internal changes)
- ✅ **Add tests**: If refactoring exposes new testable units
- ❌ **No new behavior**: Tests should prove behavior unchanged

**Coverage Target**: No decrease in coverage, ideally increase

**Example** (Extract service logic):
```dart
// Updated tests for new structure
- test('extracted service maintains same behavior')
- test('old interface still works (if kept for compatibility)')
- test('new service handles all edge cases')
```

### Testing Task

**Required Tests**:
- ✅ **Follow existing patterns**: Use `TestSetup`, `DialogTestHelpers`, etc.
- ✅ **Add edge case coverage**: Per Issue #39 standards
- ✅ **Document test patterns**: If establishing new helpers

**Coverage Target**: Per task requirements (usually specific gap-filling)

**Example** (Add edge case coverage for ingredients):
```dart
// Empty states
- testWidgets('shows empty state with no ingredients')

// Boundary conditions
- test('handles zero quantity')
- test('handles negative quantity (validation)')

// Error scenarios
- test('handles database error gracefully')
- test('shows error message on failed save')

// Interaction patterns
- testWidgets('handles rapid successive adds')
```

## Localization Rules

### When Localization is Required

**Always required** when:
- ✅ Adding new UI screens or dialogs
- ✅ Adding user-facing messages (errors, confirmations, labels)
- ✅ Modifying existing user-facing text
- ✅ Adding form fields or buttons

**Not required** when:
- ❌ Backend-only changes (services, models)
- ❌ Test code
- ❌ Internal logging or debugging strings

### Localization Checklist

When UI text changes are needed:

- [ ] Add strings to `lib/l10n/app_en.arb` (English)
- [ ] Add translations to `lib/l10n/app_pt.arb` (Portuguese)
- [ ] Run `flutter gen-l10n` to generate localization code
- [ ] Use `AppLocalizations.of(context)!.stringKey` in code
- [ ] Use `DateFormat.yMd(locale)` for dates (never hardcode format)
- [ ] Use `NumberFormat.decimalPattern(locale)` for numbers (if applicable)
- [ ] Test both languages visually (ensure text fits in UI)
- [ ] Verify plurals use proper ICU syntax (if applicable)

### ARB File Format

**app_en.arb**:
```json
{
  "myFeatureTitle": "My Feature Title",
  "@myFeatureTitle": {
    "description": "Title for my feature screen"
  },
  "myFeatureError": "An error occurred: {error}",
  "@myFeatureError": {
    "description": "Error message shown when feature fails",
    "placeholders": {
      "error": {
        "type": "String"
      }
    }
  }
}
```

**app_pt.arb**:
```json
{
  "myFeatureTitle": "Título do Meu Recurso",
  "myFeatureError": "Ocorreu um erro: {error}"
}
```

### Common Localization Patterns

**Screen titles**:
```dart
AppLocalizations.of(context)!.recipeListTitle
```

**Error messages**:
```dart
AppLocalizations.of(context)!.recipeNotFound
```

**Parameterized strings**:
```dart
// ARB: "recipeCount": "{count} recipes"
AppLocalizations.of(context)!.recipeCount(recipes.length)
```

**Dates**:
```dart
import 'package:intl/intl.dart';

final locale = Localizations.localeOf(context).toString();
final dateStr = DateFormat.yMd(locale).format(date);
```

## Database Change Rules

### When Database Changes are Required

**Schema changes needed** when:
- ✅ Adding new table
- ✅ Adding/removing columns
- ✅ Changing column types or constraints
- ✅ Adding/removing foreign keys or indexes
- ✅ Restructuring relationships (junction tables, etc.)

**No schema changes** when:
- ❌ Only changing data (use seed data instead)
- ❌ Only changing business logic
- ❌ Only changing UI

### Database Change Checklist

When database schema changes are needed:

- [ ] **Update model class** (`lib/core/models/*.dart`)
  - Add/remove fields
  - Update constructor, fromMap, toMap methods
  - Update any custom methods (copyWith, etc.)

- [ ] **Create migration file** (`lib/core/database/migrations/*.dart`)
  - Create new migration class extending `Migration`
  - Implement `up()` method (apply changes)
  - Implement `down()` method (rollback changes)
  - Add to migration list in `DatabaseHelper`

- [ ] **Update seed data** (if needed - `lib/core/database/seed_data.dart`)
  - Add new required data
  - Update existing data format
  - Ensure seed data matches new schema

- [ ] **Test migration**
  - Test migration on empty database (fresh install)
  - Test migration on database with existing data (upgrade)
  - Verify data integrity after migration
  - Test rollback (down migration)

- [ ] **Update dependent code**
  - Update services using the model
  - Update UI displaying the data
  - Update tests using the model

### Migration Pattern

**Example migration**:
```dart
class AddMealTypeToRecipeMigration extends Migration {
  @override
  int get version => 5; // Increment version

  @override
  Future<void> up(Database db) async {
    await db.execute('''
      ALTER TABLE recipes
      ADD COLUMN meal_type TEXT DEFAULT 'any'
    ''');
  }

  @override
  Future<void> down(Database db) async {
    // Note: SQLite doesn't support DROP COLUMN easily
    // Usually need to recreate table or leave column
    // Document the limitation
  }
}
```

### Model Update Pattern

**Before**:
```dart
class Recipe {
  final int id;
  final String name;

  Recipe({required this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'],
      name: map['name'],
    );
  }
}
```

**After** (adding meal_type):
```dart
class Recipe {
  final int id;
  final String name;
  final String mealType; // New field

  Recipe({
    required this.id,
    required this.name,
    this.mealType = 'any', // Default value
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'meal_type': mealType, // Add to map
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'],
      name: map['name'],
      mealType: map['meal_type'] ?? 'any', // Handle existing data
    );
  }
}
```

## Files by Issue Type

### UI Bug (Layout, Overflow, SafeArea)

**Files to check**:
- `lib/screens/*_screen.dart` - Screen with the issue
- `lib/widgets/*_widget.dart` - Affected widgets
- `test/widget/*_test.dart` - Widget tests for regression

**Typical changes**:
- Add `SafeArea` wrapper
- Fix `Column` with `SingleChildScrollView`
- Adjust `Padding` or `Margin`
- Fix responsive layout with `MediaQuery`

### Feature with Database Changes

**Files to check**:
- `lib/core/models/*.dart` - Data model
- `lib/core/database/migrations/*.dart` - New migration file
- `lib/core/database/database_helper.dart` - Migration registration
- `lib/core/database/seed_data.dart` - Seed data updates
- `lib/core/services/*_service.dart` - Business logic
- `lib/screens/*.dart` - UI screens
- `lib/widgets/*.dart` - UI components
- `lib/l10n/app_en.arb`, `lib/l10n/app_pt.arb` - Localization
- `test/unit/*_test.dart` - Service tests
- `test/widget/*_test.dart` - Widget tests
- `test/integration/*_test.dart` - Integration tests

**Typical changes**:
- Update model class (add fields)
- Create migration (alter table)
- Update service (new business logic)
- Update UI (forms, displays)
- Add localization strings
- Add comprehensive tests

### Service Refactoring

**Files to check**:
- `lib/core/services/*_service.dart` - Service to refactor
- `lib/core/di/service_provider.dart` - DI registration
- `lib/screens/*.dart` - Screens using service
- `lib/widgets/*.dart` - Widgets using service
- `test/unit/*_test.dart` - Unit tests for service
- `test/widget/*_test.dart` - Widget tests using service

**Typical changes**:
- Extract service methods
- Consolidate similar services
- Update dependency injection
- Update all callers
- Update all tests

### Parser Improvements

**Files to check**:
- `lib/utils/ingredient_parser.dart` - Parser logic
- `lib/utils/unit_converter.dart` - Unit conversion
- `test/unit/ingredient_parser_test.dart` - Parser tests

**Typical changes**:
- Add regex patterns
- Handle new formats
- Improve unit detection
- Add edge case tests

### Testing Task

**Files to check**:
- `test/widget/*_test.dart` - Widget tests to add
- `test/unit/*_test.dart` - Unit tests to add
- `test/edge_cases/*/*.dart` - Edge case coverage
- `test/helpers/*_helpers.dart` - Test helpers (if creating new patterns)

**Typical changes**:
- Add missing test coverage
- Follow existing test patterns
- Use `TestSetup`, `DialogTestHelpers`, `EdgeCaseTestHelpers`
- Add regression tests

## Question Guidelines

### When to Ask Questions

**Ask when**:
- ✅ Issue description is ambiguous or incomplete
- ✅ Multiple valid implementation approaches exist
- ✅ Scope boundaries unclear (what's in/out of this issue)
- ✅ Edge cases not specified in issue
- ✅ Acceptance criteria missing or vague
- ✅ Breaking changes required (need user confirmation)

### When NOT to Ask Questions

**Don't ask when**:
- ❌ Standard testing requirements (always needed, per this skill)
- ❌ Obvious localization needs (clear from UI changes)
- ❌ File locations (reference project structure above)
- ❌ Git workflow (use feature branches per Git Flow)
- ❌ Code formatting (use `flutter analyze` and Dart conventions)
- ❌ Dependency injection (use `ServiceProvider`)

### Question Format

**Group questions at end of roadmap** under "Questions" section:

```markdown
## Questions

Before implementation, please clarify:

1. **[Category]**: [Specific question]?
   - Option A: [Approach 1]
   - Option B: [Approach 2]
   - Recommendation: [Your recommendation based on patterns]

2. **[Category]**: [Specific question]?
   - Context: [Why this is unclear]
   - Impact: [What depends on this decision]
```

**Example good questions**:
- "Should the meal type filter be persistent across sessions or reset on app restart?"
- "Should we allow multiple meal types per recipe or single selection only?"
- "The issue mentions 'improve performance' - should we prioritize memory or speed?"

**Example bad questions** (don't ask these):
- "Should we write tests?" (YES, always)
- "Should we localize the UI?" (YES, if user-facing text)
- "What branch should we use?" (Feature branch per Git Flow)

## Output Format Standards

### Document Structure

Use the template at `templates/roadmap_template.md` with these sections:

1. **Header**: Issue number, title, metadata (type, priority, estimate, dependencies)
2. **Overview**: Brief context from issue description
3. **Prerequisites Check**: Items to verify before starting
4. **Phase 1-4**: Detailed checkbox lists for each phase
5. **Files to Modify**: Specific file paths
6. **Testing Strategy**: Detailed test plan
7. **Acceptance Criteria**: From issue + implicit requirements
8. **Risk Assessment**: If applicable
9. **Questions**: If needed

### Formatting Conventions

**Checkbox lists**:
```markdown
- [ ] Action item 1
- [ ] Action item 2
  - Sub-item (if needed)
```

**File paths** (in code blocks):
```markdown
## Files to Modify

- `lib/screens/recipe_list_screen.dart`
- `lib/core/services/recipe_service.dart`
- `test/widget/recipe_list_screen_test.dart`
```

**Code examples** (when helpful):
```dart
// Example migration
await db.execute('''
  ALTER TABLE recipes ADD COLUMN meal_type TEXT
''');
```

**Section headers** (consistent hierarchy):
- `#` for document title
- `##` for major sections (Phase 1, Phase 2, etc.)
- `###` for subsections

### Tone and Style

**Be**:
- ✅ Actionable (every item is a concrete task)
- ✅ Specific (reference actual file paths, methods, patterns)
- ✅ Concise (user knows the codebase, no fluff)
- ✅ Professional (clear, organized, comprehensive)

**Don't be**:
- ❌ Explanatory about obvious things (user is experienced)
- ❌ Verbose (no unnecessary context)
- ❌ Vague (no "update relevant files" - specify which files)
- ❌ Tutorial-style (no "here's how X works" unless essential)

### Implicit Requirements

Always include these even if not in issue:

**Testing** (Phase 3):
- Unit tests for services/models
- Widget tests for UI components
- E2E tests for workflows
- Edge case coverage
- Regression tests for bugs

**Localization** (if UI changes):
- Update app_en.arb
- Update app_pt.arb
- Run flutter gen-l10n
- Test both languages

**Code Quality** (Phase 4):
- Run flutter analyze (no warnings)
- Run flutter test (all pass)
- Update comments (if complex)
- Follow Dart conventions

**Git Workflow** (Phase 4):
- Feature branch: `type/issue-number-short-description`
- Commit message: `type: description (#issue-number)`
- Push to origin
- Create PR (if applicable)
- Close issue

## Issue Type Patterns

### UI Layout Bugs (SafeArea, Overflow)

**Common patterns**:
- Small screens don't have enough space
- Keyboard overlaps input fields
- Content extends into notch/status bar areas
- Horizontal/vertical overflow

**Typical fix**:
```dart
// Wrap content in SafeArea
SafeArea(
  child: SingleChildScrollView(
    child: Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [/* content */],
      ),
    ),
  ),
)
```

**Roadmap focus**:
- Phase 1: Reproduce on small screen, identify overflow source
- Phase 2: Add SafeArea, scrolling, adjust padding
- Phase 3: Widget test on various screen sizes
- Phase 4: Verify on both platforms

### Feature with Database Changes

**Common patterns**:
- Add new entity (new table)
- Add new field to existing entity (alter table)
- Add relationship (foreign key, junction table)

**Roadmap focus**:
- Phase 1: Design schema changes, plan migration
- Phase 2: Model → Migration → Service → UI → Localization
- Phase 3: Unit tests (service), widget tests (UI), E2E (workflow)
- Phase 4: Test migration on fresh + existing DB

### Service Consolidation Refactoring

**Common patterns**:
- Extract common logic from multiple services
- Merge similar services
- Simplify service interfaces

**Roadmap focus**:
- Phase 1: Analyze current services, identify duplication
- Phase 2: Extract/consolidate, update DI, update callers
- Phase 3: Ensure all existing tests pass, add new tests
- Phase 4: Verify no behavior changes

### Testing Coverage Improvements

**Common patterns**:
- Add edge case coverage (Issue #39 standards)
- Add widget tests for uncovered components
- Add regression tests for fixed bugs
- Add E2E tests for critical workflows

**Roadmap focus**:
- Phase 1: Identify coverage gaps, review existing patterns
- Phase 2: N/A (testing-only task)
- Phase 3: Write tests using helpers, verify coverage increase
- Phase 4: Document test patterns if new helpers created

## Examples Reference

See `examples/` directory for complete roadmap examples:

- **UI Bug**: `examples/ui_bug_safearea.md` - SafeArea issue (simple fix)
- **Feature**: `examples/feature_meal_type.md` - Meal type selection (DB changes)
- **Refactoring**: `examples/refactor_service.md` - Service consolidation
- **Testing**: `examples/testing_dialog_coverage.md` - Dialog test coverage

## Usage Instructions

### Step 1: Recognize Trigger

When user says "deal with #XXX" or similar trigger:
- Immediately use `gh issue view XXX --json number,title,body,labels` to fetch issue details
- Fetch story points from Project #3: `gh project item-list 3 --owner alemdisso --format json --limit 100` — use the `estimate` field (source of truth, not issue body)
- Parse issue details (type, description, acceptance criteria)

### Step 2: Analyze Issue Type

Determine:
- Issue type: feature, bug, refactor, testing
- Affected areas: UI, service, database, parser
- Required changes: model, migration, localization, tests

### Step 3: Apply Project Conventions

Automatically include:
- Testing requirements (based on issue type matrix)
- Localization (if UI changes)
- Database migration (if schema changes)
- Git workflow (feature branch, commit format)

### Step 4: Generate Roadmap

Use `templates/roadmap_template.md` structure:
1. Fill in header with issue metadata
2. Write Phase 1 (analysis tasks)
3. Write Phase 2 (implementation tasks)
4. Write Phase 3 (testing tasks - mandatory)
5. Write Phase 4 (documentation tasks)
6. List specific file paths
7. Detail testing strategy
8. Include acceptance criteria + implicit requirements

### Step 5: Add Questions (if needed)

Only if genuinely unclear from issue:
- Group at end under "Questions" section
- Provide context and options
- Recommend preferred approach

### Step 6: Present Roadmap

- Output complete markdown document
- Use checkbox lists for trackability
- Reference actual file paths from project structure
- Keep tone concise and actionable

## Roadmap Validation Checklist

Before presenting roadmap, verify:

- [ ] Issue details fetched from GitHub
- [ ] All 4 phases included (Analysis, Implementation, Testing, Documentation)
- [ ] Phase 3 (Testing) has specific test types based on issue type
- [ ] Localization included if UI text changes
- [ ] Database migration included if schema changes
- [ ] Specific file paths listed (not "relevant files")
- [ ] Acceptance criteria from issue included
- [ ] Implicit requirements included (testing, localization, etc.)
- [ ] Questions section only if genuinely needed
- [ ] Checkbox lists for all actionable items
- [ ] Professional, concise tone

## Version History

- **1.0.0** (2026-01-11): Initial skill creation with 4-phase roadmap structure
