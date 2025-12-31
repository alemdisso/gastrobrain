# Issue Workflow Guide

This document contains detailed workflows for issue management, GitHub Projects integration, and Git Flow processes for the Gastrobrain project.

## Issue Tackling Protocol

### Branch Naming Convention
Create branches based on issue type and number using this format:
`{type}/{issue-number}-{short-description}`

**Branch Types:**
- `feature/` - For enhancements and new functionality
- `bugfix/` - For bug fixes and corrections
- `testing/` - For adding or improving tests
- `refactor/` - For technical debt and architecture improvements
- `ui/` - For user interface improvements
- `docs/` - For documentation updates

**Examples:**
- `feature/{issue-number}-meal-type-recommendation-profiles`
- `bugfix/{issue-number}-recipe-stats-side-dish`
- `testing/{issue-number}-end-to-end-meal-edit`
- `refactor/{issue-number}-view-models-complex-displays`
- `ui/{issue-number}-refine-add-ingredient-dialog`

### Issue Workflow Process

#### 1. Starting Work on an Issue
```bash
# Check out latest main/develop branch
git checkout develop
git pull origin develop

# Create and switch to new branch
git checkout -b {type}/{issue-number}-{short-description}

# Check the issue details
gh issue view {issue-number}
```

#### 2. Development Process
1. **Analyze the Issue**: Read the GitHub issue carefully and understand requirements
2. **Plan Implementation**: Use TodoWrite tool to break down the work
3. **Follow Development Workflow**: Apply the step-by-step approach outlined in CLAUDE.md
4. **Commit Regularly**: Make small, focused commits with clear messages

#### 3. Commit Message Format
```
{type}: brief description (#{issue-number})

Optional longer description of changes made.

Closes #{issue-number}
```

**Template Examples:**
```
feature: add meal type-specific recommendation profiles (#{issue-number})

Implements lunch/dinner specific weight profiles for the
recommendation engine with temporal context awareness.

Closes #{issue-number}
```

```
bugfix: fix recipe statistics when added as side dish (#{issue-number})

Updates meal recording logic to properly increment recipe
statistics for both primary and side dishes.

Closes #{issue-number}
```

#### 4. Testing Before Integration
```bash
# Run relevant tests
flutter test test/path/to/related/tests/

# Run full test suite if major changes
flutter test

# Check code quality
flutter analyze
```

#### 5. Merge to Develop
```bash
# Ensure all changes are committed
git status

# Switch to develop and merge
git checkout develop
git pull origin develop
git merge {type}/{issue-number}-{short-description}

# Push to remote
git push origin develop

# Close the issue
gh issue close {issue-number}
```

#### 6. Branch Cleanup
```bash
# Delete local branch
git branch -d {type}/{issue-number}-{short-description}

# Delete remote branch (if pushed)
git push origin --delete {type}/{issue-number}-{short-description}
```

### GitHub CLI Issue Commands
```bash
# List all open issues
gh issue list

# View specific issue details
gh issue view {issue-number}

# Create new issue
gh issue create --title "Issue title" --body "Issue description"

# Close issue
gh issue close {issue-number}

# Add labels to issue
gh issue edit {issue-number} --add-label "enhancement,✓✓"
```

This protocol ensures consistent branch management and clear traceability between issues and code changes.

## GitHub Best Practices

### Issue Creation Workflow

When creating new GitHub issues, follow this **deliberate, multi-step approach** to ensure proper organization and categorization:

#### 1. Create Issue First (Minimal)
Create the issue with just the title and description. **Do NOT** add labels or milestones inline during creation:

```bash
# ✅ CORRECT: Create issue without labels/milestones
gh issue create --title "ui: fix quantity display format in bulk recipe update tool" --body "$(cat <<'EOF'
[Full issue description here]
EOF
)"

# ❌ INCORRECT: Trying to add labels inline often causes errors
gh issue create --title "..." --body "..." --label "ui,enhancement,✓"
```

**Why?** Inline label/milestone assignment can fail if:
- Label names don't match exactly (case-sensitive, special characters)
- Labels don't exist in the repository
- Milestone names are incorrect or don't exist

#### 2. Review Available Labels
Before adding labels, check what labels exist to avoid duplication and ensure consistency:

```bash
# List all available labels
gh label list

# Review output for exact label names
```

**Key considerations:**
- Labels are case-sensitive and may contain special characters
- Check for similar existing labels (e.g., "UI" vs "ui", "user-interface")
- Understand label categories: type, priority, scope, status

#### 3. Add Labels Thoughtfully
After reviewing available labels, add appropriate ones to the issue:

```bash
# Add labels separately after creation
gh issue edit {issue-number} --add-label "UI,enhancement,✓"
```

**Label Selection Guidelines:**

**Type Labels** (What kind of work):
- `enhancement` - New feature or improvement
- `bug` / `✘` / `✘✘` / `✘✘✘` - Defects (severity-based)
- `documentation` - Documentation updates
- `technical-debt` - Code quality improvements
- `testing` - Test-related work

**Scope Labels** (What area):
- `UI` - User interface changes
- `UX` - User experience improvements
- `model` - Data model changes
- `architecture` - Structural changes
- `performance` - Optimization work
- `i18n` - Internationalization/localization

**Priority Labels** (How urgent):
- `P0-Critical` - Blocking daily use (immediate action)
- `P1-High` - Important features (current milestone)
- `P2-Medium` - Nice-to-have improvements (next milestone)
- `P3-Low` - Future enhancements (backlog)
- `✓` / `✓✓` / `✓✓✓` - Feature priority (low/medium/high)

**Best practices:**
- Use 2-4 labels per issue (type + scope + priority)
- Don't over-label - keep it meaningful
- Be consistent with label combinations across similar issues

#### 4. Assign Milestone Thoughtfully

**IMPORTANT**: Milestone assignment requires careful consideration and should **never** be done automatically or hastily.

##### When to Assign Milestones

**Before assigning**, ask these questions:

1. **Is this issue required for the next release?**
   - If yes → Consider current milestone (e.g., 0.1.0)
   - If no → Leave unassigned or assign to future milestone

2. **What is the scope and complexity?**
   - Small fix/enhancement → May fit in current milestone
   - Large feature → May need its own milestone or future milestone

3. **Are there dependencies?**
   - Blocking other issues → Higher priority for current milestone
   - Blocked by other issues → Future milestone or backlog

4. **What is the project's current focus?**
   - Aligns with current goals → Current milestone
   - Nice-to-have → Future milestone
   - Experimental → No milestone (backlog)

##### Milestone Assignment Process

```bash
# First, list available milestones
gh api repos/:owner/:repo/milestones --jq '.[] | "\(.title) - \(.description)"'

# Or view in browser
gh repo view --web

# After careful consideration, assign milestone
gh issue edit {issue-number} --milestone "0.1.0"
```

##### Milestone Guidelines

**Current Milestone (e.g., 0.1.0):**
- Critical bugs affecting current functionality
- High-priority features for imminent release
- Issues blocking other current-milestone work
- Small improvements with high impact
- Issues actively being worked on

**Next Milestone (e.g., 0.2.0):**
- Planned features for next release cycle
- Medium-priority improvements
- Issues that depend on current milestone completion
- Features that need more design/planning

**Future Milestones (e.g., 1.0.0):**
- Long-term architectural changes
- Major feature additions
- Issues requiring significant research
- Low-priority enhancements

**No Milestone (Backlog):**
- Exploratory ideas
- Nice-to-have features (undefined priority)
- Issues needing more discussion
- Low-priority technical debt
- Community suggestions pending evaluation

##### Milestone Assignment Examples

```bash
# ✅ CORRECT: Thoughtful assignment
# Issue: Critical bug in meal planning
gh issue edit 123 --milestone "0.1.0"
# Reasoning: Breaks core functionality, must fix before release

# ✅ CORRECT: Deferred to future
# Issue: Add advanced filtering to recipe search
gh issue edit 124 --milestone "0.2.0"
# Reasoning: Nice feature but not critical for 0.1.0, plan for next release

# ✅ CORRECT: No milestone
# Issue: Explore alternative recommendation algorithms
# Don't assign milestone yet
# Reasoning: Research task, needs scoping before committing to milestone

# ❌ INCORRECT: Automatic assignment
# Don't automatically assign everything to current milestone
# Each issue deserves individual consideration
```

##### Milestone Review and Adjustment

Milestones are not permanent. Review and adjust as needed:

```bash
# Move issue to different milestone if priorities change
gh issue edit {issue-number} --milestone "0.2.0"

# Remove milestone if issue is deferred
gh issue edit {issue-number} --milestone ""
```

**When to review milestones:**
- During sprint/release planning
- When issue scope changes significantly
- When priorities shift
- When issues are blocked or unblocked
- Before starting work on a milestone

#### 5. Complete Issue Creation Checklist

Before considering an issue "properly created", verify:

- [ ] Issue created with clear title and comprehensive description
- [ ] Available labels reviewed with `gh label list`
- [ ] Appropriate labels added (type + scope + priority)
- [ ] Milestone assignment carefully considered
- [ ] Milestone assigned only if issue fits clearly into release plan
- [ ] Related issues linked if applicable
- [ ] Issue appears correctly in project board (if using)

### Issue Management Commands Reference

```bash
# Create issue (no labels/milestones)
gh issue create --title "Title" --body "Description"

# Review available labels
gh label list

# Add labels after creation
gh issue edit {issue-number} --add-label "label1,label2"

# List milestones
gh api repos/:owner/:repo/milestones --jq '.[] | "\(.title)"'

# Assign milestone after consideration
gh issue edit {issue-number} --milestone "0.1.0"

# Remove milestone if needed
gh issue edit {issue-number} --milestone ""

# View issue to verify changes
gh issue view {issue-number}

# Link related issues in issue body or comments
gh issue comment {issue-number} --body "Related to #123"
```

### Issue Quality Standards

Every issue should include:

1. **Clear Title**: Use conventional commit format (`type: brief description`)
2. **Context**: Why is this issue being created?
3. **Current Behavior**: What happens now?
4. **Expected Behavior**: What should happen?
5. **Proposed Solution**: How might we solve it? (if applicable)
6. **Tasks**: Checklist of work items
7. **Acceptance Criteria**: How do we know it's done?
8. **Technical Notes**: Implementation details, files affected
9. **Test Cases**: Expected test scenarios

This structured approach ensures issues are well-defined and actionable.

## GitHub Projects Integration

This project uses GitHub Projects for issue tracking and workflow management. All issues should be added to the **Gastrobrain** project and configured with appropriate field values.

### Project Information

- **Project Name**: Gastrobrain
- **Project Number**: 3
- **Owner**: alemdisso
- **Project ID**: `PVT_kwHOABLkTc4A5MPP`

### Project Fields

The Gastrobrain project includes the following custom fields:

**Status** (Single Select):
- `Backlog` (ID: `f75ad846`) - New issues, not yet ready to work on
- `Ready` (ID: `61e4505c`) - Ready to be picked up for work
- `In progress` (ID: `47fc9ee4`) - Currently being worked on
- `In review` (ID: `df73e18b`) - Implementation complete, needs verification
- `Done` (ID: `98236657`) - Completed

**Priority** (Single Select):
- `P0` (ID: `79628723`) - Critical priority
- `P1` (ID: `0a877460`) - High priority
- `P2` (ID: `da944a9c`) - Medium priority

**Size** (Single Select) - Estimated effort:
- `XS` (ID: `6c6483d2`) - < 1 hour
- `S` (ID: `f784b110`) - 1-2 hours
- `M` (ID: `7515a9f1`) - 2-4 hours
- `L` (ID: `817d0097`) - 4-8 hours
- `XL` (ID: `db339eb2`) - > 8 hours (consider breaking down)

**Estimate** (Number) - Story points for effort estimation (whole numbers only)

**Other Fields**:
- Title, Assignees, Labels, Milestone (auto-populated from issue)
- Start date, End date (optional)
- Parent issue, Sub-issues progress (for epic tracking)
- Linked pull requests, Reviewers (auto-populated)

### Project Workflow

#### 1. Add Issue to Project

After creating an issue, immediately add it to the Gastrobrain project:

```bash
# Add issue to project (returns item ID for next steps)
gh project item-add 3 --owner alemdisso --url https://github.com/alemdisso/gastrobrain/issues/{issue-number} --format json | jq -r '.id'

# Store the item ID for subsequent commands
ITEM_ID=$(gh project item-add 3 --owner alemdisso --url https://github.com/alemdisso/gastrobrain/issues/{issue-number} --format json | jq -r '.id')
```

**Note**: The `--format json` output includes the `id` field (format: `PVTI_...`) which is required for editing project fields.

#### 2. Set Project Fields

After adding the issue to the project, configure its fields based on the issue characteristics:

##### Set Status

For new issues in the current milestone, set status to "Backlog":

```bash
# Set Status to Backlog
gh project item-edit \
  --id {item-id} \
  --field-id PVTSSF_lAHOABLkTc4A5MPPzguCBuU \
  --project-id PVT_kwHOABLkTc4A5MPP \
  --single-select-option-id f75ad846
```

**Status Guidelines**:
- **Backlog**: All new issues start here
- **Ready**: Move here during planning when issue is well-defined and ready to work on
- **In progress**: Set when you start working on the issue
- **In review**: Set when implementation is complete and you need to verify before closing
- **Done**: Set when issue is merged and closed

##### Set Size

Estimate the effort required and set the size field:

```bash
# Set Size based on estimated effort
# XS (< 1 hour)
gh project item-edit \
  --id {item-id} \
  --field-id PVTSSF_lAHOABLkTc4A5MPPzguCB3M \
  --project-id PVT_kwHOABLkTc4A5MPP \
  --single-select-option-id 6c6483d2

# S (1-2 hours)
gh project item-edit \
  --id {item-id} \
  --field-id PVTSSF_lAHOABLkTc4A5MPPzguCB3M \
  --project-id PVT_kwHOABLkTc4A5MPP \
  --single-select-option-id f784b110

# M (2-4 hours)
gh project item-edit \
  --id {item-id} \
  --field-id PVTSSF_lAHOABLkTc4A5MPPzguCB3M \
  --project-id PVT_kwHOABLkTc4A5MPP \
  --single-select-option-id 7515a9f1

# L (4-8 hours)
gh project item-edit \
  --id {item-id} \
  --field-id PVTSSF_lAHOABLkTc4A5MPPzguCB3M \
  --project-id PVT_kwHOABLkTc4A5MPP \
  --single-select-option-id 817d0097

# XL (> 8 hours - consider breaking down)
gh project item-edit \
  --id {item-id} \
  --field-id PVTSSF_lAHOABLkTc4A5MPPzguCB3M \
  --project-id PVT_kwHOABLkTc4A5MPP \
  --single-select-option-id db339eb2
```

**Size Estimation Guidelines**:
- **XS** (< 1 hour): Simple fixes, documentation updates, minor tweaks
- **S** (1-2 hours): Small features, straightforward bug fixes, UI improvements
- **M** (2-4 hours): Medium features, complex bug fixes, refactoring tasks
- **L** (4-8 hours): Large features, architectural changes, major refactoring
- **XL** (> 8 hours): Epic-level work - **strongly consider breaking down** into smaller issues

##### Set Estimate

Provide story points to estimate effort:

```bash
# Set Estimate (story points, whole numbers only)
gh project item-edit \
  --id {item-id} \
  --field-id PVTF_lAHOABLkTc4A5MPPzguCB3Q \
  --project-id PVT_kwHOABLkTc4A5MPP \
  --number {points}

# Examples:
# 1 point (smallest meaningful task)
--number 1

# 2 points (small task)
--number 2

# 3 points (medium task)
--number 3

# 5 points (larger task)
--number 5

# 8 points (large task, consider breaking down)
--number 8
```

**Estimate Guidelines**:
- **Use whole numbers only** - No decimals (avoids false precision)
- **Use story points, not hours** - Points represent relative effort/complexity
- Should roughly align with Size selection
- Common point values: 1, 2, 3, 5, 8, 13 (Fibonacci-like scale)
- Be realistic, not optimistic
- Consider complexity, uncertainty, and effort
- If estimate is > 8 points, consider breaking down the issue

##### Set Priority (Optional)

Priority can be set via GitHub labels or project field:

```bash
# Set Priority via project field
# P0 (Critical)
gh project item-edit \
  --id {item-id} \
  --field-id PVTSSF_lAHOABLkTc4A5MPPzguCB3I \
  --project-id PVT_kwHOABLkTc4A5MPP \
  --single-select-option-id 79628723

# P1 (High)
gh project item-edit \
  --id {item-id} \
  --field-id PVTSSF_lAHOABLkTc4A5MPPzguCB3I \
  --project-id PVT_kwHOABLkTc4A5MPP \
  --single-select-option-id 0a877460

# P2 (Medium)
gh project item-edit \
  --id {item-id} \
  --field-id PVTSSF_lAHOABLkTc4A5MPPzguCB3I \
  --project-id PVT_kwHOABLkTc4A5MPP \
  --single-select-option-id da944a9c
```

**Note**: Priority can also be managed via GitHub issue labels (P0-Critical, P1-High, P2-Medium, P3-Low, or ✓/✓✓/✓✓✓).

#### 3. Complete Project Setup Example

Here's a complete example of creating an issue and setting all project fields:

```bash
# Step 1: Create issue (no labels/milestones)
gh issue create --title "ui: fix quantity display format" --body "$(cat <<'EOF'
[Full issue description]
EOF
)"

# Step 2: Review and add labels
gh label list
gh issue edit 167 --add-label "UI,enhancement,✓"

# Step 3: Consider milestone assignment
# (Think carefully - see Milestone Guidelines above)
gh issue edit 167 --milestone "0.1.0"

# Step 4: Add to project and capture item ID
ITEM_ID=$(gh project item-add 3 --owner alemdisso --url https://github.com/alemdisso/gastrobrain/issues/167 --format json | jq -r '.id')
echo "Item ID: $ITEM_ID"

# Step 5: Set Status to Backlog
gh project item-edit \
  --id $ITEM_ID \
  --field-id PVTSSF_lAHOABLkTc4A5MPPzguCBuU \
  --project-id PVT_kwHOABLkTc4A5MPP \
  --single-select-option-id f75ad846

# Step 6: Set Size to XS (< 1 hour)
gh project item-edit \
  --id $ITEM_ID \
  --field-id PVTSSF_lAHOABLkTc4A5MPPzguCB3M \
  --project-id PVT_kwHOABLkTc4A5MPP \
  --single-select-option-id 6c6483d2

# Step 7: Set Estimate to 1 point (small task)
gh project item-edit \
  --id $ITEM_ID \
  --field-id PVTF_lAHOABLkTc4A5MPPzguCB3Q \
  --project-id PVT_kwHOABLkTc4A5MPP \
  --number 1

# Step 8: Verify the issue in project
gh issue view 167
```

#### 4. Updating Project Status During Work

As you progress through the issue, update the Status field:

```bash
# When starting work: Set to "In progress"
gh project item-edit \
  --id {item-id} \
  --field-id PVTSSF_lAHOABLkTc4A5MPPzguCBuU \
  --project-id PVT_kwHOABLkTc4A5MPP \
  --single-select-option-id 47fc9ee4

# When ready for final verification: Set to "In review"
gh project item-edit \
  --id {item-id} \
  --field-id PVTSSF_lAHOABLkTc4A5MPPzguCBuU \
  --project-id PVT_kwHOABLkTc4A5MPP \
  --single-select-option-id df73e18b
```

**Important: GitHub Project Automation**

When an issue is **closed**, GitHub Projects automatically moves it to "Done" status. **You do not need to manually update the status to "Done"** after closing an issue.

Manual status update to "Done" is only needed in rare cases where you want to mark something as done without closing the issue.

**Note**: You'll need to retrieve the item ID if you don't have it saved. Use:
```bash
gh project item-list 3 --owner alemdisso --format json | jq '.items[] | select(.content.number == {issue-number}) | .id'
```

### Project Field Reference

Quick reference for common project field operations:

```bash
# Field IDs (for reference)
STATUS_FIELD_ID="PVTSSF_lAHOABLkTc4A5MPPzguCBuU"
SIZE_FIELD_ID="PVTSSF_lAHOABLkTc4A5MPPzguCB3M"
ESTIMATE_FIELD_ID="PVTF_lAHOABLkTc4A5MPPzguCB3Q"
PRIORITY_FIELD_ID="PVTSSF_lAHOABLkTc4A5MPPzguCB3I"
PROJECT_ID="PVT_kwHOABLkTc4A5MPP"

# Status option IDs
STATUS_BACKLOG="f75ad846"
STATUS_READY="61e4505c"
STATUS_IN_PROGRESS="47fc9ee4"
STATUS_IN_REVIEW="df73e18b"
STATUS_DONE="98236657"

# Size option IDs
SIZE_XS="6c6483d2"  # < 1 hour
SIZE_S="f784b110"   # 1-2 hours
SIZE_M="7515a9f1"   # 2-4 hours
SIZE_L="817d0097"   # 4-8 hours
SIZE_XL="db339eb2"  # > 8 hours

# Priority option IDs
PRIORITY_P0="79628723"  # Critical
PRIORITY_P1="0a877460"  # High
PRIORITY_P2="da944a9c"  # Medium

# Get item ID from issue number
get_item_id() {
  gh project item-list 3 --owner alemdisso --format json | jq -r ".items[] | select(.content.number == $1) | .id"
}

# Usage example
ITEM_ID=$(get_item_id 167)
```

### Project Best Practices

1. **Always add new issues to the project** - No exceptions
2. **Set Status to "Backlog" for new issues** - Unless immediately starting work
3. **Estimate Size and Estimate together** - They should align
4. **Update Status as work progresses** - Keep project board current
5. **Review project board during planning** - Move "Backlog" → "Ready" for upcoming work
6. **Use Size to inform sprint planning** - Don't overcommit
7. **Track actual time vs. estimate** - Learn and improve estimates

### Troubleshooting

**Can't find item ID?**
```bash
# List all items in project with issue numbers
gh project item-list 3 --owner alemdisso --format json | jq '.items[] | {id: .id, number: .content.number, title: .content.title}'
```

**Need to update project field options?**
```bash
# List all field options for Status, Priority, Size
gh api graphql -f query='
{
  user(login: "alemdisso") {
    projectV2(number: 3) {
      fields(first: 20) {
        nodes {
          ... on ProjectV2SingleSelectField {
            name
            id
            options {
              id
              name
            }
          }
        }
      }
    }
  }
}' | jq '.data.user.projectV2.fields.nodes[] | select(.name != null)'
```

**View project in browser:**
```bash
gh project view 3 --owner alemdisso --web
```

## Git Flow Workflow

This project follows the **Git Flow workflow model** for organized branch management and release cycles.

### Core Branches

#### Production Branches
- **`master`** - Production-ready code with tagged releases (0.1, 0.2, 1.0)
  - Always contains stable, deployable code
  - All commits should be tagged with version numbers
  - Only receives merges from `release` and `hotfix` branches

- **`develop`** - Integration branch for ongoing development
  - Contains the latest development changes
  - All feature branches merge here
  - Serves as the base for release branches

#### Supporting Branches
- **`release/`** - Preparation for production releases
- **`hotfix/`** - Emergency fixes for production issues
- **`feature/`** - New feature development (existing convention maintained)

### Workflow Process

#### Feature Development
```bash
# Create feature branch from develop
git checkout develop
git pull origin develop
git checkout -b feature/{issue-number}-{short-description}

# Work on feature
# ... make commits ...

# Merge back to develop when complete
git checkout develop
git pull origin develop
git merge feature/{issue-number}-{short-description}
git push origin develop

# Delete feature branch
git branch -d feature/{issue-number}-{short-description}
```

#### Release Process
```bash
# Create release branch from develop when ready
git checkout develop
git pull origin develop
git checkout -b release/{version}

# Final testing and bug fixes in release branch
# ... make necessary fixes ...

# Merge to master and tag
git checkout master
git pull origin master
git merge release/{version}
git tag -a {version} -m "Release version {version}"
git push origin master --tags

# Merge back to develop
git checkout develop
git merge release/{version}
git push origin develop

# Delete release branch
git branch -d release/{version}
```

#### Hotfix Process
```bash
# Create hotfix branch from master for critical production bugs
git checkout master
git pull origin master
git checkout -b hotfix/{patch-version}-{short-description}

# Fix the issue
# ... make commits ...

# Merge to master and tag
git checkout master
git merge hotfix/{patch-version}-{short-description}
git tag -a {patch-version} -m "Hotfix version {patch-version}"
git push origin master --tags

# Merge to develop
git checkout develop
git merge hotfix/{patch-version}-{short-description}
git push origin develop

# Delete hotfix branch
git branch -d hotfix/{patch-version}-{short-description}
```

### Git Flow Rules

1. **`master` always contains production-ready code**
   - Never commit directly to master
   - All releases are tagged for version tracking

2. **`develop` contains latest development changes**
   - All features merge here first
   - Base for all release branches

3. **Release branches allow final polish**
   - Created from develop when feature-complete
   - Only bug fixes and release preparation
   - Prevents blocking new development

4. **Hotfixes ensure production issues can be addressed immediately**
   - Created from master for critical bugs
   - Merged to both master and develop
   - Tagged as patch releases

5. **All releases are tagged for version tracking**
   - Semantic versioning (MAJOR.MINOR.PATCH)
   - Tags enable easy rollback and reference

### Branch Naming Conventions (Updated for Git Flow)

**Core Branches:**
- `master` - Production releases
- `develop` - Development integration

**Supporting Branches:**
- `feature/{issue-number}-{short-description}` - New features
- `release/{version}` - Release preparation (e.g., `release/1.2.0`)
- `hotfix/{patch-version}-{short-description}` - Production fixes (e.g., `hotfix/1.2.1-login-crash`)

**Legacy Branch Types (still supported for non-feature work):**
- `bugfix/{issue-number}-{short-description}` - Bug fixes for develop
- `testing/{issue-number}-{short-description}` - Test improvements
- `refactor/{issue-number}-{short-description}` - Code refactoring
- `ui/{issue-number}-{short-description}` - UI improvements
- `docs/{issue-number}-{short-description}` - Documentation updates
