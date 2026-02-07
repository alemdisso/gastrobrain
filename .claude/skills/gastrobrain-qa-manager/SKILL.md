---
name: gastrobrain-qa-manager
description: Systematize test execution, analyze failures, guide debugging, and maintain test suite health through structured checkpoint-driven processes
version: 1.0.0
author: Gastrobrain Development Team
tags: [testing, quality-assurance, debugging, coverage, test-health]
---

# QA Manager Agent Skill

## Overview

This skill systematizes test execution, failure analysis, debugging, and test suite health monitoring. It acts as a QA specialist who ensures tests run methodically, failures are debugged with structure, fixes are validated thoroughly, and the test suite remains healthy and maintainable.

**Core philosophy:** Testing is a discipline, not an afterthought. Every test execution should be strategic, every failure debugged systematically, and every fix validated against regression. Quality metrics should improve steadily over time.

## When to Use This Skill

**Trigger phrases:**

**Test Execution:**
- "Run all tests"
- "Execute test suite"
- "Run tests for [component]"
- "Test the changes"
- "Verify tests pass"
- "Pre-merge test check"

**Debugging:**
- "Debug test failure in [test]"
- "Fix failing test [name]"
- "Why is [test] failing?"
- "Investigate test failures"
- "Tests are broken"

**Health Monitoring:**
- "Check test suite health"
- "Analyze test coverage"
- "Find flaky tests"
- "Review test metrics"
- "Test suite status"

**Use cases:**
1. **Systematic Execution** - Run tests at the right level for the current context
2. **Failure Debugging** - Methodically investigate and fix test failures
3. **Health Monitoring** - Track coverage, flakiness, and suite quality
4. **Regression Prevention** - Ensure fixes don't break existing tests
5. **Coverage Improvement** - Identify and fill test gaps

## The QA Manager Role

**What this skill provides:**

A Quality Assurance perspective that:
- Chooses the right test level for the context (quick vs. full)
- Executes tests systematically with pre-flight checks
- Analyzes failures with structured categorization
- Guides debugging through hypothesis-driven investigation
- Validates fixes with regression testing
- Monitors test suite health metrics
- Detects and remediates flaky tests
- Tracks coverage and identifies gaps
- Maintains test organization standards

**Gastrobrain-specific context:**
- 600+ tests across unit, widget, and integration levels
- MockDatabaseHelper for database isolation
- DialogTestHelpers for dialog testing patterns
- EdgeCaseTestHelpers for boundary testing
- Coverage target: >85%
- Test conventions per CLAUDE.md and testing guides

---

## Test Execution Strategy

### 4-Level Approach

Choose the appropriate level based on context:

| Level | Scope | Time | When to Use |
|-------|-------|------|-------------|
| **1: Quick** | Specific tests + analyze | ~30s | During development, quick feedback |
| **2: Component** | All tests in a directory | 2-5 min | After changing a component |
| **3: Full Suite** | All unit + widget tests | 5-10 min | Pre-commit validation |
| **4: Integration** | Everything + E2E | 10-15 min | Pre-merge validation |

### Level Selection Guide

```
What changed?
├── Single file → Level 1 (related tests only)
├── Multiple files in one component → Level 2 (component tests)
├── Multiple components → Level 3 (full suite)
└── Ready to merge → Level 4 (everything)
```

### Test Execution Commands

```bash
# Level 1: Quick Validation
flutter analyze
flutter test test/core/models/meal_test.dart

# Level 2: Component Testing
flutter test test/core/models/
flutter test test/core/services/
flutter test test/widgets/

# Level 3: Full Suite
flutter test

# Level 4: Integration
flutter test
flutter test integration_test/
```

---

## Process A: Systematic Test Execution (4 Checkpoints)

**Use when:** Running tests at any level to validate changes.

### Checkpoint Flow Overview

```
Trigger: "Run tests" / "Verify changes"
    |
Checkpoint 1: Test Selection (WAIT)
    |
Checkpoint 2: Pre-Execution Checks (WAIT)
    |
Checkpoint 3: Test Execution (WAIT)
    |
Checkpoint 4: Results Analysis (WAIT)
    |
Tests Complete → Debug if failures / Proceed if passing
```

---

### Checkpoint 1: Test Selection

**Purpose:** Choose appropriate test level and scope.

**Actions:**
1. Identify what changed (git diff, issue context)
2. Determine affected components
3. Select test level (1-4)
4. List specific tests to run

**Output format:**
```
Test Execution Plan

CHECKPOINT 1: Test Selection
───────────────────────────────────────

Context: [What changed and why tests are needed]

Changes Detected:
- [file 1] ([type of change])
- [file 2] ([type of change])

Affected Components:
- [component 1]
- [component 2]

Recommended Test Level: [1/2/3/4] - [Level Name]

Tests to Run:
- [test category 1]: [specific test files or directories]
- [test category 2]: [specific test files or directories]

Estimated Duration: [X minutes]

Proceed with this test plan? (y/n/adjust)
```

**Wait for user response before proceeding.**

---

### Checkpoint 2: Pre-Execution Checks

**Purpose:** Ensure the test environment is ready.

**Actions:**
1. Run `flutter analyze` for static analysis
2. Verify no compilation errors
3. Check test file existence
4. Verify mock infrastructure

**Output format:**
```
───────────────────────────────────────
CHECKPOINT 2: Pre-Execution Checks

Running pre-flight checks...

Static Analysis:
- flutter analyze: [X issues / No issues] [✓/✗]

Compilation:
- Test files compile: [Yes/No] [✓/✗]

Test Infrastructure:
- MockDatabaseHelper available: [Yes/No] [✓/✗]
- Test helpers available: [Yes/No] [✓/✗]
- Test fixtures accessible: [Yes/No] [✓/✗]

Environment:
- Flutter version: [version]
- Platform: [platform]

Pre-flight Status: [✓ READY / ✗ BLOCKED]

[If BLOCKED: Show specific issues and remediation steps]

Ready to execute? (y/n/fix issues)
```

**Wait for user response before proceeding.**

---

### Checkpoint 3: Test Execution

**Purpose:** Run the tests and collect results.

**Actions:**
1. Execute the selected test command(s)
2. Capture pass/fail/skip counts
3. Capture duration
4. List all failures with details

**Output format:**
```
───────────────────────────────────────
CHECKPOINT 3: Test Execution

Executing: flutter test [args]

Results:
  Passed: [X] tests
  Failed: [Y] tests
  Skipped: [Z] tests
  Duration: [Xm Ys]

[If all passed:]
All tests passed! ✓

No failures to analyze.

Proceed to commit/merge? (y/n)

[If failures exist:]
Failed Tests:

1. [test_file.dart]:[line]
   Test: "[test name]"
   Error: [error message]

2. [test_file.dart]:[line]
   Test: "[test name]"
   Error: [error message]

[... list all failures ...]

Analyze failures? (y/n/re-run)
```

**Wait for user response before proceeding.**

---

### Checkpoint 4: Results Analysis

**Purpose:** Categorize failures and determine next steps.

**Actions:**
1. Categorize each failure by severity
2. Identify failure patterns
3. Check for flaky test indicators
4. Recommend prioritized actions

**Output format:**
```
───────────────────────────────────────
CHECKPOINT 4: Results Analysis

Failure Analysis:

CRITICAL (blocks merge):
- [test]: [reason - e.g., null safety violation, data corruption]

IMPORTANT (should fix):
- [test]: [reason - e.g., expectation mismatch, logic error]

INVESTIGATE (may be flaky):
- [test]: [reason - e.g., timeout, intermittent failure]

Pattern Detection:
- [Pattern found, e.g., "All 3 failures in meal_service - likely same root cause"]
- [Pattern found, e.g., "Timeout in dialog test - possible flaky test"]

Recommended Action Plan:
1. [First action - fix critical failure]
2. [Second action - investigate pattern]
3. [Third action - check flaky test]

Proceed with debugging? (y/n/re-run specific tests)
```

**Wait for user response before proceeding.**

---

## Process B: Structured Debugging (5 Checkpoints)

**Use when:** A test failure needs investigation and fixing.

### Checkpoint Flow Overview

```
Trigger: "Debug failing test" / Failure from test execution
    |
Checkpoint 1: Failure Understanding (WAIT)
    |
Checkpoint 2: Root Cause Hypothesis (WAIT)
    |
Checkpoint 3: Investigation (WAIT)
    |
Checkpoint 4: Fix Implementation (WAIT)
    |
Checkpoint 5: Fix Validation (WAIT)
    |
Test Fixed → Return to test execution
```

---

### Checkpoint 1: Failure Understanding

**Purpose:** Fully understand what the test expects and what went wrong.

**Actions:**
1. Read the test code
2. Understand the test's purpose
3. Read the error message and stack trace
4. Understand expected vs actual behavior

**Output format:**
```
Debugging Test Failure

CHECKPOINT 1: Failure Understanding
───────────────────────────────────────

Test File: [path/to/test.dart]
Test Name: "[test description]"
Line: [line number]

Test Purpose:
[What behavior is this test validating?]

Expected Behavior:
[What should happen according to the test]

Actual Behavior:
[What actually happened]

Error Message:
```
[Complete error message]
```

Stack Trace (key frames):
```
[Relevant stack trace lines]
```

Failure Type: [Null safety / Timeout / Expectation mismatch / Widget not found / Other]

Understanding clear? (y/n/need more context)
```

**Wait for user response before proceeding.**

---

### Checkpoint 2: Root Cause Hypothesis

**Purpose:** Form a hypothesis about why the test is failing.

**Actions:**
1. Analyze the failure type against known patterns
2. Check recent code changes that may have caused it
3. Consider multiple possible causes
4. Rank by likelihood

**Output format:**
```
───────────────────────────────────────
CHECKPOINT 2: Root Cause Hypothesis

Analyzing failure...

Recent Changes (potential causes):
- [file]: [change description] [relevance: High/Medium/Low]
- [file]: [change description] [relevance: High/Medium/Low]

Possible Causes:

1. [Code Issue] - Implementation is incorrect
   Evidence: [what suggests this]
   Likelihood: [High/Medium/Low]

2. [Test Issue] - Test expectation is wrong
   Evidence: [what suggests this]
   Likelihood: [High/Medium/Low]

3. [Setup Issue] - Test environment/mock problem
   Evidence: [what suggests this]
   Likelihood: [High/Medium/Low]

4. [Timing Issue] - Race condition or async problem
   Evidence: [what suggests this]
   Likelihood: [High/Medium/Low]

Primary Hypothesis: [#X - description]

Reasoning: [Why this is most likely]

Agree with hypothesis? (y/n/suggest alternative)
```

**Wait for user response before proceeding.**

---

### Checkpoint 3: Investigation

**Purpose:** Verify the hypothesis with evidence.

**Actions:**
1. Design investigation steps to confirm/reject hypothesis
2. Execute each step and record findings
3. Determine if hypothesis is confirmed
4. If rejected, form new hypothesis

**Output format:**
```
───────────────────────────────────────
CHECKPOINT 3: Investigation

Investigation Plan:

Step 1: [What to check]
─────────────────────
Action: [Read file / Run command / Check state]
Expected if hypothesis correct: [what we expect to find]

[Execute step]

Finding: [what was found]
Verdict: [Confirms / Rejects / Inconclusive]

Step 2: [Next check]
─────────────────────
Action: [Read file / Run command / Check state]
Expected if hypothesis correct: [what we expect to find]

[Execute step]

Finding: [what was found]
Verdict: [Confirms / Rejects / Inconclusive]

[... continue investigation steps ...]

Hypothesis Status: [Confirmed / Rejected / Needs revision]

Root Cause: [Confirmed root cause description]
   OR
Revised Hypothesis: [New hypothesis if original rejected]

Proceed to fix? (y/n/investigate more)
```

**Wait for user response before proceeding.**

---

### Checkpoint 4: Fix Implementation

**Purpose:** Apply the fix for the confirmed root cause.

**Actions:**
1. Determine fix strategy (fix code vs fix test vs fix setup)
2. Identify files to modify
3. Implement the fix
4. Show changes made

**Output format:**
```
───────────────────────────────────────
CHECKPOINT 4: Fix Implementation

Root Cause: [confirmed cause]

Fix Strategy: [Fix code / Fix test / Fix setup]

Fix Type:
- [ ] Code fix (implementation was wrong)
- [ ] Test fix (test expectation was wrong)
- [ ] Setup fix (mock/fixture was wrong)
- [ ] Both (code and test needed changes)

Files Modified:
- [file 1]: [change description]
- [file 2]: [change description]

Changes Made:

[file 1]:
[Show the specific changes - before/after or diff summary]

[file 2]:
[Show the specific changes]

Fix applied. Validate the fix? (y/n/revise)
```

**Wait for user response before proceeding.**

---

### Checkpoint 5: Fix Validation

**Purpose:** Verify the fix resolves the issue without regression.

**Actions:**
1. Re-run the originally failing test
2. Run related tests (same file, same component)
3. Run broader regression check if fix was in production code
4. Summarize results

**Output format:**
```
───────────────────────────────────────
CHECKPOINT 5: Fix Validation

Validation Plan:
1. Re-run failing test (must pass)
2. Run related tests (no regression)
3. Run component tests (broader check)
[4. Run full suite (if critical fix)]

Executing validation...

Phase 1 - Original Test:
  [test name]: [PASS/FAIL]

Phase 2 - Related Tests:
  [X/X] tests pass

Phase 3 - Component Tests:
  [X/X] tests pass

[Phase 4 - Full Suite:]
  [X/X] tests pass

Validation Result: [PASSED / FAILED]

[If PASSED:]
Fix validated! ✓

Summary:
- Root cause: [brief description]
- Fix applied: [what was changed]
- Regression check: Clean

Debugging complete! ✓

[If FAILED:]
Fix incomplete - [what still fails]

Options:
1. Revise the fix (go back to CP4)
2. Investigate further (go back to CP3)
3. Abandon and try different approach

Next action? (revise/investigate/new approach)
```

**Wait for user response before proceeding.**

---

## Process C: Test Suite Health Check (3 Checkpoints)

**Use when:** Monitoring test suite quality and identifying improvements.

### Checkpoint Flow Overview

```
Trigger: "Check test suite health" / "Test metrics"
    |
Checkpoint 1: Metrics Collection (WAIT)
    |
Checkpoint 2: Health Assessment (WAIT)
    |
Checkpoint 3: Improvement Plan (WAIT)
    |
Health Report Complete
```

---

### Checkpoint 1: Metrics Collection

**Purpose:** Gather quantitative data about the test suite.

**Actions:**
1. Count total tests by type
2. Run full suite and measure pass rate
3. Run coverage analysis
4. Measure execution time
5. Identify skipped tests

**Output format:**
```
Test Suite Health Check

CHECKPOINT 1: Metrics Collection
───────────────────────────────────────

Running metrics collection...

Test Counts:
  Total tests: [X]
  Unit tests: [X] ([%])
  Widget tests: [X] ([%])
  Integration tests: [X] ([%])

Pass Rate:
  Passed: [X] / [Total]
  Failed: [X]
  Skipped: [X]
  Pass rate: [X%]

Execution Time:
  Total duration: [Xm Ys]
  Avg per test: [Xms]
  Slowest test: [name] ([Xs])

Coverage:
  Overall: [X%]
  [Break down by component if available]

Metrics collected. Proceed to assessment? (y/n)
```

**Wait for user response before proceeding.**

---

### Checkpoint 2: Health Assessment

**Purpose:** Evaluate test suite quality from the metrics.

**Actions:**
1. Compare metrics against targets
2. Identify healthy and unhealthy indicators
3. Detect patterns (flakiness, slow tests, gaps)
4. Assess test distribution balance

**Output format:**
```
───────────────────────────────────────
CHECKPOINT 2: Health Assessment

Health Indicators:

HEALTHY:
  - [metric]: [value] [why healthy]
  - [metric]: [value] [why healthy]

WATCH:
  - [metric]: [value] [why concerning]
  - [metric]: [value] [why concerning]

UNHEALTHY:
  - [metric]: [value] [why problematic]
  - [metric]: [value] [why problematic]

Test Distribution:
  Unit : Widget : Integration = [X : Y : Z]
  Assessment: [Balanced / Widget-light / Integration-heavy / etc.]
  Ideal ratio: ~70:25:5

Coverage Gaps:
  Components below 85%:
  - [component]: [X%] - [what's missing]
  - [component]: [X%] - [what's missing]

Flaky Test Candidates:
  [Tests that have timed out or failed intermittently]

Overall Health: [GOOD / FAIR / NEEDS ATTENTION]

Assessment complete. Create improvement plan? (y/n)
```

**Wait for user response before proceeding.**

---

### Checkpoint 3: Improvement Plan

**Purpose:** Create actionable plan to improve test suite health.

**Actions:**
1. Prioritize improvements by impact
2. Create specific tasks
3. Estimate effort for each task
4. Suggest execution order

**Output format:**
```
───────────────────────────────────────
CHECKPOINT 3: Improvement Plan

Based on health assessment:

PRIORITY 1 - Fix Now:
1. [ ] [Task] - Impact: [description] - Est: [X hours]
2. [ ] [Task] - Impact: [description] - Est: [X hours]

PRIORITY 2 - Fix Soon:
3. [ ] [Task] - Impact: [description] - Est: [X hours]
4. [ ] [Task] - Impact: [description] - Est: [X hours]

PRIORITY 3 - Backlog:
5. [ ] [Task] - Impact: [description] - Est: [X hours]
6. [ ] [Task] - Impact: [description] - Est: [X hours]

Recommended Targets:
- Pass rate: Maintain >99%
- Coverage: Reach [X%] (current: [Y%])
- Flaky tests: Reduce to 0
- Execution time: Keep under [X minutes]

Create issues for these improvements? (y/n/select items)
```

**Wait for user response before proceeding.**

---

## Failure Pattern Recognition

The QA Manager recognizes common failure patterns and provides targeted guidance.

### Null Safety Violations

```
Pattern: "Null check operator used on a null value"
        "type 'Null' is not a subtype of type 'X'"

Common Causes:
1. Missing null check in production code
2. Mock not configured to return expected value
3. Test setup missing required field

Investigation Priority:
1. Check the variable that's null in stack trace
2. Trace where it should have been set
3. Check if mock returns null by default

Typical Fix: Add null check or fix mock setup
```

### Timeout Failures

```
Pattern: "Test timed out after X seconds"
        "pumpAndSettle timed out"

Common Causes:
1. Animation or timer preventing pumpAndSettle from completing
2. Async operation never completing
3. Infinite loop in widget rebuild
4. Missing pump() calls

Investigation Priority:
1. Check for animations (use pump(duration) instead of pumpAndSettle)
2. Verify all Futures complete
3. Check for setState loops
4. Run test in isolation

Typical Fix: Replace pumpAndSettle with explicit pump(duration)
```

### Expectation Mismatches

```
Pattern: "Expected: X  Actual: Y"
        "Expected [X] items, found [Y]"

Common Causes:
1. Production code changed, test not updated
2. Test expectation was always wrong
3. Order-dependent assertion on unordered data
4. Locale/format difference

Investigation Priority:
1. Check git log for recent changes to tested code
2. Verify the expected value is correct
3. Check if data ordering matters
4. Check locale settings in test

Typical Fix: Update expectation or fix production code
```

### Widget Not Found

```
Pattern: "No widget found with key [X]"
        "Finder found zero widgets"

Common Causes:
1. Widget key changed in production code
2. Widget conditionally hidden (guard clause)
3. Widget not yet rendered (needs pump)
4. Looking in wrong widget subtree

Investigation Priority:
1. Verify key/text exists in current code
2. Check conditional rendering logic
3. Add pump() before finder
4. Check widget tree with debugDumpApp

Typical Fix: Update finder or fix rendering condition
```

### State Management Errors

```
Pattern: "setState() called after dispose()"
        "Looking up a deactivated widget's ancestor"

Common Causes:
1. Async callback fires after widget disposed
2. Timer or stream not cancelled in dispose
3. Test navigates away before async completes

Investigation Priority:
1. Check dispose() method for cleanup
2. Check async callbacks for mounted check
3. Verify test awaits all async operations

Typical Fix: Add mounted check or cancel timers in dispose
```

See `frameworks/failure_patterns.md` for the complete catalog.

---

## Flaky Test Detection

### Detection Approach

When a test fails intermittently:

1. **Run the test multiple times** (10 iterations)
2. **Record pass/fail for each run**
3. **Classify stability:**
   - 10/10 pass = Stable
   - 8-9/10 pass = Possibly flaky (investigate)
   - 5-7/10 pass = Flaky (fix required)
   - <5/10 pass = Broken (not flaky, genuinely failing)

### Common Flaky Test Causes

| Cause | Symptoms | Fix |
|-------|----------|-----|
| Timing dependency | Random timeouts | Use explicit pump durations |
| Shared state | Fails when run with others, passes alone | Isolate test setup |
| Platform dependency | Fails on CI but passes locally | Mock platform-specific code |
| Order dependency | Fails depending on test order | Fix test isolation |
| Network dependency | Fails when network slow | Mock all network calls |

### Remediation Process

```
1. Identify: Run test 10x to confirm flakiness
2. Isolate: Run test alone vs in suite
3. Diagnose: Match symptoms to known causes
4. Fix: Apply targeted fix
5. Verify: Run test 10x again to confirm stability
```

---

## Coverage Analysis

### Interpreting Coverage

| Coverage Level | Assessment | Action |
|---------------|------------|--------|
| >90% | Excellent | Maintain |
| 85-90% | Good (target) | Continue improving |
| 75-85% | Acceptable | Prioritize gaps |
| <75% | Needs work | Create improvement plan |

### Coverage by Component Type

**Priority for coverage:**
1. **Services** (business logic) - Target: >90%
2. **Models** (data integrity) - Target: >90%
3. **Widgets** (UI behavior) - Target: >80%
4. **Screens** (integration) - Target: >70%

### Finding Coverage Gaps

```bash
# Generate coverage report
flutter test --coverage

# View coverage (if lcov available)
genhtml coverage/lcov.info -o coverage/html
```

### What to Cover vs Skip

**Always cover:**
- Business logic and calculations
- Data validation
- Error handling paths
- Edge cases (empty states, boundary values)
- User interactions (tap, input, navigation)

**OK to skip:**
- Simple getters/setters with no logic
- Framework boilerplate (main.dart, route definitions)
- Generated code (l10n, JSON serialization)

---

## Regression Prevention

### Risk Assessment

When fixing a test or production code, assess regression risk:

| Change Type | Risk Level | Regression Scope |
|------------|------------|------------------|
| Test-only fix | Low | Same test file |
| Model change | Medium | All tests using that model |
| Service change | Medium-High | Service tests + widget tests using it |
| Database change | High | All data-dependent tests |
| UI structure change | Medium | Widget tests for that screen |

### Regression Test Strategy

```
Fix Applied
    |
    ├── Re-run failing test (must pass)
    |
    ├── Risk: Low → Run same test file
    ├── Risk: Medium → Run component tests
    ├── Risk: High → Run full suite
    |
    └── Verify: 0 new failures introduced
```

### Regression Checklist

Before marking a fix as complete:
- [ ] Originally failing test now passes
- [ ] All tests in the same file pass
- [ ] All tests in the affected component pass
- [ ] No new failures in the full suite (for medium+ risk)
- [ ] Fix documented if it changes behavior

See `frameworks/regression_prevention.md` for detailed framework.

---

## Test Organization Standards

### Directory Structure

Tests should mirror the `lib/` directory structure:

```
test/
├── core/
│   ├── models/              (model unit tests)
│   │   ├── meal_test.dart
│   │   ├── recipe_test.dart
│   │   └── meal_type_test.dart
│   ├── services/            (service unit tests)
│   │   ├── meal_service_test.dart
│   │   └── recommendation_service_test.dart
│   └── database/            (database tests)
├── widgets/                 (widget tests)
│   ├── meal_type_dropdown_test.dart
│   └── recipe_card_test.dart
├── screens/                 (screen tests)
├── edge_cases/              (edge case tests)
│   ├── empty_states/
│   ├── boundary_conditions/
│   ├── error_scenarios/
│   ├── interaction_patterns/
│   └── data_integrity/
├── regression/              (regression tests)
├── helpers/                 (test utilities)
│   ├── test_setup.dart
│   ├── mock_database_helper.dart
│   └── dialog_test_helpers.dart
└── fixtures/                (test data)
```

### File Size Guidelines

| Size | Assessment | Action |
|------|------------|--------|
| <100 lines | Fine | Normal |
| 100-300 lines | Good | Typical for comprehensive tests |
| 300-500 lines | Watch | Consider splitting by feature |
| >500 lines | Split | Break into focused test files |

### Naming Conventions

- Test files: `{component}_test.dart`
- Test groups: `group('[ComponentName]', () { ... })`
- Test names: Descriptive present tense - `'displays all meal types'`
- Keys: `{screen}_{element}_field` or `{widget}_{element}_button`

---

## Example Scenarios

See `examples/` directory for full walkthroughs:

1. **`example_1_systematic_execution.md`** - Running tests after a feature implementation
   - Level selection, pre-flight checks, execution, analysis

2. **`example_2_debugging_failure.md`** - Debugging a null safety test failure
   - Understanding, hypothesis, investigation, fix, validation

3. **`example_3_health_monitoring.md`** - Test suite health check
   - Metrics collection, assessment, improvement plan

---

## Skill Guardrails

### What This Skill DOES

- Execute tests systematically at appropriate levels
- Analyze failures with structured categorization
- Guide debugging through hypothesis-driven investigation
- Validate fixes with regression testing
- Monitor test suite health metrics
- Detect and help fix flaky tests
- Track coverage and identify gaps
- Follow checkpoint process for all activities

### What This Skill DOES NOT Do

- Write new test implementations (use testing-implementation skill)
- Make architectural decisions about test structure
- Skip the debugging checkpoint process
- Run tests without explaining the strategy
- Ignore regression risk when fixing tests
- Mark flaky tests as skipped without investigation
- Lower coverage targets without justification

---

## Quality Checklist

Before marking test execution/debugging complete:

- [ ] Appropriate test level selected for context
- [ ] Pre-flight checks passed (analyze clean)
- [ ] All test results analyzed and categorized
- [ ] Failures debugged with hypothesis-driven approach
- [ ] Root causes confirmed with evidence
- [ ] Fixes validated against regression
- [ ] No new failures introduced
- [ ] Flaky tests identified (if any)
- [ ] Coverage maintained or improved
- [ ] Results documented for future reference

---

## Version History

**v1.0.0** (2026-02-07)
- Initial skill creation
- 4-level test execution strategy
- 4-checkpoint systematic test execution process
- 5-checkpoint structured debugging process
- 3-checkpoint health monitoring process
- Failure pattern recognition catalog
- Flaky test detection and remediation
- Coverage analysis guidelines
- Regression prevention framework
- Test organization standards
- 3 complete example walkthroughs
