# Gastrobrain Code Review Agent Skill

Systematic pre-merge code review using 7-checkpoint verification to ensure quality standards before merging to develop.

## Quick Start

```bash
# From your feature branch ready to merge
# In Claude Code, invoke the skill:
/gastrobrain-code-review

# Or use trigger phrases:
"Review #268"
"Pre-merge check for #199"
"Ready to merge #XXX"
```

The skill will:
1. Load issue and roadmap automatically
2. Run 7 systematic checkpoints
3. Provide clear pass/warning/fail status
4. Generate merge instructions if approved

## Core Philosophy

**Systematic Quality → Checkpoint Verification → Merge Confidence**

Never skip checkpoints. Always verify each aspect before proceeding.

### Why Checkpoint-Based Review?

**The Problem with Ad-Hoc Reviews:**
```
❌ Quick scan → "Looks good" → Merge → Issues discovered in develop
Risk: HIGH | Confidence: LOW | Consistency: LOW
```

**The Checkpoint Advantage:**
```
✅ CP1 → CP2 → CP3 → CP4 → CP5 → CP6 → CP7 → Merge with confidence
Risk: LOW | Confidence: HIGH | Consistency: HIGH
```

## Seven Standard Checkpoints

Every code review follows this systematic structure:

### 1. Git Status & Branch Verification (~2 min)
- Clean working directory
- Branch properly synced
- No merge conflicts with develop
- Branch up to date with remote

### 2. Roadmap Completion Verification (~2 min)
- All 4 phases complete
- All checkboxes marked
- No incomplete tasks

### 3. Acceptance Criteria Validation (~3 min)
- All issue acceptance criteria met
- User confirmation for manual criteria
- Automated verification where possible

### 4. Technical Standards (~5 min)
- `flutter analyze`: 0 errors required
- `flutter test`: 100% pass rate required
- Coverage maintained or improved

### 5. Code Quality Checks (~3 min)
- No debug code (print, debugPrint)
- No critical TODO comments
- Error handling adequate
- Code documented

### 6. Localization Verification (~2 min)
- New UI strings in both ARB files (if UI changed)
- No hardcoded strings
- Date/time formatting with locale
- Skip if no UI changes

### 7. Merge Readiness Assessment (~3 min)
- Summary of all checkpoints
- Overall status (Approved/Conditional/Rejected)
- Merge instructions if approved

**Total Time**: ~15-20 minutes for comprehensive review

## Status Indicators

- **✓ PASS**: Checkpoint passed, no issues
- **⚠ WARNING**: Minor issues, can proceed with notes
- **✗ FAIL**: Blocking issues, cannot proceed
- **ℹ INFO**: Informational note

## Quality Standards

### Must-Have (Blocking)
- ✗ Flutter analyze errors
- ✗ Test failures
- ✗ Unmet critical acceptance criteria
- ✗ Breaking backward compatibility

### Should-Have (Warning)
- ⚠ Decreased test coverage
- ⚠ Missing README updates
- ⚠ TODO comments
- ⚠ Minor localization gaps

### Nice-to-Have (Note)
- ℹ Code style improvements possible
- ℹ Additional test cases could be added

## Example Reviews

### Simple Bug Fix (All Pass)
See: `examples/simple_bug_fix_review.md`
- **Scenario**: Date formatting fix
- **Checkpoints**: 7/7 passed
- **Time**: ~10 minutes
- **Result**: Clean approval

### Feature with Database Migration
See: `examples/feature_with_database_migration.md` (to be created)
- **Scenario**: Add notes field to recipes
- **Checkpoints**: 7/7 with minor warnings
- **Time**: ~18 minutes
- **Result**: Approved with notes

### Review with Failures
See: `examples/review_with_failures.md` (to be created)
- **Scenario**: Feature with test failures
- **Checkpoints**: Failed at CP4 (tests)
- **Result**: Remediation guidance provided

## Merge Decision Matrix

**Automatic Approval** (all true):
- ✓ All checkpoints pass
- ✓ No blocking issues
- ✓ < 3 minor warnings
- ✓ All acceptance criteria met
→ Approved for merge

**Conditional Approval** (some true):
- ⚠ 3-5 warnings
- ⚠ Minor gaps with follow-ups
- ⚠ Some manual checks uncertain
→ Proceed with caution

**Rejection** (any true):
- ✗ Any checkpoint fails
- ✗ Critical criteria unmet
- ✗ Tests failing
- ✗ Analyze errors
→ Fix issues first

## Automated vs Manual Checks

### Automated Checks (Tool Runs)
- Git status and branch sync
- Flutter analyze
- Flutter test
- Test coverage
- Debug code detection (grep)
- TODO detection (grep)
- ARB file completeness

### Manual Checks (User Confirms)
- Acceptance criteria met
- Complex logic documented
- Error handling complete
- UI looks correct
- Edge cases considered

## Failure Remediation

If checkpoint fails:
1. **Stop** - Don't proceed to next checkpoint
2. **Diagnose** - Understand what failed
3. **Fix** - Provide specific remediation steps
4. **Verify** - Re-run failed checkpoint
5. **Continue** - Only proceed when passing

Example:
```
✗ CHECKPOINT 4 FAILED: Tests failing

Issues: 3/618 tests failing

Remediation:
1. Run failed test with verbose: flutter test path/to/test.dart --verbose
2. Fix issue
3. Re-run: flutter test
4. Verify all pass
5. Continue to Checkpoint 5

After fixing, re-run review from Checkpoint 4.
```

## Merge Instructions Format

When approved, skill provides step-by-step merge instructions:

```
Step 1: git status → verify clean
Step 2: git checkout develop && git pull
Step 3: git merge --no-ff feature/XXX
Step 4: flutter analyze && flutter test → verify
Step 5: git push origin develop
Step 6: gh issue close XXX
Step 7: Delete branch (optional)
```

With verification checkboxes at each step.

## When to Use This Skill

✅ **Use when:**
- Feature branch complete, ready for develop
- Want systematic pre-merge check
- Need confidence all standards met
- Preparing for merge

❌ **Don't use when:**
- Mid-development (not ready to merge)
- Reviewing individual commits
- Architectural planning
- Just running tests (use flutter test directly)

## Success Metrics

**This skill succeeds when:**
- ✅ Fewer bugs after merge to develop
- ✅ Consistent quality standards
- ✅ Clear merge decisions
- ✅ No surprises post-merge
- ✅ High confidence in merges

## File Structure

```
gastrobrain-code-review/
├── SKILL.md                                 # Complete skill documentation
├── README.md                                # This file
├── templates/
│   └── code_review_checkpoint_template.md  # Format for each checkpoint
└── examples/
    ├── simple_bug_fix_review.md            # All checkpoints pass
    ├── feature_with_database_migration.md  # Comprehensive review (pending)
    └── review_with_failures.md             # Failure + remediation (pending)
```

## References

- **SKILL.md**: Complete checkpoint documentation
- **Template**: Exact format for each checkpoint
- **Examples**: Real-world review scenarios
- **Master Index**: `../../docs/architecture/gastrobrain-skills-master-index.md`

## Quick Reference

**Triggers:**
- "Review #XXX"
- "Pre-merge check for #XXX"
- "Ready to merge #XXX"
- "/gastrobrain-code-review"

**Checkpoints:**
1. Git Status (2 min)
2. Roadmap (2 min)
3. Acceptance (3 min)
4. Technical (5 min)
5. Quality (3 min)
6. Localization (2 min)
7. Merge Ready (3 min)

**Total Time**: ~15-20 minutes

**Success Rate**: High when used systematically

---

**Version**: 1.0.0
**Last Updated**: January 2026
**Status**: Ready for use
