# Gastrobrain Testing Implementation Agent Skill

An agent skill for implementing Phase 3 (Testing) from issue roadmaps using a **single-test-at-a-time approach** that ensures quality and prevents error propagation.

## Quick Start

```bash
# From your branch for an issue (e.g., feature/250-meal-type-filter)
# In Claude Code, invoke the skill:
/gastrobrain-testing-implementation
```

The skill will:
1. Detect your current branch and issue number
2. Load the issue roadmap
3. Analyze Phase 3 (Testing) requirements
4. Generate a test plan
5. Implement tests **ONE AT A TIME** with verification between each

## Core Philosophy

**Generate → Verify → Learn → Repeat**

Never batch multiple tests. Always verify each test passes before writing the next one.

### Why One Test at a Time?

**The Problem with Batching:**
```
❌ Write 8 tests → Run all → 7 fail with same pattern error → Fix all 7
Time wasted: High | Frustration: High | Risk: High
```

**The Single Test Advantage:**
```
✅ Write test 1 → Verify → Learn → Write test 2 → Verify → Learn
Time wasted: None | Frustration: Low | Risk: Low
```

### Key Benefits

1. **Immediate Feedback**: Know if your approach works after first test
2. **Pattern Learning**: Each test teaches you about the codebase
3. **Error Isolation**: Failures are easy to diagnose (only one new test)
4. **Progressive Refinement**: Each test is better than the last
5. **User Control**: Full visibility and control over pace
6. **No Wasted Work**: Never write 7 tests only to rewrite them all

## File Structure

```
gastrobrain-testing-implementation/
├── SKILL.md                              # Main skill documentation
├── README.md                             # This file
├── templates/
│   └── single_test_loop_template.md     # Template showing loop structure
└── examples/
    ├── success_sequence_example.md      # 5-test sequence with learning
    └── failure_recovery_example.md      # Debugging mid-sequence
```

## How It Works

### Phase 1: Analysis
- Detects current branch: `feature/XXX-description`
- Extracts issue number: `XXX`
- Loads roadmap: `docs/planning/0.1.X/ISSUE-XXX-ROADMAP.md`
- Locates Phase 3 (Testing) section

### Phase 2: Test Plan
- Analyzes Phase 3 requirements
- Breaks into test categories (setup, core, persistence, edge cases)
- Lists individual tests needed with count
- **Does NOT generate tests yet** - just the plan

### Phase 3: Single Test Loop
For EACH test (repeat until all complete):
1. Generate **ONE** test (with complete implementation)
2. Show run command
3. Ask: "Does the test pass? (y/n)"
4. **WAIT** for user response
5. If **yes**: Mark complete, show progress, continue to next test
6. If **no**: Debug, fix, retry current test until it passes
7. After success: Document learnings, apply to next test

### Phase 4: Completion
- Final verification: Run all tests together
- Summary of implementation
- Patterns learned
- Next steps

## Interaction Protocol

```
TEST 1/N: [Test name]
[Generate ONE test]
Run: flutter test [specific command]
Does the test pass? (y/n)
[WAIT]

[If y:]
✅ TEST 1/N complete
Progress: 1/N tests complete [progress bar]
Ready for TEST 2/N? (y/n)

[If n:]
❌ TEST 1/N FAILED
Let's debug...
[Help fix]
[Try again]
Does it pass now? (y/n)
[Loop until pass]
```

## Learning Between Tests

After each successful test, the skill notes:
- Mock setup patterns that worked
- Effective interaction patterns
- Successful assertion styles
- Timing strategies (pump vs pumpAndSettle)
- Finder approaches that were effective

These learnings are **immediately applied** to subsequent tests, preventing repeated errors.

## Test Categories

### Setup (1 test typically)
- File creation and imports
- Mock initialization
- Test group structure

### Core Functionality (varies by feature)
- Primary feature behavior
- User interactions
- UI state changes

### Data Persistence (varies by feature)
- Save, load, update, delete operations
- Database verification

### Edge Cases (required by Issue #39)
- Null handling
- Empty collections
- Boundary values
- Error states

## Examples

### Success Sequence
See `examples/success_sequence_example.md` for a complete 5-test implementation where all tests pass and demonstrate progressive learning.

**Highlights:**
- Each test builds on knowledge from previous tests
- Clear pattern evolution
- No errors propagated
- 25 minutes vs 45+ minutes with batching

### Failure Recovery
See `examples/failure_recovery_example.md` for a 6-test implementation where TEST 3 fails and requires debugging before continuing.

**Highlights:**
- TEST 3 fails with PopupMenuButton interaction error
- Debugging iterations fix the issue
- Pattern learned from debugging TEST 3
- TEST 4-6 succeed immediately using learned pattern
- **3 errors prevented** by catching issue in TEST 3

## Success Criteria

The skill succeeds when:
1. ✓ No batch testing (always one test at a time)
2. ✓ Clear progress tracking (TEST X/Y)
3. ✓ Learning visible between tests
4. ✓ Failures handled before continuing
5. ✓ User has full control (wait for y/n)
6. ✓ Pattern errors caught in first test, not propagated
7. ✓ Complete tests (no TODOs)
8. ✓ Follows project patterns

## Testing Patterns Reference

### Widget Tests
- Location: `test/widgets/`
- Keys: `{screen}_{field}_field`
- Use `pumpAndSettle()` after interactions
- MaterialApp wrapper for dialogs/navigation

### Unit Tests
- Location: `test/core/services/`
- MockDatabaseHelper for service dependencies
- Test one method/behavior per test

### MockDatabaseHelper
- Uses internal maps: `recipes`, `meals`, `settings`, etc.
- Check maps directly, not method calls
- Standard setup in `setUp()` method

### Edge Cases (Issue #39)
- Null handling
- Empty collections
- Boundary values
- Error states

## When to Use This Skill

✅ **Use when:**
- Working on Phase 3 (Testing) of an issue roadmap
- Need to implement multiple tests for a feature
- Want to ensure quality and prevent error propagation

❌ **Don't use when:**
- Quick single test addition (just write it)
- Fixing existing tests (debug directly)
- Running test suites (use `flutter test`)

## Template Reference

See `templates/single_test_loop_template.md` for the exact format used for:
- Initial test plan output
- Each test generation
- Success responses
- Failure debugging
- Progress tracking
- Learning documentation

## Anti-Patterns to Avoid

### ❌ NEVER DO:
1. **Batch tests**: Generate multiple tests at once
2. **Assume success**: Don't verify tests pass
3. **Proceed with failures**: Fix before continuing
4. **Ignore learnings**: Apply patterns from previous tests
5. **Generic debugging**: Ask for specific error messages

### ✅ ALWAYS DO:
1. **One test at a time**: Generate exactly one test per iteration
2. **Wait for verification**: Require user "y/n" response
3. **Debug immediately**: Stop and fix failures before next test
4. **Document learnings**: Note patterns that work
5. **Apply patterns**: Use learnings in subsequent tests

## References

- **Issue #39**: Edge case testing standards
- **`test/widgets/`**: Widget test patterns
- **`test/core/services/`**: Unit test patterns
- **`test/mocks/mock_database_helper.dart`**: Mock setup reference
- **`docs/testing/`**: Testing documentation
- **`CLAUDE.md`**: Development workflow and patterns

---

**Remember**: Quality over speed. One working test is worth more than ten broken tests.

## Version

**v1.0.0** - Initial release with single-test-at-a-time methodology
