# Implementation Checklist Template

Use this template to track Phase 2 implementation progress for an issue.

## Issue Information

| Field | Value |
|-------|-------|
| Issue | #XXX |
| Branch | `feature/XXX-description` |
| Roadmap | `docs/planning/0.1.X/ISSUE-XXX-ROADMAP.md` |
| Started | YYYY-MM-DD |
| Completed | - |

## Pre-Implementation Checklist

- [ ] Branch created from `develop`
- [ ] Roadmap Phase 1 (Analysis) complete
- [ ] Phase 2 requirements understood
- [ ] Patterns identified in codebase
- [ ] Checkpoint plan defined

## Implementation Categories

| Category | Needed | Delegated To |
|----------|--------|--------------|
| Database | Yes/No | gastrobrain-database-migration |
| Models | Yes/No | - |
| Services | Yes/No | - |
| Widgets | Yes/No | - |
| Providers | Yes/No | - |
| Localization | Yes/No | - |

## Checkpoint Tracking

### Checkpoint 1: [Name]
- **Goal**: [Brief description]
- **Pattern Reference**: [path/to/pattern.dart]
- **Status**: [ ] Pending / [ ] In Progress / [ ] Complete
- **Files Modified**:
  - [ ] file1.dart
  - [ ] file2.dart
- **Verification**:
  - [ ] flutter analyze passes
  - [ ] [Specific verification]

### Checkpoint 2: [Name]
- **Goal**: [Brief description]
- **Pattern Reference**: [path/to/pattern.dart]
- **Status**: [ ] Pending / [ ] In Progress / [ ] Complete
- **Files Modified**:
  - [ ] file1.dart
- **Verification**:
  - [ ] flutter analyze passes
  - [ ] [Specific verification]

### Checkpoint 3: [Name]
- **Goal**: [Brief description]
- **Pattern Reference**: [path/to/pattern.dart]
- **Status**: [ ] Pending / [ ] In Progress / [ ] Complete
- **Files Modified**:
  - [ ] file1.dart
- **Verification**:
  - [ ] flutter analyze passes
  - [ ] [Specific verification]

### Checkpoint N: [Name]
- **Goal**: [Brief description]
- **Pattern Reference**: [path/to/pattern.dart]
- **Status**: [ ] Pending / [ ] In Progress / [ ] Complete
- **Files Modified**:
  - [ ] file1.dart
- **Verification**:
  - [ ] flutter analyze passes
  - [ ] [Specific verification]

## Quality Gates Summary

| Gate | Status | Notes |
|------|--------|-------|
| Static Analysis | [ ] Pass | `flutter analyze` |
| File Length | [ ] Pass | All files < 400 lines |
| SOLID Principles | [ ] Pass | |
| Pattern Compliance | [ ] Pass | |
| Test Readiness | [ ] Pass | DI in place |
| Localization | [ ] Pass | Both ARB files |

## Files Modified Summary

### New Files
- [ ] `lib/path/to/new_file.dart`

### Modified Files
- [ ] `lib/path/to/modified_file.dart`

### Localization Files
- [ ] `lib/l10n/app_en.arb` - X strings added
- [ ] `lib/l10n/app_pt.arb` - X strings added

## Roadmap Update

Update Phase 2 checkboxes in roadmap:

```markdown
## Phase 2: Implementation

- [x] Task 1 (Checkpoint 1)
- [x] Task 2 (Checkpoint 2)
- [x] Task 3 (Checkpoint 3)
...
```

## Handoff Notes

### For Testing (Phase 3)

**Ready for `gastrobrain-testing-implementation`**

Key areas to test:
1. [Area 1] - [What to verify]
2. [Area 2] - [What to verify]
3. [Area 3] - [What to verify]

Edge cases identified:
- [ ] Empty state: [Description]
- [ ] Boundary: [Description]
- [ ] Error: [Description]

### For Code Review

**Ready for `gastrobrain-code-review`**

Review focus areas:
1. [Area 1] - Pattern compliance
2. [Area 2] - Error handling
3. [Area 3] - Performance

Known limitations:
- [Limitation 1]

## Completion Checklist

- [ ] All checkpoints complete
- [ ] All quality gates pass
- [ ] Roadmap checkboxes updated
- [ ] Handoff notes documented
- [ ] Ready for Phase 3 (Testing)

---

**Implementation completed on**: YYYY-MM-DD
**Time spent**: X hours across Y sessions
