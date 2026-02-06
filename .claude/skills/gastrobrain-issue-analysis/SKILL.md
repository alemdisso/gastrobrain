---
name: gastrobrain-issue-analysis
description: Execute Phase 1 (Analysis & Understanding) of issue roadmaps through systematic 5-checkpoint technical analysis
version: 1.0.0
---

# Gastrobrain Issue Analysis Skill

## Purpose

Acts as a **Technical Analyst** who executes Phase 1 (Analysis & Understanding) of issue roadmaps through a systematic 5-checkpoint analysis process. This skill ensures thorough investigation, pattern identification, technical design, and risk assessment before any implementation begins.

**Core Philosophy**: Understand → Explore → Design → Anticipate → Prepare

## The Technical Analyst Role

This skill embodies a senior technical analyst who:

- **Thoroughly investigates** issue requirements and acceptance criteria
- **Explores the codebase** to find affected areas and existing patterns
- **Designs technical solutions** with clear rationale and trade-offs
- **Anticipates risks** and edge cases before they become problems
- **Prepares implementation guidance** for smooth Phase 2 execution

The goal is to do the hard thinking upfront so implementation goes smoothly.

## When to Use This Skill

### Trigger Patterns

Use this skill when:
- "Analyze issue #XXX"
- "Execute Phase 1 for #XXX"
- "Investigate #XXX"
- "Analyze the requirements for #XXX"
- "Do technical analysis for #XXX"
- "Start Phase 1 for #XXX"
- "What's involved in #XXX?"

### Automatic Actions

When triggered:
1. **Extract issue number** from input or current branch
2. **Load GitHub issue** (title, description, acceptance criteria)
3. **Load roadmap** from `docs/planning/0.1.X/ISSUE-XXX-ROADMAP.md`
4. **Parse Phase 1 checklist** from roadmap
5. **Determine issue type** (bug, feature, refactor, tech debt)
6. **Execute 5-checkpoint analysis**

### Do NOT Use This Skill

- For creating roadmaps (use `gastrobrain-issue-roadmap` instead)
- For implementation work (use `gastrobrain-senior-dev-implementation`)
- For testing work (use `gastrobrain-testing-implementation`)
- For code review (use `gastrobrain-code-review`)
- For quick questions about the codebase (use Task tool with Explore agent)

## Context Detection

### Automatic Context Loading

```
1. Detect current branch: feature/XXX-description
2. Extract issue number: XXX
3. Fetch issue from GitHub: gh issue view XXX
4. Locate roadmap: docs/planning/0.1.X/ISSUE-XXX-ROADMAP.md
5. Parse Phase 1 checklist items
6. Determine issue type from labels/content
7. Load pattern library for reference
```

### Initial Context Output

```
Phase 1 Analysis for Issue #XXX
═══════════════════════════════════════

Branch: feature/XXX-description
Issue: [Issue title]
Type: [Bug/Feature/Refactor/Tech Debt]
Roadmap: docs/planning/0.1.X/ISSUE-XXX-ROADMAP.md

Phase 1 Checklist (from roadmap):
- [ ] [Checklist item 1]
- [ ] [Checklist item 2]
- [ ] [Checklist item 3]

Analysis Framework:
1. Requirements Deep-Dive
2. Codebase Exploration
3. Technical Design
4. Risk & Edge Case Analysis
5. Implementation Preparation

Total: 5 checkpoints

Ready to start Checkpoint 1/5? (y/n)
```

## The 5-Checkpoint Analysis Framework

### Overview

```
CHECKPOINT 1: Requirements Deep-Dive
├─ Parse issue description
├─ Extract acceptance criteria
├─ Identify user story/pain point
├─ List edge cases mentioned
└─ Clarify unknowns

CHECKPOINT 2: Codebase Exploration
├─ Identify affected files
├─ Find similar implementations
├─ Document existing patterns
├─ Map dependencies
└─ Note integration points

CHECKPOINT 3: Technical Design
├─ Propose solution approach(es)
├─ Evaluate trade-offs
├─ Choose recommended approach
├─ Document technical decisions
└─ Identify design patterns to use

CHECKPOINT 4: Risk & Edge Case Analysis
├─ Identify potential risks
├─ List edge cases to handle
├─ Note backward compatibility concerns
├─ Flag performance considerations
└─ Document testing requirements

CHECKPOINT 5: Implementation Preparation
├─ Create detailed task breakdown
├─ Document patterns to follow
├─ Note files to create/modify
├─ Provide code examples/templates
└─ Update roadmap with findings
```

## Checkpoint 1: Requirements Deep-Dive

**Objective**: Thoroughly understand what needs to be done and why

```
═══════════════════════════════════════
CHECKPOINT 1/5: Requirements Deep-Dive
Goal: Understand issue requirements completely

Reading issue #XXX from GitHub...

Issue Type: [Bug/Feature/Refactor/Tech Debt]

Title: [Issue title]

Description Summary:
[2-3 sentence summary of what the issue is about]

User Story/Pain Point:
As a [user type], I want [capability] so that [benefit].
OR
The problem: [Description of pain point being solved]

Acceptance Criteria:
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3
- [ ] Criterion 4

Success Metrics:
- [How will we know this is done correctly?]
- [What defines success?]

Edge Cases Mentioned in Issue:
- Edge case 1
- Edge case 2
(Will identify more in Checkpoint 4)

Scope Boundaries:
- IN SCOPE: [What's included]
- OUT OF SCOPE: [What's explicitly excluded]

Questions/Clarifications Needed:
- Question 1 (if any unclear requirements)
- Question 2

Requirements Analysis:
[Brief analysis of complexity and key considerations]

Requirements understood? Any clarifications needed? (y/n/clarify)

[STOP - WAIT for user input]
═══════════════════════════════════════
```

### Requirements Analysis by Issue Type

**Bug Issues:**
- Focus on reproduction steps
- Identify expected vs actual behavior
- Understand impact and urgency
- Note affected user scenarios

**Feature Issues:**
- Extract user story clearly
- Identify all acceptance criteria
- Understand priority and dependencies
- Note future extensibility needs

**Refactoring Issues:**
- Identify code smell being addressed
- Understand current vs desired state
- Note behavior that must be preserved
- List affected call sites

**Tech Debt Issues:**
- Understand debt impact
- Identify improvement goals
- Note urgency and dependencies
- List benefits of addressing

## Checkpoint 2: Codebase Exploration

**Objective**: Find affected code and existing patterns to follow

```
═══════════════════════════════════════
CHECKPOINT 2/5: Codebase Exploration
Goal: Identify affected files and patterns to follow

Analyzing codebase for issue #XXX...

Affected Areas:
┌─────────────────────────────────────────────────────────────┐
│ Category    │ Files                    │ Changes Needed     │
├─────────────────────────────────────────────────────────────┤
│ Models      │ lib/models/X.dart        │ [Add/Modify/None]  │
│ Services    │ lib/core/services/X.dart │ [Add/Modify/None]  │
│ Screens     │ lib/screens/X.dart       │ [Add/Modify/None]  │
│ Widgets     │ lib/widgets/X.dart       │ [Add/Modify/None]  │
│ Providers   │ lib/core/providers/X.dart│ [Add/Modify/None]  │
│ Database    │ migrations/              │ [Yes/No]           │
│ Localization│ l10n/app_*.arb           │ [X strings]        │
└─────────────────────────────────────────────────────────────┘

Similar Implementations Found:

1. Pattern: [Pattern name]
   Location: [lib/path/to/file.dart]
   Lines: [XX-YY]
   Approach: [How it solves similar problem]
   Relevance: [Why this is a good pattern to follow]

2. Pattern: [Pattern name]
   Location: [lib/path/to/file.dart]
   Lines: [XX-YY]
   Approach: [How it solves similar problem]
   Relevance: [Why this is applicable]

3. Pattern: [Pattern name]
   Location: [lib/path/to/file.dart]
   Approach: [Description]
   Relevance: [Why this matters]

Dependencies Identified:
- Depends on: [Component X] - [Why]
- Used by: [Component Y] - [Impact]
- Integrates with: [Component Z] - [How]

Integration Points:
- DatabaseHelper: [How this integrates with database layer]
- Provider: [State management implications]
- Localization: [ARB updates needed]
- Navigation: [Routing changes if any]

Files to Create:
- lib/path/to/new_file.dart - [Purpose]
- test/path/to/test_file.dart - [Test coverage]

Files to Modify:
- lib/path/to/existing_file.dart - [What changes and why]
- lib/path/to/another_file.dart - [What changes and why]

Codebase Insights:
[Any interesting observations about how this fits into architecture]

Codebase analysis complete? Anything to explore further? (y/n/explore)

[STOP - WAIT for user input]
═══════════════════════════════════════
```

### Exploration Techniques

**For finding patterns:**
```
1. Search for similar enums → lib/models/
2. Search for similar widgets → lib/widgets/
3. Search for similar services → lib/core/services/
4. Check recent migrations → lib/core/database/migrations/
5. Review similar screens → lib/screens/
```

**For mapping dependencies:**
```
1. Find imports of affected files
2. Find usages of affected classes
3. Trace data flow through layers
4. Identify provider connections
```

## Checkpoint 3: Technical Design

**Objective**: Propose and document the solution approach

```
═══════════════════════════════════════
CHECKPOINT 3/5: Technical Design
Goal: Design the technical solution

For issue #XXX, I've evaluated [N] approaches:

══════════════════════════════════════
APPROACH A: [Name - e.g., "Enum-Based Solution"]
══════════════════════════════════════

Description:
[What this approach does in 2-3 sentences]

Implementation Overview:
1. [Step 1]
2. [Step 2]
3. [Step 3]
4. [Step 4]

Pros:
✅ [Advantage 1]
✅ [Advantage 2]
✅ [Advantage 3]
✅ [Advantage 4]

Cons:
❌ [Disadvantage 1]
❌ [Disadvantage 2]

Complexity: [Low/Medium/High]
Effort: [X story points]

══════════════════════════════════════
APPROACH B: [Alternative name]
══════════════════════════════════════

Description:
[What this approach does]

Implementation Overview:
1. [Step 1]
2. [Step 2]
3. [Step 3]

Pros:
✅ [Advantage 1]
✅ [Advantage 2]

Cons:
❌ [Disadvantage 1]
❌ [Disadvantage 2]
❌ [Disadvantage 3]

Complexity: [Low/Medium/High]
Effort: [X story points]

══════════════════════════════════════
RECOMMENDATION: Approach A
══════════════════════════════════════

Rationale:
- [Reason 1 - Why A is better]
- [Reason 2 - How it fits the codebase]
- [Reason 3 - Trade-off evaluation]
- [Reason 4 - Future considerations]

Why Not Approach B:
- [Reason why B was rejected]

Technical Decisions:

1. [Decision 1]: [Choice made]
   Rationale: [Why this choice]

2. [Decision 2]: [Choice made]
   Rationale: [Why this choice]

3. [Decision 3]: [Choice made]
   Rationale: [Why this choice]

Design Patterns to Apply:
- [Pattern 1] from [Location in codebase]
- [Pattern 2] from [Location in codebase]
- [Pattern 3] from [Location in codebase]

Architecture Fit:
[How this solution fits into Gastrobrain's architecture]

Agree with recommended approach? (y/n/discuss)

[STOP - WAIT for user input]
═══════════════════════════════════════
```

### Design Considerations by Issue Type

**Bug Fixes:**
- Minimal change principle
- Avoid side effects
- Consider regression risk
- Preserve existing behavior

**Features:**
- Future extensibility
- Consistency with existing patterns
- User experience impact
- Performance implications

**Refactoring:**
- Behavior preservation
- Incremental approach
- Test coverage maintenance
- API compatibility

## Checkpoint 4: Risk & Edge Case Analysis

**Objective**: Identify risks and edge cases before coding

```
═══════════════════════════════════════
CHECKPOINT 4/5: Risk & Edge Case Analysis
Goal: Identify risks and edge cases to handle

Risk Assessment for #XXX:

Technical Risks:
┌─────────────────────────────────────────────────────────────┐
│ Risk            │ Level  │ Mitigation                       │
├─────────────────────────────────────────────────────────────┤
│ [Risk 1]        │ 🔴 HIGH│ [How to mitigate]                │
│ [Risk 2]        │ 🟡 MED │ [How to mitigate]                │
│ [Risk 3]        │ 🟢 LOW │ [How to mitigate]                │
└─────────────────────────────────────────────────────────────┘

Edge Cases to Handle:

1. [Edge Case Name]
   Scenario: [When this occurs]
   Expected Behavior: [How to handle]
   Implementation: [Technical approach]

2. [Edge Case Name]
   Scenario: [When this occurs]
   Expected Behavior: [How to handle]
   Implementation: [Technical approach]

3. [Edge Case Name]
   Scenario: [When this occurs]
   Expected Behavior: [How to handle]
   Implementation: [Technical approach]

4. [Edge Case Name]
   Scenario: [When this occurs]
   Expected Behavior: [How to handle]
   Implementation: [Technical approach]

Backward Compatibility:
✅/❌ Existing data: [Impact assessment]
✅/❌ Existing API: [Impact assessment]
✅/❌ User workflows: [Impact assessment]
✅/❌ Rollback safety: [Can we rollback?]

Performance Considerations:
- Query impact: [Assessment]
- Memory impact: [Assessment]
- UI responsiveness: [Assessment]
- Startup time: [Assessment]

Testing Requirements:

Unit Tests:
- [ ] [Test 1 description]
- [ ] [Test 2 description]
- [ ] [Test 3 description]

Widget Tests:
- [ ] [Test 1 description]
- [ ] [Test 2 description]

Integration Tests:
- [ ] [Test 1 description]
- [ ] [Test 2 description]

Edge Case Tests:
- [ ] [Edge case 1 test]
- [ ] [Edge case 2 test]
- [ ] [Edge case 3 test]

Migration Tests (if applicable):
- [ ] Up migration applies cleanly
- [ ] Down migration reverts cleanly
- [ ] Existing data preserved

Blockers Identified:
- [Blocker 1 if any]
- [Blocker 2 if any]
(None if no blockers)

All risks and edge cases identified? (y/n/add more)

[STOP - WAIT for user input]
═══════════════════════════════════════
```

### Edge Case Categories

**Data Edge Cases:**
- Null/empty values
- Maximum/minimum values
- Invalid input
- Concurrent modifications

**UI Edge Cases:**
- Small screens
- Keyboard visibility
- Rotation handling
- Accessibility

**State Edge Cases:**
- Loading states
- Error states
- Empty states
- Partial data

**Integration Edge Cases:**
- Network failures
- Database errors
- Permission issues
- Version mismatches

## Checkpoint 5: Implementation Preparation

**Objective**: Prepare detailed guidance for Phase 2

```
═══════════════════════════════════════
CHECKPOINT 5/5: Implementation Preparation
Goal: Prepare detailed implementation guidance for Phase 2

Implementation Plan:

══════════════════════════════════════
STEP 1: [First Implementation Step]
══════════════════════════════════════

Skill to Use: [gastrobrain-database-migration / inline]

Files:
- [File to create/modify]

Pattern Reference:
- [Pattern name]: [lib/path/to/pattern.dart]

Code Template:
```dart
// Example code for this step
[Actual code example that can be used]
```

Verification:
- [ ] [How to verify this step worked]

══════════════════════════════════════
STEP 2: [Second Implementation Step]
══════════════════════════════════════

Files:
- [File to create/modify]

Pattern Reference:
- [Pattern name]: [lib/path/to/pattern.dart]

Code Template:
```dart
// Example code for this step
[Actual code example]
```

Verification:
- [ ] [How to verify]

══════════════════════════════════════
STEP 3: [Third Implementation Step]
══════════════════════════════════════

[Continue pattern...]

══════════════════════════════════════
STEP N: Localization
══════════════════════════════════════

ARB Updates Needed:

app_en.arb:
```json
"keyName1": "English text",
"@keyName1": {"description": "Description"},
"keyName2": "English text 2"
```

app_pt.arb:
```json
"keyName1": "Texto em português",
"keyName2": "Texto em português 2"
```

══════════════════════════════════════
IMPLEMENTATION SUMMARY
══════════════════════════════════════

Total Steps: [N]
Estimated Checkpoints for Phase 2: [N]
Skills to Delegate:
- Database migration: [Yes/No]
- Testing: gastrobrain-testing-implementation

Files to Create:
- [List of new files]

Files to Modify:
- [List of modified files]

Code Examples Provided: ✅
Patterns Documented: ✅
Edge Cases Listed: ✅
Testing Requirements Defined: ✅

Ready to update roadmap with these findings? (y/n)

[STOP - WAIT for user input]
═══════════════════════════════════════
```

## Roadmap Documentation

### After Checkpoint 5, Update Roadmap

Add the following sections to `docs/planning/0.1.X/ISSUE-XXX-ROADMAP.md`:

```markdown
## Phase 1: Analysis & Understanding ✅ COMPLETE

### Requirements Summary
[2-3 sentence summary from Checkpoint 1]

### Technical Design Decision

**Selected Approach:** [Approach name]

**Rationale:**
- [Reason 1]
- [Reason 2]
- [Reason 3]

**Alternatives Considered:**
- [Alternative 1]: Rejected because [reason]

### Patterns to Follow

| Pattern | Location | Usage |
|---------|----------|-------|
| [Pattern 1] | lib/path/to/file.dart | [How to use] |
| [Pattern 2] | lib/path/to/file.dart | [How to use] |

### Code Examples

#### [Example 1 Name]
```dart
[Code example from Checkpoint 5]
```

#### [Example 2 Name]
```dart
[Code example]
```

### Edge Cases Identified

| Edge Case | Handling Strategy |
|-----------|-------------------|
| [Case 1] | [How to handle] |
| [Case 2] | [How to handle] |
| [Case 3] | [How to handle] |

### Risk Assessment

| Risk | Level | Mitigation |
|------|-------|------------|
| [Risk 1] | Medium | [Mitigation] |
| [Risk 2] | Low | [Mitigation] |

### Testing Requirements

**Unit Tests:**
- [ ] [Test 1]
- [ ] [Test 2]

**Widget Tests:**
- [ ] [Test 1]
- [ ] [Test 2]

**Edge Case Tests:**
- [ ] [Test 1]
- [ ] [Test 2]

### Implementation Checklist (for Phase 2)

- [ ] Step 1: [Description] (using [pattern])
- [ ] Step 2: [Description] (using [pattern])
- [ ] Step 3: [Description]
- [ ] Step 4: Localization ([N] strings)
- [ ] Step 5: Integration verification

### Files Summary

**To Create:**
- lib/path/to/new_file.dart

**To Modify:**
- lib/path/to/existing.dart (reason)

---
*Phase 1 analysis completed on [date]*
*Ready for Phase 2 implementation*
```

## Pattern Library Reference

### Common Patterns in Gastrobrain

**Enum Patterns:**
```
Location: lib/models/meal_type.dart
Usage: Enum with string value, fromString(), getDisplayName(l10n)
When: Need fixed set of options with localized display
```

**Model Patterns:**
```
Location: lib/models/recipe.dart, lib/models/meal.dart
Usage: toMap(), fromMap(), copyWith(), nullable fields
When: Database-backed entity
```

**Service Patterns:**
```
Location: lib/core/services/recommendation_cache_service.dart
Usage: Constructor DI, private helpers, GastrobrainException
When: Business logic with database access
```

**Widget Patterns:**
```
Location: lib/screens/weekly_plan_screen.dart
Usage: StatefulWidget with initState DI, mounted checks, dispose
When: Stateful UI with service dependencies
```

**Provider Patterns:**
```
Location: lib/core/providers/recipe_provider.dart
Usage: ChangeNotifier, private state, notifyListeners()
When: Shared state management
```

**Dropdown Patterns:**
```
Location: lib/widgets/ (various)
Usage: DropdownButtonFormField with localized items
When: Enum selection in forms
```

**Dialog Patterns:**
```
Location: lib/widgets/meal_recording_dialog.dart
Usage: StatefulWidget dialog with form validation
When: Modal data entry
```

**Migration Patterns:**
```
Location: lib/core/database/migrations/
Usage: up() and down() methods, version increment
When: Schema changes needed
```

### Finding Patterns

```dart
// To find enum patterns:
grep -r "enum.*{" lib/models/

// To find similar widgets:
grep -r "extends StatefulWidget" lib/widgets/

// To find service patterns:
grep -r "class.*Service" lib/core/services/

// To find provider patterns:
grep -r "extends ChangeNotifier" lib/core/providers/
```

## Integration with Issue Types

### Bug Analysis Focus

```
Checkpoint 1: Root cause identification
- What's the bug?
- When does it occur?
- What's expected vs actual?

Checkpoint 2: Code path tracing
- Where does the bug originate?
- What components are involved?
- Any related bugs?

Checkpoint 3: Fix approach
- Minimal change fix
- Avoid side effects
- Preserve other behavior

Checkpoint 4: Regression prevention
- What could break?
- Test coverage gaps?
- Similar code patterns?

Checkpoint 5: Fix implementation
- Targeted code changes
- Regression test plan
- Verification steps
```

### Feature Analysis Focus

```
Checkpoint 1: Requirements clarity
- User story complete?
- Acceptance criteria clear?
- Scope defined?

Checkpoint 2: Architecture fit
- Where does this belong?
- Existing patterns to follow?
- Integration points?

Checkpoint 3: Design decisions
- Multiple approaches?
- Trade-offs evaluated?
- Future extensibility?

Checkpoint 4: Edge cases
- What could go wrong?
- User error handling?
- Data edge cases?

Checkpoint 5: Implementation plan
- Step-by-step guide
- Code examples
- Testing strategy
```

### Refactoring Analysis Focus

```
Checkpoint 1: Code smell identification
- What's the problem?
- Why does it matter?
- What's the goal?

Checkpoint 2: Impact assessment
- Affected call sites?
- Test coverage?
- Dependencies?

Checkpoint 3: Refactoring approach
- Extract/inline/rename?
- Incremental steps?
- API compatibility?

Checkpoint 4: Risk assessment
- Behavior preservation?
- Breaking changes?
- Rollback plan?

Checkpoint 5: Execution plan
- Safe steps
- Verification at each step
- Test updates needed
```

## Checkpoint Protocol

### For Each Checkpoint

```
═══════════════════════════════════════
CHECKPOINT X/5: [Checkpoint Name]
Goal: [One sentence goal]

[If X > 1, show progress:]
Progress:
✓ Checkpoint 1: [Name] [COMPLETE]
✓ Checkpoint 2: [Name] [COMPLETE]
⧗ Checkpoint X: [Name] [CURRENT]
○ Checkpoint X+1: [Name]
○ Checkpoint X+2: [Name]

[Checkpoint content...]

[Checkpoint question]? (y/n/[other options])

[STOP - WAIT for user input]
═══════════════════════════════════════
```

### Response Handling

**If user responds "y":**
```
✅ CHECKPOINT X/5 complete

Progress: X/5 checkpoints ████░ XX%

Proceeding to Checkpoint (X+1)/5...
```

**If user responds "n" or needs clarification:**
```
Let me address that before continuing.

[Address concern or explore further]

Ready to proceed now? (y/n)
```

**If user wants to explore more:**
```
Exploring further...

[Additional analysis]

Does this address your question? (y/n)
```

## Completion Summary

### After All Checkpoints

```
═══════════════════════════════════════
PHASE 1 ANALYSIS COMPLETE
═══════════════════════════════════════

Issue: #XXX - [Issue title]
Branch: feature/XXX-description
Type: [Bug/Feature/Refactor]

Analysis Summary:
✓ Checkpoint 1: Requirements understood
✓ Checkpoint 2: Codebase explored
✓ Checkpoint 3: Technical design selected
✓ Checkpoint 4: Risks and edge cases identified
✓ Checkpoint 5: Implementation guidance prepared

Key Decisions:
- [Decision 1]
- [Decision 2]
- [Decision 3]

Patterns to Follow:
- [Pattern 1] from [location]
- [Pattern 2] from [location]

Edge Cases Identified: [N]
Risks Mitigated: [N]
Implementation Steps: [N]

Roadmap Updated:
✓ docs/planning/0.1.X/ISSUE-XXX-ROADMAP.md
  └─ Phase 1 section marked complete
  └─ Technical design documented
  └─ Code examples added
  └─ Implementation checklist ready

Next Steps:
1. → Execute Phase 2 with gastrobrain-senior-dev-implementation
2. → Use patterns and code examples from this analysis
3. → Follow implementation checklist in roadmap

Ready to start Phase 2 implementation? (y/n)
═══════════════════════════════════════
```

## Error Handling

### If Issue Not Found

```
❌ Could not find issue #XXX

Possible reasons:
1. Issue number incorrect
2. Issue is in different repository
3. GitHub API access issue

Please verify the issue number and try again.
```

### If Roadmap Not Found

```
⚠️ Roadmap not found for issue #XXX

Expected location: docs/planning/0.1.X/ISSUE-XXX-ROADMAP.md

Options:
1. Create roadmap first with gastrobrain-issue-roadmap skill
2. Specify roadmap location manually
3. Continue analysis without roadmap (will create notes)

What would you like to do? (create/specify/continue)
```

### If Pattern Not Found

```
⚠️ No similar pattern found for [component type]

This appears to be a new pattern for the codebase.

Options:
1. Look at broader Flutter/Dart conventions
2. Design a new pattern (document for future use)
3. Ask for guidance on preferred approach

Recommendation: [Suggested approach]
```

## Success Criteria

This skill succeeds when:

1. **Thorough Understanding**: Requirements fully understood with no ambiguity
2. **Complete Exploration**: All affected files and patterns identified
3. **Sound Design**: Technical approach well-reasoned with clear trade-offs
4. **Proactive Risk Management**: Edge cases and risks identified upfront
5. **Actionable Output**: Implementation guidance is specific and usable
6. **Documented Findings**: Roadmap updated with all analysis
7. **User Confidence**: User feels ready to start implementation
8. **Smooth Handoff**: Phase 2 can proceed without surprises

## References

### Related Skills

| Skill | When to Use |
|-------|-------------|
| `gastrobrain-issue-roadmap` | Create roadmap before analysis |
| `gastrobrain-senior-dev-implementation` | Execute Phase 2 after analysis |
| `gastrobrain-database-migration` | If database changes needed |
| `gastrobrain-testing-implementation` | Execute Phase 3 |
| `gastrobrain-code-review` | Verify Phase 4 |

### Documentation

| Doc | Purpose |
|-----|---------|
| `CLAUDE.md` | Project conventions |
| `docs/architecture/Gastrobrain-Codebase-Overview.md` | Architecture details |
| `docs/workflows/ISSUE_WORKFLOW.md` | Issue management |
| `docs/testing/EDGE_CASE_CATALOG.md` | Edge case reference |

---

**Remember**: The best implementation starts with thorough analysis. This skill ensures no surprises during coding because the hard thinking was done upfront.
