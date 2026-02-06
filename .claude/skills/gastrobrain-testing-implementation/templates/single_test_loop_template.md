# Single Test Loop Template

This template shows the exact format for implementing each test in the single-test-at-a-time workflow.

## Initial Test Plan Output

```
Phase 3 Testing Implementation for Issue #[NUMBER]

Analyzing roadmap at: docs/planning/0.1.X/ISSUE-[NUMBER]-ROADMAP.md

Phase 3 Requirements Summary:
[1-3 sentences summarizing what Phase 3 asks for]

Test Plan Breakdown:

Category: Setup ([N] test)
├─ Test 1: [Description]

Category: Core Functionality ([N] tests)
├─ Test 2: [Description]
├─ Test 3: [Description]
└─ Test 4: [Description]

Category: Data Persistence ([N] tests)
├─ Test 5: [Description]
└─ Test 6: [Description]

Category: Edge Cases ([N] tests)
├─ Test 7: [Description]
└─ Test 8: [Description]

Total: [N] tests to implement

This will follow the single-test-at-a-time protocol:
- Generate ONE test
- Wait for your verification (pass/fail)
- Learn from result
- Generate NEXT test
- Repeat

Ready to start TEST 1/[N]? (y/n)
```

## Test Loop Template (For Each Test)

### First Test (No Prior Learning)

```
==================
TEST 1/[N]: [Clear, specific test name]
Category: Setup

Implementing test:
[One sentence describing what this test validates]

Creating: [test file path]

Test implementation:
```dart
[COMPLETE test code - no TODOs or placeholders]
```

✓ Test code added to [file path]

Run this command to verify:
```bash
flutter test [specific test file/name]
```

Does the test pass? (y/n)

[STOP - WAIT - DO NOT PROCEED UNTIL USER RESPONDS]
```

### Subsequent Tests (With Learning)

```
==================
TEST [X]/[N]: [Clear, specific test name]
Category: [Category] ([M]/[K] in this category)

Learning from previous tests:
✓ [Key pattern 1 that worked]
✓ [Key pattern 2 that worked]
✓ [Key setup approach that's effective]
✓ [Effective assertion style]

Implementing test:
[One sentence describing what this test validates]

Applying learned patterns:
- [How learning 1 is applied to this test]
- [How learning 2 is applied to this test]

Test implementation:
```dart
[COMPLETE test code incorporating learnings]
```

✓ Test code added to [file path]
[If existing file: Lines approximately XXX-YYY]

Run this command to verify:
```bash
flutter test [specific test file/name]
```

Does the test pass? (y/n)

[STOP - WAIT - DO NOT PROCEED UNTIL USER RESPONDS]
```

## Response Templates

### When Test Passes

```
✅ TEST [X]/[N] complete

Progress: [X]/[N] tests complete [progress bar] [percentage]%

Test Status:
✓ Test 1: [name] [COMPLETE]
✓ Test 2: [name] [COMPLETE]
✓ Test X: [name] [COMPLETE - just finished]
○ Test X+1: [name]
○ Test X+2: [name]
[... remaining tests ...]

[If X < N:]
Ready for TEST [X+1]/[N]? (y/n)

[If X == N:]
🎉 All [N] tests complete!

Final verification - run all tests together:
```bash
flutter test [full test file path]
```

Do all tests pass together? (y/n)
```

### When Test Fails

```
❌ TEST [X]/[N] FAILED

Let's debug this before continuing. It's important to fix this test
before moving to the next one to avoid propagating errors.

Common issues for [test type] tests:
1. [Common issue 1 with brief explanation]
2. [Common issue 2 with brief explanation]
3. [Common issue 3 with brief explanation]

What is the exact error message you're seeing?

[WAIT FOR USER INPUT - DO NOT GUESS OR ASSUME]

---

[After receiving error message:]

Analysis:
The error "[user's error]" indicates: [diagnosis]

Root cause: [explanation]

Fix strategy:
[Clear explanation of what needs to change and why]

Corrected test:
```dart
[CORRECTED test code with changes highlighted in comments]
```

Try the fixed version:
```bash
flutter test [specific test command]
```

Does it pass now? (y/n)

[If still failing, continue debugging loop]
[If passes, continue to next test]
```

### Debugging Loop (If First Fix Doesn't Work)

```
Still failing? Let's dig deeper.

What's the new error message?

[WAIT FOR USER INPUT]

---

[After second error:]

I see - the issue is actually: [deeper diagnosis]

Let's try approach #2:
[Alternative solution explanation]

Updated test:
```dart
[UPDATED test code]
```

Run:
```bash
flutter test [command]
```

Result? (y/n)

[Continue until test passes]
```

## Progress Bar Examples

```
Progress: 1/8 tests complete █░░░░░░░ 12%
Progress: 2/8 tests complete ██░░░░░░ 25%
Progress: 3/8 tests complete ███░░░░░ 37%
Progress: 4/8 tests complete ████░░░░ 50%
Progress: 5/8 tests complete █████░░░ 62%
Progress: 6/8 tests complete ██████░░ 75%
Progress: 7/8 tests complete ███████░ 87%
Progress: 8/8 tests complete ████████ 100%
```

## Test Status Indicators

```
✓ Test 1: Setup [COMPLETE]
✓ Test 2: Core feature [COMPLETE]
⧗ Test 3: Interaction [CURRENT - IN PROGRESS]
○ Test 4: Persistence [PENDING]
○ Test 5: Edge case [PENDING]
```

## Learning Note Template

```
Learning from TEST [X]:

✓ Mock Configuration:
  - [What mock setup worked]
  - [Any helper data added]
  - [Effective initialization pattern]

✓ Widget Testing:
  - [Widget tree structure that worked]
  - [Pump strategy (pump vs pumpAndSettle)]
  - [MaterialApp wrapper considerations]

✓ Finder Strategy:
  - [What finder approach worked (byKey, byType, text)]
  - [Any finder timing issues resolved]

✓ Interaction Pattern:
  - [Effective tap/input sequence]
  - [Timing with pumpAndSettle]
  - [Any animation considerations]

✓ Assertions:
  - [Clear assertion pattern used]
  - [Effective matchers]
  - [Error message clarity]

Applying to TEST [X+1]:
- [Specific application 1]
- [Specific application 2]
- [Specific application 3]
```

## Complete Example Flow (3 Tests)

```
Phase 3 Testing Implementation for Issue #199

Test Plan (3 tests):
1. Setup: Test file structure
2. Core: Dropdown display
3. Persistence: Save meal type

Total: 3 tests

Ready to start TEST 1/3? (y/n)

[User: y]

==================
TEST 1/3: Setup test file with mocks
Category: Setup

Implementing test:
Creates test file structure with imports and mock initialization.

Creating: test/widgets/meal_recording_dialog_test.dart

[... test code ...]

Run: flutter test test/widgets/meal_recording_dialog_test.dart

Does the test pass? (y/n)

[User: y]

✅ TEST 1/3 complete

Progress: 1/3 tests complete ███░ 33%

✓ Test 1: Setup [COMPLETE]
○ Test 2: Dropdown display
○ Test 3: Save meal type

Ready for TEST 2/3? (y/n)

[User: y]

==================
TEST 2/3: Dropdown displays meal types
Category: Core Functionality

Learning from TEST 1:
✓ MockDatabaseHelper setup pattern established
✓ MaterialApp wrapper works for dialog tests
✓ Standard test group structure in place

Implementing test:
Verifies meal type dropdown shows all options (breakfast, lunch, dinner, snack).

[... test code with learnings applied ...]

Run: flutter test test/widgets/meal_recording_dialog_test.dart --name "dropdown"

Does the test pass? (y/n)

[User: n]

❌ TEST 2/3 FAILED

Common issues for dropdown tests:
1. Dropdown not expanded (need to tap first)
2. Wrong finder strategy
3. Timing with animations

What error message do you see?

[User: "findsNothing"]

Analysis: Dropdown menu items only appear after tapping the dropdown.

Fix: Add tap interaction before finding menu items.

[... corrected code ...]

Run: flutter test test/widgets/meal_recording_dialog_test.dart --name "dropdown"

Does it pass now? (y/n)

[User: y]

✅ TEST 2/3 complete (after fix)

Progress: 2/3 tests complete ███████░ 66%

✓ Test 1: Setup [COMPLETE]
✓ Test 2: Dropdown display [COMPLETE]
○ Test 3: Save meal type

Learning from TEST 2:
✓ Dropdowns require tap before finding items
✓ Use pumpAndSettle after tap for animation
✓ byType(DropdownMenuItem) works for menu items

Ready for TEST 3/3? (y/n)

[User: y]

==================
TEST 3/3: Save selected meal type to database
Category: Data Persistence

Learning from previous tests:
✓ Mock setup pattern from TEST 1
✓ Dropdown interaction pattern from TEST 2
✓ pumpAndSettle timing strategy

Implementing test:
Verifies selecting and saving a meal type updates the database correctly.

Applying learned patterns:
- Using established mock configuration
- Applying dropdown tap → pumpAndSettle pattern
- Following test structure from previous tests

[... test code ...]

Run: flutter test test/widgets/meal_recording_dialog_test.dart --name "save"

Does the test pass? (y/n)

[User: y]

✅ TEST 3/3 complete

Progress: 3/3 tests complete ████████ 100%

✓ Test 1: Setup [COMPLETE]
✓ Test 2: Dropdown display [COMPLETE]
✓ Test 3: Save meal type [COMPLETE]

🎉 All 3 tests complete!

Final verification:
```bash
flutter test test/widgets/meal_recording_dialog_test.dart
```

Do all tests pass together? (y/n)

[User: y]

Perfect! Phase 3 testing implementation complete for Issue #199.

Summary:
- 3/3 tests implemented successfully
- 1 test required debugging (TEST 2)
- All patterns learned and applied
- Full test suite passing

Next steps:
- Run full project test suite to ensure no regressions
- Update issue roadmap to mark Phase 3 complete
- Ready to proceed to Phase 4 (if applicable)
```

---

**Key Reminders:**

1. Generate EXACTLY ONE test per iteration
2. ALWAYS wait for user "y/n" response
3. NEVER assume test passes - require confirmation
4. Learn from each test and apply to next
5. Stop and debug failures immediately
6. Show clear progress after each test
7. Provide complete test code (no TODOs)
8. Use specific test commands for verification
