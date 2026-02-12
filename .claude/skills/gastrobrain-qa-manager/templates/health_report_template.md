# Test Suite Health Report Template

Use this template for periodic test suite health assessments.

---

## Template

```markdown
# Test Suite Health Report

**Date:** YYYY-MM-DD
**Period:** [Weekly / Monthly / Quarterly]
**Assessed by:** [Name / QA Manager skill]

## Executive Summary

**Overall Health:** [GOOD / FAIR / NEEDS ATTENTION]

Key findings:
- [Finding 1]
- [Finding 2]
- [Finding 3]

## Metrics

### Test Counts

| Category | Count | % of Total |
|----------|-------|------------|
| Unit Tests | [X] | [X%] |
| Widget Tests | [X] | [X%] |
| Integration Tests | [X] | [X%] |
| Edge Case Tests | [X] | [X%] |
| Regression Tests | [X] | [X%] |
| **Total** | **[X]** | **100%** |

### Pass Rate

| Run | Total | Passed | Failed | Skipped | Rate |
|-----|-------|--------|--------|---------|------|
| Current | [X] | [X] | [X] | [X] | [X%] |
| Previous | [X] | [X] | [X] | [X] | [X%] |
| Trend | [+/-X] | [+/-X] | [+/-X] | [+/-X] | [+/-X%] |

### Execution Time

| Metric | Value | Target | Status |
|--------|-------|--------|--------|
| Total duration | [Xm Ys] | <10 min | [Met/Not met] |
| Avg per test | [Xms] | <200ms | [Met/Not met] |
| Slowest test | [name] ([Xs]) | <5s | [Met/Not met] |

### Coverage

| Component | Current | Previous | Target | Status |
|-----------|---------|----------|--------|--------|
| Overall | [X%] | [X%] | >85% | [Met/Not met] |
| Models | [X%] | [X%] | >90% | [Met/Not met] |
| Services | [X%] | [X%] | >90% | [Met/Not met] |
| Widgets | [X%] | [X%] | >80% | [Met/Not met] |
| Screens | [X%] | [X%] | >70% | [Met/Not met] |

## Health Indicators

### Healthy

- [Indicator]: [Value] - [Why this is good]
- [Indicator]: [Value] - [Why this is good]

### Watch Areas

- [Indicator]: [Value] - [Why this needs attention]
- [Indicator]: [Value] - [Why this needs attention]

### Unhealthy

- [Indicator]: [Value] - [Why this is problematic]
- [Indicator]: [Value] - [Action needed]

## Flaky Tests

| Test | File | Stability | Symptoms | Status |
|------|------|-----------|----------|--------|
| [name] | [path] | [X/10] | [symptom] | [Investigating/Fixed/Known] |

## Test Distribution Analysis

**Current ratio:** Unit : Widget : Integration = [X : Y : Z]
**Ideal ratio:** ~70 : 25 : 5
**Assessment:** [Balanced / Needs more widget tests / Needs more integration tests]

## Trends

| Week | Tests | Pass Rate | Coverage | Duration |
|------|-------|-----------|----------|----------|
| [W-3] | [X] | [X%] | [X%] | [Xm] |
| [W-2] | [X] | [X%] | [X%] | [Xm] |
| [W-1] | [X] | [X%] | [X%] | [Xm] |
| Current | [X] | [X%] | [X%] | [Xm] |

**Trend Direction:** [Improving / Stable / Declining]

## Improvement Plan

### Priority 1 - Address Now

1. [ ] [Task] - Est: [X hours]
2. [ ] [Task] - Est: [X hours]

### Priority 2 - Address Soon

3. [ ] [Task] - Est: [X hours]
4. [ ] [Task] - Est: [X hours]

### Priority 3 - Backlog

5. [ ] [Task] - Est: [X hours]

## Next Review

**Date:** [YYYY-MM-DD]
**Focus areas:** [What to pay special attention to]
```

---

## Usage Notes

- Run health reports weekly during active development
- Compare against previous report to track trends
- Focus on trends rather than absolute numbers
- Use the improvement plan to create GitHub issues
- Keep historical reports for trend analysis
