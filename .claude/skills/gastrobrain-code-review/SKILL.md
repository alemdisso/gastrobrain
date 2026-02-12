---
name: gastrobrain-code-review
description: Performs systematic pre-merge code review using checkpoint-based verification to ensure quality standards before merging to develop branch
version: 1.0.0
---

# Gastrobrain Code Review Agent

## Purpose

Performs comprehensive code review before merging feature branches to develop, using a **checkpoint-based verification system** that systematically validates quality, completeness, and adherence to project standards.

**Core Philosophy**: Systematic Quality → Checkpoint Verification → Merge Confidence

## When to Use This Skill

Use this skill when:
- Ready to merge feature branch to develop
- Want pre-merge quality verification
- Need systematic review checklist
- Want to verify all acceptance criteria met
- Need confirmation all tests and standards pass
- Want merge readiness assessment

**Triggers**:
- "Review code for #XXX"
- "Ready to merge #XXX"
- "Pre-merge check for #XXX"
- "Code review before merging"
- "/gastrobrain-code-review"

**DO NOT use this skill for:**
- During active development (mid-feature)
- For reviewing individual commits
- For architectural planning (use planning skill)
- For implementing code (use implementation skill)

## Checkpoint-Based Review System

### Why Systematic Checkpoints?

**The Problem with Ad-Hoc Reviews:**
```
❌ BAD: Quick scan → "Looks good" → Merge → Issues discovered in develop
Risk: High (quality issues reach main branch)
Confidence: Low (unsure what was checked)
Consistency: Low (different things checked each time)
```

**The Checkpoint Advantage:**
```
✅ GOOD: CP1 (git) → CP2 (roadmap) → CP3 (criteria) → ... → Merge with confidence
Risk: Low (systematic verification)
Confidence: High (everything checked)
Consistency: High (same checks every time)
```

### Key Benefits

1. **Completeness**: Nothing overlooked (systematic checklist)
2. **Quality Assurance**: Technical standards verified
3. **Acceptance Validation**: All criteria explicitly checked
4. **Issue Prevention**: Problems caught before merge
5. **Merge Confidence**: Clear approval based on evidence
6. **Audit Trail**: Record of what was verified

## Seven Standard Checkpoints

### Overview

Every code review follows this structure:

1. **Git Status & Branch Verification** - Clean working state
2. **Roadmap Completion** - All phases complete
3. **Acceptance Criteria** - All requirements met
4. **Technical Standards** - Tests, analyze, coverage
5. **Code Quality** - Debug code, TODOs, comments
6. **Localization** - i18n requirements (if UI changes)
7. **Merge Readiness** - Final assessment and instructions

### Checkpoint Flow

```
Start Review
    ↓
CP1: Git Status ───→ [Issues?] ──Yes──→ Remediate ──→ Retry CP1
    ↓ No                                                    ↓
CP2: Roadmap ──────→ [Issues?] ──Yes──→ Remediate ──→ Retry CP2
    ↓ No                                                    ↓
CP3: Acceptance ───→ [Issues?] ──Yes──→ Remediate ──→ Retry CP3
    ↓ No                                                    ↓
CP4: Technical ────→ [Issues?] ──Yes──→ Remediate ──→ Retry CP4
    ↓ No                                                    ↓
CP5: Code Quality ─→ [Issues?] ──Yes──→ Remediate ──→ Retry CP5
    ↓ No                                                    ↓
CP6: Localization ─→ [Issues?] ──Yes──→ Remediate ──→ Retry CP6
    ↓ No                                                    ↓
CP7: Merge Ready ──→ Generate merge instructions
    ↓
Approved (with notes)
```

## Context Detection

### Automatic Analysis

The skill automatically detects and analyzes:

```
1. Current branch: feature/XXX-description
2. Extract issue number: XXX
3. Fetch issue from GitHub: gh issue view XXX
4. Load roadmap: docs/planning/0.1.X/ISSUE-XXX-ROADMAP.md
5. Check git status: uncommitted changes, branch sync
6. Identify changed files: git diff develop...HEAD
7. Determine review focus: UI changes, DB changes, logic changes
```

### Initial Output

```
Code Review for Issue #XXX

Preparing systematic review...

Context:
- Branch: feature/XXX-description
- Issue: #XXX - [Title from GitHub]
- Roadmap: docs/planning/0.1.X/ISSUE-XXX-ROADMAP.md
- Base branch: develop
- Changed files: X files, +Y/-Z lines

Focus areas detected:
[✓ UI Changes / ✓ Database Migration / ✓ Service Logic / ✓ Testing]

Review will proceed through 7 systematic checkpoints:
1. Git Status & Branch Verification
2. Roadmap Completion
3. Acceptance Criteria Validation
4. Technical Standards (analyze, tests)
5. Code Quality Checks
6. Localization Verification [if UI changes]
7. Merge Readiness Assessment

Ready to begin systematic review? (y/n)
```

## Checkpoint 1: Git Status & Branch Verification

**Goal**: Ensure clean working state and proper branch alignment

### Automated Checks

```
1.1 - Working Directory Status:
Command: git status
Expected: "nothing to commit, working tree clean"
Status: [✓ Clean / ⚠ Uncommitted changes / ✗ Untracked files]

1.2 - Current Branch:
Command: git branch --show-current
Expected: feature/XXX-description
Status: [✓ Correct / ✗ Wrong branch]

1.3 - Branch Sync with Remote:
Command: git fetch origin && git status
Expected: "Your branch is up to date with 'origin/feature/XXX-description'"
Status: [✓ Up to date / ⚠ Behind / ⚠ Ahead / ✗ Diverged]

1.4 - Sync with Develop:
Command: git fetch origin develop && git merge-base --is-ancestor origin/develop HEAD
Expected: develop is ancestor (no missing commits)
Status: [✓ Up to date / ⚠ Behind develop]

1.5 - Merge Conflicts Check:
Command: git merge-tree $(git merge-base origin/develop HEAD) origin/develop HEAD
Expected: No conflicts
Status: [✓ No conflicts / ✗ Conflicts detected]
```

### Status Indicators

- **✓ PASS**: All checks green, ready to proceed
- **⚠ WARNING**: Minor issues (e.g., ahead of remote, need to push)
- **✗ FAIL**: Blocking issues (uncommitted changes, conflicts)

### Remediation

**If uncommitted changes:**
```
Fix:
1. Review uncommitted changes: git status
2. Either:
   a) Commit them: git add . && git commit -m "message"
   b) Stash them: git stash
   c) Discard them: git restore .

After fixing, re-run checkpoint 1.
```

**If behind develop:**
```
Fix:
1. Update develop: git fetch origin develop
2. Rebase on develop: git rebase origin/develop
3. Resolve conflicts if any
4. Force push: git push --force-with-lease origin feature/XXX-description

After fixing, re-run checkpoint 1.
```

**If merge conflicts detected:**
```
Warning: Merging to develop will cause conflicts.

Preview conflicts:
[Show conflict areas]

Options:
1. Fix now: Rebase on develop and resolve conflicts
2. Proceed with warning: Resolve during merge
3. Abort review: Fix issues first

Choice? (1/2/3)
```

## Checkpoint 2: Roadmap Completion

**Goal**: Verify all roadmap phases are complete

### Roadmap Analysis

```
Reading roadmap: docs/planning/0.1.X/ISSUE-XXX-ROADMAP.md

Analyzing phases...

Phase 1: Analysis & Understanding
- [✓] Task 1 description
- [✓] Task 2 description
- [✓] Task 3 description
Status: ✓ COMPLETE (3/3 tasks)

Phase 2: Implementation
- [✓] Subtask 1
- [✓] Subtask 2
- [⚠] Subtask 3 (checkbox not marked)
Status: ⚠ INCOMPLETE (2/3 tasks)

Phase 3: Testing
- [✓] All tests implemented
- [✓] Tests passing
Status: ✓ COMPLETE (2/2 tasks)

Phase 4: Documentation & Cleanup
- [✓] Code comments added
- [✗] README not updated
Status: ✗ INCOMPLETE (1/2 tasks)
```

### Status Assessment

```
Overall Roadmap Status: ⚠ MOSTLY COMPLETE

Complete Phases: 2/4
- ✓ Phase 1: Analysis & Understanding
- ⚠ Phase 2: Implementation (1 task unmarked)
- ✓ Phase 3: Testing
- ✗ Phase 4: Documentation (README missing)

Issues Found:
1. Phase 2, Task 3: Checkbox not marked (possible oversight?)
2. Phase 4: README update missing

Is Phase 2, Task 3 actually complete? (y/n)
[If yes: Update roadmap checkbox]
[If no: Task needs completion]
```

### Remediation

**If tasks incomplete:**
```
Remediation Required:

Issue: Phase 4 - README update missing

Steps to fix:
1. Open README.md
2. Add section documenting new feature
3. Include usage examples if applicable
4. Commit changes: git add README.md && git commit -m "docs: update README for #XXX"
5. Update roadmap: Mark Phase 4 task complete

After fixing:
- Update roadmap file
- Commit roadmap update
- Continue review from checkpoint 2

Fix now? (y/n)
```

## Checkpoint 3: Acceptance Criteria Validation

**Goal**: Verify all issue acceptance criteria are met

### Criteria Analysis

```
Loading acceptance criteria from issue #XXX...

From issue description:

Acceptance Criteria:

1. [Criterion 1 from issue]
   Type: [Automated / Manual verification]
   [If automated: ✓ Verified via test_name_test.dart]
   [If manual: User confirmation needed]
   Status: [Pending user confirmation]

2. [Criterion 2 from issue]
   Type: Manual verification
   Verification needed: [Is this requirement met? y/n]
   Status: [Pending]

3. [Criterion 3 from issue]
   Type: Automated
   ✓ Verified: test passes, feature works as expected
   Status: ✓ CONFIRMED

[Iterate through all criteria]
```

### User Confirmation Flow

```
Criterion 1: "Users can add notes to recipes"

This requires manual verification.

Questions:
1. Can you navigate to a recipe? (y/n)
2. Is there a notes field/button? (y/n)
3. Can you add text to notes? (y/n)
4. Does the note save and persist? (y/n)

[Collect user responses]

Result: [✓ ALL YES - PASS / ⚠ SOME NO - PARTIAL / ✗ MOSTLY NO - FAIL]
```

### Status Assessment

```
Acceptance Criteria Summary:

Total Criteria: 5
✓ Confirmed: 4
⚠ Partial: 1
✗ Failed: 0

Details:
✓ Criterion 1: Users can add notes to recipes
✓ Criterion 2: Notes persist across app restarts
✓ Criterion 3: Notes support multi-line text
⚠ Criterion 4: Notes have 500 char limit (not enforced in UI)
✓ Criterion 5: Empty notes are allowed

Overall Status: ⚠ MOSTLY MET (non-critical gap)

Issue: Criterion 4 - Character limit not shown in UI

Severity: ⚠ Minor (backend enforces limit, but UX could be better)

Options:
1. Fix now: Add character counter to UI
2. Create follow-up issue: Track as enhancement
3. Accept as-is: Note in merge decision

Choice? (1/2/3)
```

### Remediation

```
Creating follow-up issue for minor gap...

Created issue #XXY: "Add character counter to recipe notes field"
- Labeled as: enhancement
- Linked to: #XXX
- Assigned to: backlog

Criterion 4 marked as: ✓ PASS WITH FOLLOW-UP

Proceed to checkpoint 4? (y/n)
```

## Checkpoint 4: Technical Standards

**Goal**: Verify code quality through automated technical checks

### 4.1 - Flutter Analyze

```
Running: flutter analyze

Output:
Analyzing gastrobrain...
[Analysis progress...]

Result:
- 0 errors
- 0 warnings
- 0 hints

Status: ✓ PASS - No issues found
```

**If issues found:**
```
Result:
- 2 errors
- 5 warnings
- 3 hints

Issues:
ERROR: lib/widgets/recipe_dialog.dart:45
  - Undefined name 'recipeName'

ERROR: lib/core/services/recommendation_service.dart:120
  - Missing return statement

WARNING: lib/screens/meal_planning_screen.dart:89
  - Unused import 'package:flutter/material.dart'

[... more issues ...]

Status: ✗ FAIL - Must fix before merge

Remediation:
1. Fix all errors (blocking)
2. Fix all warnings (required)
3. Fix hints (recommended)

Commands to fix:
- View specific file: [command]
- Run analyze again: flutter analyze

Fix now? (y/n)
```

### 4.2 - Flutter Test

```
Running: flutter test

Output:
00:00 +0: loading test/...
[Test progress...]
00:05 +615: All tests passed!

Result:
- Total tests: 615
- Passed: 615
- Failed: 0
- Skipped: 0

Status: ✓ PASS - All tests passing
```

**If tests fail:**
```
Result:
- Total tests: 618
- Passed: 615
- Failed: 3
- Skipped: 0

Failed Tests:

1. test/widgets/recipe_notes_dialog_test.dart
   - "saves note with 500 characters"
   - Expected: true, Actual: false
   - Error: Character limit not enforced

2. test/core/services/recipe_service_test.dart
   - "validates note length"
   - Expected: ValidationException, Actual: no exception

3. test/integration/recipe_workflow_test.dart
   - "complete recipe creation with notes"
   - Timeout after 30s

Status: ✗ FAIL - Must fix failing tests

Remediation:
1. Fix failing tests (blocking)
2. Investigate test 3 timeout (may indicate real issue)

Commands:
- Run specific test: flutter test test/widgets/recipe_notes_dialog_test.dart
- Run with verbose: flutter test --verbose
- Debug test: [instructions]

Fix now? (y/n)
```

### 4.3 - Test Coverage (Optional)

```
Running: flutter test --coverage

Coverage Report:
- Overall: 87.3%
- Changed files: 89.1%

By Category:
- Widgets: 85.2%
- Services: 92.4%
- Models: 95.1%
- Utils: 78.9%

Status: ✓ PASS - Coverage maintained

[If coverage decreased significantly:]
Status: ⚠ WARNING - Coverage decreased from 89% to 87%

Recommendation: Consider adding tests for uncovered code
- lib/widgets/recipe_notes_field.dart: 62% coverage
- lib/core/services/note_validator.dart: 71% coverage

Proceed anyway? (y/n)
```

### Overall Technical Status

```
Checkpoint 4 Summary:

4.1 - Flutter Analyze: ✓ PASS
4.2 - Flutter Test:    ✓ PASS (615 tests)
4.3 - Test Coverage:   ✓ PASS (87.3%)

Overall Status: ✓ PASS - All technical standards met

Proceed to checkpoint 5? (y/n)
```

## Checkpoint 5: Code Quality Checks

**Goal**: Manual verification of code quality standards

### 5.1 - Debug Code Detection

```
Checking for debug code...

Searching for print() statements:
Command: grep -r "print(" lib/ --include="*.dart" | grep -v "// print"

Result: [✓ None found / ⚠ X instances found]

If found:
Files with print():
- lib/screens/debug_screen.dart:45 (OK - debug screen)
- lib/widgets/recipe_card.dart:89 (REMOVE - debug leftover)

Searching for debugPrint():
Result: [✓ None found / ⚠ X instances found]

Searching for debug flags:
Pattern: kDebugMode
Result: [✓ Properly used / ⚠ Improper usage]

Status: [✓ CLEAN / ⚠ MINOR ISSUES / ✗ DEBUG CODE PRESENT]
```

### 5.2 - TODO Comments

```
Checking for TODO comments...

Command: grep -r "TODO" lib/ --include="*.dart"

Result: [✓ None found / ⚠ X found]

If found:
TODOs in production code:
1. lib/core/services/recipe_service.dart:120
   - "TODO: Add caching"
   - Severity: ⚠ Minor (performance optimization)

2. lib/widgets/meal_plan_widget.dart:67
   - "TODO: Fix bug with dates"
   - Severity: ✗ Critical (bug noted but not fixed)

Status: [✓ CLEAN / ⚠ MINOR TODOs / ✗ CRITICAL TODOs]

Remediation for critical TODOs:
- Either fix the issue now
- Or create GitHub issue and remove TODO

Proceed? (y/n)
```

### 5.3 - Error Handling

```
Manual verification needed: Error Handling

Review these aspects:

1. Are all async operations wrapped in try-catch?
   User confirmation: (y/n)

2. Do all error paths show user-friendly messages?
   User confirmation: (y/n)

3. Are errors logged appropriately (not just printed)?
   User confirmation: (y/n)

4. Do errors in critical paths prevent data corruption?
   User confirmation: (y/n)

[Collect responses]

Status: [✓ PASS / ⚠ SOME GAPS / ✗ INADEQUATE]
```

### 5.4 - Code Documentation

```
Manual verification needed: Code Documentation

Review these aspects:

1. Is complex business logic documented with comments?
   User confirmation: (y/n)

2. Are public APIs documented (methods, classes)?
   User confirmation: (y/n)

3. Do comments explain "why" not just "what"?
   User confirmation: (y/n)

4. Are any confusing patterns explained?
   User confirmation: (y/n)

Status: [✓ WELL DOCUMENTED / ⚠ MINIMAL DOCS / ✗ UNDOCUMENTED]
```

### Overall Code Quality Status

```
Checkpoint 5 Summary:

5.1 - Debug Code:      ✓ CLEAN
5.2 - TODO Comments:   ⚠ MINOR (1 non-critical TODO)
5.3 - Error Handling:  ✓ ADEQUATE
5.4 - Documentation:   ✓ WELL DOCUMENTED

Overall Status: ✓ PASS WITH MINOR NOTES

Proceed to checkpoint 6? (y/n)
```

## Checkpoint 6: Localization Verification

**Goal**: Verify internationalization requirements (skip if no UI changes)

### 6.1 - Detect UI Changes

```
Analyzing changed files for UI components...

Changed Files Analysis:
- lib/screens/: 2 files
- lib/widgets/: 3 files
- lib/dialogs/: 1 file

UI Changes Detected: ✓ YES

Proceeding with localization checks...

[If no UI changes:]
No UI changes detected.
Skipping localization verification.
Proceed to checkpoint 7? (y/n)
```

### 6.2 - New UI Strings Detection

```
Searching for new UI strings...

Method 1: Check ARB file changes
Command: git diff develop...HEAD -- lib/l10n/app_en.arb

New strings in app_en.arb:
1. "recipeNotesLabel": "Notes"
2. "recipeNotesHint": "Add your cooking notes here"
3. "recipeNotesCharLimit": "{current} / {max} characters"

Found: 3 new strings

Method 2: Check for hardcoded strings (should be none)
Command: grep -r "Text(" lib/widgets/ lib/screens/ | grep -v "AppLocalizations"

Result: [✓ None found / ⚠ X hardcoded strings found]
```

### 6.3 - ARB Files Updated

```
Verifying ARB file completeness...

Check 1: English ARB (app_en.arb)
- "recipeNotesLabel": ✓ Present
- "recipeNotesHint": ✓ Present
- "recipeNotesCharLimit": ✓ Present
Status: ✓ COMPLETE

Check 2: Portuguese ARB (app_pt.arb)
- "recipeNotesLabel": ✓ Present ("Notas")
- "recipeNotesHint": ✓ Present ("Adicione suas notas de cozinha aqui")
- "recipeNotesCharLimit": ✓ Present ("{current} / {max} caracteres")
Status: ✓ COMPLETE

Both ARB files updated: ✓ YES
```

**If translations missing:**
```
Check 2: Portuguese ARB (app_pt.arb)
- "recipeNotesLabel": ✗ MISSING
- "recipeNotesHint": ✗ MISSING
- "recipeNotesCharLimit": ✓ Present

Status: ✗ INCOMPLETE

Remediation:
1. Open lib/l10n/app_pt.arb
2. Add missing translations:
   ```json
   "recipeNotesLabel": "Notas",
   "recipeNotesHint": "Adicione suas notas de cozinha aqui"
   ```
3. Run: flutter gen-l10n
4. Commit changes

Fix now? (y/n)
```

### 6.4 - AppLocalizations Usage

```
Verifying AppLocalizations usage...

Checking UI files for proper localization:
- lib/widgets/recipe_notes_field.dart: ✓ Uses AppLocalizations
- lib/screens/recipe_detail_screen.dart: ✓ Uses AppLocalizations
- lib/dialogs/recipe_notes_dialog.dart: ✓ Uses AppLocalizations

Checking for hardcoded strings:
Pattern: Text("...", without AppLocalizations
Result: [✓ None found / ⚠ X found]

Status: [✓ PROPER USAGE / ✗ HARDCODED STRINGS]

If hardcoded strings found:
Files with hardcoded strings:
- lib/widgets/recipe_card.dart:45
  - Text("Recipe") → Should use AppLocalizations.of(context)!.recipeLabel

Remediation: Replace hardcoded strings with AppLocalizations
Fix now? (y/n)
```

### 6.5 - Date/Time Formatting

```
Checking date/time formatting...

Searching for DateFormat usage:
Pattern: DateFormat.(...)

Findings:
- lib/widgets/meal_plan_card.dart:67
  - DateFormat('yyyy-MM-dd').format(date) ✓ Correct
- lib/screens/shopping_list_screen.dart:102
  - DateFormat.yMMMd().format(date) ⚠ Missing locale

Status: ⚠ MINOR ISSUE

Remediation:
Change: DateFormat.yMMMd().format(date)
To: DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(date)

Fix now? (y/n)
```

### Overall Localization Status

```
Checkpoint 6 Summary:

6.1 - UI Changes:       ✓ Detected (6 files)
6.2 - New Strings:      ✓ Found and added (3 strings)
6.3 - ARB Files:        ✓ Both EN and PT updated
6.4 - AppLocalizations: ✓ Properly used
6.5 - Date Formatting:  ⚠ Minor issue (1 missing locale)

Overall Status: ✓ PASS WITH MINOR NOTE

Proceed to final checkpoint? (y/n)
```

## Checkpoint 7: Merge Readiness Assessment

**Goal**: Final review summary and merge decision

### Review Summary

```
==================
MERGE READINESS ASSESSMENT
Issue #XXX: [Title]
Branch: feature/XXX-description → develop
==================

CHECKPOINT RESULTS:

✓ Checkpoint 1: Git Status & Branch
  - Working directory clean
  - Branch properly synced
  - No merge conflicts

✓ Checkpoint 2: Roadmap Completion
  - All 4 phases complete
  - All tasks checked off

✓ Checkpoint 3: Acceptance Criteria
  - 5/5 criteria met
  - 1 follow-up issue created (#XXY)

✓ Checkpoint 4: Technical Standards
  - Flutter analyze: 0 issues
  - Flutter test: 615/615 passing
  - Coverage: 87.3% (maintained)

✓ Checkpoint 5: Code Quality
  - No debug code
  - 1 minor TODO (non-blocking)
  - Error handling adequate
  - Well documented

✓ Checkpoint 6: Localization
  - 3 new strings added
  - Both EN/PT ARBs updated
  - 1 minor date format issue (noted)

WARNINGS / NOTES:

⚠ Minor TODO in recipe_service.dart (performance optimization)
⚠ DateFormat missing locale in 1 location (non-critical)
ℹ Follow-up issue #XXY created for UI enhancement

BLOCKING ISSUES:

✗ None - All critical requirements met

==================
OVERALL ASSESSMENT
==================

Status: ✓ APPROVED FOR MERGE

Quality Level: HIGH
Risk Level: LOW
Completeness: 100% (with minor notes)

Confidence: ✓ HIGH - All checkpoints passed

Recommendation: MERGE TO DEVELOP

Merge Strategy: Standard merge (no fast-forward)
Post-Merge: Monitor for 24h, ready for release branch

Ready to see merge instructions? (y/n)
```

### Merge Decision Matrix

**Automatic Approval** (if all true):
- ✓ All checkpoints pass
- ✓ No blocking issues
- ✓ Warnings acceptable (< 3 minor)
- ✓ All acceptance criteria met

**Conditional Approval** (if some true):
- ⚠ Some warnings present (3-5)
- ⚠ Minor gaps with follow-ups created
- ⚠ Some manual checks uncertain
→ Proceed with caution, note issues

**Rejection** (if any true):
- ✗ Any checkpoint fails
- ✗ Critical acceptance criteria unmet
- ✗ Tests failing
- ✗ Flutter analyze errors
- ✗ Blocking bugs present
→ DO NOT MERGE, fix issues first

## Merge Instructions Generation

When approved:

```
═══════════════════════════════════════════
MERGE INSTRUCTIONS FOR ISSUE #XXX
═══════════════════════════════════════════

Review Status: ✓ APPROVED
Merge Strategy: Standard merge to develop
Estimated Time: 5-10 minutes

PREREQUISITES VERIFIED:
✓ All tests passing (615 tests)
✓ Code quality standards met
✓ Branch synced with develop
✓ No merge conflicts
✓ Working directory clean

═══════════════════════════════════════════
STEP-BY-STEP MERGE PROCESS
═══════════════════════════════════════════

STEP 1: Final Status Check
═══════════════════════════════════════════
Command:
  git status

Expected Output:
  On branch feature/XXX-description
  nothing to commit, working tree clean

Status: [Execute and verify]

═══════════════════════════════════════════
STEP 2: Switch to Develop Branch
═══════════════════════════════════════════
Commands:
  git checkout develop
  git pull origin develop

Expected Output:
  Switched to branch 'develop'
  Already up to date.

Status: [Execute and verify]

═══════════════════════════════════════════
STEP 3: Merge Feature Branch
═══════════════════════════════════════════
Command:
  git merge --no-ff feature/XXX-description -m "Merge feature/XXX-description: [Title]"

Expected Output:
  Merge made by the 'recursive' strategy.
  [List of changed files]

⚠️ If conflicts occur:
1. Stop and review conflicts: git status
2. Resolve conflicts in each file
3. Stage resolved files: git add [files]
4. Complete merge: git commit
5. Verify: git log --oneline -5

Status: [Execute and verify]

═══════════════════════════════════════════
STEP 4: Post-Merge Verification
═══════════════════════════════════════════
Run final quality checks on develop branch:

Command 1: flutter analyze
Expected: No issues found
Status: [Execute and verify]

Command 2: flutter test
Expected: All tests passed! (615/615)
Status: [Execute and verify]

⚠️ If any check fails:
1. DO NOT push to origin
2. Investigate failure cause
3. Fix on develop or revert merge: git reset --hard HEAD~1
4. Re-merge after fixing

═══════════════════════════════════════════
STEP 5: Push to Remote
═══════════════════════════════════════════
Command:
  git push origin develop

Expected Output:
  To github.com:username/gastrobrain.git
     abc1234..def5678  develop -> develop

Status: [Execute and verify]

═══════════════════════════════════════════
STEP 6: Close Issue and Update Project
═══════════════════════════════════════════
Command:
  gh issue close XXX --comment "✓ Merged to develop in commit $(git rev-parse --short HEAD). All acceptance criteria met, tests passing."

Expected Output:
  ✓ Closed issue #XXX

Note: GitHub Project status will automatically update to "Done"

Status: [Execute and verify]

═══════════════════════════════════════════
STEP 7: Clean Up Feature Branch (Optional)
═══════════════════════════════════════════
Commands:
  git branch -d feature/XXX-description
  git push origin --delete feature/XXX-description

Expected Output:
  Deleted branch feature/XXX-description
  To github.com:username/gastrobrain.git
   - [deleted]  feature/XXX-description

Note: This is optional. Keep branch if you want history preserved.

Status: [Execute if desired]

═══════════════════════════════════════════
MERGE COMPLETE - POST-MERGE CHECKLIST
═══════════════════════════════════════════

Verify the following:

□ Develop branch has new commits: git log develop --oneline -5
□ Issue #XXX is closed on GitHub
□ GitHub Project status shows "Done"
□ Feature branch deleted (if Step 7 executed)
□ CI/CD pipeline passes (if applicable)
□ No errors in develop branch

═══════════════════════════════════════════
NEXT STEPS
═══════════════════════════════════════════

Immediate:
- Monitor develop branch for any issues
- Test feature in dev environment if available
- Check if any follow-up issues need attention (#XXY)

Within 24-48 hours:
- Consider merge to release branch if stable
- Update release notes if preparing release
- Monitor for any bug reports related to #XXX

═══════════════════════════════════════════
MERGE NOTES
═══════════════════════════════════════════

Quality Assessment:
- All 7 checkpoints passed
- 615 tests passing
- Zero analyze warnings
- High confidence merge

Known Minor Items:
- 1 TODO comment (non-blocking)
- 1 date format minor issue
- Follow-up issue #XXY created

Merge performed by: [System Date/Time]
Review completed by: gastrobrain-code-review skill v1.0.0

═══════════════════════════════════════════

Proceed with merge? (y/n)
```

## Failure Remediation Guide

### General Remediation Pattern

```
CHECKPOINT X FAILED: [Checkpoint Name]

Issues Identified:
1. [Specific issue 1]
   Severity: [✗ Critical / ⚠ Warning / ℹ Info]
2. [Specific issue 2]
   Severity: [Level]

══════════════════════════════════════════
REMEDIATION FOR ISSUE 1
══════════════════════════════════════════

Problem: [Detailed description]

Root Cause: [Why it's happening]

Solution Steps:

1. [Step 1 with specific commands]
   Command: [exact command]
   Expected: [expected result]

2. [Step 2]
   Command: [exact command]
   Expected: [expected result]

3. [Verification step]
   Command: [exact command]
   Expected: [expected result]

Estimated Time: [X minutes]

══════════════════════════════════════════
REMEDIATION FOR ISSUE 2
══════════════════════════════════════════

[Similar structure]

══════════════════════════════════════════
AFTER REMEDIATION
══════════════════════════════════════════

Options:
1. Re-run entire review: /gastrobrain-code-review
2. Re-run from this checkpoint: [if possible]
3. Abort and fix offline: [defer review]

What would you like to do? (1/2/3)
```

### Common Failures and Remediation

**Flutter Analyze Errors:**
```
Issue: 5 errors, 12 warnings found

Remediation:
1. View all issues: flutter analyze > analyze_output.txt
2. Fix errors first (blocking):
   - Open each file
   - Fix error
   - Save and re-analyze
3. Fix warnings (required for merge)
4. Re-run: flutter analyze
5. Verify: 0 issues

Time estimate: 15-30 minutes depending on complexity
```

**Test Failures:**
```
Issue: 3/618 tests failing

Remediation:
1. Run failing tests with verbose output:
   flutter test test/path/to/failing_test.dart --verbose
2. Identify failure cause from output
3. Common causes:
   - Test data outdated
   - Logic bug in code
   - Test expectations wrong
   - Timing issue (increase timeout)
4. Fix issue
5. Re-run specific test to verify
6. Run full suite: flutter test
7. Verify: All tests passing

Time estimate: 10-60 minutes per test
```

**Acceptance Criteria Not Met:**
```
Issue: Criterion 3 not met - "Feature X works on small screens"

Remediation:
1. Test feature on small screen device/emulator
2. Identify layout issue (overflow, clipping, etc.)
3. Fix responsive layout:
   - Use MediaQuery
   - Add scrolling if needed
   - Adjust constraints
4. Test on multiple screen sizes
5. Re-verify acceptance criterion
6. Update any relevant tests

Time estimate: 30-120 minutes
```

**Localization Issues:**
```
Issue: 3 strings not translated to Portuguese

Remediation:
1. Identify missing strings: [list]
2. Open lib/l10n/app_pt.arb
3. Add translations:
   ```json
   "key1": "Tradução 1",
   "key2": "Tradução 2",
   "key3": "Tradução 3"
   ```
4. Run: flutter gen-l10n
5. Verify: Check both ARB files have same keys
6. Test: Switch app to PT locale and verify

Time estimate: 10-20 minutes
```

## Quality Standards Reference

### Must-Have Standards (Blocking)

**These MUST pass for merge approval:**

- ✗ Flutter analyze: ZERO errors
- ✗ Flutter test: 100% passing rate
- ✗ Critical acceptance criteria: ALL met
- ✗ Backward compatibility: NO breaking changes
- ✗ Data integrity: NO data loss scenarios
- ✗ Security: NO vulnerabilities introduced

### Should-Have Standards (Warning)

**These should pass but can proceed with justification:**

- ⚠ Flutter analyze: Zero warnings (minor warnings acceptable with reason)
- ⚠ Test coverage: Maintained or improved (small decrease acceptable)
- ⚠ Documentation: README updated (can do in follow-up)
- ⚠ Code comments: Complex logic documented (can improve in follow-up)
- ⚠ TODOs: Removed or tracked (non-critical TODOs acceptable)

### Nice-to-Have Standards (Note)

**These improve quality but don't block merge:**

- ℹ Code style: Consistent formatting (automated by formatter)
- ℹ Performance: Optimizations possible (track for future)
- ℹ Additional tests: Edge cases could be added (track for future)
- ℹ Documentation expansion: More examples could help (track for future)

## Success Criteria

The code review succeeds when:

1. ✓ All 7 checkpoints completed systematically
2. ✓ No blocking issues found (or all remediated)
3. ✓ All acceptance criteria explicitly verified
4. ✓ Technical standards met (analyze, tests)
5. ✓ Clear merge decision made (approve/conditional/reject)
6. ✓ Merge instructions provided if approved
7. ✓ User has high confidence in merge safety

## References

- **Issue Workflow**: `docs/workflows/ISSUE_WORKFLOW.md`
- **Testing Guide**: `docs/testing/DIALOG_TESTING_GUIDE.md`
- **Localization Protocol**: `docs/workflows/L10N_PROTOCOL.md`
- **Edge Case Standards**: Issue #39, `docs/testing/EDGE_CASE_TESTING_GUIDE.md`
- **CLAUDE.md**: General development workflow

---

**Remember**: Code review is about quality assurance, not speed. Each checkpoint verification prevents issues from reaching develop branch. Never rush through checkpoints.
