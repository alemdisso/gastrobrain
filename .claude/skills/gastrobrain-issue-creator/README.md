# Gastrobrain Issue Creator Skill

Transform informal bug reports, feature requests, or technical debt discoveries into well-structured GitHub issues following Gastrobrain conventions through an interactive checkpoint-based process.

## Quick Start

**Trigger the skill with:**
- "Create an issue for [description]"
- "I found a bug: [description]"
- "Feature request: [description]"
- "We should refactor [component]"

**The skill will guide you through 6 checkpoints to create a complete, actionable issue.**

## What This Skill Does

✅ **Transforms informal reports** into structured GitHub issues
✅ **Interactive 6-checkpoint process** ensures accuracy and completeness
✅ **Provides technical context** (files, patterns, related issues)
✅ **Suggests labels and priorities** with reasoning
✅ **Estimates story points** with detailed justification
✅ **Detects related issues** automatically
✅ **Generates exact GitHub CLI commands** ready to execute
✅ **Allows revision** at any checkpoint

## The 6-Checkpoint Process

```
1. Understanding the Problem
   └─ Confirm issue type, scope, priority
   └─ Ask clarifying questions
   └─ WAIT for user confirmation

2. Issue Details
   └─ Draft title, context, current/expected behavior
   └─ WAIT for user approval

3. Implementation Guidance
   └─ Propose solution, break down tasks
   └─ Provide technical context
   └─ WAIT for user input

4. Acceptance & Testing
   └─ Define "done" criteria
   └─ Identify test scenarios
   └─ WAIT for user confirmation

5. Labels & Priority
   └─ Suggest labels with reasoning
   └─ Estimate story points with breakdown
   └─ WAIT for user agreement

6. Final Review
   └─ Show complete issue markdown
   └─ WAIT for final approval
   └─ Provide GitHub CLI commands
```

**The skill NEVER skips checkpoints or generates issues without approval.**

## Issue Types Supported

| Type | Description | Typical Priority | Story Points |
|------|-------------|------------------|--------------|
| **Bug** | Defects, incorrect behavior | P0-P1 | 2-5 |
| **Enhancement** | New features, improvements | P1-P2 | 3-8 |
| **Technical Debt** | Code quality, refactoring | P3 | 2-5 |
| **Testing** | Test coverage gaps | P2-P3 | 1-3 |
| **Documentation** | Docs missing or unclear | P3 | 1-2 |

## File Structure

```
.github/skills/gastrobrain-issue-creator/
├── SKILL.md                           # Main skill documentation
├── README.md                          # This file
├── templates/
│   └── issue_templates.md             # Quick reference templates
└── examples/
    ├── bug_from_user_report.md        # Bug discovery example
    ├── enhancement_from_suggestion.md # Feature request example
    └── technical_debt_discovery.md    # Code quality issue example
```

## Example Usage

### Example 1: User Bug Report

**Input:**
```
User: "When I edit a meal with side dishes, they disappear after saving"
```

**Output:**
→ 6 checkpoints guiding you through issue creation
→ Complete bug issue with:
  - Clear reproduction steps
  - Technical context (affected files, related issues)
  - Comprehensive test cases
  - P1-High priority with reasoning
  - 3 point estimate with breakdown
→ Ready-to-execute GitHub CLI commands

**See:** `examples/bug_from_user_report.md` for full walkthrough

---

### Example 2: Feature Request

**Input:**
```
User: "It would be great if I could duplicate my meal plan to the next week"
```

**Output:**
→ 6 checkpoints with clarifying questions
→ Complete enhancement issue with:
  - User pain point clearly defined
  - Implementation approach
  - Localization considerations (EN/PT-BR)
  - Edge cases identified
  - P2-Medium priority with reasoning
  - 5 point estimate with breakdown
→ Ready-to-execute GitHub CLI commands

**See:** `examples/enhancement_from_suggestion.md` for full walkthrough

---

### Example 3: Technical Debt Discovery

**Input:**
```
Developer: "While working on #250, I noticed duplicate protein counting logic in three places"
```

**Output:**
→ Detects active work context (branch, current issue)
→ 6 checkpoints creating refactoring issue
→ Complete technical debt issue with:
  - Discovery context referenced (#250)
  - Specific files and methods identified
  - Refactoring approach outlined
  - Pure refactoring emphasized (no behavior changes)
  - P3-Low priority with reasoning
  - 2 point estimate with breakdown
→ Ready-to-execute GitHub CLI commands

**See:** `examples/technical_debt_discovery.md` for full walkthrough

---

## Label System

### Type Labels
- `enhancement` - New features or improvements
- `bug` - Defects or incorrect behavior
- `technical-debt` - Code quality improvements
- `testing` - Test coverage work
- `documentation` - Documentation updates

### Scope Labels
- `UI` - User interface changes
- `UX` - User experience improvements
- `model` - Data model changes
- `architecture` - Structural/design changes
- `testing` - Test infrastructure
- `performance` - Optimization work
- `i18n` - Internationalization/localization

### Priority Labels
- `P0-Critical` - Blocks daily use (immediate)
- `P1-High` - Important (current/next sprint)
- `P2-Medium` - Nice-to-have (future sprint)
- `P3-Low` - Enhancement (backlog)

---

## Story Point Scale

| Points | Complexity | Estimated Effort | Example |
|--------|-----------|------------------|---------|
| **1** | Trivial | < 1 hour | Typo fix, simple config change |
| **2** | Small | 1-2 hours | Add field, simple fix, quick test |
| **3** | Medium | 2-4 hours | New widget, bug investigation |
| **5** | Larger | 4-8 hours | Feature with UI, service updates |
| **8** | Large | 8-16 hours | Complex feature, major refactor |
| **13+** | Epic | Break down | Should be split into smaller issues |

**The skill always provides reasoning for estimates.**

---

## Features

### Context Detection
- Detects active work (current branch, issue)
- Identifies issue type from description
- Suggests priority based on impact
- Finds related issues automatically

### Technical Guidance
- References specific files when known
- Links to similar patterns in codebase
- Notes database migrations if needed
- Mentions localization requirements
- References testing guides

### Quality Assurance
- Follows Gastrobrain conventions exactly
- Includes acceptance criteria for all issues
- Comprehensive test case identification
- Edge case consideration
- Error handling requirements

### Interactive Process
- Ask clarifying questions
- Allow revision at any checkpoint
- Incorporate user preferences
- Show complete issue before creation
- Provide exact CLI commands

---

## Best Practices

### When Creating Issues

**DO:**
- Use the checkpoint process (don't rush)
- Provide specific details
- Answer clarifying questions
- Review complete issue before approval
- Reference related issues when applicable

**DON'T:**
- Skip checkpoints for "simple" issues
- Create issues without user confirmation
- Guess at unknown technical details
- Make architectural decisions without user input

### Issue Quality Checklist

Before final approval, verify:
- [ ] Title follows convention: `[type]: [description]`
- [ ] Context explains why this matters
- [ ] Current/Expected behavior clearly distinguished
- [ ] Tasks are actionable and complete
- [ ] Acceptance criteria define "done"
- [ ] Technical notes include file paths
- [ ] Labels match issue type and scope
- [ ] Priority justified with reasoning
- [ ] Story points estimated with explanation
- [ ] Related issues referenced if applicable
- [ ] Localization considered if UI
- [ ] Testing approach mentioned

---

## GitHub CLI Commands

After approval, the skill provides exact commands:

```bash
# Create issue
gh issue create \
  --title "bug: side dishes disappear when editing" \
  --body "$(cat <<'EOF'
[Complete issue markdown]
EOF
)"

# Add labels
gh issue edit 267 --add-label "bug,UI,P1-High"

# Optional: Add to project
gh project item-add 3 --owner alemdisso \
  --url https://github.com/alemdisso/gastrobrain/issues/267

# Optional: Set milestone
gh issue edit 267 --milestone "0.1.6 - Shopping List & Polish"
```

---

## Advanced Features

### Related Issue Detection

The skill automatically searches for related issues:
```bash
Related Issues Detected:
- #237: "Consolidate MealEditService" (same service)
- #206: "Fix protein counting" (similar functionality)

Should I reference these? (y/n/which ones)
```

### Active Work Context

When working on another issue:
```
Context detected:
- Current branch: feature/250-save-button-fix
- Working on: Issue #250
- Discovered: Bug in related component

Should I:
1. Reference #250 in new issue
2. Note this was discovered during #250 work
3. Check if this blocks #250 completion
```

### Multiple Issues in One Report

If user describes multiple issues:
```
I detected TWO distinct issues:

Issue A: Side dishes disappear (data loss)
Issue B: Date picker allows future dates (validation)

Which would you like to create first? (A/B/both separately)
```

---

## Integration with Gastrobrain Workflow

This skill follows Gastrobrain conventions:

- **Git Flow:** Issues lead to feature branches from develop
- **Branch naming:** `{type}/{issue-number}-{description}`
- **Commit format:** `{type}: description (#{issue-number})`
- **Testing:** References DIALOG_TESTING_GUIDE, EDGE_CASE_TESTING_GUIDE
- **Localization:** Always considers EN/PT-BR for UI changes
- **Architecture:** References ServiceProvider, DatabaseHelper patterns
- **Documentation:** Links to CLAUDE.md, workflow docs

---

## Troubleshooting

**Q: The skill asked too many questions**
A: The checkpoint process ensures accuracy. Answer "y" quickly if details are correct.

**Q: I want to change something from an earlier checkpoint**
A: Say "n" or "revise" at Final Review and specify which checkpoint to revisit.

**Q: The estimate seems wrong**
A: Say "n" at Checkpoint 5 and provide your reasoning. The skill will adjust.

**Q: I need a simpler process for trivial issues**
A: For very simple fixes (typos, etc.), you can create issues directly. The skill is designed for non-trivial work.

---

## Version History

**v1.0.0** (2026-01-13)
- Initial release
- 6-checkpoint interactive process
- Bug, enhancement, technical debt, testing templates
- Context detection and related issue search
- Story point estimation with reasoning
- Complete example flows
- GitHub CLI command generation

---

## Getting Help

**Documentation:**
- Read `SKILL.md` for complete details
- Check `templates/issue_templates.md` for quick reference
- Review `examples/` for complete walkthroughs

**Feedback:**
- Issues with this skill: Create issue with `skill:issue-creator` label
- Suggestions: Add `enhancement` label

---

## License

Part of the Gastrobrain project. See main repository for license details.
