---
name: gastrobrain-issue-creator
description: Transform user reports, bug discoveries, or feature ideas into well-structured GitHub issues following Gastrobrain conventions through an interactive checkpoint-based process
version: 1.0.0
author: Gastrobrain Development Team
tags: [issue-management, github, planning, workflow]
---

# Issue Creation Agent Skill

## Overview

This skill transforms informal bug reports, feature requests, or technical debt discoveries into well-structured GitHub issues that follow Gastrobrain's conventions. It uses a **6-checkpoint interactive process** to ensure accuracy, completeness, and user approval before creation.

## When to Use This Skill

**Trigger phrases:**
- "Create an issue for..."
- "I found a bug..."
- "We should add a feature..."
- "There's technical debt in..."
- User reports a problem
- Discovery during work on another issue

**Use cases:**
1. **User Reports/Feedback** - Transform informal bug reports into structured issues
2. **Bug Discovery** - Document bugs found during development
3. **Feature Requests** - Convert ideas into actionable enhancement issues
4. **Technical Debt** - Track refactoring needs and code quality improvements
5. **Testing Gaps** - Create issues for missing test coverage

## Issue Creation Philosophy

**Why structured issues matter:**
- Clear problem definition prevents confusion
- Acceptance criteria provide definition of done
- Technical context speeds up implementation
- Proper labeling enables sprint planning
- Story point estimates help with capacity planning
- Related issue links maintain context

**Gastrobrain-specific requirements:**
- Follow Git Flow workflow (feature branches from develop)
- Include localization considerations (EN/PT-BR)
- Reference project conventions (CLAUDE.md, workflows)
- Align with testing standards (DIALOG_TESTING_GUIDE.md, EDGE_CASE_TESTING_GUIDE.md)
- Consider architectural patterns (ServiceProvider, DatabaseHelper)

## Checkpoint-Based Creation Process

**CRITICAL:** Never generate an entire issue in one response. Always use the 6-checkpoint interactive process.

### Checkpoint Flow Overview

```
User Input → Context Detection
    ↓
Checkpoint 1: Understanding the Problem (WAIT)
    ↓
Checkpoint 2: Issue Details (WAIT)
    ↓
Checkpoint 3: Implementation Guidance (WAIT)
    ↓
Checkpoint 4: Acceptance & Testing (WAIT)
    ↓
Checkpoint 5: Labels & Priority (WAIT)
    ↓
Checkpoint 6: Final Review (WAIT)
    ↓
GitHub CLI Commands
```

### Checkpoint 1: Understanding the Problem

**Purpose:** Confirm understanding of the issue before writing anything

**Output format:**
```
Issue Creation: [Type]

CHECKPOINT 1: Understanding the Problem
─────────────────────────────────────────

Let me make sure I understand:

Type: [Bug/Enhancement/Technical Debt/Testing/Documentation]
Scope: [UI/UX/Model/Architecture/Testing/Performance]
Affected area: [Specific component/screen/service]
Priority: [P0-Critical/P1-High/P2-Medium/P3-Low] (preliminary)

Specifics:
- [Key detail 1]
- [Key detail 2]
- [Impact statement]

Is this correct? Any other details I should know? (y/n/more details)
```

**Wait for user response before proceeding.**

---

### Checkpoint 2: Issue Details

**Purpose:** Draft the core issue content for user review

**Output format:**
```
─────────────────────────────────────────
CHECKPOINT 2: Issue Details

Title: "[type]: [brief description in lowercase]"

Context:
[Why this matters, background, when/where discovered]

Current Behavior:
[What happens now - for bugs: steps to reproduce]

Expected Behavior:
[What should happen instead]

Does this capture the issue correctly? Any adjustments needed? (y/n/edit)
```

**If user says "edit":** Ask which section to revise and incorporate changes.

**Wait for user response before proceeding.**

---

### Checkpoint 3: Implementation Guidance

**Purpose:** Provide technical direction and break down work

**Output format:**
```
─────────────────────────────────────────
CHECKPOINT 3: Implementation Guidance

Proposed Solution:
[High-level approach if clear, or "To be determined during implementation"]

Tasks:
- [ ] [Task 1 - typically: Analyze/Design/Implement/Test]
- [ ] [Task 2]
- [ ] [Task 3]
- [ ] [Consider localization if UI changes]
- [ ] [Run flutter analyze && flutter test]

Technical Notes:
- Affected files: [list specific files if known]
- Related issues: #XXX [if applicable]
- Pattern to follow: [reference similar work]
- Database changes: [if applicable]
- [Other technical context]

Is this implementation direction helpful? (y/n/adjust)
```

**Technical context guidelines:**
- Reference specific files when known (lib/screens/, lib/core/services/, etc.)
- Link to similar patterns in codebase
- Note if database migration needed
- Mention localization requirements (app_en.arb, app_pt.arb)
- Reference testing patterns (MockDatabaseHelper, DialogTestHelpers)

**Wait for user response before proceeding.**

---

### Checkpoint 4: Acceptance & Testing

**Purpose:** Define "done" criteria and test scenarios

**Output format:**
```
─────────────────────────────────────────
CHECKPOINT 4: Acceptance & Testing

Acceptance Criteria:
- [ ] [Criterion 1 - core functionality works]
- [ ] [Criterion 2 - edge cases handled]
- [ ] [Criterion 3 - tests pass]
- [ ] [Criterion 4 - no regressions]
- [ ] [Localized in EN and PT-BR] (if UI)

Test Cases:
- [Main workflow test]
- [Edge case 1]
- [Edge case 2]
- [Error scenario test]

Are these acceptance criteria complete? Need more? (y/n/add)
```

**Testing context guidelines:**
- Reference testing guides (DIALOG_TESTING_GUIDE.md, EDGE_CASE_TESTING_GUIDE.md)
- Include empty state tests for features with lists
- Include boundary condition tests
- Include error handling tests
- Mention regression tests for bugs

**Wait for user response before proceeding.**

---

### Checkpoint 5: Labels & Priority

**Purpose:** Assign metadata for planning and filtering

**Output format:**
```
─────────────────────────────────────────
CHECKPOINT 5: Labels & Priority

Recommended labels:
- Type: [enhancement/bug/technical-debt/testing/documentation]
- Scope: [UI/UX/model/architecture/testing/performance/i18n]
- Priority: [P0-Critical/P1-High/P2-Medium/P3-Low]
- Additional: [good first issue] (if applicable)

Priority reasoning:
[Why this priority level - impact, urgency, blocking other work]

Story Point Estimate: [X points] (preliminary)
Estimation reasoning:
- Complexity: [simple/moderate/complex]
- Files affected: [few/several/many]
- Testing required: [minimal/moderate/comprehensive]
- Uncertainty: [low/medium/high]
- Estimated effort: [X-Y hours]

Agree with labels and estimate? (y/n/adjust)
```

**Label selection guidelines:**

*Type labels:*
- `enhancement` - New features or improvements
- `bug` - Defects or incorrect behavior
- `technical-debt` - Code quality, refactoring
- `testing` - Test coverage improvements
- `documentation` - Documentation updates

*Scope labels:*
- `UI` - User interface changes
- `UX` - User experience improvements
- `model` - Data model changes
- `architecture` - Structural/design changes
- `testing` - Test infrastructure
- `performance` - Optimization work
- `i18n` - Internationalization/localization

*Priority labels:*
- `P0-Critical` - Blocks daily use, immediate fix needed
- `P1-High` - Important, should be in current/next sprint
- `P2-Medium` - Nice-to-have, plan for future sprint
- `P3-Low` - Enhancement for backlog

*Special labels:*
- `good first issue` - Suitable for new contributors
- `help wanted` - Seeking assistance

**Story point scale:**
- **1 point:** Trivial (< 1 hour) - typo, simple config change
- **2 points:** Small (1-2 hours) - add field, simple test, quick fix
- **3 points:** Medium (2-4 hours) - new widget, bug investigation, unit tests
- **5 points:** Larger (4-8 hours) - feature with UI, service updates, comprehensive tests
- **8 points:** Large (8-16 hours) - complex feature, major refactor, multiple services
- **13+ points:** Epic - should be broken into smaller issues

**Wait for user response before proceeding.**

---

### Checkpoint 6: Final Review

**Purpose:** Show complete issue markdown and get final approval

**Output format:**
```
─────────────────────────────────────────
CHECKPOINT 6: Final Review

Here's the complete issue:

─────────────────────────────────────────
[Display complete issue markdown]
─────────────────────────────────────────

Ready to create this issue? (y/n/revise)

If "revise": Which section? (1-5 to go back to checkpoint)
If "y": [Proceed to GitHub CLI commands]
```

**If approved, execute the issue creation workflow:**

Use the Bash tool to execute the following commands in sequence. The tool will automatically prompt the user for permission before each execution, allowing them to:
- Execute the command
- Execute and allow similar commands
- Deny the command

**Step 1:** Create the issue using `gh issue create`
- This will return an issue number (e.g., #267)
- Store this number for subsequent commands

**Step 2:** Add labels using `gh issue edit [number] --add-label`
- Use the issue number from Step 1
- Combine all labels in a single comma-separated list

**Step 3 (Optional):** Add to project if requested
- Use `gh project item-add` with the issue URL

**Step 4 (Optional):** Set milestone if known
- Use `gh issue edit [number] --milestone`

**Important:** Execute commands one at a time, waiting for each to complete before proceeding. If the user denies a command, explain what was skipped and continue with remaining steps (if applicable).

---

## Issue Type Templates

### Bug Issue Structure

```markdown
## Context
[When/where discovered, impact on users, severity justification]

## Current Behavior

**Steps to Reproduce:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Actual Result:** [What happens - be specific]

**Expected Result:** [What should happen]

[Optional: Screenshots, error messages, logs]

## Proposed Solution
[How to fix if known, or "To be investigated during implementation"]

## Tasks
- [ ] Reproduce bug with test case
- [ ] Identify root cause in [affected component]
- [ ] Implement fix
- [ ] Add regression test
- [ ] Verify fix works across scenarios
- [ ] Run flutter analyze && flutter test

## Acceptance Criteria
- [ ] Bug no longer occurs with reproduction steps
- [ ] Regression test added to prevent recurrence
- [ ] No new bugs introduced
- [ ] Related functionality still works correctly
- [ ] All existing tests pass

## Technical Notes
- **Affected files:** [list paths]
- **Discovered in:** #XXX [if during other work]
- **Suspected cause:** [hypothesis if known]
- **Related issues:** #XXX [if applicable]
- **Testing pattern:** [reference applicable guide]

## Test Cases
- Test that reproduces the bug
- Test that verifies the fix
- Edge cases: [list scenarios]
- Regression check: [related functionality]
```

---

### Enhancement Issue Structure

```markdown
## Context
[Why is this needed? User pain point, opportunity, or improvement rationale]

## Current Behavior
[What exists now, what's missing, or what's suboptimal]

## Expected Behavior
[Detailed description of desired feature/improvement]
[Optional: UI mockups, workflow diagrams]

## Proposed Solution
[High-level implementation approach]
[Alternative approaches considered]

## Tasks
- [ ] Design implementation approach
- [ ] Update data models (if needed)
- [ ] Add database migrations (if needed)
- [ ] Implement core functionality
- [ ] Add UI components (if applicable)
- [ ] Add strings to app_en.arb and app_pt.arb
- [ ] Run flutter gen-l10n (if strings added)
- [ ] Write unit tests
- [ ] Write widget tests (if UI)
- [ ] Write integration/E2E tests (if workflow)
- [ ] Update documentation
- [ ] Run flutter analyze && flutter test

## Acceptance Criteria
- [ ] Feature works as specified
- [ ] Localized in both English and Portuguese
- [ ] Tests cover main scenarios and edge cases
- [ ] No regressions in existing features
- [ ] Performance is acceptable
- [ ] Follows project architecture patterns
- [ ] Documentation updated

## Technical Notes
- **New models/services:** [list if applicable]
- **Database changes:** [describe schema changes, migration needed]
- **Affected screens:** [list UI components]
- **Similar pattern:** #XXX [reference if similar work exists]
- **Dependencies:** [new packages needed]
- **Localization:** [specific strings needed]
- **Testing approach:** [reference DIALOG_TESTING_GUIDE or EDGE_CASE_TESTING_GUIDE]

## Test Cases
- Main workflow test: [describe]
- Edge cases: [list scenarios]
- Error scenarios: [list error handling]
- Empty state: [if applicable]
- Boundary conditions: [if applicable]
```

---

### Technical Debt Issue Structure

```markdown
## Context
[Why this technical debt exists, how it impacts development/maintenance]

## Current Behavior
[Description of problematic implementation, code smell, or architectural issue]
[Examples of where the problem manifests]

## Expected Behavior
[What the improved structure/implementation should look like]
[Benefits of refactoring]

## Proposed Solution
[Refactoring approach: extract service, consolidate logic, improve pattern, etc.]
[Step-by-step approach if complex]

## Tasks
- [ ] Analyze current implementation thoroughly
- [ ] Design refactored structure
- [ ] Create new abstraction/service (if needed)
- [ ] Extract/consolidate code
- [ ] Update all call sites
- [ ] Verify all existing tests still pass
- [ ] Add tests for refactored code (if coverage gaps)
- [ ] Update documentation
- [ ] Run flutter analyze && flutter test

## Acceptance Criteria
- [ ] Code is more maintainable/readable
- [ ] All existing tests still pass
- [ ] No functionality changes (pure refactoring)
- [ ] Test coverage maintained or improved
- [ ] Related code follows new pattern
- [ ] Documentation reflects new structure

## Technical Notes
- **Files to refactor:** [list paths]
- **Pattern to follow:** [reference existing pattern or issue]
- **Similar refactoring:** #XXX [if applicable]
- **Benefits:**
  - [Reduced duplication]
  - [Clearer separation of concerns]
  - [Easier testing]
  - [Other benefits]
- **Risks:** [potential issues during refactoring]

## Test Cases
- Verify existing behavior is unchanged
- Test all affected code paths
- Edge cases still handled correctly
- No regressions in dependent code
```

---

### Testing Issue Structure

```markdown
## Context
[Why these tests are needed, what coverage gap exists]

## Current Behavior
[Current test coverage state, what's missing]

## Expected Behavior
[Desired test coverage level, scenarios that should be tested]

## Proposed Solution
[Testing approach, which test helpers to use]

## Tasks
- [ ] Identify test scenarios (happy path, edge cases, errors)
- [ ] Set up test fixtures/mocks
- [ ] Write unit tests (if applicable)
- [ ] Write widget tests (if UI)
- [ ] Write integration tests (if workflow)
- [ ] Test edge cases (empty states, boundary conditions)
- [ ] Test error scenarios
- [ ] Verify coverage improvement
- [ ] Run flutter test --coverage && flutter analyze

## Acceptance Criteria
- [ ] All identified scenarios have test coverage
- [ ] Tests follow project patterns (MockDatabaseHelper, TestSetup, etc.)
- [ ] Edge cases covered (see EDGE_CASE_TESTING_GUIDE.md)
- [ ] Error scenarios tested
- [ ] All tests pass consistently
- [ ] Coverage improved by [X]%

## Technical Notes
- **Component under test:** [path to file]
- **Testing pattern:** [reference DIALOG_TESTING_GUIDE, EDGE_CASE_TESTING_GUIDE, etc.]
- **Test helpers:** [MockDatabaseHelper, DialogTestHelpers, EdgeCaseTestHelpers, etc.]
- **Coverage before:** [X]%
- **Coverage target:** [Y]%

## Test Cases
- Happy path: [main workflow]
- Edge cases: [empty state, boundary conditions]
- Error scenarios: [database errors, validation failures]
- Cancellation: [if dialog]
- Alternative dismissal: [back button, tap outside, etc.]
```

---

## Context Detection Guidelines

### Detecting Issue Type

**Bug indicators:**
- "doesn't work", "broken", "error", "crash", "wrong behavior"
- "disappears", "lost", "missing", "incorrect"
- Steps to reproduce provided
- Error messages or unexpected behavior

**Enhancement indicators:**
- "would be nice", "feature request", "add", "improve"
- "should have", "could use", "missing feature"
- User suggests new capability

**Technical Debt indicators:**
- "refactor", "consolidate", "duplicate code", "code smell"
- "hard to maintain", "confusing", "should extract"
- "debt", "cleanup", "improve structure"

**Testing indicators:**
- "no tests for", "missing coverage", "should test"
- "add tests", "test gap", "untested"

### Detecting Priority

**P0-Critical (Blocking):**
- App crashes, data loss, security issue
- Blocks all users from core functionality
- Production breaking issue

**P1-High (Important):**
- Significant feature not working
- Data integrity issues
- Impacts daily use for most users
- Should fix in current/next sprint

**P2-Medium (Nice-to-have):**
- Enhancement that improves experience
- Non-critical bug with workaround
- Plan for future sprint

**P3-Low (Backlog):**
- Nice-to-have enhancement
- Cosmetic issues
- Technical debt that's not blocking
- Future consideration

### Detecting Affected Areas

**UI indicators:**
- Screen names (MealRecordingDialog, WeeklyPlanScreen)
- Widget names (RecipeCard, CalendarWidget)
- Visual issues (layout, overflow, alignment)

**Model indicators:**
- Data structures (Recipe, Meal, Ingredient)
- Database tables
- Validation issues

**Service indicators:**
- Business logic (RecommendationService, MealEditService)
- Data processing
- Algorithms

**Architecture indicators:**
- Cross-cutting concerns
- Dependency injection
- Service organization

---

## Related Issue Detection

### When to Search for Related Issues

- User mentions component name (check for existing issues on that component)
- Working on another issue (check for related work)
- Similar symptoms to past bugs
- Enhancement in area with existing issues

### How to Search

```bash
# Search by component name
gh issue list --search "MealRecordingDialog" --state all

# Search by keyword
gh issue list --search "side dish" --state all

# Search by label
gh issue list --label "UI" --state open
```

### Presenting Related Issues

```
Related Issues Detected:
- #237: "Consolidate MealEditService" (same service)
- #206: "Fix protein counting" (similar functionality)
- #250: "Save button obscured" (same screen)

Should I reference these in the new issue? (y/n/which ones)
```

### Relationship Types

- **Blocks/Blocked by:** One issue must be completed before the other
- **Related to:** Similar area or functionality
- **Duplicate of:** Same issue (don't create, comment on existing)
- **Discovered during:** Bug found while working on another issue
- **Parent/Child:** Epic and sub-tasks

---

## Special Scenarios

### Scenario 1: Issue Discovered During Active Work

**Context detection:**
```
Detecting active work context...
- Current branch: feature/250-save-button-fix
- Working on: Issue #250
- Current milestone: 0.1.6
```

**Checkpoint 1 addition:**
```
Context detected:
- Discovered while working on #250
- May be related to current work
- Could block #250 completion

Should I:
1. Reference #250 in the new issue
2. Note this was discovered during #250 work
3. Consider priority relative to #250
4. Check if this blocks #250

How should we handle the relationship? (1/2/3/4/all)
```

---

### Scenario 2: User Report in Informal Language

**Example user input:**
```
"The thing where you add ingredients is super broken when you have
like a ton of them. I can't even see the save button lol"
```

**Checkpoint 1 translation:**
```
CHECKPOINT 1: Understanding the Problem
─────────────────────────────────────────

Let me translate this to structured format:

Type: Bug
Scope: UI (layout/scrolling issue)
Affected area: Add Ingredient Dialog
Priority: P1-High (blocks core functionality)

Specifics:
- Happens when: Many ingredients in the list
- Condition: Long ingredient list
- Result: Save button not visible/accessible
- Impact: Users cannot save after selecting ingredient

My interpretation:
- Dialog doesn't scroll properly with long lists
- Save button at bottom is obscured
- Possibly viewport/layout constraint issue

Is this correct? Did I capture the issue? (y/n/more details)
```

---

### Scenario 3: Feature Request with Vague Description

**Example user input:**
```
"Can we make meal planning easier somehow?"
```

**Checkpoint 1 - Ask clarifying questions:**
```
CHECKPOINT 1: Understanding the Problem
─────────────────────────────────────────

I need more details to create a good issue. Let me ask:

1. What part of meal planning is difficult?
   - Finding recipes?
   - Adding recipes to the plan?
   - Managing the weekly view?
   - Something else?

2. What would make it easier?
   - Faster workflow?
   - Less clicks?
   - Better recommendations?
   - Different UI?

3. Can you describe the current workflow that's hard?
   - Step 1: I do...
   - Step 2: Then I...
   - The hard part is...

Please provide more specifics so I can create a focused, actionable issue.
```

**Wait for clarification before proceeding to full checkpoints.**

---

### Scenario 4: Multiple Issues in One Report

**Example user input:**
```
"When I edit meals, the side dishes disappear AND the date picker
shows future dates which shouldn't be allowed."
```

**Response:**
```
I detected TWO distinct issues in your report:

Issue A: Side dishes disappear when editing meals
- Type: Bug (data loss)
- Priority: P1-High

Issue B: Date picker allows future dates
- Type: Bug (validation)
- Priority: P2-Medium

These should be separate issues for better tracking.

Which would you like to create first? (A/B/both separately)
```

**Then run checkpoint process for each issue separately.**

---

## GitHub CLI Commands Reference

**Note:** This section provides command syntax examples for your understanding. When creating issues through this skill, these commands will be executed using the Bash tool with user permission prompts - they should NOT be output as text for copy/paste.

### Basic Issue Creation

```bash
# Create issue with title and body
gh issue create \
  --title "bug: side dishes disappear when editing meals" \
  --body "$(cat <<'EOF'
[Issue markdown here]
EOF
)"
```

### Adding Labels

```bash
# Add labels to issue (use issue number from creation)
gh issue edit 267 --add-label "bug,UI,P1-High"
```

### Adding to Project

```bash
# Add issue to GitHub Project
gh project item-add 3 \
  --owner alemdisso \
  --url https://github.com/alemdisso/gastrobrain/issues/267
```

### Setting Milestone

```bash
# Assign to milestone
gh issue edit 267 --milestone "0.1.6 - Shopping List & Polish"

# List available milestones
gh api repos/:owner/:repo/milestones --jq '.[] | {number, title}'
```

### Setting Assignee

```bash
# Assign to yourself (solo dev)
gh issue edit 267 --add-assignee @me
```

### Linking Issues

```bash
# Reference in comment (for relationships)
gh issue comment 267 --body "Related to #250 - discovered during that work"
gh issue comment 267 --body "Blocks #250 - must fix before completing"
gh issue comment 267 --body "Duplicate of #123 - closing this one"
```

---

## Complete Example Flows

See `examples/` directory for:
1. `bug_from_user_report.md` - Bug discovered by user
2. `enhancement_from_suggestion.md` - Feature request
3. `technical_debt_discovery.md` - Code quality issue
4. `issue_during_work.md` - Bug found during active work

---

## Skill Guardrails

### What This Skill DOES

✅ Transform informal reports into structured issues
✅ Use interactive checkpoint process for accuracy
✅ Provide technical context and implementation guidance
✅ Suggest appropriate labels and priorities with reasoning
✅ Estimate story points with justification
✅ Detect related issues
✅ Generate exact GitHub CLI commands
✅ Allow revision at any checkpoint

### What This Skill DOES NOT Do

❌ Create issues without user confirmation
❌ Generate entire issue in one response
❌ Guess at unknown technical details
❌ Assign issues without user approval
❌ Close or modify existing issues
❌ Make architectural decisions
❌ Skip checkpoint process for "simple" issues

---

## Quality Checklist

Before final approval (Checkpoint 6), verify:

- [ ] Title follows convention: `[type]: [description]`
- [ ] Context explains why this matters
- [ ] Current/Expected behavior clearly distinguished
- [ ] Tasks are actionable and complete
- [ ] Acceptance criteria define "done"
- [ ] Technical notes include file paths and patterns
- [ ] Labels match issue type and scope
- [ ] Priority justified with reasoning
- [ ] Story points estimated with explanation
- [ ] Related issues referenced if applicable
- [ ] Localization considered if UI changes
- [ ] Testing approach mentioned
- [ ] Follows Gastrobrain conventions

---

## Version History

**v1.0.0** (2026-01-13)
- Initial skill creation
- 6-checkpoint interactive process
- Bug, enhancement, technical debt, testing templates
- Context detection and related issue search
- Story point estimation guidelines
- Complete example flows
