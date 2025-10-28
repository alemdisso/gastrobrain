# GitHub Copilot Instructions Template

This file provides reusable instruction templates for assigning issues to GitHub Copilot. These templates ensure Copilot follows our project conventions and workflow.

## How to Use

1. **Copy the appropriate template** below (Generic or Issue-Specific)
2. **Customize** the placeholders (issue number, branch type, file paths)
3. **Paste as a comment** when assigning the issue to Copilot
4. **Monitor** that Copilot follows the workflow steps

---

## 🚫🚫🚫 CRITICAL RULES FOR COPILOT - READ FIRST 🚫🚫🚫

### ❌ ABSOLUTELY NO "Initial plan" COMMITS

**This is the #1 most important rule. You have violated this rule in EVERY previous PR.**

- ❌ **DO NOT** create commits with message "Initial plan"
- ❌ **DO NOT** create empty commits
- ❌ **DO NOT** create separate planning commits
- ❌ **DO NOT** create multiple commits for documentation
- ✅ **CREATE EXACTLY ONE COMMIT** with all your changes
- ✅ **USE PROPER FORMAT**: `{type}: description (#{issue-number})`

**Why this matters:**
- Empty commits clutter git history and create maintenance overhead
- You waste reviewer time by forcing them to squash your commits
- GitHub Actions will now **BLOCK** your PR if you create empty commits
- Your PR will be **AUTOMATICALLY REJECTED** by CI if you violate this rule

**Verification before pushing:**
```bash
git log --oneline
```
**Expected result:** EXACTLY ONE commit with meaningful file changes

**Examples:**
- ✅ GOOD: `bugfix: fix Row overflow at line 1460 (#187)` (1 commit, files changed)
- ❌ BAD: `Initial plan` followed by `bugfix: fix Row overflow (#187)` (2 commits)
- ❌ BAD: Empty commit with no file changes

**GitHub Actions enforcement:**
A workflow (`check-commits.yml`) will automatically check every PR and **FAIL** the build if:
1. Any commit has message containing "initial plan" (case insensitive)
2. Any commit has zero file changes (empty commit)

**If your PR fails this check:**
You must squash or remove the offending commits before your PR can be merged.

---

## CI/CD Workflow Awareness

**IMPORTANT**: All pull requests trigger automated checks via GitHub Actions:

### What Runs Automatically on PRs
1. **Flutter Setup** - Installs Flutter 3.32.5
2. **Dependency Installation** - Runs `flutter pub get`
3. **Code Analysis** - `flutter analyze` (MUST pass, CI will fail if it doesn't)
4. **Test Suite** - `flutter test --coverage` (runs all tests)
5. **Coverage Generation** - Creates lcov.info (Codecov upload currently disabled)
6. **Build Validation** - `flutter build apk --debug` (verifies code builds)

### CI Implications for Copilot
- **Code MUST pass `flutter analyze`** - CI will catch any issues
- **Tests MUST not fail** - CI runs full test suite
- **Code MUST build** - CI attempts APK build
- **No syntax errors tolerated** - CI is stricter than local checks

### Firewall Issue (Known Problem)
If you see warnings about blocked URLs (storage.googleapis.com) in PR description:
- This is expected - repository firewall blocks some downloads
- Does NOT indicate a problem with your implementation
- Flutter SDK is pre-installed before firewall activates
- `flutter analyze` can still run successfully

---

## Common Issues & Prevention

Based on previous Copilot implementations, avoid these common mistakes:

### ❌ Issue: Firewall Blocks Flutter SDK Downloads

**Problem**: Copilot cannot access Google Cloud Storage to download Flutter/Dart SDK, preventing `flutter analyze` from running.

**Solution**: Configure [Actions setup steps](https://gh.io/copilot/actions-setup-steps) in repository settings to pre-install Flutter before the firewall activates.

**How to detect**: Look for warnings in PR description about blocked URLs (storage.googleapis.com).

**Status**: ✅ Already configured - firewall warnings are expected and harmless

### ❌ Issue: Empty "Initial plan" Commits

**Problem**: Copilot creates empty commits with message "Initial plan" that add no value.

**Status**: ✅ **NOW ENFORCED BY GITHUB ACTIONS**
- A workflow (`check-commits.yml`) automatically blocks PRs with empty or "Initial plan" commits
- CI will fail if any commit violates this rule
- Copilot MUST squash/remove these commits before PR can be merged

**Prevention**: Add this to instructions (now included in all templates):
```markdown
🚫 DO NOT create "Initial plan" commits - GitHub Actions will BLOCK your PR
🚫 CREATE EXACTLY ONE COMMIT with all your changes
- Make ONLY ONE commit with your implementation
- Do NOT create separate "Initial plan" or "docs" commits
- Include all changes in a single, well-formatted commit
- GitHub Actions will automatically reject PRs with empty commits
```

### ❌ Issue: Modified Generated Files

**Problem**: Copilot modifies files marked "Generated file. Do not edit." (e.g., `GeneratedPluginRegistrant.swift`, `app_localizations.dart`)

**Files to NEVER manually edit**:
- `macos/Flutter/GeneratedPluginRegistrant.swift`
- `lib/l10n/app_localizations.dart`
- `lib/l10n/app_localizations_*.dart` (except when running `flutter gen-l10n`)
- Any file with "Generated file. Do not edit." comment

**Prevention**: Add this to instructions:
```markdown
- NEVER manually edit files marked "Generated file. Do not edit."
- When updating .arb files, run `flutter gen-l10n` to regenerate localization files
- Do NOT commit changes to generated files unless they result from running official Flutter commands
```

### ❌ Issue: Misleading Commit Messages

**Problem**: Commit messages don't accurately describe changes (e.g., "docs: final implementation summary" when modifying code)

**Prevention**: Add this to instructions:
```markdown
- Commit message MUST accurately describe what was changed
- Use correct type prefix (feature/bugfix/ui, not "docs" for code changes)
- Keep commit count minimal - ideally ONE commit per issue
```

### ❌ Issue: Breaking Existing Tests

**Problem**: Changes break existing tests, causing CI to fail

**Prevention**: Add this to instructions:
```markdown
- Run `flutter test` locally before committing
- CI will run ALL tests - ensure none break
- If tests need updates, include test changes in your commit
```

---

## Generic Template

Use this for any issue. Replace placeholders in `{braces}`:

```markdown
@copilot-swe-agent Please implement issue #{issue-number} following our project workflow:

🚫 CRITICAL: Read the "CRITICAL RULES FOR COPILOT" section at the top of .github/COPILOT_INSTRUCTIONS.md
🚫 DO NOT create "Initial plan" commits - GitHub Actions will BLOCK your PR if you do
🚫 CREATE EXACTLY ONE COMMIT with all your changes

WORKFLOW CONVENTIONS (see docs/ISSUE_WORKFLOW.md):
- Branch: {type}/{issue-number}-{short-description}
  Types: feature/bugfix/ui/refactor/testing/docs
- Commits: "{type}: brief description (#{issue-number})"
- Read CLAUDE.md and docs/Gastrobrain-Codebase-Overview.md for architecture patterns

REQUIRED STEPS:
1. Read the issue completely - understand requirements and acceptance criteria
2. Analyze relevant code in {primary-file-path}
3. Plan your implementation approach (small, focused changes)
4. Implement the solution following existing patterns
5. VALIDATE LOCALLY: 
   - Run `flutter analyze` (MUST pass - CI will check)
   - Run `flutter test` (MUST pass - CI will check)
   - Verify `flutter build apk --debug` succeeds
6. Create ONE commit with proper format

CI/CD AWARENESS:
- Your PR will automatically trigger GitHub Actions workflow
- CI runs: flutter analyze, flutter test, flutter build apk --debug
- ALL checks MUST pass for PR to be merged
- Fix any CI failures before requesting review

CRITICAL NOTES:
- Follow existing code patterns and conventions
- If user-facing strings are added: update lib/l10n/app_en.arb and app_pt.arb, then run `flutter gen-l10n`
- Keep changes minimal and focused on the issue requirements
- Test that your changes don't break existing functionality
- Make ONLY ONE commit - do NOT create separate "Initial plan" or "docs" commits
- NEVER manually edit files marked "Generated file. Do not edit."
- Commit message MUST accurately describe what was changed

Review acceptance criteria in the issue before considering the work complete.
```

---

## UI Enhancement Template

Optimized for UI-related issues:

```markdown
@copilot-swe-agent Please implement issue #{issue-number} following our project workflow:

🚫 CRITICAL: DO NOT create "Initial plan" commits - GitHub Actions will BLOCK your PR
🚫 CREATE EXACTLY ONE COMMIT with all your changes

WORKFLOW CONVENTIONS (see docs/ISSUE_WORKFLOW.md):
- Branch: ui/{issue-number}-{short-description}
- Commits: "ui: brief description (#{issue-number})"
- Read CLAUDE.md for architecture patterns

REQUIRED STEPS:
1. Read issue #{issue-number} completely - understand UI/UX requirements
2. Analyze relevant code in {screen-file-path}
3. Identify existing UI patterns and widgets to reuse
4. Plan minimal UI changes (avoid over-engineering)
5. Implement following Material Design and existing patterns
6. VALIDATE LOCALLY:
   - Run `flutter analyze` (MUST pass - CI will check)
   - Run `flutter test` (MUST pass - CI will check)
   - Verify `flutter build apk --debug` succeeds
7. Create ONE commit with proper format

CI/CD AWARENESS:
- Your PR will automatically trigger GitHub Actions workflow
- CI runs: flutter analyze, flutter test, flutter build apk --debug
- ALL checks MUST pass for PR to be merged

CRITICAL NOTES:
- Follow existing UI patterns in the screen
- Use existing themes, colors, and styles (Theme.of(context).colorScheme)
- Test on narrow screens (360px width) - use MediaQuery for responsive layouts
- Add overflow protection: TextOverflow.ellipsis, maxLines, Expanded/Flexible
- If text is added: update lib/l10n/app_en.arb and app_pt.arb, then run `flutter gen-l10n`
- Make ONLY ONE commit - do NOT create separate "Initial plan" or "docs" commits
- NEVER manually edit files marked "Generated file. Do not edit."

Review acceptance criteria and test cases in the issue before completing.
```

---

## Bug Fix Template

Optimized for bug fixes:

```markdown
@copilot-swe-agent Please implement issue #{issue-number} following our project workflow:

🚫 CRITICAL: DO NOT create "Initial plan" commits - GitHub Actions will BLOCK your PR
🚫 CREATE EXACTLY ONE COMMIT with all your changes

WORKFLOW CONVENTIONS (see docs/ISSUE_WORKFLOW.md):
- Branch: bugfix/{issue-number}-{short-description}
- Commits: "bugfix: brief description (#{issue-number})"
- Read CLAUDE.md for architecture patterns

REQUIRED STEPS:
1. Read issue #{issue-number} - understand the bug and error messages
2. Locate the bug in {file-path} around line {approximate-line}
3. Reproduce the issue conditions (if possible)
4. Identify root cause (don't just treat symptoms)
5. Implement minimal fix following existing patterns
6. VALIDATE LOCALLY:
   - Run `flutter analyze` (MUST pass - CI will check)
   - Run `flutter test` (MUST pass - CI will check)
   - Run affected tests specifically to verify fix
   - Verify `flutter build apk --debug` succeeds
7. Test that fix resolves the issue without breaking other features
8. Create ONE commit with proper format

CI/CD AWARENESS:
- Your PR will automatically trigger GitHub Actions workflow
- Bug fix MUST NOT break existing tests
- CI will catch any regressions in test suite

CRITICAL NOTES:
- Keep fix minimal - don't refactor unnecessarily
- Test edge cases mentioned in the issue
- If fix changes error handling, ensure proper exception types used
- Verify test cases from issue acceptance criteria
- Make ONLY ONE commit - do NOT create separate "Initial plan" or "docs" commits
- NEVER manually edit files marked "Generated file. Do not edit."

Document what was changed and why in the commit message.
```

---

## Feature Enhancement Template

Optimized for new features:

```markdown
@copilot-swe-agent Please implement issue #{issue-number} following our project workflow:

🚫 CRITICAL: DO NOT create "Initial plan" commits - GitHub Actions will BLOCK your PR
🚫 CREATE EXACTLY ONE COMMIT with all your changes

WORKFLOW CONVENTIONS (see docs/ISSUE_WORKFLOW.md):
- Branch: feature/{issue-number}-{short-description}
- Commits: "feature: brief description (#{issue-number})"
- Read CLAUDE.md and docs/Gastrobrain-Codebase-Overview.md for patterns

REQUIRED STEPS:
1. Read issue #{issue-number} - understand feature requirements fully
2. Review existing architecture in {relevant-files}
3. Plan implementation following established patterns:
   - Use ServiceProvider for dependency injection
   - Use DatabaseHelper for data operations
   - Follow existing error handling patterns
4. Implement feature incrementally
5. VALIDATE LOCALLY:
   - Run `flutter analyze` (MUST pass - CI will check)
   - Run `flutter test` (MUST pass - CI will check)
   - Add tests for new functionality if needed
   - Verify `flutter build apk --debug` succeeds
6. Test feature with various inputs and edge cases
7. Create ONE commit with proper format

CI/CD AWARENESS:
- Your PR will automatically trigger GitHub Actions workflow
- New features should include tests (CI runs full test suite)
- CI will verify code builds and analyzes cleanly

CRITICAL NOTES:
- Follow dependency injection pattern via ServiceProvider
- Use proper error handling (NotFoundException, ValidationException, GastrobrainException)
- Add user-facing strings to lib/l10n/app_en.arb and app_pt.arb, run `flutter gen-l10n`
- Keep implementation focused - avoid scope creep
- Document any new patterns or conventions introduced
- Make ONLY ONE commit - do NOT create separate "Initial plan" or "docs" commits
- NEVER manually edit files marked "Generated file. Do not edit."

Review all acceptance criteria before considering complete.
```

---

## Branch Type Reference

Quick reference for choosing the right branch type:

| Issue Label | Branch Type | Commit Prefix |
|-------------|-------------|---------------|
| `enhancement` | `feature/` or `enhancement/` | `feature:` or `enhancement:` |
| `bug`, `✘`, `✘✘`, `✘✘✘` | `bugfix/` | `bugfix:` or `fix:` |
| `UI`, `UX` | `ui/` | `ui:` |
| `refactor`, `technical-debt` | `refactor/` | `refactor:` |
| `testing` | `testing/` | `test:` |
| `documentation` | `docs/` | `docs:` |

---

## Validation Checklist

Include this checklist in your Copilot instruction for complex issues:

```markdown
LOCAL VALIDATION CHECKLIST:
- [ ] `flutter analyze` passes with no errors (CI will check)
- [ ] `flutter test` passes all tests (CI will check)
- [ ] `flutter build apk --debug` succeeds (CI will check)
- [ ] All acceptance criteria from issue are met
- [ ] No hardcoded user-facing strings (all in .arb files)
- [ ] Existing functionality not broken
- [ ] Code follows existing patterns in the file
- [ ] Commit message follows format: "{type}: description (#{issue-number})"
- [ ] No unnecessary changes or scope creep

CI/CD CHECKS (will run automatically on PR):
- [ ] GitHub Actions workflow passes all steps
- [ ] Flutter analyze check passes
- [ ] Test suite check passes
- [ ] Build APK check passes
```

---

## Example: Issue #179

Here's a complete example for issue #179 with CI/CD awareness:

```markdown
Please implement issue #179 following our project workflow:

WORKFLOW CONVENTIONS (see docs/ISSUE_WORKFLOW.md):
- Branch: enhancement/179-{short-description-from-issue}
- Commits: "enhancement: brief description (#179)"
- Read CLAUDE.md and docs/Gastrobrain-Codebase-Overview.md for architecture patterns

REQUIRED STEPS:
1. Read issue #179 completely - understand all requirements and acceptance criteria
2. Analyze relevant code files mentioned in the issue
3. Plan your implementation approach (small, focused changes)
4. Implement the solution following existing patterns
5. VALIDATE LOCALLY:
   - Run `flutter analyze` (MUST pass - CI will check this)
   - Run `flutter test` (MUST pass - CI will check this)
   - Verify `flutter build apk --debug` succeeds (CI will check this)
6. Create ONE commit with proper format

CI/CD AWARENESS:
- Your PR will automatically trigger GitHub Actions
- CI runs: flutter analyze, flutter test --coverage, flutter build apk --debug
- ALL checks MUST pass for PR to be merged
- Firewall warnings about storage.googleapis.com are expected and harmless

CRITICAL NOTES:
- Follow existing code patterns and conventions
- Keep changes minimal and focused on issue #179 requirements
- If user-facing strings are added: update lib/l10n/app_en.arb and app_pt.arb, then run `flutter gen-l10n`
- Test that your changes don't break existing functionality
- Make ONLY ONE commit - do NOT create separate "Initial plan" or "docs" commits
- NEVER manually edit files marked "Generated file. Do not edit."
- Commit message MUST accurately describe what was changed

LOCAL VALIDATION CHECKLIST:
- [ ] `flutter analyze` passes with no errors
- [ ] `flutter test` passes all tests
- [ ] `flutter build apk --debug` succeeds
- [ ] All acceptance criteria from issue #179 are met
- [ ] No hardcoded user-facing strings
- [ ] Existing functionality not broken
- [ ] Code follows existing patterns
- [ ] Commit message follows format

Review all acceptance criteria in issue #179 before considering the work complete.
```

---

## Tips for Success

1. **Be Specific**: Include exact file paths and approximate line numbers when known
2. **Emphasize CI/CD**: Always remind that checks will run automatically
3. **Require Local Validation**: Copilot should run all CI checks locally first
4. **Reference Documentation**: Point to CLAUDE.md, ISSUE_WORKFLOW.md, and Gastrobrain-Codebase-Overview.md
5. **Focus on Requirements**: Keep instructions focused on what TO do rather than restrictions
6. **Review Acceptance Criteria**: Always remind Copilot to check issue acceptance criteria
7. **Monitor Progress**: Check that Copilot shows a plan before implementing
8. **Verify Output**: Review commits to ensure format compliance

---

## Post-Implementation Review

After Copilot completes the work, verify:

### ✅ Code Quality
1. Branch name follows convention (`{type}/{issue-number}-{short-description}`)
2. Commit message follows format and accurately describes changes
3. Changes are minimal and focused on the issue
4. All acceptance criteria are met
5. Code follows existing patterns and conventions

### ✅ Local Validation
6. `flutter analyze` was run and passed
7. `flutter test` was run and passed
8. No hardcoded user-facing strings (all in .arb files)
9. Localization files regenerated if .arb files were modified

### ✅ CI/CD Checks
10. **GitHub Actions workflow completed successfully**
11. **Flutter analyze step passed** (green checkmark)
12. **Test suite step passed** (green checkmark)
13. **Build APK step passed** (green checkmark)
14. Check PR for firewall warnings (expected, not a problem)

### ✅ Commit Hygiene
15. **ONLY ONE meaningful commit** (not counting merge commits)
16. **NO "Initial plan" empty commits**
17. **NO unnecessary "docs" commits after implementation**
18. Commit type prefix matches the actual changes

### ✅ Generated Files
19. **NO manual edits to generated files**:
    - `macos/Flutter/GeneratedPluginRegistrant.swift`
    - `lib/l10n/app_localizations*.dart` (unless via `flutter gen-l10n`)
    - Files marked "Generated file. Do not edit."
20. Only generated files from official Flutter commands should be committed

### ✅ Common Issues
21. No unrelated file changes (e.g., IDE config, build artifacts)
22. No scope creep - implementation matches issue requirements
23. CI passed without requiring fixes

### 🔴 If CI Fails
- Review the failed step in GitHub Actions logs
- Copilot must fix issues and push updates
- Do NOT merge until all CI checks are green

If any checks fail, provide feedback to Copilot and request corrections before merging.

---

## Understanding CI Failures

Common CI failure scenarios and how to address them:

### Flutter Analyze Failures
**Symptom**: `flutter analyze` step fails with errors
**Causes**: Syntax errors, unused imports, type mismatches
**Fix**: Review analyze output in CI logs, fix locally, push update

### Test Failures
**Symptom**: `flutter test` step fails
**Causes**: Broken tests, new code breaks existing functionality
**Fix**: Run tests locally, identify broken tests, fix and push update

### Build Failures
**Symptom**: `flutter build apk --debug` step fails
**Causes**: Missing dependencies, compilation errors
**Fix**: Try building locally, resolve dependency/compilation issues

### Firewall Warnings
**Symptom**: PR description shows blocked URLs (storage.googleapis.com)
**Status**: **This is NORMAL** - not a failure
**Reason**: Flutter SDK is pre-installed before firewall activates
**Action**: Ignore these warnings

---

## Updating This Template

As you learn what works best with GitHub Copilot:

1. **Document patterns** that consistently work well
2. **Add common pitfalls** to the CRITICAL NOTES sections
3. **Refine templates** based on Copilot's typical mistakes
4. **Share improvements** with the team
5. **Update CI/CD section** if workflow changes

This is a living document - improve it based on experience!