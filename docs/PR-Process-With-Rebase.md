# Pull Request Process with Rebase Merge

This guide provides a complete step-by-step process for creating, reviewing, and merging Pull Requests using the rebase strategy. This approach maintains clean linear history while preserving all individual commits.

## Table of Contents
- [When to Use This Process](#when-to-use-this-process)
- [Prerequisites](#prerequisites)
- [Phase 1: Pre-PR Preparation](#phase-1-pre-pr-preparation)
- [Phase 2: Create the Pull Request](#phase-2-create-the-pull-request)
- [Phase 3: PR Review Process](#phase-3-pr-review-process)
- [Phase 4: Pre-Rebase Preparation](#phase-4-pre-rebase-preparation)
- [Phase 5: Testing & Final Verification](#phase-5-testing--final-verification)
- [Phase 6: Merge with Rebase](#phase-6-merge-with-rebase)
- [Phase 7: Post-Merge Cleanup](#phase-7-post-merge-cleanup)
- [Benefits of Rebase Merge](#benefits-of-rebase-merge)
- [Important Notes](#important-notes)
- [Troubleshooting](#troubleshooting)

## When to Use This Process

**Use Rebase Merge for:**
- ✅ **Major features** with logical progression (like i18n implementation)
- ✅ **Learning projects** where commit history adds educational value
- ✅ **Complex changes** that benefit from showing methodology
- ✅ **Solo development** where clean linear history is preferred
- ✅ **Well-structured commits** with meaningful messages

**Consider Squash Merge for:**
- ❌ Simple bug fixes or minor changes
- ❌ Commits with poor messages or structure
- ❌ Team projects requiring simplified history

## Prerequisites

- Working on a feature branch (following Git Flow)
- All commits have clear, descriptive messages
- Code tested and passes `flutter analyze`
- GitHub CLI installed and configured (`gh auth login`)

## Phase 1: Pre-PR Preparation

### Current Status Check
Ensure your feature branch is ready:

```bash
# Check current branch and status
git branch
git status

# Verify you're on your feature branch
# Should show: feature/{issue-number}-{description}

# Ensure working directory is clean
# Should show: "nothing to commit, working tree clean"
```

**Checklist:**
- [ ] Working on correct feature branch
- [ ] All changes committed
- [ ] Code tested (`flutter test`)
- [ ] Analysis clean (`flutter analyze`)
- [ ] Following project conventions

## Phase 2: Create the Pull Request

### Step 1: Push Your Branch to Remote

```bash
# Push the feature branch to origin
git push origin feature/{issue-number}-{description}

# Example:
# git push origin feature/143-i18n-pt-br-implementation
```

### Step 2: Create PR via GitHub CLI

```bash
gh pr create --title "feature: [descriptive title] (#{issue-number})" --body "$(cat <<'EOF'
## Summary
[Brief description of what this PR accomplishes]

### Changes Made
- **Key accomplishment 1** - Details
- **Key accomplishment 2** - Details
- **Key accomplishment 3** - Details

### Files Modified
- `path/to/file1.dart` - Description of changes
- `path/to/file2.dart` - Description of changes
- `path/to/file3.dart` - Description of changes

### Commit Structure
This PR maintains detailed commit history showing the methodical approach:
1. [Brief description of commit 1]
2. [Brief description of commit 2]
3. [Brief description of commit 3]

### Technical Implementation
- [Technical detail 1]
- [Technical detail 2]
- [Technical detail 3]

### Testing
- [x] `flutter analyze` - No issues found
- [x] `flutter test` - All tests pass
- [x] Manual testing completed
- [x] [Specific testing item 1]
- [x] [Specific testing item 2]

### Breaking Changes
[None/List any breaking changes]

Closes #{issue-number}

🤖 Generated with [Claude Code](https://claude.ai/code)
EOF
)"
```

## Phase 3: PR Review Process

### Step 3: Review Your Own PR

```bash
# View the PR you just created
gh pr view

# Look at the diff in the browser
gh pr view --web
```

### Step 4: Self-Review Checklist

As the reviewer, systematically check:

#### **Code Quality**
- [ ] All files follow project conventions
- [ ] No hardcoded values where configuration should be used
- [ ] Proper imports and dependencies
- [ ] Method signatures are consistent
- [ ] Error handling is appropriate

#### **Commit Quality** (Critical for Rebase)
- [ ] Each commit has clear, descriptive message
- [ ] Commits are logically separated (one concern per commit)
- [ ] No "fix typo" or "oops" commits that should be squashed
- [ ] Commit messages follow project conventions
- [ ] No merge commits in feature branch

#### **Functionality**
- [ ] New features work as expected
- [ ] Existing features remain unaffected
- [ ] Edge cases are handled
- [ ] User experience is preserved or improved

#### **Testing**
- [ ] Existing tests still pass
- [ ] New functionality is tested (if applicable)
- [ ] Manual testing completed
- [ ] No regressions introduced

## Phase 4: Pre-Rebase Preparation

### Step 5: Review Commit History

```bash
# Review your commit history
git log --oneline origin/develop..HEAD

# Check for any issues:
# - Are commit messages clear?
# - Are commits logically separated?
# - Any commits that should be squashed?

# If cleanup needed, interactive rebase:
# git rebase -i HEAD~{number-of-commits}
```

### Step 6: Update Your Branch

**Important:** This step ensures a clean rebase without conflicts.

```bash
# Fetch latest changes from develop
git fetch origin develop

# Check if develop has moved ahead
git log --oneline HEAD..origin/develop

# Rebase your feature branch onto latest develop
git rebase origin/develop

# If conflicts occur:
# 1. Fix conflicts in affected files
# 2. git add <resolved-files>
# 3. git rebase --continue
# 4. Repeat until rebase completes

# Force push the rebased branch (rewrites history)
git push --force-with-lease origin feature/{issue-number}-{description}
```

**Conflict Resolution Tips:**
- Take your time to understand each conflict
- Test after resolving conflicts
- Use `git status` to see which files need resolution
- Use `git diff` to see conflict markers

## Phase 5: Testing & Final Verification

### Step 7: Run Comprehensive Tests

```bash
# Run all checks on rebased branch
flutter analyze
flutter test

# Generate any auto-generated files
flutter gen-l10n  # If using internationalization

# Optional: Full build test
flutter build apk --debug
```

### Step 8: Manual Testing

Perform targeted manual testing:
- [ ] Core functionality works
- [ ] New features behave correctly
- [ ] UI displays properly
- [ ] No obvious regressions
- [ ] Performance feels normal

## Phase 6: Merge with Rebase

### Step 9: Approve Your PR

```bash
# If satisfied with the review
gh pr review --approve
```

### Step 10: Rebase Merge the PR

```bash
# Merge using rebase strategy
gh pr merge --rebase --delete-branch
```

**What This Does:**
1. **Applies each commit individually** to develop branch
2. **Maintains commit history** and messages
3. **Creates linear timeline** without merge commits
4. **Updates commit hashes** (normal for rebase)
5. **Deletes feature branch** to keep repo clean

### Expected Result

**Before Rebase Merge:**
```
develop: [old-commit] Previous work

feature/branch:
├── [commit-3] Your latest work  
├── [commit-2] Your middle work
├── [commit-1] Your initial work
└── [old-commit] Previous work
```

**After Rebase Merge:**
```
develop:
├── [new-hash-3] Your latest work  
├── [new-hash-2] Your middle work
├── [new-hash-1] Your initial work
└── [old-commit] Previous work
```

## Phase 7: Post-Merge Cleanup

### Step 11: Update Local Repository

```bash
# Switch back to develop
git checkout develop

# Pull the rebased commits
git pull origin develop

# Verify the rebase merge went smoothly
git log --oneline -10

# You should see your commits at the top of develop
```

### Step 12: Verify Merge Success

```bash
# Ensure issue was closed automatically
gh issue view {issue-number}

# Confirm feature branch was deleted
git branch -r | grep feature/{issue-number}  # Should return nothing

# Admire the clean linear history
git log --oneline --graph -10
```

### Step 13: Clean Up Local References

```bash
# Remove any stale remote references
git remote prune origin

# Remove local feature branch if it still exists
git branch -d feature/{issue-number}-{description}
```

## Benefits of Rebase Merge

### **For Learning Projects**
- ✅ **Preserves methodology** - See exactly how complex features were built
- ✅ **Educational value** - Future reference for similar work
- ✅ **Clean progression** - Understand the thought process

### **For Code Quality**
- ✅ **Linear history** - Easy to follow timeline
- ✅ **No merge noise** - No "Merge branch" commits
- ✅ **Bisect-friendly** - Each commit can be tested individually
- ✅ **Clear attribution** - See who did what when

### **For Team Collaboration**
- ✅ **Readable history** - Easy to understand project evolution
- ✅ **Meaningful commits** - Each commit tells a story
- ✅ **Professional appearance** - Clean, organized repository

## Important Notes

### **Commit Hash Changes**
- **Normal behavior:** Rebase changes commit hashes
- **Content identical:** Code changes remain exactly the same
- **Messages preserved:** Commit messages stay intact
- **Authorship maintained:** You remain the author

### **Force Push Required**
- **After rebase:** Must use `git push --force-with-lease`
- **Safety feature:** `--force-with-lease` prevents overwriting others' work
- **Only on feature branches:** Never force push to develop/main

### **Original History Preserved**
- **In PR:** GitHub preserves original commits in PR view
- **In reflog:** Git keeps references for recovery
- **In documentation:** This process documents the approach

## Troubleshooting

### **Rebase Conflicts**

```bash
# If rebase stops due to conflicts:
git status  # Shows conflicted files

# Edit files to resolve conflicts (look for <<<< markers)
# After resolving conflicts:
git add <resolved-files>
git rebase --continue

# If you get stuck:
git rebase --abort  # Returns to pre-rebase state
```

### **Force Push Issues**

```bash
# If force push is rejected:
git push --force-with-lease origin feature/branch-name

# If that fails (someone else pushed), fetch first:
git fetch origin
git rebase origin/feature/branch-name  # If others contributed
git push --force-with-lease origin feature/branch-name
```

### **PR Merge Issues**

```bash
# If GitHub says branch is out of date:
git fetch origin develop
git rebase origin/develop
git push --force-with-lease origin feature/branch-name

# Then retry the merge:
gh pr merge --rebase --delete-branch
```

### **Verification Failures**

```bash
# If tests fail after rebase:
flutter clean
flutter pub get
flutter analyze
flutter test

# Fix any issues, commit, and force push:
git add .
git commit -m "fix: resolve post-rebase issues"
git push --force-with-lease origin feature/branch-name
```

## Summary

This rebase merge process provides:
- **Clean, linear history** showing your methodical approach
- **Preserved commit details** for future reference and learning
- **Professional workflow** suitable for solo or team development
- **Maintainable codebase** with clear progression tracking

The extra steps ensure high-quality merges that enhance rather than clutter your project's history.

---

*This document is part of the Gastrobrain project's development guidelines. For other workflows, see [CLAUDE.md](../CLAUDE.md).*