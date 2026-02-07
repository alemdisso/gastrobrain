# Coverage Report Template

Use this template for focused coverage analysis.

---

## Template

```markdown
# Coverage Analysis Report

**Date:** YYYY-MM-DD
**Trigger:** [Routine check / Pre-merge / Coverage improvement sprint]

## Overall Coverage

| Metric | Value | Target | Delta |
|--------|-------|--------|-------|
| Line coverage | [X%] | 85% | [+/-X%] |
| Branch coverage | [X%] | - | [+/-X%] |
| Function coverage | [X%] | - | [+/-X%] |

## Coverage by Directory

| Directory | Lines | Covered | Coverage | Target | Status |
|-----------|-------|---------|----------|--------|--------|
| lib/core/models/ | [X] | [X] | [X%] | 90% | [Met/Gap] |
| lib/core/services/ | [X] | [X] | [X%] | 90% | [Met/Gap] |
| lib/core/database/ | [X] | [X] | [X%] | 85% | [Met/Gap] |
| lib/widgets/ | [X] | [X] | [X%] | 80% | [Met/Gap] |
| lib/screens/ | [X] | [X] | [X%] | 70% | [Met/Gap] |

## Coverage Gaps

### Critical Gaps (0% coverage on important code)

| File | Lines Uncovered | Impact | Priority |
|------|----------------|--------|----------|
| [path] | [X lines] | [What's not tested] | [High] |

### Significant Gaps (<70% on important code)

| File | Coverage | Missing | Suggested Tests |
|------|----------|---------|----------------|
| [path] | [X%] | [What's not covered] | [What tests to add] |
| [path] | [X%] | [What's not covered] | [What tests to add] |

### Acceptable Gaps (intentionally uncovered)

| File | Coverage | Reason for Exclusion |
|------|----------|---------------------|
| [path] | [X%] | [Generated code / Framework boilerplate / etc.] |

## Uncovered Code Categories

| Category | Lines | % of Uncovered | Action |
|----------|-------|---------------|--------|
| Error handling paths | [X] | [X%] | Add error scenario tests |
| Edge cases | [X] | [X%] | Add boundary tests |
| UI-only code | [X] | [X%] | Add widget tests |
| Conditional branches | [X] | [X%] | Add conditional tests |
| Generated/boilerplate | [X] | [X%] | Exclude from targets |

## Improvement Plan

### Quick Wins (high coverage gain, low effort)

1. [ ] Add test for [uncovered method] in [file]
   - Lines gained: [X]
   - Coverage impact: +[X%]
   - Effort: [X hours]

2. [ ] Add error scenario test for [service]
   - Lines gained: [X]
   - Coverage impact: +[X%]
   - Effort: [X hours]

### Medium Effort

3. [ ] Add widget tests for [widget]
   - Lines gained: [X]
   - Coverage impact: +[X%]
   - Effort: [X hours]

### Larger Effort

4. [ ] Add integration tests for [screen]
   - Lines gained: [X]
   - Coverage impact: +[X%]
   - Effort: [X hours]

## Coverage Trend

| Date | Overall | Models | Services | Widgets | Screens |
|------|---------|--------|----------|---------|---------|
| [Date 1] | [X%] | [X%] | [X%] | [X%] | [X%] |
| [Date 2] | [X%] | [X%] | [X%] | [X%] | [X%] |
| Current | [X%] | [X%] | [X%] | [X%] | [X%] |

## Recommendations

1. **Target:** [Specific coverage target for next period]
2. **Focus area:** [Which component to improve first]
3. **Strategy:** [Quick wins first / Systematic component-by-component]
4. **Exclusions:** [What to intentionally exclude from targets]
```

---

## How to Generate Coverage Data

```bash
# Generate coverage report
flutter test --coverage

# View summary (if lcov tools available)
lcov --summary coverage/lcov.info

# Generate HTML report (if genhtml available)
genhtml coverage/lcov.info -o coverage/html

# View specific file coverage
lcov --extract coverage/lcov.info 'lib/core/services/*' --output-file /tmp/services.info
lcov --summary /tmp/services.info
```

---

## Usage Notes

- Run coverage analysis after each milestone or sprint
- Focus on coverage trends, not just absolute numbers
- Prioritize quick wins that increase coverage significantly
- Don't chase 100% - focus on meaningful coverage of business logic
- Exclude generated code and framework boilerplate from targets
