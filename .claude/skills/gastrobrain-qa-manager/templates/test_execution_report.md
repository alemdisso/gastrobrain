# Test Execution Report Template

Use this template to document test execution results.

---

## Template

```markdown
# Test Execution Report

**Date:** YYYY-MM-DD
**Context:** [What triggered this test run - e.g., "Post-implementation of #268"]
**Level:** [1: Quick / 2: Component / 3: Full Suite / 4: Integration]
**Branch:** [current branch name]

## Pre-Execution

**Static Analysis:**
- flutter analyze: [X issues / Clean]

**Changes Since Last Run:**
- [file 1]: [change summary]
- [file 2]: [change summary]

## Execution Summary

| Metric | Value |
|--------|-------|
| Total Tests | [X] |
| Passed | [X] |
| Failed | [X] |
| Skipped | [X] |
| Duration | [Xm Ys] |
| Pass Rate | [X%] |

## Results by Component

| Component | Total | Passed | Failed | Duration |
|-----------|-------|--------|--------|----------|
| Models | [X] | [X] | [X] | [Xs] |
| Services | [X] | [X] | [X] | [Xs] |
| Widgets | [X] | [X] | [X] | [Xs] |
| Integration | [X] | [X] | [X] | [Xs] |

## Failures

### Failure 1: [test name]

- **File:** [path:line]
- **Category:** [Critical / Important / Investigate]
- **Error:** [error message]
- **Likely Cause:** [brief assessment]
- **Action:** [Debug / Update test / Re-run]

### Failure 2: [test name]

[Repeat for each failure]

## Assessment

**Overall Status:** [PASS - Safe to proceed / FAIL - Needs debugging]

**Failures Categorized:**
- Critical: [X] (must fix before proceeding)
- Important: [X] (should fix soon)
- Investigate: [X] (may be flaky)

## Next Steps

1. [Action 1]
2. [Action 2]
3. [Action 3]
```

---

## Usage Notes

- Create a report for Level 3+ test runs
- Keep failure descriptions concise but actionable
- Categorize failures to prioritize debugging effort
- Reference this report when starting debugging process
