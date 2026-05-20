<!-- markdownlint-disable -->
# Gastrobrain Agent Skills - Master Index

## Overview

This document maps the complete Agent Skills ecosystem for Gastrobrain development, showing how skills work together throughout the development workflow and their implementation status.

---

## Skills Ecosystem Architecture

### Tier 1: Planning & Strategy
High-level planning, issue preparation, and strategic alignment

### Tier 2: Implementation & Execution
Phase-by-phase implementation with checkpoints

### Tier 3: Quality & Finalization
Review, validation, and merge

---

## Complete Skill Catalog

All skills live in `.claude/skills/` and are invoked with `/skill-name` in Claude Code.

---

### **Tier 1: Planning & Strategy Skills**

#### Issue Creation Skill ⭐
**Status:** ✅ Implemented
**Location:** `.claude/skills/gastrobrain-issue-creator/`
**Triggers:** "Create an issue for...", "I found a bug...", "Feature request...", user reports problem

**Purpose:**
- Transform informal reports into structured GitHub issues
- Interactive 6-checkpoint process for accuracy
- Support bug reports, feature requests, technical debt
- Estimate story points with reasoning
- Detect and reference related issues
- Generate exact GitHub CLI commands

---

#### Sprint Planning Skill
**Status:** ✅ Implemented
**Location:** `.claude/skills/gastrobrain-sprint-planner/`
**Triggers:** "Help me plan sprint 0.X.Y", "plan next sprint", "sprint retrospective"

**Purpose:**
- Analyze GitHub issues from Project #3 with `limit 500`
- Apply sprint history insights from Sprint Estimation Diary
- Group issues by type and dependencies
- Generate realistic capacity planning (~30 pts/week cruising)
- Risk assessment and sequencing strategy
- Conduct structured sprint retrospectives with developer interviews
- Generate Sprint Estimation Diary entries

---

#### Issue Roadmap Skill
**Status:** ✅ Implemented
**Location:** `.claude/skills/gastrobrain-issue-roadmap/`
**Triggers:** "I want to deal with #XXX", "create roadmap for #XXX", "plan issue #XXX"

**Purpose:**
- Fetch issue details from GitHub
- Generate 4-phase roadmap (Analysis → Implementation → Testing → Documentation)
- Identify files to modify
- Apply Gastrobrain-specific conventions
- Testing requirements by issue type
- Localization and database change checklists

---

#### Issue Analysis Skill
**Status:** ✅ Implemented
**Location:** `.claude/skills/gastrobrain-issue-analysis/`
**Triggers:** "Analyze #XXX", "Phase 1 for #XXX", "understand the scope of #XXX"

**Purpose:**
- Execute Phase 1 (Analysis & Understanding) of issue roadmaps
- 5-checkpoint technical analysis: understand scope → explore codebase → identify risks → design approach → produce analysis document
- Produces structured analysis before implementation begins
- Distinct from Issue Roadmap: roadmap plans the work; analysis understands the code

---

#### Product Strategy Skill ⭐
**Status:** ✅ Implemented
**Location:** `.claude/skills/gastrobrain-product-strategy/`
**Triggers:** "Review the roadmap", "Help me prioritize", "Is my milestone balanced?", "Strategic review of 0.X.Y"

**Purpose:**
- Strategic partner for roadmap planning, priority setting, and project health management
- 'Wide picture' perspective balancing feature development with code quality and technical debt
- Milestone health checks: too much/too little in scope?
- Technical debt vs. feature velocity analysis
- Long-term sustainability assessment

---

#### UX Design Skill ⭐
**Status:** ✅ Implemented
**Location:** `.claude/skills/gastrobrain-ux-design/`
**Triggers:** "Design the UX for #XXX", "Help me redesign [screen]", "What should the user flow be?", "I need wireframes for #XXX"

**Purpose:**
- User experience design specialist
- Analyzes user goals, maps flows, designs information architecture
- Creates wireframes and user journey maps
- Ensures accessibility before implementation begins
- Reinforces 'Cultured & Flavorful' design identity
- Mandatory before UX-heavy issues (e.g., 0.2.13 used this for #370 and #371)

---

### **Tier 2: Implementation Skills**

#### Issue Analysis → Implementation Flow
Use **Issue Analysis** (Tier 1) for Phase 1, then these skills for Phase 2.

---

#### Senior Developer Implementation Skill ⭐
**Status:** ✅ Implemented
**Location:** `.claude/skills/gastrobrain-senior-dev-implementation/`
**Triggers:** "Implement Phase 2 for #XXX", "implement [feature]", "Phase 2 - UI", "Phase 2 - service layer"

**Purpose:**
- Checkpoint-driven Phase 2 implementation
- Covers UI, service layer, and repository patterns
- Reads and applies Gastrobrain conventions (keys, localization, ServiceProvider, error handling)
- Patterns available: `model_pattern.dart`, `service_pattern.dart`, `provider_pattern.dart`, `widget_pattern.dart`
- Replaces the former "UI Component" and "Service/Repository" planned skills

---

#### Testing Implementation Skill ⭐
**Status:** ✅ Implemented
**Location:** `.claude/skills/gastrobrain-testing-implementation/`
**Triggers:** "Implement Phase 3 for #XXX", "add tests for #XXX", "implement testing"

**Purpose:**
- ONE test at a time — prevents pattern error propagation
- Reads roadmap Phase 3 (Testing)
- Generates test plan with count
- Creates tests iteratively with verification
- Learns from each test before the next
- Progress tracking (TEST X/Y)

---

#### Database Migration Skill ⭐
**Status:** ✅ Implemented
**Location:** `.claude/skills/gastrobrain-database-migration/`
**Triggers:** "Create migration for #XXX", "implement database changes", "Phase 2 - database"

**Purpose:**
- Checkpoint-based migration implementation
- Determines migration version number
- Implements schema changes safely with rollback verification
- Updates models and seed data
- Migration tests

---

#### UI Styling & Visual Polish Skill ⭐
**Status:** ✅ Implemented
**Location:** `.claude/skills/gastrobrain-ui-polish/`
**Triggers:** "Polish the UI for...", "Help me style...", "This feels unfinished visually"

**Purpose:**
- Guide systematic visual refinement of Flutter UI
- Creates and applies design tokens (color, typography, spacing, components)
- Maintains visual consistency across features
- Considers bilingual support and responsive layouts
- Documents reusable visual patterns

---

#### Refactoring Skill ⭐
**Status:** ✅ Implemented
**Location:** `.claude/skills/gastrobrain-refactoring/`
**Triggers:** "Refactor according to #XXX", "extract service", "consolidate code", file in refactoring-backlog.md

**Purpose:**
- Systematic code refactoring for readability, maintainability, and SOLID principles
- Checkpoint-driven iterations through analysis → design → extract → verify
- Maintains test coverage throughout refactoring
- Updates all call sites
- Feeds from `.github/refactoring-backlog.md` (Code Quality Watchdog output)

---

#### Localization Update Skill
**Status:** 📋 Not yet a standalone skill
**Coverage:** Handled within **Senior Developer Implementation Skill** (localization checklist built in)

**If creating standalone:** Scan code for new UI strings, generate EN/PT-BR ARB entries following naming conventions, show `AppLocalizations` usage, verify no hardcoded strings remain.

---

### **Tier 3: Quality & Finalization Skills**

#### Code Review Skill ⭐
**Status:** ✅ Implemented
**Location:** `.claude/skills/gastrobrain-code-review/`
**Triggers:** "Review #XXX", "pre-merge check for #XXX", "ready to merge #XXX"

**Purpose:**
- Systematic pre-merge quality verification (7 checkpoints)
- Verifies roadmap completion and acceptance criteria
- Runs `flutter analyze` and test suite
- Localization verification
- Generates merge instructions (solo workflow: no PRs, merge to develop)

---

#### QA Manager Skill ⭐
**Status:** ✅ Implemented
**Location:** `.claude/skills/gastrobrain-qa-manager/`
**Triggers:** "Run the test suite", "investigate failing tests", "test health report", "fix test failures"

**Purpose:**
- Systematize test execution and analyze failures
- Guide structured debugging of test failures
- Maintain test suite health through checkpoint-driven processes
- Track test failure patterns and regression prevention
- Produces health reports and debugging reports

---

#### Documentation Master Skill ⭐
**Status:** ✅ Implemented
**Location:** `.claude/skills/gastrobrain-documentation-master/`
**Triggers:** "Update documentation for #XXX", "audit project documentation", "document the [component]"

**Purpose:**
- Post-implementation documentation updates (4-checkpoint process)
- Full documentation audits (6-checkpoint process)
- Specific documentation tasks — architecture docs, ADRs, feature guides (3-checkpoint process)
- Maintains accuracy of docs against actual codebase state
- Follows Gastrobrain documentation standards and templates

---

#### Issue Closing Workflow
**Status:** No standalone skill — handled by workflow conventions
**How it works:**
- `Closes #XXX` in commit message auto-closes the issue on push to main
- Manual `gh issue close` is not needed
- See `docs/workflows/ISSUE_WORKFLOW.md` for complete closing workflow

---

## Skill Interaction Map

### Complete Issue Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                    ISSUE CREATION (Optional)                 │
│  /gastrobrain-issue-creator                                  │
│  Input: User report, bug discovery, feature idea             │
│  Output: Well-structured GitHub issue with estimate          │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    SPRINT PLANNING                           │
│  /gastrobrain-sprint-planner                                 │
│  Input: Open issues from Project #3                          │
│  Output: Sprint plan with ~30 pts, sequencing               │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    ISSUE PLANNING                            │
│  /gastrobrain-issue-roadmap                                  │
│  Input: Issue #XXX from sprint plan                          │
│  Output: 4-phase roadmap with checklists                     │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│              PHASE 1: ANALYSIS & UNDERSTANDING               │
│  /gastrobrain-issue-analysis                                 │
│  Input: Issue #XXX + roadmap                                 │
│  Output: Technical analysis, risk identification, approach   │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                 PHASE 2: IMPLEMENTATION                      │
│                                                               │
│  [UX Design needed?]                                         │
│  → /gastrobrain-ux-design (wireframes, flows, IA)            │
│                                                               │
│  [Database changes?]                                         │
│  → /gastrobrain-database-migration (6 checkpoints)          │
│                                                               │
│  [UI or service changes?]                                    │
│  → /gastrobrain-senior-dev-implementation                    │
│                                                               │
│  [Visual polish?]                                            │
│  → /gastrobrain-ui-polish                                    │
│                                                               │
│  [Refactoring?]                                              │
│  → /gastrobrain-refactoring                                  │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                   PHASE 3: TESTING                           │
│  /gastrobrain-testing-implementation                         │
│  Process: One test at a time with verification               │
│  Output: Complete test suite for issue                       │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                  PHASE 4: DOCUMENTATION                      │
│  /gastrobrain-documentation-master                           │
│  Input: Completed issue #XXX                                 │
│  Output: Docs updated, code comments added                   │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    PRE-MERGE REVIEW                          │
│  /gastrobrain-code-review                                    │
│  Process: 7-checkpoint systematic review                     │
│  Output: Merge approval + instructions                       │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    ISSUE CLOSING                             │
│  Closes #XXX in commit message → auto-closes on push         │
│  Merge branch to develop; delete feature branch              │
└─────────────────────────────────────────────────────────────┘
```

---

## Skill Quick Reference

| Skill | Trigger | Key Output |
|-------|---------|-----------|
| `/gastrobrain-issue-creator` | New bug / feature / debt | Structured GitHub issue + CLI commands |
| `/gastrobrain-sprint-planner` | Sprint start or retro | Sprint plan / retrospective + diary entry |
| `/gastrobrain-product-strategy` | "Review roadmap" / "prioritize" | Strategic assessment, health report |
| `/gastrobrain-issue-roadmap` | "I want to deal with #XXX" | 4-phase roadmap markdown |
| `/gastrobrain-issue-analysis` | Phase 1 of roadmap | Technical analysis, approach design |
| `/gastrobrain-ux-design` | UX-heavy issues | Wireframes, user flows, IA |
| `/gastrobrain-database-migration` | Schema changes | Safe migration with rollback |
| `/gastrobrain-senior-dev-implementation` | Phase 2 implementation | Code changes (UI, services, repos) |
| `/gastrobrain-ui-polish` | Visual refinement | Consistent styling, design token updates |
| `/gastrobrain-refactoring` | Code health / god classes | Focused, tested refactoring |
| `/gastrobrain-testing-implementation` | Phase 3 testing | Test suite (one test at a time) |
| `/gastrobrain-documentation-master` | Post-implementation / audit | Updated docs, code comments |
| `/gastrobrain-code-review` | Pre-merge | Merge approval + instructions |
| `/gastrobrain-qa-manager` | Test failures / suite health | Debug reports, health reports |

---

## Skill Development Guidelines

### Creating a New Skill

1. **Use it manually first** (3-5 times) — understand the pain points and repetitive patterns
2. **Document the manual workflow** — write down step-by-step process and decision points
3. **Design checkpoint structure** — 4-6 logical, verifiable checkpoints with user confirmation between
4. **Create the prompt** using existing skills as templates
5. **Test with real issues** and refine based on experience

### Maintaining Skills

- **Review every 2-3 sprints:** Are patterns still current?
- **Update after major changes:** New testing patterns? New architecture? Update the skill
- **Deprecate if unused:** Don't maintain skills you don't use

---

## Success Metrics

**Sprint Planning Skill:** Sprints stay within capacity; estimates match history patterns

**Issue Roadmap Skill:** No missed requirements; fewer "forgot to test X" moments

**Testing Implementation Skill:** Tests pass first time more often; no "fix 8 tests with same error" scenarios

**Database Migration Skill:** No data loss; rollback tested every time

**Code Review Skill:** Fewer bugs found after merge; clear merge decisions

**QA Manager Skill:** Faster failure diagnosis; test suite stays green

**Refactoring Skill:** Watchdog backlog items get resolved systematically each sprint

---

## Tips for Success

- **Start with Planning:** Issue roadmap → issue analysis before writing any code
- **UX-heavy issues get a design day first** — no code on day 1 when UX is unmapped
- **One test at a time** — never batch-write tests; write, run, verify, proceed
- **Trust the checkpoints** — they prevent rushing and catch issues early
- **Sprint velocity target:** 30 pts/week cruising; expect ~20 pts/week on discovery-heavy sprints

---

**Document Version:** 2.0
**Last Updated:** May 2026
**Status:** Reflects current skill ecosystem (13 skills implemented)
