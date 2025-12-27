<!-- markdownlint-disable -->
# Testing Roadmap Summary: Issues #38 & #39

**Last Updated**: 2025-12-27

## Overview

This document summarizes the comprehensive testing roadmaps for Issues #38 (Dialog Testing) and #39 (Edge Case Suite), including user priorities, timeline constraints, and recommended execution strategies.

---

## Issue #38: Dialog and State Management Testing

**Full Roadmap**: `docs/ISSUE_38_ROADMAP.md`

### Target Timeline

- **User Constraint**: Maximum 10 work sessions
- **Original Estimate**: 11-15 sessions
- **Gap**: 1-5 sessions over budget
- **Strategy**: Prioritize high-impact dialogs, streamline documentation

### Critical Regression Test

**Controller Disposal Crash (commit 07058a2)**

```dart
// THE BUG: Controller disposed while still in use during dialog cancellation
// SYMPTOM: App crashed when user cancelled dialog
// FIX PATTERN:
if (mounted) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    controller.dispose();
  });
}
```

**Test Requirements**:
- Verify all 6 dialogs safely dispose controllers on cancellation
- Test rapid dialog open/close cycles
- Test back button, outside tap, and explicit cancel
- Ensure no crashes when dialog dismissed during async operations

### Dialog Testing Priorities

Based on Issue #237 (meal editing workflow complexity):

| Priority | Dialog | Reason | Phase 2 Order |
|----------|--------|--------|---------------|
| **HIGH** | AddSideDishDialog | Critical meal editing workflow | Test 1st |
| **HIGH** | EditMealRecordingDialog | Core meal editing | Test 2nd |
| **HIGH** | MealRecordingDialog | Core meal planning | Test 3rd |
| MEDIUM | AddIngredientDialog | Already has basic tests | Test 4th |
| MEDIUM | MealCookedDialog | Planning workflow | Test 5th |
| LOW | AddNewIngredientDialog | Less frequently used | Defer if needed |

### Recommended Execution Strategy for 10-Session Constraint

**Must-Have (8 sessions)**:
- **Phase 1** (2 sessions): DialogTestHelper + basic documentation
- **Phase 2 - Priority Dialogs Only** (3 sessions): Test 3 high-priority dialogs (AddSideDish, EditMealRecording, MealRecording)
- **Phase 2.2** (1 session): Cancellation tests for all 6 dialogs (including regression test)
- **Phase 3 - Limited** (1 session): Error handling for priority dialogs only
- **Phase 4 - Streamlined** (1 session): Regression test + minimal documentation

**Nice-to-Have (if time permits)**:
- Complete remaining 3 dialogs (AddIngredient, MealCooked, AddNewIngredient)
- Full Phase 3 coverage (temporary state, edge cases)
- Comprehensive documentation

**Deferred (can be done later)**:
- Low-priority dialog comprehensive tests
- Advanced edge case scenarios
- Performance optimization of tests

### Success Criteria (Adjusted for 10 Sessions)

Minimum viable completion:
- ✅ DialogTestHelper utility exists and is documented
- ✅ 3 high-priority dialogs fully tested (return values, cancellation, errors)
- ✅ All 6 dialogs have cancellation tests (including regression)
- ✅ Controller disposal regression test passes
- ✅ 85% coverage for priority dialogs
- ✅ Basic testing guide documentation

---

## Issue #39: Edge Case Test Suite

**Full Roadmap**: `docs/ISSUE_39_ROADMAP.md`

### Target Timeline

- **User Constraint**: Maximum 20 work sessions
- **Original Estimate**: 21-27 sessions
- **Gap**: 1-7 sessions over budget
- **Strategy**: Focus on critical features, streamline device testing

### Critical Features (Priority Order)

| Priority | Feature Area | Components | Focus Areas |
|----------|-------------|------------|-------------|
| **HIGHEST** | Meal Editing | WeeklyPlanScreen, MealHistoryScreen, CookMealScreen | All edge cases, Issue #237 complexity |
| **HIGH** | Multi-Recipe Meals | AddSideDishDialog integration | Side dish handling edge cases |
| **HIGH** | Recommendations | RecommendationService | Large dataset performance |
| MEDIUM | Recipe Management | Add/EditRecipeScreen | Basic edge cases |
| MEDIUM | Ingredients | IngredientsScreen, Parser | Boundary conditions |
| LOW | Import/Export | BulkUpdate, Export services | Defer if needed |

### Performance Thresholds (Emulator-Based)

Thresholds adjusted for Pixel 2 API 35 emulator:

**Screen Performance**:
```
Empty state:      < 200ms
10 items:         < 400ms
100 items:        < 1000ms (1 second)
1000+ items:      < 2000ms (2 seconds)
```

**Database Operations**:
```
Single query:     < 100ms
List (100):       < 200ms
Complex joins:    < 400ms
Batch ops:        < 1000ms
```

**Recommendations**:
```
10 recipes:       < 200ms
100 recipes:      < 600ms
1000 recipes:     < 2000ms (max acceptable: 3s with loading)
```

**UI Responsiveness**:
```
Button tap:       < 200ms
Dialog open:      < 400ms
Navigation:       < 600ms
Scrolling:        Smooth (allow occasional jank on emulator)
```

*Note: Emulator thresholds are ~2x more lenient than physical device targets due to virtualization overhead*

### Device Testing Specification

**Automated Test Emulators**:
- **Primary**: Pixel 2 API 35 (Android 15, 5.0" 1080x1920) - all integration tests
- **Secondary**: Medium Phone API 35 (Android 15) - optional for screen size variations
- **Test Type**: Integration tests only (widget/unit tests run on dev machine without emulator)

**Physical Device** (Manual Testing Only):
- Samsung Galaxy S24+ (Android 16, One UI 8.0, 6.7" display)
- Used for: Final validation, real-world performance verification
- Not part of automated test suite

**Note**: Issues #38 and #39 tests are primarily widget/unit tests that don't require emulators. Only integration tests use emulators.

### Recommended Execution Strategy for 20-Session Constraint

**Must-Have (16 sessions)**:
- **Phase 1** (2 sessions): EdgeCaseTestHelpers + catalog foundation
- **Phase 2 - Focused** (6 sessions):
  - Empty states for critical features only (meal editing, recipes)
  - Boundary conditions for meal workflow
  - Skip low-priority features
- **Phase 3 - Critical Only** (5 sessions):
  - Meal editing error scenarios
  - Recommendation service failures
  - Controller disposal pattern verification
  - Skip import/export errors
- **Phase 5 - Priority Items** (3 sessions):
  - Issue #77 Phase 4 integration (MealHistoryScreen edge cases)
  - Critical regression tests
  - Streamlined documentation

**Nice-to-Have (if time permits)**:
- **Phase 4** (4 sessions): Interaction patterns, device testing
- Full Phase 2 coverage (all features)
- Comprehensive Phase 3 (all error scenarios)

**Deferred (can be done later)**:
- Low-priority feature edge cases
- Advanced device-specific testing
- Performance benchmarking for non-critical paths
- Accessibility edge cases (beyond basics)

### Success Criteria (Adjusted for 20 Sessions)

Minimum viable completion:
- ✅ EdgeCaseTestHelpers utility exists
- ✅ Edge case catalog for critical features
- ✅ Meal editing workflow fully tested (empty, boundary, errors)
- ✅ Recommendation service edge cases covered
- ✅ Issue #77 Phase 4 integrated
- ✅ Controller disposal pattern verified app-wide
- ✅ 85% coverage for critical features
- ✅ 90%+ coverage for meal editing
- ✅ Performance thresholds documented and tested for critical paths
- ✅ Basic edge case testing guide

---

## Execution Sequence

### Recommended Order

```
┌─────────────────────────────────────┐
│ 1. Issue #38 (10 sessions)          │
│    - DialogTestHelper foundation    │
│    - 3 priority dialogs tested      │
│    - Regression test for controller │
└──────────────┬──────────────────────┘
               │ Provides utilities & patterns
               ▼
┌─────────────────────────────────────┐
│ 2. Issue #39 (20 sessions)          │
│    - Extends #38 utilities         │
│    - Focus on meal editing         │
│    - Large dataset testing         │
└─────────────────────────────────────┘
```

### Why This Order?

1. **#38 Creates Foundation**: DialogTestHelper patterns extend to EdgeCaseTestHelpers
2. **Smaller Scope First**: Perfect the approach on dialogs before app-wide
3. **Build Momentum**: Early wins with focused dialog testing
4. **Reuse Learning**: #38 error injection patterns → #39 error scenarios

---

## Key Insights from Issue #237

**The Meal Editing Workflow is Complex**:
- 3 different screens handle meal editing
- ~85% code duplication across screens
- Scheduled for consolidation in Issue #237 (milestone 0.1.4)
- Edge case testing will expose integration issues

**Testing Opportunity**:
- Current edge case tests will validate pre-consolidation behavior
- Tests become regression suite after #237 refactoring
- Ensures consolidation doesn't break functionality

**Strategic Value**:
- Testing before refactoring = safety net
- Exposes current bugs = better refactoring
- Validates edge cases = smoother #237 implementation

---

## Timeline Reality Check

### Issue #38 Timeline

**Optimistic** (10 sessions):
- Requires strict prioritization
- May need to defer low-priority dialogs
- Documentation streamlined

**Realistic** (12 sessions):
- All 6 dialogs tested
- Basic Phase 3 coverage
- Good documentation

**Comfortable** (15 sessions):
- Comprehensive Phase 3
- Excellent documentation
- All edge cases covered

### Issue #39 Timeline

**Optimistic** (20 sessions):
- Requires strict focus on critical features
- Streamlined device testing
- May defer accessibility edge cases

**Realistic** (24 sessions):
- All critical features covered
- Basic device testing
- Good documentation

**Comfortable** (27 sessions):
- Full coverage all features
- Comprehensive device testing
- Excellent documentation

---

## Recommendations

### For Issue #38 (Dialog Testing)

**To meet 10-session target**:

1. **Strictly prioritize**: Focus on AddSideDish, EditMealRecording, MealRecording
2. **Minimal documentation**: Create guide, skip extensive examples
3. **Defer low-priority**: AddNewIngredientDialog can wait
4. **Batch similar work**: Test all cancellations together (efficient)
5. **Reuse patterns**: Once AddSideDish is tested, others go faster

**Risk mitigation**:
- If running over, pause at 10 sessions
- Defer remaining dialogs to follow-up issue
- Core utilities and patterns more important than 100% dialog coverage

### For Issue #39 (Edge Case Suite)

**To meet 20-session target**:

1. **Focus on meal editing**: Highest complexity, highest value
2. **Performance test critical paths only**: Recommendations, large lists
3. **Streamline device testing**: Focus on Galaxy S24+, skip extensive cross-device
4. **Integrate #77 Phase 4 early**: Don't save for end
5. **Document as you go**: Avoid final documentation push

**Risk mitigation**:
- If running over, pause at 20 sessions
- Create follow-up issue for deferred features
- Ensure critical regression tests are done
- Performance thresholds documented even if not all tested

---

## Success Metrics

### Issue #38 (Minimum Viable)

- [x] DialogTestHelper exists with core methods (Phase 1 ✅)
- [ ] 3 high-priority dialogs fully tested
- [ ] Controller disposal regression test passes
- [ ] All 6 dialogs have cancellation tests
- [ ] 85% coverage for priority dialogs
- [x] Basic documentation complete (DIALOG_TESTING_GUIDE.md ✅)

### Issue #39 (Minimum Viable)

- [ ] EdgeCaseTestHelpers exists
- [ ] Meal editing edge cases complete
- [ ] Recommendation edge cases complete
- [ ] Issue #77 Phase 4 integrated
- [ ] Controller disposal verified app-wide
- [ ] 85% coverage for critical features
- [ ] 90%+ for meal editing
- [ ] Performance thresholds documented

---

## Next Steps

### Immediate (Before Starting #38)

1. **Review updated roadmaps**:
   - `docs/ISSUE_38_ROADMAP.md`
   - `docs/ISSUE_39_ROADMAP.md`

2. **Clarify any questions** about:
   - Prioritization strategy
   - Performance thresholds (are suggested values acceptable?)
   - Scope trade-offs if over budget

3. **Prepare for #38**:
   - Review existing dialog tests
   - Understand SnackbarTestHelpers pattern (template for DialogTestHelpers)
   - Familiarize with commit 07058a2 (regression test context)

### During #38 Execution

1. **Track time carefully**: Log actual time per phase
2. **Adjust as needed**: If Phase 1 takes longer, adjust Phase 2
3. **Communicate progress**: Update roadmap checkboxes
4. **Flag blockers early**: If stuck, ask for help

### After #38, Before #39

1. **Retrospective**: What worked? What didn't?
2. **Adjust #39 estimates**: Based on #38 actuals
3. **Identify reuse opportunities**: What from #38 directly helps #39?
4. **Refine priorities**: Based on learnings

---

## Questions & Clarifications

### Performance Thresholds

The suggested thresholds are based on general Flutter best practices:
- **Are these acceptable for your app?**
- **Should any be adjusted?** (e.g., more/less strict)
- **Priority order correct?** (meal editing > recommendations > recipes)

### Scope Decisions

If we need to defer work to meet timeline:

**Issue #38 - Defer which?**
- Option A: AddNewIngredientDialog (low usage)
- Option B: Detailed Phase 3 edge cases for medium-priority dialogs
- Option C: Extensive documentation examples

**Issue #39 - Defer which?**
- Option A: Import/Export edge cases (low priority)
- Option B: Accessibility advanced scenarios
- Option C: Cross-device testing (focus on Galaxy S24+ only)

Your preferences will help guide execution decisions.

---

**Physical Device Performance Validation**

Comprehensive physical device performance profiling is **deferred to Issue #243** (milestone 0.2.0 - Beta-Ready Phase).

**Current focus** (Issues #38 & #39):
- ✅ Correctness (features work as expected)
- ✅ Automated test coverage (emulator-based)
- ✅ Functional validation (business logic correct)

**Future focus** (Issue #243, milestone 0.2.0+):
- 📊 Real-world performance validation
- 📊 Physical device profiling (Samsung Galaxy S24+)
- 📊 User experience optimization
- 📊 Performance benchmarking suite

**Rationale**: At this stage (0.1.3), focus on building stable features with good test coverage. Performance optimization and validation make more sense when preparing for beta users (0.2.0) or scaling (0.3.0).

---

**Ready to Start?**

When you're ready to begin Issue #38:
1. Confirm priorities look good
2. Confirm performance thresholds are reasonable (emulator-based)
3. Confirm scope trade-offs are acceptable
4. Start with Phase 1: DialogTestHelper foundation

The roadmaps are now living documents - check off tasks as you complete them!