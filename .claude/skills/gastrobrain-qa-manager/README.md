# Gastrobrain QA Manager

Systematize test execution, analyze failures, guide debugging, and maintain test suite health through structured checkpoint-driven processes.

## Quick Start

```bash
# In Claude Code, invoke the skill:
/gastrobrain-qa-manager

# Or use trigger phrases:
"Run all tests"
"Debug test failure in meal_service_test"
"Check test suite health"
"Why is meal_type_dropdown_test failing?"
"Pre-merge test check"
```

The skill will:
1. Detect context type (execution, debugging, or health check)
2. Select appropriate test level and strategy
3. Run the checkpoint process with user confirmation
4. Provide structured analysis and actionable next steps

## Core Philosophy

**Systematic Quality: Strategic Execution -> Structured Debugging -> Continuous Improvement**

Never run tests randomly. Always choose the right level, analyze results methodically, and track quality over time.

## Three Processes

### Process A: Systematic Test Execution (4 Checkpoints)

```
CP1: Test Selection → CP2: Pre-Execution → CP3: Execute → CP4: Analyze Results
 └─ Choose level      └─ Pre-flight        └─ Run tests   └─ Categorize
    and scope            checks               & collect      failures
```

**Use when:** Running tests to validate changes at any stage.

### Process B: Structured Debugging (5 Checkpoints)

```
CP1: Understand → CP2: Hypothesize → CP3: Investigate → CP4: Fix → CP5: Validate
 └─ What failed    └─ Why it failed    └─ Verify cause    └─ Apply  └─ Regression
    & expected?       (ranked causes)     with evidence      fix       check
```

**Use when:** A test failure needs investigation and resolution.

### Process C: Health Monitoring (3 Checkpoints)

```
CP1: Collect Metrics → CP2: Assess Health → CP3: Improvement Plan
 └─ Counts, coverage,   └─ Compare against    └─ Prioritized
    pass rate, timing       targets               action items
```

**Use when:** Reviewing overall test suite quality.

## 4-Level Test Execution Strategy

| Level | Scope | Time | When |
|-------|-------|------|------|
| **1: Quick** | Specific tests + analyze | ~30s | During development |
| **2: Component** | Directory of tests | 2-5 min | After changing a component |
| **3: Full Suite** | All unit + widget | 5-10 min | Pre-commit |
| **4: Integration** | Everything + E2E | 10-15 min | Pre-merge |

## Failure Pattern Recognition

The skill recognizes common Flutter test failure patterns:

| Pattern | Symptoms | Quick Guide |
|---------|----------|-------------|
| **Null Safety** | `Null check operator used on null value` | Check mock setup, add null checks |
| **Timeout** | `Test timed out after X seconds` | Use pump(duration), check animations |
| **Expectation Mismatch** | `Expected: X  Actual: Y` | Check recent code changes |
| **Widget Not Found** | `Finder found zero widgets` | Verify key/text, add pump() |
| **State After Dispose** | `setState() called after dispose()` | Add mounted check |

See `frameworks/failure_patterns.md` for the complete catalog.

## Flaky Test Detection

```
Run test 10x → Classify stability → Fix root cause → Verify 10x
```

| Pass Rate | Classification | Action |
|-----------|---------------|--------|
| 10/10 | Stable | No action needed |
| 8-9/10 | Possibly flaky | Investigate |
| 5-7/10 | Flaky | Fix required |
| <5/10 | Broken | Not flaky, genuinely failing |

## Coverage Targets

| Component | Target | Priority |
|-----------|--------|----------|
| Services | >90% | Highest |
| Models | >90% | Highest |
| Widgets | >80% | High |
| Screens | >70% | Medium |
| Overall | >85% | Project target |

## Example Walkthroughs

### Example 1: Systematic Test Execution
**Scenario:** Running tests after implementing meal type feature
**Process:** 4 checkpoints - select level, pre-flight, execute, analyze
**See:** `examples/example_1_systematic_execution.md`

### Example 2: Debugging a Failure
**Scenario:** Null safety violation in meal_service_test
**Process:** 5 checkpoints - understand, hypothesize, investigate, fix, validate
**See:** `examples/example_2_debugging_failure.md`

### Example 3: Health Monitoring
**Scenario:** Quarterly test suite health review
**Process:** 3 checkpoints - collect metrics, assess, plan improvements
**See:** `examples/example_3_health_monitoring.md`

## Regression Prevention

```
Fix Applied → Re-run failing test → Run related tests → Run full suite (if high risk)
                    │                      │                      │
                Must pass             Must pass              Must pass
```

| Change Type | Risk | Regression Scope |
|------------|------|------------------|
| Test-only | Low | Same test file |
| Model | Medium | All tests using model |
| Service | Medium-High | Service + widget tests |
| Database | High | All data-dependent tests |

## When to Use This Skill

**Use when:**
- Running tests at any development stage
- Test failures need investigation
- Want structured debugging approach
- Monitoring test suite health
- Preparing for merge (regression check)
- Identifying flaky tests

**Don't use when:**
- Writing new tests (use testing-implementation)
- Reviewing code quality (use code-review)
- Planning test strategy (use issue-roadmap)
- Implementing features (use senior-dev-implementation)

## File Structure

```
gastrobrain-qa-manager/
├── SKILL.md                               # Complete skill documentation
├── README.md                              # This file
├── frameworks/
│   ├── test_execution_framework.md       # Systematic test running
│   ├── debugging_framework.md            # 5-checkpoint debugging
│   ├── failure_patterns.md               # Common failure types
│   └── regression_prevention.md          # Avoiding regressions
├── templates/
│   ├── test_execution_report.md          # Test run summary
│   ├── debugging_report.md               # Debug investigation
│   ├── health_report_template.md         # Suite health
│   └── coverage_report_template.md       # Coverage analysis
└── examples/
    ├── example_1_systematic_execution.md # Running tests
    ├── example_2_debugging_failure.md    # Fixing a test
    └── example_3_health_monitoring.md    # Tracking metrics
```

## References

- **SKILL.md**: Complete process documentation with all checkpoints
- **Frameworks**: Execution, debugging, patterns, and regression approaches
- **Templates**: Report formats for test activities
- **Examples**: Real-world walkthrough scenarios
- **CLAUDE.md**: Project testing conventions and patterns
- **docs/testing/**: Testing guides (dialog, edge case, mock)

---

**Version**: 1.0.0
**Last Updated**: February 2026
**Status**: Ready for use
