# Sprint Plan: [Sprint Number] - [Sprint Theme]

**Sprint Period**: [Start Date] - [End Date] ([X] working days)
**Milestone**: [Milestone Name/Number]
**Total Story Points**: [Raw Points] ([Adjusted Points] adjusted)
**Target Velocity**: [X.X] points/day (based on [conservative/normal/optimistic] planning)

---

## Sprint Goal

[2-3 sentence summary of what this sprint aims to achieve, aligned with milestone theme]

Key deliverables:
- [Primary deliverable 1]
- [Primary deliverable 2]
- [Primary deliverable 3]

---

## Capacity Analysis

### Base Calculation
- **Available days**: [X] days
- **Median velocity**: 2.5 points/day
- **Base capacity**: [X × 2.5] = [XX] points

### Work Type Adjustments
- **Primary work type**: [Feature/Bug/Refactor/Testing/UI/etc.]
- **Type multiplier**: [X.Xx] ([justification from velocity calibration])
- **Overhead percentage**: [XX]% ([mobile tooling/localization/testing/etc.])

### Adjusted Capacity
```
Adjusted = Base × (1 - Overhead%) × Type Multiplier
         = [XX] × [X.XX] × [X.XX]
         = [XX.X] adjusted points
```

### Capacity Decision
- **Target**: [XX-XX] points ([conservative/normal] planning)
- **Confidence**: [High/Medium/Low]
- **Rationale**: [Why this capacity target is appropriate for this sprint]

---

## Issues Breakdown

### Theme 1: [Theme Name] ([X] issues, [XX] points)

#### Issue #XXX: [Issue Title]
- **Story Points**: [X] ([X.X] adjusted)
- **Type**: [Feature/Bug/Refactor/etc.]
- **Size**: [XS/S/M/L/XL]
- **Multiplier Applied**: [X.Xx] ([reason])
- **Dependencies**: [None / Issue #XXX must complete first / etc.]
- **Risk Level**: [High/Medium/Low]
- **Acceptance Criteria**:
  - [ ] [Criterion 1]
  - [ ] [Criterion 2]
  - [ ] [Criterion 3]

#### Issue #XXX: [Issue Title]
- **Story Points**: [X] ([X.X] adjusted)
- **Type**: [Feature/Bug/Refactor/etc.]
- **Size**: [XS/S/M/L/XL]
- **Multiplier Applied**: [X.Xx] ([reason])
- **Dependencies**: [None / Issue #XXX must complete first / etc.]
- **Risk Level**: [High/Medium/Low]
- **Acceptance Criteria**:
  - [ ] [Criterion 1]
  - [ ] [Criterion 2]

### Theme 2: [Theme Name] ([X] issues, [XX] points)

[Repeat structure above for each theme]

### Quick Wins / Flex Items ([X] issues, [XX] points)

[Issues that can be done at start for momentum or at end as stretch goals]

---

## Day-by-Day Breakdown

### Day 1: [Focus Area] ([XX] adjusted points)

**Goal**: [What this day aims to accomplish]

**Issues**:
- **Issue #XXX**: [Title] ([X.X] adjusted points)
  - **Why first**: [Rationale for sequencing - quick win / prerequisite / etc.]
  - **Deliverable**: [What should be complete by end of day]

- **Issue #XXX**: [Title] ([X.X] adjusted points)
  - **Why now**: [Rationale]
  - **Deliverable**: [What should be complete]

**Testing**: [Any testing work planned for Day 1]

**Risks**: [Any risks specific to Day 1 work]

---

### Day 2: [Focus Area] ([XX] adjusted points)

**Goal**: [What this day aims to accomplish]

**Issues**:
- **Issue #XXX**: [Title] ([X.X] adjusted points)
  - **Why now**: [Rationale - main feature when fresh / dependencies cleared / etc.]
  - **Deliverable**: [What should be complete]
  - **Dependencies Met**: [Prerequisites from Day 1 that enable this work]

**Testing**: [Any testing work planned for Day 2]

**Risks**: [Any risks specific to Day 2 work]

---

### Day 3: [Focus Area] ([XX] adjusted points)

**Goal**: [What this day aims to accomplish]

**Issues**:
- **Issue #XXX**: [Title or continuation] ([X.X] adjusted points)
  - **Why now**: [Rationale]
  - **Deliverable**: [What should be complete]

**Testing**: [Any testing work planned for Day 3]

**Risks**: [Any risks specific to Day 3 work]

---

### Day 4: [Focus Area] ([XX] adjusted points)

**Goal**: [What this day aims to accomplish]

**Issues**:
- **Issue #XXX**: [Title] ([X.X] adjusted points)
  - **Why now**: [Rationale - batching similar work / integration phase / etc.]
  - **Deliverable**: [What should be complete]

**Testing**: [Any testing work planned for Day 4]

**Risks**: [Any risks specific to Day 4 work]

---

### Day 5: [Focus Area] ([XX] adjusted points)

**Goal**: [What this day aims to accomplish - often polish, testing, flex work]

**Issues**:
- **Issue #XXX**: [Title] ([X.X] adjusted points)
  - **Why last**: [Rationale - open-ended work / can be cut / polish / etc.]
  - **Deliverable**: [What should be complete]

**Stretch Goals** (if time permits):
- Issue #XXX: [Deferred work that can be pulled in]
- Issue #XXX: [Additional work if sprint is ahead]

**Testing**: [Final testing work]

**Risks**: [Any risks specific to Day 5 work]

---

## Risk Assessment

### High Risks

| Risk | Impact | Likelihood | Mitigation | Owner |
|------|--------|------------|------------|-------|
| [Risk description] | [High/Medium/Low] | [High/Medium/Low] | [How we'll mitigate] | [Who's responsible] |
| [Example: UI iteration takes longer than expected] | High | Medium | 30% buffer applied, flex work in Day 5 can be cut | Developer |

### Medium Risks

| Risk | Impact | Likelihood | Mitigation | Owner |
|------|--------|------------|------------|-------|
| [Risk description] | [High/Medium/Low] | [High/Medium/Low] | [How we'll mitigate] | [Who's responsible] |

### Low Risks

| Risk | Impact | Likelihood | Mitigation | Owner |
|------|--------|------------|------------|-------|
| [Risk description] | [High/Medium/Low] | [High/Medium/Low] | [How we'll mitigate] | [Who's responsible] |

### Risk Mitigation Summary
- **Time Buffer**: [XX]% buffer included in estimates
- **Scope Flexibility**: [Which issues can be deferred if needed]
- **Dependency Management**: [How we're handling prerequisites]
- **Technical Unknowns**: [How we're addressing discovery work]

---

## Testing Strategy

### Test Coverage Requirements

#### Unit Tests
- **Issues requiring unit tests**: #XXX, #XXX
- **Estimated overhead**: [XX]% of implementation time
- **Focus areas**: [Business logic, models, services, etc.]
- **Success criteria**: >80% code coverage for new code

#### Widget Tests
- **Issues requiring widget tests**: #XXX, #XXX
- **Estimated overhead**: [XX]% of implementation time
- **Focus areas**: [UI components, screens, dialogs, etc.]
- **Success criteria**: >70% widget coverage for new UI

#### Integration Tests
- **Issues requiring integration tests**: #XXX, #XXX
- **Estimated overhead**: [XX]% of implementation time
- **Focus areas**: [Multi-component workflows, data flows, etc.]
- **Success criteria**: All critical paths tested

#### E2E Tests
- **Issues requiring E2E tests**: #XXX
- **Estimated overhead**: [XX]% of implementation time
- **Focus areas**: [Full user journeys, end-to-end workflows]
- **Success criteria**: Happy path + error path covered

#### Edge Case Tests (Issue #39 Standards)
- **Issues requiring edge case tests**: #XXX, #XXX
- **Estimated overhead**: [XX]% of implementation time
- **Categories to cover**:
  - [ ] Empty states (no data scenarios)
  - [ ] Boundary conditions (min/max, zero, negative)
  - [ ] Error scenarios (database failures, validation errors)
  - [ ] Interaction patterns (unusual user behaviors)
  - [ ] Data integrity (consistency across operations)
- **Reference**: `docs/testing/EDGE_CASE_TESTING_GUIDE.md`

#### Regression Tests
- **Issues requiring regression tests**: #XXX (if bug fixes)
- **Purpose**: Prevent reoccurrence of fixed bugs
- **Location**: `test/regression/`

### Testing Schedule

**Day 1-2**: [Testing work for early issues]
**Day 3**: [Main feature testing]
**Day 4**: [Integration and widget testing]
**Day 5**: [Edge case coverage, final validation]

### Localization Testing
- **Issues with user-facing strings**: #XXX, #XXX
- **Languages to test**: English (EN), Portuguese-BR (PT-BR)
- **ARB files to update**:
  - `lib/l10n/app_en.arb`
  - `lib/l10n/app_pt.arb`
- **Validation**: Run `flutter gen-l10n` after ARB changes

### Test Execution

**Local validation (WSL)**:
```bash
flutter analyze
flutter test
```

**CI/CD validation (GitHub Actions)**:
```bash
flutter build apk  # Cannot run in WSL
```

**Success criteria**:
- [ ] All tests pass (`flutter test`)
- [ ] No analysis issues (`flutter analyze`)
- [ ] CI/CD build succeeds
- [ ] Both languages tested manually
- [ ] Edge cases documented and tested

---

## Database Migration Plan

[If sprint includes database changes]

### Migrations Required

#### Migration 1: [Migration Name]
- **Issue**: #XXX
- **Type**: [Simple/Complex]
- **Changes**:
  - [Add column X to table Y with default value Z]
  - [Create table A with columns B, C, D]
- **Data migration**: [None / Script to transform existing data]
- **Rollback plan**: [How to revert if issues found]
- **Testing**:
  - [ ] Test on empty database
  - [ ] Test on database with existing data
  - [ ] Verify data integrity after migration

### Migration Schedule
- **When**: Day [X] (early in sprint to allow recovery time)
- **Validation**: Day [X+1] (ensure no issues before proceeding)

---

## Localization Impact

[If sprint includes UI changes requiring localization]

### ARB File Updates

#### New Strings Required
- **Issue #XXX**: [X] new strings
  - `stringKey1`: "English text" / "Texto em português"
  - `stringKey2`: "English text" / "Texto em português"

- **Issue #XXX**: [X] new strings
  - `stringKey3`: "English text" / "Texto em português"

### Localization Workflow
1. Add strings to `lib/l10n/app_en.arb`
2. Add translations to `lib/l10n/app_pt.arb`
3. Run `flutter gen-l10n` to generate code
4. Use `AppLocalizations.of(context)!.stringKey` in code
5. Test both languages in UI

### Localization Testing
- [ ] All new strings in both ARB files
- [ ] No hardcoded strings in code
- [ ] Both languages tested visually
- [ ] Layouts work with both language text lengths

---

## Dependencies & Prerequisites

### External Dependencies
- **Library/API**: [Name and version if adding new dependencies]
- **Impact**: [What this enables]
- **Risk**: [Availability, compatibility, etc.]

### Internal Prerequisites

| Issue | Prerequisite | Status | Blocker? |
|-------|--------------|--------|----------|
| #XXX | [Prerequisite work] | [Complete/In Progress/Not Started] | [Yes/No] |
| #XXX | [Prerequisite work] | [Complete/In Progress/Not Started] | [Yes/No] |

### Blocking Issues
[List any issues that MUST complete before others can start]
- Issue #XXX blocks Issue #XXX (reason: [backend before UI / migration before feature / etc.])

---

## Success Criteria

### Primary Goals (Must Complete)
- [ ] [Goal 1 - specific, measurable]
- [ ] [Goal 2 - specific, measurable]
- [ ] [Goal 3 - specific, measurable]
- [ ] All tests pass (`flutter test`)
- [ ] No analysis warnings (`flutter analyze`)
- [ ] CI/CD build succeeds

### Secondary Goals (Should Complete)
- [ ] [Goal 4 - nice to have]
- [ ] [Goal 5 - nice to have]
- [ ] Documentation updated
- [ ] Both languages tested

### Stretch Goals (If Time Permits)
- [ ] [Stretch goal 1 - deferred work that can be pulled in]
- [ ] [Stretch goal 2]

### Quality Gates
- [ ] All acceptance criteria met for committed issues
- [ ] Edge case coverage per Issue #39 standards
- [ ] Regression tests added for bug fixes
- [ ] Localization complete (EN + PT-BR)
- [ ] Code review self-checklist complete
- [ ] No known blockers for future work

### Sprint Completion Checklist
- [ ] All primary goals complete
- [ ] All committed issues resolved
- [ ] All tests passing (unit, widget, integration, E2E)
- [ ] No regression in existing functionality
- [ ] Documentation updated (if applicable)
- [ ] CHANGELOG.md updated with changes
- [ ] Ready to merge to `develop` branch
- [ ] Ready to create release branch (if milestone complete)

---

## Notes & Assumptions

### Assumptions
- [Assumption 1 about requirements, technical approach, etc.]
- [Assumption 2]

### Known Limitations
- [Limitation 1 - WSL cannot run flutter build/run]
- [Limitation 2]

### Follow-Up Work
[Issues identified during planning that should be created for future sprints]
- [Future work 1]
- [Future work 2]

### References
- Sprint Estimation Diary: `docs/archive/Sprint-Estimation-Diary.md`
- Issue Workflow: `docs/workflows/ISSUE_WORKFLOW.md`
- Edge Case Testing Guide: `docs/testing/EDGE_CASE_TESTING_GUIDE.md`
- Localization Protocol: `docs/workflows/L10N_PROTOCOL.md`
- GitHub Project #3: [Link to project board]

---

**Plan Created**: [Date]
**Plan Author**: [Name/Tool]
**Last Updated**: [Date]
