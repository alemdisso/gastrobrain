# GitHub Copilot Instructions Template

This file provides reusable instruction templates for assigning issues to GitHub Copilot. These templates ensure Copilot follows our project conventions and workflow.

## How to Use

1. **Copy the appropriate template** below (Generic or Issue-Specific)
2. **Customize** the placeholders (issue number, branch type, file paths)
3. **Paste as a comment** when assigning the issue to Copilot
4. **Monitor** that Copilot follows the workflow steps

---

## Common Issues & Prevention

Based on previous Copilot implementations, avoid these common mistakes:

### ❌ Issue: Firewall Blocks Flutter SDK Downloads

**Problem**: Copilot cannot access Google Cloud Storage to download Flutter/Dart SDK, preventing `flutter analyze` from running.

**Solution**: Configure [Actions setup steps](https://gh.io/copilot/actions-setup-steps) in repository settings to pre-install Flutter before the firewall activates.

**How to detect**: Look for warnings in PR description about blocked URLs (storage.googleapis.com).

### ❌ Issue: Empty "Initial plan" Commits

**Problem**: Copilot creates empty commits with message "Initial plan" that add no value.

**Prevention**: Add this to instructions:
```markdown
- Make ONLY ONE commit with your implementation
- Do NOT create separate "Initial plan" or "docs" commits
- Include all changes in a single, well-formatted commit
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

---

## Generic Template

Use this for any issue. Replace placeholders in `{braces}`:

```markdown
Please implement issue #{issue-number} following our project workflow:

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
5. VALIDATE: Run `flutter analyze` (must pass with no errors)
6. Create ONE commit with proper format

CRITICAL NOTES:
- Follow existing code patterns and conventions
- Use `flutter analyze` for validation (required before commit)
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
Please implement issue #{issue-number} following our project workflow:

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
6. VALIDATE: Run `flutter analyze` (must pass with no errors)
7. Create ONE commit with proper format

CRITICAL NOTES:
- Follow existing UI patterns in the screen
- Use existing themes, colors, and styles (Theme.of(context).colorScheme)
- Test on narrow screens (360px width) - use MediaQuery for responsive layouts
- Add overflow protection: TextOverflow.ellipsis, maxLines, Expanded/Flexible
- If text is added: update lib/l10n/app_en.arb and app_pt.arb, then run `flutter gen-l10n`
- Use `flutter analyze` for validation (required before commit)
- Make ONLY ONE commit - do NOT create separate "Initial plan" or "docs" commits
- NEVER manually edit files marked "Generated file. Do not edit."

Review acceptance criteria and test cases in the issue before completing.
```

---

## Bug Fix Template

Optimized for bug fixes:

```markdown
Please implement issue #{issue-number} following our project workflow:

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
6. VALIDATE: Run `flutter analyze` (must pass with no errors)
7. Test that fix resolves the issue without breaking other features
8. Create ONE commit with proper format

CRITICAL NOTES:
- Keep fix minimal - don't refactor unnecessarily
- Test edge cases mentioned in the issue
- If fix changes error handling, ensure proper exception types used
- Use `flutter analyze` for validation (required before commit)
- Verify test cases from issue acceptance criteria
- Make ONLY ONE commit - do NOT create separate "Initial plan" or "docs" commits
- NEVER manually edit files marked "Generated file. Do not edit."

Document what was changed and why in the commit message.
```

---

## Feature Enhancement Template

Optimized for new features:

```markdown
Please implement issue #{issue-number} following our project workflow:

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
5. VALIDATE: Run `flutter analyze` (must pass with no errors)
6. Test feature with various inputs and edge cases
7. Create ONE commit with proper format

CRITICAL NOTES:
- Follow dependency injection pattern via ServiceProvider
- Use proper error handling (NotFoundException, ValidationException, GastrobrainException)
- Add user-facing strings to lib/l10n/app_en.arb and app_pt.arb, run `flutter gen-l10n`
- Keep implementation focused - avoid scope creep
- Use `flutter analyze` for validation (required before commit)
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
VALIDATION CHECKLIST:
- [ ] `flutter analyze` passes with no errors
- [ ] All acceptance criteria from issue are met
- [ ] No hardcoded user-facing strings (all in .arb files)
- [ ] Existing functionality not broken
- [ ] Code follows existing patterns in the file
- [ ] Commit message follows format: "{type}: description (#{issue-number})"
- [ ] No unnecessary changes or scope creep
```

---

## Example: Issue #182

Here's a complete example for issue #182:

```markdown
Please implement issue #182 following our project workflow:

WORKFLOW CONVENTIONS (see docs/ISSUE_WORKFLOW.md):
- Branch: enhancement/182-create-new-ingredient-option
- Commits: "enhancement: add create new ingredient option for low/medium matches (#182)"
- Read CLAUDE.md and docs/Gastrobrain-Codebase-Overview.md for architecture patterns

REQUIRED STEPS:
1. Read issue #182 completely - understand requirements and acceptance criteria
2. Analyze relevant code in lib/screens/bulk_recipe_update_screen.dart (_buildIngredientRow method, around lines 1800-2000)
3. Plan your implementation approach (small, focused changes)
4. Implement the solution: add "Create New Ingredient" button below match dropdown
5. VALIDATE: Run `flutter analyze` (must pass with no errors)
6. Create ONE commit with format above

CRITICAL NOTES:
- Follow existing code patterns for button styling (OutlinedButton.icon recommended per issue)
- Use existing _showCreateIngredientDialog() method - don't recreate it
- Keep changes minimal and focused on the issue requirements
- Button should be visible when ingredient.matches.isNotEmpty
- Place button below the existing match dropdown with appropriate spacing
- Use `flutter analyze` for validation (required before commit)
- Make ONLY ONE commit - do NOT create separate "Initial plan" or "docs" commits
- NEVER manually edit files marked "Generated file. Do not edit."

VALIDATION CHECKLIST:
- [ ] `flutter analyze` passes with no errors
- [ ] "Create New" button appears when matches exist
- [ ] Button triggers _showCreateIngredientDialog() correctly
- [ ] Works for all confidence levels (low, medium, high)
- [ ] Doesn't break existing "no matches" scenario
- [ ] Clear visual distinction between dropdown and button

Review acceptance criteria in issue #182 before considering the work complete.
```

---

## Tips for Success

1. **Be Specific**: Include exact file paths and approximate line numbers when known
2. **Emphasize Validation**: Always require `flutter analyze` to pass
3. **Reference Documentation**: Point to CLAUDE.md, ISSUE_WORKFLOW.md, and Gastrobrain-Codebase-Overview.md
4. **Focus on Requirements**: Keep instructions focused on what TO do rather than restrictions
5. **Review Acceptance Criteria**: Always remind Copilot to check issue acceptance criteria
6. **Monitor Progress**: Check that Copilot shows a plan before implementing
7. **Verify Output**: Review commits to ensure format compliance

---

## Post-Implementation Review

After Copilot completes the work, verify:

### ✅ Code Quality
1. Branch name follows convention (`{type}/{issue-number}-{short-description}`)
2. Commit message follows format and accurately describes changes
3. Changes are minimal and focused on the issue
4. All acceptance criteria are met
5. Code follows existing patterns and conventions

### ✅ Validation
6. `flutter analyze` was run and passed (check PR description for firewall warnings)
7. No hardcoded user-facing strings (all in .arb files)
8. Localization files regenerated if .arb files were modified

### ✅ Commit Hygiene
9. **ONLY ONE meaningful commit** (not counting merge commits)
10. **NO "Initial plan" empty commits**
11. **NO unnecessary "docs" commits after implementation**
12. Commit type prefix matches the actual changes

### ✅ Generated Files
13. **NO manual edits to generated files**:
    - `macos/Flutter/GeneratedPluginRegistrant.swift`
    - `lib/l10n/app_localizations*.dart` (unless via `flutter gen-l10n`)
    - Files marked "Generated file. Do not edit."
14. Only generated files from official Flutter commands should be committed

### ✅ Common Issues
15. Check PR description for firewall warnings about blocked URLs
16. No unrelated file changes (e.g., IDE config, build artifacts)
17. No scope creep - implementation matches issue requirements

If any checks fail, provide feedback to Copilot and request corrections before merging.

---

## Updating This Template

As you learn what works best with GitHub Copilot:

1. **Document patterns** that consistently work well
2. **Add common pitfalls** to the CRITICAL NOTES sections
3. **Refine templates** based on Copilot's typical mistakes
4. **Share improvements** with the team

This is a living document - improve it based on experience!
