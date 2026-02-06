# Phase 1 Analysis Template

Use this template to document Phase 1 analysis findings for an issue.

## Issue Information

| Field | Value |
|-------|-------|
| Issue | #XXX |
| Title | [Issue title] |
| Type | [Bug/Feature/Refactor/Tech Debt] |
| Branch | `feature/XXX-description` |
| Roadmap | `docs/planning/0.1.X/ISSUE-XXX-ROADMAP.md` |
| Analysis Date | YYYY-MM-DD |

---

## Checkpoint 1: Requirements Summary

### User Story / Pain Point

[As a user, I want... OR The problem being solved is...]

### Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3
- [ ] Criterion 4

### Scope

**In Scope:**
- [Item 1]
- [Item 2]

**Out of Scope:**
- [Item 1]
- [Item 2]

### Clarifications Needed

- [ ] [Question 1] - [Answer/Status]
- [ ] [Question 2] - [Answer/Status]

---

## Checkpoint 2: Codebase Analysis

### Affected Files

| Category | File | Change Type | Notes |
|----------|------|-------------|-------|
| Models | `lib/models/X.dart` | Modify | [What changes] |
| Services | `lib/core/services/X.dart` | Create | [Purpose] |
| Widgets | `lib/widgets/X.dart` | Modify | [What changes] |
| Screens | `lib/screens/X.dart` | None | N/A |
| Database | `migrations/` | Create | [Migration needed] |
| Localization | `l10n/app_*.arb` | Modify | [X strings] |

### Similar Patterns Found

#### Pattern 1: [Name]
- **Location:** `lib/path/to/file.dart`
- **Lines:** XX-YY
- **Approach:** [How it solves similar problem]
- **Relevance:** [Why follow this pattern]

#### Pattern 2: [Name]
- **Location:** `lib/path/to/file.dart`
- **Approach:** [Description]
- **Relevance:** [Why applicable]

### Dependencies

| Dependency | Direction | Impact |
|------------|-----------|--------|
| [Component X] | Depends on | [Why] |
| [Component Y] | Used by | [Impact] |
| [Component Z] | Integrates with | [How] |

---

## Checkpoint 3: Technical Design

### Recommended Approach: [Approach Name]

**Description:**
[2-3 sentences describing the approach]

**Implementation Steps:**
1. [Step 1]
2. [Step 2]
3. [Step 3]
4. [Step 4]

**Pros:**
- [Advantage 1]
- [Advantage 2]
- [Advantage 3]

**Cons:**
- [Disadvantage 1]
- [Disadvantage 2]

### Alternatives Considered

#### Alternative: [Name]
- **Description:** [Brief description]
- **Rejected because:** [Reason]

### Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| [Decision 1] | [Choice] | [Why] |
| [Decision 2] | [Choice] | [Why] |
| [Decision 3] | [Choice] | [Why] |

### Design Patterns to Apply

- [ ] [Pattern 1] from `lib/path/to/file.dart`
- [ ] [Pattern 2] from `lib/path/to/file.dart`

---

## Checkpoint 4: Risk & Edge Cases

### Risk Assessment

| Risk | Level | Mitigation |
|------|-------|------------|
| [Risk 1] | High/Med/Low | [How to mitigate] |
| [Risk 2] | High/Med/Low | [How to mitigate] |
| [Risk 3] | High/Med/Low | [How to mitigate] |

### Edge Cases

| Edge Case | Scenario | Handling |
|-----------|----------|----------|
| [Case 1] | [When it occurs] | [How to handle] |
| [Case 2] | [When it occurs] | [How to handle] |
| [Case 3] | [When it occurs] | [How to handle] |
| [Case 4] | [When it occurs] | [How to handle] |

### Backward Compatibility

- [ ] Existing data: [Impact]
- [ ] Existing API: [Impact]
- [ ] User workflows: [Impact]
- [ ] Rollback safety: [Can rollback?]

### Testing Requirements

**Unit Tests:**
- [ ] [Test description]
- [ ] [Test description]

**Widget Tests:**
- [ ] [Test description]
- [ ] [Test description]

**Edge Case Tests:**
- [ ] [Test description]
- [ ] [Test description]

---

## Checkpoint 5: Implementation Plan

### Step-by-Step Guide

#### Step 1: [Name]
- **Files:** [Files to create/modify]
- **Pattern:** [Pattern to follow]
- **Verification:** [How to verify]

#### Step 2: [Name]
- **Files:** [Files to create/modify]
- **Pattern:** [Pattern to follow]
- **Verification:** [How to verify]

#### Step 3: [Name]
- **Files:** [Files to create/modify]
- **Pattern:** [Pattern to follow]
- **Verification:** [How to verify]

#### Step N: Localization
- **app_en.arb:** [Keys to add]
- **app_pt.arb:** [Keys to add]

### Code Examples

#### [Example 1 Name]
```dart
// Code example
```

#### [Example 2 Name]
```dart
// Code example
```

### Implementation Checklist for Phase 2

- [ ] Step 1: [Description]
- [ ] Step 2: [Description]
- [ ] Step 3: [Description]
- [ ] Step 4: [Description]
- [ ] Step 5: Integration verification

---

## Analysis Summary

| Metric | Value |
|--------|-------|
| Files to Create | X |
| Files to Modify | X |
| Edge Cases | X |
| Risks Identified | X |
| Test Categories | X |
| Implementation Steps | X |
| Estimated Effort | X points |

---

*Analysis completed on [date]*
*Ready for Phase 2 implementation*
