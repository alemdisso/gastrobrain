# Gastrobrain Documentation

**Last Updated**: 2026-02-08

This directory contains comprehensive documentation for the Gastrobrain project, organized by category.

## Quick Links

- **New to the project?** Start with [Gastrobrain Codebase Overview](architecture/Gastrobrain-Codebase-Overview.md)
- **Working on an issue?** Create roadmap in [issues/roadmaps/](issues/roadmaps/) and analysis in [issues/analysis/](issues/analysis/)
- **Setting up tests?** See [Dialog Testing Guide](testing/DIALOG_TESTING_GUIDE.md) and [Edge Case Testing Guide](testing/EDGE_CASE_TESTING_GUIDE.md)
- **Writing edge case tests?** Check [Edge Case Catalog](testing/EDGE_CASE_CATALOG.md)
- **Following workflows?** Check [Issue Workflow](workflows/ISSUE_WORKFLOW.md)
- **Adding localization?** Read [L10N Protocol](workflows/L10N_PROTOCOL.md)
- **Planning milestone?** See [planning/milestones/](planning/milestones/)
- **Designing UI/UX?** Check [design/ux/](design/ux/)

---

## Documentation Structure

```
docs/
├── README.md (this file)
│
├── issues/               # Issue-Level Implementation Docs
│   ├── analysis/         # Phase 1: Understanding existing code
│   └── roadmaps/         # Phase-based implementation plans
│
├── planning/             # Project-Level Planning
│   ├── milestones/       # Milestone roadmaps (0.1.x)
│   ├── sprints/          # Sprint planning docs
│   └── features/         # High-level feature specifications
│
├── design/               # Visual & UX Design
│   ├── ux/               # Feature-specific UX designs
│   └── *.md              # Design tokens, theme, visual identity
│
├── architecture/         # System Architecture & Technical Decisions
├── testing/              # Testing Guides & Resources
├── workflows/            # Development Workflows & Processes
└── archive/              # Historical & Completed Documents
```

---

## Issues (Implementation Documentation)

**Purpose**: Issue-level implementation documentation following the 4-phase roadmap approach.

### Analysis Documents

Analysis documents capture understanding of existing code before implementation.

| Document | Issue | Status |
|----------|-------|--------|
| [issue-262-navigation-analysis.md](issues/analysis/issue-262-navigation-analysis.md) | #262 - Standardize Navigation Styles | ✅ Complete |

**Naming convention**: `issue-{number}-analysis.md`

### Roadmaps

Roadmaps provide phase-based implementation plans with checkbox lists for tracking.

| Document | Issue | Status |
|----------|-------|--------|
| [issue-262-standardize-navigation-styles.md](issues/roadmaps/issue-262-standardize-navigation-styles.md) | #262 - Standardize Navigation Styles | ✅ Complete |

**Naming convention**: `issue-{number}-roadmap.md` or `issue-{number}-phase{X}-roadmap.md` for phased work

**When to create**:
- Create analysis doc when starting Phase 1 (understanding existing code)
- Create roadmap doc when planning implementation approach
- Both are **issue-level** documentation (not project-level)

---

## Planning (Project-Level Documentation)

**Purpose**: Project-level planning documents for milestones, sprints, and high-level feature specifications.

### Milestone Roadmaps

Strategic roadmaps for complete milestones (version releases).

| Document | Milestone | Status |
|----------|-----------|--------|
| [roadmap-0.1.4.md](planning/milestones/roadmap-0.1.4.md) | 0.1.4 - Testing Infrastructure | ✅ Complete |
| [roadmap-0.1.5.md](planning/milestones/roadmap-0.1.5.md) | 0.1.5 - Meal Recording Consolidation | ✅ Complete |
| [roadmap-0.1.6.md](planning/milestones/roadmap-0.1.6.md) | 0.1.6 - Recipe Management Polish | ✅ Complete |

**Naming convention**: `roadmap-{version}.md`

### Sprint Planning

Sprint-level planning documents with velocity tracking and issue sequencing.

| Document | Sprint | Status |
|----------|--------|--------|
| [sprint-planning-0.1.2-0.1.3.md](planning/sprints/sprint-planning-0.1.2-0.1.3.md) | Milestones 0.1.2-0.1.3 | ✅ Complete |

**Naming convention**: `sprint-planning-{version-or-dates}.md`

### Feature Specifications

High-level feature specifications that may span multiple issues.

| Document | Feature | Status |
|----------|---------|--------|
| [feature-spec-shopping-list.md](planning/features/feature-spec-shopping-list.md) | Shopping List System | ✅ Complete |

**Naming convention**: `feature-spec-{name}.md`

---

## Design (Visual & UX Design)

**Purpose**: Visual design system and feature-specific UX designs.

### Visual Design System

| Document | Purpose | Status |
|----------|---------|--------|
| [design-tokens.md](design/design-tokens.md) | Core design tokens (colors, spacing, typography) | ✅ Current |
| [theme_usage.md](design/theme_usage.md) | Flutter theme implementation patterns | ✅ Current |
| [visual_identity.md](design/visual_identity.md) | Gastrobrain visual identity ("Cultured & Flavorful") | ✅ Current |

### Feature UX Designs

UX designs and user flow documentation for specific features.

| Document | Issue | Status |
|----------|-------|--------|
| [meal-plan-summary-design.md](design/ux/meal-plan-summary-design.md) | Meal Plan Summary Feature | ✅ Complete |

**Naming convention**: `issue-{number}-ux-design.md` or `{feature-name}-design.md`

**When to create**:
- Create UX design doc when planning user flows, wireframes, or interaction patterns
- Should be created **before** implementation roadmap
- Focus on "what" and "why", not "how" (implementation is in roadmaps)

---

## Architecture & Design

| Document | Purpose | Status |
|----------|---------|--------|
| [Gastrobrain-Codebase-Overview.md](architecture/Gastrobrain-Codebase-Overview.md) | Comprehensive architecture overview, data models, services, and patterns | ✅ Current (2026-02-08) |
| [RECOMMENDATION_ENGINE.md](architecture/RECOMMENDATION_ENGINE.md) | Recommendation service architecture and scoring factors | ✅ Current |
| [Dependency-Injection-Strategy.md](architecture/Dependency-Injection-Strategy.md) | ServiceProvider pattern and DI approach | ✅ Current |

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
| [RELEASE_WORKFLOW.md](workflows/RELEASE_WORKFLOW.md) | Release process, versioning, and automated pipeline | ✅ Current |

---

## Archive

Historical planning documents and completed project tracking:

| Document | Purpose | Status |
|----------|---------|--------|
| [Gastrobrain-Roadmap-Status.md](archive/Gastrobrain-Roadmap-Status.md) | Overall project roadmap and milestone tracking | 📅 Historical (2025-12-19) |
| [Sprint-Estimation-Diary.md](archive/Sprint-Estimation-Diary.md) | Sprint estimation tracking and learnings | 📅 Historical (2025-12-19) |

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

## Naming Conventions

### Issue-Level Documentation

**Analysis**: `docs/issues/analysis/issue-{number}-{short-name}.md`
- Example: `issue-266-shopping-list-preview-analysis.md`

**Roadmap**: `docs/issues/roadmaps/issue-{number}-roadmap.md`
- Example: `issue-266-roadmap.md`
- For phased work: `issue-{number}-phase{X}-roadmap.md`

**UX Design**: `docs/design/ux/issue-{number}-ux-design.md`
- Example: `issue-258-ux-design.md`

### Project-Level Documentation

**Milestone Roadmap**: `docs/planning/milestones/roadmap-{version}.md`
- Example: `roadmap-0.1.7.md`

**Sprint Planning**: `docs/planning/sprints/sprint-planning-{version-or-dates}.md`
- Example: `sprint-planning-0.1.7a-0.1.7b.md`

**Feature Spec**: `docs/planning/features/feature-spec-{name}.md`
- Example: `feature-spec-recommendation-engine.md`

**Visual Design**: `docs/design/{topic}.md`
- Example: `design-tokens.md`, `visual_identity.md`

---

## Document Decision Tree

**"Where should I put this documentation?"**

```
Is it about a specific GitHub issue?
├─ YES → docs/issues/
│   ├─ Analysis of existing code? → docs/issues/analysis/
│   ├─ Implementation roadmap? → docs/issues/roadmaps/
│   └─ UX design/wireframes? → docs/design/ux/
│
└─ NO → Is it project-level?
    ├─ Milestone planning? → docs/planning/milestones/
    ├─ Sprint planning? → docs/planning/sprints/
    ├─ Feature specification? → docs/planning/features/
    ├─ Visual design system? → docs/design/
    ├─ System architecture? → docs/architecture/
    ├─ Testing guide? → docs/testing/
    ├─ Development workflow? → docs/workflows/
    └─ Historical/completed? → docs/archive/
```

---

## Contributing to Documentation

When adding or updating documentation:

1. **Use the decision tree above** to determine correct location
2. **Follow naming conventions** strictly for consistency
3. **Include "Last Updated" date** at the top of the file
4. **Update this README** if adding new documents
5. **Cross-reference** related documents with links
6. **Use clear headers** for easy navigation
7. **Include examples** where helpful
8. **Keep format consistent** with existing docs

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
