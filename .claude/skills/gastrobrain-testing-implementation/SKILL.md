---
name: gastrobrain-testing-implementation
description: Implements Phase 3 testing from issue roadmaps ONE TEST AT A TIME with verification between each test to avoid propagating errors
version: 1.0.0
---

# Gastrobrain Testing Implementation Agent

## Purpose

Implements Phase 3 (Testing) from issue roadmaps using a **single-test-at-a-time approach** that ensures quality and prevents error propagation.

**Core Philosophy**: Generate → Verify → Learn → Repeat

## When to Use This Skill

Use this skill when:
- Working on Phase 3 (Testing) of an issue roadmap
- Need to implement multiple tests for a feature
- Want to ensure each test works before writing the next
- Need to learn from test patterns and apply to subsequent tests
- Want to avoid fixing the same error in multiple tests

**DO NOT use this skill for:**
- Quick single test additions (just write it directly)
- Fixing existing tests (use standard debugging)
- Running test suites (use `flutter test` directly)

## CRITICAL: Single Test Loop Philosophy

### Why One Test at a Time?

**The Problem with Batching:**
```
❌ BAD: Write 8 tests → Run all → 7 fail with same pattern error → Fix all 7
Time wasted: High
Frustration: High
Risk of missing edge cases: High
```

**The Single Test Advantage:**
```
✅ GOOD: Write test 1 → Verify → Learn → Write test 2 → Verify → Learn
Time wasted: None
Frustration: Low
Risk of missing edge cases: Low
Pattern errors caught immediately
```

### Key Benefits

1. **Immediate Feedback**: Know if your approach works after first test
2. **Pattern Learning**: Each test teaches you about the codebase
3. **Error Isolation**: Failures are easy to diagnose (only one new test)
4. **Progressive Refinement**: Each test is better than the last
5. **User Control**: User has full visibility and control over pace
6. **No Wasted Work**: Never write 7 tests only to rewrite them all

## Anti-Patterns to Avoid

### ❌ NEVER DO THESE:

1. **Batching Tests**
   ```
   ❌ "Here are 8 tests for the feature..."
   ✅ "TEST 1/8: File setup. Does it pass? (y/n)"
   ```

2. **Assuming Success**
   ```
   ❌ "Test created. Moving to next test..."
   ✅ "Test created. Does it pass? (y/n) [WAIT]"
   ```

3. **Generic Debugging**
   ```
   ❌ "The tests might fail because X, Y, or Z..."
   ✅ "TEST 3/8 FAILED. What's the exact error message?"
   ```

4. **Proceeding with Failures**
   ```
   ❌ "Test 3 failed but let's continue with test 4..."
   ✅ "Let's fix test 3 before proceeding. What error do you see?"
   ```

5. **Ignoring Learnings**
   ```
   ❌ Each test repeats the same pattern without improvement
   ✅ "Learning from TEST 2: Mock setup works, applying to TEST 3"
   ```

## Test Loop Protocol

### Phase 1: Initial Analysis

```
1. Detect current branch: feature/XXX-description
2. Extract issue number: XXX
3. Load roadmap: docs/planning/0.1.X/ISSUE-XXX-ROADMAP.md
4. Locate Phase 3 (Testing) section
5. Analyze test requirements
```

### Phase 2: Test Plan Generation

**DO NOT generate actual tests yet - just the plan:**

```
Phase 3 Testing Implementation for Issue #XXX

Roadmap Phase 3 Analysis:
[Summary of Phase 3 requirements]

Test Plan Breakdown:

Category: Setup (1 test)
├─ Test 1: File structure, imports, and mock setup

Category: Core Functionality (3 tests)
├─ Test 2: Primary behavior validation
├─ Test 3: Secondary behavior validation
└─ Test 4: User interaction handling

Category: Data Persistence (2 tests)
├─ Test 5: Save operation
└─ Test 6: Load operation

Category: Edge Cases (2 tests)
├─ Test 7: Null/empty handling
└─ Test 8: Boundary conditions

Total: 8 tests to implement

Ready to start TEST 1/8? (y/n)
```

### Phase 3: Single Test Loop

**For EACH test (repeat 1-8 times):**

```
==================
TEST X/Y: [Clear test name]
Category: [Category name] (N/M if multiple in category)

[If X > 1, show learnings:]
Learning from previous tests:
- [Pattern 1 that worked]
- [Pattern 2 that worked]
- [Setup approach that's effective]

Implementing test:
[One clear sentence about what this test does]

[Generate ONLY this ONE test with complete implementation]

File: [path to test file]
Lines: [approximate line numbers or "new file"]

✓ Test code added

[Execute test using Bash tool - user will approve via permission prompt]
[Use: flutter test [specific test command]]
[Tool will show output - if test passes, continue; if fails, debug]

[WAIT for test execution result]
```

### Phase 4: Response Handling

**If test passes (Bash tool shows success):**

```
✓ TEST X/Y complete

Progress: X/Y tests complete [progress bar]

[If X < Y:]
Ready for TEST (X+1)/Y? (y/n)

[If X == Y:]
🎉 All Y tests complete!

Final verification:
[Execute full test file using Bash tool]
```

**If test fails (Bash tool shows error):**

```
❌ TEST X/Y failed - Let's debug

[Analyze error output from Bash tool]

Common issues for [test type]:
1. [Common issue 1]
2. [Common issue 2]
3. [Common issue 3]

Diagnosis: [Based on actual error message]

Fix:
[Provide corrected test code OR specific fix instructions]

[Execute fixed test using Bash tool to verify]

[If still fails, continue debugging]
[If passes, proceed to next test]
```

## Learning Between Tests

After each successful test, explicitly note:

```
Learning from TEST X:

✓ Mock Setup:
  - [What mock configuration worked]
  - [Any helper methods created]

✓ Widget Building:
  - [Effective widget tree structure]
  - [Working pump/pumpAndSettle patterns]

✓ Interaction Patterns:
  - [Successful tap/input methods]
  - [Effective finder strategies]

✓ Assertions:
  - [Clear assertion patterns]
  - [Helpful matchers used]

Applying to TEST (X+1):
- [How these learnings will be used]
```

## Progress Tracking

Show visual progress after each test:

```
Phase 3 Progress: X/Y tests complete ████░░░░ 37%

✓ Test 1: File setup and imports
✓ Test 2: Display meal types dropdown
✓ Test 3: Default selection behavior
⧗ Test 4: Selection interaction [CURRENT]
○ Test 5: Save meal type to database
○ Test 6: Load meal type from database
○ Test 7: Handle null meal type
○ Test 8: Handle invalid meal type
```

## Testing Patterns by Type

### Widget Tests

**Location**: `test/widgets/`

**Standard Pattern**:
```dart
testWidgets('descriptive test name', (WidgetTester tester) async {
  // Setup
  final mockDb = MockDatabaseHelper();
  // Configure mock as needed

  // Build widget
  await tester.pumpWidget(
    MaterialApp(
      home: WidgetUnderTest(databaseHelper: mockDb),
    ),
  );

  // Interact
  await tester.tap(find.byKey(Key('widget_field_field')));
  await tester.pumpAndSettle();

  // Assert
  expect(find.text('Expected Result'), findsOneWidget);
});
```

**Key Conventions**:
- Test keys: `{screen}_{field}_field`
- Use `pumpAndSettle()` after interactions
- Use MaterialApp wrapper for dialogs/navigation

### Unit Tests

**Location**: `test/core/services/`

**Standard Pattern**:
```dart
test('descriptive test name', () async {
  // Setup
  final mockDb = MockDatabaseHelper();
  final service = ServiceUnderTest(mockDb);

  // Execute
  final result = await service.methodUnderTest(params);

  // Assert
  expect(result, expectedValue);
});
```

### Edge Case Tests

**Required by Issue #39**:

```dart
group('Edge Cases', () {
  testWidgets('handles null input gracefully', (tester) async {
    // Test with null
  });

  testWidgets('handles empty list', (tester) async {
    // Test with empty data
  });

  testWidgets('handles boundary values', (tester) async {
    // Test min/max values
  });

  testWidgets('displays error state', (tester) async {
    // Test error scenarios
  });
});
```

### MockDatabaseHelper Setup

**Standard Setup**:
```dart
late MockDatabaseHelper mockDb;

setUp(() {
  mockDb = MockDatabaseHelper();
  // Add test data as needed
});
```

**Common Mock Operations**:
```dart
// Add test recipe
final recipe = Recipe(
  id: 1,
  name: 'Test Recipe',
  // ... other fields
);
mockDb.recipes[recipe.id!] = recipe;

// Add test meal
final meal = Meal(
  id: 1,
  recipeId: 1,
  // ... other fields
);
mockDb.meals[meal.id!] = meal;
```

## Verification Standards Per Test

Each test must:

1. **Compile without errors**
   - No syntax errors
   - All imports present
   - Types match

2. **Run successfully (green)**
   - Test passes
   - No runtime errors
   - No timeout issues

3. **Test exactly one behavior**
   - Single clear purpose
   - Focused assertion
   - No scope creep

4. **Have clear assertions**
   - Explicit expected values
   - Meaningful matchers
   - Clear failure messages

5. **Follow project patterns**
   - Matches existing test style
   - Uses standard helpers
   - Follows naming conventions

## Complete Interaction Example

```
Phase 3 Testing Implementation for Issue #199

Roadmap Phase 3 requires:
- Widget tests for meal type dropdown
- Data persistence tests
- Edge case validation

Test Plan (5 tests total):
1. Setup: Test file and mock structure
2. Core: Dropdown displays meal types
3. Persistence: Save selected meal type
4. Edge: Handle null meal type
5. Edge: Handle empty meal type

Ready to start TEST 1/5? (y/n)

[User: y]

==================
TEST 1/5: Setup test file with mocks
Category: Setup

Creating test file with:
- Standard imports (flutter_test, mockito)
- MockDatabaseHelper setup
- Test group structure for meal recording dialog

File: test/widgets/meal_recording_dialog_test.dart (new file)

✓ Test code added

Run: flutter test test/widgets/meal_recording_dialog_test.dart

Does the test pass? (y/n)

[User: y]

✓ TEST 1/5 complete

Progress: 1/5 tests complete ██░░░ 20%

✓ Test 1: Setup test file [COMPLETE]
○ Test 2: Dropdown displays meal types
○ Test 3: Save selected meal type
○ Test 4: Handle null meal type
○ Test 5: Handle empty meal type

Ready for TEST 2/5? (y/n)

[User: y]

==================
TEST 2/5: Dropdown displays all meal types
Category: Core Functionality

Learning from TEST 1:
- MockDatabaseHelper initialized successfully
- MaterialApp wrapper works for dialog tests
- Standard imports are sufficient

Implementing test:
Verifies that the meal type dropdown shows all expected options
(breakfast, lunch, dinner, snack).

[Generates ONLY the dropdown test]

✓ Test code added to meal_recording_dialog_test.dart

Run: flutter test test/widgets/meal_recording_dialog_test.dart --name "displays meal types"

Does the test pass? (y/n)

[User: n]

❌ TEST 2/5 failed - Let's debug before continuing

Common issues for dropdown tests:
1. Dropdown not rendered yet (need pumpAndSettle)
2. Wrong finder strategy (try byType vs byKey)
3. Test key not matching convention

What error message do you see?

[User: "findsNothing - can't find dropdown"]

The issue is: The dropdown needs to be tapped to show options.

Fix:
Need to tap the dropdown button first, THEN look for the menu items.

Updated test:
[Provides corrected code with tap before find]

Try the fixed version:
Run: flutter test test/widgets/meal_recording_dialog_test.dart --name "displays meal types"

Does it pass now? (y/n)

[User: y]

✓ TEST 2/5 complete (after debug)

Progress: 2/5 tests complete ████░ 40%

✓ Test 1: Setup test file [COMPLETE]
✓ Test 2: Dropdown displays meal types [COMPLETE]
○ Test 3: Save selected meal type
○ Test 4: Handle null meal type
○ Test 5: Handle empty meal type

Learning from TEST 2:
- Dropdowns require tap before finding menu items
- Use pumpAndSettle after tap to wait for animation
- byType(DropdownMenuItem) works well for finding options

Ready for TEST 3/5? (y/n)

[User: y]

==================
TEST 3/5: Save selected meal type to database
Category: Data Persistence

Learning from previous tests:
- Mock setup pattern established
- Dropdown interaction requires tap → pumpAndSettle
- Test keys follow {screen}_{field}_field convention

Implementing test:
Verifies that selecting a meal type and saving updates the
database correctly through the mock.

[Generates ONLY the persistence test, applying previous learnings]

✓ Test code added

Run: flutter test test/widgets/meal_recording_dialog_test.dart --name "save meal type"

Does the test pass? (y/n)

[Continues until all 5 tests complete...]
```

## Failure Recovery Example

```
TEST 3/6 FAILED - Let's debug before continuing

Common issues for persistence tests:
1. Mock not configured to handle the operation
2. Dialog not returning expected result
3. Timing issue with async operations

What error message do you see?

[User: "NoSuchMethodError on mockDb.insertMeal"]

The issue is: MockDatabaseHelper doesn't have insertMeal mocked.

This is expected - MockDatabaseHelper uses internal storage.
The test should verify the meal was added to mockDb.meals map.

Fix approach:
Instead of expecting a method call, check the meals map directly:

expect(mockDb.meals.length, equals(1));
expect(mockDb.meals.values.first.mealType, equals('dinner'));

Updated test:
[Provides corrected test with direct map verification]

Try the fixed version:
Run: flutter test test/widgets/meal_recording_dialog_test.dart --name "save meal type"

Does it pass now? (y/n)

[User: y]

✓ TEST 3/6 complete (after fix)

Learning from this failure:
- MockDatabaseHelper uses maps (meals, recipes, etc.), not method mocking
- Check internal state directly, not method calls
- This pattern applies to all persistence tests

Applying to remaining tests:
- TEST 4 (load): Check mockDb.meals.values
- TEST 5 (update): Verify mockDb.meals[id] changes
- TEST 6 (delete): Verify mockDb.meals.containsKey is false

Ready for TEST 4/6? (y/n)
```

## Test Categories Reference

### Setup Tests (1 test typically)
- File creation
- Import statements
- Mock initialization
- Test group structure

### Core Functionality Tests (varies by feature)
- Primary feature behavior
- User interactions
- UI state changes
- Navigation flows

### Data Persistence Tests (varies by feature)
- Save operations
- Load operations
- Update operations
- Delete operations

### Edge Case Tests (required by Issue #39)
- Null handling
- Empty collections
- Boundary values
- Error states
- Invalid input

## Success Criteria

This skill succeeds when:

1. **No Batch Testing**: NEVER more than one test generated at a time
2. **Clear Progress**: User always knows TEST X/Y status
3. **Learning Visible**: Patterns noted and applied between tests
4. **Failure Handling**: Stops and helps debug, doesn't continue
5. **User Control**: Waits for "y/n" after every test
6. **Pattern Prevention**: Errors caught in first test, not propagated
7. **Complete Tests**: Each test fully implemented (no TODOs)
8. **Standards Compliance**: Follows project patterns and conventions

## References

- Issue #39: Edge case testing standards
- `test/widgets/`: Widget test patterns
- `test/core/services/`: Unit test patterns
- `integration_test/`: E2E test patterns
- `test/mocks/mock_database_helper.dart`: Mock setup reference
- `docs/testing/`: Testing documentation

---

**Remember**: Quality over speed. One working test is worth more than ten broken tests.
