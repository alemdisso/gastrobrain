# Example 1: Systematic Test Execution

## Scenario

Issue #268 (meal type categorization) has just been implemented. The developer wants to run tests to validate the changes before committing. Changes span models, widgets, a database migration, and localization files.

**Process:** Systematic Test Execution (4 Checkpoints)

---

## Walkthrough

### CHECKPOINT 1: Test Selection

```
Test Execution Plan

CHECKPOINT 1: Test Selection
───────────────────────────────────────

Context: Post-implementation validation for issue #268 (meal type categorization)

Changes Detected:
- lib/core/models/meal.dart (added mealType field)
- lib/core/models/meal_type.dart (new enum)
- lib/widgets/meal_type_dropdown.dart (new widget)
- lib/screens/meal_recording_screen.dart (integrated dropdown)
- lib/core/database/database_helper.dart (migration v16)
- lib/l10n/app_en.arb (4 new strings)
- lib/l10n/app_pt.arb (4 new strings)

Affected Components:
- Models (meal, meal_type)
- Widgets (meal_type_dropdown, meal_recording)
- Database (migration, queries)
- Localization (new strings)

Recommended Test Level: 3 - Full Suite
Reasoning: Changes span multiple components (models, widgets, database).
Database migration increases risk. Full suite ensures no regressions.

Tests to Run:
- All model tests: test/core/models/
- All service tests: test/core/services/
- All widget tests: test/widgets/
- All edge case tests: test/edge_cases/
- Regression tests: test/regression/

Estimated Duration: ~6 minutes

Proceed with this test plan? (y/n/adjust)
```

**User:** y

---

### CHECKPOINT 2: Pre-Execution Checks

```
───────────────────────────────────────
CHECKPOINT 2: Pre-Execution Checks

Running pre-flight checks...

Static Analysis:
- flutter analyze: No issues found ✓

Compilation:
- Test files compile: Yes ✓
- New test files detected:
  - test/core/models/meal_type_test.dart ✓
  - test/widgets/meal_type_dropdown_test.dart ✓

Test Infrastructure:
- MockDatabaseHelper available: Yes ✓
- TestSetup configured: Yes ✓
- DialogTestHelpers available: Yes ✓
- EdgeCaseTestHelpers available: Yes ✓

Environment:
- Flutter version: 3.27.4
- Platform: Windows (MSYS)

Pre-flight Status: ✓ READY

All checks passed. No issues to resolve.

Ready to execute? (y/n)
```

**User:** y

---

### CHECKPOINT 3: Test Execution

```
───────────────────────────────────────
CHECKPOINT 3: Test Execution

Executing: flutter test

[Progress updates as tests run...]

00:03 +142: test/core/models/meal_test.dart
00:05 +215: test/core/services/meal_service_test.dart
00:08 +389: test/widgets/meal_recording_dialog_test.dart
00:11 +567: test/edge_cases/boundary_conditions/

Results:
  Passed: 609 tests
  Failed: 2 tests
  Skipped: 0 tests
  Duration: 5m 47s

Failed Tests:

1. test/widgets/meal_type_dropdown_test.dart:45
   Test: "displays all meal types in dropdown"
   Error: Expected: exactly 4 widgets matching type DropdownMenuItem<MealType>
          Actual: found 5 widgets

2. test/core/services/meal_service_test.dart:178
   Test: "saves meal without type for backward compatibility"
   Error: Null check operator used on a null value

All tests executed. Analyze failures? (y/n)
```

**User:** y

---

### CHECKPOINT 4: Results Analysis

```
───────────────────────────────────────
CHECKPOINT 4: Results Analysis

Failure Analysis:

CRITICAL (blocks commit):
- meal_service_test.dart:178 - Null safety violation
  Assessment: Production code likely missing null check for mealType.
  The test validates backward compatibility with meals that have no type,
  but the code appears to assume mealType is always set.
  Risk: Could crash the app when viewing old meals.

IMPORTANT (should fix):
- meal_type_dropdown_test.dart:45 - Expectation mismatch
  Assessment: Test expects 4 DropdownMenuItems but the widget includes
  a "Not specified" option (null selection), making 5 total.
  This is likely a test issue - the test wasn't updated for the
  null selection option.
  Risk: No production risk, test needs updating.

Pattern Detection:
- The null safety failure and the dropdown mismatch may be related:
  both involve null/optional meal type handling.
- Suggests the nullable mealType scenario needs more attention.

Recommended Action Plan:
1. Fix critical failure first: Add null check in meal_service.dart
2. Fix test expectation: Update dropdown test to expect 5 items
3. Re-run full suite to verify no regressions

Proceed with debugging? (y/n/re-run specific tests)
```

**User:** y, let's debug both

---

## Result

The test execution identified:
- **609/611 tests passing** (99.7% pass rate)
- **1 critical failure** (null safety in production code - needs code fix)
- **1 test issue** (dropdown count expectation - needs test update)
- Both related to nullable mealType handling
- Clear action plan: fix code, update test, re-validate

Next step: Use the Structured Debugging process (Process B) for each failure.
