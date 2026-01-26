# Technical Debt Sprint Plan - [Sprint Name]

**Sprint Number:** [0.X.Y]
**Sprint Theme:** [e.g., "Code Health Foundation", "Testing Excellence", "Architecture Cleanup"]
**Duration:** [Start Date] - [End Date] ([X] days)
**Target:** 80% quality work, 20% critical bugs only

---

## Strategic Context

### Why This Tech Debt Sprint?

**Triggers:**
- [ ] Files >500 lines present
- [ ] Test coverage <70%
- [ ] Velocity declining >20%
- [ ] Tech debt >40% of backlog
- [ ] Debt >1 year old present
- [ ] Quarterly cadence (every 3-4 sprints)
- [ ] Other: [Specify]

**Current Health Status:**
- Code Quality: 🟢/🟡/🔴
- Tech Debt: 🟢/🟡/🔴
- Testing: 🟢/🟡/🔴
- Architecture: 🟢/🟡/🔴

**Primary Goals:**
1. [Goal 1 - e.g., "Eliminate all files >400 lines"]
2. [Goal 2 - e.g., "Achieve 90% test coverage"]
3. [Goal 3 - e.g., "Close all tech debt >6 months old"]

---

## Sprint Composition (80/20 Rule)

### Quality Work: 80% (XX points)

#### Refactoring: 50% (XX points total)

**Large File Refactoring:**
- [ ] `path/to/file1.dart` (XXX lines → target <300) - X pts (#XXX if exists)
- [ ] `path/to/file2.dart` (XXX lines → target <300) - X pts (#XXX if exists)
- [ ] `path/to/file3.dart` (XXX lines → target <300) - X pts (#XXX if exists)

**Code Duplication Elimination:**
- [ ] [Duplicate pattern 1] - across X files - X pts (#XXX)
- [ ] [Duplicate pattern 2] - across X files - X pts (#XXX)

**Service Extraction:**
- [ ] Extract [ServiceName] from [Component] - X pts (#XXX)
- [ ] Consolidate [functionality] into service - X pts (#XXX)

**Other Refactoring:**
- [ ] [Refactoring task 1] - X pts (#XXX)
- [ ] [Refactoring task 2] - X pts (#XXX)

**Total Refactoring:** XX points (50% of sprint)

---

#### Testing: 30% (XX points total)

**Coverage Gaps:**
- [ ] Add tests for [Component/Feature 1] - X pts (#XXX)
- [ ] Add tests for [Component/Feature 2] - X pts (#XXX)
- [ ] Fill edge case gaps in [Area] - X pts (#XXX)

**Test Infrastructure:**
- [ ] Improve [TestHelper/MockInfrastructure] - X pts (#XXX)
- [ ] Add [E2E/Integration] tests for [Flow] - X pts (#XXX)

**Test Debt:**
- [ ] Fix flaky tests in [Area] - X pts (#XXX)
- [ ] Update outdated test patterns - X pts (#XXX)

**Total Testing:** XX points (30% of sprint)

---

#### Documentation: 10% (XX points total)

**Architecture Documentation:**
- [ ] Update architecture diagrams - X pts
- [ ] Document refactoring patterns - X pts
- [ ] Update service layer documentation - X pts

**Code Documentation:**
- [ ] Add missing class/method documentation - X pts
- [ ] Update README with new patterns - X pts

**Testing Documentation:**
- [ ] Update testing guides with new patterns - X pts

**Total Documentation:** XX points (10% of sprint)

---

### Critical Bugs Only: 20% (XX points)

**P0 Critical Bugs:**
- [ ] #XXX - [Bug title] - X pts
- [ ] #XXX - [Bug title] - X pts

**Defer to Next Sprint:**
- P1-P2 bugs deferred
- New features deferred
- Enhancements deferred

**Total Bug Work:** XX points (20% of sprint)

---

## Success Criteria

### Code Quality Success

**File Length:**
- [ ] All files <400 lines (0 files >400)
- [ ] Target: All files <350 lines
- [ ] Stretch: Average file length <300 lines

**Code Smells:**
- [ ] All identified god classes refactored
- [ ] All code duplication >50 lines eliminated
- [ ] Long methods (>50 lines) reduced by XX%

**Refactoring Patterns:**
- [ ] Document XX reusable patterns
- [ ] Apply patterns consistently

---

### Technical Debt Success

**Debt Reduction:**
- [ ] Close all tech debt issues >6 months old
- [ ] Reduce debt % from XX% to <20%
- [ ] Reduce total debt issues by XX%

**Debt Prevention:**
- [ ] Establish monitoring for file length
- [ ] Set up regular refactoring cadence
- [ ] Document when to create tech debt issues

---

### Testing Success

**Coverage:**
- [ ] Achieve >85% overall coverage (currently XX%)
- [ ] Achieve >90% coverage in [critical areas]
- [ ] Fill all identified coverage gaps

**Test Quality:**
- [ ] Fix all flaky tests
- [ ] Reduce test execution time to <X minutes
- [ ] Improve test readability and maintainability

**Test Infrastructure:**
- [ ] [Infrastructure improvement 1] completed
- [ ] [Infrastructure improvement 2] completed

---

### Developer Experience Success

**Friction Reduction:**
- [ ] Developers report reduced friction (survey/feedback)
- [ ] Easier to add new features (validated post-sprint)
- [ ] Confidence in making changes increased

**Velocity Impact:**
- [ ] Expected velocity improvement next sprint: +XX%
- [ ] Time to implement similar features reduced

---

## Pre-Sprint Preparation

### Analysis Complete

- [ ] All large files identified and prioritized
- [ ] Code duplication patterns documented
- [ ] Test coverage gaps mapped
- [ ] Tech debt issues triaged

### Issues Created

- [ ] All refactoring issues created in GitHub
- [ ] All testing issues created in GitHub
- [ ] All documentation issues created in GitHub
- [ ] Issues estimated with story points

### Team Aligned

- [ ] Sprint goals communicated
- [ ] Success criteria understood
- [ ] 80/20 rule commitment
- [ ] No new features to be started

---

## Daily Focus Areas

### Day 1-2: Large File Refactoring
- Focus: Break down biggest files
- Goal: [Specific files to complete]

### Day 3-4: Testing & Coverage
- Focus: Fill coverage gaps
- Goal: [Specific coverage targets]

### Day 5: Service Extraction & Duplication
- Focus: Consolidate duplicated logic
- Goal: [Specific extractions]

### Day 6-7: Polish & Documentation
- Focus: Documentation, remaining items
- Goal: Complete all success criteria

---

## Risks & Mitigation

### Risk: Scope Creep

**Mitigation:**
- Strict 80/20 rule enforcement
- Defer all non-critical bugs
- No new features allowed
- Daily scope review

### Risk: Refactoring Breaking Tests

**Mitigation:**
- Run tests after each refactoring
- Small, incremental changes
- Commit after each successful change
- Pair review for complex refactorings

### Risk: Not Completing Sprint

**Mitigation:**
- Prioritize ruthlessly (P0 items first)
- Cut scope if needed (preserve 80/20 ratio)
- Extend sprint by 1-2 days if critical
- Accept partial completion if quality high

---

## Metrics Tracking

### Before Sprint

**Code Quality:**
- Average file length: XXX lines
- Files >400 lines: X
- Files >500 lines: X
- Largest file: XXX lines

**Technical Debt:**
- Total debt issues: X
- Debt as % backlog: XX%
- Oldest debt: X months
- Debt >6 months: X issues

**Testing:**
- Total tests: XXX
- Coverage: XX%
- Tests broken recently: XX%
- Coverage gaps: X areas

---

### After Sprint (Target)

**Code Quality:**
- Average file length: <300 lines
- Files >400 lines: 0
- Files >500 lines: 0
- Largest file: <350 lines

**Technical Debt:**
- Total debt issues: <X (reduction of XX%)
- Debt as % backlog: <20%
- Oldest debt: <3 months
- Debt >6 months: 0 issues

**Testing:**
- Total tests: XXX+ (growth of XX tests)
- Coverage: >85%
- Tests broken recently: 0%
- Coverage gaps: 0 critical gaps

---

## Post-Sprint Actions

### Sprint Retrospective

**What Went Well:**
- [Item 1]
- [Item 2]
- [Item 3]

**What Could Improve:**
- [Item 1]
- [Item 2]
- [Item 3]

**Action Items:**
- [ ] [Improvement 1]
- [ ] [Improvement 2]

### Velocity Impact Assessment

**Expected Impact:** [Faster/Maintained/Slower for next sprint]
**Reasoning:** [Why]

### Next Tech Debt Sprint

**Recommended Timing:** [When - typically Q+1]
**Preliminary Focus:** [What areas will likely need attention]

---

## Communication Plan

### Stakeholder Communication

**Before Sprint:**
- Explain purpose and benefits
- Set expectations (no feature delivery this sprint)
- Emphasize long-term value

**During Sprint:**
- Daily progress updates
- Visible progress (tests passing, files shrinking)
- Address concerns proactively

**After Sprint:**
- Demonstrate improvements (metrics, before/after)
- Show velocity impact in next sprints
- Justify time investment with data

---

## Sprint Summary

**Total Capacity:** XX points
**Quality Work:** XX points (80%)
**Bug Work:** XX points (20%)

**Expected Outcomes:**
- 🟢 Code Quality to HEALTHY status
- 🟢 Tech Debt to HEALTHY status (<20%)
- 🟢 Testing to HEALTHY status (>85%)
- 🟢 Developer Experience improved
- 🟢 Velocity increase expected next sprint

**Commitment Level:** 🟢 High / 🟡 Medium / 🔴 Low
**Why:** [Explanation]

---

**Status:** ✅ Approved / 🔄 Planning / ⏸️ Pending
**Approved By:** [Name/Date]
**Sprint Start:** [Date]
