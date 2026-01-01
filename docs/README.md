# Gastrobrain Documentation

**Last Updated**: 2025-12-30

This directory contains comprehensive documentation for the Gastrobrain project, organized by category.

## Quick Links

- **New to the project?** Start with [Gastrobrain Codebase Overview](architecture/Gastrobrain-Codebase-Overview.md)
- **Setting up tests?** See [Dialog Testing Guide](testing/DIALOG_TESTING_GUIDE.md) and [Edge Case Testing Guide](testing/EDGE_CASE_TESTING_GUIDE.md)
- **Writing edge case tests?** Check [Edge Case Catalog](testing/EDGE_CASE_CATALOG.md)
- **Working on an issue?** Check [Issue Workflow](workflows/ISSUE_WORKFLOW.md)
- **Adding localization?** Read [L10N Protocol](workflows/L10N_PROTOCOL.md)

---

## Documentation Structure

```
docs/
├── README.md (this file)
├── architecture/     # Architecture & Design Documentation
├── testing/          # Testing Guides & Resources
├── workflows/        # Development Workflows & Processes
└── archive/          # Historical Planning Documents
```

---

## Architecture & Design

| Document | Purpose | Status |
|----------|---------|--------|
| [Gastrobrain-Codebase-Overview.md](architecture/Gastrobrain-Codebase-Overview.md) | Comprehensive architecture overview, data models, services, and patterns | ✅ Current (2025-12-30) |
| [RECOMMENDATION_ENGINE.md](architecture/RECOMMENDATION_ENGINE.md) | Recommendation service architecture and scoring factors | ✅ Current |
| [Dependency-Injection-Strategy.md](architecture/Dependency-Injection-Strategy.md) | ServiceProvider pattern and DI approach | ⚠️ May need update |

---

## Testing Documentation

### Testing Guides

| Document | Purpose | Status |
|----------|---------|--------|
| [DIALOG_TESTING_GUIDE.md](testing/DIALOG_TESTING_GUIDE.md) | Comprehensive guide for testing dialogs with DialogTestHelper | ✅ Current (2025-12-29) |
| [EDGE_CASE_TESTING_GUIDE.md](testing/EDGE_CASE_TESTING_GUIDE.md) | Comprehensive guide for edge case testing patterns and helpers | ✅ Current (2025-12-30) |
| [EDGE_CASE_CATALOG.md](testing/EDGE_CASE_CATALOG.md) | Catalog of edge cases and EdgeCaseTestHelpers usage | ✅ Current (2025-12-30) |
| [EDGE_CASE_TEST_REVIEW.md](testing/EDGE_CASE_TEST_REVIEW.md) | Comprehensive review of edge case test suite quality | ✅ Current (2025-12-30) |
| [E2E_TESTING.md](testing/E2E_TESTING.md) | End-to-end testing guidelines | ✅ Current |
| [createTestableWidget-pattern.md](testing/createTestableWidget-pattern.md) | Pattern for creating testable widgets | ✅ Current |
| [RecipeProvider-test-setup.md](testing/RecipeProvider-test-setup.md) | Provider testing setup guide | ✅ Current |
| [Revised-Flutter-Integration-Testing-Guidelines.md](testing/Revised-Flutter-Integration-Testing-Guidelines.md) | Integration testing approach and guidelines | ✅ Current |

### Testing Documentation Hierarchy

For testing-related work, follow this hierarchy:

```
1. Testing Guides (start here for implementation)
   ├─ DIALOG_TESTING_GUIDE.md (for dialog tests)
   ├─ EDGE_CASE_TESTING_GUIDE.md (for edge case tests)
   ├─ EDGE_CASE_CATALOG.md (edge case reference & helpers)
   └─ EDGE_CASE_TEST_REVIEW.md (test quality review)

2. Test Files
   ├─ test/widgets/ (dialog tests - 122 tests across 6 dialogs)
   ├─ test/edge_cases/ (458 edge case tests across 27 files)
   ├─ test/regression/ (critical regression tests)
   └─ test/edge_cases/performance/ (performance benchmarks)
```

## Workflows & Processes

| Document | Purpose | Status |
|----------|---------|--------|
| [ISSUE_WORKFLOW.md](workflows/ISSUE_WORKFLOW.md) | GitHub issue management, Git Flow, branching strategy | ✅ Current |
| [L10N_PROTOCOL.md](workflows/L10N_PROTOCOL.md) | Localization workflow for English/Portuguese | ✅ Current |

---

## Archive

Historical planning documents and completed project tracking:

| Document | Purpose | Status |
|----------|---------|--------|
| [Gastrobrain-Roadmap-Status.md](archive/Gastrobrain-Roadmap-Status.md) | Overall project roadmap and milestone tracking | 📅 Historical (2025-12-19) |
| [Sprint-Planning-0.1.2-0.1.3.md](archive/Sprint-Planning-0.1.2-0.1.3.md) | Sprint planning for milestones 0.1.2-0.1.3 | 📅 Historical (2025-12-19) |
| [Sprint-Estimation-Diary.md](archive/Sprint-Estimation-Diary.md) | Sprint estimation tracking and learnings | 📅 Historical (2025-12-19) |
| [meal-editing-refactoring-plan.md](archive/meal-editing-refactoring-plan.md) | Plan for consolidating meal editing screens (Issue #237) | 📅 Future work (2025-12-19) |

---

## Document Status Legend

- ✅ **Current**: Up-to-date and actively maintained
- ⚠️ **May need update**: Potentially outdated, review recommended
- 📅 **Historical**: Preserved for reference, not actively maintained
- 🔄 **In Progress**: Currently being updated

---

## Maintenance Notes

### Regular Updates Needed

- **EDGE_CASE_CATALOG.md**: Add new edge cases as discovered during development
- **EDGE_CASE_TESTING_GUIDE.md**: Update when new testing patterns emerge
- **Gastrobrain-Codebase-Overview.md**: Update when architecture changes
- **RECOMMENDATION_ENGINE.md**: Update when recommendation factors change

### Archive Policy

Documents are moved to archive/ when:
- Planning phase is complete (sprint plans, roadmaps)
- Issue is closed (issue-specific tracking docs)
- Work is deferred to future milestones (refactoring plans)

---

## Contributing to Documentation

When adding or updating documentation:

1. **Include "Last Updated" date** at the top of the file
2. **Update this README** if adding new documents or changing organization
3. **Cross-reference** related documents with links
4. **Use clear headers** for easy navigation
5. **Include examples** where helpful
6. **Keep format consistent** with existing docs
7. **Place in appropriate subfolder**:
   - `architecture/` - Design and architecture docs
   - `testing/` - Testing guides and resources
   - `workflows/` - Development processes
   - `archive/` - Completed planning docs

---

## Questions?

If you can't find what you're looking for:
- Check the main project [README.md](../README.md)
- Review [CLAUDE.md](../CLAUDE.md) for development patterns
- Search across documentation files for keywords

---

**Maintained by**: Development Team
**Primary Audience**: Developers, Contributors, Claude Code
**Repository**: gastrobrain (private)
