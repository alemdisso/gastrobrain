# Roadmap: 0.1.4 - Architecture & Critical Bug Fixes

**Milestone:** 0.1.4 - Architecture & Critical Bug Fixes
**Status:** 📋 Planning
**Total Issues:** 4
**Total Points:** 12
**Estimated Duration:** 7-9 working days (10-12 calendar days)
**Start Date:** TBD
**Target Completion:** TBD

---

## Milestone Overview

**Theme:** Fix critical user-blocking bugs, improve testing infrastructure, and consolidate architecture.

**Goals:**
1. ✅ Fix critical UI bugs preventing users from accessing core functionality
2. ✅ Improve testing infrastructure to enable better error testing
3. ✅ Consolidate duplicated meal editing logic into shared service
4. ✅ Improve code quality and maintainability

**Success Criteria:**
- All critical bugs fixed and deployed
- Testing infrastructure improved for 0.1.5 needs
- Meal editing logic consolidated (125 lines removed, better architecture)
- No regressions in existing functionality

---

## Issues Summary

| # | Title | Type | Priority | Points | Estimate |
|---|-------|------|----------|--------|----------|
| #250 | Save Changes button obscured by Android navigation bar | Bug (✘✘) | Critical | S=2 | 3-5 hours |
| #252 | Recipe card chevron inaccessible behind FAB | Bug (✘✘) | Important | S=2 | 3-5 hours |
| #244 | Add error simulation to MockDatabaseHelper | Testing | Medium | M=3 | 4-6 hours |
| #237 | Consolidate meal editing logic into shared service | Architecture | Medium | M=5 | 9-13 hours |
| **TOTAL** | | | | **12** | **19-29 hours** |

---

## Recommended Execution Order

### Phase 1: Critical Bug Fixes (Days 1-2)

#### Issue #250: Save Changes button obscured by Android navigation bar
**Priority:** CRITICAL - Must be done first
**Estimate:** S = 2 points (~3-5 hours)
**Type:** UI Bug

**Why first:**
- ✅ **Critical bug** - Users cannot save recipe edits on Android
- ✅ **User-blocking** - Core functionality broken
- ✅ **Quick win** - Low complexity, clear fix (SafeArea wrapper)
- ✅ **High value** - Immediate user impact

**Scope:**
- Audit EditRecipeScreen and AddRecipeScreen for same issue
- Apply SafeArea wrapper or MediaQuery bottom padding
- Test on Android emulator/device with different navigation styles
- Manual verification on multiple screens

**Risks:** Low - Standard Flutter pattern for system insets

**Dependencies:** None

---

#### Issue #252: Recipe card chevron inaccessible behind FAB
**Priority:** Important - Second priority
**Estimate:** S = 2 points (~3-5 hours)
**Type:** UI Bug

**Why second:**
- ✅ **Important UX issue** - Users can't access recipe options in filtered lists
- ✅ **Quick win** - Clear solution (dynamic padding + scroll physics)
- ✅ **Builds momentum** - Two fixes in first 2 days
- ✅ **Common scenario** - Affects users frequently using filters

**Scope:**
- Fix Recipes tab (HomePage) and Ingredients screen
- Add dynamic bottom padding to ListViews
- Enable AlwaysScrollableScrollPhysics
- Manual testing with various filter results (1-5 items)

**Risks:** Low - Straightforward ListView configuration

**Dependencies:** None

---

### Phase 2: Testing Infrastructure (Days 3-4)

#### Issue #244: Add error simulation to MockDatabaseHelper
**Priority:** Medium - Enables 0.1.5 work
**Estimate:** M = 3 points (~4-6 hours)
**Type:** Testing Infrastructure

**Why third:**
- ✅ **Unblocks 0.1.5** - Enables #245 (deferred error tests)
- ✅ **Medium complexity** - Good to do before big refactoring
- ✅ **Improves test quality** - Better error testing for all future work
- ✅ **Benefits #237** - New MealEditService can have proper error tests

**Scope:**
- Add error simulation to ~10 MockDatabaseHelper methods
- Refactor `deleteMeal` to use standard pattern
- Create documentation: `docs/testing/MOCK_DATABASE_ERROR_SIMULATION.md`
- No new tests (just capability)

**Risks:** Low-Medium - Extending existing patterns, mostly copy-paste work

**Dependencies:** None

**Blocks:** #245 in milestone 0.1.5

---

### Phase 3: Architecture Refactoring (Days 5-7+)

#### Issue #237: Consolidate meal editing logic into shared service
**Priority:** Medium - Biggest architectural improvement
**Estimate:** M = 5 points (~9-13 hours)
**Type:** Architecture

**Why last:**
- ✅ **Largest and most complex** - Deserves full focus
- ✅ **Higher risk** - Touches 3 core screens (meal editing workflows)
- ✅ **Benefits from prior work** - Bugs fixed, tests improved
- ✅ **Can take time** - Not blocking other milestone work
- ✅ **Prerequisites complete** - #234, #235, #236 already done

**Scope:**
- Create new MealEditService with 2 main methods
- Register in ServiceProvider
- Refactor MealHistoryScreen (remove ~55 lines)
- Refactor WeeklyPlanScreen (remove ~50 lines)
- Refactor CookMealScreen (simplify ~20 lines)
- Write unit tests for service
- Verify existing integration tests pass

**Risks:** Medium - Core workflow refactoring, regression potential

**Dependencies:**
- ✅ #234 (completed)
- ✅ #235 (completed)
- ✅ #236 (completed)

---

## Timeline

### Sequential Execution (Recommended)

**Week 1:**
- **Days 1-2:** Phase 1 - Critical bug fixes (#250, #252)
  - Day 1: #250 (Save button fix)
  - Day 2: #252 (Recipe chevron fix)
  - **Checkpoint:** Both critical bugs fixed, users unblocked

- **Days 3-4:** Phase 2 - Testing infrastructure (#244)
  - Days 3-4: #244 (MockDatabaseHelper error simulation)
  - **Checkpoint:** Testing infrastructure ready for 0.1.5

**Week 2:**
- **Days 5-7+:** Phase 3 - Architecture refactoring (#237)
  - Days 5-7: #237 (Consolidate meal editing service)
  - **Checkpoint:** Architecture improved, code consolidated

**Total Duration:** 7-9 working days (10-12 calendar days)

### Adjusted for 0.1.2 Performance (0.90x ratio)

Based on 0.1.2 sprint analysis (estimates were slightly conservative):
- **Estimated:** 7-9 days
- **Likely actual:** 6-8 days
- **Buffer:** 1-2 days for unknowns

---

## Alternative Approach: Parallel Execution

If working with interruptions or wanting variety:

**Primary Track:**
1. Start: #250 (critical, must be first)
2. Continue: #237 (long-running architecture work)

**Secondary Track (interleave as needed):**
- Break task 1: #252 (when stuck on #237)
- Break task 2: #244 (when stuck on #237)

**Note:** Not recommended - sequential is clearer and lower risk.

---

## Risk Assessment

### Low Risk Issues
- ✅ #250: Standard SafeArea pattern
- ✅ #252: Straightforward ListView configuration
- ✅ #244: Extending existing test patterns

### Medium Risk Issues
- ⚠️ #237: Core workflow refactoring
  - **Mitigation:** Unit tests for service, verify integration tests pass
  - **Mitigation:** Manual testing of all 3 affected screens
  - **Mitigation:** Prerequisites (#234-236) already complete

### Critical Path
1. #250 must be done first (critical bug)
2. #244 should be done before 0.1.5 starts (unblocks #245)
3. #237 can be done anytime (no external dependencies)

---

## Dependencies

### Prerequisites (Already Complete)
- ✅ #234 - Refactor WeeklyPlanScreen._updateMealRecord()
- ✅ #235 - Refactor WeeklyPlanScreen._handleMarkAsCooked()
- ✅ #236 - Refactor WeeklyPlanScreen._updateMealPlanItemRecipes()

### Blocks Future Work
- #244 → #245 (deferred error tests in 0.1.5)

### No Internal Dependencies
All 4 issues can technically be done in parallel, but sequential execution is recommended for focus and risk management.

---

## Success Metrics

### Completion Criteria
- [ ] All 4 issues completed and merged
- [ ] All tests passing (`flutter test`)
- [ ] No analysis issues (`flutter analyze`)
- [ ] Manual testing confirms no regressions
- [ ] Critical bugs verified fixed on Android device

### Code Quality Metrics
- [ ] Net code reduction: ~25 lines (after #237)
- [ ] Duplicated code eliminated: ~125 lines removed
- [ ] Test infrastructure improved: 10 new error simulation methods
- [ ] Architecture improved: Meal editing logic consolidated

### User Impact
- [ ] Users can save recipe edits on Android (fix #250)
- [ ] Users can access recipe options in filtered lists (fix #252)
- [ ] Better error testing enables higher quality in 0.1.5+
- [ ] More maintainable codebase for future features

---

## Lessons from 0.1.2

**Apply these learnings:**
1. ✅ **Small tasks efficient when batched** - #250 and #252 together on days 1-2
2. ✅ **Test infrastructure = main risk** - But #244 is extending patterns, not new infra
3. ✅ **High commit count = complexity signal** - Watch #237 carefully
4. ✅ **Most estimates conservative** - Expect ~0.90x ratio (slightly faster)

**From 0.1.2 retrospective:**
- Bug fixes: 0.62x ratio (faster than expected)
- UI/Features: 0.84x ratio (good estimates)
- Testing (existing patterns): 0.62x ratio (conservative)
- Testing (new infrastructure): 4.00x ratio (main risk - not applicable here)

---

## Daily Checklist

### Before Starting
- [ ] Review issue details and acceptance criteria
- [ ] Check for any new dependencies or blockers
- [ ] Ensure development environment is ready

### During Work
- [ ] Run tests frequently (`flutter test`)
- [ ] Check analysis regularly (`flutter analyze`)
- [ ] Commit incrementally with descriptive messages
- [ ] Manual testing on Android device/emulator for UI issues

### After Completing Issue
- [ ] All acceptance criteria met
- [ ] All tests passing
- [ ] No analysis issues
- [ ] Manual verification complete
- [ ] PR created and reviewed
- [ ] Issue closed and cleaned up

---

## Notes

**Testing Environment:**
- Android emulator available for #250, #252 testing
- Real Android device available if needed
- Manual testing is acceptable for UI bugs

**Architecture Decision (#237):**
- Create new MealEditService (clean separation)
- Use existing integration tests (no new integration tests)
- Trust refactoring with good unit tests

**Coverage (#244):**
- Focus on practical error simulation
- No need to test the error simulation itself
- Documentation is important for future test writers

---

## Document History

- **2025-12-31:** Initial roadmap created
- **Status:** Ready for execution

---

**Approved by:**
- Product Owner: ⏳ Pending
- Technical Leader: ⏳ Pending
