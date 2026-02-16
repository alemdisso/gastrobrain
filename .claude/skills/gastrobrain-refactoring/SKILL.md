---
name: Gastrobrain Refactoring Guide
description: Guide systematic code refactoring to improve readability, maintainability, and adherence to SOLID principles through checkpoint-driven iterations. Use when files exceed 300-400 lines, code duplication exists, or before major features.
---

# Refactoring Skill

## Purpose
Guide systematic code refactoring to improve readability, maintainability, and adherence to SOLID principles through checkpoint-driven iterations. Acts as a dedicated code quality specialist focused on keeping the codebase clean and well-organized.

## Gastrobrain-Specific Context

This skill is tailored for the Gastrobrain Flutter/Dart project with specific considerations:

**Project Structure:**
- Flutter application with 600+ test suite
- Service layer pattern with dependency injection via `ServiceProvider`
- Database layer using `DatabaseHelper` with custom exception hierarchy
- Screen/widget architecture with dialog-based interactions
- Localization support (English/Portuguese ARB files)

**Common Refactoring Scenarios:**
- **Long screens** (>500 lines) - Extract widgets, move business logic to services
- **Service consolidation** - Move database operations from screens/dialogs to service layer
- **Dialog refactoring** - Improve dependency injection, extract reusable components
- **Duplicate code elimination** - Particularly in ingredient parsing, meal recording, recipe management
- **Test infrastructure** - MockDatabaseHelper patterns, DialogTestHelpers usage

**Testing Requirements:**
- All 600+ tests must remain passing throughout refactoring
- Use `flutter analyze` for static analysis validation
- Maintain or improve test coverage
- Local builds and device testing available via VS Code on Windows; CI/CD also available via GitHub Actions

**Historical Context:**
Reference past successful refactorings as examples:
- Issue #234-237: Dialog database access consolidation to service layer
- Service extraction patterns from god classes
- Screen decomposition into widgets + services

## Trigger Patterns

Use this skill when the user says:
- "Refactor [file/class/screen]"
- "This code needs refactoring"
- "Clean up [component]"
- "Extract service from [screen]"
- "Consolidate [duplicate code]"
- "This file is too long"
- "Break up [god class]"
- "Improve code quality for [component]"

## When to Use
- Files exceeding reasonable length (>300-400 lines)
- Classes/methods with too many responsibilities
- Code duplication across multiple files
- Poor separation of concerns
- Complex methods that are hard to understand
- Technical debt accumulation
- Before major feature additions (clean foundation)
- After rapid prototyping phases

## Prerequisites
- Existing codebase to refactor
- All tests passing (or test coverage for affected code)
- Understanding of the feature's current functionality
- Access to the Flutter/Dart project

## Skill Workflow

### CHECKPOINT 1: Code Analysis & Smell Detection
**Objective:** Identify specific code quality issues and refactoring opportunities

**Actions:**
1. Review target files/modules for code smells:
   - **Long files** (>300-400 lines)
   - **God classes** (classes doing too much)
   - **Long methods** (>50 lines, multiple responsibilities)
   - **Code duplication** (repeated logic across files)
   - **Poor naming** (unclear variable/method names)
   - **Deep nesting** (>3-4 levels)
   - **Feature envy** (methods using other classes' data excessively)
   - **Primitive obsession** (using primitives instead of domain objects)
   - **Large parameter lists** (>3-4 parameters)

2. Analyze dependencies and coupling:
   - Tight coupling between unrelated components
   - Missing abstractions
   - Violation of dependency inversion

3. Check adherence to SOLID principles:
   - Single Responsibility Principle violations
   - Open/Closed Principle violations
   - Liskov Substitution Principle violations
   - Interface Segregation Principle violations
   - Dependency Inversion Principle violations

4. Review test coverage for affected code

**Output:** 
- List of specific code smells identified
- Files/classes/methods flagged for refactoring
- SOLID principle violations noted
- Prioritized list of issues (highest impact first)

**User Confirmation Required:** Does this analysis identify the key problems? Any additional concerns or areas to focus on?

---

### CHECKPOINT 2: Refactoring Strategy
**Objective:** Plan the refactoring approach without breaking functionality

**Actions:**
1. For each identified issue, propose refactoring technique:
   - **Extract Method** - break long methods into smaller, named pieces
   - **Extract Class** - split god classes by responsibility
   - **Move Method/Field** - relocate to more appropriate classes
   - **Replace Magic Numbers with Named Constants**
   - **Introduce Parameter Object** - group related parameters
   - **Replace Conditional with Polymorphism**
   - **Extract Interface** - define contracts for flexibility
   - **Introduce Domain Objects** - replace primitives with value objects
   - **Remove Duplication** - consolidate repeated code

2. Identify dependencies and order of refactoring:
   - Which refactorings must happen first?
   - Which files will be affected?
   - Are there circular dependencies to break?

3. Plan for maintaining test coverage:
   - Which tests need updating?
   - Do new tests need to be written?
   - How to verify behavior preservation?

4. Consider breaking changes:
   - Will public APIs change?
   - How to minimize impact?
   - Migration strategy if needed

**Output:** 
- Specific refactoring plan with techniques for each issue
- Order of refactoring operations
- List of files to be modified/created
- Test strategy to ensure correctness

**User Confirmation Required:** Does this refactoring strategy make sense? Any concerns about the approach?

---

### CHECKPOINT 3: Test Verification Setup
**Objective:** Ensure tests exist and pass before refactoring

**Actions:**
1. Run existing tests for target code
2. Review test coverage:
   - Is coverage sufficient for safe refactoring?
   - Are edge cases tested?
   - Are integration points tested?

3. If coverage is insufficient:
   - Identify critical paths to test
   - Write additional tests for current behavior
   - Run new tests to confirm they pass

4. Document current behavior baseline:
   - What are the expected outputs?
   - What are the success criteria?

**Output:** 
- Test coverage report for target code
- New tests added (if needed)
- All tests passing before refactoring begins
- Behavior baseline documented

**User Confirmation Required:** Are we confident the tests cover the critical behavior? Ready to proceed with refactoring?

---

### CHECKPOINT 4: Incremental Refactoring - Phase 1
**Objective:** Apply first set of refactorings, typically structural changes

**Actions:**
1. Start with highest-priority, lowest-risk refactorings:
   - Extract methods from long functions
   - Rename unclear variables/methods
   - Remove obvious duplication
   - Extract constants for magic numbers

2. Make ONE refactoring change at a time:
   - Apply the change
   - Run tests immediately
   - Verify all tests pass
   - Commit if using Git Flow

3. Keep changes small and focused:
   - Each refactoring should be independently verifiable
   - Avoid mixing multiple refactoring types in one step

4. Maintain functionality:
   - No behavior changes, only structure changes
   - Output must remain identical

**Output:** 
- First round of refactoring applied
- All tests passing
- Code more readable with improved naming/structure

**User Confirmation Required:** Verify changes work as expected. Any issues? Ready for next phase?

---

### CHECKPOINT 5: Incremental Refactoring - Phase 2
**Objective:** Apply deeper refactorings involving class/module restructuring

**Actions:**
1. Apply more substantial refactorings:
   - Extract classes from god classes
   - Move methods/fields to appropriate classes
   - Introduce interfaces/abstractions
   - Break tight coupling
   - Create domain objects to replace primitives

2. Continue one-refactoring-at-a-time approach:
   - Apply change
   - Run tests
   - Verify
   - Commit

3. Update tests as needed:
   - Adjust test structure for new classes
   - Maintain same behavior verification
   - Add tests for new abstractions if helpful

4. Review emerging patterns:
   - Are new patterns reusable?
   - Is architecture improving?
   - Are responsibilities clearer?

**Output:** 
- Major structural improvements applied
- Classes have clearer responsibilities
- Better separation of concerns
- All tests passing

**User Confirmation Required:** Does the new structure feel clearer? Are responsibilities well-separated? Any adjustments needed?

---

### CHECKPOINT 6: SOLID Principle Compliance Review
**Objective:** Verify refactored code adheres to SOLID principles

**Actions:**
1. Review each principle:
   - **Single Responsibility**: Each class has one clear reason to change
   - **Open/Closed**: Classes open for extension, closed for modification
   - **Liskov Substitution**: Subtypes can replace parent types safely
   - **Interface Segregation**: Interfaces are focused and minimal
   - **Dependency Inversion**: Depend on abstractions, not concretions

2. Check for remaining violations:
   - Are there still god classes?
   - Are dependencies properly inverted?
   - Are interfaces cohesive?

3. Apply final refinements if needed

4. Verify with tests one more time

**Output:** 
- SOLID compliance assessment
- Final refinements applied if needed
- All tests passing
- Code structure aligned with principles

**User Confirmation Required:** Does the code structure feel solid and maintainable? Any remaining concerns?

---

### CHECKPOINT 7: Documentation & Pattern Capture
**Objective:** Document refactoring decisions and patterns for future reference

**Actions:**
1. Document what was refactored and why:
   - Original problems
   - Refactoring techniques applied
   - Design decisions made
   - Patterns that emerged

2. Update code documentation:
   - Class/method comments if helpful
   - README updates if architecture changed
   - Diagram updates if applicable

3. Capture reusable patterns:
   - What patterns worked well?
   - What can be applied elsewhere?
   - Any anti-patterns to avoid?

4. Note technical debt addressed:
   - Update issue tracker
   - Close related technical debt issues
   - Note remaining tech debt if any

5. Create refactoring report:
   - Before/after metrics (file lengths, method lengths, etc.)
   - Test coverage improvement
   - Complexity reduction

**Output:** 
- Refactoring documentation
- Updated code comments where helpful
- Pattern capture for future use
- Technical debt tracking updated
- Refactoring summary report

**User Confirmation Required:** Is the refactoring well-documented? Ready to merge/close?

---

## Integration with Other Skills

**Works well with:**
- **Testing Implementation Skill** - Ensure test coverage before/after refactoring, write tests for refactored components
- **Code Review Skill** - Use for systematic review of refactored code before merging
- **Issue Roadmap Skill** - Plan refactoring work as part of issue breakdown
- **Sprint Planning Skill** - Schedule refactoring work proactively to prevent technical debt
- **UX Design Skill** - Refactor before implementing new UX to provide clean foundation
- **Database Migration Skill** - Often paired when database changes require service layer refactoring

**Workflow Position:**
```
Issue Roadmap → Refactoring (if needed) → UX Design → Implementation → Testing
```

**Common Sequences:**
1. **Before feature work**: Refactoring → UX Design → UI Component Implementation
2. **After prototyping**: Implementation → Refactoring → Testing Implementation
3. **Technical debt sprint**: Issue Roadmap → Refactoring → Code Review

**Timing:**
- Use periodically to prevent technical debt accumulation
- Use before major feature additions (clean foundation)
- Use when code smells accumulate (files >300 lines, duplication)
- Use after rapid prototyping (consolidation phase)
- Use when dialog/service patterns emerge across multiple components

## Key Principles

1. **Incremental changes** - One refactoring at a time, verify with tests
2. **Behavior preservation** - Never change functionality during refactoring
3. **Test-first verification** - Tests must pass before and after each change
4. **SOLID adherence** - Guide refactoring with SOLID principles
5. **User checkpoints** - Verify at each phase before proceeding
6. **Documentation** - Capture decisions and patterns for future reference
7. **No premature optimization** - Focus on readability and maintainability, not performance

## Common Refactoring Patterns

### Extract Method
```dart
// Before: Long method with multiple responsibilities
void processOrder(Order order) {
  // 50 lines of validation
  // 30 lines of calculation
  // 20 lines of persistence
}

// After: Clear, focused methods
void processOrder(Order order) {
  validateOrder(order);
  final total = calculateOrderTotal(order);
  saveOrder(order, total);
}
```

### Extract Class
```dart
// Before: God class with too many responsibilities
class UserManager {
  void authenticate() { }
  void updateProfile() { }
  void sendEmail() { }
  void generateReport() { }
}

// After: Separate concerns
class AuthenticationService { void authenticate() { } }
class ProfileService { void updateProfile() { } }
class EmailService { void sendEmail() { } }
class ReportGenerator { void generateReport() { } }
```

### Introduce Domain Object
```dart
// Before: Primitive obsession
double calculatePrice(double price, double tax, String currency) { }

// After: Domain objects
class Money {
  final double amount;
  final String currency;
  Money(this.amount, this.currency);
}

Money calculatePrice(Money price, double taxRate) { }
```

### Extract Interface
```dart
// Before: Tight coupling to concrete implementation
class OrderProcessor {
  final MySQLDatabase database;
  OrderProcessor(this.database);
}

// After: Dependency on abstraction
abstract class Database {
  Future<void> save(Map<String, dynamic> data);
}

class OrderProcessor {
  final Database database;
  OrderProcessor(this.database);
}
```

## Code Smell Reference

### Critical (Refactor Immediately)
- Files >500 lines
- Methods >100 lines
- Classes with >10 public methods
- Cyclomatic complexity >15
- Deeply nested code (>5 levels)

### High Priority (Refactor Soon)
- Files >300 lines
- Methods >50 lines
- Obvious code duplication
- God classes with multiple responsibilities
- Large parameter lists (>4 parameters)

### Medium Priority (Refactor When Convenient)
- Files >200 lines
- Methods >30 lines
- Minor duplication
- Unclear naming
- Missing abstractions

## Success Criteria

- Code structure aligned with SOLID principles
- Files under reasonable length (<300 lines typical)
- Methods have single, clear responsibilities (<30 lines typical)
- Clear separation of concerns
- Reduced code duplication
- Improved readability and maintainability
- All tests passing
- Test coverage maintained or improved
- Refactoring decisions documented
- User confirms improved code quality

## Common Pitfalls to Avoid

- Changing behavior while refactoring (keep separate)
- Making too many changes at once
- Refactoring without test coverage
- Over-engineering (keep it simple)
- Neglecting to run tests after each change
- Not committing incrementally
- Mixing refactoring with feature work
- Refactoring for perfection (diminishing returns)

## Metrics to Track

**Before/After:**
- Average file length
- Average method length
- Number of classes with >5 responsibilities
- Code duplication percentage
- Test coverage percentage
- Cyclomatic complexity scores
- Number of SOLID violations

## When NOT to Refactor

- Code is working fine and rarely changes
- Code will be deleted soon
- Under tight deadline (schedule it for later)
- Without adequate test coverage (write tests first)
- Just for the sake of it (refactor with purpose)