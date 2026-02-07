# Debugging Framework

Structured 5-checkpoint approach to investigating and resolving test failures.

---

## The Debugging Mindset

**Principles:**
1. **Understand before fixing** - Never change code until you know the root cause
2. **Hypothesis-driven** - Form a theory, then test it with evidence
3. **One variable at a time** - Change one thing, observe the result
4. **Document findings** - Record what you tried and what you found
5. **Validate thoroughly** - A fix isn't complete until regression-tested

---

## 5-Checkpoint Process

### Checkpoint 1: Failure Understanding

**Goal:** Know exactly what failed and what was expected.

**Questions to answer:**
- What test failed? (file, line, name)
- What does this test validate? (read the test code)
- What was expected? (the assertion)
- What actually happened? (the error)
- When did it start failing? (recent change?)

**Investigation tools:**
```bash
# Run the specific failing test with verbose output
flutter test test/path/to/test.dart --name="test name" --reporter=expanded

# Check recent changes to affected code
git log --oneline -10 -- lib/path/to/code.dart

# Check recent changes to the test
git log --oneline -10 -- test/path/to/test.dart
```

**Output:** Clear statement of expected vs actual behavior.

---

### Checkpoint 2: Root Cause Hypothesis

**Goal:** Form a ranked list of possible causes.

**Hypothesis categories:**

| Category | Description | Likelihood Indicators |
|----------|-------------|----------------------|
| Code Issue | Production code has a bug | Test was passing before code change |
| Test Issue | Test expectation is wrong | Code hasn't changed recently |
| Setup Issue | Mock/fixture misconfigured | Test setup recently modified |
| Timing Issue | Race condition or async problem | Fails intermittently |
| Environment | Platform or dependency issue | Works locally, fails in CI |

**How to rank hypotheses:**
1. Check git log for recent changes (most likely cause)
2. Match error type to known patterns (see failure_patterns.md)
3. Consider if test was recently added (higher chance of test issue)
4. Check if other tests in same file fail (suggests shared setup)

**Output:** Ranked list of 2-4 hypotheses with evidence for each.

---

### Checkpoint 3: Investigation

**Goal:** Confirm or reject the primary hypothesis.

**Investigation techniques:**

**For code issues:**
```dart
// Add temporary debug output
debugPrint('Variable value: $variable');

// Check specific state
expect(actual, isNotNull, reason: 'Should not be null at this point');
```

**For test issues:**
```dart
// Isolate the test
test('ISOLATED - specific behavior', () {
  // Minimal test that checks one thing
});

// Add intermediate assertions
expect(setup, isNotNull, reason: 'Setup should complete');
expect(intermediate, equals(expected), reason: 'Step 1 should produce X');
expect(final, equals(expected), reason: 'Final should produce Y');
```

**For setup issues:**
```dart
// Print mock state
debugPrint('Mock recipes: ${mockDb.recipes.length}');
debugPrint('Mock configured: ${mockDb.isConfigured}');
```

**For timing issues:**
```dart
// Replace pumpAndSettle with explicit pumps
await tester.pump();                    // Single frame
await tester.pump(Duration(seconds: 1)); // Wait 1 second
await tester.pumpAndSettle();           // Wait for animations
```

**Decision tree after investigation:**
```
Hypothesis Confirmed?
├── Yes → Proceed to Checkpoint 4 (Fix)
├── No → Form new hypothesis, repeat CP2-CP3
└── Unclear → Add more investigation steps
```

---

### Checkpoint 4: Fix Implementation

**Goal:** Apply targeted fix for the confirmed root cause.

**Fix strategies by cause type:**

| Cause | Fix Location | Approach |
|-------|-------------|----------|
| Code bug | Production code | Fix the logic |
| Wrong expectation | Test code | Update assertion |
| Missing setup | Test setup | Add/fix mock config |
| Race condition | Test or production | Add waits or fix async |
| Missing null check | Production code | Add null handling |

**Fix quality checklist:**
- [ ] Fix addresses the root cause (not a symptom)
- [ ] Fix is minimal (don't over-fix)
- [ ] Fix doesn't introduce new issues
- [ ] Fix follows existing code patterns
- [ ] Fix is documented if behavior changed

---

### Checkpoint 5: Fix Validation

**Goal:** Verify the fix works and doesn't break anything else.

**Validation levels:**

```
Level 1 (Always): Re-run the failing test
  └── Must pass

Level 2 (Always): Run all tests in the same file
  └── Must all pass

Level 3 (If code changed): Run component tests
  └── Must all pass

Level 4 (If high risk): Run full suite
  └── Must all pass
```

**Validation commands:**
```bash
# Level 1: Specific test
flutter test test/path/test.dart --name="test name"

# Level 2: Same file
flutter test test/path/test.dart

# Level 3: Component
flutter test test/core/services/

# Level 4: Full suite
flutter test
```

**If validation fails:**
- New failure in same file → Fix likely incomplete, revise
- New failure elsewhere → Fix introduced regression, investigate
- Original test still fails → Root cause was wrong, go back to CP2

---

## Debugging Quick Reference

### Common Commands

```bash
# Run single test with full output
flutter test test/path.dart --name="test" --reporter=expanded

# Run test with timeout override
flutter test test/path.dart --timeout=30s

# Run tests sequentially (for isolation)
flutter test test/path.dart --concurrency=1

# Check what changed recently
git diff HEAD~5 -- lib/ test/

# Find when a test started failing
git bisect start HEAD <last-known-good-commit>
git bisect good/bad
```

### Useful Debugging Patterns

```dart
// Dump widget tree in widget test
await tester.pumpWidget(app);
debugDumpApp(); // Prints full widget tree

// Check if widget exists before asserting
final finder = find.byKey(Key('my_key'));
debugPrint('Found ${finder.evaluate().length} widgets');

// Add timeout to specific test
testWidgets('my test', (tester) async {
  // test body
}, timeout: Timeout(Duration(seconds: 30)));
```

---

## When to Escalate

**Stop debugging and ask for help when:**
- After 3 failed hypotheses with no progress
- The failure is in framework code (not your code)
- The failure only reproduces in CI, not locally
- The fix requires architectural changes
- You've spent more than 30 minutes on one test failure
