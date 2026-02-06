# Code Review Checkpoint Template

This template shows the exact format for conducting systematic code reviews with 7 checkpoints.

## Initial Context and Analysis

```
Code Review for Issue #[NUMBER]

Preparing systematic review...

Context Detection:
- Branch: feature/[NUMBER]-[description]
- Issue: #[NUMBER] - [Title from GitHub]
- Roadmap: docs/planning/0.1.X/ISSUE-[NUMBER]-ROADMAP.md
- Base branch: develop
- Files changed: [X] files, +[Y]/-[Z] lines

Focus Areas Detected:
[✓ UI Changes / ✓ Database Migration / ✓ Service Logic / ✓ Testing]

Review Structure:
This systematic review will proceed through 7 checkpoints:
1. Git Status & Branch Verification
2. Roadmap Completion Verification
3. Acceptance Criteria Validation
4. Technical Standards (analyze, tests)
5. Code Quality Checks
6. Localization Verification
7. Merge Readiness Assessment

Each checkpoint must pass before proceeding to the next.

Ready to begin systematic review? (y/n)

[WAIT for user confirmation]
```

---

## Checkpoint 1: Git Status & Branch Verification

```
==================
CHECKPOINT 1/7: Git Status & Branch Verification
Goal: Ensure clean working state and proper branch alignment

Running automated checks...

1.1 - Working Directory Status
Command: git status
Output:
[Actual output]

Status: [✓ Clean / ⚠ Uncommitted changes / ✗ Untracked files]

1.2 - Current Branch
Command: git branch --show-current
Output: feature/[NUMBER]-[description]
Status: [✓ Correct branch / ✗ Wrong branch]

1.3 - Branch Sync with Remote
Command: git fetch origin && git status
Output:
[Branch sync status]
Status: [✓ Up to date / ⚠ Behind / ⚠ Ahead / ✗ Diverged]

1.4 - Sync with Develop
Command: git fetch origin develop && git log origin/develop..HEAD --oneline
Output:
[Commits ahead of develop]
Status: [✓ Up to date / ⚠ Behind develop]

1.5 - Merge Conflict Check
Command: git merge-tree $(git merge-base origin/develop HEAD) origin/develop HEAD
Status: [✓ No conflicts / ⚠ Potential conflicts / ✗ Conflicts detected]

Overall Checkpoint 1 Status: [✓ PASS / ⚠ WARNING / ✗ FAIL]

[If issues found, show remediation]

Proceed to Checkpoint 2? (y/n)

[STOP - WAIT for user response]
```

**Remediation Template (if needed):**
```
Issues Found:
1. [Issue description]
   Severity: [✗ Blocking / ⚠ Warning / ℹ Info]

Remediation Steps:
1. [Step 1]
   Command: [exact command]
2. [Step 2]
   Command: [exact command]
3. Verification
   Command: [verification command]

After fixing, re-run Checkpoint 1.
```

---

## Checkpoint 2: Roadmap Completion Verification

```
==================
CHECKPOINT 2/7: Roadmap Completion Verification
Goal: Verify all roadmap phases are complete

Reading roadmap: docs/planning/0.1.X/ISSUE-[NUMBER]-ROADMAP.md

Phase Analysis:

Phase 1: Analysis & Understanding
Tasks:
- [✓] Task 1 description
- [✓] Task 2 description
- [✓] Task 3 description
Status: [✓ COMPLETE / ⚠ INCOMPLETE / ✗ MAJOR GAPS]

Phase 2: Implementation
Tasks:
- [✓] Subtask 1
- [✓] Subtask 2
- [✓] Subtask 3
Status: [✓ COMPLETE / ⚠ INCOMPLETE / ✗ MAJOR GAPS]

Phase 3: Testing
Tasks:
- [✓] Test implementation
- [✓] All tests passing
Status: [✓ COMPLETE / ⚠ INCOMPLETE / ✗ MAJOR GAPS]

Phase 4: Documentation & Cleanup
Tasks:
- [✓] Code comments
- [✓] README updated
Status: [✓ COMPLETE / ⚠ INCOMPLETE / ✗ MAJOR GAPS]

Overall Roadmap Status: [✓ COMPLETE / ⚠ MOSTLY COMPLETE / ✗ INCOMPLETE]

Complete Phases: [X]/4
Issues:
[List any incomplete tasks]

[If incomplete tasks:]
Manual verification: Are these tasks actually complete but unchecked? (y/n)
[If yes: Update roadmap checkboxes]
[If no: List remediation steps]

Overall Checkpoint 2 Status: [✓ PASS / ⚠ WARNING / ✗ FAIL]

Proceed to Checkpoint 3? (y/n)

[STOP - WAIT for user response]
```

---

## Checkpoint 3: Acceptance Criteria Validation

```
==================
CHECKPOINT 3/7: Acceptance Criteria Validation
Goal: Verify all issue acceptance criteria are met

Loading acceptance criteria from issue #[NUMBER]...

From issue description:

Acceptance Criterion 1: [Description]
Type: [Automated / Manual verification]
[If automated:]
  ✓ Verified via: [test name or evidence]
[If manual:]
  User confirmation needed: Is this criterion met? (y/n)
Status: [✓ CONFIRMED / ⚠ PARTIAL / ✗ NOT MET]

Acceptance Criterion 2: [Description]
Type: [Automated / Manual verification]
[Similar structure]
Status: [✓ CONFIRMED / ⚠ PARTIAL / ✗ NOT MET]

[Repeat for all criteria]

Summary:
Total Criteria: [N]
✓ Confirmed: [X]
⚠ Partial: [Y]
✗ Not Met: [Z]

Overall Checkpoint 3 Status: [✓ ALL MET / ⚠ MOSTLY MET / ✗ CRITICAL UNMET]

[If criteria not fully met:]
Options:
1. Fix now: [Describe what needs fixing]
2. Create follow-up issue: [For non-critical gaps]
3. Abort review: [If critical criteria unmet]

Choice? (1/2/3)

Proceed to Checkpoint 4? (y/n)

[STOP - WAIT for user response]
```

---

## Checkpoint 4: Technical Standards

```
==================
CHECKPOINT 4/7: Technical Standards
Goal: Verify code quality through automated technical checks

Running automated checks...

4.1 - Flutter Analyze
═══════════════════════════════════════════
Command: flutter analyze

Output:
[Actual analyze output]

Result:
- Errors: [N]
- Warnings: [N]
- Hints: [N]

Status: [✓ PASS (0 issues) / ⚠ MINOR ISSUES / ✗ FAIL (errors present)]

[If issues found, list details]

4.2 - Flutter Test
═══════════════════════════════════════════
Command: flutter test

Output:
[Actual test output]

Result:
- Total tests: [N]
- Passed: [N]
- Failed: [N]
- Skipped: [N]

Status: [✓ PASS (all passing) / ✗ FAIL (failures present)]

[If failures, list failed tests]

4.3 - Test Coverage (Optional)
═══════════════════════════════════════════
Command: flutter test --coverage

Coverage Report:
- Overall: [X]%
- Changed files: [Y]%

Status: [✓ PASS (maintained/improved) / ⚠ DECREASED]

[If decreased significantly, show details]

Overall Checkpoint 4 Status: [✓ PASS / ⚠ MINOR ISSUES / ✗ FAIL]

[If failures, show remediation steps]

Proceed to Checkpoint 5? (y/n)

[STOP - WAIT for user response]
```

---

## Checkpoint 5: Code Quality Checks

```
==================
CHECKPOINT 5/7: Code Quality Checks
Goal: Manual verification of code quality standards

5.1 - Debug Code Detection
═══════════════════════════════════════════
Checking for debug code...

Search: print() statements
Command: grep -r "print(" lib/ --include="*.dart" | grep -v "// print"
Result: [✓ None found / ⚠ [N] found]

[If found, list locations]

Search: debugPrint() calls
Command: grep -r "debugPrint(" lib/ --include="*.dart"
Result: [✓ None found / ⚠ [N] found]

Status: [✓ CLEAN / ⚠ MINOR DEBUG CODE / ✗ SIGNIFICANT DEBUG CODE]

5.2 - TODO Comments
═══════════════════════════════════════════
Checking for TODO comments...

Command: grep -r "TODO" lib/ --include="*.dart"
Result: [✓ None found / ⚠ [N] found]

[If found:]
TODOs in production code:
1. [file:line] - "TODO: [description]"
   Severity: [ℹ Minor / ⚠ Important / ✗ Critical]

Status: [✓ CLEAN / ⚠ MINOR TODOs / ✗ CRITICAL TODOs]

5.3 - Error Handling (Manual Verification)
═══════════════════════════════════════════
Manual verification needed:

Questions:
1. Are all async operations wrapped in try-catch?
   User confirmation: (y/n)

2. Do error paths show user-friendly messages?
   User confirmation: (y/n)

3. Are errors logged appropriately?
   User confirmation: (y/n)

4. Do errors prevent data corruption?
   User confirmation: (y/n)

Status: [✓ ADEQUATE / ⚠ SOME GAPS / ✗ INADEQUATE]

5.4 - Code Documentation (Manual Verification)
═══════════════════════════════════════════
Manual verification needed:

Questions:
1. Is complex business logic documented?
   User confirmation: (y/n)

2. Are public APIs documented?
   User confirmation: (y/n)

3. Do comments explain "why" not just "what"?
   User confirmation: (y/n)

Status: [✓ WELL DOCUMENTED / ⚠ MINIMAL DOCS / ✗ UNDOCUMENTED]

Overall Checkpoint 5 Status: [✓ PASS / ⚠ MINOR ISSUES / ✗ MAJOR ISSUES]

Proceed to Checkpoint 6? (y/n)

[STOP - WAIT for user response]
```

---

## Checkpoint 6: Localization Verification

```
==================
CHECKPOINT 6/7: Localization Verification
Goal: Verify i18n requirements if UI changed

6.1 - Detect UI Changes
═══════════════════════════════════════════
Analyzing changed files for UI components...

Changed Files:
- lib/screens/: [N] files
- lib/widgets/: [N] files
- lib/dialogs/: [N] files

UI Changes Detected: [✓ YES / ✗ NO]

[If NO UI changes:]
No UI changes detected.
Skipping localization verification.
Proceed to Checkpoint 7? (y/n)

[If YES, continue...]

6.2 - New UI Strings Detection
═══════════════════════════════════════════
Checking for new UI strings...

Command: git diff develop...HEAD -- lib/l10n/app_en.arb

New strings in app_en.arb:
1. "[key1]": "[value1]"
2. "[key2]": "[value2]"
[List all new strings]

Found: [N] new strings

6.3 - ARB Files Completeness
═══════════════════════════════════════════
Verifying both language files updated...

Check: English ARB (app_en.arb)
- "[key1]": [✓ Present / ✗ Missing]
- "[key2]": [✓ Present / ✗ Missing]
Status: [✓ COMPLETE / ✗ INCOMPLETE]

Check: Portuguese ARB (app_pt.arb)
- "[key1]": [✓ Present / ✗ Missing]
- "[key2]": [✓ Present / ✗ Missing]
Status: [✓ COMPLETE / ✗ INCOMPLETE]

Both ARB files updated: [✓ YES / ✗ NO]

6.4 - AppLocalizations Usage
═══════════════════════════════════════════
Checking for hardcoded strings...

Command: grep -r "Text(" lib/widgets/ lib/screens/ | grep -v "AppLocalizations"

Result: [✓ None found / ⚠ [N] hardcoded strings found]

[If found, list locations]

Status: [✓ PROPER USAGE / ✗ HARDCODED STRINGS]

6.5 - Date/Time Formatting
═══════════════════════════════════════════
Checking date/time formatting...

Command: grep -r "DateFormat" lib/

Findings:
[List DateFormat usages]
- [file:line]: [✓ Has locale / ⚠ Missing locale]

Status: [✓ CORRECT / ⚠ MINOR ISSUES]

Overall Checkpoint 6 Status: [✓ PASS / ⚠ MINOR ISSUES / ✗ FAIL]

Proceed to final checkpoint? (y/n)

[STOP - WAIT for user response]
```

---

## Checkpoint 7: Merge Readiness Assessment

```
==================
CHECKPOINT 7/7: Merge Readiness Assessment
Goal: Final review summary and merge decision

═══════════════════════════════════════════
REVIEW SUMMARY
═══════════════════════════════════════════

Issue: #[NUMBER] - [Title]
Branch: feature/[NUMBER]-[description] → develop

CHECKPOINT RESULTS:

✓ Checkpoint 1: Git Status & Branch
  - [Key findings]

[✓/⚠/✗] Checkpoint 2: Roadmap Completion
  - [Key findings]

[✓/⚠/✗] Checkpoint 3: Acceptance Criteria
  - [Key findings]

[✓/⚠/✗] Checkpoint 4: Technical Standards
  - [Key findings]

[✓/⚠/✗] Checkpoint 5: Code Quality
  - [Key findings]

[✓/⚠/✗] Checkpoint 6: Localization
  - [Key findings]

WARNINGS / NOTES:
[List any warnings or notes]
⚠ [Warning 1]
⚠ [Warning 2]
ℹ [Note 1]

BLOCKING ISSUES:
[List any blocking issues, or state "None"]
✗ [Blocking issue 1] (if any)

═══════════════════════════════════════════
OVERALL ASSESSMENT
═══════════════════════════════════════════

Status: [✓ APPROVED / ⚠ APPROVED WITH NOTES / ✗ REJECTED]

Quality Level: [HIGH / MEDIUM / LOW]
Risk Level: [LOW / MEDIUM / HIGH]
Completeness: [percentage]% (with minor notes)

Confidence: [✓ HIGH / ⚠ MEDIUM / ✗ LOW]

Recommendation: [MERGE TO DEVELOP / FIX ISSUES FIRST / MAJOR REWORK NEEDED]

[If approved:]
Merge Strategy: Standard merge (--no-ff)
Post-Merge: Monitor for 24h, ready for release branch

[If approved with notes:]
Proceed with merge, addressing these notes:
- [Note 1]
- [Note 2]

[If rejected:]
Do not merge. Address these blocking issues:
- [Issue 1]
- [Issue 2]

Ready to see merge instructions? (y/n)

[If rejected: End review here]
```

---

## Merge Instructions (If Approved)

```
═══════════════════════════════════════════
MERGE INSTRUCTIONS FOR ISSUE #[NUMBER]
═══════════════════════════════════════════

Review Status: ✓ APPROVED
Branch: feature/[NUMBER]-[description] → develop
Estimated Time: 5-10 minutes

PREREQUISITES VERIFIED:
✓ All tests passing ([N] tests)
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
  On branch feature/[NUMBER]-[description]
  nothing to commit, working tree clean

□ Verified

═══════════════════════════════════════════
STEP 2: Switch to Develop Branch
═══════════════════════════════════════════
Commands:
  git checkout develop
  git pull origin develop

Expected Output:
  Switched to branch 'develop'
  Already up to date.

□ Verified

═══════════════════════════════════════════
STEP 3: Merge Feature Branch
═══════════════════════════════════════════
Command:
  git merge --no-ff feature/[NUMBER]-[description] -m "Merge feature/[NUMBER]-[description]: [Title]"

Expected Output:
  Merge made by the 'recursive' strategy.
  [List of changed files]

⚠️ If conflicts occur:
  1. Review conflicts: git status
  2. Resolve conflicts manually in each file
  3. Stage resolved files: git add [files]
  4. Complete merge: git commit

□ Verified

═══════════════════════════════════════════
STEP 4: Post-Merge Verification
═══════════════════════════════════════════
Run final quality checks on develop branch:

Command 1: flutter analyze
Expected: No issues found
□ Verified

Command 2: flutter test
Expected: All tests passed! ([N]/[N])
□ Verified

⚠️ If any check fails:
  1. DO NOT push to origin
  2. Investigate failure
  3. Fix on develop OR revert: git reset --hard HEAD~1
  4. Re-merge after fixing

═══════════════════════════════════════════
STEP 5: Push to Remote
═══════════════════════════════════════════
Command:
  git push origin develop

Expected Output:
  To github.com:username/gastrobrain.git
     [hash1]..[hash2]  develop -> develop

□ Verified

═══════════════════════════════════════════
STEP 6: Close Issue and Update Project
═══════════════════════════════════════════
Command:
  gh issue close [NUMBER] --comment "✓ Merged to develop in commit $(git rev-parse --short HEAD). All acceptance criteria met, tests passing."

Expected Output:
  ✓ Closed issue #[NUMBER]

Note: GitHub Project #3 status will automatically update to "Done"

□ Verified

═══════════════════════════════════════════
STEP 7: Clean Up Feature Branch (Optional)
═══════════════════════════════════════════
Commands:
  git branch -d feature/[NUMBER]-[description]
  git push origin --delete feature/[NUMBER]-[description]

Expected Output:
  Deleted branch feature/[NUMBER]-[description]
  To github.com:username/gastrobrain.git
   - [deleted]  feature/[NUMBER]-[description]

□ Completed (if desired)

═══════════════════════════════════════════
POST-MERGE CHECKLIST
═══════════════════════════════════════════

Verify the following:

□ Develop branch has new commits
□ Issue #[NUMBER] is closed on GitHub
□ GitHub Project status shows "Done"
□ Feature branch deleted (if Step 7 executed)
□ CI/CD pipeline passes (if applicable)
□ No errors in develop branch

═══════════════════════════════════════════
NEXT STEPS
═══════════════════════════════════════════

Immediate:
- Monitor develop branch for issues
- Test feature in dev environment
- Check follow-up issues (if any created)

Within 24-48 hours:
- Consider merge to release branch if stable
- Update release notes if preparing release
- Monitor for bug reports

═══════════════════════════════════════════
MERGE NOTES
═══════════════════════════════════════════

Quality Assessment:
- All 7 checkpoints passed
- [N] tests passing
- Zero analyze warnings
- High confidence merge

Known Minor Items:
[List any minor notes from review]

Merge Completed: [Date/Time]
Review By: gastrobrain-code-review v1.0.0

═══════════════════════════════════════════
```

---

## Progress Indicators

```
Review Progress: 3/7 checkpoints complete ████░░░ 42%

✓ Checkpoint 1: Git Status [COMPLETE]
✓ Checkpoint 2: Roadmap [COMPLETE]
✓ Checkpoint 3: Acceptance [COMPLETE]
⧗ Checkpoint 4: Technical [CURRENT]
○ Checkpoint 5: Code Quality [PENDING]
○ Checkpoint 6: Localization [PENDING]
○ Checkpoint 7: Merge Ready [PENDING]
```

---

## Status Indicators Reference

- **✓** PASS - Checkpoint passed, no issues
- **⚠** WARNING - Minor issues, can proceed with notes
- **✗** FAIL - Blocking issues, cannot proceed
- **⧗** CURRENT - Currently executing this checkpoint
- **○** PENDING - Not yet started
- **ℹ** INFO - Informational note
- **□** CHECKBOX - Action item to verify

---

**Key Principles:**
1. Execute checkpoints in order (1-7)
2. WAIT for user confirmation between checkpoints
3. Provide clear pass/warning/fail status
4. Show remediation steps for failures
5. Generate complete merge instructions when approved
