# Failure Pattern Catalog

Common Flutter test failure patterns, their causes, and resolution strategies.

---

## Pattern 1: Null Safety Violations

### Symptoms

```
Null check operator used on a null value
type 'Null' is not a subtype of type 'String'
type 'Null' is not a subtype of type 'Future<List<Recipe>>'
```

### Common Causes

| Cause | Likelihood | How to Identify |
|-------|------------|-----------------|
| Mock returning null by default | High | Check mock setup |
| Missing field in test data | High | Check test fixture |
| Production code missing null check | Medium | Check code logic |
| Async operation returned null | Medium | Check Future chain |

### Investigation Steps

1. **Find the null variable** - Look at the stack trace for the exact line
2. **Trace backwards** - Where should the value have been set?
3. **Check mock config** - Is the mock returning what the code expects?
4. **Check production code** - Is there a missing null check?

### Typical Fixes

```dart
// Fix 1: Configure mock to return expected value
when(mockDb.getRecipe(any)).thenAnswer((_) async => testRecipe);

// Fix 2: Add null check in production code
final recipe = await dbHelper.getRecipe(id);
if (recipe == null) throw NotFoundException('Recipe $id not found');

// Fix 3: Fix test fixture
final testRecipe = Recipe(
  id: 'test-1',
  name: 'Test Recipe',  // Was missing, causing null
);
```

---

## Pattern 2: Timeout Failures

### Symptoms

```
Test timed out after 5 seconds
pumpAndSettle timed out because the widget tree kept rebuilding
```

### Common Causes

| Cause | Likelihood | How to Identify |
|-------|------------|-----------------|
| Animation loop (pumpAndSettle) | High | Check for ongoing animations |
| Timer preventing settle | High | Check for periodic timers |
| Unresolved Future | Medium | Check async operations |
| Infinite setState loop | Low | Check setState calls |

### Investigation Steps

1. **Replace pumpAndSettle** - Use `pump(Duration)` instead
2. **Check for animations** - CircularProgressIndicator, AnimatedWidget
3. **Check for timers** - Timer.periodic, Future.delayed
4. **Run in isolation** - Does it timeout alone?

### Typical Fixes

```dart
// Fix 1: Replace pumpAndSettle with explicit pump
// BEFORE (times out with animations):
await tester.pumpAndSettle();

// AFTER:
await tester.pump();
await tester.pump(const Duration(milliseconds: 500));

// Fix 2: Cancel timer in dispose
@override
void dispose() {
  _timer?.cancel();
  super.dispose();
}

// Fix 3: Increase timeout for slow operations
testWidgets('slow test', (tester) async {
  // test body
}, timeout: Timeout(Duration(seconds: 30)));
```

---

## Pattern 3: Expectation Mismatches

### Symptoms

```
Expected: 4
  Actual: 5
Expected: 'Breakfast'
  Actual: 'breakfast'
Expected: [Recipe A, Recipe B]
  Actual: [Recipe B, Recipe A]
```

### Common Causes

| Cause | Likelihood | How to Identify |
|-------|------------|-----------------|
| Production code changed | High | Check git log |
| Test expectation wrong | Medium | Verify expected value |
| Order-dependent assertion | Medium | Check if order matters |
| Case sensitivity | Low | Compare exact strings |
| Locale difference | Low | Check test locale setup |

### Investigation Steps

1. **Check recent changes** - `git log --oneline -5 -- <affected-file>`
2. **Verify expected value** - Is the test's expected value actually correct?
3. **Check ordering** - Does the code guarantee order? Use `containsAll` if not
4. **Check string format** - Case, whitespace, locale

### Typical Fixes

```dart
// Fix 1: Update expectation to match new code
expect(mealTypes.length, equals(5)); // Was 4, now 5 after adding 'snack'

// Fix 2: Use order-independent assertion
expect(result, containsAll(['A', 'B', 'C'])); // Instead of equals([...])

// Fix 3: Use case-insensitive comparison
expect(result.toLowerCase(), equals('breakfast'));

// Fix 4: Fix production code if expectation was correct
// In production code, fix the logic to return expected value
```

---

## Pattern 4: Widget Not Found

### Symptoms

```
The following TestFailure was thrown running a test:
Expected: exactly one matching node in the widget tree
  Actual: _TextFinder (found zero widgets)

No widget found with key Key('meal_type_dropdown')
```

### Common Causes

| Cause | Likelihood | How to Identify |
|-------|------------|-----------------|
| Widget key/text changed | High | Check current widget code |
| Conditional rendering | High | Check if widget has guard clause |
| Missing pump | Medium | Widget hasn't rendered yet |
| Wrong parent widget | Low | Widget in different subtree |

### Investigation Steps

1. **Check if key/text exists** in current production code
2. **Check conditions** - Is there an `if` guard? Is the condition met?
3. **Add pump calls** - Ensure widget has time to render
4. **Debug widget tree** - Use `debugDumpApp()` to see what's rendered

### Typical Fixes

```dart
// Fix 1: Update finder to match current key
find.byKey(Key('meal_type_selector')); // Key was renamed

// Fix 2: Ensure condition is met in test setup
mockDb.addRecipes([testRecipe]); // Widget shows only when recipes exist
await tester.pumpAndSettle();

// Fix 3: Add pump before finding
await tester.pump(); // Let widget render first
expect(find.byKey(Key('my_widget')), findsOneWidget);

// Fix 4: Use debugDumpApp to see what's actually rendered
debugDumpApp(); // Print widget tree to console
```

---

## Pattern 5: State After Dispose

### Symptoms

```
setState() called after dispose()
Looking up a deactivated widget's ancestor is unsafe
A RenderObject was not laid out
```

### Common Causes

| Cause | Likelihood | How to Identify |
|-------|------------|-----------------|
| Async callback after dispose | High | Check async code in widget |
| Timer not cancelled | High | Check dispose() method |
| Stream not closed | Medium | Check StreamSubscription |
| Navigator pop during async | Medium | Check navigation timing |

### Investigation Steps

1. **Check dispose method** - Is everything cleaned up?
2. **Check async callbacks** - Do they check `mounted`?
3. **Check timers/streams** - Are they cancelled in dispose?
4. **Check test timing** - Does test navigate away mid-async?

### Typical Fixes

```dart
// Fix 1: Check mounted before setState
if (mounted) {
  setState(() {
    _data = newData;
  });
}

// Fix 2: Cancel timer in dispose
@override
void dispose() {
  _debounceTimer?.cancel();
  _subscription?.cancel();
  super.dispose();
}

// Fix 3: Use CancelableOperation for async work
final _cancelable = CancelableOperation.fromFuture(
  fetchData(),
);

@override
void dispose() {
  _cancelable.cancel();
  super.dispose();
}
```

---

## Pattern 6: Mock Configuration Issues

### Symptoms

```
MissingStubError: 'getAllRecipes'
No matching calls (possibly due to a missing stub)
type 'Null' is not a subtype of type 'Future<X>'
```

### Common Causes

| Cause | Likelihood | How to Identify |
|-------|------------|-----------------|
| Missing mock stub | High | Method not configured |
| Wrong argument matcher | Medium | Check when() arguments |
| Mock reset between tests | Medium | Check setUp/tearDown |
| New method not mocked | High | Recently added method |

### Typical Fixes

```dart
// Fix 1: Add missing stub
when(mockDb.getAllRecipes()).thenAnswer((_) async => [testRecipe]);

// Fix 2: Use correct matcher
when(mockDb.getRecipe(any)).thenAnswer((_) async => testRecipe);
// NOT: when(mockDb.getRecipe('specific-id'))... // Only matches one ID

// Fix 3: Configure in setUp
setUp(() {
  mockDb = TestSetup.setupMockDatabase();
  // All stubs configured here, available to all tests
});
```

---

## Pattern 7: Overflow and Layout Errors

### Symptoms

```
A RenderFlex overflowed by 42.0 pixels on the bottom
RenderBox was not laid out
BoxConstraints forces an infinite width
```

### Common Causes

| Cause | Likelihood | How to Identify |
|-------|------------|-----------------|
| Small test viewport | High | Test uses default 800x600 |
| Missing Expanded/Flexible | Medium | Check parent layout |
| Unbounded constraints | Medium | Check ListView/Column nesting |

### Typical Fixes

```dart
// Fix 1: Set test viewport size
testWidgets('handles small screen', (tester) async {
  tester.view.physicalSize = Size(400, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  // ...
});

// Fix 2: Wrap in constrained parent for test
await tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 400,
        height: 600,
        child: WidgetUnderTest(),
      ),
    ),
  ),
);
```

---

## Quick Reference: Error to Pattern

| Error Message Contains | Pattern | Section |
|-----------------------|---------|---------|
| `null value` / `Null is not a subtype` | Null Safety | Pattern 1 |
| `timed out` / `kept rebuilding` | Timeout | Pattern 2 |
| `Expected:` / `Actual:` | Expectation Mismatch | Pattern 3 |
| `found zero widgets` / `no widget found` | Widget Not Found | Pattern 4 |
| `after dispose` / `deactivated widget` | State After Dispose | Pattern 5 |
| `MissingStubError` / `missing stub` | Mock Config | Pattern 6 |
| `overflowed` / `not laid out` | Overflow/Layout | Pattern 7 |
