# Issue Templates for Gastrobrain

Quick reference templates for different issue types. Use these as starting points during the checkpoint process.

---

## Bug Issue Template

```markdown
## Context
[When/where discovered, impact on users]

## Current Behavior

**Steps to Reproduce:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Actual Result:** [What happens]

**Expected Result:** [What should happen]

## Proposed Solution
[How to fix if known, or "To be investigated"]

## Tasks
- [ ] Reproduce bug with test case
- [ ] Identify root cause
- [ ] Implement fix
- [ ] Add regression test
- [ ] Verify fix works
- [ ] Run flutter analyze && flutter test

## Acceptance Criteria
- [ ] Bug no longer occurs with reproduction steps
- [ ] Regression test added
- [ ] No new bugs introduced
- [ ] Related functionality still works

## Technical Notes
- **Affected files:** [paths]
- **Discovered in:** #XXX [if applicable]
- **Suspected cause:** [if known]
- **Related issues:** #XXX

## Test Cases
- Test that reproduces the bug
- Test that verifies the fix
- Edge cases: [list]
```

**Labels:** `bug`, `[scope]`, `[priority]`

**Story points:** 2-5 depending on complexity

---

## Enhancement Issue Template

```markdown
## Context
[Why is this needed? User pain point or opportunity]

## Current Behavior
[What exists now or what's missing]

## Expected Behavior
[What the feature should do]

## Proposed Solution
[High-level approach]

## Tasks
- [ ] Design implementation approach
- [ ] Update data models (if needed)
- [ ] Add database migrations (if needed)
- [ ] Implement core functionality
- [ ] Add UI components (if applicable)
- [ ] Add strings to app_en.arb and app_pt.arb
- [ ] Run flutter gen-l10n
- [ ] Write tests (unit/widget/E2E)
- [ ] Update documentation
- [ ] Run flutter analyze && flutter test

## Acceptance Criteria
- [ ] Feature works as specified
- [ ] Localized in EN and PT-BR
- [ ] Tests cover main scenarios
- [ ] No regressions
- [ ] Performance acceptable

## Technical Notes
- **New models/services:** [list]
- **Database changes:** [migration needed?]
- **Affected screens:** [list]
- **Similar pattern:** #XXX
- **Testing approach:** [guide reference]

## Test Cases
- Main workflow test
- Edge cases: [list]
- Error scenarios: [list]
```

**Labels:** `enhancement`, `[scope]`, `[priority]`

**Story points:** 3-8 depending on scope

---

## Technical Debt Issue Template

```markdown
## Context
[Why this technical debt exists, impact on development]

## Current Behavior
[Description of problematic implementation]

## Expected Behavior
[What improved structure should look like]

## Proposed Solution
[Refactoring approach]

## Tasks
- [ ] Analyze current implementation
- [ ] Design refactored structure
- [ ] Extract/consolidate code
- [ ] Update all call sites
- [ ] Verify all tests still pass
- [ ] Update documentation
- [ ] Run flutter analyze && flutter test

## Acceptance Criteria
- [ ] Code is more maintainable
- [ ] All tests still pass
- [ ] No functionality changes
- [ ] Test coverage maintained/improved

## Technical Notes
- **Files to refactor:** [list]
- **Pattern to follow:** [reference]
- **Benefits:** [reduced duplication, clearer separation, etc.]

## Test Cases
- Verify existing behavior unchanged
- Test all affected code paths
```

**Labels:** `technical-debt`, `[scope]`, `P3-Low` (typically)

**Story points:** 2-5 depending on complexity

---

## Testing Issue Template

```markdown
## Context
[Why these tests are needed, coverage gap]

## Current Behavior
[Current test coverage state, what's missing]

## Expected Behavior
[Desired test coverage, scenarios to test]

## Proposed Solution
[Testing approach, helpers to use]

## Tasks
- [ ] Identify test scenarios
- [ ] Set up test fixtures/mocks
- [ ] Write unit tests (if applicable)
- [ ] Write widget tests (if UI)
- [ ] Write integration tests (if workflow)
- [ ] Test edge cases
- [ ] Test error scenarios
- [ ] Verify coverage improvement
- [ ] Run flutter test --coverage && flutter analyze

## Acceptance Criteria
- [ ] All scenarios have coverage
- [ ] Tests follow project patterns
- [ ] Edge cases covered
- [ ] Error scenarios tested
- [ ] All tests pass consistently
- [ ] Coverage improved by [X]%

## Technical Notes
- **Component under test:** [path]
- **Testing pattern:** [guide reference]
- **Test helpers:** [MockDatabaseHelper, etc.]
- **Coverage before:** [X]%
- **Coverage target:** [Y]%

## Test Cases
- Happy path: [main workflow]
- Edge cases: [list]
- Error scenarios: [list]
```

**Labels:** `testing`, `[priority]`

**Story points:** 1-3 depending on scope

---

## Documentation Issue Template

```markdown
## Context
[What documentation is missing or needs improvement]

## Current State
[What exists now]

## Expected State
[What documentation should include]

## Tasks
- [ ] Research topic/functionality
- [ ] Write documentation
- [ ] Add examples/code samples
- [ ] Review for accuracy
- [ ] Review for completeness
- [ ] Add to appropriate location

## Acceptance Criteria
- [ ] Documentation is clear and complete
- [ ] Examples are accurate
- [ ] Formatting is consistent
- [ ] Links work correctly
- [ ] Technically accurate

## Technical Notes
- **Location:** [docs/ or README or code comments]
- **Format:** [Markdown, inline comments, etc.]
- **Related docs:** [other documentation to reference]

## Review Checklist
- Clear and concise
- Technically accurate
- Complete coverage of topic
- Good examples
```

**Labels:** `documentation`, `P3-Low` (typically)

**Story points:** 1-2

---

## Minimal Issue Template (Quick Bugs)

For very simple, obvious bugs that don't need extensive documentation:

```markdown
## Problem
[One sentence: what's broken]

## Steps to Reproduce
1. [Step]
2. [Step]
3. See error

## Expected
[What should happen]

## Fix
[Where to fix and how]

## Tasks
- [ ] Fix
- [ ] Test
- [ ] Verify
```

**Use this only for P3-Low, obvious, 1-2 point bugs.**

---

## Template Selection Guide

| Situation | Template | Why |
|-----------|----------|-----|
| Something doesn't work | Bug | Clear steps to reproduce |
| Want to add capability | Enhancement | New functionality |
| Code is messy/duplicated | Technical Debt | Refactoring needed |
| Missing test coverage | Testing | Gap in tests |
| Documentation unclear | Documentation | Docs need work |
| Quick obvious fix | Minimal | Don't over-document simple fixes |

---

## Common Sections Explained

### Context
**Purpose:** Explain why this issue matters
**Good:** "Users report they can't save recipes with many ingredients because the save button is off-screen"
**Bad:** "Save button problem"

### Current Behavior
**Purpose:** Describe what happens now (bugs) or what's missing (features)
**Good:** "When adding 15+ ingredients, the dialog doesn't scroll and the save button at the bottom is inaccessible"
**Bad:** "Scrolling is broken"

### Expected Behavior
**Purpose:** Describe the desired outcome
**Good:** "Dialog should scroll to show all content and keep save button accessible regardless of ingredient count"
**Bad:** "Fix the scrolling"

### Proposed Solution
**Purpose:** Provide technical direction for implementation
**Good:** "Wrap ingredient list in SingleChildScrollView with proper constraints, or use a ListView.builder"
**Bad:** "Make it work"

### Tasks
**Purpose:** Break work into actionable steps
**Include:** Analysis, implementation, testing, documentation
**Don't forget:** Localization (if UI), flutter analyze, flutter test

### Acceptance Criteria
**Purpose:** Define "done" - how we know it's complete
**Good:** Specific, testable, complete
**Bad:** Vague or incomplete

### Technical Notes
**Purpose:** Provide implementation context
**Include:** File paths, related issues, patterns to follow, dependencies
**Help:** Speed up implementation by providing context

### Test Cases
**Purpose:** Specify what should be tested
**Include:** Main workflow, edge cases, error scenarios
**Reference:** Testing guides when applicable
