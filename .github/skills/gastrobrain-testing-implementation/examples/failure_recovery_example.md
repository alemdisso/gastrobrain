# Failure Recovery Example: Debugging in Test Sequence

This example shows how the single-test-at-a-time approach handles test failures, helps debug them, and prevents error propagation to subsequent tests.

**Scenario**: Implementing tests for recipe sorting feature (Issue #275). TEST 3 fails and requires debugging before continuing.

---

## Initial Plan

```
Phase 3 Testing Implementation for Issue #275

Test Plan (6 tests):
1. Setup: Test file and mock data
2. Core: Display recipes in default order
3. Core: Sort by name ascending
4. Core: Sort by rating descending
5. Persistence: Remember sort preference
6. Edge: Handle empty recipe list

Total: 6 tests

Ready to start TEST 1/6? (y/n)
```

**User**: y

---

## TEST 1/6: Success

```
==================
TEST 1/6: Setup test file with mock recipes
Category: Setup

[... test implementation ...]

✓ Test code added

Run: flutter test test/widgets/recipe_sorter_test.dart

Does the test pass? (y/n)
```

**User**: y

```
✅ TEST 1/6 complete

Progress: 1/6 tests complete ██░░░░ 16%

Ready for TEST 2/6? (y/n)
```

**User**: y

---

## TEST 2/6: Success

```
==================
TEST 2/6: Display recipes in default order
Category: Core Functionality (1/3)

Learning from TEST 1:
✓ MockDatabaseHelper with 3 test recipes works well
✓ MaterialApp wrapper established

[... test implementation ...]

✓ Test code added

Run: flutter test test/widgets/recipe_sorter_test.dart --name "default order"

Does the test pass? (y/n)
```

**User**: y

```
✅ TEST 2/6 complete

Progress: 2/6 tests complete ████░░ 33%

Learning from TEST 2:
✓ find.byType(ListTile) works for recipe list items
✓ Recipe names visible in Text widgets

Ready for TEST 3/6? (y/n)
```

**User**: y

---

## TEST 3/6: Initial Failure

```
==================
TEST 3/6: Sort recipes by name ascending
Category: Core Functionality (2/3)

Learning from previous tests:
✓ Mock setup with 3 test recipes
✓ ListTile finder works for recipe items
✓ Text widgets contain recipe names

Implementing test:
Verifies that tapping "Sort by Name" button sorts the
recipe list alphabetically by name.

Test implementation:
```dart
testWidgets('sorts recipes by name ascending', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: RecipeSorter(databaseHelper: mockDb),
      ),
    ),
  );

  // Tap sort button
  await tester.tap(find.byKey(Key('recipe_sort_button')));
  await tester.pumpAndSettle();

  // Select "Name (A-Z)"
  await tester.tap(find.text('Name (A-Z)'));
  await tester.pumpAndSettle();

  // Verify recipes are sorted alphabetically
  final listTiles = find.byType(ListTile);
  expect(listTiles, findsNWidgets(3));

  // Check order by examining Text widgets
  final textWidgets = find.descendant(
    of: listTiles.first,
    matching: find.byType(Text),
  );
  expect(textWidgets.first, findsOneWidget);
  expect((textWidgets.first.evaluate().single.widget as Text).data,
         equals('Apple Pie'));
});
```

✓ Test code added

Run: flutter test test/widgets/recipe_sorter_test.dart --name "sorts by name"

Does the test pass? (y/n)
```

**User**: n

---

## TEST 3/6: Debugging Loop

```
❌ TEST 3/6 FAILED

Let's debug this before continuing. It's critical to fix this
test before moving to TEST 4 to avoid propagating the error.

Common issues for sorting tests:
1. Dropdown/menu not rendering (wrong finder or timing)
2. Incorrect widget tree traversal for verification
3. Sort operation not triggering properly

What is the exact error message you're seeing?
```

**User**: "findsNothing for find.text('Name (A-Z)')"

```
Analysis:
The error "findsNothing for find.text('Name (A-Z)')" indicates the
sort menu isn't visible yet.

Root cause: The sort button likely opens a bottom sheet or popup menu,
which needs additional setup or different interaction.

Let me ask: What widget type does the sort button use?
1. DropdownButton
2. PopupMenuButton
3. Custom button opening bottom sheet

What do you see? (1/2/3 or describe)
```

**User**: "PopupMenuButton"

```
Perfect! PopupMenuButton requires a slightly different approach.

The issue: PopupMenuButton items aren't in the widget tree until
the button is tapped. But we also need to ensure the popup is fully
rendered before searching for menu items.

Fix strategy:
1. Tap the PopupMenuButton
2. Use pumpAndSettle() to wait for animation
3. Then find menu items

The current test taps by key, but for PopupMenuButton we should tap
the button directly by type.

Corrected test:
```dart
testWidgets('sorts recipes by name ascending', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: RecipeSorter(databaseHelper: mockDb),
      ),
    ),
  );

  // Tap the PopupMenuButton to open menu
  await tester.tap(find.byType(PopupMenuButton));
  await tester.pumpAndSettle(); // Wait for menu animation

  // Now find and tap the menu item
  await tester.tap(find.text('Name (A-Z)'));
  await tester.pumpAndSettle(); // Wait for sort to complete

  // Verify recipes are sorted alphabetically
  final listTiles = find.byType(ListTile);
  expect(listTiles, findsNWidgets(3));

  // Verify first recipe is "Apple Pie" (alphabetically first)
  final firstTileText = find.descendant(
    of: listTiles.at(0),
    matching: find.byType(Text),
  );
  final firstRecipeName = (firstTileText.evaluate().first.widget as Text).data;
  expect(firstRecipeName, contains('Apple Pie'));

  // Verify last recipe is "Chocolate Cake" (alphabetically last)
  final lastTileText = find.descendant(
    of: listTiles.at(2),
    matching: find.byType(Text),
  );
  final lastRecipeName = (lastTileText.evaluate().first.widget as Text).data;
  expect(lastRecipeName, contains('Chocolate Cake'));
});
```

Key changes:
1. Changed from byKey to byType(PopupMenuButton) - more reliable
2. Added pumpAndSettle after opening menu
3. Improved verification to check BOTH first and last items
4. Used .at(index) instead of .first for clearer access
5. Used contains() instead of equals() for more flexible matching

Try the fixed version:
```bash
flutter test test/widgets/recipe_sorter_test.dart --name "sorts by name"
```

Does it pass now? (y/n)
```

**User**: n

```
Still failing? Let's dig deeper.

What's the new error message you're seeing?
```

**User**: "evaluate().first throws StateError (No element)"

```
Ah! The issue is that our descendant finder isn't finding any Text widgets.

This often means the ListTile structure is different than expected.
Maybe the recipe name is in a subtitle, or wrapped in another widget.

Let me provide a more robust verification approach that inspects
the widget tree:

Alternative test verification:
```dart
testWidgets('sorts recipes by name ascending', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: RecipeSorter(databaseHelper: mockDb),
      ),
    ),
  );

  // Tap the PopupMenuButton to open menu
  await tester.tap(find.byType(PopupMenuButton));
  await tester.pumpAndSettle();

  // Select "Name (A-Z)"
  await tester.tap(find.text('Name (A-Z)'));
  await tester.pumpAndSettle();

  // Simpler verification: just check that all recipe names appear
  // in the correct order using find.text
  expect(find.text('Apple Pie'), findsOneWidget);
  expect(find.text('Banana Bread'), findsOneWidget);
  expect(find.text('Chocolate Cake'), findsOneWidget);

  // Verify order by checking vertical positions
  final applePieY = tester.getTopLeft(find.text('Apple Pie')).dy;
  final bananaBreadY = tester.getTopLeft(find.text('Banana Bread')).dy;
  final chocolateCakeY = tester.getTopLeft(find.text('Chocolate Cake')).dy;

  expect(applePieY < bananaBreadY, isTrue,
         reason: 'Apple Pie should appear before Banana Bread');
  expect(bananaBreadY < chocolateCakeY, isTrue,
         reason: 'Banana Bread should appear before Chocolate Cake');
});
```

This approach:
1. Avoids complex widget tree traversal
2. Uses direct text finding (more reliable)
3. Verifies sort order by checking Y positions (vertical order)
4. Includes helpful reason messages for failures

This is actually a BETTER pattern for list ordering tests!

Try this version:
```bash
flutter test test/widgets/recipe_sorter_test.dart --name "sorts by name"
```

Does it pass now? (y/n)
```

**User**: y

---

## TEST 3/6: Success After Debugging

```
✅ TEST 3/6 complete (after debugging)

Progress: 3/6 tests complete █████░ 50%

✓ Test 1: Setup with mock recipes [COMPLETE]
✓ Test 2: Display default order [COMPLETE]
✓ Test 3: Sort by name ascending [COMPLETE - debugged]
○ Test 4: Sort by rating descending
○ Test 5: Remember sort preference
○ Test 6: Handle empty list

Learning from TEST 3 (and debugging):
✓ PopupMenuButton requires byType(PopupMenuButton) tap
✓ Need pumpAndSettle AFTER opening popup
✓ Position-based verification (getTopLeft) is MORE RELIABLE than tree traversal
✓ Direct find.text() better than complex descendant finding
✓ Reason messages in expects help with debugging

CRITICAL LESSON: When widget structure is uncertain, use position
verification instead of tree traversal!

This will improve all remaining tests.

Ready for TEST 4/6? (y/n)
```

**User**: y

---

## TEST 4/6: Applying Learned Patterns

```
==================
TEST 4/6: Sort recipes by rating descending
Category: Core Functionality (3/3)

Learning from previous tests:
✓ MockDatabaseHelper setup (TEST 1)
✓ ListTile finder for recipe items (TEST 2)
✓ PopupMenuButton interaction: byType → pumpAndSettle → tap item (TEST 3)
✓ Position-based verification is most reliable (TEST 3)
✓ Direct find.text() better than tree traversal (TEST 3)

Implementing test:
Verifies that sorting by rating shows highest-rated recipes first.

Applying learned patterns:
- Using PopupMenuButton tap pattern from TEST 3
- Using position-based verification from TEST 3
- Using direct text finding from TEST 3
- Adding reason messages for clarity

NEW: This test will verify ratings, not names, so we'll look
for rating display (assuming recipes show their rating).

Test implementation:
```dart
testWidgets('sorts recipes by rating descending', (WidgetTester tester) async {
  // Setup recipes with different ratings
  mockDb.recipes[1]!.rating = 5.0; // Apple Pie
  mockDb.recipes[2]!.rating = 3.5; // Banana Bread
  mockDb.recipes[3]!.rating = 4.2; // Chocolate Cake

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: RecipeSorter(databaseHelper: mockDb),
      ),
    ),
  );

  // Open sort menu
  await tester.tap(find.byType(PopupMenuButton));
  await tester.pumpAndSettle();

  // Select "Rating (High to Low)"
  await tester.tap(find.text('Rating (High to Low)'));
  await tester.pumpAndSettle();

  // Verify order: Apple Pie (5.0) → Chocolate Cake (4.2) → Banana Bread (3.5)
  final applePieY = tester.getTopLeft(find.text('Apple Pie')).dy;
  final chocolateCakeY = tester.getTopLeft(find.text('Chocolate Cake')).dy;
  final bananaBreadY = tester.getTopLeft(find.text('Banana Bread')).dy;

  expect(applePieY < chocolateCakeY, isTrue,
         reason: 'Apple Pie (5.0) should be before Chocolate Cake (4.2)');
  expect(chocolateCakeY < bananaBreadY, isTrue,
         reason: 'Chocolate Cake (4.2) should be before Banana Bread (3.5)');
});
```

✓ Test code added
Applies all patterns learned from debugging TEST 3!

Run: flutter test test/widgets/recipe_sorter_test.dart --name "rating descending"

Does the test pass? (y/n)
```

**User**: y

```
✅ TEST 4/6 complete

Progress: 4/6 tests complete ████████░ 66%

Perfect! The patterns from debugging TEST 3 made TEST 4 much smoother.

Notice how we:
- Used the same PopupMenuButton interaction pattern
- Used the same position-based verification
- Added ratings to mock data before the test
- Kept the same clear structure

This is the power of single-test-at-a-time: we learned from TEST 3's
debugging and immediately applied it to TEST 4 successfully!

Ready for TEST 5/6? (y/n)
```

**User**: y

---

## TEST 5/6 & 6/6: Smooth Completion

```
[TEST 5 and TEST 6 proceed smoothly using all the established patterns]

✅ TEST 5/6 complete
✅ TEST 6/6 complete

Progress: 6/6 tests complete ████████████ 100%

🎉 All 6 tests complete!

═══════════════════════════════════════════
PHASE 3 COMPLETE - WITH LESSONS LEARNED
═══════════════════════════════════════════

Tests Implemented: 6/6 (100%)
Tests Passing: 6/6 (100%)
Tests Required Debugging: 1 (TEST 3)
Pattern Errors Propagated: 0 ✓

Debugging Impact Analysis:
══════════════════════════════════════════

TEST 3 Failed Initially:
- Issue: Wrong PopupMenuButton interaction pattern
- Debug iterations: 2
- Time spent debugging: ~5 minutes
- Pattern learned: PopupMenuButton + position verification

Tests Saved by Debugging TEST 3:
- TEST 4: Would have failed with same error
- TEST 5: Would have failed (also uses PopupMenuButton)
- TEST 6: Would have failed (same pattern)

If we had batched all 6 tests:
❌ Write all 6 → 4 fail (TEST 3-6) → Fix all 4 → Rerun → Pass
   Time wasted: ~15-20 minutes, frustration: HIGH

With single-test-at-a-time:
✅ TEST 3 fails → Fix TEST 3 → TEST 4-6 succeed immediately
   Time saved: ~10-15 minutes, frustration: LOW
   Pattern errors prevented: 3 tests

Key Patterns Established:
1. PopupMenuButton: tap byType → pumpAndSettle → tap item
2. Position verification: getTopLeft().dy comparison
3. Direct find.text() over complex tree traversal
4. Reason messages in expects
5. Mock data preparation in test body

Breakthrough Moment:
TEST 3's second debugging iteration discovered that position-based
verification is MORE RELIABLE than widget tree traversal. This
insight improved TEST 4-6 before they were even written!

═══════════════════════════════════════════

Final verification:
```bash
flutter test test/widgets/recipe_sorter_test.dart
```

All tests pass together? (y/n)
```

**User**: y

---

## Analysis: Why Single-Test-At-A-Time Saved Time

### Scenario Comparison

**IF we had batched all 6 tests:**
```
Write TEST 1 ━━━━━ (5 min)
Write TEST 2 ━━━━━ (5 min)
Write TEST 3 ━━━━━ (5 min) ← Wrong pattern
Write TEST 4 ━━━━━ (5 min) ← Wrong pattern
Write TEST 5 ━━━━━ (5 min) ← Wrong pattern
Write TEST 6 ━━━━━ (5 min) ← Wrong pattern
                   ────────
                   30 minutes writing

Run all ━ 4 tests fail (TEST 3-6)

Debug TEST 3 ━━━━━━━━━━ (10 min)
Fix TEST 3 ━ (2 min)
Fix TEST 4 ━ (2 min)
Fix TEST 5 ━ (2 min)
Fix TEST 6 ━ (2 min)
                   ────────
                   18 minutes fixing

TOTAL: 48 minutes
FRUSTRATION: High (4 failures at once)
```

**With single-test-at-a-time (actual):**
```
Write & verify TEST 1 ━━━━━━ (7 min) ✓
Write & verify TEST 2 ━━━━━━ (7 min) ✓
Write TEST 3 ━━━━━━━━━━━━━━━ (5 min)
  Verify ━ FAIL
  Debug iteration 1 ━━━━━ (3 min)
  Debug iteration 2 ━━━━━ (3 min) ✓
Write & verify TEST 4 ━━━━━━ (6 min) ✓ ← Pattern applied, works first try
Write & verify TEST 5 ━━━━━━ (6 min) ✓ ← Pattern applied, works first try
Write & verify TEST 6 ━━━━━━ (6 min) ✓ ← Pattern applied, works first try
                              ────────
TOTAL: 43 minutes (saves 5 minutes)
FRUSTRATION: Low (only 1 failure, immediately addressed)
LEARNING: High (pattern applied to 3 subsequent tests)
```

**But wait, there's more:**
The time savings calculation doesn't include:
- Mental context switching cost when fixing 4 tests
- Risk of introducing NEW errors while fixing multiple tests
- Higher cognitive load from multiple simultaneous failures
- Difficulty tracking which fix applies to which test

**Real time savings: ~10-15 minutes**
**Real frustration reduction: Significant**
**Real learning improvement: 3 tests automatically improved**

---

## Key Takeaways

### 1. Failures Caught Early
TEST 3 failure was isolated and debugged before it could spread to TEST 4-6.

### 2. Pattern Learning Applied Immediately
The "position verification" pattern discovered while debugging TEST 3
was immediately applied to TEST 4-6, preventing 3 more failures.

### 3. Debugging Was Manageable
With only one test failing at a time, debugging was:
- Focused (only one test to think about)
- Fast (clear cause-effect relationship)
- Educational (learned pattern applied to remaining tests)

### 4. No Wasted Work
Never wrote TEST 4-6 with the wrong pattern because TEST 3 caught
the error first.

### 5. Progressive Confidence
- TEST 1-2: Building foundation
- TEST 3: Encountered challenge, learned from it
- TEST 4-6: Applied learning, smooth execution

### 6. Zero Error Propagation
The anti-pattern (wrong PopupMenuButton interaction) was caught in ONE test,
not propagated to THREE tests.

---

## Debugging Patterns Demonstrated

1. **Identify Common Issues**: Listed typical problems for the test type
2. **Request Exact Error**: Asked for precise error message, not guesses
3. **Diagnose Root Cause**: Explained why the error occurred
4. **Provide Fix**: Gave corrected code with explanation
5. **Iterate If Needed**: Second debugging round when first fix insufficient
6. **Extract Pattern**: Identified reusable pattern from the fix
7. **Document Learning**: Explicitly noted pattern for future tests
8. **Apply Immediately**: Used pattern in next test

---

## Comparison: Error Propagation Impact

**Batched Approach:**
```
TEST 3: Wrong pattern
TEST 4: Wrong pattern (copied from TEST 3)
TEST 5: Wrong pattern (copied from TEST 3)
TEST 6: Wrong pattern (copied from TEST 3)
─────────────────────────
Result: 4 tests to fix, same error repeated 4 times
```

**Single-Test-At-A-Time:**
```
TEST 3: Wrong pattern → Debug → Learn correct pattern
TEST 4: Correct pattern (applied from TEST 3)
TEST 5: Correct pattern (applied from TEST 3)
TEST 6: Correct pattern (applied from TEST 3)
─────────────────────────
Result: 1 test to fix, pattern applied 3 times
```

**Error Propagation Prevented: 3 tests**
**Debugging Sessions Prevented: 3 sessions**
**Frustration Prevented: Immeasurable**

---

This example demonstrates the core value of single-test-at-a-time: **preventing error propagation through immediate feedback and learning**.
