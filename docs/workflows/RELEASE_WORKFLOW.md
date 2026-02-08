# Release Workflow

**Last Updated**: 2025-12-30

This document outlines the step-by-step process for creating and deploying release branches following Git Flow practices.

---

## When to Create a Release

Create a release branch when:
- ✅ All planned features for the milestone are complete and merged to `develop`
- ✅ All tests are passing (`flutter test && flutter analyze`)
- ✅ Sprint review completed and documented
- ✅ Ready to prepare for production deployment

---

## Release Branch Naming

**Format**: `release/{version}`

**Examples**:
- `release/0.1.3`
- `release/0.2.0`
- `release/1.0.0`

**Version numbering** (Semantic Versioning):
- **MAJOR.MINOR.PATCH** (e.g., 1.2.3)
- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

---

## Automated Release Pipeline

This repository uses **GitHub Actions** to automate the release process. When you push a version tag (e.g., `v0.1.3`), the following happens automatically:

**Triggered by**: Pushing tags matching `v*` pattern
**Workflow file**: `.github/workflows/release.yml`

**Automated steps**:
1. ✅ **Build APK**: Compiles release APK with signing
2. ✅ **Create GitHub Release**: Automatically creates a published release
3. ✅ **Upload APK**: Attaches APK to the release as `gastrobrain-{version}.apk`
4. ✅ **Publish**: Release is immediately published (non-draft, non-prerelease)

**What you still need to do manually**:
- Version updates (pubspec.yaml, CHANGELOG.md)
- Git branching and merging
- Creating and pushing the tag
- Optionally enhancing the auto-generated release description

---

## Release Process

### Step 1: Create Release Branch

```bash
# Ensure develop is up to date
git checkout develop
git pull origin develop

# Create release branch from develop
git checkout -b release/0.1.3
```

### Step 2: Update Version Numbers

**Update `pubspec.yaml`**:
```yaml
version: 0.1.3+4  # version+buildNumber
```

**Version format**: `MAJOR.MINOR.PATCH+BUILD`
- **Build number ALWAYS increments** (never resets)
- Build number is independent of version number
- Example progression: `0.1.2+3` → `0.1.3+4` → `0.1.4+5` → `1.0.0+6`

**IMPORTANT**: The build number must monotonically increase for app store compatibility.

### Step 3: Update CHANGELOG.md

Add release notes to `CHANGELOG.md`:

```markdown
## [0.1.3] - 2025-12-30

### Added
- Complete dialog testing infrastructure (#38)
- Comprehensive edge case test suite (#39)
- Testing documentation guides (4 major guides)
- Performance benchmarking for critical operations

### Changed
- Reorganized docs/ folder into logical subfolders
- Updated testing patterns in CLAUDE.md
- Enhanced test coverage to 100% for critical paths

### Fixed
- None

### Performance
- All operations exceed performance thresholds
- 614 tests execute in 2-3 seconds

### Documentation
- DIALOG_TESTING_GUIDE.md (1,288 lines)
- EDGE_CASE_TESTING_GUIDE.md (740+ lines)
- EDGE_CASE_CATALOG.md (460+ lines)
- Sprint review analysis for velocity tracking
```

### Step 4: Commit Version Updates

```bash
git add pubspec.yaml CHANGELOG.md
git commit -m "chore: bump version to 0.1.3 for release

- Update version in pubspec.yaml to 0.1.3+4
- Add CHANGELOG.md entries for 0.1.3 release
- Document features, changes, and improvements

Milestone: 0.1.3 - User Features & Critical Foundation"
```

### Step 5: Final Verification

```bash
# Run all tests
flutter test

# Run static analysis
flutter analyze

# Optional: Build APK to verify (if not in WSL)
flutter build apk --release
```

**Expected Results**:
- ✅ All tests pass
- ✅ Zero analyze errors
- ✅ Build succeeds (if applicable)

### Step 6: Push Release Branch

```bash
git push origin release/0.1.3
```

### Step 7: Merge to Main

```bash
# Switch to main branch
git checkout main
git pull origin main

# Merge release branch (no-ff to preserve history)
git merge --no-ff release/0.1.3

# Push to main
git push origin main
```

**Note**: Pushing to main triggers GitHub Actions CI (`.github/workflows/ci.yml`) which will:
- Run `flutter analyze`
- Run `flutter test --coverage`
- Build debug APK
- Upload coverage to Codecov

### Step 8: Create and Push Git Tag

```bash
# Create annotated tag
git tag -a v0.1.3 -m "Release v0.1.3: User Features & Critical Foundation

Milestone 0.1.3 complete:
- Dialog testing infrastructure (#38)
- Edge case test suite (#39)
- 614 tests, 100% critical path coverage
- 4 comprehensive testing guides"

# Push tag to remote
git push origin v0.1.3
```

**⚠️ IMPORTANT**: Pushing the tag triggers automated GitHub Actions (`.github/workflows/release.yml`) that will:
1. ✅ Build the release APK automatically
2. ✅ Create the GitHub Release automatically
3. ✅ Upload the APK to the release automatically
4. ✅ Publish the release (non-draft, non-prerelease)

**Monitor the GitHub Actions workflow** at: `https://github.com/your-org/gastrobrain/actions`

### Step 9: Wait for GitHub Actions to Complete

**Monitor the automated release workflow**:
1. Go to: `https://github.com/your-org/gastrobrain/actions`
2. Find the "Release Build" workflow triggered by your tag
3. Verify all steps complete successfully:
   - ✅ Checkout code
   - ✅ Setup Flutter
   - ✅ Build release APK
   - ✅ Create Release
   - ✅ Upload APK to Release

**Expected duration**: ~5-10 minutes

### Step 10: Merge Back to Develop

```bash
# Merge release changes back to develop
git checkout develop
git pull origin develop
git merge --no-ff release/0.1.3
git push origin develop
```

### Step 11: Clean Up Release Branch

```bash
# Delete local branch
git branch -d release/0.1.3

# Delete remote branch
git push origin --delete release/0.1.3
```

### Step 12: Verify and Enhance GitHub Release (Optional)

**On GitHub**:
1. Go to Releases → Find `v0.1.3`
2. The release is **already created and published** by GitHub Actions
3. **Optionally edit** the release to:
   - Add detailed CHANGELOG content to description
   - Add release highlights or breaking changes
   - Update release notes with migration guides
4. The APK is already attached: `gastrobrain-v0.1.3.apk`

**Note**: The automated release has a basic title and description. You can enhance it with more detailed notes if needed.

---

## Quick Reference Checklist

Release preparation:
- [ ] All milestone issues closed
- [ ] All tests passing
- [ ] Sprint review documented
- [ ] develop branch up to date

Creating release:
- [ ] Create `release/{version}` branch from develop
- [ ] Update version in `pubspec.yaml`
- [ ] Update `CHANGELOG.md` with release notes
- [ ] Commit version changes
- [ ] Run `flutter test && flutter analyze`
- [ ] Push release branch

Merging release:
- [ ] Merge release branch to main (standard merge, NOT squash)
- [ ] Push to main (triggers CI tests)
- [ ] Create annotated tag `v{version}`
- [ ] Push tag to remote (triggers automated release build)
- [ ] **Wait for GitHub Actions to complete** (~5-10 min)
- [ ] Merge back to develop
- [ ] Delete release branch (local and remote)
- [ ] (Optional) Enhance auto-created GitHub Release

Post-release:
- [ ] Verify tag appears on GitHub
- [ ] Verify GitHub Release published (auto-created)
- [ ] Verify APK attached to release (auto-uploaded)
- [ ] (Optional) Edit release description with CHANGELOG
- [ ] Announce release (if applicable)
- [ ] Archive sprint/milestone docs

---

## Hotfix Process (Emergency Fixes)

For critical bugs in production:

```bash
# Create hotfix branch from main
git checkout main
git checkout -b hotfix/0.1.3.1

# Fix the bug, update version (patch increment)
# Update CHANGELOG.md under [0.1.3.1] - YYYY-MM-DD

# Commit fix
git add .
git commit -m "fix: critical bug description (#issue)

Brief explanation of the fix."

# Merge to main
git checkout main
git merge --no-ff hotfix/0.1.3.1
git tag -a v0.1.3.1 -m "Hotfix: critical bug fix"
git push origin main --tags

# Merge to develop
git checkout develop
git merge --no-ff hotfix/0.1.3.1
git push origin develop

# Clean up
git branch -d hotfix/0.1.3.1
```

---

## Version History Reference

| Version | Date | Milestone | Branch | Notes |
|---------|------|-----------|--------|-------|
| 0.1.0 | 2025-11-11 | Initial Release | - | First version |
| 0.1.1 | 2025-11-28 | Stability & Polish | - | Testing infrastructure, E2E framework |
| 0.1.2 | 2025-12-17 | Polish & Data Safety | - | Backup/restore, UX improvements |
| 0.1.3 | 2025-12-30 | User Features & Critical Foundation | release/0.1.3 | Testing foundation, 614 tests |
| 0.1.4 | 2026-01-03 | Testing Infrastructure | release/0.1.4 | MealEditService, error simulation |
| 0.1.5 | 2026-01-09 | Meal Recording Consolidation | release/0.1.5 | Meal types, Codecov, dialog coverage |
| 0.1.6 | 2026-01-29 | Recipe Management Polish | release/0.1.6 | Shopping list, meal plan summary, recipe navigation |
| 0.1.7 | 2026-02-06 | UI Polish & Design System | release/0.1.7 | Design tokens, Material 3 theme, component standardization |

---

## Common Issues & Solutions

### Build Number Conflicts

**Problem**: Build number doesn't increment properly
**Solution**: Build number must ALWAYS increment (never reset or decrement)
- Build number is independent of version number
- Example: `0.1.2+3` → `0.1.3+4` → `0.1.4+5` → `1.0.0+6`
- ❌ WRONG: `0.1.2+3` → `0.1.3+3` (build didn't increment)
- ❌ WRONG: `0.1.2+3` → `0.2.0+1` (build number reset)
- ✅ CORRECT: Build number always increases monotonically

**Why it matters**: App stores require build numbers to always increase for updates to work properly.

### Merge Conflicts in CHANGELOG

**Problem**: Conflicts in CHANGELOG.md when merging back to develop
**Solution**:
1. Keep both changes (release notes + new develop work)
2. Ensure chronological order (newest at top)
3. Verify all release notes are preserved

### Tag Already Exists

**Problem**: `git tag v0.1.3` fails - tag exists
**Solution**:
```bash
# Delete local tag
git tag -d v0.1.3

# Delete remote tag (if pushed)
git push origin :refs/tags/v0.1.3

# Recreate tag
git tag -a v0.1.3 -m "Release message"
git push origin v0.1.3
```

---

## Additional Resources

- [Semantic Versioning](https://semver.org/)
- [Git Flow](https://nvie.com/posts/a-successful-git-branching-model/)
- [Keep a Changelog](https://keepachangelog.com/)
- [Issue Workflow](./ISSUE_WORKFLOW.md) - Development workflow
- [Sprint Planning](../archive/Sprint-Planning-0.1.2-0.1.3.md) - Milestone planning

---

**Maintained by**: Development Team
**Primary Audience**: Developers, Release Managers
**Repository**: gastrobrain (private)
