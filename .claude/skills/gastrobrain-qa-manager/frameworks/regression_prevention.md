# Regression Prevention Framework

Systematic approach to ensuring fixes and changes don't break existing functionality.

---

## Core Principle

**Every fix has a blast radius.** The goal of regression prevention is to understand that radius and test accordingly.

---

## Risk Assessment Matrix

### By Change Type

| Change Type | Risk Level | Blast Radius | Required Validation |
|------------|------------|--------------|---------------------|
| Test-only fix | Low | Same test file | Re-run same file |
| Model field added | Medium | Tests using that model | Component tests |
| Model field changed | Medium-High | Tests using that model + widgets | Component + widget tests |
| Service method fixed | Medium | Service tests + dependent widgets | Component + dependent tests |
| Service behavior changed | High | All consumers of the service | Full suite |
| Database schema change | High | All data-dependent tests | Full suite |
| UI structure change | Medium | Widget tests for that screen | Screen tests |
| Navigation change | Medium-High | Widget + integration tests | Full suite |
| Dependency updated | High | Everything (unknown impact) | Full suite |

### By File Location

```
Changed file in:
├── test/ only
│   └── Risk: LOW → Re-run test file
│
├── lib/core/models/
│   └── Risk: MEDIUM → Run model tests + widget tests that use model
│
├── lib/core/services/
│   └── Risk: MEDIUM-HIGH → Run service tests + widget tests
│
├── lib/core/database/
│   └── Risk: HIGH → Run full suite
│
├── lib/widgets/
│   └── Risk: MEDIUM → Run widget tests for that widget + parent screens
│
├── lib/screens/
│   └── Risk: MEDIUM → Run screen tests + integration tests
│
└── pubspec.yaml
    └── Risk: HIGH → Run full suite
```

---

## Regression Test Protocol

### Phase 1: Direct Impact (Always Required)

Re-run the test that was fixed or the tests most directly affected.

```bash
# Re-run the specific test
flutter test test/path/to/test.dart --name="test name"

# Re-run the entire test file
flutter test test/path/to/test.dart
```

**Pass criteria:** All tests in the file pass, including the fixed test.

---

### Phase 2: Related Impact (Required for Medium+ Risk)

Run tests in the same component and direct dependents.

```bash
# Same component
flutter test test/core/services/

# Known dependents (identify from imports)
flutter test test/widgets/meal_recording_dialog_test.dart
flutter test test/widgets/edit_meal_recording_dialog_test.dart
```

**How to identify related tests:**
1. Check what imports the changed file
2. Check what tests use the same mock/fixture
3. Check tests in the same directory

---

### Phase 3: Full Regression (Required for High Risk)

Run the complete test suite.

```bash
flutter test
```

**Pass criteria:** Zero new failures compared to before the fix.

---

### Phase 4: Integration Regression (Required for Database/Navigation Changes)

Run integration tests after full suite passes.

```bash
flutter test integration_test/
```

---

## Regression Checklist

Use this checklist after applying any fix:

```
Regression Validation for: [description of fix]

Change Risk: [Low / Medium / High]

Phase 1 - Direct Impact:
  [ ] Fixed test passes
  [ ] All tests in same file pass
  Result: [PASS / FAIL]

Phase 2 - Related Impact (if Medium+ risk):
  [ ] Component tests pass
  [ ] Dependent widget tests pass
  Result: [PASS / FAIL]

Phase 3 - Full Regression (if High risk):
  [ ] All unit tests pass
  [ ] All widget tests pass
  Total: [X/Y tests pass]
  Result: [PASS / FAIL]

Phase 4 - Integration (if Database/Navigation):
  [ ] Integration tests pass
  Result: [PASS / FAIL]

Overall: [CLEAN / REGRESSION FOUND]
```

---

## What to Do When Regression Found

### New failure in the same component

**Likely cause:** Fix is incomplete or has a side effect in related code.

**Action:**
1. Check if the new failure is related to the fix
2. Extend the fix to cover the new failure
3. Re-validate from Phase 1

### New failure in a different component

**Likely cause:** Fix changed shared behavior that another component depends on.

**Action:**
1. Understand why the other component fails
2. Determine if the other component's expectation is correct
3. Either extend the fix or update the other test
4. Re-validate from Phase 1

### Many new failures

**Likely cause:** Fix broke something fundamental (shared utility, base class, database schema).

**Action:**
1. STOP - Don't try to fix all failures individually
2. Review the fix for unintended broad impact
3. Consider if the approach is correct
4. May need to revert and try a different approach

---

## Prevention Strategies

### Before Making Changes

1. **Run related tests first** - Know the baseline before changing code
2. **Understand the dependency tree** - What depends on what you're changing?
3. **Check for shared utilities** - Changes to helpers affect all consumers
4. **Consider backward compatibility** - Can you add without changing existing behavior?

### While Making Changes

1. **Change one thing at a time** - Don't batch unrelated changes
2. **Run tests after each change** - Catch regressions early
3. **Preserve existing behavior** - Don't change signatures unnecessarily
4. **Use deprecation** - Mark old behavior as deprecated before removing

### After Making Changes

1. **Run regression protocol** - Follow the phases above
2. **Compare test counts** - Same number of tests should pass
3. **Check for skipped tests** - Don't accidentally skip tests
4. **Document behavior changes** - If fix changes behavior, update docs

---

## Common Regression Traps

| Trap | Description | Prevention |
|------|-------------|------------|
| Silent null | Changed return type to nullable, callers don't check | Search all callers |
| Shared mock | Changed mock setup, affects other tests | Check all tests using mock |
| Order change | Changed sort order, other tests expect old order | Use order-independent assertions |
| Default change | Changed default parameter, callers rely on old default | Search all call sites |
| Side effect | Added side effect to existing method | Check all callers |
