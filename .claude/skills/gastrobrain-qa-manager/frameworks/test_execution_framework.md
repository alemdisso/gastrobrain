# Test Execution Framework

Systematic approach to running tests at the right level for the right context.

---

## 4-Level Strategy

### Level 1: Quick Validation (~30 seconds)

**When to use:**
- Changed a single file
- Quick feedback during development
- Verifying a specific behavior

**Commands:**
```bash
# Static analysis first
flutter analyze

# Run specific test file
flutter test test/core/models/meal_test.dart

# Run specific test by name
flutter test --name="saves meal with type"
```

**What it catches:**
- Compilation errors
- Specific behavior regressions
- Quick feedback on current change

**What it misses:**
- Side effects on other components
- Integration issues
- Broad regressions

---

### Level 2: Component Testing (2-5 minutes)

**When to use:**
- Changed multiple files in one component
- Modified a service that multiple widgets use
- After completing a small feature

**Commands:**
```bash
# Test all models
flutter test test/core/models/

# Test all services
flutter test test/core/services/

# Test all widgets
flutter test test/widgets/

# Test specific component group
flutter test test/core/services/meal_service_test.dart test/widgets/meal_recording_dialog_test.dart
```

**What it catches:**
- Component-level regressions
- Related test failures
- Interface contract violations

**What it misses:**
- Cross-component integration issues
- Full system regressions

---

### Level 3: Full Test Suite (5-10 minutes)

**When to use:**
- Before committing changes
- After completing a feature
- When uncertain about impact scope

**Commands:**
```bash
# Full unit + widget test suite
flutter test
```

**What it catches:**
- All unit and widget-level regressions
- Cross-component issues
- Comprehensive behavior validation

**What it misses:**
- E2E workflow issues
- Integration test scenarios

---

### Level 4: Integration Testing (10-15 minutes)

**When to use:**
- Before merging to develop
- After database migrations
- After UI workflow changes
- Release preparation

**Commands:**
```bash
# Full suite first
flutter test

# Then integration tests
flutter test integration_test/
```

**What it catches:**
- Everything from Level 3
- Full user workflow regressions
- Database integration issues
- Navigation and routing issues

---

## Level Selection Decision Tree

```
What changed?
│
├── Single test file only
│   └── Level 1 (just that test)
│
├── Single source file
│   ├── Model → Level 1 (model tests)
│   ├── Service → Level 2 (service + dependent widget tests)
│   ├── Widget → Level 1 (widget tests)
│   └── Database → Level 3 (many things depend on DB)
│
├── Multiple files, same component
│   └── Level 2 (component tests)
│
├── Multiple components
│   └── Level 3 (full suite)
│
├── Database migration
│   └── Level 4 (everything)
│
└── Ready to merge
    └── Level 4 (everything)
```

---

## Pre-Execution Checklist

Before running any test level:

```
[ ] flutter analyze passes (0 errors)
[ ] No uncommitted merge conflicts
[ ] Dependencies up to date (flutter pub get if needed)
[ ] Test infrastructure accessible:
    [ ] MockDatabaseHelper compiles
    [ ] Test helpers compile
    [ ] Test fixtures available
```

---

## Interpreting Results

### All Passed

```
All tests passed!

Next steps:
- Level 1-2: Continue development or run higher level
- Level 3: Safe to commit
- Level 4: Safe to merge
```

### Some Failed

```
Failures detected.

Categorize each failure:
1. CRITICAL: Blocks progress (null safety, data corruption)
2. IMPORTANT: Should fix (logic error, expectation mismatch)
3. INVESTIGATE: May be flaky (timeout, intermittent)

Then:
- Fix critical failures first
- Group related failures (likely same root cause)
- Use structured debugging process for each
```

### Timeouts

```
Test timed out.

This is likely:
- Flaky test (run again to check)
- Missing pump/pumpAndSettle
- Infinite rebuild loop
- Unresolved Future

Re-run the specific test first. If it passes, mark as potentially flaky.
If it fails again, debug with structured process.
```

---

## Parallel vs Sequential

**Run in parallel (default):**
- `flutter test` runs tests in parallel by default
- Good for full suite execution
- Faster total execution time

**Run sequentially (when needed):**
```bash
# If tests have shared state issues
flutter test --concurrency=1

# Single test file (always sequential within file)
flutter test test/specific_test.dart
```

**When to use sequential:**
- Investigating order-dependent failures
- Debugging shared state issues
- When parallel execution causes resource contention
