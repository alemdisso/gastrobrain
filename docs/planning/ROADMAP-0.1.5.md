# Roadmap: 0.1.5 - Test Coverage & Polish

**Milestone:** 0.1.5 - Test Coverage & Polish
**Status:** Planning
**Total Issues:** 7
**Total Points:** 14
**Start Date:** TBD
**Target Completion:** TBD

---

## Milestone Overview

**Theme:** Improve test coverage to >90% for critical dialogs, add coverage visibility infrastructure, and polish UI/UX.

**Goals:**
1. Set up test coverage reporting infrastructure (Codecov)
2. Improve dialog test coverage from ~75% to >90%
3. Implement deferred error handling tests (now unblocked)
4. Polish UI with visual hierarchy improvements
5. Add meal type selection feature for better meal tracking

**Success Criteria:**
- Coverage reporting active with Codecov badge in README
- All 3 dialog coverage issues reach >90% coverage
- Deferred error tests from Phase 3 implemented
- AddSideDishDialog has clear visual hierarchy
- Meals can be tagged with type (lunch/dinner/prep)

---

## Issues Summary

| # | Title | Type | Priority | Points | Estimate |
|---|-------|------|----------|--------|----------|
| #230 | Add test coverage reporting | Infrastructure | P1-Critical | S=2 | 3-5 hours |
| #247 | AddIngredientDialog coverage (75.6% → 90%) | Testing | P2-Medium | S=2 | 3-5 hours |
| #248 | EditMealRecordingDialog coverage (75.5% → 90%) | Testing | P2-Medium | S=2 | 3-5 hours |
| #249 | MealRecordingDialog coverage (75.5% → 90%) | Testing | P2-Medium | S=2 | 3-5 hours |
| #245 | Implement deferred Phase 3 error tests | Testing | P3-Low | S=1 | 1-1.5 hours |
| #251 | Visual hierarchy in AddSideDishDialog | UI/Polish | P2-Medium | S=2 | 3-4 hours |
| #199 | Meal type selection when recording | Feature | P2-Medium | M=3 | 6-8 hours |
| **TOTAL** | | | | **14** | **25-36 hours** |

---

## Dependency Graph

```
#230 (Coverage Infrastructure)
  │
  ├──► #247 (AddIngredientDialog coverage)
  │
  ├──► #248 (EditMealRecordingDialog coverage)
  │
  └──► #249 (MealRecordingDialog coverage)
             │
             └──► #245 (Deferred error tests) ◄── Also depends on #244, #237 (CLOSED)

#251 (AddSideDishDialog UI) ──► Independent
#199 (Meal type selection)  ──► Independent
```

**Key Dependencies:**
- **#230 blocks #247, #248, #249** - Coverage tooling needed to identify gaps
- **#245 was blocked by #244 and #237** - Both now CLOSED in 0.1.4
- **#251 and #199** - Fully independent, can be done anytime

---

## Recommended Execution Order

### Track A: Testing Infrastructure (Primary Track)

| Order | Issue | Dependencies | Reason |
|-------|-------|--------------|--------|
| 1 | #230 | None | Foundational - enables all coverage work |
| 2-4 | #247, #248, #249 | #230 | Can be parallelized after #230 |
| 5 | #245 | #244, #237 (closed) | Small cleanup task |

### Track B: Polish & Features (Can be interleaved)

| Order | Issue | Dependencies | Reason |
|-------|-------|--------------|--------|
| Any | #251 | None | UI improvement, independent |
| Any | #199 | None | Feature, independent |

---

## Execution Phases

### Phase 1: Coverage Infrastructure (Days 1-2)

**Issue #230: Add test coverage reporting**
- **Priority:** CRITICAL - Must be done first
- **Estimate:** S = 2 points (~3-5 hours)
- **Type:** Infrastructure

**Why first:**
- Foundational - blocks all coverage improvement issues
- Enables data-driven decisions for #247, #248, #249
- Low risk - following documented best practices
- High value - visibility into testing quality

**Deliverables:**
- Codecov integration active
- Coverage badge in README
- Local coverage generation documented
- CI/CD workflow updated

**Detailed roadmap:** [docs/planning/0.1.5/ISSUE-230-ROADMAP.md](0.1.5/ISSUE-230-ROADMAP.md)

---

### Phase 2: Dialog Coverage Improvement (Days 3-6)

**Issues #247, #248, #249: Dialog test coverage improvements**
- **Priority:** Medium - Core milestone work
- **Estimate:** S = 2 points each (~3-5 hours each)
- **Type:** Testing

**Why together:**
- Same approach for all three
- Can be parallelized
- Use coverage tooling from #230 to identify gaps
- Similar scope (~15% improvement each)

**Approach:**
1. Generate coverage report for specific dialog
2. Identify uncovered lines/branches
3. Write pragmatic tests for valuable coverage
4. Verify >90% achieved

**Detailed roadmaps:**
- [docs/planning/0.1.5/ISSUE-247-ROADMAP.md](0.1.5/ISSUE-247-ROADMAP.md) - AddIngredientDialog
- [docs/planning/0.1.5/ISSUE-248-ROADMAP.md](0.1.5/ISSUE-248-ROADMAP.md) - EditMealRecordingDialog
- [docs/planning/0.1.5/ISSUE-249-ROADMAP.md](0.1.5/ISSUE-249-ROADMAP.md) - MealRecordingDialog

---

### Phase 3: Deferred Tests Cleanup (Day 7)

**Issue #245: Implement deferred Phase 3 error handling tests**
- **Priority:** Low - Cleanup task
- **Estimate:** S = 1 point (~1-1.5 hours)
- **Type:** Testing

**Why last in testing track:**
- Smallest testing issue
- Was blocked until 0.1.4 completed #244 and #237
- Only 2 specific tests to implement

**Deliverables:**
- AddIngredientDialog error test (loading ingredients failure)
- MealRecordingDialog error test (loading recipes failure)

**Detailed roadmap:** [docs/planning/0.1.5/ISSUE-245-ROADMAP.md](0.1.5/ISSUE-245-ROADMAP.md)

---

### Track B: Polish & Features (Interleave as needed)

#### Issue #251: Visual hierarchy in AddSideDishDialog
- **Priority:** Medium - UI Polish
- **Estimate:** S = 2 points (~3-4 hours)
- **Type:** UI Enhancement

**When to do:**
- Can be done anytime (independent)
- Good break task between testing work
- Improves user experience

**Detailed roadmap:** [docs/planning/0.1.5/ISSUE-251-ROADMAP.md](0.1.5/ISSUE-251-ROADMAP.md)

---

#### Issue #199: Meal type selection when recording
- **Priority:** Medium - Feature
- **Estimate:** M = 3 points (~6-8 hours)
- **Type:** New Feature

**When to do:**
- Can be done anytime (independent)
- Largest issue in milestone
- Good to do when focused time available

**Detailed roadmap:** [docs/planning/0.1.5/ISSUE-199-ROADMAP.md](0.1.5/ISSUE-199-ROADMAP.md)

---

## Timeline Options

### Option A: Sequential (Testing First)

**Week 1:**
- Day 1-2: #230 (Coverage infrastructure)
- Day 3-4: #247 (AddIngredientDialog coverage)
- Day 5: #248 (EditMealRecordingDialog coverage)

**Week 2:**
- Day 6: #249 (MealRecordingDialog coverage)
- Day 7: #245 (Deferred error tests)
- Day 8: #251 (AddSideDishDialog UI)
- Day 9-10: #199 (Meal type selection)

**Total:** ~10 working days

### Option B: Parallel Tracks

**Testing Track:**
- Day 1-2: #230
- Day 3-5: #247, #248, #249 (in parallel or overlapping)
- Day 6: #245

**Polish Track (interleaved):**
- Day 3-4: #251 (while coverage reports generate)
- Day 7-8: #199

**Total:** ~8 working days (with parallelization)

### Option C: Feature First Variant

If user-facing features are higher priority:
- Day 1-3: #199 (Meal type selection)
- Day 4: #251 (AddSideDishDialog UI)
- Day 5-6: #230 (Coverage infrastructure)
- Day 7-9: #247, #248, #249, #245

**Total:** ~9 working days

---

## Risk Assessment

### Low Risk Issues
- **#230:** Following documented best practices, external service
- **#251:** UI restructuring, no data model changes
- **#245:** Only 2 specific tests, clear scope

### Medium Risk Issues
- **#247, #248, #249:** May discover more gaps than expected
  - **Mitigation:** Pragmatic approach - target ~90%, not 100%
  - **Mitigation:** Accept some lines as impractical to test
- **#199:** Database migration, touches multiple screens
  - **Mitigation:** Nullable column, no data backfill needed
  - **Mitigation:** Trust existing migration patterns

### Blockers Status (from 0.1.4)
- **#244 (MockDatabaseHelper error simulation):** CLOSED
- **#237 (Meal editing service consolidation):** CLOSED

All 0.1.4 blockers resolved - 0.1.5 issues are unblocked.

---

## Success Metrics

### Completion Criteria
- [ ] All 7 issues completed and merged
- [ ] All tests passing (`flutter test`)
- [ ] No analysis issues (`flutter analyze`)
- [ ] Coverage badge showing in README
- [ ] Dialog coverage at >90% for all 3 dialogs

### Quality Metrics
- [ ] Codecov integration active with trend tracking
- [ ] AddIngredientDialog: 75.6% → >90%
- [ ] EditMealRecordingDialog: 75.5% → >90%
- [ ] MealRecordingDialog: 75.5% → >90%
- [ ] 2 deferred error tests implemented

### User Impact
- [ ] Coverage visibility enables quality tracking
- [ ] AddSideDishDialog has better visual hierarchy
- [ ] Meals can be tagged with type for better history

---

## Individual Issue Roadmaps

Detailed implementation plans for each issue:

| Issue | Roadmap Document |
|-------|------------------|
| #230 | [ISSUE-230-ROADMAP.md](0.1.5/ISSUE-230-ROADMAP.md) |
| #247 | [ISSUE-247-ROADMAP.md](0.1.5/ISSUE-247-ROADMAP.md) |
| #248 | [ISSUE-248-ROADMAP.md](0.1.5/ISSUE-248-ROADMAP.md) |
| #249 | [ISSUE-249-ROADMAP.md](0.1.5/ISSUE-249-ROADMAP.md) |
| #245 | [ISSUE-245-ROADMAP.md](0.1.5/ISSUE-245-ROADMAP.md) |
| #251 | [ISSUE-251-ROADMAP.md](0.1.5/ISSUE-251-ROADMAP.md) |
| #199 | [ISSUE-199-ROADMAP.md](0.1.5/ISSUE-199-ROADMAP.md) |

---

## Document History

- **2026-01-05:** Initial roadmap created
- **Status:** Ready for review

---

**Approved by:**
- Product Owner: Pending
- Technical Leader: Pending
