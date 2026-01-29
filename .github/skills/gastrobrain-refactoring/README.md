# Gastrobrain Refactoring Skill

## Overview

The Gastrobrain Refactoring Skill is a systematic guide for improving code quality through structured, checkpoint-driven refactoring. It helps maintain clean, maintainable code by identifying code smells, planning refactoring strategies, and executing changes incrementally while ensuring all tests remain passing.

This skill acts as a dedicated code quality specialist, focusing on readability, maintainability, and adherence to SOLID principles without changing functionality.

## When to Use This Skill

### Trigger Scenarios

Invoke this skill when you encounter:

- **Long files** - Files exceeding 300-400 lines (critical at >500 lines)
- **God classes** - Classes with too many responsibilities
- **Code duplication** - Repeated logic across multiple files
- **Complex methods** - Methods that are hard to understand (>50 lines)
- **Poor separation** - Business logic mixed with UI code
- **Before major features** - Clean foundation before adding functionality
- **After prototyping** - Consolidation after rapid development

### Common Trigger Phrases

- "Refactor [file/class/screen]"
- "This code needs refactoring"
- "Clean up [component]"
- "Extract service from [screen]"
- "This file is too long"
- "Break up [god class]"
- "Consolidate [duplicate code]"

## How It Works

### 7-Checkpoint Process

The skill guides you through seven systematic checkpoints with user confirmation at each stage:

1. **Code Analysis & Smell Detection** - Identify specific problems and SOLID violations
2. **Refactoring Strategy** - Plan approach with specific techniques
3. **Test Verification Setup** - Ensure tests exist and pass before changes
4. **Incremental Refactoring - Phase 1** - Structural improvements (naming, extraction)
5. **Incremental Refactoring - Phase 2** - Deeper changes (classes, modules)
6. **SOLID Principle Compliance Review** - Verify adherence to best practices
7. **Documentation & Pattern Capture** - Document decisions and patterns

Each checkpoint requires user confirmation before proceeding, ensuring alignment and control throughout the refactoring process.

### Key Principles

- **Incremental changes** - One refactoring at a time, verified with tests
- **Behavior preservation** - Never change functionality during refactoring
- **Test-first verification** - Tests must pass before and after each change
- **SOLID adherence** - Guide refactoring with SOLID principles
- **User checkpoints** - Verify at each phase before proceeding

## Quick Start

### Example Invocation

```
User: "Refactor WeeklyPlanScreen - it's grown to 547 lines"

Skill: Initiates CHECKPOINT 1 - Code Analysis
- Identifies god class pattern
- Finds long methods (_buildWeekView: 87 lines)
- Detects tight coupling to DatabaseHelper
- Notes SOLID violations (Single Responsibility, Dependency Inversion)
- Requests user confirmation before proceeding

[Continues through 7 checkpoints with user approval at each stage]
```

### Gastrobrain-Specific Usage

For the Gastrobrain project, this skill understands:

- Flutter/Dart patterns and service layer architecture
- `ServiceProvider` dependency injection patterns
- `DatabaseHelper` vs service layer separation
- Dialog testing with `MockDatabaseHelper` and `DialogTestHelpers`
- 600+ test suite requirements
- Localization (ARB file) considerations

## Skill Components

### SKILL.md
Main skill file containing:
- 7-checkpoint workflow with detailed actions
- Code smell reference (critical, high, medium priority)
- Common refactoring patterns (Extract Method, Extract Class, etc.)
- SOLID principles guide
- Success criteria and metrics
- Common pitfalls to avoid

### templates/
Ready-to-use templates for refactoring work:
- **refactoring_plan_template.md** - Planning document (used after Checkpoint 2)
- **refactoring_report_template.md** - Summary document (used after Checkpoint 7)

### examples/
Complete refactoring walkthroughs showing all 7 checkpoints:
- **example_1_long_screen_refactor.md** - Refactoring a 547-line screen
- **example_2_service_extraction.md** - Extracting services from dialogs
- **example_3_duplicate_elimination.md** - Eliminating ingredient parsing duplication

## Integration with Other Skills

This skill works seamlessly with:

| Skill | Integration Point |
|-------|-------------------|
| **Testing Implementation** | Ensure test coverage before/after refactoring |
| **Code Review** | Systematic review of refactored code |
| **Issue Roadmap** | Plan refactoring work as part of issue breakdown |
| **Sprint Planning** | Schedule refactoring to prevent technical debt |
| **UX Design** | Refactor before implementing new UX |
| **Database Migration** | Often paired when DB changes require refactoring |

### Common Workflow Sequences

1. **Before feature work**: Refactoring → UX Design → Implementation
2. **After prototyping**: Implementation → Refactoring → Testing
3. **Technical debt sprint**: Issue Roadmap → Refactoring → Code Review

## Success Metrics

Refactoring is successful when:

- Code structure aligns with SOLID principles
- Files under reasonable length (<300 lines typical)
- Methods have single, clear responsibilities (<30 lines typical)
- Clear separation of concerns (UI vs business logic)
- Reduced code duplication
- All tests passing (600+ test suite)
- Test coverage maintained or improved
- User confirms improved code quality

### Measurable Improvements

Track these before/after metrics:
- Average file length
- Average method length
- Number of classes with multiple responsibilities
- Code duplication percentage
- Test coverage percentage
- Cyclomatic complexity scores
- Number of SOLID violations

## Gastrobrain Context

### Project-Specific Patterns

**Common refactoring scenarios in Gastrobrain:**

1. **Screen decomposition** - 500+ line screens → widgets + services
2. **Service extraction** - DatabaseHelper calls → service layer
3. **Dialog consolidation** - Direct DB access → service injection
4. **Duplicate elimination** - Shared logic → utility classes/services

### Testing Requirements

- All 600+ tests must pass throughout refactoring
- Use `flutter analyze` for validation
- `flutter run` not available in WSL (testing happens via CI/CD)
- Maintain MockDatabaseHelper and DialogTestHelpers patterns

### Historical Examples

Reference successful refactorings:
- **Issue #234-237** - Dialog database access → service layer
- Service extraction from god classes
- Screen decomposition patterns

## Related Documentation

- [Issue Roadmap Skill](../gastrobrain-issue-roadmap/) - Planning refactoring work
- [Testing Implementation Skill](../gastrobrain-testing-implementation/) - Test coverage
- [Code Review Skill](../gastrobrain-code-review/) - Review refactored code
- [Gastrobrain Architecture](../../../docs/architecture/Gastrobrain-Codebase-Overview.md) - Codebase patterns

## When NOT to Refactor

Avoid refactoring when:
- Code is working fine and rarely changes
- Code will be deleted soon
- Under tight deadline (schedule it for later)
- Without adequate test coverage (write tests first)
- Just for the sake of it (refactor with purpose)

## Common Pitfalls

- Changing behavior while refactoring (keep separate!)
- Making too many changes at once
- Refactoring without test coverage
- Over-engineering (keep it simple)
- Not running tests after each change
- Mixing refactoring with feature work
- Refactoring for perfection (diminishing returns)

---

**Version**: 1.0.0
**Last Updated**: 2026-01-25
**Maintainer**: Gastrobrain Development Team
