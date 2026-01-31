# Gastrobrain Issue Analysis Skill

Technical analyst skill that executes Phase 1 (Analysis & Understanding) of issue roadmaps through systematic 5-checkpoint analysis.

## Quick Start

### Trigger Phrases

```
"Analyze issue #XXX"
"Execute Phase 1 for #XXX"
"Investigate #XXX"
"Do technical analysis for #XXX"
```

### What Happens

1. Loads issue from GitHub
2. Loads roadmap from `docs/planning/`
3. Executes 5-checkpoint analysis
4. Documents findings in roadmap
5. Prepares implementation guidance

## The 5 Checkpoints

| Checkpoint | Focus | Output |
|------------|-------|--------|
| 1. Requirements Deep-Dive | What needs to be done | Acceptance criteria, user story, scope |
| 2. Codebase Exploration | Where to make changes | Affected files, patterns to follow |
| 3. Technical Design | How to implement | Recommended approach with rationale |
| 4. Risk & Edge Cases | What could go wrong | Risks, edge cases, testing needs |
| 5. Implementation Prep | Guidance for Phase 2 | Code examples, step-by-step plan |

## Core Philosophy

**Understand → Explore → Design → Anticipate → Prepare**

Do the hard thinking upfront so implementation goes smoothly.

## Workflow Integration

```
gastrobrain-issue-roadmap
  ↓ Creates roadmap with Phase 1 checklist

gastrobrain-issue-analysis ← THIS SKILL
  ↓ Executes Phase 1 analysis
  ↓ Documents findings in roadmap

gastrobrain-senior-dev-implementation
  ↓ Executes Phase 2 using analysis findings

gastrobrain-testing-implementation
  ↓ Executes Phase 3 testing

gastrobrain-code-review
  ↓ Verifies Phase 4 cleanup
```

## Analysis by Issue Type

### Bug Issues
- Root cause identification
- Affected code paths
- Fix approach with minimal side effects
- Regression test requirements

### Feature Issues
- User story and acceptance criteria
- Architecture fit assessment
- Pattern selection
- Edge case identification

### Refactoring Issues
- Code smell analysis
- Impact assessment
- Behavior preservation strategy
- Safe incremental steps

## Example Flow

```
You: "Analyze issue #199"

Claude: Starting Phase 1 Analysis for #199

        ═══════════════════════════════════════
        CHECKPOINT 1/5: Requirements Deep-Dive

        Issue Type: Feature
        Title: Add meal type selection

        Acceptance Criteria:
        - [ ] Dropdown in meal recording dialog
        - [ ] Types: breakfast, lunch, dinner, snack
        - [ ] Optional field (backward compatible)

        Requirements clear? (y/n)
        ═══════════════════════════════════════

You: y

Claude: ═══════════════════════════════════════
        CHECKPOINT 2/5: Codebase Exploration

        Similar Patterns Found:
        1. MealType enum: lib/models/meal_type.dart
           - Enum with string value mapping
           - getDisplayName() for localization

        Affected Files:
        - lib/models/meal.dart (add field)
        - lib/widgets/meal_recording_dialog.dart (add dropdown)
        - migrations/ (add column)

        Exploration complete? (y/n)
        ═══════════════════════════════════════

[Continues through all 5 checkpoints...]

Claude: ═══════════════════════════════════════
        PHASE 1 ANALYSIS COMPLETE

        Roadmap Updated:
        ✓ docs/planning/0.1.6/ISSUE-199-ROADMAP.md
          └─ Technical design documented
          └─ Code examples added
          └─ Implementation checklist ready

        Ready to start Phase 2? (y/n)
        ═══════════════════════════════════════
```

## Roadmap Updates

After analysis, the roadmap includes:

- **Technical Design Decision** - Selected approach with rationale
- **Patterns to Follow** - References to similar code
- **Code Examples** - Templates for implementation
- **Edge Cases** - Identified scenarios to handle
- **Risk Assessment** - Potential issues and mitigations
- **Implementation Checklist** - Step-by-step guide for Phase 2

## Pattern Library

The skill knows where to find patterns:

| Pattern | Location |
|---------|----------|
| Enum | `lib/models/meal_type.dart` |
| Model | `lib/models/recipe.dart` |
| Service | `lib/core/services/recommendation_cache_service.dart` |
| Widget | `lib/screens/weekly_plan_screen.dart` |
| Provider | `lib/core/providers/recipe_provider.dart` |
| Migration | `lib/core/database/migrations/` |

## Success Criteria

- [ ] Requirements fully understood
- [ ] All affected files identified
- [ ] Patterns to follow documented
- [ ] Technical approach selected with rationale
- [ ] Edge cases and risks identified
- [ ] Implementation guidance prepared
- [ ] Roadmap updated with findings
- [ ] Ready for smooth Phase 2 execution

## When NOT to Use

- Creating roadmaps → use `gastrobrain-issue-roadmap`
- Implementation work → use `gastrobrain-senior-dev-implementation`
- Testing work → use `gastrobrain-testing-implementation`
- Quick codebase questions → use Task tool with Explore agent

---

**Full documentation**: See `SKILL.md` for complete checkpoint details and examples.
