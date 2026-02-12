# Gastrobrain Sprint Planner Skill

A specialized Claude Code skill for data-driven sprint planning and structured sprint retrospectives tailored to the Gastrobrain Flutter project.

## Overview

This skill covers the full sprint lifecycle: **plan -> execute -> review -> plan next**. It helps plan development sprints by analyzing GitHub Project #3 issues, applying historical velocity patterns from the Sprint Estimation Diary, and generating realistic, well-sequenced sprint plans. After sprint completion, it conducts structured retrospectives with developer interviews, estimation accuracy analysis, and diary entry generation.

## Files

- **SKILL.md**: Main skill definition with YAML frontmatter, complete planning framework, and retrospective process
- **templates/sprint_plan_template.md**: Structured output template for generated sprint plans
- **templates/sprint_review_template.md**: Structured output template for sprint diary entries
- **README.md**: This file

## Key Features

### Sprint Planning
- **Velocity-Based Capacity Planning**: Uses historical data (Sprints 0.1.2-0.1.7b) to predict realistic capacity
- **Type-Specific Multipliers**: Adjusts estimates based on work type (UI, testing, bugs, features, refactoring, design system)
- **Overhead Accounting**: Factors in mobile tooling (25-35%), localization (10-15%), and testing (varies by type)
- **Optimal Sequencing**: Day-by-day breakdown following proven patterns (quick wins first, risky work mid-sprint)
- **Risk Assessment**: Identifies and mitigates high/medium/low risks with specific strategies
- **Testing Strategy**: Ensures comprehensive test coverage (unit, widget, integration, E2E, edge cases)
- **Flutter-Specific**: Accounts for Flutter development patterns, WSL limitations, and bilingual requirements

### Sprint Retrospective
- **5-Checkpoint Process**: Data Gathering -> Developer Interview -> Estimation Analysis -> Pattern Recognition -> Lessons & Documentation
- **Developer Interview**: Dedicated checkpoint to gather context commits don't capture (hidden work, efficiency drivers, blockers)
- **Balanced Assessment**: Distinguishes genuine efficiency from overestimation; frames emergent work contextually
- **Diary Entry Generation**: Produces complete entries matching the established Sprint Estimation Diary format
- **Calibration Updates**: Proposes updates to velocity multipliers and type-based calibration factors

## When to Use

Invoke this skill when:

### Planning
- Planning a new sprint or release cycle
- Evaluating sprint capacity and feasibility
- Sequencing issues for optimal implementation flow
- Assessing risks in upcoming work
- Needing day-by-day sprint breakdown

### Retrospective
- Completed a sprint and need to review it
- Generating a Sprint Estimation Diary entry
- Analyzing estimation accuracy for a completed milestone
- Updating velocity calibration data

## How to Use

### With Claude Code

**Planning:**
```
User: "Use the gastrobrain-sprint-planner skill to plan Sprint 0.1.8"
User: "Help me plan the next sprint with issues from Project #3"
```

**Retrospective:**
```
User: "Sprint review for 0.1.8"
User: "Retrospective for last sprint"
User: "Generate diary entry for sprint 0.1.8"
```

### Planning Input Required

Provide the skill with:
1. Sprint number and theme
2. List of GitHub issues (from Project #3)
3. Milestone context
4. Available time (typically 5 working days)

The skill can fetch issues directly using `gh` CLI or work from a provided list.

### Retrospective Input Required

Provide the skill with:
1. Sprint number/milestone that was completed
2. Sprint date range (start and end dates)
3. Your availability for the developer interview (~10 min)

The skill will gather commit data, milestone info, and guide through 5 checkpoints.

### Planning Output

Generates a comprehensive sprint plan using `templates/sprint_plan_template.md` with:
- Sprint goal and key deliverables
- Capacity analysis (raw points -> adjusted points)
- Issues grouped by theme
- Day-by-day implementation breakdown
- Risk assessment with mitigations
- Testing strategy (unit, widget, integration, E2E, edge cases)
- Database migration plan (if applicable)
- Localization impact analysis
- Success criteria checklist

### Retrospective Output

Generates a complete diary entry using `templates/sprint_review_template.md` with:
- Estimation vs Actual table with per-issue ratios
- Accuracy by Type analysis
- Variance Analysis (overruns, underruns, unplanned work)
- Working Pattern Observations (commit timeline)
- Lessons Learned (5-8 balanced, actionable lessons)
- Recommendations table for future sprints
- Updates to cumulative metrics and calibration factors

## Core Concepts

### Story Points

Fibonacci-like scale: 1, 2, 3, 5, 8, 13
- **1**: <1 hour, trivial
- **2**: 2-3 hours, simple
- **3**: 4-6 hours, standard feature
- **5**: ~1 day, complex feature
- **8**: ~2 days, major feature
- **13**: 3+ days, epic-level

### Velocity Data

**Normal range**: 1.1 - 3.0 points/day
- **Conservative**: 2.0 points/day
- **Median**: 2.5 points/day
- **Optimistic**: 2.8 points/day

**Outliers:** Sprint 0.1.4 (6.0), 0.1.7a (67.7), 0.1.7b (6.43) — not baselines for general planning.

### Sprint Capacity

**For 5-day sprint:**
- **Conservative**: 10-12 points (UI work, new features, discovery)
- **Normal**: 12-15 points (established patterns, backend work)
- **Aggressive**: 15-18 points (only for well-prepared, pattern extension work)

### Type Multipliers

- **Known bugs**: 0.1-0.2x (quick fixes)
- **UI polish**: 3.0-4.0x (iteration overhead)
- **Extend test patterns**: 0.2-0.4x (fast)
- **New test infrastructure**: 1.0-1.5x (slower)
- **Well-prepared refactor**: 0.2-0.3x (clear plan)
- **Design foundation**: 0.1-0.2x (linked tasks as single unit)
- **Screen polish (first)**: 0.4-0.5x (includes pattern creation)
- **Screen polish (subsequent)**: 0.1-0.2x (applying established patterns)
- **Component standardization**: 0.1-0.2x (mechanical with tokens)

### Overhead

- **Mobile tooling**: +25-35% (UI-heavy sprints)
- **Localization**: +10-15% (new UI screens)
- **Testing**: +20-100% (varies by test type)

## Sequencing Strategy

**Optimal pattern:**
1. **Day 1-2**: Quick wins + prerequisites
2. **Day 2-3**: Main features (when fresh)
3. **Day 4**: Integration + testing
4. **Day 5**: Polish + flex work

**Key principles:**
- Dependencies first (DB migrations early, UI after backend)
- Batch similar work (all testing together, all UI together)
- Risk management (risky work mid-sprint with recovery time)
- Flex at end (open-ended work that can be cut)

## Risk Levels

- **High**: Unclear requirements, new patterns, external dependencies -> 50-100% buffer
- **Medium**: Some prior work, UI iteration, integration -> 25-50% buffer
- **Low**: Established patterns, clear requirements, backend only -> 10-15% buffer

## Testing Requirements

All sprints must include:
- **Unit tests**: Business logic, models, services (>80% coverage)
- **Widget tests**: UI components, screens (>70% coverage)
- **Integration tests**: Multi-component workflows (key paths)
- **E2E tests**: Critical user journeys (happy path + error path)
- **Edge case tests**: Issue #39 standards (empty states, boundaries, errors)
- **Regression tests**: For all bug fixes

## Historical Patterns

### Sprint 0.1.2 (0.90x ratio)
- Mixed work, DB changes, discovery overhead
- Lesson: Account for hidden complexity

### Sprint 0.1.3 (0.38x ratio)
- Pattern reuse accelerated delivery 2.5-5x
- Lesson: Distinguish "extend patterns" from "new patterns"

### Sprint 0.1.4 (0.17x ratio)
- **OUTLIER**: Well-prepared, prerequisites complete
- Lesson: Don't use as baseline, atypical conditions

### Sprint 0.1.5 (1.98x ratio)
- Hidden mobile tooling overhead, UI iteration
- Lesson: Add 25-35% buffer for UI-heavy sprints

### Sprint 0.1.6 (0.33x ratio)
- Well-specified features, clear MVP scope
- Lesson: Detailed specs enable 3-4x faster execution

### Sprint 0.1.7a (0.01x ratio)
- **OUTLIER**: Design foundation, linked tasks completed as single unit
- Lesson: Estimate linked design tasks as single 3-5 point unit

### Sprint 0.1.7b (0.16x ratio)
- **OUTLIER**: Design system application, compound pattern reuse
- Lesson: First-screen polish creates patterns; subsequent screens harvest them (8x difference)

## References

- Sprint Estimation Diary: `docs/archive/Sprint-Estimation-Diary.md`
- Issue Workflow: `docs/workflows/ISSUE_WORKFLOW.md`
- Edge Case Testing: `docs/testing/EDGE_CASE_TESTING_GUIDE.md`
- Localization Protocol: `docs/workflows/L10N_PROTOCOL.md`

## Version

**Current Version**: 2.0.0
**Last Updated**: 2026-02-08

## Continuous Improvement

After each sprint:
1. Run the Sprint Retrospective Process (5 checkpoints) to generate a diary entry
2. Update Sprint Estimation Diary with actual vs estimated
3. Calculate effort ratio and update cumulative metrics
4. Refine multipliers based on balanced assessment
5. Update this skill with new insights

**This skill evolves** as more sprint data becomes available. The retrospective process closes the loop: **plan -> execute -> review -> plan next**.
