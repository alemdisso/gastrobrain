# Debugging Report Template

Use this template to document debugging investigations and fixes.

---

## Template

```markdown
# Debugging Report

**Date:** YYYY-MM-DD
**Test:** [test file:line - "test name"]
**Issue:** [brief description of the failure]
**Severity:** [Critical / Important / Investigate]

## Failure Details

**Error Message:**
```
[Complete error message]
```

**Stack Trace (key frames):**
```
[Relevant stack trace]
```

**Failure Type:** [Null safety / Timeout / Expectation mismatch / Widget not found / Other]

## Root Cause Analysis

### Hypothesis

**Primary hypothesis:** [What we thought caused the failure]
**Evidence:** [What pointed to this cause]
**Likelihood:** [High / Medium / Low]

### Investigation

| Step | Action | Finding | Verdict |
|------|--------|---------|---------|
| 1 | [What was checked] | [What was found] | [Confirms/Rejects] |
| 2 | [What was checked] | [What was found] | [Confirms/Rejects] |
| 3 | [What was checked] | [What was found] | [Confirms/Rejects] |

### Confirmed Root Cause

[Detailed explanation of the actual root cause]

## Fix Applied

**Fix Type:** [Code fix / Test fix / Setup fix / Both]

**Files Modified:**
- [file 1]: [what changed]
- [file 2]: [what changed]

**Changes Summary:**
[Brief description of what was changed and why]

## Validation

| Phase | Scope | Result |
|-------|-------|--------|
| 1 - Original test | [test name] | [PASS/FAIL] |
| 2 - Same file | [X/X pass] | [PASS/FAIL] |
| 3 - Component | [X/X pass] | [PASS/FAIL] |
| 4 - Full suite | [X/X pass] | [PASS/FAIL] |

**Regression Check:** [Clean / Issues found]

## Lessons Learned

- [What we learned from this failure]
- [How to prevent similar failures]
- [Pattern to recognize in the future]

## Related

- **Issue:** #[XXX] (if related to a GitHub issue)
- **Pattern:** [Reference to failure_patterns.md if applicable]
- **Similar past failures:** [References if any]
```

---

## Usage Notes

- Create a report for each non-trivial debugging session
- The "Lessons Learned" section helps prevent future occurrences
- Reference failure patterns to build institutional knowledge
- Keep reports concise but complete enough to be useful later
